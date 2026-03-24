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
    
    printf("Testing BAR0 regions:\n");
    printf("====================\n\n");
    
    // Vendor CSR space
    printf("BAR0+0x000000 (Vendor CSR): 0x%08x\n", bar0[0x000000/4]);
    printf("BAR0+0x000004 (Vendor CSR): 0x%08x\n", bar0[0x000004/4]);
    printf("BAR0+0x000008 (Vendor CSR): 0x%08x\n", bar0[0x000008/4]);
    
    // PCIe mirror
    printf("\nBAR0+0x0E0000 (PCIe config): 0x%08x\n", bar0[0x0E0000/4]);
    printf("BAR0+0x0E0004 (PCIe config): 0x%08x\n", bar0[0x0E0004/4]);
    
    // CXL Component
    printf("\nBAR0+0x150000 (CXL Comp): 0x%08x\n", bar0[0x150000/4]);
    printf("BAR0+0x151000 (CXL Comp): 0x%08x\n", bar0[0x151000/4]);
    printf("BAR0+0x151F00 (HDM): 0x%08x\n", bar0[0x151F00/4]);
    
    // CXL Device
    printf("\nBAR0+0x180000 (CXL Dev): 0x%08x\n", bar0[0x180000/4]);
    
    // GPU CSR
    printf("\nBAR0+0x080000 (GPU CSR): 0x%08x\n", bar0[0x080000/4]);
    printf("BAR0+0x080004 (GPU CSR): 0x%08x\n", bar0[0x080004/4]);
    
    munmap((void*)bar0, 0x200000);
    close(fd);
    return 0;
}
