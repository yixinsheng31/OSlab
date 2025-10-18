#include "slub.h"
#include <defs.h>
#include <pmm.h>
#include <memlayout.h>
#include <string.h>
#include "stdio.h"

/* Two-layer simplified SLUB:
 * Layer 1 (page layer): use page allocator (alloc_pages/free_pages) to provide slabs.
 * Layer 2 (object layer): per-size-class caches allocate objects from slabs.
 * Implementation simplifications:
 * - slab size = 1 page
 * - maintain a page->owner map (which cache index owns this slab)
 * - no per-cpu caches, no fine-grained locking (single-core/demo oriented)
 */

#define SLUB_MIN_SHIFT 5 /* 32 bytes */
#define SLUB_MIN_SIZE (1 << SLUB_MIN_SHIFT)
#define SLUB_MAX_SHIFT 11 /* 2048 bytes */
#define SLUB_MAX_SIZE (1 << SLUB_MAX_SHIFT)
#define SLUB_NR_SIZES (SLUB_MAX_SHIFT - SLUB_MIN_SHIFT + 1)

typedef struct obj_head { 
    struct obj_head *next; 
    unsigned short owner_page; /* index in pages[] + 1, 0 means none */
} obj_head_t;

typedef struct kmem_cache {
    size_t size;           /* object size */
    obj_head_t *freelist;  /* free objects */
} kmem_cache_t;

static kmem_cache_t kmem_caches[SLUB_NR_SIZES];

/* page owner map: for each page in 'pages' array, store owning cache index+1, 0 = none */
static unsigned short page_owner_map[KMEMSIZE / PGSIZE];
static unsigned short page_freecount[KMEMSIZE / PGSIZE];

static inline int size_to_index(size_t size) {
    size_t s = SLUB_MIN_SIZE;
    int i = 0;
    while (i < SLUB_NR_SIZES && s < size) { s <<= 1; i++; }
    if (i >= SLUB_NR_SIZES) return -1;
    return i;
}

void slub_init(void) {
    for (int i = 0; i < SLUB_NR_SIZES; i++) {
        kmem_caches[i].size = SLUB_MIN_SIZE << i;
        kmem_caches[i].freelist = NULL;
    }
    /* clear owner map */
    memset(page_owner_map, 0, sizeof(page_owner_map));
}

/* carve one physical page into objects for cache 'idx' */
static void carve_slab_into_cache(int idx) {
    struct Page *pg = alloc_page();
    if (!pg) return;
    uintptr_t pa = page2pa(pg);
    void *kva = (void *)(pa + va_pa_offset);
    size_t objsz = kmem_caches[idx].size;
    size_t n = PGSIZE / objsz;
    char *p = (char *)kva;
    /* compute page index */
    int page_index = pg - pages; /* index into pages[] */
    if (page_index < 0 || page_index >= (int)(KMEMSIZE / PGSIZE)) {
        /* unable to track owner; just return */
        return;
    }
    /* mark page owner */
    page_owner_map[page_index] = (unsigned short)(idx + 1);
    for (size_t i = 0; i < n; i++) {
        obj_head_t *o = (obj_head_t *)p;
        o->next = kmem_caches[idx].freelist;
        o->owner_page = (unsigned short)(page_index + 1);
        kmem_caches[idx].freelist = o;
        p += objsz;
    }
    page_freecount[page_index] = (unsigned short)n;
}

void *kmalloc(size_t size) {
    if (size == 0) return NULL;
    if (size > SLUB_MAX_SIZE) {
        /* allocate whole pages */
        size_t np = (size + PGSIZE - 1) / PGSIZE;
        struct Page *p = alloc_pages(np);
        if (!p) return NULL;
        return (void *)(page2pa(p) + va_pa_offset);
    }
    int idx = size_to_index(size);
    if (idx < 0) return NULL;
    kmem_cache_t *cache = &kmem_caches[idx];
    if (!cache->freelist) {
        carve_slab_into_cache(idx);
        if (!cache->freelist) return NULL;
    }
    obj_head_t *o = cache->freelist;
    cache->freelist = o->next;
    /* decrement freecount for owning page */
    if (o->owner_page) {
        int owner_idx = (int)o->owner_page - 1;
        page_freecount[owner_idx]--;
    }
    return (void *)o;
}

void kfree(void *ptr) {
    if (!ptr) return;
    uintptr_t pa = (uintptr_t)ptr - va_pa_offset;
    /* validate pa by checking physical page number falls within managed pages */
    size_t _ppn = PPN(pa);
    if (_ppn < nbase || _ppn >= npage) {
        /* pointer outside managed physical pages; ignore */
        return;
    }
    struct Page *pg = pa2page(pa);
    int page_index = pg - pages;
    if (page_index < 0 || page_index >= (int)(KMEMSIZE / PGSIZE)) return;
    unsigned short owner = page_owner_map[page_index];
    if (owner == 0) {
        /* not a cached object: free whole page */
        free_page(pg);
        return;
    }
    int idx = (int)owner - 1;
    obj_head_t *o = (obj_head_t *)ptr;
    o->next = kmem_caches[idx].freelist;
    kmem_caches[idx].freelist = o;
    /* increment freecount for owning page */
    if (page_index >= 0) {
        page_freecount[page_index]++;
        /* If the whole page becomes free, remove its objects from the freelist and
         * return the page to the page allocator. This prevents stale page_owner_map
         * entries and makes slub_self_test's final checks consistent.
         */
        size_t objsz = kmem_caches[idx].size;
        unsigned short expected = (unsigned short)(PGSIZE / objsz);
        if (page_freecount[page_index] == expected) {
            /* remove objects that belong to this page from the cache freelist */
            obj_head_t *new_head = NULL;
            obj_head_t *cur = kmem_caches[idx].freelist;
            while (cur) {
                obj_head_t *next = cur->next;
                if (cur->owner_page == (unsigned short)(page_index + 1)) {
                    /* skip objects from this page */
                } else {
                    cur->next = new_head;
                    new_head = cur;
                }
                cur = next;
            }
            kmem_caches[idx].freelist = new_head;
            /* clear owner map and free the page */
            page_owner_map[page_index] = 0;
            page_freecount[page_index] = 0;
            free_page(pg);
            return;
        }
    }
}

/* Stronger self-test: allocate many objects across size-classes and free them */
void slub_self_test(void) {
    slub_init();
    const int N = 1024;
    void *ptrs[N];
    int alloced = 0, failed = 0;
    int per_class_alloc[SLUB_NR_SIZES];
    for (int i = 0; i < SLUB_NR_SIZES; i++) per_class_alloc[i] = 0;

    /* deterministic pseudo-random sequence */
    unsigned int seed = 12345;
    for (int i = 0; i < N; i++) {
        /* simple LCG */
        seed = seed * 1103515245 + 12345;
        int cls = seed % SLUB_NR_SIZES;
        size_t sz = kmem_caches[cls].size;
        ptrs[i] = kmalloc(sz - (SLUB_MIN_SIZE/4));
        if (ptrs[i]) {
            alloced++; per_class_alloc[cls]++;
            memset(ptrs[i], 0x5A, sz);
        } else {
            failed++;
        }
    }

        cprintf("slub_self_test: allocated=%d failed=%d\n", alloced, failed);
    for (int i = 0; i < SLUB_NR_SIZES; i++) {
            cprintf("class %d size %u allocated %d\n", i, (unsigned int)kmem_caches[i].size, per_class_alloc[i]);
    }

    /* sanity checks: record which pages are owned before freeing */
    size_t total_pages = KMEMSIZE / PGSIZE;
    uint8_t *was_owner = (uint8_t *)kmalloc(total_pages * sizeof(uint8_t));
    if (!was_owner) {
        cprintf("slub_self_test: cannot allocate was_owner buffer\n");
        return;
    }
    for (size_t pi = 0; pi < total_pages; pi++) was_owner[pi] = page_owner_map[pi] ? 1 : 0;

    for (int i = N - 1; i >= 0; i--) if (ptrs[i]) kfree(ptrs[i]);

    int errors = 0;
    int reclaimed = 0;
    for (size_t pi = 0; pi < total_pages; pi++) {
        if (!was_owner[pi]) continue;
        if (page_owner_map[pi] == 0) {
            /* page got reclaimed by kfree */
            reclaimed++;
            continue;
        }
        int idx = page_owner_map[pi] - 1;
        size_t objsz = kmem_caches[idx].size;
        unsigned short expected = (unsigned short)(PGSIZE / objsz);
        if (page_freecount[pi] != expected) {
            cprintf("slub_self_test: page %u freecount %u expected %u\n", (unsigned int)pi, (unsigned int)page_freecount[pi], (unsigned int)expected);
            errors++;
        }
    }

    cprintf("slub_self_test: reclaimed_pages=%d errors=%d\n", reclaimed, errors);
    if (errors == 0) cprintf("slub_self_test completed OK\n");
    else cprintf("slub_self_test completed with %d errors\n", errors);

    /* free temporary buffer */
    kfree(was_owner);
}
