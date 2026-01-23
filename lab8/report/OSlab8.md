# **练习1：完成读文件操作的实现**

## **一、实验目的**

实现 `sfs_io_nolock()` 函数中的文件读取功能，理解文件系统如何将逻辑文件数据映射到物理磁盘块，掌握文件I/O操作的底层实现机制。

## **二、实验内容**

在 `kern/fs/sfs/sfs_inode.c` 文件中完成 `sfs_io_nolock()` 函数的实现，该函数负责在文件系统中读写文件数据。

## **三、实现思路**

### **3.1 问题分析**

文件读写操作需要处理以下几种情况：

1\. **起始位置未对齐**：读写起始位置不在块边界上

2\. **中间完整块**：可以整块读写的数据

3\. **结束位置未对齐**：读写结束位置不在块边界上

### **3.2 核心概念**

\- **SFS\_BLKSIZE**：文件系统块大小（通常为4096字节）

\- **blkno**：逻辑块号（从文件起始位置计算）

\- **blkoff**：块内偏移量

\- **ino**：物理磁盘块号

\- **nblks**：需要处理的完整块数量

### **3.3 实现策略**

将文件读写分为三个阶段处理：

#### **阶段1：处理起始块（非对齐部分）**

```plain&#x20;text
文件: [-------|-------|-------|-------]
偏移:     ^offset
读取:     [====]  (从offset到块末尾)
```

#### **阶段2：处理中间完整块**

```plain&#x20;text
文件: [-------|-------|-------|-------]
读取:         [=======][=======]  (完整的块)
```

#### **阶段3：处理末尾块（非对齐部分）**

```plain&#x20;text
文件: [-------|-------|-------|-------]
读取:                         [===]  (从块开始到endpos)
```

## **四、代码实现**

### **4.1 完整代码**

```c
// (1) 处理起始块：如果起始偏移量不是块大小的整数倍
blkoff = offset % SFS_BLKSIZE;
if (blkoff != 0) {
    // 计算需要读写的大小
    size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
    // 加载对应的磁盘块号
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    // 从指定偏移量读写指定大小的数据
    if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) {
        goto out;
    }
    // 更新已处理的数据量和缓冲区指针
    alen += size;
    buf += size;
    // 如果已经处理完所有数据，直接跳转到结束
    if (nblks == 0) {
        goto out;
    }
    // 移动到下一块
    blkno++;
    nblks--;
}

// (2) 处理中间的完整块
if (nblks > 0) {
    // 加载起始块号（用于检查）
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    // 连续读写多个完整的块
    if ((ret = sfs_block_op(sfs, buf, blkno, nblks)) != 0) {
        goto out;
    }
    // 更新已处理的数据量和缓冲区指针
    alen += nblks * SFS_BLKSIZE;
    buf += nblks * SFS_BLKSIZE;
    // 移动到末尾块
    blkno += nblks;
    nblks = 0;
}

// (3) 处理末尾块：如果结束位置不是块大小的整数倍
size = endpos % SFS_BLKSIZE;
if (size != 0) {
    // 加载末尾块的磁盘块号
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    // 从块的起始位置读写指定大小的数据
    if ((ret = sfs_buf_op(sfs, buf, size, ino, 0)) != 0) {
        goto out;
    }
    // 更新已处理的数据量
    alen += size;
}
```

### **4.2 关键函数说明**

#### **sfs\_bmap\_load\_nolock()**

```c
int sfs_bmap_load_nolock(struct sfs_fs *sfs, struct sfs_inode *sin, 
                         uint32_t index, uint32_t *ino_store)
```

\- **功能**：将文件的逻辑块号转换为物理磁盘块号

\- **参数**：

* `sfs`：文件系统指针

* `sin`：inode指针

* `index`：逻辑块号

* `ino_store`：输出物理块号

#### **sfs\_buf\_op()**

```c
int sfs_buf_op(struct sfs_fs *sfs, void *buf, size_t len, 
               uint32_t blkno, off_t offset)
```

\- **功能**：读写块的部分数据

\- **参数**：

* `buf`：数据缓冲区

* `len`：读写长度

* `blkno`：物理块号

* `offset`：块内偏移量

#### **sfs\_block\_op()**

```c
int sfs_block_op(struct sfs_fs *sfs, void *buf, 
                 uint32_t blkno, uint32_t nblks)
```

\- **功能**：连续读写多个完整块

\- **参数**：

* `buf`：数据缓冲区

* `blkno`：起始物理块号

* `nblks`：块数量

## **五、学习收获**

1. 理解了文件系统如何将连续的文件空间映射到离散的磁盘块

2. 掌握了处理非对齐I/O操作的通用方法

3) 学会了如何设计高效的块设备I/O接口

4) 认识到错误处理在系统编程中的重要性

### **可能的改进**

1\. **预读优化**：对顺序读取进行预读

2\. **缓存机制**：缓存频繁访问的块

3\. **异步I/O**：支持异步读取操作

4\. **零拷贝**：使用直接DMA减少数据拷贝



# 练习2: 完成基于文件系统的执行程序机制的实现

## 代码实现

### 1. **`do_fork()` 函数的完整实现**

这个函数负责创建子进程，你实现了完整的 fork 逻辑：

#### **进程控制块的分配和初始化**

```c
if ((proc = alloc_proc()) == NULL) {
    goto fork_out;
}
proc->parent = current;
assert(current->wait_state == 0);
```

* 分配新的进程控制块

* 设置父子进程关系

* 确保当前进程不在等待状态

#### **内核栈的设置**

```c
if (setup_kstack(proc) != 0) {
    goto bad_fork_cleanup_proc;
}
```

为子进程分配内核栈空间

#### **内存管理结构的复制**

```c
if (copy_mm(clone_flags, proc) != 0) {
    goto bad_fork_cleanup_kstack;
}
```

复制父进程的内存管理结构

#### **文件系统结构的复制**（LAB8 新增）

```c
if (copy_files(clone_flags, proc) != 0) {
    goto bad_fork_cleanup_mm;
}
```

* 这是 LAB8 的重点：复制文件描述符表

* 确保在 `copy_mm` 之后调用

* 如果失败，跳转到新增的 `bad_fork_cleanup_mm` 清理代码

#### **线程上下文的复制**

```c
copy_thread(proc, stack, tf);
```

复制寄存器状态和栈指针

#### **进程 ID 分配和链表插入**

```c
bool intr_flag;
local_intr_save(intr_flag);
{
    proc->pid = get_pid();
    hash_proc(proc);
    set_links(proc);
}
local_intr_restore(intr_flag);
```

* 关中断保护临界区

* 分配 PID

* 插入哈希表和进程链表

#### **唤醒新进程**

```c
wakeup_proc(proc);
ret = proc->pid;
```

#### **错误处理链的完善**

```c
bad_fork_cleanup_mm:
    if (proc->mm != NULL) {
        struct mm_struct *mm = proc->mm;
        if (mm_count_dec(mm) == 0) {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        proc->mm = NULL;
    }
```

新增了内存清理代码，处理 `copy_files` 失败的情况

***

### 2. **`load_icode()` 函数的完整实现**

这个函数负责加载 ELF 可执行文件到进程地址空间，是实现 `exec` 系统调用的核心。

#### **辅助函数1：`uva2kva()`**

```c
static void *uva2kva(pde_t *pgdir, uintptr_t uva)
```

* 将用户虚拟地址转换为内核虚拟地址

* 用于向用户空间写入数据时的地址转换

#### **辅助函数2：`copy_to_user_pages()`**

```c
static int copy_to_user_pages(pde_t *pgdir, uintptr_t dst_uva, const void *src, size_t len)
```

* 跨页边界向用户空间复制数据

* 处理数据跨越多个页面的情况

* 每次复制一页或页内剩余部分

#### **ELF 文件加载的完整流程**

**步骤1：创建内存管理结构**

```c
struct mm_struct *mm = NULL;
if ((mm = mm_create()) == NULL) goto bad;
if ((ret = setup_pgdir(mm)) != 0) goto bad_mm;
```

**步骤2：读取并验证 ELF 头**

```c
if ((ret = load_icode_read(fd, elf, sizeof(struct elfhdr), 0)) != 0)
    goto bad_cleanup_mmap;
if (elf->e_magic != ELF_MAGIC) {
    ret = -E_INVAL;
    goto bad_cleanup_mmap;
}
```

**步骤3：加载程序段（TEXT/DATA/BSS）**

```c
for (uint16_t i = 0; i < elf->e_phnum; i++) {
    // 读取程序头
    // 跳过非 LOAD 类型的段
    // 设置 VM_FLAGS（基于 ELF_PF_R/W/X）
    // 调用 mm_map 建立 VMA
    // 分配物理页面
    // 从文件读取内容到页面
    // 处理 BSS 段（未初始化数据，填充0）
}
```

关键点：

* 根据 `ph. p_flags` 设置页面权限（`PTE_R/W/X`）

* 使用 `ROUNDDOWN/ROUNDUP` 处理页面对齐

* BSS 段通过 `memset(kva, 0, PGSIZE)` 清零

**步骤4：设置用户栈**

```c
// 建立用户栈 VMA
mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, VM_READ | VM_WRITE | VM_STACK, NULL);

// 分配用户栈的物理页面
for (uintptr_t la = USTACKTOP - USTACKSIZE; la < USTACKTOP; la += PGSIZE) {
    struct Page *page = pgdir_alloc_page(mm->pgdir, la, PTE_U | PTE_R | PTE_W);
    memset(page2kva(page), 0, PGSIZE);
}
```

**步骤5：构建 argc/argv**

```c
uintptr_t sp = USTACKTOP;
uintptr_t uargv_ptrs[EXEC_MAX_ARG_NUM + 1];

// 逆序压入参数字符串
for (int i = argc - 1; i >= 0; i--) {
    size_t slen = strnlen(kargv[i], EXEC_MAX_ARG_LEN) + 1;
    sp -= slen;
    sp = ROUNDDOWN(sp, sizeof(uintptr_t));
    uargv_ptrs[i] = sp;
    copy_to_user_pages(mm->pgdir, sp, kargv[i], slen);
}

// 压入 argv 指针数组
sp = ROUNDDOWN(sp, 16);  // 16字节对齐（RISC-V ABI要求）
sp -= (argc + 1) * sizeof(uintptr_t);
copy_to_user_pages(mm->pgdir, uargv, uargv_ptrs, (argc + 1) * sizeof(uintptr_t));
```

**步骤6：安装内存管理结构**

```c
mm_count_inc(mm);
current->mm = mm;
current->pgdir = PADDR(mm->pgdir);
lsatp(current->pgdir);  // 加载页表基址寄存器
flush_tlb();            // 刷新 TLB
```

**步骤7：设置用户态 Trapframe**

```c
struct trapframe *tf = current->tf;
tf->gpr.sp = sp;                    // 栈指针
tf->gpr.a0 = argc;                  // 第一个参数
tf->gpr.a1 = uargv;                 // 第二个参数
tf->epc = (uintptr_t)elf->e_entry;  // 程序入口点
tf->status = (read_csr(sstatus) | SSTATUS_SPIE) & ~SSTATUS_SPP & ~SSTATUS_SIE;
```

* `SSTATUS_SPIE`：从中断返回时使能中断

* `~SSTATUS_SPP`：返回用户态

* `~SSTATUS_SIE`：暂时禁用中断



**步骤8：关闭文件并返回**

```c
sysfile_close(fd);
return 0;
```

***

## 实验要点总结

1. **文件系统集成**：在 `do_fork` 中正确调用 `copy_files()`，处理文件描述符的继承

2. **ELF 加载**：完整实现从文件系统读取可执行文件到内存的过程

3) **参数传递**：通过用户栈传递 `argc` 和 `argv` 给新程序

4) **权限控制**：正确设置页面权限（用户态、读写执行）

5. **错误处理**：多级清理链确保资源正确释放

# 扩展练习 Challenge1：完成基于“UNIX的PIPE机制”的设计方案

## 一、设计目标

在 uCore 操作系统中引入 UNIX 风格的管道（Pipe）机制，用于实现**进程间的字节流通信**。
管道应支持以下基本语义：

* 单向通信（读端 / 写端）

* 阻塞式读写

* 正确处理 EOF 与 EPIPE

* 多进程并发访问下的同步与互斥

## 二、核心数据结构设计

### 1. 管道核心数据结构

管道本质上是一个**带同步机制的环形缓冲区**，其核心结构如下：

```c
#define PIPE_SIZE 4096   // 管道缓冲区大小

struct pipe {
    char buffer[PIPE_SIZE];   // 环形缓冲区
    int read_pos;             // 当前读位置
    int write_pos;            // 当前写位置
    int data_size;            // 缓冲区中已有数据量

    /* 同步与互斥 */
    semaphore_t mutex;        // 互斥访问管道缓冲区
    semaphore_t data_avail;   // 数据可用（用于读阻塞）
    semaphore_t space_avail;  // 空间可用（用于写阻塞）

    /* 端点与引用管理 */
    int read_ref;             // 读端引用计数
    int write_ref;            // 写端引用计数
    int ref_count;            // 总引用计数

    bool read_closed;         // 是否所有读端已关闭
    bool write_closed;        // 是否所有写端已关闭
};
```

* `buffer + read_pos + write_pos` 组成环形缓冲区，用于高效数据传输

* 使用信号量抽象实现互斥访问和条件同步

* 通过引用计数与关闭标志正确处理 EOF 和 EPIPE 语义

***

### 2. 管道文件抽象（与文件系统集成）

为了与 uCore 的文件描述符机制兼容，每个管道端点对应一个文件对象：

```c
struct pipe_file {
    struct file base_file;    // 通用文件结构
    struct pipe *pipe;        // 指向管道核心结构
    bool is_read_end;         // 是否为读端
};
```

> 该结构用于将 pipe 统一纳入 uCore 的 file / fd 管理体系，便于通过 read/write 系统调用访问。

***

## 三、核心接口设计（语义说明）

### 1. 管道创建与销毁接口

```c
// 创建一个管道，返回读端和写端文件描述符
int pipe(int pipefd[2]);
```

**语义说明：**

* 创建一个新的管道对象

* 分配两个文件描述符，分别对应读端和写端

* 初始化管道缓冲区与同步原语

***

```c
// 关闭管道的一个端点
int pipe_close(struct file *file);
```

**语义说明：**

* 关闭对应的读端或写端

* 更新引用计数

* 在必要时唤醒对端阻塞进程

* 当所有端点关闭时释放管道资源

***

### 2. 管道读写接口

```c
// 从管道读取数据
ssize_t pipe_read(struct file *file, char *buf, size_t count);
```

**语义说明：**

* 若管道中有数据，读取不超过 `count` 字节

* 若管道为空且写端仍存在，则阻塞等待

* 若管道为空且写端已关闭，返回 0（EOF）

***

```c
// 向管道写入数据
ssize_t pipe_write(struct file *file, const char *buf, size_t count);
```

**语义说明：**

* 若缓冲区未满，写入不超过 `count` 字节

* 若缓冲区已满，则阻塞等待空间

* 若所有读端已关闭，返回 `EPIPE`（并在支持信号机制时触发 SIGPIPE）

***

## 四、同步与互斥问题的处理

### 1. 互斥访问控制

* 使用 `mutex` 信号量保护管道内部状态

* 如果是缓冲区问题就初始设置为1，同步问题就初始设置为0

* 先p()后v()

* 确保多进程并发读写时缓冲区状态的一致性

***

### 2. 阻塞与唤醒机制

* 当管道为空时，读进程阻塞在 `data_avail`

* 当管道满时，写进程阻塞在 `space_avail`

* 数据或空间状态变化后，通过信号量唤醒对应进程

***

### 3. 端点关闭与异常处理

* 当写端全部关闭且缓冲区为空时，读操作返回 EOF

* 当读端全部关闭时，写操作返回 EPIPE

* 关闭操作会唤醒所有可能阻塞的对端进程，防止死锁

***

# 扩展练习 Challenge2：完成基于“UNIX的软连接和硬连接机制”的设计方案

## 设计目标

在 uCore 文件系统中引入 **UNIX 风格的硬连接与软连接机制**，使多个路径名可共享同一 inode（硬连接），或通过路径间接引用目标文件（软连接），并保证多进程环境下的正确性与一致性。

***

## 核心数据结构设计

### 2.1 inode 扩展

```c
enum inode_type {
    INODE_REGULAR,
    INODE_DIRECTORY,
    INODE_SYMLINK,
};

struct inode {
    ino_t ino;
    enum inode_type type;
    size_t size;

    /* 硬连接 */
    uint32_t nlinks;                 // 硬连接计数

    /* 软连接 */
    char symlink_target[MAX_PATH];   // 目标路径（仅符号链接使用）

    /* 同步与引用 */
    atomic_t ref_count;              // 内存引用计数
    semaphore_t inode_mutex;         // inode 互斥锁
};
```

**说明：**

* **硬连接本质**：多个目录项指向同一个 inode，通过 `nlinks` 管理

* **软连接本质**：独立 inode，内部保存目标路径字符串

***

### 2.2 目录项

```c
struct dirent {
    ino_t ino;
    char name[MAX_NAME_LEN];
};
```

**说明：**

* 硬连接通过新增 `dirent` 实现

* 删除硬连接仅删除目录项，不立即释放 inode

***

## 接口设计

### 3.1 硬连接接口

```c
int link(const char *oldpath, const char *newpath);
```

* 创建新的目录项 `newpath`

* 指向 `oldpath` 的 inode

* 增加 inode 的 `nlinks`

* 不允许跨文件系统或对目录创建硬连接

```c
int unlink(const char *path);
```

* 删除目录项

* inode 的 `nlinks--`

* 当 `nlinks == 0` 且无进程引用时释放 inode

***

### 3.2 软连接接口

```c
int symlink(const char *target, const char *linkpath);
```

* 创建类型为 `INODE_SYMLINK` 的 inode

* inode 内保存目标路径

* 允许目标不存在

```c
ssize_t readlink(const char *path, char *buf, size_t size);
```

* 读取符号链接中保存的路径字符串

* 不解析链接

***

### 3.3 路径解析接口

```c
int open(const char *path, int flags);
int stat(const char *path, struct stat *buf);
int lstat(const char *path, struct stat *buf);
```

* `open / stat`：解析符号链接并访问目标

* `lstat`：返回符号链接本身信息

* 设置最大解析深度，防止循环符号链接

***

## 同步与互斥设计

### 硬连接与删除

* inode 加锁保护 `nlinks`

* 目录 inode 加锁防止并发修改目录结构

* 保证目录项操作与 `nlinks` 修改的原子性

### 延迟删除机制

* `unlink` 仅减少 `nlinks`

* 当 `nlinks == 0` 且 `ref_count == 0` 时才真正释放 inode

* 避免“正在使用的文件被删除”

### 符号链接解析

* 解析过程只读 inode

* 通过引用计数防止解析过程中 inode 被回收

* 限制解析层数，避免死循环
