#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    volatile uint32_t* bar0 = (volatile uint32_t*)mmap(nullptr, 0x200000, 
                                                        PROT_READ | PROT_WRITE,
                                                        MAP_SHARED, fd, 0xa2800000UL);
    
    printf("PIO Bridge Diagnostics\n");
    printf("=======================\n\n");
    
    // CXL Device registers might have status bits
    printf("CXL Device Status (BAR0+0x180000): 0x%08x\n", bar0[0x180000/4]);
    printf("CXL Device Status+4 (BAR0+0x180004): 0x%08x\n", bar0[0x180004/4]);
    
    // Try reading BAR0+0x151F00 (HDM Decoder - should be accessible)
    printf("HDM Decoder Register (BAR0+0x151F00): 0x%08x\n", bar0[0x151F00/4]);
    
    // The issue: GPU CSR at 0x080000 returns 0
    printf("\nGPU CSR Issue:\n");
    printf("GPU CSR at 0x080000 (should be accessible): 0x%08x\n", bar0[0x080000/4]);
    
    // Check if GPU CSR area is just not responding at all
    printf("\nTrying multiple GPU CSR reads:\n");
    for (int i = 0; i < 5; i++) {
        uint32_t val = bar0[0x080000/4];
        printf("  Read %d: 0x%08x\n", i+1, val);
        usleep(100);
    }
    
    printf("\nChecking if CXL CSR bridge is responding at all...\n");
    // Try to write to PF1 BAR2 CSR space (should be different path)
    printf("BAR2 area (if mapped): would be at different physical address\n");
    
    munmap((void*)bar0, 0x200000);
    close(fd);
    return 0;
}
