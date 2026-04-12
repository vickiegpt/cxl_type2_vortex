/**
 * cira_profiler.h
 *
 * Two-pass profiling infrastructure for CIRA.
 *
 * Pass 1: Native x86 execution with PMU sampling.
 *   - Collects per-region: wall time, LLC misses, stall cycles, IPC
 *   - Outputs profile.json consumed by Pass 2 compiler passes
 *
 * Pass 2: cira-twopass-timing reads profile.json and annotates
 *   cira.offload regions with timing, prefetch depth, H2D/D2H decisions.
 */

#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <map>
#include <chrono>

namespace cira::profiling {

/**
 * Per-region profiling metrics collected during Pass 1.
 */
struct RegionProfile {
    std::string name;           // Region/function identifier
    uint64_t wall_time_ns;      // Wall-clock time
    uint64_t cpu_cycles;        // Total CPU cycles
    uint64_t instructions;      // Retired instructions
    uint64_t llc_misses;        // Last-level cache misses
    uint64_t llc_refs;          // LLC references
    uint64_t stall_cycles;      // Backend stall cycles
    uint64_t branch_misses;     // Branch mispredictions
    uint32_t chain_depth;       // Estimated dependent load chain depth
    double ipc;                 // Instructions per cycle
    double cache_hit_rate;      // LLC hit rate (0.0 - 1.0)
    double memory_bound_pct;    // Fraction of slots that are memory-bound
    bool is_offloadable;        // Whether this region should be offloaded
};

/**
 * Offload decision produced by the cost model.
 */
struct OffloadDecision {
    std::string region_name;
    bool should_offload;
    uint32_t prefetch_depth;    // Optimal depth from profiling
    double estimated_speedup;
    double sync_overhead_ns;    // Cost of host<->device sync
    double latency_saving_ns;   // Per-step latency hiding
};

/**
 * CiraProfiler — collects PMU data during Pass 1 execution.
 *
 * Usage:
 *   CiraProfiler prof;
 *   prof.begin_region("mcf_pricing");
 *   // ... execute pricing kernel ...
 *   prof.end_region("mcf_pricing");
 *   prof.save("profile.json");
 */
class CiraProfiler {
public:
    CiraProfiler();
    ~CiraProfiler();

    /** Start profiling a named code region */
    void begin_region(const std::string& name);

    /** End profiling a named code region */
    void end_region(const std::string& name);

    /** Save all profiles to a JSON file */
    bool save(const std::string& path) const;

    /** Load profiles from a JSON file (for Pass 2) */
    bool load(const std::string& path);

    /** Get profile for a specific region */
    const RegionProfile* get_region(const std::string& name) const;

    /** Run cost model on all regions and produce offload decisions */
    std::vector<OffloadDecision> analyze(double cxl_latency_ns = 165.0,
                                          double llc_latency_ns = 15.0,
                                          double sync_overhead_ns = 50.0) const;

    /** Get all region profiles */
    const std::map<std::string, RegionProfile>& regions() const { return regions_; }

private:
    struct TimerState {
        std::chrono::high_resolution_clock::time_point start;
        int perf_fd_cycles;      // perf_event file descriptor
        int perf_fd_llc_misses;
        int perf_fd_llc_refs;
        int perf_fd_stalls;
        int perf_fd_instructions;
    };

    std::map<std::string, RegionProfile> regions_;
    std::map<std::string, TimerState> active_;

    int open_perf_counter(uint32_t type, uint64_t config);
    uint64_t read_perf_counter(int fd);
    void close_perf_counter(int fd);
};

}  // namespace cira::profiling
