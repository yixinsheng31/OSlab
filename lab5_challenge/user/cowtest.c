/* user/cowtest.c
 * Copy-on-Write机制功能验证测试
 * 测试父子进程在fork后共享内存，子进程写入时触发COW的正确性
 */
#include <stdio.h>
#include <ulib.h>

#define ARRAY_LEN 10
#define INIT_MULTIPLIER 100
#define MODIFY_MULTIPLIER 200

/* 计算数组元素之和 */
static int sum(int arr[], int len) {
    int total = 0;
    for (int i = 0; i < len; i++) {
        total += arr[i];
    }
    return total;
}

/* 初始化测试数组 */
static void init_test_array(int arr[], int len, int multiplier) {
    for (int i = 0; i < len; i++) {
        arr[i] = i * multiplier;
    }
}

int main(void) {
    cprintf("COW Test Starting...\n");
    
    static int test_array[ARRAY_LEN];
    
    // 父进程初始化测试数据
    init_test_array(test_array, ARRAY_LEN, INIT_MULTIPLIER);
    cprintf("Parent: initialized data\n");
    
    int child_pid = fork();
    
    if (child_pid == 0) {
        // 子进程执行路径
        cprintf("Child: reading parent's data...\n");
        
        // 验证初始共享状态：子进程应该能读取到父进程的数据
        int initial_sum = sum(test_array, ARRAY_LEN);
        cprintf("Child: sum before write = %d\n", initial_sum);
        
        // 期望的初始和：0*100 + 1*100 + ... + 9*100 = 4500
        if (initial_sum != 4500) {
            cprintf("Child: ERROR - sum should be 4500\n");
            exit(-1);
        }
        
        // 执行写入操作，这应该触发COW机制
        cprintf("Child: writing data (trigger COW)...\n");
        init_test_array(test_array, ARRAY_LEN, MODIFY_MULTIPLIER);
        
        // 验证写入后的数据
        int modified_sum = sum(test_array, ARRAY_LEN);
        cprintf("Child: sum after write = %d\n", modified_sum);
        
        // 期望的修改后和：0*200 + 1*200 + ... + 9*200 = 9000
        if (modified_sum != 9000) {
            cprintf("Child: ERROR - sum should be 9000\n");
            exit(-2);
        }
        
        exit(0);
        
    } else if (child_pid > 0) {
        // 父进程执行路径
        int child_status = 0;
        waitpid(child_pid, &child_status);
        
        if (child_status == 0) {
            cprintf("Child completed successfully\n");
        } else {
            cprintf("Child failed with code %d\n", child_status);
        }
        
        // 验证父进程的数据未被子进程修改
        cprintf("Parent: checking data after child...\n");
        int parent_sum = sum(test_array, ARRAY_LEN);
        cprintf("Parent: sum = %d (should be 4500)\n", parent_sum);
        
        // COW机制应保证父子进程数据独立
        if (parent_sum == 4500 && child_status == 0) {
            cprintf("COW Test PASSED!\n");
        } else {
            cprintf("COW Test FAILED!\n");
        }
        
    } else {
        cprintf("fork failed\n");
        return -1;
    }
    
    return 0;
}
