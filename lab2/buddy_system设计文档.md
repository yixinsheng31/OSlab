## 背景知识介绍
buddy system是一种经典的内存分配算法，应用于Linux底层内存管理。它将系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

## 设计目标
- 实现初始化函数，配置系统中的初始内存块。

- 实现内存分配和释放的核心算法，并确保能处理不同大小的内存请求。在这个过程中也要实现内存块的合并与分裂操作。

- 编写合适的check函数来验证算法的正确性。

## 关键值界设置


    #define MAX_INIT_PAGES 16384  // 2^14 = 16384 
    int MEM_BEGIN;

由于buddy system要求每个块的大小是2的次方，首先打印出总的空闲页数量，发现为31929，向下取最大的2的次方的数，发现为2^14（16384），因此在文件开始部分进行定义。

MEM_BEGIN是定义初始块时base的首地址，它的作用和赋值将在后文进行介绍，此处不赘述。

## 函数编写
### 初始化空闲块链表
    static void
    buddy_system_init(void) {
        list_init(&free_list);
        nr_free = 0;
    }

此过程初始化空闲块链表（指定free_list的prev和next指针都指向它自身），并将初始空闲页数定义为0。

### 初始化内存管理
    static void
    buddy_system_init_memmap(struct Page *base, size_t n) {
        assert(n > 0);
        MEM_BEGIN = (size_t)base;//作用将在后文介绍
        n = MAX_INIT_PAGES; // 限制
        struct Page *p = base;
        for (; p != base + n; p ++) {
            assert(PageReserved(p));
            p->flags = p->property = 0;//设置它们引用次数为0且目前都可用
            set_page_ref(p, 0);
        }
        base->property = n;// 对第一页进行设置，整体是一个大块，记录页数多少
        SetPageProperty(base);
        nr_free += n;// 记录的空闲块个数+n
        if (list_empty(&free_list)) {
            list_add(&free_list, &(base->page_link));
        } else {
            list_entry_t* le = &free_list;
            while ((le = list_next(le)) != &free_list) {
                struct Page* page = le2page(le, page_link);
                if (base < page) {
                    list_add_before(le, &(base->page_link));
                    break;
                } else if (list_next(le) == &free_list) {
                    list_add(le, &(base->page_link));
                }
            }
        }
    }
其中(le = list_next(le)) != &free_list作为循环终止条件由于我们定义了此链表为双向循环链表。此外，增加顺序是依照内存顺序而不是依照块的大小。

此过程将指定页面数的内存块初始化为一个大的空闲块，并将其插入到 free_list 链表中，手动限制最大分配的页数为 16384 页。

### 内存分配
首先，在分配内存时，如果请求内存页数不是2的次方，应该将它处理成大于等于它的最小的2的次方数。因此编写函数如下：

    static size_t round_up_pow2(size_t n) {
        size_t size = 1;
        while (size < n) {
            size <<= 1;
        }
        return size;
    }
然后才是内存分配相关函数：

    static struct Page *
    buddy_system_alloc_pages(size_t n) {
        assert(n > 0);
        n = round_up_pow2(n);// 将请求的块大小调整为大于等于 n 的最小的 2 的幂次方
        // 如果请求的页数大于可用页数，返回 NULL
        if (n > nr_free) {
            return NULL;
        }
        struct Page *page = NULL;
        list_entry_t *le = &free_list;
        // 遍历空闲块链表，查找第一个块大小大于等于n的空闲块
        while ((le = list_next(le)) != &free_list) {
            struct Page *p = le2page(le, page_link);
            if (p->property >= n) {
                page = p;// 找到第一个块大小大于等于n的空闲块
                //然后打印一下起始地址。
                cprintf("找到第一个满足要求的空闲块 p\n");
                cprintf("准备用于分配的空闲块 p 的地址为: 0x%016lx.\n", p);
                cprintf("准备分配的空闲块 p 的页数为: %d\n", p->property);
                break;
            }
        }
        // 分裂空闲块->也就是变成开始的一半
        if (page != NULL) {
            cprintf("开始分裂空闲块……\n\n");
            list_entry_t* prev = list_prev(&(page->page_link));// 找到 page 前面的块
            list_del(&(page->page_link));// 从空闲块链表中移除空闲块 page
            // 持续分裂，直到获得大小相同的块
            while (page->property > n) {
                struct Page *p = page + (page->property >> 1);// 分裂当前空闲块成两个块
                p->property = page->property >> 1;// 设置 p 的大小为空闲块的一半
                SetPageProperty(p);// 标记 p 这个块为空闲块 
                list_add(prev, &(p->page_link));// 将 p 插入到空闲块链表中
                page->property >>= 1;// 将当前空闲块的大小减半
            }
            
            nr_free -= n;// 更新空闲页计数器
            ClearPageProperty(page);
        }
        cprintf("最终分配的空闲块 p 的页数为: %d\n", page->property);
        return page;
    }

此过程主要完成任务如下：

- 将输入的所需页面大小进行处理。处理后n如果超过最大可分配内存，则直接返回。

- 找到内存中第一个块大小>=n的块（此处采用了first_fit的策略，速度较快）。然后对此块进行分裂，将多余的页面作为新的空闲块重新插入到空闲块链表中，直到有块大小=n。

- 更新空闲页计数器，并调用 ClearPageProperty(page) ，表示此块已经进行分配。

### 内存释放
我开始的时候思考了是释放内存时候输入的n是向上取值还是向下取值，然后考虑了一个较为简单的情况，即我们释放的都是前面已经分配的一整块内存，此时需要向上取整。在此基础上继续进行编写，如下：

    static void
    buddy_system_free_pages(struct Page *base, size_t n) {
        if(base==NULL)
            return;//这个主要为了后面测试案例的特殊情况而写，实际意义不大。
        assert(n > 0);
        n = round_up_pow2(n);
        // 遍历该块的每个页, 将其标记为未使用, 并将页面引用计数清零
        struct Page *p = base;
        for (; p != base + n; p ++) {
            assert(!PageReserved(p) && !PageProperty(p));
            p->flags = 0;
            set_page_ref(p, 0);// 页面引用计数清零 
        }
        base->property = n;// 将起始页的 property 设置为 n，表示这是一个大小为 n 页的空闲块
        SetPageProperty(base);// 标记 base 这个块为空闲块 
        nr_free += n;// 更新空闲页计数器
        // 将 base 插入到空闲块链表中
        if (list_empty(&free_list)) {
            list_add(&free_list, &(base->page_link));
        } else {
            list_entry_t* le = &free_list;
            while ((le = list_next(le)) != &free_list) {
                struct Page* page = le2page(le, page_link);
                if (base < page) {
                    list_add_before(le, &(base->page_link));
                    break;
                } else if (list_next(le) == &free_list) {
                    list_add(le, &(base->page_link));
                }
            }
        }
        
        // 尝试合并相邻的空闲块
        int merged = 1;  // 标记是否进行了合并
        while (merged && base->property < MAX_INIT_PAGES) {
            merged = 0;
            cprintf("当前块的地址为: 0x%016lx.\n", base);
            cprintf("当前块的页数为: %d\n\n", base->property);
            // 检查前一块是否可以合并
            list_entry_t* le = list_prev(&(base->page_link));// 找到 base 前面的块
            if (le != &free_list) {
                struct Page *p = le2page(le, page_link);
                cprintf("找到 base 前面的块 p\n");
                cprintf("块 p 的地址为: 0x%016lx.\n", p);
                cprintf("块 p 的页数为: %d\n", p->property);
            
                if (p + p->property == base && p->property == base->property) {// 前一空闲块和当前块大小相同
                    cprintf("伙伴块的地址为: 0x%016lx.\n", p);
                    cprintf("伙伴块的页数为: %d\n", base->property);
                
                    // 合并前，先检查合并后的相对首地址是否为合并后块大小的整数倍
                    size_t relative_addr = (size_t)p - MEM_BEGIN; // 计算 p 的相对起始地址
                    cprintf("合并后的相对首地址为: 0x%016lx.\n", relative_addr);
                    size_t block_size = (p->property << 1) * sizeof(struct Page);//合并后的块大小
                    cprintf("合并后的块大小为: 0x%016lx.\n", block_size);
                    if (relative_addr % block_size == 0) { // 如果合并后的相对首地址是合并后的块大小的整数倍
                        cprintf("合并成功\n");
                        p->property <<= 1;
                        ClearPageProperty(base);
                        list_del(&(base->page_link));
                        base = p;
                        merged = 1; // 标记为合并
                        cprintf("合并后的块的地址为: 0x%016lx.\n", base);
                        cprintf("合并后的块的块页数为: %d\n\n", base->property);
                    }
                }
            }
            // 检查后一块是否可以合并
            le = list_next(&(base->page_link));// 找到 base 后面的块
            if (le != &free_list) {
                struct Page *p = le2page(le, page_link);
                cprintf("找到 base 后面的块 p\n");
                cprintf("块 p 的地址为: 0x%016lx.\n", p);
                cprintf("块 p 的页数为: %d\n\n", p->property);
                if (base + base->property == p && base->property == p->property) {// 当前块和后一空闲块大小相同
                    cprintf("伙伴块的地址为: 0x%016lx.\n", p);
                    cprintf("伙伴块的页数为: %d\n", p->property);
                    // 合并前，先检查合并后的相对首地址是否为合并后块大小的整数倍
                    size_t relative_addr = (size_t)base - MEM_BEGIN; // 计算 base 的相对起始地址
                    cprintf("合并后的相对首地址为: 0x%016lx.\n", relative_addr);
                    size_t block_size = (base->property << 1) * sizeof(struct Page);//合并后的块大小
                    cprintf("合并后的块大小为: 0x%016lx.\n", block_size);
                    if (relative_addr % block_size == 0) { // 如果合并后的相对首地址是合并后的块大小的整数倍
                        cprintf("合并成功\n");
                        base->property <<= 1;
                        ClearPageProperty(p);
                        list_del(&(p->page_link));
                        merged = 1; // 标记为合并
                        cprintf("合并后的块的地址为: 0x%016lx.\n", base);
                        cprintf("合并后的块的块页数为: %d\n\n", base->property);
                    }
                }
            }
            if(!merged){
                cprintf("没有找到可以合并的伙伴块\n\n");
            }
            else{
                cprintf("继续尝试合并……\n\n");
            }
        }
    }
- 我开始并未意识到使用MEM_BEGIN计算相对位置有什么用，想当然认为只要两块内存大小相同且内存地址相连就可以合并，直到构造出例子：

    1（0），1（1），1（2），1（3），4，8
其中大小为1的Page都被占用，现在开始释放内存，先释放1（1）处，再释放1（2）处，发现两个地方虽满足内存大小相同且内存地址相连的条件，但是不能合并（如果合并，那么后序释放1（3）或1（0）等内存也不能正确合并）。因此增添判断条件：对于 buddy 合并，左边块的起始地址（相对于 MEM_BEGIN）必须是 “合并后块大小” 的整数倍。

- merged用于减少代码的时间复杂度。当一个base块既不能和前面的块合并，又不能和后面的块合并时，就可以直接跳出循环，这样充分节省了时间。

### 测试样例

其中basic_check只是用于进行简单检验，采用了和default_pmm相同的策略，此处不再赘述。

    static void
    buddy_system_check(void) {
            basic_check();//先通过基础测试
            cprintf("=========后序测试开始=========\n");
            int count = 0, total = 0;
            list_entry_t *le = &free_list;

            // 计算当前空闲块数目和空闲页数目,确定初始只有一个块。
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
            }
            assert(total == nr_free_pages());

            cprintf("空闲块数目为: %d\n", count);
            cprintf("空闲页数目为: %d\n", nr_free);

            //basic_check();

            cprintf("--------------------------------------------\n");
            cprintf("p0请求6页\n");
            struct Page *p0 = alloc_pages(6);  // 请求 6 页

            int i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("--------------------------------------------\n");

            cprintf("p1请求6页\n");
            struct Page *p1 = alloc_pages(6);  // 请求 6 页

            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("--------------------------------------------\n");

            cprintf("p2请求18页\n");
            struct Page *p2 = alloc_pages(18);  // 请求 18 页

            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("--------------------------------------------\n");

            cprintf("p3请求7页\n");
            struct Page *p3 = alloc_pages(7);   // 请求 7 页

            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("--------------------------------------------\n");


            cprintf("p4请求66页\n");
            struct Page *p4 = alloc_pages(66);   // 请求 66 页

            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("--------------------------------------------\n");

            // 确保分配的页是不同的
            assert(p0 != p1 && p0 != p2 && p0 != p3 && p0!=p4);
            assert(p1 != p2 && p1 != p3 && p1 != p4 );
            assert( p2 != p3 && p2 != p4 );
            assert( p3 != p4 );
            // 确保分配页的引用计数为 0
            assert(page_ref(p0) == 0 && page_ref(p1) == 0 
                && page_ref(p2) == 0 && page_ref(p3) == 0 && page_ref(p4) ==0);

            // 确保分配的页地址在物理内存范围内
            assert(page2pa(p0) < npage * PGSIZE);
            assert(page2pa(p1) < npage * PGSIZE);
            assert(page2pa(p2) < npage * PGSIZE);
            assert(page2pa(p3) < npage * PGSIZE);
            assert(page2pa(p4) < npage * PGSIZE);

            // 释放 p1
            cprintf("释放p1\n");
            free_pages(p1, 6);
            le = &free_list;
            count = 0, total = 0;
            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("释放p1后，空闲块数目为: %d\n", count);
            cprintf("释放p1后，空闲页数目为: %d\n\n", total);

            cprintf("--------------------------------------------\n");

            // 释放 p3
            cprintf("释放p3\n");
            free_pages(p3, 7);
            le = &free_list;
            count = 0, total = 0;
            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("释放p3后，空闲块数目为: %d\n", count);
            cprintf("释放p3后，空闲页数目为: %d\n\n", total);

            cprintf("--------------------------------------------\n");

            // 释放 p2
            cprintf("释放p2\n");
            free_pages(p2, 18);
            le = &free_list;
            count = 0, total = 0;
            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("释放p2后，空闲块数目为: %d\n", count);
            cprintf("释放p2后，空闲页数目为: %d\n\n", total);
            cprintf("--------------------------------------------\n");

            // 释放 p0
            cprintf("释放p0\n");
            free_pages(p0, 6);
            le = &free_list;
            count = 0, total = 0;
            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("释放p0后，空闲块数目为: %d\n", count);
            cprintf("释放p0后，空闲页数目为: %d\n\n", total);
            cprintf("--------------------------------------------\n");

            //尝试分配一个超大内存
            cprintf("p5请求16384页\n");
            struct Page *p5 = alloc_pages(16384);   // 请求16384 页，显然现在不行

            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("--------------------------------------------\n");
            // 释放 p4
            cprintf("释放p5\n");
            free_pages(p5, 16384);
            le = &free_list;
            count = 0, total = 0;
            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("释放p5后，空闲块数目为: %d\n", count);
            cprintf("释放p5后，空闲页数目为: %d\n\n", total);
            cprintf("--------------------------------------------\n");

            // 释放 p4
            cprintf("释放p4\n");
            free_pages(p4, 66);
            le = &free_list;
            count = 0, total = 0;
            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("释放p4后，空闲块数目为: %d\n", count);
            cprintf("释放p4后，空闲页数目为: %d\n\n", total);
            cprintf("--------------------------------------------\n");

            //继续尝试分配一个超大内存
            cprintf("p5请求16384页\n");
            p5 = alloc_pages(16384);   // 请求16384 页，显然现在不行

            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("--------------------------------------------\n");

            //释放
            cprintf("释放p5\n");
            free_pages(p5, 16384);
            le = &free_list;
            count = 0, total = 0;
            i=1;
            while ((le = list_next(le)) != &free_list) {
                struct Page *p = le2page(le, page_link);
                assert(PageProperty(p));
                count ++, total += p->property;
                cprintf("空闲块%d的虚拟地址为:0x%016lx.\n", i, p);
                cprintf("空闲页数目为: %d\n\n", p->property);
                i+=1;
            }

            cprintf("释放p5后，空闲块数目为: %d\n", count);
            cprintf("释放p5后，空闲页数目为: %d\n\n", total);
            cprintf("--------------------------------------------\n");

            // 清空空闲页计数，再尝试分配内存块
            unsigned int nr_free_store = nr_free;// 暂存当前的空闲页数目
            cprintf("清空空闲页！\n");
            nr_free = 0;
            // p6 请求 1 页
            cprintf("p6请求1页\n");
            struct Page *p6 = alloc_pages(1);
            assert(p6 == NULL);
            cprintf("分配失败，空闲页数目为: %d\n", nr_free);
            nr_free = nr_free_store;// 恢复空闲页数目

            cprintf("=========测试全部结束=========\n");
        }
此过程主要包含以下几部分：
- basic_check的进行，对代码功能进行简单验证。
- 多次分配和释放不同大小的块。
- 对我在上文提到内存释放部分的特殊例子进行检验，看新编写代码是否能实现此功能。
- 及大块分配和释放过程的检验。
- 当空闲块数量为0时分配的尝试。

### 接口
    const struct pmm_manager buddy_system_pmm_manager = {
        .name = "buddy_system_pmm_manager",
        .init = buddy_system_init,
        .init_memmap = buddy_system_init_memmap,
        .alloc_pages = buddy_system_alloc_pages,
        .free_pages = buddy_system_free_pages,
        .nr_free_pages = buddy_system_nr_free_pages,
        .check = buddy_system_check,
    };

### 其他文件所需的改动
- 编写对应的.h文件

        #ifndef __KERN_MM_DEFAULT_PMM_H__
        #define  __KERN_MM_DEFAULT_PMM_H__

        #include <pmm.h>

        extern const struct pmm_manager default_pmm_manager;

        #endif /* ! __KERN_MM_DEFAULT_PMM_H__ */


- 在pmm.c文件中增加
  
        #include <buddy_system_pmm.h>
且修改对应语句为

        pmm_manager = &buddy_system_pmm_manager;

## 运行结果展示
由于输出结果过长我就在结果前进行说明。

首先进行了basic_check的检测，即分配3个大小为1的内存空间，然后检测它们分配页非空，分配到不同的页，第一次分配时引用次数为0，大小没有越界，还检测了它们的正确释放。

后序检测是在basic_check正确完成的基础上进行的。basic_check正确完成后，我们有一块完整的大小为16384的内存空间。在此基础上进行内存的分配和释放。测试了前文提到的特殊情况、超大块内存的分配和释放、空闲页数为0时的分配问题，都成功完成。

    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210340.
    准备分配的空闲块 p 的页数为: 16384
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 1
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210368.
    准备分配的空闲块 p 的页数为: 1
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 1
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210390.
    准备分配的空闲块 p 的页数为: 2
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 1
    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 1

    没有找到可以合并的伙伴块

    当前块的地址为: 0xffffffffc0210368.
    当前块的页数为: 1

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210368.
    块 p 的页数为: 1
    没有找到可以合并的伙伴块

    当前块的地址为: 0xffffffffc0210390.
    当前块的页数为: 1

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210390.
    块 p 的页数为: 1
    没有找到可以合并的伙伴块

    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210340.
    准备分配的空闲块 p 的页数为: 1
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 1
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210368.
    准备分配的空闲块 p 的页数为: 1
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 1
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210390.
    准备分配的空闲块 p 的页数为: 1
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 1
    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 1

    没有找到可以合并的伙伴块

    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210340.
    准备分配的空闲块 p 的页数为: 1
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 1
    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 1

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc02103b8.
    块 p 的页数为: 1

    没有找到可以合并的伙伴块

    当前块的地址为: 0xffffffffc0210368.
    当前块的页数为: 1

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210340.
    块 p 的页数为: 1
    伙伴块的地址为: 0xffffffffc0210340.
    伙伴块的页数为: 1
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000050.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 2

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc02103b8.
    块 p 的页数为: 1

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 2

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc02103b8.
    块 p 的页数为: 1

    没有找到可以合并的伙伴块

    当前块的地址为: 0xffffffffc0210390.
    当前块的页数为: 1

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210340.
    块 p 的页数为: 2
    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc02103b8.
    块 p 的页数为: 1

    伙伴块的地址为: 0xffffffffc02103b8.
    伙伴块的页数为: 1
    合并后的相对首地址为: 0x0000000000000050.
    合并后的块大小为: 0x0000000000000050.
    合并成功
    合并后的块的地址为: 0xffffffffc0210390.
    合并后的块的块页数为: 2

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210390.
    当前块的页数为: 2

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210340.
    块 p 的页数为: 2
    伙伴块的地址为: 0xffffffffc0210340.
    伙伴块的页数为: 2
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x00000000000000a0.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 4

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc02103e0.
    块 p 的页数为: 4

    伙伴块的地址为: 0xffffffffc02103e0.
    伙伴块的页数为: 4
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000140.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 8

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 8

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210480.
    块 p 的页数为: 8

    伙伴块的地址为: 0xffffffffc0210480.
    伙伴块的页数为: 8
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000280.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 16

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 16

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc02105c0.
    块 p 的页数为: 16

    伙伴块的地址为: 0xffffffffc02105c0.
    伙伴块的页数为: 16
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000500.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 32

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 32

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210840.
    块 p 的页数为: 32

    伙伴块的地址为: 0xffffffffc0210840.
    伙伴块的页数为: 32
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000a00.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 64

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 64

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210d40.
    块 p 的页数为: 64

    伙伴块的地址为: 0xffffffffc0210d40.
    伙伴块的页数为: 64
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000001400.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 128

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 128

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0211740.
    块 p 的页数为: 128

    伙伴块的地址为: 0xffffffffc0211740.
    伙伴块的页数为: 128
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000002800.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 256

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 256

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0212b40.
    块 p 的页数为: 256

    伙伴块的地址为: 0xffffffffc0212b40.
    伙伴块的页数为: 256
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000005000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 512

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 512

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0215340.
    块 p 的页数为: 512

    伙伴块的地址为: 0xffffffffc0215340.
    伙伴块的页数为: 512
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x000000000000a000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 1024

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 1024

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc021a340.
    块 p 的页数为: 1024

    伙伴块的地址为: 0xffffffffc021a340.
    伙伴块的页数为: 1024
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000014000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 2048

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 2048

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0224340.
    块 p 的页数为: 2048

    伙伴块的地址为: 0xffffffffc0224340.
    伙伴块的页数为: 2048
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000028000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 4096

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 4096

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0238340.
    块 p 的页数为: 4096

    伙伴块的地址为: 0xffffffffc0238340.
    伙伴块的页数为: 4096
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000050000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 8192

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 8192

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0260340.
    块 p 的页数为: 8192

    伙伴块的地址为: 0xffffffffc0260340.
    伙伴块的页数为: 8192
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x00000000000a0000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 16384

    继续尝试合并……

    =========测试开始=========
    空闲块数目为: 1
    空闲页数目为: 16384
    --------------------------------------------
    p0请求6页
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210340.
    准备分配的空闲块 p 的页数为: 16384
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 8
    空闲块1的虚拟地址为:0xffffffffc0210480.
    空闲页数目为: 8

    空闲块2的虚拟地址为:0xffffffffc02105c0.
    空闲页数目为: 16

    空闲块3的虚拟地址为:0xffffffffc0210840.
    空闲页数目为: 32

    空闲块4的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块5的虚拟地址为:0xffffffffc0211740.
    空闲页数目为: 128

    空闲块6的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块7的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块8的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块9的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块10的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块11的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    --------------------------------------------
    p1请求6页
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210480.
    准备分配的空闲块 p 的页数为: 8
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 8
    空闲块1的虚拟地址为:0xffffffffc02105c0.
    空闲页数目为: 16

    空闲块2的虚拟地址为:0xffffffffc0210840.
    空闲页数目为: 32

    空闲块3的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块4的虚拟地址为:0xffffffffc0211740.
    空闲页数目为: 128

    空闲块5的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块6的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块7的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块8的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块9的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块10的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    --------------------------------------------
    p2请求18页
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210840.
    准备分配的空闲块 p 的页数为: 32
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 32
    空闲块1的虚拟地址为:0xffffffffc02105c0.
    空闲页数目为: 16

    空闲块2的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块3的虚拟地址为:0xffffffffc0211740.
    空闲页数目为: 128

    空闲块4的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块5的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块6的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块7的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块8的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块9的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    --------------------------------------------
    p3请求7页
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc02105c0.
    准备分配的空闲块 p 的页数为: 16
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 8
    空闲块1的虚拟地址为:0xffffffffc0210700.
    空闲页数目为: 8

    空闲块2的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块3的虚拟地址为:0xffffffffc0211740.
    空闲页数目为: 128

    空闲块4的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块5的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块6的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块7的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块8的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块9的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    --------------------------------------------
    p4请求66页
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0211740.
    准备分配的空闲块 p 的页数为: 128
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 128
    空闲块1的虚拟地址为:0xffffffffc0210700.
    空闲页数目为: 8

    空闲块2的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块3的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块4的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块5的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块6的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块7的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块8的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    --------------------------------------------
    释放p1
    当前块的地址为: 0xffffffffc0210480.
    当前块的页数为: 8

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210700.
    块 p 的页数为: 8

    没有找到可以合并的伙伴块

    空闲块1的虚拟地址为:0xffffffffc0210480.
    空闲页数目为: 8

    空闲块2的虚拟地址为:0xffffffffc0210700.
    空闲页数目为: 8

    空闲块3的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块4的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块5的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块6的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块7的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块8的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块9的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    释放p1后，空闲块数目为: 9
    释放p1后，空闲页数目为: 16208

    --------------------------------------------
    释放p3
    当前块的地址为: 0xffffffffc02105c0.
    当前块的页数为: 8

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210480.
    块 p 的页数为: 8
    伙伴块的地址为: 0xffffffffc0210480.
    伙伴块的页数为: 8
    合并后的相对首地址为: 0x0000000000000140.
    合并后的块大小为: 0x0000000000000280.
    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210700.
    块 p 的页数为: 8

    伙伴块的地址为: 0xffffffffc0210700.
    伙伴块的页数为: 8
    合并后的相对首地址为: 0x0000000000000280.
    合并后的块大小为: 0x0000000000000280.
    合并成功
    合并后的块的地址为: 0xffffffffc02105c0.
    合并后的块的块页数为: 16

    继续尝试合并……

    当前块的地址为: 0xffffffffc02105c0.
    当前块的页数为: 16

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210480.
    块 p 的页数为: 8
    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210d40.
    块 p 的页数为: 64

    没有找到可以合并的伙伴块

    空闲块1的虚拟地址为:0xffffffffc0210480.
    空闲页数目为: 8

    空闲块2的虚拟地址为:0xffffffffc02105c0.
    空闲页数目为: 16

    空闲块3的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块4的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块5的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块6的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块7的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块8的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块9的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    释放p3后，空闲块数目为: 9
    释放p3后，空闲页数目为: 16216

    --------------------------------------------
    释放p2
    当前块的地址为: 0xffffffffc0210840.
    当前块的页数为: 32

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc02105c0.
    块 p 的页数为: 16
    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210d40.
    块 p 的页数为: 64

    没有找到可以合并的伙伴块

    空闲块1的虚拟地址为:0xffffffffc0210480.
    空闲页数目为: 8

    空闲块2的虚拟地址为:0xffffffffc02105c0.
    空闲页数目为: 16

    空闲块3的虚拟地址为:0xffffffffc0210840.
    空闲页数目为: 32

    空闲块4的虚拟地址为:0xffffffffc0210d40.
    空闲页数目为: 64

    空闲块5的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块6的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块7的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块8的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块9的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块10的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    释放p2后，空闲块数目为: 10
    释放p2后，空闲页数目为: 16248

    --------------------------------------------
    释放p0
    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 8

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210480.
    块 p 的页数为: 8

    伙伴块的地址为: 0xffffffffc0210480.
    伙伴块的页数为: 8
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000280.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 16

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 16

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc02105c0.
    块 p 的页数为: 16

    伙伴块的地址为: 0xffffffffc02105c0.
    伙伴块的页数为: 16
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000500.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 32

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 32

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210840.
    块 p 的页数为: 32

    伙伴块的地址为: 0xffffffffc0210840.
    伙伴块的页数为: 32
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000000a00.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 64

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 64

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0210d40.
    块 p 的页数为: 64

    伙伴块的地址为: 0xffffffffc0210d40.
    伙伴块的页数为: 64
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000001400.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 128

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 128

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0212b40.
    块 p 的页数为: 256

    没有找到可以合并的伙伴块

    空闲块1的虚拟地址为:0xffffffffc0210340.
    空闲页数目为: 128

    空闲块2的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块3的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块4的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块5的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块6的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块7的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    释放p0后，空闲块数目为: 7
    释放p0后，空闲页数目为: 16256

    --------------------------------------------
    p5请求16384页
    空闲块1的虚拟地址为:0xffffffffc0210340.
    空闲页数目为: 128

    空闲块2的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块3的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块4的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块5的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块6的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块7的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    --------------------------------------------
    释放p5
    空闲块1的虚拟地址为:0xffffffffc0210340.
    空闲页数目为: 128

    空闲块2的虚拟地址为:0xffffffffc0212b40.
    空闲页数目为: 256

    空闲块3的虚拟地址为:0xffffffffc0215340.
    空闲页数目为: 512

    空闲块4的虚拟地址为:0xffffffffc021a340.
    空闲页数目为: 1024

    空闲块5的虚拟地址为:0xffffffffc0224340.
    空闲页数目为: 2048

    空闲块6的虚拟地址为:0xffffffffc0238340.
    空闲页数目为: 4096

    空闲块7的虚拟地址为:0xffffffffc0260340.
    空闲页数目为: 8192

    释放p5后，空闲块数目为: 7
    释放p5后，空闲页数目为: 16256

    --------------------------------------------
    释放p4
    当前块的地址为: 0xffffffffc0211740.
    当前块的页数为: 128

    找到 base 前面的块 p
    块 p 的地址为: 0xffffffffc0210340.
    块 p 的页数为: 128
    伙伴块的地址为: 0xffffffffc0210340.
    伙伴块的页数为: 128
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000002800.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 256

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0212b40.
    块 p 的页数为: 256

    伙伴块的地址为: 0xffffffffc0212b40.
    伙伴块的页数为: 256
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000005000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 512

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 512

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0215340.
    块 p 的页数为: 512

    伙伴块的地址为: 0xffffffffc0215340.
    伙伴块的页数为: 512
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x000000000000a000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 1024

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 1024

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc021a340.
    块 p 的页数为: 1024

    伙伴块的地址为: 0xffffffffc021a340.
    伙伴块的页数为: 1024
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000014000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 2048

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 2048

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0224340.
    块 p 的页数为: 2048

    伙伴块的地址为: 0xffffffffc0224340.
    伙伴块的页数为: 2048
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000028000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 4096

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 4096

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0238340.
    块 p 的页数为: 4096

    伙伴块的地址为: 0xffffffffc0238340.
    伙伴块的页数为: 4096
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x0000000000050000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 8192

    继续尝试合并……

    当前块的地址为: 0xffffffffc0210340.
    当前块的页数为: 8192

    找到 base 后面的块 p
    块 p 的地址为: 0xffffffffc0260340.
    块 p 的页数为: 8192

    伙伴块的地址为: 0xffffffffc0260340.
    伙伴块的页数为: 8192
    合并后的相对首地址为: 0x0000000000000000.
    合并后的块大小为: 0x00000000000a0000.
    合并成功
    合并后的块的地址为: 0xffffffffc0210340.
    合并后的块的块页数为: 16384

    继续尝试合并……

    空闲块1的虚拟地址为:0xffffffffc0210340.
    空闲页数目为: 16384

    释放p4后，空闲块数目为: 1
    释放p4后，空闲页数目为: 16384

    --------------------------------------------
    p5请求16384页
    找到第一个满足要求的空闲块 p
    准备用于分配的空闲块 p 的地址为: 0xffffffffc0210340.
    准备分配的空闲块 p 的页数为: 16384
    开始分裂空闲块……

    最终分配的空闲块 p 的页数为: 16384
    --------------------------------------------
    释放p5
    空闲块1的虚拟地址为:0xffffffffc0210340.
    空闲页数目为: 16384

    释放p5后，空闲块数目为: 1
    释放p5后，空闲页数目为: 16384

    --------------------------------------------
    清空空闲页！
    p6请求1页
    分配失败，空闲页数目为: 0
    =========测试结束=========
