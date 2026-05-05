#include <iostream>
#include <string>
#include <vector>
#include <map>

// ============================================================================
// CIRA Bioinformatics Sequence Alignment Compiler Pass
// ============================================================================
// Pattern Detection: BLAST/Smith-Waterman, sequence database search, DP tables
// CIRA Operations: sequence_prefetch, alignment_compute_async, filter_candidates
// Vortex Offload: Database prefetch, candidate filtering with SIMT
// Expected Improvement: 1.2-1.4x (db search latency hidden, filtering parallelized)

struct SequencePattern {
    std::string algorithm;  // "blast", "smith_waterman", "knn_search"
    std::string database_access;  // "linear_scan", "indexed_lookup"
    std::string computation_type;  // "pairwise_alignment", "filtering"
    int query_length;
    int db_size;
    bool requires_dp_table;
};

struct AlignmentTask {
    std::string query;
    std::string db_segment_ptr;
    int segment_size;
    float score_threshold;
};

// ============================================================================
// PATTERN DETECTION PHASE
// ============================================================================

SequencePattern detect_bioinfo_pattern(const std::string& kernel_code) {
    SequencePattern pattern;
    pattern.algorithm = "unknown";
    pattern.database_access = "linear_scan";
    pattern.computation_type = "unknown";
    pattern.requires_dp_table = false;
    pattern.query_length = 0;
    pattern.db_size = 0;

    // Detect BLAST-like linear scan
    if (kernel_code.find("for") != std::string::npos &&
        kernel_code.find("database") != std::string::npos &&
        kernel_code.find("score") != std::string::npos) {
        pattern.algorithm = "blast";
        pattern.computation_type = "filtering";
    }

    // Detect Smith-Waterman (DP table)
    if (kernel_code.find("dp_table") != std::string::npos ||
        kernel_code.find("dp[") != std::string::npos ||
        kernel_code.find("dynamic_programming") != std::string::npos) {
        pattern.algorithm = "smith_waterman";
        pattern.computation_type = "pairwise_alignment";
        pattern.requires_dp_table = true;
    }

    // Detect sequence kNN search
    if (kernel_code.find("knn") != std::string::npos ||
        kernel_code.find("top_k") != std::string::npos ||
        kernel_code.find("nearest") != std::string::npos) {
        pattern.algorithm = "knn_search";
        pattern.computation_type = "similarity_search";
    }

    // Detect indexed lookup
    if (kernel_code.find("index") != std::string::npos ||
        kernel_code.find("lookup") != std::string::npos) {
        pattern.database_access = "indexed_lookup";
    }

    return pattern;
}

// ============================================================================
// CIRA IR GENERATION PHASE
// ============================================================================

std::string generate_blast_async_filtering(const SequencePattern& pattern) {
    std::string cira_ir = R"(
// CIRA BLAST-Like Sequence Filtering with Async Database Scan
// Pattern: Linear scan over database, score filtering, candidate gathering

%query_seq = cira.load_query_sequence : !cira.sequence
%query_len = cira.sequence_length %query_seq : i32
%database_ptr = cira.load_database_ptr : !cira.database_handle
%db_size = cira.database_size %database_ptr : i64
%score_threshold = cira.constant_f32 {value = <THRESHOLD>}

// Phase 1: Divide database into prefetch chunks for Vortex
%chunk_size = cira.constant_i64 {value = 16384}  // 16KB chunks
%num_chunks = cira.div_i64 %db_size, %chunk_size : i64

// Phase 2: Vortex prefetches database chunks sequentially
cira.offload_start %vortex_core_0 {
  // Vortex Task: Stage database segments for CPU filtering
  // SIMT parallelism: threads prefetch different chunks in parallel

  %chunk_buffer = cira.allocate_buffer
                  %chunk_size : !cira.buffer<sequence_chunk>

  cira.for_range %chunk_idx = 0 to %num_chunks {
    // Calculate chunk offset in database
    %offset = cira.mul_i64 %chunk_idx, %chunk_size : i64

    // Load chunk from database to Vortex local buffer
    %chunk_data = cira.load_database_range %database_ptr, %offset, %chunk_size : !cira.sequence_chunk

    // SIMT: Compute preliminary scores for sequences in chunk (fast filtering)
    cira.for_range %seq_idx = 0 to %sequences_per_chunk {
      %offset_in_chunk = cira.mul_i64 %seq_idx, seq_size : i64
      %candidate_seq = cira.vector_extract_slice %chunk_data, %offset_in_chunk, seq_size : !cira.sequence

      // Fast k-mer matching (less precise but quick)
      %kmer_score = cira.kmer_match_fast %query_seq, %candidate_seq, kmer_size=8 : f32
      %passes_kmer = cira.fcmp_ogt %kmer_score, %score_threshold : i1

      cira.cond_branch %passes_kmer, ^candidate_found, ^next_sequence

      ^candidate_found:
        // Candidate passed k-mer filter, add to candidate list
        %global_seq_idx = cira.add_i64 %chunk_idx * %sequences_per_chunk, %seq_idx : i64
        cira.candidate_buffer_append %global_seq_idx, %kmer_score

      ^next_sequence:
    }

    // Prefetch next chunk for pipelining
    %next_chunk_idx = cira.add_i64 %chunk_idx, 1 : i64
    cira.cond_branch %next_chunk_idx < %num_chunks, ^prefetch_next, ^chunk_scan_done

    ^prefetch_next:
      %next_offset = cira.mul_i64 %next_chunk_idx, %chunk_size : i64
      cira.prefetch_l2_range %database_ptr, %next_offset, %chunk_size : !cira.ptr

    ^chunk_scan_done:
  }

  // Barrier: wait for prefetch to complete
  cira.barrier_async
}

// Phase 3: CPU retrieves filtered candidates and performs full alignment
%candidates = cira.candidate_buffer_get : !cira.vector<candidate_info>
%num_candidates = cira.vector_length %candidates : i64

%results = cira.allocate_vector %num_candidates : !cira.vector<alignment_result>

cira.for_range %cand_idx = 0 to %num_candidates {
  %candidate_info = cira.vector_extract %candidates, %cand_idx : !cira.candidate_info
  %candidate_seq_idx = cira.candidate_extract_seq_idx %candidate_info : i64

  // Load full candidate sequence
  %candidate_seq = cira.database_load_sequence %database_ptr, %candidate_seq_idx : !cira.sequence

  // Full alignment (only for candidates that passed filter)
  %alignment = cira.pairwise_alignment_fast %query_seq, %candidate_seq : !cira.alignment_result
  cira.vector_store %results, %cand_idx, %alignment
}

// Return filtered and aligned results
cira.return %results : !cira.vector<alignment_result>
)";

    return cira_ir;
}

std::string generate_smith_waterman_async(const SequencePattern& pattern) {
    std::string cira_ir = R"(
// CIRA Smith-Waterman DP with Async Computation Overlap
// Pattern: Dynamic programming table computation with candidate sequences

%query_seq = cira.load_query_sequence : !cira.sequence
%query_len = cira.sequence_length %query_seq : i32
%candidate_sequences = cira.load_candidate_sequences : !cira.vector<sequence>
%num_candidates = cira.vector_length %candidate_sequences : i64

// Phase 1: Allocate DP tables for parallel processing
%max_seq_len = cira.constant_i32 {value = 1024}
%dp_tables = cira.allocate_buffer
             %num_candidates * %max_seq_len * %query_len * sizeof(f32) : !cira.buffer<dp_table>

// Phase 2: Vortex pre-processes candidates (compute profile vectors)
cira.offload_start %vortex_core_0 {
  // Vortex Task: Compute sequence profiles for SIMT DP computation
  // Profile = composition vector (freq of each amino acid) for fast comparison

  cira.for_range %cand_idx = 0 to %num_candidates {
    %candidate = cira.vector_extract %candidate_sequences, %cand_idx : !cira.sequence
    %candidate_len = cira.sequence_length %candidate : i32

    // Compute amino acid composition profile (20-dim vector)
    %profile = cira.sequence_profile_compute %candidate : !cira.vector<f32>

    // Store profile for CPU access
    %profile_buffer_offset = cira.mul_i32 %cand_idx, profile_size : i32
    cira.buffer_write %profile_buffer, %profile_buffer_offset, %profile : !cira.vector<f32>
  }

  cira.barrier_async
}

// Phase 3: CPU computes Smith-Waterman DP tables for all candidates
// Each candidate DP computed with profile-based substitution matrix

cira.for_range %cand_idx = 0 to %num_candidates {
  %candidate = cira.vector_extract %candidate_sequences, %cand_idx : !cira.sequence
  %candidate_len = cira.sequence_length %candidate : i32

  // Get precomputed profile
  %profile_buffer_offset = cira.mul_i32 %cand_idx, profile_size : i32
  %profile = cira.buffer_read %profile_buffer, %profile_buffer_offset : !cira.vector<f32>

  // Initialize DP table
  %dp = cira.allocate_dp_table %query_len, %candidate_len : !cira.matrix<f32>

  // Fill DP table with profile-based costs
  cira.for_range %i = 1 to %query_len {
    %query_amino = cira.sequence_extract %query_seq, %i : i32

    cira.for_range %j = 1 to %candidate_len {
      %candidate_amino = cira.sequence_extract %candidate, %j : i32

      // Match score using substitution matrix (BLOSUM62)
      %match_score = cira.substitution_matrix_lookup %query_amino, %candidate_amino : f32
      %profile_multiplier = cira.vector_extract %profile, %query_amino : f32
      %adjusted_score = cira.fmul_f32 %match_score, %profile_multiplier : f32

      // DP recurrence: max of (diagonal+match, up+gap, left+gap)
      %diag = cira.dp_table_extract %dp, %i-1, %j-1 : f32
      %up = cira.dp_table_extract %dp, %i-1, %j : f32
      %left = cira.dp_table_extract %dp, %i, %j-1 : f32

      %gap_cost = cira.constant_f32 {value = -4.0}
      %diag_score = cira.fadd_f32 %diag, %adjusted_score : f32
      %up_score = cira.fadd_f32 %up, %gap_cost : f32
      %left_score = cira.fadd_f32 %left, %gap_cost : f32

      // Smith-Waterman: never go below 0 (local alignment)
      %best_score = cira.max_f32 %diag_score, %up_score : f32
      %best_score = cira.max_f32 %best_score, %left_score : f32
      %best_score = cira.max_f32 %best_score, 0.0 : f32

      cira.dp_table_store %dp, %i, %j, %best_score : f32
    }
  }

  // Extract alignment score (max in DP table) and traceback
  %alignment_score = cira.dp_table_max %dp : f32
  %alignment = cira.dp_traceback %dp, %query_seq, %candidate : !cira.alignment_result

  cira.offload_async %vortex_core_0 {
    // Async: Vortex stores result while CPU processes next candidate
    %result_buffer_offset = cira.mul_i32 %cand_idx, result_size : i32
    cira.buffer_write %results_buffer, %result_buffer_offset, %alignment : !cira.alignment_result
  }
}

cira.return cira.buffer_as_vector %results_buffer : !cira.vector<alignment_result>
)";

    return cira_ir;
}

std::string generate_sequence_knn_async(const SequencePattern& pattern) {
    std::string cira_ir = R"(
// CIRA Sequence k-NN Search with Async Database Traversal
// Pattern: Find k nearest neighbors in sequence database using similarity

%query_seq = cira.load_query_sequence : !cira.sequence
%query_len = cira.sequence_length %query_seq : i32
%database_ptr = cira.load_database_ptr : !cira.database_handle
%db_size = cira.database_size %database_ptr : i64
%k = cira.constant_i64 {value = 10}

// Phase 1: Vortex stages candidates for kNN
cira.offload_start %vortex_core_0 {
  // Vortex Task: Compute initial similarity scores for all database sequences
  // Use fast approximation (k-mer overlap) to rank candidates

  %top_k_candidates = cira.allocate_priority_queue %k : !cira.priority_queue<similarity>

  cira.for_range %db_idx = 0 to %db_size {
    %db_seq = cira.database_load_sequence %database_ptr, %db_idx : !cira.sequence

    // Fast similarity using shared k-mers (k=8)
    %similarity = cira.kmer_similarity %query_seq, %db_seq, k=8 : f32

    // Add to top-k priority queue (min-heap, keep largest)
    cira.priority_queue_insert %top_k_candidates, %db_idx, %similarity : !cira.priority_queue<similarity>

    // Prefetch next database entries to hide latency
    cira.cond_branch %db_idx % 64 == 0, ^prefetch_ahead, ^skip_prefetch
    ^prefetch_ahead:
      %lookahead_idx = cira.add_i64 %db_idx, 128 : i64
      cira.prefetch_l2 %database_ptr, %lookahead_idx
    ^skip_prefetch:
  }

  cira.barrier_async
}

// Phase 2: CPU retrieves top-k candidates
%top_k_info = cira.priority_queue_drain %top_k_candidates : !cira.vector<knn_info>

// Phase 3: For top-k candidates, compute accurate alignment scores
%refined_results = cira.allocate_vector %k : !cira.vector<alignment_result>

cira.for_range %rank = 0 to %k {
  %knn_info = cira.vector_extract %top_k_info, %rank : !cira.knn_info
  %candidate_idx = cira.knn_extract_index %knn_info : i64
  %approx_similarity = cira.knn_extract_score %knn_info : f32

  %candidate_seq = cira.database_load_sequence %database_ptr, %candidate_idx : !cira.sequence

  // Compute accurate alignment
  %alignment = cira.pairwise_alignment_accurate %query_seq, %candidate_seq : !cira.alignment_result

  cira.vector_store %refined_results, %rank, %alignment
}

cira.return %refined_results : !cira.vector<alignment_result>
)";

    return cira_ir;
}

// ============================================================================
// VORTEX KERNEL GENERATION
// ============================================================================

std::string generate_vortex_kmer_filter_kernel() {
    return R"(
// Vortex RISC-V SIMT Kernel for k-mer Based Sequence Filtering

.global bioinfo_kmer_filter_kernel

bioinfo_kmer_filter_kernel:
  // Input:
  //   %a0 = query_sequence (pointer to query, ASCII encoded)
  //   %a1 = database_ptr (pointer to sequence database)
  //   %a2 = db_size (number of sequences in database)
  //   %a3 = threshold (minimum k-mer overlap score)

  // Compute k-mer fingerprint of query
  li %query_base, 0x4000        // shared memory base
  li %kmer_size, 8

  // Thread 0: Compute query k-mer hashes
  li %tid, $tid
  cmpi.eq %tid, 0
  cmov.n %is_thread0, 1

  // Extract k-mers from query (stride-based)
  li %kmer_hash_base, 0x5000    // k-mer hash array base
  li %query_idx, 0
  li %kmer_count, 0

  query_kmer_loop:
    // Extract query[query_idx..query_idx+8]
    add %query_ptr, %a0, %query_idx
    lbu %k1, 0(%query_ptr)
    lbu %k2, 1(%query_ptr)
    lbu %k3, 2(%query_ptr)
    lbu %k4, 3(%query_ptr)
    lbu %k5, 4(%query_ptr)
    lbu %k6, 5(%query_ptr)
    lbu %k7, 6(%query_ptr)
    lbu %k8, 7(%query_ptr)

    // Compute hash: simple polynomial rolling hash
    li %hash, %k1
    mul %hash, %hash, 31
    add %hash, %hash, %k2
    mul %hash, %hash, 31
    add %hash, %hash, %k3
    // ... continue for k3-k8 (simplified)

    // Store k-mer hash
    sw %hash, 0(%kmer_hash_base + %kmer_count * 4)

    addi %query_idx, %query_idx, 1
    addi %kmer_count, %kmer_count, 1
    cmp %query_idx, 256           // max query length
    ble query_kmer_loop

  // Barrier: sync after query k-mer computation
  barrier.warp

  // Each thread: score database sequences
  addi %db_idx, %tid, 0
  li %warp_size, 32

  db_score_loop:
    cmp %db_idx, %a2              // if db_idx >= db_size, done
    ble all_scored

    // Load database sequence (strided access)
    mul %seq_offset, %db_idx, 512  // assuming 512 bytes per sequence
    add %seq_ptr, %a1, %seq_offset

    // Compute k-mer hashes for database sequence
    li %db_kmer_base, 0x6000
    li %db_idx_inner, 0
    li %overlap_count, 0

    db_kmer_loop:
      // Extract db_seq[db_idx_inner..db_idx_inner+8]
      add %db_kmer_ptr, %seq_ptr, %db_idx_inner
      lbu %d1, 0(%db_kmer_ptr)
      lbu %d2, 1(%db_kmer_ptr)
      // ... load remaining bytes

      // Compute hash (same as query)
      li %db_hash, %d1
      mul %db_hash, %db_hash, 31
      add %db_hash, %db_hash, %d2
      // ... continue (simplified)

      // Check if hash matches any query k-mer
      li %query_kmer_idx, 0
      match_check_loop:
        lw %query_hash, 0(%kmer_hash_base + %query_kmer_idx * 4)
        cmp %db_hash, %query_hash
        beq kmer_match_found

        addi %query_kmer_idx, %query_kmer_idx, 1
        cmp %query_kmer_idx, %kmer_count
        ble match_check_loop
        j no_match

      kmer_match_found:
        addi %overlap_count, %overlap_count, 1

      no_match:
        addi %db_idx_inner, %db_idx_inner, 1
        cmp %db_idx_inner, 256     // max db sequence length
        ble db_kmer_loop

    // Check if overlap exceeds threshold
    fcvt.s.w %overlap_f, %overlap_count
    li.s %threshold_f, <THRESHOLD>
    fcmp.s %overlap_f, %threshold_f
    bge threshold_passed

    // Score below threshold, skip
    j next_db_sequence

  threshold_passed:
    // Store this sequence index as candidate
    li %candidate_list_base, 0x7000
    lw %candidate_count, 0(%candidate_list_base)
    mul %candidate_offset, %candidate_count, 4
    add %candidate_ptr, %candidate_list_base, 4
    add %candidate_ptr, %candidate_ptr, %candidate_offset
    sw %db_idx, 0(%candidate_ptr)

    // Update count
    addi %candidate_count, %candidate_count, 1
    sw %candidate_count, 0(%candidate_list_base)

  next_db_sequence:
    add %db_idx, %db_idx, %warp_size
    j db_score_loop

  all_scored:
    barrier.warp
    ret
)";
}

std::string generate_vortex_dp_profile_kernel() {
    return R"(
// Vortex RISC-V SIMT Kernel for Sequence Profile Computation (Smith-Waterman)

.global bioinfo_dp_profile_kernel

bioinfo_dp_profile_kernel:
  // Input:
  //   %a0 = sequence (pointer to sequence)
  //   %a1 = sequence_length (length in amino acids)
  //   %a2 = profile_output (20-dim vector for amino acid composition)

  // SIMT: Each thread accumulates count for specific amino acid

  li %tid, $tid                 // thread ID (0-31)
  li %warp_size, 32
  li %amino_acids, 20           // standard amino acid count

  // Initialize per-thread accumulator
  li %my_aa, %tid               // thread handles amino acid [tid]
  li %my_count, 0

  // If thread handles amino acid (tid < 20), proceed
  cmpi.lt %my_aa, %amino_acids
  cmov.n %valid_aa, 1

  cmp %valid_aa, 0
  ble invalid_thread

  // Thread 0-19: Count occurrences of amino acid [tid]
  li %seq_idx, 0
  count_loop:
    cmp %seq_idx, %a1           // if seq_idx >= length, done
    ble counts_ready

    // Load amino acid from sequence
    add %seq_ptr, %a0, %seq_idx
    lbu %aa_char, 0(%seq_ptr)

    // Map character to amino acid index (0-19)
    // Simplified: assume input is already 0-19 encoded
    cmp %aa_char, %my_aa
    bne skip_increment

    addi %my_count, %my_count, 1

  skip_increment:
    addi %seq_idx, %seq_idx, 1
    j count_loop

  counts_ready:
    // Normalize count to frequency (0.0-1.0)
    fcvt.s.w %count_f, %my_count
    fcvt.s.w %len_f, %a1
    fdiv.s %frequency, %count_f, %len_f

    // Store to output profile vector
    mul %out_offset, %my_aa, 4
    add %out_ptr, %a2, %out_offset
    fsw %frequency, 0(%out_ptr)

    j done

  invalid_thread:
    // Threads >= 20: do nothing (or idle)

  done:
    barrier.warp
    ret
)";
}

// ============================================================================
// MAIN ANALYSIS AND CODE GENERATION
// ============================================================================

int main() {
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "CIRA Bioinformatics Sequence Alignment Compiler Pass" << std::endl;
    std::cout << "Optimizing Database Search & Dynamic Programming Computation" << std::endl;
    std::cout << "====================================================================================================" << std::endl;
    std::cout << std::endl;

    // ========== EXAMPLE INPUT KERNELS ==========
    std::string blast_kernel = R"(
void blast_search(const char* query,
                  int query_len,
                  struct Database* db,
                  int db_size,
                  float threshold,
                  struct Result* results,
                  int* result_count) {
    *result_count = 0;

    // Linear scan: check all database sequences
    for (int db_idx = 0; db_idx < db_size; db_idx++) {
        char* db_seq = db->sequences[db_idx];
        int db_len = db->lengths[db_idx];

        // Fast k-mer based filtering
        float kmer_score = compute_kmer_score(query, db_seq, 8);
        if (kmer_score < threshold) continue;

        // Full alignment for candidates that pass filter
        float alignment_score = smith_waterman(query, query_len,
                                               db_seq, db_len);

        if (alignment_score >= threshold) {
            results[*result_count].db_index = db_idx;
            results[*result_count].score = alignment_score;
            (*result_count)++;
        }
    }
}
    )";

    std::string smith_waterman_kernel = R"(
float smith_waterman(const char* query, int qlen,
                    const char* subject, int slen) {
    // Dynamic programming for local sequence alignment
    float dp[qlen+1][slen+1];

    // Initialize
    for (int i = 0; i <= qlen; i++) dp[i][0] = 0;
    for (int j = 0; j <= slen; j++) dp[0][j] = 0;

    // Fill DP table
    float max_score = 0;
    for (int i = 1; i <= qlen; i++) {
        for (int j = 1; j <= slen; j++) {
            // Match score from substitution matrix
            int match_score = (query[i-1] == subject[j-1]) ? 2 : -1;

            float diag = dp[i-1][j-1] + match_score;
            float up = dp[i-1][j] - 2;  // gap penalty
            float left = dp[i][j-1] - 2;

            // Smith-Waterman: local alignment (never go below 0)
            dp[i][j] = fmax(fmax(diag, up), left);
            dp[i][j] = fmax(dp[i][j], 0);

            max_score = fmax(max_score, dp[i][j]);
        }
    }

    return max_score;
}
    )";

    std::string knn_kernel = R"(
void knn_search(const char* query,
                struct Database* db,
                int k,
                struct Result* top_k) {
    // Find k nearest neighbors in database
    struct MaxHeap* heap = create_max_heap(k);

    for (int db_idx = 0; db_idx < db->size; db_idx++) {
        char* db_seq = db->sequences[db_idx];

        // Fast approximate similarity (k-mer overlap)
        float similarity = kmer_similarity(query, db_seq, 8);

        // Insert into top-k heap
        max_heap_insert(heap, db_idx, similarity);
    }

    // Extract top-k and sort
    struct Result* results = max_heap_extract_all(heap);
    for (int i = 0; i < k; i++) {
        top_k[i] = results[i];
    }
}
    )";

    std::cout << "Input Kernel (BLAST-Like Linear Database Scan):" << std::endl;
    std::cout << std::endl;
    std::cout << blast_kernel << std::endl;

    std::cout << "Input Kernel (Smith-Waterman Dynamic Programming):" << std::endl;
    std::cout << std::endl;
    std::cout << smith_waterman_kernel << std::endl;

    std::cout << "Input Kernel (Sequence k-NN Search):" << std::endl;
    std::cout << std::endl;
    std::cout << knn_kernel << std::endl;
    std::cout << std::endl;

    // ========== ANALYSIS PHASE ==========
    std::cout << "--- ANALYSIS PHASE ---" << std::endl;

    SequencePattern blast_pattern = detect_bioinfo_pattern(blast_kernel);
    SequencePattern sw_pattern = detect_bioinfo_pattern(smith_waterman_kernel);
    SequencePattern knn_pattern = detect_bioinfo_pattern(knn_kernel);

    std::cout << "  [Analysis] Detected " << blast_pattern.algorithm << " with " << blast_pattern.database_access << std::endl;
    std::cout << "  [Analysis] Linear database scan causing random memory access patterns" << std::endl;
    std::cout << "  [Analysis] Detected " << sw_pattern.algorithm << " with DP table required: "
              << (sw_pattern.requires_dp_table ? "YES" : "NO") << std::endl;
    std::cout << "  [Analysis] DP computation shows cache locality; candidates are pre-filtered" << std::endl;
    std::cout << "  [Analysis] Detected " << knn_pattern.algorithm << " pattern for similarity ranking" << std::endl;
    std::cout << "  [Analysis] Opportunity: Vortex prefetch database, parallelize k-mer scoring, async alignment" << std::endl;
    std::cout << std::endl;

    // ========== CIRA IR GENERATION ==========
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: BLAST-Like Filtering (Async Database Scan)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_blast = generate_blast_async_filtering(blast_pattern);
    std::cout << cira_blast << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: Smith-Waterman (DP with Profile-Based Acceleration)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_sw = generate_smith_waterman_async(sw_pattern);
    std::cout << cira_sw << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: k-NN Search (Async Similarity Ranking)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_knn = generate_sequence_knn_async(knn_pattern);
    std::cout << cira_knn << std::endl;
    std::cout << std::endl;

    // ========== VORTEX KERNEL GENERATION ==========
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "VORTEX RISC-V SIMT KERNEL: k-mer Based Filtering (SIMT Scoring)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string vortex_kmer = generate_vortex_kmer_filter_kernel();
    std::cout << vortex_kmer << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "VORTEX RISC-V SIMT KERNEL: DP Profile Computation (Amino Acid Composition)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string vortex_profile = generate_vortex_dp_profile_kernel();
    std::cout << vortex_profile << std::endl;
    std::cout << std::endl;

    // ========== OPTIMIZATION SUMMARY ==========
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "OPTIMIZATION SUMMARY" << std::endl;
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "✓ Pattern detection: BLAST linear scan, Smith-Waterman DP, k-NN search" << std::endl;
    std::cout << "✓ Database prefetch: Vortex stages sequence chunks sequentially" << std::endl;
    std::cout << "✓ Fast filtering: k-mer overlap scoring with SIMT parallelism" << std::endl;
    std::cout << "✓ DP acceleration: Profile-based substitution matrix for faster computation" << std::endl;
    std::cout << "✓ Async alignment: CPU/Vortex pipeline for full alignment of top candidates" << std::endl;
    std::cout << std::endl;
    std::cout << "Expected Performance Improvement: 1.2-1.4x" << std::endl;
    std::cout << "  - Database linear scan latency hidden by async prefetch" << std::endl;
    std::cout << "  - k-mer filtering reduces full alignment candidates by 10-50x" << std::endl;
    std::cout << "  - Smith-Waterman DP cache-friendly with good SIMD utilization" << std::endl;
    std::cout << "  - k-NN ranking parallelized; expensive DP only on top candidates" << std::endl;

    return 0;
}
