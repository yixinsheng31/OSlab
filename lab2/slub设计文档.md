
# SLUB设计文档
======================

### 目标
----
实现一份对 ucore 教学友好的简化 SLUB 分配器，实现两层分配器：

- 第一层：页分配（使用已有的 Page 分配器），负责提供 slab（本实现 slab 为单页）。
- 第二层：对象分配（按 size-class），在 slab 上切分对象并用空闲链表管理。

### 设计要点与取舍
----------------

- slab 固定为 1 页，简化 slab 元数据与回收逻辑；
- 支持 object sizes 从 32B 到 2048B（2 的幂），采用幂次级别的 size-class；
- 维护 page -> owner 映射（page_owner_map）和 page_freecount，用于释放/检测一致性；

### 数据结构
------------------

#### 两个结构体

- obj_head_t
	- next: 指向下一个空闲对象
	- owner_page: 存放该对象所在页的索引+1（0 表示无）

- kmem_cache_t
	- size: 对应 cache 的对象大小
	- freelist: 空闲对象链表（obj_head_t*）
	- slabs: slab 列表头（为后续扩展保留）

#### 两个数组

- page_owner_map[]
	- 对应 pages[] 的每一页，值为 owning cache 索引 + 1, 
	0 表示空闲或未被 cache 使用

- page_freecount[]
	- 每个被 cache 使用的页当前空闲对象数量

### 主要函数
---------------------

- void slub_init(void)
	- 输入：无
	- 输出：初始化所有 cache 与 page_map
	- 错误：无

- void *kmalloc(size_t size)
	- 输入：请求字节数
	- 输出：返回 kernel virtual address 或 NULL
	- 行为：若 size > SLUB_MAX_SIZE 按页分配；否则在对应 cache 分配对象（必要时先 carve slab）

- void kfree(void *ptr)
	- 输入：指向之前由 kmalloc/alloc_pages 返回的地址
	- 输出：无
	- 行为：若 ptr 对应页由 cache 管理则放回 freelist 并更新 page_freecount；否则按页释放

### 实现要点与行为说明
-------------------

- slab 固定为 1 页：每次 carve 会向 pmm 请求一页并把整页切成固定大小对象。
- 元数据分布：
	- 每个对象头 `obj_head_t` 包含 `owner_page`（页索引+1），用于快速定位对象的归属页；
	- 全局数组 `page_owner_map[page_index]`（cache index + 1 或 0）记录页的归属；
	- 全局数组 `page_freecount[page_index]` 记录页当前的空闲对象数（用于判断是否能回收整页）。
- 分配/释放流程摘要：
	- kmalloc：若 size > SLUB_MAX_SIZE 则按页分配（alloc_pages(np)），否则从对应 size-class 的 `freelist` pop 一个对象（若空则 carve slab）；
	- kfree：通过 ptr -> pa -> pa2page 找到 `page_index`，若 `page_owner_map[page_index] == 0` 则认为是按页的大对象并释放页（注意：当前实现对多页大对象的释放需要改进），否则把对象插回 cache.freelist 并 `page_freecount++`；
	- 整页回收：当 `page_freecount[page_index]` 达到该页对象总数（PGSIZE / objsz）时，当前实现会遍历该 cache.freelist 并剔除属于该页的对象，然后清除 `page_owner_map`/`page_freecount` 并调用 `free_page(pg)` 回收该页。



### 对外接口
--------------------


1) `pmm.c`（`lab2/kern/mm/pmm.c`）
	 - 在 `pmm_init()` 中以弱符号方式声明并调用 `slub_init()`：
		 ```c

		 extern void slub_init(void) __attribute__((weak));
		 if (slub_init) slub_init();
		 ```+
		 目的是在 pmm 初始化并建立物理页管理后再初始化 SLUB（SLUB 内部需要调用 `alloc_page()`）。
	 - 以弱符号方式调用 `slub_self_test()`（如果定义则运行自检）：
		 ```c
		 extern void slub_self_test(void) __attribute__((weak));
		 if (slub_self_test) slub_self_test();
		 ```
	 - 这样做保证在没有定义 SLUB 的情况下仍能回退到默认 pmm 管理器，不会产生链接错误。

2) `slub.h`（`lab2/kern/mm/slub.h`）
	 - 对外接口：`slub_init`, `kmalloc`, `kfree`, `slub_self_test`。
	 - 说明：上层模块只需包含该头文件即可调用 kmalloc/kfree（或通过弱引用在 `pmm.c` 中检测并初始化）。



### 测试用例与验证策略
--------------------

1) 基本分配释放（slub_self_test）
	 - 分配 512 个对象，覆盖所有 size-class。
	 - 对每个对象写数据并释放，检查 page_freecount 在释放之后返回到满容量。

2) 随机压力测试（建议实现）
 	 - 随机选择 size、随机分配/释放，循环 1e4 次，核对 nr_free_pages 及 page_freecount 的一致性。

3) 边界测试
 	 - 请求 0 字节（应返回 NULL）；请求大于 SLUB_MAX_SIZE 的内存（按页分配）。

4) 大对象释放测试
 	 - 分配一个大于一页的对象（np>1），释放后检查 `nr_free_pages` 恢复到分配前的值；此测试用于验证多页分配的释放逻辑是否正确。





### 运行结果
---------------------
```
sheng@Amazonian:/mnt/c/Users/sheng/Desktop/workspace/labcode/lab2$ make qemu 
+ cc kern/mm/pmm.c
+ cc kern/mm/slub.c
+ ld bin/kernel
riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img

OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
DTB Init
HartID: 0
DTB Address: 0x82200000
Physical Memory from DTB:
  Base: 0x0000000080000000
  Size: 0x0000000008000000 (128 MB)
  End:  0x0000000087ffffff
DTB init completed
(THU.CST) os is loading ...
Special kernel symbols:
  entry  0xffffffffc02000d8 (virtual)
  etext  0xffffffffc0201cb2 (virtual)
  edata  0xffffffffc0206018 (virtual)
  end    0xffffffffc02258e8 (virtual)
Kernel executable memory footprint: 151KB
memory management: default_pmm_manager
physcial memory map:
  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].      
slub allocator initialized
slub_self_test: allocated=1024 failed=0
class 0 size 32 allocated 134
class 1 size 64 allocated 163
class 2 size 128 allocated 145
class 3 size 256 allocated 149
class 4 size 512 allocated 152
class 5 size 1024 allocated 156
class 6 size 2048 allocated 125
slub_self_test: reclaimed_pages=141 errors=0
slub_self_test completed OK
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
```
