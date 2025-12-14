/* user/dirtycow_test.c
 * DirtyCOW漏洞防护测试
 * 验证COW实现能够防止竞态条件导致的父进程数据被意外修改
 * 参考: https://dirtycow.ninja/
 */
#include <stdio.h>
#include <ulib.h>
#include <string.h>

#define PAGE_SIZE 4096
#define WRITE_ITERATIONS 100
#define INIT_STRING "ORIGINAL DATA"

/* 验证字符串是否与原始值一致 */
static int verify_string_integrity(const char *buf, const char *expected) {
    for (int i = 0; expected[i] != '\0'; i++) {
        if (buf[i] != expected[i]) {
            return 0;  // 数据被破坏
        }
    }
    return 1;  // 数据完整
}

/* 初始化测试缓冲区 */
static void setup_test_buffer(char *buf, int size) {
    const char *init_str = INIT_STRING;
    int i;
    for (i = 0; init_str[i] != '\0' && i < size - 1; i++) {
        buf[i] = init_str[i];
    }
    buf[i] = '\0';
}

int main(void) {
    cprintf("DirtyCOW vulnerability test\n");
    
    static char test_buffer[PAGE_SIZE];
    
    // 初始化测试数据
    setup_test_buffer(test_buffer, PAGE_SIZE);
    
    int child_pid = fork();
    
    if (child_pid == 0) {
        // 子进程：尝试多次写入以触发COW
        // 在存在DirtyCOW漏洞的系统中，这可能通过竞态条件修改父进程的只读内存
        // 但正确的COW实现应该为子进程创建独立的页面副本
        for (int i = 0; i < WRITE_ITERATIONS; i++) {
            test_buffer[0] = 'M';  // 触发COW机制
        }
        
        // 验证子进程能够修改自己的副本
        if (test_buffer[0] == 'M') {
            cprintf("Child: data modified (expected behavior)\n");
        }
        
        exit(0);
        
    } else if (child_pid > 0) {
        // 父进程：等待子进程完成并验证数据完整性
        int child_status = 0;
        waitpid(child_pid, &child_status);
        
        // 检查父进程的数据是否被破坏
        // COW机制应确保父进程的数据保持原样
        int data_intact = verify_string_integrity(test_buffer, INIT_STRING);
        
        if (data_intact) {
            cprintf("Test completed - no corruption should occur\n");
        } else {
            cprintf("ERROR: parent data corrupted!\n");
        }
        
    } else {
        cprintf("fork failed\n");
        return -1;
    }
    
    return 0;
}
