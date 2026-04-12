/**
 * cira_profiler.cpp
 *
 * PMU-based profiler using Linux perf_event_open.
 * JSON output for consumption by Pass 2 compiler passes.
 */

#include "cira_profiler.h"
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/perf_event.h>
#include <sys/syscall.h>

namespace cira::profiling {

CiraProfiler::CiraProfiler() = default;
CiraProfiler::~CiraProfiler() = default;

static int perf_event_open(struct perf_event_attr* attr, pid_t pid,
                           int cpu, int group_fd, unsigned long flags) {
    return syscall(__NR_perf_event_open, attr, pid, cpu, group_fd, flags);
}

int CiraProfiler::open_perf_counter(uint32_t type, uint64_t config) {
    struct perf_event_attr pe = {};
    pe.type = type;
    pe.size = sizeof(pe);
    pe.config = config;
    pe.disabled = 1;
    pe.exclude_kernel = 1;
    pe.exclude_hv = 1;

    int fd = perf_event_open(&pe, 0, -1, -1, 0);
    if (fd < 0) {
        // Non-fatal: PMU may not be available (e.g., in VM)
        return -1;
    }
    return fd;
}

uint64_t CiraProfiler::read_perf_counter(int fd) {
    if (fd < 0) return 0;
    uint64_t val = 0;
    read(fd, &val, sizeof(val));
    return val;
}

void CiraProfiler::close_perf_counter(int fd) {
    if (fd >= 0) close(fd);
}

void CiraProfiler::begin_region(const std::string& name) {
    TimerState ts;
    ts.start = std::chrono::high_resolution_clock::now();
    ts.perf_fd_cycles = open_perf_counter(PERF_TYPE_HARDWARE, PERF_COUNT_HW_CPU_CYCLES);
    ts.perf_fd_instructions = open_perf_counter(PERF_TYPE_HARDWARE, PERF_COUNT_HW_INSTRUCTIONS);
    ts.perf_fd_llc_misses = open_perf_counter(PERF_TYPE_HARDWARE, PERF_COUNT_HW_CACHE_MISSES);
    ts.perf_fd_llc_refs = open_perf_counter(PERF_TYPE_HARDWARE, PERF_COUNT_HW_CACHE_REFERENCES);
    ts.perf_fd_stalls = open_perf_counter(PERF_TYPE_HARDWARE, PERF_COUNT_HW_STALLED_CYCLES_BACKEND);

    // Enable and reset all counters
    int fds[] = {ts.perf_fd_cycles, ts.perf_fd_instructions,
                 ts.perf_fd_llc_misses, ts.perf_fd_llc_refs, ts.perf_fd_stalls};
    for (int fd : fds) {
        if (fd >= 0) {
            ioctl(fd, PERF_EVENT_IOC_RESET, 0);
            ioctl(fd, PERF_EVENT_IOC_ENABLE, 0);
        }
    }

    active_[name] = ts;
}

void CiraProfiler::end_region(const std::string& name) {
    auto it = active_.find(name);
    if (it == active_.end()) return;

    auto& ts = it->second;
    auto end = std::chrono::high_resolution_clock::now();

    // Disable counters
    int fds[] = {ts.perf_fd_cycles, ts.perf_fd_instructions,
                 ts.perf_fd_llc_misses, ts.perf_fd_llc_refs, ts.perf_fd_stalls};
    for (int fd : fds) {
        if (fd >= 0) ioctl(fd, PERF_EVENT_IOC_DISABLE, 0);
    }

    RegionProfile rp;
    rp.name = name;
    rp.wall_time_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(
        end - ts.start).count();
    rp.cpu_cycles = read_perf_counter(ts.perf_fd_cycles);
    rp.instructions = read_perf_counter(ts.perf_fd_instructions);
    rp.llc_misses = read_perf_counter(ts.perf_fd_llc_misses);
    rp.llc_refs = read_perf_counter(ts.perf_fd_llc_refs);
    rp.stall_cycles = read_perf_counter(ts.perf_fd_stalls);
    rp.branch_misses = 0;

    rp.ipc = (rp.cpu_cycles > 0) ? (double)rp.instructions / rp.cpu_cycles : 0.0;
    rp.cache_hit_rate = (rp.llc_refs > 0)
        ? 1.0 - (double)rp.llc_misses / rp.llc_refs : 1.0;
    rp.memory_bound_pct = (rp.cpu_cycles > 0)
        ? (double)rp.stall_cycles / rp.cpu_cycles * 100.0 : 0.0;

    // Heuristic: estimate chain depth from CPI and stall ratio
    double cpi = (rp.instructions > 0) ? (double)rp.cpu_cycles / rp.instructions : 1.0;
    if (cpi > 2.0 && rp.memory_bound_pct > 50.0) {
        rp.chain_depth = (uint32_t)(cpi * 4);  // Rough heuristic
        rp.is_offloadable = true;
    } else if (rp.memory_bound_pct > 30.0) {
        rp.chain_depth = 8;
        rp.is_offloadable = true;
    } else {
        rp.chain_depth = 0;
        rp.is_offloadable = false;
    }

    regions_[name] = rp;

    // Cleanup
    for (int fd : fds) close_perf_counter(fd);
    active_.erase(it);
}

bool CiraProfiler::save(const std::string& path) const {
    FILE* f = fopen(path.c_str(), "w");
    if (!f) return false;

    fprintf(f, "{\n  \"regions\": [\n");
    bool first = true;
    for (auto& [name, rp] : regions_) {
        if (!first) fprintf(f, ",\n");
        first = false;
        fprintf(f,
            "    {\n"
            "      \"name\": \"%s\",\n"
            "      \"wall_time_ns\": %lu,\n"
            "      \"cpu_cycles\": %lu,\n"
            "      \"instructions\": %lu,\n"
            "      \"llc_misses\": %lu,\n"
            "      \"llc_refs\": %lu,\n"
            "      \"stall_cycles\": %lu,\n"
            "      \"ipc\": %.3f,\n"
            "      \"cache_hit_rate\": %.3f,\n"
            "      \"memory_bound_pct\": %.1f,\n"
            "      \"chain_depth\": %u,\n"
            "      \"is_offloadable\": %s\n"
            "    }",
            rp.name.c_str(), rp.wall_time_ns, rp.cpu_cycles,
            rp.instructions, rp.llc_misses, rp.llc_refs,
            rp.stall_cycles, rp.ipc, rp.cache_hit_rate,
            rp.memory_bound_pct, rp.chain_depth,
            rp.is_offloadable ? "true" : "false");
    }
    fprintf(f, "\n  ]\n}\n");
    fclose(f);
    return true;
}

bool CiraProfiler::load(const std::string& path) {
    // Simple JSON parser for our known format
    FILE* f = fopen(path.c_str(), "r");
    if (!f) return false;

    char buf[16384];
    size_t n = fread(buf, 1, sizeof(buf) - 1, f);
    fclose(f);
    buf[n] = '\0';

    // Parse regions using sscanf (sufficient for our structured output)
    const char* p = buf;
    while ((p = strstr(p, "\"name\"")) != nullptr) {
        RegionProfile rp;
        char name_buf[256];
        if (sscanf(p, "\"name\": \"%255[^\"]\"", name_buf) == 1) {
            rp.name = name_buf;
        }
        p++;

        auto extract = [&](const char* key, uint64_t& val) {
            const char* k = strstr(p, key);
            if (k) sscanf(k + strlen(key) + 2, "%lu", &val);
        };
        auto extractf = [&](const char* key, double& val) {
            const char* k = strstr(p, key);
            if (k) sscanf(k + strlen(key) + 2, "%lf", &val);
        };

        extract("\"wall_time_ns\"", rp.wall_time_ns);
        extract("\"cpu_cycles\"", rp.cpu_cycles);
        extract("\"instructions\"", rp.instructions);
        extract("\"llc_misses\"", rp.llc_misses);
        extract("\"llc_refs\"", rp.llc_refs);
        extract("\"stall_cycles\"", rp.stall_cycles);
        extractf("\"ipc\"", rp.ipc);
        extractf("\"cache_hit_rate\"", rp.cache_hit_rate);
        extractf("\"memory_bound_pct\"", rp.memory_bound_pct);

        uint64_t cd = 0;
        extract("\"chain_depth\"", cd);
        rp.chain_depth = (uint32_t)cd;

        rp.is_offloadable = (strstr(p, "\"is_offloadable\": true") != nullptr);

        regions_[rp.name] = rp;
    }

    return !regions_.empty();
}

const RegionProfile* CiraProfiler::get_region(const std::string& name) const {
    auto it = regions_.find(name);
    return (it != regions_.end()) ? &it->second : nullptr;
}

std::vector<OffloadDecision> CiraProfiler::analyze(double cxl_latency_ns,
                                                    double llc_latency_ns,
                                                    double sync_overhead_ns) const {
    std::vector<OffloadDecision> decisions;

    for (auto& [name, rp] : regions_) {
        OffloadDecision d;
        d.region_name = name;
        d.sync_overhead_ns = sync_overhead_ns;

        double per_step_saving = cxl_latency_ns - llc_latency_ns;
        d.latency_saving_ns = per_step_saving;

        // Cost model from paper Equation 1:
        // Gain = sum(L_CXL - L_LLC) - (C_sync + C_vortex_busy)
        double gain = rp.chain_depth * per_step_saving - sync_overhead_ns;

        d.should_offload = rp.is_offloadable && (gain > 0);
        d.prefetch_depth = rp.chain_depth;

        if (d.should_offload && rp.wall_time_ns > 0) {
            double hidden_ns = rp.chain_depth * per_step_saving;
            d.estimated_speedup = (double)rp.wall_time_ns /
                                  (rp.wall_time_ns - hidden_ns + sync_overhead_ns);
        } else {
            d.estimated_speedup = 1.0;
        }

        decisions.push_back(d);
    }

    return decisions;
}

}  // namespace cira::profiling
