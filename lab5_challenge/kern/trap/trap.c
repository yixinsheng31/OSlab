#include <defs.h>
#include <mmu.h>
#include <memlayout.h>
#include <clock.h>
#include <trap.h>
#include <riscv.h>
#include <stdio.h>
#include <assert.h>
#include <console.h>
#include <vmm.h>
#include <kdebug.h>
#include <unistd.h>
#include <syscall.h>
#include <error.h>
#include <sched.h>
#include <sync.h>
#include <sbi.h>
#include <pmm.h>      // 提供 get_pte, page_insert, page_remove 等
#include <string.h>   // 提供 memcpy

#define TICK_NUM 100

static void print_ticks()
{
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf)
{
    return (tf->status & SSTATUS_SPP) != 0;
}

void print_trapframe(struct trapframe *tf)
{
    cprintf("trapframe at %p\n", tf);
    // cprintf("trapframe at 0x%x\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08x\n", tf->status);
    cprintf("  epc      0x%08x\n", tf->epc);
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
    cprintf("  ra       0x%08x\n", gpr->ra);
    cprintf("  sp       0x%08x\n", gpr->sp);
    cprintf("  gp       0x%08x\n", gpr->gp);
    cprintf("  tp       0x%08x\n", gpr->tp);
    cprintf("  t0       0x%08x\n", gpr->t0);
    cprintf("  t1       0x%08x\n", gpr->t1);
    cprintf("  t2       0x%08x\n", gpr->t2);
    cprintf("  s0       0x%08x\n", gpr->s0);
    cprintf("  s1       0x%08x\n", gpr->s1);
    cprintf("  a0       0x%08x\n", gpr->a0);
    cprintf("  a1       0x%08x\n", gpr->a1);
    cprintf("  a2       0x%08x\n", gpr->a2);
    cprintf("  a3       0x%08x\n", gpr->a3);
    cprintf("  a4       0x%08x\n", gpr->a4);
    cprintf("  a5       0x%08x\n", gpr->a5);
    cprintf("  a6       0x%08x\n", gpr->a6);
    cprintf("  a7       0x%08x\n", gpr->a7);
    cprintf("  s2       0x%08x\n", gpr->s2);
    cprintf("  s3       0x%08x\n", gpr->s3);
    cprintf("  s4       0x%08x\n", gpr->s4);
    cprintf("  s5       0x%08x\n", gpr->s5);
    cprintf("  s6       0x%08x\n", gpr->s6);
    cprintf("  s7       0x%08x\n", gpr->s7);
    cprintf("  s8       0x%08x\n", gpr->s8);
    cprintf("  s9       0x%08x\n", gpr->s9);
    cprintf("  s10      0x%08x\n", gpr->s10);
    cprintf("  s11      0x%08x\n", gpr->s11);
    cprintf("  t3       0x%08x\n", gpr->t3);
    cprintf("  t4       0x%08x\n", gpr->t4);
    cprintf("  t5       0x%08x\n", gpr->t5);
    cprintf("  t6       0x%08x\n", gpr->t6);
}

extern struct mm_struct *check_mm_struct;

/* handle_cow_fault - 处理Copy-on-Write页面错误
 * 当进程尝试写入标记为COW的页面时，需要根据引用计数决定是直接恢复写权限还是复制页面
 */
static int handle_cow_fault(struct mm_struct *mm, uintptr_t fault_addr);

/* pgfault_handler - 统一的页面错误处理入口
 * 检查是否是COW相关的页面错误，如果是则调用专门的COW处理函数
 */
static int pgfault_handler(struct trapframe *tf) {
    uintptr_t fault_addr = tf->tval;
    uint32_t cause = tf->cause;
    
    // 基本检查：确保在用户态且有有效的内存管理结构
    if (current == NULL || current->mm == NULL) {
        print_trapframe(tf);
        panic("page fault in kernel!");
    }
    
    // 获取页表项，检查是否是COW页面错误
    pde_t *pgdir = current->mm->pgdir;
    pte_t *ptep = get_pte(pgdir, fault_addr, 0);
    
    // 判断是否为COW页面且是写操作导致的错误
    if (ptep != NULL && (*ptep & PTE_V) && (*ptep & PTE_COW)) {
        if (cause == CAUSE_STORE_PAGE_FAULT) {
            return handle_cow_fault(current->mm, fault_addr);
        }
    }
    
    // 其他类型的页面错误，输出错误信息
    cprintf("page fault at 0x%08x: %c/%c\n", fault_addr,
            (cause == CAUSE_LOAD_PAGE_FAULT) ? 'R' : 'W',
            (tf->status & SSTATUS_SPP) ? 'K' : 'U');
    
    return -E_INVAL;
}

/* handle_cow_fault - 实现Copy-on-Write的核心逻辑
 * 策略：
 *   1. 如果页面引用计数为1，说明其他进程已经完成复制，直接恢复写权限
 *   2. 如果引用计数>1，需要分配新页面并复制内容，然后更新页表项
 */
static int handle_cow_fault(struct mm_struct *mm, uintptr_t fault_addr) {
    uintptr_t page_addr = ROUNDDOWN(fault_addr, PGSIZE);
    pte_t *ptep = get_pte(mm->pgdir, page_addr, 0);
    
    // 验证页表项有效性
    if (ptep == NULL || !(*ptep & PTE_V)) {
        return -E_INVAL;
    }
    
    pte_t current_pte = *ptep;
    struct Page *shared_page = pte2page(current_pte);
    int page_refs = page_ref(shared_page);
    
    // 情况1：页面只被当前进程引用，可以直接获得写权限
    if (page_refs == 1) {
        // 清除COW标记，恢复写权限
        *ptep = (current_pte | PTE_W) & ~PTE_COW;
        
        // 刷新TLB以确保更改生效
        asm volatile("sfence.vma zero, %0" :: "r"(page_addr) : "memory");
        asm volatile("fence" ::: "memory");
        
        return 0;
    }
    
    // 情况2：页面被多个进程共享，需要复制
    struct Page *copied_page = alloc_page();
    if (copied_page == NULL) {
        return -E_NO_MEM;
    }
    
    // 执行页面内容复制
    void *src = (void*)page2kva(shared_page);
    void *dst = (void*)page2kva(copied_page);
    memcpy(dst, src, PGSIZE);
    
    // 更新引用计数：原页面减少，新页面设置为1
    page_ref_dec(shared_page);
    set_page_ref(copied_page, 1);
    
    // 构建新的页表项：保留原有权限（用户、读、执行），添加写权限，清除COW标记
    uint32_t page_perm = (current_pte & (PTE_U | PTE_R | PTE_X)) | PTE_W;
    *ptep = pte_create(page2ppn(copied_page), PTE_V | page_perm);
    
    // 刷新TLB
    asm volatile("sfence.vma zero, %0" :: "r"(page_addr) : "memory");
    asm volatile("fence" ::: "memory");
    
    return 0;
}

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
    {
    case IRQ_U_SOFT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
        break;
    case IRQ_U_TIMER:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_TIMER:
        /* LAB5 GRADE   YOUR CODE :  */
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
        ticks++;
        /* reschedule promptly so long-running user code (e.g., spin) yields */
        if (current) {
            current->need_resched = 1;
        }
        /* keep periodic heartbeat output */
        if (ticks % TICK_NUM == 0) {
            print_ticks();
        }
        break;
    case IRQ_H_TIMER:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_TIMER:
        cprintf("Machine software interrupt\n");
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
        break;
    case IRQ_H_EXT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_EXT:
        cprintf("Machine software interrupt\n");
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
    {
    case CAUSE_MISALIGNED_FETCH:
        cprintf("Instruction address misaligned\n");
        break;
    case CAUSE_FETCH_ACCESS:
        cprintf("Instruction access fault\n");
        break;
    case CAUSE_ILLEGAL_INSTRUCTION:
        cprintf("Illegal instruction\n");
        break;
    case CAUSE_BREAKPOINT:
        cprintf("Breakpoint\n");
        if (tf->gpr.a7 == 10)
        {
            tf->epc += 4;
            syscall();
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
        }
        break;
    case CAUSE_MISALIGNED_LOAD:
        cprintf("Load address misaligned\n");
        break;
    case CAUSE_LOAD_ACCESS:
        cprintf("Load access fault\n");
        break;
    case CAUSE_MISALIGNED_STORE:
        panic("AMO address misaligned\n");
        break;
    case CAUSE_STORE_ACCESS:
        cprintf("Store/AMO access fault\n");
        break;
    case CAUSE_USER_ECALL:
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_HYPERVISOR_ECALL:
        cprintf("Environment call from H-mode\n");
        break;
    case CAUSE_MACHINE_ECALL:
        cprintf("Environment call from M-mode\n");
        break;
    case CAUSE_FETCH_PAGE_FAULT:
        // cprintf("Instruction page fault\n");
        if ((ret = pgfault_handler(tf)) != 0) {
            cprintf("Instruction page fault\n");
            print_trapframe(tf);
            if (current != NULL) {
                do_exit(-E_KILLED);
            } else {
                panic("kernel page fault");
            }
        }
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        // cprintf("Load page fault\n");
        if ((ret = pgfault_handler(tf)) != 0) {
            cprintf("Load page fault\n");
            print_trapframe(tf);
            if (current != NULL) {
                do_exit(-E_KILLED);
            } else {
                panic("kernel page fault");
            }
        }
        break;
    case CAUSE_STORE_PAGE_FAULT:
        // cprintf("Store/AMO page fault\n");
        if ((ret = pgfault_handler(tf)) != 0) {
            cprintf("Store/AMO page fault\n");
            print_trapframe(tf);
            if (current != NULL) {
                do_exit(-E_KILLED);
            } else {
                panic("kernel page fault");
            }
        }
        break;
    default:
        print_trapframe(tf);
        break;
    }
}

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
    {
        // interrupts
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
    }
}

/* *
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
        current->tf = tf;

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
        if (!in_kernel)
        {
            if (current->flags & PF_EXITING)
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
            {
                schedule();
            }
        }
    }
}
