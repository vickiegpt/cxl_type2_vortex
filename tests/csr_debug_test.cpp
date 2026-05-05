#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

// PCI config offsets
#define PCI_CONFIG_BAR0_LO  0x10
#define PCI_CONFIG_BAR0_HI  0x14

int main() {
    int mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem_fd < 0) {
        perror("open /dev/mem");
        return 1;
    }

    // First check PCI config space
    printf("Checking PCI configuration...\n");
    volatile uint8_t* pci_config = (volatile uint8_t*)mmap(nullptr, 0x1000,
                                                            PROT_READ | PROT_WRITE,
                                                            MAP_SHARED, mem_fd, 0xcf800000 + (0x3b << 15));
    if (pci_config != MAP_FAILED) {
        uint32_t bar0_lo = *(volatile uint32_t*)(pci_config + PCI_CONFIG_BAR0_LO);
        uint32_t bar0_hi = *(volatile uint32_t*)(pci_config + PCI_CONFIG_BAR0_HI);
        printf("BAR0 from PCI config: 0x%08x_%08x\n", bar0_hi, bar0_lo);
        munmap((void*)pci_config, 0x1000);
    }

    // Map BAR0 directly
    volatile uint32_t* bar0 = (volatile uint32_t*)mmap(nullptr, 0x200000,
                                                        PROT_READ | PROT_WRITE,
                                                        MAP_SHARED, mem_fd, 0xa2800000UL);
    if (bar0 == MAP_FAILED) {
        perror("mmap BAR0");
        return 1;
    }

    printf("\nTesting GPU CSR path...\n");
    printf("======================\n\n");

    // CXL Component Registers at BAR0+0x150000
    volatile uint32_t* cxl_comp = bar0 + 0x150000/4;
    printf("CXL Component Register: 0x%08x\n", cxl_comp[0]);

    // Try to read a simple register first
    volatile uint32_t* csr_base = bar0 + 0x080000/4;
    
    printf("\nDirect PIO reads (no CSR handshake):\n");
    printf("BAR0+0x000000: 0x%08x\n", bar0[0]);
    printf("BAR0+0x150000: 0x%08x\n", cxl_comp[0]);
    
    // Check if GPU is responding at all
    printf("\nGPU CSR Status Register (0x080000):\n");
    uint32_t gpu_status = csr_base[0];
    printf("  Read: 0x%08x\n", gpu_status);
    
    // Check if GPU CSR is at all accessible
    printf("\nGPU CSR Identity Register (should be nonzero):\n");
    uint32_t gpu_id = csr_base[0x00/4];
    printf("  0x080000: 0x%08x\n", gpu_id);

    printf("\nAttempting simple CSR write...\n");
    csr_base[0x100/4] = 0xCAFEBABE;
    printf("  Wrote 0xCAFEBABE to 0x080100\n");
    usleep(500);
    uint32_t read_back = csr_base[0x100/4];
    printf("  Read back: 0x%08x\n", read_back);
    printf("  Status: %s\n", read_back == 0xCAFEBABE ? "PASS" : "FAIL");

    munmap((void*)bar0, 0x200000);
    close(mem_fd);
    return 0;
}
