#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>

int main() {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    volatile uint32_t* bar0 = (volatile uint32_t*)mmap(nullptr, 0x200000, 
                                                        PROT_READ | PROT_WRITE,
                                                        MAP_SHARED, fd, 0xa2800000UL);
    
    printf("GPU CSR Write Test\n");
    printf("==================\n\n");
    
    // Test 1: Try to write a distinctive value
    printf("Test 1: Write 0x12345678 to GPU CSR register\n");
    bar0[0x080100/4] = 0x12345678;
    usleep(200);
    uint32_t read1 = bar0[0x080100/4];
    printf("  Wrote: 0x12345678\n");
    printf("  Read back: 0x%08x\n\n", read1);
    
    // Test 2: Try a different register
    printf("Test 2: Write 0xABCDEF00 to different GPU CSR register\n");
    bar0[0x080110/4] = 0xABCDEF00;
    usleep(200);
    uint32_t read2 = bar0[0x080110/4];
    printf("  Wrote: 0xABCDEF00\n");
    printf("  Read back: 0x%08x\n\n", read2);
    
    // Test 3: Check if writes are actually going somewhere
    printf("Test 3: Read different GPU CSR addresses\n");
    printf("  0x080000: 0x%08x\n", bar0[0x080000/4]);
    printf("  0x080004: 0x%08x\n", bar0[0x080004/4]);
    printf("  0x080008: 0x%08x\n", bar0[0x080008/4]);
    printf("  0x080100: 0x%08x (should be 0x12345678 if writes work)\n", bar0[0x080100/4]);
    printf("  0x080110: 0x%08x (should be 0xABCDEF00 if writes work)\n\n", bar0[0x080110/4]);
    
    // Test 4: Is the address reaching the GPU at all?
    printf("Test 4: Check CXL Device register to confirm PIO path works\n");
    printf("  0x180000: 0x%08x (CXL Device - should be nonzero)\n", bar0[0x180000/4]);
    
    munmap((void*)bar0, 0x200000);
    close(fd);
    return 0;
}
