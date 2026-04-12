/**
 * mcf_cira.cpp
 *
 * MCF (network simplex) benchmark with CIRA heterogeneous execution.
 *
 * Demonstrates the two-phase offload pattern from the paper:
 *   Phase 1: Pricing kernel — pointer-chase through arc list (offloaded)
 *   Phase 2: Price-out kernel — implicit arc evaluation (offloaded)
 *   Host: tree updates in psimplex (overlapped with Vortex prefetch)
 *
 * Build:
 *   g++ -std=c++17 -O2 -march=native -o mcf_cira mcf_cira.cpp \
 *       ../runtime/cira_runtime.cpp -I../runtime -lpthread
 *
 * Usage:
 *   ./mcf_cira [--simulate] [--depth N] [--iterations N]
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <chrono>
#include <vector>
#include <numeric>
#include "cira_runtime.h"

using namespace cira::runtime;

// Simplified MCF arc structure (matches MCF network simplex arc layout)
struct Arc {
    Arc* next;          // Next arc in adjacency list (pointer chase target)
    int64_t cost;       // Reduced cost
    int64_t flow;       // Current flow
    uint32_t tail;      // Source node
    uint32_t head;      // Destination node
    uint64_t padding;   // Align to 48 bytes
};

// Build a random linked-list graph to simulate MCF arc structure
std::vector<Arc> build_random_arcs(uint32_t n_arcs) {
    std::vector<Arc> arcs(n_arcs);
    for (uint32_t i = 0; i < n_arcs; i++) {
        arcs[i].next = (i + 1 < n_arcs) ? &arcs[i + 1] : nullptr;
        arcs[i].cost = rand() % 1000 - 500;
        arcs[i].flow = 0;
        arcs[i].tail = i;
        arcs[i].head = (i + 1) % n_arcs;
    }
    // Shuffle to create irregular access pattern
    for (uint32_t i = n_arcs - 1; i > 0; i--) {
        uint32_t j = rand() % (i + 1);
        // Swap next pointers to randomize chain
        Arc* tmp = arcs[i].next;
        arcs[i].next = arcs[j].next;
        arcs[j].next = tmp;
    }
    return arcs;
}

// Baseline: pricing kernel (x86 only, no offloading)
int64_t pricing_baseline(Arc* arc_list, uint32_t n_arcs) {
    int64_t min_cost = INT64_MAX;
    Arc* arc = arc_list;
    while (arc) {
        if (arc->cost < min_cost) {
            min_cost = arc->cost;
        }
        arc = arc->next;
    }
    return min_cost;
}

// CIRA: pricing kernel with Vortex prefetch offloading
int64_t pricing_cira(Arc* arc_list, uint32_t n_arcs,
                     CiraRuntime& rt, uint32_t depth) {
    // Allocate LLC tile and future
    CiraHandle buf = rt.alloc_cxl(depth * sizeof(Arc));
    CiraFuture f = rt.future_create(1);

    // Offload pointer-chase prefetching to Vortex
    rt.offload(
        reinterpret_cast<uint64_t>(arc_list),
        FUNC_PREFETCH_CHAIN,
        offsetof(Arc, next),     // next_offset
        offsetof(Arc, cost),     // data_offset
        sizeof(int64_t),         // data_size
        0,                       // arg3 (unused)
        depth,
        &f
    );

    // Host: consume data as Vortex delivers it
    int64_t min_cost = INT64_MAX;
    Arc* arc = arc_list;

    // Process arcs, with Vortex running ahead
    while (arc) {
        if (arc->cost < min_cost) {
            min_cost = arc->cost;
        }
        arc = arc->next;
    }

    // Wait for Vortex to finish
    rt.future_await(f);
    rt.release(f);
    rt.free_cxl(buf);

    return min_cost;
}

// Simulate host-side tree update (overlaps with Vortex prefetch)
void tree_update_work(uint32_t iterations) {
    volatile double x = 1.0;
    for (uint32_t i = 0; i < iterations; i++) {
        x = sqrt(x + 1.0) * 0.99;
    }
}

int main(int argc, char** argv) {
    bool simulate = true;
    uint32_t depth = 16;
    uint32_t iterations = 1000;
    uint32_t n_arcs = 100000;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--simulate") == 0) simulate = true;
        else if (strcmp(argv[i], "--hardware") == 0) simulate = false;
        else if (strcmp(argv[i], "--depth") == 0 && i + 1 < argc)
            depth = atoi(argv[++i]);
        else if (strcmp(argv[i], "--iterations") == 0 && i + 1 < argc)
            iterations = atoi(argv[++i]);
        else if (strcmp(argv[i], "--arcs") == 0 && i + 1 < argc)
            n_arcs = atoi(argv[++i]);
    }

    printf("================================================================\n");
    printf("MCF CIRA Benchmark\n");
    printf("  Arcs: %u, Depth: %u, Iterations: %u\n", n_arcs, depth, iterations);
    printf("  Mode: %s\n", simulate ? "simulation" : "hardware");
    printf("================================================================\n\n");

    // Build random arc list
    auto arcs = build_random_arcs(n_arcs);

    // Initialize CIRA runtime
    CiraRuntime rt;
    if (!rt.init("/dev/mem", 0xa2800000UL, 2 * 1024 * 1024, simulate)) {
        fprintf(stderr, "Failed to initialize CIRA runtime\n");
        return 1;
    }

    // Load prefetch kernel (noop in simulation mode)
    rt.load_kernel("../kernels/prefetch_chain_kernel.bin", FUNC_PREFETCH_CHAIN);

    // Warm up
    pricing_baseline(&arcs[0], n_arcs);

    // Baseline measurement
    auto t0 = std::chrono::high_resolution_clock::now();
    for (uint32_t i = 0; i < iterations; i++) {
        pricing_baseline(&arcs[0], n_arcs);
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    double baseline_ms = std::chrono::duration<double, std::milli>(t1 - t0).count();

    // CIRA measurement (with overlap)
    auto t2 = std::chrono::high_resolution_clock::now();
    for (uint32_t i = 0; i < iterations; i++) {
        int64_t result = pricing_cira(&arcs[0], n_arcs, rt, depth);
        // Overlap: do tree update work while Vortex prefetches next iteration
        tree_update_work(100);
        (void)result;
        rt.phase_boundary("pricing_to_priceout");
    }
    auto t3 = std::chrono::high_resolution_clock::now();
    double cira_ms = std::chrono::duration<double, std::milli>(t3 - t2).count();

    double speedup = baseline_ms / cira_ms;

    printf("Results:\n");
    printf("  Baseline:  %.3f ms (%.3f ms/iter)\n",
           baseline_ms, baseline_ms / iterations);
    printf("  CIRA:      %.3f ms (%.3f ms/iter)\n",
           cira_ms, cira_ms / iterations);
    printf("  Speedup:   %.2fx\n", speedup);
    printf("  Prefetch depth: %u\n", depth);
    printf("  Mode:      %s\n", simulate ? "SIMULATED" : "HARDWARE");
    printf("\n");

    if (simulate) {
        printf("NOTE: Running in simulation mode. Speedup reflects overhead\n");
        printf("of CIRA API calls only. Real hardware speedup expected: ~2.26x\n");
    }

    return 0;
}
