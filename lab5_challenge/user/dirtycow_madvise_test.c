/* user/dirtycow_madvise_test.c
 * 测试 madvise(MADV_DONTNEED) 与 COW 的竞态条件
 */
#include <stdio.h>
#include <ulib.h>
#include <string.h>
#include <unistd.h>

#define PAGE_SIZE 4096
#define INIT_STRING "ORIGINAL DATA"

int main(void) {
    cprintf("DirtyCOW + madvise Race Condition Test\n");
    
    static char test_buffer[PAGE_SIZE];
    const char *original = INIT_STRING;
    for (int i = 0; original[i] != '\0'; i++) {
        test_buffer[i] = original[i];
    }
    test_buffer[strlen(original)] = '\0';
    
    cprintf("Parent: initialized data = \"%s\"\n", test_buffer);
    
    int child_pid = fork();
    
    if (child_pid == 0) {
        // 子进程1：不断调用 madvise(MADV_DONTNEED)
        cprintf("Child (madvise): starting madvise loop...\n");
        for (int i = 0; i < 1000; i++) {
            madvise(test_buffer, PAGE_SIZE, MADV_DONTNEED);
            yield();
        }
        cprintf("Child (madvise): completed 1000 madvise calls\n");
        exit(0);
    } else if (child_pid > 0) {
        // 父进程：创建第二个子进程触发 COW
        int child2_pid = fork();
        
        if (child2_pid == 0) {
            // 子进程2：触发 COW
            cprintf("Child (COW): starting COW writes...\n");
            for (int i = 0; i < 1000; i++) {
                test_buffer[0] = 'M';
                yield();
            }
            cprintf("Child (COW): completed 1000 writes\n");
            if (test_buffer[0] == 'M') {
                cprintf("Child (COW): data modified successfully\n");
            }
            exit(0);
        } else if (child2_pid > 0) {
            // 父进程：等待两个子进程完成
            cprintf("Parent: waiting for children...\n");
            int status1 = 0, status2 = 0;
            waitpid(child_pid, &status1);
            waitpid(child2_pid, &status2);
            
            cprintf("Parent: checking data integrity...\n");
            cprintf("Parent: current data = \"%s\"\n", test_buffer);
            
            int is_corrupted = 0;
            for (int i = 0; original[i] != '\0'; i++) {
                if (test_buffer[i] != original[i]) {
                    is_corrupted = 1;
                    cprintf("Parent: ERROR - data[%d] changed\n", i);
                    break;
                }
            }
            
            if (is_corrupted) {
                cprintf("VULNERABILITY DETECTED: Data corrupted!\n");
                return -1;
            } else {
                cprintf("SECURITY CHECK PASSED: Data intact\n");
                return 0;
            }
        }
    }
    return 0;
}
