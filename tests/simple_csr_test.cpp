#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

int main() {
    int mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem_fd < 0) {
        perror("open /dev/mem");
        return 1;
    }

    volatile uint32_t* bar0 = (volatile uint32_t*)mmap(nullptr, 0x200000,
                                                        PROT_READ | PROT_WRITE,
                                                        MAP_SHARED, mem_fd, 0xa2800000UL);
    if (bar0 == MAP_FAILED) {
        perror("mmap");
        return 1;
    }

    printf("Testing GPU CSR read/write at BAR0+0x180100 (CXL Device Region)\n");
    printf("==============================================================\n\n");

    // CSR base is at BAR0+0x180100 (within CXL Device Registers region)
    // Remapped internally to 0x000100 where GPU CSR registers are defined
    volatile uint32_t* gpu_csr = bar0 + 0x180100/4;

    // Test 1: Read GPU status (offset 0x00)
    uint32_t status = gpu_csr[0x00/4];
    printf("GPU Status (0x080000): 0x%08x\n", status);

    // Test 2: Write to kernel entry point (offset 0x100)
    printf("\nTest: Write kernel entry point\n");
    uint32_t write_val = 0xDEADBEEF;
    gpu_csr[0x100/4] = write_val;
    printf("  Wrote: 0x%08x to 0x080100\n", write_val);
    
    usleep(100); // Small delay
    
    uint32_t read_val = gpu_csr[0x100/4];
    printf("  Read:  0x%08x from 0x080100\n", read_val);
    printf("  Match: %s\n", (read_val == write_val) ? "YES ✓" : "NO ✗");

    // Test 3: Write to grid_x (offset 0x110)
    printf("\nTest: Write grid_x\n");
    write_val = 0x12345678;
    gpu_csr[0x110/4] = write_val;
    printf("  Wrote: 0x%08x to 0x080110\n", write_val);
    
    usleep(100);
    
    read_val = gpu_csr[0x110/4];
    printf("  Read:  0x%08x from 0x080110\n", read_val);
    printf("  Match: %s\n", (read_val == write_val) ? "YES ✓" : "NO ✗");

    // Test 4: Multiple writes to same register
    printf("\nTest: Multiple writes to kernel entry point\n");
    for (int i = 0; i < 3; i++) {
        write_val = 0x80000000 + (i * 0x100000);
        gpu_csr[0x100/4] = write_val;
        usleep(50);
        read_val = gpu_csr[0x100/4];
        printf("  Write 0x%08x, Read 0x%08x %s\n", write_val, read_val, 
               (read_val == write_val) ? "✓" : "✗");
    }

    munmap((void*)bar0, 0x200000);
    close(mem_fd);
    return 0;
}
