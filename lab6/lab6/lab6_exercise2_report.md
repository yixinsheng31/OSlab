# Lab6 练习2：实现 Round Robin 调度算法 - 实验报告

**学号：2311781**  
**日期：2026年1月2日**

---

## 一、Lab5与Lab6的函数对比与改动分析

### 1.1 对比函数：`wakeup_proc()` 在 `kern/schedule/sched.c` 中的变化

#### Lab5 实现（简化版）：
```c
void wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            // Lab5: 没有调度器框架，直接加入链表
        }
    }
    local_intr_restore(intr_flag);
}
```

#### Lab6 实现：
```c
void wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            if (proc != current) {
                sched_class_enqueue(proc);  // ← 新增：使用调度器框架
            }
        }
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
```

### 1.2 改动原因分析

**为什么要做这个改动？**

1. **引入调度器框架**：Lab6 实现了统一的调度器接口 `sched_class`，支持多种调度算法（RR、Stride等）
2. **解耦调度逻辑**：通过 `sched_class_enqueue()` 调用具体调度器的 `enqueue` 方法，实现了调度算法与进程管理的解耦
3. **时间片管理**：在 `enqueue` 中统一初始化进程的 `time_slice`，确保进程被唤醒时有合适的时间片

**不做这个改动会出什么问题？**

1. **进程无法被调度**：唤醒的进程不会被加入就绪队列，调度器无法选择它运行
2. **时间片未初始化**：进程的 `time_slice` 可能为0，导致立即被抢占
3. **调度器状态不一致**：`rq->proc_num` 等元数据不会更新，影响调度决策

---

## 二、Round Robin 调度算法实现详解

### 2.1 总体设计思路

Round Robin（时间片轮转）是一种**抢占式调度算法**，核心思想：
- 所有就绪进程按**FIFO顺序**排列在一个队列中
- 每个进程分配固定的**时间片**（本实验中为5个tick）
- 时间片用完后，进程被移到队列尾部，调度下一个进程

**数据结构**：
```c
struct run_queue {
    list_entry_t run_list;        // 双向循环链表头
    unsigned int proc_num;        // 进程数量
    int max_time_slice;          // 最大时间片
};
```

### 2.2 各函数实现详解

#### 2.2.1 `RR_init()` - 初始化运行队列

```c
static void RR_init(struct run_queue *rq)
{
    // LAB6: 2311781
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}
```

**实现思路**：
- 初始化双向循环链表头 `run_list`
- 进程数量置为0
- `max_time_slice` 由调用者（`sched_init`）设置

**边界条件**：无特殊边界条件，纯初始化操作

---

#### 2.2.2 `RR_enqueue()` - 进程入队

```c
static void RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2311781
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link));
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num ++;
}
```

**实现思路**：
1. **断言检查**：确保进程的 `run_link` 为空（未在任何队列中）
2. **插入队列尾部**：使用 `list_add_before(&rq->run_list, &proc->run_link)`
   - `run_list` 是循环链表头
   - 插入到头节点之前 = 插入到队列尾部
3. **时间片重置**：如果时间片为0或过大，重置为 `max_time_slice`
4. **更新元数据**：设置 `proc->rq` 指针，增加 `proc_num`

**为什么选择 `list_add_before`？**
- RR调度要求FIFO顺序
- `list_add_before(&head, &new)` 将新节点插入到头节点之前，即队列尾部
- `list_next(&head)` 取队列头部，实现先进先出

**边界条件处理**：
- **时间片为0**：新创建的进程或时间片耗尽的进程，需重新分配
- **时间片过大**：防止异常情况，限制最大值
- **重复入队**：通过 `assert` 防止同一进程多次入队

---

#### 2.2.3 `RR_dequeue()` - 进程出队

```c
static void RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2311781
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num --;
}
```

**实现思路**：
1. **断言检查**：
   - 进程必须在队列中（`run_link` 非空）
   - 进程必须属于这个队列（`proc->rq == rq`）
2. **从链表中删除**：使用 `list_del_init()` 删除并重新初始化节点
3. **更新计数**：减少 `proc_num`

**为什么使用 `list_del_init` 而不是 `list_del`？**
- `list_del_init()` 会将节点的 `prev` 和 `next` 指向自己
- 使 `list_empty()` 返回 `true`，方便后续检查
- 避免悬空指针导致的二次删除

**边界条件处理**：
- **空队列**：通过 `assert` 防止从空队列删除
- **错误的队列**：防止从错误的队列删除进程

---

#### 2.2.4 `RR_pick_next()` - 选择下一个进程

```c
static struct proc_struct *RR_pick_next(struct run_queue *rq)
{
    // LAB6: 2311781
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}
```

**实现思路**：
1. **获取队列头部**：`list_next(&rq->run_list)` 返回第一个进程节点
2. **检查队列是否为空**：如果 `le == &rq->run_list`，说明队列为空
3. **转换为进程结构体**：使用 `le2proc(le, run_link)` 宏
   - `le2proc` 通过 `run_link` 成员的地址反推出 `proc_struct` 的地址
   - 相当于 `container_of(le, struct proc_struct, run_link)`

**边界条件处理**：
- **空队列**：返回 `NULL`，调度器会选择 `idleproc`

---

#### 2.2.5 `RR_proc_tick()` - 时间片管理

```c
static void RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2311781
    if (proc->time_slice > 0) {
        proc->time_slice --;
    }
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}
```

**实现思路**：
1. **时间片递减**：每个时钟中断（tick）减1
2. **检查是否耗尽**：如果 `time_slice == 0`，设置重调度标志
3. **触发调度**：`need_resched = 1` 使进程在返回用户态前调用 `schedule()`

**为什么需要设置 `need_resched` 标志？**
1. **避免中断处理中调度**：不能在中断处理函数中直接调用 `schedule()`
2. **延迟调度**：设置标志后，在 `trap()` 返回前检查并调度
3. **保证原子性**：确保中断处理完整完成后再切换进程

**边界条件处理**：
- **time_slice > 0**：先检查再递减，避免负值
- **idle进程**：在 `sched_class_proc_tick()` 中已过滤，不会调用到这里

---

### 2.3 关键改动：`trap.c` 中的时钟中断处理

#### 2.3.1 调用 `sched_class_proc_tick()`

```c
case IRQ_S_TIMER:
    clock_set_next_event();
    ticks++;
    if (ticks % 100 == 0) {
        print_ticks();
        print_count++;
        if (print_count == 10) {
            sbi_shutdown();
        }
    }
    // LAB6: 2311781 在每次时钟中断时调用sched_class_proc_tick
    sched_class_proc_tick(current);  // ← 关键调用
    break;
```

**作用**：每个时钟中断都会更新当前进程的时间片，实现时间片轮转。

#### 2.3.2 修复 `DEBUG_GRADE` 模式的过早退出问题

**问题**：原始代码在 `print_ticks()` 中，每次打印 "100 ticks" 都会 panic，导致测试在第一个100 ticks就退出。

**解决方案**：将 panic 延迟到 `print_count == 10`（即1000 ticks）时执行：

```c
if (print_count == 10) {
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
    sbi_shutdown();
}
```

**作用**：让 priority 测试程序有足够时间（200+ ticks）运行完成。

---

### 2.4 进程初始化：`alloc_proc()` 中的字段初始化

```c
// LAB6: 2311781 初始化LAB6新增的调度相关字段
proc->rq            = NULL;
list_init(&(proc->run_link));  // ← 关键：必须初始化链表
proc->time_slice    = 0;
proc->lab6_stride   = 0;
proc->lab6_priority = 1;
```

**关键点**：
- `list_init(&proc->run_link)` 是**必须的**，否则 `RR_enqueue()` 中的 `assert(list_empty(&proc->run_link))` 会失败
- `lab6_priority = 1` 作为默认优先级

---

## 三、测试结果与调度现象观察

### 3.1 `make grade` 测试结果

```bash
oslab@qiyu:/mnt/c/Users/18435/Desktop/os/lab6/lab6$ make grade
priority:                (3.8s)
  -check result:                             OK
  -check output:                             OK
Total Score: 50/50
```

✅ **测试通过，满分50/50！**

### 3.2 QEMU 中观察到的调度现象

#### 完整输出日志：
```
sched class: RR_scheduler
++ setup timer interrupts
kernel_execve: pid = 2, name = "priority".
set priority to 6
main: fork ok,now need to wait pids.
set priority to 1
set priority to 2
set priority to 3
set priority to 4
set priority to 5
100 ticks
100 ticks
child pid 3, acc 404000, time 2010
child pid 4, acc 408000, time 2010
child pid 5, acc 404000, time 2020
child pid 6, acc 400000, time 2020
child pid 7, acc 408000, time 2020
main: pid 0, acc 404000, time 2020
main: pid 4, acc 408000, time 2020
main: pid 5, acc 404000, time 2020
main: pid 6, acc 400000, time 2020
main: pid 7, acc 408000, time 2020
main: wait pids over
sched result: 1 1 1 1 1
all user-mode processes have quit.
init check memory pass.
```

#### 调度现象分析：

1. **进程创建顺序**：
   - 父进程（priority测试，pid=2）设置自己优先级为6
   - 依次fork 5个子进程（pid 3-7），分别设置优先级1-5
   - 父进程输出 "main: fork ok..."

2. **调度顺序观察**：
   - 5个子进程按**创建顺序**（1,2,3,4,5）输出 "set priority to X"
   - **说明RR调度器按FIFO顺序调度，不考虑优先级**

3. **时间片轮转**：
   - 每个进程获得5个tick的时间片
   - 时间片用完后自动切换到下一个进程
   - 所有进程**公平地**获得CPU时间

4. **计算结果**：
   - 5个子进程的 `acc` 值接近（404000, 408000等）
   - 计算 `sched result: 1 1 1 1 1`（相对比例都是1）
   - **证明RR调度实现了CPU时间的公平分配**

5. **进程结束**：
   - 所有子进程运行约2000ms后正常退出
   - 父进程收集退出状态并检查内存
   - 系统正常关机

---

## 四、Round Robin 调度算法分析

### 4.1 优点

1. **简单高效**：
   - 实现简单，只需要一个FIFO队列
   - 调度开销小，O(1)时间复杂度

2. **公平性好**：
   - 所有进程平等对待，避免饥饿
   - 适合分时系统，保证响应时间

3. **可预测性**：
   - 等待时间可预测：最多等待 `(n-1) × time_slice`
   - 适合交互式应用

### 4.2 缺点

1. **不考虑优先级**：
   - 所有进程一视同仁，无法满足重要进程的需求
   - 不适合有优先级要求的系统

2. **上下文切换开销**：
   - 时间片过小导致频繁切换，降低效率
   - 切换开销占比增大

3. **不区分I/O密集和CPU密集**：
   - I/O密集型进程可能浪费时间片
   - CPU密集型进程可能得不到足够时间

4. **平均等待时间较长**：
   - 短作业可能等待很久
   - 不如SJF（最短作业优先）

### 4.3 时间片大小的影响

#### 时间片过大：
- ✅ 减少上下文切换开销
- ❌ 响应时间变长，接近FCFS
- ❌ 交互性变差

#### 时间片过小：
- ✅ 响应时间短，交互性好
- ❌ 上下文切换频繁，CPU利用率降低
- ❌ 系统吞吐量下降

#### 最佳时间片选择：
- **经验值**：10-100ms
- **本实验**：5个tick = 50ms（假设1 tick = 10ms）
- **调整策略**：
  - 交互式系统：较小时间片（10-20ms）
  - 批处理系统：较大时间片（100-200ms）
  - 混合系统：动态调整（多级反馈队列）

### 4.4 为什么需要在 `RR_proc_tick` 中设置 `need_resched` 标志？

#### 原因1：避免在中断处理中直接调度
```c
// ❌ 错误做法
void RR_proc_tick(...) {
    if (proc->time_slice == 0) {
        schedule();  // 不能在中断处理中调用！
    }
}
```
- 中断处理函数不能被抢占
- `schedule()` 可能导致死锁或数据不一致

#### 原因2：延迟调度，保证原子性
```c
// ✅ 正确做法
void RR_proc_tick(...) {
    if (proc->time_slice == 0) {
        proc->need_resched = 1;  // 设置标志
    }
}

void trap(struct trapframe *tf) {
    // ... 中断处理 ...
    if (current->need_resched) {
        schedule();  // 在合适的时机调度
    }
}
```

#### 原因3：符合中断处理设计原则
- **中断处理应尽快完成**：只做必要的工作
- **复杂操作延后执行**：调度、I/O等放到中断返回前
- **保证系统稳定性**：避免嵌套调度导致的混乱

---

## 五、拓展思考

### 5.1 如果要实现优先级 RR 调度，代码需要如何修改？

#### 方案1：多级队列（Multiple Queues）

```c
#define MAX_PRIORITY 8

struct run_queue {
    list_entry_t run_list[MAX_PRIORITY];  // 多个优先级队列
    unsigned int proc_num[MAX_PRIORITY];
    int max_time_slice;
};

static void Priority_RR_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    int priority = proc->lab6_priority;
    if (priority < 0) priority = 0;
    if (priority >= MAX_PRIORITY) priority = MAX_PRIORITY - 1;
    
    list_add_before(&(rq->run_list[priority]), &(proc->run_link));
    proc->time_slice = rq->max_time_slice;
    rq->proc_num[priority]++;
}

static struct proc_struct *Priority_RR_pick_next(struct run_queue *rq) {
    // 从高优先级队列开始查找
    for (int i = MAX_PRIORITY - 1; i >= 0; i--) {
        list_entry_t *le = list_next(&(rq->run_list[i]));
        if (le != &(rq->run_list[i])) {
            return le2proc(le, run_link);
        }
    }
    return NULL;
}
```

**特点**：
- 高优先级进程优先调度
- 同优先级内使用RR
- 可能导致低优先级进程饥饿

#### 方案2：动态优先级（Dynamic Priority）

```c
static void Dynamic_RR_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    if (proc->time_slice == 0) {
        // 降低优先级，防止CPU密集型进程占用过多
        if (proc->lab6_priority > 0) {
            proc->lab6_priority--;
        }
        proc->need_resched = 1;
    }
}

void wakeup_proc(struct proc_struct *proc) {
    // I/O完成时提升优先级，优化交互性
    if (proc->lab6_priority < MAX_PRIORITY - 1) {
        proc->lab6_priority++;
    }
    // ... 其他代码 ...
}
```

**特点**：
- CPU密集型进程优先级降低
- I/O密集型进程优先级提高
- 自动平衡，防止饥饿

---

### 5.2 当前实现是否支持多核调度？

#### 答案：❌ **不支持**

#### 当前实现的问题：

1. **全局运行队列**：
   ```c
   static struct run_queue *rq;  // 单一队列，所有CPU共享
   ```
   - 所有CPU竞争同一个队列
   - 需要频繁加锁，性能差

2. **单一 `current` 指针**：
   ```c
   struct proc_struct *current = NULL;  // 全局变量
   ```
   - 多核环境下每个CPU应有独立的 `current`

3. **缺少CPU亲和性**：
   - 进程可能在不同CPU间频繁迁移
   - 缓存失效，性能下降

#### 改进方案：

##### 方案1：Per-CPU 运行队列

```c
// 每个CPU一个运行队列
struct cpu_rq {
    struct run_queue rq;
    struct proc_struct *current;
    spinlock_t lock;
};

struct cpu_rq cpu_rqs[MAX_CPU];

void schedule(void) {
    int cpu_id = get_cpu_id();
    struct cpu_rq *cpu_rq = &cpu_rqs[cpu_id];
    
    spin_lock(&cpu_rq->lock);
    // 从本地队列调度
    struct proc_struct *next = sched_class_pick_next(&cpu_rq->rq);
    spin_unlock(&cpu_rq->lock);
    
    if (next != NULL) {
        proc_run(next);
    }
}
```

**优点**：
- 减少锁竞争
- 提高缓存局部性
- 扩展性好

##### 方案2：负载均衡

```c
void load_balance(void) {
    int cpu_id = get_cpu_id();
    struct cpu_rq *this_rq = &cpu_rqs[cpu_id];
    
    // 找到最忙的CPU
    int busiest_cpu = find_busiest_cpu();
    if (busiest_cpu == cpu_id) return;
    
    struct cpu_rq *busiest_rq = &cpu_rqs[busiest_cpu];
    
    // 迁移一半进程到当前CPU
    int migrate_count = busiest_rq->rq.proc_num / 2;
    for (int i = 0; i < migrate_count; i++) {
        struct proc_struct *proc = RR_pick_next(&busiest_rq->rq);
        if (proc) {
            RR_dequeue(&busiest_rq->rq, proc);
            RR_enqueue(&this_rq->rq, proc);
        }
    }
}
```

**策略**：
- 定期检查负载
- 从忙CPU迁移进程到空闲CPU
- 保持各CPU负载均衡

##### 方案3：CPU亲和性

```c
struct proc_struct {
    // ... 其他字段 ...
    int cpu_affinity;      // 倾向在哪个CPU运行
    int last_cpu;          // 上次运行的CPU
    uint64_t last_run_time; // 上次运行时间
};

void schedule(void) {
    int cpu_id = get_cpu_id();
    struct proc_struct *next = sched_class_pick_next(&cpu_rqs[cpu_id].rq);
    
    // 优先选择上次在本CPU运行的进程
    if (next && next->last_cpu == cpu_id) {
        // 缓存命中率高
    } else if (next && next->cpu_affinity == cpu_id) {
        // 用户指定亲和性
    }
    
    if (next) {
        next->last_cpu = cpu_id;
        proc_run(next);
    }
}
```

---

## 六、总结

### 6.1 实验收获

1. **深入理解调度器框架**：
   - 学习了调度器接口的设计（`sched_class`）
   - 理解了进程状态转换与调度的关系

2. **掌握Round Robin算法**：
   - 实现了完整的RR调度器
   - 理解了时间片轮转的原理和实现细节

3. **系统编程技能提升**：
   - 熟练使用双向链表操作
   - 理解中断处理与调度的配合
   - 掌握边界条件处理技巧

4. **性能分析能力**：
   - 分析了RR调度算法的优缺点
   - 理解了时间片大小对系统性能的影响

### 6.2 实验要点

| 文件 | 关键修改 | 作用 |
|------|---------|------|
| `default_sched.c` | 实现5个RR调度函数 | 核心调度逻辑 |
| `proc.c` | 初始化LAB6字段 | 进程结构体准备 |
| `trap.c` | 调用`sched_class_proc_tick` | 时间片更新 |
| `trap.c` | 修复DEBUG_GRADE退出时机 | 让测试完整运行 |

### 6.3 测试结果

✅ **Total Score: 50/50**

所有进程正常调度，时间片轮转工作正常，测试完全通过！

---

## 附录：关键代码清单

### A. RR调度器完整实现 (`default_sched.c`)

```c
static void RR_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}

static void RR_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link));
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}

static void RR_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num--;
}

static struct proc_struct *RR_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}

static void RR_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}
```

### B. 时钟中断处理关键代码 (`trap.c`)

```c
case IRQ_S_TIMER:
    clock_set_next_event();
    ticks++;
    if (ticks % 100 == 0) {
        print_ticks();
        print_count++;
        if (print_count == 10) {
#ifdef DEBUG_GRADE
            cprintf("End of Test.\n");
            panic("EOT: kernel seems ok.");
#endif
            sbi_shutdown();
        }
    }
    sched_class_proc_tick(current);
    break;
```

---

**实验完成日期**：2026年1月2日  
**最终得分**：50/50 ✅
