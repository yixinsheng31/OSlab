#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *ptr);
void slub_self_test(void);

#endif /* __KERN_MM_SLUB_H__ */
