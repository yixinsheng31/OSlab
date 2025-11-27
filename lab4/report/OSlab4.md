# 练习0：填写已有实验

本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。

# 练习1：分配并初始化一个进程控制块

> alloc\_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc\_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> * 请说明proc\_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

初始化过程如下：

首先把整个结构体清零,所有指针自动被设为 `NULL`，所有整数设为 0，这样就可以避免context和name置空较为麻烦的问题。

然后将一些值手动赋予初值，除了`pid`置为-1之外其余值都是在置0或空（`PROC_UNINIT`在proc.h中有初始化为0）。`pid`置为-1是因为此时进程并未真正被创建，用 -1 表示暂时还没有 pid，不会跟系统中已有进程冲突，后续会由 get\_pid()函数统一分配。

`struct context context`中context结构体代表上下文，定义如下：

可以看到它包含了返回地址 (`ra`)、栈顶指针 (`sp`) 和被调用者保存寄存器 (`s0` - `s11`)，用于保存和恢复线程/进程的执行状态，主要应用在上下文切换（例如线程调度）时。

`struct trapframe *tf` 中 trapframe 结构体代表陷入帧（Trap Frame），也称为中断/异常的上下文保存区，定义如下：

可以看到它包含了通用寄存器 (`struct pushregs gpr`)、状态寄存器 (`status`)、异常程序计数器 (`epc`)、错误虚拟地址 (`badvaddr`) 和异常原因 (`cause`)，用于在发生中断、异常或系统调用时，保存 CPU 的完整状态，以便在中断/异常处理结束后能准确恢复到被中断/异常前的执行点继续执行。

其中`struct pushregs` 包含了 RISC-V 架构下所有 32 个通用寄存器（除 `pc` 外）的值，用于在进入内核态（如中断/异常发生时）时，将用户态或前一个内核执行流的完整通用寄存器状态保存到内存中。

# 练习2：为新创建的内核线程分配资源

> 创建一个内核线程需要分配和设置好很多资源。kernel\_thread函数通过调用**do\_fork**函数完成具体内核线程的创建工作。do\_kernel函数会调用alloc\_proc函数来分配并初始化一个进程控制块，但alloc\_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do\_fork实际创建新的内核线程。do\_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do\_fork函数中的处理过程。它的大致执行步骤包括：
>
> * 调用alloc\_proc，首先获得一块用户信息块。
>
> * 为进程分配一个内核栈。
>
> * 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
>
> * 复制原进程上下文到新进程
>
> * 将新进程添加到进程列表
>
> * 唤醒新进程
>
> * 返回新进程号
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> * 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

## 实验目标

通过实现 `do_fork` 函数，完成内核线程的创建过程，掌握操作系统中进程管理的基本原理。

## 设计实现过程

`do_fork` 函数的实现主要包括以下步骤：

1. **调用 `alloc_proc`**：分配并初始化一个进程控制块（`proc_struct`）。

2. **调用 `setup_kstack`**：为子进程分配一个内核栈。

3. **调用 `copy_mm`**：根据 `clone_flags` 复制或共享内存管理信息（在当前实验中未实际实现）。

4. **调用 `copy_thread`**：设置子进程的 `trapframe` 和上下文。

5. **将子进程插入 `hash_list` 和 `proc_list`**：分配唯一的 PID，并将进程添加到进程列表中。

6. **调用 `wakeup_proc`**：将子进程状态设置为 `PROC_RUNNABLE`。

7. **返回子进程的 PID**：作为 `do_fork` 的返回值。

## 代码实现

以下是 `do_fork` 函数的核心代码：

```c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    copy_thread(proc, stack, tf);
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
        hash_proc(proc);
        list_add(&proc_list, &(proc->list_link));
        nr_process++;
    }
    local_intr_restore(intr_flag);
    wakeup_proc(proc);
    ret = proc->pid;
fork_out:
    return ret;
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

## 问题分析

### ucore 是否做到给每个新 fork 的线程一个唯一的 ID？

是的，ucore 能够为每个新 fork 的线程分配一个唯一的 ID。

#### 分析与理由

1. `get_pid` 函数通过遍历 `proc_list` 和 `hash_list`，确保分配的 PID 不与现有进程冲突。

2. 如果所有 PID 都被占用，`get_pid` 会从头开始重新分配，直到找到一个未被使用的 PID。

3. 这种机制保证了每个新创建的线程都有一个唯一的 PID。

## 实验总结

通过实现 `do_fork` 函数，我们深入理解了内核线程的创建过程，包括资源分配、上下文复制和进程管理等关键步骤。同时，通过分析 `get_pid` 函数的实现，我们验证了 ucore 能够为每个新线程分配唯一的 ID，从而确保了系统的稳定性和一致性。

# 练习3：编写proc\_run 函数

> proc\_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：
>
> * 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
>
> * 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
>
> * 切换当前进程为要运行的进程。
>
> * 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lsatp(unsigned int pgdir)`函数，可实现修改SATP寄存器值的功能。
>
> * 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
>
> * 允许中断。
>
> 请回答如下问题：
>
> * 在本实验的执行过程中，创建且运行了几个内核线程？
>
> 完成代码编写后，编译并运行代码：make qemu

## 代码实现

* 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。

  ```c
      if (proc != current)
      {...
  ```

* 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。

  ```c
          local_intr_save(intr_flag);
  ```

* 切换当前进程为要运行的进程。

  ```c
          prev = current;
          /* update bookkeeping for prev and new current */
          if (prev->state == PROC_RUNNING)
              prev->state = PROC_RUNNABLE;

          current = proc;
          proc->state = PROC_RUNNING;
          proc->runs++;
  ```

* 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lsatp(unsigned int pgdir)`函数，可实现修改SATP寄存器值的功能。

  ```c
          if (proc->pgdir != prev->pgdir)
          {
              lsatp(proc->pgdir);
          }
  ```

* 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。

  ```c
          switch_to(&prev->context, &proc->context);
  ```

* 允许中断。

  ```c
          local_intr_restore(intr_flag);
  ```

## 问题回答

* “在本实验的执行过程中，创建且运行了几个内核线程？”

* 答：创建且运行了两个：一个是“第0个”，即idleproc，在所有CPU空闲时间运行；另一个是“第1个”，即initproc，在本实验中输出“Hello world”，在后续实验中起到作为线程初始化蓝本的作用。其中后者通过proc\_run运行。

# 扩展练习 Challenge：

> 1. 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

`local_intr_save()` 有如下定义：

通过读取 sstatus 寄存器检查当前中断标志位 SIE。如果中断原本开启，则调用 `intr_disable()` 使用 RISC-V 的 `csrrc` 指令清除 SIE 位，从而关闭中断，并返回 1 作为保存状态，保存在`intr_flag`中。

`local_intr_restore()` 根据保存的状态决定是否重新开启中断：

若 flag 为 1，则调用 `intr_enable()`，使用 `csrrs` 指令设置 SIE 位恢复中断；若 flag 为 0，则保持中断关闭不变。

通过以上函数，该语句对临界区实现了“进入时关闭中断，退出时恢复原状态”的功能，保证了物理内存分配器等关键代码的原子性和一致性。



> 2. 深入理解不同分页模式的工作原理（思考题）
>
> get\_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。

## 关于 `get_pte` 函数的分析

`get_pte` 函数用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。函数中包含两段形式类似的代码，这与 RISC-V 的分页机制密切相关。

### sv32、sv39 和 sv48 的分页机制异同

1. **共同点**：

   * 都是多级页表机制，逐级解析虚拟地址。

   * 每一级页表项都包含有效位（如 PTE\_V），用于指示该项是否有效。

   * 如果某一级页表项无效且需要创建，则分配新的页表页。

2. **不同点**：

   * **sv32**：两级页表，虚拟地址分为 VPN\[1:0] 和偏移量。

   * **sv39**：三级页表，虚拟地址分为 VPN\[2:0] 和偏移量。

   * **sv48**：四级页表，虚拟地址分为 VPN\[3:0] 和偏移量。

   * 页表级数的增加使得 sv39 和 sv48 能够支持更大的虚拟地址空间。

### 为什么代码形式类似

`get_pte` 函数的两段代码分别处理两级页表项（PDE 和 PTE）。这种形式的相似性源于多级页表的递归结构。无论是 sv32、sv39 还是 sv48，每一级页表的处理逻辑基本一致：

1. 检查当前页表项是否有效。

2. 如果无效且需要创建，则分配新的页表页。

3. 更新页表项并设置有效位。

这种递归结构使得代码在处理不同级别的页表时具有一致性。

### 页表项的查找和分配是否应该拆开写

目前 `get_pte()` 函数将“查找页表项”和“分配页表项”这两个功能合并在一起，通过 `create` 参数决定是否分配新的页表项。这种写法在内核开发中是常见的，主要优点是简化了接口调用，方便在需要时自动分配页表项，减少了重复代码。

结合 `pmm.c` 中各函数的使用场景来看：

* 在 `page_insert()`、`boot_map_segment()` 等函数中，通常需要保证页表项存在，如果没有则分配，所以会传入 `create=1`。

* 在 `get_page()`、`page_remove()` 等函数中，只是查找页表项，不希望分配新页表项，所以传入 `create=0`。

我认为没有必要分开。&#x20;

