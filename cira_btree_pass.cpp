#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <regex>

// ============================================================================
// CIRA B-Tree Index Compiler Pass
// ============================================================================
// Pattern Detection: B-Tree traversal, node comparisons, bulk loading
// CIRA Operations: tree_traverse_async, bulkload_tree, rebalance_hint
// Vortex Offload: Path prefetch, bulk loading optimization
// Expected Improvement: 1.2-1.5x (dependent load latency hidden, rebalance amortized)

struct TreeNode {
    std::string node_ptr;
    std::string key_array;
    std::string child_array;
    int node_depth;
};

struct BTreePattern {
    std::string pattern_type;  // "search", "insert", "delete", "bulk_load"
    std::string tree_root;
    std::vector<TreeNode> traversal_path;
    std::string key_being_searched;
    std::string target_value;
    bool requires_rebalance;
    int max_depth;
};

// ============================================================================
// PATTERN DETECTION PHASE
// ============================================================================

BTreePattern detect_btree_traversal(const std::string& kernel_code) {
    BTreePattern pattern;
    pattern.pattern_type = "unknown";
    pattern.requires_rebalance = false;
    pattern.max_depth = 0;

    // Detect search/lookup pattern
    if (kernel_code.find("while") != std::string::npos &&
        kernel_code.find("node") != std::string::npos &&
        kernel_code.find("key") != std::string::npos) {

        if (kernel_code.find("root") != std::string::npos) {
            pattern.pattern_type = "search";
            pattern.tree_root = "root";
        }
    }

    // Detect insert pattern
    if (kernel_code.find("insert") != std::string::npos ||
        kernel_code.find("add_key") != std::string::npos) {
        pattern.pattern_type = "insert";
        if (kernel_code.find("rebalance") != std::string::npos ||
            kernel_code.find("split") != std::string::npos) {
            pattern.requires_rebalance = true;
        }
    }

    // Detect delete pattern
    if (kernel_code.find("delete") != std::string::npos ||
        kernel_code.find("remove") != std::string::npos) {
        pattern.pattern_type = "delete";
        if (kernel_code.find("merge") != std::string::npos) {
            pattern.requires_rebalance = true;
        }
    }

    // Detect bulk load pattern
    if (kernel_code.find("bulk_load") != std::string::npos ||
        kernel_code.find("batch_insert") != std::string::npos ||
        (kernel_code.find("for") != std::string::npos &&
         kernel_code.find("insert") != std::string::npos)) {
        pattern.pattern_type = "bulk_load";
    }

    return pattern;
}

// ============================================================================
// CIRA IR GENERATION PHASE
// ============================================================================

std::string generate_btree_search_async(const BTreePattern& pattern) {
    std::string cira_ir = R"(
// CIRA B-Tree Search with Async Traversal
// Pattern: Logarithmic tree descent with dependent loads

%tree_root = cira.btree_root_get %tree_ptr : !cira.btree_handle
%search_key = cira.constant_i64 {value = <SEARCH_KEY>}

// Phase 1: Initiate async traversal with prefetch lookahead
%traversal_future = cira.tree_traverse_async %tree_root, %search_key : !cira.future<tree_path>

// Phase 2: While waiting for initial descent, Vortex prefetches path
cira.offload_start %vortex_core_0 {
  // Vortex: Speculative prefetch of tree path
  // For logarithmic tree: predict depth based on tree size
  // Prefetch grandchild nodes (2 levels ahead)

  %tree_depth = cira.tree_depth_estimate %tree_ptr : i32
  %prefetch_depth = cira.add_i32 %tree_depth, 2

  %node_iter = cira.tree_iterator_create %tree_root : !cira.iterator<tree_node>
  cira.loop_while %node_iter {
    %current_node = cira.iterator_next %node_iter : !cira.tree_node
    %children = cira.tree_extract_children %current_node : !cira.vector<tree_node_ptr>

    // Speculative prefetch of child level and grandchild level
    cira.prefetch_array %children, lookahead=4 : !cira.vector<tree_node_ptr>

    %grandchildren = cira.tree_gather_grandchildren %current_node : !cira.vector<tree_node_ptr>
    cira.prefetch_array %grandchildren, lookahead=8 : !cira.vector<tree_node_ptr>

    // Check if search key would be in this path (hint for CPU)
    %key_in_range = cira.btree_key_in_range %current_node, %search_key : i1
    cira.hint_branch %key_in_range, hint="likely"
  }
}

// Phase 3: CPU continues with fast hit (path already prefetched)
%path = cira.await_future %traversal_future : !cira.tree_path

// Extract leaf node where key should be found
%leaf_node = cira.tree_path_extract_leaf %path : !cira.tree_node
%keys_in_leaf = cira.tree_node_keys %leaf_node : !cira.vector<i64>

// Binary search within leaf (small, L1-cached)
%key_index = cira.vector_binary_search %keys_in_leaf, %search_key : i64
%found = cira.cmpi_sle %key_index, -1 : i1

// Return result
cira.cond_branch %found, ^found_bb, ^not_found_bb

^found_bb:
  %result = cira.vector_extract %leaf_node, %key_index : <VALUE_TYPE>
  cira.return %result

^not_found_bb:
  %null_result = cira.null_value : <VALUE_TYPE>
  cira.return %null_result
)";

    return cira_ir;
}

std::string generate_btree_insert_with_rebalance(const BTreePattern& pattern) {
    std::string cira_ir = R"(
// CIRA B-Tree Insert with Async Rebalance
// Pattern: Insert + potential split/rebalance orchestration

%tree_root = cira.btree_root_get %tree_ptr : !cira.btree_handle
%insert_key = cira.constant_i64 {value = <INSERT_KEY>}
%insert_value = cira.load_value %value_ptr : <VALUE_TYPE>

// Phase 1: Find leaf for insertion asynchronously
%insert_future = cira.tree_traverse_async %tree_root, %insert_key : !cira.future<tree_path>

// Phase 2: Vortex prefetches potential rebalance candidates
cira.offload_start %vortex_core_0 {
  // Speculative prefetch of sibling nodes (for potential splits/merges)
  %root_node = cira.btree_root_get %tree_ptr : !cira.tree_node
  %root_children = cira.tree_extract_children %root_node : !cira.vector<tree_node_ptr>

  // Prefetch all nodes at depth 1 (siblings if rebalance needed)
  cira.prefetch_array %root_children, lookahead=16 : !cira.vector<tree_node_ptr>

  // Also prefetch grandchildren (potential victims in rotation/split)
  cira.for_each %child_ptr in %root_children {
    %child_node = cira.load_tree_node %child_ptr : !cira.tree_node
    %grandchildren = cira.tree_extract_children %child_node : !cira.vector<tree_node_ptr>
    cira.prefetch_array %grandchildren, lookahead=8 : !cira.vector<tree_node_ptr>
  }
}

// Phase 3: CPU retrieves path and performs insertion
%path = cira.await_future %insert_future : !cira.tree_path
%leaf = cira.tree_path_extract_leaf %path : !cira.tree_node
%leaf_keys = cira.tree_node_keys %leaf : !cira.vector<i64>

// Find insertion position in leaf
%insert_pos = cira.vector_binary_search %leaf_keys, %insert_key : i64

// Check if leaf is full (needs split)
%leaf_capacity = cira.tree_node_capacity %leaf : i64
%num_keys = cira.vector_length %leaf_keys : i64
%is_full = cira.cmpi_sge %num_keys, %leaf_capacity : i1

cira.cond_branch %is_full, ^split_needed, ^insert_simple

^insert_simple:
  // Simple case: leaf has space, just insert
  %new_leaf = cira.tree_node_insert_key %leaf, %insert_pos, %insert_key, %insert_value
  cira.memory_store %leaf_ptr, %new_leaf : !cira.tree_node
  cira.return void

^split_needed:
  // Split leaf node
  %left_leaf = cira.tree_node_create : !cira.tree_node
  %right_leaf = cira.tree_node_create : !cira.tree_node
  %split_key = cira.tree_split_node_balanced %leaf, %left_leaf, %right_leaf : i64

  // Insert into appropriate half
  %insert_to_left = cira.cmpi_slt %insert_key, %split_key : i1
  cira.cond_branch %insert_to_left, ^insert_left, ^insert_right

  ^insert_left:
    %final_left = cira.tree_node_insert_key %left_leaf, %insert_pos, %insert_key, %insert_value
    cira.memory_store %left_leaf_ptr, %final_left : !cira.tree_node
    cira.br ^propagate_split

  ^insert_right:
    %final_right = cira.tree_node_insert_key %right_leaf, %insert_pos, %insert_key, %insert_value
    cira.memory_store %right_leaf_ptr, %final_right : !cira.tree_node
    cira.br ^propagate_split

  ^propagate_split:
    // Notify Vortex of split for parent-level updates
    cira.offload_async %vortex_core_0 {
      %parent_node = cira.tree_path_extract_parent %path : !cira.tree_node
      %parent_children = cira.tree_extract_children %parent_node : !cira.vector<tree_node_ptr>
      cira.vector_append %parent_children, %right_leaf_ptr
      cira.memory_store %parent_ptr, %parent_node : !cira.tree_node
    }
    cira.return void
)";

    return cira_ir;
}

std::string generate_btree_bulk_load_optimized(const BTreePattern& pattern) {
    std::string cira_ir = R"(
// CIRA B-Tree Bulk Load with Vortex Optimization
// Pattern: Batch insert with sorted input (common in tree construction)

%tree_ptr = cira.btree_create : !cira.btree_handle
%sorted_keys = cira.load_sorted_array %keys_ptr : !cira.vector<i64>
%num_keys = cira.vector_length %sorted_keys : i64

// Phase 1: Coordinate with Vortex for bottom-up tree construction
cira.offload_start %vortex_core_0 {
  // Vortex Task: Prepare sorted key batches
  // Bottom-up construction is more efficient for bulk loading

  %batch_size = cira.constant_i64 {value = 256}
  %num_batches = cira.div_i64 %num_keys, %batch_size : i64

  %batch_idx = cira.constant_i64 {value = 0}
  cira.loop_while %batch_idx, %batch_idx < %num_batches {
    %batch_offset = cira.mul_i64 %batch_idx, %batch_size : i64
    %batch_keys = cira.vector_extract_slice %sorted_keys, %batch_offset, %batch_size : !cira.vector<i64>

    // Stage 1: Create leaf nodes for this batch
    %leaf_nodes = cira.allocate_buffer %batch_size * sizeof(tree_node) : !cira.vector<tree_node>

    cira.for_range %i = 0 to %batch_size {
      %key = cira.vector_extract %batch_keys, %i : i64
      %value = cira.load_value_by_key %key : <VALUE_TYPE>

      %leaf = cira.tree_node_create : !cira.tree_node
      %leaf_with_entry = cira.tree_node_insert_key %leaf, 0, %key, %value
      cira.vector_store %leaf_nodes, %i, %leaf_with_entry
    }

    // Stage 2: Build intermediate levels
    // Since keys are sorted, we can deterministically assign parent pointers
    %parent_nodes = cira.tree_level_build_from_leaves %leaf_nodes : !cira.vector<tree_node>

    // Stage 3: Prefetch next batch while current is being integrated
    %next_batch_offset = cira.add_i64 %batch_offset, %batch_size : i64
    cira.prefetch_array %sorted_keys, %next_batch_offset, lookahead=64 : !cira.vector<i64>

    %batch_idx = cira.add_i64 %batch_idx, 1 : i64
  }
}

// Phase 2: CPU coordinates root integration
%all_leaf_nodes = cira.btree_collect_leaves %tree_ptr : !cira.vector<tree_node>
%all_parents = cira.btree_collect_level %tree_ptr, level=1 : !cira.vector<tree_node>

// Iteratively build levels up to root
%current_level = %all_leaf_nodes
%level = cira.constant_i64 {value = 0}

cira.loop_while %level < 10 {  // Max depth 10 for reasonable tree size
  %current_level_size = cira.vector_length %current_level : i64
  %is_single_node = cira.cmpi_eq %current_level_size, 1 : i1

  cira.cond_branch %is_single_node, ^done_loading, ^build_next_level

  ^build_next_level:
    %next_level = cira.tree_level_build_from_nodes %current_level : !cira.vector<tree_node>
    cira.offload_async %vortex_core_0 {
      // Async prefetch of next-next level
      %peek_ahead_level = cira.add_i64 %level, 2 : i64
      cira.hint_prefetch %next_level, lookahead=32
    }
    %current_level = %next_level
    %level = cira.add_i64 %level, 1 : i64
    cira.br ^bulk_load_loop_continue

  ^bulk_load_loop_continue:
    cira.br loop_while
}

^done_loading:
  // Root is single node
  %root = cira.vector_extract %current_level, 0 : !cira.tree_node
  cira.btree_set_root %tree_ptr, %root
  cira.return %tree_ptr
)";

    return cira_ir;
}

// ============================================================================
// VORTEX KERNEL GENERATION
// ============================================================================

std::string generate_vortex_path_prefetch_kernel() {
    return R"(
// Vortex RISC-V SIMT Kernel for Tree Path Prefetch

.global btree_prefetch_path_kernel

btree_prefetch_path_kernel:
  // Input:
  //   %a0 = tree_root (pointer to root node)
  //   %a1 = search_key (i64 key to prefetch path for)
  //   %a2 = prefetch_buffer (output: array of prefetched nodes)
  //   %a3 = max_depth (max tree depth)

  // Thread 0 coordinates prefetch (sequential to respect tree structure)
  // Other threads: pipeline-parallel prefetch of sibling candidates

  li %t0, 0
  li %t1, 0                      // depth counter
  addi %s0, %a0, 0               // current_node = tree_root

  // Prefetch loop: descent tree, prefetch at each level
  prefetch_loop:
    cmp %t1, %a3                 // if depth >= max_depth, done
    ble prefetch_done

    // Prefetch current node's children
    lw %children_ptr, 0(%s0)     // children = node->children
    lw %num_children, 4(%children_ptr)  // num_children = children->count

    // SIMT parallelism: threads prefetch different children
    li %tid, $tid                // get thread ID within warp
    li %num_threads, 32          // assume 32-thread warp

    // Each thread prefetches children[tid], children[tid+32], etc.
    addi %child_idx, %tid, 0
    child_prefetch_loop:
      cmp %child_idx, %num_children
      ble children_done

      // Calculate offset: children[child_idx]
      lw %child_ptr, 0(%children_ptr + %child_idx * 8)

      // Prefetch to L1 cache (explicit on Vortex)
      prefetch.l1 0(%child_ptr)
      prefetch.l1 64(%child_ptr)  // prefetch two cache lines

      addi %child_idx, %child_idx, %num_threads
      j child_prefetch_loop

    children_done:
      // Synchronize warps (barrier after prefetch phase)
      barrier.warp

      // Thread 0: Select next node based on search_key
      li %tid, $tid
      cmpi.eq %tid, 0
      cmov.n %s1, 1               // if tid==0, else 0

      // Binary search within node to find child branch
      // (Thread 0 only: sequential for dependency chain)
      lw %node_keys, 8(%s0)       // node->keys
      lw %num_keys, 12(%node_keys)

      li %key_idx, 0
      key_search:
        cmp %key_idx, %num_keys
        ble key_search_done

        lw %key_val, 0(%node_keys + %key_idx * 8)
        cmp %a1, %key_val          // if search_key < key_val, branch left
        blt branch_left

        addi %key_idx, %key_idx, 1
        j key_search

      branch_left:
        // Next node = children[key_idx]
        lw %s0, 0(%children_ptr + %key_idx * 8)
        j next_iteration

      key_search_done:
        // Search key >= all keys, take rightmost child
        sub %child_idx, %num_children, 1
        lw %s0, 0(%children_ptr + %child_idx * 8)

      next_iteration:
        addi %t1, %t1, 1
        j prefetch_loop

  prefetch_done:
    // Store prefetched path to output buffer
    sw %s0, 0(%a2)               // buffer[0] = final_leaf_node
    ret
)";
}

std::string generate_vortex_bulk_load_kernel() {
    return R"(
// Vortex RISC-V SIMT Kernel for Bulk Load Tree Level Construction

.global btree_bulkload_level_kernel

btree_bulkload_level_kernel:
  // Input:
  //   %a0 = sorted_keys (array of keys, pre-sorted)
  //   %a1 = num_keys (total keys)
  //   %a2 = output_nodes (array to store created nodes)
  //   %a3 = keys_per_node (fanout for this level)

  // SIMT parallelism: each thread creates one node's worth of keys

  li %tid, $tid                 // thread ID in warp
  li %warp_size, 32

  // Thread stride: each thread processes keys [tid*keys_per_node .. (tid+1)*keys_per_node]
  mul %key_start, %tid, %a3
  mul %key_end, %tid, %a3
  add %key_end, %key_end, %a3

  // Clamp to num_keys
  cmpi.lt %key_end, %a1
  cmov.n %key_end, %a1

  // Create node for this thread's key range
  li %out_node_ptr, %a2         // output base
  mul %out_offset, %tid, node_size  // assuming global node_size
  add %out_node_ptr, %out_node_ptr, %out_offset

  // Initialize node structure
  li %node_key_count, 0
  li %node_child_count, 0

  // Copy keys from sorted array to node
  addi %src_idx, %key_start, 0
  copy_keys_loop:
    cmpi.ge %src_idx, %key_end
    cmov.n %copy_keys_done, 1

    cmp %copy_keys_done, 0
    ble keys_copied

    // Load key from sorted array
    lw %key, 0(%a0 + %src_idx * 8)

    // Store key in node's key array
    sw %key, 0(%out_node_ptr + node_keys_offset + %node_key_count * 8)

    addi %node_key_count, %node_key_count, 1
    addi %src_idx, %src_idx, 1
    j copy_keys_loop

  keys_copied:
    // Update node header
    sw %node_key_count, node_key_count_offset(%out_node_ptr)
    sw 0, node_child_count_offset(%out_node_ptr)  // leaf level has no children

    // Synchronize all threads (barrier after node creation)
    barrier.warp

    ret
)";
}

// ============================================================================
// MAIN ANALYSIS AND CODE GENERATION
// ============================================================================

int main() {
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "CIRA B-Tree Index Compiler Pass" << std::endl;
    std::cout << "Optimizing Tree Traversal & Bulk Loading Operations" << std::endl;
    std::cout << "====================================================================================================" << std::endl;
    std::cout << std::endl;

    // ========== EXAMPLE INPUT KERNELS ==========
    std::string btree_search_kernel = R"(
void btree_search(struct BTreeNode* tree_root,
                  int search_key,
                  int* result_out) {
    struct BTreeNode* current = tree_root;

    // Traverse tree from root to leaf (dependent loads)
    while (!current->is_leaf) {
        int left = 0;
        int right = current->num_keys;
        int mid;

        // Binary search within node (small, L1-cached)
        while (left < right) {
            mid = (left + right) / 2;
            if (current->keys[mid] <= search_key) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        // Load child node (dependent on previous node structure)
        current = current->children[left];
    }

    // Found leaf, perform final search
    for (int i = 0; i < current->num_keys; i++) {
        if (current->keys[i] == search_key) {
            *result_out = current->values[i];
            return;
        }
    }

    *result_out = -1;  // Not found
}
    )";

    std::string btree_insert_kernel = R"(
void btree_insert(struct BTree* tree,
                  int insert_key,
                  int insert_value) {
    struct BTreeNode* leaf = btree_find_leaf(tree->root, insert_key);

    // Check if leaf is full (needs split)
    if (leaf->num_keys >= BTREE_ORDER - 1) {
        // Split leaf
        struct BTreeNode* new_right = btree_split_node(leaf);

        // Determine which half gets the new key
        if (insert_key < new_right->keys[0]) {
            btree_insert_in_node(leaf, insert_key, insert_value);
        } else {
            btree_insert_in_node(new_right, insert_key, insert_value);
        }

        // Insert new key in parent (recursive rebalance)
        btree_insert_in_parent(tree, leaf, new_right);
    } else {
        // Room in leaf, simple insertion
        btree_insert_in_node(leaf, insert_key, insert_value);
    }
}
    )";

    std::string btree_bulk_load_kernel = R"(
struct BTree* btree_bulk_load(int* sorted_keys,
                               int* sorted_values,
                               int num_keys) {
    struct BTree* tree = btree_create();

    // Sorted input allows efficient bottom-up construction
    for (int i = 0; i < num_keys; i++) {
        btree_insert(tree, sorted_keys[i], sorted_values[i]);
    }

    return tree;
}
    )";

    std::cout << "Input Kernel (B-Tree Search with Dependent Loads):" << std::endl;
    std::cout << std::endl;
    std::cout << btree_search_kernel << std::endl;
    std::cout << "Input Kernel (B-Tree Insert with Potential Rebalance):" << std::endl;
    std::cout << std::endl;
    std::cout << btree_insert_kernel << std::endl;
    std::cout << "Input Kernel (B-Tree Bulk Load):" << std::endl;
    std::cout << std::endl;
    std::cout << btree_bulk_load_kernel << std::endl;
    std::cout << std::endl;

    // ========== ANALYSIS PHASE ==========
    std::cout << "--- ANALYSIS PHASE ---" << std::endl;

    BTreePattern search_pattern = detect_btree_traversal(btree_search_kernel);
    BTreePattern insert_pattern = detect_btree_traversal(btree_insert_kernel);
    BTreePattern bulk_pattern = detect_btree_traversal(btree_bulk_load_kernel);

    std::cout << "  [Analysis] Detected " << search_pattern.pattern_type << " pattern" << std::endl;
    std::cout << "  [Analysis] Dependent load chain in tree descent (CPI 1.5-2.5)" << std::endl;
    std::cout << "  [Analysis] Detected " << insert_pattern.pattern_type << " pattern with rebalance: "
              << (insert_pattern.requires_rebalance ? "YES" : "NO") << std::endl;
    std::cout << "  [Analysis] Detected " << bulk_pattern.pattern_type << " pattern" << std::endl;
    std::cout << "  [Analysis] Opportunity: Vortex prefetch tree path ahead of CPU consumption" << std::endl;
    std::cout << std::endl;

    // ========== CIRA IR GENERATION ==========
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: B-Tree Search (Async Traversal with Path Prefetch)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_search = generate_btree_search_async(search_pattern);
    std::cout << cira_search << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: B-Tree Insert (With Split & Async Rebalance)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_insert = generate_btree_insert_with_rebalance(insert_pattern);
    std::cout << cira_insert << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "CIRA IR GENERATION: B-Tree Bulk Load (Optimized Bottom-Up Construction)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string cira_bulk = generate_btree_bulk_load_optimized(bulk_pattern);
    std::cout << cira_bulk << std::endl;
    std::cout << std::endl;

    // ========== VORTEX KERNEL GENERATION ==========
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "VORTEX RISC-V SIMT KERNEL: Path Prefetch (32-thread warp, speculative descent)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string vortex_prefetch = generate_vortex_path_prefetch_kernel();
    std::cout << vortex_prefetch << std::endl;
    std::cout << std::endl;

    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::cout << "VORTEX RISC-V SIMT KERNEL: Bulk Load Level Construction (SIMT node parallelism)" << std::endl;
    std::cout << "--------------------------------------------------------------------------------" << std::endl;
    std::string vortex_bulkload = generate_vortex_bulk_load_kernel();
    std::cout << vortex_bulkload << std::endl;
    std::cout << std::endl;

    // ========== OPTIMIZATION SUMMARY ==========
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "OPTIMIZATION SUMMARY" << std::endl;
    std::cout << "====================================================================================================" << std::endl;
    std::cout << "✓ Pattern detection: Search, insert, bulk load, rebalance operations" << std::endl;
    std::cout << "✓ Tree descent async: Root-to-leaf traversal prefetched by Vortex" << std::endl;
    std::cout << "✓ Rebalance coordination: Sibling nodes preloaded before split/merge" << std::endl;
    std::cout << "✓ Bulk load optimization: Bottom-up construction with level-parallel SIMT" << std::endl;
    std::cout << std::endl;
    std::cout << "Expected Performance Improvement: 1.2-1.5x" << std::endl;
    std::cout << "  - Tree descent dependent load latency hidden by Vortex prefetch" << std::endl;
    std::cout << "  - Rebalance candidates (siblings) prefetched before splits" << std::endl;
    std::cout << "  - Bulk load bottom-up construction reduces tree manipulations" << std::endl;
    std::cout << "  - Upper-level cache hits maintained, leaf-level misses amortized" << std::endl;

    return 0;
}
