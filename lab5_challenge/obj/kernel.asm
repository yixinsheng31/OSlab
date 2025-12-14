
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000cb517          	auipc	a0,0xcb
ffffffffc020004e:	fce50513          	addi	a0,a0,-50 # ffffffffc02cb018 <buf>
ffffffffc0200052:	000cf617          	auipc	a2,0xcf
ffffffffc0200056:	46a60613          	addi	a2,a2,1130 # ffffffffc02cf4bc <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	7c0050ef          	jal	ra,ffffffffc0205822 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	7e258593          	addi	a1,a1,2018 # ffffffffc0205850 <etext+0x4>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0205870 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	2af020ef          	jal	ra,ffffffffc0202b34 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	31b030ef          	jal	ra,ffffffffc0203bac <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	6df040ef          	jal	ra,ffffffffc0204f74 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	06a050ef          	jal	ra,ffffffffc020510c <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	7bc50513          	addi	a0,a0,1980 # ffffffffc0205878 <etext+0x2c>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000cbb97          	auipc	s7,0xcb
ffffffffc02000d6:	f46b8b93          	addi	s7,s7,-186 # ffffffffc02cb018 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000cb517          	auipc	a0,0xcb
ffffffffc0200132:	eea50513          	addi	a0,a0,-278 # ffffffffc02cb018 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	276050ef          	jal	ra,ffffffffc02053fe <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	240050ef          	jal	ra,ffffffffc02053fe <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	66250513          	addi	a0,a0,1634 # ffffffffc0205880 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	66c50513          	addi	a0,a0,1644 # ffffffffc02058a0 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	60c58593          	addi	a1,a1,1548 # ffffffffc020584c <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	67850513          	addi	a0,a0,1656 # ffffffffc02058c0 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000cb597          	auipc	a1,0xcb
ffffffffc0200258:	dc458593          	addi	a1,a1,-572 # ffffffffc02cb018 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	68450513          	addi	a0,a0,1668 # ffffffffc02058e0 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000cf597          	auipc	a1,0xcf
ffffffffc020026c:	25458593          	addi	a1,a1,596 # ffffffffc02cf4bc <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	69050513          	addi	a0,a0,1680 # ffffffffc0205900 <etext+0xb4>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000cf597          	auipc	a1,0xcf
ffffffffc0200280:	63f58593          	addi	a1,a1,1599 # ffffffffc02cf8bb <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	68250513          	addi	a0,a0,1666 # ffffffffc0205920 <etext+0xd4>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	6a460613          	addi	a2,a2,1700 # ffffffffc0205950 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	6b050513          	addi	a0,a0,1712 # ffffffffc0205968 <etext+0x11c>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	6b860613          	addi	a2,a2,1720 # ffffffffc0205980 <etext+0x134>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	6d058593          	addi	a1,a1,1744 # ffffffffc02059a0 <etext+0x154>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	6d050513          	addi	a0,a0,1744 # ffffffffc02059a8 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	6d260613          	addi	a2,a2,1746 # ffffffffc02059b8 <etext+0x16c>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	6f258593          	addi	a1,a1,1778 # ffffffffc02059e0 <etext+0x194>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	6b250513          	addi	a0,a0,1714 # ffffffffc02059a8 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	6ee60613          	addi	a2,a2,1774 # ffffffffc02059f0 <etext+0x1a4>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	70658593          	addi	a1,a1,1798 # ffffffffc0205a10 <etext+0x1c4>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	69650513          	addi	a0,a0,1686 # ffffffffc02059a8 <etext+0x15c>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	6d450513          	addi	a0,a0,1748 # ffffffffc0205a20 <etext+0x1d4>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	6da50513          	addi	a0,a0,1754 # ffffffffc0205a48 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	734c0c13          	addi	s8,s8,1844 # ffffffffc0205ab8 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	6e490913          	addi	s2,s2,1764 # ffffffffc0205a70 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	6e448493          	addi	s1,s1,1764 # ffffffffc0205a78 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	6e2b0b13          	addi	s6,s6,1762 # ffffffffc0205a80 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	5faa0a13          	addi	s4,s4,1530 # ffffffffc02059a0 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	6f0d0d13          	addi	s10,s10,1776 # ffffffffc0205ab8 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	3f2050ef          	jal	ra,ffffffffc02057c8 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	3de050ef          	jal	ra,ffffffffc02057c8 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	3e4050ef          	jal	ra,ffffffffc020580c <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	3a6050ef          	jal	ra,ffffffffc020580c <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	62050513          	addi	a0,a0,1568 # ffffffffc0205aa0 <etext+0x254>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000cf317          	auipc	t1,0xcf
ffffffffc0200492:	fb230313          	addi	t1,t1,-78 # ffffffffc02cf440 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	64450513          	addi	a0,a0,1604 # ffffffffc0205b00 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	78650513          	addi	a0,a0,1926 # ffffffffc0206c58 <default_pmm_manager+0x520>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	61a50513          	addi	a0,a0,1562 # ffffffffc0205b20 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	73250513          	addi	a0,a0,1842 # ffffffffc0206c58 <default_pmm_manager+0x520>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_cowtest_out_size+0xd168>
ffffffffc0200540:	000cf717          	auipc	a4,0xcf
ffffffffc0200544:	f0f73823          	sd	a5,-240(a4) # ffffffffc02cf450 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	5e050513          	addi	a0,a0,1504 # ffffffffc0205b40 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000cf797          	auipc	a5,0xcf
ffffffffc020056c:	ee07b023          	sd	zero,-288(a5) # ffffffffc02cf448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000cf797          	auipc	a5,0xcf
ffffffffc020057a:	eda7b783          	ld	a5,-294(a5) # ffffffffc02cf450 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	56050513          	addi	a0,a0,1376 # ffffffffc0205b60 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	54250513          	addi	a0,a0,1346 # ffffffffc0205b70 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	53c50513          	addi	a0,a0,1340 # ffffffffc0205b80 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	54450513          	addi	a0,a0,1348 # ffffffffc0205b98 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe10a31>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	4da90913          	addi	s2,s2,1242 # ffffffffc0205be8 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	4c448493          	addi	s1,s1,1220 # ffffffffc0205be0 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	4f050513          	addi	a0,a0,1264 # ffffffffc0205c60 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	51c50513          	addi	a0,a0,1308 # ffffffffc0205c98 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	3fc50513          	addi	a0,a0,1020 # ffffffffc0205bb8 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	7b7040ef          	jal	ra,ffffffffc0205780 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	00e050ef          	jal	ra,ffffffffc02057e6 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	75b040ef          	jal	ra,ffffffffc02057c8 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	36e50513          	addi	a0,a0,878 # ffffffffc0205bf0 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	2c050513          	addi	a0,a0,704 # ffffffffc0205c10 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	2c650513          	addi	a0,a0,710 # ffffffffc0205c28 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	2d450513          	addi	a0,a0,724 # ffffffffc0205c48 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	31850513          	addi	a0,a0,792 # ffffffffc0205c98 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000cf797          	auipc	a5,0xcf
ffffffffc020098c:	ac87b823          	sd	s0,-1328(a5) # ffffffffc02cf458 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000cf797          	auipc	a5,0xcf
ffffffffc0200994:	ad67b823          	sd	s6,-1328(a5) # ffffffffc02cf460 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000cf517          	auipc	a0,0xcf
ffffffffc020099e:	abe53503          	ld	a0,-1346(a0) # ffffffffc02cf458 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000cf517          	auipc	a0,0xcf
ffffffffc02009a8:	abc53503          	ld	a0,-1348(a0) # ffffffffc02cf460 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	73878793          	addi	a5,a5,1848 # ffffffffc02010f8 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	2d250513          	addi	a0,a0,722 # ffffffffc0205cb0 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	2da50513          	addi	a0,a0,730 # ffffffffc0205cc8 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	2e450513          	addi	a0,a0,740 # ffffffffc0205ce0 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	2ee50513          	addi	a0,a0,750 # ffffffffc0205cf8 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	2f850513          	addi	a0,a0,760 # ffffffffc0205d10 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	30250513          	addi	a0,a0,770 # ffffffffc0205d28 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	30c50513          	addi	a0,a0,780 # ffffffffc0205d40 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	31650513          	addi	a0,a0,790 # ffffffffc0205d58 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	32050513          	addi	a0,a0,800 # ffffffffc0205d70 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	32a50513          	addi	a0,a0,810 # ffffffffc0205d88 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	33450513          	addi	a0,a0,820 # ffffffffc0205da0 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	33e50513          	addi	a0,a0,830 # ffffffffc0205db8 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	34850513          	addi	a0,a0,840 # ffffffffc0205dd0 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	35250513          	addi	a0,a0,850 # ffffffffc0205de8 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	35c50513          	addi	a0,a0,860 # ffffffffc0205e00 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	36650513          	addi	a0,a0,870 # ffffffffc0205e18 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	37050513          	addi	a0,a0,880 # ffffffffc0205e30 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	37a50513          	addi	a0,a0,890 # ffffffffc0205e48 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	38450513          	addi	a0,a0,900 # ffffffffc0205e60 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	38e50513          	addi	a0,a0,910 # ffffffffc0205e78 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	39850513          	addi	a0,a0,920 # ffffffffc0205e90 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	3a250513          	addi	a0,a0,930 # ffffffffc0205ea8 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	3ac50513          	addi	a0,a0,940 # ffffffffc0205ec0 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	3b650513          	addi	a0,a0,950 # ffffffffc0205ed8 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	3c050513          	addi	a0,a0,960 # ffffffffc0205ef0 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	3ca50513          	addi	a0,a0,970 # ffffffffc0205f08 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	3d450513          	addi	a0,a0,980 # ffffffffc0205f20 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	3de50513          	addi	a0,a0,990 # ffffffffc0205f38 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	3e850513          	addi	a0,a0,1000 # ffffffffc0205f50 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	3f250513          	addi	a0,a0,1010 # ffffffffc0205f68 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	3fc50513          	addi	a0,a0,1020 # ffffffffc0205f80 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	40250513          	addi	a0,a0,1026 # ffffffffc0205f98 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	40450513          	addi	a0,a0,1028 # ffffffffc0205fb0 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	40450513          	addi	a0,a0,1028 # ffffffffc0205fc8 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	40c50513          	addi	a0,a0,1036 # ffffffffc0205fe0 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	41450513          	addi	a0,a0,1044 # ffffffffc0205ff8 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	41050513          	addi	a0,a0,1040 # ffffffffc0206008 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <pgfault_handler>:
static int handle_cow_fault(struct mm_struct *mm, uintptr_t fault_addr);

/* pgfault_handler - 统一的页面错误处理入口
 * 检查是否是COW相关的页面错误，如果是则调用专门的COW处理函数
 */
static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200c06:	715d                	addi	sp,sp,-80
ffffffffc0200c08:	f84a                	sd	s2,48(sp)
    uintptr_t fault_addr = tf->tval;
    uint32_t cause = tf->cause;
    
    // 基本检查：确保在用户态且有有效的内存管理结构
    if (current == NULL || current->mm == NULL) {
ffffffffc0200c0a:	000cf917          	auipc	s2,0xcf
ffffffffc0200c0e:	89690913          	addi	s2,s2,-1898 # ffffffffc02cf4a0 <current>
ffffffffc0200c12:	00093783          	ld	a5,0(s2)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200c16:	e0a2                	sd	s0,64(sp)
ffffffffc0200c18:	fc26                	sd	s1,56(sp)
ffffffffc0200c1a:	f44e                	sd	s3,40(sp)
ffffffffc0200c1c:	e486                	sd	ra,72(sp)
ffffffffc0200c1e:	f052                	sd	s4,32(sp)
ffffffffc0200c20:	ec56                	sd	s5,24(sp)
ffffffffc0200c22:	e85a                	sd	s6,16(sp)
ffffffffc0200c24:	e45e                	sd	s7,8(sp)
    uintptr_t fault_addr = tf->tval;
ffffffffc0200c26:	11053483          	ld	s1,272(a0)
    uint32_t cause = tf->cause;
ffffffffc0200c2a:	11852983          	lw	s3,280(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200c2e:	842a                	mv	s0,a0
    if (current == NULL || current->mm == NULL) {
ffffffffc0200c30:	16078863          	beqz	a5,ffffffffc0200da0 <pgfault_handler+0x19a>
ffffffffc0200c34:	779c                	ld	a5,40(a5)
ffffffffc0200c36:	16078563          	beqz	a5,ffffffffc0200da0 <pgfault_handler+0x19a>
        panic("page fault in kernel!");
    }
    
    // 获取页表项，检查是否是COW页面错误
    pde_t *pgdir = current->mm->pgdir;
    pte_t *ptep = get_pte(pgdir, fault_addr, 0);
ffffffffc0200c3a:	6f88                	ld	a0,24(a5)
ffffffffc0200c3c:	4601                	li	a2,0
ffffffffc0200c3e:	85a6                	mv	a1,s1
ffffffffc0200c40:	5a4010ef          	jal	ra,ffffffffc02021e4 <get_pte>
    
    // 判断是否为COW页面且是写操作导致的错误
    if (ptep != NULL && (*ptep & PTE_V) && (*ptep & PTE_COW)) {
ffffffffc0200c44:	12050163          	beqz	a0,ffffffffc0200d66 <pgfault_handler+0x160>
ffffffffc0200c48:	611c                	ld	a5,0(a0)
ffffffffc0200c4a:	20100713          	li	a4,513
ffffffffc0200c4e:	2017f793          	andi	a5,a5,513
ffffffffc0200c52:	10e79a63          	bne	a5,a4,ffffffffc0200d66 <pgfault_handler+0x160>
        if (cause == CAUSE_STORE_PAGE_FAULT) {
ffffffffc0200c56:	47bd                	li	a5,15
ffffffffc0200c58:	10f99763          	bne	s3,a5,ffffffffc0200d66 <pgfault_handler+0x160>
            return handle_cow_fault(current->mm, fault_addr);
ffffffffc0200c5c:	00093783          	ld	a5,0(s2)
 * 策略：
 *   1. 如果页面引用计数为1，说明其他进程已经完成复制，直接恢复写权限
 *   2. 如果引用计数>1，需要分配新页面并复制内容，然后更新页表项
 */
static int handle_cow_fault(struct mm_struct *mm, uintptr_t fault_addr) {
    uintptr_t page_addr = ROUNDDOWN(fault_addr, PGSIZE);
ffffffffc0200c60:	75fd                	lui	a1,0xfffff
ffffffffc0200c62:	8ced                	and	s1,s1,a1
    pte_t *ptep = get_pte(mm->pgdir, page_addr, 0);
ffffffffc0200c64:	779c                	ld	a5,40(a5)
ffffffffc0200c66:	4601                	li	a2,0
ffffffffc0200c68:	85a6                	mv	a1,s1
ffffffffc0200c6a:	6f88                	ld	a0,24(a5)
ffffffffc0200c6c:	578010ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc0200c70:	892a                	mv	s2,a0
    
    // 验证页表项有效性
    if (ptep == NULL || !(*ptep & PTE_V)) {
ffffffffc0200c72:	12050363          	beqz	a0,ffffffffc0200d98 <pgfault_handler+0x192>
ffffffffc0200c76:	6100                	ld	s0,0(a0)
ffffffffc0200c78:	00147793          	andi	a5,s0,1
ffffffffc0200c7c:	10078e63          	beqz	a5,ffffffffc0200d98 <pgfault_handler+0x192>
}

static inline struct Page *
pa2page(uintptr_t pa)
{
    if (PPN(pa) >= npage)
ffffffffc0200c80:	000cfb97          	auipc	s7,0xcf
ffffffffc0200c84:	800b8b93          	addi	s7,s7,-2048 # ffffffffc02cf480 <npage>
ffffffffc0200c88:	000bb703          	ld	a4,0(s7)
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
ffffffffc0200c8c:	00241793          	slli	a5,s0,0x2
ffffffffc0200c90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0200c92:	12e7f663          	bgeu	a5,a4,ffffffffc0200dbe <pgfault_handler+0x1b8>
    return &pages[PPN(pa) - nbase];
ffffffffc0200c96:	000ceb17          	auipc	s6,0xce
ffffffffc0200c9a:	7f2b0b13          	addi	s6,s6,2034 # ffffffffc02cf488 <pages>
ffffffffc0200c9e:	000b3983          	ld	s3,0(s6)
ffffffffc0200ca2:	00007a97          	auipc	s5,0x7
ffffffffc0200ca6:	d16aba83          	ld	s5,-746(s5) # ffffffffc02079b8 <nbase>
ffffffffc0200caa:	415787b3          	sub	a5,a5,s5
ffffffffc0200cae:	079a                	slli	a5,a5,0x6
ffffffffc0200cb0:	99be                	add	s3,s3,a5
    pte_t current_pte = *ptep;
    struct Page *shared_page = pte2page(current_pte);
    int page_refs = page_ref(shared_page);
    
    // 情况1：页面只被当前进程引用，可以直接获得写权限
    if (page_refs == 1) {
ffffffffc0200cb2:	0009a703          	lw	a4,0(s3)
ffffffffc0200cb6:	4785                	li	a5,1
ffffffffc0200cb8:	08f70c63          	beq	a4,a5,ffffffffc0200d50 <pgfault_handler+0x14a>
        
        return 0;
    }
    
    // 情况2：页面被多个进程共享，需要复制
    struct Page *copied_page = alloc_page();
ffffffffc0200cbc:	4505                	li	a0,1
ffffffffc0200cbe:	46e010ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0200cc2:	8a2a                	mv	s4,a0
    if (copied_page == NULL) {
ffffffffc0200cc4:	cd61                	beqz	a0,ffffffffc0200d9c <pgfault_handler+0x196>
    return page - pages + nbase;
ffffffffc0200cc6:	000b3683          	ld	a3,0(s6)
    return KADDR(page2pa(page));
ffffffffc0200cca:	57fd                	li	a5,-1
ffffffffc0200ccc:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0200cd0:	40d985b3          	sub	a1,s3,a3
ffffffffc0200cd4:	8599                	srai	a1,a1,0x6
ffffffffc0200cd6:	95d6                	add	a1,a1,s5
    return KADDR(page2pa(page));
ffffffffc0200cd8:	83b1                	srli	a5,a5,0xc
ffffffffc0200cda:	00f5f633          	and	a2,a1,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cde:	05b2                	slli	a1,a1,0xc
    return KADDR(page2pa(page));
ffffffffc0200ce0:	10e67763          	bgeu	a2,a4,ffffffffc0200dee <pgfault_handler+0x1e8>
    return page - pages + nbase;
ffffffffc0200ce4:	40d506b3          	sub	a3,a0,a3
ffffffffc0200ce8:	8699                	srai	a3,a3,0x6
ffffffffc0200cea:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0200cec:	000ce517          	auipc	a0,0xce
ffffffffc0200cf0:	7ac53503          	ld	a0,1964(a0) # ffffffffc02cf498 <va_pa_offset>
ffffffffc0200cf4:	8ff5                	and	a5,a5,a3
ffffffffc0200cf6:	95aa                	add	a1,a1,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cf8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0200cfa:	0ce7fe63          	bgeu	a5,a4,ffffffffc0200dd6 <pgfault_handler+0x1d0>
    }
    
    // 执行页面内容复制
    void *src = (void*)page2kva(shared_page);
    void *dst = (void*)page2kva(copied_page);
    memcpy(dst, src, PGSIZE);
ffffffffc0200cfe:	6605                	lui	a2,0x1
ffffffffc0200d00:	9536                	add	a0,a0,a3
ffffffffc0200d02:	333040ef          	jal	ra,ffffffffc0205834 <memcpy>
    return page - pages + nbase;
ffffffffc0200d06:	000b3703          	ld	a4,0(s6)
}

static inline int
page_ref_dec(struct Page *page)
{
    page->ref -= 1;
ffffffffc0200d0a:	0009a783          	lw	a5,0(s3)
    // 更新引用计数：原页面减少，新页面设置为1
    page_ref_dec(shared_page);
    set_page_ref(copied_page, 1);
    
    // 构建新的页表项：保留原有权限（用户、读、执行），添加写权限，清除COW标记
    uint32_t page_perm = (current_pte & (PTE_U | PTE_R | PTE_X)) | PTE_W;
ffffffffc0200d0e:	8869                	andi	s0,s0,26
    return page - pages + nbase;
ffffffffc0200d10:	40ea0733          	sub	a4,s4,a4
ffffffffc0200d14:	8719                	srai	a4,a4,0x6
ffffffffc0200d16:	9756                	add	a4,a4,s5
    page->ref -= 1;
ffffffffc0200d18:	37fd                	addiw	a5,a5,-1
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d1a:	072a                	slli	a4,a4,0xa
    page->ref -= 1;
ffffffffc0200d1c:	00f9a023          	sw	a5,0(s3)
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d20:	8c59                	or	s0,s0,a4
    page->ref = val;
ffffffffc0200d22:	4785                	li	a5,1
ffffffffc0200d24:	00fa2023          	sw	a5,0(s4)
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200d28:	00546413          	ori	s0,s0,5
    *ptep = pte_create(page2ppn(copied_page), PTE_V | page_perm);
ffffffffc0200d2c:	00893023          	sd	s0,0(s2)
    
    // 刷新TLB
    asm volatile("sfence.vma zero, %0" :: "r"(page_addr) : "memory");
ffffffffc0200d30:	12900073          	sfence.vma	zero,s1
    asm volatile("fence" ::: "memory");
ffffffffc0200d34:	0ff0000f          	fence
    
    return 0;
ffffffffc0200d38:	4501                	li	a0,0
}
ffffffffc0200d3a:	60a6                	ld	ra,72(sp)
ffffffffc0200d3c:	6406                	ld	s0,64(sp)
ffffffffc0200d3e:	74e2                	ld	s1,56(sp)
ffffffffc0200d40:	7942                	ld	s2,48(sp)
ffffffffc0200d42:	79a2                	ld	s3,40(sp)
ffffffffc0200d44:	7a02                	ld	s4,32(sp)
ffffffffc0200d46:	6ae2                	ld	s5,24(sp)
ffffffffc0200d48:	6b42                	ld	s6,16(sp)
ffffffffc0200d4a:	6ba2                	ld	s7,8(sp)
ffffffffc0200d4c:	6161                	addi	sp,sp,80
ffffffffc0200d4e:	8082                	ret
        *ptep = (current_pte | PTE_W) & ~PTE_COW;
ffffffffc0200d50:	dfb47413          	andi	s0,s0,-517
ffffffffc0200d54:	00446413          	ori	s0,s0,4
ffffffffc0200d58:	e100                	sd	s0,0(a0)
        asm volatile("sfence.vma zero, %0" :: "r"(page_addr) : "memory");
ffffffffc0200d5a:	12900073          	sfence.vma	zero,s1
        asm volatile("fence" ::: "memory");
ffffffffc0200d5e:	0ff0000f          	fence
        return 0;
ffffffffc0200d62:	4501                	li	a0,0
ffffffffc0200d64:	bfd9                	j	ffffffffc0200d3a <pgfault_handler+0x134>
    cprintf("page fault at 0x%08x: %c/%c\n", fault_addr,
ffffffffc0200d66:	47b5                	li	a5,13
ffffffffc0200d68:	05200613          	li	a2,82
ffffffffc0200d6c:	00f98463          	beq	s3,a5,ffffffffc0200d74 <pgfault_handler+0x16e>
ffffffffc0200d70:	05700613          	li	a2,87
            (tf->status & SSTATUS_SPP) ? 'K' : 'U');
ffffffffc0200d74:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", fault_addr,
ffffffffc0200d78:	04b00693          	li	a3,75
            (tf->status & SSTATUS_SPP) ? 'K' : 'U');
ffffffffc0200d7c:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", fault_addr,
ffffffffc0200d80:	e399                	bnez	a5,ffffffffc0200d86 <pgfault_handler+0x180>
ffffffffc0200d82:	05500693          	li	a3,85
ffffffffc0200d86:	85a6                	mv	a1,s1
ffffffffc0200d88:	00005517          	auipc	a0,0x5
ffffffffc0200d8c:	32050513          	addi	a0,a0,800 # ffffffffc02060a8 <commands+0x5f0>
ffffffffc0200d90:	c04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return -E_INVAL;
ffffffffc0200d94:	5575                	li	a0,-3
ffffffffc0200d96:	b755                	j	ffffffffc0200d3a <pgfault_handler+0x134>
        return -E_INVAL;
ffffffffc0200d98:	5575                	li	a0,-3
ffffffffc0200d9a:	b745                	j	ffffffffc0200d3a <pgfault_handler+0x134>
        return -E_NO_MEM;
ffffffffc0200d9c:	5571                	li	a0,-4
ffffffffc0200d9e:	bf71                	j	ffffffffc0200d3a <pgfault_handler+0x134>
        print_trapframe(tf);
ffffffffc0200da0:	8522                	mv	a0,s0
ffffffffc0200da2:	e03ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
        panic("page fault in kernel!");
ffffffffc0200da6:	00005617          	auipc	a2,0x5
ffffffffc0200daa:	27a60613          	addi	a2,a2,634 # ffffffffc0206020 <commands+0x568>
ffffffffc0200dae:	07300593          	li	a1,115
ffffffffc0200db2:	00005517          	auipc	a0,0x5
ffffffffc0200db6:	28650513          	addi	a0,a0,646 # ffffffffc0206038 <commands+0x580>
ffffffffc0200dba:	ed4ff0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200dbe:	00005617          	auipc	a2,0x5
ffffffffc0200dc2:	29260613          	addi	a2,a2,658 # ffffffffc0206050 <commands+0x598>
ffffffffc0200dc6:	06900593          	li	a1,105
ffffffffc0200dca:	00005517          	auipc	a0,0x5
ffffffffc0200dce:	2a650513          	addi	a0,a0,678 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0200dd2:	ebcff0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0200dd6:	00005617          	auipc	a2,0x5
ffffffffc0200dda:	2aa60613          	addi	a2,a2,682 # ffffffffc0206080 <commands+0x5c8>
ffffffffc0200dde:	07100593          	li	a1,113
ffffffffc0200de2:	00005517          	auipc	a0,0x5
ffffffffc0200de6:	28e50513          	addi	a0,a0,654 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0200dea:	ea4ff0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0200dee:	86ae                	mv	a3,a1
ffffffffc0200df0:	00005617          	auipc	a2,0x5
ffffffffc0200df4:	29060613          	addi	a2,a2,656 # ffffffffc0206080 <commands+0x5c8>
ffffffffc0200df8:	07100593          	li	a1,113
ffffffffc0200dfc:	00005517          	auipc	a0,0x5
ffffffffc0200e00:	27450513          	addi	a0,a0,628 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0200e04:	e8aff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e08 <interrupt_handler>:
}

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200e08:	11853783          	ld	a5,280(a0)
ffffffffc0200e0c:	472d                	li	a4,11
ffffffffc0200e0e:	0786                	slli	a5,a5,0x1
ffffffffc0200e10:	8385                	srli	a5,a5,0x1
ffffffffc0200e12:	08f76463          	bltu	a4,a5,ffffffffc0200e9a <interrupt_handler+0x92>
ffffffffc0200e16:	00005717          	auipc	a4,0x5
ffffffffc0200e1a:	36270713          	addi	a4,a4,866 # ffffffffc0206178 <commands+0x6c0>
ffffffffc0200e1e:	078a                	slli	a5,a5,0x2
ffffffffc0200e20:	97ba                	add	a5,a5,a4
ffffffffc0200e22:	439c                	lw	a5,0(a5)
ffffffffc0200e24:	97ba                	add	a5,a5,a4
ffffffffc0200e26:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200e28:	00005517          	auipc	a0,0x5
ffffffffc0200e2c:	30050513          	addi	a0,a0,768 # ffffffffc0206128 <commands+0x670>
ffffffffc0200e30:	b64ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200e34:	00005517          	auipc	a0,0x5
ffffffffc0200e38:	2d450513          	addi	a0,a0,724 # ffffffffc0206108 <commands+0x650>
ffffffffc0200e3c:	b58ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200e40:	00005517          	auipc	a0,0x5
ffffffffc0200e44:	28850513          	addi	a0,a0,648 # ffffffffc02060c8 <commands+0x610>
ffffffffc0200e48:	b4cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200e4c:	00005517          	auipc	a0,0x5
ffffffffc0200e50:	29c50513          	addi	a0,a0,668 # ffffffffc02060e8 <commands+0x630>
ffffffffc0200e54:	b40ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200e58:	1141                	addi	sp,sp,-16
ffffffffc0200e5a:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
ffffffffc0200e5c:	f16ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        ticks++;
ffffffffc0200e60:	000ce797          	auipc	a5,0xce
ffffffffc0200e64:	5e878793          	addi	a5,a5,1512 # ffffffffc02cf448 <ticks>
ffffffffc0200e68:	6398                	ld	a4,0(a5)
        /* reschedule promptly so long-running user code (e.g., spin) yields */
        if (current) {
ffffffffc0200e6a:	000ce697          	auipc	a3,0xce
ffffffffc0200e6e:	6366b683          	ld	a3,1590(a3) # ffffffffc02cf4a0 <current>
        ticks++;
ffffffffc0200e72:	0705                	addi	a4,a4,1
ffffffffc0200e74:	e398                	sd	a4,0(a5)
        if (current) {
ffffffffc0200e76:	c299                	beqz	a3,ffffffffc0200e7c <interrupt_handler+0x74>
            current->need_resched = 1;
ffffffffc0200e78:	4705                	li	a4,1
ffffffffc0200e7a:	ee98                	sd	a4,24(a3)
        }
        /* keep periodic heartbeat output */
        if (ticks % TICK_NUM == 0) {
ffffffffc0200e7c:	639c                	ld	a5,0(a5)
ffffffffc0200e7e:	06400713          	li	a4,100
ffffffffc0200e82:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200e86:	cb99                	beqz	a5,ffffffffc0200e9c <interrupt_handler+0x94>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200e88:	60a2                	ld	ra,8(sp)
ffffffffc0200e8a:	0141                	addi	sp,sp,16
ffffffffc0200e8c:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200e8e:	00005517          	auipc	a0,0x5
ffffffffc0200e92:	2ca50513          	addi	a0,a0,714 # ffffffffc0206158 <commands+0x6a0>
ffffffffc0200e96:	afeff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200e9a:	b329                	j	ffffffffc0200ba4 <print_trapframe>
}
ffffffffc0200e9c:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200e9e:	06400593          	li	a1,100
ffffffffc0200ea2:	00005517          	auipc	a0,0x5
ffffffffc0200ea6:	2a650513          	addi	a0,a0,678 # ffffffffc0206148 <commands+0x690>
}
ffffffffc0200eaa:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200eac:	ae8ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200eb0 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200eb0:	11853783          	ld	a5,280(a0)
{
ffffffffc0200eb4:	1141                	addi	sp,sp,-16
ffffffffc0200eb6:	e022                	sd	s0,0(sp)
ffffffffc0200eb8:	e406                	sd	ra,8(sp)
ffffffffc0200eba:	473d                	li	a4,15
ffffffffc0200ebc:	842a                	mv	s0,a0
ffffffffc0200ebe:	14f76763          	bltu	a4,a5,ffffffffc020100c <exception_handler+0x15c>
ffffffffc0200ec2:	00005717          	auipc	a4,0x5
ffffffffc0200ec6:	47670713          	addi	a4,a4,1142 # ffffffffc0206338 <commands+0x880>
ffffffffc0200eca:	078a                	slli	a5,a5,0x2
ffffffffc0200ecc:	97ba                	add	a5,a5,a4
ffffffffc0200ece:	439c                	lw	a5,0(a5)
ffffffffc0200ed0:	97ba                	add	a5,a5,a4
ffffffffc0200ed2:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200ed4:	00005517          	auipc	a0,0x5
ffffffffc0200ed8:	3a450513          	addi	a0,a0,932 # ffffffffc0206278 <commands+0x7c0>
ffffffffc0200edc:	ab8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200ee0:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200ee4:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200ee6:	0791                	addi	a5,a5,4
ffffffffc0200ee8:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200eec:	6402                	ld	s0,0(sp)
ffffffffc0200eee:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200ef0:	40c0406f          	j	ffffffffc02052fc <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200ef4:	00005517          	auipc	a0,0x5
ffffffffc0200ef8:	3a450513          	addi	a0,a0,932 # ffffffffc0206298 <commands+0x7e0>
}
ffffffffc0200efc:	6402                	ld	s0,0(sp)
ffffffffc0200efe:	60a2                	ld	ra,8(sp)
ffffffffc0200f00:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200f02:	a92ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200f06:	00005517          	auipc	a0,0x5
ffffffffc0200f0a:	3b250513          	addi	a0,a0,946 # ffffffffc02062b8 <commands+0x800>
ffffffffc0200f0e:	b7fd                	j	ffffffffc0200efc <exception_handler+0x4c>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200f10:	cf7ff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200f14:	0c050963          	beqz	a0,ffffffffc0200fe6 <exception_handler+0x136>
            cprintf("Instruction page fault\n");
ffffffffc0200f18:	00005517          	auipc	a0,0x5
ffffffffc0200f1c:	3c050513          	addi	a0,a0,960 # ffffffffc02062d8 <commands+0x820>
ffffffffc0200f20:	a74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200f24:	8522                	mv	a0,s0
ffffffffc0200f26:	c7fff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200f2a:	000ce797          	auipc	a5,0xce
ffffffffc0200f2e:	5767b783          	ld	a5,1398(a5) # ffffffffc02cf4a0 <current>
ffffffffc0200f32:	ebbd                	bnez	a5,ffffffffc0200fa8 <exception_handler+0xf8>
                panic("kernel page fault");
ffffffffc0200f34:	00005617          	auipc	a2,0x5
ffffffffc0200f38:	3bc60613          	addi	a2,a2,956 # ffffffffc02062f0 <commands+0x838>
ffffffffc0200f3c:	13a00593          	li	a1,314
ffffffffc0200f40:	00005517          	auipc	a0,0x5
ffffffffc0200f44:	0f850513          	addi	a0,a0,248 # ffffffffc0206038 <commands+0x580>
ffffffffc0200f48:	d46ff0ef          	jal	ra,ffffffffc020048e <__panic>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200f4c:	cbbff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200f50:	c959                	beqz	a0,ffffffffc0200fe6 <exception_handler+0x136>
            cprintf("Load page fault\n");
ffffffffc0200f52:	00005517          	auipc	a0,0x5
ffffffffc0200f56:	3b650513          	addi	a0,a0,950 # ffffffffc0206308 <commands+0x850>
ffffffffc0200f5a:	a3aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200f5e:	8522                	mv	a0,s0
ffffffffc0200f60:	c45ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200f64:	000ce797          	auipc	a5,0xce
ffffffffc0200f68:	53c7b783          	ld	a5,1340(a5) # ffffffffc02cf4a0 <current>
ffffffffc0200f6c:	ef95                	bnez	a5,ffffffffc0200fa8 <exception_handler+0xf8>
                panic("kernel page fault");
ffffffffc0200f6e:	00005617          	auipc	a2,0x5
ffffffffc0200f72:	38260613          	addi	a2,a2,898 # ffffffffc02062f0 <commands+0x838>
ffffffffc0200f76:	14600593          	li	a1,326
ffffffffc0200f7a:	00005517          	auipc	a0,0x5
ffffffffc0200f7e:	0be50513          	addi	a0,a0,190 # ffffffffc0206038 <commands+0x580>
ffffffffc0200f82:	d0cff0ef          	jal	ra,ffffffffc020048e <__panic>
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200f86:	c81ff0ef          	jal	ra,ffffffffc0200c06 <pgfault_handler>
ffffffffc0200f8a:	cd31                	beqz	a0,ffffffffc0200fe6 <exception_handler+0x136>
            cprintf("Store/AMO page fault\n");
ffffffffc0200f8c:	00005517          	auipc	a0,0x5
ffffffffc0200f90:	39450513          	addi	a0,a0,916 # ffffffffc0206320 <commands+0x868>
ffffffffc0200f94:	a00ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200f98:	8522                	mv	a0,s0
ffffffffc0200f9a:	c0bff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            if (current != NULL) {
ffffffffc0200f9e:	000ce797          	auipc	a5,0xce
ffffffffc0200fa2:	5027b783          	ld	a5,1282(a5) # ffffffffc02cf4a0 <current>
ffffffffc0200fa6:	c7dd                	beqz	a5,ffffffffc0201054 <exception_handler+0x1a4>
}
ffffffffc0200fa8:	6402                	ld	s0,0(sp)
ffffffffc0200faa:	60a2                	ld	ra,8(sp)
                do_exit(-E_KILLED);
ffffffffc0200fac:	555d                	li	a0,-9
}
ffffffffc0200fae:	0141                	addi	sp,sp,16
                do_exit(-E_KILLED);
ffffffffc0200fb0:	5a60306f          	j	ffffffffc0204556 <do_exit>
        cprintf("Instruction address misaligned\n");
ffffffffc0200fb4:	00005517          	auipc	a0,0x5
ffffffffc0200fb8:	1f450513          	addi	a0,a0,500 # ffffffffc02061a8 <commands+0x6f0>
ffffffffc0200fbc:	b781                	j	ffffffffc0200efc <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200fbe:	00005517          	auipc	a0,0x5
ffffffffc0200fc2:	20a50513          	addi	a0,a0,522 # ffffffffc02061c8 <commands+0x710>
ffffffffc0200fc6:	bf1d                	j	ffffffffc0200efc <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200fc8:	00005517          	auipc	a0,0x5
ffffffffc0200fcc:	22050513          	addi	a0,a0,544 # ffffffffc02061e8 <commands+0x730>
ffffffffc0200fd0:	b735                	j	ffffffffc0200efc <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200fd2:	00005517          	auipc	a0,0x5
ffffffffc0200fd6:	22e50513          	addi	a0,a0,558 # ffffffffc0206200 <commands+0x748>
ffffffffc0200fda:	9baff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200fde:	6458                	ld	a4,136(s0)
ffffffffc0200fe0:	47a9                	li	a5,10
ffffffffc0200fe2:	04f70663          	beq	a4,a5,ffffffffc020102e <exception_handler+0x17e>
}
ffffffffc0200fe6:	60a2                	ld	ra,8(sp)
ffffffffc0200fe8:	6402                	ld	s0,0(sp)
ffffffffc0200fea:	0141                	addi	sp,sp,16
ffffffffc0200fec:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200fee:	00005517          	auipc	a0,0x5
ffffffffc0200ff2:	22250513          	addi	a0,a0,546 # ffffffffc0206210 <commands+0x758>
ffffffffc0200ff6:	b719                	j	ffffffffc0200efc <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200ff8:	00005517          	auipc	a0,0x5
ffffffffc0200ffc:	23850513          	addi	a0,a0,568 # ffffffffc0206230 <commands+0x778>
ffffffffc0201000:	bdf5                	j	ffffffffc0200efc <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0201002:	00005517          	auipc	a0,0x5
ffffffffc0201006:	25e50513          	addi	a0,a0,606 # ffffffffc0206260 <commands+0x7a8>
ffffffffc020100a:	bdcd                	j	ffffffffc0200efc <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc020100c:	8522                	mv	a0,s0
}
ffffffffc020100e:	6402                	ld	s0,0(sp)
ffffffffc0201010:	60a2                	ld	ra,8(sp)
ffffffffc0201012:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0201014:	be41                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0201016:	00005617          	auipc	a2,0x5
ffffffffc020101a:	23260613          	addi	a2,a2,562 # ffffffffc0206248 <commands+0x790>
ffffffffc020101e:	11d00593          	li	a1,285
ffffffffc0201022:	00005517          	auipc	a0,0x5
ffffffffc0201026:	01650513          	addi	a0,a0,22 # ffffffffc0206038 <commands+0x580>
ffffffffc020102a:	c64ff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc020102e:	10843783          	ld	a5,264(s0)
ffffffffc0201032:	0791                	addi	a5,a5,4
ffffffffc0201034:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0201038:	2c4040ef          	jal	ra,ffffffffc02052fc <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc020103c:	000ce797          	auipc	a5,0xce
ffffffffc0201040:	4647b783          	ld	a5,1124(a5) # ffffffffc02cf4a0 <current>
ffffffffc0201044:	6b9c                	ld	a5,16(a5)
ffffffffc0201046:	8522                	mv	a0,s0
}
ffffffffc0201048:	6402                	ld	s0,0(sp)
ffffffffc020104a:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc020104c:	6589                	lui	a1,0x2
ffffffffc020104e:	95be                	add	a1,a1,a5
}
ffffffffc0201050:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0201052:	aa95                	j	ffffffffc02011c6 <kernel_execve_ret>
                panic("kernel page fault");
ffffffffc0201054:	00005617          	auipc	a2,0x5
ffffffffc0201058:	29c60613          	addi	a2,a2,668 # ffffffffc02062f0 <commands+0x838>
ffffffffc020105c:	15200593          	li	a1,338
ffffffffc0201060:	00005517          	auipc	a0,0x5
ffffffffc0201064:	fd850513          	addi	a0,a0,-40 # ffffffffc0206038 <commands+0x580>
ffffffffc0201068:	c26ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020106c <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc020106c:	1101                	addi	sp,sp,-32
ffffffffc020106e:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0201070:	000ce417          	auipc	s0,0xce
ffffffffc0201074:	43040413          	addi	s0,s0,1072 # ffffffffc02cf4a0 <current>
ffffffffc0201078:	6018                	ld	a4,0(s0)
{
ffffffffc020107a:	ec06                	sd	ra,24(sp)
ffffffffc020107c:	e426                	sd	s1,8(sp)
ffffffffc020107e:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0201080:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0201084:	cf1d                	beqz	a4,ffffffffc02010c2 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0201086:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc020108a:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc020108e:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0201090:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0201094:	0206c463          	bltz	a3,ffffffffc02010bc <trap+0x50>
        exception_handler(tf);
ffffffffc0201098:	e19ff0ef          	jal	ra,ffffffffc0200eb0 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc020109c:	601c                	ld	a5,0(s0)
ffffffffc020109e:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc02010a2:	e499                	bnez	s1,ffffffffc02010b0 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc02010a4:	0b07a703          	lw	a4,176(a5)
ffffffffc02010a8:	8b05                	andi	a4,a4,1
ffffffffc02010aa:	e329                	bnez	a4,ffffffffc02010ec <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc02010ac:	6f9c                	ld	a5,24(a5)
ffffffffc02010ae:	eb85                	bnez	a5,ffffffffc02010de <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc02010b0:	60e2                	ld	ra,24(sp)
ffffffffc02010b2:	6442                	ld	s0,16(sp)
ffffffffc02010b4:	64a2                	ld	s1,8(sp)
ffffffffc02010b6:	6902                	ld	s2,0(sp)
ffffffffc02010b8:	6105                	addi	sp,sp,32
ffffffffc02010ba:	8082                	ret
        interrupt_handler(tf);
ffffffffc02010bc:	d4dff0ef          	jal	ra,ffffffffc0200e08 <interrupt_handler>
ffffffffc02010c0:	bff1                	j	ffffffffc020109c <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc02010c2:	0006c863          	bltz	a3,ffffffffc02010d2 <trap+0x66>
}
ffffffffc02010c6:	6442                	ld	s0,16(sp)
ffffffffc02010c8:	60e2                	ld	ra,24(sp)
ffffffffc02010ca:	64a2                	ld	s1,8(sp)
ffffffffc02010cc:	6902                	ld	s2,0(sp)
ffffffffc02010ce:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc02010d0:	b3c5                	j	ffffffffc0200eb0 <exception_handler>
}
ffffffffc02010d2:	6442                	ld	s0,16(sp)
ffffffffc02010d4:	60e2                	ld	ra,24(sp)
ffffffffc02010d6:	64a2                	ld	s1,8(sp)
ffffffffc02010d8:	6902                	ld	s2,0(sp)
ffffffffc02010da:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc02010dc:	b335                	j	ffffffffc0200e08 <interrupt_handler>
}
ffffffffc02010de:	6442                	ld	s0,16(sp)
ffffffffc02010e0:	60e2                	ld	ra,24(sp)
ffffffffc02010e2:	64a2                	ld	s1,8(sp)
ffffffffc02010e4:	6902                	ld	s2,0(sp)
ffffffffc02010e6:	6105                	addi	sp,sp,32
                schedule();
ffffffffc02010e8:	1280406f          	j	ffffffffc0205210 <schedule>
                do_exit(-E_KILLED);
ffffffffc02010ec:	555d                	li	a0,-9
ffffffffc02010ee:	468030ef          	jal	ra,ffffffffc0204556 <do_exit>
            if (current->need_resched)
ffffffffc02010f2:	601c                	ld	a5,0(s0)
ffffffffc02010f4:	bf65                	j	ffffffffc02010ac <trap+0x40>
	...

ffffffffc02010f8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02010f8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc02010fc:	00011463          	bnez	sp,ffffffffc0201104 <__alltraps+0xc>
ffffffffc0201100:	14002173          	csrr	sp,sscratch
ffffffffc0201104:	712d                	addi	sp,sp,-288
ffffffffc0201106:	e002                	sd	zero,0(sp)
ffffffffc0201108:	e406                	sd	ra,8(sp)
ffffffffc020110a:	ec0e                	sd	gp,24(sp)
ffffffffc020110c:	f012                	sd	tp,32(sp)
ffffffffc020110e:	f416                	sd	t0,40(sp)
ffffffffc0201110:	f81a                	sd	t1,48(sp)
ffffffffc0201112:	fc1e                	sd	t2,56(sp)
ffffffffc0201114:	e0a2                	sd	s0,64(sp)
ffffffffc0201116:	e4a6                	sd	s1,72(sp)
ffffffffc0201118:	e8aa                	sd	a0,80(sp)
ffffffffc020111a:	ecae                	sd	a1,88(sp)
ffffffffc020111c:	f0b2                	sd	a2,96(sp)
ffffffffc020111e:	f4b6                	sd	a3,104(sp)
ffffffffc0201120:	f8ba                	sd	a4,112(sp)
ffffffffc0201122:	fcbe                	sd	a5,120(sp)
ffffffffc0201124:	e142                	sd	a6,128(sp)
ffffffffc0201126:	e546                	sd	a7,136(sp)
ffffffffc0201128:	e94a                	sd	s2,144(sp)
ffffffffc020112a:	ed4e                	sd	s3,152(sp)
ffffffffc020112c:	f152                	sd	s4,160(sp)
ffffffffc020112e:	f556                	sd	s5,168(sp)
ffffffffc0201130:	f95a                	sd	s6,176(sp)
ffffffffc0201132:	fd5e                	sd	s7,184(sp)
ffffffffc0201134:	e1e2                	sd	s8,192(sp)
ffffffffc0201136:	e5e6                	sd	s9,200(sp)
ffffffffc0201138:	e9ea                	sd	s10,208(sp)
ffffffffc020113a:	edee                	sd	s11,216(sp)
ffffffffc020113c:	f1f2                	sd	t3,224(sp)
ffffffffc020113e:	f5f6                	sd	t4,232(sp)
ffffffffc0201140:	f9fa                	sd	t5,240(sp)
ffffffffc0201142:	fdfe                	sd	t6,248(sp)
ffffffffc0201144:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0201148:	100024f3          	csrr	s1,sstatus
ffffffffc020114c:	14102973          	csrr	s2,sepc
ffffffffc0201150:	143029f3          	csrr	s3,stval
ffffffffc0201154:	14202a73          	csrr	s4,scause
ffffffffc0201158:	e822                	sd	s0,16(sp)
ffffffffc020115a:	e226                	sd	s1,256(sp)
ffffffffc020115c:	e64a                	sd	s2,264(sp)
ffffffffc020115e:	ea4e                	sd	s3,272(sp)
ffffffffc0201160:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0201162:	850a                	mv	a0,sp
    jal trap
ffffffffc0201164:	f09ff0ef          	jal	ra,ffffffffc020106c <trap>

ffffffffc0201168 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0201168:	6492                	ld	s1,256(sp)
ffffffffc020116a:	6932                	ld	s2,264(sp)
ffffffffc020116c:	1004f413          	andi	s0,s1,256
ffffffffc0201170:	e401                	bnez	s0,ffffffffc0201178 <__trapret+0x10>
ffffffffc0201172:	1200                	addi	s0,sp,288
ffffffffc0201174:	14041073          	csrw	sscratch,s0
ffffffffc0201178:	10049073          	csrw	sstatus,s1
ffffffffc020117c:	14191073          	csrw	sepc,s2
ffffffffc0201180:	60a2                	ld	ra,8(sp)
ffffffffc0201182:	61e2                	ld	gp,24(sp)
ffffffffc0201184:	7202                	ld	tp,32(sp)
ffffffffc0201186:	72a2                	ld	t0,40(sp)
ffffffffc0201188:	7342                	ld	t1,48(sp)
ffffffffc020118a:	73e2                	ld	t2,56(sp)
ffffffffc020118c:	6406                	ld	s0,64(sp)
ffffffffc020118e:	64a6                	ld	s1,72(sp)
ffffffffc0201190:	6546                	ld	a0,80(sp)
ffffffffc0201192:	65e6                	ld	a1,88(sp)
ffffffffc0201194:	7606                	ld	a2,96(sp)
ffffffffc0201196:	76a6                	ld	a3,104(sp)
ffffffffc0201198:	7746                	ld	a4,112(sp)
ffffffffc020119a:	77e6                	ld	a5,120(sp)
ffffffffc020119c:	680a                	ld	a6,128(sp)
ffffffffc020119e:	68aa                	ld	a7,136(sp)
ffffffffc02011a0:	694a                	ld	s2,144(sp)
ffffffffc02011a2:	69ea                	ld	s3,152(sp)
ffffffffc02011a4:	7a0a                	ld	s4,160(sp)
ffffffffc02011a6:	7aaa                	ld	s5,168(sp)
ffffffffc02011a8:	7b4a                	ld	s6,176(sp)
ffffffffc02011aa:	7bea                	ld	s7,184(sp)
ffffffffc02011ac:	6c0e                	ld	s8,192(sp)
ffffffffc02011ae:	6cae                	ld	s9,200(sp)
ffffffffc02011b0:	6d4e                	ld	s10,208(sp)
ffffffffc02011b2:	6dee                	ld	s11,216(sp)
ffffffffc02011b4:	7e0e                	ld	t3,224(sp)
ffffffffc02011b6:	7eae                	ld	t4,232(sp)
ffffffffc02011b8:	7f4e                	ld	t5,240(sp)
ffffffffc02011ba:	7fee                	ld	t6,248(sp)
ffffffffc02011bc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02011be:	10200073          	sret

ffffffffc02011c2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc02011c2:	812a                	mv	sp,a0
    j __trapret
ffffffffc02011c4:	b755                	j	ffffffffc0201168 <__trapret>

ffffffffc02011c6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc02011c6:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x80c0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc02011ca:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc02011ce:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc02011d2:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc02011d6:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc02011da:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc02011de:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc02011e2:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc02011e6:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc02011ea:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc02011ec:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc02011ee:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc02011f0:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc02011f2:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc02011f4:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc02011f6:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc02011f8:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc02011fa:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc02011fc:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc02011fe:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0201200:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0201202:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201204:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0201206:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0201208:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc020120a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc020120c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc020120e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0201210:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0201212:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201214:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0201216:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201218:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc020121a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc020121c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc020121e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201220:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0201222:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201224:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0201226:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201228:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc020122a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc020122c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc020122e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201230:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0201232:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201234:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0201236:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201238:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc020123a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc020123c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc020123e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201240:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0201242:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201244:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0201246:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201248:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc020124a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc020124c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc020124e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201250:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0201252:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201254:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201256:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201258:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc020125a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc020125c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020125e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201260:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201262:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201264:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201266:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201268:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020126a:	812e                	mv	sp,a1
ffffffffc020126c:	bdf5                	j	ffffffffc0201168 <__trapret>

ffffffffc020126e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020126e:	000ca797          	auipc	a5,0xca
ffffffffc0201272:	1aa78793          	addi	a5,a5,426 # ffffffffc02cb418 <free_area>
ffffffffc0201276:	e79c                	sd	a5,8(a5)
ffffffffc0201278:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020127a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020127e:	8082                	ret

ffffffffc0201280 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201280:	000ca517          	auipc	a0,0xca
ffffffffc0201284:	1a856503          	lwu	a0,424(a0) # ffffffffc02cb428 <free_area+0x10>
ffffffffc0201288:	8082                	ret

ffffffffc020128a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020128a:	715d                	addi	sp,sp,-80
ffffffffc020128c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020128e:	000ca417          	auipc	s0,0xca
ffffffffc0201292:	18a40413          	addi	s0,s0,394 # ffffffffc02cb418 <free_area>
ffffffffc0201296:	641c                	ld	a5,8(s0)
ffffffffc0201298:	e486                	sd	ra,72(sp)
ffffffffc020129a:	fc26                	sd	s1,56(sp)
ffffffffc020129c:	f84a                	sd	s2,48(sp)
ffffffffc020129e:	f44e                	sd	s3,40(sp)
ffffffffc02012a0:	f052                	sd	s4,32(sp)
ffffffffc02012a2:	ec56                	sd	s5,24(sp)
ffffffffc02012a4:	e85a                	sd	s6,16(sp)
ffffffffc02012a6:	e45e                	sd	s7,8(sp)
ffffffffc02012a8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012aa:	2a878d63          	beq	a5,s0,ffffffffc0201564 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02012ae:	4481                	li	s1,0
ffffffffc02012b0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02012b2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02012b6:	8b09                	andi	a4,a4,2
ffffffffc02012b8:	2a070a63          	beqz	a4,ffffffffc020156c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02012bc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012c0:	679c                	ld	a5,8(a5)
ffffffffc02012c2:	2905                	addiw	s2,s2,1
ffffffffc02012c4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012c6:	fe8796e3          	bne	a5,s0,ffffffffc02012b2 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02012ca:	89a6                	mv	s3,s1
ffffffffc02012cc:	6df000ef          	jal	ra,ffffffffc02021aa <nr_free_pages>
ffffffffc02012d0:	6f351e63          	bne	a0,s3,ffffffffc02019cc <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012d4:	4505                	li	a0,1
ffffffffc02012d6:	657000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02012da:	8aaa                	mv	s5,a0
ffffffffc02012dc:	42050863          	beqz	a0,ffffffffc020170c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012e0:	4505                	li	a0,1
ffffffffc02012e2:	64b000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02012e6:	89aa                	mv	s3,a0
ffffffffc02012e8:	70050263          	beqz	a0,ffffffffc02019ec <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012ec:	4505                	li	a0,1
ffffffffc02012ee:	63f000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02012f2:	8a2a                	mv	s4,a0
ffffffffc02012f4:	48050c63          	beqz	a0,ffffffffc020178c <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012f8:	293a8a63          	beq	s5,s3,ffffffffc020158c <default_check+0x302>
ffffffffc02012fc:	28aa8863          	beq	s5,a0,ffffffffc020158c <default_check+0x302>
ffffffffc0201300:	28a98663          	beq	s3,a0,ffffffffc020158c <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201304:	000aa783          	lw	a5,0(s5)
ffffffffc0201308:	2a079263          	bnez	a5,ffffffffc02015ac <default_check+0x322>
ffffffffc020130c:	0009a783          	lw	a5,0(s3)
ffffffffc0201310:	28079e63          	bnez	a5,ffffffffc02015ac <default_check+0x322>
ffffffffc0201314:	411c                	lw	a5,0(a0)
ffffffffc0201316:	28079b63          	bnez	a5,ffffffffc02015ac <default_check+0x322>
    return page - pages + nbase;
ffffffffc020131a:	000ce797          	auipc	a5,0xce
ffffffffc020131e:	16e7b783          	ld	a5,366(a5) # ffffffffc02cf488 <pages>
ffffffffc0201322:	40fa8733          	sub	a4,s5,a5
ffffffffc0201326:	00006617          	auipc	a2,0x6
ffffffffc020132a:	69263603          	ld	a2,1682(a2) # ffffffffc02079b8 <nbase>
ffffffffc020132e:	8719                	srai	a4,a4,0x6
ffffffffc0201330:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201332:	000ce697          	auipc	a3,0xce
ffffffffc0201336:	14e6b683          	ld	a3,334(a3) # ffffffffc02cf480 <npage>
ffffffffc020133a:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020133c:	0732                	slli	a4,a4,0xc
ffffffffc020133e:	28d77763          	bgeu	a4,a3,ffffffffc02015cc <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201342:	40f98733          	sub	a4,s3,a5
ffffffffc0201346:	8719                	srai	a4,a4,0x6
ffffffffc0201348:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020134a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020134c:	4cd77063          	bgeu	a4,a3,ffffffffc020180c <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201350:	40f507b3          	sub	a5,a0,a5
ffffffffc0201354:	8799                	srai	a5,a5,0x6
ffffffffc0201356:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201358:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020135a:	30d7f963          	bgeu	a5,a3,ffffffffc020166c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020135e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201360:	00043c03          	ld	s8,0(s0)
ffffffffc0201364:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201368:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020136c:	e400                	sd	s0,8(s0)
ffffffffc020136e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201370:	000ca797          	auipc	a5,0xca
ffffffffc0201374:	0a07ac23          	sw	zero,184(a5) # ffffffffc02cb428 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201378:	5b5000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc020137c:	2c051863          	bnez	a0,ffffffffc020164c <default_check+0x3c2>
    free_page(p0);
ffffffffc0201380:	4585                	li	a1,1
ffffffffc0201382:	8556                	mv	a0,s5
ffffffffc0201384:	5e7000ef          	jal	ra,ffffffffc020216a <free_pages>
    free_page(p1);
ffffffffc0201388:	4585                	li	a1,1
ffffffffc020138a:	854e                	mv	a0,s3
ffffffffc020138c:	5df000ef          	jal	ra,ffffffffc020216a <free_pages>
    free_page(p2);
ffffffffc0201390:	4585                	li	a1,1
ffffffffc0201392:	8552                	mv	a0,s4
ffffffffc0201394:	5d7000ef          	jal	ra,ffffffffc020216a <free_pages>
    assert(nr_free == 3);
ffffffffc0201398:	4818                	lw	a4,16(s0)
ffffffffc020139a:	478d                	li	a5,3
ffffffffc020139c:	28f71863          	bne	a4,a5,ffffffffc020162c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013a0:	4505                	li	a0,1
ffffffffc02013a2:	58b000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02013a6:	89aa                	mv	s3,a0
ffffffffc02013a8:	26050263          	beqz	a0,ffffffffc020160c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013ac:	4505                	li	a0,1
ffffffffc02013ae:	57f000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02013b2:	8aaa                	mv	s5,a0
ffffffffc02013b4:	3a050c63          	beqz	a0,ffffffffc020176c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013b8:	4505                	li	a0,1
ffffffffc02013ba:	573000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02013be:	8a2a                	mv	s4,a0
ffffffffc02013c0:	38050663          	beqz	a0,ffffffffc020174c <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02013c4:	4505                	li	a0,1
ffffffffc02013c6:	567000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02013ca:	36051163          	bnez	a0,ffffffffc020172c <default_check+0x4a2>
    free_page(p0);
ffffffffc02013ce:	4585                	li	a1,1
ffffffffc02013d0:	854e                	mv	a0,s3
ffffffffc02013d2:	599000ef          	jal	ra,ffffffffc020216a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02013d6:	641c                	ld	a5,8(s0)
ffffffffc02013d8:	20878a63          	beq	a5,s0,ffffffffc02015ec <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02013dc:	4505                	li	a0,1
ffffffffc02013de:	54f000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02013e2:	30a99563          	bne	s3,a0,ffffffffc02016ec <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02013e6:	4505                	li	a0,1
ffffffffc02013e8:	545000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02013ec:	2e051063          	bnez	a0,ffffffffc02016cc <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02013f0:	481c                	lw	a5,16(s0)
ffffffffc02013f2:	2a079d63          	bnez	a5,ffffffffc02016ac <default_check+0x422>
    free_page(p);
ffffffffc02013f6:	854e                	mv	a0,s3
ffffffffc02013f8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02013fa:	01843023          	sd	s8,0(s0)
ffffffffc02013fe:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201402:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201406:	565000ef          	jal	ra,ffffffffc020216a <free_pages>
    free_page(p1);
ffffffffc020140a:	4585                	li	a1,1
ffffffffc020140c:	8556                	mv	a0,s5
ffffffffc020140e:	55d000ef          	jal	ra,ffffffffc020216a <free_pages>
    free_page(p2);
ffffffffc0201412:	4585                	li	a1,1
ffffffffc0201414:	8552                	mv	a0,s4
ffffffffc0201416:	555000ef          	jal	ra,ffffffffc020216a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020141a:	4515                	li	a0,5
ffffffffc020141c:	511000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0201420:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201422:	26050563          	beqz	a0,ffffffffc020168c <default_check+0x402>
ffffffffc0201426:	651c                	ld	a5,8(a0)
ffffffffc0201428:	8385                	srli	a5,a5,0x1
ffffffffc020142a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020142c:	54079063          	bnez	a5,ffffffffc020196c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201430:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201432:	00043b03          	ld	s6,0(s0)
ffffffffc0201436:	00843a83          	ld	s5,8(s0)
ffffffffc020143a:	e000                	sd	s0,0(s0)
ffffffffc020143c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020143e:	4ef000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0201442:	50051563          	bnez	a0,ffffffffc020194c <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201446:	08098a13          	addi	s4,s3,128
ffffffffc020144a:	8552                	mv	a0,s4
ffffffffc020144c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020144e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201452:	000ca797          	auipc	a5,0xca
ffffffffc0201456:	fc07ab23          	sw	zero,-42(a5) # ffffffffc02cb428 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020145a:	511000ef          	jal	ra,ffffffffc020216a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020145e:	4511                	li	a0,4
ffffffffc0201460:	4cd000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0201464:	4c051463          	bnez	a0,ffffffffc020192c <default_check+0x6a2>
ffffffffc0201468:	0889b783          	ld	a5,136(s3)
ffffffffc020146c:	8385                	srli	a5,a5,0x1
ffffffffc020146e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201470:	48078e63          	beqz	a5,ffffffffc020190c <default_check+0x682>
ffffffffc0201474:	0909a703          	lw	a4,144(s3)
ffffffffc0201478:	478d                	li	a5,3
ffffffffc020147a:	48f71963          	bne	a4,a5,ffffffffc020190c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020147e:	450d                	li	a0,3
ffffffffc0201480:	4ad000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0201484:	8c2a                	mv	s8,a0
ffffffffc0201486:	46050363          	beqz	a0,ffffffffc02018ec <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020148a:	4505                	li	a0,1
ffffffffc020148c:	4a1000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0201490:	42051e63          	bnez	a0,ffffffffc02018cc <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201494:	418a1c63          	bne	s4,s8,ffffffffc02018ac <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201498:	4585                	li	a1,1
ffffffffc020149a:	854e                	mv	a0,s3
ffffffffc020149c:	4cf000ef          	jal	ra,ffffffffc020216a <free_pages>
    free_pages(p1, 3);
ffffffffc02014a0:	458d                	li	a1,3
ffffffffc02014a2:	8552                	mv	a0,s4
ffffffffc02014a4:	4c7000ef          	jal	ra,ffffffffc020216a <free_pages>
ffffffffc02014a8:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02014ac:	04098c13          	addi	s8,s3,64
ffffffffc02014b0:	8385                	srli	a5,a5,0x1
ffffffffc02014b2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014b4:	3c078c63          	beqz	a5,ffffffffc020188c <default_check+0x602>
ffffffffc02014b8:	0109a703          	lw	a4,16(s3)
ffffffffc02014bc:	4785                	li	a5,1
ffffffffc02014be:	3cf71763          	bne	a4,a5,ffffffffc020188c <default_check+0x602>
ffffffffc02014c2:	008a3783          	ld	a5,8(s4)
ffffffffc02014c6:	8385                	srli	a5,a5,0x1
ffffffffc02014c8:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014ca:	3a078163          	beqz	a5,ffffffffc020186c <default_check+0x5e2>
ffffffffc02014ce:	010a2703          	lw	a4,16(s4)
ffffffffc02014d2:	478d                	li	a5,3
ffffffffc02014d4:	38f71c63          	bne	a4,a5,ffffffffc020186c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02014d8:	4505                	li	a0,1
ffffffffc02014da:	453000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02014de:	36a99763          	bne	s3,a0,ffffffffc020184c <default_check+0x5c2>
    free_page(p0);
ffffffffc02014e2:	4585                	li	a1,1
ffffffffc02014e4:	487000ef          	jal	ra,ffffffffc020216a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02014e8:	4509                	li	a0,2
ffffffffc02014ea:	443000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02014ee:	32aa1f63          	bne	s4,a0,ffffffffc020182c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02014f2:	4589                	li	a1,2
ffffffffc02014f4:	477000ef          	jal	ra,ffffffffc020216a <free_pages>
    free_page(p2);
ffffffffc02014f8:	4585                	li	a1,1
ffffffffc02014fa:	8562                	mv	a0,s8
ffffffffc02014fc:	46f000ef          	jal	ra,ffffffffc020216a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201500:	4515                	li	a0,5
ffffffffc0201502:	42b000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0201506:	89aa                	mv	s3,a0
ffffffffc0201508:	48050263          	beqz	a0,ffffffffc020198c <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020150c:	4505                	li	a0,1
ffffffffc020150e:	41f000ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0201512:	2c051d63          	bnez	a0,ffffffffc02017ec <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201516:	481c                	lw	a5,16(s0)
ffffffffc0201518:	2a079a63          	bnez	a5,ffffffffc02017cc <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020151c:	4595                	li	a1,5
ffffffffc020151e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201520:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201524:	01643023          	sd	s6,0(s0)
ffffffffc0201528:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020152c:	43f000ef          	jal	ra,ffffffffc020216a <free_pages>
    return listelm->next;
ffffffffc0201530:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201532:	00878963          	beq	a5,s0,ffffffffc0201544 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201536:	ff87a703          	lw	a4,-8(a5)
ffffffffc020153a:	679c                	ld	a5,8(a5)
ffffffffc020153c:	397d                	addiw	s2,s2,-1
ffffffffc020153e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201540:	fe879be3          	bne	a5,s0,ffffffffc0201536 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201544:	26091463          	bnez	s2,ffffffffc02017ac <default_check+0x522>
    assert(total == 0);
ffffffffc0201548:	46049263          	bnez	s1,ffffffffc02019ac <default_check+0x722>
}
ffffffffc020154c:	60a6                	ld	ra,72(sp)
ffffffffc020154e:	6406                	ld	s0,64(sp)
ffffffffc0201550:	74e2                	ld	s1,56(sp)
ffffffffc0201552:	7942                	ld	s2,48(sp)
ffffffffc0201554:	79a2                	ld	s3,40(sp)
ffffffffc0201556:	7a02                	ld	s4,32(sp)
ffffffffc0201558:	6ae2                	ld	s5,24(sp)
ffffffffc020155a:	6b42                	ld	s6,16(sp)
ffffffffc020155c:	6ba2                	ld	s7,8(sp)
ffffffffc020155e:	6c02                	ld	s8,0(sp)
ffffffffc0201560:	6161                	addi	sp,sp,80
ffffffffc0201562:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201564:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201566:	4481                	li	s1,0
ffffffffc0201568:	4901                	li	s2,0
ffffffffc020156a:	b38d                	j	ffffffffc02012cc <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	e0c68693          	addi	a3,a3,-500 # ffffffffc0206378 <commands+0x8c0>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	e1460613          	addi	a2,a2,-492 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020157c:	11000593          	li	a1,272
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	e2050513          	addi	a0,a0,-480 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201588:	f07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	eac68693          	addi	a3,a3,-340 # ffffffffc0206438 <commands+0x980>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	df460613          	addi	a2,a2,-524 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020159c:	0db00593          	li	a1,219
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	e0050513          	addi	a0,a0,-512 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02015a8:	ee7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	eb468693          	addi	a3,a3,-332 # ffffffffc0206460 <commands+0x9a8>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	dd460613          	addi	a2,a2,-556 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02015bc:	0dc00593          	li	a1,220
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	de050513          	addi	a0,a0,-544 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02015c8:	ec7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	ed468693          	addi	a3,a3,-300 # ffffffffc02064a0 <commands+0x9e8>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	db460613          	addi	a2,a2,-588 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02015dc:	0de00593          	li	a1,222
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	dc050513          	addi	a0,a0,-576 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02015e8:	ea7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	f3c68693          	addi	a3,a3,-196 # ffffffffc0206528 <commands+0xa70>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	d9460613          	addi	a2,a2,-620 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02015fc:	0f700593          	li	a1,247
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	da050513          	addi	a0,a0,-608 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201608:	e87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	dcc68693          	addi	a3,a3,-564 # ffffffffc02063d8 <commands+0x920>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	d7460613          	addi	a2,a2,-652 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020161c:	0f000593          	li	a1,240
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	d8050513          	addi	a0,a0,-640 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201628:	e67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	eec68693          	addi	a3,a3,-276 # ffffffffc0206518 <commands+0xa60>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	d5460613          	addi	a2,a2,-684 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020163c:	0ee00593          	li	a1,238
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	d6050513          	addi	a0,a0,-672 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201648:	e47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	eb468693          	addi	a3,a3,-332 # ffffffffc0206500 <commands+0xa48>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	d3460613          	addi	a2,a2,-716 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020165c:	0e900593          	li	a1,233
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	d4050513          	addi	a0,a0,-704 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201668:	e27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	e7468693          	addi	a3,a3,-396 # ffffffffc02064e0 <commands+0xa28>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	d1460613          	addi	a2,a2,-748 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020167c:	0e000593          	li	a1,224
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	d2050513          	addi	a0,a0,-736 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201688:	e07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	ee468693          	addi	a3,a3,-284 # ffffffffc0206570 <commands+0xab8>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	cf460613          	addi	a2,a2,-780 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020169c:	11800593          	li	a1,280
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	d0050513          	addi	a0,a0,-768 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02016a8:	de7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	eb468693          	addi	a3,a3,-332 # ffffffffc0206560 <commands+0xaa8>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	cd460613          	addi	a2,a2,-812 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02016bc:	0fd00593          	li	a1,253
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	ce050513          	addi	a0,a0,-800 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02016c8:	dc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	e3468693          	addi	a3,a3,-460 # ffffffffc0206500 <commands+0xa48>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	cb460613          	addi	a2,a2,-844 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02016dc:	0fb00593          	li	a1,251
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	cc050513          	addi	a0,a0,-832 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02016e8:	da7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	e5468693          	addi	a3,a3,-428 # ffffffffc0206540 <commands+0xa88>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	c9460613          	addi	a2,a2,-876 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02016fc:	0fa00593          	li	a1,250
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	ca050513          	addi	a0,a0,-864 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201708:	d87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	ccc68693          	addi	a3,a3,-820 # ffffffffc02063d8 <commands+0x920>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	c7460613          	addi	a2,a2,-908 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020171c:	0d700593          	li	a1,215
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	c8050513          	addi	a0,a0,-896 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201728:	d67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	dd468693          	addi	a3,a3,-556 # ffffffffc0206500 <commands+0xa48>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	c5460613          	addi	a2,a2,-940 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020173c:	0f400593          	li	a1,244
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	c6050513          	addi	a0,a0,-928 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201748:	d47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020174c:	00005697          	auipc	a3,0x5
ffffffffc0201750:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206418 <commands+0x960>
ffffffffc0201754:	00005617          	auipc	a2,0x5
ffffffffc0201758:	c3460613          	addi	a2,a2,-972 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020175c:	0f200593          	li	a1,242
ffffffffc0201760:	00005517          	auipc	a0,0x5
ffffffffc0201764:	c4050513          	addi	a0,a0,-960 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201768:	d27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020176c:	00005697          	auipc	a3,0x5
ffffffffc0201770:	c8c68693          	addi	a3,a3,-884 # ffffffffc02063f8 <commands+0x940>
ffffffffc0201774:	00005617          	auipc	a2,0x5
ffffffffc0201778:	c1460613          	addi	a2,a2,-1004 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020177c:	0f100593          	li	a1,241
ffffffffc0201780:	00005517          	auipc	a0,0x5
ffffffffc0201784:	c2050513          	addi	a0,a0,-992 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201788:	d07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020178c:	00005697          	auipc	a3,0x5
ffffffffc0201790:	c8c68693          	addi	a3,a3,-884 # ffffffffc0206418 <commands+0x960>
ffffffffc0201794:	00005617          	auipc	a2,0x5
ffffffffc0201798:	bf460613          	addi	a2,a2,-1036 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020179c:	0d900593          	li	a1,217
ffffffffc02017a0:	00005517          	auipc	a0,0x5
ffffffffc02017a4:	c0050513          	addi	a0,a0,-1024 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02017a8:	ce7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02017ac:	00005697          	auipc	a3,0x5
ffffffffc02017b0:	f1468693          	addi	a3,a3,-236 # ffffffffc02066c0 <commands+0xc08>
ffffffffc02017b4:	00005617          	auipc	a2,0x5
ffffffffc02017b8:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02017bc:	14600593          	li	a1,326
ffffffffc02017c0:	00005517          	auipc	a0,0x5
ffffffffc02017c4:	be050513          	addi	a0,a0,-1056 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02017c8:	cc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02017cc:	00005697          	auipc	a3,0x5
ffffffffc02017d0:	d9468693          	addi	a3,a3,-620 # ffffffffc0206560 <commands+0xaa8>
ffffffffc02017d4:	00005617          	auipc	a2,0x5
ffffffffc02017d8:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02017dc:	13a00593          	li	a1,314
ffffffffc02017e0:	00005517          	auipc	a0,0x5
ffffffffc02017e4:	bc050513          	addi	a0,a0,-1088 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02017e8:	ca7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02017ec:	00005697          	auipc	a3,0x5
ffffffffc02017f0:	d1468693          	addi	a3,a3,-748 # ffffffffc0206500 <commands+0xa48>
ffffffffc02017f4:	00005617          	auipc	a2,0x5
ffffffffc02017f8:	b9460613          	addi	a2,a2,-1132 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02017fc:	13800593          	li	a1,312
ffffffffc0201800:	00005517          	auipc	a0,0x5
ffffffffc0201804:	ba050513          	addi	a0,a0,-1120 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201808:	c87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020180c:	00005697          	auipc	a3,0x5
ffffffffc0201810:	cb468693          	addi	a3,a3,-844 # ffffffffc02064c0 <commands+0xa08>
ffffffffc0201814:	00005617          	auipc	a2,0x5
ffffffffc0201818:	b7460613          	addi	a2,a2,-1164 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020181c:	0df00593          	li	a1,223
ffffffffc0201820:	00005517          	auipc	a0,0x5
ffffffffc0201824:	b8050513          	addi	a0,a0,-1152 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201828:	c67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020182c:	00005697          	auipc	a3,0x5
ffffffffc0201830:	e5468693          	addi	a3,a3,-428 # ffffffffc0206680 <commands+0xbc8>
ffffffffc0201834:	00005617          	auipc	a2,0x5
ffffffffc0201838:	b5460613          	addi	a2,a2,-1196 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020183c:	13200593          	li	a1,306
ffffffffc0201840:	00005517          	auipc	a0,0x5
ffffffffc0201844:	b6050513          	addi	a0,a0,-1184 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201848:	c47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020184c:	00005697          	auipc	a3,0x5
ffffffffc0201850:	e1468693          	addi	a3,a3,-492 # ffffffffc0206660 <commands+0xba8>
ffffffffc0201854:	00005617          	auipc	a2,0x5
ffffffffc0201858:	b3460613          	addi	a2,a2,-1228 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020185c:	13000593          	li	a1,304
ffffffffc0201860:	00005517          	auipc	a0,0x5
ffffffffc0201864:	b4050513          	addi	a0,a0,-1216 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201868:	c27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020186c:	00005697          	auipc	a3,0x5
ffffffffc0201870:	dcc68693          	addi	a3,a3,-564 # ffffffffc0206638 <commands+0xb80>
ffffffffc0201874:	00005617          	auipc	a2,0x5
ffffffffc0201878:	b1460613          	addi	a2,a2,-1260 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020187c:	12e00593          	li	a1,302
ffffffffc0201880:	00005517          	auipc	a0,0x5
ffffffffc0201884:	b2050513          	addi	a0,a0,-1248 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201888:	c07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020188c:	00005697          	auipc	a3,0x5
ffffffffc0201890:	d8468693          	addi	a3,a3,-636 # ffffffffc0206610 <commands+0xb58>
ffffffffc0201894:	00005617          	auipc	a2,0x5
ffffffffc0201898:	af460613          	addi	a2,a2,-1292 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020189c:	12d00593          	li	a1,301
ffffffffc02018a0:	00005517          	auipc	a0,0x5
ffffffffc02018a4:	b0050513          	addi	a0,a0,-1280 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02018a8:	be7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02018ac:	00005697          	auipc	a3,0x5
ffffffffc02018b0:	d5468693          	addi	a3,a3,-684 # ffffffffc0206600 <commands+0xb48>
ffffffffc02018b4:	00005617          	auipc	a2,0x5
ffffffffc02018b8:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02018bc:	12800593          	li	a1,296
ffffffffc02018c0:	00005517          	auipc	a0,0x5
ffffffffc02018c4:	ae050513          	addi	a0,a0,-1312 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02018c8:	bc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02018cc:	00005697          	auipc	a3,0x5
ffffffffc02018d0:	c3468693          	addi	a3,a3,-972 # ffffffffc0206500 <commands+0xa48>
ffffffffc02018d4:	00005617          	auipc	a2,0x5
ffffffffc02018d8:	ab460613          	addi	a2,a2,-1356 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02018dc:	12700593          	li	a1,295
ffffffffc02018e0:	00005517          	auipc	a0,0x5
ffffffffc02018e4:	ac050513          	addi	a0,a0,-1344 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02018e8:	ba7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02018ec:	00005697          	auipc	a3,0x5
ffffffffc02018f0:	cf468693          	addi	a3,a3,-780 # ffffffffc02065e0 <commands+0xb28>
ffffffffc02018f4:	00005617          	auipc	a2,0x5
ffffffffc02018f8:	a9460613          	addi	a2,a2,-1388 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02018fc:	12600593          	li	a1,294
ffffffffc0201900:	00005517          	auipc	a0,0x5
ffffffffc0201904:	aa050513          	addi	a0,a0,-1376 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201908:	b87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020190c:	00005697          	auipc	a3,0x5
ffffffffc0201910:	ca468693          	addi	a3,a3,-860 # ffffffffc02065b0 <commands+0xaf8>
ffffffffc0201914:	00005617          	auipc	a2,0x5
ffffffffc0201918:	a7460613          	addi	a2,a2,-1420 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020191c:	12500593          	li	a1,293
ffffffffc0201920:	00005517          	auipc	a0,0x5
ffffffffc0201924:	a8050513          	addi	a0,a0,-1408 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201928:	b67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020192c:	00005697          	auipc	a3,0x5
ffffffffc0201930:	c6c68693          	addi	a3,a3,-916 # ffffffffc0206598 <commands+0xae0>
ffffffffc0201934:	00005617          	auipc	a2,0x5
ffffffffc0201938:	a5460613          	addi	a2,a2,-1452 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020193c:	12400593          	li	a1,292
ffffffffc0201940:	00005517          	auipc	a0,0x5
ffffffffc0201944:	a6050513          	addi	a0,a0,-1440 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201948:	b47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020194c:	00005697          	auipc	a3,0x5
ffffffffc0201950:	bb468693          	addi	a3,a3,-1100 # ffffffffc0206500 <commands+0xa48>
ffffffffc0201954:	00005617          	auipc	a2,0x5
ffffffffc0201958:	a3460613          	addi	a2,a2,-1484 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020195c:	11e00593          	li	a1,286
ffffffffc0201960:	00005517          	auipc	a0,0x5
ffffffffc0201964:	a4050513          	addi	a0,a0,-1472 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201968:	b27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020196c:	00005697          	auipc	a3,0x5
ffffffffc0201970:	c1468693          	addi	a3,a3,-1004 # ffffffffc0206580 <commands+0xac8>
ffffffffc0201974:	00005617          	auipc	a2,0x5
ffffffffc0201978:	a1460613          	addi	a2,a2,-1516 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020197c:	11900593          	li	a1,281
ffffffffc0201980:	00005517          	auipc	a0,0x5
ffffffffc0201984:	a2050513          	addi	a0,a0,-1504 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201988:	b07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020198c:	00005697          	auipc	a3,0x5
ffffffffc0201990:	d1468693          	addi	a3,a3,-748 # ffffffffc02066a0 <commands+0xbe8>
ffffffffc0201994:	00005617          	auipc	a2,0x5
ffffffffc0201998:	9f460613          	addi	a2,a2,-1548 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020199c:	13700593          	li	a1,311
ffffffffc02019a0:	00005517          	auipc	a0,0x5
ffffffffc02019a4:	a0050513          	addi	a0,a0,-1536 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02019a8:	ae7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02019ac:	00005697          	auipc	a3,0x5
ffffffffc02019b0:	d2468693          	addi	a3,a3,-732 # ffffffffc02066d0 <commands+0xc18>
ffffffffc02019b4:	00005617          	auipc	a2,0x5
ffffffffc02019b8:	9d460613          	addi	a2,a2,-1580 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02019bc:	14700593          	li	a1,327
ffffffffc02019c0:	00005517          	auipc	a0,0x5
ffffffffc02019c4:	9e050513          	addi	a0,a0,-1568 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02019c8:	ac7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02019cc:	00005697          	auipc	a3,0x5
ffffffffc02019d0:	9ec68693          	addi	a3,a3,-1556 # ffffffffc02063b8 <commands+0x900>
ffffffffc02019d4:	00005617          	auipc	a2,0x5
ffffffffc02019d8:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02019dc:	11300593          	li	a1,275
ffffffffc02019e0:	00005517          	auipc	a0,0x5
ffffffffc02019e4:	9c050513          	addi	a0,a0,-1600 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc02019e8:	aa7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02019ec:	00005697          	auipc	a3,0x5
ffffffffc02019f0:	a0c68693          	addi	a3,a3,-1524 # ffffffffc02063f8 <commands+0x940>
ffffffffc02019f4:	00005617          	auipc	a2,0x5
ffffffffc02019f8:	99460613          	addi	a2,a2,-1644 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02019fc:	0d800593          	li	a1,216
ffffffffc0201a00:	00005517          	auipc	a0,0x5
ffffffffc0201a04:	9a050513          	addi	a0,a0,-1632 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201a08:	a87fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a0c <default_free_pages>:
{
ffffffffc0201a0c:	1141                	addi	sp,sp,-16
ffffffffc0201a0e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a10:	14058463          	beqz	a1,ffffffffc0201b58 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201a14:	00659693          	slli	a3,a1,0x6
ffffffffc0201a18:	96aa                	add	a3,a3,a0
ffffffffc0201a1a:	87aa                	mv	a5,a0
ffffffffc0201a1c:	02d50263          	beq	a0,a3,ffffffffc0201a40 <default_free_pages+0x34>
ffffffffc0201a20:	6798                	ld	a4,8(a5)
ffffffffc0201a22:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201a24:	10071a63          	bnez	a4,ffffffffc0201b38 <default_free_pages+0x12c>
ffffffffc0201a28:	6798                	ld	a4,8(a5)
ffffffffc0201a2a:	8b09                	andi	a4,a4,2
ffffffffc0201a2c:	10071663          	bnez	a4,ffffffffc0201b38 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201a30:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0201a34:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a38:	04078793          	addi	a5,a5,64
ffffffffc0201a3c:	fed792e3          	bne	a5,a3,ffffffffc0201a20 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201a40:	2581                	sext.w	a1,a1
ffffffffc0201a42:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201a44:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a48:	4789                	li	a5,2
ffffffffc0201a4a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201a4e:	000ca697          	auipc	a3,0xca
ffffffffc0201a52:	9ca68693          	addi	a3,a3,-1590 # ffffffffc02cb418 <free_area>
ffffffffc0201a56:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a58:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a5a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a5e:	9db9                	addw	a1,a1,a4
ffffffffc0201a60:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a62:	0ad78463          	beq	a5,a3,ffffffffc0201b0a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a66:	fe878713          	addi	a4,a5,-24
ffffffffc0201a6a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a6e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a70:	00e56a63          	bltu	a0,a4,ffffffffc0201a84 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201a74:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a76:	04d70c63          	beq	a4,a3,ffffffffc0201ace <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201a7a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a7c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a80:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a74 <default_free_pages+0x68>
ffffffffc0201a84:	c199                	beqz	a1,ffffffffc0201a8a <default_free_pages+0x7e>
ffffffffc0201a86:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a8a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201a8c:	e390                	sd	a2,0(a5)
ffffffffc0201a8e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a90:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a92:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201a94:	00d70d63          	beq	a4,a3,ffffffffc0201aae <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201a98:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201a9c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201aa0:	02059813          	slli	a6,a1,0x20
ffffffffc0201aa4:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201aa8:	97b2                	add	a5,a5,a2
ffffffffc0201aaa:	02f50c63          	beq	a0,a5,ffffffffc0201ae2 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201aae:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201ab0:	00d78c63          	beq	a5,a3,ffffffffc0201ac8 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201ab4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201ab6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201aba:	02061593          	slli	a1,a2,0x20
ffffffffc0201abe:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201ac2:	972a                	add	a4,a4,a0
ffffffffc0201ac4:	04e68a63          	beq	a3,a4,ffffffffc0201b18 <default_free_pages+0x10c>
}
ffffffffc0201ac8:	60a2                	ld	ra,8(sp)
ffffffffc0201aca:	0141                	addi	sp,sp,16
ffffffffc0201acc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201ace:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ad0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201ad2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201ad4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201ad6:	02d70763          	beq	a4,a3,ffffffffc0201b04 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201ada:	8832                	mv	a6,a2
ffffffffc0201adc:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ade:	87ba                	mv	a5,a4
ffffffffc0201ae0:	bf71                	j	ffffffffc0201a7c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201ae2:	491c                	lw	a5,16(a0)
ffffffffc0201ae4:	9dbd                	addw	a1,a1,a5
ffffffffc0201ae6:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201aea:	57f5                	li	a5,-3
ffffffffc0201aec:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201af0:	01853803          	ld	a6,24(a0)
ffffffffc0201af4:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201af6:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201af8:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201afc:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201afe:	0105b023          	sd	a6,0(a1)
ffffffffc0201b02:	b77d                	j	ffffffffc0201ab0 <default_free_pages+0xa4>
ffffffffc0201b04:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201b06:	873e                	mv	a4,a5
ffffffffc0201b08:	bf41                	j	ffffffffc0201a98 <default_free_pages+0x8c>
}
ffffffffc0201b0a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201b0c:	e390                	sd	a2,0(a5)
ffffffffc0201b0e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201b10:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201b12:	ed1c                	sd	a5,24(a0)
ffffffffc0201b14:	0141                	addi	sp,sp,16
ffffffffc0201b16:	8082                	ret
            base->property += p->property;
ffffffffc0201b18:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201b1c:	ff078693          	addi	a3,a5,-16
ffffffffc0201b20:	9e39                	addw	a2,a2,a4
ffffffffc0201b22:	c910                	sw	a2,16(a0)
ffffffffc0201b24:	5775                	li	a4,-3
ffffffffc0201b26:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201b2a:	6398                	ld	a4,0(a5)
ffffffffc0201b2c:	679c                	ld	a5,8(a5)
}
ffffffffc0201b2e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201b30:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201b32:	e398                	sd	a4,0(a5)
ffffffffc0201b34:	0141                	addi	sp,sp,16
ffffffffc0201b36:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201b38:	00005697          	auipc	a3,0x5
ffffffffc0201b3c:	bb068693          	addi	a3,a3,-1104 # ffffffffc02066e8 <commands+0xc30>
ffffffffc0201b40:	00005617          	auipc	a2,0x5
ffffffffc0201b44:	84860613          	addi	a2,a2,-1976 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0201b48:	09400593          	li	a1,148
ffffffffc0201b4c:	00005517          	auipc	a0,0x5
ffffffffc0201b50:	85450513          	addi	a0,a0,-1964 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201b54:	93bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201b58:	00005697          	auipc	a3,0x5
ffffffffc0201b5c:	b8868693          	addi	a3,a3,-1144 # ffffffffc02066e0 <commands+0xc28>
ffffffffc0201b60:	00005617          	auipc	a2,0x5
ffffffffc0201b64:	82860613          	addi	a2,a2,-2008 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0201b68:	09000593          	li	a1,144
ffffffffc0201b6c:	00005517          	auipc	a0,0x5
ffffffffc0201b70:	83450513          	addi	a0,a0,-1996 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201b74:	91bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b78 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201b78:	c941                	beqz	a0,ffffffffc0201c08 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201b7a:	000ca597          	auipc	a1,0xca
ffffffffc0201b7e:	89e58593          	addi	a1,a1,-1890 # ffffffffc02cb418 <free_area>
ffffffffc0201b82:	0105a803          	lw	a6,16(a1)
ffffffffc0201b86:	872a                	mv	a4,a0
ffffffffc0201b88:	02081793          	slli	a5,a6,0x20
ffffffffc0201b8c:	9381                	srli	a5,a5,0x20
ffffffffc0201b8e:	00a7ee63          	bltu	a5,a0,ffffffffc0201baa <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201b92:	87ae                	mv	a5,a1
ffffffffc0201b94:	a801                	j	ffffffffc0201ba4 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201b96:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201b9a:	02069613          	slli	a2,a3,0x20
ffffffffc0201b9e:	9201                	srli	a2,a2,0x20
ffffffffc0201ba0:	00e67763          	bgeu	a2,a4,ffffffffc0201bae <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201ba4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201ba6:	feb798e3          	bne	a5,a1,ffffffffc0201b96 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201baa:	4501                	li	a0,0
}
ffffffffc0201bac:	8082                	ret
    return listelm->prev;
ffffffffc0201bae:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201bb2:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201bb6:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201bba:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201bbe:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201bc2:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201bc6:	02c77863          	bgeu	a4,a2,ffffffffc0201bf6 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201bca:	071a                	slli	a4,a4,0x6
ffffffffc0201bcc:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201bce:	41c686bb          	subw	a3,a3,t3
ffffffffc0201bd2:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201bd4:	00870613          	addi	a2,a4,8
ffffffffc0201bd8:	4689                	li	a3,2
ffffffffc0201bda:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201bde:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201be2:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201be6:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201bea:	e290                	sd	a2,0(a3)
ffffffffc0201bec:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201bf0:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201bf2:	01173c23          	sd	a7,24(a4)
ffffffffc0201bf6:	41c8083b          	subw	a6,a6,t3
ffffffffc0201bfa:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201bfe:	5775                	li	a4,-3
ffffffffc0201c00:	17c1                	addi	a5,a5,-16
ffffffffc0201c02:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201c06:	8082                	ret
{
ffffffffc0201c08:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201c0a:	00005697          	auipc	a3,0x5
ffffffffc0201c0e:	ad668693          	addi	a3,a3,-1322 # ffffffffc02066e0 <commands+0xc28>
ffffffffc0201c12:	00004617          	auipc	a2,0x4
ffffffffc0201c16:	77660613          	addi	a2,a2,1910 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0201c1a:	06c00593          	li	a1,108
ffffffffc0201c1e:	00004517          	auipc	a0,0x4
ffffffffc0201c22:	78250513          	addi	a0,a0,1922 # ffffffffc02063a0 <commands+0x8e8>
{
ffffffffc0201c26:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201c28:	867fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c2c <default_init_memmap>:
{
ffffffffc0201c2c:	1141                	addi	sp,sp,-16
ffffffffc0201c2e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201c30:	c5f1                	beqz	a1,ffffffffc0201cfc <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201c32:	00659693          	slli	a3,a1,0x6
ffffffffc0201c36:	96aa                	add	a3,a3,a0
ffffffffc0201c38:	87aa                	mv	a5,a0
ffffffffc0201c3a:	00d50f63          	beq	a0,a3,ffffffffc0201c58 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201c3e:	6798                	ld	a4,8(a5)
ffffffffc0201c40:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201c42:	cf49                	beqz	a4,ffffffffc0201cdc <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201c44:	0007a823          	sw	zero,16(a5)
ffffffffc0201c48:	0007b423          	sd	zero,8(a5)
ffffffffc0201c4c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201c50:	04078793          	addi	a5,a5,64
ffffffffc0201c54:	fed795e3          	bne	a5,a3,ffffffffc0201c3e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201c58:	2581                	sext.w	a1,a1
ffffffffc0201c5a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201c5c:	4789                	li	a5,2
ffffffffc0201c5e:	00850713          	addi	a4,a0,8
ffffffffc0201c62:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201c66:	000c9697          	auipc	a3,0xc9
ffffffffc0201c6a:	7b268693          	addi	a3,a3,1970 # ffffffffc02cb418 <free_area>
ffffffffc0201c6e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201c70:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201c72:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201c76:	9db9                	addw	a1,a1,a4
ffffffffc0201c78:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201c7a:	04d78a63          	beq	a5,a3,ffffffffc0201cce <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201c7e:	fe878713          	addi	a4,a5,-24
ffffffffc0201c82:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201c86:	4581                	li	a1,0
            if (base < page)
ffffffffc0201c88:	00e56a63          	bltu	a0,a4,ffffffffc0201c9c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201c8c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201c8e:	02d70263          	beq	a4,a3,ffffffffc0201cb2 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201c92:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201c94:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201c98:	fee57ae3          	bgeu	a0,a4,ffffffffc0201c8c <default_init_memmap+0x60>
ffffffffc0201c9c:	c199                	beqz	a1,ffffffffc0201ca2 <default_init_memmap+0x76>
ffffffffc0201c9e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201ca2:	6398                	ld	a4,0(a5)
}
ffffffffc0201ca4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201ca6:	e390                	sd	a2,0(a5)
ffffffffc0201ca8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201caa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201cac:	ed18                	sd	a4,24(a0)
ffffffffc0201cae:	0141                	addi	sp,sp,16
ffffffffc0201cb0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201cb2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201cb4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201cb6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201cb8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201cba:	00d70663          	beq	a4,a3,ffffffffc0201cc6 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201cbe:	8832                	mv	a6,a2
ffffffffc0201cc0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201cc2:	87ba                	mv	a5,a4
ffffffffc0201cc4:	bfc1                	j	ffffffffc0201c94 <default_init_memmap+0x68>
}
ffffffffc0201cc6:	60a2                	ld	ra,8(sp)
ffffffffc0201cc8:	e290                	sd	a2,0(a3)
ffffffffc0201cca:	0141                	addi	sp,sp,16
ffffffffc0201ccc:	8082                	ret
ffffffffc0201cce:	60a2                	ld	ra,8(sp)
ffffffffc0201cd0:	e390                	sd	a2,0(a5)
ffffffffc0201cd2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201cd4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201cd6:	ed1c                	sd	a5,24(a0)
ffffffffc0201cd8:	0141                	addi	sp,sp,16
ffffffffc0201cda:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201cdc:	00005697          	auipc	a3,0x5
ffffffffc0201ce0:	a3468693          	addi	a3,a3,-1484 # ffffffffc0206710 <commands+0xc58>
ffffffffc0201ce4:	00004617          	auipc	a2,0x4
ffffffffc0201ce8:	6a460613          	addi	a2,a2,1700 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0201cec:	04b00593          	li	a1,75
ffffffffc0201cf0:	00004517          	auipc	a0,0x4
ffffffffc0201cf4:	6b050513          	addi	a0,a0,1712 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201cf8:	f96fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201cfc:	00005697          	auipc	a3,0x5
ffffffffc0201d00:	9e468693          	addi	a3,a3,-1564 # ffffffffc02066e0 <commands+0xc28>
ffffffffc0201d04:	00004617          	auipc	a2,0x4
ffffffffc0201d08:	68460613          	addi	a2,a2,1668 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0201d0c:	04700593          	li	a1,71
ffffffffc0201d10:	00004517          	auipc	a0,0x4
ffffffffc0201d14:	69050513          	addi	a0,a0,1680 # ffffffffc02063a0 <commands+0x8e8>
ffffffffc0201d18:	f76fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d1c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201d1c:	c94d                	beqz	a0,ffffffffc0201dce <slob_free+0xb2>
{
ffffffffc0201d1e:	1141                	addi	sp,sp,-16
ffffffffc0201d20:	e022                	sd	s0,0(sp)
ffffffffc0201d22:	e406                	sd	ra,8(sp)
ffffffffc0201d24:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201d26:	e9c1                	bnez	a1,ffffffffc0201db6 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d28:	100027f3          	csrr	a5,sstatus
ffffffffc0201d2c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201d2e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d30:	ebd9                	bnez	a5,ffffffffc0201dc6 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201d32:	000c9617          	auipc	a2,0xc9
ffffffffc0201d36:	2d660613          	addi	a2,a2,726 # ffffffffc02cb008 <slobfree>
ffffffffc0201d3a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201d3c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201d3e:	679c                	ld	a5,8(a5)
ffffffffc0201d40:	02877a63          	bgeu	a4,s0,ffffffffc0201d74 <slob_free+0x58>
ffffffffc0201d44:	00f46463          	bltu	s0,a5,ffffffffc0201d4c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201d48:	fef76ae3          	bltu	a4,a5,ffffffffc0201d3c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201d4c:	400c                	lw	a1,0(s0)
ffffffffc0201d4e:	00459693          	slli	a3,a1,0x4
ffffffffc0201d52:	96a2                	add	a3,a3,s0
ffffffffc0201d54:	02d78a63          	beq	a5,a3,ffffffffc0201d88 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201d58:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201d5a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201d5c:	00469793          	slli	a5,a3,0x4
ffffffffc0201d60:	97ba                	add	a5,a5,a4
ffffffffc0201d62:	02f40e63          	beq	s0,a5,ffffffffc0201d9e <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201d66:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201d68:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201d6a:	e129                	bnez	a0,ffffffffc0201dac <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201d6c:	60a2                	ld	ra,8(sp)
ffffffffc0201d6e:	6402                	ld	s0,0(sp)
ffffffffc0201d70:	0141                	addi	sp,sp,16
ffffffffc0201d72:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201d74:	fcf764e3          	bltu	a4,a5,ffffffffc0201d3c <slob_free+0x20>
ffffffffc0201d78:	fcf472e3          	bgeu	s0,a5,ffffffffc0201d3c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201d7c:	400c                	lw	a1,0(s0)
ffffffffc0201d7e:	00459693          	slli	a3,a1,0x4
ffffffffc0201d82:	96a2                	add	a3,a3,s0
ffffffffc0201d84:	fcd79ae3          	bne	a5,a3,ffffffffc0201d58 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201d88:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201d8a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201d8c:	9db5                	addw	a1,a1,a3
ffffffffc0201d8e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201d90:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201d92:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201d94:	00469793          	slli	a5,a3,0x4
ffffffffc0201d98:	97ba                	add	a5,a5,a4
ffffffffc0201d9a:	fcf416e3          	bne	s0,a5,ffffffffc0201d66 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201d9e:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201da0:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201da2:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201da4:	9ebd                	addw	a3,a3,a5
ffffffffc0201da6:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201da8:	e70c                	sd	a1,8(a4)
ffffffffc0201daa:	d169                	beqz	a0,ffffffffc0201d6c <slob_free+0x50>
}
ffffffffc0201dac:	6402                	ld	s0,0(sp)
ffffffffc0201dae:	60a2                	ld	ra,8(sp)
ffffffffc0201db0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201db2:	bfdfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201db6:	25bd                	addiw	a1,a1,15
ffffffffc0201db8:	8191                	srli	a1,a1,0x4
ffffffffc0201dba:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dbc:	100027f3          	csrr	a5,sstatus
ffffffffc0201dc0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201dc2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dc4:	d7bd                	beqz	a5,ffffffffc0201d32 <slob_free+0x16>
        intr_disable();
ffffffffc0201dc6:	beffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201dca:	4505                	li	a0,1
ffffffffc0201dcc:	b79d                	j	ffffffffc0201d32 <slob_free+0x16>
ffffffffc0201dce:	8082                	ret

ffffffffc0201dd0 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201dd0:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201dd2:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201dd4:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201dd8:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201dda:	352000ef          	jal	ra,ffffffffc020212c <alloc_pages>
	if (!page)
ffffffffc0201dde:	c91d                	beqz	a0,ffffffffc0201e14 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201de0:	000cd697          	auipc	a3,0xcd
ffffffffc0201de4:	6a86b683          	ld	a3,1704(a3) # ffffffffc02cf488 <pages>
ffffffffc0201de8:	8d15                	sub	a0,a0,a3
ffffffffc0201dea:	8519                	srai	a0,a0,0x6
ffffffffc0201dec:	00006697          	auipc	a3,0x6
ffffffffc0201df0:	bcc6b683          	ld	a3,-1076(a3) # ffffffffc02079b8 <nbase>
ffffffffc0201df4:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201df6:	00c51793          	slli	a5,a0,0xc
ffffffffc0201dfa:	83b1                	srli	a5,a5,0xc
ffffffffc0201dfc:	000cd717          	auipc	a4,0xcd
ffffffffc0201e00:	68473703          	ld	a4,1668(a4) # ffffffffc02cf480 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e04:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201e06:	00e7fa63          	bgeu	a5,a4,ffffffffc0201e1a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201e0a:	000cd697          	auipc	a3,0xcd
ffffffffc0201e0e:	68e6b683          	ld	a3,1678(a3) # ffffffffc02cf498 <va_pa_offset>
ffffffffc0201e12:	9536                	add	a0,a0,a3
}
ffffffffc0201e14:	60a2                	ld	ra,8(sp)
ffffffffc0201e16:	0141                	addi	sp,sp,16
ffffffffc0201e18:	8082                	ret
ffffffffc0201e1a:	86aa                	mv	a3,a0
ffffffffc0201e1c:	00004617          	auipc	a2,0x4
ffffffffc0201e20:	26460613          	addi	a2,a2,612 # ffffffffc0206080 <commands+0x5c8>
ffffffffc0201e24:	07100593          	li	a1,113
ffffffffc0201e28:	00004517          	auipc	a0,0x4
ffffffffc0201e2c:	24850513          	addi	a0,a0,584 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0201e30:	e5efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e34 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201e34:	1101                	addi	sp,sp,-32
ffffffffc0201e36:	ec06                	sd	ra,24(sp)
ffffffffc0201e38:	e822                	sd	s0,16(sp)
ffffffffc0201e3a:	e426                	sd	s1,8(sp)
ffffffffc0201e3c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201e3e:	01050713          	addi	a4,a0,16
ffffffffc0201e42:	6785                	lui	a5,0x1
ffffffffc0201e44:	0cf77363          	bgeu	a4,a5,ffffffffc0201f0a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201e48:	00f50493          	addi	s1,a0,15
ffffffffc0201e4c:	8091                	srli	s1,s1,0x4
ffffffffc0201e4e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e50:	10002673          	csrr	a2,sstatus
ffffffffc0201e54:	8a09                	andi	a2,a2,2
ffffffffc0201e56:	e25d                	bnez	a2,ffffffffc0201efc <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201e58:	000c9917          	auipc	s2,0xc9
ffffffffc0201e5c:	1b090913          	addi	s2,s2,432 # ffffffffc02cb008 <slobfree>
ffffffffc0201e60:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201e64:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201e66:	4398                	lw	a4,0(a5)
ffffffffc0201e68:	08975e63          	bge	a4,s1,ffffffffc0201f04 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201e6c:	00f68b63          	beq	a3,a5,ffffffffc0201e82 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201e70:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201e72:	4018                	lw	a4,0(s0)
ffffffffc0201e74:	02975a63          	bge	a4,s1,ffffffffc0201ea8 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201e78:	00093683          	ld	a3,0(s2)
ffffffffc0201e7c:	87a2                	mv	a5,s0
ffffffffc0201e7e:	fef699e3          	bne	a3,a5,ffffffffc0201e70 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201e82:	ee31                	bnez	a2,ffffffffc0201ede <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201e84:	4501                	li	a0,0
ffffffffc0201e86:	f4bff0ef          	jal	ra,ffffffffc0201dd0 <__slob_get_free_pages.constprop.0>
ffffffffc0201e8a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201e8c:	cd05                	beqz	a0,ffffffffc0201ec4 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201e8e:	6585                	lui	a1,0x1
ffffffffc0201e90:	e8dff0ef          	jal	ra,ffffffffc0201d1c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e94:	10002673          	csrr	a2,sstatus
ffffffffc0201e98:	8a09                	andi	a2,a2,2
ffffffffc0201e9a:	ee05                	bnez	a2,ffffffffc0201ed2 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201e9c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ea0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201ea2:	4018                	lw	a4,0(s0)
ffffffffc0201ea4:	fc974ae3          	blt	a4,s1,ffffffffc0201e78 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201ea8:	04e48763          	beq	s1,a4,ffffffffc0201ef6 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201eac:	00449693          	slli	a3,s1,0x4
ffffffffc0201eb0:	96a2                	add	a3,a3,s0
ffffffffc0201eb2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201eb4:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201eb6:	9f05                	subw	a4,a4,s1
ffffffffc0201eb8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201eba:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201ebc:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201ebe:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201ec2:	e20d                	bnez	a2,ffffffffc0201ee4 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201ec4:	60e2                	ld	ra,24(sp)
ffffffffc0201ec6:	8522                	mv	a0,s0
ffffffffc0201ec8:	6442                	ld	s0,16(sp)
ffffffffc0201eca:	64a2                	ld	s1,8(sp)
ffffffffc0201ecc:	6902                	ld	s2,0(sp)
ffffffffc0201ece:	6105                	addi	sp,sp,32
ffffffffc0201ed0:	8082                	ret
        intr_disable();
ffffffffc0201ed2:	ae3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201ed6:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201eda:	4605                	li	a2,1
ffffffffc0201edc:	b7d1                	j	ffffffffc0201ea0 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201ede:	ad1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ee2:	b74d                	j	ffffffffc0201e84 <slob_alloc.constprop.0+0x50>
ffffffffc0201ee4:	acbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201ee8:	60e2                	ld	ra,24(sp)
ffffffffc0201eea:	8522                	mv	a0,s0
ffffffffc0201eec:	6442                	ld	s0,16(sp)
ffffffffc0201eee:	64a2                	ld	s1,8(sp)
ffffffffc0201ef0:	6902                	ld	s2,0(sp)
ffffffffc0201ef2:	6105                	addi	sp,sp,32
ffffffffc0201ef4:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ef6:	6418                	ld	a4,8(s0)
ffffffffc0201ef8:	e798                	sd	a4,8(a5)
ffffffffc0201efa:	b7d1                	j	ffffffffc0201ebe <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201efc:	ab9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201f00:	4605                	li	a2,1
ffffffffc0201f02:	bf99                	j	ffffffffc0201e58 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201f04:	843e                	mv	s0,a5
ffffffffc0201f06:	87b6                	mv	a5,a3
ffffffffc0201f08:	b745                	j	ffffffffc0201ea8 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201f0a:	00005697          	auipc	a3,0x5
ffffffffc0201f0e:	86668693          	addi	a3,a3,-1946 # ffffffffc0206770 <default_pmm_manager+0x38>
ffffffffc0201f12:	00004617          	auipc	a2,0x4
ffffffffc0201f16:	47660613          	addi	a2,a2,1142 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0201f1a:	06300593          	li	a1,99
ffffffffc0201f1e:	00005517          	auipc	a0,0x5
ffffffffc0201f22:	87250513          	addi	a0,a0,-1934 # ffffffffc0206790 <default_pmm_manager+0x58>
ffffffffc0201f26:	d68fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f2a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201f2a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201f2c:	00005517          	auipc	a0,0x5
ffffffffc0201f30:	87c50513          	addi	a0,a0,-1924 # ffffffffc02067a8 <default_pmm_manager+0x70>
{
ffffffffc0201f34:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201f36:	a5efe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201f3a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201f3c:	00005517          	auipc	a0,0x5
ffffffffc0201f40:	88450513          	addi	a0,a0,-1916 # ffffffffc02067c0 <default_pmm_manager+0x88>
}
ffffffffc0201f44:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201f46:	a4efe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201f4a <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201f4a:	4501                	li	a0,0
ffffffffc0201f4c:	8082                	ret

ffffffffc0201f4e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201f4e:	1101                	addi	sp,sp,-32
ffffffffc0201f50:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201f52:	6905                	lui	s2,0x1
{
ffffffffc0201f54:	e822                	sd	s0,16(sp)
ffffffffc0201f56:	ec06                	sd	ra,24(sp)
ffffffffc0201f58:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201f5a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8fb1>
{
ffffffffc0201f5e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201f60:	04a7f963          	bgeu	a5,a0,ffffffffc0201fb2 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201f64:	4561                	li	a0,24
ffffffffc0201f66:	ecfff0ef          	jal	ra,ffffffffc0201e34 <slob_alloc.constprop.0>
ffffffffc0201f6a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201f6c:	c929                	beqz	a0,ffffffffc0201fbe <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201f6e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201f72:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201f74:	00f95763          	bge	s2,a5,ffffffffc0201f82 <kmalloc+0x34>
ffffffffc0201f78:	6705                	lui	a4,0x1
ffffffffc0201f7a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201f7c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201f7e:	fef74ee3          	blt	a4,a5,ffffffffc0201f7a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201f82:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201f84:	e4dff0ef          	jal	ra,ffffffffc0201dd0 <__slob_get_free_pages.constprop.0>
ffffffffc0201f88:	e488                	sd	a0,8(s1)
ffffffffc0201f8a:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201f8c:	c525                	beqz	a0,ffffffffc0201ff4 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f8e:	100027f3          	csrr	a5,sstatus
ffffffffc0201f92:	8b89                	andi	a5,a5,2
ffffffffc0201f94:	ef8d                	bnez	a5,ffffffffc0201fce <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201f96:	000cd797          	auipc	a5,0xcd
ffffffffc0201f9a:	4d278793          	addi	a5,a5,1234 # ffffffffc02cf468 <bigblocks>
ffffffffc0201f9e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201fa0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201fa2:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201fa4:	60e2                	ld	ra,24(sp)
ffffffffc0201fa6:	8522                	mv	a0,s0
ffffffffc0201fa8:	6442                	ld	s0,16(sp)
ffffffffc0201faa:	64a2                	ld	s1,8(sp)
ffffffffc0201fac:	6902                	ld	s2,0(sp)
ffffffffc0201fae:	6105                	addi	sp,sp,32
ffffffffc0201fb0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201fb2:	0541                	addi	a0,a0,16
ffffffffc0201fb4:	e81ff0ef          	jal	ra,ffffffffc0201e34 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201fb8:	01050413          	addi	s0,a0,16
ffffffffc0201fbc:	f565                	bnez	a0,ffffffffc0201fa4 <kmalloc+0x56>
ffffffffc0201fbe:	4401                	li	s0,0
}
ffffffffc0201fc0:	60e2                	ld	ra,24(sp)
ffffffffc0201fc2:	8522                	mv	a0,s0
ffffffffc0201fc4:	6442                	ld	s0,16(sp)
ffffffffc0201fc6:	64a2                	ld	s1,8(sp)
ffffffffc0201fc8:	6902                	ld	s2,0(sp)
ffffffffc0201fca:	6105                	addi	sp,sp,32
ffffffffc0201fcc:	8082                	ret
        intr_disable();
ffffffffc0201fce:	9e7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201fd2:	000cd797          	auipc	a5,0xcd
ffffffffc0201fd6:	49678793          	addi	a5,a5,1174 # ffffffffc02cf468 <bigblocks>
ffffffffc0201fda:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201fdc:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201fde:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201fe0:	9cffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201fe4:	6480                	ld	s0,8(s1)
}
ffffffffc0201fe6:	60e2                	ld	ra,24(sp)
ffffffffc0201fe8:	64a2                	ld	s1,8(sp)
ffffffffc0201fea:	8522                	mv	a0,s0
ffffffffc0201fec:	6442                	ld	s0,16(sp)
ffffffffc0201fee:	6902                	ld	s2,0(sp)
ffffffffc0201ff0:	6105                	addi	sp,sp,32
ffffffffc0201ff2:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ff4:	45e1                	li	a1,24
ffffffffc0201ff6:	8526                	mv	a0,s1
ffffffffc0201ff8:	d25ff0ef          	jal	ra,ffffffffc0201d1c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201ffc:	b765                	j	ffffffffc0201fa4 <kmalloc+0x56>

ffffffffc0201ffe <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201ffe:	c169                	beqz	a0,ffffffffc02020c0 <kfree+0xc2>
{
ffffffffc0202000:	1101                	addi	sp,sp,-32
ffffffffc0202002:	e822                	sd	s0,16(sp)
ffffffffc0202004:	ec06                	sd	ra,24(sp)
ffffffffc0202006:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0202008:	03451793          	slli	a5,a0,0x34
ffffffffc020200c:	842a                	mv	s0,a0
ffffffffc020200e:	e3d9                	bnez	a5,ffffffffc0202094 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202010:	100027f3          	csrr	a5,sstatus
ffffffffc0202014:	8b89                	andi	a5,a5,2
ffffffffc0202016:	e7d9                	bnez	a5,ffffffffc02020a4 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202018:	000cd797          	auipc	a5,0xcd
ffffffffc020201c:	4507b783          	ld	a5,1104(a5) # ffffffffc02cf468 <bigblocks>
    return 0;
ffffffffc0202020:	4601                	li	a2,0
ffffffffc0202022:	cbad                	beqz	a5,ffffffffc0202094 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0202024:	000cd697          	auipc	a3,0xcd
ffffffffc0202028:	44468693          	addi	a3,a3,1092 # ffffffffc02cf468 <bigblocks>
ffffffffc020202c:	a021                	j	ffffffffc0202034 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc020202e:	01048693          	addi	a3,s1,16
ffffffffc0202032:	c3a5                	beqz	a5,ffffffffc0202092 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0202034:	6798                	ld	a4,8(a5)
ffffffffc0202036:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0202038:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc020203a:	fe871ae3          	bne	a4,s0,ffffffffc020202e <kfree+0x30>
				*last = bb->next;
ffffffffc020203e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0202040:	ee2d                	bnez	a2,ffffffffc02020ba <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0202042:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0202046:	4098                	lw	a4,0(s1)
ffffffffc0202048:	08f46963          	bltu	s0,a5,ffffffffc02020da <kfree+0xdc>
ffffffffc020204c:	000cd697          	auipc	a3,0xcd
ffffffffc0202050:	44c6b683          	ld	a3,1100(a3) # ffffffffc02cf498 <va_pa_offset>
ffffffffc0202054:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0202056:	8031                	srli	s0,s0,0xc
ffffffffc0202058:	000cd797          	auipc	a5,0xcd
ffffffffc020205c:	4287b783          	ld	a5,1064(a5) # ffffffffc02cf480 <npage>
ffffffffc0202060:	06f47163          	bgeu	s0,a5,ffffffffc02020c2 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0202064:	00006517          	auipc	a0,0x6
ffffffffc0202068:	95453503          	ld	a0,-1708(a0) # ffffffffc02079b8 <nbase>
ffffffffc020206c:	8c09                	sub	s0,s0,a0
ffffffffc020206e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0202070:	000cd517          	auipc	a0,0xcd
ffffffffc0202074:	41853503          	ld	a0,1048(a0) # ffffffffc02cf488 <pages>
ffffffffc0202078:	4585                	li	a1,1
ffffffffc020207a:	9522                	add	a0,a0,s0
ffffffffc020207c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0202080:	0ea000ef          	jal	ra,ffffffffc020216a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0202084:	6442                	ld	s0,16(sp)
ffffffffc0202086:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202088:	8526                	mv	a0,s1
}
ffffffffc020208a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc020208c:	45e1                	li	a1,24
}
ffffffffc020208e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202090:	b171                	j	ffffffffc0201d1c <slob_free>
ffffffffc0202092:	e20d                	bnez	a2,ffffffffc02020b4 <kfree+0xb6>
ffffffffc0202094:	ff040513          	addi	a0,s0,-16
}
ffffffffc0202098:	6442                	ld	s0,16(sp)
ffffffffc020209a:	60e2                	ld	ra,24(sp)
ffffffffc020209c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc020209e:	4581                	li	a1,0
}
ffffffffc02020a0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02020a2:	b9ad                	j	ffffffffc0201d1c <slob_free>
        intr_disable();
ffffffffc02020a4:	911fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc02020a8:	000cd797          	auipc	a5,0xcd
ffffffffc02020ac:	3c07b783          	ld	a5,960(a5) # ffffffffc02cf468 <bigblocks>
        return 1;
ffffffffc02020b0:	4605                	li	a2,1
ffffffffc02020b2:	fbad                	bnez	a5,ffffffffc0202024 <kfree+0x26>
        intr_enable();
ffffffffc02020b4:	8fbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020b8:	bff1                	j	ffffffffc0202094 <kfree+0x96>
ffffffffc02020ba:	8f5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020be:	b751                	j	ffffffffc0202042 <kfree+0x44>
ffffffffc02020c0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02020c2:	00004617          	auipc	a2,0x4
ffffffffc02020c6:	f8e60613          	addi	a2,a2,-114 # ffffffffc0206050 <commands+0x598>
ffffffffc02020ca:	06900593          	li	a1,105
ffffffffc02020ce:	00004517          	auipc	a0,0x4
ffffffffc02020d2:	fa250513          	addi	a0,a0,-94 # ffffffffc0206070 <commands+0x5b8>
ffffffffc02020d6:	bb8fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02020da:	86a2                	mv	a3,s0
ffffffffc02020dc:	00004617          	auipc	a2,0x4
ffffffffc02020e0:	70460613          	addi	a2,a2,1796 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc02020e4:	07700593          	li	a1,119
ffffffffc02020e8:	00004517          	auipc	a0,0x4
ffffffffc02020ec:	f8850513          	addi	a0,a0,-120 # ffffffffc0206070 <commands+0x5b8>
ffffffffc02020f0:	b9efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02020f4 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc02020f4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02020f6:	00004617          	auipc	a2,0x4
ffffffffc02020fa:	f5a60613          	addi	a2,a2,-166 # ffffffffc0206050 <commands+0x598>
ffffffffc02020fe:	06900593          	li	a1,105
ffffffffc0202102:	00004517          	auipc	a0,0x4
ffffffffc0202106:	f6e50513          	addi	a0,a0,-146 # ffffffffc0206070 <commands+0x5b8>
pa2page(uintptr_t pa)
ffffffffc020210a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020210c:	b82fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202110 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0202110:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0202112:	00004617          	auipc	a2,0x4
ffffffffc0202116:	6f660613          	addi	a2,a2,1782 # ffffffffc0206808 <default_pmm_manager+0xd0>
ffffffffc020211a:	07f00593          	li	a1,127
ffffffffc020211e:	00004517          	auipc	a0,0x4
ffffffffc0202122:	f5250513          	addi	a0,a0,-174 # ffffffffc0206070 <commands+0x5b8>
pte2page(pte_t pte)
ffffffffc0202126:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0202128:	b66fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020212c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020212c:	100027f3          	csrr	a5,sstatus
ffffffffc0202130:	8b89                	andi	a5,a5,2
ffffffffc0202132:	e799                	bnez	a5,ffffffffc0202140 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0202134:	000cd797          	auipc	a5,0xcd
ffffffffc0202138:	35c7b783          	ld	a5,860(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc020213c:	6f9c                	ld	a5,24(a5)
ffffffffc020213e:	8782                	jr	a5
{
ffffffffc0202140:	1141                	addi	sp,sp,-16
ffffffffc0202142:	e406                	sd	ra,8(sp)
ffffffffc0202144:	e022                	sd	s0,0(sp)
ffffffffc0202146:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0202148:	86dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020214c:	000cd797          	auipc	a5,0xcd
ffffffffc0202150:	3447b783          	ld	a5,836(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc0202154:	6f9c                	ld	a5,24(a5)
ffffffffc0202156:	8522                	mv	a0,s0
ffffffffc0202158:	9782                	jalr	a5
ffffffffc020215a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020215c:	853fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0202160:	60a2                	ld	ra,8(sp)
ffffffffc0202162:	8522                	mv	a0,s0
ffffffffc0202164:	6402                	ld	s0,0(sp)
ffffffffc0202166:	0141                	addi	sp,sp,16
ffffffffc0202168:	8082                	ret

ffffffffc020216a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020216a:	100027f3          	csrr	a5,sstatus
ffffffffc020216e:	8b89                	andi	a5,a5,2
ffffffffc0202170:	e799                	bnez	a5,ffffffffc020217e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0202172:	000cd797          	auipc	a5,0xcd
ffffffffc0202176:	31e7b783          	ld	a5,798(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc020217a:	739c                	ld	a5,32(a5)
ffffffffc020217c:	8782                	jr	a5
{
ffffffffc020217e:	1101                	addi	sp,sp,-32
ffffffffc0202180:	ec06                	sd	ra,24(sp)
ffffffffc0202182:	e822                	sd	s0,16(sp)
ffffffffc0202184:	e426                	sd	s1,8(sp)
ffffffffc0202186:	842a                	mv	s0,a0
ffffffffc0202188:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020218a:	82bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020218e:	000cd797          	auipc	a5,0xcd
ffffffffc0202192:	3027b783          	ld	a5,770(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc0202196:	739c                	ld	a5,32(a5)
ffffffffc0202198:	85a6                	mv	a1,s1
ffffffffc020219a:	8522                	mv	a0,s0
ffffffffc020219c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020219e:	6442                	ld	s0,16(sp)
ffffffffc02021a0:	60e2                	ld	ra,24(sp)
ffffffffc02021a2:	64a2                	ld	s1,8(sp)
ffffffffc02021a4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02021a6:	809fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc02021aa <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02021aa:	100027f3          	csrr	a5,sstatus
ffffffffc02021ae:	8b89                	andi	a5,a5,2
ffffffffc02021b0:	e799                	bnez	a5,ffffffffc02021be <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02021b2:	000cd797          	auipc	a5,0xcd
ffffffffc02021b6:	2de7b783          	ld	a5,734(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc02021ba:	779c                	ld	a5,40(a5)
ffffffffc02021bc:	8782                	jr	a5
{
ffffffffc02021be:	1141                	addi	sp,sp,-16
ffffffffc02021c0:	e406                	sd	ra,8(sp)
ffffffffc02021c2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02021c4:	ff0fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02021c8:	000cd797          	auipc	a5,0xcd
ffffffffc02021cc:	2c87b783          	ld	a5,712(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc02021d0:	779c                	ld	a5,40(a5)
ffffffffc02021d2:	9782                	jalr	a5
ffffffffc02021d4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02021d6:	fd8fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02021da:	60a2                	ld	ra,8(sp)
ffffffffc02021dc:	8522                	mv	a0,s0
ffffffffc02021de:	6402                	ld	s0,0(sp)
ffffffffc02021e0:	0141                	addi	sp,sp,16
ffffffffc02021e2:	8082                	ret

ffffffffc02021e4 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02021e4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc02021e8:	1ff7f793          	andi	a5,a5,511
{
ffffffffc02021ec:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02021ee:	078e                	slli	a5,a5,0x3
{
ffffffffc02021f0:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02021f2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc02021f6:	6094                	ld	a3,0(s1)
{
ffffffffc02021f8:	f04a                	sd	s2,32(sp)
ffffffffc02021fa:	ec4e                	sd	s3,24(sp)
ffffffffc02021fc:	e852                	sd	s4,16(sp)
ffffffffc02021fe:	fc06                	sd	ra,56(sp)
ffffffffc0202200:	f822                	sd	s0,48(sp)
ffffffffc0202202:	e456                	sd	s5,8(sp)
ffffffffc0202204:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0202206:	0016f793          	andi	a5,a3,1
{
ffffffffc020220a:	892e                	mv	s2,a1
ffffffffc020220c:	8a32                	mv	s4,a2
ffffffffc020220e:	000cd997          	auipc	s3,0xcd
ffffffffc0202212:	27298993          	addi	s3,s3,626 # ffffffffc02cf480 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202216:	efbd                	bnez	a5,ffffffffc0202294 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202218:	14060c63          	beqz	a2,ffffffffc0202370 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020221c:	100027f3          	csrr	a5,sstatus
ffffffffc0202220:	8b89                	andi	a5,a5,2
ffffffffc0202222:	14079963          	bnez	a5,ffffffffc0202374 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202226:	000cd797          	auipc	a5,0xcd
ffffffffc020222a:	26a7b783          	ld	a5,618(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc020222e:	6f9c                	ld	a5,24(a5)
ffffffffc0202230:	4505                	li	a0,1
ffffffffc0202232:	9782                	jalr	a5
ffffffffc0202234:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202236:	12040d63          	beqz	s0,ffffffffc0202370 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020223a:	000cdb17          	auipc	s6,0xcd
ffffffffc020223e:	24eb0b13          	addi	s6,s6,590 # ffffffffc02cf488 <pages>
ffffffffc0202242:	000b3503          	ld	a0,0(s6)
ffffffffc0202246:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020224a:	000cd997          	auipc	s3,0xcd
ffffffffc020224e:	23698993          	addi	s3,s3,566 # ffffffffc02cf480 <npage>
ffffffffc0202252:	40a40533          	sub	a0,s0,a0
ffffffffc0202256:	8519                	srai	a0,a0,0x6
ffffffffc0202258:	9556                	add	a0,a0,s5
ffffffffc020225a:	0009b703          	ld	a4,0(s3)
ffffffffc020225e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202262:	4685                	li	a3,1
ffffffffc0202264:	c014                	sw	a3,0(s0)
ffffffffc0202266:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202268:	0532                	slli	a0,a0,0xc
ffffffffc020226a:	16e7f763          	bgeu	a5,a4,ffffffffc02023d8 <get_pte+0x1f4>
ffffffffc020226e:	000cd797          	auipc	a5,0xcd
ffffffffc0202272:	22a7b783          	ld	a5,554(a5) # ffffffffc02cf498 <va_pa_offset>
ffffffffc0202276:	6605                	lui	a2,0x1
ffffffffc0202278:	4581                	li	a1,0
ffffffffc020227a:	953e                	add	a0,a0,a5
ffffffffc020227c:	5a6030ef          	jal	ra,ffffffffc0205822 <memset>
    return page - pages + nbase;
ffffffffc0202280:	000b3683          	ld	a3,0(s6)
ffffffffc0202284:	40d406b3          	sub	a3,s0,a3
ffffffffc0202288:	8699                	srai	a3,a3,0x6
ffffffffc020228a:	96d6                	add	a3,a3,s5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020228c:	06aa                	slli	a3,a3,0xa
ffffffffc020228e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202292:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202294:	77fd                	lui	a5,0xfffff
ffffffffc0202296:	068a                	slli	a3,a3,0x2
ffffffffc0202298:	0009b703          	ld	a4,0(s3)
ffffffffc020229c:	8efd                	and	a3,a3,a5
ffffffffc020229e:	00c6d793          	srli	a5,a3,0xc
ffffffffc02022a2:	10e7ff63          	bgeu	a5,a4,ffffffffc02023c0 <get_pte+0x1dc>
ffffffffc02022a6:	000cda97          	auipc	s5,0xcd
ffffffffc02022aa:	1f2a8a93          	addi	s5,s5,498 # ffffffffc02cf498 <va_pa_offset>
ffffffffc02022ae:	000ab403          	ld	s0,0(s5)
ffffffffc02022b2:	01595793          	srli	a5,s2,0x15
ffffffffc02022b6:	1ff7f793          	andi	a5,a5,511
ffffffffc02022ba:	96a2                	add	a3,a3,s0
ffffffffc02022bc:	00379413          	slli	s0,a5,0x3
ffffffffc02022c0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02022c2:	6014                	ld	a3,0(s0)
ffffffffc02022c4:	0016f793          	andi	a5,a3,1
ffffffffc02022c8:	ebad                	bnez	a5,ffffffffc020233a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02022ca:	0a0a0363          	beqz	s4,ffffffffc0202370 <get_pte+0x18c>
ffffffffc02022ce:	100027f3          	csrr	a5,sstatus
ffffffffc02022d2:	8b89                	andi	a5,a5,2
ffffffffc02022d4:	efcd                	bnez	a5,ffffffffc020238e <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022d6:	000cd797          	auipc	a5,0xcd
ffffffffc02022da:	1ba7b783          	ld	a5,442(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc02022de:	6f9c                	ld	a5,24(a5)
ffffffffc02022e0:	4505                	li	a0,1
ffffffffc02022e2:	9782                	jalr	a5
ffffffffc02022e4:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02022e6:	c4c9                	beqz	s1,ffffffffc0202370 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02022e8:	000cdb17          	auipc	s6,0xcd
ffffffffc02022ec:	1a0b0b13          	addi	s6,s6,416 # ffffffffc02cf488 <pages>
ffffffffc02022f0:	000b3503          	ld	a0,0(s6)
ffffffffc02022f4:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02022f8:	0009b703          	ld	a4,0(s3)
ffffffffc02022fc:	40a48533          	sub	a0,s1,a0
ffffffffc0202300:	8519                	srai	a0,a0,0x6
ffffffffc0202302:	9552                	add	a0,a0,s4
ffffffffc0202304:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202308:	4685                	li	a3,1
ffffffffc020230a:	c094                	sw	a3,0(s1)
ffffffffc020230c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020230e:	0532                	slli	a0,a0,0xc
ffffffffc0202310:	0ee7f163          	bgeu	a5,a4,ffffffffc02023f2 <get_pte+0x20e>
ffffffffc0202314:	000ab783          	ld	a5,0(s5)
ffffffffc0202318:	6605                	lui	a2,0x1
ffffffffc020231a:	4581                	li	a1,0
ffffffffc020231c:	953e                	add	a0,a0,a5
ffffffffc020231e:	504030ef          	jal	ra,ffffffffc0205822 <memset>
    return page - pages + nbase;
ffffffffc0202322:	000b3683          	ld	a3,0(s6)
ffffffffc0202326:	40d486b3          	sub	a3,s1,a3
ffffffffc020232a:	8699                	srai	a3,a3,0x6
ffffffffc020232c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020232e:	06aa                	slli	a3,a3,0xa
ffffffffc0202330:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202334:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202336:	0009b703          	ld	a4,0(s3)
ffffffffc020233a:	068a                	slli	a3,a3,0x2
ffffffffc020233c:	757d                	lui	a0,0xfffff
ffffffffc020233e:	8ee9                	and	a3,a3,a0
ffffffffc0202340:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202344:	06e7f263          	bgeu	a5,a4,ffffffffc02023a8 <get_pte+0x1c4>
ffffffffc0202348:	000ab503          	ld	a0,0(s5)
ffffffffc020234c:	00c95913          	srli	s2,s2,0xc
ffffffffc0202350:	1ff97913          	andi	s2,s2,511
ffffffffc0202354:	96aa                	add	a3,a3,a0
ffffffffc0202356:	00391513          	slli	a0,s2,0x3
ffffffffc020235a:	9536                	add	a0,a0,a3
}
ffffffffc020235c:	70e2                	ld	ra,56(sp)
ffffffffc020235e:	7442                	ld	s0,48(sp)
ffffffffc0202360:	74a2                	ld	s1,40(sp)
ffffffffc0202362:	7902                	ld	s2,32(sp)
ffffffffc0202364:	69e2                	ld	s3,24(sp)
ffffffffc0202366:	6a42                	ld	s4,16(sp)
ffffffffc0202368:	6aa2                	ld	s5,8(sp)
ffffffffc020236a:	6b02                	ld	s6,0(sp)
ffffffffc020236c:	6121                	addi	sp,sp,64
ffffffffc020236e:	8082                	ret
            return NULL;
ffffffffc0202370:	4501                	li	a0,0
ffffffffc0202372:	b7ed                	j	ffffffffc020235c <get_pte+0x178>
        intr_disable();
ffffffffc0202374:	e40fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202378:	000cd797          	auipc	a5,0xcd
ffffffffc020237c:	1187b783          	ld	a5,280(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc0202380:	6f9c                	ld	a5,24(a5)
ffffffffc0202382:	4505                	li	a0,1
ffffffffc0202384:	9782                	jalr	a5
ffffffffc0202386:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202388:	e26fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020238c:	b56d                	j	ffffffffc0202236 <get_pte+0x52>
        intr_disable();
ffffffffc020238e:	e26fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202392:	000cd797          	auipc	a5,0xcd
ffffffffc0202396:	0fe7b783          	ld	a5,254(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc020239a:	6f9c                	ld	a5,24(a5)
ffffffffc020239c:	4505                	li	a0,1
ffffffffc020239e:	9782                	jalr	a5
ffffffffc02023a0:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02023a2:	e0cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02023a6:	b781                	j	ffffffffc02022e6 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02023a8:	00004617          	auipc	a2,0x4
ffffffffc02023ac:	cd860613          	addi	a2,a2,-808 # ffffffffc0206080 <commands+0x5c8>
ffffffffc02023b0:	0fa00593          	li	a1,250
ffffffffc02023b4:	00004517          	auipc	a0,0x4
ffffffffc02023b8:	47c50513          	addi	a0,a0,1148 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02023bc:	8d2fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02023c0:	00004617          	auipc	a2,0x4
ffffffffc02023c4:	cc060613          	addi	a2,a2,-832 # ffffffffc0206080 <commands+0x5c8>
ffffffffc02023c8:	0ed00593          	li	a1,237
ffffffffc02023cc:	00004517          	auipc	a0,0x4
ffffffffc02023d0:	46450513          	addi	a0,a0,1124 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02023d4:	8bafe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02023d8:	86aa                	mv	a3,a0
ffffffffc02023da:	00004617          	auipc	a2,0x4
ffffffffc02023de:	ca660613          	addi	a2,a2,-858 # ffffffffc0206080 <commands+0x5c8>
ffffffffc02023e2:	0e900593          	li	a1,233
ffffffffc02023e6:	00004517          	auipc	a0,0x4
ffffffffc02023ea:	44a50513          	addi	a0,a0,1098 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02023ee:	8a0fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02023f2:	86aa                	mv	a3,a0
ffffffffc02023f4:	00004617          	auipc	a2,0x4
ffffffffc02023f8:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206080 <commands+0x5c8>
ffffffffc02023fc:	0f700593          	li	a1,247
ffffffffc0202400:	00004517          	auipc	a0,0x4
ffffffffc0202404:	43050513          	addi	a0,a0,1072 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0202408:	886fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020240c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020240c:	1141                	addi	sp,sp,-16
ffffffffc020240e:	e022                	sd	s0,0(sp)
ffffffffc0202410:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202412:	4601                	li	a2,0
{
ffffffffc0202414:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202416:	dcfff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
    if (ptep_store != NULL)
ffffffffc020241a:	c011                	beqz	s0,ffffffffc020241e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020241c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020241e:	c511                	beqz	a0,ffffffffc020242a <get_page+0x1e>
ffffffffc0202420:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202422:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202424:	0017f713          	andi	a4,a5,1
ffffffffc0202428:	e709                	bnez	a4,ffffffffc0202432 <get_page+0x26>
}
ffffffffc020242a:	60a2                	ld	ra,8(sp)
ffffffffc020242c:	6402                	ld	s0,0(sp)
ffffffffc020242e:	0141                	addi	sp,sp,16
ffffffffc0202430:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202432:	078a                	slli	a5,a5,0x2
ffffffffc0202434:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202436:	000cd717          	auipc	a4,0xcd
ffffffffc020243a:	04a73703          	ld	a4,74(a4) # ffffffffc02cf480 <npage>
ffffffffc020243e:	00e7ff63          	bgeu	a5,a4,ffffffffc020245c <get_page+0x50>
ffffffffc0202442:	60a2                	ld	ra,8(sp)
ffffffffc0202444:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202446:	fff80537          	lui	a0,0xfff80
ffffffffc020244a:	97aa                	add	a5,a5,a0
ffffffffc020244c:	079a                	slli	a5,a5,0x6
ffffffffc020244e:	000cd517          	auipc	a0,0xcd
ffffffffc0202452:	03a53503          	ld	a0,58(a0) # ffffffffc02cf488 <pages>
ffffffffc0202456:	953e                	add	a0,a0,a5
ffffffffc0202458:	0141                	addi	sp,sp,16
ffffffffc020245a:	8082                	ret
ffffffffc020245c:	c99ff0ef          	jal	ra,ffffffffc02020f4 <pa2page.part.0>

ffffffffc0202460 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202460:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202462:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202466:	f486                	sd	ra,104(sp)
ffffffffc0202468:	f0a2                	sd	s0,96(sp)
ffffffffc020246a:	eca6                	sd	s1,88(sp)
ffffffffc020246c:	e8ca                	sd	s2,80(sp)
ffffffffc020246e:	e4ce                	sd	s3,72(sp)
ffffffffc0202470:	e0d2                	sd	s4,64(sp)
ffffffffc0202472:	fc56                	sd	s5,56(sp)
ffffffffc0202474:	f85a                	sd	s6,48(sp)
ffffffffc0202476:	f45e                	sd	s7,40(sp)
ffffffffc0202478:	f062                	sd	s8,32(sp)
ffffffffc020247a:	ec66                	sd	s9,24(sp)
ffffffffc020247c:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020247e:	17d2                	slli	a5,a5,0x34
ffffffffc0202480:	e3ed                	bnez	a5,ffffffffc0202562 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202482:	002007b7          	lui	a5,0x200
ffffffffc0202486:	842e                	mv	s0,a1
ffffffffc0202488:	0ef5ed63          	bltu	a1,a5,ffffffffc0202582 <unmap_range+0x122>
ffffffffc020248c:	8932                	mv	s2,a2
ffffffffc020248e:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202582 <unmap_range+0x122>
ffffffffc0202492:	4785                	li	a5,1
ffffffffc0202494:	07fe                	slli	a5,a5,0x1f
ffffffffc0202496:	0ec7e663          	bltu	a5,a2,ffffffffc0202582 <unmap_range+0x122>
ffffffffc020249a:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020249c:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020249e:	000cdc97          	auipc	s9,0xcd
ffffffffc02024a2:	fe2c8c93          	addi	s9,s9,-30 # ffffffffc02cf480 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02024a6:	000cdc17          	auipc	s8,0xcd
ffffffffc02024aa:	fe2c0c13          	addi	s8,s8,-30 # ffffffffc02cf488 <pages>
ffffffffc02024ae:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02024b2:	000cdd17          	auipc	s10,0xcd
ffffffffc02024b6:	fded0d13          	addi	s10,s10,-34 # ffffffffc02cf490 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02024ba:	00200b37          	lui	s6,0x200
ffffffffc02024be:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02024c2:	4601                	li	a2,0
ffffffffc02024c4:	85a2                	mv	a1,s0
ffffffffc02024c6:	854e                	mv	a0,s3
ffffffffc02024c8:	d1dff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc02024cc:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02024ce:	cd29                	beqz	a0,ffffffffc0202528 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02024d0:	611c                	ld	a5,0(a0)
ffffffffc02024d2:	e395                	bnez	a5,ffffffffc02024f6 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02024d4:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02024d6:	ff2466e3          	bltu	s0,s2,ffffffffc02024c2 <unmap_range+0x62>
}
ffffffffc02024da:	70a6                	ld	ra,104(sp)
ffffffffc02024dc:	7406                	ld	s0,96(sp)
ffffffffc02024de:	64e6                	ld	s1,88(sp)
ffffffffc02024e0:	6946                	ld	s2,80(sp)
ffffffffc02024e2:	69a6                	ld	s3,72(sp)
ffffffffc02024e4:	6a06                	ld	s4,64(sp)
ffffffffc02024e6:	7ae2                	ld	s5,56(sp)
ffffffffc02024e8:	7b42                	ld	s6,48(sp)
ffffffffc02024ea:	7ba2                	ld	s7,40(sp)
ffffffffc02024ec:	7c02                	ld	s8,32(sp)
ffffffffc02024ee:	6ce2                	ld	s9,24(sp)
ffffffffc02024f0:	6d42                	ld	s10,16(sp)
ffffffffc02024f2:	6165                	addi	sp,sp,112
ffffffffc02024f4:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02024f6:	0017f713          	andi	a4,a5,1
ffffffffc02024fa:	df69                	beqz	a4,ffffffffc02024d4 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc02024fc:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202500:	078a                	slli	a5,a5,0x2
ffffffffc0202502:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202504:	08e7ff63          	bgeu	a5,a4,ffffffffc02025a2 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202508:	000c3503          	ld	a0,0(s8)
ffffffffc020250c:	97de                	add	a5,a5,s7
ffffffffc020250e:	079a                	slli	a5,a5,0x6
ffffffffc0202510:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202512:	411c                	lw	a5,0(a0)
ffffffffc0202514:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202518:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020251a:	cf11                	beqz	a4,ffffffffc0202536 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020251c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202520:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202524:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202526:	bf45                	j	ffffffffc02024d6 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202528:	945a                	add	s0,s0,s6
ffffffffc020252a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020252e:	d455                	beqz	s0,ffffffffc02024da <unmap_range+0x7a>
ffffffffc0202530:	f92469e3          	bltu	s0,s2,ffffffffc02024c2 <unmap_range+0x62>
ffffffffc0202534:	b75d                	j	ffffffffc02024da <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202536:	100027f3          	csrr	a5,sstatus
ffffffffc020253a:	8b89                	andi	a5,a5,2
ffffffffc020253c:	e799                	bnez	a5,ffffffffc020254a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020253e:	000d3783          	ld	a5,0(s10)
ffffffffc0202542:	4585                	li	a1,1
ffffffffc0202544:	739c                	ld	a5,32(a5)
ffffffffc0202546:	9782                	jalr	a5
    if (flag)
ffffffffc0202548:	bfd1                	j	ffffffffc020251c <unmap_range+0xbc>
ffffffffc020254a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020254c:	c68fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202550:	000d3783          	ld	a5,0(s10)
ffffffffc0202554:	6522                	ld	a0,8(sp)
ffffffffc0202556:	4585                	li	a1,1
ffffffffc0202558:	739c                	ld	a5,32(a5)
ffffffffc020255a:	9782                	jalr	a5
        intr_enable();
ffffffffc020255c:	c52fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202560:	bf75                	j	ffffffffc020251c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202562:	00004697          	auipc	a3,0x4
ffffffffc0202566:	2de68693          	addi	a3,a3,734 # ffffffffc0206840 <default_pmm_manager+0x108>
ffffffffc020256a:	00004617          	auipc	a2,0x4
ffffffffc020256e:	e1e60613          	addi	a2,a2,-482 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0202572:	12000593          	li	a1,288
ffffffffc0202576:	00004517          	auipc	a0,0x4
ffffffffc020257a:	2ba50513          	addi	a0,a0,698 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc020257e:	f11fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202582:	00004697          	auipc	a3,0x4
ffffffffc0202586:	2ee68693          	addi	a3,a3,750 # ffffffffc0206870 <default_pmm_manager+0x138>
ffffffffc020258a:	00004617          	auipc	a2,0x4
ffffffffc020258e:	dfe60613          	addi	a2,a2,-514 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0202592:	12100593          	li	a1,289
ffffffffc0202596:	00004517          	auipc	a0,0x4
ffffffffc020259a:	29a50513          	addi	a0,a0,666 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc020259e:	ef1fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02025a2:	b53ff0ef          	jal	ra,ffffffffc02020f4 <pa2page.part.0>

ffffffffc02025a6 <exit_range>:
{
ffffffffc02025a6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025a8:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02025ac:	fc86                	sd	ra,120(sp)
ffffffffc02025ae:	f8a2                	sd	s0,112(sp)
ffffffffc02025b0:	f4a6                	sd	s1,104(sp)
ffffffffc02025b2:	f0ca                	sd	s2,96(sp)
ffffffffc02025b4:	ecce                	sd	s3,88(sp)
ffffffffc02025b6:	e8d2                	sd	s4,80(sp)
ffffffffc02025b8:	e4d6                	sd	s5,72(sp)
ffffffffc02025ba:	e0da                	sd	s6,64(sp)
ffffffffc02025bc:	fc5e                	sd	s7,56(sp)
ffffffffc02025be:	f862                	sd	s8,48(sp)
ffffffffc02025c0:	f466                	sd	s9,40(sp)
ffffffffc02025c2:	f06a                	sd	s10,32(sp)
ffffffffc02025c4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025c6:	17d2                	slli	a5,a5,0x34
ffffffffc02025c8:	20079a63          	bnez	a5,ffffffffc02027dc <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02025cc:	002007b7          	lui	a5,0x200
ffffffffc02025d0:	24f5e463          	bltu	a1,a5,ffffffffc0202818 <exit_range+0x272>
ffffffffc02025d4:	8ab2                	mv	s5,a2
ffffffffc02025d6:	24c5f163          	bgeu	a1,a2,ffffffffc0202818 <exit_range+0x272>
ffffffffc02025da:	4785                	li	a5,1
ffffffffc02025dc:	07fe                	slli	a5,a5,0x1f
ffffffffc02025de:	22c7ed63          	bltu	a5,a2,ffffffffc0202818 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02025e2:	c00009b7          	lui	s3,0xc0000
ffffffffc02025e6:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02025ea:	ffe00937          	lui	s2,0xffe00
ffffffffc02025ee:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02025f2:	5cfd                	li	s9,-1
ffffffffc02025f4:	8c2a                	mv	s8,a0
ffffffffc02025f6:	0125f933          	and	s2,a1,s2
ffffffffc02025fa:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02025fc:	000cdd17          	auipc	s10,0xcd
ffffffffc0202600:	e84d0d13          	addi	s10,s10,-380 # ffffffffc02cf480 <npage>
    return KADDR(page2pa(page));
ffffffffc0202604:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202608:	000cd717          	auipc	a4,0xcd
ffffffffc020260c:	e8070713          	addi	a4,a4,-384 # ffffffffc02cf488 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202610:	000cdd97          	auipc	s11,0xcd
ffffffffc0202614:	e80d8d93          	addi	s11,s11,-384 # ffffffffc02cf490 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202618:	c0000437          	lui	s0,0xc0000
ffffffffc020261c:	944e                	add	s0,s0,s3
ffffffffc020261e:	8079                	srli	s0,s0,0x1e
ffffffffc0202620:	1ff47413          	andi	s0,s0,511
ffffffffc0202624:	040e                	slli	s0,s0,0x3
ffffffffc0202626:	9462                	add	s0,s0,s8
ffffffffc0202628:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_cowtest_out_size+0xffffffffbfff4ac8>
        if (pde1 & PTE_V)
ffffffffc020262c:	001a7793          	andi	a5,s4,1
ffffffffc0202630:	eb99                	bnez	a5,ffffffffc0202646 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202632:	12098463          	beqz	s3,ffffffffc020275a <exit_range+0x1b4>
ffffffffc0202636:	400007b7          	lui	a5,0x40000
ffffffffc020263a:	97ce                	add	a5,a5,s3
ffffffffc020263c:	894e                	mv	s2,s3
ffffffffc020263e:	1159fe63          	bgeu	s3,s5,ffffffffc020275a <exit_range+0x1b4>
ffffffffc0202642:	89be                	mv	s3,a5
ffffffffc0202644:	bfd1                	j	ffffffffc0202618 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202646:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020264a:	0a0a                	slli	s4,s4,0x2
ffffffffc020264c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202650:	1cfa7263          	bgeu	s4,a5,ffffffffc0202814 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202654:	fff80637          	lui	a2,0xfff80
ffffffffc0202658:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020265a:	000806b7          	lui	a3,0x80
ffffffffc020265e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202660:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202664:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202666:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202668:	18f5fa63          	bgeu	a1,a5,ffffffffc02027fc <exit_range+0x256>
ffffffffc020266c:	000cd817          	auipc	a6,0xcd
ffffffffc0202670:	e2c80813          	addi	a6,a6,-468 # ffffffffc02cf498 <va_pa_offset>
ffffffffc0202674:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202678:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020267a:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020267e:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202680:	00080337          	lui	t1,0x80
ffffffffc0202684:	6885                	lui	a7,0x1
ffffffffc0202686:	a819                	j	ffffffffc020269c <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202688:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020268a:	002007b7          	lui	a5,0x200
ffffffffc020268e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202690:	08090c63          	beqz	s2,ffffffffc0202728 <exit_range+0x182>
ffffffffc0202694:	09397a63          	bgeu	s2,s3,ffffffffc0202728 <exit_range+0x182>
ffffffffc0202698:	0f597063          	bgeu	s2,s5,ffffffffc0202778 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020269c:	01595493          	srli	s1,s2,0x15
ffffffffc02026a0:	1ff4f493          	andi	s1,s1,511
ffffffffc02026a4:	048e                	slli	s1,s1,0x3
ffffffffc02026a6:	94da                	add	s1,s1,s6
ffffffffc02026a8:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02026aa:	0017f693          	andi	a3,a5,1
ffffffffc02026ae:	dee9                	beqz	a3,ffffffffc0202688 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02026b0:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026b4:	078a                	slli	a5,a5,0x2
ffffffffc02026b6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026b8:	14b7fe63          	bgeu	a5,a1,ffffffffc0202814 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02026bc:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02026be:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02026c2:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02026c6:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02026ca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02026cc:	12bef863          	bgeu	t4,a1,ffffffffc02027fc <exit_range+0x256>
ffffffffc02026d0:	00083783          	ld	a5,0(a6)
ffffffffc02026d4:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02026d6:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02026da:	629c                	ld	a5,0(a3)
ffffffffc02026dc:	8b85                	andi	a5,a5,1
ffffffffc02026de:	f7d5                	bnez	a5,ffffffffc020268a <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02026e0:	06a1                	addi	a3,a3,8
ffffffffc02026e2:	fed59ce3          	bne	a1,a3,ffffffffc02026da <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02026e6:	631c                	ld	a5,0(a4)
ffffffffc02026e8:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026ea:	100027f3          	csrr	a5,sstatus
ffffffffc02026ee:	8b89                	andi	a5,a5,2
ffffffffc02026f0:	e7d9                	bnez	a5,ffffffffc020277e <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02026f2:	000db783          	ld	a5,0(s11)
ffffffffc02026f6:	4585                	li	a1,1
ffffffffc02026f8:	e032                	sd	a2,0(sp)
ffffffffc02026fa:	739c                	ld	a5,32(a5)
ffffffffc02026fc:	9782                	jalr	a5
    if (flag)
ffffffffc02026fe:	6602                	ld	a2,0(sp)
ffffffffc0202700:	000cd817          	auipc	a6,0xcd
ffffffffc0202704:	d9880813          	addi	a6,a6,-616 # ffffffffc02cf498 <va_pa_offset>
ffffffffc0202708:	fff80e37          	lui	t3,0xfff80
ffffffffc020270c:	00080337          	lui	t1,0x80
ffffffffc0202710:	6885                	lui	a7,0x1
ffffffffc0202712:	000cd717          	auipc	a4,0xcd
ffffffffc0202716:	d7670713          	addi	a4,a4,-650 # ffffffffc02cf488 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020271a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020271e:	002007b7          	lui	a5,0x200
ffffffffc0202722:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202724:	f60918e3          	bnez	s2,ffffffffc0202694 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202728:	f00b85e3          	beqz	s7,ffffffffc0202632 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020272c:	000d3783          	ld	a5,0(s10)
ffffffffc0202730:	0efa7263          	bgeu	s4,a5,ffffffffc0202814 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202734:	6308                	ld	a0,0(a4)
ffffffffc0202736:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202738:	100027f3          	csrr	a5,sstatus
ffffffffc020273c:	8b89                	andi	a5,a5,2
ffffffffc020273e:	efad                	bnez	a5,ffffffffc02027b8 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202740:	000db783          	ld	a5,0(s11)
ffffffffc0202744:	4585                	li	a1,1
ffffffffc0202746:	739c                	ld	a5,32(a5)
ffffffffc0202748:	9782                	jalr	a5
ffffffffc020274a:	000cd717          	auipc	a4,0xcd
ffffffffc020274e:	d3e70713          	addi	a4,a4,-706 # ffffffffc02cf488 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202752:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202756:	ee0990e3          	bnez	s3,ffffffffc0202636 <exit_range+0x90>
}
ffffffffc020275a:	70e6                	ld	ra,120(sp)
ffffffffc020275c:	7446                	ld	s0,112(sp)
ffffffffc020275e:	74a6                	ld	s1,104(sp)
ffffffffc0202760:	7906                	ld	s2,96(sp)
ffffffffc0202762:	69e6                	ld	s3,88(sp)
ffffffffc0202764:	6a46                	ld	s4,80(sp)
ffffffffc0202766:	6aa6                	ld	s5,72(sp)
ffffffffc0202768:	6b06                	ld	s6,64(sp)
ffffffffc020276a:	7be2                	ld	s7,56(sp)
ffffffffc020276c:	7c42                	ld	s8,48(sp)
ffffffffc020276e:	7ca2                	ld	s9,40(sp)
ffffffffc0202770:	7d02                	ld	s10,32(sp)
ffffffffc0202772:	6de2                	ld	s11,24(sp)
ffffffffc0202774:	6109                	addi	sp,sp,128
ffffffffc0202776:	8082                	ret
            if (free_pd0)
ffffffffc0202778:	ea0b8fe3          	beqz	s7,ffffffffc0202636 <exit_range+0x90>
ffffffffc020277c:	bf45                	j	ffffffffc020272c <exit_range+0x186>
ffffffffc020277e:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202780:	e42a                	sd	a0,8(sp)
ffffffffc0202782:	a32fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202786:	000db783          	ld	a5,0(s11)
ffffffffc020278a:	6522                	ld	a0,8(sp)
ffffffffc020278c:	4585                	li	a1,1
ffffffffc020278e:	739c                	ld	a5,32(a5)
ffffffffc0202790:	9782                	jalr	a5
        intr_enable();
ffffffffc0202792:	a1cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202796:	6602                	ld	a2,0(sp)
ffffffffc0202798:	000cd717          	auipc	a4,0xcd
ffffffffc020279c:	cf070713          	addi	a4,a4,-784 # ffffffffc02cf488 <pages>
ffffffffc02027a0:	6885                	lui	a7,0x1
ffffffffc02027a2:	00080337          	lui	t1,0x80
ffffffffc02027a6:	fff80e37          	lui	t3,0xfff80
ffffffffc02027aa:	000cd817          	auipc	a6,0xcd
ffffffffc02027ae:	cee80813          	addi	a6,a6,-786 # ffffffffc02cf498 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02027b2:	0004b023          	sd	zero,0(s1)
ffffffffc02027b6:	b7a5                	j	ffffffffc020271e <exit_range+0x178>
ffffffffc02027b8:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02027ba:	9fafe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027be:	000db783          	ld	a5,0(s11)
ffffffffc02027c2:	6502                	ld	a0,0(sp)
ffffffffc02027c4:	4585                	li	a1,1
ffffffffc02027c6:	739c                	ld	a5,32(a5)
ffffffffc02027c8:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ca:	9e4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02027ce:	000cd717          	auipc	a4,0xcd
ffffffffc02027d2:	cba70713          	addi	a4,a4,-838 # ffffffffc02cf488 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02027d6:	00043023          	sd	zero,0(s0)
ffffffffc02027da:	bfb5                	j	ffffffffc0202756 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02027dc:	00004697          	auipc	a3,0x4
ffffffffc02027e0:	06468693          	addi	a3,a3,100 # ffffffffc0206840 <default_pmm_manager+0x108>
ffffffffc02027e4:	00004617          	auipc	a2,0x4
ffffffffc02027e8:	ba460613          	addi	a2,a2,-1116 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02027ec:	13500593          	li	a1,309
ffffffffc02027f0:	00004517          	auipc	a0,0x4
ffffffffc02027f4:	04050513          	addi	a0,a0,64 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02027f8:	c97fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02027fc:	00004617          	auipc	a2,0x4
ffffffffc0202800:	88460613          	addi	a2,a2,-1916 # ffffffffc0206080 <commands+0x5c8>
ffffffffc0202804:	07100593          	li	a1,113
ffffffffc0202808:	00004517          	auipc	a0,0x4
ffffffffc020280c:	86850513          	addi	a0,a0,-1944 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0202810:	c7ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202814:	8e1ff0ef          	jal	ra,ffffffffc02020f4 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202818:	00004697          	auipc	a3,0x4
ffffffffc020281c:	05868693          	addi	a3,a3,88 # ffffffffc0206870 <default_pmm_manager+0x138>
ffffffffc0202820:	00004617          	auipc	a2,0x4
ffffffffc0202824:	b6860613          	addi	a2,a2,-1176 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0202828:	13600593          	li	a1,310
ffffffffc020282c:	00004517          	auipc	a0,0x4
ffffffffc0202830:	00450513          	addi	a0,a0,4 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0202834:	c5bfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202838 <copy_range>:
{
ffffffffc0202838:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020283a:	00d667b3          	or	a5,a2,a3
{
ffffffffc020283e:	ec86                	sd	ra,88(sp)
ffffffffc0202840:	e8a2                	sd	s0,80(sp)
ffffffffc0202842:	e4a6                	sd	s1,72(sp)
ffffffffc0202844:	e0ca                	sd	s2,64(sp)
ffffffffc0202846:	fc4e                	sd	s3,56(sp)
ffffffffc0202848:	f852                	sd	s4,48(sp)
ffffffffc020284a:	f456                	sd	s5,40(sp)
ffffffffc020284c:	f05a                	sd	s6,32(sp)
ffffffffc020284e:	ec5e                	sd	s7,24(sp)
ffffffffc0202850:	e862                	sd	s8,16(sp)
ffffffffc0202852:	e466                	sd	s9,8(sp)
ffffffffc0202854:	e06a                	sd	s10,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202856:	17d2                	slli	a5,a5,0x34
ffffffffc0202858:	10079963          	bnez	a5,ffffffffc020296a <copy_range+0x132>
    assert(USER_ACCESS(start, end));
ffffffffc020285c:	002007b7          	lui	a5,0x200
ffffffffc0202860:	8432                	mv	s0,a2
ffffffffc0202862:	0ef66463          	bltu	a2,a5,ffffffffc020294a <copy_range+0x112>
ffffffffc0202866:	8936                	mv	s2,a3
ffffffffc0202868:	0ed67163          	bgeu	a2,a3,ffffffffc020294a <copy_range+0x112>
ffffffffc020286c:	4785                	li	a5,1
ffffffffc020286e:	07fe                	slli	a5,a5,0x1f
ffffffffc0202870:	0cd7ed63          	bltu	a5,a3,ffffffffc020294a <copy_range+0x112>
ffffffffc0202874:	8aaa                	mv	s5,a0
ffffffffc0202876:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc0202878:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020287a:	000cdc17          	auipc	s8,0xcd
ffffffffc020287e:	c06c0c13          	addi	s8,s8,-1018 # ffffffffc02cf480 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202882:	000cdb97          	auipc	s7,0xcd
ffffffffc0202886:	c06b8b93          	addi	s7,s7,-1018 # ffffffffc02cf488 <pages>
ffffffffc020288a:	fff80b37          	lui	s6,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020288e:	00200d37          	lui	s10,0x200
ffffffffc0202892:	ffe00cb7          	lui	s9,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0202896:	4601                	li	a2,0
ffffffffc0202898:	85a2                	mv	a1,s0
ffffffffc020289a:	854e                	mv	a0,s3
ffffffffc020289c:	949ff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc02028a0:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02028a2:	c93d                	beqz	a0,ffffffffc0202918 <copy_range+0xe0>
        if (*ptep & PTE_V)
ffffffffc02028a4:	611c                	ld	a5,0(a0)
ffffffffc02028a6:	8b85                	andi	a5,a5,1
ffffffffc02028a8:	e39d                	bnez	a5,ffffffffc02028ce <copy_range+0x96>
        start += PGSIZE;
ffffffffc02028aa:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02028ac:	ff2465e3          	bltu	s0,s2,ffffffffc0202896 <copy_range+0x5e>
    return 0;
ffffffffc02028b0:	4501                	li	a0,0
}
ffffffffc02028b2:	60e6                	ld	ra,88(sp)
ffffffffc02028b4:	6446                	ld	s0,80(sp)
ffffffffc02028b6:	64a6                	ld	s1,72(sp)
ffffffffc02028b8:	6906                	ld	s2,64(sp)
ffffffffc02028ba:	79e2                	ld	s3,56(sp)
ffffffffc02028bc:	7a42                	ld	s4,48(sp)
ffffffffc02028be:	7aa2                	ld	s5,40(sp)
ffffffffc02028c0:	7b02                	ld	s6,32(sp)
ffffffffc02028c2:	6be2                	ld	s7,24(sp)
ffffffffc02028c4:	6c42                	ld	s8,16(sp)
ffffffffc02028c6:	6ca2                	ld	s9,8(sp)
ffffffffc02028c8:	6d02                	ld	s10,0(sp)
ffffffffc02028ca:	6125                	addi	sp,sp,96
ffffffffc02028cc:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02028ce:	4605                	li	a2,1
ffffffffc02028d0:	85a2                	mv	a1,s0
ffffffffc02028d2:	8556                	mv	a0,s5
ffffffffc02028d4:	911ff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc02028d8:	c939                	beqz	a0,ffffffffc020292e <copy_range+0xf6>
            struct Page *page = pte2page(*ptep);
ffffffffc02028da:	6098                	ld	a4,0(s1)
    if (!(pte & PTE_V))
ffffffffc02028dc:	00177793          	andi	a5,a4,1
ffffffffc02028e0:	cba9                	beqz	a5,ffffffffc0202932 <copy_range+0xfa>
    if (PPN(pa) >= npage)
ffffffffc02028e2:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028e6:	00271793          	slli	a5,a4,0x2
ffffffffc02028ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028ec:	08d7ff63          	bgeu	a5,a3,ffffffffc020298a <copy_range+0x152>
    return &pages[PPN(pa) - nbase];
ffffffffc02028f0:	000bb683          	ld	a3,0(s7)
ffffffffc02028f4:	97da                	add	a5,a5,s6
ffffffffc02028f6:	079a                	slli	a5,a5,0x6
ffffffffc02028f8:	97b6                	add	a5,a5,a3
    page->ref += 1;
ffffffffc02028fa:	4394                	lw	a3,0(a5)
            if (*ptep & PTE_W) {
ffffffffc02028fc:	00477613          	andi	a2,a4,4
ffffffffc0202900:	2685                	addiw	a3,a3,1
ffffffffc0202902:	c215                	beqz	a2,ffffffffc0202926 <copy_range+0xee>
                pte_t child_pte = ((*ptep) & ~((pte_t)0x3FF)) |  // 保留PPN
ffffffffc0202904:	dfb77713          	andi	a4,a4,-517
ffffffffc0202908:	c394                	sw	a3,0(a5)
ffffffffc020290a:	20076713          	ori	a4,a4,512
                *nptep = child_pte;
ffffffffc020290e:	e118                	sd	a4,0(a0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202910:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202914:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202916:	bf59                	j	ffffffffc02028ac <copy_range+0x74>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202918:	946a                	add	s0,s0,s10
ffffffffc020291a:	01947433          	and	s0,s0,s9
    } while (start != 0 && start < end);
ffffffffc020291e:	d849                	beqz	s0,ffffffffc02028b0 <copy_range+0x78>
ffffffffc0202920:	f7246be3          	bltu	s0,s2,ffffffffc0202896 <copy_range+0x5e>
ffffffffc0202924:	b771                	j	ffffffffc02028b0 <copy_range+0x78>
ffffffffc0202926:	c394                	sw	a3,0(a5)
                *nptep = *ptep;
ffffffffc0202928:	e118                	sd	a4,0(a0)
        start += PGSIZE;
ffffffffc020292a:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020292c:	b741                	j	ffffffffc02028ac <copy_range+0x74>
                return -E_NO_MEM;
ffffffffc020292e:	5571                	li	a0,-4
ffffffffc0202930:	b749                	j	ffffffffc02028b2 <copy_range+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc0202932:	00004617          	auipc	a2,0x4
ffffffffc0202936:	ed660613          	addi	a2,a2,-298 # ffffffffc0206808 <default_pmm_manager+0xd0>
ffffffffc020293a:	07f00593          	li	a1,127
ffffffffc020293e:	00003517          	auipc	a0,0x3
ffffffffc0202942:	73250513          	addi	a0,a0,1842 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0202946:	b49fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020294a:	00004697          	auipc	a3,0x4
ffffffffc020294e:	f2668693          	addi	a3,a3,-218 # ffffffffc0206870 <default_pmm_manager+0x138>
ffffffffc0202952:	00004617          	auipc	a2,0x4
ffffffffc0202956:	a3660613          	addi	a2,a2,-1482 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020295a:	17c00593          	li	a1,380
ffffffffc020295e:	00004517          	auipc	a0,0x4
ffffffffc0202962:	ed250513          	addi	a0,a0,-302 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0202966:	b29fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020296a:	00004697          	auipc	a3,0x4
ffffffffc020296e:	ed668693          	addi	a3,a3,-298 # ffffffffc0206840 <default_pmm_manager+0x108>
ffffffffc0202972:	00004617          	auipc	a2,0x4
ffffffffc0202976:	a1660613          	addi	a2,a2,-1514 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020297a:	17b00593          	li	a1,379
ffffffffc020297e:	00004517          	auipc	a0,0x4
ffffffffc0202982:	eb250513          	addi	a0,a0,-334 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0202986:	b09fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020298a:	00003617          	auipc	a2,0x3
ffffffffc020298e:	6c660613          	addi	a2,a2,1734 # ffffffffc0206050 <commands+0x598>
ffffffffc0202992:	06900593          	li	a1,105
ffffffffc0202996:	00003517          	auipc	a0,0x3
ffffffffc020299a:	6da50513          	addi	a0,a0,1754 # ffffffffc0206070 <commands+0x5b8>
ffffffffc020299e:	af1fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02029a2 <page_remove>:
{
ffffffffc02029a2:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02029a4:	4601                	li	a2,0
{
ffffffffc02029a6:	ec26                	sd	s1,24(sp)
ffffffffc02029a8:	f406                	sd	ra,40(sp)
ffffffffc02029aa:	f022                	sd	s0,32(sp)
ffffffffc02029ac:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02029ae:	837ff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
    if (ptep != NULL)
ffffffffc02029b2:	c511                	beqz	a0,ffffffffc02029be <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02029b4:	611c                	ld	a5,0(a0)
ffffffffc02029b6:	842a                	mv	s0,a0
ffffffffc02029b8:	0017f713          	andi	a4,a5,1
ffffffffc02029bc:	e711                	bnez	a4,ffffffffc02029c8 <page_remove+0x26>
}
ffffffffc02029be:	70a2                	ld	ra,40(sp)
ffffffffc02029c0:	7402                	ld	s0,32(sp)
ffffffffc02029c2:	64e2                	ld	s1,24(sp)
ffffffffc02029c4:	6145                	addi	sp,sp,48
ffffffffc02029c6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02029c8:	078a                	slli	a5,a5,0x2
ffffffffc02029ca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029cc:	000cd717          	auipc	a4,0xcd
ffffffffc02029d0:	ab473703          	ld	a4,-1356(a4) # ffffffffc02cf480 <npage>
ffffffffc02029d4:	06e7f363          	bgeu	a5,a4,ffffffffc0202a3a <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02029d8:	fff80537          	lui	a0,0xfff80
ffffffffc02029dc:	97aa                	add	a5,a5,a0
ffffffffc02029de:	079a                	slli	a5,a5,0x6
ffffffffc02029e0:	000cd517          	auipc	a0,0xcd
ffffffffc02029e4:	aa853503          	ld	a0,-1368(a0) # ffffffffc02cf488 <pages>
ffffffffc02029e8:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02029ea:	411c                	lw	a5,0(a0)
ffffffffc02029ec:	fff7871b          	addiw	a4,a5,-1
ffffffffc02029f0:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02029f2:	cb11                	beqz	a4,ffffffffc0202a06 <page_remove+0x64>
        *ptep = 0;
ffffffffc02029f4:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02029f8:	12048073          	sfence.vma	s1
}
ffffffffc02029fc:	70a2                	ld	ra,40(sp)
ffffffffc02029fe:	7402                	ld	s0,32(sp)
ffffffffc0202a00:	64e2                	ld	s1,24(sp)
ffffffffc0202a02:	6145                	addi	sp,sp,48
ffffffffc0202a04:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202a06:	100027f3          	csrr	a5,sstatus
ffffffffc0202a0a:	8b89                	andi	a5,a5,2
ffffffffc0202a0c:	eb89                	bnez	a5,ffffffffc0202a1e <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202a0e:	000cd797          	auipc	a5,0xcd
ffffffffc0202a12:	a827b783          	ld	a5,-1406(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc0202a16:	739c                	ld	a5,32(a5)
ffffffffc0202a18:	4585                	li	a1,1
ffffffffc0202a1a:	9782                	jalr	a5
    if (flag)
ffffffffc0202a1c:	bfe1                	j	ffffffffc02029f4 <page_remove+0x52>
        intr_disable();
ffffffffc0202a1e:	e42a                	sd	a0,8(sp)
ffffffffc0202a20:	f95fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202a24:	000cd797          	auipc	a5,0xcd
ffffffffc0202a28:	a6c7b783          	ld	a5,-1428(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc0202a2c:	739c                	ld	a5,32(a5)
ffffffffc0202a2e:	6522                	ld	a0,8(sp)
ffffffffc0202a30:	4585                	li	a1,1
ffffffffc0202a32:	9782                	jalr	a5
        intr_enable();
ffffffffc0202a34:	f7bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202a38:	bf75                	j	ffffffffc02029f4 <page_remove+0x52>
ffffffffc0202a3a:	ebaff0ef          	jal	ra,ffffffffc02020f4 <pa2page.part.0>

ffffffffc0202a3e <page_insert>:
{
ffffffffc0202a3e:	7139                	addi	sp,sp,-64
ffffffffc0202a40:	e852                	sd	s4,16(sp)
ffffffffc0202a42:	8a32                	mv	s4,a2
ffffffffc0202a44:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202a46:	4605                	li	a2,1
{
ffffffffc0202a48:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202a4a:	85d2                	mv	a1,s4
{
ffffffffc0202a4c:	f426                	sd	s1,40(sp)
ffffffffc0202a4e:	fc06                	sd	ra,56(sp)
ffffffffc0202a50:	f04a                	sd	s2,32(sp)
ffffffffc0202a52:	ec4e                	sd	s3,24(sp)
ffffffffc0202a54:	e456                	sd	s5,8(sp)
ffffffffc0202a56:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202a58:	f8cff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
    if (ptep == NULL)
ffffffffc0202a5c:	c961                	beqz	a0,ffffffffc0202b2c <page_insert+0xee>
    page->ref += 1;
ffffffffc0202a5e:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202a60:	611c                	ld	a5,0(a0)
ffffffffc0202a62:	89aa                	mv	s3,a0
ffffffffc0202a64:	0016871b          	addiw	a4,a3,1
ffffffffc0202a68:	c018                	sw	a4,0(s0)
ffffffffc0202a6a:	0017f713          	andi	a4,a5,1
ffffffffc0202a6e:	ef05                	bnez	a4,ffffffffc0202aa6 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202a70:	000cd717          	auipc	a4,0xcd
ffffffffc0202a74:	a1873703          	ld	a4,-1512(a4) # ffffffffc02cf488 <pages>
ffffffffc0202a78:	8c19                	sub	s0,s0,a4
ffffffffc0202a7a:	000807b7          	lui	a5,0x80
ffffffffc0202a7e:	8419                	srai	s0,s0,0x6
ffffffffc0202a80:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202a82:	042a                	slli	s0,s0,0xa
ffffffffc0202a84:	8cc1                	or	s1,s1,s0
ffffffffc0202a86:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202a8a:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_cowtest_out_size+0xffffffffbfff4ac8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202a8e:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202a92:	4501                	li	a0,0
}
ffffffffc0202a94:	70e2                	ld	ra,56(sp)
ffffffffc0202a96:	7442                	ld	s0,48(sp)
ffffffffc0202a98:	74a2                	ld	s1,40(sp)
ffffffffc0202a9a:	7902                	ld	s2,32(sp)
ffffffffc0202a9c:	69e2                	ld	s3,24(sp)
ffffffffc0202a9e:	6a42                	ld	s4,16(sp)
ffffffffc0202aa0:	6aa2                	ld	s5,8(sp)
ffffffffc0202aa2:	6121                	addi	sp,sp,64
ffffffffc0202aa4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202aa6:	078a                	slli	a5,a5,0x2
ffffffffc0202aa8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aaa:	000cd717          	auipc	a4,0xcd
ffffffffc0202aae:	9d673703          	ld	a4,-1578(a4) # ffffffffc02cf480 <npage>
ffffffffc0202ab2:	06e7ff63          	bgeu	a5,a4,ffffffffc0202b30 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ab6:	000cda97          	auipc	s5,0xcd
ffffffffc0202aba:	9d2a8a93          	addi	s5,s5,-1582 # ffffffffc02cf488 <pages>
ffffffffc0202abe:	000ab703          	ld	a4,0(s5)
ffffffffc0202ac2:	fff80937          	lui	s2,0xfff80
ffffffffc0202ac6:	993e                	add	s2,s2,a5
ffffffffc0202ac8:	091a                	slli	s2,s2,0x6
ffffffffc0202aca:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202acc:	01240c63          	beq	s0,s2,ffffffffc0202ae4 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202ad0:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcb0b44>
ffffffffc0202ad4:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202ad8:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202adc:	c691                	beqz	a3,ffffffffc0202ae8 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202ade:	120a0073          	sfence.vma	s4
}
ffffffffc0202ae2:	bf59                	j	ffffffffc0202a78 <page_insert+0x3a>
ffffffffc0202ae4:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202ae6:	bf49                	j	ffffffffc0202a78 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202ae8:	100027f3          	csrr	a5,sstatus
ffffffffc0202aec:	8b89                	andi	a5,a5,2
ffffffffc0202aee:	ef91                	bnez	a5,ffffffffc0202b0a <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202af0:	000cd797          	auipc	a5,0xcd
ffffffffc0202af4:	9a07b783          	ld	a5,-1632(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc0202af8:	739c                	ld	a5,32(a5)
ffffffffc0202afa:	4585                	li	a1,1
ffffffffc0202afc:	854a                	mv	a0,s2
ffffffffc0202afe:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202b00:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202b04:	120a0073          	sfence.vma	s4
ffffffffc0202b08:	bf85                	j	ffffffffc0202a78 <page_insert+0x3a>
        intr_disable();
ffffffffc0202b0a:	eabfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202b0e:	000cd797          	auipc	a5,0xcd
ffffffffc0202b12:	9827b783          	ld	a5,-1662(a5) # ffffffffc02cf490 <pmm_manager>
ffffffffc0202b16:	739c                	ld	a5,32(a5)
ffffffffc0202b18:	4585                	li	a1,1
ffffffffc0202b1a:	854a                	mv	a0,s2
ffffffffc0202b1c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b1e:	e91fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202b22:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202b26:	120a0073          	sfence.vma	s4
ffffffffc0202b2a:	b7b9                	j	ffffffffc0202a78 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202b2c:	5571                	li	a0,-4
ffffffffc0202b2e:	b79d                	j	ffffffffc0202a94 <page_insert+0x56>
ffffffffc0202b30:	dc4ff0ef          	jal	ra,ffffffffc02020f4 <pa2page.part.0>

ffffffffc0202b34 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202b34:	00004797          	auipc	a5,0x4
ffffffffc0202b38:	c0478793          	addi	a5,a5,-1020 # ffffffffc0206738 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202b3c:	638c                	ld	a1,0(a5)
{
ffffffffc0202b3e:	7159                	addi	sp,sp,-112
ffffffffc0202b40:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202b42:	00004517          	auipc	a0,0x4
ffffffffc0202b46:	d4650513          	addi	a0,a0,-698 # ffffffffc0206888 <default_pmm_manager+0x150>
    pmm_manager = &default_pmm_manager;
ffffffffc0202b4a:	000cdb17          	auipc	s6,0xcd
ffffffffc0202b4e:	946b0b13          	addi	s6,s6,-1722 # ffffffffc02cf490 <pmm_manager>
{
ffffffffc0202b52:	f486                	sd	ra,104(sp)
ffffffffc0202b54:	e8ca                	sd	s2,80(sp)
ffffffffc0202b56:	e4ce                	sd	s3,72(sp)
ffffffffc0202b58:	f0a2                	sd	s0,96(sp)
ffffffffc0202b5a:	eca6                	sd	s1,88(sp)
ffffffffc0202b5c:	e0d2                	sd	s4,64(sp)
ffffffffc0202b5e:	fc56                	sd	s5,56(sp)
ffffffffc0202b60:	f45e                	sd	s7,40(sp)
ffffffffc0202b62:	f062                	sd	s8,32(sp)
ffffffffc0202b64:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202b66:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202b6a:	e2afd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202b6e:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202b72:	000cd997          	auipc	s3,0xcd
ffffffffc0202b76:	92698993          	addi	s3,s3,-1754 # ffffffffc02cf498 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202b7a:	679c                	ld	a5,8(a5)
ffffffffc0202b7c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202b7e:	57f5                	li	a5,-3
ffffffffc0202b80:	07fa                	slli	a5,a5,0x1e
ffffffffc0202b82:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202b86:	e15fd0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202b8a:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202b8c:	e19fd0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202b90:	200505e3          	beqz	a0,ffffffffc020359a <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202b94:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202b96:	00004517          	auipc	a0,0x4
ffffffffc0202b9a:	d2a50513          	addi	a0,a0,-726 # ffffffffc02068c0 <default_pmm_manager+0x188>
ffffffffc0202b9e:	df6fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202ba2:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202ba6:	fff40693          	addi	a3,s0,-1
ffffffffc0202baa:	864a                	mv	a2,s2
ffffffffc0202bac:	85a6                	mv	a1,s1
ffffffffc0202bae:	00004517          	auipc	a0,0x4
ffffffffc0202bb2:	d2a50513          	addi	a0,a0,-726 # ffffffffc02068d8 <default_pmm_manager+0x1a0>
ffffffffc0202bb6:	ddefd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202bba:	c8000737          	lui	a4,0xc8000
ffffffffc0202bbe:	87a2                	mv	a5,s0
ffffffffc0202bc0:	54876163          	bltu	a4,s0,ffffffffc0203102 <pmm_init+0x5ce>
ffffffffc0202bc4:	757d                	lui	a0,0xfffff
ffffffffc0202bc6:	000ce617          	auipc	a2,0xce
ffffffffc0202bca:	8f560613          	addi	a2,a2,-1803 # ffffffffc02d04bb <end+0xfff>
ffffffffc0202bce:	8e69                	and	a2,a2,a0
ffffffffc0202bd0:	000cd497          	auipc	s1,0xcd
ffffffffc0202bd4:	8b048493          	addi	s1,s1,-1872 # ffffffffc02cf480 <npage>
ffffffffc0202bd8:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202bdc:	000cdb97          	auipc	s7,0xcd
ffffffffc0202be0:	8acb8b93          	addi	s7,s7,-1876 # ffffffffc02cf488 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202be4:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202be6:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202bea:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202bee:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202bf0:	02f50863          	beq	a0,a5,ffffffffc0202c20 <pmm_init+0xec>
ffffffffc0202bf4:	4781                	li	a5,0
ffffffffc0202bf6:	4585                	li	a1,1
ffffffffc0202bf8:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202bfc:	00679513          	slli	a0,a5,0x6
ffffffffc0202c00:	9532                	add	a0,a0,a2
ffffffffc0202c02:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd2fb4c>
ffffffffc0202c06:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202c0a:	6088                	ld	a0,0(s1)
ffffffffc0202c0c:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202c0e:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202c12:	00d50733          	add	a4,a0,a3
ffffffffc0202c16:	fee7e3e3          	bltu	a5,a4,ffffffffc0202bfc <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c1a:	071a                	slli	a4,a4,0x6
ffffffffc0202c1c:	00e606b3          	add	a3,a2,a4
ffffffffc0202c20:	c02007b7          	lui	a5,0xc0200
ffffffffc0202c24:	2ef6ece3          	bltu	a3,a5,ffffffffc020371c <pmm_init+0xbe8>
ffffffffc0202c28:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202c2c:	77fd                	lui	a5,0xfffff
ffffffffc0202c2e:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c30:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202c32:	5086eb63          	bltu	a3,s0,ffffffffc0203148 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202c36:	00004517          	auipc	a0,0x4
ffffffffc0202c3a:	cca50513          	addi	a0,a0,-822 # ffffffffc0206900 <default_pmm_manager+0x1c8>
ffffffffc0202c3e:	d56fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202c42:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202c46:	000cd917          	auipc	s2,0xcd
ffffffffc0202c4a:	83290913          	addi	s2,s2,-1998 # ffffffffc02cf478 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202c4e:	7b9c                	ld	a5,48(a5)
ffffffffc0202c50:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202c52:	00004517          	auipc	a0,0x4
ffffffffc0202c56:	cc650513          	addi	a0,a0,-826 # ffffffffc0206918 <default_pmm_manager+0x1e0>
ffffffffc0202c5a:	d3afd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202c5e:	00007697          	auipc	a3,0x7
ffffffffc0202c62:	3a268693          	addi	a3,a3,930 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202c66:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202c6a:	c02007b7          	lui	a5,0xc0200
ffffffffc0202c6e:	28f6ebe3          	bltu	a3,a5,ffffffffc0203704 <pmm_init+0xbd0>
ffffffffc0202c72:	0009b783          	ld	a5,0(s3)
ffffffffc0202c76:	8e9d                	sub	a3,a3,a5
ffffffffc0202c78:	000cc797          	auipc	a5,0xcc
ffffffffc0202c7c:	7ed7bc23          	sd	a3,2040(a5) # ffffffffc02cf470 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202c80:	100027f3          	csrr	a5,sstatus
ffffffffc0202c84:	8b89                	andi	a5,a5,2
ffffffffc0202c86:	4a079763          	bnez	a5,ffffffffc0203134 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c8a:	000b3783          	ld	a5,0(s6)
ffffffffc0202c8e:	779c                	ld	a5,40(a5)
ffffffffc0202c90:	9782                	jalr	a5
ffffffffc0202c92:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202c94:	6098                	ld	a4,0(s1)
ffffffffc0202c96:	c80007b7          	lui	a5,0xc8000
ffffffffc0202c9a:	83b1                	srli	a5,a5,0xc
ffffffffc0202c9c:	66e7e363          	bltu	a5,a4,ffffffffc0203302 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202ca0:	00093503          	ld	a0,0(s2)
ffffffffc0202ca4:	62050f63          	beqz	a0,ffffffffc02032e2 <pmm_init+0x7ae>
ffffffffc0202ca8:	03451793          	slli	a5,a0,0x34
ffffffffc0202cac:	62079b63          	bnez	a5,ffffffffc02032e2 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202cb0:	4601                	li	a2,0
ffffffffc0202cb2:	4581                	li	a1,0
ffffffffc0202cb4:	f58ff0ef          	jal	ra,ffffffffc020240c <get_page>
ffffffffc0202cb8:	60051563          	bnez	a0,ffffffffc02032c2 <pmm_init+0x78e>
ffffffffc0202cbc:	100027f3          	csrr	a5,sstatus
ffffffffc0202cc0:	8b89                	andi	a5,a5,2
ffffffffc0202cc2:	44079e63          	bnez	a5,ffffffffc020311e <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cc6:	000b3783          	ld	a5,0(s6)
ffffffffc0202cca:	4505                	li	a0,1
ffffffffc0202ccc:	6f9c                	ld	a5,24(a5)
ffffffffc0202cce:	9782                	jalr	a5
ffffffffc0202cd0:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202cd2:	00093503          	ld	a0,0(s2)
ffffffffc0202cd6:	4681                	li	a3,0
ffffffffc0202cd8:	4601                	li	a2,0
ffffffffc0202cda:	85d2                	mv	a1,s4
ffffffffc0202cdc:	d63ff0ef          	jal	ra,ffffffffc0202a3e <page_insert>
ffffffffc0202ce0:	26051ae3          	bnez	a0,ffffffffc0203754 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202ce4:	00093503          	ld	a0,0(s2)
ffffffffc0202ce8:	4601                	li	a2,0
ffffffffc0202cea:	4581                	li	a1,0
ffffffffc0202cec:	cf8ff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc0202cf0:	240502e3          	beqz	a0,ffffffffc0203734 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202cf4:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202cf6:	0017f713          	andi	a4,a5,1
ffffffffc0202cfa:	5a070263          	beqz	a4,ffffffffc020329e <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202cfe:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202d00:	078a                	slli	a5,a5,0x2
ffffffffc0202d02:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d04:	58e7fb63          	bgeu	a5,a4,ffffffffc020329a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d08:	000bb683          	ld	a3,0(s7)
ffffffffc0202d0c:	fff80637          	lui	a2,0xfff80
ffffffffc0202d10:	97b2                	add	a5,a5,a2
ffffffffc0202d12:	079a                	slli	a5,a5,0x6
ffffffffc0202d14:	97b6                	add	a5,a5,a3
ffffffffc0202d16:	14fa17e3          	bne	s4,a5,ffffffffc0203664 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202d1a:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8fa0>
ffffffffc0202d1e:	4785                	li	a5,1
ffffffffc0202d20:	12f692e3          	bne	a3,a5,ffffffffc0203644 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202d24:	00093503          	ld	a0,0(s2)
ffffffffc0202d28:	77fd                	lui	a5,0xfffff
ffffffffc0202d2a:	6114                	ld	a3,0(a0)
ffffffffc0202d2c:	068a                	slli	a3,a3,0x2
ffffffffc0202d2e:	8efd                	and	a3,a3,a5
ffffffffc0202d30:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202d34:	0ee67ce3          	bgeu	a2,a4,ffffffffc020362c <pmm_init+0xaf8>
ffffffffc0202d38:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d3c:	96e2                	add	a3,a3,s8
ffffffffc0202d3e:	0006ba83          	ld	s5,0(a3)
ffffffffc0202d42:	0a8a                	slli	s5,s5,0x2
ffffffffc0202d44:	00fafab3          	and	s5,s5,a5
ffffffffc0202d48:	00cad793          	srli	a5,s5,0xc
ffffffffc0202d4c:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203612 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d50:	4601                	li	a2,0
ffffffffc0202d52:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d54:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d56:	c8eff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d5a:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202d5c:	55551363          	bne	a0,s5,ffffffffc02032a2 <pmm_init+0x76e>
ffffffffc0202d60:	100027f3          	csrr	a5,sstatus
ffffffffc0202d64:	8b89                	andi	a5,a5,2
ffffffffc0202d66:	3a079163          	bnez	a5,ffffffffc0203108 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d6a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d6e:	4505                	li	a0,1
ffffffffc0202d70:	6f9c                	ld	a5,24(a5)
ffffffffc0202d72:	9782                	jalr	a5
ffffffffc0202d74:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d76:	00093503          	ld	a0,0(s2)
ffffffffc0202d7a:	46d1                	li	a3,20
ffffffffc0202d7c:	6605                	lui	a2,0x1
ffffffffc0202d7e:	85e2                	mv	a1,s8
ffffffffc0202d80:	cbfff0ef          	jal	ra,ffffffffc0202a3e <page_insert>
ffffffffc0202d84:	060517e3          	bnez	a0,ffffffffc02035f2 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202d88:	00093503          	ld	a0,0(s2)
ffffffffc0202d8c:	4601                	li	a2,0
ffffffffc0202d8e:	6585                	lui	a1,0x1
ffffffffc0202d90:	c54ff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc0202d94:	02050fe3          	beqz	a0,ffffffffc02035d2 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202d98:	611c                	ld	a5,0(a0)
ffffffffc0202d9a:	0107f713          	andi	a4,a5,16
ffffffffc0202d9e:	7c070e63          	beqz	a4,ffffffffc020357a <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202da2:	8b91                	andi	a5,a5,4
ffffffffc0202da4:	7a078b63          	beqz	a5,ffffffffc020355a <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202da8:	00093503          	ld	a0,0(s2)
ffffffffc0202dac:	611c                	ld	a5,0(a0)
ffffffffc0202dae:	8bc1                	andi	a5,a5,16
ffffffffc0202db0:	78078563          	beqz	a5,ffffffffc020353a <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202db4:	000c2703          	lw	a4,0(s8)
ffffffffc0202db8:	4785                	li	a5,1
ffffffffc0202dba:	76f71063          	bne	a4,a5,ffffffffc020351a <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202dbe:	4681                	li	a3,0
ffffffffc0202dc0:	6605                	lui	a2,0x1
ffffffffc0202dc2:	85d2                	mv	a1,s4
ffffffffc0202dc4:	c7bff0ef          	jal	ra,ffffffffc0202a3e <page_insert>
ffffffffc0202dc8:	72051963          	bnez	a0,ffffffffc02034fa <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202dcc:	000a2703          	lw	a4,0(s4)
ffffffffc0202dd0:	4789                	li	a5,2
ffffffffc0202dd2:	70f71463          	bne	a4,a5,ffffffffc02034da <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202dd6:	000c2783          	lw	a5,0(s8)
ffffffffc0202dda:	6e079063          	bnez	a5,ffffffffc02034ba <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202dde:	00093503          	ld	a0,0(s2)
ffffffffc0202de2:	4601                	li	a2,0
ffffffffc0202de4:	6585                	lui	a1,0x1
ffffffffc0202de6:	bfeff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc0202dea:	6a050863          	beqz	a0,ffffffffc020349a <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202dee:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202df0:	00177793          	andi	a5,a4,1
ffffffffc0202df4:	4a078563          	beqz	a5,ffffffffc020329e <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202df8:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202dfa:	00271793          	slli	a5,a4,0x2
ffffffffc0202dfe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e00:	48d7fd63          	bgeu	a5,a3,ffffffffc020329a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e04:	000bb683          	ld	a3,0(s7)
ffffffffc0202e08:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202e0c:	97d6                	add	a5,a5,s5
ffffffffc0202e0e:	079a                	slli	a5,a5,0x6
ffffffffc0202e10:	97b6                	add	a5,a5,a3
ffffffffc0202e12:	66fa1463          	bne	s4,a5,ffffffffc020347a <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202e16:	8b41                	andi	a4,a4,16
ffffffffc0202e18:	64071163          	bnez	a4,ffffffffc020345a <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202e1c:	00093503          	ld	a0,0(s2)
ffffffffc0202e20:	4581                	li	a1,0
ffffffffc0202e22:	b81ff0ef          	jal	ra,ffffffffc02029a2 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202e26:	000a2c83          	lw	s9,0(s4)
ffffffffc0202e2a:	4785                	li	a5,1
ffffffffc0202e2c:	60fc9763          	bne	s9,a5,ffffffffc020343a <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202e30:	000c2783          	lw	a5,0(s8)
ffffffffc0202e34:	5e079363          	bnez	a5,ffffffffc020341a <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202e38:	00093503          	ld	a0,0(s2)
ffffffffc0202e3c:	6585                	lui	a1,0x1
ffffffffc0202e3e:	b65ff0ef          	jal	ra,ffffffffc02029a2 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202e42:	000a2783          	lw	a5,0(s4)
ffffffffc0202e46:	52079a63          	bnez	a5,ffffffffc020337a <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202e4a:	000c2783          	lw	a5,0(s8)
ffffffffc0202e4e:	50079663          	bnez	a5,ffffffffc020335a <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202e52:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202e56:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e58:	000a3683          	ld	a3,0(s4)
ffffffffc0202e5c:	068a                	slli	a3,a3,0x2
ffffffffc0202e5e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e60:	42b6fd63          	bgeu	a3,a1,ffffffffc020329a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e64:	000bb503          	ld	a0,0(s7)
ffffffffc0202e68:	96d6                	add	a3,a3,s5
ffffffffc0202e6a:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202e6c:	00d507b3          	add	a5,a0,a3
ffffffffc0202e70:	439c                	lw	a5,0(a5)
ffffffffc0202e72:	4d979463          	bne	a5,s9,ffffffffc020333a <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202e76:	8699                	srai	a3,a3,0x6
ffffffffc0202e78:	00080637          	lui	a2,0x80
ffffffffc0202e7c:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202e7e:	00c69713          	slli	a4,a3,0xc
ffffffffc0202e82:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e84:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e86:	48b77e63          	bgeu	a4,a1,ffffffffc0203322 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202e8a:	0009b703          	ld	a4,0(s3)
ffffffffc0202e8e:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e90:	629c                	ld	a5,0(a3)
ffffffffc0202e92:	078a                	slli	a5,a5,0x2
ffffffffc0202e94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e96:	40b7f263          	bgeu	a5,a1,ffffffffc020329a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e9a:	8f91                	sub	a5,a5,a2
ffffffffc0202e9c:	079a                	slli	a5,a5,0x6
ffffffffc0202e9e:	953e                	add	a0,a0,a5
ffffffffc0202ea0:	100027f3          	csrr	a5,sstatus
ffffffffc0202ea4:	8b89                	andi	a5,a5,2
ffffffffc0202ea6:	30079963          	bnez	a5,ffffffffc02031b8 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202eaa:	000b3783          	ld	a5,0(s6)
ffffffffc0202eae:	4585                	li	a1,1
ffffffffc0202eb0:	739c                	ld	a5,32(a5)
ffffffffc0202eb2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202eb4:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202eb8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202eba:	078a                	slli	a5,a5,0x2
ffffffffc0202ebc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ebe:	3ce7fe63          	bgeu	a5,a4,ffffffffc020329a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ec2:	000bb503          	ld	a0,0(s7)
ffffffffc0202ec6:	fff80737          	lui	a4,0xfff80
ffffffffc0202eca:	97ba                	add	a5,a5,a4
ffffffffc0202ecc:	079a                	slli	a5,a5,0x6
ffffffffc0202ece:	953e                	add	a0,a0,a5
ffffffffc0202ed0:	100027f3          	csrr	a5,sstatus
ffffffffc0202ed4:	8b89                	andi	a5,a5,2
ffffffffc0202ed6:	2c079563          	bnez	a5,ffffffffc02031a0 <pmm_init+0x66c>
ffffffffc0202eda:	000b3783          	ld	a5,0(s6)
ffffffffc0202ede:	4585                	li	a1,1
ffffffffc0202ee0:	739c                	ld	a5,32(a5)
ffffffffc0202ee2:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ee4:	00093783          	ld	a5,0(s2)
ffffffffc0202ee8:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd2fb44>
    asm volatile("sfence.vma");
ffffffffc0202eec:	12000073          	sfence.vma
ffffffffc0202ef0:	100027f3          	csrr	a5,sstatus
ffffffffc0202ef4:	8b89                	andi	a5,a5,2
ffffffffc0202ef6:	28079b63          	bnez	a5,ffffffffc020318c <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202efa:	000b3783          	ld	a5,0(s6)
ffffffffc0202efe:	779c                	ld	a5,40(a5)
ffffffffc0202f00:	9782                	jalr	a5
ffffffffc0202f02:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202f04:	4b441b63          	bne	s0,s4,ffffffffc02033ba <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202f08:	00004517          	auipc	a0,0x4
ffffffffc0202f0c:	d3850513          	addi	a0,a0,-712 # ffffffffc0206c40 <default_pmm_manager+0x508>
ffffffffc0202f10:	a84fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202f14:	100027f3          	csrr	a5,sstatus
ffffffffc0202f18:	8b89                	andi	a5,a5,2
ffffffffc0202f1a:	24079f63          	bnez	a5,ffffffffc0203178 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f1e:	000b3783          	ld	a5,0(s6)
ffffffffc0202f22:	779c                	ld	a5,40(a5)
ffffffffc0202f24:	9782                	jalr	a5
ffffffffc0202f26:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202f28:	6098                	ld	a4,0(s1)
ffffffffc0202f2a:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f2e:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202f30:	00c71793          	slli	a5,a4,0xc
ffffffffc0202f34:	6a05                	lui	s4,0x1
ffffffffc0202f36:	02f47c63          	bgeu	s0,a5,ffffffffc0202f6e <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f3a:	00c45793          	srli	a5,s0,0xc
ffffffffc0202f3e:	00093503          	ld	a0,0(s2)
ffffffffc0202f42:	2ee7ff63          	bgeu	a5,a4,ffffffffc0203240 <pmm_init+0x70c>
ffffffffc0202f46:	0009b583          	ld	a1,0(s3)
ffffffffc0202f4a:	4601                	li	a2,0
ffffffffc0202f4c:	95a2                	add	a1,a1,s0
ffffffffc0202f4e:	a96ff0ef          	jal	ra,ffffffffc02021e4 <get_pte>
ffffffffc0202f52:	32050463          	beqz	a0,ffffffffc020327a <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f56:	611c                	ld	a5,0(a0)
ffffffffc0202f58:	078a                	slli	a5,a5,0x2
ffffffffc0202f5a:	0157f7b3          	and	a5,a5,s5
ffffffffc0202f5e:	2e879e63          	bne	a5,s0,ffffffffc020325a <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202f62:	6098                	ld	a4,0(s1)
ffffffffc0202f64:	9452                	add	s0,s0,s4
ffffffffc0202f66:	00c71793          	slli	a5,a4,0xc
ffffffffc0202f6a:	fcf468e3          	bltu	s0,a5,ffffffffc0202f3a <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f6e:	00093783          	ld	a5,0(s2)
ffffffffc0202f72:	639c                	ld	a5,0(a5)
ffffffffc0202f74:	42079363          	bnez	a5,ffffffffc020339a <pmm_init+0x866>
ffffffffc0202f78:	100027f3          	csrr	a5,sstatus
ffffffffc0202f7c:	8b89                	andi	a5,a5,2
ffffffffc0202f7e:	24079963          	bnez	a5,ffffffffc02031d0 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202f82:	000b3783          	ld	a5,0(s6)
ffffffffc0202f86:	4505                	li	a0,1
ffffffffc0202f88:	6f9c                	ld	a5,24(a5)
ffffffffc0202f8a:	9782                	jalr	a5
ffffffffc0202f8c:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202f8e:	00093503          	ld	a0,0(s2)
ffffffffc0202f92:	4699                	li	a3,6
ffffffffc0202f94:	10000613          	li	a2,256
ffffffffc0202f98:	85d2                	mv	a1,s4
ffffffffc0202f9a:	aa5ff0ef          	jal	ra,ffffffffc0202a3e <page_insert>
ffffffffc0202f9e:	44051e63          	bnez	a0,ffffffffc02033fa <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202fa2:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8fa0>
ffffffffc0202fa6:	4785                	li	a5,1
ffffffffc0202fa8:	42f71963          	bne	a4,a5,ffffffffc02033da <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202fac:	00093503          	ld	a0,0(s2)
ffffffffc0202fb0:	6405                	lui	s0,0x1
ffffffffc0202fb2:	4699                	li	a3,6
ffffffffc0202fb4:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ea0>
ffffffffc0202fb8:	85d2                	mv	a1,s4
ffffffffc0202fba:	a85ff0ef          	jal	ra,ffffffffc0202a3e <page_insert>
ffffffffc0202fbe:	72051363          	bnez	a0,ffffffffc02036e4 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202fc2:	000a2703          	lw	a4,0(s4)
ffffffffc0202fc6:	4789                	li	a5,2
ffffffffc0202fc8:	6ef71e63          	bne	a4,a5,ffffffffc02036c4 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202fcc:	00004597          	auipc	a1,0x4
ffffffffc0202fd0:	dbc58593          	addi	a1,a1,-580 # ffffffffc0206d88 <default_pmm_manager+0x650>
ffffffffc0202fd4:	10000513          	li	a0,256
ffffffffc0202fd8:	7de020ef          	jal	ra,ffffffffc02057b6 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202fdc:	10040593          	addi	a1,s0,256
ffffffffc0202fe0:	10000513          	li	a0,256
ffffffffc0202fe4:	7e4020ef          	jal	ra,ffffffffc02057c8 <strcmp>
ffffffffc0202fe8:	6a051e63          	bnez	a0,ffffffffc02036a4 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202fec:	000bb683          	ld	a3,0(s7)
ffffffffc0202ff0:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202ff4:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202ff6:	40da06b3          	sub	a3,s4,a3
ffffffffc0202ffa:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202ffc:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202ffe:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203000:	8031                	srli	s0,s0,0xc
ffffffffc0203002:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203006:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203008:	30f77d63          	bgeu	a4,a5,ffffffffc0203322 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020300c:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203010:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0203014:	96be                	add	a3,a3,a5
ffffffffc0203016:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020301a:	766020ef          	jal	ra,ffffffffc0205780 <strlen>
ffffffffc020301e:	66051363          	bnez	a0,ffffffffc0203684 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0203022:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0203026:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203028:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd2fb44>
ffffffffc020302c:	068a                	slli	a3,a3,0x2
ffffffffc020302e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0203030:	26f6f563          	bgeu	a3,a5,ffffffffc020329a <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0203034:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203036:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203038:	2ef47563          	bgeu	s0,a5,ffffffffc0203322 <pmm_init+0x7ee>
ffffffffc020303c:	0009b403          	ld	s0,0(s3)
ffffffffc0203040:	9436                	add	s0,s0,a3
ffffffffc0203042:	100027f3          	csrr	a5,sstatus
ffffffffc0203046:	8b89                	andi	a5,a5,2
ffffffffc0203048:	1e079163          	bnez	a5,ffffffffc020322a <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc020304c:	000b3783          	ld	a5,0(s6)
ffffffffc0203050:	4585                	li	a1,1
ffffffffc0203052:	8552                	mv	a0,s4
ffffffffc0203054:	739c                	ld	a5,32(a5)
ffffffffc0203056:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203058:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc020305a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020305c:	078a                	slli	a5,a5,0x2
ffffffffc020305e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203060:	22e7fd63          	bgeu	a5,a4,ffffffffc020329a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0203064:	000bb503          	ld	a0,0(s7)
ffffffffc0203068:	fff80737          	lui	a4,0xfff80
ffffffffc020306c:	97ba                	add	a5,a5,a4
ffffffffc020306e:	079a                	slli	a5,a5,0x6
ffffffffc0203070:	953e                	add	a0,a0,a5
ffffffffc0203072:	100027f3          	csrr	a5,sstatus
ffffffffc0203076:	8b89                	andi	a5,a5,2
ffffffffc0203078:	18079d63          	bnez	a5,ffffffffc0203212 <pmm_init+0x6de>
ffffffffc020307c:	000b3783          	ld	a5,0(s6)
ffffffffc0203080:	4585                	li	a1,1
ffffffffc0203082:	739c                	ld	a5,32(a5)
ffffffffc0203084:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203086:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc020308a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020308c:	078a                	slli	a5,a5,0x2
ffffffffc020308e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203090:	20e7f563          	bgeu	a5,a4,ffffffffc020329a <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0203094:	000bb503          	ld	a0,0(s7)
ffffffffc0203098:	fff80737          	lui	a4,0xfff80
ffffffffc020309c:	97ba                	add	a5,a5,a4
ffffffffc020309e:	079a                	slli	a5,a5,0x6
ffffffffc02030a0:	953e                	add	a0,a0,a5
ffffffffc02030a2:	100027f3          	csrr	a5,sstatus
ffffffffc02030a6:	8b89                	andi	a5,a5,2
ffffffffc02030a8:	14079963          	bnez	a5,ffffffffc02031fa <pmm_init+0x6c6>
ffffffffc02030ac:	000b3783          	ld	a5,0(s6)
ffffffffc02030b0:	4585                	li	a1,1
ffffffffc02030b2:	739c                	ld	a5,32(a5)
ffffffffc02030b4:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02030b6:	00093783          	ld	a5,0(s2)
ffffffffc02030ba:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02030be:	12000073          	sfence.vma
ffffffffc02030c2:	100027f3          	csrr	a5,sstatus
ffffffffc02030c6:	8b89                	andi	a5,a5,2
ffffffffc02030c8:	10079f63          	bnez	a5,ffffffffc02031e6 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02030cc:	000b3783          	ld	a5,0(s6)
ffffffffc02030d0:	779c                	ld	a5,40(a5)
ffffffffc02030d2:	9782                	jalr	a5
ffffffffc02030d4:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02030d6:	4c8c1e63          	bne	s8,s0,ffffffffc02035b2 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02030da:	00004517          	auipc	a0,0x4
ffffffffc02030de:	d2650513          	addi	a0,a0,-730 # ffffffffc0206e00 <default_pmm_manager+0x6c8>
ffffffffc02030e2:	8b2fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02030e6:	7406                	ld	s0,96(sp)
ffffffffc02030e8:	70a6                	ld	ra,104(sp)
ffffffffc02030ea:	64e6                	ld	s1,88(sp)
ffffffffc02030ec:	6946                	ld	s2,80(sp)
ffffffffc02030ee:	69a6                	ld	s3,72(sp)
ffffffffc02030f0:	6a06                	ld	s4,64(sp)
ffffffffc02030f2:	7ae2                	ld	s5,56(sp)
ffffffffc02030f4:	7b42                	ld	s6,48(sp)
ffffffffc02030f6:	7ba2                	ld	s7,40(sp)
ffffffffc02030f8:	7c02                	ld	s8,32(sp)
ffffffffc02030fa:	6ce2                	ld	s9,24(sp)
ffffffffc02030fc:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02030fe:	e2dfe06f          	j	ffffffffc0201f2a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0203102:	c80007b7          	lui	a5,0xc8000
ffffffffc0203106:	bc7d                	j	ffffffffc0202bc4 <pmm_init+0x90>
        intr_disable();
ffffffffc0203108:	8adfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020310c:	000b3783          	ld	a5,0(s6)
ffffffffc0203110:	4505                	li	a0,1
ffffffffc0203112:	6f9c                	ld	a5,24(a5)
ffffffffc0203114:	9782                	jalr	a5
ffffffffc0203116:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0203118:	897fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020311c:	b9a9                	j	ffffffffc0202d76 <pmm_init+0x242>
        intr_disable();
ffffffffc020311e:	897fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203122:	000b3783          	ld	a5,0(s6)
ffffffffc0203126:	4505                	li	a0,1
ffffffffc0203128:	6f9c                	ld	a5,24(a5)
ffffffffc020312a:	9782                	jalr	a5
ffffffffc020312c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020312e:	881fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203132:	b645                	j	ffffffffc0202cd2 <pmm_init+0x19e>
        intr_disable();
ffffffffc0203134:	881fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203138:	000b3783          	ld	a5,0(s6)
ffffffffc020313c:	779c                	ld	a5,40(a5)
ffffffffc020313e:	9782                	jalr	a5
ffffffffc0203140:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203142:	86dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203146:	b6b9                	j	ffffffffc0202c94 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0203148:	6705                	lui	a4,0x1
ffffffffc020314a:	177d                	addi	a4,a4,-1
ffffffffc020314c:	96ba                	add	a3,a3,a4
ffffffffc020314e:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0203150:	00c7d713          	srli	a4,a5,0xc
ffffffffc0203154:	14a77363          	bgeu	a4,a0,ffffffffc020329a <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0203158:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020315c:	fff80537          	lui	a0,0xfff80
ffffffffc0203160:	972a                	add	a4,a4,a0
ffffffffc0203162:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0203164:	8c1d                	sub	s0,s0,a5
ffffffffc0203166:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020316a:	00c45593          	srli	a1,s0,0xc
ffffffffc020316e:	9532                	add	a0,a0,a2
ffffffffc0203170:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0203172:	0009b583          	ld	a1,0(s3)
}
ffffffffc0203176:	b4c1                	j	ffffffffc0202c36 <pmm_init+0x102>
        intr_disable();
ffffffffc0203178:	83dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020317c:	000b3783          	ld	a5,0(s6)
ffffffffc0203180:	779c                	ld	a5,40(a5)
ffffffffc0203182:	9782                	jalr	a5
ffffffffc0203184:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0203186:	829fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020318a:	bb79                	j	ffffffffc0202f28 <pmm_init+0x3f4>
        intr_disable();
ffffffffc020318c:	829fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203190:	000b3783          	ld	a5,0(s6)
ffffffffc0203194:	779c                	ld	a5,40(a5)
ffffffffc0203196:	9782                	jalr	a5
ffffffffc0203198:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020319a:	815fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020319e:	b39d                	j	ffffffffc0202f04 <pmm_init+0x3d0>
ffffffffc02031a0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02031a2:	813fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02031a6:	000b3783          	ld	a5,0(s6)
ffffffffc02031aa:	6522                	ld	a0,8(sp)
ffffffffc02031ac:	4585                	li	a1,1
ffffffffc02031ae:	739c                	ld	a5,32(a5)
ffffffffc02031b0:	9782                	jalr	a5
        intr_enable();
ffffffffc02031b2:	ffcfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031b6:	b33d                	j	ffffffffc0202ee4 <pmm_init+0x3b0>
ffffffffc02031b8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02031ba:	ffafd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02031be:	000b3783          	ld	a5,0(s6)
ffffffffc02031c2:	6522                	ld	a0,8(sp)
ffffffffc02031c4:	4585                	li	a1,1
ffffffffc02031c6:	739c                	ld	a5,32(a5)
ffffffffc02031c8:	9782                	jalr	a5
        intr_enable();
ffffffffc02031ca:	fe4fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031ce:	b1dd                	j	ffffffffc0202eb4 <pmm_init+0x380>
        intr_disable();
ffffffffc02031d0:	fe4fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02031d4:	000b3783          	ld	a5,0(s6)
ffffffffc02031d8:	4505                	li	a0,1
ffffffffc02031da:	6f9c                	ld	a5,24(a5)
ffffffffc02031dc:	9782                	jalr	a5
ffffffffc02031de:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02031e0:	fcefd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031e4:	b36d                	j	ffffffffc0202f8e <pmm_init+0x45a>
        intr_disable();
ffffffffc02031e6:	fcefd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02031ea:	000b3783          	ld	a5,0(s6)
ffffffffc02031ee:	779c                	ld	a5,40(a5)
ffffffffc02031f0:	9782                	jalr	a5
ffffffffc02031f2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02031f4:	fbafd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02031f8:	bdf9                	j	ffffffffc02030d6 <pmm_init+0x5a2>
ffffffffc02031fa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02031fc:	fb8fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203200:	000b3783          	ld	a5,0(s6)
ffffffffc0203204:	6522                	ld	a0,8(sp)
ffffffffc0203206:	4585                	li	a1,1
ffffffffc0203208:	739c                	ld	a5,32(a5)
ffffffffc020320a:	9782                	jalr	a5
        intr_enable();
ffffffffc020320c:	fa2fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203210:	b55d                	j	ffffffffc02030b6 <pmm_init+0x582>
ffffffffc0203212:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203214:	fa0fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203218:	000b3783          	ld	a5,0(s6)
ffffffffc020321c:	6522                	ld	a0,8(sp)
ffffffffc020321e:	4585                	li	a1,1
ffffffffc0203220:	739c                	ld	a5,32(a5)
ffffffffc0203222:	9782                	jalr	a5
        intr_enable();
ffffffffc0203224:	f8afd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203228:	bdb9                	j	ffffffffc0203086 <pmm_init+0x552>
        intr_disable();
ffffffffc020322a:	f8afd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020322e:	000b3783          	ld	a5,0(s6)
ffffffffc0203232:	4585                	li	a1,1
ffffffffc0203234:	8552                	mv	a0,s4
ffffffffc0203236:	739c                	ld	a5,32(a5)
ffffffffc0203238:	9782                	jalr	a5
        intr_enable();
ffffffffc020323a:	f74fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020323e:	bd29                	j	ffffffffc0203058 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203240:	86a2                	mv	a3,s0
ffffffffc0203242:	00003617          	auipc	a2,0x3
ffffffffc0203246:	e3e60613          	addi	a2,a2,-450 # ffffffffc0206080 <commands+0x5c8>
ffffffffc020324a:	24600593          	li	a1,582
ffffffffc020324e:	00003517          	auipc	a0,0x3
ffffffffc0203252:	5e250513          	addi	a0,a0,1506 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203256:	a38fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020325a:	00004697          	auipc	a3,0x4
ffffffffc020325e:	a4668693          	addi	a3,a3,-1466 # ffffffffc0206ca0 <default_pmm_manager+0x568>
ffffffffc0203262:	00003617          	auipc	a2,0x3
ffffffffc0203266:	12660613          	addi	a2,a2,294 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020326a:	24700593          	li	a1,583
ffffffffc020326e:	00003517          	auipc	a0,0x3
ffffffffc0203272:	5c250513          	addi	a0,a0,1474 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203276:	a18fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020327a:	00004697          	auipc	a3,0x4
ffffffffc020327e:	9e668693          	addi	a3,a3,-1562 # ffffffffc0206c60 <default_pmm_manager+0x528>
ffffffffc0203282:	00003617          	auipc	a2,0x3
ffffffffc0203286:	10660613          	addi	a2,a2,262 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020328a:	24600593          	li	a1,582
ffffffffc020328e:	00003517          	auipc	a0,0x3
ffffffffc0203292:	5a250513          	addi	a0,a0,1442 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203296:	9f8fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020329a:	e5bfe0ef          	jal	ra,ffffffffc02020f4 <pa2page.part.0>
ffffffffc020329e:	e73fe0ef          	jal	ra,ffffffffc0202110 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02032a2:	00003697          	auipc	a3,0x3
ffffffffc02032a6:	7b668693          	addi	a3,a3,1974 # ffffffffc0206a58 <default_pmm_manager+0x320>
ffffffffc02032aa:	00003617          	auipc	a2,0x3
ffffffffc02032ae:	0de60613          	addi	a2,a2,222 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02032b2:	21600593          	li	a1,534
ffffffffc02032b6:	00003517          	auipc	a0,0x3
ffffffffc02032ba:	57a50513          	addi	a0,a0,1402 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02032be:	9d0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02032c2:	00003697          	auipc	a3,0x3
ffffffffc02032c6:	6d668693          	addi	a3,a3,1750 # ffffffffc0206998 <default_pmm_manager+0x260>
ffffffffc02032ca:	00003617          	auipc	a2,0x3
ffffffffc02032ce:	0be60613          	addi	a2,a2,190 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02032d2:	20900593          	li	a1,521
ffffffffc02032d6:	00003517          	auipc	a0,0x3
ffffffffc02032da:	55a50513          	addi	a0,a0,1370 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02032de:	9b0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02032e2:	00003697          	auipc	a3,0x3
ffffffffc02032e6:	67668693          	addi	a3,a3,1654 # ffffffffc0206958 <default_pmm_manager+0x220>
ffffffffc02032ea:	00003617          	auipc	a2,0x3
ffffffffc02032ee:	09e60613          	addi	a2,a2,158 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02032f2:	20800593          	li	a1,520
ffffffffc02032f6:	00003517          	auipc	a0,0x3
ffffffffc02032fa:	53a50513          	addi	a0,a0,1338 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02032fe:	990fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203302:	00003697          	auipc	a3,0x3
ffffffffc0203306:	63668693          	addi	a3,a3,1590 # ffffffffc0206938 <default_pmm_manager+0x200>
ffffffffc020330a:	00003617          	auipc	a2,0x3
ffffffffc020330e:	07e60613          	addi	a2,a2,126 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203312:	20700593          	li	a1,519
ffffffffc0203316:	00003517          	auipc	a0,0x3
ffffffffc020331a:	51a50513          	addi	a0,a0,1306 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc020331e:	970fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203322:	00003617          	auipc	a2,0x3
ffffffffc0203326:	d5e60613          	addi	a2,a2,-674 # ffffffffc0206080 <commands+0x5c8>
ffffffffc020332a:	07100593          	li	a1,113
ffffffffc020332e:	00003517          	auipc	a0,0x3
ffffffffc0203332:	d4250513          	addi	a0,a0,-702 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0203336:	958fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020333a:	00004697          	auipc	a3,0x4
ffffffffc020333e:	8ae68693          	addi	a3,a3,-1874 # ffffffffc0206be8 <default_pmm_manager+0x4b0>
ffffffffc0203342:	00003617          	auipc	a2,0x3
ffffffffc0203346:	04660613          	addi	a2,a2,70 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020334a:	22f00593          	li	a1,559
ffffffffc020334e:	00003517          	auipc	a0,0x3
ffffffffc0203352:	4e250513          	addi	a0,a0,1250 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203356:	938fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020335a:	00004697          	auipc	a3,0x4
ffffffffc020335e:	84668693          	addi	a3,a3,-1978 # ffffffffc0206ba0 <default_pmm_manager+0x468>
ffffffffc0203362:	00003617          	auipc	a2,0x3
ffffffffc0203366:	02660613          	addi	a2,a2,38 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020336a:	22d00593          	li	a1,557
ffffffffc020336e:	00003517          	auipc	a0,0x3
ffffffffc0203372:	4c250513          	addi	a0,a0,1218 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203376:	918fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020337a:	00004697          	auipc	a3,0x4
ffffffffc020337e:	85668693          	addi	a3,a3,-1962 # ffffffffc0206bd0 <default_pmm_manager+0x498>
ffffffffc0203382:	00003617          	auipc	a2,0x3
ffffffffc0203386:	00660613          	addi	a2,a2,6 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020338a:	22c00593          	li	a1,556
ffffffffc020338e:	00003517          	auipc	a0,0x3
ffffffffc0203392:	4a250513          	addi	a0,a0,1186 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203396:	8f8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc020339a:	00004697          	auipc	a3,0x4
ffffffffc020339e:	91e68693          	addi	a3,a3,-1762 # ffffffffc0206cb8 <default_pmm_manager+0x580>
ffffffffc02033a2:	00003617          	auipc	a2,0x3
ffffffffc02033a6:	fe660613          	addi	a2,a2,-26 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02033aa:	24a00593          	li	a1,586
ffffffffc02033ae:	00003517          	auipc	a0,0x3
ffffffffc02033b2:	48250513          	addi	a0,a0,1154 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02033b6:	8d8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02033ba:	00004697          	auipc	a3,0x4
ffffffffc02033be:	85e68693          	addi	a3,a3,-1954 # ffffffffc0206c18 <default_pmm_manager+0x4e0>
ffffffffc02033c2:	00003617          	auipc	a2,0x3
ffffffffc02033c6:	fc660613          	addi	a2,a2,-58 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02033ca:	23700593          	li	a1,567
ffffffffc02033ce:	00003517          	auipc	a0,0x3
ffffffffc02033d2:	46250513          	addi	a0,a0,1122 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02033d6:	8b8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc02033da:	00004697          	auipc	a3,0x4
ffffffffc02033de:	93668693          	addi	a3,a3,-1738 # ffffffffc0206d10 <default_pmm_manager+0x5d8>
ffffffffc02033e2:	00003617          	auipc	a2,0x3
ffffffffc02033e6:	fa660613          	addi	a2,a2,-90 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02033ea:	24f00593          	li	a1,591
ffffffffc02033ee:	00003517          	auipc	a0,0x3
ffffffffc02033f2:	44250513          	addi	a0,a0,1090 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02033f6:	898fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02033fa:	00004697          	auipc	a3,0x4
ffffffffc02033fe:	8d668693          	addi	a3,a3,-1834 # ffffffffc0206cd0 <default_pmm_manager+0x598>
ffffffffc0203402:	00003617          	auipc	a2,0x3
ffffffffc0203406:	f8660613          	addi	a2,a2,-122 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020340a:	24e00593          	li	a1,590
ffffffffc020340e:	00003517          	auipc	a0,0x3
ffffffffc0203412:	42250513          	addi	a0,a0,1058 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203416:	878fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020341a:	00003697          	auipc	a3,0x3
ffffffffc020341e:	78668693          	addi	a3,a3,1926 # ffffffffc0206ba0 <default_pmm_manager+0x468>
ffffffffc0203422:	00003617          	auipc	a2,0x3
ffffffffc0203426:	f6660613          	addi	a2,a2,-154 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020342a:	22900593          	li	a1,553
ffffffffc020342e:	00003517          	auipc	a0,0x3
ffffffffc0203432:	40250513          	addi	a0,a0,1026 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203436:	858fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020343a:	00003697          	auipc	a3,0x3
ffffffffc020343e:	60668693          	addi	a3,a3,1542 # ffffffffc0206a40 <default_pmm_manager+0x308>
ffffffffc0203442:	00003617          	auipc	a2,0x3
ffffffffc0203446:	f4660613          	addi	a2,a2,-186 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020344a:	22800593          	li	a1,552
ffffffffc020344e:	00003517          	auipc	a0,0x3
ffffffffc0203452:	3e250513          	addi	a0,a0,994 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203456:	838fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020345a:	00003697          	auipc	a3,0x3
ffffffffc020345e:	75e68693          	addi	a3,a3,1886 # ffffffffc0206bb8 <default_pmm_manager+0x480>
ffffffffc0203462:	00003617          	auipc	a2,0x3
ffffffffc0203466:	f2660613          	addi	a2,a2,-218 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020346a:	22500593          	li	a1,549
ffffffffc020346e:	00003517          	auipc	a0,0x3
ffffffffc0203472:	3c250513          	addi	a0,a0,962 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203476:	818fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020347a:	00003697          	auipc	a3,0x3
ffffffffc020347e:	5ae68693          	addi	a3,a3,1454 # ffffffffc0206a28 <default_pmm_manager+0x2f0>
ffffffffc0203482:	00003617          	auipc	a2,0x3
ffffffffc0203486:	f0660613          	addi	a2,a2,-250 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020348a:	22400593          	li	a1,548
ffffffffc020348e:	00003517          	auipc	a0,0x3
ffffffffc0203492:	3a250513          	addi	a0,a0,930 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203496:	ff9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020349a:	00003697          	auipc	a3,0x3
ffffffffc020349e:	62e68693          	addi	a3,a3,1582 # ffffffffc0206ac8 <default_pmm_manager+0x390>
ffffffffc02034a2:	00003617          	auipc	a2,0x3
ffffffffc02034a6:	ee660613          	addi	a2,a2,-282 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02034aa:	22300593          	li	a1,547
ffffffffc02034ae:	00003517          	auipc	a0,0x3
ffffffffc02034b2:	38250513          	addi	a0,a0,898 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02034b6:	fd9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02034ba:	00003697          	auipc	a3,0x3
ffffffffc02034be:	6e668693          	addi	a3,a3,1766 # ffffffffc0206ba0 <default_pmm_manager+0x468>
ffffffffc02034c2:	00003617          	auipc	a2,0x3
ffffffffc02034c6:	ec660613          	addi	a2,a2,-314 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02034ca:	22200593          	li	a1,546
ffffffffc02034ce:	00003517          	auipc	a0,0x3
ffffffffc02034d2:	36250513          	addi	a0,a0,866 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02034d6:	fb9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02034da:	00003697          	auipc	a3,0x3
ffffffffc02034de:	6ae68693          	addi	a3,a3,1710 # ffffffffc0206b88 <default_pmm_manager+0x450>
ffffffffc02034e2:	00003617          	auipc	a2,0x3
ffffffffc02034e6:	ea660613          	addi	a2,a2,-346 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02034ea:	22100593          	li	a1,545
ffffffffc02034ee:	00003517          	auipc	a0,0x3
ffffffffc02034f2:	34250513          	addi	a0,a0,834 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02034f6:	f99fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02034fa:	00003697          	auipc	a3,0x3
ffffffffc02034fe:	65e68693          	addi	a3,a3,1630 # ffffffffc0206b58 <default_pmm_manager+0x420>
ffffffffc0203502:	00003617          	auipc	a2,0x3
ffffffffc0203506:	e8660613          	addi	a2,a2,-378 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020350a:	22000593          	li	a1,544
ffffffffc020350e:	00003517          	auipc	a0,0x3
ffffffffc0203512:	32250513          	addi	a0,a0,802 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203516:	f79fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020351a:	00003697          	auipc	a3,0x3
ffffffffc020351e:	62668693          	addi	a3,a3,1574 # ffffffffc0206b40 <default_pmm_manager+0x408>
ffffffffc0203522:	00003617          	auipc	a2,0x3
ffffffffc0203526:	e6660613          	addi	a2,a2,-410 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020352a:	21e00593          	li	a1,542
ffffffffc020352e:	00003517          	auipc	a0,0x3
ffffffffc0203532:	30250513          	addi	a0,a0,770 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203536:	f59fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020353a:	00003697          	auipc	a3,0x3
ffffffffc020353e:	5e668693          	addi	a3,a3,1510 # ffffffffc0206b20 <default_pmm_manager+0x3e8>
ffffffffc0203542:	00003617          	auipc	a2,0x3
ffffffffc0203546:	e4660613          	addi	a2,a2,-442 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020354a:	21d00593          	li	a1,541
ffffffffc020354e:	00003517          	auipc	a0,0x3
ffffffffc0203552:	2e250513          	addi	a0,a0,738 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203556:	f39fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc020355a:	00003697          	auipc	a3,0x3
ffffffffc020355e:	5b668693          	addi	a3,a3,1462 # ffffffffc0206b10 <default_pmm_manager+0x3d8>
ffffffffc0203562:	00003617          	auipc	a2,0x3
ffffffffc0203566:	e2660613          	addi	a2,a2,-474 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020356a:	21c00593          	li	a1,540
ffffffffc020356e:	00003517          	auipc	a0,0x3
ffffffffc0203572:	2c250513          	addi	a0,a0,706 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203576:	f19fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc020357a:	00003697          	auipc	a3,0x3
ffffffffc020357e:	58668693          	addi	a3,a3,1414 # ffffffffc0206b00 <default_pmm_manager+0x3c8>
ffffffffc0203582:	00003617          	auipc	a2,0x3
ffffffffc0203586:	e0660613          	addi	a2,a2,-506 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020358a:	21b00593          	li	a1,539
ffffffffc020358e:	00003517          	auipc	a0,0x3
ffffffffc0203592:	2a250513          	addi	a0,a0,674 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203596:	ef9fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc020359a:	00003617          	auipc	a2,0x3
ffffffffc020359e:	30660613          	addi	a2,a2,774 # ffffffffc02068a0 <default_pmm_manager+0x168>
ffffffffc02035a2:	06500593          	li	a1,101
ffffffffc02035a6:	00003517          	auipc	a0,0x3
ffffffffc02035aa:	28a50513          	addi	a0,a0,650 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02035ae:	ee1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02035b2:	00003697          	auipc	a3,0x3
ffffffffc02035b6:	66668693          	addi	a3,a3,1638 # ffffffffc0206c18 <default_pmm_manager+0x4e0>
ffffffffc02035ba:	00003617          	auipc	a2,0x3
ffffffffc02035be:	dce60613          	addi	a2,a2,-562 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02035c2:	26100593          	li	a1,609
ffffffffc02035c6:	00003517          	auipc	a0,0x3
ffffffffc02035ca:	26a50513          	addi	a0,a0,618 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02035ce:	ec1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02035d2:	00003697          	auipc	a3,0x3
ffffffffc02035d6:	4f668693          	addi	a3,a3,1270 # ffffffffc0206ac8 <default_pmm_manager+0x390>
ffffffffc02035da:	00003617          	auipc	a2,0x3
ffffffffc02035de:	dae60613          	addi	a2,a2,-594 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02035e2:	21a00593          	li	a1,538
ffffffffc02035e6:	00003517          	auipc	a0,0x3
ffffffffc02035ea:	24a50513          	addi	a0,a0,586 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02035ee:	ea1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02035f2:	00003697          	auipc	a3,0x3
ffffffffc02035f6:	49668693          	addi	a3,a3,1174 # ffffffffc0206a88 <default_pmm_manager+0x350>
ffffffffc02035fa:	00003617          	auipc	a2,0x3
ffffffffc02035fe:	d8e60613          	addi	a2,a2,-626 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203602:	21900593          	li	a1,537
ffffffffc0203606:	00003517          	auipc	a0,0x3
ffffffffc020360a:	22a50513          	addi	a0,a0,554 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc020360e:	e81fc0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203612:	86d6                	mv	a3,s5
ffffffffc0203614:	00003617          	auipc	a2,0x3
ffffffffc0203618:	a6c60613          	addi	a2,a2,-1428 # ffffffffc0206080 <commands+0x5c8>
ffffffffc020361c:	21500593          	li	a1,533
ffffffffc0203620:	00003517          	auipc	a0,0x3
ffffffffc0203624:	21050513          	addi	a0,a0,528 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203628:	e67fc0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020362c:	00003617          	auipc	a2,0x3
ffffffffc0203630:	a5460613          	addi	a2,a2,-1452 # ffffffffc0206080 <commands+0x5c8>
ffffffffc0203634:	21400593          	li	a1,532
ffffffffc0203638:	00003517          	auipc	a0,0x3
ffffffffc020363c:	1f850513          	addi	a0,a0,504 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203640:	e4ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203644:	00003697          	auipc	a3,0x3
ffffffffc0203648:	3fc68693          	addi	a3,a3,1020 # ffffffffc0206a40 <default_pmm_manager+0x308>
ffffffffc020364c:	00003617          	auipc	a2,0x3
ffffffffc0203650:	d3c60613          	addi	a2,a2,-708 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203654:	21200593          	li	a1,530
ffffffffc0203658:	00003517          	auipc	a0,0x3
ffffffffc020365c:	1d850513          	addi	a0,a0,472 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203660:	e2ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203664:	00003697          	auipc	a3,0x3
ffffffffc0203668:	3c468693          	addi	a3,a3,964 # ffffffffc0206a28 <default_pmm_manager+0x2f0>
ffffffffc020366c:	00003617          	auipc	a2,0x3
ffffffffc0203670:	d1c60613          	addi	a2,a2,-740 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203674:	21100593          	li	a1,529
ffffffffc0203678:	00003517          	auipc	a0,0x3
ffffffffc020367c:	1b850513          	addi	a0,a0,440 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203680:	e0ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203684:	00003697          	auipc	a3,0x3
ffffffffc0203688:	75468693          	addi	a3,a3,1876 # ffffffffc0206dd8 <default_pmm_manager+0x6a0>
ffffffffc020368c:	00003617          	auipc	a2,0x3
ffffffffc0203690:	cfc60613          	addi	a2,a2,-772 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203694:	25800593          	li	a1,600
ffffffffc0203698:	00003517          	auipc	a0,0x3
ffffffffc020369c:	19850513          	addi	a0,a0,408 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02036a0:	deffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02036a4:	00003697          	auipc	a3,0x3
ffffffffc02036a8:	6fc68693          	addi	a3,a3,1788 # ffffffffc0206da0 <default_pmm_manager+0x668>
ffffffffc02036ac:	00003617          	auipc	a2,0x3
ffffffffc02036b0:	cdc60613          	addi	a2,a2,-804 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02036b4:	25500593          	li	a1,597
ffffffffc02036b8:	00003517          	auipc	a0,0x3
ffffffffc02036bc:	17850513          	addi	a0,a0,376 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02036c0:	dcffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02036c4:	00003697          	auipc	a3,0x3
ffffffffc02036c8:	6ac68693          	addi	a3,a3,1708 # ffffffffc0206d70 <default_pmm_manager+0x638>
ffffffffc02036cc:	00003617          	auipc	a2,0x3
ffffffffc02036d0:	cbc60613          	addi	a2,a2,-836 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02036d4:	25100593          	li	a1,593
ffffffffc02036d8:	00003517          	auipc	a0,0x3
ffffffffc02036dc:	15850513          	addi	a0,a0,344 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc02036e0:	daffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02036e4:	00003697          	auipc	a3,0x3
ffffffffc02036e8:	64468693          	addi	a3,a3,1604 # ffffffffc0206d28 <default_pmm_manager+0x5f0>
ffffffffc02036ec:	00003617          	auipc	a2,0x3
ffffffffc02036f0:	c9c60613          	addi	a2,a2,-868 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02036f4:	25000593          	li	a1,592
ffffffffc02036f8:	00003517          	auipc	a0,0x3
ffffffffc02036fc:	13850513          	addi	a0,a0,312 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203700:	d8ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203704:	00003617          	auipc	a2,0x3
ffffffffc0203708:	0dc60613          	addi	a2,a2,220 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc020370c:	0c900593          	li	a1,201
ffffffffc0203710:	00003517          	auipc	a0,0x3
ffffffffc0203714:	12050513          	addi	a0,a0,288 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203718:	d77fc0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020371c:	00003617          	auipc	a2,0x3
ffffffffc0203720:	0c460613          	addi	a2,a2,196 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc0203724:	08100593          	li	a1,129
ffffffffc0203728:	00003517          	auipc	a0,0x3
ffffffffc020372c:	10850513          	addi	a0,a0,264 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203730:	d5ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203734:	00003697          	auipc	a3,0x3
ffffffffc0203738:	2c468693          	addi	a3,a3,708 # ffffffffc02069f8 <default_pmm_manager+0x2c0>
ffffffffc020373c:	00003617          	auipc	a2,0x3
ffffffffc0203740:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203744:	21000593          	li	a1,528
ffffffffc0203748:	00003517          	auipc	a0,0x3
ffffffffc020374c:	0e850513          	addi	a0,a0,232 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203750:	d3ffc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203754:	00003697          	auipc	a3,0x3
ffffffffc0203758:	27468693          	addi	a3,a3,628 # ffffffffc02069c8 <default_pmm_manager+0x290>
ffffffffc020375c:	00003617          	auipc	a2,0x3
ffffffffc0203760:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203764:	20d00593          	li	a1,525
ffffffffc0203768:	00003517          	auipc	a0,0x3
ffffffffc020376c:	0c850513          	addi	a0,a0,200 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203770:	d1ffc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203774 <pgdir_alloc_page>:
{
ffffffffc0203774:	7179                	addi	sp,sp,-48
ffffffffc0203776:	ec26                	sd	s1,24(sp)
ffffffffc0203778:	e84a                	sd	s2,16(sp)
ffffffffc020377a:	e052                	sd	s4,0(sp)
ffffffffc020377c:	f406                	sd	ra,40(sp)
ffffffffc020377e:	f022                	sd	s0,32(sp)
ffffffffc0203780:	e44e                	sd	s3,8(sp)
ffffffffc0203782:	8a2a                	mv	s4,a0
ffffffffc0203784:	84ae                	mv	s1,a1
ffffffffc0203786:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203788:	100027f3          	csrr	a5,sstatus
ffffffffc020378c:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc020378e:	000cc997          	auipc	s3,0xcc
ffffffffc0203792:	d0298993          	addi	s3,s3,-766 # ffffffffc02cf490 <pmm_manager>
ffffffffc0203796:	ef8d                	bnez	a5,ffffffffc02037d0 <pgdir_alloc_page+0x5c>
ffffffffc0203798:	0009b783          	ld	a5,0(s3)
ffffffffc020379c:	4505                	li	a0,1
ffffffffc020379e:	6f9c                	ld	a5,24(a5)
ffffffffc02037a0:	9782                	jalr	a5
ffffffffc02037a2:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02037a4:	cc09                	beqz	s0,ffffffffc02037be <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02037a6:	86ca                	mv	a3,s2
ffffffffc02037a8:	8626                	mv	a2,s1
ffffffffc02037aa:	85a2                	mv	a1,s0
ffffffffc02037ac:	8552                	mv	a0,s4
ffffffffc02037ae:	a90ff0ef          	jal	ra,ffffffffc0202a3e <page_insert>
ffffffffc02037b2:	e915                	bnez	a0,ffffffffc02037e6 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02037b4:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02037b6:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02037b8:	4785                	li	a5,1
ffffffffc02037ba:	04f71e63          	bne	a4,a5,ffffffffc0203816 <pgdir_alloc_page+0xa2>
}
ffffffffc02037be:	70a2                	ld	ra,40(sp)
ffffffffc02037c0:	8522                	mv	a0,s0
ffffffffc02037c2:	7402                	ld	s0,32(sp)
ffffffffc02037c4:	64e2                	ld	s1,24(sp)
ffffffffc02037c6:	6942                	ld	s2,16(sp)
ffffffffc02037c8:	69a2                	ld	s3,8(sp)
ffffffffc02037ca:	6a02                	ld	s4,0(sp)
ffffffffc02037cc:	6145                	addi	sp,sp,48
ffffffffc02037ce:	8082                	ret
        intr_disable();
ffffffffc02037d0:	9e4fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02037d4:	0009b783          	ld	a5,0(s3)
ffffffffc02037d8:	4505                	li	a0,1
ffffffffc02037da:	6f9c                	ld	a5,24(a5)
ffffffffc02037dc:	9782                	jalr	a5
ffffffffc02037de:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02037e0:	9cefd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02037e4:	b7c1                	j	ffffffffc02037a4 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02037e6:	100027f3          	csrr	a5,sstatus
ffffffffc02037ea:	8b89                	andi	a5,a5,2
ffffffffc02037ec:	eb89                	bnez	a5,ffffffffc02037fe <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc02037ee:	0009b783          	ld	a5,0(s3)
ffffffffc02037f2:	8522                	mv	a0,s0
ffffffffc02037f4:	4585                	li	a1,1
ffffffffc02037f6:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02037f8:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02037fa:	9782                	jalr	a5
    if (flag)
ffffffffc02037fc:	b7c9                	j	ffffffffc02037be <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc02037fe:	9b6fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203802:	0009b783          	ld	a5,0(s3)
ffffffffc0203806:	8522                	mv	a0,s0
ffffffffc0203808:	4585                	li	a1,1
ffffffffc020380a:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020380c:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020380e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203810:	99efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203814:	b76d                	j	ffffffffc02037be <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203816:	00003697          	auipc	a3,0x3
ffffffffc020381a:	60a68693          	addi	a3,a3,1546 # ffffffffc0206e20 <default_pmm_manager+0x6e8>
ffffffffc020381e:	00003617          	auipc	a2,0x3
ffffffffc0203822:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203826:	1ee00593          	li	a1,494
ffffffffc020382a:	00003517          	auipc	a0,0x3
ffffffffc020382e:	00650513          	addi	a0,a0,6 # ffffffffc0206830 <default_pmm_manager+0xf8>
ffffffffc0203832:	c5dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203836 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203836:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203838:	00003697          	auipc	a3,0x3
ffffffffc020383c:	60068693          	addi	a3,a3,1536 # ffffffffc0206e38 <default_pmm_manager+0x700>
ffffffffc0203840:	00003617          	auipc	a2,0x3
ffffffffc0203844:	b4860613          	addi	a2,a2,-1208 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203848:	07400593          	li	a1,116
ffffffffc020384c:	00003517          	auipc	a0,0x3
ffffffffc0203850:	60c50513          	addi	a0,a0,1548 # ffffffffc0206e58 <default_pmm_manager+0x720>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203854:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203856:	c39fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020385a <mm_create>:
{
ffffffffc020385a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020385c:	04000513          	li	a0,64
{
ffffffffc0203860:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203862:	eecfe0ef          	jal	ra,ffffffffc0201f4e <kmalloc>
    if (mm != NULL)
ffffffffc0203866:	cd19                	beqz	a0,ffffffffc0203884 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203868:	e508                	sd	a0,8(a0)
ffffffffc020386a:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020386c:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203870:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203874:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203878:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020387c:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203880:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203884:	60a2                	ld	ra,8(sp)
ffffffffc0203886:	0141                	addi	sp,sp,16
ffffffffc0203888:	8082                	ret

ffffffffc020388a <find_vma>:
{
ffffffffc020388a:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc020388c:	c505                	beqz	a0,ffffffffc02038b4 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc020388e:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203890:	c501                	beqz	a0,ffffffffc0203898 <find_vma+0xe>
ffffffffc0203892:	651c                	ld	a5,8(a0)
ffffffffc0203894:	02f5f263          	bgeu	a1,a5,ffffffffc02038b8 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203898:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc020389a:	00f68d63          	beq	a3,a5,ffffffffc02038b4 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020389e:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7d30b2c>
ffffffffc02038a2:	00e5e663          	bltu	a1,a4,ffffffffc02038ae <find_vma+0x24>
ffffffffc02038a6:	ff07b703          	ld	a4,-16(a5)
ffffffffc02038aa:	00e5ec63          	bltu	a1,a4,ffffffffc02038c2 <find_vma+0x38>
ffffffffc02038ae:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02038b0:	fef697e3          	bne	a3,a5,ffffffffc020389e <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02038b4:	4501                	li	a0,0
}
ffffffffc02038b6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02038b8:	691c                	ld	a5,16(a0)
ffffffffc02038ba:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203898 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02038be:	ea88                	sd	a0,16(a3)
ffffffffc02038c0:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02038c2:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02038c6:	ea88                	sd	a0,16(a3)
ffffffffc02038c8:	8082                	ret

ffffffffc02038ca <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02038ca:	6590                	ld	a2,8(a1)
ffffffffc02038cc:	0105b803          	ld	a6,16(a1)
{
ffffffffc02038d0:	1141                	addi	sp,sp,-16
ffffffffc02038d2:	e406                	sd	ra,8(sp)
ffffffffc02038d4:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02038d6:	01066763          	bltu	a2,a6,ffffffffc02038e4 <insert_vma_struct+0x1a>
ffffffffc02038da:	a085                	j	ffffffffc020393a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02038dc:	fe87b703          	ld	a4,-24(a5)
ffffffffc02038e0:	04e66863          	bltu	a2,a4,ffffffffc0203930 <insert_vma_struct+0x66>
ffffffffc02038e4:	86be                	mv	a3,a5
ffffffffc02038e6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02038e8:	fef51ae3          	bne	a0,a5,ffffffffc02038dc <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02038ec:	02a68463          	beq	a3,a0,ffffffffc0203914 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02038f0:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02038f4:	fe86b883          	ld	a7,-24(a3)
ffffffffc02038f8:	08e8f163          	bgeu	a7,a4,ffffffffc020397a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02038fc:	04e66f63          	bltu	a2,a4,ffffffffc020395a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203900:	00f50a63          	beq	a0,a5,ffffffffc0203914 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203904:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203908:	05076963          	bltu	a4,a6,ffffffffc020395a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020390c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203910:	02c77363          	bgeu	a4,a2,ffffffffc0203936 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203914:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203916:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203918:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020391c:	e390                	sd	a2,0(a5)
ffffffffc020391e:	e690                	sd	a2,8(a3)
}
ffffffffc0203920:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203922:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203924:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203926:	0017079b          	addiw	a5,a4,1
ffffffffc020392a:	d11c                	sw	a5,32(a0)
}
ffffffffc020392c:	0141                	addi	sp,sp,16
ffffffffc020392e:	8082                	ret
    if (le_prev != list)
ffffffffc0203930:	fca690e3          	bne	a3,a0,ffffffffc02038f0 <insert_vma_struct+0x26>
ffffffffc0203934:	bfd1                	j	ffffffffc0203908 <insert_vma_struct+0x3e>
ffffffffc0203936:	f01ff0ef          	jal	ra,ffffffffc0203836 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020393a:	00003697          	auipc	a3,0x3
ffffffffc020393e:	52e68693          	addi	a3,a3,1326 # ffffffffc0206e68 <default_pmm_manager+0x730>
ffffffffc0203942:	00003617          	auipc	a2,0x3
ffffffffc0203946:	a4660613          	addi	a2,a2,-1466 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020394a:	07a00593          	li	a1,122
ffffffffc020394e:	00003517          	auipc	a0,0x3
ffffffffc0203952:	50a50513          	addi	a0,a0,1290 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203956:	b39fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020395a:	00003697          	auipc	a3,0x3
ffffffffc020395e:	54e68693          	addi	a3,a3,1358 # ffffffffc0206ea8 <default_pmm_manager+0x770>
ffffffffc0203962:	00003617          	auipc	a2,0x3
ffffffffc0203966:	a2660613          	addi	a2,a2,-1498 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020396a:	07300593          	li	a1,115
ffffffffc020396e:	00003517          	auipc	a0,0x3
ffffffffc0203972:	4ea50513          	addi	a0,a0,1258 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203976:	b19fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020397a:	00003697          	auipc	a3,0x3
ffffffffc020397e:	50e68693          	addi	a3,a3,1294 # ffffffffc0206e88 <default_pmm_manager+0x750>
ffffffffc0203982:	00003617          	auipc	a2,0x3
ffffffffc0203986:	a0660613          	addi	a2,a2,-1530 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020398a:	07200593          	li	a1,114
ffffffffc020398e:	00003517          	auipc	a0,0x3
ffffffffc0203992:	4ca50513          	addi	a0,a0,1226 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203996:	af9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020399a <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020399a:	591c                	lw	a5,48(a0)
{
ffffffffc020399c:	1141                	addi	sp,sp,-16
ffffffffc020399e:	e406                	sd	ra,8(sp)
ffffffffc02039a0:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02039a2:	e78d                	bnez	a5,ffffffffc02039cc <mm_destroy+0x32>
ffffffffc02039a4:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02039a6:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02039a8:	00a40c63          	beq	s0,a0,ffffffffc02039c0 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02039ac:	6118                	ld	a4,0(a0)
ffffffffc02039ae:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02039b0:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02039b2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02039b4:	e398                	sd	a4,0(a5)
ffffffffc02039b6:	e48fe0ef          	jal	ra,ffffffffc0201ffe <kfree>
    return listelm->next;
ffffffffc02039ba:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02039bc:	fea418e3          	bne	s0,a0,ffffffffc02039ac <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02039c0:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02039c2:	6402                	ld	s0,0(sp)
ffffffffc02039c4:	60a2                	ld	ra,8(sp)
ffffffffc02039c6:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02039c8:	e36fe06f          	j	ffffffffc0201ffe <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02039cc:	00003697          	auipc	a3,0x3
ffffffffc02039d0:	4fc68693          	addi	a3,a3,1276 # ffffffffc0206ec8 <default_pmm_manager+0x790>
ffffffffc02039d4:	00003617          	auipc	a2,0x3
ffffffffc02039d8:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02039dc:	09e00593          	li	a1,158
ffffffffc02039e0:	00003517          	auipc	a0,0x3
ffffffffc02039e4:	47850513          	addi	a0,a0,1144 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc02039e8:	aa7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039ec <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc02039ec:	7139                	addi	sp,sp,-64
ffffffffc02039ee:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02039f0:	6405                	lui	s0,0x1
ffffffffc02039f2:	147d                	addi	s0,s0,-1
ffffffffc02039f4:	77fd                	lui	a5,0xfffff
ffffffffc02039f6:	9622                	add	a2,a2,s0
ffffffffc02039f8:	962e                	add	a2,a2,a1
{
ffffffffc02039fa:	f426                	sd	s1,40(sp)
ffffffffc02039fc:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02039fe:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203a02:	f04a                	sd	s2,32(sp)
ffffffffc0203a04:	ec4e                	sd	s3,24(sp)
ffffffffc0203a06:	e852                	sd	s4,16(sp)
ffffffffc0203a08:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203a0a:	002005b7          	lui	a1,0x200
ffffffffc0203a0e:	00f67433          	and	s0,a2,a5
ffffffffc0203a12:	06b4e363          	bltu	s1,a1,ffffffffc0203a78 <mm_map+0x8c>
ffffffffc0203a16:	0684f163          	bgeu	s1,s0,ffffffffc0203a78 <mm_map+0x8c>
ffffffffc0203a1a:	4785                	li	a5,1
ffffffffc0203a1c:	07fe                	slli	a5,a5,0x1f
ffffffffc0203a1e:	0487ed63          	bltu	a5,s0,ffffffffc0203a78 <mm_map+0x8c>
ffffffffc0203a22:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203a24:	cd21                	beqz	a0,ffffffffc0203a7c <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203a26:	85a6                	mv	a1,s1
ffffffffc0203a28:	8ab6                	mv	s5,a3
ffffffffc0203a2a:	8a3a                	mv	s4,a4
ffffffffc0203a2c:	e5fff0ef          	jal	ra,ffffffffc020388a <find_vma>
ffffffffc0203a30:	c501                	beqz	a0,ffffffffc0203a38 <mm_map+0x4c>
ffffffffc0203a32:	651c                	ld	a5,8(a0)
ffffffffc0203a34:	0487e263          	bltu	a5,s0,ffffffffc0203a78 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a38:	03000513          	li	a0,48
ffffffffc0203a3c:	d12fe0ef          	jal	ra,ffffffffc0201f4e <kmalloc>
ffffffffc0203a40:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203a42:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203a44:	02090163          	beqz	s2,ffffffffc0203a66 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203a48:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203a4a:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203a4e:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203a52:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203a56:	85ca                	mv	a1,s2
ffffffffc0203a58:	e73ff0ef          	jal	ra,ffffffffc02038ca <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203a5c:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203a5e:	000a0463          	beqz	s4,ffffffffc0203a66 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203a62:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0203a66:	70e2                	ld	ra,56(sp)
ffffffffc0203a68:	7442                	ld	s0,48(sp)
ffffffffc0203a6a:	74a2                	ld	s1,40(sp)
ffffffffc0203a6c:	7902                	ld	s2,32(sp)
ffffffffc0203a6e:	69e2                	ld	s3,24(sp)
ffffffffc0203a70:	6a42                	ld	s4,16(sp)
ffffffffc0203a72:	6aa2                	ld	s5,8(sp)
ffffffffc0203a74:	6121                	addi	sp,sp,64
ffffffffc0203a76:	8082                	ret
        return -E_INVAL;
ffffffffc0203a78:	5575                	li	a0,-3
ffffffffc0203a7a:	b7f5                	j	ffffffffc0203a66 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203a7c:	00003697          	auipc	a3,0x3
ffffffffc0203a80:	46468693          	addi	a3,a3,1124 # ffffffffc0206ee0 <default_pmm_manager+0x7a8>
ffffffffc0203a84:	00003617          	auipc	a2,0x3
ffffffffc0203a88:	90460613          	addi	a2,a2,-1788 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203a8c:	0b300593          	li	a1,179
ffffffffc0203a90:	00003517          	auipc	a0,0x3
ffffffffc0203a94:	3c850513          	addi	a0,a0,968 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203a98:	9f7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a9c <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203a9c:	7139                	addi	sp,sp,-64
ffffffffc0203a9e:	fc06                	sd	ra,56(sp)
ffffffffc0203aa0:	f822                	sd	s0,48(sp)
ffffffffc0203aa2:	f426                	sd	s1,40(sp)
ffffffffc0203aa4:	f04a                	sd	s2,32(sp)
ffffffffc0203aa6:	ec4e                	sd	s3,24(sp)
ffffffffc0203aa8:	e852                	sd	s4,16(sp)
ffffffffc0203aaa:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203aac:	c52d                	beqz	a0,ffffffffc0203b16 <dup_mmap+0x7a>
ffffffffc0203aae:	892a                	mv	s2,a0
ffffffffc0203ab0:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203ab2:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203ab4:	e595                	bnez	a1,ffffffffc0203ae0 <dup_mmap+0x44>
ffffffffc0203ab6:	a085                	j	ffffffffc0203b16 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203ab8:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203aba:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_cowtest_out_size+0x1f4ad0>
        vma->vm_end = vm_end;
ffffffffc0203abe:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203ac2:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203ac6:	e05ff0ef          	jal	ra,ffffffffc02038ca <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203aca:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8fb0>
ffffffffc0203ace:	fe843603          	ld	a2,-24(s0)
ffffffffc0203ad2:	6c8c                	ld	a1,24(s1)
ffffffffc0203ad4:	01893503          	ld	a0,24(s2)
ffffffffc0203ad8:	4701                	li	a4,0
ffffffffc0203ada:	d5ffe0ef          	jal	ra,ffffffffc0202838 <copy_range>
ffffffffc0203ade:	e105                	bnez	a0,ffffffffc0203afe <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203ae0:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203ae2:	02848863          	beq	s1,s0,ffffffffc0203b12 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ae6:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203aea:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203aee:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203af2:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203af6:	c58fe0ef          	jal	ra,ffffffffc0201f4e <kmalloc>
ffffffffc0203afa:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203afc:	fd55                	bnez	a0,ffffffffc0203ab8 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203afe:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203b00:	70e2                	ld	ra,56(sp)
ffffffffc0203b02:	7442                	ld	s0,48(sp)
ffffffffc0203b04:	74a2                	ld	s1,40(sp)
ffffffffc0203b06:	7902                	ld	s2,32(sp)
ffffffffc0203b08:	69e2                	ld	s3,24(sp)
ffffffffc0203b0a:	6a42                	ld	s4,16(sp)
ffffffffc0203b0c:	6aa2                	ld	s5,8(sp)
ffffffffc0203b0e:	6121                	addi	sp,sp,64
ffffffffc0203b10:	8082                	ret
    return 0;
ffffffffc0203b12:	4501                	li	a0,0
ffffffffc0203b14:	b7f5                	j	ffffffffc0203b00 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203b16:	00003697          	auipc	a3,0x3
ffffffffc0203b1a:	3da68693          	addi	a3,a3,986 # ffffffffc0206ef0 <default_pmm_manager+0x7b8>
ffffffffc0203b1e:	00003617          	auipc	a2,0x3
ffffffffc0203b22:	86a60613          	addi	a2,a2,-1942 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203b26:	0cf00593          	li	a1,207
ffffffffc0203b2a:	00003517          	auipc	a0,0x3
ffffffffc0203b2e:	32e50513          	addi	a0,a0,814 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203b32:	95dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b36 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203b36:	1101                	addi	sp,sp,-32
ffffffffc0203b38:	ec06                	sd	ra,24(sp)
ffffffffc0203b3a:	e822                	sd	s0,16(sp)
ffffffffc0203b3c:	e426                	sd	s1,8(sp)
ffffffffc0203b3e:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203b40:	c531                	beqz	a0,ffffffffc0203b8c <exit_mmap+0x56>
ffffffffc0203b42:	591c                	lw	a5,48(a0)
ffffffffc0203b44:	84aa                	mv	s1,a0
ffffffffc0203b46:	e3b9                	bnez	a5,ffffffffc0203b8c <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203b48:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203b4a:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203b4e:	02850663          	beq	a0,s0,ffffffffc0203b7a <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203b52:	ff043603          	ld	a2,-16(s0)
ffffffffc0203b56:	fe843583          	ld	a1,-24(s0)
ffffffffc0203b5a:	854a                	mv	a0,s2
ffffffffc0203b5c:	905fe0ef          	jal	ra,ffffffffc0202460 <unmap_range>
ffffffffc0203b60:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203b62:	fe8498e3          	bne	s1,s0,ffffffffc0203b52 <exit_mmap+0x1c>
ffffffffc0203b66:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203b68:	00848c63          	beq	s1,s0,ffffffffc0203b80 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203b6c:	ff043603          	ld	a2,-16(s0)
ffffffffc0203b70:	fe843583          	ld	a1,-24(s0)
ffffffffc0203b74:	854a                	mv	a0,s2
ffffffffc0203b76:	a31fe0ef          	jal	ra,ffffffffc02025a6 <exit_range>
ffffffffc0203b7a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203b7c:	fe8498e3          	bne	s1,s0,ffffffffc0203b6c <exit_mmap+0x36>
    }
}
ffffffffc0203b80:	60e2                	ld	ra,24(sp)
ffffffffc0203b82:	6442                	ld	s0,16(sp)
ffffffffc0203b84:	64a2                	ld	s1,8(sp)
ffffffffc0203b86:	6902                	ld	s2,0(sp)
ffffffffc0203b88:	6105                	addi	sp,sp,32
ffffffffc0203b8a:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203b8c:	00003697          	auipc	a3,0x3
ffffffffc0203b90:	38468693          	addi	a3,a3,900 # ffffffffc0206f10 <default_pmm_manager+0x7d8>
ffffffffc0203b94:	00002617          	auipc	a2,0x2
ffffffffc0203b98:	7f460613          	addi	a2,a2,2036 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203b9c:	0e800593          	li	a1,232
ffffffffc0203ba0:	00003517          	auipc	a0,0x3
ffffffffc0203ba4:	2b850513          	addi	a0,a0,696 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203ba8:	8e7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203bac <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203bac:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203bae:	04000513          	li	a0,64
{
ffffffffc0203bb2:	fc06                	sd	ra,56(sp)
ffffffffc0203bb4:	f822                	sd	s0,48(sp)
ffffffffc0203bb6:	f426                	sd	s1,40(sp)
ffffffffc0203bb8:	f04a                	sd	s2,32(sp)
ffffffffc0203bba:	ec4e                	sd	s3,24(sp)
ffffffffc0203bbc:	e852                	sd	s4,16(sp)
ffffffffc0203bbe:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203bc0:	b8efe0ef          	jal	ra,ffffffffc0201f4e <kmalloc>
    if (mm != NULL)
ffffffffc0203bc4:	2e050663          	beqz	a0,ffffffffc0203eb0 <vmm_init+0x304>
ffffffffc0203bc8:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203bca:	e508                	sd	a0,8(a0)
ffffffffc0203bcc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203bce:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203bd2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203bd6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203bda:	02053423          	sd	zero,40(a0)
ffffffffc0203bde:	02052823          	sw	zero,48(a0)
ffffffffc0203be2:	02053c23          	sd	zero,56(a0)
ffffffffc0203be6:	03200413          	li	s0,50
ffffffffc0203bea:	a811                	j	ffffffffc0203bfe <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203bec:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203bee:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203bf0:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203bf4:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203bf6:	8526                	mv	a0,s1
ffffffffc0203bf8:	cd3ff0ef          	jal	ra,ffffffffc02038ca <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203bfc:	c80d                	beqz	s0,ffffffffc0203c2e <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203bfe:	03000513          	li	a0,48
ffffffffc0203c02:	b4cfe0ef          	jal	ra,ffffffffc0201f4e <kmalloc>
ffffffffc0203c06:	85aa                	mv	a1,a0
ffffffffc0203c08:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c0c:	f165                	bnez	a0,ffffffffc0203bec <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203c0e:	00003697          	auipc	a3,0x3
ffffffffc0203c12:	49a68693          	addi	a3,a3,1178 # ffffffffc02070a8 <default_pmm_manager+0x970>
ffffffffc0203c16:	00002617          	auipc	a2,0x2
ffffffffc0203c1a:	77260613          	addi	a2,a2,1906 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203c1e:	12c00593          	li	a1,300
ffffffffc0203c22:	00003517          	auipc	a0,0x3
ffffffffc0203c26:	23650513          	addi	a0,a0,566 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203c2a:	865fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203c2e:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c32:	1f900913          	li	s2,505
ffffffffc0203c36:	a819                	j	ffffffffc0203c4c <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203c38:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c3a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c3c:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c40:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203c42:	8526                	mv	a0,s1
ffffffffc0203c44:	c87ff0ef          	jal	ra,ffffffffc02038ca <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c48:	03240a63          	beq	s0,s2,ffffffffc0203c7c <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c4c:	03000513          	li	a0,48
ffffffffc0203c50:	afefe0ef          	jal	ra,ffffffffc0201f4e <kmalloc>
ffffffffc0203c54:	85aa                	mv	a1,a0
ffffffffc0203c56:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c5a:	fd79                	bnez	a0,ffffffffc0203c38 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203c5c:	00003697          	auipc	a3,0x3
ffffffffc0203c60:	44c68693          	addi	a3,a3,1100 # ffffffffc02070a8 <default_pmm_manager+0x970>
ffffffffc0203c64:	00002617          	auipc	a2,0x2
ffffffffc0203c68:	72460613          	addi	a2,a2,1828 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203c6c:	13300593          	li	a1,307
ffffffffc0203c70:	00003517          	auipc	a0,0x3
ffffffffc0203c74:	1e850513          	addi	a0,a0,488 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203c78:	817fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203c7c:	649c                	ld	a5,8(s1)
ffffffffc0203c7e:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203c80:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203c84:	16f48663          	beq	s1,a5,ffffffffc0203df0 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c88:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd2fb2c>
ffffffffc0203c8c:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8fa2>
ffffffffc0203c90:	10d61063          	bne	a2,a3,ffffffffc0203d90 <vmm_init+0x1e4>
ffffffffc0203c94:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203c98:	0ed71c63          	bne	a4,a3,ffffffffc0203d90 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203c9c:	0715                	addi	a4,a4,5
ffffffffc0203c9e:	679c                	ld	a5,8(a5)
ffffffffc0203ca0:	feb712e3          	bne	a4,a1,ffffffffc0203c84 <vmm_init+0xd8>
ffffffffc0203ca4:	4a1d                	li	s4,7
ffffffffc0203ca6:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203ca8:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203cac:	85a2                	mv	a1,s0
ffffffffc0203cae:	8526                	mv	a0,s1
ffffffffc0203cb0:	bdbff0ef          	jal	ra,ffffffffc020388a <find_vma>
ffffffffc0203cb4:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203cb6:	16050d63          	beqz	a0,ffffffffc0203e30 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203cba:	00140593          	addi	a1,s0,1
ffffffffc0203cbe:	8526                	mv	a0,s1
ffffffffc0203cc0:	bcbff0ef          	jal	ra,ffffffffc020388a <find_vma>
ffffffffc0203cc4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203cc6:	14050563          	beqz	a0,ffffffffc0203e10 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203cca:	85d2                	mv	a1,s4
ffffffffc0203ccc:	8526                	mv	a0,s1
ffffffffc0203cce:	bbdff0ef          	jal	ra,ffffffffc020388a <find_vma>
        assert(vma3 == NULL);
ffffffffc0203cd2:	16051f63          	bnez	a0,ffffffffc0203e50 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203cd6:	00340593          	addi	a1,s0,3
ffffffffc0203cda:	8526                	mv	a0,s1
ffffffffc0203cdc:	bafff0ef          	jal	ra,ffffffffc020388a <find_vma>
        assert(vma4 == NULL);
ffffffffc0203ce0:	1a051863          	bnez	a0,ffffffffc0203e90 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203ce4:	00440593          	addi	a1,s0,4
ffffffffc0203ce8:	8526                	mv	a0,s1
ffffffffc0203cea:	ba1ff0ef          	jal	ra,ffffffffc020388a <find_vma>
        assert(vma5 == NULL);
ffffffffc0203cee:	18051163          	bnez	a0,ffffffffc0203e70 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cf2:	00893783          	ld	a5,8(s2)
ffffffffc0203cf6:	0a879d63          	bne	a5,s0,ffffffffc0203db0 <vmm_init+0x204>
ffffffffc0203cfa:	01093783          	ld	a5,16(s2)
ffffffffc0203cfe:	0b479963          	bne	a5,s4,ffffffffc0203db0 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203d02:	0089b783          	ld	a5,8(s3)
ffffffffc0203d06:	0c879563          	bne	a5,s0,ffffffffc0203dd0 <vmm_init+0x224>
ffffffffc0203d0a:	0109b783          	ld	a5,16(s3)
ffffffffc0203d0e:	0d479163          	bne	a5,s4,ffffffffc0203dd0 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d12:	0415                	addi	s0,s0,5
ffffffffc0203d14:	0a15                	addi	s4,s4,5
ffffffffc0203d16:	f9541be3          	bne	s0,s5,ffffffffc0203cac <vmm_init+0x100>
ffffffffc0203d1a:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203d1c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203d1e:	85a2                	mv	a1,s0
ffffffffc0203d20:	8526                	mv	a0,s1
ffffffffc0203d22:	b69ff0ef          	jal	ra,ffffffffc020388a <find_vma>
ffffffffc0203d26:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203d2a:	c90d                	beqz	a0,ffffffffc0203d5c <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d2c:	6914                	ld	a3,16(a0)
ffffffffc0203d2e:	6510                	ld	a2,8(a0)
ffffffffc0203d30:	00003517          	auipc	a0,0x3
ffffffffc0203d34:	30050513          	addi	a0,a0,768 # ffffffffc0207030 <default_pmm_manager+0x8f8>
ffffffffc0203d38:	c5cfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203d3c:	00003697          	auipc	a3,0x3
ffffffffc0203d40:	31c68693          	addi	a3,a3,796 # ffffffffc0207058 <default_pmm_manager+0x920>
ffffffffc0203d44:	00002617          	auipc	a2,0x2
ffffffffc0203d48:	64460613          	addi	a2,a2,1604 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203d4c:	15900593          	li	a1,345
ffffffffc0203d50:	00003517          	auipc	a0,0x3
ffffffffc0203d54:	10850513          	addi	a0,a0,264 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203d58:	f36fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203d5c:	147d                	addi	s0,s0,-1
ffffffffc0203d5e:	fd2410e3          	bne	s0,s2,ffffffffc0203d1e <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203d62:	8526                	mv	a0,s1
ffffffffc0203d64:	c37ff0ef          	jal	ra,ffffffffc020399a <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203d68:	00003517          	auipc	a0,0x3
ffffffffc0203d6c:	30850513          	addi	a0,a0,776 # ffffffffc0207070 <default_pmm_manager+0x938>
ffffffffc0203d70:	c24fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203d74:	7442                	ld	s0,48(sp)
ffffffffc0203d76:	70e2                	ld	ra,56(sp)
ffffffffc0203d78:	74a2                	ld	s1,40(sp)
ffffffffc0203d7a:	7902                	ld	s2,32(sp)
ffffffffc0203d7c:	69e2                	ld	s3,24(sp)
ffffffffc0203d7e:	6a42                	ld	s4,16(sp)
ffffffffc0203d80:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d82:	00003517          	auipc	a0,0x3
ffffffffc0203d86:	30e50513          	addi	a0,a0,782 # ffffffffc0207090 <default_pmm_manager+0x958>
}
ffffffffc0203d8a:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d8c:	c08fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203d90:	00003697          	auipc	a3,0x3
ffffffffc0203d94:	1b868693          	addi	a3,a3,440 # ffffffffc0206f48 <default_pmm_manager+0x810>
ffffffffc0203d98:	00002617          	auipc	a2,0x2
ffffffffc0203d9c:	5f060613          	addi	a2,a2,1520 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203da0:	13d00593          	li	a1,317
ffffffffc0203da4:	00003517          	auipc	a0,0x3
ffffffffc0203da8:	0b450513          	addi	a0,a0,180 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203dac:	ee2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203db0:	00003697          	auipc	a3,0x3
ffffffffc0203db4:	22068693          	addi	a3,a3,544 # ffffffffc0206fd0 <default_pmm_manager+0x898>
ffffffffc0203db8:	00002617          	auipc	a2,0x2
ffffffffc0203dbc:	5d060613          	addi	a2,a2,1488 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203dc0:	14e00593          	li	a1,334
ffffffffc0203dc4:	00003517          	auipc	a0,0x3
ffffffffc0203dc8:	09450513          	addi	a0,a0,148 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203dcc:	ec2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203dd0:	00003697          	auipc	a3,0x3
ffffffffc0203dd4:	23068693          	addi	a3,a3,560 # ffffffffc0207000 <default_pmm_manager+0x8c8>
ffffffffc0203dd8:	00002617          	auipc	a2,0x2
ffffffffc0203ddc:	5b060613          	addi	a2,a2,1456 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203de0:	14f00593          	li	a1,335
ffffffffc0203de4:	00003517          	auipc	a0,0x3
ffffffffc0203de8:	07450513          	addi	a0,a0,116 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203dec:	ea2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203df0:	00003697          	auipc	a3,0x3
ffffffffc0203df4:	14068693          	addi	a3,a3,320 # ffffffffc0206f30 <default_pmm_manager+0x7f8>
ffffffffc0203df8:	00002617          	auipc	a2,0x2
ffffffffc0203dfc:	59060613          	addi	a2,a2,1424 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203e00:	13b00593          	li	a1,315
ffffffffc0203e04:	00003517          	auipc	a0,0x3
ffffffffc0203e08:	05450513          	addi	a0,a0,84 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203e0c:	e82fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203e10:	00003697          	auipc	a3,0x3
ffffffffc0203e14:	18068693          	addi	a3,a3,384 # ffffffffc0206f90 <default_pmm_manager+0x858>
ffffffffc0203e18:	00002617          	auipc	a2,0x2
ffffffffc0203e1c:	57060613          	addi	a2,a2,1392 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203e20:	14600593          	li	a1,326
ffffffffc0203e24:	00003517          	auipc	a0,0x3
ffffffffc0203e28:	03450513          	addi	a0,a0,52 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203e2c:	e62fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203e30:	00003697          	auipc	a3,0x3
ffffffffc0203e34:	15068693          	addi	a3,a3,336 # ffffffffc0206f80 <default_pmm_manager+0x848>
ffffffffc0203e38:	00002617          	auipc	a2,0x2
ffffffffc0203e3c:	55060613          	addi	a2,a2,1360 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203e40:	14400593          	li	a1,324
ffffffffc0203e44:	00003517          	auipc	a0,0x3
ffffffffc0203e48:	01450513          	addi	a0,a0,20 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203e4c:	e42fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203e50:	00003697          	auipc	a3,0x3
ffffffffc0203e54:	15068693          	addi	a3,a3,336 # ffffffffc0206fa0 <default_pmm_manager+0x868>
ffffffffc0203e58:	00002617          	auipc	a2,0x2
ffffffffc0203e5c:	53060613          	addi	a2,a2,1328 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203e60:	14800593          	li	a1,328
ffffffffc0203e64:	00003517          	auipc	a0,0x3
ffffffffc0203e68:	ff450513          	addi	a0,a0,-12 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203e6c:	e22fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203e70:	00003697          	auipc	a3,0x3
ffffffffc0203e74:	15068693          	addi	a3,a3,336 # ffffffffc0206fc0 <default_pmm_manager+0x888>
ffffffffc0203e78:	00002617          	auipc	a2,0x2
ffffffffc0203e7c:	51060613          	addi	a2,a2,1296 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203e80:	14c00593          	li	a1,332
ffffffffc0203e84:	00003517          	auipc	a0,0x3
ffffffffc0203e88:	fd450513          	addi	a0,a0,-44 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203e8c:	e02fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203e90:	00003697          	auipc	a3,0x3
ffffffffc0203e94:	12068693          	addi	a3,a3,288 # ffffffffc0206fb0 <default_pmm_manager+0x878>
ffffffffc0203e98:	00002617          	auipc	a2,0x2
ffffffffc0203e9c:	4f060613          	addi	a2,a2,1264 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203ea0:	14a00593          	li	a1,330
ffffffffc0203ea4:	00003517          	auipc	a0,0x3
ffffffffc0203ea8:	fb450513          	addi	a0,a0,-76 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203eac:	de2fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203eb0:	00003697          	auipc	a3,0x3
ffffffffc0203eb4:	03068693          	addi	a3,a3,48 # ffffffffc0206ee0 <default_pmm_manager+0x7a8>
ffffffffc0203eb8:	00002617          	auipc	a2,0x2
ffffffffc0203ebc:	4d060613          	addi	a2,a2,1232 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0203ec0:	12400593          	li	a1,292
ffffffffc0203ec4:	00003517          	auipc	a0,0x3
ffffffffc0203ec8:	f9450513          	addi	a0,a0,-108 # ffffffffc0206e58 <default_pmm_manager+0x720>
ffffffffc0203ecc:	dc2fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ed0 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203ed0:	7179                	addi	sp,sp,-48
ffffffffc0203ed2:	f022                	sd	s0,32(sp)
ffffffffc0203ed4:	f406                	sd	ra,40(sp)
ffffffffc0203ed6:	ec26                	sd	s1,24(sp)
ffffffffc0203ed8:	e84a                	sd	s2,16(sp)
ffffffffc0203eda:	e44e                	sd	s3,8(sp)
ffffffffc0203edc:	e052                	sd	s4,0(sp)
ffffffffc0203ede:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203ee0:	c135                	beqz	a0,ffffffffc0203f44 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203ee2:	002007b7          	lui	a5,0x200
ffffffffc0203ee6:	04f5e663          	bltu	a1,a5,ffffffffc0203f32 <user_mem_check+0x62>
ffffffffc0203eea:	00c584b3          	add	s1,a1,a2
ffffffffc0203eee:	0495f263          	bgeu	a1,s1,ffffffffc0203f32 <user_mem_check+0x62>
ffffffffc0203ef2:	4785                	li	a5,1
ffffffffc0203ef4:	07fe                	slli	a5,a5,0x1f
ffffffffc0203ef6:	0297ee63          	bltu	a5,s1,ffffffffc0203f32 <user_mem_check+0x62>
ffffffffc0203efa:	892a                	mv	s2,a0
ffffffffc0203efc:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203efe:	6a05                	lui	s4,0x1
ffffffffc0203f00:	a821                	j	ffffffffc0203f18 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f02:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f06:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f08:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f0a:	c685                	beqz	a3,ffffffffc0203f32 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f0c:	c399                	beqz	a5,ffffffffc0203f12 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f0e:	02e46263          	bltu	s0,a4,ffffffffc0203f32 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203f12:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203f14:	04947663          	bgeu	s0,s1,ffffffffc0203f60 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f18:	85a2                	mv	a1,s0
ffffffffc0203f1a:	854a                	mv	a0,s2
ffffffffc0203f1c:	96fff0ef          	jal	ra,ffffffffc020388a <find_vma>
ffffffffc0203f20:	c909                	beqz	a0,ffffffffc0203f32 <user_mem_check+0x62>
ffffffffc0203f22:	6518                	ld	a4,8(a0)
ffffffffc0203f24:	00e46763          	bltu	s0,a4,ffffffffc0203f32 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f28:	4d1c                	lw	a5,24(a0)
ffffffffc0203f2a:	fc099ce3          	bnez	s3,ffffffffc0203f02 <user_mem_check+0x32>
ffffffffc0203f2e:	8b85                	andi	a5,a5,1
ffffffffc0203f30:	f3ed                	bnez	a5,ffffffffc0203f12 <user_mem_check+0x42>
            return 0;
ffffffffc0203f32:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f34:	70a2                	ld	ra,40(sp)
ffffffffc0203f36:	7402                	ld	s0,32(sp)
ffffffffc0203f38:	64e2                	ld	s1,24(sp)
ffffffffc0203f3a:	6942                	ld	s2,16(sp)
ffffffffc0203f3c:	69a2                	ld	s3,8(sp)
ffffffffc0203f3e:	6a02                	ld	s4,0(sp)
ffffffffc0203f40:	6145                	addi	sp,sp,48
ffffffffc0203f42:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f44:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f48:	4501                	li	a0,0
ffffffffc0203f4a:	fef5e5e3          	bltu	a1,a5,ffffffffc0203f34 <user_mem_check+0x64>
ffffffffc0203f4e:	962e                	add	a2,a2,a1
ffffffffc0203f50:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203f34 <user_mem_check+0x64>
ffffffffc0203f54:	c8000537          	lui	a0,0xc8000
ffffffffc0203f58:	0505                	addi	a0,a0,1
ffffffffc0203f5a:	00a63533          	sltu	a0,a2,a0
ffffffffc0203f5e:	bfd9                	j	ffffffffc0203f34 <user_mem_check+0x64>
        return 1;
ffffffffc0203f60:	4505                	li	a0,1
ffffffffc0203f62:	bfc9                	j	ffffffffc0203f34 <user_mem_check+0x64>

ffffffffc0203f64 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203f64:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203f66:	9402                	jalr	s0

	jal do_exit
ffffffffc0203f68:	5ee000ef          	jal	ra,ffffffffc0204556 <do_exit>

ffffffffc0203f6c <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203f6c:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f6e:	10800513          	li	a0,264
{
ffffffffc0203f72:	e022                	sd	s0,0(sp)
ffffffffc0203f74:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f76:	fd9fd0ef          	jal	ra,ffffffffc0201f4e <kmalloc>
ffffffffc0203f7a:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203f7c:	cd05                	beqz	a0,ffffffffc0203fb4 <alloc_proc+0x48>
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
         //先把整个结构体清零,后面的context和name就不需要单独考虑了，
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc0203f7e:	10800613          	li	a2,264
ffffffffc0203f82:	4581                	li	a1,0
ffffffffc0203f84:	09f010ef          	jal	ra,ffffffffc0205822 <memset>

        //再显式设置必须的初值 
        proc->state         = PROC_UNINIT;   
ffffffffc0203f88:	57fd                	li	a5,-1
ffffffffc0203f8a:	1782                	slli	a5,a5,0x20
ffffffffc0203f8c:	e01c                	sd	a5,0(s0)
        proc->kstack        = 0;
        proc->need_resched  = 0;
        proc->parent        = NULL;
        proc->mm            = NULL;
        proc->tf            = NULL;
        proc->pgdir         = boot_pgdir_pa;  // 设置为 boot_pgdir_pa 而非 0
ffffffffc0203f8e:	000cb797          	auipc	a5,0xcb
ffffffffc0203f92:	4e27b783          	ld	a5,1250(a5) # ffffffffc02cf470 <boot_pgdir_pa>
        proc->runs          = 0;
ffffffffc0203f96:	00042423          	sw	zero,8(s0)
        proc->kstack        = 0;
ffffffffc0203f9a:	00043823          	sd	zero,16(s0)
        proc->need_resched  = 0;
ffffffffc0203f9e:	00043c23          	sd	zero,24(s0)
        proc->parent        = NULL;
ffffffffc0203fa2:	02043023          	sd	zero,32(s0)
        proc->mm            = NULL;
ffffffffc0203fa6:	02043423          	sd	zero,40(s0)
        proc->tf            = NULL;
ffffffffc0203faa:	0a043023          	sd	zero,160(s0)
        proc->pgdir         = boot_pgdir_pa;  // 设置为 boot_pgdir_pa 而非 0
ffffffffc0203fae:	f45c                	sd	a5,168(s0)
        proc->flags         = 0;
ffffffffc0203fb0:	0a042823          	sw	zero,176(s0)
    }
    return proc;
}
ffffffffc0203fb4:	60a2                	ld	ra,8(sp)
ffffffffc0203fb6:	8522                	mv	a0,s0
ffffffffc0203fb8:	6402                	ld	s0,0(sp)
ffffffffc0203fba:	0141                	addi	sp,sp,16
ffffffffc0203fbc:	8082                	ret

ffffffffc0203fbe <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203fbe:	000cb797          	auipc	a5,0xcb
ffffffffc0203fc2:	4e27b783          	ld	a5,1250(a5) # ffffffffc02cf4a0 <current>
ffffffffc0203fc6:	73c8                	ld	a0,160(a5)
ffffffffc0203fc8:	9fafd06f          	j	ffffffffc02011c2 <forkrets>

ffffffffc0203fcc <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203fcc:	000cb797          	auipc	a5,0xcb
ffffffffc0203fd0:	4d47b783          	ld	a5,1236(a5) # ffffffffc02cf4a0 <current>
ffffffffc0203fd4:	43cc                	lw	a1,4(a5)
{
ffffffffc0203fd6:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203fd8:	00003617          	auipc	a2,0x3
ffffffffc0203fdc:	0e060613          	addi	a2,a2,224 # ffffffffc02070b8 <default_pmm_manager+0x980>
ffffffffc0203fe0:	00003517          	auipc	a0,0x3
ffffffffc0203fe4:	0e850513          	addi	a0,a0,232 # ffffffffc02070c8 <default_pmm_manager+0x990>
{
ffffffffc0203fe8:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203fea:	9aafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203fee:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0203ff2:	b4278793          	addi	a5,a5,-1214 # ab30 <_binary_obj___user_dirtycow_test_out_size>
ffffffffc0203ff6:	e43e                	sd	a5,8(sp)
ffffffffc0203ff8:	00003517          	auipc	a0,0x3
ffffffffc0203ffc:	0c050513          	addi	a0,a0,192 # ffffffffc02070b8 <default_pmm_manager+0x980>
ffffffffc0204000:	00033797          	auipc	a5,0x33
ffffffffc0204004:	e6878793          	addi	a5,a5,-408 # ffffffffc0236e68 <_binary_obj___user_dirtycow_test_out_start>
ffffffffc0204008:	f03e                	sd	a5,32(sp)
ffffffffc020400a:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc020400c:	e802                	sd	zero,16(sp)
ffffffffc020400e:	772010ef          	jal	ra,ffffffffc0205780 <strlen>
ffffffffc0204012:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204014:	4511                	li	a0,4
ffffffffc0204016:	55a2                	lw	a1,40(sp)
ffffffffc0204018:	4662                	lw	a2,24(sp)
ffffffffc020401a:	5682                	lw	a3,32(sp)
ffffffffc020401c:	4722                	lw	a4,8(sp)
ffffffffc020401e:	48a9                	li	a7,10
ffffffffc0204020:	9002                	ebreak
ffffffffc0204022:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204024:	65c2                	ld	a1,16(sp)
ffffffffc0204026:	00003517          	auipc	a0,0x3
ffffffffc020402a:	0ca50513          	addi	a0,a0,202 # ffffffffc02070f0 <default_pmm_manager+0x9b8>
ffffffffc020402e:	966fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204032:	00003617          	auipc	a2,0x3
ffffffffc0204036:	0ce60613          	addi	a2,a2,206 # ffffffffc0207100 <default_pmm_manager+0x9c8>
ffffffffc020403a:	3c000593          	li	a1,960
ffffffffc020403e:	00003517          	auipc	a0,0x3
ffffffffc0204042:	0e250513          	addi	a0,a0,226 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204046:	c48fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020404a <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc020404a:	6d14                	ld	a3,24(a0)
{
ffffffffc020404c:	1141                	addi	sp,sp,-16
ffffffffc020404e:	e406                	sd	ra,8(sp)
ffffffffc0204050:	c02007b7          	lui	a5,0xc0200
ffffffffc0204054:	02f6ee63          	bltu	a3,a5,ffffffffc0204090 <put_pgdir+0x46>
ffffffffc0204058:	000cb517          	auipc	a0,0xcb
ffffffffc020405c:	44053503          	ld	a0,1088(a0) # ffffffffc02cf498 <va_pa_offset>
ffffffffc0204060:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0204062:	82b1                	srli	a3,a3,0xc
ffffffffc0204064:	000cb797          	auipc	a5,0xcb
ffffffffc0204068:	41c7b783          	ld	a5,1052(a5) # ffffffffc02cf480 <npage>
ffffffffc020406c:	02f6fe63          	bgeu	a3,a5,ffffffffc02040a8 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204070:	00004517          	auipc	a0,0x4
ffffffffc0204074:	94853503          	ld	a0,-1720(a0) # ffffffffc02079b8 <nbase>
}
ffffffffc0204078:	60a2                	ld	ra,8(sp)
ffffffffc020407a:	8e89                	sub	a3,a3,a0
ffffffffc020407c:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc020407e:	000cb517          	auipc	a0,0xcb
ffffffffc0204082:	40a53503          	ld	a0,1034(a0) # ffffffffc02cf488 <pages>
ffffffffc0204086:	4585                	li	a1,1
ffffffffc0204088:	9536                	add	a0,a0,a3
}
ffffffffc020408a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc020408c:	8defe06f          	j	ffffffffc020216a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204090:	00002617          	auipc	a2,0x2
ffffffffc0204094:	75060613          	addi	a2,a2,1872 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc0204098:	07700593          	li	a1,119
ffffffffc020409c:	00002517          	auipc	a0,0x2
ffffffffc02040a0:	fd450513          	addi	a0,a0,-44 # ffffffffc0206070 <commands+0x5b8>
ffffffffc02040a4:	beafc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02040a8:	00002617          	auipc	a2,0x2
ffffffffc02040ac:	fa860613          	addi	a2,a2,-88 # ffffffffc0206050 <commands+0x598>
ffffffffc02040b0:	06900593          	li	a1,105
ffffffffc02040b4:	00002517          	auipc	a0,0x2
ffffffffc02040b8:	fbc50513          	addi	a0,a0,-68 # ffffffffc0206070 <commands+0x5b8>
ffffffffc02040bc:	bd2fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040c0 <proc_run>:
{
ffffffffc02040c0:	7179                	addi	sp,sp,-48
ffffffffc02040c2:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02040c4:	000cb497          	auipc	s1,0xcb
ffffffffc02040c8:	3dc48493          	addi	s1,s1,988 # ffffffffc02cf4a0 <current>
ffffffffc02040cc:	6098                	ld	a4,0(s1)
{
ffffffffc02040ce:	f406                	sd	ra,40(sp)
ffffffffc02040d0:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02040d2:	02a70963          	beq	a4,a0,ffffffffc0204104 <proc_run+0x44>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040d6:	100027f3          	csrr	a5,sstatus
ffffffffc02040da:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040dc:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040de:	ef95                	bnez	a5,ffffffffc020411a <proc_run+0x5a>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc02040e0:	755c                	ld	a5,168(a0)
ffffffffc02040e2:	56fd                	li	a3,-1
ffffffffc02040e4:	16fe                	slli	a3,a3,0x3f
ffffffffc02040e6:	83b1                	srli	a5,a5,0xc
        current = proc;
ffffffffc02040e8:	e088                	sd	a0,0(s1)
        proc->need_resched = 0;
ffffffffc02040ea:	00053c23          	sd	zero,24(a0)
ffffffffc02040ee:	8fd5                	or	a5,a5,a3
ffffffffc02040f0:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &proc->context);
ffffffffc02040f4:	03050593          	addi	a1,a0,48
ffffffffc02040f8:	03070513          	addi	a0,a4,48
ffffffffc02040fc:	02a010ef          	jal	ra,ffffffffc0205126 <switch_to>
    if (flag)
ffffffffc0204100:	00091763          	bnez	s2,ffffffffc020410e <proc_run+0x4e>
}
ffffffffc0204104:	70a2                	ld	ra,40(sp)
ffffffffc0204106:	7482                	ld	s1,32(sp)
ffffffffc0204108:	6962                	ld	s2,24(sp)
ffffffffc020410a:	6145                	addi	sp,sp,48
ffffffffc020410c:	8082                	ret
ffffffffc020410e:	70a2                	ld	ra,40(sp)
ffffffffc0204110:	7482                	ld	s1,32(sp)
ffffffffc0204112:	6962                	ld	s2,24(sp)
ffffffffc0204114:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204116:	899fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc020411a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020411c:	899fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc0204120:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0204122:	6522                	ld	a0,8(sp)
ffffffffc0204124:	4905                	li	s2,1
ffffffffc0204126:	bf6d                	j	ffffffffc02040e0 <proc_run+0x20>

ffffffffc0204128 <do_fork>:
{
ffffffffc0204128:	7119                	addi	sp,sp,-128
ffffffffc020412a:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020412c:	000cb917          	auipc	s2,0xcb
ffffffffc0204130:	38c90913          	addi	s2,s2,908 # ffffffffc02cf4b8 <nr_process>
ffffffffc0204134:	00092703          	lw	a4,0(s2)
{
ffffffffc0204138:	fc86                	sd	ra,120(sp)
ffffffffc020413a:	f8a2                	sd	s0,112(sp)
ffffffffc020413c:	f4a6                	sd	s1,104(sp)
ffffffffc020413e:	ecce                	sd	s3,88(sp)
ffffffffc0204140:	e8d2                	sd	s4,80(sp)
ffffffffc0204142:	e4d6                	sd	s5,72(sp)
ffffffffc0204144:	e0da                	sd	s6,64(sp)
ffffffffc0204146:	fc5e                	sd	s7,56(sp)
ffffffffc0204148:	f862                	sd	s8,48(sp)
ffffffffc020414a:	f466                	sd	s9,40(sp)
ffffffffc020414c:	f06a                	sd	s10,32(sp)
ffffffffc020414e:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204150:	6785                	lui	a5,0x1
ffffffffc0204152:	32f75863          	bge	a4,a5,ffffffffc0204482 <do_fork+0x35a>
ffffffffc0204156:	8a2a                	mv	s4,a0
ffffffffc0204158:	89ae                	mv	s3,a1
ffffffffc020415a:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020415c:	e11ff0ef          	jal	ra,ffffffffc0203f6c <alloc_proc>
ffffffffc0204160:	84aa                	mv	s1,a0
ffffffffc0204162:	30050163          	beqz	a0,ffffffffc0204464 <do_fork+0x33c>
    proc->parent = current;
ffffffffc0204166:	000cbc17          	auipc	s8,0xcb
ffffffffc020416a:	33ac0c13          	addi	s8,s8,826 # ffffffffc02cf4a0 <current>
ffffffffc020416e:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204172:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0204174:	f09c                	sd	a5,32(s1)
    current->wait_state = 0;
ffffffffc0204176:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8eb4>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020417a:	fb3fd0ef          	jal	ra,ffffffffc020212c <alloc_pages>
    if (page != NULL)
ffffffffc020417e:	2e050063          	beqz	a0,ffffffffc020445e <do_fork+0x336>
    return page - pages + nbase;
ffffffffc0204182:	000cba97          	auipc	s5,0xcb
ffffffffc0204186:	306a8a93          	addi	s5,s5,774 # ffffffffc02cf488 <pages>
ffffffffc020418a:	000ab683          	ld	a3,0(s5)
ffffffffc020418e:	00004b17          	auipc	s6,0x4
ffffffffc0204192:	82ab0b13          	addi	s6,s6,-2006 # ffffffffc02079b8 <nbase>
ffffffffc0204196:	000b3783          	ld	a5,0(s6)
ffffffffc020419a:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc020419e:	000cbb97          	auipc	s7,0xcb
ffffffffc02041a2:	2e2b8b93          	addi	s7,s7,738 # ffffffffc02cf480 <npage>
    return page - pages + nbase;
ffffffffc02041a6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02041a8:	5dfd                	li	s11,-1
ffffffffc02041aa:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02041ae:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02041b0:	00cddd93          	srli	s11,s11,0xc
ffffffffc02041b4:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02041b8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041ba:	32e67a63          	bgeu	a2,a4,ffffffffc02044ee <do_fork+0x3c6>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02041be:	000c3603          	ld	a2,0(s8)
ffffffffc02041c2:	000cbc17          	auipc	s8,0xcb
ffffffffc02041c6:	2d6c0c13          	addi	s8,s8,726 # ffffffffc02cf498 <va_pa_offset>
ffffffffc02041ca:	000c3703          	ld	a4,0(s8)
ffffffffc02041ce:	02863d03          	ld	s10,40(a2)
ffffffffc02041d2:	e43e                	sd	a5,8(sp)
ffffffffc02041d4:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02041d6:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02041d8:	020d0863          	beqz	s10,ffffffffc0204208 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc02041dc:	100a7a13          	andi	s4,s4,256
ffffffffc02041e0:	1c0a0163          	beqz	s4,ffffffffc02043a2 <do_fork+0x27a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02041e4:	030d2703          	lw	a4,48(s10) # 200030 <_binary_obj___user_cowtest_out_size+0x1f4af8>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02041e8:	018d3783          	ld	a5,24(s10)
ffffffffc02041ec:	c02006b7          	lui	a3,0xc0200
ffffffffc02041f0:	2705                	addiw	a4,a4,1
ffffffffc02041f2:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc02041f6:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02041fa:	2cd7e163          	bltu	a5,a3,ffffffffc02044bc <do_fork+0x394>
ffffffffc02041fe:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204202:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204204:	8f99                	sub	a5,a5,a4
ffffffffc0204206:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204208:	6789                	lui	a5,0x2
ffffffffc020420a:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x80c0>
ffffffffc020420e:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204210:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204212:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204214:	87b6                	mv	a5,a3
ffffffffc0204216:	12040893          	addi	a7,s0,288
ffffffffc020421a:	00063803          	ld	a6,0(a2)
ffffffffc020421e:	6608                	ld	a0,8(a2)
ffffffffc0204220:	6a0c                	ld	a1,16(a2)
ffffffffc0204222:	6e18                	ld	a4,24(a2)
ffffffffc0204224:	0107b023          	sd	a6,0(a5)
ffffffffc0204228:	e788                	sd	a0,8(a5)
ffffffffc020422a:	eb8c                	sd	a1,16(a5)
ffffffffc020422c:	ef98                	sd	a4,24(a5)
ffffffffc020422e:	02060613          	addi	a2,a2,32
ffffffffc0204232:	02078793          	addi	a5,a5,32
ffffffffc0204236:	ff1612e3          	bne	a2,a7,ffffffffc020421a <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc020423a:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020423e:	12098f63          	beqz	s3,ffffffffc020437c <do_fork+0x254>
ffffffffc0204242:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204246:	00000797          	auipc	a5,0x0
ffffffffc020424a:	d7878793          	addi	a5,a5,-648 # ffffffffc0203fbe <forkret>
ffffffffc020424e:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204250:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204252:	100027f3          	csrr	a5,sstatus
ffffffffc0204256:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204258:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020425a:	14079063          	bnez	a5,ffffffffc020439a <do_fork+0x272>
    if (++last_pid >= MAX_PID)
ffffffffc020425e:	000c7817          	auipc	a6,0xc7
ffffffffc0204262:	db280813          	addi	a6,a6,-590 # ffffffffc02cb010 <last_pid.1>
ffffffffc0204266:	00082783          	lw	a5,0(a6)
ffffffffc020426a:	6709                	lui	a4,0x2
ffffffffc020426c:	0017851b          	addiw	a0,a5,1
ffffffffc0204270:	00a82023          	sw	a0,0(a6)
ffffffffc0204274:	08e55d63          	bge	a0,a4,ffffffffc020430e <do_fork+0x1e6>
    if (last_pid >= next_safe)
ffffffffc0204278:	000c7317          	auipc	t1,0xc7
ffffffffc020427c:	d9c30313          	addi	t1,t1,-612 # ffffffffc02cb014 <next_safe.0>
ffffffffc0204280:	00032783          	lw	a5,0(t1)
ffffffffc0204284:	000cb417          	auipc	s0,0xcb
ffffffffc0204288:	1ac40413          	addi	s0,s0,428 # ffffffffc02cf430 <proc_list>
ffffffffc020428c:	08f55963          	bge	a0,a5,ffffffffc020431e <do_fork+0x1f6>
        proc->pid = get_pid();
ffffffffc0204290:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204292:	45a9                	li	a1,10
ffffffffc0204294:	2501                	sext.w	a0,a0
ffffffffc0204296:	0e6010ef          	jal	ra,ffffffffc020537c <hash32>
ffffffffc020429a:	02051793          	slli	a5,a0,0x20
ffffffffc020429e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02042a2:	000c7797          	auipc	a5,0xc7
ffffffffc02042a6:	18e78793          	addi	a5,a5,398 # ffffffffc02cb430 <hash_list>
ffffffffc02042aa:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02042ac:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042ae:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042b0:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02042b4:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02042b6:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02042b8:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042ba:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02042bc:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02042c0:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02042c2:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02042c4:	e21c                	sd	a5,0(a2)
ffffffffc02042c6:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02042c8:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02042ca:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02042cc:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042d0:	10e4b023          	sd	a4,256(s1)
ffffffffc02042d4:	c311                	beqz	a4,ffffffffc02042d8 <do_fork+0x1b0>
        proc->optr->yptr = proc;
ffffffffc02042d6:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02042d8:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc02042dc:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02042de:	2785                	addiw	a5,a5,1
ffffffffc02042e0:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc02042e4:	18099263          	bnez	s3,ffffffffc0204468 <do_fork+0x340>
    wakeup_proc(proc);
ffffffffc02042e8:	8526                	mv	a0,s1
ffffffffc02042ea:	6a7000ef          	jal	ra,ffffffffc0205190 <wakeup_proc>
    ret = proc->pid;
ffffffffc02042ee:	40c8                	lw	a0,4(s1)
}
ffffffffc02042f0:	70e6                	ld	ra,120(sp)
ffffffffc02042f2:	7446                	ld	s0,112(sp)
ffffffffc02042f4:	74a6                	ld	s1,104(sp)
ffffffffc02042f6:	7906                	ld	s2,96(sp)
ffffffffc02042f8:	69e6                	ld	s3,88(sp)
ffffffffc02042fa:	6a46                	ld	s4,80(sp)
ffffffffc02042fc:	6aa6                	ld	s5,72(sp)
ffffffffc02042fe:	6b06                	ld	s6,64(sp)
ffffffffc0204300:	7be2                	ld	s7,56(sp)
ffffffffc0204302:	7c42                	ld	s8,48(sp)
ffffffffc0204304:	7ca2                	ld	s9,40(sp)
ffffffffc0204306:	7d02                	ld	s10,32(sp)
ffffffffc0204308:	6de2                	ld	s11,24(sp)
ffffffffc020430a:	6109                	addi	sp,sp,128
ffffffffc020430c:	8082                	ret
        last_pid = 1;
ffffffffc020430e:	4785                	li	a5,1
ffffffffc0204310:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204314:	4505                	li	a0,1
ffffffffc0204316:	000c7317          	auipc	t1,0xc7
ffffffffc020431a:	cfe30313          	addi	t1,t1,-770 # ffffffffc02cb014 <next_safe.0>
    return listelm->next;
ffffffffc020431e:	000cb417          	auipc	s0,0xcb
ffffffffc0204322:	11240413          	addi	s0,s0,274 # ffffffffc02cf430 <proc_list>
ffffffffc0204326:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020432a:	6789                	lui	a5,0x2
ffffffffc020432c:	00f32023          	sw	a5,0(t1)
ffffffffc0204330:	86aa                	mv	a3,a0
ffffffffc0204332:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204334:	6e89                	lui	t4,0x2
ffffffffc0204336:	148e0163          	beq	t3,s0,ffffffffc0204478 <do_fork+0x350>
ffffffffc020433a:	88ae                	mv	a7,a1
ffffffffc020433c:	87f2                	mv	a5,t3
ffffffffc020433e:	6609                	lui	a2,0x2
ffffffffc0204340:	a811                	j	ffffffffc0204354 <do_fork+0x22c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204342:	00e6d663          	bge	a3,a4,ffffffffc020434e <do_fork+0x226>
ffffffffc0204346:	00c75463          	bge	a4,a2,ffffffffc020434e <do_fork+0x226>
ffffffffc020434a:	863a                	mv	a2,a4
ffffffffc020434c:	4885                	li	a7,1
ffffffffc020434e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204350:	00878d63          	beq	a5,s0,ffffffffc020436a <do_fork+0x242>
            if (proc->pid == last_pid)
ffffffffc0204354:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x8064>
ffffffffc0204358:	fed715e3          	bne	a4,a3,ffffffffc0204342 <do_fork+0x21a>
                if (++last_pid >= next_safe)
ffffffffc020435c:	2685                	addiw	a3,a3,1
ffffffffc020435e:	10c6d863          	bge	a3,a2,ffffffffc020446e <do_fork+0x346>
ffffffffc0204362:	679c                	ld	a5,8(a5)
ffffffffc0204364:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204366:	fe8797e3          	bne	a5,s0,ffffffffc0204354 <do_fork+0x22c>
ffffffffc020436a:	c581                	beqz	a1,ffffffffc0204372 <do_fork+0x24a>
ffffffffc020436c:	00d82023          	sw	a3,0(a6)
ffffffffc0204370:	8536                	mv	a0,a3
ffffffffc0204372:	f0088fe3          	beqz	a7,ffffffffc0204290 <do_fork+0x168>
ffffffffc0204376:	00c32023          	sw	a2,0(t1)
ffffffffc020437a:	bf19                	j	ffffffffc0204290 <do_fork+0x168>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020437c:	89b6                	mv	s3,a3
ffffffffc020437e:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204382:	00000797          	auipc	a5,0x0
ffffffffc0204386:	c3c78793          	addi	a5,a5,-964 # ffffffffc0203fbe <forkret>
ffffffffc020438a:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020438c:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020438e:	100027f3          	csrr	a5,sstatus
ffffffffc0204392:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204394:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204396:	ec0784e3          	beqz	a5,ffffffffc020425e <do_fork+0x136>
        intr_disable();
ffffffffc020439a:	e1afc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020439e:	4985                	li	s3,1
ffffffffc02043a0:	bd7d                	j	ffffffffc020425e <do_fork+0x136>
    if ((mm = mm_create()) == NULL)
ffffffffc02043a2:	cb8ff0ef          	jal	ra,ffffffffc020385a <mm_create>
ffffffffc02043a6:	8caa                	mv	s9,a0
ffffffffc02043a8:	c159                	beqz	a0,ffffffffc020442e <do_fork+0x306>
    if ((page = alloc_page()) == NULL)
ffffffffc02043aa:	4505                	li	a0,1
ffffffffc02043ac:	d81fd0ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc02043b0:	cd25                	beqz	a0,ffffffffc0204428 <do_fork+0x300>
    return page - pages + nbase;
ffffffffc02043b2:	000ab683          	ld	a3,0(s5)
ffffffffc02043b6:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02043b8:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02043bc:	40d506b3          	sub	a3,a0,a3
ffffffffc02043c0:	8699                	srai	a3,a3,0x6
ffffffffc02043c2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02043c4:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02043c8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02043ca:	12edf263          	bgeu	s11,a4,ffffffffc02044ee <do_fork+0x3c6>
ffffffffc02043ce:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02043d2:	6605                	lui	a2,0x1
ffffffffc02043d4:	000cb597          	auipc	a1,0xcb
ffffffffc02043d8:	0a45b583          	ld	a1,164(a1) # ffffffffc02cf478 <boot_pgdir_va>
ffffffffc02043dc:	9a36                	add	s4,s4,a3
ffffffffc02043de:	8552                	mv	a0,s4
ffffffffc02043e0:	454010ef          	jal	ra,ffffffffc0205834 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02043e4:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc02043e8:	014cbc23          	sd	s4,24(s9) # ffffffffffe00018 <end+0x3fb30b5c>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02043ec:	4785                	li	a5,1
ffffffffc02043ee:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02043f2:	8b85                	andi	a5,a5,1
ffffffffc02043f4:	4a05                	li	s4,1
ffffffffc02043f6:	c799                	beqz	a5,ffffffffc0204404 <do_fork+0x2dc>
    {
        schedule();
ffffffffc02043f8:	619000ef          	jal	ra,ffffffffc0205210 <schedule>
ffffffffc02043fc:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc0204400:	8b85                	andi	a5,a5,1
ffffffffc0204402:	fbfd                	bnez	a5,ffffffffc02043f8 <do_fork+0x2d0>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204404:	85ea                	mv	a1,s10
ffffffffc0204406:	8566                	mv	a0,s9
ffffffffc0204408:	e94ff0ef          	jal	ra,ffffffffc0203a9c <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020440c:	57f9                	li	a5,-2
ffffffffc020440e:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204412:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204414:	cfa5                	beqz	a5,ffffffffc020448c <do_fork+0x364>
good_mm:
ffffffffc0204416:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204418:	dc0506e3          	beqz	a0,ffffffffc02041e4 <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc020441c:	8566                	mv	a0,s9
ffffffffc020441e:	f18ff0ef          	jal	ra,ffffffffc0203b36 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204422:	8566                	mv	a0,s9
ffffffffc0204424:	c27ff0ef          	jal	ra,ffffffffc020404a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204428:	8566                	mv	a0,s9
ffffffffc020442a:	d70ff0ef          	jal	ra,ffffffffc020399a <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020442e:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204430:	c02007b7          	lui	a5,0xc0200
ffffffffc0204434:	0af6e163          	bltu	a3,a5,ffffffffc02044d6 <do_fork+0x3ae>
ffffffffc0204438:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc020443c:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0204440:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204444:	83b1                	srli	a5,a5,0xc
ffffffffc0204446:	04e7ff63          	bgeu	a5,a4,ffffffffc02044a4 <do_fork+0x37c>
    return &pages[PPN(pa) - nbase];
ffffffffc020444a:	000b3703          	ld	a4,0(s6)
ffffffffc020444e:	000ab503          	ld	a0,0(s5)
ffffffffc0204452:	4589                	li	a1,2
ffffffffc0204454:	8f99                	sub	a5,a5,a4
ffffffffc0204456:	079a                	slli	a5,a5,0x6
ffffffffc0204458:	953e                	add	a0,a0,a5
ffffffffc020445a:	d11fd0ef          	jal	ra,ffffffffc020216a <free_pages>
    kfree(proc);
ffffffffc020445e:	8526                	mv	a0,s1
ffffffffc0204460:	b9ffd0ef          	jal	ra,ffffffffc0201ffe <kfree>
    ret = -E_NO_MEM;
ffffffffc0204464:	5571                	li	a0,-4
    return ret;
ffffffffc0204466:	b569                	j	ffffffffc02042f0 <do_fork+0x1c8>
        intr_enable();
ffffffffc0204468:	d46fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020446c:	bdb5                	j	ffffffffc02042e8 <do_fork+0x1c0>
                    if (last_pid >= MAX_PID)
ffffffffc020446e:	01d6c363          	blt	a3,t4,ffffffffc0204474 <do_fork+0x34c>
                        last_pid = 1;
ffffffffc0204472:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204474:	4585                	li	a1,1
ffffffffc0204476:	b5c1                	j	ffffffffc0204336 <do_fork+0x20e>
ffffffffc0204478:	c599                	beqz	a1,ffffffffc0204486 <do_fork+0x35e>
ffffffffc020447a:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020447e:	8536                	mv	a0,a3
ffffffffc0204480:	bd01                	j	ffffffffc0204290 <do_fork+0x168>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204482:	556d                	li	a0,-5
ffffffffc0204484:	b5b5                	j	ffffffffc02042f0 <do_fork+0x1c8>
    return last_pid;
ffffffffc0204486:	00082503          	lw	a0,0(a6)
ffffffffc020448a:	b519                	j	ffffffffc0204290 <do_fork+0x168>
    {
        panic("Unlock failed.\n");
ffffffffc020448c:	00003617          	auipc	a2,0x3
ffffffffc0204490:	cac60613          	addi	a2,a2,-852 # ffffffffc0207138 <default_pmm_manager+0xa00>
ffffffffc0204494:	03f00593          	li	a1,63
ffffffffc0204498:	00003517          	auipc	a0,0x3
ffffffffc020449c:	cb050513          	addi	a0,a0,-848 # ffffffffc0207148 <default_pmm_manager+0xa10>
ffffffffc02044a0:	feffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02044a4:	00002617          	auipc	a2,0x2
ffffffffc02044a8:	bac60613          	addi	a2,a2,-1108 # ffffffffc0206050 <commands+0x598>
ffffffffc02044ac:	06900593          	li	a1,105
ffffffffc02044b0:	00002517          	auipc	a0,0x2
ffffffffc02044b4:	bc050513          	addi	a0,a0,-1088 # ffffffffc0206070 <commands+0x5b8>
ffffffffc02044b8:	fd7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02044bc:	86be                	mv	a3,a5
ffffffffc02044be:	00002617          	auipc	a2,0x2
ffffffffc02044c2:	32260613          	addi	a2,a2,802 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc02044c6:	19700593          	li	a1,407
ffffffffc02044ca:	00003517          	auipc	a0,0x3
ffffffffc02044ce:	c5650513          	addi	a0,a0,-938 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc02044d2:	fbdfb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02044d6:	00002617          	auipc	a2,0x2
ffffffffc02044da:	30a60613          	addi	a2,a2,778 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc02044de:	07700593          	li	a1,119
ffffffffc02044e2:	00002517          	auipc	a0,0x2
ffffffffc02044e6:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0206070 <commands+0x5b8>
ffffffffc02044ea:	fa5fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02044ee:	00002617          	auipc	a2,0x2
ffffffffc02044f2:	b9260613          	addi	a2,a2,-1134 # ffffffffc0206080 <commands+0x5c8>
ffffffffc02044f6:	07100593          	li	a1,113
ffffffffc02044fa:	00002517          	auipc	a0,0x2
ffffffffc02044fe:	b7650513          	addi	a0,a0,-1162 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0204502:	f8dfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204506 <kernel_thread>:
{
ffffffffc0204506:	7129                	addi	sp,sp,-320
ffffffffc0204508:	fa22                	sd	s0,304(sp)
ffffffffc020450a:	f626                	sd	s1,296(sp)
ffffffffc020450c:	f24a                	sd	s2,288(sp)
ffffffffc020450e:	84ae                	mv	s1,a1
ffffffffc0204510:	892a                	mv	s2,a0
ffffffffc0204512:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204514:	4581                	li	a1,0
ffffffffc0204516:	12000613          	li	a2,288
ffffffffc020451a:	850a                	mv	a0,sp
{
ffffffffc020451c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020451e:	304010ef          	jal	ra,ffffffffc0205822 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204522:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204524:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204526:	100027f3          	csrr	a5,sstatus
ffffffffc020452a:	edd7f793          	andi	a5,a5,-291
ffffffffc020452e:	1207e793          	ori	a5,a5,288
ffffffffc0204532:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204534:	860a                	mv	a2,sp
ffffffffc0204536:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020453a:	00000797          	auipc	a5,0x0
ffffffffc020453e:	a2a78793          	addi	a5,a5,-1494 # ffffffffc0203f64 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204542:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204544:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204546:	be3ff0ef          	jal	ra,ffffffffc0204128 <do_fork>
}
ffffffffc020454a:	70f2                	ld	ra,312(sp)
ffffffffc020454c:	7452                	ld	s0,304(sp)
ffffffffc020454e:	74b2                	ld	s1,296(sp)
ffffffffc0204550:	7912                	ld	s2,288(sp)
ffffffffc0204552:	6131                	addi	sp,sp,320
ffffffffc0204554:	8082                	ret

ffffffffc0204556 <do_exit>:
{
ffffffffc0204556:	7179                	addi	sp,sp,-48
ffffffffc0204558:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc020455a:	000cb417          	auipc	s0,0xcb
ffffffffc020455e:	f4640413          	addi	s0,s0,-186 # ffffffffc02cf4a0 <current>
ffffffffc0204562:	601c                	ld	a5,0(s0)
{
ffffffffc0204564:	f406                	sd	ra,40(sp)
ffffffffc0204566:	ec26                	sd	s1,24(sp)
ffffffffc0204568:	e84a                	sd	s2,16(sp)
ffffffffc020456a:	e44e                	sd	s3,8(sp)
ffffffffc020456c:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020456e:	000cb717          	auipc	a4,0xcb
ffffffffc0204572:	f3a73703          	ld	a4,-198(a4) # ffffffffc02cf4a8 <idleproc>
ffffffffc0204576:	0ce78c63          	beq	a5,a4,ffffffffc020464e <do_exit+0xf8>
    if (current == initproc)
ffffffffc020457a:	000cb497          	auipc	s1,0xcb
ffffffffc020457e:	f3648493          	addi	s1,s1,-202 # ffffffffc02cf4b0 <initproc>
ffffffffc0204582:	6098                	ld	a4,0(s1)
ffffffffc0204584:	0ee78b63          	beq	a5,a4,ffffffffc020467a <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204588:	0287b983          	ld	s3,40(a5)
ffffffffc020458c:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020458e:	02098663          	beqz	s3,ffffffffc02045ba <do_exit+0x64>
ffffffffc0204592:	000cb797          	auipc	a5,0xcb
ffffffffc0204596:	ede7b783          	ld	a5,-290(a5) # ffffffffc02cf470 <boot_pgdir_pa>
ffffffffc020459a:	577d                	li	a4,-1
ffffffffc020459c:	177e                	slli	a4,a4,0x3f
ffffffffc020459e:	83b1                	srli	a5,a5,0xc
ffffffffc02045a0:	8fd9                	or	a5,a5,a4
ffffffffc02045a2:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02045a6:	0309a783          	lw	a5,48(s3)
ffffffffc02045aa:	fff7871b          	addiw	a4,a5,-1
ffffffffc02045ae:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02045b2:	cb55                	beqz	a4,ffffffffc0204666 <do_exit+0x110>
        current->mm = NULL;
ffffffffc02045b4:	601c                	ld	a5,0(s0)
ffffffffc02045b6:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02045ba:	601c                	ld	a5,0(s0)
ffffffffc02045bc:	470d                	li	a4,3
ffffffffc02045be:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02045c0:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045c4:	100027f3          	csrr	a5,sstatus
ffffffffc02045c8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045ca:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045cc:	e3f9                	bnez	a5,ffffffffc0204692 <do_exit+0x13c>
        proc = current->parent;
ffffffffc02045ce:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02045d0:	800007b7          	lui	a5,0x80000
ffffffffc02045d4:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02045d6:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02045d8:	0ec52703          	lw	a4,236(a0)
ffffffffc02045dc:	0af70f63          	beq	a4,a5,ffffffffc020469a <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc02045e0:	6018                	ld	a4,0(s0)
ffffffffc02045e2:	7b7c                	ld	a5,240(a4)
ffffffffc02045e4:	c3a1                	beqz	a5,ffffffffc0204624 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02045e6:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045ea:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc02045ec:	0985                	addi	s3,s3,1
ffffffffc02045ee:	a021                	j	ffffffffc02045f6 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc02045f0:	6018                	ld	a4,0(s0)
ffffffffc02045f2:	7b7c                	ld	a5,240(a4)
ffffffffc02045f4:	cb85                	beqz	a5,ffffffffc0204624 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02045f6:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_cowtest_out_size+0xffffffff7fff4bc8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02045fa:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02045fc:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02045fe:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204600:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204604:	10e7b023          	sd	a4,256(a5)
ffffffffc0204608:	c311                	beqz	a4,ffffffffc020460c <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc020460a:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020460c:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020460e:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204610:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204612:	fd271fe3          	bne	a4,s2,ffffffffc02045f0 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204616:	0ec52783          	lw	a5,236(a0)
ffffffffc020461a:	fd379be3          	bne	a5,s3,ffffffffc02045f0 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020461e:	373000ef          	jal	ra,ffffffffc0205190 <wakeup_proc>
ffffffffc0204622:	b7f9                	j	ffffffffc02045f0 <do_exit+0x9a>
    if (flag)
ffffffffc0204624:	020a1263          	bnez	s4,ffffffffc0204648 <do_exit+0xf2>
    schedule();
ffffffffc0204628:	3e9000ef          	jal	ra,ffffffffc0205210 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020462c:	601c                	ld	a5,0(s0)
ffffffffc020462e:	00003617          	auipc	a2,0x3
ffffffffc0204632:	b5260613          	addi	a2,a2,-1198 # ffffffffc0207180 <default_pmm_manager+0xa48>
ffffffffc0204636:	24700593          	li	a1,583
ffffffffc020463a:	43d4                	lw	a3,4(a5)
ffffffffc020463c:	00003517          	auipc	a0,0x3
ffffffffc0204640:	ae450513          	addi	a0,a0,-1308 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204644:	e4bfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204648:	b66fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020464c:	bff1                	j	ffffffffc0204628 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020464e:	00003617          	auipc	a2,0x3
ffffffffc0204652:	b1260613          	addi	a2,a2,-1262 # ffffffffc0207160 <default_pmm_manager+0xa28>
ffffffffc0204656:	21300593          	li	a1,531
ffffffffc020465a:	00003517          	auipc	a0,0x3
ffffffffc020465e:	ac650513          	addi	a0,a0,-1338 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204662:	e2dfb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204666:	854e                	mv	a0,s3
ffffffffc0204668:	cceff0ef          	jal	ra,ffffffffc0203b36 <exit_mmap>
            put_pgdir(mm);
ffffffffc020466c:	854e                	mv	a0,s3
ffffffffc020466e:	9ddff0ef          	jal	ra,ffffffffc020404a <put_pgdir>
            mm_destroy(mm);
ffffffffc0204672:	854e                	mv	a0,s3
ffffffffc0204674:	b26ff0ef          	jal	ra,ffffffffc020399a <mm_destroy>
ffffffffc0204678:	bf35                	j	ffffffffc02045b4 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc020467a:	00003617          	auipc	a2,0x3
ffffffffc020467e:	af660613          	addi	a2,a2,-1290 # ffffffffc0207170 <default_pmm_manager+0xa38>
ffffffffc0204682:	21700593          	li	a1,535
ffffffffc0204686:	00003517          	auipc	a0,0x3
ffffffffc020468a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc020468e:	e01fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc0204692:	b22fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204696:	4a05                	li	s4,1
ffffffffc0204698:	bf1d                	j	ffffffffc02045ce <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc020469a:	2f7000ef          	jal	ra,ffffffffc0205190 <wakeup_proc>
ffffffffc020469e:	b789                	j	ffffffffc02045e0 <do_exit+0x8a>

ffffffffc02046a0 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02046a0:	715d                	addi	sp,sp,-80
ffffffffc02046a2:	f84a                	sd	s2,48(sp)
ffffffffc02046a4:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02046a6:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc02046aa:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc02046ac:	fc26                	sd	s1,56(sp)
ffffffffc02046ae:	f052                	sd	s4,32(sp)
ffffffffc02046b0:	ec56                	sd	s5,24(sp)
ffffffffc02046b2:	e85a                	sd	s6,16(sp)
ffffffffc02046b4:	e45e                	sd	s7,8(sp)
ffffffffc02046b6:	e486                	sd	ra,72(sp)
ffffffffc02046b8:	e0a2                	sd	s0,64(sp)
ffffffffc02046ba:	84aa                	mv	s1,a0
ffffffffc02046bc:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc02046be:	000cbb97          	auipc	s7,0xcb
ffffffffc02046c2:	de2b8b93          	addi	s7,s7,-542 # ffffffffc02cf4a0 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02046c6:	00050b1b          	sext.w	s6,a0
ffffffffc02046ca:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02046ce:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02046d0:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02046d2:	ccbd                	beqz	s1,ffffffffc0204750 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02046d4:	0359e863          	bltu	s3,s5,ffffffffc0204704 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02046d8:	45a9                	li	a1,10
ffffffffc02046da:	855a                	mv	a0,s6
ffffffffc02046dc:	4a1000ef          	jal	ra,ffffffffc020537c <hash32>
ffffffffc02046e0:	02051793          	slli	a5,a0,0x20
ffffffffc02046e4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02046e8:	000c7797          	auipc	a5,0xc7
ffffffffc02046ec:	d4878793          	addi	a5,a5,-696 # ffffffffc02cb430 <hash_list>
ffffffffc02046f0:	953e                	add	a0,a0,a5
ffffffffc02046f2:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc02046f4:	a029                	j	ffffffffc02046fe <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc02046f6:	f2c42783          	lw	a5,-212(s0)
ffffffffc02046fa:	02978163          	beq	a5,s1,ffffffffc020471c <do_wait.part.0+0x7c>
ffffffffc02046fe:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204700:	fe851be3          	bne	a0,s0,ffffffffc02046f6 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204704:	5579                	li	a0,-2
}
ffffffffc0204706:	60a6                	ld	ra,72(sp)
ffffffffc0204708:	6406                	ld	s0,64(sp)
ffffffffc020470a:	74e2                	ld	s1,56(sp)
ffffffffc020470c:	7942                	ld	s2,48(sp)
ffffffffc020470e:	79a2                	ld	s3,40(sp)
ffffffffc0204710:	7a02                	ld	s4,32(sp)
ffffffffc0204712:	6ae2                	ld	s5,24(sp)
ffffffffc0204714:	6b42                	ld	s6,16(sp)
ffffffffc0204716:	6ba2                	ld	s7,8(sp)
ffffffffc0204718:	6161                	addi	sp,sp,80
ffffffffc020471a:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020471c:	000bb683          	ld	a3,0(s7)
ffffffffc0204720:	f4843783          	ld	a5,-184(s0)
ffffffffc0204724:	fed790e3          	bne	a5,a3,ffffffffc0204704 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204728:	f2842703          	lw	a4,-216(s0)
ffffffffc020472c:	478d                	li	a5,3
ffffffffc020472e:	0ef70b63          	beq	a4,a5,ffffffffc0204824 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204732:	4785                	li	a5,1
ffffffffc0204734:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204736:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc020473a:	2d7000ef          	jal	ra,ffffffffc0205210 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020473e:	000bb783          	ld	a5,0(s7)
ffffffffc0204742:	0b07a783          	lw	a5,176(a5)
ffffffffc0204746:	8b85                	andi	a5,a5,1
ffffffffc0204748:	d7c9                	beqz	a5,ffffffffc02046d2 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc020474a:	555d                	li	a0,-9
ffffffffc020474c:	e0bff0ef          	jal	ra,ffffffffc0204556 <do_exit>
        proc = current->cptr;
ffffffffc0204750:	000bb683          	ld	a3,0(s7)
ffffffffc0204754:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204756:	d45d                	beqz	s0,ffffffffc0204704 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204758:	470d                	li	a4,3
ffffffffc020475a:	a021                	j	ffffffffc0204762 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020475c:	10043403          	ld	s0,256(s0)
ffffffffc0204760:	d869                	beqz	s0,ffffffffc0204732 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204762:	401c                	lw	a5,0(s0)
ffffffffc0204764:	fee79ce3          	bne	a5,a4,ffffffffc020475c <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204768:	000cb797          	auipc	a5,0xcb
ffffffffc020476c:	d407b783          	ld	a5,-704(a5) # ffffffffc02cf4a8 <idleproc>
ffffffffc0204770:	0c878963          	beq	a5,s0,ffffffffc0204842 <do_wait.part.0+0x1a2>
ffffffffc0204774:	000cb797          	auipc	a5,0xcb
ffffffffc0204778:	d3c7b783          	ld	a5,-708(a5) # ffffffffc02cf4b0 <initproc>
ffffffffc020477c:	0cf40363          	beq	s0,a5,ffffffffc0204842 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204780:	000a0663          	beqz	s4,ffffffffc020478c <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204784:	0e842783          	lw	a5,232(s0)
ffffffffc0204788:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8fa0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020478c:	100027f3          	csrr	a5,sstatus
ffffffffc0204790:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204792:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204794:	e7c1                	bnez	a5,ffffffffc020481c <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204796:	6c70                	ld	a2,216(s0)
ffffffffc0204798:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020479a:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc020479e:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02047a0:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047a2:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02047a4:	6470                	ld	a2,200(s0)
ffffffffc02047a6:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02047a8:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02047aa:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc02047ac:	c319                	beqz	a4,ffffffffc02047b2 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02047ae:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc02047b0:	7c7c                	ld	a5,248(s0)
ffffffffc02047b2:	c3b5                	beqz	a5,ffffffffc0204816 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02047b4:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc02047b8:	000cb717          	auipc	a4,0xcb
ffffffffc02047bc:	d0070713          	addi	a4,a4,-768 # ffffffffc02cf4b8 <nr_process>
ffffffffc02047c0:	431c                	lw	a5,0(a4)
ffffffffc02047c2:	37fd                	addiw	a5,a5,-1
ffffffffc02047c4:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02047c6:	e5a9                	bnez	a1,ffffffffc0204810 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02047c8:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02047ca:	c02007b7          	lui	a5,0xc0200
ffffffffc02047ce:	04f6ee63          	bltu	a3,a5,ffffffffc020482a <do_wait.part.0+0x18a>
ffffffffc02047d2:	000cb797          	auipc	a5,0xcb
ffffffffc02047d6:	cc67b783          	ld	a5,-826(a5) # ffffffffc02cf498 <va_pa_offset>
ffffffffc02047da:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02047dc:	82b1                	srli	a3,a3,0xc
ffffffffc02047de:	000cb797          	auipc	a5,0xcb
ffffffffc02047e2:	ca27b783          	ld	a5,-862(a5) # ffffffffc02cf480 <npage>
ffffffffc02047e6:	06f6fa63          	bgeu	a3,a5,ffffffffc020485a <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02047ea:	00003517          	auipc	a0,0x3
ffffffffc02047ee:	1ce53503          	ld	a0,462(a0) # ffffffffc02079b8 <nbase>
ffffffffc02047f2:	8e89                	sub	a3,a3,a0
ffffffffc02047f4:	069a                	slli	a3,a3,0x6
ffffffffc02047f6:	000cb517          	auipc	a0,0xcb
ffffffffc02047fa:	c9253503          	ld	a0,-878(a0) # ffffffffc02cf488 <pages>
ffffffffc02047fe:	9536                	add	a0,a0,a3
ffffffffc0204800:	4589                	li	a1,2
ffffffffc0204802:	969fd0ef          	jal	ra,ffffffffc020216a <free_pages>
    kfree(proc);
ffffffffc0204806:	8522                	mv	a0,s0
ffffffffc0204808:	ff6fd0ef          	jal	ra,ffffffffc0201ffe <kfree>
    return 0;
ffffffffc020480c:	4501                	li	a0,0
ffffffffc020480e:	bde5                	j	ffffffffc0204706 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204810:	99efc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204814:	bf55                	j	ffffffffc02047c8 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204816:	701c                	ld	a5,32(s0)
ffffffffc0204818:	fbf8                	sd	a4,240(a5)
ffffffffc020481a:	bf79                	j	ffffffffc02047b8 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020481c:	998fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204820:	4585                	li	a1,1
ffffffffc0204822:	bf95                	j	ffffffffc0204796 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204824:	f2840413          	addi	s0,s0,-216
ffffffffc0204828:	b781                	j	ffffffffc0204768 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc020482a:	00002617          	auipc	a2,0x2
ffffffffc020482e:	fb660613          	addi	a2,a2,-74 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc0204832:	07700593          	li	a1,119
ffffffffc0204836:	00002517          	auipc	a0,0x2
ffffffffc020483a:	83a50513          	addi	a0,a0,-1990 # ffffffffc0206070 <commands+0x5b8>
ffffffffc020483e:	c51fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204842:	00003617          	auipc	a2,0x3
ffffffffc0204846:	95e60613          	addi	a2,a2,-1698 # ffffffffc02071a0 <default_pmm_manager+0xa68>
ffffffffc020484a:	36800593          	li	a1,872
ffffffffc020484e:	00003517          	auipc	a0,0x3
ffffffffc0204852:	8d250513          	addi	a0,a0,-1838 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204856:	c39fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020485a:	00001617          	auipc	a2,0x1
ffffffffc020485e:	7f660613          	addi	a2,a2,2038 # ffffffffc0206050 <commands+0x598>
ffffffffc0204862:	06900593          	li	a1,105
ffffffffc0204866:	00002517          	auipc	a0,0x2
ffffffffc020486a:	80a50513          	addi	a0,a0,-2038 # ffffffffc0206070 <commands+0x5b8>
ffffffffc020486e:	c21fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204872 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204872:	1141                	addi	sp,sp,-16
ffffffffc0204874:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204876:	935fd0ef          	jal	ra,ffffffffc02021aa <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020487a:	ed0fd0ef          	jal	ra,ffffffffc0201f4a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020487e:	4601                	li	a2,0
ffffffffc0204880:	4581                	li	a1,0
ffffffffc0204882:	fffff517          	auipc	a0,0xfffff
ffffffffc0204886:	74a50513          	addi	a0,a0,1866 # ffffffffc0203fcc <user_main>
ffffffffc020488a:	c7dff0ef          	jal	ra,ffffffffc0204506 <kernel_thread>
    if (pid <= 0)
ffffffffc020488e:	00a04563          	bgtz	a0,ffffffffc0204898 <init_main+0x26>
ffffffffc0204892:	a071                	j	ffffffffc020491e <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204894:	17d000ef          	jal	ra,ffffffffc0205210 <schedule>
    if (code_store != NULL)
ffffffffc0204898:	4581                	li	a1,0
ffffffffc020489a:	4501                	li	a0,0
ffffffffc020489c:	e05ff0ef          	jal	ra,ffffffffc02046a0 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02048a0:	d975                	beqz	a0,ffffffffc0204894 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02048a2:	00003517          	auipc	a0,0x3
ffffffffc02048a6:	93e50513          	addi	a0,a0,-1730 # ffffffffc02071e0 <default_pmm_manager+0xaa8>
ffffffffc02048aa:	8ebfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02048ae:	000cb797          	auipc	a5,0xcb
ffffffffc02048b2:	c027b783          	ld	a5,-1022(a5) # ffffffffc02cf4b0 <initproc>
ffffffffc02048b6:	7bf8                	ld	a4,240(a5)
ffffffffc02048b8:	e339                	bnez	a4,ffffffffc02048fe <init_main+0x8c>
ffffffffc02048ba:	7ff8                	ld	a4,248(a5)
ffffffffc02048bc:	e329                	bnez	a4,ffffffffc02048fe <init_main+0x8c>
ffffffffc02048be:	1007b703          	ld	a4,256(a5)
ffffffffc02048c2:	ef15                	bnez	a4,ffffffffc02048fe <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02048c4:	000cb697          	auipc	a3,0xcb
ffffffffc02048c8:	bf46a683          	lw	a3,-1036(a3) # ffffffffc02cf4b8 <nr_process>
ffffffffc02048cc:	4709                	li	a4,2
ffffffffc02048ce:	0ae69463          	bne	a3,a4,ffffffffc0204976 <init_main+0x104>
    return listelm->next;
ffffffffc02048d2:	000cb697          	auipc	a3,0xcb
ffffffffc02048d6:	b5e68693          	addi	a3,a3,-1186 # ffffffffc02cf430 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048da:	6698                	ld	a4,8(a3)
ffffffffc02048dc:	0c878793          	addi	a5,a5,200
ffffffffc02048e0:	06f71b63          	bne	a4,a5,ffffffffc0204956 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02048e4:	629c                	ld	a5,0(a3)
ffffffffc02048e6:	04f71863          	bne	a4,a5,ffffffffc0204936 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02048ea:	00003517          	auipc	a0,0x3
ffffffffc02048ee:	9de50513          	addi	a0,a0,-1570 # ffffffffc02072c8 <default_pmm_manager+0xb90>
ffffffffc02048f2:	8a3fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02048f6:	60a2                	ld	ra,8(sp)
ffffffffc02048f8:	4501                	li	a0,0
ffffffffc02048fa:	0141                	addi	sp,sp,16
ffffffffc02048fc:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02048fe:	00003697          	auipc	a3,0x3
ffffffffc0204902:	90a68693          	addi	a3,a3,-1782 # ffffffffc0207208 <default_pmm_manager+0xad0>
ffffffffc0204906:	00002617          	auipc	a2,0x2
ffffffffc020490a:	a8260613          	addi	a2,a2,-1406 # ffffffffc0206388 <commands+0x8d0>
ffffffffc020490e:	3d600593          	li	a1,982
ffffffffc0204912:	00003517          	auipc	a0,0x3
ffffffffc0204916:	80e50513          	addi	a0,a0,-2034 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc020491a:	b75fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc020491e:	00003617          	auipc	a2,0x3
ffffffffc0204922:	8a260613          	addi	a2,a2,-1886 # ffffffffc02071c0 <default_pmm_manager+0xa88>
ffffffffc0204926:	3cd00593          	li	a1,973
ffffffffc020492a:	00002517          	auipc	a0,0x2
ffffffffc020492e:	7f650513          	addi	a0,a0,2038 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204932:	b5dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204936:	00003697          	auipc	a3,0x3
ffffffffc020493a:	96268693          	addi	a3,a3,-1694 # ffffffffc0207298 <default_pmm_manager+0xb60>
ffffffffc020493e:	00002617          	auipc	a2,0x2
ffffffffc0204942:	a4a60613          	addi	a2,a2,-1462 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204946:	3d900593          	li	a1,985
ffffffffc020494a:	00002517          	auipc	a0,0x2
ffffffffc020494e:	7d650513          	addi	a0,a0,2006 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204952:	b3dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204956:	00003697          	auipc	a3,0x3
ffffffffc020495a:	91268693          	addi	a3,a3,-1774 # ffffffffc0207268 <default_pmm_manager+0xb30>
ffffffffc020495e:	00002617          	auipc	a2,0x2
ffffffffc0204962:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204966:	3d800593          	li	a1,984
ffffffffc020496a:	00002517          	auipc	a0,0x2
ffffffffc020496e:	7b650513          	addi	a0,a0,1974 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204972:	b1dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204976:	00003697          	auipc	a3,0x3
ffffffffc020497a:	8e268693          	addi	a3,a3,-1822 # ffffffffc0207258 <default_pmm_manager+0xb20>
ffffffffc020497e:	00002617          	auipc	a2,0x2
ffffffffc0204982:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204986:	3d700593          	li	a1,983
ffffffffc020498a:	00002517          	auipc	a0,0x2
ffffffffc020498e:	79650513          	addi	a0,a0,1942 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204992:	afdfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204996 <do_execve>:
{
ffffffffc0204996:	7171                	addi	sp,sp,-176
ffffffffc0204998:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020499a:	000cbd97          	auipc	s11,0xcb
ffffffffc020499e:	b06d8d93          	addi	s11,s11,-1274 # ffffffffc02cf4a0 <current>
ffffffffc02049a2:	000db783          	ld	a5,0(s11)
{
ffffffffc02049a6:	e94a                	sd	s2,144(sp)
ffffffffc02049a8:	f122                	sd	s0,160(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02049aa:	0287b903          	ld	s2,40(a5)
{
ffffffffc02049ae:	ed26                	sd	s1,152(sp)
ffffffffc02049b0:	f8da                	sd	s6,112(sp)
ffffffffc02049b2:	84aa                	mv	s1,a0
ffffffffc02049b4:	8b32                	mv	s6,a2
ffffffffc02049b6:	842e                	mv	s0,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02049b8:	862e                	mv	a2,a1
ffffffffc02049ba:	4681                	li	a3,0
ffffffffc02049bc:	85aa                	mv	a1,a0
ffffffffc02049be:	854a                	mv	a0,s2
{
ffffffffc02049c0:	f506                	sd	ra,168(sp)
ffffffffc02049c2:	e54e                	sd	s3,136(sp)
ffffffffc02049c4:	e152                	sd	s4,128(sp)
ffffffffc02049c6:	fcd6                	sd	s5,120(sp)
ffffffffc02049c8:	f4de                	sd	s7,104(sp)
ffffffffc02049ca:	f0e2                	sd	s8,96(sp)
ffffffffc02049cc:	ece6                	sd	s9,88(sp)
ffffffffc02049ce:	e8ea                	sd	s10,80(sp)
ffffffffc02049d0:	f05a                	sd	s6,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02049d2:	cfeff0ef          	jal	ra,ffffffffc0203ed0 <user_mem_check>
ffffffffc02049d6:	40050a63          	beqz	a0,ffffffffc0204dea <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02049da:	4641                	li	a2,16
ffffffffc02049dc:	4581                	li	a1,0
ffffffffc02049de:	1808                	addi	a0,sp,48
ffffffffc02049e0:	643000ef          	jal	ra,ffffffffc0205822 <memset>
    memcpy(local_name, name, len);
ffffffffc02049e4:	47bd                	li	a5,15
ffffffffc02049e6:	8622                	mv	a2,s0
ffffffffc02049e8:	1e87e263          	bltu	a5,s0,ffffffffc0204bcc <do_execve+0x236>
ffffffffc02049ec:	85a6                	mv	a1,s1
ffffffffc02049ee:	1808                	addi	a0,sp,48
ffffffffc02049f0:	645000ef          	jal	ra,ffffffffc0205834 <memcpy>
    if (mm != NULL)
ffffffffc02049f4:	1e090363          	beqz	s2,ffffffffc0204bda <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc02049f8:	00002517          	auipc	a0,0x2
ffffffffc02049fc:	4e850513          	addi	a0,a0,1256 # ffffffffc0206ee0 <default_pmm_manager+0x7a8>
ffffffffc0204a00:	fccfb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204a04:	000cb797          	auipc	a5,0xcb
ffffffffc0204a08:	a6c7b783          	ld	a5,-1428(a5) # ffffffffc02cf470 <boot_pgdir_pa>
ffffffffc0204a0c:	577d                	li	a4,-1
ffffffffc0204a0e:	177e                	slli	a4,a4,0x3f
ffffffffc0204a10:	83b1                	srli	a5,a5,0xc
ffffffffc0204a12:	8fd9                	or	a5,a5,a4
ffffffffc0204a14:	18079073          	csrw	satp,a5
ffffffffc0204a18:	03092783          	lw	a5,48(s2) # ffffffff80000030 <_binary_obj___user_cowtest_out_size+0xffffffff7fff4af8>
ffffffffc0204a1c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a20:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a24:	2c070463          	beqz	a4,ffffffffc0204cec <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204a28:	000db783          	ld	a5,0(s11)
ffffffffc0204a2c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204a30:	e2bfe0ef          	jal	ra,ffffffffc020385a <mm_create>
ffffffffc0204a34:	842a                	mv	s0,a0
ffffffffc0204a36:	1c050d63          	beqz	a0,ffffffffc0204c10 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a3a:	4505                	li	a0,1
ffffffffc0204a3c:	ef0fd0ef          	jal	ra,ffffffffc020212c <alloc_pages>
ffffffffc0204a40:	3a050963          	beqz	a0,ffffffffc0204df2 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204a44:	000cbc97          	auipc	s9,0xcb
ffffffffc0204a48:	a44c8c93          	addi	s9,s9,-1468 # ffffffffc02cf488 <pages>
ffffffffc0204a4c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204a50:	000cbc17          	auipc	s8,0xcb
ffffffffc0204a54:	a30c0c13          	addi	s8,s8,-1488 # ffffffffc02cf480 <npage>
    return page - pages + nbase;
ffffffffc0204a58:	00003717          	auipc	a4,0x3
ffffffffc0204a5c:	f6073703          	ld	a4,-160(a4) # ffffffffc02079b8 <nbase>
ffffffffc0204a60:	40d506b3          	sub	a3,a0,a3
ffffffffc0204a64:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204a66:	5a7d                	li	s4,-1
ffffffffc0204a68:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204a6c:	96ba                	add	a3,a3,a4
ffffffffc0204a6e:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a70:	00ca5713          	srli	a4,s4,0xc
ffffffffc0204a74:	ec3a                	sd	a4,24(sp)
ffffffffc0204a76:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a78:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a7a:	38f77063          	bgeu	a4,a5,ffffffffc0204dfa <do_execve+0x464>
ffffffffc0204a7e:	000cba97          	auipc	s5,0xcb
ffffffffc0204a82:	a1aa8a93          	addi	s5,s5,-1510 # ffffffffc02cf498 <va_pa_offset>
ffffffffc0204a86:	000ab483          	ld	s1,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204a8a:	6605                	lui	a2,0x1
ffffffffc0204a8c:	000cb597          	auipc	a1,0xcb
ffffffffc0204a90:	9ec5b583          	ld	a1,-1556(a1) # ffffffffc02cf478 <boot_pgdir_va>
ffffffffc0204a94:	94b6                	add	s1,s1,a3
ffffffffc0204a96:	8526                	mv	a0,s1
ffffffffc0204a98:	59d000ef          	jal	ra,ffffffffc0205834 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a9c:	7782                	ld	a5,32(sp)
ffffffffc0204a9e:	4398                	lw	a4,0(a5)
ffffffffc0204aa0:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204aa4:	ec04                	sd	s1,24(s0)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204aa6:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_cowtest_out_size+0x464b9047>
ffffffffc0204aaa:	14f71963          	bne	a4,a5,ffffffffc0204bfc <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204aae:	7682                	ld	a3,32(sp)
    struct Page *page = NULL;
ffffffffc0204ab0:	4b81                	li	s7,0
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ab2:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204ab6:	0206b903          	ld	s2,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204aba:	00371793          	slli	a5,a4,0x3
ffffffffc0204abe:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204ac0:	9936                	add	s2,s2,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ac2:	078e                	slli	a5,a5,0x3
ffffffffc0204ac4:	97ca                	add	a5,a5,s2
ffffffffc0204ac6:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204ac8:	00f97c63          	bgeu	s2,a5,ffffffffc0204ae0 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204acc:	00092783          	lw	a5,0(s2)
ffffffffc0204ad0:	4705                	li	a4,1
ffffffffc0204ad2:	14e78163          	beq	a5,a4,ffffffffc0204c14 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204ad6:	77a2                	ld	a5,40(sp)
ffffffffc0204ad8:	03890913          	addi	s2,s2,56
ffffffffc0204adc:	fef968e3          	bltu	s2,a5,ffffffffc0204acc <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204ae0:	4701                	li	a4,0
ffffffffc0204ae2:	46ad                	li	a3,11
ffffffffc0204ae4:	00100637          	lui	a2,0x100
ffffffffc0204ae8:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204aec:	8522                	mv	a0,s0
ffffffffc0204aee:	efffe0ef          	jal	ra,ffffffffc02039ec <mm_map>
ffffffffc0204af2:	89aa                	mv	s3,a0
ffffffffc0204af4:	1e051263          	bnez	a0,ffffffffc0204cd8 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204af8:	6c08                	ld	a0,24(s0)
ffffffffc0204afa:	467d                	li	a2,31
ffffffffc0204afc:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204b00:	c75fe0ef          	jal	ra,ffffffffc0203774 <pgdir_alloc_page>
ffffffffc0204b04:	38050363          	beqz	a0,ffffffffc0204e8a <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b08:	6c08                	ld	a0,24(s0)
ffffffffc0204b0a:	467d                	li	a2,31
ffffffffc0204b0c:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204b10:	c65fe0ef          	jal	ra,ffffffffc0203774 <pgdir_alloc_page>
ffffffffc0204b14:	34050b63          	beqz	a0,ffffffffc0204e6a <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b18:	6c08                	ld	a0,24(s0)
ffffffffc0204b1a:	467d                	li	a2,31
ffffffffc0204b1c:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b20:	c55fe0ef          	jal	ra,ffffffffc0203774 <pgdir_alloc_page>
ffffffffc0204b24:	32050363          	beqz	a0,ffffffffc0204e4a <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b28:	6c08                	ld	a0,24(s0)
ffffffffc0204b2a:	467d                	li	a2,31
ffffffffc0204b2c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b30:	c45fe0ef          	jal	ra,ffffffffc0203774 <pgdir_alloc_page>
ffffffffc0204b34:	2e050b63          	beqz	a0,ffffffffc0204e2a <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204b38:	581c                	lw	a5,48(s0)
    current->mm = mm;
ffffffffc0204b3a:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b3e:	6c14                	ld	a3,24(s0)
ffffffffc0204b40:	2785                	addiw	a5,a5,1
ffffffffc0204b42:	d81c                	sw	a5,48(s0)
    current->mm = mm;
ffffffffc0204b44:	f600                	sd	s0,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b46:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b4a:	2cf6e463          	bltu	a3,a5,ffffffffc0204e12 <do_execve+0x47c>
ffffffffc0204b4e:	000ab783          	ld	a5,0(s5)
ffffffffc0204b52:	577d                	li	a4,-1
ffffffffc0204b54:	177e                	slli	a4,a4,0x3f
ffffffffc0204b56:	8e9d                	sub	a3,a3,a5
ffffffffc0204b58:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b5c:	f654                	sd	a3,168(a2)
ffffffffc0204b5e:	8fd9                	or	a5,a5,a4
ffffffffc0204b60:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b64:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b66:	4581                	li	a1,0
ffffffffc0204b68:	12000613          	li	a2,288
ffffffffc0204b6c:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204b6e:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b72:	4b1000ef          	jal	ra,ffffffffc0205822 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204b76:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b78:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b7c:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204b80:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b82:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b84:	0b490913          	addi	s2,s2,180
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b88:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b8a:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b8e:	4641                	li	a2,16
ffffffffc0204b90:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b92:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204b94:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b98:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b9c:	854a                	mv	a0,s2
ffffffffc0204b9e:	485000ef          	jal	ra,ffffffffc0205822 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ba2:	463d                	li	a2,15
ffffffffc0204ba4:	180c                	addi	a1,sp,48
ffffffffc0204ba6:	854a                	mv	a0,s2
ffffffffc0204ba8:	48d000ef          	jal	ra,ffffffffc0205834 <memcpy>
}
ffffffffc0204bac:	70aa                	ld	ra,168(sp)
ffffffffc0204bae:	740a                	ld	s0,160(sp)
ffffffffc0204bb0:	64ea                	ld	s1,152(sp)
ffffffffc0204bb2:	694a                	ld	s2,144(sp)
ffffffffc0204bb4:	6a0a                	ld	s4,128(sp)
ffffffffc0204bb6:	7ae6                	ld	s5,120(sp)
ffffffffc0204bb8:	7b46                	ld	s6,112(sp)
ffffffffc0204bba:	7ba6                	ld	s7,104(sp)
ffffffffc0204bbc:	7c06                	ld	s8,96(sp)
ffffffffc0204bbe:	6ce6                	ld	s9,88(sp)
ffffffffc0204bc0:	6d46                	ld	s10,80(sp)
ffffffffc0204bc2:	6da6                	ld	s11,72(sp)
ffffffffc0204bc4:	854e                	mv	a0,s3
ffffffffc0204bc6:	69aa                	ld	s3,136(sp)
ffffffffc0204bc8:	614d                	addi	sp,sp,176
ffffffffc0204bca:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204bcc:	463d                	li	a2,15
ffffffffc0204bce:	85a6                	mv	a1,s1
ffffffffc0204bd0:	1808                	addi	a0,sp,48
ffffffffc0204bd2:	463000ef          	jal	ra,ffffffffc0205834 <memcpy>
    if (mm != NULL)
ffffffffc0204bd6:	e20911e3          	bnez	s2,ffffffffc02049f8 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204bda:	000db783          	ld	a5,0(s11)
ffffffffc0204bde:	779c                	ld	a5,40(a5)
ffffffffc0204be0:	e40788e3          	beqz	a5,ffffffffc0204a30 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204be4:	00002617          	auipc	a2,0x2
ffffffffc0204be8:	70460613          	addi	a2,a2,1796 # ffffffffc02072e8 <default_pmm_manager+0xbb0>
ffffffffc0204bec:	25300593          	li	a1,595
ffffffffc0204bf0:	00002517          	auipc	a0,0x2
ffffffffc0204bf4:	53050513          	addi	a0,a0,1328 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204bf8:	897fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204bfc:	8522                	mv	a0,s0
ffffffffc0204bfe:	c4cff0ef          	jal	ra,ffffffffc020404a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c02:	8522                	mv	a0,s0
ffffffffc0204c04:	d97fe0ef          	jal	ra,ffffffffc020399a <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204c08:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc0204c0a:	854e                	mv	a0,s3
ffffffffc0204c0c:	94bff0ef          	jal	ra,ffffffffc0204556 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204c10:	59f1                	li	s3,-4
ffffffffc0204c12:	bfe5                	j	ffffffffc0204c0a <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204c14:	02893603          	ld	a2,40(s2)
ffffffffc0204c18:	02093783          	ld	a5,32(s2)
ffffffffc0204c1c:	1cf66d63          	bltu	a2,a5,ffffffffc0204df6 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c20:	00492783          	lw	a5,4(s2)
ffffffffc0204c24:	0017f693          	andi	a3,a5,1
ffffffffc0204c28:	c291                	beqz	a3,ffffffffc0204c2c <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204c2a:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c2c:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c30:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c32:	e779                	bnez	a4,ffffffffc0204d00 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204c34:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c36:	c781                	beqz	a5,ffffffffc0204c3e <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204c38:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204c3c:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204c3e:	0026f793          	andi	a5,a3,2
ffffffffc0204c42:	e3f1                	bnez	a5,ffffffffc0204d06 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204c44:	0046f793          	andi	a5,a3,4
ffffffffc0204c48:	c399                	beqz	a5,ffffffffc0204c4e <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204c4a:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204c4e:	01093583          	ld	a1,16(s2)
ffffffffc0204c52:	4701                	li	a4,0
ffffffffc0204c54:	8522                	mv	a0,s0
ffffffffc0204c56:	d97fe0ef          	jal	ra,ffffffffc02039ec <mm_map>
ffffffffc0204c5a:	89aa                	mv	s3,a0
ffffffffc0204c5c:	ed35                	bnez	a0,ffffffffc0204cd8 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c5e:	01093b03          	ld	s6,16(s2)
ffffffffc0204c62:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c64:	02093983          	ld	s3,32(s2)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c68:	00893483          	ld	s1,8(s2)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c6c:	00fb7a33          	and	s4,s6,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c70:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c72:	99da                	add	s3,s3,s6
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c74:	94be                	add	s1,s1,a5
        while (start < end)
ffffffffc0204c76:	053b6963          	bltu	s6,s3,ffffffffc0204cc8 <do_execve+0x332>
ffffffffc0204c7a:	aa95                	j	ffffffffc0204dee <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c7c:	6785                	lui	a5,0x1
ffffffffc0204c7e:	414b0533          	sub	a0,s6,s4
ffffffffc0204c82:	9a3e                	add	s4,s4,a5
ffffffffc0204c84:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204c88:	0149f463          	bgeu	s3,s4,ffffffffc0204c90 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204c8c:	41698633          	sub	a2,s3,s6
    return page - pages + nbase;
ffffffffc0204c90:	000cb683          	ld	a3,0(s9)
ffffffffc0204c94:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c96:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c9a:	40db86b3          	sub	a3,s7,a3
ffffffffc0204c9e:	8699                	srai	a3,a3,0x6
ffffffffc0204ca0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204ca2:	67e2                	ld	a5,24(sp)
ffffffffc0204ca4:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ca8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204caa:	14b8f863          	bgeu	a7,a1,ffffffffc0204dfa <do_execve+0x464>
ffffffffc0204cae:	000ab883          	ld	a7,0(s5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cb2:	85a6                	mv	a1,s1
            start += size, from += size;
ffffffffc0204cb4:	9b32                	add	s6,s6,a2
ffffffffc0204cb6:	96c6                	add	a3,a3,a7
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cb8:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204cba:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cbc:	379000ef          	jal	ra,ffffffffc0205834 <memcpy>
            start += size, from += size;
ffffffffc0204cc0:	6622                	ld	a2,8(sp)
ffffffffc0204cc2:	94b2                	add	s1,s1,a2
        while (start < end)
ffffffffc0204cc4:	053b7363          	bgeu	s6,s3,ffffffffc0204d0a <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204cc8:	6c08                	ld	a0,24(s0)
ffffffffc0204cca:	866a                	mv	a2,s10
ffffffffc0204ccc:	85d2                	mv	a1,s4
ffffffffc0204cce:	aa7fe0ef          	jal	ra,ffffffffc0203774 <pgdir_alloc_page>
ffffffffc0204cd2:	8baa                	mv	s7,a0
ffffffffc0204cd4:	f545                	bnez	a0,ffffffffc0204c7c <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204cd6:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0204cd8:	8522                	mv	a0,s0
ffffffffc0204cda:	e5dfe0ef          	jal	ra,ffffffffc0203b36 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204cde:	8522                	mv	a0,s0
ffffffffc0204ce0:	b6aff0ef          	jal	ra,ffffffffc020404a <put_pgdir>
    mm_destroy(mm);
ffffffffc0204ce4:	8522                	mv	a0,s0
ffffffffc0204ce6:	cb5fe0ef          	jal	ra,ffffffffc020399a <mm_destroy>
    return ret;
ffffffffc0204cea:	b705                	j	ffffffffc0204c0a <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204cec:	854a                	mv	a0,s2
ffffffffc0204cee:	e49fe0ef          	jal	ra,ffffffffc0203b36 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204cf2:	854a                	mv	a0,s2
ffffffffc0204cf4:	b56ff0ef          	jal	ra,ffffffffc020404a <put_pgdir>
            mm_destroy(mm);
ffffffffc0204cf8:	854a                	mv	a0,s2
ffffffffc0204cfa:	ca1fe0ef          	jal	ra,ffffffffc020399a <mm_destroy>
ffffffffc0204cfe:	b32d                	j	ffffffffc0204a28 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204d00:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d04:	fb95                	bnez	a5,ffffffffc0204c38 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d06:	4d5d                	li	s10,23
ffffffffc0204d08:	bf35                	j	ffffffffc0204c44 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204d0a:	01093483          	ld	s1,16(s2)
ffffffffc0204d0e:	02893683          	ld	a3,40(s2)
ffffffffc0204d12:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204d14:	074b7d63          	bgeu	s6,s4,ffffffffc0204d8e <do_execve+0x3f8>
            if (start == end)
ffffffffc0204d18:	db648fe3          	beq	s1,s6,ffffffffc0204ad6 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d1c:	6785                	lui	a5,0x1
ffffffffc0204d1e:	00fb0533          	add	a0,s6,a5
ffffffffc0204d22:	41450533          	sub	a0,a0,s4
                size -= la - end;
ffffffffc0204d26:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d2a:	0b44fd63          	bgeu	s1,s4,ffffffffc0204de4 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204d2e:	000cb683          	ld	a3,0(s9)
ffffffffc0204d32:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d34:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204d38:	40db86b3          	sub	a3,s7,a3
ffffffffc0204d3c:	8699                	srai	a3,a3,0x6
ffffffffc0204d3e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d40:	67e2                	ld	a5,24(sp)
ffffffffc0204d42:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d46:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d48:	0ac5f963          	bgeu	a1,a2,ffffffffc0204dfa <do_execve+0x464>
ffffffffc0204d4c:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d50:	864e                	mv	a2,s3
ffffffffc0204d52:	4581                	li	a1,0
ffffffffc0204d54:	96c6                	add	a3,a3,a7
ffffffffc0204d56:	9536                	add	a0,a0,a3
ffffffffc0204d58:	2cb000ef          	jal	ra,ffffffffc0205822 <memset>
            start += size;
ffffffffc0204d5c:	01698733          	add	a4,s3,s6
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204d60:	0344f463          	bgeu	s1,s4,ffffffffc0204d88 <do_execve+0x3f2>
ffffffffc0204d64:	d6e489e3          	beq	s1,a4,ffffffffc0204ad6 <do_execve+0x140>
ffffffffc0204d68:	00002697          	auipc	a3,0x2
ffffffffc0204d6c:	5a868693          	addi	a3,a3,1448 # ffffffffc0207310 <default_pmm_manager+0xbd8>
ffffffffc0204d70:	00001617          	auipc	a2,0x1
ffffffffc0204d74:	61860613          	addi	a2,a2,1560 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204d78:	2bc00593          	li	a1,700
ffffffffc0204d7c:	00002517          	auipc	a0,0x2
ffffffffc0204d80:	3a450513          	addi	a0,a0,932 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204d84:	f0afb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204d88:	ff4710e3          	bne	a4,s4,ffffffffc0204d68 <do_execve+0x3d2>
ffffffffc0204d8c:	8b52                	mv	s6,s4
        while (start < end)
ffffffffc0204d8e:	d49b74e3          	bgeu	s6,s1,ffffffffc0204ad6 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d92:	6c08                	ld	a0,24(s0)
ffffffffc0204d94:	866a                	mv	a2,s10
ffffffffc0204d96:	85d2                	mv	a1,s4
ffffffffc0204d98:	9ddfe0ef          	jal	ra,ffffffffc0203774 <pgdir_alloc_page>
ffffffffc0204d9c:	8baa                	mv	s7,a0
ffffffffc0204d9e:	dd05                	beqz	a0,ffffffffc0204cd6 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204da0:	6785                	lui	a5,0x1
ffffffffc0204da2:	414b0533          	sub	a0,s6,s4
ffffffffc0204da6:	9a3e                	add	s4,s4,a5
ffffffffc0204da8:	416a0633          	sub	a2,s4,s6
            if (end < la)
ffffffffc0204dac:	0144f463          	bgeu	s1,s4,ffffffffc0204db4 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204db0:	41648633          	sub	a2,s1,s6
    return page - pages + nbase;
ffffffffc0204db4:	000cb683          	ld	a3,0(s9)
ffffffffc0204db8:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204dba:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204dbe:	40db86b3          	sub	a3,s7,a3
ffffffffc0204dc2:	8699                	srai	a3,a3,0x6
ffffffffc0204dc4:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204dc6:	67e2                	ld	a5,24(sp)
ffffffffc0204dc8:	00f6f8b3          	and	a7,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204dcc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204dce:	02b8f663          	bgeu	a7,a1,ffffffffc0204dfa <do_execve+0x464>
ffffffffc0204dd2:	000ab883          	ld	a7,0(s5)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204dd6:	4581                	li	a1,0
            start += size;
ffffffffc0204dd8:	9b32                	add	s6,s6,a2
ffffffffc0204dda:	96c6                	add	a3,a3,a7
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ddc:	9536                	add	a0,a0,a3
ffffffffc0204dde:	245000ef          	jal	ra,ffffffffc0205822 <memset>
ffffffffc0204de2:	b775                	j	ffffffffc0204d8e <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204de4:	416a09b3          	sub	s3,s4,s6
ffffffffc0204de8:	b799                	j	ffffffffc0204d2e <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204dea:	59f5                	li	s3,-3
ffffffffc0204dec:	b3c1                	j	ffffffffc0204bac <do_execve+0x216>
        while (start < end)
ffffffffc0204dee:	84da                	mv	s1,s6
ffffffffc0204df0:	bf39                	j	ffffffffc0204d0e <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204df2:	59f1                	li	s3,-4
ffffffffc0204df4:	bdc5                	j	ffffffffc0204ce4 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204df6:	59e1                	li	s3,-8
ffffffffc0204df8:	b5c5                	j	ffffffffc0204cd8 <do_execve+0x342>
ffffffffc0204dfa:	00001617          	auipc	a2,0x1
ffffffffc0204dfe:	28660613          	addi	a2,a2,646 # ffffffffc0206080 <commands+0x5c8>
ffffffffc0204e02:	07100593          	li	a1,113
ffffffffc0204e06:	00001517          	auipc	a0,0x1
ffffffffc0204e0a:	26a50513          	addi	a0,a0,618 # ffffffffc0206070 <commands+0x5b8>
ffffffffc0204e0e:	e80fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204e12:	00002617          	auipc	a2,0x2
ffffffffc0204e16:	9ce60613          	addi	a2,a2,-1586 # ffffffffc02067e0 <default_pmm_manager+0xa8>
ffffffffc0204e1a:	2db00593          	li	a1,731
ffffffffc0204e1e:	00002517          	auipc	a0,0x2
ffffffffc0204e22:	30250513          	addi	a0,a0,770 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204e26:	e68fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e2a:	00002697          	auipc	a3,0x2
ffffffffc0204e2e:	5fe68693          	addi	a3,a3,1534 # ffffffffc0207428 <default_pmm_manager+0xcf0>
ffffffffc0204e32:	00001617          	auipc	a2,0x1
ffffffffc0204e36:	55660613          	addi	a2,a2,1366 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204e3a:	2d600593          	li	a1,726
ffffffffc0204e3e:	00002517          	auipc	a0,0x2
ffffffffc0204e42:	2e250513          	addi	a0,a0,738 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204e46:	e48fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e4a:	00002697          	auipc	a3,0x2
ffffffffc0204e4e:	59668693          	addi	a3,a3,1430 # ffffffffc02073e0 <default_pmm_manager+0xca8>
ffffffffc0204e52:	00001617          	auipc	a2,0x1
ffffffffc0204e56:	53660613          	addi	a2,a2,1334 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204e5a:	2d500593          	li	a1,725
ffffffffc0204e5e:	00002517          	auipc	a0,0x2
ffffffffc0204e62:	2c250513          	addi	a0,a0,706 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204e66:	e28fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e6a:	00002697          	auipc	a3,0x2
ffffffffc0204e6e:	52e68693          	addi	a3,a3,1326 # ffffffffc0207398 <default_pmm_manager+0xc60>
ffffffffc0204e72:	00001617          	auipc	a2,0x1
ffffffffc0204e76:	51660613          	addi	a2,a2,1302 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204e7a:	2d400593          	li	a1,724
ffffffffc0204e7e:	00002517          	auipc	a0,0x2
ffffffffc0204e82:	2a250513          	addi	a0,a0,674 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204e86:	e08fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204e8a:	00002697          	auipc	a3,0x2
ffffffffc0204e8e:	4c668693          	addi	a3,a3,1222 # ffffffffc0207350 <default_pmm_manager+0xc18>
ffffffffc0204e92:	00001617          	auipc	a2,0x1
ffffffffc0204e96:	4f660613          	addi	a2,a2,1270 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0204e9a:	2d300593          	li	a1,723
ffffffffc0204e9e:	00002517          	auipc	a0,0x2
ffffffffc0204ea2:	28250513          	addi	a0,a0,642 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0204ea6:	de8fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204eaa <do_yield>:
    current->need_resched = 1;
ffffffffc0204eaa:	000ca797          	auipc	a5,0xca
ffffffffc0204eae:	5f67b783          	ld	a5,1526(a5) # ffffffffc02cf4a0 <current>
ffffffffc0204eb2:	4705                	li	a4,1
ffffffffc0204eb4:	ef98                	sd	a4,24(a5)
}
ffffffffc0204eb6:	4501                	li	a0,0
ffffffffc0204eb8:	8082                	ret

ffffffffc0204eba <do_wait>:
{
ffffffffc0204eba:	1101                	addi	sp,sp,-32
ffffffffc0204ebc:	e822                	sd	s0,16(sp)
ffffffffc0204ebe:	e426                	sd	s1,8(sp)
ffffffffc0204ec0:	ec06                	sd	ra,24(sp)
ffffffffc0204ec2:	842e                	mv	s0,a1
ffffffffc0204ec4:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204ec6:	c999                	beqz	a1,ffffffffc0204edc <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204ec8:	000ca797          	auipc	a5,0xca
ffffffffc0204ecc:	5d87b783          	ld	a5,1496(a5) # ffffffffc02cf4a0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204ed0:	7788                	ld	a0,40(a5)
ffffffffc0204ed2:	4685                	li	a3,1
ffffffffc0204ed4:	4611                	li	a2,4
ffffffffc0204ed6:	ffbfe0ef          	jal	ra,ffffffffc0203ed0 <user_mem_check>
ffffffffc0204eda:	c909                	beqz	a0,ffffffffc0204eec <do_wait+0x32>
ffffffffc0204edc:	85a2                	mv	a1,s0
}
ffffffffc0204ede:	6442                	ld	s0,16(sp)
ffffffffc0204ee0:	60e2                	ld	ra,24(sp)
ffffffffc0204ee2:	8526                	mv	a0,s1
ffffffffc0204ee4:	64a2                	ld	s1,8(sp)
ffffffffc0204ee6:	6105                	addi	sp,sp,32
ffffffffc0204ee8:	fb8ff06f          	j	ffffffffc02046a0 <do_wait.part.0>
ffffffffc0204eec:	60e2                	ld	ra,24(sp)
ffffffffc0204eee:	6442                	ld	s0,16(sp)
ffffffffc0204ef0:	64a2                	ld	s1,8(sp)
ffffffffc0204ef2:	5575                	li	a0,-3
ffffffffc0204ef4:	6105                	addi	sp,sp,32
ffffffffc0204ef6:	8082                	ret

ffffffffc0204ef8 <do_kill>:
{
ffffffffc0204ef8:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204efa:	6789                	lui	a5,0x2
{
ffffffffc0204efc:	e406                	sd	ra,8(sp)
ffffffffc0204efe:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f00:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f04:	17f9                	addi	a5,a5,-2
ffffffffc0204f06:	02e7e963          	bltu	a5,a4,ffffffffc0204f38 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f0a:	842a                	mv	s0,a0
ffffffffc0204f0c:	45a9                	li	a1,10
ffffffffc0204f0e:	2501                	sext.w	a0,a0
ffffffffc0204f10:	46c000ef          	jal	ra,ffffffffc020537c <hash32>
ffffffffc0204f14:	02051793          	slli	a5,a0,0x20
ffffffffc0204f18:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204f1c:	000c6797          	auipc	a5,0xc6
ffffffffc0204f20:	51478793          	addi	a5,a5,1300 # ffffffffc02cb430 <hash_list>
ffffffffc0204f24:	953e                	add	a0,a0,a5
ffffffffc0204f26:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204f28:	a029                	j	ffffffffc0204f32 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204f2a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f2e:	00870b63          	beq	a4,s0,ffffffffc0204f44 <do_kill+0x4c>
ffffffffc0204f32:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f34:	fef51be3          	bne	a0,a5,ffffffffc0204f2a <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204f38:	5475                	li	s0,-3
}
ffffffffc0204f3a:	60a2                	ld	ra,8(sp)
ffffffffc0204f3c:	8522                	mv	a0,s0
ffffffffc0204f3e:	6402                	ld	s0,0(sp)
ffffffffc0204f40:	0141                	addi	sp,sp,16
ffffffffc0204f42:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f44:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204f48:	00177693          	andi	a3,a4,1
ffffffffc0204f4c:	e295                	bnez	a3,ffffffffc0204f70 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f4e:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204f50:	00176713          	ori	a4,a4,1
ffffffffc0204f54:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204f58:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f5a:	fe06d0e3          	bgez	a3,ffffffffc0204f3a <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204f5e:	f2878513          	addi	a0,a5,-216
ffffffffc0204f62:	22e000ef          	jal	ra,ffffffffc0205190 <wakeup_proc>
}
ffffffffc0204f66:	60a2                	ld	ra,8(sp)
ffffffffc0204f68:	8522                	mv	a0,s0
ffffffffc0204f6a:	6402                	ld	s0,0(sp)
ffffffffc0204f6c:	0141                	addi	sp,sp,16
ffffffffc0204f6e:	8082                	ret
        return -E_KILLED;
ffffffffc0204f70:	545d                	li	s0,-9
ffffffffc0204f72:	b7e1                	j	ffffffffc0204f3a <do_kill+0x42>

ffffffffc0204f74 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f74:	1101                	addi	sp,sp,-32
ffffffffc0204f76:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f78:	000ca797          	auipc	a5,0xca
ffffffffc0204f7c:	4b878793          	addi	a5,a5,1208 # ffffffffc02cf430 <proc_list>
ffffffffc0204f80:	ec06                	sd	ra,24(sp)
ffffffffc0204f82:	e822                	sd	s0,16(sp)
ffffffffc0204f84:	e04a                	sd	s2,0(sp)
ffffffffc0204f86:	000c6497          	auipc	s1,0xc6
ffffffffc0204f8a:	4aa48493          	addi	s1,s1,1194 # ffffffffc02cb430 <hash_list>
ffffffffc0204f8e:	e79c                	sd	a5,8(a5)
ffffffffc0204f90:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f92:	000ca717          	auipc	a4,0xca
ffffffffc0204f96:	49e70713          	addi	a4,a4,1182 # ffffffffc02cf430 <proc_list>
ffffffffc0204f9a:	87a6                	mv	a5,s1
ffffffffc0204f9c:	e79c                	sd	a5,8(a5)
ffffffffc0204f9e:	e39c                	sd	a5,0(a5)
ffffffffc0204fa0:	07c1                	addi	a5,a5,16
ffffffffc0204fa2:	fef71de3          	bne	a4,a5,ffffffffc0204f9c <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204fa6:	fc7fe0ef          	jal	ra,ffffffffc0203f6c <alloc_proc>
ffffffffc0204faa:	000ca917          	auipc	s2,0xca
ffffffffc0204fae:	4fe90913          	addi	s2,s2,1278 # ffffffffc02cf4a8 <idleproc>
ffffffffc0204fb2:	00a93023          	sd	a0,0(s2)
ffffffffc0204fb6:	0e050f63          	beqz	a0,ffffffffc02050b4 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204fba:	4789                	li	a5,2
ffffffffc0204fbc:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204fbe:	00003797          	auipc	a5,0x3
ffffffffc0204fc2:	04278793          	addi	a5,a5,66 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fc6:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204fca:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204fcc:	4785                	li	a5,1
ffffffffc0204fce:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fd0:	4641                	li	a2,16
ffffffffc0204fd2:	4581                	li	a1,0
ffffffffc0204fd4:	8522                	mv	a0,s0
ffffffffc0204fd6:	04d000ef          	jal	ra,ffffffffc0205822 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fda:	463d                	li	a2,15
ffffffffc0204fdc:	00002597          	auipc	a1,0x2
ffffffffc0204fe0:	4ac58593          	addi	a1,a1,1196 # ffffffffc0207488 <default_pmm_manager+0xd50>
ffffffffc0204fe4:	8522                	mv	a0,s0
ffffffffc0204fe6:	04f000ef          	jal	ra,ffffffffc0205834 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204fea:	000ca717          	auipc	a4,0xca
ffffffffc0204fee:	4ce70713          	addi	a4,a4,1230 # ffffffffc02cf4b8 <nr_process>
ffffffffc0204ff2:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204ff4:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ff8:	4601                	li	a2,0
    nr_process++;
ffffffffc0204ffa:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ffc:	4581                	li	a1,0
ffffffffc0204ffe:	00000517          	auipc	a0,0x0
ffffffffc0205002:	87450513          	addi	a0,a0,-1932 # ffffffffc0204872 <init_main>
    nr_process++;
ffffffffc0205006:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205008:	000ca797          	auipc	a5,0xca
ffffffffc020500c:	48d7bc23          	sd	a3,1176(a5) # ffffffffc02cf4a0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205010:	cf6ff0ef          	jal	ra,ffffffffc0204506 <kernel_thread>
ffffffffc0205014:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205016:	08a05363          	blez	a0,ffffffffc020509c <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc020501a:	6789                	lui	a5,0x2
ffffffffc020501c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205020:	17f9                	addi	a5,a5,-2
ffffffffc0205022:	2501                	sext.w	a0,a0
ffffffffc0205024:	02e7e363          	bltu	a5,a4,ffffffffc020504a <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205028:	45a9                	li	a1,10
ffffffffc020502a:	352000ef          	jal	ra,ffffffffc020537c <hash32>
ffffffffc020502e:	02051793          	slli	a5,a0,0x20
ffffffffc0205032:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205036:	96a6                	add	a3,a3,s1
ffffffffc0205038:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020503a:	a029                	j	ffffffffc0205044 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc020503c:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8074>
ffffffffc0205040:	04870b63          	beq	a4,s0,ffffffffc0205096 <proc_init+0x122>
    return listelm->next;
ffffffffc0205044:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205046:	fef69be3          	bne	a3,a5,ffffffffc020503c <proc_init+0xc8>
    return NULL;
ffffffffc020504a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020504c:	0b478493          	addi	s1,a5,180
ffffffffc0205050:	4641                	li	a2,16
ffffffffc0205052:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205054:	000ca417          	auipc	s0,0xca
ffffffffc0205058:	45c40413          	addi	s0,s0,1116 # ffffffffc02cf4b0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020505c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020505e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205060:	7c2000ef          	jal	ra,ffffffffc0205822 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205064:	463d                	li	a2,15
ffffffffc0205066:	00002597          	auipc	a1,0x2
ffffffffc020506a:	44a58593          	addi	a1,a1,1098 # ffffffffc02074b0 <default_pmm_manager+0xd78>
ffffffffc020506e:	8526                	mv	a0,s1
ffffffffc0205070:	7c4000ef          	jal	ra,ffffffffc0205834 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205074:	00093783          	ld	a5,0(s2)
ffffffffc0205078:	cbb5                	beqz	a5,ffffffffc02050ec <proc_init+0x178>
ffffffffc020507a:	43dc                	lw	a5,4(a5)
ffffffffc020507c:	eba5                	bnez	a5,ffffffffc02050ec <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020507e:	601c                	ld	a5,0(s0)
ffffffffc0205080:	c7b1                	beqz	a5,ffffffffc02050cc <proc_init+0x158>
ffffffffc0205082:	43d8                	lw	a4,4(a5)
ffffffffc0205084:	4785                	li	a5,1
ffffffffc0205086:	04f71363          	bne	a4,a5,ffffffffc02050cc <proc_init+0x158>
}
ffffffffc020508a:	60e2                	ld	ra,24(sp)
ffffffffc020508c:	6442                	ld	s0,16(sp)
ffffffffc020508e:	64a2                	ld	s1,8(sp)
ffffffffc0205090:	6902                	ld	s2,0(sp)
ffffffffc0205092:	6105                	addi	sp,sp,32
ffffffffc0205094:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205096:	f2878793          	addi	a5,a5,-216
ffffffffc020509a:	bf4d                	j	ffffffffc020504c <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc020509c:	00002617          	auipc	a2,0x2
ffffffffc02050a0:	3f460613          	addi	a2,a2,1012 # ffffffffc0207490 <default_pmm_manager+0xd58>
ffffffffc02050a4:	3fc00593          	li	a1,1020
ffffffffc02050a8:	00002517          	auipc	a0,0x2
ffffffffc02050ac:	07850513          	addi	a0,a0,120 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc02050b0:	bdefb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02050b4:	00002617          	auipc	a2,0x2
ffffffffc02050b8:	3bc60613          	addi	a2,a2,956 # ffffffffc0207470 <default_pmm_manager+0xd38>
ffffffffc02050bc:	3ed00593          	li	a1,1005
ffffffffc02050c0:	00002517          	auipc	a0,0x2
ffffffffc02050c4:	06050513          	addi	a0,a0,96 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc02050c8:	bc6fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050cc:	00002697          	auipc	a3,0x2
ffffffffc02050d0:	41468693          	addi	a3,a3,1044 # ffffffffc02074e0 <default_pmm_manager+0xda8>
ffffffffc02050d4:	00001617          	auipc	a2,0x1
ffffffffc02050d8:	2b460613          	addi	a2,a2,692 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02050dc:	40300593          	li	a1,1027
ffffffffc02050e0:	00002517          	auipc	a0,0x2
ffffffffc02050e4:	04050513          	addi	a0,a0,64 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc02050e8:	ba6fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050ec:	00002697          	auipc	a3,0x2
ffffffffc02050f0:	3cc68693          	addi	a3,a3,972 # ffffffffc02074b8 <default_pmm_manager+0xd80>
ffffffffc02050f4:	00001617          	auipc	a2,0x1
ffffffffc02050f8:	29460613          	addi	a2,a2,660 # ffffffffc0206388 <commands+0x8d0>
ffffffffc02050fc:	40200593          	li	a1,1026
ffffffffc0205100:	00002517          	auipc	a0,0x2
ffffffffc0205104:	02050513          	addi	a0,a0,32 # ffffffffc0207120 <default_pmm_manager+0x9e8>
ffffffffc0205108:	b86fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020510c <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020510c:	1141                	addi	sp,sp,-16
ffffffffc020510e:	e022                	sd	s0,0(sp)
ffffffffc0205110:	e406                	sd	ra,8(sp)
ffffffffc0205112:	000ca417          	auipc	s0,0xca
ffffffffc0205116:	38e40413          	addi	s0,s0,910 # ffffffffc02cf4a0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020511a:	6018                	ld	a4,0(s0)
ffffffffc020511c:	6f1c                	ld	a5,24(a4)
ffffffffc020511e:	dffd                	beqz	a5,ffffffffc020511c <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205120:	0f0000ef          	jal	ra,ffffffffc0205210 <schedule>
ffffffffc0205124:	bfdd                	j	ffffffffc020511a <cpu_idle+0xe>

ffffffffc0205126 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205126:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020512a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020512e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205130:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205132:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205136:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020513a:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020513e:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205142:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205146:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020514a:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020514e:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205152:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205156:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020515a:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020515e:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205162:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205164:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205166:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020516a:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020516e:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205172:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205176:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020517a:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020517e:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205182:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205186:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020518a:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020518e:	8082                	ret

ffffffffc0205190 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205190:	4118                	lw	a4,0(a0)
{
ffffffffc0205192:	1101                	addi	sp,sp,-32
ffffffffc0205194:	ec06                	sd	ra,24(sp)
ffffffffc0205196:	e822                	sd	s0,16(sp)
ffffffffc0205198:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020519a:	478d                	li	a5,3
ffffffffc020519c:	04f70b63          	beq	a4,a5,ffffffffc02051f2 <wakeup_proc+0x62>
ffffffffc02051a0:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051a2:	100027f3          	csrr	a5,sstatus
ffffffffc02051a6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02051a8:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051aa:	ef9d                	bnez	a5,ffffffffc02051e8 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051ac:	4789                	li	a5,2
ffffffffc02051ae:	02f70163          	beq	a4,a5,ffffffffc02051d0 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc02051b2:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc02051b4:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc02051b8:	e491                	bnez	s1,ffffffffc02051c4 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051ba:	60e2                	ld	ra,24(sp)
ffffffffc02051bc:	6442                	ld	s0,16(sp)
ffffffffc02051be:	64a2                	ld	s1,8(sp)
ffffffffc02051c0:	6105                	addi	sp,sp,32
ffffffffc02051c2:	8082                	ret
ffffffffc02051c4:	6442                	ld	s0,16(sp)
ffffffffc02051c6:	60e2                	ld	ra,24(sp)
ffffffffc02051c8:	64a2                	ld	s1,8(sp)
ffffffffc02051ca:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051cc:	fe2fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02051d0:	00002617          	auipc	a2,0x2
ffffffffc02051d4:	37060613          	addi	a2,a2,880 # ffffffffc0207540 <default_pmm_manager+0xe08>
ffffffffc02051d8:	45d1                	li	a1,20
ffffffffc02051da:	00002517          	auipc	a0,0x2
ffffffffc02051de:	34e50513          	addi	a0,a0,846 # ffffffffc0207528 <default_pmm_manager+0xdf0>
ffffffffc02051e2:	b14fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc02051e6:	bfc9                	j	ffffffffc02051b8 <wakeup_proc+0x28>
        intr_disable();
ffffffffc02051e8:	fccfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051ec:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc02051ee:	4485                	li	s1,1
ffffffffc02051f0:	bf75                	j	ffffffffc02051ac <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051f2:	00002697          	auipc	a3,0x2
ffffffffc02051f6:	31668693          	addi	a3,a3,790 # ffffffffc0207508 <default_pmm_manager+0xdd0>
ffffffffc02051fa:	00001617          	auipc	a2,0x1
ffffffffc02051fe:	18e60613          	addi	a2,a2,398 # ffffffffc0206388 <commands+0x8d0>
ffffffffc0205202:	45a5                	li	a1,9
ffffffffc0205204:	00002517          	auipc	a0,0x2
ffffffffc0205208:	32450513          	addi	a0,a0,804 # ffffffffc0207528 <default_pmm_manager+0xdf0>
ffffffffc020520c:	a82fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205210 <schedule>:

void schedule(void)
{
ffffffffc0205210:	1141                	addi	sp,sp,-16
ffffffffc0205212:	e406                	sd	ra,8(sp)
ffffffffc0205214:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205216:	100027f3          	csrr	a5,sstatus
ffffffffc020521a:	8b89                	andi	a5,a5,2
ffffffffc020521c:	4401                	li	s0,0
ffffffffc020521e:	efbd                	bnez	a5,ffffffffc020529c <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205220:	000ca897          	auipc	a7,0xca
ffffffffc0205224:	2808b883          	ld	a7,640(a7) # ffffffffc02cf4a0 <current>
ffffffffc0205228:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020522c:	000ca517          	auipc	a0,0xca
ffffffffc0205230:	27c53503          	ld	a0,636(a0) # ffffffffc02cf4a8 <idleproc>
ffffffffc0205234:	04a88e63          	beq	a7,a0,ffffffffc0205290 <schedule+0x80>
ffffffffc0205238:	0c888693          	addi	a3,a7,200
ffffffffc020523c:	000ca617          	auipc	a2,0xca
ffffffffc0205240:	1f460613          	addi	a2,a2,500 # ffffffffc02cf430 <proc_list>
        le = last;
ffffffffc0205244:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205246:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205248:	4809                	li	a6,2
ffffffffc020524a:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc020524c:	00c78863          	beq	a5,a2,ffffffffc020525c <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc0205250:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205254:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205258:	03070163          	beq	a4,a6,ffffffffc020527a <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc020525c:	fef697e3          	bne	a3,a5,ffffffffc020524a <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205260:	ed89                	bnez	a1,ffffffffc020527a <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205262:	451c                	lw	a5,8(a0)
ffffffffc0205264:	2785                	addiw	a5,a5,1
ffffffffc0205266:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205268:	00a88463          	beq	a7,a0,ffffffffc0205270 <schedule+0x60>
        {
            proc_run(next);
ffffffffc020526c:	e55fe0ef          	jal	ra,ffffffffc02040c0 <proc_run>
    if (flag)
ffffffffc0205270:	e819                	bnez	s0,ffffffffc0205286 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205272:	60a2                	ld	ra,8(sp)
ffffffffc0205274:	6402                	ld	s0,0(sp)
ffffffffc0205276:	0141                	addi	sp,sp,16
ffffffffc0205278:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020527a:	4198                	lw	a4,0(a1)
ffffffffc020527c:	4789                	li	a5,2
ffffffffc020527e:	fef712e3          	bne	a4,a5,ffffffffc0205262 <schedule+0x52>
ffffffffc0205282:	852e                	mv	a0,a1
ffffffffc0205284:	bff9                	j	ffffffffc0205262 <schedule+0x52>
}
ffffffffc0205286:	6402                	ld	s0,0(sp)
ffffffffc0205288:	60a2                	ld	ra,8(sp)
ffffffffc020528a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020528c:	f22fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205290:	000ca617          	auipc	a2,0xca
ffffffffc0205294:	1a060613          	addi	a2,a2,416 # ffffffffc02cf430 <proc_list>
ffffffffc0205298:	86b2                	mv	a3,a2
ffffffffc020529a:	b76d                	j	ffffffffc0205244 <schedule+0x34>
        intr_disable();
ffffffffc020529c:	f18fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02052a0:	4405                	li	s0,1
ffffffffc02052a2:	bfbd                	j	ffffffffc0205220 <schedule+0x10>

ffffffffc02052a4 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052a4:	000ca797          	auipc	a5,0xca
ffffffffc02052a8:	1fc7b783          	ld	a5,508(a5) # ffffffffc02cf4a0 <current>
}
ffffffffc02052ac:	43c8                	lw	a0,4(a5)
ffffffffc02052ae:	8082                	ret

ffffffffc02052b0 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052b0:	4501                	li	a0,0
ffffffffc02052b2:	8082                	ret

ffffffffc02052b4 <sys_putc>:
    cputchar(c);
ffffffffc02052b4:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052b6:	1141                	addi	sp,sp,-16
ffffffffc02052b8:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052ba:	f11fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc02052be:	60a2                	ld	ra,8(sp)
ffffffffc02052c0:	4501                	li	a0,0
ffffffffc02052c2:	0141                	addi	sp,sp,16
ffffffffc02052c4:	8082                	ret

ffffffffc02052c6 <sys_kill>:
    return do_kill(pid);
ffffffffc02052c6:	4108                	lw	a0,0(a0)
ffffffffc02052c8:	c31ff06f          	j	ffffffffc0204ef8 <do_kill>

ffffffffc02052cc <sys_yield>:
    return do_yield();
ffffffffc02052cc:	bdfff06f          	j	ffffffffc0204eaa <do_yield>

ffffffffc02052d0 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052d0:	6d14                	ld	a3,24(a0)
ffffffffc02052d2:	6910                	ld	a2,16(a0)
ffffffffc02052d4:	650c                	ld	a1,8(a0)
ffffffffc02052d6:	6108                	ld	a0,0(a0)
ffffffffc02052d8:	ebeff06f          	j	ffffffffc0204996 <do_execve>

ffffffffc02052dc <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052dc:	650c                	ld	a1,8(a0)
ffffffffc02052de:	4108                	lw	a0,0(a0)
ffffffffc02052e0:	bdbff06f          	j	ffffffffc0204eba <do_wait>

ffffffffc02052e4 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052e4:	000ca797          	auipc	a5,0xca
ffffffffc02052e8:	1bc7b783          	ld	a5,444(a5) # ffffffffc02cf4a0 <current>
ffffffffc02052ec:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052ee:	4501                	li	a0,0
ffffffffc02052f0:	6a0c                	ld	a1,16(a2)
ffffffffc02052f2:	e37fe06f          	j	ffffffffc0204128 <do_fork>

ffffffffc02052f6 <sys_exit>:
    return do_exit(error_code);
ffffffffc02052f6:	4108                	lw	a0,0(a0)
ffffffffc02052f8:	a5eff06f          	j	ffffffffc0204556 <do_exit>

ffffffffc02052fc <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02052fc:	715d                	addi	sp,sp,-80
ffffffffc02052fe:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205300:	000ca497          	auipc	s1,0xca
ffffffffc0205304:	1a048493          	addi	s1,s1,416 # ffffffffc02cf4a0 <current>
ffffffffc0205308:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020530a:	e0a2                	sd	s0,64(sp)
ffffffffc020530c:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020530e:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205310:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205312:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205314:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205318:	0327ee63          	bltu	a5,s2,ffffffffc0205354 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020531c:	00391713          	slli	a4,s2,0x3
ffffffffc0205320:	00002797          	auipc	a5,0x2
ffffffffc0205324:	28878793          	addi	a5,a5,648 # ffffffffc02075a8 <syscalls>
ffffffffc0205328:	97ba                	add	a5,a5,a4
ffffffffc020532a:	639c                	ld	a5,0(a5)
ffffffffc020532c:	c785                	beqz	a5,ffffffffc0205354 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020532e:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205330:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205332:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205334:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205336:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205338:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc020533a:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020533c:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020533e:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205340:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205342:	0028                	addi	a0,sp,8
ffffffffc0205344:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205346:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205348:	e828                	sd	a0,80(s0)
}
ffffffffc020534a:	6406                	ld	s0,64(sp)
ffffffffc020534c:	74e2                	ld	s1,56(sp)
ffffffffc020534e:	7942                	ld	s2,48(sp)
ffffffffc0205350:	6161                	addi	sp,sp,80
ffffffffc0205352:	8082                	ret
    print_trapframe(tf);
ffffffffc0205354:	8522                	mv	a0,s0
ffffffffc0205356:	84ffb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020535a:	609c                	ld	a5,0(s1)
ffffffffc020535c:	86ca                	mv	a3,s2
ffffffffc020535e:	00002617          	auipc	a2,0x2
ffffffffc0205362:	20260613          	addi	a2,a2,514 # ffffffffc0207560 <default_pmm_manager+0xe28>
ffffffffc0205366:	43d8                	lw	a4,4(a5)
ffffffffc0205368:	06200593          	li	a1,98
ffffffffc020536c:	0b478793          	addi	a5,a5,180
ffffffffc0205370:	00002517          	auipc	a0,0x2
ffffffffc0205374:	22050513          	addi	a0,a0,544 # ffffffffc0207590 <default_pmm_manager+0xe58>
ffffffffc0205378:	916fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020537c <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020537c:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205380:	2785                	addiw	a5,a5,1
ffffffffc0205382:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205386:	02000793          	li	a5,32
ffffffffc020538a:	9f8d                	subw	a5,a5,a1
}
ffffffffc020538c:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205390:	8082                	ret

ffffffffc0205392 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205392:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205396:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205398:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020539c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020539e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053a2:	f022                	sd	s0,32(sp)
ffffffffc02053a4:	ec26                	sd	s1,24(sp)
ffffffffc02053a6:	e84a                	sd	s2,16(sp)
ffffffffc02053a8:	f406                	sd	ra,40(sp)
ffffffffc02053aa:	e44e                	sd	s3,8(sp)
ffffffffc02053ac:	84aa                	mv	s1,a0
ffffffffc02053ae:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053b0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02053b4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02053b6:	03067e63          	bgeu	a2,a6,ffffffffc02053f2 <printnum+0x60>
ffffffffc02053ba:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053bc:	00805763          	blez	s0,ffffffffc02053ca <printnum+0x38>
ffffffffc02053c0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053c2:	85ca                	mv	a1,s2
ffffffffc02053c4:	854e                	mv	a0,s3
ffffffffc02053c6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053c8:	fc65                	bnez	s0,ffffffffc02053c0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053ca:	1a02                	slli	s4,s4,0x20
ffffffffc02053cc:	00002797          	auipc	a5,0x2
ffffffffc02053d0:	2dc78793          	addi	a5,a5,732 # ffffffffc02076a8 <syscalls+0x100>
ffffffffc02053d4:	020a5a13          	srli	s4,s4,0x20
ffffffffc02053d8:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053da:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053dc:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02053e0:	70a2                	ld	ra,40(sp)
ffffffffc02053e2:	69a2                	ld	s3,8(sp)
ffffffffc02053e4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053e6:	85ca                	mv	a1,s2
ffffffffc02053e8:	87a6                	mv	a5,s1
}
ffffffffc02053ea:	6942                	ld	s2,16(sp)
ffffffffc02053ec:	64e2                	ld	s1,24(sp)
ffffffffc02053ee:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053f0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053f2:	03065633          	divu	a2,a2,a6
ffffffffc02053f6:	8722                	mv	a4,s0
ffffffffc02053f8:	f9bff0ef          	jal	ra,ffffffffc0205392 <printnum>
ffffffffc02053fc:	b7f9                	j	ffffffffc02053ca <printnum+0x38>

ffffffffc02053fe <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02053fe:	7119                	addi	sp,sp,-128
ffffffffc0205400:	f4a6                	sd	s1,104(sp)
ffffffffc0205402:	f0ca                	sd	s2,96(sp)
ffffffffc0205404:	ecce                	sd	s3,88(sp)
ffffffffc0205406:	e8d2                	sd	s4,80(sp)
ffffffffc0205408:	e4d6                	sd	s5,72(sp)
ffffffffc020540a:	e0da                	sd	s6,64(sp)
ffffffffc020540c:	fc5e                	sd	s7,56(sp)
ffffffffc020540e:	f06a                	sd	s10,32(sp)
ffffffffc0205410:	fc86                	sd	ra,120(sp)
ffffffffc0205412:	f8a2                	sd	s0,112(sp)
ffffffffc0205414:	f862                	sd	s8,48(sp)
ffffffffc0205416:	f466                	sd	s9,40(sp)
ffffffffc0205418:	ec6e                	sd	s11,24(sp)
ffffffffc020541a:	892a                	mv	s2,a0
ffffffffc020541c:	84ae                	mv	s1,a1
ffffffffc020541e:	8d32                	mv	s10,a2
ffffffffc0205420:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205422:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205426:	5b7d                	li	s6,-1
ffffffffc0205428:	00002a97          	auipc	s5,0x2
ffffffffc020542c:	2aca8a93          	addi	s5,s5,684 # ffffffffc02076d4 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205430:	00002b97          	auipc	s7,0x2
ffffffffc0205434:	4c0b8b93          	addi	s7,s7,1216 # ffffffffc02078f0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205438:	000d4503          	lbu	a0,0(s10)
ffffffffc020543c:	001d0413          	addi	s0,s10,1
ffffffffc0205440:	01350a63          	beq	a0,s3,ffffffffc0205454 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205444:	c121                	beqz	a0,ffffffffc0205484 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205446:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205448:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020544a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020544c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205450:	ff351ae3          	bne	a0,s3,ffffffffc0205444 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205454:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205458:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020545c:	4c81                	li	s9,0
ffffffffc020545e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205460:	5c7d                	li	s8,-1
ffffffffc0205462:	5dfd                	li	s11,-1
ffffffffc0205464:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205468:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020546a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020546e:	0ff5f593          	zext.b	a1,a1
ffffffffc0205472:	00140d13          	addi	s10,s0,1
ffffffffc0205476:	04b56263          	bltu	a0,a1,ffffffffc02054ba <vprintfmt+0xbc>
ffffffffc020547a:	058a                	slli	a1,a1,0x2
ffffffffc020547c:	95d6                	add	a1,a1,s5
ffffffffc020547e:	4194                	lw	a3,0(a1)
ffffffffc0205480:	96d6                	add	a3,a3,s5
ffffffffc0205482:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205484:	70e6                	ld	ra,120(sp)
ffffffffc0205486:	7446                	ld	s0,112(sp)
ffffffffc0205488:	74a6                	ld	s1,104(sp)
ffffffffc020548a:	7906                	ld	s2,96(sp)
ffffffffc020548c:	69e6                	ld	s3,88(sp)
ffffffffc020548e:	6a46                	ld	s4,80(sp)
ffffffffc0205490:	6aa6                	ld	s5,72(sp)
ffffffffc0205492:	6b06                	ld	s6,64(sp)
ffffffffc0205494:	7be2                	ld	s7,56(sp)
ffffffffc0205496:	7c42                	ld	s8,48(sp)
ffffffffc0205498:	7ca2                	ld	s9,40(sp)
ffffffffc020549a:	7d02                	ld	s10,32(sp)
ffffffffc020549c:	6de2                	ld	s11,24(sp)
ffffffffc020549e:	6109                	addi	sp,sp,128
ffffffffc02054a0:	8082                	ret
            padc = '0';
ffffffffc02054a2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02054a4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054a8:	846a                	mv	s0,s10
ffffffffc02054aa:	00140d13          	addi	s10,s0,1
ffffffffc02054ae:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054b2:	0ff5f593          	zext.b	a1,a1
ffffffffc02054b6:	fcb572e3          	bgeu	a0,a1,ffffffffc020547a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02054ba:	85a6                	mv	a1,s1
ffffffffc02054bc:	02500513          	li	a0,37
ffffffffc02054c0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02054c2:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054c6:	8d22                	mv	s10,s0
ffffffffc02054c8:	f73788e3          	beq	a5,s3,ffffffffc0205438 <vprintfmt+0x3a>
ffffffffc02054cc:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02054d0:	1d7d                	addi	s10,s10,-1
ffffffffc02054d2:	ff379de3          	bne	a5,s3,ffffffffc02054cc <vprintfmt+0xce>
ffffffffc02054d6:	b78d                	j	ffffffffc0205438 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02054d8:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02054dc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054e0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02054e2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02054e6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054ea:	02d86463          	bltu	a6,a3,ffffffffc0205512 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02054ee:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02054f2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02054f6:	0186873b          	addw	a4,a3,s8
ffffffffc02054fa:	0017171b          	slliw	a4,a4,0x1
ffffffffc02054fe:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205500:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205504:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205506:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020550a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020550e:	fed870e3          	bgeu	a6,a3,ffffffffc02054ee <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205512:	f40ddce3          	bgez	s11,ffffffffc020546a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205516:	8de2                	mv	s11,s8
ffffffffc0205518:	5c7d                	li	s8,-1
ffffffffc020551a:	bf81                	j	ffffffffc020546a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020551c:	fffdc693          	not	a3,s11
ffffffffc0205520:	96fd                	srai	a3,a3,0x3f
ffffffffc0205522:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205526:	00144603          	lbu	a2,1(s0)
ffffffffc020552a:	2d81                	sext.w	s11,s11
ffffffffc020552c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020552e:	bf35                	j	ffffffffc020546a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205530:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205534:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205538:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020553a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020553c:	bfd9                	j	ffffffffc0205512 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020553e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205540:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205544:	01174463          	blt	a4,a7,ffffffffc020554c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205548:	1a088e63          	beqz	a7,ffffffffc0205704 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020554c:	000a3603          	ld	a2,0(s4)
ffffffffc0205550:	46c1                	li	a3,16
ffffffffc0205552:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205554:	2781                	sext.w	a5,a5
ffffffffc0205556:	876e                	mv	a4,s11
ffffffffc0205558:	85a6                	mv	a1,s1
ffffffffc020555a:	854a                	mv	a0,s2
ffffffffc020555c:	e37ff0ef          	jal	ra,ffffffffc0205392 <printnum>
            break;
ffffffffc0205560:	bde1                	j	ffffffffc0205438 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205562:	000a2503          	lw	a0,0(s4)
ffffffffc0205566:	85a6                	mv	a1,s1
ffffffffc0205568:	0a21                	addi	s4,s4,8
ffffffffc020556a:	9902                	jalr	s2
            break;
ffffffffc020556c:	b5f1                	j	ffffffffc0205438 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020556e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205570:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205574:	01174463          	blt	a4,a7,ffffffffc020557c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205578:	18088163          	beqz	a7,ffffffffc02056fa <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020557c:	000a3603          	ld	a2,0(s4)
ffffffffc0205580:	46a9                	li	a3,10
ffffffffc0205582:	8a2e                	mv	s4,a1
ffffffffc0205584:	bfc1                	j	ffffffffc0205554 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205586:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020558a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020558c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020558e:	bdf1                	j	ffffffffc020546a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205590:	85a6                	mv	a1,s1
ffffffffc0205592:	02500513          	li	a0,37
ffffffffc0205596:	9902                	jalr	s2
            break;
ffffffffc0205598:	b545                	j	ffffffffc0205438 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020559a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020559e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055a0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055a2:	b5e1                	j	ffffffffc020546a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02055a4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055a6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055aa:	01174463          	blt	a4,a7,ffffffffc02055b2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02055ae:	14088163          	beqz	a7,ffffffffc02056f0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02055b2:	000a3603          	ld	a2,0(s4)
ffffffffc02055b6:	46a1                	li	a3,8
ffffffffc02055b8:	8a2e                	mv	s4,a1
ffffffffc02055ba:	bf69                	j	ffffffffc0205554 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02055bc:	03000513          	li	a0,48
ffffffffc02055c0:	85a6                	mv	a1,s1
ffffffffc02055c2:	e03e                	sd	a5,0(sp)
ffffffffc02055c4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02055c6:	85a6                	mv	a1,s1
ffffffffc02055c8:	07800513          	li	a0,120
ffffffffc02055cc:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055ce:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055d0:	6782                	ld	a5,0(sp)
ffffffffc02055d2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055d4:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02055d8:	bfb5                	j	ffffffffc0205554 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055da:	000a3403          	ld	s0,0(s4)
ffffffffc02055de:	008a0713          	addi	a4,s4,8
ffffffffc02055e2:	e03a                	sd	a4,0(sp)
ffffffffc02055e4:	14040263          	beqz	s0,ffffffffc0205728 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02055e8:	0fb05763          	blez	s11,ffffffffc02056d6 <vprintfmt+0x2d8>
ffffffffc02055ec:	02d00693          	li	a3,45
ffffffffc02055f0:	0cd79163          	bne	a5,a3,ffffffffc02056b2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055f4:	00044783          	lbu	a5,0(s0)
ffffffffc02055f8:	0007851b          	sext.w	a0,a5
ffffffffc02055fc:	cf85                	beqz	a5,ffffffffc0205634 <vprintfmt+0x236>
ffffffffc02055fe:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205602:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205606:	000c4563          	bltz	s8,ffffffffc0205610 <vprintfmt+0x212>
ffffffffc020560a:	3c7d                	addiw	s8,s8,-1
ffffffffc020560c:	036c0263          	beq	s8,s6,ffffffffc0205630 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205610:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205612:	0e0c8e63          	beqz	s9,ffffffffc020570e <vprintfmt+0x310>
ffffffffc0205616:	3781                	addiw	a5,a5,-32
ffffffffc0205618:	0ef47b63          	bgeu	s0,a5,ffffffffc020570e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020561c:	03f00513          	li	a0,63
ffffffffc0205620:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205622:	000a4783          	lbu	a5,0(s4)
ffffffffc0205626:	3dfd                	addiw	s11,s11,-1
ffffffffc0205628:	0a05                	addi	s4,s4,1
ffffffffc020562a:	0007851b          	sext.w	a0,a5
ffffffffc020562e:	ffe1                	bnez	a5,ffffffffc0205606 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205630:	01b05963          	blez	s11,ffffffffc0205642 <vprintfmt+0x244>
ffffffffc0205634:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205636:	85a6                	mv	a1,s1
ffffffffc0205638:	02000513          	li	a0,32
ffffffffc020563c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020563e:	fe0d9be3          	bnez	s11,ffffffffc0205634 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205642:	6a02                	ld	s4,0(sp)
ffffffffc0205644:	bbd5                	j	ffffffffc0205438 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205646:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205648:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020564c:	01174463          	blt	a4,a7,ffffffffc0205654 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205650:	08088d63          	beqz	a7,ffffffffc02056ea <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205654:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205658:	0a044d63          	bltz	s0,ffffffffc0205712 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020565c:	8622                	mv	a2,s0
ffffffffc020565e:	8a66                	mv	s4,s9
ffffffffc0205660:	46a9                	li	a3,10
ffffffffc0205662:	bdcd                	j	ffffffffc0205554 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205664:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205668:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020566a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020566c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205670:	8fb5                	xor	a5,a5,a3
ffffffffc0205672:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205676:	02d74163          	blt	a4,a3,ffffffffc0205698 <vprintfmt+0x29a>
ffffffffc020567a:	00369793          	slli	a5,a3,0x3
ffffffffc020567e:	97de                	add	a5,a5,s7
ffffffffc0205680:	639c                	ld	a5,0(a5)
ffffffffc0205682:	cb99                	beqz	a5,ffffffffc0205698 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205684:	86be                	mv	a3,a5
ffffffffc0205686:	00000617          	auipc	a2,0x0
ffffffffc020568a:	1f260613          	addi	a2,a2,498 # ffffffffc0205878 <etext+0x2c>
ffffffffc020568e:	85a6                	mv	a1,s1
ffffffffc0205690:	854a                	mv	a0,s2
ffffffffc0205692:	0ce000ef          	jal	ra,ffffffffc0205760 <printfmt>
ffffffffc0205696:	b34d                	j	ffffffffc0205438 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205698:	00002617          	auipc	a2,0x2
ffffffffc020569c:	03060613          	addi	a2,a2,48 # ffffffffc02076c8 <syscalls+0x120>
ffffffffc02056a0:	85a6                	mv	a1,s1
ffffffffc02056a2:	854a                	mv	a0,s2
ffffffffc02056a4:	0bc000ef          	jal	ra,ffffffffc0205760 <printfmt>
ffffffffc02056a8:	bb41                	j	ffffffffc0205438 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02056aa:	00002417          	auipc	s0,0x2
ffffffffc02056ae:	01640413          	addi	s0,s0,22 # ffffffffc02076c0 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056b2:	85e2                	mv	a1,s8
ffffffffc02056b4:	8522                	mv	a0,s0
ffffffffc02056b6:	e43e                	sd	a5,8(sp)
ffffffffc02056b8:	0e2000ef          	jal	ra,ffffffffc020579a <strnlen>
ffffffffc02056bc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02056c0:	01b05b63          	blez	s11,ffffffffc02056d6 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02056c4:	67a2                	ld	a5,8(sp)
ffffffffc02056c6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056ca:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02056cc:	85a6                	mv	a1,s1
ffffffffc02056ce:	8552                	mv	a0,s4
ffffffffc02056d0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056d2:	fe0d9ce3          	bnez	s11,ffffffffc02056ca <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056d6:	00044783          	lbu	a5,0(s0)
ffffffffc02056da:	00140a13          	addi	s4,s0,1
ffffffffc02056de:	0007851b          	sext.w	a0,a5
ffffffffc02056e2:	d3a5                	beqz	a5,ffffffffc0205642 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056e4:	05e00413          	li	s0,94
ffffffffc02056e8:	bf39                	j	ffffffffc0205606 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02056ea:	000a2403          	lw	s0,0(s4)
ffffffffc02056ee:	b7ad                	j	ffffffffc0205658 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02056f0:	000a6603          	lwu	a2,0(s4)
ffffffffc02056f4:	46a1                	li	a3,8
ffffffffc02056f6:	8a2e                	mv	s4,a1
ffffffffc02056f8:	bdb1                	j	ffffffffc0205554 <vprintfmt+0x156>
ffffffffc02056fa:	000a6603          	lwu	a2,0(s4)
ffffffffc02056fe:	46a9                	li	a3,10
ffffffffc0205700:	8a2e                	mv	s4,a1
ffffffffc0205702:	bd89                	j	ffffffffc0205554 <vprintfmt+0x156>
ffffffffc0205704:	000a6603          	lwu	a2,0(s4)
ffffffffc0205708:	46c1                	li	a3,16
ffffffffc020570a:	8a2e                	mv	s4,a1
ffffffffc020570c:	b5a1                	j	ffffffffc0205554 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020570e:	9902                	jalr	s2
ffffffffc0205710:	bf09                	j	ffffffffc0205622 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205712:	85a6                	mv	a1,s1
ffffffffc0205714:	02d00513          	li	a0,45
ffffffffc0205718:	e03e                	sd	a5,0(sp)
ffffffffc020571a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020571c:	6782                	ld	a5,0(sp)
ffffffffc020571e:	8a66                	mv	s4,s9
ffffffffc0205720:	40800633          	neg	a2,s0
ffffffffc0205724:	46a9                	li	a3,10
ffffffffc0205726:	b53d                	j	ffffffffc0205554 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205728:	03b05163          	blez	s11,ffffffffc020574a <vprintfmt+0x34c>
ffffffffc020572c:	02d00693          	li	a3,45
ffffffffc0205730:	f6d79de3          	bne	a5,a3,ffffffffc02056aa <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205734:	00002417          	auipc	s0,0x2
ffffffffc0205738:	f8c40413          	addi	s0,s0,-116 # ffffffffc02076c0 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020573c:	02800793          	li	a5,40
ffffffffc0205740:	02800513          	li	a0,40
ffffffffc0205744:	00140a13          	addi	s4,s0,1
ffffffffc0205748:	bd6d                	j	ffffffffc0205602 <vprintfmt+0x204>
ffffffffc020574a:	00002a17          	auipc	s4,0x2
ffffffffc020574e:	f77a0a13          	addi	s4,s4,-137 # ffffffffc02076c1 <syscalls+0x119>
ffffffffc0205752:	02800513          	li	a0,40
ffffffffc0205756:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020575a:	05e00413          	li	s0,94
ffffffffc020575e:	b565                	j	ffffffffc0205606 <vprintfmt+0x208>

ffffffffc0205760 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205760:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205762:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205766:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205768:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020576a:	ec06                	sd	ra,24(sp)
ffffffffc020576c:	f83a                	sd	a4,48(sp)
ffffffffc020576e:	fc3e                	sd	a5,56(sp)
ffffffffc0205770:	e0c2                	sd	a6,64(sp)
ffffffffc0205772:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205774:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205776:	c89ff0ef          	jal	ra,ffffffffc02053fe <vprintfmt>
}
ffffffffc020577a:	60e2                	ld	ra,24(sp)
ffffffffc020577c:	6161                	addi	sp,sp,80
ffffffffc020577e:	8082                	ret

ffffffffc0205780 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205780:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205784:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205786:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205788:	cb81                	beqz	a5,ffffffffc0205798 <strlen+0x18>
        cnt ++;
ffffffffc020578a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020578c:	00a707b3          	add	a5,a4,a0
ffffffffc0205790:	0007c783          	lbu	a5,0(a5)
ffffffffc0205794:	fbfd                	bnez	a5,ffffffffc020578a <strlen+0xa>
ffffffffc0205796:	8082                	ret
    }
    return cnt;
}
ffffffffc0205798:	8082                	ret

ffffffffc020579a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020579a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020579c:	e589                	bnez	a1,ffffffffc02057a6 <strnlen+0xc>
ffffffffc020579e:	a811                	j	ffffffffc02057b2 <strnlen+0x18>
        cnt ++;
ffffffffc02057a0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057a2:	00f58863          	beq	a1,a5,ffffffffc02057b2 <strnlen+0x18>
ffffffffc02057a6:	00f50733          	add	a4,a0,a5
ffffffffc02057aa:	00074703          	lbu	a4,0(a4)
ffffffffc02057ae:	fb6d                	bnez	a4,ffffffffc02057a0 <strnlen+0x6>
ffffffffc02057b0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02057b2:	852e                	mv	a0,a1
ffffffffc02057b4:	8082                	ret

ffffffffc02057b6 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02057b6:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02057b8:	0005c703          	lbu	a4,0(a1)
ffffffffc02057bc:	0785                	addi	a5,a5,1
ffffffffc02057be:	0585                	addi	a1,a1,1
ffffffffc02057c0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057c4:	fb75                	bnez	a4,ffffffffc02057b8 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057c6:	8082                	ret

ffffffffc02057c8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057c8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057cc:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057d0:	cb89                	beqz	a5,ffffffffc02057e2 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02057d2:	0505                	addi	a0,a0,1
ffffffffc02057d4:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057d6:	fee789e3          	beq	a5,a4,ffffffffc02057c8 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057da:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057de:	9d19                	subw	a0,a0,a4
ffffffffc02057e0:	8082                	ret
ffffffffc02057e2:	4501                	li	a0,0
ffffffffc02057e4:	bfed                	j	ffffffffc02057de <strcmp+0x16>

ffffffffc02057e6 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057e6:	c20d                	beqz	a2,ffffffffc0205808 <strncmp+0x22>
ffffffffc02057e8:	962e                	add	a2,a2,a1
ffffffffc02057ea:	a031                	j	ffffffffc02057f6 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02057ec:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057ee:	00e79a63          	bne	a5,a4,ffffffffc0205802 <strncmp+0x1c>
ffffffffc02057f2:	00b60b63          	beq	a2,a1,ffffffffc0205808 <strncmp+0x22>
ffffffffc02057f6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057fa:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057fc:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205800:	f7f5                	bnez	a5,ffffffffc02057ec <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205802:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205806:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205808:	4501                	li	a0,0
ffffffffc020580a:	8082                	ret

ffffffffc020580c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020580c:	00054783          	lbu	a5,0(a0)
ffffffffc0205810:	c799                	beqz	a5,ffffffffc020581e <strchr+0x12>
        if (*s == c) {
ffffffffc0205812:	00f58763          	beq	a1,a5,ffffffffc0205820 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205816:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020581a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020581c:	fbfd                	bnez	a5,ffffffffc0205812 <strchr+0x6>
    }
    return NULL;
ffffffffc020581e:	4501                	li	a0,0
}
ffffffffc0205820:	8082                	ret

ffffffffc0205822 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205822:	ca01                	beqz	a2,ffffffffc0205832 <memset+0x10>
ffffffffc0205824:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205826:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205828:	0785                	addi	a5,a5,1
ffffffffc020582a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020582e:	fec79de3          	bne	a5,a2,ffffffffc0205828 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205832:	8082                	ret

ffffffffc0205834 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205834:	ca19                	beqz	a2,ffffffffc020584a <memcpy+0x16>
ffffffffc0205836:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205838:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020583a:	0005c703          	lbu	a4,0(a1)
ffffffffc020583e:	0585                	addi	a1,a1,1
ffffffffc0205840:	0785                	addi	a5,a5,1
ffffffffc0205842:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205846:	fec59ae3          	bne	a1,a2,ffffffffc020583a <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020584a:	8082                	ret
