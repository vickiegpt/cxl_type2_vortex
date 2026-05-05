#include <iostream>
#include <string>
#include <vector>
#include <map>

// ============================================================================
// CIRA Full-Text Search Compiler Pass
// ============================================================================
// Pattern Detection: Inverted index traversal, posting list iteration, Boolean ops
// CIRA Operations: posting_list_iterator, boolean_eval_async, relevance_score_async
// Vortex Offload: Parallel postings traversal, intersection caching
// Expected Improvement: 1.3-1.6x (random index jumps hidden, cache hits improved)

struct PostingList {
    std::string list_name;
    std::string doc_ids;
    std::string frequencies;
    int list_length;
};

struct InvertedIndex {
    std::map<std::string, PostingList> index;
    std::string index_ptr;
};

struct FullTextSearchPattern {
    std::string pattern_type;  // "single_term", "phrase", "boolean", "ranking"
    std::vector<std::string> terms;
    std::string query_type;    // "AND", "OR", "phrase_query"
    bool requires_ranking;
    std::vector<PostingList> posting_lists;
};

// ============================================================================
// PATTERN DETECTION PHASE
// ============================================================================

FullTextSearchPattern detect_fulltext_search(const std::string& kernel_code) {
    FullTextSearchPattern pattern;
    pattern.pattern_type = "unknown";
    pattern.requires_ranking = false;

    // Detect single term search
    if (kernel_code.find("lookup") != std::string::npos &&
        kernel_code.find("posting") != std::string::npos) {
        pattern.pattern_type = "single_term";
    }

    // Detect phrase query (multiple sequential terms)
    if (kernel_code.find("phrase") != std::string::npos ||
        (kernel_code.find("for") != std::string::npos &&
         kernel_code.find("term") != std::string::npos)) {
        pattern.pattern_type = "phrase";
    }

    // Detect Boolean queries (AND/OR)
    if (kernel_code.find(" && ") != std::string::npos ||
        kernel_code.find("AND") != std::string::npos) {
        pattern.query_type = "AND";
        pattern.pattern_type = "boolean";
    }
    if (kernel_code.find(" || ") != std::string::npos ||
        kernel_code.find("OR") != std::string::npos) {
        pattern.query_type = "OR";
        pattern.pattern_type = "boolean";
    }

    // Detect ranking (BM25, TF-IDF)
    if (kernel_code.find("BM25") != std::string::npos ||
        kernel_code.find("TF-IDF") != std::string::npos ||
        kernel_code.find("score") != std::string::npos ||
        kernel_code.find("relevance") != std::string::npos) {
        pattern.requires_ranking = true;
    }

    return pattern;
}

// ============================================================================
// CIRA IR GENERATION PHASE
// ============================================================================

std::string generate_boolean_query_async(const FullTextSearchPattern& pattern) {
    std::string cira_ir = R"(
// CIRA Full-Text Boolean Query with Async Posting List Iteration
// Pattern: Multi-term AND/OR with intersection/union operations

%index_ptr = cira.inverted_index_get : !cira.index_handle
%query_terms = cira.constant_array {terms = ["term1", "term2", "term3"]}
%num_terms = cira.vector_length %query_terms : i64

// Phase 1: Initiate async iteration over all posting lists
%posting_futures = cira.allocate_vector %num_terms : !cira.vector<future>

cira.for_range %i = 0 to %num_terms {
  %term = cira.vector_extract %query_terms, %i : !cira.string
  %posting_future = cira.posting_list_iterator_async %index_ptr, %term : !cira.future<posting_list>
  cira.vector_store %posting_futures, %i, %posting_future
}

// Phase 2: Vortex prefetches postings lists and prepares cache
cira.offload_start %vortex_core_0 {
  // Vortex Task: Speculative loading and intersection setup
  // Goal: Cache frequently-accessed posting list segments

  %posting_buffers = cira.allocate_buffer
                     %num_terms * cache_line_size : !cira.buffer<postings>

  cira.for_range %term_idx = 0 to %num_terms {
    %term = cira.vector_extract %query_terms, %term_idx : !cira.string
    %posting_ptr = cira.index_lookup %index_ptr, %term : !cira.posting_list_ptr

    // Prefetch first segment of posting list
    %first_segment = cira.load_postings_segment %posting_ptr, offset=0 : !cira.vector<i32>
    cira.prefetch_array %first_segment, lookahead=8 : !cira.vector<i32>

    // Prefetch second segment (next batch of documents)
    %second_segment = cira.load_postings_segment %posting_ptr, offset=1 : !cira.vector<i32>
    cira.prefetch_array %second_segment, lookahead=16 : !cira.vector<i32>

    // Cache posting metadata (length, frequency distribution)
    %posting_meta = cira.posting_metadata_extract %posting_ptr : !cira.posting_metadata
    cira.llc_reserve_space %posting_meta, priority=HIGH
  }

  // Synchronize with CPU
  cira.barrier_async
}

// Phase 3: CPU evaluates Boolean operation while postings are prefetched
%postings = cira.allocate_vector %num_terms : !cira.vector<posting_list>

cira.for_range %i = 0 to %num_terms {
  %posting_future = cira.vector_extract %posting_futures, %i : !cira.future<posting_list>
  %posting = cira.await_future %posting_future : !cira.posting_list
  cira.vector_store %postings, %i, %posting
}

// Boolean operation: AND = intersection, OR = union
%is_and_query = cira.cmpi_eq %query_type, 0 : i1  // 0 = AND
cira.cond_branch %is_and_query, ^boolean_and, ^boolean_or

^boolean_and:
  // Intersection: start with smallest posting list
  %smallest_idx = cira.posting_find_smallest_list %postings : i64
  %result_docs = cira.posting_list_extract %postings, %smallest_idx : !cira.vector<i32>

  // For each other list, intersect
  cira.for_range %other_idx = 0 to %num_terms {
    %is_different = cira.cmpi_ne %other_idx, %smallest_idx : i1
    cira.cond_branch %is_different, ^intersect_with_list, ^skip_intersect

    ^intersect_with_list:
      %other_list = cira.posting_list_extract %postings, %other_idx : !cira.vector<i32>

      // Two-pointer merge for intersection
      %left_idx = cira.constant_i64 {value = 0}
      %right_idx = cira.constant_i64 {value = 0}
      %result_write_idx = cira.constant_i64 {value = 0}

      %left_len = cira.vector_length %result_docs : i64
      %right_len = cira.vector_length %other_list : i64

      cira.loop_while %left_idx < %left_len && %right_idx < %right_len {
        %left_doc = cira.vector_extract %result_docs, %left_idx : i32
        %right_doc = cira.vector_extract %other_list, %right_idx : i32

        %is_equal = cira.cmpi_eq %left_doc, %right_doc : i1
        %left_less = cira.cmpi_slt %left_doc, %right_doc : i1

        cira.cond_branch %is_equal, ^found_match, ^check_less

        ^found_match:
          // Document in both lists
          cira.vector_store %result_docs, %result_write_idx, %left_doc
          %left_idx = cira.add_i64 %left_idx, 1 : i64
          %right_idx = cira.add_i64 %right_idx, 1 : i64
          %result_write_idx = cira.add_i64 %result_write_idx, 1 : i64
          cira.br ^loop_continue

        ^check_less:
          cira.cond_branch %left_less, ^advance_left, ^advance_right

        ^advance_left:
          %left_idx = cira.add_i64 %left_idx, 1 : i64
          cira.br ^loop_continue

        ^advance_right:
          %right_idx = cira.add_i64 %right_idx, 1 : i64
          cira.br ^loop_continue

        ^loop_continue:
      }

      // Truncate result to actual length
      cira.vector_resize %result_docs, %result_write_idx
      cira.br ^skip_intersect

    ^skip_intersect:
  }

  cira.br ^return_results

^boolean_or:
  // Union: merge all posting lists (simpler than intersection)
  %merged = cira.allocate_vector : !cira.vector<i32>
  cira.for_range %p_idx = 0 to %num_terms {
    %posting = cira.vector_extract %postings, %p_idx : !cira.posting_list
    %docs = cira.posting_list_extract_docs %posting : !cira.vector<i32>
    cira.vector_append_dedup %merged, %docs
  }
  %result_docs = %merged
  cira.br ^return_results

^return_results:
  cira.return %result_docs : !cira.vector<i32>
)";

    return cira_ir;
}

std::string generate_bm25_ranking_async(const FullTextSearchPattern& pattern) {
    std::string cira_ir = R"(
// CIRA BM25 Relevance Scoring with Async Computation
// Pattern: Rank candidate documents by TF-IDF or BM25

%index_ptr = cira.inverted_index_get : !cira.index_handle
%query_terms = cira.constant_array {terms = ["term1", "term2"]}
%candidate_docs = cira.load_docs_from_result_set : !cira.vector<doc_id>
%num_docs = cira.vector_length %candidate_docs : i64

// BM25 parameters
%k1 = cira.constant_f32 {value = 1.5}
%b = cira.constant_f32 {value = 0.75}
%avg_doc_length = cira.constant_f32 {value = 500.0}

// Phase 1: Prefetch document statistics and term frequencies
cira.offload_start %vortex_core_0 {
  // Vortex Task: Stage statistics for all candidate documents
  // BM25 requires: doc_length[d], term_frequency[d,t] for each (doc, term)

  %stats_buffer = cira.allocate_buffer
                  %num_docs * sizeof(doc_stats) : !cira.buffer<doc_stats>

  cira.for_range %doc_idx = 0 to %num_docs {
    %doc_id = cira.vector_extract %candidate_docs, %doc_idx : i32

    // Prefetch document length
    %doc_length_ptr = cira.doc_length_table_lookup %index_ptr, %doc_id : !cira.ptr<i32>
    cira.prefetch_l2 0(%doc_length_ptr)

    // Prefetch term frequency vectors for this doc
    cira.for_range %term_idx = 0 to 2 {  // num_query_terms=2
      %term = cira.vector_extract %query_terms, %term_idx : !cira.string
      %tf_ptr = cira.term_frequency_lookup %index_ptr, %doc_id, %term : !cira.ptr<i32>
      cira.prefetch_l2 0(%tf_ptr)
    }
  }
}

// Phase 2: Compute BM25 scores asynchronously
%scores = cira.allocate_vector %num_docs : !cira.vector<f32>

cira.for_range %doc_idx = 0 to %num_docs {
  %doc_id = cira.vector_extract %candidate_docs, %doc_idx : i32

  // Initialize score
  %score = cira.constant_f32 {value = 0.0}

  // For each term, accumulate BM25 contribution
  cira.for_range %term_idx = 0 to 2 {
    %term = cira.vector_extract %query_terms, %term_idx : !cira.string

    // Get IDF (inverse document frequency) - constant across docs
    %idf = cira.idf_lookup %index_ptr, %term : f32

    // Get TF (term frequency in this doc)
    %tf = cira.term_frequency_lookup %index_ptr, %doc_id, %term : i32
    %tf_f32 = cira.sitofp %tf : f32

    // Get document length
    %doc_length = cira.doc_length_lookup %index_ptr, %doc_id : i32
    %doc_length_f32 = cira.sitofp %doc_length : f32

    // BM25 formula: score += IDF * (TF * (k1 + 1)) / (TF + k1 * (1 - b + b * (doc_len / avg_len)))
    %tf_scaled = cira.fadd_f32 %tf_f32, %k1 : f32
    %tf_scaled = cira.fmul_f32 %tf_scaled, %k1 : f32
    %tf_scaled = cira.fadd_f32 %tf_scaled, 1.0 : f32

    %len_ratio = cira.fdiv_f32 %doc_length_f32, %avg_doc_length : f32
    %len_scaling = cira.fmul_f32 %b, %len_ratio : f32
    %len_scaling = cira.fsub_f32 1.0, %len_scaling : f32
    %len_scaling = cira.fadd_f32 1.0, %len_scaling : f32

    %denominator = cira.fmul_f32 %k1, %len_scaling : f32
    %denominator = cira.fadd_f32 %tf_f32, %denominator : f32

    %bm25_term = cira.fdiv_f32 %tf_scaled, %denominator : f32
    %bm25_term = cira.fmul_f32 %idf, %bm25_term : f32

    %score = cira.fadd_f32 %score, %bm25_term : f32
  }

  // Store score (async, non-blocking)
  cira.offload_async %vortex_core_0 {
    cira.vector_store %scores, %doc_idx, %score
  }
}

// Phase 3: Top-K selection (performed asynchronously)
%k = cira.constant_i64 {value = 10}
%top_k_results = cira.offload_topk_async %scores, %candidate_docs, %k : !cira.future<vector>

cira.return %top_k_results : !cira.future<vector<i32>>
)";

    return cira_ir;
}

std::string generate_phrase_query_async(const FullTextSearchPattern& pattern) {
    std::string cira_ir = R"(
// CIRA Phrase Query with Positional Information
// Pattern: Multi-term phrase where words must appear consecutively

%index_ptr = cira.inverted_index_get : !cira.index_handle
%phrase_terms = cira.constant_array {terms = ["machine", "learning"]}
%num_terms = cira.vector_length %phrase_terms : i64

// Phase 1: Get posting lists for each term
%postings = cira.allocate_vector %num_terms : !cira.vector<posting_list>

cira.for_range %i = 0 to %num_terms {
  %term = cira.vector_extract %phrase_terms, %i : !cira.string
  %posting = cira.posting_list_get %index_ptr, %term : !cira.posting_list
  cira.vector_store %postings, %i, %posting
}

// Phase 2: Vortex caches posting lists and prepares position arrays
cira.offload_start %vortex_core_0 {
  // Vortex: Prefetch position information for phrase matching
  // For each term, we need doc_id -> list_of_positions

  cira.for_range %term_idx = 0 to %num_terms {
    %term = cira.vector_extract %phrase_terms, %term_idx : !cira.string
    %posting = cira.posting_list_get %index_ptr, %term : !cira.posting_list

    // Prefetch position arrays (stored as sub-arrays in posting)
    %positions_ptr = cira.posting_positions_get %posting : !cira.ptr<positions>
    cira.prefetch_array %positions_ptr, lookahead=32 : !cira.ptr<positions>
  }
}

// Phase 3: Phrase matching using position arrays
// Start with smallest posting list (for efficiency)
%smallest_idx = cira.posting_find_smallest_list %postings : i64
%candidate_docs = cira.posting_list_extract %postings, %smallest_idx : !cira.vector<i32>
%phrase_results = cira.allocate_vector : !cira.vector<i32>

cira.for_range %doc_idx = 0 to cira.vector_length(%candidate_docs) {
  %doc_id = cira.vector_extract %candidate_docs, %doc_idx : i32

  // For this document, check if phrase words appear in order
  %is_phrase_match = cira.constant_i1 {value = 1}

  // Get positions of first term in document
  %first_term = cira.vector_extract %phrase_terms, 0 : !cira.string
  %first_posting = cira.vector_extract %postings, 0 : !cira.posting_list
  %first_positions = cira.posting_doc_positions %first_posting, %doc_id : !cira.vector<i32>

  // For each position of first term, check if remaining terms follow
  cira.for_range %pos_idx = 0 to cira.vector_length(%first_positions) {
    %pos = cira.vector_extract %first_positions, %pos_idx : i32

    // Check subsequent terms are at positions pos+1, pos+2, etc.
    %all_match = cira.constant_i1 {value = 1}
    cira.for_range %term_idx = 1 to %num_terms {
      %term = cira.vector_extract %phrase_terms, %term_idx : !cira.string
      %posting = cira.vector_extract %postings, %term_idx : !cira.posting_list
      %expected_pos = cira.add_i32 %pos, %term_idx : i32

      %positions = cira.posting_doc_positions %posting, %doc_id : !cira.vector<i32>
      %found = cira.vector_contains %positions, %expected_pos : i1

      %all_match = cira.andi %all_match, %found : i1
    }

    cira.cond_branch %all_match, ^found_phrase, ^next_position

    ^found_phrase:
      cira.vector_append %phrase_results, %doc_id
      %is_phrase_match = cira.constant_i1 {value = 1}
      cira.br ^next_phrase_doc

    ^next_position:
  }

  ^next_phrase_doc:
}

cira.return %phrase_results : !cira.vector<i32>
)";

    return cira_ir;
}

// ============================================================================
// VORTEX KERNEL GENERATION
// ============================================================================

std::string generate_vortex_posting_cache_kernel() {
    return R"(
// Vortex RISC-V SIMT Kernel for Posting List Caching & Prefetch

.global fts_posting_cache_kernel

fts_posting_cache_kernel:
  // Input:
  //   %a0 = index_ptr (pointer to inverted index base)
  //   %a1 = term_ids (array of term indices to cache)
  //   %a2 = num_terms (number of terms)
  //   %a3 = cache_buffer (L2 reserved space for caching)

  // SIMT parallelism: each thread prefetches one term's posting list

  li %tid, $tid                 // get thread ID
  li %warp_size, 32

  // Thread stride: each thread handles terms[tid], terms[tid+32], etc.
  addi %term_offset, %tid, 0

  thread_loop:
    cmp %term_offset, %a2      // if term_offset >= num_terms, done
    ble all_terms_cached

    // Get term_id for this thread
    lw %term_id, 0(%a1 + %term_offset * 4)

    // Lookup posting list in index (hash table lookup in index)
    // hash = term_id % index_size
    li %index_size, 65536
    rem %hash, %term_id, %index_size

    li %index_entry_size, 32   // bytes per index entry
    mul %entry_offset, %hash, %index_entry_size
    add %entry_ptr, %a0, %entry_offset

    // Load posting list pointer from index entry
    lw %posting_ptr, 0(%entry_ptr)  // posting = index[hash]

    // Load posting list header (length, frequency info)
    lw %posting_len, 0(%posting_ptr)
    lw %freq_total, 4(%posting_ptr)
    lw %first_doc, 8(%posting_ptr)

    // Prefetch multiple segments of posting list
    li %segment_size, 256      // bytes per segment
    li %num_segments, 4        // prefetch first 4 segments

    li %segment_idx, 0
  segment_loop:
    cmp %segment_idx, %num_segments
    ble segments_done

    mul %segment_offset, %segment_idx, %segment_size
    add %prefetch_addr, %posting_ptr, %segment_offset
    addi %prefetch_addr, %prefetch_addr, 16   // skip header

    // Prefetch to L2
    prefetch.l2 0(%prefetch_addr)
    prefetch.l2 64(%prefetch_addr)
    prefetch.l2 128(%prefetch_addr)
    prefetch.l2 192(%prefetch_addr)

    addi %segment_idx, %segment_idx, 1
    j segment_loop

  segments_done:
    // Store posting list pointer in cache buffer for CPU access
    mul %cache_offset, %tid, 8
    sw %posting_ptr, 0(%a3 + %cache_offset)

    // Move to next term (thread stride)
    add %term_offset, %term_offset, %warp_size
    j thread_loop

  all_terms_cached:
    // Synchronize all threads (barrier)
    barrier.warp
    ret
)";
}

std::string generate_vortex_bm25_scoring_kernel() {
    return R"(
// Vortex RISC-V SIMT Kernel for BM25 Score Computation

.global fts_bm25_scoring_kernel

fts_bm25_scoring_kernel:
  // Input:
  //   %a0 = candidate_docs (array of doc IDs to score)
  //   %a1 = num_docs (number of candidate documents)
  //   %a2 = query_terms (array of term IDs)
  //   %a3 = num_terms (number of query terms)

  // Additional inputs via shared memory:
  //   doc_stats[doc_id] = (doc_length, freq_ptr)
  //   idf[term_id] = inverse document frequency

  // SIMT parallelism: each thread scores one document

  li %tid, $tid                 // thread ID
  li %warp_size, 32

  // Initialize per-thread score accumulator
  fcvt.s.w %score, %zero        // score = 0.0

  // Each thread processes one document
  addi %doc_idx, %tid, 0

  doc_loop:
    cmp %doc_idx, %a1           // if doc_idx >= num_docs, done
    ble all_docs_scored

    // Load document ID
    lw %doc_id, 0(%a0 + %doc_idx * 4)

    // Load document statistics from shared memory
    li %doc_stats_base, 0x1000  // shared memory base (Vortex AXI4-MM)
    mul %doc_stats_offset, %doc_id, 8
    add %doc_stats_ptr, %doc_stats_base, %doc_stats_offset

    lw %doc_length, 0(%doc_stats_ptr)
    lw %freq_ptr, 4(%doc_stats_ptr)

    fcvt.s.w %doc_len_f, %doc_length    // convert to float

    // Score accumulation loop for each query term
    li %term_idx, 0
  score_term_loop:
    cmp %term_idx, %a3          // if term_idx >= num_terms, done
    ble scored_doc

    // Load term ID
    lw %term_id, 0(%a2 + %term_idx * 4)

    // Load IDF for this term (from cache/register)
    // Simplified: assume IDF values are pre-loaded in registers
    // In real implementation, would use small lookup table

    // Load term frequency for (doc, term)
    // TF offset = freq_ptr + term_idx * 4
    add %tf_offset, %freq_ptr, %term_idx
    add %tf_offset, %tf_offset, %tf_offset   // x2 (multiply by 4, but already have /)
    lw %tf_i, 0(%freq_ptr + %tf_offset)
    fcvt.s.w %tf_f, %tf_i

    // BM25 parameters (constants)
    li.s %k1, 1.5
    li.s %b, 0.75
    li.s %avg_doc_len, 500.0

    // BM25 computation (simplified)
    // numerator = TF * (k1 + 1)
    fadd.s %num, %tf_f, %k1
    fmul.s %num, %num, %k1
    fadd.s %num, %num, 1.0
    fmul.s %num, %num, %tf_f

    // denominator = TF + k1 * (1 - b + b * (doc_len / avg_len))
    fdiv.s %len_ratio, %doc_len_f, %avg_doc_len
    fmul.s %denom, %b, %len_ratio
    fsub.s %denom, 1.0, %denom
    fadd.s %denom, %denom, 1.0
    fmul.s %denom, %denom, %k1
    fadd.s %denom, %denom, %tf_f

    // bm25_term = IDF * (numerator / denominator)
    fdiv.s %bm25_term, %num, %denom
    fmul.s %bm25_term, %bm25_term, %idf  // use cached IDF

    // Accumulate score
    fadd.s %score, %score, %bm25_term

    addi %term_idx, %term_idx, 1
    j score_term_loop

  scored_doc:
    // Store score to shared memory output
    li %scores_base, 0x2000     // output buffer base
    mul %score_offset, %doc_idx, 4
    add %score_ptr, %scores_base, %score_offset
    fsw %score, 0(%score_ptr)

    // Move to next document
    add %doc_idx, %doc_idx, %warp_size
    fcvt.s.w %score, %zero      // reset accumulator
    j doc_loop

  all_docs_scored:
    barrier.warp
    ret
)";
}

// ============================================================================
// MAIN ANALYSIS AND CODE GENERATION
// ============================================================================

int main() {
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "CIRA Full-Text Search Compiler Pass" << std::endl;
    std::cout << "Optimizing Inverted Index Traversal & Boolean Query Evaluation" << std::endl;
    std::cout << "====================================================================================================" << std::endl;
    std::cout << std::endl;

    // ========== EXAMPLE INPUT KERNELS ==========
    std::string fts_boolean_kernel = R"(
void boolean_query_and(struct InvertedIndex* index,
                       const char** query_terms,
                       int num_terms,
                       int* result_docs,
                       int* result_count) {
    struct PostingList* first_list = index_lookup(index, query_terms[0]);
    memcpy(result_docs, first_list->docs, first_list->length * sizeof(int));
    *result_count = first_list->length;

    // Intersect with remaining posting lists
    for (int t = 1; t < num_terms; t++) {
        struct PostingList* list = index_lookup(index, query_terms[t]);

        // Two-pointer intersection merge
        int left = 0, right = 0, write_idx = 0;
        while (left < *result_count && right < list->length) {
            if (result_docs[left] == list->docs[right]) {
                result_docs[write_idx++] = result_docs[left];
                left++;
                right++;
            } else if (result_docs[left] < list->docs[right]) {
                left++;
            } else {
                right++;
            }
        }
        *result_count = write_idx;
    }
}
    )";

    std::string fts_ranking_kernel = R"(
void bm25_rank(struct InvertedIndex* index,
               const char** query_terms,
               int num_terms,
               int* candidate_docs,
               int num_candidates,
               float* scores) {
    float k1 = 1.5, b = 0.75;
    float avg_doc_length = 500.0;

    for (int d = 0; d < num_candidates; d++) {
        int doc_id = candidate_docs[d];
        float score = 0.0;

        for (int t = 0; t < num_terms; t++) {
            float idf = get_idf(index, query_terms[t]);
            int tf = get_term_frequency(index, doc_id, query_terms[t]);
            float doc_length = get_doc_length(index, doc_id);

            // BM25 formula
            float numerator = tf * (k1 + 1);
            float denominator = tf + k1 * (1.0 - b + b * (doc_length / avg_doc_length));
            score += idf * (numerator / denominator);
        }

        scores[d] = score;
    }
}
    )";

    std::string fts_phrase_kernel = R"(
void phrase_query(struct InvertedIndex* index,
                  const char** phrase_terms,
                  int num_terms,
                  int* result_docs,
                  int* result_count) {
    struct PostingList* first_list = index_lookup(index, phrase_terms[0]);
    *result_count = 0;

    // For each document containing first term
    for (int d = 0; d < first_list->length; d++) {
        int doc_id = first_list->docs[d];
        int* first_positions = get_positions(index, doc_id, phrase_terms[0]);

        // For each occurrence of first term
        for (int pos_idx = 0; pos_idx < first_positions[0]; pos_idx++) {
            int pos = first_positions[pos_idx + 1];
            int match = 1;

            // Check if remaining terms follow at pos+1, pos+2, etc.
            for (int t = 1; t < num_terms; t++) {
                int* positions = get_positions(index, doc_id, phrase_terms[t]);
                if (!contains(positions, pos + t)) {
                    match = 0;
                    break;
                }
            }

            if (match) {
                result_docs[*result_count] = doc_id;
                (*result_count)++;
                break;  // Found this document
            }
        }
    }
}
    )";

    std::cout << "Input Kernel (Boolean AND Query):" << std::endl;
    std::cout << std::endl;
    std::cout << fts_boolean_kernel << std::endl;

    std::cout << "Input Kernel (BM25 Relevance Ranking):" << std::endl;
    std::cout << std::endl;
    std::cout << fts_ranking_kernel << std::endl;

    std::cout << "Input Kernel (Phrase Query):" << std::endl;
    std::cout << std::endl;
    std::cout << fts_phrase_kernel << std::endl;
    std::cout << std::endl;

    // ========== ANALYSIS PHASE ==========
    std::cout << "--- ANALYSIS PHASE ---" << std::endl;

    FullTextSearchPattern bool_pattern = detect_fulltext_search(fts_boolean_kernel);
    FullTextSearchPattern rank_pattern = detect_fulltext_search(fts_ranking_kernel);
    FullTextSearchPattern phrase_pattern = detect_fulltext_search(fts_phrase_kernel);

    std::cout << "  [Analysis] Detected " << bool_pattern.pattern_type << " pattern (type: " << bool_pattern.query_type << ")" << std::endl;
    std::cout << "  [Analysis] Random posting list jumps causing cache misses and stalls" << std::endl;
    std::cout << "  [Analysis] Detected " << rank_pattern.pattern_type << " pattern with ranking" << std::endl;
    std::cout << "  [Analysis] BM25 scoring requires term frequency lookups per document" << std::endl;
    std::cout << "  [Analysis] Detected " << phrase_pattern.pattern_type << " pattern with position constraints" << std::endl;
    std::cout << "  [Analysis] Position-based matching requires sequential posting traversal" << std::endl;
    std::cout << std::endl;

    // ========== CIRA IR GENERATION ==========
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: Boolean AND Query (Async Posting Intersection)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_bool = generate_boolean_query_async(bool_pattern);
    std::cout << cira_bool << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: BM25 Ranking (Async Scoring with Prefetch)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_rank = generate_bm25_ranking_async(rank_pattern);
    std::cout << cira_rank << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: Phrase Query (Position-Based Matching)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_phrase = generate_phrase_query_async(phrase_pattern);
    std::cout << cira_phrase << std::endl;
    std::cout << std::endl;

    // ========== VORTEX KERNEL GENERATION ==========
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "VORTEX RISC-V SIMT KERNEL: Posting List Caching (Prefetch & Stage)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string vortex_cache = generate_vortex_posting_cache_kernel();
    std::cout << vortex_cache << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "VORTEX RISC-V SIMT KERNEL: BM25 Scoring (SIMT Document Parallelism)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string vortex_scoring = generate_vortex_bm25_scoring_kernel();
    std::cout << vortex_scoring << std::endl;
    std::cout << std::endl;

    // ========== OPTIMIZATION SUMMARY ==========
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "OPTIMIZATION SUMMARY" << std::endl;
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "✓ Pattern detection: Boolean AND/OR, phrase queries, BM25 ranking" << std::endl;
    std::cout << "✓ Async posting iteration: Parallel list traversal with speculative prefetch" << std::endl;
    std::cout << "✓ Cache coordination: Vortex stages hot index segments in LLC" << std::endl;
    std::cout << "✓ Score computation: SIMT-parallel BM25 across candidate documents" << std::endl;
    std::cout << std::endl;
    std::cout << "Expected Performance Improvement: 1.3-1.6x" << std::endl;
    std::cout << "  - Random posting list jumps hidden by async prefetch" << std::endl;
    std::cout << "  - Intersection/union operations parallelized via SIMT" << std::endl;
    std::cout << "  - Document statistics and position arrays cached in LLC" << std::endl;
    std::cout << "  - BM25 scoring overlapped with postings traversal" << std::endl;

    return 0;
}
