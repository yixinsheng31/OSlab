
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
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	11650513          	addi	a0,a0,278 # ffffffffc02a6160 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	5b260613          	addi	a2,a2,1458 # ffffffffc02aa604 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	616050ef          	jal	ra,ffffffffc0205678 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	63a58593          	addi	a1,a1,1594 # ffffffffc02056a8 <etext+0x6>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	65250513          	addi	a0,a0,1618 # ffffffffc02056c8 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6a4020ef          	jal	ra,ffffffffc020272a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	171030ef          	jal	ra,ffffffffc0203a02 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	535040ef          	jal	ra,ffffffffc0204dca <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	6c1040ef          	jal	ra,ffffffffc0204f62 <cpu_idle>

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
ffffffffc02000c0:	61450513          	addi	a0,a0,1556 # ffffffffc02056d0 <etext+0x2e>
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
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	08eb8b93          	addi	s7,s7,142 # ffffffffc02a6160 <buf>
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
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	03250513          	addi	a0,a0,50 # ffffffffc02a6160 <buf>
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
ffffffffc0200188:	0cc050ef          	jal	ra,ffffffffc0205254 <vprintfmt>
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
ffffffffc02001be:	096050ef          	jal	ra,ffffffffc0205254 <vprintfmt>
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
ffffffffc0200222:	4ba50513          	addi	a0,a0,1210 # ffffffffc02056d8 <etext+0x36>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	4c450513          	addi	a0,a0,1220 # ffffffffc02056f8 <etext+0x56>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	46258593          	addi	a1,a1,1122 # ffffffffc02056a2 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	4d050513          	addi	a0,a0,1232 # ffffffffc0205718 <etext+0x76>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	f0c58593          	addi	a1,a1,-244 # ffffffffc02a6160 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205738 <etext+0x96>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	39c58593          	addi	a1,a1,924 # ffffffffc02aa604 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	4e850513          	addi	a0,a0,1256 # ffffffffc0205758 <etext+0xb6>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000aa597          	auipc	a1,0xaa
ffffffffc0200280:	78758593          	addi	a1,a1,1927 # ffffffffc02aaa03 <end+0x3ff>
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
ffffffffc02002a2:	4da50513          	addi	a0,a0,1242 # ffffffffc0205778 <etext+0xd6>
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
ffffffffc02002b0:	4fc60613          	addi	a2,a2,1276 # ffffffffc02057a8 <etext+0x106>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	50850513          	addi	a0,a0,1288 # ffffffffc02057c0 <etext+0x11e>
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
ffffffffc02002cc:	51060613          	addi	a2,a2,1296 # ffffffffc02057d8 <etext+0x136>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	52858593          	addi	a1,a1,1320 # ffffffffc02057f8 <etext+0x156>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	52850513          	addi	a0,a0,1320 # ffffffffc0205800 <etext+0x15e>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	52a60613          	addi	a2,a2,1322 # ffffffffc0205810 <etext+0x16e>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	54a58593          	addi	a1,a1,1354 # ffffffffc0205838 <etext+0x196>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	50a50513          	addi	a0,a0,1290 # ffffffffc0205800 <etext+0x15e>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	54660613          	addi	a2,a2,1350 # ffffffffc0205848 <etext+0x1a6>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	55e58593          	addi	a1,a1,1374 # ffffffffc0205868 <etext+0x1c6>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	4ee50513          	addi	a0,a0,1262 # ffffffffc0205800 <etext+0x15e>
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
ffffffffc0200350:	52c50513          	addi	a0,a0,1324 # ffffffffc0205878 <etext+0x1d6>
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
ffffffffc0200372:	53250513          	addi	a0,a0,1330 # ffffffffc02058a0 <etext+0x1fe>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	58cc0c13          	addi	s8,s8,1420 # ffffffffc0205910 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	53c90913          	addi	s2,s2,1340 # ffffffffc02058c8 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	53c48493          	addi	s1,s1,1340 # ffffffffc02058d0 <etext+0x22e>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	53ab0b13          	addi	s6,s6,1338 # ffffffffc02058d8 <etext+0x236>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	452a0a13          	addi	s4,s4,1106 # ffffffffc02057f8 <etext+0x156>
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
ffffffffc02003cc:	548d0d13          	addi	s10,s10,1352 # ffffffffc0205910 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	248050ef          	jal	ra,ffffffffc020561e <strcmp>
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
ffffffffc02003ea:	234050ef          	jal	ra,ffffffffc020561e <strcmp>
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
ffffffffc0200428:	23a050ef          	jal	ra,ffffffffc0205662 <strchr>
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
ffffffffc0200466:	1fc050ef          	jal	ra,ffffffffc0205662 <strchr>
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
ffffffffc0200484:	47850513          	addi	a0,a0,1144 # ffffffffc02058f8 <etext+0x256>
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
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	0fa30313          	addi	t1,t1,250 # ffffffffc02aa588 <is_panic>
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
ffffffffc02004c0:	49c50513          	addi	a0,a0,1180 # ffffffffc0205958 <commands+0x48>
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
ffffffffc02004d6:	58e50513          	addi	a0,a0,1422 # ffffffffc0206a60 <default_pmm_manager+0x578>
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
ffffffffc020050a:	47250513          	addi	a0,a0,1138 # ffffffffc0205978 <commands+0x68>
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
ffffffffc020052a:	53a50513          	addi	a0,a0,1338 # ffffffffc0206a60 <default_pmm_manager+0x578>
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
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd598>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	04f73c23          	sd	a5,88(a4) # ffffffffc02aa598 <timebase>
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
ffffffffc0200564:	43850513          	addi	a0,a0,1080 # ffffffffc0205998 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	0207b423          	sd	zero,40(a5) # ffffffffc02aa590 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	0227b783          	ld	a5,34(a5) # ffffffffc02aa598 <timebase>
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
ffffffffc0200604:	3b850513          	addi	a0,a0,952 # ffffffffc02059b8 <commands+0xa8>
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
ffffffffc0200632:	39a50513          	addi	a0,a0,922 # ffffffffc02059c8 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	39450513          	addi	a0,a0,916 # ffffffffc02059d8 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	39c50513          	addi	a0,a0,924 # ffffffffc02059f0 <commands+0xe0>
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
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe358e9>
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
ffffffffc0200712:	33290913          	addi	s2,s2,818 # ffffffffc0205a40 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	31c48493          	addi	s1,s1,796 # ffffffffc0205a38 <commands+0x128>
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
ffffffffc0200774:	34850513          	addi	a0,a0,840 # ffffffffc0205ab8 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	37450513          	addi	a0,a0,884 # ffffffffc0205af0 <commands+0x1e0>
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
ffffffffc02007c0:	25450513          	addi	a0,a0,596 # ffffffffc0205a10 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	60d040ef          	jal	ra,ffffffffc02055d6 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	665040ef          	jal	ra,ffffffffc020563c <strncmp>
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
ffffffffc020086e:	5b1040ef          	jal	ra,ffffffffc020561e <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	1c650513          	addi	a0,a0,454 # ffffffffc0205a48 <commands+0x138>
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
ffffffffc0200954:	11850513          	addi	a0,a0,280 # ffffffffc0205a68 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	11e50513          	addi	a0,a0,286 # ffffffffc0205a80 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	12c50513          	addi	a0,a0,300 # ffffffffc0205aa0 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	17050513          	addi	a0,a0,368 # ffffffffc0205af0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	c087bc23          	sd	s0,-1000(a5) # ffffffffc02aa5a0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	c167bc23          	sd	s6,-1000(a5) # ffffffffc02aa5a8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	c0653503          	ld	a0,-1018(a0) # ffffffffc02aa5a0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	c0453503          	ld	a0,-1020(a0) # ffffffffc02aa5a8 <memory_size>
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
ffffffffc02009c4:	49878793          	addi	a5,a5,1176 # ffffffffc0200e58 <__alltraps>
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
ffffffffc02009e2:	12a50513          	addi	a0,a0,298 # ffffffffc0205b08 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	13250513          	addi	a0,a0,306 # ffffffffc0205b20 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	13c50513          	addi	a0,a0,316 # ffffffffc0205b38 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	14650513          	addi	a0,a0,326 # ffffffffc0205b50 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	15050513          	addi	a0,a0,336 # ffffffffc0205b68 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	15a50513          	addi	a0,a0,346 # ffffffffc0205b80 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	16450513          	addi	a0,a0,356 # ffffffffc0205b98 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	16e50513          	addi	a0,a0,366 # ffffffffc0205bb0 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	17850513          	addi	a0,a0,376 # ffffffffc0205bc8 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	18250513          	addi	a0,a0,386 # ffffffffc0205be0 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	18c50513          	addi	a0,a0,396 # ffffffffc0205bf8 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	19650513          	addi	a0,a0,406 # ffffffffc0205c10 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	1a050513          	addi	a0,a0,416 # ffffffffc0205c28 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	1aa50513          	addi	a0,a0,426 # ffffffffc0205c40 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	1b450513          	addi	a0,a0,436 # ffffffffc0205c58 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	1be50513          	addi	a0,a0,446 # ffffffffc0205c70 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	1c850513          	addi	a0,a0,456 # ffffffffc0205c88 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	1d250513          	addi	a0,a0,466 # ffffffffc0205ca0 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	1dc50513          	addi	a0,a0,476 # ffffffffc0205cb8 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	1e650513          	addi	a0,a0,486 # ffffffffc0205cd0 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	1f050513          	addi	a0,a0,496 # ffffffffc0205ce8 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	1fa50513          	addi	a0,a0,506 # ffffffffc0205d00 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	20450513          	addi	a0,a0,516 # ffffffffc0205d18 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	20e50513          	addi	a0,a0,526 # ffffffffc0205d30 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	21850513          	addi	a0,a0,536 # ffffffffc0205d48 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	22250513          	addi	a0,a0,546 # ffffffffc0205d60 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	22c50513          	addi	a0,a0,556 # ffffffffc0205d78 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	23650513          	addi	a0,a0,566 # ffffffffc0205d90 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	24050513          	addi	a0,a0,576 # ffffffffc0205da8 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	24a50513          	addi	a0,a0,586 # ffffffffc0205dc0 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	25450513          	addi	a0,a0,596 # ffffffffc0205dd8 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	25a50513          	addi	a0,a0,602 # ffffffffc0205df0 <commands+0x4e0>
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
ffffffffc0200bb0:	25c50513          	addi	a0,a0,604 # ffffffffc0205e08 <commands+0x4f8>
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
ffffffffc0200bc8:	25c50513          	addi	a0,a0,604 # ffffffffc0205e20 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	26450513          	addi	a0,a0,612 # ffffffffc0205e38 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	26c50513          	addi	a0,a0,620 # ffffffffc0205e50 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	26850513          	addi	a0,a0,616 # ffffffffc0205e60 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	08f76463          	bltu	a4,a5,ffffffffc0200c98 <interrupt_handler+0x92>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	31470713          	addi	a4,a4,788 # ffffffffc0205f28 <commands+0x618>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	2b250513          	addi	a0,a0,690 # ffffffffc0205ed8 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	28650513          	addi	a0,a0,646 # ffffffffc0205eb8 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	23a50513          	addi	a0,a0,570 # ffffffffc0205e78 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	24e50513          	addi	a0,a0,590 # ffffffffc0205e98 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        ticks++;
ffffffffc0200c5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200c62:	93278793          	addi	a5,a5,-1742 # ffffffffc02aa590 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
        /* reschedule promptly so long-running user code (e.g., spin) yields */
        if (current) {
ffffffffc0200c68:	000aa697          	auipc	a3,0xaa
ffffffffc0200c6c:	9806b683          	ld	a3,-1664(a3) # ffffffffc02aa5e8 <current>
        ticks++;
ffffffffc0200c70:	0705                	addi	a4,a4,1
ffffffffc0200c72:	e398                	sd	a4,0(a5)
        if (current) {
ffffffffc0200c74:	c299                	beqz	a3,ffffffffc0200c7a <interrupt_handler+0x74>
            current->need_resched = 1;
ffffffffc0200c76:	4705                	li	a4,1
ffffffffc0200c78:	ee98                	sd	a4,24(a3)
        }
        /* keep periodic heartbeat output */
        if (ticks % TICK_NUM == 0) {
ffffffffc0200c7a:	639c                	ld	a5,0(a5)
ffffffffc0200c7c:	06400713          	li	a4,100
ffffffffc0200c80:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c84:	cb99                	beqz	a5,ffffffffc0200c9a <interrupt_handler+0x94>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c86:	60a2                	ld	ra,8(sp)
ffffffffc0200c88:	0141                	addi	sp,sp,16
ffffffffc0200c8a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	27c50513          	addi	a0,a0,636 # ffffffffc0205f08 <commands+0x5f8>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c98:	b731                	j	ffffffffc0200ba4 <print_trapframe>
}
ffffffffc0200c9a:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c9c:	06400593          	li	a1,100
ffffffffc0200ca0:	00005517          	auipc	a0,0x5
ffffffffc0200ca4:	25850513          	addi	a0,a0,600 # ffffffffc0205ef8 <commands+0x5e8>
}
ffffffffc0200ca8:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200caa:	ceaff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200cae <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cae:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cb2:	1141                	addi	sp,sp,-16
ffffffffc0200cb4:	e022                	sd	s0,0(sp)
ffffffffc0200cb6:	e406                	sd	ra,8(sp)
ffffffffc0200cb8:	473d                	li	a4,15
ffffffffc0200cba:	842a                	mv	s0,a0
ffffffffc0200cbc:	0cf76463          	bltu	a4,a5,ffffffffc0200d84 <exception_handler+0xd6>
ffffffffc0200cc0:	00005717          	auipc	a4,0x5
ffffffffc0200cc4:	42870713          	addi	a4,a4,1064 # ffffffffc02060e8 <commands+0x7d8>
ffffffffc0200cc8:	078a                	slli	a5,a5,0x2
ffffffffc0200cca:	97ba                	add	a5,a5,a4
ffffffffc0200ccc:	439c                	lw	a5,0(a5)
ffffffffc0200cce:	97ba                	add	a5,a5,a4
ffffffffc0200cd0:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cd2:	00005517          	auipc	a0,0x5
ffffffffc0200cd6:	36e50513          	addi	a0,a0,878 # ffffffffc0206040 <commands+0x730>
ffffffffc0200cda:	cbaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cde:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200ce2:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200ce4:	0791                	addi	a5,a5,4
ffffffffc0200ce6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cea:	6402                	ld	s0,0(sp)
ffffffffc0200cec:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cee:	4640406f          	j	ffffffffc0205152 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cf2:	00005517          	auipc	a0,0x5
ffffffffc0200cf6:	36e50513          	addi	a0,a0,878 # ffffffffc0206060 <commands+0x750>
}
ffffffffc0200cfa:	6402                	ld	s0,0(sp)
ffffffffc0200cfc:	60a2                	ld	ra,8(sp)
ffffffffc0200cfe:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d00:	c94ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d04:	00005517          	auipc	a0,0x5
ffffffffc0200d08:	37c50513          	addi	a0,a0,892 # ffffffffc0206080 <commands+0x770>
ffffffffc0200d0c:	b7fd                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d0e:	00005517          	auipc	a0,0x5
ffffffffc0200d12:	39250513          	addi	a0,a0,914 # ffffffffc02060a0 <commands+0x790>
ffffffffc0200d16:	b7d5                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200d18:	00005517          	auipc	a0,0x5
ffffffffc0200d1c:	3a050513          	addi	a0,a0,928 # ffffffffc02060b8 <commands+0x7a8>
ffffffffc0200d20:	bfe9                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	3ae50513          	addi	a0,a0,942 # ffffffffc02060d0 <commands+0x7c0>
ffffffffc0200d2a:	bfc1                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d2c:	00005517          	auipc	a0,0x5
ffffffffc0200d30:	22c50513          	addi	a0,a0,556 # ffffffffc0205f58 <commands+0x648>
ffffffffc0200d34:	b7d9                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d36:	00005517          	auipc	a0,0x5
ffffffffc0200d3a:	24250513          	addi	a0,a0,578 # ffffffffc0205f78 <commands+0x668>
ffffffffc0200d3e:	bf75                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d40:	00005517          	auipc	a0,0x5
ffffffffc0200d44:	25850513          	addi	a0,a0,600 # ffffffffc0205f98 <commands+0x688>
ffffffffc0200d48:	bf4d                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d4a:	00005517          	auipc	a0,0x5
ffffffffc0200d4e:	26650513          	addi	a0,a0,614 # ffffffffc0205fb0 <commands+0x6a0>
ffffffffc0200d52:	c42ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d56:	6458                	ld	a4,136(s0)
ffffffffc0200d58:	47a9                	li	a5,10
ffffffffc0200d5a:	04f70663          	beq	a4,a5,ffffffffc0200da6 <exception_handler+0xf8>
}
ffffffffc0200d5e:	60a2                	ld	ra,8(sp)
ffffffffc0200d60:	6402                	ld	s0,0(sp)
ffffffffc0200d62:	0141                	addi	sp,sp,16
ffffffffc0200d64:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d66:	00005517          	auipc	a0,0x5
ffffffffc0200d6a:	25a50513          	addi	a0,a0,602 # ffffffffc0205fc0 <commands+0x6b0>
ffffffffc0200d6e:	b771                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d70:	00005517          	auipc	a0,0x5
ffffffffc0200d74:	27050513          	addi	a0,a0,624 # ffffffffc0205fe0 <commands+0x6d0>
ffffffffc0200d78:	b749                	j	ffffffffc0200cfa <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d7a:	00005517          	auipc	a0,0x5
ffffffffc0200d7e:	2ae50513          	addi	a0,a0,686 # ffffffffc0206028 <commands+0x718>
ffffffffc0200d82:	bfa5                	j	ffffffffc0200cfa <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d84:	8522                	mv	a0,s0
}
ffffffffc0200d86:	6402                	ld	s0,0(sp)
ffffffffc0200d88:	60a2                	ld	ra,8(sp)
ffffffffc0200d8a:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d8c:	bd21                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d8e:	00005617          	auipc	a2,0x5
ffffffffc0200d92:	26a60613          	addi	a2,a2,618 # ffffffffc0205ff8 <commands+0x6e8>
ffffffffc0200d96:	0be00593          	li	a1,190
ffffffffc0200d9a:	00005517          	auipc	a0,0x5
ffffffffc0200d9e:	27650513          	addi	a0,a0,630 # ffffffffc0206010 <commands+0x700>
ffffffffc0200da2:	eecff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200da6:	10843783          	ld	a5,264(s0)
ffffffffc0200daa:	0791                	addi	a5,a5,4
ffffffffc0200dac:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200db0:	3a2040ef          	jal	ra,ffffffffc0205152 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200db4:	000aa797          	auipc	a5,0xaa
ffffffffc0200db8:	8347b783          	ld	a5,-1996(a5) # ffffffffc02aa5e8 <current>
ffffffffc0200dbc:	6b9c                	ld	a5,16(a5)
ffffffffc0200dbe:	8522                	mv	a0,s0
}
ffffffffc0200dc0:	6402                	ld	s0,0(sp)
ffffffffc0200dc2:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dc4:	6589                	lui	a1,0x2
ffffffffc0200dc6:	95be                	add	a1,a1,a5
}
ffffffffc0200dc8:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dca:	aab1                	j	ffffffffc0200f26 <kernel_execve_ret>

ffffffffc0200dcc <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200dcc:	1101                	addi	sp,sp,-32
ffffffffc0200dce:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200dd0:	000aa417          	auipc	s0,0xaa
ffffffffc0200dd4:	81840413          	addi	s0,s0,-2024 # ffffffffc02aa5e8 <current>
ffffffffc0200dd8:	6018                	ld	a4,0(s0)
{
ffffffffc0200dda:	ec06                	sd	ra,24(sp)
ffffffffc0200ddc:	e426                	sd	s1,8(sp)
ffffffffc0200dde:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200de0:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200de4:	cf1d                	beqz	a4,ffffffffc0200e22 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200de6:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200dea:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200dee:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200df0:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200df4:	0206c463          	bltz	a3,ffffffffc0200e1c <trap+0x50>
        exception_handler(tf);
ffffffffc0200df8:	eb7ff0ef          	jal	ra,ffffffffc0200cae <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200dfc:	601c                	ld	a5,0(s0)
ffffffffc0200dfe:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e02:	e499                	bnez	s1,ffffffffc0200e10 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e04:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e08:	8b05                	andi	a4,a4,1
ffffffffc0200e0a:	e329                	bnez	a4,ffffffffc0200e4c <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e0c:	6f9c                	ld	a5,24(a5)
ffffffffc0200e0e:	eb85                	bnez	a5,ffffffffc0200e3e <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e10:	60e2                	ld	ra,24(sp)
ffffffffc0200e12:	6442                	ld	s0,16(sp)
ffffffffc0200e14:	64a2                	ld	s1,8(sp)
ffffffffc0200e16:	6902                	ld	s2,0(sp)
ffffffffc0200e18:	6105                	addi	sp,sp,32
ffffffffc0200e1a:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e1c:	debff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e20:	bff1                	j	ffffffffc0200dfc <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e22:	0006c863          	bltz	a3,ffffffffc0200e32 <trap+0x66>
}
ffffffffc0200e26:	6442                	ld	s0,16(sp)
ffffffffc0200e28:	60e2                	ld	ra,24(sp)
ffffffffc0200e2a:	64a2                	ld	s1,8(sp)
ffffffffc0200e2c:	6902                	ld	s2,0(sp)
ffffffffc0200e2e:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e30:	bdbd                	j	ffffffffc0200cae <exception_handler>
}
ffffffffc0200e32:	6442                	ld	s0,16(sp)
ffffffffc0200e34:	60e2                	ld	ra,24(sp)
ffffffffc0200e36:	64a2                	ld	s1,8(sp)
ffffffffc0200e38:	6902                	ld	s2,0(sp)
ffffffffc0200e3a:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e3c:	b3e9                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e3e:	6442                	ld	s0,16(sp)
ffffffffc0200e40:	60e2                	ld	ra,24(sp)
ffffffffc0200e42:	64a2                	ld	s1,8(sp)
ffffffffc0200e44:	6902                	ld	s2,0(sp)
ffffffffc0200e46:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e48:	21e0406f          	j	ffffffffc0205066 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e4c:	555d                	li	a0,-9
ffffffffc0200e4e:	55e030ef          	jal	ra,ffffffffc02043ac <do_exit>
            if (current->need_resched)
ffffffffc0200e52:	601c                	ld	a5,0(s0)
ffffffffc0200e54:	bf65                	j	ffffffffc0200e0c <trap+0x40>
	...

ffffffffc0200e58 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e58:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e5c:	00011463          	bnez	sp,ffffffffc0200e64 <__alltraps+0xc>
ffffffffc0200e60:	14002173          	csrr	sp,sscratch
ffffffffc0200e64:	712d                	addi	sp,sp,-288
ffffffffc0200e66:	e002                	sd	zero,0(sp)
ffffffffc0200e68:	e406                	sd	ra,8(sp)
ffffffffc0200e6a:	ec0e                	sd	gp,24(sp)
ffffffffc0200e6c:	f012                	sd	tp,32(sp)
ffffffffc0200e6e:	f416                	sd	t0,40(sp)
ffffffffc0200e70:	f81a                	sd	t1,48(sp)
ffffffffc0200e72:	fc1e                	sd	t2,56(sp)
ffffffffc0200e74:	e0a2                	sd	s0,64(sp)
ffffffffc0200e76:	e4a6                	sd	s1,72(sp)
ffffffffc0200e78:	e8aa                	sd	a0,80(sp)
ffffffffc0200e7a:	ecae                	sd	a1,88(sp)
ffffffffc0200e7c:	f0b2                	sd	a2,96(sp)
ffffffffc0200e7e:	f4b6                	sd	a3,104(sp)
ffffffffc0200e80:	f8ba                	sd	a4,112(sp)
ffffffffc0200e82:	fcbe                	sd	a5,120(sp)
ffffffffc0200e84:	e142                	sd	a6,128(sp)
ffffffffc0200e86:	e546                	sd	a7,136(sp)
ffffffffc0200e88:	e94a                	sd	s2,144(sp)
ffffffffc0200e8a:	ed4e                	sd	s3,152(sp)
ffffffffc0200e8c:	f152                	sd	s4,160(sp)
ffffffffc0200e8e:	f556                	sd	s5,168(sp)
ffffffffc0200e90:	f95a                	sd	s6,176(sp)
ffffffffc0200e92:	fd5e                	sd	s7,184(sp)
ffffffffc0200e94:	e1e2                	sd	s8,192(sp)
ffffffffc0200e96:	e5e6                	sd	s9,200(sp)
ffffffffc0200e98:	e9ea                	sd	s10,208(sp)
ffffffffc0200e9a:	edee                	sd	s11,216(sp)
ffffffffc0200e9c:	f1f2                	sd	t3,224(sp)
ffffffffc0200e9e:	f5f6                	sd	t4,232(sp)
ffffffffc0200ea0:	f9fa                	sd	t5,240(sp)
ffffffffc0200ea2:	fdfe                	sd	t6,248(sp)
ffffffffc0200ea4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ea8:	100024f3          	csrr	s1,sstatus
ffffffffc0200eac:	14102973          	csrr	s2,sepc
ffffffffc0200eb0:	143029f3          	csrr	s3,stval
ffffffffc0200eb4:	14202a73          	csrr	s4,scause
ffffffffc0200eb8:	e822                	sd	s0,16(sp)
ffffffffc0200eba:	e226                	sd	s1,256(sp)
ffffffffc0200ebc:	e64a                	sd	s2,264(sp)
ffffffffc0200ebe:	ea4e                	sd	s3,272(sp)
ffffffffc0200ec0:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ec2:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ec4:	f09ff0ef          	jal	ra,ffffffffc0200dcc <trap>

ffffffffc0200ec8 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ec8:	6492                	ld	s1,256(sp)
ffffffffc0200eca:	6932                	ld	s2,264(sp)
ffffffffc0200ecc:	1004f413          	andi	s0,s1,256
ffffffffc0200ed0:	e401                	bnez	s0,ffffffffc0200ed8 <__trapret+0x10>
ffffffffc0200ed2:	1200                	addi	s0,sp,288
ffffffffc0200ed4:	14041073          	csrw	sscratch,s0
ffffffffc0200ed8:	10049073          	csrw	sstatus,s1
ffffffffc0200edc:	14191073          	csrw	sepc,s2
ffffffffc0200ee0:	60a2                	ld	ra,8(sp)
ffffffffc0200ee2:	61e2                	ld	gp,24(sp)
ffffffffc0200ee4:	7202                	ld	tp,32(sp)
ffffffffc0200ee6:	72a2                	ld	t0,40(sp)
ffffffffc0200ee8:	7342                	ld	t1,48(sp)
ffffffffc0200eea:	73e2                	ld	t2,56(sp)
ffffffffc0200eec:	6406                	ld	s0,64(sp)
ffffffffc0200eee:	64a6                	ld	s1,72(sp)
ffffffffc0200ef0:	6546                	ld	a0,80(sp)
ffffffffc0200ef2:	65e6                	ld	a1,88(sp)
ffffffffc0200ef4:	7606                	ld	a2,96(sp)
ffffffffc0200ef6:	76a6                	ld	a3,104(sp)
ffffffffc0200ef8:	7746                	ld	a4,112(sp)
ffffffffc0200efa:	77e6                	ld	a5,120(sp)
ffffffffc0200efc:	680a                	ld	a6,128(sp)
ffffffffc0200efe:	68aa                	ld	a7,136(sp)
ffffffffc0200f00:	694a                	ld	s2,144(sp)
ffffffffc0200f02:	69ea                	ld	s3,152(sp)
ffffffffc0200f04:	7a0a                	ld	s4,160(sp)
ffffffffc0200f06:	7aaa                	ld	s5,168(sp)
ffffffffc0200f08:	7b4a                	ld	s6,176(sp)
ffffffffc0200f0a:	7bea                	ld	s7,184(sp)
ffffffffc0200f0c:	6c0e                	ld	s8,192(sp)
ffffffffc0200f0e:	6cae                	ld	s9,200(sp)
ffffffffc0200f10:	6d4e                	ld	s10,208(sp)
ffffffffc0200f12:	6dee                	ld	s11,216(sp)
ffffffffc0200f14:	7e0e                	ld	t3,224(sp)
ffffffffc0200f16:	7eae                	ld	t4,232(sp)
ffffffffc0200f18:	7f4e                	ld	t5,240(sp)
ffffffffc0200f1a:	7fee                	ld	t6,248(sp)
ffffffffc0200f1c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f1e:	10200073          	sret

ffffffffc0200f22 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f22:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f24:	b755                	j	ffffffffc0200ec8 <__trapret>

ffffffffc0200f26 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f26:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cb8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f2a:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f2e:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f32:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f36:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f3a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f3e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f42:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f46:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f4a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f4c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f4e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f50:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f52:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f54:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f56:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f58:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f5a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f5c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f5e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f60:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f62:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f64:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f66:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f68:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f6a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f6c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f6e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f70:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f72:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f74:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f76:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f78:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f7a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f7c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f7e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f80:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f82:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f84:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f86:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f88:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f8a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f8c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f8e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f90:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f92:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f94:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f96:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f98:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f9a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f9c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f9e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200fa0:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200fa2:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200fa4:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200fa6:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200fa8:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200faa:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200fac:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200fae:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200fb0:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200fb2:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200fb4:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200fb6:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200fb8:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200fba:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200fbc:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200fbe:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200fc0:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200fc2:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200fc4:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200fc6:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200fc8:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200fca:	812e                	mv	sp,a1
ffffffffc0200fcc:	bdf5                	j	ffffffffc0200ec8 <__trapret>

ffffffffc0200fce <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200fce:	000a5797          	auipc	a5,0xa5
ffffffffc0200fd2:	59278793          	addi	a5,a5,1426 # ffffffffc02a6560 <free_area>
ffffffffc0200fd6:	e79c                	sd	a5,8(a5)
ffffffffc0200fd8:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200fda:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fde:	8082                	ret

ffffffffc0200fe0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fe0:	000a5517          	auipc	a0,0xa5
ffffffffc0200fe4:	59056503          	lwu	a0,1424(a0) # ffffffffc02a6570 <free_area+0x10>
ffffffffc0200fe8:	8082                	ret

ffffffffc0200fea <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200fea:	715d                	addi	sp,sp,-80
ffffffffc0200fec:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fee:	000a5417          	auipc	s0,0xa5
ffffffffc0200ff2:	57240413          	addi	s0,s0,1394 # ffffffffc02a6560 <free_area>
ffffffffc0200ff6:	641c                	ld	a5,8(s0)
ffffffffc0200ff8:	e486                	sd	ra,72(sp)
ffffffffc0200ffa:	fc26                	sd	s1,56(sp)
ffffffffc0200ffc:	f84a                	sd	s2,48(sp)
ffffffffc0200ffe:	f44e                	sd	s3,40(sp)
ffffffffc0201000:	f052                	sd	s4,32(sp)
ffffffffc0201002:	ec56                	sd	s5,24(sp)
ffffffffc0201004:	e85a                	sd	s6,16(sp)
ffffffffc0201006:	e45e                	sd	s7,8(sp)
ffffffffc0201008:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020100a:	2a878d63          	beq	a5,s0,ffffffffc02012c4 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020100e:	4481                	li	s1,0
ffffffffc0201010:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201012:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201016:	8b09                	andi	a4,a4,2
ffffffffc0201018:	2a070a63          	beqz	a4,ffffffffc02012cc <default_check+0x2e2>
        count++, total += p->property;
ffffffffc020101c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201020:	679c                	ld	a5,8(a5)
ffffffffc0201022:	2905                	addiw	s2,s2,1
ffffffffc0201024:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201026:	fe8796e3          	bne	a5,s0,ffffffffc0201012 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020102a:	89a6                	mv	s3,s1
ffffffffc020102c:	6df000ef          	jal	ra,ffffffffc0201f0a <nr_free_pages>
ffffffffc0201030:	6f351e63          	bne	a0,s3,ffffffffc020172c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201034:	4505                	li	a0,1
ffffffffc0201036:	657000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc020103a:	8aaa                	mv	s5,a0
ffffffffc020103c:	42050863          	beqz	a0,ffffffffc020146c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201040:	4505                	li	a0,1
ffffffffc0201042:	64b000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201046:	89aa                	mv	s3,a0
ffffffffc0201048:	70050263          	beqz	a0,ffffffffc020174c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020104c:	4505                	li	a0,1
ffffffffc020104e:	63f000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201052:	8a2a                	mv	s4,a0
ffffffffc0201054:	48050c63          	beqz	a0,ffffffffc02014ec <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201058:	293a8a63          	beq	s5,s3,ffffffffc02012ec <default_check+0x302>
ffffffffc020105c:	28aa8863          	beq	s5,a0,ffffffffc02012ec <default_check+0x302>
ffffffffc0201060:	28a98663          	beq	s3,a0,ffffffffc02012ec <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201064:	000aa783          	lw	a5,0(s5)
ffffffffc0201068:	2a079263          	bnez	a5,ffffffffc020130c <default_check+0x322>
ffffffffc020106c:	0009a783          	lw	a5,0(s3)
ffffffffc0201070:	28079e63          	bnez	a5,ffffffffc020130c <default_check+0x322>
ffffffffc0201074:	411c                	lw	a5,0(a0)
ffffffffc0201076:	28079b63          	bnez	a5,ffffffffc020130c <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020107a:	000a9797          	auipc	a5,0xa9
ffffffffc020107e:	5567b783          	ld	a5,1366(a5) # ffffffffc02aa5d0 <pages>
ffffffffc0201082:	40fa8733          	sub	a4,s5,a5
ffffffffc0201086:	00006617          	auipc	a2,0x6
ffffffffc020108a:	76263603          	ld	a2,1890(a2) # ffffffffc02077e8 <nbase>
ffffffffc020108e:	8719                	srai	a4,a4,0x6
ffffffffc0201090:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201092:	000a9697          	auipc	a3,0xa9
ffffffffc0201096:	5366b683          	ld	a3,1334(a3) # ffffffffc02aa5c8 <npage>
ffffffffc020109a:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020109c:	0732                	slli	a4,a4,0xc
ffffffffc020109e:	28d77763          	bgeu	a4,a3,ffffffffc020132c <default_check+0x342>
    return page - pages + nbase;
ffffffffc02010a2:	40f98733          	sub	a4,s3,a5
ffffffffc02010a6:	8719                	srai	a4,a4,0x6
ffffffffc02010a8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010aa:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010ac:	4cd77063          	bgeu	a4,a3,ffffffffc020156c <default_check+0x582>
    return page - pages + nbase;
ffffffffc02010b0:	40f507b3          	sub	a5,a0,a5
ffffffffc02010b4:	8799                	srai	a5,a5,0x6
ffffffffc02010b6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010b8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010ba:	30d7f963          	bgeu	a5,a3,ffffffffc02013cc <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02010be:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010c0:	00043c03          	ld	s8,0(s0)
ffffffffc02010c4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02010c8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02010cc:	e400                	sd	s0,8(s0)
ffffffffc02010ce:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010d0:	000a5797          	auipc	a5,0xa5
ffffffffc02010d4:	4a07a023          	sw	zero,1184(a5) # ffffffffc02a6570 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010d8:	5b5000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc02010dc:	2c051863          	bnez	a0,ffffffffc02013ac <default_check+0x3c2>
    free_page(p0);
ffffffffc02010e0:	4585                	li	a1,1
ffffffffc02010e2:	8556                	mv	a0,s5
ffffffffc02010e4:	5e7000ef          	jal	ra,ffffffffc0201eca <free_pages>
    free_page(p1);
ffffffffc02010e8:	4585                	li	a1,1
ffffffffc02010ea:	854e                	mv	a0,s3
ffffffffc02010ec:	5df000ef          	jal	ra,ffffffffc0201eca <free_pages>
    free_page(p2);
ffffffffc02010f0:	4585                	li	a1,1
ffffffffc02010f2:	8552                	mv	a0,s4
ffffffffc02010f4:	5d7000ef          	jal	ra,ffffffffc0201eca <free_pages>
    assert(nr_free == 3);
ffffffffc02010f8:	4818                	lw	a4,16(s0)
ffffffffc02010fa:	478d                	li	a5,3
ffffffffc02010fc:	28f71863          	bne	a4,a5,ffffffffc020138c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201100:	4505                	li	a0,1
ffffffffc0201102:	58b000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201106:	89aa                	mv	s3,a0
ffffffffc0201108:	26050263          	beqz	a0,ffffffffc020136c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020110c:	4505                	li	a0,1
ffffffffc020110e:	57f000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201112:	8aaa                	mv	s5,a0
ffffffffc0201114:	3a050c63          	beqz	a0,ffffffffc02014cc <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201118:	4505                	li	a0,1
ffffffffc020111a:	573000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc020111e:	8a2a                	mv	s4,a0
ffffffffc0201120:	38050663          	beqz	a0,ffffffffc02014ac <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201124:	4505                	li	a0,1
ffffffffc0201126:	567000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc020112a:	36051163          	bnez	a0,ffffffffc020148c <default_check+0x4a2>
    free_page(p0);
ffffffffc020112e:	4585                	li	a1,1
ffffffffc0201130:	854e                	mv	a0,s3
ffffffffc0201132:	599000ef          	jal	ra,ffffffffc0201eca <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201136:	641c                	ld	a5,8(s0)
ffffffffc0201138:	20878a63          	beq	a5,s0,ffffffffc020134c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020113c:	4505                	li	a0,1
ffffffffc020113e:	54f000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201142:	30a99563          	bne	s3,a0,ffffffffc020144c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201146:	4505                	li	a0,1
ffffffffc0201148:	545000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc020114c:	2e051063          	bnez	a0,ffffffffc020142c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201150:	481c                	lw	a5,16(s0)
ffffffffc0201152:	2a079d63          	bnez	a5,ffffffffc020140c <default_check+0x422>
    free_page(p);
ffffffffc0201156:	854e                	mv	a0,s3
ffffffffc0201158:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020115a:	01843023          	sd	s8,0(s0)
ffffffffc020115e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201162:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201166:	565000ef          	jal	ra,ffffffffc0201eca <free_pages>
    free_page(p1);
ffffffffc020116a:	4585                	li	a1,1
ffffffffc020116c:	8556                	mv	a0,s5
ffffffffc020116e:	55d000ef          	jal	ra,ffffffffc0201eca <free_pages>
    free_page(p2);
ffffffffc0201172:	4585                	li	a1,1
ffffffffc0201174:	8552                	mv	a0,s4
ffffffffc0201176:	555000ef          	jal	ra,ffffffffc0201eca <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020117a:	4515                	li	a0,5
ffffffffc020117c:	511000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201180:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201182:	26050563          	beqz	a0,ffffffffc02013ec <default_check+0x402>
ffffffffc0201186:	651c                	ld	a5,8(a0)
ffffffffc0201188:	8385                	srli	a5,a5,0x1
ffffffffc020118a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020118c:	54079063          	bnez	a5,ffffffffc02016cc <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201190:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201192:	00043b03          	ld	s6,0(s0)
ffffffffc0201196:	00843a83          	ld	s5,8(s0)
ffffffffc020119a:	e000                	sd	s0,0(s0)
ffffffffc020119c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020119e:	4ef000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc02011a2:	50051563          	bnez	a0,ffffffffc02016ac <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011a6:	08098a13          	addi	s4,s3,128
ffffffffc02011aa:	8552                	mv	a0,s4
ffffffffc02011ac:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011ae:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02011b2:	000a5797          	auipc	a5,0xa5
ffffffffc02011b6:	3a07af23          	sw	zero,958(a5) # ffffffffc02a6570 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011ba:	511000ef          	jal	ra,ffffffffc0201eca <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011be:	4511                	li	a0,4
ffffffffc02011c0:	4cd000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc02011c4:	4c051463          	bnez	a0,ffffffffc020168c <default_check+0x6a2>
ffffffffc02011c8:	0889b783          	ld	a5,136(s3)
ffffffffc02011cc:	8385                	srli	a5,a5,0x1
ffffffffc02011ce:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011d0:	48078e63          	beqz	a5,ffffffffc020166c <default_check+0x682>
ffffffffc02011d4:	0909a703          	lw	a4,144(s3)
ffffffffc02011d8:	478d                	li	a5,3
ffffffffc02011da:	48f71963          	bne	a4,a5,ffffffffc020166c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011de:	450d                	li	a0,3
ffffffffc02011e0:	4ad000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc02011e4:	8c2a                	mv	s8,a0
ffffffffc02011e6:	46050363          	beqz	a0,ffffffffc020164c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02011ea:	4505                	li	a0,1
ffffffffc02011ec:	4a1000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc02011f0:	42051e63          	bnez	a0,ffffffffc020162c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02011f4:	418a1c63          	bne	s4,s8,ffffffffc020160c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011f8:	4585                	li	a1,1
ffffffffc02011fa:	854e                	mv	a0,s3
ffffffffc02011fc:	4cf000ef          	jal	ra,ffffffffc0201eca <free_pages>
    free_pages(p1, 3);
ffffffffc0201200:	458d                	li	a1,3
ffffffffc0201202:	8552                	mv	a0,s4
ffffffffc0201204:	4c7000ef          	jal	ra,ffffffffc0201eca <free_pages>
ffffffffc0201208:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020120c:	04098c13          	addi	s8,s3,64
ffffffffc0201210:	8385                	srli	a5,a5,0x1
ffffffffc0201212:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201214:	3c078c63          	beqz	a5,ffffffffc02015ec <default_check+0x602>
ffffffffc0201218:	0109a703          	lw	a4,16(s3)
ffffffffc020121c:	4785                	li	a5,1
ffffffffc020121e:	3cf71763          	bne	a4,a5,ffffffffc02015ec <default_check+0x602>
ffffffffc0201222:	008a3783          	ld	a5,8(s4)
ffffffffc0201226:	8385                	srli	a5,a5,0x1
ffffffffc0201228:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020122a:	3a078163          	beqz	a5,ffffffffc02015cc <default_check+0x5e2>
ffffffffc020122e:	010a2703          	lw	a4,16(s4)
ffffffffc0201232:	478d                	li	a5,3
ffffffffc0201234:	38f71c63          	bne	a4,a5,ffffffffc02015cc <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201238:	4505                	li	a0,1
ffffffffc020123a:	453000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc020123e:	36a99763          	bne	s3,a0,ffffffffc02015ac <default_check+0x5c2>
    free_page(p0);
ffffffffc0201242:	4585                	li	a1,1
ffffffffc0201244:	487000ef          	jal	ra,ffffffffc0201eca <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201248:	4509                	li	a0,2
ffffffffc020124a:	443000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc020124e:	32aa1f63          	bne	s4,a0,ffffffffc020158c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201252:	4589                	li	a1,2
ffffffffc0201254:	477000ef          	jal	ra,ffffffffc0201eca <free_pages>
    free_page(p2);
ffffffffc0201258:	4585                	li	a1,1
ffffffffc020125a:	8562                	mv	a0,s8
ffffffffc020125c:	46f000ef          	jal	ra,ffffffffc0201eca <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201260:	4515                	li	a0,5
ffffffffc0201262:	42b000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201266:	89aa                	mv	s3,a0
ffffffffc0201268:	48050263          	beqz	a0,ffffffffc02016ec <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020126c:	4505                	li	a0,1
ffffffffc020126e:	41f000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0201272:	2c051d63          	bnez	a0,ffffffffc020154c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201276:	481c                	lw	a5,16(s0)
ffffffffc0201278:	2a079a63          	bnez	a5,ffffffffc020152c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020127c:	4595                	li	a1,5
ffffffffc020127e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201280:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201284:	01643023          	sd	s6,0(s0)
ffffffffc0201288:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020128c:	43f000ef          	jal	ra,ffffffffc0201eca <free_pages>
    return listelm->next;
ffffffffc0201290:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201292:	00878963          	beq	a5,s0,ffffffffc02012a4 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201296:	ff87a703          	lw	a4,-8(a5)
ffffffffc020129a:	679c                	ld	a5,8(a5)
ffffffffc020129c:	397d                	addiw	s2,s2,-1
ffffffffc020129e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012a0:	fe879be3          	bne	a5,s0,ffffffffc0201296 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02012a4:	26091463          	bnez	s2,ffffffffc020150c <default_check+0x522>
    assert(total == 0);
ffffffffc02012a8:	46049263          	bnez	s1,ffffffffc020170c <default_check+0x722>
}
ffffffffc02012ac:	60a6                	ld	ra,72(sp)
ffffffffc02012ae:	6406                	ld	s0,64(sp)
ffffffffc02012b0:	74e2                	ld	s1,56(sp)
ffffffffc02012b2:	7942                	ld	s2,48(sp)
ffffffffc02012b4:	79a2                	ld	s3,40(sp)
ffffffffc02012b6:	7a02                	ld	s4,32(sp)
ffffffffc02012b8:	6ae2                	ld	s5,24(sp)
ffffffffc02012ba:	6b42                	ld	s6,16(sp)
ffffffffc02012bc:	6ba2                	ld	s7,8(sp)
ffffffffc02012be:	6c02                	ld	s8,0(sp)
ffffffffc02012c0:	6161                	addi	sp,sp,80
ffffffffc02012c2:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02012c4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02012c6:	4481                	li	s1,0
ffffffffc02012c8:	4901                	li	s2,0
ffffffffc02012ca:	b38d                	j	ffffffffc020102c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02012cc:	00005697          	auipc	a3,0x5
ffffffffc02012d0:	e5c68693          	addi	a3,a3,-420 # ffffffffc0206128 <commands+0x818>
ffffffffc02012d4:	00005617          	auipc	a2,0x5
ffffffffc02012d8:	e6460613          	addi	a2,a2,-412 # ffffffffc0206138 <commands+0x828>
ffffffffc02012dc:	11000593          	li	a1,272
ffffffffc02012e0:	00005517          	auipc	a0,0x5
ffffffffc02012e4:	e7050513          	addi	a0,a0,-400 # ffffffffc0206150 <commands+0x840>
ffffffffc02012e8:	9a6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012ec:	00005697          	auipc	a3,0x5
ffffffffc02012f0:	efc68693          	addi	a3,a3,-260 # ffffffffc02061e8 <commands+0x8d8>
ffffffffc02012f4:	00005617          	auipc	a2,0x5
ffffffffc02012f8:	e4460613          	addi	a2,a2,-444 # ffffffffc0206138 <commands+0x828>
ffffffffc02012fc:	0db00593          	li	a1,219
ffffffffc0201300:	00005517          	auipc	a0,0x5
ffffffffc0201304:	e5050513          	addi	a0,a0,-432 # ffffffffc0206150 <commands+0x840>
ffffffffc0201308:	986ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020130c:	00005697          	auipc	a3,0x5
ffffffffc0201310:	f0468693          	addi	a3,a3,-252 # ffffffffc0206210 <commands+0x900>
ffffffffc0201314:	00005617          	auipc	a2,0x5
ffffffffc0201318:	e2460613          	addi	a2,a2,-476 # ffffffffc0206138 <commands+0x828>
ffffffffc020131c:	0dc00593          	li	a1,220
ffffffffc0201320:	00005517          	auipc	a0,0x5
ffffffffc0201324:	e3050513          	addi	a0,a0,-464 # ffffffffc0206150 <commands+0x840>
ffffffffc0201328:	966ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020132c:	00005697          	auipc	a3,0x5
ffffffffc0201330:	f2468693          	addi	a3,a3,-220 # ffffffffc0206250 <commands+0x940>
ffffffffc0201334:	00005617          	auipc	a2,0x5
ffffffffc0201338:	e0460613          	addi	a2,a2,-508 # ffffffffc0206138 <commands+0x828>
ffffffffc020133c:	0de00593          	li	a1,222
ffffffffc0201340:	00005517          	auipc	a0,0x5
ffffffffc0201344:	e1050513          	addi	a0,a0,-496 # ffffffffc0206150 <commands+0x840>
ffffffffc0201348:	946ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc020134c:	00005697          	auipc	a3,0x5
ffffffffc0201350:	f8c68693          	addi	a3,a3,-116 # ffffffffc02062d8 <commands+0x9c8>
ffffffffc0201354:	00005617          	auipc	a2,0x5
ffffffffc0201358:	de460613          	addi	a2,a2,-540 # ffffffffc0206138 <commands+0x828>
ffffffffc020135c:	0f700593          	li	a1,247
ffffffffc0201360:	00005517          	auipc	a0,0x5
ffffffffc0201364:	df050513          	addi	a0,a0,-528 # ffffffffc0206150 <commands+0x840>
ffffffffc0201368:	926ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020136c:	00005697          	auipc	a3,0x5
ffffffffc0201370:	e1c68693          	addi	a3,a3,-484 # ffffffffc0206188 <commands+0x878>
ffffffffc0201374:	00005617          	auipc	a2,0x5
ffffffffc0201378:	dc460613          	addi	a2,a2,-572 # ffffffffc0206138 <commands+0x828>
ffffffffc020137c:	0f000593          	li	a1,240
ffffffffc0201380:	00005517          	auipc	a0,0x5
ffffffffc0201384:	dd050513          	addi	a0,a0,-560 # ffffffffc0206150 <commands+0x840>
ffffffffc0201388:	906ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020138c:	00005697          	auipc	a3,0x5
ffffffffc0201390:	f3c68693          	addi	a3,a3,-196 # ffffffffc02062c8 <commands+0x9b8>
ffffffffc0201394:	00005617          	auipc	a2,0x5
ffffffffc0201398:	da460613          	addi	a2,a2,-604 # ffffffffc0206138 <commands+0x828>
ffffffffc020139c:	0ee00593          	li	a1,238
ffffffffc02013a0:	00005517          	auipc	a0,0x5
ffffffffc02013a4:	db050513          	addi	a0,a0,-592 # ffffffffc0206150 <commands+0x840>
ffffffffc02013a8:	8e6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013ac:	00005697          	auipc	a3,0x5
ffffffffc02013b0:	f0468693          	addi	a3,a3,-252 # ffffffffc02062b0 <commands+0x9a0>
ffffffffc02013b4:	00005617          	auipc	a2,0x5
ffffffffc02013b8:	d8460613          	addi	a2,a2,-636 # ffffffffc0206138 <commands+0x828>
ffffffffc02013bc:	0e900593          	li	a1,233
ffffffffc02013c0:	00005517          	auipc	a0,0x5
ffffffffc02013c4:	d9050513          	addi	a0,a0,-624 # ffffffffc0206150 <commands+0x840>
ffffffffc02013c8:	8c6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02013cc:	00005697          	auipc	a3,0x5
ffffffffc02013d0:	ec468693          	addi	a3,a3,-316 # ffffffffc0206290 <commands+0x980>
ffffffffc02013d4:	00005617          	auipc	a2,0x5
ffffffffc02013d8:	d6460613          	addi	a2,a2,-668 # ffffffffc0206138 <commands+0x828>
ffffffffc02013dc:	0e000593          	li	a1,224
ffffffffc02013e0:	00005517          	auipc	a0,0x5
ffffffffc02013e4:	d7050513          	addi	a0,a0,-656 # ffffffffc0206150 <commands+0x840>
ffffffffc02013e8:	8a6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02013ec:	00005697          	auipc	a3,0x5
ffffffffc02013f0:	f3468693          	addi	a3,a3,-204 # ffffffffc0206320 <commands+0xa10>
ffffffffc02013f4:	00005617          	auipc	a2,0x5
ffffffffc02013f8:	d4460613          	addi	a2,a2,-700 # ffffffffc0206138 <commands+0x828>
ffffffffc02013fc:	11800593          	li	a1,280
ffffffffc0201400:	00005517          	auipc	a0,0x5
ffffffffc0201404:	d5050513          	addi	a0,a0,-688 # ffffffffc0206150 <commands+0x840>
ffffffffc0201408:	886ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020140c:	00005697          	auipc	a3,0x5
ffffffffc0201410:	f0468693          	addi	a3,a3,-252 # ffffffffc0206310 <commands+0xa00>
ffffffffc0201414:	00005617          	auipc	a2,0x5
ffffffffc0201418:	d2460613          	addi	a2,a2,-732 # ffffffffc0206138 <commands+0x828>
ffffffffc020141c:	0fd00593          	li	a1,253
ffffffffc0201420:	00005517          	auipc	a0,0x5
ffffffffc0201424:	d3050513          	addi	a0,a0,-720 # ffffffffc0206150 <commands+0x840>
ffffffffc0201428:	866ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020142c:	00005697          	auipc	a3,0x5
ffffffffc0201430:	e8468693          	addi	a3,a3,-380 # ffffffffc02062b0 <commands+0x9a0>
ffffffffc0201434:	00005617          	auipc	a2,0x5
ffffffffc0201438:	d0460613          	addi	a2,a2,-764 # ffffffffc0206138 <commands+0x828>
ffffffffc020143c:	0fb00593          	li	a1,251
ffffffffc0201440:	00005517          	auipc	a0,0x5
ffffffffc0201444:	d1050513          	addi	a0,a0,-752 # ffffffffc0206150 <commands+0x840>
ffffffffc0201448:	846ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020144c:	00005697          	auipc	a3,0x5
ffffffffc0201450:	ea468693          	addi	a3,a3,-348 # ffffffffc02062f0 <commands+0x9e0>
ffffffffc0201454:	00005617          	auipc	a2,0x5
ffffffffc0201458:	ce460613          	addi	a2,a2,-796 # ffffffffc0206138 <commands+0x828>
ffffffffc020145c:	0fa00593          	li	a1,250
ffffffffc0201460:	00005517          	auipc	a0,0x5
ffffffffc0201464:	cf050513          	addi	a0,a0,-784 # ffffffffc0206150 <commands+0x840>
ffffffffc0201468:	826ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020146c:	00005697          	auipc	a3,0x5
ffffffffc0201470:	d1c68693          	addi	a3,a3,-740 # ffffffffc0206188 <commands+0x878>
ffffffffc0201474:	00005617          	auipc	a2,0x5
ffffffffc0201478:	cc460613          	addi	a2,a2,-828 # ffffffffc0206138 <commands+0x828>
ffffffffc020147c:	0d700593          	li	a1,215
ffffffffc0201480:	00005517          	auipc	a0,0x5
ffffffffc0201484:	cd050513          	addi	a0,a0,-816 # ffffffffc0206150 <commands+0x840>
ffffffffc0201488:	806ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020148c:	00005697          	auipc	a3,0x5
ffffffffc0201490:	e2468693          	addi	a3,a3,-476 # ffffffffc02062b0 <commands+0x9a0>
ffffffffc0201494:	00005617          	auipc	a2,0x5
ffffffffc0201498:	ca460613          	addi	a2,a2,-860 # ffffffffc0206138 <commands+0x828>
ffffffffc020149c:	0f400593          	li	a1,244
ffffffffc02014a0:	00005517          	auipc	a0,0x5
ffffffffc02014a4:	cb050513          	addi	a0,a0,-848 # ffffffffc0206150 <commands+0x840>
ffffffffc02014a8:	fe7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014ac:	00005697          	auipc	a3,0x5
ffffffffc02014b0:	d1c68693          	addi	a3,a3,-740 # ffffffffc02061c8 <commands+0x8b8>
ffffffffc02014b4:	00005617          	auipc	a2,0x5
ffffffffc02014b8:	c8460613          	addi	a2,a2,-892 # ffffffffc0206138 <commands+0x828>
ffffffffc02014bc:	0f200593          	li	a1,242
ffffffffc02014c0:	00005517          	auipc	a0,0x5
ffffffffc02014c4:	c9050513          	addi	a0,a0,-880 # ffffffffc0206150 <commands+0x840>
ffffffffc02014c8:	fc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	cdc68693          	addi	a3,a3,-804 # ffffffffc02061a8 <commands+0x898>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	c6460613          	addi	a2,a2,-924 # ffffffffc0206138 <commands+0x828>
ffffffffc02014dc:	0f100593          	li	a1,241
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	c7050513          	addi	a0,a0,-912 # ffffffffc0206150 <commands+0x840>
ffffffffc02014e8:	fa7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	cdc68693          	addi	a3,a3,-804 # ffffffffc02061c8 <commands+0x8b8>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	c4460613          	addi	a2,a2,-956 # ffffffffc0206138 <commands+0x828>
ffffffffc02014fc:	0d900593          	li	a1,217
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	c5050513          	addi	a0,a0,-944 # ffffffffc0206150 <commands+0x840>
ffffffffc0201508:	f87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	f6468693          	addi	a3,a3,-156 # ffffffffc0206470 <commands+0xb60>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	c2460613          	addi	a2,a2,-988 # ffffffffc0206138 <commands+0x828>
ffffffffc020151c:	14600593          	li	a1,326
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	c3050513          	addi	a0,a0,-976 # ffffffffc0206150 <commands+0x840>
ffffffffc0201528:	f67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	de468693          	addi	a3,a3,-540 # ffffffffc0206310 <commands+0xa00>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	c0460613          	addi	a2,a2,-1020 # ffffffffc0206138 <commands+0x828>
ffffffffc020153c:	13a00593          	li	a1,314
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	c1050513          	addi	a0,a0,-1008 # ffffffffc0206150 <commands+0x840>
ffffffffc0201548:	f47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	d6468693          	addi	a3,a3,-668 # ffffffffc02062b0 <commands+0x9a0>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	be460613          	addi	a2,a2,-1052 # ffffffffc0206138 <commands+0x828>
ffffffffc020155c:	13800593          	li	a1,312
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	bf050513          	addi	a0,a0,-1040 # ffffffffc0206150 <commands+0x840>
ffffffffc0201568:	f27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	d0468693          	addi	a3,a3,-764 # ffffffffc0206270 <commands+0x960>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	bc460613          	addi	a2,a2,-1084 # ffffffffc0206138 <commands+0x828>
ffffffffc020157c:	0df00593          	li	a1,223
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	bd050513          	addi	a0,a0,-1072 # ffffffffc0206150 <commands+0x840>
ffffffffc0201588:	f07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	ea468693          	addi	a3,a3,-348 # ffffffffc0206430 <commands+0xb20>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	ba460613          	addi	a2,a2,-1116 # ffffffffc0206138 <commands+0x828>
ffffffffc020159c:	13200593          	li	a1,306
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	bb050513          	addi	a0,a0,-1104 # ffffffffc0206150 <commands+0x840>
ffffffffc02015a8:	ee7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	e6468693          	addi	a3,a3,-412 # ffffffffc0206410 <commands+0xb00>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	b8460613          	addi	a2,a2,-1148 # ffffffffc0206138 <commands+0x828>
ffffffffc02015bc:	13000593          	li	a1,304
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	b9050513          	addi	a0,a0,-1136 # ffffffffc0206150 <commands+0x840>
ffffffffc02015c8:	ec7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	e1c68693          	addi	a3,a3,-484 # ffffffffc02063e8 <commands+0xad8>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	b6460613          	addi	a2,a2,-1180 # ffffffffc0206138 <commands+0x828>
ffffffffc02015dc:	12e00593          	li	a1,302
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	b7050513          	addi	a0,a0,-1168 # ffffffffc0206150 <commands+0x840>
ffffffffc02015e8:	ea7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	dd468693          	addi	a3,a3,-556 # ffffffffc02063c0 <commands+0xab0>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	b4460613          	addi	a2,a2,-1212 # ffffffffc0206138 <commands+0x828>
ffffffffc02015fc:	12d00593          	li	a1,301
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	b5050513          	addi	a0,a0,-1200 # ffffffffc0206150 <commands+0x840>
ffffffffc0201608:	e87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	da468693          	addi	a3,a3,-604 # ffffffffc02063b0 <commands+0xaa0>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	b2460613          	addi	a2,a2,-1244 # ffffffffc0206138 <commands+0x828>
ffffffffc020161c:	12800593          	li	a1,296
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	b3050513          	addi	a0,a0,-1232 # ffffffffc0206150 <commands+0x840>
ffffffffc0201628:	e67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	c8468693          	addi	a3,a3,-892 # ffffffffc02062b0 <commands+0x9a0>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	b0460613          	addi	a2,a2,-1276 # ffffffffc0206138 <commands+0x828>
ffffffffc020163c:	12700593          	li	a1,295
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	b1050513          	addi	a0,a0,-1264 # ffffffffc0206150 <commands+0x840>
ffffffffc0201648:	e47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	d4468693          	addi	a3,a3,-700 # ffffffffc0206390 <commands+0xa80>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	ae460613          	addi	a2,a2,-1308 # ffffffffc0206138 <commands+0x828>
ffffffffc020165c:	12600593          	li	a1,294
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	af050513          	addi	a0,a0,-1296 # ffffffffc0206150 <commands+0x840>
ffffffffc0201668:	e27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	cf468693          	addi	a3,a3,-780 # ffffffffc0206360 <commands+0xa50>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	ac460613          	addi	a2,a2,-1340 # ffffffffc0206138 <commands+0x828>
ffffffffc020167c:	12500593          	li	a1,293
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	ad050513          	addi	a0,a0,-1328 # ffffffffc0206150 <commands+0x840>
ffffffffc0201688:	e07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	cbc68693          	addi	a3,a3,-836 # ffffffffc0206348 <commands+0xa38>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	aa460613          	addi	a2,a2,-1372 # ffffffffc0206138 <commands+0x828>
ffffffffc020169c:	12400593          	li	a1,292
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	ab050513          	addi	a0,a0,-1360 # ffffffffc0206150 <commands+0x840>
ffffffffc02016a8:	de7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	c0468693          	addi	a3,a3,-1020 # ffffffffc02062b0 <commands+0x9a0>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	a8460613          	addi	a2,a2,-1404 # ffffffffc0206138 <commands+0x828>
ffffffffc02016bc:	11e00593          	li	a1,286
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	a9050513          	addi	a0,a0,-1392 # ffffffffc0206150 <commands+0x840>
ffffffffc02016c8:	dc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	c6468693          	addi	a3,a3,-924 # ffffffffc0206330 <commands+0xa20>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	a6460613          	addi	a2,a2,-1436 # ffffffffc0206138 <commands+0x828>
ffffffffc02016dc:	11900593          	li	a1,281
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	a7050513          	addi	a0,a0,-1424 # ffffffffc0206150 <commands+0x840>
ffffffffc02016e8:	da7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	d6468693          	addi	a3,a3,-668 # ffffffffc0206450 <commands+0xb40>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206138 <commands+0x828>
ffffffffc02016fc:	13700593          	li	a1,311
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	a5050513          	addi	a0,a0,-1456 # ffffffffc0206150 <commands+0x840>
ffffffffc0201708:	d87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	d7468693          	addi	a3,a3,-652 # ffffffffc0206480 <commands+0xb70>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206138 <commands+0x828>
ffffffffc020171c:	14700593          	li	a1,327
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	a3050513          	addi	a0,a0,-1488 # ffffffffc0206150 <commands+0x840>
ffffffffc0201728:	d67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0206168 <commands+0x858>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206138 <commands+0x828>
ffffffffc020173c:	11300593          	li	a1,275
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	a1050513          	addi	a0,a0,-1520 # ffffffffc0206150 <commands+0x840>
ffffffffc0201748:	d47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020174c:	00005697          	auipc	a3,0x5
ffffffffc0201750:	a5c68693          	addi	a3,a3,-1444 # ffffffffc02061a8 <commands+0x898>
ffffffffc0201754:	00005617          	auipc	a2,0x5
ffffffffc0201758:	9e460613          	addi	a2,a2,-1564 # ffffffffc0206138 <commands+0x828>
ffffffffc020175c:	0d800593          	li	a1,216
ffffffffc0201760:	00005517          	auipc	a0,0x5
ffffffffc0201764:	9f050513          	addi	a0,a0,-1552 # ffffffffc0206150 <commands+0x840>
ffffffffc0201768:	d27fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020176c <default_free_pages>:
{
ffffffffc020176c:	1141                	addi	sp,sp,-16
ffffffffc020176e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201770:	14058463          	beqz	a1,ffffffffc02018b8 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201774:	00659693          	slli	a3,a1,0x6
ffffffffc0201778:	96aa                	add	a3,a3,a0
ffffffffc020177a:	87aa                	mv	a5,a0
ffffffffc020177c:	02d50263          	beq	a0,a3,ffffffffc02017a0 <default_free_pages+0x34>
ffffffffc0201780:	6798                	ld	a4,8(a5)
ffffffffc0201782:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201784:	10071a63          	bnez	a4,ffffffffc0201898 <default_free_pages+0x12c>
ffffffffc0201788:	6798                	ld	a4,8(a5)
ffffffffc020178a:	8b09                	andi	a4,a4,2
ffffffffc020178c:	10071663          	bnez	a4,ffffffffc0201898 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201790:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201794:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201798:	04078793          	addi	a5,a5,64
ffffffffc020179c:	fed792e3          	bne	a5,a3,ffffffffc0201780 <default_free_pages+0x14>
    base->property = n;
ffffffffc02017a0:	2581                	sext.w	a1,a1
ffffffffc02017a2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017a4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017a8:	4789                	li	a5,2
ffffffffc02017aa:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017ae:	000a5697          	auipc	a3,0xa5
ffffffffc02017b2:	db268693          	addi	a3,a3,-590 # ffffffffc02a6560 <free_area>
ffffffffc02017b6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017b8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017ba:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017be:	9db9                	addw	a1,a1,a4
ffffffffc02017c0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02017c2:	0ad78463          	beq	a5,a3,ffffffffc020186a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02017c6:	fe878713          	addi	a4,a5,-24
ffffffffc02017ca:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02017ce:	4581                	li	a1,0
            if (base < page)
ffffffffc02017d0:	00e56a63          	bltu	a0,a4,ffffffffc02017e4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017d4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017d6:	04d70c63          	beq	a4,a3,ffffffffc020182e <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02017da:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017dc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017e0:	fee57ae3          	bgeu	a0,a4,ffffffffc02017d4 <default_free_pages+0x68>
ffffffffc02017e4:	c199                	beqz	a1,ffffffffc02017ea <default_free_pages+0x7e>
ffffffffc02017e6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017ea:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017ec:	e390                	sd	a2,0(a5)
ffffffffc02017ee:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017f0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017f2:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02017f4:	00d70d63          	beq	a4,a3,ffffffffc020180e <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017f8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017fc:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201800:	02059813          	slli	a6,a1,0x20
ffffffffc0201804:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201808:	97b2                	add	a5,a5,a2
ffffffffc020180a:	02f50c63          	beq	a0,a5,ffffffffc0201842 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020180e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201810:	00d78c63          	beq	a5,a3,ffffffffc0201828 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201814:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201816:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020181a:	02061593          	slli	a1,a2,0x20
ffffffffc020181e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201822:	972a                	add	a4,a4,a0
ffffffffc0201824:	04e68a63          	beq	a3,a4,ffffffffc0201878 <default_free_pages+0x10c>
}
ffffffffc0201828:	60a2                	ld	ra,8(sp)
ffffffffc020182a:	0141                	addi	sp,sp,16
ffffffffc020182c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020182e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201830:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201832:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201834:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201836:	02d70763          	beq	a4,a3,ffffffffc0201864 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020183a:	8832                	mv	a6,a2
ffffffffc020183c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020183e:	87ba                	mv	a5,a4
ffffffffc0201840:	bf71                	j	ffffffffc02017dc <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201842:	491c                	lw	a5,16(a0)
ffffffffc0201844:	9dbd                	addw	a1,a1,a5
ffffffffc0201846:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020184a:	57f5                	li	a5,-3
ffffffffc020184c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201850:	01853803          	ld	a6,24(a0)
ffffffffc0201854:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201856:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201858:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc020185c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020185e:	0105b023          	sd	a6,0(a1)
ffffffffc0201862:	b77d                	j	ffffffffc0201810 <default_free_pages+0xa4>
ffffffffc0201864:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201866:	873e                	mv	a4,a5
ffffffffc0201868:	bf41                	j	ffffffffc02017f8 <default_free_pages+0x8c>
}
ffffffffc020186a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020186c:	e390                	sd	a2,0(a5)
ffffffffc020186e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201870:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201872:	ed1c                	sd	a5,24(a0)
ffffffffc0201874:	0141                	addi	sp,sp,16
ffffffffc0201876:	8082                	ret
            base->property += p->property;
ffffffffc0201878:	ff87a703          	lw	a4,-8(a5)
ffffffffc020187c:	ff078693          	addi	a3,a5,-16
ffffffffc0201880:	9e39                	addw	a2,a2,a4
ffffffffc0201882:	c910                	sw	a2,16(a0)
ffffffffc0201884:	5775                	li	a4,-3
ffffffffc0201886:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020188a:	6398                	ld	a4,0(a5)
ffffffffc020188c:	679c                	ld	a5,8(a5)
}
ffffffffc020188e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201890:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201892:	e398                	sd	a4,0(a5)
ffffffffc0201894:	0141                	addi	sp,sp,16
ffffffffc0201896:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201898:	00005697          	auipc	a3,0x5
ffffffffc020189c:	c0068693          	addi	a3,a3,-1024 # ffffffffc0206498 <commands+0xb88>
ffffffffc02018a0:	00005617          	auipc	a2,0x5
ffffffffc02018a4:	89860613          	addi	a2,a2,-1896 # ffffffffc0206138 <commands+0x828>
ffffffffc02018a8:	09400593          	li	a1,148
ffffffffc02018ac:	00005517          	auipc	a0,0x5
ffffffffc02018b0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206150 <commands+0x840>
ffffffffc02018b4:	bdbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc02018b8:	00005697          	auipc	a3,0x5
ffffffffc02018bc:	bd868693          	addi	a3,a3,-1064 # ffffffffc0206490 <commands+0xb80>
ffffffffc02018c0:	00005617          	auipc	a2,0x5
ffffffffc02018c4:	87860613          	addi	a2,a2,-1928 # ffffffffc0206138 <commands+0x828>
ffffffffc02018c8:	09000593          	li	a1,144
ffffffffc02018cc:	00005517          	auipc	a0,0x5
ffffffffc02018d0:	88450513          	addi	a0,a0,-1916 # ffffffffc0206150 <commands+0x840>
ffffffffc02018d4:	bbbfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02018d8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018d8:	c941                	beqz	a0,ffffffffc0201968 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02018da:	000a5597          	auipc	a1,0xa5
ffffffffc02018de:	c8658593          	addi	a1,a1,-890 # ffffffffc02a6560 <free_area>
ffffffffc02018e2:	0105a803          	lw	a6,16(a1)
ffffffffc02018e6:	872a                	mv	a4,a0
ffffffffc02018e8:	02081793          	slli	a5,a6,0x20
ffffffffc02018ec:	9381                	srli	a5,a5,0x20
ffffffffc02018ee:	00a7ee63          	bltu	a5,a0,ffffffffc020190a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02018f2:	87ae                	mv	a5,a1
ffffffffc02018f4:	a801                	j	ffffffffc0201904 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02018f6:	ff87a683          	lw	a3,-8(a5)
ffffffffc02018fa:	02069613          	slli	a2,a3,0x20
ffffffffc02018fe:	9201                	srli	a2,a2,0x20
ffffffffc0201900:	00e67763          	bgeu	a2,a4,ffffffffc020190e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201904:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201906:	feb798e3          	bne	a5,a1,ffffffffc02018f6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020190a:	4501                	li	a0,0
}
ffffffffc020190c:	8082                	ret
    return listelm->prev;
ffffffffc020190e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201912:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201916:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020191a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020191e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201922:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201926:	02c77863          	bgeu	a4,a2,ffffffffc0201956 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020192a:	071a                	slli	a4,a4,0x6
ffffffffc020192c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020192e:	41c686bb          	subw	a3,a3,t3
ffffffffc0201932:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201934:	00870613          	addi	a2,a4,8
ffffffffc0201938:	4689                	li	a3,2
ffffffffc020193a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020193e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201942:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201946:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020194a:	e290                	sd	a2,0(a3)
ffffffffc020194c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201950:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201952:	01173c23          	sd	a7,24(a4)
ffffffffc0201956:	41c8083b          	subw	a6,a6,t3
ffffffffc020195a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020195e:	5775                	li	a4,-3
ffffffffc0201960:	17c1                	addi	a5,a5,-16
ffffffffc0201962:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201966:	8082                	ret
{
ffffffffc0201968:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020196a:	00005697          	auipc	a3,0x5
ffffffffc020196e:	b2668693          	addi	a3,a3,-1242 # ffffffffc0206490 <commands+0xb80>
ffffffffc0201972:	00004617          	auipc	a2,0x4
ffffffffc0201976:	7c660613          	addi	a2,a2,1990 # ffffffffc0206138 <commands+0x828>
ffffffffc020197a:	06c00593          	li	a1,108
ffffffffc020197e:	00004517          	auipc	a0,0x4
ffffffffc0201982:	7d250513          	addi	a0,a0,2002 # ffffffffc0206150 <commands+0x840>
{
ffffffffc0201986:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201988:	b07fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020198c <default_init_memmap>:
{
ffffffffc020198c:	1141                	addi	sp,sp,-16
ffffffffc020198e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201990:	c5f1                	beqz	a1,ffffffffc0201a5c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201992:	00659693          	slli	a3,a1,0x6
ffffffffc0201996:	96aa                	add	a3,a3,a0
ffffffffc0201998:	87aa                	mv	a5,a0
ffffffffc020199a:	00d50f63          	beq	a0,a3,ffffffffc02019b8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020199e:	6798                	ld	a4,8(a5)
ffffffffc02019a0:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02019a2:	cf49                	beqz	a4,ffffffffc0201a3c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02019a4:	0007a823          	sw	zero,16(a5)
ffffffffc02019a8:	0007b423          	sd	zero,8(a5)
ffffffffc02019ac:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019b0:	04078793          	addi	a5,a5,64
ffffffffc02019b4:	fed795e3          	bne	a5,a3,ffffffffc020199e <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019b8:	2581                	sext.w	a1,a1
ffffffffc02019ba:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019bc:	4789                	li	a5,2
ffffffffc02019be:	00850713          	addi	a4,a0,8
ffffffffc02019c2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02019c6:	000a5697          	auipc	a3,0xa5
ffffffffc02019ca:	b9a68693          	addi	a3,a3,-1126 # ffffffffc02a6560 <free_area>
ffffffffc02019ce:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019d0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019d2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019d6:	9db9                	addw	a1,a1,a4
ffffffffc02019d8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019da:	04d78a63          	beq	a5,a3,ffffffffc0201a2e <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02019de:	fe878713          	addi	a4,a5,-24
ffffffffc02019e2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019e6:	4581                	li	a1,0
            if (base < page)
ffffffffc02019e8:	00e56a63          	bltu	a0,a4,ffffffffc02019fc <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019ec:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019ee:	02d70263          	beq	a4,a3,ffffffffc0201a12 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02019f2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019f4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019f8:	fee57ae3          	bgeu	a0,a4,ffffffffc02019ec <default_init_memmap+0x60>
ffffffffc02019fc:	c199                	beqz	a1,ffffffffc0201a02 <default_init_memmap+0x76>
ffffffffc02019fe:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a02:	6398                	ld	a4,0(a5)
}
ffffffffc0201a04:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a06:	e390                	sd	a2,0(a5)
ffffffffc0201a08:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a0a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a0c:	ed18                	sd	a4,24(a0)
ffffffffc0201a0e:	0141                	addi	sp,sp,16
ffffffffc0201a10:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a12:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a14:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a16:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a18:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a1a:	00d70663          	beq	a4,a3,ffffffffc0201a26 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a1e:	8832                	mv	a6,a2
ffffffffc0201a20:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a22:	87ba                	mv	a5,a4
ffffffffc0201a24:	bfc1                	j	ffffffffc02019f4 <default_init_memmap+0x68>
}
ffffffffc0201a26:	60a2                	ld	ra,8(sp)
ffffffffc0201a28:	e290                	sd	a2,0(a3)
ffffffffc0201a2a:	0141                	addi	sp,sp,16
ffffffffc0201a2c:	8082                	ret
ffffffffc0201a2e:	60a2                	ld	ra,8(sp)
ffffffffc0201a30:	e390                	sd	a2,0(a5)
ffffffffc0201a32:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a34:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a36:	ed1c                	sd	a5,24(a0)
ffffffffc0201a38:	0141                	addi	sp,sp,16
ffffffffc0201a3a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a3c:	00005697          	auipc	a3,0x5
ffffffffc0201a40:	a8468693          	addi	a3,a3,-1404 # ffffffffc02064c0 <commands+0xbb0>
ffffffffc0201a44:	00004617          	auipc	a2,0x4
ffffffffc0201a48:	6f460613          	addi	a2,a2,1780 # ffffffffc0206138 <commands+0x828>
ffffffffc0201a4c:	04b00593          	li	a1,75
ffffffffc0201a50:	00004517          	auipc	a0,0x4
ffffffffc0201a54:	70050513          	addi	a0,a0,1792 # ffffffffc0206150 <commands+0x840>
ffffffffc0201a58:	a37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a5c:	00005697          	auipc	a3,0x5
ffffffffc0201a60:	a3468693          	addi	a3,a3,-1484 # ffffffffc0206490 <commands+0xb80>
ffffffffc0201a64:	00004617          	auipc	a2,0x4
ffffffffc0201a68:	6d460613          	addi	a2,a2,1748 # ffffffffc0206138 <commands+0x828>
ffffffffc0201a6c:	04700593          	li	a1,71
ffffffffc0201a70:	00004517          	auipc	a0,0x4
ffffffffc0201a74:	6e050513          	addi	a0,a0,1760 # ffffffffc0206150 <commands+0x840>
ffffffffc0201a78:	a17fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a7c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a7c:	c94d                	beqz	a0,ffffffffc0201b2e <slob_free+0xb2>
{
ffffffffc0201a7e:	1141                	addi	sp,sp,-16
ffffffffc0201a80:	e022                	sd	s0,0(sp)
ffffffffc0201a82:	e406                	sd	ra,8(sp)
ffffffffc0201a84:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201a86:	e9c1                	bnez	a1,ffffffffc0201b16 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a88:	100027f3          	csrr	a5,sstatus
ffffffffc0201a8c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a8e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a90:	ebd9                	bnez	a5,ffffffffc0201b26 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a92:	000a4617          	auipc	a2,0xa4
ffffffffc0201a96:	6be60613          	addi	a2,a2,1726 # ffffffffc02a6150 <slobfree>
ffffffffc0201a9a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a9c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a9e:	679c                	ld	a5,8(a5)
ffffffffc0201aa0:	02877a63          	bgeu	a4,s0,ffffffffc0201ad4 <slob_free+0x58>
ffffffffc0201aa4:	00f46463          	bltu	s0,a5,ffffffffc0201aac <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aa8:	fef76ae3          	bltu	a4,a5,ffffffffc0201a9c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201aac:	400c                	lw	a1,0(s0)
ffffffffc0201aae:	00459693          	slli	a3,a1,0x4
ffffffffc0201ab2:	96a2                	add	a3,a3,s0
ffffffffc0201ab4:	02d78a63          	beq	a5,a3,ffffffffc0201ae8 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201ab8:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201aba:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201abc:	00469793          	slli	a5,a3,0x4
ffffffffc0201ac0:	97ba                	add	a5,a5,a4
ffffffffc0201ac2:	02f40e63          	beq	s0,a5,ffffffffc0201afe <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201ac6:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201ac8:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201aca:	e129                	bnez	a0,ffffffffc0201b0c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201acc:	60a2                	ld	ra,8(sp)
ffffffffc0201ace:	6402                	ld	s0,0(sp)
ffffffffc0201ad0:	0141                	addi	sp,sp,16
ffffffffc0201ad2:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ad4:	fcf764e3          	bltu	a4,a5,ffffffffc0201a9c <slob_free+0x20>
ffffffffc0201ad8:	fcf472e3          	bgeu	s0,a5,ffffffffc0201a9c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201adc:	400c                	lw	a1,0(s0)
ffffffffc0201ade:	00459693          	slli	a3,a1,0x4
ffffffffc0201ae2:	96a2                	add	a3,a3,s0
ffffffffc0201ae4:	fcd79ae3          	bne	a5,a3,ffffffffc0201ab8 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201ae8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201aea:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201aec:	9db5                	addw	a1,a1,a3
ffffffffc0201aee:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201af0:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201af2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201af4:	00469793          	slli	a5,a3,0x4
ffffffffc0201af8:	97ba                	add	a5,a5,a4
ffffffffc0201afa:	fcf416e3          	bne	s0,a5,ffffffffc0201ac6 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201afe:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201b00:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201b02:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201b04:	9ebd                	addw	a3,a3,a5
ffffffffc0201b06:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b08:	e70c                	sd	a1,8(a4)
ffffffffc0201b0a:	d169                	beqz	a0,ffffffffc0201acc <slob_free+0x50>
}
ffffffffc0201b0c:	6402                	ld	s0,0(sp)
ffffffffc0201b0e:	60a2                	ld	ra,8(sp)
ffffffffc0201b10:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201b12:	e9dfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b16:	25bd                	addiw	a1,a1,15
ffffffffc0201b18:	8191                	srli	a1,a1,0x4
ffffffffc0201b1a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b1c:	100027f3          	csrr	a5,sstatus
ffffffffc0201b20:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b22:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b24:	d7bd                	beqz	a5,ffffffffc0201a92 <slob_free+0x16>
        intr_disable();
ffffffffc0201b26:	e8ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b2a:	4505                	li	a0,1
ffffffffc0201b2c:	b79d                	j	ffffffffc0201a92 <slob_free+0x16>
ffffffffc0201b2e:	8082                	ret

ffffffffc0201b30 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b30:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b32:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b34:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b38:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b3a:	352000ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
	if (!page)
ffffffffc0201b3e:	c91d                	beqz	a0,ffffffffc0201b74 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b40:	000a9697          	auipc	a3,0xa9
ffffffffc0201b44:	a906b683          	ld	a3,-1392(a3) # ffffffffc02aa5d0 <pages>
ffffffffc0201b48:	8d15                	sub	a0,a0,a3
ffffffffc0201b4a:	8519                	srai	a0,a0,0x6
ffffffffc0201b4c:	00006697          	auipc	a3,0x6
ffffffffc0201b50:	c9c6b683          	ld	a3,-868(a3) # ffffffffc02077e8 <nbase>
ffffffffc0201b54:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201b56:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b5a:	83b1                	srli	a5,a5,0xc
ffffffffc0201b5c:	000a9717          	auipc	a4,0xa9
ffffffffc0201b60:	a6c73703          	ld	a4,-1428(a4) # ffffffffc02aa5c8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b64:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b66:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b7a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b6a:	000a9697          	auipc	a3,0xa9
ffffffffc0201b6e:	a766b683          	ld	a3,-1418(a3) # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0201b72:	9536                	add	a0,a0,a3
}
ffffffffc0201b74:	60a2                	ld	ra,8(sp)
ffffffffc0201b76:	0141                	addi	sp,sp,16
ffffffffc0201b78:	8082                	ret
ffffffffc0201b7a:	86aa                	mv	a3,a0
ffffffffc0201b7c:	00005617          	auipc	a2,0x5
ffffffffc0201b80:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0201b84:	07100593          	li	a1,113
ffffffffc0201b88:	00005517          	auipc	a0,0x5
ffffffffc0201b8c:	9c050513          	addi	a0,a0,-1600 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0201b90:	8fffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b94 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b94:	1101                	addi	sp,sp,-32
ffffffffc0201b96:	ec06                	sd	ra,24(sp)
ffffffffc0201b98:	e822                	sd	s0,16(sp)
ffffffffc0201b9a:	e426                	sd	s1,8(sp)
ffffffffc0201b9c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b9e:	01050713          	addi	a4,a0,16
ffffffffc0201ba2:	6785                	lui	a5,0x1
ffffffffc0201ba4:	0cf77363          	bgeu	a4,a5,ffffffffc0201c6a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201ba8:	00f50493          	addi	s1,a0,15
ffffffffc0201bac:	8091                	srli	s1,s1,0x4
ffffffffc0201bae:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bb0:	10002673          	csrr	a2,sstatus
ffffffffc0201bb4:	8a09                	andi	a2,a2,2
ffffffffc0201bb6:	e25d                	bnez	a2,ffffffffc0201c5c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201bb8:	000a4917          	auipc	s2,0xa4
ffffffffc0201bbc:	59890913          	addi	s2,s2,1432 # ffffffffc02a6150 <slobfree>
ffffffffc0201bc0:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bc4:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201bc6:	4398                	lw	a4,0(a5)
ffffffffc0201bc8:	08975e63          	bge	a4,s1,ffffffffc0201c64 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201bcc:	00f68b63          	beq	a3,a5,ffffffffc0201be2 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bd0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bd2:	4018                	lw	a4,0(s0)
ffffffffc0201bd4:	02975a63          	bge	a4,s1,ffffffffc0201c08 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201bd8:	00093683          	ld	a3,0(s2)
ffffffffc0201bdc:	87a2                	mv	a5,s0
ffffffffc0201bde:	fef699e3          	bne	a3,a5,ffffffffc0201bd0 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201be2:	ee31                	bnez	a2,ffffffffc0201c3e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201be4:	4501                	li	a0,0
ffffffffc0201be6:	f4bff0ef          	jal	ra,ffffffffc0201b30 <__slob_get_free_pages.constprop.0>
ffffffffc0201bea:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201bec:	cd05                	beqz	a0,ffffffffc0201c24 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201bee:	6585                	lui	a1,0x1
ffffffffc0201bf0:	e8dff0ef          	jal	ra,ffffffffc0201a7c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bf4:	10002673          	csrr	a2,sstatus
ffffffffc0201bf8:	8a09                	andi	a2,a2,2
ffffffffc0201bfa:	ee05                	bnez	a2,ffffffffc0201c32 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201bfc:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c00:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c02:	4018                	lw	a4,0(s0)
ffffffffc0201c04:	fc974ae3          	blt	a4,s1,ffffffffc0201bd8 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c08:	04e48763          	beq	s1,a4,ffffffffc0201c56 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c0c:	00449693          	slli	a3,s1,0x4
ffffffffc0201c10:	96a2                	add	a3,a3,s0
ffffffffc0201c12:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c14:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c16:	9f05                	subw	a4,a4,s1
ffffffffc0201c18:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c1a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c1c:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c1e:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c22:	e20d                	bnez	a2,ffffffffc0201c44 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c24:	60e2                	ld	ra,24(sp)
ffffffffc0201c26:	8522                	mv	a0,s0
ffffffffc0201c28:	6442                	ld	s0,16(sp)
ffffffffc0201c2a:	64a2                	ld	s1,8(sp)
ffffffffc0201c2c:	6902                	ld	s2,0(sp)
ffffffffc0201c2e:	6105                	addi	sp,sp,32
ffffffffc0201c30:	8082                	ret
        intr_disable();
ffffffffc0201c32:	d83fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c36:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c3a:	4605                	li	a2,1
ffffffffc0201c3c:	b7d1                	j	ffffffffc0201c00 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c3e:	d71fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c42:	b74d                	j	ffffffffc0201be4 <slob_alloc.constprop.0+0x50>
ffffffffc0201c44:	d6bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c48:	60e2                	ld	ra,24(sp)
ffffffffc0201c4a:	8522                	mv	a0,s0
ffffffffc0201c4c:	6442                	ld	s0,16(sp)
ffffffffc0201c4e:	64a2                	ld	s1,8(sp)
ffffffffc0201c50:	6902                	ld	s2,0(sp)
ffffffffc0201c52:	6105                	addi	sp,sp,32
ffffffffc0201c54:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c56:	6418                	ld	a4,8(s0)
ffffffffc0201c58:	e798                	sd	a4,8(a5)
ffffffffc0201c5a:	b7d1                	j	ffffffffc0201c1e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201c5c:	d59fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201c60:	4605                	li	a2,1
ffffffffc0201c62:	bf99                	j	ffffffffc0201bb8 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201c64:	843e                	mv	s0,a5
ffffffffc0201c66:	87b6                	mv	a5,a3
ffffffffc0201c68:	b745                	j	ffffffffc0201c08 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c6a:	00005697          	auipc	a3,0x5
ffffffffc0201c6e:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0206558 <default_pmm_manager+0x70>
ffffffffc0201c72:	00004617          	auipc	a2,0x4
ffffffffc0201c76:	4c660613          	addi	a2,a2,1222 # ffffffffc0206138 <commands+0x828>
ffffffffc0201c7a:	06300593          	li	a1,99
ffffffffc0201c7e:	00005517          	auipc	a0,0x5
ffffffffc0201c82:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0206578 <default_pmm_manager+0x90>
ffffffffc0201c86:	809fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c8a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c8a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c8c:	00005517          	auipc	a0,0x5
ffffffffc0201c90:	90450513          	addi	a0,a0,-1788 # ffffffffc0206590 <default_pmm_manager+0xa8>
{
ffffffffc0201c94:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201c96:	cfefe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c9a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c9c:	00005517          	auipc	a0,0x5
ffffffffc0201ca0:	90c50513          	addi	a0,a0,-1780 # ffffffffc02065a8 <default_pmm_manager+0xc0>
}
ffffffffc0201ca4:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ca6:	ceefe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201caa <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201caa:	4501                	li	a0,0
ffffffffc0201cac:	8082                	ret

ffffffffc0201cae <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cae:	1101                	addi	sp,sp,-32
ffffffffc0201cb0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cb2:	6905                	lui	s2,0x1
{
ffffffffc0201cb4:	e822                	sd	s0,16(sp)
ffffffffc0201cb6:	ec06                	sd	ra,24(sp)
ffffffffc0201cb8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cba:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8ba9>
{
ffffffffc0201cbe:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cc0:	04a7f963          	bgeu	a5,a0,ffffffffc0201d12 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cc4:	4561                	li	a0,24
ffffffffc0201cc6:	ecfff0ef          	jal	ra,ffffffffc0201b94 <slob_alloc.constprop.0>
ffffffffc0201cca:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ccc:	c929                	beqz	a0,ffffffffc0201d1e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201cce:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201cd2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201cd4:	00f95763          	bge	s2,a5,ffffffffc0201ce2 <kmalloc+0x34>
ffffffffc0201cd8:	6705                	lui	a4,0x1
ffffffffc0201cda:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201cdc:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cde:	fef74ee3          	blt	a4,a5,ffffffffc0201cda <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201ce2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ce4:	e4dff0ef          	jal	ra,ffffffffc0201b30 <__slob_get_free_pages.constprop.0>
ffffffffc0201ce8:	e488                	sd	a0,8(s1)
ffffffffc0201cea:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201cec:	c525                	beqz	a0,ffffffffc0201d54 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cee:	100027f3          	csrr	a5,sstatus
ffffffffc0201cf2:	8b89                	andi	a5,a5,2
ffffffffc0201cf4:	ef8d                	bnez	a5,ffffffffc0201d2e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201cf6:	000a9797          	auipc	a5,0xa9
ffffffffc0201cfa:	8ba78793          	addi	a5,a5,-1862 # ffffffffc02aa5b0 <bigblocks>
ffffffffc0201cfe:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d00:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d02:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201d04:	60e2                	ld	ra,24(sp)
ffffffffc0201d06:	8522                	mv	a0,s0
ffffffffc0201d08:	6442                	ld	s0,16(sp)
ffffffffc0201d0a:	64a2                	ld	s1,8(sp)
ffffffffc0201d0c:	6902                	ld	s2,0(sp)
ffffffffc0201d0e:	6105                	addi	sp,sp,32
ffffffffc0201d10:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d12:	0541                	addi	a0,a0,16
ffffffffc0201d14:	e81ff0ef          	jal	ra,ffffffffc0201b94 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d18:	01050413          	addi	s0,a0,16
ffffffffc0201d1c:	f565                	bnez	a0,ffffffffc0201d04 <kmalloc+0x56>
ffffffffc0201d1e:	4401                	li	s0,0
}
ffffffffc0201d20:	60e2                	ld	ra,24(sp)
ffffffffc0201d22:	8522                	mv	a0,s0
ffffffffc0201d24:	6442                	ld	s0,16(sp)
ffffffffc0201d26:	64a2                	ld	s1,8(sp)
ffffffffc0201d28:	6902                	ld	s2,0(sp)
ffffffffc0201d2a:	6105                	addi	sp,sp,32
ffffffffc0201d2c:	8082                	ret
        intr_disable();
ffffffffc0201d2e:	c87fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d32:	000a9797          	auipc	a5,0xa9
ffffffffc0201d36:	87e78793          	addi	a5,a5,-1922 # ffffffffc02aa5b0 <bigblocks>
ffffffffc0201d3a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d3c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d3e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d40:	c6ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d44:	6480                	ld	s0,8(s1)
}
ffffffffc0201d46:	60e2                	ld	ra,24(sp)
ffffffffc0201d48:	64a2                	ld	s1,8(sp)
ffffffffc0201d4a:	8522                	mv	a0,s0
ffffffffc0201d4c:	6442                	ld	s0,16(sp)
ffffffffc0201d4e:	6902                	ld	s2,0(sp)
ffffffffc0201d50:	6105                	addi	sp,sp,32
ffffffffc0201d52:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d54:	45e1                	li	a1,24
ffffffffc0201d56:	8526                	mv	a0,s1
ffffffffc0201d58:	d25ff0ef          	jal	ra,ffffffffc0201a7c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201d5c:	b765                	j	ffffffffc0201d04 <kmalloc+0x56>

ffffffffc0201d5e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d5e:	c169                	beqz	a0,ffffffffc0201e20 <kfree+0xc2>
{
ffffffffc0201d60:	1101                	addi	sp,sp,-32
ffffffffc0201d62:	e822                	sd	s0,16(sp)
ffffffffc0201d64:	ec06                	sd	ra,24(sp)
ffffffffc0201d66:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d68:	03451793          	slli	a5,a0,0x34
ffffffffc0201d6c:	842a                	mv	s0,a0
ffffffffc0201d6e:	e3d9                	bnez	a5,ffffffffc0201df4 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d70:	100027f3          	csrr	a5,sstatus
ffffffffc0201d74:	8b89                	andi	a5,a5,2
ffffffffc0201d76:	e7d9                	bnez	a5,ffffffffc0201e04 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d78:	000a9797          	auipc	a5,0xa9
ffffffffc0201d7c:	8387b783          	ld	a5,-1992(a5) # ffffffffc02aa5b0 <bigblocks>
    return 0;
ffffffffc0201d80:	4601                	li	a2,0
ffffffffc0201d82:	cbad                	beqz	a5,ffffffffc0201df4 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d84:	000a9697          	auipc	a3,0xa9
ffffffffc0201d88:	82c68693          	addi	a3,a3,-2004 # ffffffffc02aa5b0 <bigblocks>
ffffffffc0201d8c:	a021                	j	ffffffffc0201d94 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d8e:	01048693          	addi	a3,s1,16
ffffffffc0201d92:	c3a5                	beqz	a5,ffffffffc0201df2 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201d94:	6798                	ld	a4,8(a5)
ffffffffc0201d96:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201d98:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d9a:	fe871ae3          	bne	a4,s0,ffffffffc0201d8e <kfree+0x30>
				*last = bb->next;
ffffffffc0201d9e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201da0:	ee2d                	bnez	a2,ffffffffc0201e1a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201da2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201da6:	4098                	lw	a4,0(s1)
ffffffffc0201da8:	08f46963          	bltu	s0,a5,ffffffffc0201e3a <kfree+0xdc>
ffffffffc0201dac:	000a9697          	auipc	a3,0xa9
ffffffffc0201db0:	8346b683          	ld	a3,-1996(a3) # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0201db4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201db6:	8031                	srli	s0,s0,0xc
ffffffffc0201db8:	000a9797          	auipc	a5,0xa9
ffffffffc0201dbc:	8107b783          	ld	a5,-2032(a5) # ffffffffc02aa5c8 <npage>
ffffffffc0201dc0:	06f47163          	bgeu	s0,a5,ffffffffc0201e22 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dc4:	00006517          	auipc	a0,0x6
ffffffffc0201dc8:	a2453503          	ld	a0,-1500(a0) # ffffffffc02077e8 <nbase>
ffffffffc0201dcc:	8c09                	sub	s0,s0,a0
ffffffffc0201dce:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201dd0:	000a9517          	auipc	a0,0xa9
ffffffffc0201dd4:	80053503          	ld	a0,-2048(a0) # ffffffffc02aa5d0 <pages>
ffffffffc0201dd8:	4585                	li	a1,1
ffffffffc0201dda:	9522                	add	a0,a0,s0
ffffffffc0201ddc:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201de0:	0ea000ef          	jal	ra,ffffffffc0201eca <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201de4:	6442                	ld	s0,16(sp)
ffffffffc0201de6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201de8:	8526                	mv	a0,s1
}
ffffffffc0201dea:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dec:	45e1                	li	a1,24
}
ffffffffc0201dee:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201df0:	b171                	j	ffffffffc0201a7c <slob_free>
ffffffffc0201df2:	e20d                	bnez	a2,ffffffffc0201e14 <kfree+0xb6>
ffffffffc0201df4:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201df8:	6442                	ld	s0,16(sp)
ffffffffc0201dfa:	60e2                	ld	ra,24(sp)
ffffffffc0201dfc:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dfe:	4581                	li	a1,0
}
ffffffffc0201e00:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e02:	b9ad                	j	ffffffffc0201a7c <slob_free>
        intr_disable();
ffffffffc0201e04:	bb1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e08:	000a8797          	auipc	a5,0xa8
ffffffffc0201e0c:	7a87b783          	ld	a5,1960(a5) # ffffffffc02aa5b0 <bigblocks>
        return 1;
ffffffffc0201e10:	4605                	li	a2,1
ffffffffc0201e12:	fbad                	bnez	a5,ffffffffc0201d84 <kfree+0x26>
        intr_enable();
ffffffffc0201e14:	b9bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e18:	bff1                	j	ffffffffc0201df4 <kfree+0x96>
ffffffffc0201e1a:	b95fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e1e:	b751                	j	ffffffffc0201da2 <kfree+0x44>
ffffffffc0201e20:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e22:	00004617          	auipc	a2,0x4
ffffffffc0201e26:	7ce60613          	addi	a2,a2,1998 # ffffffffc02065f0 <default_pmm_manager+0x108>
ffffffffc0201e2a:	06900593          	li	a1,105
ffffffffc0201e2e:	00004517          	auipc	a0,0x4
ffffffffc0201e32:	71a50513          	addi	a0,a0,1818 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0201e36:	e58fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e3a:	86a2                	mv	a3,s0
ffffffffc0201e3c:	00004617          	auipc	a2,0x4
ffffffffc0201e40:	78c60613          	addi	a2,a2,1932 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc0201e44:	07700593          	li	a1,119
ffffffffc0201e48:	00004517          	auipc	a0,0x4
ffffffffc0201e4c:	70050513          	addi	a0,a0,1792 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0201e50:	e3efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e54 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e54:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e56:	00004617          	auipc	a2,0x4
ffffffffc0201e5a:	79a60613          	addi	a2,a2,1946 # ffffffffc02065f0 <default_pmm_manager+0x108>
ffffffffc0201e5e:	06900593          	li	a1,105
ffffffffc0201e62:	00004517          	auipc	a0,0x4
ffffffffc0201e66:	6e650513          	addi	a0,a0,1766 # ffffffffc0206548 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201e6a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e6c:	e22fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e70 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201e70:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201e72:	00004617          	auipc	a2,0x4
ffffffffc0201e76:	79e60613          	addi	a2,a2,1950 # ffffffffc0206610 <default_pmm_manager+0x128>
ffffffffc0201e7a:	07f00593          	li	a1,127
ffffffffc0201e7e:	00004517          	auipc	a0,0x4
ffffffffc0201e82:	6ca50513          	addi	a0,a0,1738 # ffffffffc0206548 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201e86:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201e88:	e06fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e8c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e8c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e90:	8b89                	andi	a5,a5,2
ffffffffc0201e92:	e799                	bnez	a5,ffffffffc0201ea0 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e94:	000a8797          	auipc	a5,0xa8
ffffffffc0201e98:	7447b783          	ld	a5,1860(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0201e9c:	6f9c                	ld	a5,24(a5)
ffffffffc0201e9e:	8782                	jr	a5
{
ffffffffc0201ea0:	1141                	addi	sp,sp,-16
ffffffffc0201ea2:	e406                	sd	ra,8(sp)
ffffffffc0201ea4:	e022                	sd	s0,0(sp)
ffffffffc0201ea6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201ea8:	b0dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eac:	000a8797          	auipc	a5,0xa8
ffffffffc0201eb0:	72c7b783          	ld	a5,1836(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0201eb4:	6f9c                	ld	a5,24(a5)
ffffffffc0201eb6:	8522                	mv	a0,s0
ffffffffc0201eb8:	9782                	jalr	a5
ffffffffc0201eba:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ebc:	af3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ec0:	60a2                	ld	ra,8(sp)
ffffffffc0201ec2:	8522                	mv	a0,s0
ffffffffc0201ec4:	6402                	ld	s0,0(sp)
ffffffffc0201ec6:	0141                	addi	sp,sp,16
ffffffffc0201ec8:	8082                	ret

ffffffffc0201eca <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eca:	100027f3          	csrr	a5,sstatus
ffffffffc0201ece:	8b89                	andi	a5,a5,2
ffffffffc0201ed0:	e799                	bnez	a5,ffffffffc0201ede <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ed2:	000a8797          	auipc	a5,0xa8
ffffffffc0201ed6:	7067b783          	ld	a5,1798(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0201eda:	739c                	ld	a5,32(a5)
ffffffffc0201edc:	8782                	jr	a5
{
ffffffffc0201ede:	1101                	addi	sp,sp,-32
ffffffffc0201ee0:	ec06                	sd	ra,24(sp)
ffffffffc0201ee2:	e822                	sd	s0,16(sp)
ffffffffc0201ee4:	e426                	sd	s1,8(sp)
ffffffffc0201ee6:	842a                	mv	s0,a0
ffffffffc0201ee8:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201eea:	acbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201eee:	000a8797          	auipc	a5,0xa8
ffffffffc0201ef2:	6ea7b783          	ld	a5,1770(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0201ef6:	739c                	ld	a5,32(a5)
ffffffffc0201ef8:	85a6                	mv	a1,s1
ffffffffc0201efa:	8522                	mv	a0,s0
ffffffffc0201efc:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201efe:	6442                	ld	s0,16(sp)
ffffffffc0201f00:	60e2                	ld	ra,24(sp)
ffffffffc0201f02:	64a2                	ld	s1,8(sp)
ffffffffc0201f04:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f06:	aa9fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f0a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f0a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f0e:	8b89                	andi	a5,a5,2
ffffffffc0201f10:	e799                	bnez	a5,ffffffffc0201f1e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f12:	000a8797          	auipc	a5,0xa8
ffffffffc0201f16:	6c67b783          	ld	a5,1734(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0201f1a:	779c                	ld	a5,40(a5)
ffffffffc0201f1c:	8782                	jr	a5
{
ffffffffc0201f1e:	1141                	addi	sp,sp,-16
ffffffffc0201f20:	e406                	sd	ra,8(sp)
ffffffffc0201f22:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f24:	a91fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f28:	000a8797          	auipc	a5,0xa8
ffffffffc0201f2c:	6b07b783          	ld	a5,1712(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0201f30:	779c                	ld	a5,40(a5)
ffffffffc0201f32:	9782                	jalr	a5
ffffffffc0201f34:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f36:	a79fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f3a:	60a2                	ld	ra,8(sp)
ffffffffc0201f3c:	8522                	mv	a0,s0
ffffffffc0201f3e:	6402                	ld	s0,0(sp)
ffffffffc0201f40:	0141                	addi	sp,sp,16
ffffffffc0201f42:	8082                	ret

ffffffffc0201f44 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f44:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f48:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f4c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f4e:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f50:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f52:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f56:	6094                	ld	a3,0(s1)
{
ffffffffc0201f58:	f04a                	sd	s2,32(sp)
ffffffffc0201f5a:	ec4e                	sd	s3,24(sp)
ffffffffc0201f5c:	e852                	sd	s4,16(sp)
ffffffffc0201f5e:	fc06                	sd	ra,56(sp)
ffffffffc0201f60:	f822                	sd	s0,48(sp)
ffffffffc0201f62:	e456                	sd	s5,8(sp)
ffffffffc0201f64:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f66:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f6a:	892e                	mv	s2,a1
ffffffffc0201f6c:	8a32                	mv	s4,a2
ffffffffc0201f6e:	000a8997          	auipc	s3,0xa8
ffffffffc0201f72:	65a98993          	addi	s3,s3,1626 # ffffffffc02aa5c8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f76:	efbd                	bnez	a5,ffffffffc0201ff4 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f78:	14060c63          	beqz	a2,ffffffffc02020d0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f7c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f80:	8b89                	andi	a5,a5,2
ffffffffc0201f82:	14079963          	bnez	a5,ffffffffc02020d4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f86:	000a8797          	auipc	a5,0xa8
ffffffffc0201f8a:	6527b783          	ld	a5,1618(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0201f8e:	6f9c                	ld	a5,24(a5)
ffffffffc0201f90:	4505                	li	a0,1
ffffffffc0201f92:	9782                	jalr	a5
ffffffffc0201f94:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f96:	12040d63          	beqz	s0,ffffffffc02020d0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f9a:	000a8b17          	auipc	s6,0xa8
ffffffffc0201f9e:	636b0b13          	addi	s6,s6,1590 # ffffffffc02aa5d0 <pages>
ffffffffc0201fa2:	000b3503          	ld	a0,0(s6)
ffffffffc0201fa6:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201faa:	000a8997          	auipc	s3,0xa8
ffffffffc0201fae:	61e98993          	addi	s3,s3,1566 # ffffffffc02aa5c8 <npage>
ffffffffc0201fb2:	40a40533          	sub	a0,s0,a0
ffffffffc0201fb6:	8519                	srai	a0,a0,0x6
ffffffffc0201fb8:	9556                	add	a0,a0,s5
ffffffffc0201fba:	0009b703          	ld	a4,0(s3)
ffffffffc0201fbe:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201fc2:	4685                	li	a3,1
ffffffffc0201fc4:	c014                	sw	a3,0(s0)
ffffffffc0201fc6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fc8:	0532                	slli	a0,a0,0xc
ffffffffc0201fca:	16e7f763          	bgeu	a5,a4,ffffffffc0202138 <get_pte+0x1f4>
ffffffffc0201fce:	000a8797          	auipc	a5,0xa8
ffffffffc0201fd2:	6127b783          	ld	a5,1554(a5) # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0201fd6:	6605                	lui	a2,0x1
ffffffffc0201fd8:	4581                	li	a1,0
ffffffffc0201fda:	953e                	add	a0,a0,a5
ffffffffc0201fdc:	69c030ef          	jal	ra,ffffffffc0205678 <memset>
    return page - pages + nbase;
ffffffffc0201fe0:	000b3683          	ld	a3,0(s6)
ffffffffc0201fe4:	40d406b3          	sub	a3,s0,a3
ffffffffc0201fe8:	8699                	srai	a3,a3,0x6
ffffffffc0201fea:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fec:	06aa                	slli	a3,a3,0xa
ffffffffc0201fee:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ff2:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ff4:	77fd                	lui	a5,0xfffff
ffffffffc0201ff6:	068a                	slli	a3,a3,0x2
ffffffffc0201ff8:	0009b703          	ld	a4,0(s3)
ffffffffc0201ffc:	8efd                	and	a3,a3,a5
ffffffffc0201ffe:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202002:	10e7ff63          	bgeu	a5,a4,ffffffffc0202120 <get_pte+0x1dc>
ffffffffc0202006:	000a8a97          	auipc	s5,0xa8
ffffffffc020200a:	5daa8a93          	addi	s5,s5,1498 # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc020200e:	000ab403          	ld	s0,0(s5)
ffffffffc0202012:	01595793          	srli	a5,s2,0x15
ffffffffc0202016:	1ff7f793          	andi	a5,a5,511
ffffffffc020201a:	96a2                	add	a3,a3,s0
ffffffffc020201c:	00379413          	slli	s0,a5,0x3
ffffffffc0202020:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202022:	6014                	ld	a3,0(s0)
ffffffffc0202024:	0016f793          	andi	a5,a3,1
ffffffffc0202028:	ebad                	bnez	a5,ffffffffc020209a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020202a:	0a0a0363          	beqz	s4,ffffffffc02020d0 <get_pte+0x18c>
ffffffffc020202e:	100027f3          	csrr	a5,sstatus
ffffffffc0202032:	8b89                	andi	a5,a5,2
ffffffffc0202034:	efcd                	bnez	a5,ffffffffc02020ee <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202036:	000a8797          	auipc	a5,0xa8
ffffffffc020203a:	5a27b783          	ld	a5,1442(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc020203e:	6f9c                	ld	a5,24(a5)
ffffffffc0202040:	4505                	li	a0,1
ffffffffc0202042:	9782                	jalr	a5
ffffffffc0202044:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202046:	c4c9                	beqz	s1,ffffffffc02020d0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202048:	000a8b17          	auipc	s6,0xa8
ffffffffc020204c:	588b0b13          	addi	s6,s6,1416 # ffffffffc02aa5d0 <pages>
ffffffffc0202050:	000b3503          	ld	a0,0(s6)
ffffffffc0202054:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202058:	0009b703          	ld	a4,0(s3)
ffffffffc020205c:	40a48533          	sub	a0,s1,a0
ffffffffc0202060:	8519                	srai	a0,a0,0x6
ffffffffc0202062:	9552                	add	a0,a0,s4
ffffffffc0202064:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202068:	4685                	li	a3,1
ffffffffc020206a:	c094                	sw	a3,0(s1)
ffffffffc020206c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020206e:	0532                	slli	a0,a0,0xc
ffffffffc0202070:	0ee7f163          	bgeu	a5,a4,ffffffffc0202152 <get_pte+0x20e>
ffffffffc0202074:	000ab783          	ld	a5,0(s5)
ffffffffc0202078:	6605                	lui	a2,0x1
ffffffffc020207a:	4581                	li	a1,0
ffffffffc020207c:	953e                	add	a0,a0,a5
ffffffffc020207e:	5fa030ef          	jal	ra,ffffffffc0205678 <memset>
    return page - pages + nbase;
ffffffffc0202082:	000b3683          	ld	a3,0(s6)
ffffffffc0202086:	40d486b3          	sub	a3,s1,a3
ffffffffc020208a:	8699                	srai	a3,a3,0x6
ffffffffc020208c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020208e:	06aa                	slli	a3,a3,0xa
ffffffffc0202090:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202094:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202096:	0009b703          	ld	a4,0(s3)
ffffffffc020209a:	068a                	slli	a3,a3,0x2
ffffffffc020209c:	757d                	lui	a0,0xfffff
ffffffffc020209e:	8ee9                	and	a3,a3,a0
ffffffffc02020a0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020a4:	06e7f263          	bgeu	a5,a4,ffffffffc0202108 <get_pte+0x1c4>
ffffffffc02020a8:	000ab503          	ld	a0,0(s5)
ffffffffc02020ac:	00c95913          	srli	s2,s2,0xc
ffffffffc02020b0:	1ff97913          	andi	s2,s2,511
ffffffffc02020b4:	96aa                	add	a3,a3,a0
ffffffffc02020b6:	00391513          	slli	a0,s2,0x3
ffffffffc02020ba:	9536                	add	a0,a0,a3
}
ffffffffc02020bc:	70e2                	ld	ra,56(sp)
ffffffffc02020be:	7442                	ld	s0,48(sp)
ffffffffc02020c0:	74a2                	ld	s1,40(sp)
ffffffffc02020c2:	7902                	ld	s2,32(sp)
ffffffffc02020c4:	69e2                	ld	s3,24(sp)
ffffffffc02020c6:	6a42                	ld	s4,16(sp)
ffffffffc02020c8:	6aa2                	ld	s5,8(sp)
ffffffffc02020ca:	6b02                	ld	s6,0(sp)
ffffffffc02020cc:	6121                	addi	sp,sp,64
ffffffffc02020ce:	8082                	ret
            return NULL;
ffffffffc02020d0:	4501                	li	a0,0
ffffffffc02020d2:	b7ed                	j	ffffffffc02020bc <get_pte+0x178>
        intr_disable();
ffffffffc02020d4:	8e1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020d8:	000a8797          	auipc	a5,0xa8
ffffffffc02020dc:	5007b783          	ld	a5,1280(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc02020e0:	6f9c                	ld	a5,24(a5)
ffffffffc02020e2:	4505                	li	a0,1
ffffffffc02020e4:	9782                	jalr	a5
ffffffffc02020e6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020e8:	8c7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020ec:	b56d                	j	ffffffffc0201f96 <get_pte+0x52>
        intr_disable();
ffffffffc02020ee:	8c7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02020f2:	000a8797          	auipc	a5,0xa8
ffffffffc02020f6:	4e67b783          	ld	a5,1254(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc02020fa:	6f9c                	ld	a5,24(a5)
ffffffffc02020fc:	4505                	li	a0,1
ffffffffc02020fe:	9782                	jalr	a5
ffffffffc0202100:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202102:	8adfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202106:	b781                	j	ffffffffc0202046 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202108:	00004617          	auipc	a2,0x4
ffffffffc020210c:	41860613          	addi	a2,a2,1048 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0202110:	0fa00593          	li	a1,250
ffffffffc0202114:	00004517          	auipc	a0,0x4
ffffffffc0202118:	52450513          	addi	a0,a0,1316 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020211c:	b72fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202120:	00004617          	auipc	a2,0x4
ffffffffc0202124:	40060613          	addi	a2,a2,1024 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0202128:	0ed00593          	li	a1,237
ffffffffc020212c:	00004517          	auipc	a0,0x4
ffffffffc0202130:	50c50513          	addi	a0,a0,1292 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202134:	b5afe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202138:	86aa                	mv	a3,a0
ffffffffc020213a:	00004617          	auipc	a2,0x4
ffffffffc020213e:	3e660613          	addi	a2,a2,998 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0202142:	0e900593          	li	a1,233
ffffffffc0202146:	00004517          	auipc	a0,0x4
ffffffffc020214a:	4f250513          	addi	a0,a0,1266 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020214e:	b40fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202152:	86aa                	mv	a3,a0
ffffffffc0202154:	00004617          	auipc	a2,0x4
ffffffffc0202158:	3cc60613          	addi	a2,a2,972 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc020215c:	0f700593          	li	a1,247
ffffffffc0202160:	00004517          	auipc	a0,0x4
ffffffffc0202164:	4d850513          	addi	a0,a0,1240 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202168:	b26fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020216c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020216c:	1141                	addi	sp,sp,-16
ffffffffc020216e:	e022                	sd	s0,0(sp)
ffffffffc0202170:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202172:	4601                	li	a2,0
{
ffffffffc0202174:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202176:	dcfff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
    if (ptep_store != NULL)
ffffffffc020217a:	c011                	beqz	s0,ffffffffc020217e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020217c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020217e:	c511                	beqz	a0,ffffffffc020218a <get_page+0x1e>
ffffffffc0202180:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202182:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202184:	0017f713          	andi	a4,a5,1
ffffffffc0202188:	e709                	bnez	a4,ffffffffc0202192 <get_page+0x26>
}
ffffffffc020218a:	60a2                	ld	ra,8(sp)
ffffffffc020218c:	6402                	ld	s0,0(sp)
ffffffffc020218e:	0141                	addi	sp,sp,16
ffffffffc0202190:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202192:	078a                	slli	a5,a5,0x2
ffffffffc0202194:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202196:	000a8717          	auipc	a4,0xa8
ffffffffc020219a:	43273703          	ld	a4,1074(a4) # ffffffffc02aa5c8 <npage>
ffffffffc020219e:	00e7ff63          	bgeu	a5,a4,ffffffffc02021bc <get_page+0x50>
ffffffffc02021a2:	60a2                	ld	ra,8(sp)
ffffffffc02021a4:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02021a6:	fff80537          	lui	a0,0xfff80
ffffffffc02021aa:	97aa                	add	a5,a5,a0
ffffffffc02021ac:	079a                	slli	a5,a5,0x6
ffffffffc02021ae:	000a8517          	auipc	a0,0xa8
ffffffffc02021b2:	42253503          	ld	a0,1058(a0) # ffffffffc02aa5d0 <pages>
ffffffffc02021b6:	953e                	add	a0,a0,a5
ffffffffc02021b8:	0141                	addi	sp,sp,16
ffffffffc02021ba:	8082                	ret
ffffffffc02021bc:	c99ff0ef          	jal	ra,ffffffffc0201e54 <pa2page.part.0>

ffffffffc02021c0 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021c0:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021c2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021c6:	f486                	sd	ra,104(sp)
ffffffffc02021c8:	f0a2                	sd	s0,96(sp)
ffffffffc02021ca:	eca6                	sd	s1,88(sp)
ffffffffc02021cc:	e8ca                	sd	s2,80(sp)
ffffffffc02021ce:	e4ce                	sd	s3,72(sp)
ffffffffc02021d0:	e0d2                	sd	s4,64(sp)
ffffffffc02021d2:	fc56                	sd	s5,56(sp)
ffffffffc02021d4:	f85a                	sd	s6,48(sp)
ffffffffc02021d6:	f45e                	sd	s7,40(sp)
ffffffffc02021d8:	f062                	sd	s8,32(sp)
ffffffffc02021da:	ec66                	sd	s9,24(sp)
ffffffffc02021dc:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021de:	17d2                	slli	a5,a5,0x34
ffffffffc02021e0:	e3ed                	bnez	a5,ffffffffc02022c2 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02021e2:	002007b7          	lui	a5,0x200
ffffffffc02021e6:	842e                	mv	s0,a1
ffffffffc02021e8:	0ef5ed63          	bltu	a1,a5,ffffffffc02022e2 <unmap_range+0x122>
ffffffffc02021ec:	8932                	mv	s2,a2
ffffffffc02021ee:	0ec5fa63          	bgeu	a1,a2,ffffffffc02022e2 <unmap_range+0x122>
ffffffffc02021f2:	4785                	li	a5,1
ffffffffc02021f4:	07fe                	slli	a5,a5,0x1f
ffffffffc02021f6:	0ec7e663          	bltu	a5,a2,ffffffffc02022e2 <unmap_range+0x122>
ffffffffc02021fa:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021fc:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02021fe:	000a8c97          	auipc	s9,0xa8
ffffffffc0202202:	3cac8c93          	addi	s9,s9,970 # ffffffffc02aa5c8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202206:	000a8c17          	auipc	s8,0xa8
ffffffffc020220a:	3cac0c13          	addi	s8,s8,970 # ffffffffc02aa5d0 <pages>
ffffffffc020220e:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202212:	000a8d17          	auipc	s10,0xa8
ffffffffc0202216:	3c6d0d13          	addi	s10,s10,966 # ffffffffc02aa5d8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020221a:	00200b37          	lui	s6,0x200
ffffffffc020221e:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202222:	4601                	li	a2,0
ffffffffc0202224:	85a2                	mv	a1,s0
ffffffffc0202226:	854e                	mv	a0,s3
ffffffffc0202228:	d1dff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
ffffffffc020222c:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020222e:	cd29                	beqz	a0,ffffffffc0202288 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202230:	611c                	ld	a5,0(a0)
ffffffffc0202232:	e395                	bnez	a5,ffffffffc0202256 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202234:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202236:	ff2466e3          	bltu	s0,s2,ffffffffc0202222 <unmap_range+0x62>
}
ffffffffc020223a:	70a6                	ld	ra,104(sp)
ffffffffc020223c:	7406                	ld	s0,96(sp)
ffffffffc020223e:	64e6                	ld	s1,88(sp)
ffffffffc0202240:	6946                	ld	s2,80(sp)
ffffffffc0202242:	69a6                	ld	s3,72(sp)
ffffffffc0202244:	6a06                	ld	s4,64(sp)
ffffffffc0202246:	7ae2                	ld	s5,56(sp)
ffffffffc0202248:	7b42                	ld	s6,48(sp)
ffffffffc020224a:	7ba2                	ld	s7,40(sp)
ffffffffc020224c:	7c02                	ld	s8,32(sp)
ffffffffc020224e:	6ce2                	ld	s9,24(sp)
ffffffffc0202250:	6d42                	ld	s10,16(sp)
ffffffffc0202252:	6165                	addi	sp,sp,112
ffffffffc0202254:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202256:	0017f713          	andi	a4,a5,1
ffffffffc020225a:	df69                	beqz	a4,ffffffffc0202234 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020225c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202260:	078a                	slli	a5,a5,0x2
ffffffffc0202262:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202264:	08e7ff63          	bgeu	a5,a4,ffffffffc0202302 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202268:	000c3503          	ld	a0,0(s8)
ffffffffc020226c:	97de                	add	a5,a5,s7
ffffffffc020226e:	079a                	slli	a5,a5,0x6
ffffffffc0202270:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202272:	411c                	lw	a5,0(a0)
ffffffffc0202274:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202278:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020227a:	cf11                	beqz	a4,ffffffffc0202296 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020227c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202280:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202284:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202286:	bf45                	j	ffffffffc0202236 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202288:	945a                	add	s0,s0,s6
ffffffffc020228a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020228e:	d455                	beqz	s0,ffffffffc020223a <unmap_range+0x7a>
ffffffffc0202290:	f92469e3          	bltu	s0,s2,ffffffffc0202222 <unmap_range+0x62>
ffffffffc0202294:	b75d                	j	ffffffffc020223a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202296:	100027f3          	csrr	a5,sstatus
ffffffffc020229a:	8b89                	andi	a5,a5,2
ffffffffc020229c:	e799                	bnez	a5,ffffffffc02022aa <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020229e:	000d3783          	ld	a5,0(s10)
ffffffffc02022a2:	4585                	li	a1,1
ffffffffc02022a4:	739c                	ld	a5,32(a5)
ffffffffc02022a6:	9782                	jalr	a5
    if (flag)
ffffffffc02022a8:	bfd1                	j	ffffffffc020227c <unmap_range+0xbc>
ffffffffc02022aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02022ac:	f08fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02022b0:	000d3783          	ld	a5,0(s10)
ffffffffc02022b4:	6522                	ld	a0,8(sp)
ffffffffc02022b6:	4585                	li	a1,1
ffffffffc02022b8:	739c                	ld	a5,32(a5)
ffffffffc02022ba:	9782                	jalr	a5
        intr_enable();
ffffffffc02022bc:	ef2fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022c0:	bf75                	j	ffffffffc020227c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022c2:	00004697          	auipc	a3,0x4
ffffffffc02022c6:	38668693          	addi	a3,a3,902 # ffffffffc0206648 <default_pmm_manager+0x160>
ffffffffc02022ca:	00004617          	auipc	a2,0x4
ffffffffc02022ce:	e6e60613          	addi	a2,a2,-402 # ffffffffc0206138 <commands+0x828>
ffffffffc02022d2:	12000593          	li	a1,288
ffffffffc02022d6:	00004517          	auipc	a0,0x4
ffffffffc02022da:	36250513          	addi	a0,a0,866 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02022de:	9b0fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022e2:	00004697          	auipc	a3,0x4
ffffffffc02022e6:	39668693          	addi	a3,a3,918 # ffffffffc0206678 <default_pmm_manager+0x190>
ffffffffc02022ea:	00004617          	auipc	a2,0x4
ffffffffc02022ee:	e4e60613          	addi	a2,a2,-434 # ffffffffc0206138 <commands+0x828>
ffffffffc02022f2:	12100593          	li	a1,289
ffffffffc02022f6:	00004517          	auipc	a0,0x4
ffffffffc02022fa:	34250513          	addi	a0,a0,834 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02022fe:	990fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202302:	b53ff0ef          	jal	ra,ffffffffc0201e54 <pa2page.part.0>

ffffffffc0202306 <exit_range>:
{
ffffffffc0202306:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202308:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020230c:	fc86                	sd	ra,120(sp)
ffffffffc020230e:	f8a2                	sd	s0,112(sp)
ffffffffc0202310:	f4a6                	sd	s1,104(sp)
ffffffffc0202312:	f0ca                	sd	s2,96(sp)
ffffffffc0202314:	ecce                	sd	s3,88(sp)
ffffffffc0202316:	e8d2                	sd	s4,80(sp)
ffffffffc0202318:	e4d6                	sd	s5,72(sp)
ffffffffc020231a:	e0da                	sd	s6,64(sp)
ffffffffc020231c:	fc5e                	sd	s7,56(sp)
ffffffffc020231e:	f862                	sd	s8,48(sp)
ffffffffc0202320:	f466                	sd	s9,40(sp)
ffffffffc0202322:	f06a                	sd	s10,32(sp)
ffffffffc0202324:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202326:	17d2                	slli	a5,a5,0x34
ffffffffc0202328:	20079a63          	bnez	a5,ffffffffc020253c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020232c:	002007b7          	lui	a5,0x200
ffffffffc0202330:	24f5e463          	bltu	a1,a5,ffffffffc0202578 <exit_range+0x272>
ffffffffc0202334:	8ab2                	mv	s5,a2
ffffffffc0202336:	24c5f163          	bgeu	a1,a2,ffffffffc0202578 <exit_range+0x272>
ffffffffc020233a:	4785                	li	a5,1
ffffffffc020233c:	07fe                	slli	a5,a5,0x1f
ffffffffc020233e:	22c7ed63          	bltu	a5,a2,ffffffffc0202578 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202342:	c00009b7          	lui	s3,0xc0000
ffffffffc0202346:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020234a:	ffe00937          	lui	s2,0xffe00
ffffffffc020234e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202352:	5cfd                	li	s9,-1
ffffffffc0202354:	8c2a                	mv	s8,a0
ffffffffc0202356:	0125f933          	and	s2,a1,s2
ffffffffc020235a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020235c:	000a8d17          	auipc	s10,0xa8
ffffffffc0202360:	26cd0d13          	addi	s10,s10,620 # ffffffffc02aa5c8 <npage>
    return KADDR(page2pa(page));
ffffffffc0202364:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202368:	000a8717          	auipc	a4,0xa8
ffffffffc020236c:	26870713          	addi	a4,a4,616 # ffffffffc02aa5d0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202370:	000a8d97          	auipc	s11,0xa8
ffffffffc0202374:	268d8d93          	addi	s11,s11,616 # ffffffffc02aa5d8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202378:	c0000437          	lui	s0,0xc0000
ffffffffc020237c:	944e                	add	s0,s0,s3
ffffffffc020237e:	8079                	srli	s0,s0,0x1e
ffffffffc0202380:	1ff47413          	andi	s0,s0,511
ffffffffc0202384:	040e                	slli	s0,s0,0x3
ffffffffc0202386:	9462                	add	s0,s0,s8
ffffffffc0202388:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ef8>
        if (pde1 & PTE_V)
ffffffffc020238c:	001a7793          	andi	a5,s4,1
ffffffffc0202390:	eb99                	bnez	a5,ffffffffc02023a6 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202392:	12098463          	beqz	s3,ffffffffc02024ba <exit_range+0x1b4>
ffffffffc0202396:	400007b7          	lui	a5,0x40000
ffffffffc020239a:	97ce                	add	a5,a5,s3
ffffffffc020239c:	894e                	mv	s2,s3
ffffffffc020239e:	1159fe63          	bgeu	s3,s5,ffffffffc02024ba <exit_range+0x1b4>
ffffffffc02023a2:	89be                	mv	s3,a5
ffffffffc02023a4:	bfd1                	j	ffffffffc0202378 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02023a6:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023aa:	0a0a                	slli	s4,s4,0x2
ffffffffc02023ac:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02023b0:	1cfa7263          	bgeu	s4,a5,ffffffffc0202574 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b4:	fff80637          	lui	a2,0xfff80
ffffffffc02023b8:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02023ba:	000806b7          	lui	a3,0x80
ffffffffc02023be:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02023c0:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02023c4:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023c6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023c8:	18f5fa63          	bgeu	a1,a5,ffffffffc020255c <exit_range+0x256>
ffffffffc02023cc:	000a8817          	auipc	a6,0xa8
ffffffffc02023d0:	21480813          	addi	a6,a6,532 # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc02023d4:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02023d8:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02023da:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02023de:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02023e0:	00080337          	lui	t1,0x80
ffffffffc02023e4:	6885                	lui	a7,0x1
ffffffffc02023e6:	a819                	j	ffffffffc02023fc <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02023e8:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02023ea:	002007b7          	lui	a5,0x200
ffffffffc02023ee:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023f0:	08090c63          	beqz	s2,ffffffffc0202488 <exit_range+0x182>
ffffffffc02023f4:	09397a63          	bgeu	s2,s3,ffffffffc0202488 <exit_range+0x182>
ffffffffc02023f8:	0f597063          	bgeu	s2,s5,ffffffffc02024d8 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023fc:	01595493          	srli	s1,s2,0x15
ffffffffc0202400:	1ff4f493          	andi	s1,s1,511
ffffffffc0202404:	048e                	slli	s1,s1,0x3
ffffffffc0202406:	94da                	add	s1,s1,s6
ffffffffc0202408:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020240a:	0017f693          	andi	a3,a5,1
ffffffffc020240e:	dee9                	beqz	a3,ffffffffc02023e8 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202410:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202414:	078a                	slli	a5,a5,0x2
ffffffffc0202416:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202418:	14b7fe63          	bgeu	a5,a1,ffffffffc0202574 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020241c:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020241e:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202422:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202426:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020242a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020242c:	12bef863          	bgeu	t4,a1,ffffffffc020255c <exit_range+0x256>
ffffffffc0202430:	00083783          	ld	a5,0(a6)
ffffffffc0202434:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202436:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020243a:	629c                	ld	a5,0(a3)
ffffffffc020243c:	8b85                	andi	a5,a5,1
ffffffffc020243e:	f7d5                	bnez	a5,ffffffffc02023ea <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202440:	06a1                	addi	a3,a3,8
ffffffffc0202442:	fed59ce3          	bne	a1,a3,ffffffffc020243a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202446:	631c                	ld	a5,0(a4)
ffffffffc0202448:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020244a:	100027f3          	csrr	a5,sstatus
ffffffffc020244e:	8b89                	andi	a5,a5,2
ffffffffc0202450:	e7d9                	bnez	a5,ffffffffc02024de <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202452:	000db783          	ld	a5,0(s11)
ffffffffc0202456:	4585                	li	a1,1
ffffffffc0202458:	e032                	sd	a2,0(sp)
ffffffffc020245a:	739c                	ld	a5,32(a5)
ffffffffc020245c:	9782                	jalr	a5
    if (flag)
ffffffffc020245e:	6602                	ld	a2,0(sp)
ffffffffc0202460:	000a8817          	auipc	a6,0xa8
ffffffffc0202464:	18080813          	addi	a6,a6,384 # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0202468:	fff80e37          	lui	t3,0xfff80
ffffffffc020246c:	00080337          	lui	t1,0x80
ffffffffc0202470:	6885                	lui	a7,0x1
ffffffffc0202472:	000a8717          	auipc	a4,0xa8
ffffffffc0202476:	15e70713          	addi	a4,a4,350 # ffffffffc02aa5d0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020247a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020247e:	002007b7          	lui	a5,0x200
ffffffffc0202482:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202484:	f60918e3          	bnez	s2,ffffffffc02023f4 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202488:	f00b85e3          	beqz	s7,ffffffffc0202392 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020248c:	000d3783          	ld	a5,0(s10)
ffffffffc0202490:	0efa7263          	bgeu	s4,a5,ffffffffc0202574 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202494:	6308                	ld	a0,0(a4)
ffffffffc0202496:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202498:	100027f3          	csrr	a5,sstatus
ffffffffc020249c:	8b89                	andi	a5,a5,2
ffffffffc020249e:	efad                	bnez	a5,ffffffffc0202518 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02024a0:	000db783          	ld	a5,0(s11)
ffffffffc02024a4:	4585                	li	a1,1
ffffffffc02024a6:	739c                	ld	a5,32(a5)
ffffffffc02024a8:	9782                	jalr	a5
ffffffffc02024aa:	000a8717          	auipc	a4,0xa8
ffffffffc02024ae:	12670713          	addi	a4,a4,294 # ffffffffc02aa5d0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02024b2:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02024b6:	ee0990e3          	bnez	s3,ffffffffc0202396 <exit_range+0x90>
}
ffffffffc02024ba:	70e6                	ld	ra,120(sp)
ffffffffc02024bc:	7446                	ld	s0,112(sp)
ffffffffc02024be:	74a6                	ld	s1,104(sp)
ffffffffc02024c0:	7906                	ld	s2,96(sp)
ffffffffc02024c2:	69e6                	ld	s3,88(sp)
ffffffffc02024c4:	6a46                	ld	s4,80(sp)
ffffffffc02024c6:	6aa6                	ld	s5,72(sp)
ffffffffc02024c8:	6b06                	ld	s6,64(sp)
ffffffffc02024ca:	7be2                	ld	s7,56(sp)
ffffffffc02024cc:	7c42                	ld	s8,48(sp)
ffffffffc02024ce:	7ca2                	ld	s9,40(sp)
ffffffffc02024d0:	7d02                	ld	s10,32(sp)
ffffffffc02024d2:	6de2                	ld	s11,24(sp)
ffffffffc02024d4:	6109                	addi	sp,sp,128
ffffffffc02024d6:	8082                	ret
            if (free_pd0)
ffffffffc02024d8:	ea0b8fe3          	beqz	s7,ffffffffc0202396 <exit_range+0x90>
ffffffffc02024dc:	bf45                	j	ffffffffc020248c <exit_range+0x186>
ffffffffc02024de:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02024e0:	e42a                	sd	a0,8(sp)
ffffffffc02024e2:	cd2fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024e6:	000db783          	ld	a5,0(s11)
ffffffffc02024ea:	6522                	ld	a0,8(sp)
ffffffffc02024ec:	4585                	li	a1,1
ffffffffc02024ee:	739c                	ld	a5,32(a5)
ffffffffc02024f0:	9782                	jalr	a5
        intr_enable();
ffffffffc02024f2:	cbcfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02024f6:	6602                	ld	a2,0(sp)
ffffffffc02024f8:	000a8717          	auipc	a4,0xa8
ffffffffc02024fc:	0d870713          	addi	a4,a4,216 # ffffffffc02aa5d0 <pages>
ffffffffc0202500:	6885                	lui	a7,0x1
ffffffffc0202502:	00080337          	lui	t1,0x80
ffffffffc0202506:	fff80e37          	lui	t3,0xfff80
ffffffffc020250a:	000a8817          	auipc	a6,0xa8
ffffffffc020250e:	0d680813          	addi	a6,a6,214 # ffffffffc02aa5e0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202512:	0004b023          	sd	zero,0(s1)
ffffffffc0202516:	b7a5                	j	ffffffffc020247e <exit_range+0x178>
ffffffffc0202518:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020251a:	c9afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020251e:	000db783          	ld	a5,0(s11)
ffffffffc0202522:	6502                	ld	a0,0(sp)
ffffffffc0202524:	4585                	li	a1,1
ffffffffc0202526:	739c                	ld	a5,32(a5)
ffffffffc0202528:	9782                	jalr	a5
        intr_enable();
ffffffffc020252a:	c84fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020252e:	000a8717          	auipc	a4,0xa8
ffffffffc0202532:	0a270713          	addi	a4,a4,162 # ffffffffc02aa5d0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202536:	00043023          	sd	zero,0(s0)
ffffffffc020253a:	bfb5                	j	ffffffffc02024b6 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020253c:	00004697          	auipc	a3,0x4
ffffffffc0202540:	10c68693          	addi	a3,a3,268 # ffffffffc0206648 <default_pmm_manager+0x160>
ffffffffc0202544:	00004617          	auipc	a2,0x4
ffffffffc0202548:	bf460613          	addi	a2,a2,-1036 # ffffffffc0206138 <commands+0x828>
ffffffffc020254c:	13500593          	li	a1,309
ffffffffc0202550:	00004517          	auipc	a0,0x4
ffffffffc0202554:	0e850513          	addi	a0,a0,232 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202558:	f37fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020255c:	00004617          	auipc	a2,0x4
ffffffffc0202560:	fc460613          	addi	a2,a2,-60 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0202564:	07100593          	li	a1,113
ffffffffc0202568:	00004517          	auipc	a0,0x4
ffffffffc020256c:	fe050513          	addi	a0,a0,-32 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0202570:	f1ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202574:	8e1ff0ef          	jal	ra,ffffffffc0201e54 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202578:	00004697          	auipc	a3,0x4
ffffffffc020257c:	10068693          	addi	a3,a3,256 # ffffffffc0206678 <default_pmm_manager+0x190>
ffffffffc0202580:	00004617          	auipc	a2,0x4
ffffffffc0202584:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206138 <commands+0x828>
ffffffffc0202588:	13600593          	li	a1,310
ffffffffc020258c:	00004517          	auipc	a0,0x4
ffffffffc0202590:	0ac50513          	addi	a0,a0,172 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202594:	efbfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202598 <page_remove>:
{
ffffffffc0202598:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020259a:	4601                	li	a2,0
{
ffffffffc020259c:	ec26                	sd	s1,24(sp)
ffffffffc020259e:	f406                	sd	ra,40(sp)
ffffffffc02025a0:	f022                	sd	s0,32(sp)
ffffffffc02025a2:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025a4:	9a1ff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
    if (ptep != NULL)
ffffffffc02025a8:	c511                	beqz	a0,ffffffffc02025b4 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02025aa:	611c                	ld	a5,0(a0)
ffffffffc02025ac:	842a                	mv	s0,a0
ffffffffc02025ae:	0017f713          	andi	a4,a5,1
ffffffffc02025b2:	e711                	bnez	a4,ffffffffc02025be <page_remove+0x26>
}
ffffffffc02025b4:	70a2                	ld	ra,40(sp)
ffffffffc02025b6:	7402                	ld	s0,32(sp)
ffffffffc02025b8:	64e2                	ld	s1,24(sp)
ffffffffc02025ba:	6145                	addi	sp,sp,48
ffffffffc02025bc:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02025be:	078a                	slli	a5,a5,0x2
ffffffffc02025c0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025c2:	000a8717          	auipc	a4,0xa8
ffffffffc02025c6:	00673703          	ld	a4,6(a4) # ffffffffc02aa5c8 <npage>
ffffffffc02025ca:	06e7f363          	bgeu	a5,a4,ffffffffc0202630 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ce:	fff80537          	lui	a0,0xfff80
ffffffffc02025d2:	97aa                	add	a5,a5,a0
ffffffffc02025d4:	079a                	slli	a5,a5,0x6
ffffffffc02025d6:	000a8517          	auipc	a0,0xa8
ffffffffc02025da:	ffa53503          	ld	a0,-6(a0) # ffffffffc02aa5d0 <pages>
ffffffffc02025de:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02025e0:	411c                	lw	a5,0(a0)
ffffffffc02025e2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02025e6:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02025e8:	cb11                	beqz	a4,ffffffffc02025fc <page_remove+0x64>
        *ptep = 0;
ffffffffc02025ea:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025ee:	12048073          	sfence.vma	s1
}
ffffffffc02025f2:	70a2                	ld	ra,40(sp)
ffffffffc02025f4:	7402                	ld	s0,32(sp)
ffffffffc02025f6:	64e2                	ld	s1,24(sp)
ffffffffc02025f8:	6145                	addi	sp,sp,48
ffffffffc02025fa:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025fc:	100027f3          	csrr	a5,sstatus
ffffffffc0202600:	8b89                	andi	a5,a5,2
ffffffffc0202602:	eb89                	bnez	a5,ffffffffc0202614 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202604:	000a8797          	auipc	a5,0xa8
ffffffffc0202608:	fd47b783          	ld	a5,-44(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc020260c:	739c                	ld	a5,32(a5)
ffffffffc020260e:	4585                	li	a1,1
ffffffffc0202610:	9782                	jalr	a5
    if (flag)
ffffffffc0202612:	bfe1                	j	ffffffffc02025ea <page_remove+0x52>
        intr_disable();
ffffffffc0202614:	e42a                	sd	a0,8(sp)
ffffffffc0202616:	b9efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020261a:	000a8797          	auipc	a5,0xa8
ffffffffc020261e:	fbe7b783          	ld	a5,-66(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc0202622:	739c                	ld	a5,32(a5)
ffffffffc0202624:	6522                	ld	a0,8(sp)
ffffffffc0202626:	4585                	li	a1,1
ffffffffc0202628:	9782                	jalr	a5
        intr_enable();
ffffffffc020262a:	b84fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020262e:	bf75                	j	ffffffffc02025ea <page_remove+0x52>
ffffffffc0202630:	825ff0ef          	jal	ra,ffffffffc0201e54 <pa2page.part.0>

ffffffffc0202634 <page_insert>:
{
ffffffffc0202634:	7139                	addi	sp,sp,-64
ffffffffc0202636:	e852                	sd	s4,16(sp)
ffffffffc0202638:	8a32                	mv	s4,a2
ffffffffc020263a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020263c:	4605                	li	a2,1
{
ffffffffc020263e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202640:	85d2                	mv	a1,s4
{
ffffffffc0202642:	f426                	sd	s1,40(sp)
ffffffffc0202644:	fc06                	sd	ra,56(sp)
ffffffffc0202646:	f04a                	sd	s2,32(sp)
ffffffffc0202648:	ec4e                	sd	s3,24(sp)
ffffffffc020264a:	e456                	sd	s5,8(sp)
ffffffffc020264c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020264e:	8f7ff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
    if (ptep == NULL)
ffffffffc0202652:	c961                	beqz	a0,ffffffffc0202722 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202654:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202656:	611c                	ld	a5,0(a0)
ffffffffc0202658:	89aa                	mv	s3,a0
ffffffffc020265a:	0016871b          	addiw	a4,a3,1
ffffffffc020265e:	c018                	sw	a4,0(s0)
ffffffffc0202660:	0017f713          	andi	a4,a5,1
ffffffffc0202664:	ef05                	bnez	a4,ffffffffc020269c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202666:	000a8717          	auipc	a4,0xa8
ffffffffc020266a:	f6a73703          	ld	a4,-150(a4) # ffffffffc02aa5d0 <pages>
ffffffffc020266e:	8c19                	sub	s0,s0,a4
ffffffffc0202670:	000807b7          	lui	a5,0x80
ffffffffc0202674:	8419                	srai	s0,s0,0x6
ffffffffc0202676:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202678:	042a                	slli	s0,s0,0xa
ffffffffc020267a:	8cc1                	or	s1,s1,s0
ffffffffc020267c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202680:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ef8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202684:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202688:	4501                	li	a0,0
}
ffffffffc020268a:	70e2                	ld	ra,56(sp)
ffffffffc020268c:	7442                	ld	s0,48(sp)
ffffffffc020268e:	74a2                	ld	s1,40(sp)
ffffffffc0202690:	7902                	ld	s2,32(sp)
ffffffffc0202692:	69e2                	ld	s3,24(sp)
ffffffffc0202694:	6a42                	ld	s4,16(sp)
ffffffffc0202696:	6aa2                	ld	s5,8(sp)
ffffffffc0202698:	6121                	addi	sp,sp,64
ffffffffc020269a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020269c:	078a                	slli	a5,a5,0x2
ffffffffc020269e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026a0:	000a8717          	auipc	a4,0xa8
ffffffffc02026a4:	f2873703          	ld	a4,-216(a4) # ffffffffc02aa5c8 <npage>
ffffffffc02026a8:	06e7ff63          	bgeu	a5,a4,ffffffffc0202726 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026ac:	000a8a97          	auipc	s5,0xa8
ffffffffc02026b0:	f24a8a93          	addi	s5,s5,-220 # ffffffffc02aa5d0 <pages>
ffffffffc02026b4:	000ab703          	ld	a4,0(s5)
ffffffffc02026b8:	fff80937          	lui	s2,0xfff80
ffffffffc02026bc:	993e                	add	s2,s2,a5
ffffffffc02026be:	091a                	slli	s2,s2,0x6
ffffffffc02026c0:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02026c2:	01240c63          	beq	s0,s2,ffffffffc02026da <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02026c6:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd59fc>
ffffffffc02026ca:	fff7869b          	addiw	a3,a5,-1
ffffffffc02026ce:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02026d2:	c691                	beqz	a3,ffffffffc02026de <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026d4:	120a0073          	sfence.vma	s4
}
ffffffffc02026d8:	bf59                	j	ffffffffc020266e <page_insert+0x3a>
ffffffffc02026da:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02026dc:	bf49                	j	ffffffffc020266e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026de:	100027f3          	csrr	a5,sstatus
ffffffffc02026e2:	8b89                	andi	a5,a5,2
ffffffffc02026e4:	ef91                	bnez	a5,ffffffffc0202700 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02026e6:	000a8797          	auipc	a5,0xa8
ffffffffc02026ea:	ef27b783          	ld	a5,-270(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc02026ee:	739c                	ld	a5,32(a5)
ffffffffc02026f0:	4585                	li	a1,1
ffffffffc02026f2:	854a                	mv	a0,s2
ffffffffc02026f4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02026f6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026fa:	120a0073          	sfence.vma	s4
ffffffffc02026fe:	bf85                	j	ffffffffc020266e <page_insert+0x3a>
        intr_disable();
ffffffffc0202700:	ab4fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202704:	000a8797          	auipc	a5,0xa8
ffffffffc0202708:	ed47b783          	ld	a5,-300(a5) # ffffffffc02aa5d8 <pmm_manager>
ffffffffc020270c:	739c                	ld	a5,32(a5)
ffffffffc020270e:	4585                	li	a1,1
ffffffffc0202710:	854a                	mv	a0,s2
ffffffffc0202712:	9782                	jalr	a5
        intr_enable();
ffffffffc0202714:	a9afe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202718:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020271c:	120a0073          	sfence.vma	s4
ffffffffc0202720:	b7b9                	j	ffffffffc020266e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202722:	5571                	li	a0,-4
ffffffffc0202724:	b79d                	j	ffffffffc020268a <page_insert+0x56>
ffffffffc0202726:	f2eff0ef          	jal	ra,ffffffffc0201e54 <pa2page.part.0>

ffffffffc020272a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020272a:	00004797          	auipc	a5,0x4
ffffffffc020272e:	dbe78793          	addi	a5,a5,-578 # ffffffffc02064e8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202732:	638c                	ld	a1,0(a5)
{
ffffffffc0202734:	7159                	addi	sp,sp,-112
ffffffffc0202736:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202738:	00004517          	auipc	a0,0x4
ffffffffc020273c:	f5850513          	addi	a0,a0,-168 # ffffffffc0206690 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202740:	000a8b17          	auipc	s6,0xa8
ffffffffc0202744:	e98b0b13          	addi	s6,s6,-360 # ffffffffc02aa5d8 <pmm_manager>
{
ffffffffc0202748:	f486                	sd	ra,104(sp)
ffffffffc020274a:	e8ca                	sd	s2,80(sp)
ffffffffc020274c:	e4ce                	sd	s3,72(sp)
ffffffffc020274e:	f0a2                	sd	s0,96(sp)
ffffffffc0202750:	eca6                	sd	s1,88(sp)
ffffffffc0202752:	e0d2                	sd	s4,64(sp)
ffffffffc0202754:	fc56                	sd	s5,56(sp)
ffffffffc0202756:	f45e                	sd	s7,40(sp)
ffffffffc0202758:	f062                	sd	s8,32(sp)
ffffffffc020275a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020275c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202760:	a35fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202764:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202768:	000a8997          	auipc	s3,0xa8
ffffffffc020276c:	e7898993          	addi	s3,s3,-392 # ffffffffc02aa5e0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202770:	679c                	ld	a5,8(a5)
ffffffffc0202772:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202774:	57f5                	li	a5,-3
ffffffffc0202776:	07fa                	slli	a5,a5,0x1e
ffffffffc0202778:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020277c:	a1efe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202780:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202782:	a22fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202786:	200505e3          	beqz	a0,ffffffffc0203190 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020278a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020278c:	00004517          	auipc	a0,0x4
ffffffffc0202790:	f3c50513          	addi	a0,a0,-196 # ffffffffc02066c8 <default_pmm_manager+0x1e0>
ffffffffc0202794:	a01fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202798:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020279c:	fff40693          	addi	a3,s0,-1
ffffffffc02027a0:	864a                	mv	a2,s2
ffffffffc02027a2:	85a6                	mv	a1,s1
ffffffffc02027a4:	00004517          	auipc	a0,0x4
ffffffffc02027a8:	f3c50513          	addi	a0,a0,-196 # ffffffffc02066e0 <default_pmm_manager+0x1f8>
ffffffffc02027ac:	9e9fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02027b0:	c8000737          	lui	a4,0xc8000
ffffffffc02027b4:	87a2                	mv	a5,s0
ffffffffc02027b6:	54876163          	bltu	a4,s0,ffffffffc0202cf8 <pmm_init+0x5ce>
ffffffffc02027ba:	757d                	lui	a0,0xfffff
ffffffffc02027bc:	000a9617          	auipc	a2,0xa9
ffffffffc02027c0:	e4760613          	addi	a2,a2,-441 # ffffffffc02ab603 <end+0xfff>
ffffffffc02027c4:	8e69                	and	a2,a2,a0
ffffffffc02027c6:	000a8497          	auipc	s1,0xa8
ffffffffc02027ca:	e0248493          	addi	s1,s1,-510 # ffffffffc02aa5c8 <npage>
ffffffffc02027ce:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027d2:	000a8b97          	auipc	s7,0xa8
ffffffffc02027d6:	dfeb8b93          	addi	s7,s7,-514 # ffffffffc02aa5d0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02027da:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027dc:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027e0:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027e4:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027e6:	02f50863          	beq	a0,a5,ffffffffc0202816 <pmm_init+0xec>
ffffffffc02027ea:	4781                	li	a5,0
ffffffffc02027ec:	4585                	li	a1,1
ffffffffc02027ee:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02027f2:	00679513          	slli	a0,a5,0x6
ffffffffc02027f6:	9532                	add	a0,a0,a2
ffffffffc02027f8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd54a04>
ffffffffc02027fc:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202800:	6088                	ld	a0,0(s1)
ffffffffc0202802:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202804:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202808:	00d50733          	add	a4,a0,a3
ffffffffc020280c:	fee7e3e3          	bltu	a5,a4,ffffffffc02027f2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202810:	071a                	slli	a4,a4,0x6
ffffffffc0202812:	00e606b3          	add	a3,a2,a4
ffffffffc0202816:	c02007b7          	lui	a5,0xc0200
ffffffffc020281a:	2ef6ece3          	bltu	a3,a5,ffffffffc0203312 <pmm_init+0xbe8>
ffffffffc020281e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202822:	77fd                	lui	a5,0xfffff
ffffffffc0202824:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202826:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202828:	5086eb63          	bltu	a3,s0,ffffffffc0202d3e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020282c:	00004517          	auipc	a0,0x4
ffffffffc0202830:	edc50513          	addi	a0,a0,-292 # ffffffffc0206708 <default_pmm_manager+0x220>
ffffffffc0202834:	961fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202838:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020283c:	000a8917          	auipc	s2,0xa8
ffffffffc0202840:	d8490913          	addi	s2,s2,-636 # ffffffffc02aa5c0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202844:	7b9c                	ld	a5,48(a5)
ffffffffc0202846:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202848:	00004517          	auipc	a0,0x4
ffffffffc020284c:	ed850513          	addi	a0,a0,-296 # ffffffffc0206720 <default_pmm_manager+0x238>
ffffffffc0202850:	945fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202854:	00007697          	auipc	a3,0x7
ffffffffc0202858:	7ac68693          	addi	a3,a3,1964 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc020285c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202860:	c02007b7          	lui	a5,0xc0200
ffffffffc0202864:	28f6ebe3          	bltu	a3,a5,ffffffffc02032fa <pmm_init+0xbd0>
ffffffffc0202868:	0009b783          	ld	a5,0(s3)
ffffffffc020286c:	8e9d                	sub	a3,a3,a5
ffffffffc020286e:	000a8797          	auipc	a5,0xa8
ffffffffc0202872:	d4d7b523          	sd	a3,-694(a5) # ffffffffc02aa5b8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202876:	100027f3          	csrr	a5,sstatus
ffffffffc020287a:	8b89                	andi	a5,a5,2
ffffffffc020287c:	4a079763          	bnez	a5,ffffffffc0202d2a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202880:	000b3783          	ld	a5,0(s6)
ffffffffc0202884:	779c                	ld	a5,40(a5)
ffffffffc0202886:	9782                	jalr	a5
ffffffffc0202888:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020288a:	6098                	ld	a4,0(s1)
ffffffffc020288c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202890:	83b1                	srli	a5,a5,0xc
ffffffffc0202892:	66e7e363          	bltu	a5,a4,ffffffffc0202ef8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202896:	00093503          	ld	a0,0(s2)
ffffffffc020289a:	62050f63          	beqz	a0,ffffffffc0202ed8 <pmm_init+0x7ae>
ffffffffc020289e:	03451793          	slli	a5,a0,0x34
ffffffffc02028a2:	62079b63          	bnez	a5,ffffffffc0202ed8 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028a6:	4601                	li	a2,0
ffffffffc02028a8:	4581                	li	a1,0
ffffffffc02028aa:	8c3ff0ef          	jal	ra,ffffffffc020216c <get_page>
ffffffffc02028ae:	60051563          	bnez	a0,ffffffffc0202eb8 <pmm_init+0x78e>
ffffffffc02028b2:	100027f3          	csrr	a5,sstatus
ffffffffc02028b6:	8b89                	andi	a5,a5,2
ffffffffc02028b8:	44079e63          	bnez	a5,ffffffffc0202d14 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028bc:	000b3783          	ld	a5,0(s6)
ffffffffc02028c0:	4505                	li	a0,1
ffffffffc02028c2:	6f9c                	ld	a5,24(a5)
ffffffffc02028c4:	9782                	jalr	a5
ffffffffc02028c6:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02028c8:	00093503          	ld	a0,0(s2)
ffffffffc02028cc:	4681                	li	a3,0
ffffffffc02028ce:	4601                	li	a2,0
ffffffffc02028d0:	85d2                	mv	a1,s4
ffffffffc02028d2:	d63ff0ef          	jal	ra,ffffffffc0202634 <page_insert>
ffffffffc02028d6:	26051ae3          	bnez	a0,ffffffffc020334a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028da:	00093503          	ld	a0,0(s2)
ffffffffc02028de:	4601                	li	a2,0
ffffffffc02028e0:	4581                	li	a1,0
ffffffffc02028e2:	e62ff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
ffffffffc02028e6:	240502e3          	beqz	a0,ffffffffc020332a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02028ea:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028ec:	0017f713          	andi	a4,a5,1
ffffffffc02028f0:	5a070263          	beqz	a4,ffffffffc0202e94 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02028f4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028f6:	078a                	slli	a5,a5,0x2
ffffffffc02028f8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02028fa:	58e7fb63          	bgeu	a5,a4,ffffffffc0202e90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02028fe:	000bb683          	ld	a3,0(s7)
ffffffffc0202902:	fff80637          	lui	a2,0xfff80
ffffffffc0202906:	97b2                	add	a5,a5,a2
ffffffffc0202908:	079a                	slli	a5,a5,0x6
ffffffffc020290a:	97b6                	add	a5,a5,a3
ffffffffc020290c:	14fa17e3          	bne	s4,a5,ffffffffc020325a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202910:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8b98>
ffffffffc0202914:	4785                	li	a5,1
ffffffffc0202916:	12f692e3          	bne	a3,a5,ffffffffc020323a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020291a:	00093503          	ld	a0,0(s2)
ffffffffc020291e:	77fd                	lui	a5,0xfffff
ffffffffc0202920:	6114                	ld	a3,0(a0)
ffffffffc0202922:	068a                	slli	a3,a3,0x2
ffffffffc0202924:	8efd                	and	a3,a3,a5
ffffffffc0202926:	00c6d613          	srli	a2,a3,0xc
ffffffffc020292a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203222 <pmm_init+0xaf8>
ffffffffc020292e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202932:	96e2                	add	a3,a3,s8
ffffffffc0202934:	0006ba83          	ld	s5,0(a3)
ffffffffc0202938:	0a8a                	slli	s5,s5,0x2
ffffffffc020293a:	00fafab3          	and	s5,s5,a5
ffffffffc020293e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202942:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203208 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202946:	4601                	li	a2,0
ffffffffc0202948:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020294a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020294c:	df8ff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202950:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202952:	55551363          	bne	a0,s5,ffffffffc0202e98 <pmm_init+0x76e>
ffffffffc0202956:	100027f3          	csrr	a5,sstatus
ffffffffc020295a:	8b89                	andi	a5,a5,2
ffffffffc020295c:	3a079163          	bnez	a5,ffffffffc0202cfe <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202960:	000b3783          	ld	a5,0(s6)
ffffffffc0202964:	4505                	li	a0,1
ffffffffc0202966:	6f9c                	ld	a5,24(a5)
ffffffffc0202968:	9782                	jalr	a5
ffffffffc020296a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020296c:	00093503          	ld	a0,0(s2)
ffffffffc0202970:	46d1                	li	a3,20
ffffffffc0202972:	6605                	lui	a2,0x1
ffffffffc0202974:	85e2                	mv	a1,s8
ffffffffc0202976:	cbfff0ef          	jal	ra,ffffffffc0202634 <page_insert>
ffffffffc020297a:	060517e3          	bnez	a0,ffffffffc02031e8 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020297e:	00093503          	ld	a0,0(s2)
ffffffffc0202982:	4601                	li	a2,0
ffffffffc0202984:	6585                	lui	a1,0x1
ffffffffc0202986:	dbeff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
ffffffffc020298a:	02050fe3          	beqz	a0,ffffffffc02031c8 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020298e:	611c                	ld	a5,0(a0)
ffffffffc0202990:	0107f713          	andi	a4,a5,16
ffffffffc0202994:	7c070e63          	beqz	a4,ffffffffc0203170 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202998:	8b91                	andi	a5,a5,4
ffffffffc020299a:	7a078b63          	beqz	a5,ffffffffc0203150 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020299e:	00093503          	ld	a0,0(s2)
ffffffffc02029a2:	611c                	ld	a5,0(a0)
ffffffffc02029a4:	8bc1                	andi	a5,a5,16
ffffffffc02029a6:	78078563          	beqz	a5,ffffffffc0203130 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02029aa:	000c2703          	lw	a4,0(s8)
ffffffffc02029ae:	4785                	li	a5,1
ffffffffc02029b0:	76f71063          	bne	a4,a5,ffffffffc0203110 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029b4:	4681                	li	a3,0
ffffffffc02029b6:	6605                	lui	a2,0x1
ffffffffc02029b8:	85d2                	mv	a1,s4
ffffffffc02029ba:	c7bff0ef          	jal	ra,ffffffffc0202634 <page_insert>
ffffffffc02029be:	72051963          	bnez	a0,ffffffffc02030f0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02029c2:	000a2703          	lw	a4,0(s4)
ffffffffc02029c6:	4789                	li	a5,2
ffffffffc02029c8:	70f71463          	bne	a4,a5,ffffffffc02030d0 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02029cc:	000c2783          	lw	a5,0(s8)
ffffffffc02029d0:	6e079063          	bnez	a5,ffffffffc02030b0 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029d4:	00093503          	ld	a0,0(s2)
ffffffffc02029d8:	4601                	li	a2,0
ffffffffc02029da:	6585                	lui	a1,0x1
ffffffffc02029dc:	d68ff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
ffffffffc02029e0:	6a050863          	beqz	a0,ffffffffc0203090 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02029e4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029e6:	00177793          	andi	a5,a4,1
ffffffffc02029ea:	4a078563          	beqz	a5,ffffffffc0202e94 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029ee:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029f0:	00271793          	slli	a5,a4,0x2
ffffffffc02029f4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029f6:	48d7fd63          	bgeu	a5,a3,ffffffffc0202e90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02029fa:	000bb683          	ld	a3,0(s7)
ffffffffc02029fe:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a02:	97d6                	add	a5,a5,s5
ffffffffc0202a04:	079a                	slli	a5,a5,0x6
ffffffffc0202a06:	97b6                	add	a5,a5,a3
ffffffffc0202a08:	66fa1463          	bne	s4,a5,ffffffffc0203070 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a0c:	8b41                	andi	a4,a4,16
ffffffffc0202a0e:	64071163          	bnez	a4,ffffffffc0203050 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a12:	00093503          	ld	a0,0(s2)
ffffffffc0202a16:	4581                	li	a1,0
ffffffffc0202a18:	b81ff0ef          	jal	ra,ffffffffc0202598 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a1c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a20:	4785                	li	a5,1
ffffffffc0202a22:	60fc9763          	bne	s9,a5,ffffffffc0203030 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a26:	000c2783          	lw	a5,0(s8)
ffffffffc0202a2a:	5e079363          	bnez	a5,ffffffffc0203010 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a2e:	00093503          	ld	a0,0(s2)
ffffffffc0202a32:	6585                	lui	a1,0x1
ffffffffc0202a34:	b65ff0ef          	jal	ra,ffffffffc0202598 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a38:	000a2783          	lw	a5,0(s4)
ffffffffc0202a3c:	52079a63          	bnez	a5,ffffffffc0202f70 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a40:	000c2783          	lw	a5,0(s8)
ffffffffc0202a44:	50079663          	bnez	a5,ffffffffc0202f50 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a48:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a4c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a4e:	000a3683          	ld	a3,0(s4)
ffffffffc0202a52:	068a                	slli	a3,a3,0x2
ffffffffc0202a54:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a56:	42b6fd63          	bgeu	a3,a1,ffffffffc0202e90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a5a:	000bb503          	ld	a0,0(s7)
ffffffffc0202a5e:	96d6                	add	a3,a3,s5
ffffffffc0202a60:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202a62:	00d507b3          	add	a5,a0,a3
ffffffffc0202a66:	439c                	lw	a5,0(a5)
ffffffffc0202a68:	4d979463          	bne	a5,s9,ffffffffc0202f30 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202a6c:	8699                	srai	a3,a3,0x6
ffffffffc0202a6e:	00080637          	lui	a2,0x80
ffffffffc0202a72:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202a74:	00c69713          	slli	a4,a3,0xc
ffffffffc0202a78:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a7a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a7c:	48b77e63          	bgeu	a4,a1,ffffffffc0202f18 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a80:	0009b703          	ld	a4,0(s3)
ffffffffc0202a84:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a86:	629c                	ld	a5,0(a3)
ffffffffc0202a88:	078a                	slli	a5,a5,0x2
ffffffffc0202a8a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a8c:	40b7f263          	bgeu	a5,a1,ffffffffc0202e90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a90:	8f91                	sub	a5,a5,a2
ffffffffc0202a92:	079a                	slli	a5,a5,0x6
ffffffffc0202a94:	953e                	add	a0,a0,a5
ffffffffc0202a96:	100027f3          	csrr	a5,sstatus
ffffffffc0202a9a:	8b89                	andi	a5,a5,2
ffffffffc0202a9c:	30079963          	bnez	a5,ffffffffc0202dae <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202aa0:	000b3783          	ld	a5,0(s6)
ffffffffc0202aa4:	4585                	li	a1,1
ffffffffc0202aa6:	739c                	ld	a5,32(a5)
ffffffffc0202aa8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aaa:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202aae:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ab0:	078a                	slli	a5,a5,0x2
ffffffffc0202ab2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ab4:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202e90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ab8:	000bb503          	ld	a0,0(s7)
ffffffffc0202abc:	fff80737          	lui	a4,0xfff80
ffffffffc0202ac0:	97ba                	add	a5,a5,a4
ffffffffc0202ac2:	079a                	slli	a5,a5,0x6
ffffffffc0202ac4:	953e                	add	a0,a0,a5
ffffffffc0202ac6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aca:	8b89                	andi	a5,a5,2
ffffffffc0202acc:	2c079563          	bnez	a5,ffffffffc0202d96 <pmm_init+0x66c>
ffffffffc0202ad0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ad4:	4585                	li	a1,1
ffffffffc0202ad6:	739c                	ld	a5,32(a5)
ffffffffc0202ad8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ada:	00093783          	ld	a5,0(s2)
ffffffffc0202ade:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd549fc>
    asm volatile("sfence.vma");
ffffffffc0202ae2:	12000073          	sfence.vma
ffffffffc0202ae6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aea:	8b89                	andi	a5,a5,2
ffffffffc0202aec:	28079b63          	bnez	a5,ffffffffc0202d82 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202af0:	000b3783          	ld	a5,0(s6)
ffffffffc0202af4:	779c                	ld	a5,40(a5)
ffffffffc0202af6:	9782                	jalr	a5
ffffffffc0202af8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202afa:	4b441b63          	bne	s0,s4,ffffffffc0202fb0 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202afe:	00004517          	auipc	a0,0x4
ffffffffc0202b02:	f4a50513          	addi	a0,a0,-182 # ffffffffc0206a48 <default_pmm_manager+0x560>
ffffffffc0202b06:	e8efd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202b0a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b0e:	8b89                	andi	a5,a5,2
ffffffffc0202b10:	24079f63          	bnez	a5,ffffffffc0202d6e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b14:	000b3783          	ld	a5,0(s6)
ffffffffc0202b18:	779c                	ld	a5,40(a5)
ffffffffc0202b1a:	9782                	jalr	a5
ffffffffc0202b1c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b1e:	6098                	ld	a4,0(s1)
ffffffffc0202b20:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b24:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b26:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b2a:	6a05                	lui	s4,0x1
ffffffffc0202b2c:	02f47c63          	bgeu	s0,a5,ffffffffc0202b64 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b30:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b34:	00093503          	ld	a0,0(s2)
ffffffffc0202b38:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e36 <pmm_init+0x70c>
ffffffffc0202b3c:	0009b583          	ld	a1,0(s3)
ffffffffc0202b40:	4601                	li	a2,0
ffffffffc0202b42:	95a2                	add	a1,a1,s0
ffffffffc0202b44:	c00ff0ef          	jal	ra,ffffffffc0201f44 <get_pte>
ffffffffc0202b48:	32050463          	beqz	a0,ffffffffc0202e70 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b4c:	611c                	ld	a5,0(a0)
ffffffffc0202b4e:	078a                	slli	a5,a5,0x2
ffffffffc0202b50:	0157f7b3          	and	a5,a5,s5
ffffffffc0202b54:	2e879e63          	bne	a5,s0,ffffffffc0202e50 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b58:	6098                	ld	a4,0(s1)
ffffffffc0202b5a:	9452                	add	s0,s0,s4
ffffffffc0202b5c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b60:	fcf468e3          	bltu	s0,a5,ffffffffc0202b30 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b64:	00093783          	ld	a5,0(s2)
ffffffffc0202b68:	639c                	ld	a5,0(a5)
ffffffffc0202b6a:	42079363          	bnez	a5,ffffffffc0202f90 <pmm_init+0x866>
ffffffffc0202b6e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b72:	8b89                	andi	a5,a5,2
ffffffffc0202b74:	24079963          	bnez	a5,ffffffffc0202dc6 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b78:	000b3783          	ld	a5,0(s6)
ffffffffc0202b7c:	4505                	li	a0,1
ffffffffc0202b7e:	6f9c                	ld	a5,24(a5)
ffffffffc0202b80:	9782                	jalr	a5
ffffffffc0202b82:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b84:	00093503          	ld	a0,0(s2)
ffffffffc0202b88:	4699                	li	a3,6
ffffffffc0202b8a:	10000613          	li	a2,256
ffffffffc0202b8e:	85d2                	mv	a1,s4
ffffffffc0202b90:	aa5ff0ef          	jal	ra,ffffffffc0202634 <page_insert>
ffffffffc0202b94:	44051e63          	bnez	a0,ffffffffc0202ff0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202b98:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8b98>
ffffffffc0202b9c:	4785                	li	a5,1
ffffffffc0202b9e:	42f71963          	bne	a4,a5,ffffffffc0202fd0 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202ba2:	00093503          	ld	a0,0(s2)
ffffffffc0202ba6:	6405                	lui	s0,0x1
ffffffffc0202ba8:	4699                	li	a3,6
ffffffffc0202baa:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8a98>
ffffffffc0202bae:	85d2                	mv	a1,s4
ffffffffc0202bb0:	a85ff0ef          	jal	ra,ffffffffc0202634 <page_insert>
ffffffffc0202bb4:	72051363          	bnez	a0,ffffffffc02032da <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202bb8:	000a2703          	lw	a4,0(s4)
ffffffffc0202bbc:	4789                	li	a5,2
ffffffffc0202bbe:	6ef71e63          	bne	a4,a5,ffffffffc02032ba <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bc2:	00004597          	auipc	a1,0x4
ffffffffc0202bc6:	fce58593          	addi	a1,a1,-50 # ffffffffc0206b90 <default_pmm_manager+0x6a8>
ffffffffc0202bca:	10000513          	li	a0,256
ffffffffc0202bce:	23f020ef          	jal	ra,ffffffffc020560c <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202bd2:	10040593          	addi	a1,s0,256
ffffffffc0202bd6:	10000513          	li	a0,256
ffffffffc0202bda:	245020ef          	jal	ra,ffffffffc020561e <strcmp>
ffffffffc0202bde:	6a051e63          	bnez	a0,ffffffffc020329a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202be2:	000bb683          	ld	a3,0(s7)
ffffffffc0202be6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202bea:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202bec:	40da06b3          	sub	a3,s4,a3
ffffffffc0202bf0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202bf2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202bf4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202bf6:	8031                	srli	s0,s0,0xc
ffffffffc0202bf8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bfc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bfe:	30f77d63          	bgeu	a4,a5,ffffffffc0202f18 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c02:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c06:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c0a:	96be                	add	a3,a3,a5
ffffffffc0202c0c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c10:	1c7020ef          	jal	ra,ffffffffc02055d6 <strlen>
ffffffffc0202c14:	66051363          	bnez	a0,ffffffffc020327a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c18:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c1c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c1e:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd549fc>
ffffffffc0202c22:	068a                	slli	a3,a3,0x2
ffffffffc0202c24:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c26:	26f6f563          	bgeu	a3,a5,ffffffffc0202e90 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202c2a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c2c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c2e:	2ef47563          	bgeu	s0,a5,ffffffffc0202f18 <pmm_init+0x7ee>
ffffffffc0202c32:	0009b403          	ld	s0,0(s3)
ffffffffc0202c36:	9436                	add	s0,s0,a3
ffffffffc0202c38:	100027f3          	csrr	a5,sstatus
ffffffffc0202c3c:	8b89                	andi	a5,a5,2
ffffffffc0202c3e:	1e079163          	bnez	a5,ffffffffc0202e20 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c42:	000b3783          	ld	a5,0(s6)
ffffffffc0202c46:	4585                	li	a1,1
ffffffffc0202c48:	8552                	mv	a0,s4
ffffffffc0202c4a:	739c                	ld	a5,32(a5)
ffffffffc0202c4c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c4e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202c50:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c52:	078a                	slli	a5,a5,0x2
ffffffffc0202c54:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c56:	22e7fd63          	bgeu	a5,a4,ffffffffc0202e90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c5a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c5e:	fff80737          	lui	a4,0xfff80
ffffffffc0202c62:	97ba                	add	a5,a5,a4
ffffffffc0202c64:	079a                	slli	a5,a5,0x6
ffffffffc0202c66:	953e                	add	a0,a0,a5
ffffffffc0202c68:	100027f3          	csrr	a5,sstatus
ffffffffc0202c6c:	8b89                	andi	a5,a5,2
ffffffffc0202c6e:	18079d63          	bnez	a5,ffffffffc0202e08 <pmm_init+0x6de>
ffffffffc0202c72:	000b3783          	ld	a5,0(s6)
ffffffffc0202c76:	4585                	li	a1,1
ffffffffc0202c78:	739c                	ld	a5,32(a5)
ffffffffc0202c7a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c7c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c80:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c82:	078a                	slli	a5,a5,0x2
ffffffffc0202c84:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c86:	20e7f563          	bgeu	a5,a4,ffffffffc0202e90 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c8a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c8e:	fff80737          	lui	a4,0xfff80
ffffffffc0202c92:	97ba                	add	a5,a5,a4
ffffffffc0202c94:	079a                	slli	a5,a5,0x6
ffffffffc0202c96:	953e                	add	a0,a0,a5
ffffffffc0202c98:	100027f3          	csrr	a5,sstatus
ffffffffc0202c9c:	8b89                	andi	a5,a5,2
ffffffffc0202c9e:	14079963          	bnez	a5,ffffffffc0202df0 <pmm_init+0x6c6>
ffffffffc0202ca2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ca6:	4585                	li	a1,1
ffffffffc0202ca8:	739c                	ld	a5,32(a5)
ffffffffc0202caa:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cac:	00093783          	ld	a5,0(s2)
ffffffffc0202cb0:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202cb4:	12000073          	sfence.vma
ffffffffc0202cb8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cbc:	8b89                	andi	a5,a5,2
ffffffffc0202cbe:	10079f63          	bnez	a5,ffffffffc0202ddc <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc6:	779c                	ld	a5,40(a5)
ffffffffc0202cc8:	9782                	jalr	a5
ffffffffc0202cca:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202ccc:	4c8c1e63          	bne	s8,s0,ffffffffc02031a8 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202cd0:	00004517          	auipc	a0,0x4
ffffffffc0202cd4:	f3850513          	addi	a0,a0,-200 # ffffffffc0206c08 <default_pmm_manager+0x720>
ffffffffc0202cd8:	cbcfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202cdc:	7406                	ld	s0,96(sp)
ffffffffc0202cde:	70a6                	ld	ra,104(sp)
ffffffffc0202ce0:	64e6                	ld	s1,88(sp)
ffffffffc0202ce2:	6946                	ld	s2,80(sp)
ffffffffc0202ce4:	69a6                	ld	s3,72(sp)
ffffffffc0202ce6:	6a06                	ld	s4,64(sp)
ffffffffc0202ce8:	7ae2                	ld	s5,56(sp)
ffffffffc0202cea:	7b42                	ld	s6,48(sp)
ffffffffc0202cec:	7ba2                	ld	s7,40(sp)
ffffffffc0202cee:	7c02                	ld	s8,32(sp)
ffffffffc0202cf0:	6ce2                	ld	s9,24(sp)
ffffffffc0202cf2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202cf4:	f97fe06f          	j	ffffffffc0201c8a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202cf8:	c80007b7          	lui	a5,0xc8000
ffffffffc0202cfc:	bc7d                	j	ffffffffc02027ba <pmm_init+0x90>
        intr_disable();
ffffffffc0202cfe:	cb7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d02:	000b3783          	ld	a5,0(s6)
ffffffffc0202d06:	4505                	li	a0,1
ffffffffc0202d08:	6f9c                	ld	a5,24(a5)
ffffffffc0202d0a:	9782                	jalr	a5
ffffffffc0202d0c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d0e:	ca1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d12:	b9a9                	j	ffffffffc020296c <pmm_init+0x242>
        intr_disable();
ffffffffc0202d14:	ca1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d18:	000b3783          	ld	a5,0(s6)
ffffffffc0202d1c:	4505                	li	a0,1
ffffffffc0202d1e:	6f9c                	ld	a5,24(a5)
ffffffffc0202d20:	9782                	jalr	a5
ffffffffc0202d22:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d24:	c8bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d28:	b645                	j	ffffffffc02028c8 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202d2a:	c8bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d2e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d32:	779c                	ld	a5,40(a5)
ffffffffc0202d34:	9782                	jalr	a5
ffffffffc0202d36:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d38:	c77fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d3c:	b6b9                	j	ffffffffc020288a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d3e:	6705                	lui	a4,0x1
ffffffffc0202d40:	177d                	addi	a4,a4,-1
ffffffffc0202d42:	96ba                	add	a3,a3,a4
ffffffffc0202d44:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d46:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d4a:	14a77363          	bgeu	a4,a0,ffffffffc0202e90 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d4e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202d52:	fff80537          	lui	a0,0xfff80
ffffffffc0202d56:	972a                	add	a4,a4,a0
ffffffffc0202d58:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d5a:	8c1d                	sub	s0,s0,a5
ffffffffc0202d5c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202d60:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d64:	9532                	add	a0,a0,a2
ffffffffc0202d66:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d68:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d6c:	b4c1                	j	ffffffffc020282c <pmm_init+0x102>
        intr_disable();
ffffffffc0202d6e:	c47fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d72:	000b3783          	ld	a5,0(s6)
ffffffffc0202d76:	779c                	ld	a5,40(a5)
ffffffffc0202d78:	9782                	jalr	a5
ffffffffc0202d7a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d7c:	c33fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d80:	bb79                	j	ffffffffc0202b1e <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202d82:	c33fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d86:	000b3783          	ld	a5,0(s6)
ffffffffc0202d8a:	779c                	ld	a5,40(a5)
ffffffffc0202d8c:	9782                	jalr	a5
ffffffffc0202d8e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d90:	c1ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d94:	b39d                	j	ffffffffc0202afa <pmm_init+0x3d0>
ffffffffc0202d96:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202d98:	c1dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202d9c:	000b3783          	ld	a5,0(s6)
ffffffffc0202da0:	6522                	ld	a0,8(sp)
ffffffffc0202da2:	4585                	li	a1,1
ffffffffc0202da4:	739c                	ld	a5,32(a5)
ffffffffc0202da6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202da8:	c07fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dac:	b33d                	j	ffffffffc0202ada <pmm_init+0x3b0>
ffffffffc0202dae:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202db0:	c05fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202db4:	000b3783          	ld	a5,0(s6)
ffffffffc0202db8:	6522                	ld	a0,8(sp)
ffffffffc0202dba:	4585                	li	a1,1
ffffffffc0202dbc:	739c                	ld	a5,32(a5)
ffffffffc0202dbe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dc0:	beffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dc4:	b1dd                	j	ffffffffc0202aaa <pmm_init+0x380>
        intr_disable();
ffffffffc0202dc6:	beffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dca:	000b3783          	ld	a5,0(s6)
ffffffffc0202dce:	4505                	li	a0,1
ffffffffc0202dd0:	6f9c                	ld	a5,24(a5)
ffffffffc0202dd2:	9782                	jalr	a5
ffffffffc0202dd4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dd6:	bd9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dda:	b36d                	j	ffffffffc0202b84 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202ddc:	bd9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202de0:	000b3783          	ld	a5,0(s6)
ffffffffc0202de4:	779c                	ld	a5,40(a5)
ffffffffc0202de6:	9782                	jalr	a5
ffffffffc0202de8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dea:	bc5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dee:	bdf9                	j	ffffffffc0202ccc <pmm_init+0x5a2>
ffffffffc0202df0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202df2:	bc3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202df6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dfa:	6522                	ld	a0,8(sp)
ffffffffc0202dfc:	4585                	li	a1,1
ffffffffc0202dfe:	739c                	ld	a5,32(a5)
ffffffffc0202e00:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e02:	badfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e06:	b55d                	j	ffffffffc0202cac <pmm_init+0x582>
ffffffffc0202e08:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e0a:	babfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e0e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e12:	6522                	ld	a0,8(sp)
ffffffffc0202e14:	4585                	li	a1,1
ffffffffc0202e16:	739c                	ld	a5,32(a5)
ffffffffc0202e18:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e1a:	b95fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e1e:	bdb9                	j	ffffffffc0202c7c <pmm_init+0x552>
        intr_disable();
ffffffffc0202e20:	b95fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e24:	000b3783          	ld	a5,0(s6)
ffffffffc0202e28:	4585                	li	a1,1
ffffffffc0202e2a:	8552                	mv	a0,s4
ffffffffc0202e2c:	739c                	ld	a5,32(a5)
ffffffffc0202e2e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e30:	b7ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e34:	bd29                	j	ffffffffc0202c4e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e36:	86a2                	mv	a3,s0
ffffffffc0202e38:	00003617          	auipc	a2,0x3
ffffffffc0202e3c:	6e860613          	addi	a2,a2,1768 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0202e40:	24f00593          	li	a1,591
ffffffffc0202e44:	00003517          	auipc	a0,0x3
ffffffffc0202e48:	7f450513          	addi	a0,a0,2036 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202e4c:	e42fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e50:	00004697          	auipc	a3,0x4
ffffffffc0202e54:	c5868693          	addi	a3,a3,-936 # ffffffffc0206aa8 <default_pmm_manager+0x5c0>
ffffffffc0202e58:	00003617          	auipc	a2,0x3
ffffffffc0202e5c:	2e060613          	addi	a2,a2,736 # ffffffffc0206138 <commands+0x828>
ffffffffc0202e60:	25000593          	li	a1,592
ffffffffc0202e64:	00003517          	auipc	a0,0x3
ffffffffc0202e68:	7d450513          	addi	a0,a0,2004 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202e6c:	e22fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e70:	00004697          	auipc	a3,0x4
ffffffffc0202e74:	bf868693          	addi	a3,a3,-1032 # ffffffffc0206a68 <default_pmm_manager+0x580>
ffffffffc0202e78:	00003617          	auipc	a2,0x3
ffffffffc0202e7c:	2c060613          	addi	a2,a2,704 # ffffffffc0206138 <commands+0x828>
ffffffffc0202e80:	24f00593          	li	a1,591
ffffffffc0202e84:	00003517          	auipc	a0,0x3
ffffffffc0202e88:	7b450513          	addi	a0,a0,1972 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202e8c:	e02fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202e90:	fc5fe0ef          	jal	ra,ffffffffc0201e54 <pa2page.part.0>
ffffffffc0202e94:	fddfe0ef          	jal	ra,ffffffffc0201e70 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202e98:	00004697          	auipc	a3,0x4
ffffffffc0202e9c:	9c868693          	addi	a3,a3,-1592 # ffffffffc0206860 <default_pmm_manager+0x378>
ffffffffc0202ea0:	00003617          	auipc	a2,0x3
ffffffffc0202ea4:	29860613          	addi	a2,a2,664 # ffffffffc0206138 <commands+0x828>
ffffffffc0202ea8:	21f00593          	li	a1,543
ffffffffc0202eac:	00003517          	auipc	a0,0x3
ffffffffc0202eb0:	78c50513          	addi	a0,a0,1932 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202eb4:	ddafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202eb8:	00004697          	auipc	a3,0x4
ffffffffc0202ebc:	8e868693          	addi	a3,a3,-1816 # ffffffffc02067a0 <default_pmm_manager+0x2b8>
ffffffffc0202ec0:	00003617          	auipc	a2,0x3
ffffffffc0202ec4:	27860613          	addi	a2,a2,632 # ffffffffc0206138 <commands+0x828>
ffffffffc0202ec8:	21200593          	li	a1,530
ffffffffc0202ecc:	00003517          	auipc	a0,0x3
ffffffffc0202ed0:	76c50513          	addi	a0,a0,1900 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202ed4:	dbafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202ed8:	00004697          	auipc	a3,0x4
ffffffffc0202edc:	88868693          	addi	a3,a3,-1912 # ffffffffc0206760 <default_pmm_manager+0x278>
ffffffffc0202ee0:	00003617          	auipc	a2,0x3
ffffffffc0202ee4:	25860613          	addi	a2,a2,600 # ffffffffc0206138 <commands+0x828>
ffffffffc0202ee8:	21100593          	li	a1,529
ffffffffc0202eec:	00003517          	auipc	a0,0x3
ffffffffc0202ef0:	74c50513          	addi	a0,a0,1868 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202ef4:	d9afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ef8:	00004697          	auipc	a3,0x4
ffffffffc0202efc:	84868693          	addi	a3,a3,-1976 # ffffffffc0206740 <default_pmm_manager+0x258>
ffffffffc0202f00:	00003617          	auipc	a2,0x3
ffffffffc0202f04:	23860613          	addi	a2,a2,568 # ffffffffc0206138 <commands+0x828>
ffffffffc0202f08:	21000593          	li	a1,528
ffffffffc0202f0c:	00003517          	auipc	a0,0x3
ffffffffc0202f10:	72c50513          	addi	a0,a0,1836 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202f14:	d7afd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f18:	00003617          	auipc	a2,0x3
ffffffffc0202f1c:	60860613          	addi	a2,a2,1544 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0202f20:	07100593          	li	a1,113
ffffffffc0202f24:	00003517          	auipc	a0,0x3
ffffffffc0202f28:	62450513          	addi	a0,a0,1572 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0202f2c:	d62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f30:	00004697          	auipc	a3,0x4
ffffffffc0202f34:	ac068693          	addi	a3,a3,-1344 # ffffffffc02069f0 <default_pmm_manager+0x508>
ffffffffc0202f38:	00003617          	auipc	a2,0x3
ffffffffc0202f3c:	20060613          	addi	a2,a2,512 # ffffffffc0206138 <commands+0x828>
ffffffffc0202f40:	23800593          	li	a1,568
ffffffffc0202f44:	00003517          	auipc	a0,0x3
ffffffffc0202f48:	6f450513          	addi	a0,a0,1780 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202f4c:	d42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f50:	00004697          	auipc	a3,0x4
ffffffffc0202f54:	a5868693          	addi	a3,a3,-1448 # ffffffffc02069a8 <default_pmm_manager+0x4c0>
ffffffffc0202f58:	00003617          	auipc	a2,0x3
ffffffffc0202f5c:	1e060613          	addi	a2,a2,480 # ffffffffc0206138 <commands+0x828>
ffffffffc0202f60:	23600593          	li	a1,566
ffffffffc0202f64:	00003517          	auipc	a0,0x3
ffffffffc0202f68:	6d450513          	addi	a0,a0,1748 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202f6c:	d22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f70:	00004697          	auipc	a3,0x4
ffffffffc0202f74:	a6868693          	addi	a3,a3,-1432 # ffffffffc02069d8 <default_pmm_manager+0x4f0>
ffffffffc0202f78:	00003617          	auipc	a2,0x3
ffffffffc0202f7c:	1c060613          	addi	a2,a2,448 # ffffffffc0206138 <commands+0x828>
ffffffffc0202f80:	23500593          	li	a1,565
ffffffffc0202f84:	00003517          	auipc	a0,0x3
ffffffffc0202f88:	6b450513          	addi	a0,a0,1716 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202f8c:	d02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f90:	00004697          	auipc	a3,0x4
ffffffffc0202f94:	b3068693          	addi	a3,a3,-1232 # ffffffffc0206ac0 <default_pmm_manager+0x5d8>
ffffffffc0202f98:	00003617          	auipc	a2,0x3
ffffffffc0202f9c:	1a060613          	addi	a2,a2,416 # ffffffffc0206138 <commands+0x828>
ffffffffc0202fa0:	25300593          	li	a1,595
ffffffffc0202fa4:	00003517          	auipc	a0,0x3
ffffffffc0202fa8:	69450513          	addi	a0,a0,1684 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202fac:	ce2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fb0:	00004697          	auipc	a3,0x4
ffffffffc0202fb4:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206a20 <default_pmm_manager+0x538>
ffffffffc0202fb8:	00003617          	auipc	a2,0x3
ffffffffc0202fbc:	18060613          	addi	a2,a2,384 # ffffffffc0206138 <commands+0x828>
ffffffffc0202fc0:	24000593          	li	a1,576
ffffffffc0202fc4:	00003517          	auipc	a0,0x3
ffffffffc0202fc8:	67450513          	addi	a0,a0,1652 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202fcc:	cc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fd0:	00004697          	auipc	a3,0x4
ffffffffc0202fd4:	b4868693          	addi	a3,a3,-1208 # ffffffffc0206b18 <default_pmm_manager+0x630>
ffffffffc0202fd8:	00003617          	auipc	a2,0x3
ffffffffc0202fdc:	16060613          	addi	a2,a2,352 # ffffffffc0206138 <commands+0x828>
ffffffffc0202fe0:	25800593          	li	a1,600
ffffffffc0202fe4:	00003517          	auipc	a0,0x3
ffffffffc0202fe8:	65450513          	addi	a0,a0,1620 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0202fec:	ca2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202ff0:	00004697          	auipc	a3,0x4
ffffffffc0202ff4:	ae868693          	addi	a3,a3,-1304 # ffffffffc0206ad8 <default_pmm_manager+0x5f0>
ffffffffc0202ff8:	00003617          	auipc	a2,0x3
ffffffffc0202ffc:	14060613          	addi	a2,a2,320 # ffffffffc0206138 <commands+0x828>
ffffffffc0203000:	25700593          	li	a1,599
ffffffffc0203004:	00003517          	auipc	a0,0x3
ffffffffc0203008:	63450513          	addi	a0,a0,1588 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020300c:	c82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203010:	00004697          	auipc	a3,0x4
ffffffffc0203014:	99868693          	addi	a3,a3,-1640 # ffffffffc02069a8 <default_pmm_manager+0x4c0>
ffffffffc0203018:	00003617          	auipc	a2,0x3
ffffffffc020301c:	12060613          	addi	a2,a2,288 # ffffffffc0206138 <commands+0x828>
ffffffffc0203020:	23200593          	li	a1,562
ffffffffc0203024:	00003517          	auipc	a0,0x3
ffffffffc0203028:	61450513          	addi	a0,a0,1556 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020302c:	c62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203030:	00004697          	auipc	a3,0x4
ffffffffc0203034:	81868693          	addi	a3,a3,-2024 # ffffffffc0206848 <default_pmm_manager+0x360>
ffffffffc0203038:	00003617          	auipc	a2,0x3
ffffffffc020303c:	10060613          	addi	a2,a2,256 # ffffffffc0206138 <commands+0x828>
ffffffffc0203040:	23100593          	li	a1,561
ffffffffc0203044:	00003517          	auipc	a0,0x3
ffffffffc0203048:	5f450513          	addi	a0,a0,1524 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020304c:	c42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203050:	00004697          	auipc	a3,0x4
ffffffffc0203054:	97068693          	addi	a3,a3,-1680 # ffffffffc02069c0 <default_pmm_manager+0x4d8>
ffffffffc0203058:	00003617          	auipc	a2,0x3
ffffffffc020305c:	0e060613          	addi	a2,a2,224 # ffffffffc0206138 <commands+0x828>
ffffffffc0203060:	22e00593          	li	a1,558
ffffffffc0203064:	00003517          	auipc	a0,0x3
ffffffffc0203068:	5d450513          	addi	a0,a0,1492 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020306c:	c22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203070:	00003697          	auipc	a3,0x3
ffffffffc0203074:	7c068693          	addi	a3,a3,1984 # ffffffffc0206830 <default_pmm_manager+0x348>
ffffffffc0203078:	00003617          	auipc	a2,0x3
ffffffffc020307c:	0c060613          	addi	a2,a2,192 # ffffffffc0206138 <commands+0x828>
ffffffffc0203080:	22d00593          	li	a1,557
ffffffffc0203084:	00003517          	auipc	a0,0x3
ffffffffc0203088:	5b450513          	addi	a0,a0,1460 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020308c:	c02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203090:	00004697          	auipc	a3,0x4
ffffffffc0203094:	84068693          	addi	a3,a3,-1984 # ffffffffc02068d0 <default_pmm_manager+0x3e8>
ffffffffc0203098:	00003617          	auipc	a2,0x3
ffffffffc020309c:	0a060613          	addi	a2,a2,160 # ffffffffc0206138 <commands+0x828>
ffffffffc02030a0:	22c00593          	li	a1,556
ffffffffc02030a4:	00003517          	auipc	a0,0x3
ffffffffc02030a8:	59450513          	addi	a0,a0,1428 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02030ac:	be2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030b0:	00004697          	auipc	a3,0x4
ffffffffc02030b4:	8f868693          	addi	a3,a3,-1800 # ffffffffc02069a8 <default_pmm_manager+0x4c0>
ffffffffc02030b8:	00003617          	auipc	a2,0x3
ffffffffc02030bc:	08060613          	addi	a2,a2,128 # ffffffffc0206138 <commands+0x828>
ffffffffc02030c0:	22b00593          	li	a1,555
ffffffffc02030c4:	00003517          	auipc	a0,0x3
ffffffffc02030c8:	57450513          	addi	a0,a0,1396 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02030cc:	bc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030d0:	00004697          	auipc	a3,0x4
ffffffffc02030d4:	8c068693          	addi	a3,a3,-1856 # ffffffffc0206990 <default_pmm_manager+0x4a8>
ffffffffc02030d8:	00003617          	auipc	a2,0x3
ffffffffc02030dc:	06060613          	addi	a2,a2,96 # ffffffffc0206138 <commands+0x828>
ffffffffc02030e0:	22a00593          	li	a1,554
ffffffffc02030e4:	00003517          	auipc	a0,0x3
ffffffffc02030e8:	55450513          	addi	a0,a0,1364 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02030ec:	ba2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030f0:	00004697          	auipc	a3,0x4
ffffffffc02030f4:	87068693          	addi	a3,a3,-1936 # ffffffffc0206960 <default_pmm_manager+0x478>
ffffffffc02030f8:	00003617          	auipc	a2,0x3
ffffffffc02030fc:	04060613          	addi	a2,a2,64 # ffffffffc0206138 <commands+0x828>
ffffffffc0203100:	22900593          	li	a1,553
ffffffffc0203104:	00003517          	auipc	a0,0x3
ffffffffc0203108:	53450513          	addi	a0,a0,1332 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020310c:	b82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203110:	00004697          	auipc	a3,0x4
ffffffffc0203114:	83868693          	addi	a3,a3,-1992 # ffffffffc0206948 <default_pmm_manager+0x460>
ffffffffc0203118:	00003617          	auipc	a2,0x3
ffffffffc020311c:	02060613          	addi	a2,a2,32 # ffffffffc0206138 <commands+0x828>
ffffffffc0203120:	22700593          	li	a1,551
ffffffffc0203124:	00003517          	auipc	a0,0x3
ffffffffc0203128:	51450513          	addi	a0,a0,1300 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020312c:	b62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203130:	00003697          	auipc	a3,0x3
ffffffffc0203134:	7f868693          	addi	a3,a3,2040 # ffffffffc0206928 <default_pmm_manager+0x440>
ffffffffc0203138:	00003617          	auipc	a2,0x3
ffffffffc020313c:	00060613          	mv	a2,a2
ffffffffc0203140:	22600593          	li	a1,550
ffffffffc0203144:	00003517          	auipc	a0,0x3
ffffffffc0203148:	4f450513          	addi	a0,a0,1268 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020314c:	b42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203150:	00003697          	auipc	a3,0x3
ffffffffc0203154:	7c868693          	addi	a3,a3,1992 # ffffffffc0206918 <default_pmm_manager+0x430>
ffffffffc0203158:	00003617          	auipc	a2,0x3
ffffffffc020315c:	fe060613          	addi	a2,a2,-32 # ffffffffc0206138 <commands+0x828>
ffffffffc0203160:	22500593          	li	a1,549
ffffffffc0203164:	00003517          	auipc	a0,0x3
ffffffffc0203168:	4d450513          	addi	a0,a0,1236 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020316c:	b22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203170:	00003697          	auipc	a3,0x3
ffffffffc0203174:	79868693          	addi	a3,a3,1944 # ffffffffc0206908 <default_pmm_manager+0x420>
ffffffffc0203178:	00003617          	auipc	a2,0x3
ffffffffc020317c:	fc060613          	addi	a2,a2,-64 # ffffffffc0206138 <commands+0x828>
ffffffffc0203180:	22400593          	li	a1,548
ffffffffc0203184:	00003517          	auipc	a0,0x3
ffffffffc0203188:	4b450513          	addi	a0,a0,1204 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020318c:	b02fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203190:	00003617          	auipc	a2,0x3
ffffffffc0203194:	51860613          	addi	a2,a2,1304 # ffffffffc02066a8 <default_pmm_manager+0x1c0>
ffffffffc0203198:	06500593          	li	a1,101
ffffffffc020319c:	00003517          	auipc	a0,0x3
ffffffffc02031a0:	49c50513          	addi	a0,a0,1180 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02031a4:	aeafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02031a8:	00004697          	auipc	a3,0x4
ffffffffc02031ac:	87868693          	addi	a3,a3,-1928 # ffffffffc0206a20 <default_pmm_manager+0x538>
ffffffffc02031b0:	00003617          	auipc	a2,0x3
ffffffffc02031b4:	f8860613          	addi	a2,a2,-120 # ffffffffc0206138 <commands+0x828>
ffffffffc02031b8:	26a00593          	li	a1,618
ffffffffc02031bc:	00003517          	auipc	a0,0x3
ffffffffc02031c0:	47c50513          	addi	a0,a0,1148 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02031c4:	acafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031c8:	00003697          	auipc	a3,0x3
ffffffffc02031cc:	70868693          	addi	a3,a3,1800 # ffffffffc02068d0 <default_pmm_manager+0x3e8>
ffffffffc02031d0:	00003617          	auipc	a2,0x3
ffffffffc02031d4:	f6860613          	addi	a2,a2,-152 # ffffffffc0206138 <commands+0x828>
ffffffffc02031d8:	22300593          	li	a1,547
ffffffffc02031dc:	00003517          	auipc	a0,0x3
ffffffffc02031e0:	45c50513          	addi	a0,a0,1116 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02031e4:	aaafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031e8:	00003697          	auipc	a3,0x3
ffffffffc02031ec:	6a868693          	addi	a3,a3,1704 # ffffffffc0206890 <default_pmm_manager+0x3a8>
ffffffffc02031f0:	00003617          	auipc	a2,0x3
ffffffffc02031f4:	f4860613          	addi	a2,a2,-184 # ffffffffc0206138 <commands+0x828>
ffffffffc02031f8:	22200593          	li	a1,546
ffffffffc02031fc:	00003517          	auipc	a0,0x3
ffffffffc0203200:	43c50513          	addi	a0,a0,1084 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203204:	a8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203208:	86d6                	mv	a3,s5
ffffffffc020320a:	00003617          	auipc	a2,0x3
ffffffffc020320e:	31660613          	addi	a2,a2,790 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0203212:	21e00593          	li	a1,542
ffffffffc0203216:	00003517          	auipc	a0,0x3
ffffffffc020321a:	42250513          	addi	a0,a0,1058 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020321e:	a70fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203222:	00003617          	auipc	a2,0x3
ffffffffc0203226:	2fe60613          	addi	a2,a2,766 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc020322a:	21d00593          	li	a1,541
ffffffffc020322e:	00003517          	auipc	a0,0x3
ffffffffc0203232:	40a50513          	addi	a0,a0,1034 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203236:	a58fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020323a:	00003697          	auipc	a3,0x3
ffffffffc020323e:	60e68693          	addi	a3,a3,1550 # ffffffffc0206848 <default_pmm_manager+0x360>
ffffffffc0203242:	00003617          	auipc	a2,0x3
ffffffffc0203246:	ef660613          	addi	a2,a2,-266 # ffffffffc0206138 <commands+0x828>
ffffffffc020324a:	21b00593          	li	a1,539
ffffffffc020324e:	00003517          	auipc	a0,0x3
ffffffffc0203252:	3ea50513          	addi	a0,a0,1002 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203256:	a38fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020325a:	00003697          	auipc	a3,0x3
ffffffffc020325e:	5d668693          	addi	a3,a3,1494 # ffffffffc0206830 <default_pmm_manager+0x348>
ffffffffc0203262:	00003617          	auipc	a2,0x3
ffffffffc0203266:	ed660613          	addi	a2,a2,-298 # ffffffffc0206138 <commands+0x828>
ffffffffc020326a:	21a00593          	li	a1,538
ffffffffc020326e:	00003517          	auipc	a0,0x3
ffffffffc0203272:	3ca50513          	addi	a0,a0,970 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203276:	a18fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020327a:	00004697          	auipc	a3,0x4
ffffffffc020327e:	96668693          	addi	a3,a3,-1690 # ffffffffc0206be0 <default_pmm_manager+0x6f8>
ffffffffc0203282:	00003617          	auipc	a2,0x3
ffffffffc0203286:	eb660613          	addi	a2,a2,-330 # ffffffffc0206138 <commands+0x828>
ffffffffc020328a:	26100593          	li	a1,609
ffffffffc020328e:	00003517          	auipc	a0,0x3
ffffffffc0203292:	3aa50513          	addi	a0,a0,938 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203296:	9f8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020329a:	00004697          	auipc	a3,0x4
ffffffffc020329e:	90e68693          	addi	a3,a3,-1778 # ffffffffc0206ba8 <default_pmm_manager+0x6c0>
ffffffffc02032a2:	00003617          	auipc	a2,0x3
ffffffffc02032a6:	e9660613          	addi	a2,a2,-362 # ffffffffc0206138 <commands+0x828>
ffffffffc02032aa:	25e00593          	li	a1,606
ffffffffc02032ae:	00003517          	auipc	a0,0x3
ffffffffc02032b2:	38a50513          	addi	a0,a0,906 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02032b6:	9d8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032ba:	00004697          	auipc	a3,0x4
ffffffffc02032be:	8be68693          	addi	a3,a3,-1858 # ffffffffc0206b78 <default_pmm_manager+0x690>
ffffffffc02032c2:	00003617          	auipc	a2,0x3
ffffffffc02032c6:	e7660613          	addi	a2,a2,-394 # ffffffffc0206138 <commands+0x828>
ffffffffc02032ca:	25a00593          	li	a1,602
ffffffffc02032ce:	00003517          	auipc	a0,0x3
ffffffffc02032d2:	36a50513          	addi	a0,a0,874 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02032d6:	9b8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02032da:	00004697          	auipc	a3,0x4
ffffffffc02032de:	85668693          	addi	a3,a3,-1962 # ffffffffc0206b30 <default_pmm_manager+0x648>
ffffffffc02032e2:	00003617          	auipc	a2,0x3
ffffffffc02032e6:	e5660613          	addi	a2,a2,-426 # ffffffffc0206138 <commands+0x828>
ffffffffc02032ea:	25900593          	li	a1,601
ffffffffc02032ee:	00003517          	auipc	a0,0x3
ffffffffc02032f2:	34a50513          	addi	a0,a0,842 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02032f6:	998fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02032fa:	00003617          	auipc	a2,0x3
ffffffffc02032fe:	2ce60613          	addi	a2,a2,718 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc0203302:	0c900593          	li	a1,201
ffffffffc0203306:	00003517          	auipc	a0,0x3
ffffffffc020330a:	33250513          	addi	a0,a0,818 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc020330e:	980fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203312:	00003617          	auipc	a2,0x3
ffffffffc0203316:	2b660613          	addi	a2,a2,694 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc020331a:	08100593          	li	a1,129
ffffffffc020331e:	00003517          	auipc	a0,0x3
ffffffffc0203322:	31a50513          	addi	a0,a0,794 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203326:	968fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020332a:	00003697          	auipc	a3,0x3
ffffffffc020332e:	4d668693          	addi	a3,a3,1238 # ffffffffc0206800 <default_pmm_manager+0x318>
ffffffffc0203332:	00003617          	auipc	a2,0x3
ffffffffc0203336:	e0660613          	addi	a2,a2,-506 # ffffffffc0206138 <commands+0x828>
ffffffffc020333a:	21900593          	li	a1,537
ffffffffc020333e:	00003517          	auipc	a0,0x3
ffffffffc0203342:	2fa50513          	addi	a0,a0,762 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203346:	948fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020334a:	00003697          	auipc	a3,0x3
ffffffffc020334e:	48668693          	addi	a3,a3,1158 # ffffffffc02067d0 <default_pmm_manager+0x2e8>
ffffffffc0203352:	00003617          	auipc	a2,0x3
ffffffffc0203356:	de660613          	addi	a2,a2,-538 # ffffffffc0206138 <commands+0x828>
ffffffffc020335a:	21600593          	li	a1,534
ffffffffc020335e:	00003517          	auipc	a0,0x3
ffffffffc0203362:	2da50513          	addi	a0,a0,730 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203366:	928fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020336a <copy_range>:
{
ffffffffc020336a:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020336c:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203370:	f486                	sd	ra,104(sp)
ffffffffc0203372:	f0a2                	sd	s0,96(sp)
ffffffffc0203374:	eca6                	sd	s1,88(sp)
ffffffffc0203376:	e8ca                	sd	s2,80(sp)
ffffffffc0203378:	e4ce                	sd	s3,72(sp)
ffffffffc020337a:	e0d2                	sd	s4,64(sp)
ffffffffc020337c:	fc56                	sd	s5,56(sp)
ffffffffc020337e:	f85a                	sd	s6,48(sp)
ffffffffc0203380:	f45e                	sd	s7,40(sp)
ffffffffc0203382:	f062                	sd	s8,32(sp)
ffffffffc0203384:	ec66                	sd	s9,24(sp)
ffffffffc0203386:	e86a                	sd	s10,16(sp)
ffffffffc0203388:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020338a:	17d2                	slli	a5,a5,0x34
ffffffffc020338c:	20079f63          	bnez	a5,ffffffffc02035aa <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc0203390:	002007b7          	lui	a5,0x200
ffffffffc0203394:	8432                	mv	s0,a2
ffffffffc0203396:	1af66263          	bltu	a2,a5,ffffffffc020353a <copy_range+0x1d0>
ffffffffc020339a:	8936                	mv	s2,a3
ffffffffc020339c:	18d67f63          	bgeu	a2,a3,ffffffffc020353a <copy_range+0x1d0>
ffffffffc02033a0:	4785                	li	a5,1
ffffffffc02033a2:	07fe                	slli	a5,a5,0x1f
ffffffffc02033a4:	18d7eb63          	bltu	a5,a3,ffffffffc020353a <copy_range+0x1d0>
ffffffffc02033a8:	5b7d                	li	s6,-1
ffffffffc02033aa:	8aaa                	mv	s5,a0
ffffffffc02033ac:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02033ae:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02033b0:	000a7c17          	auipc	s8,0xa7
ffffffffc02033b4:	218c0c13          	addi	s8,s8,536 # ffffffffc02aa5c8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02033b8:	000a7b97          	auipc	s7,0xa7
ffffffffc02033bc:	218b8b93          	addi	s7,s7,536 # ffffffffc02aa5d0 <pages>
    return KADDR(page2pa(page));
ffffffffc02033c0:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02033c4:	000a7c97          	auipc	s9,0xa7
ffffffffc02033c8:	214c8c93          	addi	s9,s9,532 # ffffffffc02aa5d8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02033cc:	4601                	li	a2,0
ffffffffc02033ce:	85a2                	mv	a1,s0
ffffffffc02033d0:	854e                	mv	a0,s3
ffffffffc02033d2:	b73fe0ef          	jal	ra,ffffffffc0201f44 <get_pte>
ffffffffc02033d6:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02033d8:	0e050c63          	beqz	a0,ffffffffc02034d0 <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc02033dc:	611c                	ld	a5,0(a0)
ffffffffc02033de:	8b85                	andi	a5,a5,1
ffffffffc02033e0:	e785                	bnez	a5,ffffffffc0203408 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02033e2:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02033e4:	ff2464e3          	bltu	s0,s2,ffffffffc02033cc <copy_range+0x62>
    return 0;
ffffffffc02033e8:	4501                	li	a0,0
}
ffffffffc02033ea:	70a6                	ld	ra,104(sp)
ffffffffc02033ec:	7406                	ld	s0,96(sp)
ffffffffc02033ee:	64e6                	ld	s1,88(sp)
ffffffffc02033f0:	6946                	ld	s2,80(sp)
ffffffffc02033f2:	69a6                	ld	s3,72(sp)
ffffffffc02033f4:	6a06                	ld	s4,64(sp)
ffffffffc02033f6:	7ae2                	ld	s5,56(sp)
ffffffffc02033f8:	7b42                	ld	s6,48(sp)
ffffffffc02033fa:	7ba2                	ld	s7,40(sp)
ffffffffc02033fc:	7c02                	ld	s8,32(sp)
ffffffffc02033fe:	6ce2                	ld	s9,24(sp)
ffffffffc0203400:	6d42                	ld	s10,16(sp)
ffffffffc0203402:	6da2                	ld	s11,8(sp)
ffffffffc0203404:	6165                	addi	sp,sp,112
ffffffffc0203406:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203408:	4605                	li	a2,1
ffffffffc020340a:	85a2                	mv	a1,s0
ffffffffc020340c:	8556                	mv	a0,s5
ffffffffc020340e:	b37fe0ef          	jal	ra,ffffffffc0201f44 <get_pte>
ffffffffc0203412:	c56d                	beqz	a0,ffffffffc02034fc <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203414:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203416:	0017f713          	andi	a4,a5,1
ffffffffc020341a:	01f7f493          	andi	s1,a5,31
ffffffffc020341e:	16070a63          	beqz	a4,ffffffffc0203592 <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc0203422:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203426:	078a                	slli	a5,a5,0x2
ffffffffc0203428:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020342c:	14d77763          	bgeu	a4,a3,ffffffffc020357a <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc0203430:	000bb783          	ld	a5,0(s7)
ffffffffc0203434:	fff806b7          	lui	a3,0xfff80
ffffffffc0203438:	9736                	add	a4,a4,a3
ffffffffc020343a:	071a                	slli	a4,a4,0x6
ffffffffc020343c:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203440:	10002773          	csrr	a4,sstatus
ffffffffc0203444:	8b09                	andi	a4,a4,2
ffffffffc0203446:	e345                	bnez	a4,ffffffffc02034e6 <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203448:	000cb703          	ld	a4,0(s9)
ffffffffc020344c:	4505                	li	a0,1
ffffffffc020344e:	6f18                	ld	a4,24(a4)
ffffffffc0203450:	9702                	jalr	a4
ffffffffc0203452:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203454:	0c0d8363          	beqz	s11,ffffffffc020351a <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc0203458:	100d0163          	beqz	s10,ffffffffc020355a <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc020345c:	000bb703          	ld	a4,0(s7)
ffffffffc0203460:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203464:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203468:	40ed86b3          	sub	a3,s11,a4
ffffffffc020346c:	8699                	srai	a3,a3,0x6
ffffffffc020346e:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0203470:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203474:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203476:	08c7f663          	bgeu	a5,a2,ffffffffc0203502 <copy_range+0x198>
    return page - pages + nbase;
ffffffffc020347a:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc020347e:	000a7717          	auipc	a4,0xa7
ffffffffc0203482:	16270713          	addi	a4,a4,354 # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0203486:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203488:	8799                	srai	a5,a5,0x6
ffffffffc020348a:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc020348c:	0167f733          	and	a4,a5,s6
ffffffffc0203490:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203494:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203496:	06c77563          	bgeu	a4,a2,ffffffffc0203500 <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020349a:	6605                	lui	a2,0x1
ffffffffc020349c:	953e                	add	a0,a0,a5
ffffffffc020349e:	1ec020ef          	jal	ra,ffffffffc020568a <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034a2:	86a6                	mv	a3,s1
ffffffffc02034a4:	8622                	mv	a2,s0
ffffffffc02034a6:	85ea                	mv	a1,s10
ffffffffc02034a8:	8556                	mv	a0,s5
ffffffffc02034aa:	98aff0ef          	jal	ra,ffffffffc0202634 <page_insert>
            assert(ret == 0);
ffffffffc02034ae:	d915                	beqz	a0,ffffffffc02033e2 <copy_range+0x78>
ffffffffc02034b0:	00003697          	auipc	a3,0x3
ffffffffc02034b4:	79868693          	addi	a3,a3,1944 # ffffffffc0206c48 <default_pmm_manager+0x760>
ffffffffc02034b8:	00003617          	auipc	a2,0x3
ffffffffc02034bc:	c8060613          	addi	a2,a2,-896 # ffffffffc0206138 <commands+0x828>
ffffffffc02034c0:	1ae00593          	li	a1,430
ffffffffc02034c4:	00003517          	auipc	a0,0x3
ffffffffc02034c8:	17450513          	addi	a0,a0,372 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02034cc:	fc3fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02034d0:	00200637          	lui	a2,0x200
ffffffffc02034d4:	9432                	add	s0,s0,a2
ffffffffc02034d6:	ffe00637          	lui	a2,0xffe00
ffffffffc02034da:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02034dc:	f00406e3          	beqz	s0,ffffffffc02033e8 <copy_range+0x7e>
ffffffffc02034e0:	ef2466e3          	bltu	s0,s2,ffffffffc02033cc <copy_range+0x62>
ffffffffc02034e4:	b711                	j	ffffffffc02033e8 <copy_range+0x7e>
        intr_disable();
ffffffffc02034e6:	ccefd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034ea:	000cb703          	ld	a4,0(s9)
ffffffffc02034ee:	4505                	li	a0,1
ffffffffc02034f0:	6f18                	ld	a4,24(a4)
ffffffffc02034f2:	9702                	jalr	a4
ffffffffc02034f4:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc02034f6:	cb8fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02034fa:	bfa9                	j	ffffffffc0203454 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc02034fc:	5571                	li	a0,-4
ffffffffc02034fe:	b5f5                	j	ffffffffc02033ea <copy_range+0x80>
ffffffffc0203500:	86be                	mv	a3,a5
ffffffffc0203502:	00003617          	auipc	a2,0x3
ffffffffc0203506:	01e60613          	addi	a2,a2,30 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc020350a:	07100593          	li	a1,113
ffffffffc020350e:	00003517          	auipc	a0,0x3
ffffffffc0203512:	03a50513          	addi	a0,a0,58 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0203516:	f79fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc020351a:	00003697          	auipc	a3,0x3
ffffffffc020351e:	70e68693          	addi	a3,a3,1806 # ffffffffc0206c28 <default_pmm_manager+0x740>
ffffffffc0203522:	00003617          	auipc	a2,0x3
ffffffffc0203526:	c1660613          	addi	a2,a2,-1002 # ffffffffc0206138 <commands+0x828>
ffffffffc020352a:	19400593          	li	a1,404
ffffffffc020352e:	00003517          	auipc	a0,0x3
ffffffffc0203532:	10a50513          	addi	a0,a0,266 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203536:	f59fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020353a:	00003697          	auipc	a3,0x3
ffffffffc020353e:	13e68693          	addi	a3,a3,318 # ffffffffc0206678 <default_pmm_manager+0x190>
ffffffffc0203542:	00003617          	auipc	a2,0x3
ffffffffc0203546:	bf660613          	addi	a2,a2,-1034 # ffffffffc0206138 <commands+0x828>
ffffffffc020354a:	17c00593          	li	a1,380
ffffffffc020354e:	00003517          	auipc	a0,0x3
ffffffffc0203552:	0ea50513          	addi	a0,a0,234 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203556:	f39fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc020355a:	00003697          	auipc	a3,0x3
ffffffffc020355e:	6de68693          	addi	a3,a3,1758 # ffffffffc0206c38 <default_pmm_manager+0x750>
ffffffffc0203562:	00003617          	auipc	a2,0x3
ffffffffc0203566:	bd660613          	addi	a2,a2,-1066 # ffffffffc0206138 <commands+0x828>
ffffffffc020356a:	19500593          	li	a1,405
ffffffffc020356e:	00003517          	auipc	a0,0x3
ffffffffc0203572:	0ca50513          	addi	a0,a0,202 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203576:	f19fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020357a:	00003617          	auipc	a2,0x3
ffffffffc020357e:	07660613          	addi	a2,a2,118 # ffffffffc02065f0 <default_pmm_manager+0x108>
ffffffffc0203582:	06900593          	li	a1,105
ffffffffc0203586:	00003517          	auipc	a0,0x3
ffffffffc020358a:	fc250513          	addi	a0,a0,-62 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc020358e:	f01fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203592:	00003617          	auipc	a2,0x3
ffffffffc0203596:	07e60613          	addi	a2,a2,126 # ffffffffc0206610 <default_pmm_manager+0x128>
ffffffffc020359a:	07f00593          	li	a1,127
ffffffffc020359e:	00003517          	auipc	a0,0x3
ffffffffc02035a2:	faa50513          	addi	a0,a0,-86 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc02035a6:	ee9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035aa:	00003697          	auipc	a3,0x3
ffffffffc02035ae:	09e68693          	addi	a3,a3,158 # ffffffffc0206648 <default_pmm_manager+0x160>
ffffffffc02035b2:	00003617          	auipc	a2,0x3
ffffffffc02035b6:	b8660613          	addi	a2,a2,-1146 # ffffffffc0206138 <commands+0x828>
ffffffffc02035ba:	17b00593          	li	a1,379
ffffffffc02035be:	00003517          	auipc	a0,0x3
ffffffffc02035c2:	07a50513          	addi	a0,a0,122 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc02035c6:	ec9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035ca <pgdir_alloc_page>:
{
ffffffffc02035ca:	7179                	addi	sp,sp,-48
ffffffffc02035cc:	ec26                	sd	s1,24(sp)
ffffffffc02035ce:	e84a                	sd	s2,16(sp)
ffffffffc02035d0:	e052                	sd	s4,0(sp)
ffffffffc02035d2:	f406                	sd	ra,40(sp)
ffffffffc02035d4:	f022                	sd	s0,32(sp)
ffffffffc02035d6:	e44e                	sd	s3,8(sp)
ffffffffc02035d8:	8a2a                	mv	s4,a0
ffffffffc02035da:	84ae                	mv	s1,a1
ffffffffc02035dc:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035de:	100027f3          	csrr	a5,sstatus
ffffffffc02035e2:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02035e4:	000a7997          	auipc	s3,0xa7
ffffffffc02035e8:	ff498993          	addi	s3,s3,-12 # ffffffffc02aa5d8 <pmm_manager>
ffffffffc02035ec:	ef8d                	bnez	a5,ffffffffc0203626 <pgdir_alloc_page+0x5c>
ffffffffc02035ee:	0009b783          	ld	a5,0(s3)
ffffffffc02035f2:	4505                	li	a0,1
ffffffffc02035f4:	6f9c                	ld	a5,24(a5)
ffffffffc02035f6:	9782                	jalr	a5
ffffffffc02035f8:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02035fa:	cc09                	beqz	s0,ffffffffc0203614 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02035fc:	86ca                	mv	a3,s2
ffffffffc02035fe:	8626                	mv	a2,s1
ffffffffc0203600:	85a2                	mv	a1,s0
ffffffffc0203602:	8552                	mv	a0,s4
ffffffffc0203604:	830ff0ef          	jal	ra,ffffffffc0202634 <page_insert>
ffffffffc0203608:	e915                	bnez	a0,ffffffffc020363c <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc020360a:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc020360c:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020360e:	4785                	li	a5,1
ffffffffc0203610:	04f71e63          	bne	a4,a5,ffffffffc020366c <pgdir_alloc_page+0xa2>
}
ffffffffc0203614:	70a2                	ld	ra,40(sp)
ffffffffc0203616:	8522                	mv	a0,s0
ffffffffc0203618:	7402                	ld	s0,32(sp)
ffffffffc020361a:	64e2                	ld	s1,24(sp)
ffffffffc020361c:	6942                	ld	s2,16(sp)
ffffffffc020361e:	69a2                	ld	s3,8(sp)
ffffffffc0203620:	6a02                	ld	s4,0(sp)
ffffffffc0203622:	6145                	addi	sp,sp,48
ffffffffc0203624:	8082                	ret
        intr_disable();
ffffffffc0203626:	b8efd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020362a:	0009b783          	ld	a5,0(s3)
ffffffffc020362e:	4505                	li	a0,1
ffffffffc0203630:	6f9c                	ld	a5,24(a5)
ffffffffc0203632:	9782                	jalr	a5
ffffffffc0203634:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203636:	b78fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020363a:	b7c1                	j	ffffffffc02035fa <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020363c:	100027f3          	csrr	a5,sstatus
ffffffffc0203640:	8b89                	andi	a5,a5,2
ffffffffc0203642:	eb89                	bnez	a5,ffffffffc0203654 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203644:	0009b783          	ld	a5,0(s3)
ffffffffc0203648:	8522                	mv	a0,s0
ffffffffc020364a:	4585                	li	a1,1
ffffffffc020364c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020364e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203650:	9782                	jalr	a5
    if (flag)
ffffffffc0203652:	b7c9                	j	ffffffffc0203614 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203654:	b60fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203658:	0009b783          	ld	a5,0(s3)
ffffffffc020365c:	8522                	mv	a0,s0
ffffffffc020365e:	4585                	li	a1,1
ffffffffc0203660:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203662:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203664:	9782                	jalr	a5
        intr_enable();
ffffffffc0203666:	b48fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020366a:	b76d                	j	ffffffffc0203614 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020366c:	00003697          	auipc	a3,0x3
ffffffffc0203670:	5ec68693          	addi	a3,a3,1516 # ffffffffc0206c58 <default_pmm_manager+0x770>
ffffffffc0203674:	00003617          	auipc	a2,0x3
ffffffffc0203678:	ac460613          	addi	a2,a2,-1340 # ffffffffc0206138 <commands+0x828>
ffffffffc020367c:	1f700593          	li	a1,503
ffffffffc0203680:	00003517          	auipc	a0,0x3
ffffffffc0203684:	fb850513          	addi	a0,a0,-72 # ffffffffc0206638 <default_pmm_manager+0x150>
ffffffffc0203688:	e07fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020368c <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020368c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020368e:	00003697          	auipc	a3,0x3
ffffffffc0203692:	5e268693          	addi	a3,a3,1506 # ffffffffc0206c70 <default_pmm_manager+0x788>
ffffffffc0203696:	00003617          	auipc	a2,0x3
ffffffffc020369a:	aa260613          	addi	a2,a2,-1374 # ffffffffc0206138 <commands+0x828>
ffffffffc020369e:	07400593          	li	a1,116
ffffffffc02036a2:	00003517          	auipc	a0,0x3
ffffffffc02036a6:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036aa:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036ac:	de3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036b0 <mm_create>:
{
ffffffffc02036b0:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036b2:	04000513          	li	a0,64
{
ffffffffc02036b6:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036b8:	df6fe0ef          	jal	ra,ffffffffc0201cae <kmalloc>
    if (mm != NULL)
ffffffffc02036bc:	cd19                	beqz	a0,ffffffffc02036da <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036be:	e508                	sd	a0,8(a0)
ffffffffc02036c0:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036c2:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036c6:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036ca:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036ce:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036d2:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036d6:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036da:	60a2                	ld	ra,8(sp)
ffffffffc02036dc:	0141                	addi	sp,sp,16
ffffffffc02036de:	8082                	ret

ffffffffc02036e0 <find_vma>:
{
ffffffffc02036e0:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02036e2:	c505                	beqz	a0,ffffffffc020370a <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02036e4:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036e6:	c501                	beqz	a0,ffffffffc02036ee <find_vma+0xe>
ffffffffc02036e8:	651c                	ld	a5,8(a0)
ffffffffc02036ea:	02f5f263          	bgeu	a1,a5,ffffffffc020370e <find_vma+0x2e>
    return listelm->next;
ffffffffc02036ee:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02036f0:	00f68d63          	beq	a3,a5,ffffffffc020370a <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02036f4:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ee0>
ffffffffc02036f8:	00e5e663          	bltu	a1,a4,ffffffffc0203704 <find_vma+0x24>
ffffffffc02036fc:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203700:	00e5ec63          	bltu	a1,a4,ffffffffc0203718 <find_vma+0x38>
ffffffffc0203704:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203706:	fef697e3          	bne	a3,a5,ffffffffc02036f4 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc020370a:	4501                	li	a0,0
}
ffffffffc020370c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020370e:	691c                	ld	a5,16(a0)
ffffffffc0203710:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02036ee <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203714:	ea88                	sd	a0,16(a3)
ffffffffc0203716:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203718:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc020371c:	ea88                	sd	a0,16(a3)
ffffffffc020371e:	8082                	ret

ffffffffc0203720 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203720:	6590                	ld	a2,8(a1)
ffffffffc0203722:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74f08>
{
ffffffffc0203726:	1141                	addi	sp,sp,-16
ffffffffc0203728:	e406                	sd	ra,8(sp)
ffffffffc020372a:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020372c:	01066763          	bltu	a2,a6,ffffffffc020373a <insert_vma_struct+0x1a>
ffffffffc0203730:	a085                	j	ffffffffc0203790 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203732:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203736:	04e66863          	bltu	a2,a4,ffffffffc0203786 <insert_vma_struct+0x66>
ffffffffc020373a:	86be                	mv	a3,a5
ffffffffc020373c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020373e:	fef51ae3          	bne	a0,a5,ffffffffc0203732 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203742:	02a68463          	beq	a3,a0,ffffffffc020376a <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203746:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020374a:	fe86b883          	ld	a7,-24(a3)
ffffffffc020374e:	08e8f163          	bgeu	a7,a4,ffffffffc02037d0 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203752:	04e66f63          	bltu	a2,a4,ffffffffc02037b0 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203756:	00f50a63          	beq	a0,a5,ffffffffc020376a <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020375a:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020375e:	05076963          	bltu	a4,a6,ffffffffc02037b0 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203762:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203766:	02c77363          	bgeu	a4,a2,ffffffffc020378c <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020376a:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020376c:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020376e:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203772:	e390                	sd	a2,0(a5)
ffffffffc0203774:	e690                	sd	a2,8(a3)
}
ffffffffc0203776:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203778:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020377a:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020377c:	0017079b          	addiw	a5,a4,1
ffffffffc0203780:	d11c                	sw	a5,32(a0)
}
ffffffffc0203782:	0141                	addi	sp,sp,16
ffffffffc0203784:	8082                	ret
    if (le_prev != list)
ffffffffc0203786:	fca690e3          	bne	a3,a0,ffffffffc0203746 <insert_vma_struct+0x26>
ffffffffc020378a:	bfd1                	j	ffffffffc020375e <insert_vma_struct+0x3e>
ffffffffc020378c:	f01ff0ef          	jal	ra,ffffffffc020368c <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203790:	00003697          	auipc	a3,0x3
ffffffffc0203794:	51068693          	addi	a3,a3,1296 # ffffffffc0206ca0 <default_pmm_manager+0x7b8>
ffffffffc0203798:	00003617          	auipc	a2,0x3
ffffffffc020379c:	9a060613          	addi	a2,a2,-1632 # ffffffffc0206138 <commands+0x828>
ffffffffc02037a0:	07a00593          	li	a1,122
ffffffffc02037a4:	00003517          	auipc	a0,0x3
ffffffffc02037a8:	4ec50513          	addi	a0,a0,1260 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc02037ac:	ce3fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037b0:	00003697          	auipc	a3,0x3
ffffffffc02037b4:	53068693          	addi	a3,a3,1328 # ffffffffc0206ce0 <default_pmm_manager+0x7f8>
ffffffffc02037b8:	00003617          	auipc	a2,0x3
ffffffffc02037bc:	98060613          	addi	a2,a2,-1664 # ffffffffc0206138 <commands+0x828>
ffffffffc02037c0:	07300593          	li	a1,115
ffffffffc02037c4:	00003517          	auipc	a0,0x3
ffffffffc02037c8:	4cc50513          	addi	a0,a0,1228 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc02037cc:	cc3fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037d0:	00003697          	auipc	a3,0x3
ffffffffc02037d4:	4f068693          	addi	a3,a3,1264 # ffffffffc0206cc0 <default_pmm_manager+0x7d8>
ffffffffc02037d8:	00003617          	auipc	a2,0x3
ffffffffc02037dc:	96060613          	addi	a2,a2,-1696 # ffffffffc0206138 <commands+0x828>
ffffffffc02037e0:	07200593          	li	a1,114
ffffffffc02037e4:	00003517          	auipc	a0,0x3
ffffffffc02037e8:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc02037ec:	ca3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037f0 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02037f0:	591c                	lw	a5,48(a0)
{
ffffffffc02037f2:	1141                	addi	sp,sp,-16
ffffffffc02037f4:	e406                	sd	ra,8(sp)
ffffffffc02037f6:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02037f8:	e78d                	bnez	a5,ffffffffc0203822 <mm_destroy+0x32>
ffffffffc02037fa:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02037fc:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02037fe:	00a40c63          	beq	s0,a0,ffffffffc0203816 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203802:	6118                	ld	a4,0(a0)
ffffffffc0203804:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203806:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203808:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020380a:	e398                	sd	a4,0(a5)
ffffffffc020380c:	d52fe0ef          	jal	ra,ffffffffc0201d5e <kfree>
    return listelm->next;
ffffffffc0203810:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203812:	fea418e3          	bne	s0,a0,ffffffffc0203802 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203816:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203818:	6402                	ld	s0,0(sp)
ffffffffc020381a:	60a2                	ld	ra,8(sp)
ffffffffc020381c:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020381e:	d40fe06f          	j	ffffffffc0201d5e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203822:	00003697          	auipc	a3,0x3
ffffffffc0203826:	4de68693          	addi	a3,a3,1246 # ffffffffc0206d00 <default_pmm_manager+0x818>
ffffffffc020382a:	00003617          	auipc	a2,0x3
ffffffffc020382e:	90e60613          	addi	a2,a2,-1778 # ffffffffc0206138 <commands+0x828>
ffffffffc0203832:	09e00593          	li	a1,158
ffffffffc0203836:	00003517          	auipc	a0,0x3
ffffffffc020383a:	45a50513          	addi	a0,a0,1114 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc020383e:	c51fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203842 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203842:	7139                	addi	sp,sp,-64
ffffffffc0203844:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203846:	6405                	lui	s0,0x1
ffffffffc0203848:	147d                	addi	s0,s0,-1
ffffffffc020384a:	77fd                	lui	a5,0xfffff
ffffffffc020384c:	9622                	add	a2,a2,s0
ffffffffc020384e:	962e                	add	a2,a2,a1
{
ffffffffc0203850:	f426                	sd	s1,40(sp)
ffffffffc0203852:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203854:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203858:	f04a                	sd	s2,32(sp)
ffffffffc020385a:	ec4e                	sd	s3,24(sp)
ffffffffc020385c:	e852                	sd	s4,16(sp)
ffffffffc020385e:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203860:	002005b7          	lui	a1,0x200
ffffffffc0203864:	00f67433          	and	s0,a2,a5
ffffffffc0203868:	06b4e363          	bltu	s1,a1,ffffffffc02038ce <mm_map+0x8c>
ffffffffc020386c:	0684f163          	bgeu	s1,s0,ffffffffc02038ce <mm_map+0x8c>
ffffffffc0203870:	4785                	li	a5,1
ffffffffc0203872:	07fe                	slli	a5,a5,0x1f
ffffffffc0203874:	0487ed63          	bltu	a5,s0,ffffffffc02038ce <mm_map+0x8c>
ffffffffc0203878:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020387a:	cd21                	beqz	a0,ffffffffc02038d2 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020387c:	85a6                	mv	a1,s1
ffffffffc020387e:	8ab6                	mv	s5,a3
ffffffffc0203880:	8a3a                	mv	s4,a4
ffffffffc0203882:	e5fff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
ffffffffc0203886:	c501                	beqz	a0,ffffffffc020388e <mm_map+0x4c>
ffffffffc0203888:	651c                	ld	a5,8(a0)
ffffffffc020388a:	0487e263          	bltu	a5,s0,ffffffffc02038ce <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020388e:	03000513          	li	a0,48
ffffffffc0203892:	c1cfe0ef          	jal	ra,ffffffffc0201cae <kmalloc>
ffffffffc0203896:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203898:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020389a:	02090163          	beqz	s2,ffffffffc02038bc <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020389e:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02038a0:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02038a4:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02038a8:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02038ac:	85ca                	mv	a1,s2
ffffffffc02038ae:	e73ff0ef          	jal	ra,ffffffffc0203720 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02038b2:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02038b4:	000a0463          	beqz	s4,ffffffffc02038bc <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02038b8:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8b98>

out:
    return ret;
}
ffffffffc02038bc:	70e2                	ld	ra,56(sp)
ffffffffc02038be:	7442                	ld	s0,48(sp)
ffffffffc02038c0:	74a2                	ld	s1,40(sp)
ffffffffc02038c2:	7902                	ld	s2,32(sp)
ffffffffc02038c4:	69e2                	ld	s3,24(sp)
ffffffffc02038c6:	6a42                	ld	s4,16(sp)
ffffffffc02038c8:	6aa2                	ld	s5,8(sp)
ffffffffc02038ca:	6121                	addi	sp,sp,64
ffffffffc02038cc:	8082                	ret
        return -E_INVAL;
ffffffffc02038ce:	5575                	li	a0,-3
ffffffffc02038d0:	b7f5                	j	ffffffffc02038bc <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038d2:	00003697          	auipc	a3,0x3
ffffffffc02038d6:	44668693          	addi	a3,a3,1094 # ffffffffc0206d18 <default_pmm_manager+0x830>
ffffffffc02038da:	00003617          	auipc	a2,0x3
ffffffffc02038de:	85e60613          	addi	a2,a2,-1954 # ffffffffc0206138 <commands+0x828>
ffffffffc02038e2:	0b300593          	li	a1,179
ffffffffc02038e6:	00003517          	auipc	a0,0x3
ffffffffc02038ea:	3aa50513          	addi	a0,a0,938 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc02038ee:	ba1fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038f2 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038f2:	7139                	addi	sp,sp,-64
ffffffffc02038f4:	fc06                	sd	ra,56(sp)
ffffffffc02038f6:	f822                	sd	s0,48(sp)
ffffffffc02038f8:	f426                	sd	s1,40(sp)
ffffffffc02038fa:	f04a                	sd	s2,32(sp)
ffffffffc02038fc:	ec4e                	sd	s3,24(sp)
ffffffffc02038fe:	e852                	sd	s4,16(sp)
ffffffffc0203900:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203902:	c52d                	beqz	a0,ffffffffc020396c <dup_mmap+0x7a>
ffffffffc0203904:	892a                	mv	s2,a0
ffffffffc0203906:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203908:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc020390a:	e595                	bnez	a1,ffffffffc0203936 <dup_mmap+0x44>
ffffffffc020390c:	a085                	j	ffffffffc020396c <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020390e:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203910:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4f00>
        vma->vm_end = vm_end;
ffffffffc0203914:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203918:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc020391c:	e05ff0ef          	jal	ra,ffffffffc0203720 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203920:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0203924:	fe843603          	ld	a2,-24(s0)
ffffffffc0203928:	6c8c                	ld	a1,24(s1)
ffffffffc020392a:	01893503          	ld	a0,24(s2)
ffffffffc020392e:	4701                	li	a4,0
ffffffffc0203930:	a3bff0ef          	jal	ra,ffffffffc020336a <copy_range>
ffffffffc0203934:	e105                	bnez	a0,ffffffffc0203954 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203936:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203938:	02848863          	beq	s1,s0,ffffffffc0203968 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020393c:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203940:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203944:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203948:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020394c:	b62fe0ef          	jal	ra,ffffffffc0201cae <kmalloc>
ffffffffc0203950:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203952:	fd55                	bnez	a0,ffffffffc020390e <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203954:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203956:	70e2                	ld	ra,56(sp)
ffffffffc0203958:	7442                	ld	s0,48(sp)
ffffffffc020395a:	74a2                	ld	s1,40(sp)
ffffffffc020395c:	7902                	ld	s2,32(sp)
ffffffffc020395e:	69e2                	ld	s3,24(sp)
ffffffffc0203960:	6a42                	ld	s4,16(sp)
ffffffffc0203962:	6aa2                	ld	s5,8(sp)
ffffffffc0203964:	6121                	addi	sp,sp,64
ffffffffc0203966:	8082                	ret
    return 0;
ffffffffc0203968:	4501                	li	a0,0
ffffffffc020396a:	b7f5                	j	ffffffffc0203956 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc020396c:	00003697          	auipc	a3,0x3
ffffffffc0203970:	3bc68693          	addi	a3,a3,956 # ffffffffc0206d28 <default_pmm_manager+0x840>
ffffffffc0203974:	00002617          	auipc	a2,0x2
ffffffffc0203978:	7c460613          	addi	a2,a2,1988 # ffffffffc0206138 <commands+0x828>
ffffffffc020397c:	0cf00593          	li	a1,207
ffffffffc0203980:	00003517          	auipc	a0,0x3
ffffffffc0203984:	31050513          	addi	a0,a0,784 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203988:	b07fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020398c <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc020398c:	1101                	addi	sp,sp,-32
ffffffffc020398e:	ec06                	sd	ra,24(sp)
ffffffffc0203990:	e822                	sd	s0,16(sp)
ffffffffc0203992:	e426                	sd	s1,8(sp)
ffffffffc0203994:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203996:	c531                	beqz	a0,ffffffffc02039e2 <exit_mmap+0x56>
ffffffffc0203998:	591c                	lw	a5,48(a0)
ffffffffc020399a:	84aa                	mv	s1,a0
ffffffffc020399c:	e3b9                	bnez	a5,ffffffffc02039e2 <exit_mmap+0x56>
    return listelm->next;
ffffffffc020399e:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02039a0:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02039a4:	02850663          	beq	a0,s0,ffffffffc02039d0 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039a8:	ff043603          	ld	a2,-16(s0)
ffffffffc02039ac:	fe843583          	ld	a1,-24(s0)
ffffffffc02039b0:	854a                	mv	a0,s2
ffffffffc02039b2:	80ffe0ef          	jal	ra,ffffffffc02021c0 <unmap_range>
ffffffffc02039b6:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039b8:	fe8498e3          	bne	s1,s0,ffffffffc02039a8 <exit_mmap+0x1c>
ffffffffc02039bc:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039be:	00848c63          	beq	s1,s0,ffffffffc02039d6 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039c2:	ff043603          	ld	a2,-16(s0)
ffffffffc02039c6:	fe843583          	ld	a1,-24(s0)
ffffffffc02039ca:	854a                	mv	a0,s2
ffffffffc02039cc:	93bfe0ef          	jal	ra,ffffffffc0202306 <exit_range>
ffffffffc02039d0:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039d2:	fe8498e3          	bne	s1,s0,ffffffffc02039c2 <exit_mmap+0x36>
    }
}
ffffffffc02039d6:	60e2                	ld	ra,24(sp)
ffffffffc02039d8:	6442                	ld	s0,16(sp)
ffffffffc02039da:	64a2                	ld	s1,8(sp)
ffffffffc02039dc:	6902                	ld	s2,0(sp)
ffffffffc02039de:	6105                	addi	sp,sp,32
ffffffffc02039e0:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039e2:	00003697          	auipc	a3,0x3
ffffffffc02039e6:	36668693          	addi	a3,a3,870 # ffffffffc0206d48 <default_pmm_manager+0x860>
ffffffffc02039ea:	00002617          	auipc	a2,0x2
ffffffffc02039ee:	74e60613          	addi	a2,a2,1870 # ffffffffc0206138 <commands+0x828>
ffffffffc02039f2:	0e800593          	li	a1,232
ffffffffc02039f6:	00003517          	auipc	a0,0x3
ffffffffc02039fa:	29a50513          	addi	a0,a0,666 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc02039fe:	a91fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a02 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a02:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a04:	04000513          	li	a0,64
{
ffffffffc0203a08:	fc06                	sd	ra,56(sp)
ffffffffc0203a0a:	f822                	sd	s0,48(sp)
ffffffffc0203a0c:	f426                	sd	s1,40(sp)
ffffffffc0203a0e:	f04a                	sd	s2,32(sp)
ffffffffc0203a10:	ec4e                	sd	s3,24(sp)
ffffffffc0203a12:	e852                	sd	s4,16(sp)
ffffffffc0203a14:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a16:	a98fe0ef          	jal	ra,ffffffffc0201cae <kmalloc>
    if (mm != NULL)
ffffffffc0203a1a:	2e050663          	beqz	a0,ffffffffc0203d06 <vmm_init+0x304>
ffffffffc0203a1e:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203a20:	e508                	sd	a0,8(a0)
ffffffffc0203a22:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a24:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a28:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a2c:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a30:	02053423          	sd	zero,40(a0)
ffffffffc0203a34:	02052823          	sw	zero,48(a0)
ffffffffc0203a38:	02053c23          	sd	zero,56(a0)
ffffffffc0203a3c:	03200413          	li	s0,50
ffffffffc0203a40:	a811                	j	ffffffffc0203a54 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203a42:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a44:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a46:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203a4a:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a4c:	8526                	mv	a0,s1
ffffffffc0203a4e:	cd3ff0ef          	jal	ra,ffffffffc0203720 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a52:	c80d                	beqz	s0,ffffffffc0203a84 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a54:	03000513          	li	a0,48
ffffffffc0203a58:	a56fe0ef          	jal	ra,ffffffffc0201cae <kmalloc>
ffffffffc0203a5c:	85aa                	mv	a1,a0
ffffffffc0203a5e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a62:	f165                	bnez	a0,ffffffffc0203a42 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a64:	00003697          	auipc	a3,0x3
ffffffffc0203a68:	47c68693          	addi	a3,a3,1148 # ffffffffc0206ee0 <default_pmm_manager+0x9f8>
ffffffffc0203a6c:	00002617          	auipc	a2,0x2
ffffffffc0203a70:	6cc60613          	addi	a2,a2,1740 # ffffffffc0206138 <commands+0x828>
ffffffffc0203a74:	12c00593          	li	a1,300
ffffffffc0203a78:	00003517          	auipc	a0,0x3
ffffffffc0203a7c:	21850513          	addi	a0,a0,536 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203a80:	a0ffc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203a84:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a88:	1f900913          	li	s2,505
ffffffffc0203a8c:	a819                	j	ffffffffc0203aa2 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203a8e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a90:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a92:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a96:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a98:	8526                	mv	a0,s1
ffffffffc0203a9a:	c87ff0ef          	jal	ra,ffffffffc0203720 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a9e:	03240a63          	beq	s0,s2,ffffffffc0203ad2 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aa2:	03000513          	li	a0,48
ffffffffc0203aa6:	a08fe0ef          	jal	ra,ffffffffc0201cae <kmalloc>
ffffffffc0203aaa:	85aa                	mv	a1,a0
ffffffffc0203aac:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203ab0:	fd79                	bnez	a0,ffffffffc0203a8e <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203ab2:	00003697          	auipc	a3,0x3
ffffffffc0203ab6:	42e68693          	addi	a3,a3,1070 # ffffffffc0206ee0 <default_pmm_manager+0x9f8>
ffffffffc0203aba:	00002617          	auipc	a2,0x2
ffffffffc0203abe:	67e60613          	addi	a2,a2,1662 # ffffffffc0206138 <commands+0x828>
ffffffffc0203ac2:	13300593          	li	a1,307
ffffffffc0203ac6:	00003517          	auipc	a0,0x3
ffffffffc0203aca:	1ca50513          	addi	a0,a0,458 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203ace:	9c1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203ad2:	649c                	ld	a5,8(s1)
ffffffffc0203ad4:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ad6:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203ada:	16f48663          	beq	s1,a5,ffffffffc0203c46 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ade:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd549e4>
ffffffffc0203ae2:	ffe70693          	addi	a3,a4,-2
ffffffffc0203ae6:	10d61063          	bne	a2,a3,ffffffffc0203be6 <vmm_init+0x1e4>
ffffffffc0203aea:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203aee:	0ed71c63          	bne	a4,a3,ffffffffc0203be6 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203af2:	0715                	addi	a4,a4,5
ffffffffc0203af4:	679c                	ld	a5,8(a5)
ffffffffc0203af6:	feb712e3          	bne	a4,a1,ffffffffc0203ada <vmm_init+0xd8>
ffffffffc0203afa:	4a1d                	li	s4,7
ffffffffc0203afc:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203afe:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b02:	85a2                	mv	a1,s0
ffffffffc0203b04:	8526                	mv	a0,s1
ffffffffc0203b06:	bdbff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
ffffffffc0203b0a:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203b0c:	16050d63          	beqz	a0,ffffffffc0203c86 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b10:	00140593          	addi	a1,s0,1
ffffffffc0203b14:	8526                	mv	a0,s1
ffffffffc0203b16:	bcbff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
ffffffffc0203b1a:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b1c:	14050563          	beqz	a0,ffffffffc0203c66 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b20:	85d2                	mv	a1,s4
ffffffffc0203b22:	8526                	mv	a0,s1
ffffffffc0203b24:	bbdff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b28:	16051f63          	bnez	a0,ffffffffc0203ca6 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b2c:	00340593          	addi	a1,s0,3
ffffffffc0203b30:	8526                	mv	a0,s1
ffffffffc0203b32:	bafff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b36:	1a051863          	bnez	a0,ffffffffc0203ce6 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b3a:	00440593          	addi	a1,s0,4
ffffffffc0203b3e:	8526                	mv	a0,s1
ffffffffc0203b40:	ba1ff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b44:	18051163          	bnez	a0,ffffffffc0203cc6 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b48:	00893783          	ld	a5,8(s2)
ffffffffc0203b4c:	0a879d63          	bne	a5,s0,ffffffffc0203c06 <vmm_init+0x204>
ffffffffc0203b50:	01093783          	ld	a5,16(s2)
ffffffffc0203b54:	0b479963          	bne	a5,s4,ffffffffc0203c06 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b58:	0089b783          	ld	a5,8(s3)
ffffffffc0203b5c:	0c879563          	bne	a5,s0,ffffffffc0203c26 <vmm_init+0x224>
ffffffffc0203b60:	0109b783          	ld	a5,16(s3)
ffffffffc0203b64:	0d479163          	bne	a5,s4,ffffffffc0203c26 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b68:	0415                	addi	s0,s0,5
ffffffffc0203b6a:	0a15                	addi	s4,s4,5
ffffffffc0203b6c:	f9541be3          	bne	s0,s5,ffffffffc0203b02 <vmm_init+0x100>
ffffffffc0203b70:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b72:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b74:	85a2                	mv	a1,s0
ffffffffc0203b76:	8526                	mv	a0,s1
ffffffffc0203b78:	b69ff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
ffffffffc0203b7c:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b80:	c90d                	beqz	a0,ffffffffc0203bb2 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203b82:	6914                	ld	a3,16(a0)
ffffffffc0203b84:	6510                	ld	a2,8(a0)
ffffffffc0203b86:	00003517          	auipc	a0,0x3
ffffffffc0203b8a:	2e250513          	addi	a0,a0,738 # ffffffffc0206e68 <default_pmm_manager+0x980>
ffffffffc0203b8e:	e06fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b92:	00003697          	auipc	a3,0x3
ffffffffc0203b96:	2fe68693          	addi	a3,a3,766 # ffffffffc0206e90 <default_pmm_manager+0x9a8>
ffffffffc0203b9a:	00002617          	auipc	a2,0x2
ffffffffc0203b9e:	59e60613          	addi	a2,a2,1438 # ffffffffc0206138 <commands+0x828>
ffffffffc0203ba2:	15900593          	li	a1,345
ffffffffc0203ba6:	00003517          	auipc	a0,0x3
ffffffffc0203baa:	0ea50513          	addi	a0,a0,234 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203bae:	8e1fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203bb2:	147d                	addi	s0,s0,-1
ffffffffc0203bb4:	fd2410e3          	bne	s0,s2,ffffffffc0203b74 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203bb8:	8526                	mv	a0,s1
ffffffffc0203bba:	c37ff0ef          	jal	ra,ffffffffc02037f0 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bbe:	00003517          	auipc	a0,0x3
ffffffffc0203bc2:	2ea50513          	addi	a0,a0,746 # ffffffffc0206ea8 <default_pmm_manager+0x9c0>
ffffffffc0203bc6:	dcefc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203bca:	7442                	ld	s0,48(sp)
ffffffffc0203bcc:	70e2                	ld	ra,56(sp)
ffffffffc0203bce:	74a2                	ld	s1,40(sp)
ffffffffc0203bd0:	7902                	ld	s2,32(sp)
ffffffffc0203bd2:	69e2                	ld	s3,24(sp)
ffffffffc0203bd4:	6a42                	ld	s4,16(sp)
ffffffffc0203bd6:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bd8:	00003517          	auipc	a0,0x3
ffffffffc0203bdc:	2f050513          	addi	a0,a0,752 # ffffffffc0206ec8 <default_pmm_manager+0x9e0>
}
ffffffffc0203be0:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203be2:	db2fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203be6:	00003697          	auipc	a3,0x3
ffffffffc0203bea:	19a68693          	addi	a3,a3,410 # ffffffffc0206d80 <default_pmm_manager+0x898>
ffffffffc0203bee:	00002617          	auipc	a2,0x2
ffffffffc0203bf2:	54a60613          	addi	a2,a2,1354 # ffffffffc0206138 <commands+0x828>
ffffffffc0203bf6:	13d00593          	li	a1,317
ffffffffc0203bfa:	00003517          	auipc	a0,0x3
ffffffffc0203bfe:	09650513          	addi	a0,a0,150 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203c02:	88dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c06:	00003697          	auipc	a3,0x3
ffffffffc0203c0a:	20268693          	addi	a3,a3,514 # ffffffffc0206e08 <default_pmm_manager+0x920>
ffffffffc0203c0e:	00002617          	auipc	a2,0x2
ffffffffc0203c12:	52a60613          	addi	a2,a2,1322 # ffffffffc0206138 <commands+0x828>
ffffffffc0203c16:	14e00593          	li	a1,334
ffffffffc0203c1a:	00003517          	auipc	a0,0x3
ffffffffc0203c1e:	07650513          	addi	a0,a0,118 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203c22:	86dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c26:	00003697          	auipc	a3,0x3
ffffffffc0203c2a:	21268693          	addi	a3,a3,530 # ffffffffc0206e38 <default_pmm_manager+0x950>
ffffffffc0203c2e:	00002617          	auipc	a2,0x2
ffffffffc0203c32:	50a60613          	addi	a2,a2,1290 # ffffffffc0206138 <commands+0x828>
ffffffffc0203c36:	14f00593          	li	a1,335
ffffffffc0203c3a:	00003517          	auipc	a0,0x3
ffffffffc0203c3e:	05650513          	addi	a0,a0,86 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203c42:	84dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c46:	00003697          	auipc	a3,0x3
ffffffffc0203c4a:	12268693          	addi	a3,a3,290 # ffffffffc0206d68 <default_pmm_manager+0x880>
ffffffffc0203c4e:	00002617          	auipc	a2,0x2
ffffffffc0203c52:	4ea60613          	addi	a2,a2,1258 # ffffffffc0206138 <commands+0x828>
ffffffffc0203c56:	13b00593          	li	a1,315
ffffffffc0203c5a:	00003517          	auipc	a0,0x3
ffffffffc0203c5e:	03650513          	addi	a0,a0,54 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203c62:	82dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c66:	00003697          	auipc	a3,0x3
ffffffffc0203c6a:	16268693          	addi	a3,a3,354 # ffffffffc0206dc8 <default_pmm_manager+0x8e0>
ffffffffc0203c6e:	00002617          	auipc	a2,0x2
ffffffffc0203c72:	4ca60613          	addi	a2,a2,1226 # ffffffffc0206138 <commands+0x828>
ffffffffc0203c76:	14600593          	li	a1,326
ffffffffc0203c7a:	00003517          	auipc	a0,0x3
ffffffffc0203c7e:	01650513          	addi	a0,a0,22 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203c82:	80dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203c86:	00003697          	auipc	a3,0x3
ffffffffc0203c8a:	13268693          	addi	a3,a3,306 # ffffffffc0206db8 <default_pmm_manager+0x8d0>
ffffffffc0203c8e:	00002617          	auipc	a2,0x2
ffffffffc0203c92:	4aa60613          	addi	a2,a2,1194 # ffffffffc0206138 <commands+0x828>
ffffffffc0203c96:	14400593          	li	a1,324
ffffffffc0203c9a:	00003517          	auipc	a0,0x3
ffffffffc0203c9e:	ff650513          	addi	a0,a0,-10 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203ca2:	fecfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203ca6:	00003697          	auipc	a3,0x3
ffffffffc0203caa:	13268693          	addi	a3,a3,306 # ffffffffc0206dd8 <default_pmm_manager+0x8f0>
ffffffffc0203cae:	00002617          	auipc	a2,0x2
ffffffffc0203cb2:	48a60613          	addi	a2,a2,1162 # ffffffffc0206138 <commands+0x828>
ffffffffc0203cb6:	14800593          	li	a1,328
ffffffffc0203cba:	00003517          	auipc	a0,0x3
ffffffffc0203cbe:	fd650513          	addi	a0,a0,-42 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203cc2:	fccfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203cc6:	00003697          	auipc	a3,0x3
ffffffffc0203cca:	13268693          	addi	a3,a3,306 # ffffffffc0206df8 <default_pmm_manager+0x910>
ffffffffc0203cce:	00002617          	auipc	a2,0x2
ffffffffc0203cd2:	46a60613          	addi	a2,a2,1130 # ffffffffc0206138 <commands+0x828>
ffffffffc0203cd6:	14c00593          	li	a1,332
ffffffffc0203cda:	00003517          	auipc	a0,0x3
ffffffffc0203cde:	fb650513          	addi	a0,a0,-74 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203ce2:	facfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203ce6:	00003697          	auipc	a3,0x3
ffffffffc0203cea:	10268693          	addi	a3,a3,258 # ffffffffc0206de8 <default_pmm_manager+0x900>
ffffffffc0203cee:	00002617          	auipc	a2,0x2
ffffffffc0203cf2:	44a60613          	addi	a2,a2,1098 # ffffffffc0206138 <commands+0x828>
ffffffffc0203cf6:	14a00593          	li	a1,330
ffffffffc0203cfa:	00003517          	auipc	a0,0x3
ffffffffc0203cfe:	f9650513          	addi	a0,a0,-106 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203d02:	f8cfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203d06:	00003697          	auipc	a3,0x3
ffffffffc0203d0a:	01268693          	addi	a3,a3,18 # ffffffffc0206d18 <default_pmm_manager+0x830>
ffffffffc0203d0e:	00002617          	auipc	a2,0x2
ffffffffc0203d12:	42a60613          	addi	a2,a2,1066 # ffffffffc0206138 <commands+0x828>
ffffffffc0203d16:	12400593          	li	a1,292
ffffffffc0203d1a:	00003517          	auipc	a0,0x3
ffffffffc0203d1e:	f7650513          	addi	a0,a0,-138 # ffffffffc0206c90 <default_pmm_manager+0x7a8>
ffffffffc0203d22:	f6cfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d26 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d26:	7179                	addi	sp,sp,-48
ffffffffc0203d28:	f022                	sd	s0,32(sp)
ffffffffc0203d2a:	f406                	sd	ra,40(sp)
ffffffffc0203d2c:	ec26                	sd	s1,24(sp)
ffffffffc0203d2e:	e84a                	sd	s2,16(sp)
ffffffffc0203d30:	e44e                	sd	s3,8(sp)
ffffffffc0203d32:	e052                	sd	s4,0(sp)
ffffffffc0203d34:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d36:	c135                	beqz	a0,ffffffffc0203d9a <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d38:	002007b7          	lui	a5,0x200
ffffffffc0203d3c:	04f5e663          	bltu	a1,a5,ffffffffc0203d88 <user_mem_check+0x62>
ffffffffc0203d40:	00c584b3          	add	s1,a1,a2
ffffffffc0203d44:	0495f263          	bgeu	a1,s1,ffffffffc0203d88 <user_mem_check+0x62>
ffffffffc0203d48:	4785                	li	a5,1
ffffffffc0203d4a:	07fe                	slli	a5,a5,0x1f
ffffffffc0203d4c:	0297ee63          	bltu	a5,s1,ffffffffc0203d88 <user_mem_check+0x62>
ffffffffc0203d50:	892a                	mv	s2,a0
ffffffffc0203d52:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d54:	6a05                	lui	s4,0x1
ffffffffc0203d56:	a821                	j	ffffffffc0203d6e <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d58:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d5c:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d5e:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d60:	c685                	beqz	a3,ffffffffc0203d88 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d62:	c399                	beqz	a5,ffffffffc0203d68 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d64:	02e46263          	bltu	s0,a4,ffffffffc0203d88 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203d68:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203d6a:	04947663          	bgeu	s0,s1,ffffffffc0203db6 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203d6e:	85a2                	mv	a1,s0
ffffffffc0203d70:	854a                	mv	a0,s2
ffffffffc0203d72:	96fff0ef          	jal	ra,ffffffffc02036e0 <find_vma>
ffffffffc0203d76:	c909                	beqz	a0,ffffffffc0203d88 <user_mem_check+0x62>
ffffffffc0203d78:	6518                	ld	a4,8(a0)
ffffffffc0203d7a:	00e46763          	bltu	s0,a4,ffffffffc0203d88 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d7e:	4d1c                	lw	a5,24(a0)
ffffffffc0203d80:	fc099ce3          	bnez	s3,ffffffffc0203d58 <user_mem_check+0x32>
ffffffffc0203d84:	8b85                	andi	a5,a5,1
ffffffffc0203d86:	f3ed                	bnez	a5,ffffffffc0203d68 <user_mem_check+0x42>
            return 0;
ffffffffc0203d88:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d8a:	70a2                	ld	ra,40(sp)
ffffffffc0203d8c:	7402                	ld	s0,32(sp)
ffffffffc0203d8e:	64e2                	ld	s1,24(sp)
ffffffffc0203d90:	6942                	ld	s2,16(sp)
ffffffffc0203d92:	69a2                	ld	s3,8(sp)
ffffffffc0203d94:	6a02                	ld	s4,0(sp)
ffffffffc0203d96:	6145                	addi	sp,sp,48
ffffffffc0203d98:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d9a:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d9e:	4501                	li	a0,0
ffffffffc0203da0:	fef5e5e3          	bltu	a1,a5,ffffffffc0203d8a <user_mem_check+0x64>
ffffffffc0203da4:	962e                	add	a2,a2,a1
ffffffffc0203da6:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203d8a <user_mem_check+0x64>
ffffffffc0203daa:	c8000537          	lui	a0,0xc8000
ffffffffc0203dae:	0505                	addi	a0,a0,1
ffffffffc0203db0:	00a63533          	sltu	a0,a2,a0
ffffffffc0203db4:	bfd9                	j	ffffffffc0203d8a <user_mem_check+0x64>
        return 1;
ffffffffc0203db6:	4505                	li	a0,1
ffffffffc0203db8:	bfc9                	j	ffffffffc0203d8a <user_mem_check+0x64>

ffffffffc0203dba <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203dba:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203dbc:	9402                	jalr	s0

	jal do_exit
ffffffffc0203dbe:	5ee000ef          	jal	ra,ffffffffc02043ac <do_exit>

ffffffffc0203dc2 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203dc2:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203dc4:	10800513          	li	a0,264
{
ffffffffc0203dc8:	e022                	sd	s0,0(sp)
ffffffffc0203dca:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203dcc:	ee3fd0ef          	jal	ra,ffffffffc0201cae <kmalloc>
ffffffffc0203dd0:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203dd2:	cd05                	beqz	a0,ffffffffc0203e0a <alloc_proc+0x48>
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
         //先把整个结构体清零,后面的context和name就不需要单独考虑了，
        memset(proc, 0, sizeof(struct proc_struct));
ffffffffc0203dd4:	10800613          	li	a2,264
ffffffffc0203dd8:	4581                	li	a1,0
ffffffffc0203dda:	09f010ef          	jal	ra,ffffffffc0205678 <memset>

        //再显式设置必须的初值 
        proc->state         = PROC_UNINIT;   
ffffffffc0203dde:	57fd                	li	a5,-1
ffffffffc0203de0:	1782                	slli	a5,a5,0x20
ffffffffc0203de2:	e01c                	sd	a5,0(s0)
        proc->kstack        = 0;
        proc->need_resched  = 0;
        proc->parent        = NULL;
        proc->mm            = NULL;
        proc->tf            = NULL;
        proc->pgdir         = boot_pgdir_pa;  // 设置为 boot_pgdir_pa 而非 0
ffffffffc0203de4:	000a6797          	auipc	a5,0xa6
ffffffffc0203de8:	7d47b783          	ld	a5,2004(a5) # ffffffffc02aa5b8 <boot_pgdir_pa>
        proc->runs          = 0;
ffffffffc0203dec:	00042423          	sw	zero,8(s0)
        proc->kstack        = 0;
ffffffffc0203df0:	00043823          	sd	zero,16(s0)
        proc->need_resched  = 0;
ffffffffc0203df4:	00043c23          	sd	zero,24(s0)
        proc->parent        = NULL;
ffffffffc0203df8:	02043023          	sd	zero,32(s0)
        proc->mm            = NULL;
ffffffffc0203dfc:	02043423          	sd	zero,40(s0)
        proc->tf            = NULL;
ffffffffc0203e00:	0a043023          	sd	zero,160(s0)
        proc->pgdir         = boot_pgdir_pa;  // 设置为 boot_pgdir_pa 而非 0
ffffffffc0203e04:	f45c                	sd	a5,168(s0)
        proc->flags         = 0;
ffffffffc0203e06:	0a042823          	sw	zero,176(s0)
    }
    return proc;
}
ffffffffc0203e0a:	60a2                	ld	ra,8(sp)
ffffffffc0203e0c:	8522                	mv	a0,s0
ffffffffc0203e0e:	6402                	ld	s0,0(sp)
ffffffffc0203e10:	0141                	addi	sp,sp,16
ffffffffc0203e12:	8082                	ret

ffffffffc0203e14 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e14:	000a6797          	auipc	a5,0xa6
ffffffffc0203e18:	7d47b783          	ld	a5,2004(a5) # ffffffffc02aa5e8 <current>
ffffffffc0203e1c:	73c8                	ld	a0,160(a5)
ffffffffc0203e1e:	904fd06f          	j	ffffffffc0200f22 <forkrets>

ffffffffc0203e22 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e22:	000a6797          	auipc	a5,0xa6
ffffffffc0203e26:	7c67b783          	ld	a5,1990(a5) # ffffffffc02aa5e8 <current>
ffffffffc0203e2a:	43cc                	lw	a1,4(a5)
{
ffffffffc0203e2c:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e2e:	00003617          	auipc	a2,0x3
ffffffffc0203e32:	0c260613          	addi	a2,a2,194 # ffffffffc0206ef0 <default_pmm_manager+0xa08>
ffffffffc0203e36:	00003517          	auipc	a0,0x3
ffffffffc0203e3a:	0c250513          	addi	a0,a0,194 # ffffffffc0206ef8 <default_pmm_manager+0xa10>
{
ffffffffc0203e3e:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e40:	b54fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203e44:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203e48:	74478793          	addi	a5,a5,1860 # a588 <_binary_obj___user_divzero_out_size>
ffffffffc0203e4c:	e43e                	sd	a5,8(sp)
ffffffffc0203e4e:	00003517          	auipc	a0,0x3
ffffffffc0203e52:	0a250513          	addi	a0,a0,162 # ffffffffc0206ef0 <default_pmm_manager+0xa08>
ffffffffc0203e56:	0001c797          	auipc	a5,0x1c
ffffffffc0203e5a:	10278793          	addi	a5,a5,258 # ffffffffc021ff58 <_binary_obj___user_divzero_out_start>
ffffffffc0203e5e:	f03e                	sd	a5,32(sp)
ffffffffc0203e60:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203e62:	e802                	sd	zero,16(sp)
ffffffffc0203e64:	772010ef          	jal	ra,ffffffffc02055d6 <strlen>
ffffffffc0203e68:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203e6a:	4511                	li	a0,4
ffffffffc0203e6c:	55a2                	lw	a1,40(sp)
ffffffffc0203e6e:	4662                	lw	a2,24(sp)
ffffffffc0203e70:	5682                	lw	a3,32(sp)
ffffffffc0203e72:	4722                	lw	a4,8(sp)
ffffffffc0203e74:	48a9                	li	a7,10
ffffffffc0203e76:	9002                	ebreak
ffffffffc0203e78:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203e7a:	65c2                	ld	a1,16(sp)
ffffffffc0203e7c:	00003517          	auipc	a0,0x3
ffffffffc0203e80:	0a450513          	addi	a0,a0,164 # ffffffffc0206f20 <default_pmm_manager+0xa38>
ffffffffc0203e84:	b10fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203e88:	00003617          	auipc	a2,0x3
ffffffffc0203e8c:	0a860613          	addi	a2,a2,168 # ffffffffc0206f30 <default_pmm_manager+0xa48>
ffffffffc0203e90:	3c000593          	li	a1,960
ffffffffc0203e94:	00003517          	auipc	a0,0x3
ffffffffc0203e98:	0bc50513          	addi	a0,a0,188 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0203e9c:	df2fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ea0 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203ea0:	6d14                	ld	a3,24(a0)
{
ffffffffc0203ea2:	1141                	addi	sp,sp,-16
ffffffffc0203ea4:	e406                	sd	ra,8(sp)
ffffffffc0203ea6:	c02007b7          	lui	a5,0xc0200
ffffffffc0203eaa:	02f6ee63          	bltu	a3,a5,ffffffffc0203ee6 <put_pgdir+0x46>
ffffffffc0203eae:	000a6517          	auipc	a0,0xa6
ffffffffc0203eb2:	73253503          	ld	a0,1842(a0) # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0203eb6:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203eb8:	82b1                	srli	a3,a3,0xc
ffffffffc0203eba:	000a6797          	auipc	a5,0xa6
ffffffffc0203ebe:	70e7b783          	ld	a5,1806(a5) # ffffffffc02aa5c8 <npage>
ffffffffc0203ec2:	02f6fe63          	bgeu	a3,a5,ffffffffc0203efe <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ec6:	00004517          	auipc	a0,0x4
ffffffffc0203eca:	92253503          	ld	a0,-1758(a0) # ffffffffc02077e8 <nbase>
}
ffffffffc0203ece:	60a2                	ld	ra,8(sp)
ffffffffc0203ed0:	8e89                	sub	a3,a3,a0
ffffffffc0203ed2:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203ed4:	000a6517          	auipc	a0,0xa6
ffffffffc0203ed8:	6fc53503          	ld	a0,1788(a0) # ffffffffc02aa5d0 <pages>
ffffffffc0203edc:	4585                	li	a1,1
ffffffffc0203ede:	9536                	add	a0,a0,a3
}
ffffffffc0203ee0:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203ee2:	fe9fd06f          	j	ffffffffc0201eca <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203ee6:	00002617          	auipc	a2,0x2
ffffffffc0203eea:	6e260613          	addi	a2,a2,1762 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc0203eee:	07700593          	li	a1,119
ffffffffc0203ef2:	00002517          	auipc	a0,0x2
ffffffffc0203ef6:	65650513          	addi	a0,a0,1622 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0203efa:	d94fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203efe:	00002617          	auipc	a2,0x2
ffffffffc0203f02:	6f260613          	addi	a2,a2,1778 # ffffffffc02065f0 <default_pmm_manager+0x108>
ffffffffc0203f06:	06900593          	li	a1,105
ffffffffc0203f0a:	00002517          	auipc	a0,0x2
ffffffffc0203f0e:	63e50513          	addi	a0,a0,1598 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0203f12:	d7cfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f16 <proc_run>:
{
ffffffffc0203f16:	7179                	addi	sp,sp,-48
ffffffffc0203f18:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203f1a:	000a6497          	auipc	s1,0xa6
ffffffffc0203f1e:	6ce48493          	addi	s1,s1,1742 # ffffffffc02aa5e8 <current>
ffffffffc0203f22:	6098                	ld	a4,0(s1)
{
ffffffffc0203f24:	f406                	sd	ra,40(sp)
ffffffffc0203f26:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203f28:	02a70963          	beq	a4,a0,ffffffffc0203f5a <proc_run+0x44>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f2c:	100027f3          	csrr	a5,sstatus
ffffffffc0203f30:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f32:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f34:	ef95                	bnez	a5,ffffffffc0203f70 <proc_run+0x5a>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203f36:	755c                	ld	a5,168(a0)
ffffffffc0203f38:	56fd                	li	a3,-1
ffffffffc0203f3a:	16fe                	slli	a3,a3,0x3f
ffffffffc0203f3c:	83b1                	srli	a5,a5,0xc
        current = proc;
ffffffffc0203f3e:	e088                	sd	a0,0(s1)
        proc->need_resched = 0;
ffffffffc0203f40:	00053c23          	sd	zero,24(a0)
ffffffffc0203f44:	8fd5                	or	a5,a5,a3
ffffffffc0203f46:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &proc->context);
ffffffffc0203f4a:	03050593          	addi	a1,a0,48
ffffffffc0203f4e:	03070513          	addi	a0,a4,48
ffffffffc0203f52:	02a010ef          	jal	ra,ffffffffc0204f7c <switch_to>
    if (flag)
ffffffffc0203f56:	00091763          	bnez	s2,ffffffffc0203f64 <proc_run+0x4e>
}
ffffffffc0203f5a:	70a2                	ld	ra,40(sp)
ffffffffc0203f5c:	7482                	ld	s1,32(sp)
ffffffffc0203f5e:	6962                	ld	s2,24(sp)
ffffffffc0203f60:	6145                	addi	sp,sp,48
ffffffffc0203f62:	8082                	ret
ffffffffc0203f64:	70a2                	ld	ra,40(sp)
ffffffffc0203f66:	7482                	ld	s1,32(sp)
ffffffffc0203f68:	6962                	ld	s2,24(sp)
ffffffffc0203f6a:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203f6c:	a43fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0203f70:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203f72:	a43fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc0203f76:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0203f78:	6522                	ld	a0,8(sp)
ffffffffc0203f7a:	4905                	li	s2,1
ffffffffc0203f7c:	bf6d                	j	ffffffffc0203f36 <proc_run+0x20>

ffffffffc0203f7e <do_fork>:
{
ffffffffc0203f7e:	7119                	addi	sp,sp,-128
ffffffffc0203f80:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203f82:	000a6917          	auipc	s2,0xa6
ffffffffc0203f86:	67e90913          	addi	s2,s2,1662 # ffffffffc02aa600 <nr_process>
ffffffffc0203f8a:	00092703          	lw	a4,0(s2)
{
ffffffffc0203f8e:	fc86                	sd	ra,120(sp)
ffffffffc0203f90:	f8a2                	sd	s0,112(sp)
ffffffffc0203f92:	f4a6                	sd	s1,104(sp)
ffffffffc0203f94:	ecce                	sd	s3,88(sp)
ffffffffc0203f96:	e8d2                	sd	s4,80(sp)
ffffffffc0203f98:	e4d6                	sd	s5,72(sp)
ffffffffc0203f9a:	e0da                	sd	s6,64(sp)
ffffffffc0203f9c:	fc5e                	sd	s7,56(sp)
ffffffffc0203f9e:	f862                	sd	s8,48(sp)
ffffffffc0203fa0:	f466                	sd	s9,40(sp)
ffffffffc0203fa2:	f06a                	sd	s10,32(sp)
ffffffffc0203fa4:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203fa6:	6785                	lui	a5,0x1
ffffffffc0203fa8:	32f75863          	bge	a4,a5,ffffffffc02042d8 <do_fork+0x35a>
ffffffffc0203fac:	8a2a                	mv	s4,a0
ffffffffc0203fae:	89ae                	mv	s3,a1
ffffffffc0203fb0:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0203fb2:	e11ff0ef          	jal	ra,ffffffffc0203dc2 <alloc_proc>
ffffffffc0203fb6:	84aa                	mv	s1,a0
ffffffffc0203fb8:	30050163          	beqz	a0,ffffffffc02042ba <do_fork+0x33c>
    proc->parent = current;
ffffffffc0203fbc:	000a6c17          	auipc	s8,0xa6
ffffffffc0203fc0:	62cc0c13          	addi	s8,s8,1580 # ffffffffc02aa5e8 <current>
ffffffffc0203fc4:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203fc8:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203fca:	f09c                	sd	a5,32(s1)
    current->wait_state = 0;
ffffffffc0203fcc:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8aac>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203fd0:	ebdfd0ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
    if (page != NULL)
ffffffffc0203fd4:	2e050063          	beqz	a0,ffffffffc02042b4 <do_fork+0x336>
    return page - pages + nbase;
ffffffffc0203fd8:	000a6a97          	auipc	s5,0xa6
ffffffffc0203fdc:	5f8a8a93          	addi	s5,s5,1528 # ffffffffc02aa5d0 <pages>
ffffffffc0203fe0:	000ab683          	ld	a3,0(s5)
ffffffffc0203fe4:	00004b17          	auipc	s6,0x4
ffffffffc0203fe8:	804b0b13          	addi	s6,s6,-2044 # ffffffffc02077e8 <nbase>
ffffffffc0203fec:	000b3783          	ld	a5,0(s6)
ffffffffc0203ff0:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203ff4:	000a6b97          	auipc	s7,0xa6
ffffffffc0203ff8:	5d4b8b93          	addi	s7,s7,1492 # ffffffffc02aa5c8 <npage>
    return page - pages + nbase;
ffffffffc0203ffc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203ffe:	5dfd                	li	s11,-1
ffffffffc0204000:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204004:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204006:	00cddd93          	srli	s11,s11,0xc
ffffffffc020400a:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020400e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204010:	32e67a63          	bgeu	a2,a4,ffffffffc0204344 <do_fork+0x3c6>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204014:	000c3603          	ld	a2,0(s8)
ffffffffc0204018:	000a6c17          	auipc	s8,0xa6
ffffffffc020401c:	5c8c0c13          	addi	s8,s8,1480 # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0204020:	000c3703          	ld	a4,0(s8)
ffffffffc0204024:	02863d03          	ld	s10,40(a2)
ffffffffc0204028:	e43e                	sd	a5,8(sp)
ffffffffc020402a:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020402c:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc020402e:	020d0863          	beqz	s10,ffffffffc020405e <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc0204032:	100a7a13          	andi	s4,s4,256
ffffffffc0204036:	1c0a0163          	beqz	s4,ffffffffc02041f8 <do_fork+0x27a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020403a:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020403e:	018d3783          	ld	a5,24(s10)
ffffffffc0204042:	c02006b7          	lui	a3,0xc0200
ffffffffc0204046:	2705                	addiw	a4,a4,1
ffffffffc0204048:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc020404c:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204050:	2cd7e163          	bltu	a5,a3,ffffffffc0204312 <do_fork+0x394>
ffffffffc0204054:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204058:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020405a:	8f99                	sub	a5,a5,a4
ffffffffc020405c:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020405e:	6789                	lui	a5,0x2
ffffffffc0204060:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cb8>
ffffffffc0204064:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204066:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204068:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020406a:	87b6                	mv	a5,a3
ffffffffc020406c:	12040893          	addi	a7,s0,288
ffffffffc0204070:	00063803          	ld	a6,0(a2)
ffffffffc0204074:	6608                	ld	a0,8(a2)
ffffffffc0204076:	6a0c                	ld	a1,16(a2)
ffffffffc0204078:	6e18                	ld	a4,24(a2)
ffffffffc020407a:	0107b023          	sd	a6,0(a5)
ffffffffc020407e:	e788                	sd	a0,8(a5)
ffffffffc0204080:	eb8c                	sd	a1,16(a5)
ffffffffc0204082:	ef98                	sd	a4,24(a5)
ffffffffc0204084:	02060613          	addi	a2,a2,32
ffffffffc0204088:	02078793          	addi	a5,a5,32
ffffffffc020408c:	ff1612e3          	bne	a2,a7,ffffffffc0204070 <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc0204090:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204094:	12098f63          	beqz	s3,ffffffffc02041d2 <do_fork+0x254>
ffffffffc0204098:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020409c:	00000797          	auipc	a5,0x0
ffffffffc02040a0:	d7878793          	addi	a5,a5,-648 # ffffffffc0203e14 <forkret>
ffffffffc02040a4:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02040a6:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040a8:	100027f3          	csrr	a5,sstatus
ffffffffc02040ac:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040ae:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040b0:	14079063          	bnez	a5,ffffffffc02041f0 <do_fork+0x272>
    if (++last_pid >= MAX_PID)
ffffffffc02040b4:	000a2817          	auipc	a6,0xa2
ffffffffc02040b8:	0a480813          	addi	a6,a6,164 # ffffffffc02a6158 <last_pid.1>
ffffffffc02040bc:	00082783          	lw	a5,0(a6)
ffffffffc02040c0:	6709                	lui	a4,0x2
ffffffffc02040c2:	0017851b          	addiw	a0,a5,1
ffffffffc02040c6:	00a82023          	sw	a0,0(a6)
ffffffffc02040ca:	08e55d63          	bge	a0,a4,ffffffffc0204164 <do_fork+0x1e6>
    if (last_pid >= next_safe)
ffffffffc02040ce:	000a2317          	auipc	t1,0xa2
ffffffffc02040d2:	08e30313          	addi	t1,t1,142 # ffffffffc02a615c <next_safe.0>
ffffffffc02040d6:	00032783          	lw	a5,0(t1)
ffffffffc02040da:	000a6417          	auipc	s0,0xa6
ffffffffc02040de:	49e40413          	addi	s0,s0,1182 # ffffffffc02aa578 <proc_list>
ffffffffc02040e2:	08f55963          	bge	a0,a5,ffffffffc0204174 <do_fork+0x1f6>
        proc->pid = get_pid();
ffffffffc02040e6:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02040e8:	45a9                	li	a1,10
ffffffffc02040ea:	2501                	sext.w	a0,a0
ffffffffc02040ec:	0e6010ef          	jal	ra,ffffffffc02051d2 <hash32>
ffffffffc02040f0:	02051793          	slli	a5,a0,0x20
ffffffffc02040f4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02040f8:	000a2797          	auipc	a5,0xa2
ffffffffc02040fc:	48078793          	addi	a5,a5,1152 # ffffffffc02a6578 <hash_list>
ffffffffc0204100:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204102:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204104:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204106:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020410a:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020410c:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc020410e:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204110:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204112:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204116:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0204118:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020411a:	e21c                	sd	a5,0(a2)
ffffffffc020411c:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc020411e:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204120:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204122:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204126:	10e4b023          	sd	a4,256(s1)
ffffffffc020412a:	c311                	beqz	a4,ffffffffc020412e <do_fork+0x1b0>
        proc->optr->yptr = proc;
ffffffffc020412c:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc020412e:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204132:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204134:	2785                	addiw	a5,a5,1
ffffffffc0204136:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc020413a:	18099263          	bnez	s3,ffffffffc02042be <do_fork+0x340>
    wakeup_proc(proc);
ffffffffc020413e:	8526                	mv	a0,s1
ffffffffc0204140:	6a7000ef          	jal	ra,ffffffffc0204fe6 <wakeup_proc>
    ret = proc->pid;
ffffffffc0204144:	40c8                	lw	a0,4(s1)
}
ffffffffc0204146:	70e6                	ld	ra,120(sp)
ffffffffc0204148:	7446                	ld	s0,112(sp)
ffffffffc020414a:	74a6                	ld	s1,104(sp)
ffffffffc020414c:	7906                	ld	s2,96(sp)
ffffffffc020414e:	69e6                	ld	s3,88(sp)
ffffffffc0204150:	6a46                	ld	s4,80(sp)
ffffffffc0204152:	6aa6                	ld	s5,72(sp)
ffffffffc0204154:	6b06                	ld	s6,64(sp)
ffffffffc0204156:	7be2                	ld	s7,56(sp)
ffffffffc0204158:	7c42                	ld	s8,48(sp)
ffffffffc020415a:	7ca2                	ld	s9,40(sp)
ffffffffc020415c:	7d02                	ld	s10,32(sp)
ffffffffc020415e:	6de2                	ld	s11,24(sp)
ffffffffc0204160:	6109                	addi	sp,sp,128
ffffffffc0204162:	8082                	ret
        last_pid = 1;
ffffffffc0204164:	4785                	li	a5,1
ffffffffc0204166:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020416a:	4505                	li	a0,1
ffffffffc020416c:	000a2317          	auipc	t1,0xa2
ffffffffc0204170:	ff030313          	addi	t1,t1,-16 # ffffffffc02a615c <next_safe.0>
    return listelm->next;
ffffffffc0204174:	000a6417          	auipc	s0,0xa6
ffffffffc0204178:	40440413          	addi	s0,s0,1028 # ffffffffc02aa578 <proc_list>
ffffffffc020417c:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204180:	6789                	lui	a5,0x2
ffffffffc0204182:	00f32023          	sw	a5,0(t1)
ffffffffc0204186:	86aa                	mv	a3,a0
ffffffffc0204188:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020418a:	6e89                	lui	t4,0x2
ffffffffc020418c:	148e0163          	beq	t3,s0,ffffffffc02042ce <do_fork+0x350>
ffffffffc0204190:	88ae                	mv	a7,a1
ffffffffc0204192:	87f2                	mv	a5,t3
ffffffffc0204194:	6609                	lui	a2,0x2
ffffffffc0204196:	a811                	j	ffffffffc02041aa <do_fork+0x22c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204198:	00e6d663          	bge	a3,a4,ffffffffc02041a4 <do_fork+0x226>
ffffffffc020419c:	00c75463          	bge	a4,a2,ffffffffc02041a4 <do_fork+0x226>
ffffffffc02041a0:	863a                	mv	a2,a4
ffffffffc02041a2:	4885                	li	a7,1
ffffffffc02041a4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02041a6:	00878d63          	beq	a5,s0,ffffffffc02041c0 <do_fork+0x242>
            if (proc->pid == last_pid)
ffffffffc02041aa:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c5c>
ffffffffc02041ae:	fed715e3          	bne	a4,a3,ffffffffc0204198 <do_fork+0x21a>
                if (++last_pid >= next_safe)
ffffffffc02041b2:	2685                	addiw	a3,a3,1
ffffffffc02041b4:	10c6d863          	bge	a3,a2,ffffffffc02042c4 <do_fork+0x346>
ffffffffc02041b8:	679c                	ld	a5,8(a5)
ffffffffc02041ba:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041bc:	fe8797e3          	bne	a5,s0,ffffffffc02041aa <do_fork+0x22c>
ffffffffc02041c0:	c581                	beqz	a1,ffffffffc02041c8 <do_fork+0x24a>
ffffffffc02041c2:	00d82023          	sw	a3,0(a6)
ffffffffc02041c6:	8536                	mv	a0,a3
ffffffffc02041c8:	f0088fe3          	beqz	a7,ffffffffc02040e6 <do_fork+0x168>
ffffffffc02041cc:	00c32023          	sw	a2,0(t1)
ffffffffc02041d0:	bf19                	j	ffffffffc02040e6 <do_fork+0x168>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02041d2:	89b6                	mv	s3,a3
ffffffffc02041d4:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02041d8:	00000797          	auipc	a5,0x0
ffffffffc02041dc:	c3c78793          	addi	a5,a5,-964 # ffffffffc0203e14 <forkret>
ffffffffc02041e0:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02041e2:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041e4:	100027f3          	csrr	a5,sstatus
ffffffffc02041e8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02041ea:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041ec:	ec0784e3          	beqz	a5,ffffffffc02040b4 <do_fork+0x136>
        intr_disable();
ffffffffc02041f0:	fc4fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02041f4:	4985                	li	s3,1
ffffffffc02041f6:	bd7d                	j	ffffffffc02040b4 <do_fork+0x136>
    if ((mm = mm_create()) == NULL)
ffffffffc02041f8:	cb8ff0ef          	jal	ra,ffffffffc02036b0 <mm_create>
ffffffffc02041fc:	8caa                	mv	s9,a0
ffffffffc02041fe:	c159                	beqz	a0,ffffffffc0204284 <do_fork+0x306>
    if ((page = alloc_page()) == NULL)
ffffffffc0204200:	4505                	li	a0,1
ffffffffc0204202:	c8bfd0ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0204206:	cd25                	beqz	a0,ffffffffc020427e <do_fork+0x300>
    return page - pages + nbase;
ffffffffc0204208:	000ab683          	ld	a3,0(s5)
ffffffffc020420c:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc020420e:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204212:	40d506b3          	sub	a3,a0,a3
ffffffffc0204216:	8699                	srai	a3,a3,0x6
ffffffffc0204218:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020421a:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020421e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204220:	12edf263          	bgeu	s11,a4,ffffffffc0204344 <do_fork+0x3c6>
ffffffffc0204224:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204228:	6605                	lui	a2,0x1
ffffffffc020422a:	000a6597          	auipc	a1,0xa6
ffffffffc020422e:	3965b583          	ld	a1,918(a1) # ffffffffc02aa5c0 <boot_pgdir_va>
ffffffffc0204232:	9a36                	add	s4,s4,a3
ffffffffc0204234:	8552                	mv	a0,s4
ffffffffc0204236:	454010ef          	jal	ra,ffffffffc020568a <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020423a:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc020423e:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204242:	4785                	li	a5,1
ffffffffc0204244:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204248:	8b85                	andi	a5,a5,1
ffffffffc020424a:	4a05                	li	s4,1
ffffffffc020424c:	c799                	beqz	a5,ffffffffc020425a <do_fork+0x2dc>
    {
        schedule();
ffffffffc020424e:	619000ef          	jal	ra,ffffffffc0205066 <schedule>
ffffffffc0204252:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc0204256:	8b85                	andi	a5,a5,1
ffffffffc0204258:	fbfd                	bnez	a5,ffffffffc020424e <do_fork+0x2d0>
        ret = dup_mmap(mm, oldmm);
ffffffffc020425a:	85ea                	mv	a1,s10
ffffffffc020425c:	8566                	mv	a0,s9
ffffffffc020425e:	e94ff0ef          	jal	ra,ffffffffc02038f2 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204262:	57f9                	li	a5,-2
ffffffffc0204264:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204268:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020426a:	cfa5                	beqz	a5,ffffffffc02042e2 <do_fork+0x364>
good_mm:
ffffffffc020426c:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc020426e:	dc0506e3          	beqz	a0,ffffffffc020403a <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc0204272:	8566                	mv	a0,s9
ffffffffc0204274:	f18ff0ef          	jal	ra,ffffffffc020398c <exit_mmap>
    put_pgdir(mm);
ffffffffc0204278:	8566                	mv	a0,s9
ffffffffc020427a:	c27ff0ef          	jal	ra,ffffffffc0203ea0 <put_pgdir>
    mm_destroy(mm);
ffffffffc020427e:	8566                	mv	a0,s9
ffffffffc0204280:	d70ff0ef          	jal	ra,ffffffffc02037f0 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204284:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204286:	c02007b7          	lui	a5,0xc0200
ffffffffc020428a:	0af6e163          	bltu	a3,a5,ffffffffc020432c <do_fork+0x3ae>
ffffffffc020428e:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204292:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0204296:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020429a:	83b1                	srli	a5,a5,0xc
ffffffffc020429c:	04e7ff63          	bgeu	a5,a4,ffffffffc02042fa <do_fork+0x37c>
    return &pages[PPN(pa) - nbase];
ffffffffc02042a0:	000b3703          	ld	a4,0(s6)
ffffffffc02042a4:	000ab503          	ld	a0,0(s5)
ffffffffc02042a8:	4589                	li	a1,2
ffffffffc02042aa:	8f99                	sub	a5,a5,a4
ffffffffc02042ac:	079a                	slli	a5,a5,0x6
ffffffffc02042ae:	953e                	add	a0,a0,a5
ffffffffc02042b0:	c1bfd0ef          	jal	ra,ffffffffc0201eca <free_pages>
    kfree(proc);
ffffffffc02042b4:	8526                	mv	a0,s1
ffffffffc02042b6:	aa9fd0ef          	jal	ra,ffffffffc0201d5e <kfree>
    ret = -E_NO_MEM;
ffffffffc02042ba:	5571                	li	a0,-4
    return ret;
ffffffffc02042bc:	b569                	j	ffffffffc0204146 <do_fork+0x1c8>
        intr_enable();
ffffffffc02042be:	ef0fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02042c2:	bdb5                	j	ffffffffc020413e <do_fork+0x1c0>
                    if (last_pid >= MAX_PID)
ffffffffc02042c4:	01d6c363          	blt	a3,t4,ffffffffc02042ca <do_fork+0x34c>
                        last_pid = 1;
ffffffffc02042c8:	4685                	li	a3,1
                    goto repeat;
ffffffffc02042ca:	4585                	li	a1,1
ffffffffc02042cc:	b5c1                	j	ffffffffc020418c <do_fork+0x20e>
ffffffffc02042ce:	c599                	beqz	a1,ffffffffc02042dc <do_fork+0x35e>
ffffffffc02042d0:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02042d4:	8536                	mv	a0,a3
ffffffffc02042d6:	bd01                	j	ffffffffc02040e6 <do_fork+0x168>
    int ret = -E_NO_FREE_PROC;
ffffffffc02042d8:	556d                	li	a0,-5
ffffffffc02042da:	b5b5                	j	ffffffffc0204146 <do_fork+0x1c8>
    return last_pid;
ffffffffc02042dc:	00082503          	lw	a0,0(a6)
ffffffffc02042e0:	b519                	j	ffffffffc02040e6 <do_fork+0x168>
    {
        panic("Unlock failed.\n");
ffffffffc02042e2:	00003617          	auipc	a2,0x3
ffffffffc02042e6:	c8660613          	addi	a2,a2,-890 # ffffffffc0206f68 <default_pmm_manager+0xa80>
ffffffffc02042ea:	03f00593          	li	a1,63
ffffffffc02042ee:	00003517          	auipc	a0,0x3
ffffffffc02042f2:	c8a50513          	addi	a0,a0,-886 # ffffffffc0206f78 <default_pmm_manager+0xa90>
ffffffffc02042f6:	998fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02042fa:	00002617          	auipc	a2,0x2
ffffffffc02042fe:	2f660613          	addi	a2,a2,758 # ffffffffc02065f0 <default_pmm_manager+0x108>
ffffffffc0204302:	06900593          	li	a1,105
ffffffffc0204306:	00002517          	auipc	a0,0x2
ffffffffc020430a:	24250513          	addi	a0,a0,578 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc020430e:	980fc0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204312:	86be                	mv	a3,a5
ffffffffc0204314:	00002617          	auipc	a2,0x2
ffffffffc0204318:	2b460613          	addi	a2,a2,692 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc020431c:	19700593          	li	a1,407
ffffffffc0204320:	00003517          	auipc	a0,0x3
ffffffffc0204324:	c3050513          	addi	a0,a0,-976 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204328:	966fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc020432c:	00002617          	auipc	a2,0x2
ffffffffc0204330:	29c60613          	addi	a2,a2,668 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc0204334:	07700593          	li	a1,119
ffffffffc0204338:	00002517          	auipc	a0,0x2
ffffffffc020433c:	21050513          	addi	a0,a0,528 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0204340:	94efc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204344:	00002617          	auipc	a2,0x2
ffffffffc0204348:	1dc60613          	addi	a2,a2,476 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc020434c:	07100593          	li	a1,113
ffffffffc0204350:	00002517          	auipc	a0,0x2
ffffffffc0204354:	1f850513          	addi	a0,a0,504 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0204358:	936fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020435c <kernel_thread>:
{
ffffffffc020435c:	7129                	addi	sp,sp,-320
ffffffffc020435e:	fa22                	sd	s0,304(sp)
ffffffffc0204360:	f626                	sd	s1,296(sp)
ffffffffc0204362:	f24a                	sd	s2,288(sp)
ffffffffc0204364:	84ae                	mv	s1,a1
ffffffffc0204366:	892a                	mv	s2,a0
ffffffffc0204368:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020436a:	4581                	li	a1,0
ffffffffc020436c:	12000613          	li	a2,288
ffffffffc0204370:	850a                	mv	a0,sp
{
ffffffffc0204372:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204374:	304010ef          	jal	ra,ffffffffc0205678 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204378:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020437a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020437c:	100027f3          	csrr	a5,sstatus
ffffffffc0204380:	edd7f793          	andi	a5,a5,-291
ffffffffc0204384:	1207e793          	ori	a5,a5,288
ffffffffc0204388:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020438a:	860a                	mv	a2,sp
ffffffffc020438c:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204390:	00000797          	auipc	a5,0x0
ffffffffc0204394:	a2a78793          	addi	a5,a5,-1494 # ffffffffc0203dba <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204398:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020439a:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020439c:	be3ff0ef          	jal	ra,ffffffffc0203f7e <do_fork>
}
ffffffffc02043a0:	70f2                	ld	ra,312(sp)
ffffffffc02043a2:	7452                	ld	s0,304(sp)
ffffffffc02043a4:	74b2                	ld	s1,296(sp)
ffffffffc02043a6:	7912                	ld	s2,288(sp)
ffffffffc02043a8:	6131                	addi	sp,sp,320
ffffffffc02043aa:	8082                	ret

ffffffffc02043ac <do_exit>:
{
ffffffffc02043ac:	7179                	addi	sp,sp,-48
ffffffffc02043ae:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02043b0:	000a6417          	auipc	s0,0xa6
ffffffffc02043b4:	23840413          	addi	s0,s0,568 # ffffffffc02aa5e8 <current>
ffffffffc02043b8:	601c                	ld	a5,0(s0)
{
ffffffffc02043ba:	f406                	sd	ra,40(sp)
ffffffffc02043bc:	ec26                	sd	s1,24(sp)
ffffffffc02043be:	e84a                	sd	s2,16(sp)
ffffffffc02043c0:	e44e                	sd	s3,8(sp)
ffffffffc02043c2:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02043c4:	000a6717          	auipc	a4,0xa6
ffffffffc02043c8:	22c73703          	ld	a4,556(a4) # ffffffffc02aa5f0 <idleproc>
ffffffffc02043cc:	0ce78c63          	beq	a5,a4,ffffffffc02044a4 <do_exit+0xf8>
    if (current == initproc)
ffffffffc02043d0:	000a6497          	auipc	s1,0xa6
ffffffffc02043d4:	22848493          	addi	s1,s1,552 # ffffffffc02aa5f8 <initproc>
ffffffffc02043d8:	6098                	ld	a4,0(s1)
ffffffffc02043da:	0ee78b63          	beq	a5,a4,ffffffffc02044d0 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02043de:	0287b983          	ld	s3,40(a5)
ffffffffc02043e2:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02043e4:	02098663          	beqz	s3,ffffffffc0204410 <do_exit+0x64>
ffffffffc02043e8:	000a6797          	auipc	a5,0xa6
ffffffffc02043ec:	1d07b783          	ld	a5,464(a5) # ffffffffc02aa5b8 <boot_pgdir_pa>
ffffffffc02043f0:	577d                	li	a4,-1
ffffffffc02043f2:	177e                	slli	a4,a4,0x3f
ffffffffc02043f4:	83b1                	srli	a5,a5,0xc
ffffffffc02043f6:	8fd9                	or	a5,a5,a4
ffffffffc02043f8:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02043fc:	0309a783          	lw	a5,48(s3)
ffffffffc0204400:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204404:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204408:	cb55                	beqz	a4,ffffffffc02044bc <do_exit+0x110>
        current->mm = NULL;
ffffffffc020440a:	601c                	ld	a5,0(s0)
ffffffffc020440c:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204410:	601c                	ld	a5,0(s0)
ffffffffc0204412:	470d                	li	a4,3
ffffffffc0204414:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204416:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020441a:	100027f3          	csrr	a5,sstatus
ffffffffc020441e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204420:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204422:	e3f9                	bnez	a5,ffffffffc02044e8 <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204424:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204426:	800007b7          	lui	a5,0x80000
ffffffffc020442a:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020442c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020442e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204432:	0af70f63          	beq	a4,a5,ffffffffc02044f0 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204436:	6018                	ld	a4,0(s0)
ffffffffc0204438:	7b7c                	ld	a5,240(a4)
ffffffffc020443a:	c3a1                	beqz	a5,ffffffffc020447a <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020443c:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204440:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204442:	0985                	addi	s3,s3,1
ffffffffc0204444:	a021                	j	ffffffffc020444c <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204446:	6018                	ld	a4,0(s0)
ffffffffc0204448:	7b7c                	ld	a5,240(a4)
ffffffffc020444a:	cb85                	beqz	a5,ffffffffc020447a <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020444c:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4ff8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204450:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204452:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204454:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204456:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020445a:	10e7b023          	sd	a4,256(a5)
ffffffffc020445e:	c311                	beqz	a4,ffffffffc0204462 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204460:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204462:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204464:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204466:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204468:	fd271fe3          	bne	a4,s2,ffffffffc0204446 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020446c:	0ec52783          	lw	a5,236(a0)
ffffffffc0204470:	fd379be3          	bne	a5,s3,ffffffffc0204446 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204474:	373000ef          	jal	ra,ffffffffc0204fe6 <wakeup_proc>
ffffffffc0204478:	b7f9                	j	ffffffffc0204446 <do_exit+0x9a>
    if (flag)
ffffffffc020447a:	020a1263          	bnez	s4,ffffffffc020449e <do_exit+0xf2>
    schedule();
ffffffffc020447e:	3e9000ef          	jal	ra,ffffffffc0205066 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204482:	601c                	ld	a5,0(s0)
ffffffffc0204484:	00003617          	auipc	a2,0x3
ffffffffc0204488:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206fb0 <default_pmm_manager+0xac8>
ffffffffc020448c:	24700593          	li	a1,583
ffffffffc0204490:	43d4                	lw	a3,4(a5)
ffffffffc0204492:	00003517          	auipc	a0,0x3
ffffffffc0204496:	abe50513          	addi	a0,a0,-1346 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc020449a:	ff5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc020449e:	d10fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02044a2:	bff1                	j	ffffffffc020447e <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02044a4:	00003617          	auipc	a2,0x3
ffffffffc02044a8:	aec60613          	addi	a2,a2,-1300 # ffffffffc0206f90 <default_pmm_manager+0xaa8>
ffffffffc02044ac:	21300593          	li	a1,531
ffffffffc02044b0:	00003517          	auipc	a0,0x3
ffffffffc02044b4:	aa050513          	addi	a0,a0,-1376 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc02044b8:	fd7fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc02044bc:	854e                	mv	a0,s3
ffffffffc02044be:	cceff0ef          	jal	ra,ffffffffc020398c <exit_mmap>
            put_pgdir(mm);
ffffffffc02044c2:	854e                	mv	a0,s3
ffffffffc02044c4:	9ddff0ef          	jal	ra,ffffffffc0203ea0 <put_pgdir>
            mm_destroy(mm);
ffffffffc02044c8:	854e                	mv	a0,s3
ffffffffc02044ca:	b26ff0ef          	jal	ra,ffffffffc02037f0 <mm_destroy>
ffffffffc02044ce:	bf35                	j	ffffffffc020440a <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02044d0:	00003617          	auipc	a2,0x3
ffffffffc02044d4:	ad060613          	addi	a2,a2,-1328 # ffffffffc0206fa0 <default_pmm_manager+0xab8>
ffffffffc02044d8:	21700593          	li	a1,535
ffffffffc02044dc:	00003517          	auipc	a0,0x3
ffffffffc02044e0:	a7450513          	addi	a0,a0,-1420 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc02044e4:	fabfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02044e8:	cccfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02044ec:	4a05                	li	s4,1
ffffffffc02044ee:	bf1d                	j	ffffffffc0204424 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02044f0:	2f7000ef          	jal	ra,ffffffffc0204fe6 <wakeup_proc>
ffffffffc02044f4:	b789                	j	ffffffffc0204436 <do_exit+0x8a>

ffffffffc02044f6 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02044f6:	715d                	addi	sp,sp,-80
ffffffffc02044f8:	f84a                	sd	s2,48(sp)
ffffffffc02044fa:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc02044fc:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204500:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204502:	fc26                	sd	s1,56(sp)
ffffffffc0204504:	f052                	sd	s4,32(sp)
ffffffffc0204506:	ec56                	sd	s5,24(sp)
ffffffffc0204508:	e85a                	sd	s6,16(sp)
ffffffffc020450a:	e45e                	sd	s7,8(sp)
ffffffffc020450c:	e486                	sd	ra,72(sp)
ffffffffc020450e:	e0a2                	sd	s0,64(sp)
ffffffffc0204510:	84aa                	mv	s1,a0
ffffffffc0204512:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204514:	000a6b97          	auipc	s7,0xa6
ffffffffc0204518:	0d4b8b93          	addi	s7,s7,212 # ffffffffc02aa5e8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc020451c:	00050b1b          	sext.w	s6,a0
ffffffffc0204520:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204524:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204526:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204528:	ccbd                	beqz	s1,ffffffffc02045a6 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020452a:	0359e863          	bltu	s3,s5,ffffffffc020455a <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020452e:	45a9                	li	a1,10
ffffffffc0204530:	855a                	mv	a0,s6
ffffffffc0204532:	4a1000ef          	jal	ra,ffffffffc02051d2 <hash32>
ffffffffc0204536:	02051793          	slli	a5,a0,0x20
ffffffffc020453a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020453e:	000a2797          	auipc	a5,0xa2
ffffffffc0204542:	03a78793          	addi	a5,a5,58 # ffffffffc02a6578 <hash_list>
ffffffffc0204546:	953e                	add	a0,a0,a5
ffffffffc0204548:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020454a:	a029                	j	ffffffffc0204554 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020454c:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204550:	02978163          	beq	a5,s1,ffffffffc0204572 <do_wait.part.0+0x7c>
ffffffffc0204554:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204556:	fe851be3          	bne	a0,s0,ffffffffc020454c <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc020455a:	5579                	li	a0,-2
}
ffffffffc020455c:	60a6                	ld	ra,72(sp)
ffffffffc020455e:	6406                	ld	s0,64(sp)
ffffffffc0204560:	74e2                	ld	s1,56(sp)
ffffffffc0204562:	7942                	ld	s2,48(sp)
ffffffffc0204564:	79a2                	ld	s3,40(sp)
ffffffffc0204566:	7a02                	ld	s4,32(sp)
ffffffffc0204568:	6ae2                	ld	s5,24(sp)
ffffffffc020456a:	6b42                	ld	s6,16(sp)
ffffffffc020456c:	6ba2                	ld	s7,8(sp)
ffffffffc020456e:	6161                	addi	sp,sp,80
ffffffffc0204570:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204572:	000bb683          	ld	a3,0(s7)
ffffffffc0204576:	f4843783          	ld	a5,-184(s0)
ffffffffc020457a:	fed790e3          	bne	a5,a3,ffffffffc020455a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020457e:	f2842703          	lw	a4,-216(s0)
ffffffffc0204582:	478d                	li	a5,3
ffffffffc0204584:	0ef70b63          	beq	a4,a5,ffffffffc020467a <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204588:	4785                	li	a5,1
ffffffffc020458a:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020458c:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204590:	2d7000ef          	jal	ra,ffffffffc0205066 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204594:	000bb783          	ld	a5,0(s7)
ffffffffc0204598:	0b07a783          	lw	a5,176(a5)
ffffffffc020459c:	8b85                	andi	a5,a5,1
ffffffffc020459e:	d7c9                	beqz	a5,ffffffffc0204528 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02045a0:	555d                	li	a0,-9
ffffffffc02045a2:	e0bff0ef          	jal	ra,ffffffffc02043ac <do_exit>
        proc = current->cptr;
ffffffffc02045a6:	000bb683          	ld	a3,0(s7)
ffffffffc02045aa:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02045ac:	d45d                	beqz	s0,ffffffffc020455a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045ae:	470d                	li	a4,3
ffffffffc02045b0:	a021                	j	ffffffffc02045b8 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02045b2:	10043403          	ld	s0,256(s0)
ffffffffc02045b6:	d869                	beqz	s0,ffffffffc0204588 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045b8:	401c                	lw	a5,0(s0)
ffffffffc02045ba:	fee79ce3          	bne	a5,a4,ffffffffc02045b2 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02045be:	000a6797          	auipc	a5,0xa6
ffffffffc02045c2:	0327b783          	ld	a5,50(a5) # ffffffffc02aa5f0 <idleproc>
ffffffffc02045c6:	0c878963          	beq	a5,s0,ffffffffc0204698 <do_wait.part.0+0x1a2>
ffffffffc02045ca:	000a6797          	auipc	a5,0xa6
ffffffffc02045ce:	02e7b783          	ld	a5,46(a5) # ffffffffc02aa5f8 <initproc>
ffffffffc02045d2:	0cf40363          	beq	s0,a5,ffffffffc0204698 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02045d6:	000a0663          	beqz	s4,ffffffffc02045e2 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02045da:	0e842783          	lw	a5,232(s0)
ffffffffc02045de:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8b98>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045e2:	100027f3          	csrr	a5,sstatus
ffffffffc02045e6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045e8:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045ea:	e7c1                	bnez	a5,ffffffffc0204672 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02045ec:	6c70                	ld	a2,216(s0)
ffffffffc02045ee:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc02045f0:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02045f4:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02045f6:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02045f8:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02045fa:	6470                	ld	a2,200(s0)
ffffffffc02045fc:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02045fe:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204600:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204602:	c319                	beqz	a4,ffffffffc0204608 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204604:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204606:	7c7c                	ld	a5,248(s0)
ffffffffc0204608:	c3b5                	beqz	a5,ffffffffc020466c <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020460a:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc020460e:	000a6717          	auipc	a4,0xa6
ffffffffc0204612:	ff270713          	addi	a4,a4,-14 # ffffffffc02aa600 <nr_process>
ffffffffc0204616:	431c                	lw	a5,0(a4)
ffffffffc0204618:	37fd                	addiw	a5,a5,-1
ffffffffc020461a:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc020461c:	e5a9                	bnez	a1,ffffffffc0204666 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020461e:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204620:	c02007b7          	lui	a5,0xc0200
ffffffffc0204624:	04f6ee63          	bltu	a3,a5,ffffffffc0204680 <do_wait.part.0+0x18a>
ffffffffc0204628:	000a6797          	auipc	a5,0xa6
ffffffffc020462c:	fb87b783          	ld	a5,-72(a5) # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc0204630:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204632:	82b1                	srli	a3,a3,0xc
ffffffffc0204634:	000a6797          	auipc	a5,0xa6
ffffffffc0204638:	f947b783          	ld	a5,-108(a5) # ffffffffc02aa5c8 <npage>
ffffffffc020463c:	06f6fa63          	bgeu	a3,a5,ffffffffc02046b0 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204640:	00003517          	auipc	a0,0x3
ffffffffc0204644:	1a853503          	ld	a0,424(a0) # ffffffffc02077e8 <nbase>
ffffffffc0204648:	8e89                	sub	a3,a3,a0
ffffffffc020464a:	069a                	slli	a3,a3,0x6
ffffffffc020464c:	000a6517          	auipc	a0,0xa6
ffffffffc0204650:	f8453503          	ld	a0,-124(a0) # ffffffffc02aa5d0 <pages>
ffffffffc0204654:	9536                	add	a0,a0,a3
ffffffffc0204656:	4589                	li	a1,2
ffffffffc0204658:	873fd0ef          	jal	ra,ffffffffc0201eca <free_pages>
    kfree(proc);
ffffffffc020465c:	8522                	mv	a0,s0
ffffffffc020465e:	f00fd0ef          	jal	ra,ffffffffc0201d5e <kfree>
    return 0;
ffffffffc0204662:	4501                	li	a0,0
ffffffffc0204664:	bde5                	j	ffffffffc020455c <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204666:	b48fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020466a:	bf55                	j	ffffffffc020461e <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020466c:	701c                	ld	a5,32(s0)
ffffffffc020466e:	fbf8                	sd	a4,240(a5)
ffffffffc0204670:	bf79                	j	ffffffffc020460e <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204672:	b42fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204676:	4585                	li	a1,1
ffffffffc0204678:	bf95                	j	ffffffffc02045ec <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020467a:	f2840413          	addi	s0,s0,-216
ffffffffc020467e:	b781                	j	ffffffffc02045be <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204680:	00002617          	auipc	a2,0x2
ffffffffc0204684:	f4860613          	addi	a2,a2,-184 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc0204688:	07700593          	li	a1,119
ffffffffc020468c:	00002517          	auipc	a0,0x2
ffffffffc0204690:	ebc50513          	addi	a0,a0,-324 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0204694:	dfbfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204698:	00003617          	auipc	a2,0x3
ffffffffc020469c:	93860613          	addi	a2,a2,-1736 # ffffffffc0206fd0 <default_pmm_manager+0xae8>
ffffffffc02046a0:	36800593          	li	a1,872
ffffffffc02046a4:	00003517          	auipc	a0,0x3
ffffffffc02046a8:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc02046ac:	de3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02046b0:	00002617          	auipc	a2,0x2
ffffffffc02046b4:	f4060613          	addi	a2,a2,-192 # ffffffffc02065f0 <default_pmm_manager+0x108>
ffffffffc02046b8:	06900593          	li	a1,105
ffffffffc02046bc:	00002517          	auipc	a0,0x2
ffffffffc02046c0:	e8c50513          	addi	a0,a0,-372 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc02046c4:	dcbfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02046c8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02046c8:	1141                	addi	sp,sp,-16
ffffffffc02046ca:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02046cc:	83ffd0ef          	jal	ra,ffffffffc0201f0a <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02046d0:	ddafd0ef          	jal	ra,ffffffffc0201caa <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02046d4:	4601                	li	a2,0
ffffffffc02046d6:	4581                	li	a1,0
ffffffffc02046d8:	fffff517          	auipc	a0,0xfffff
ffffffffc02046dc:	74a50513          	addi	a0,a0,1866 # ffffffffc0203e22 <user_main>
ffffffffc02046e0:	c7dff0ef          	jal	ra,ffffffffc020435c <kernel_thread>
    if (pid <= 0)
ffffffffc02046e4:	00a04563          	bgtz	a0,ffffffffc02046ee <init_main+0x26>
ffffffffc02046e8:	a071                	j	ffffffffc0204774 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02046ea:	17d000ef          	jal	ra,ffffffffc0205066 <schedule>
    if (code_store != NULL)
ffffffffc02046ee:	4581                	li	a1,0
ffffffffc02046f0:	4501                	li	a0,0
ffffffffc02046f2:	e05ff0ef          	jal	ra,ffffffffc02044f6 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02046f6:	d975                	beqz	a0,ffffffffc02046ea <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02046f8:	00003517          	auipc	a0,0x3
ffffffffc02046fc:	91850513          	addi	a0,a0,-1768 # ffffffffc0207010 <default_pmm_manager+0xb28>
ffffffffc0204700:	a95fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204704:	000a6797          	auipc	a5,0xa6
ffffffffc0204708:	ef47b783          	ld	a5,-268(a5) # ffffffffc02aa5f8 <initproc>
ffffffffc020470c:	7bf8                	ld	a4,240(a5)
ffffffffc020470e:	e339                	bnez	a4,ffffffffc0204754 <init_main+0x8c>
ffffffffc0204710:	7ff8                	ld	a4,248(a5)
ffffffffc0204712:	e329                	bnez	a4,ffffffffc0204754 <init_main+0x8c>
ffffffffc0204714:	1007b703          	ld	a4,256(a5)
ffffffffc0204718:	ef15                	bnez	a4,ffffffffc0204754 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020471a:	000a6697          	auipc	a3,0xa6
ffffffffc020471e:	ee66a683          	lw	a3,-282(a3) # ffffffffc02aa600 <nr_process>
ffffffffc0204722:	4709                	li	a4,2
ffffffffc0204724:	0ae69463          	bne	a3,a4,ffffffffc02047cc <init_main+0x104>
    return listelm->next;
ffffffffc0204728:	000a6697          	auipc	a3,0xa6
ffffffffc020472c:	e5068693          	addi	a3,a3,-432 # ffffffffc02aa578 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204730:	6698                	ld	a4,8(a3)
ffffffffc0204732:	0c878793          	addi	a5,a5,200
ffffffffc0204736:	06f71b63          	bne	a4,a5,ffffffffc02047ac <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020473a:	629c                	ld	a5,0(a3)
ffffffffc020473c:	04f71863          	bne	a4,a5,ffffffffc020478c <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204740:	00003517          	auipc	a0,0x3
ffffffffc0204744:	9b850513          	addi	a0,a0,-1608 # ffffffffc02070f8 <default_pmm_manager+0xc10>
ffffffffc0204748:	a4dfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc020474c:	60a2                	ld	ra,8(sp)
ffffffffc020474e:	4501                	li	a0,0
ffffffffc0204750:	0141                	addi	sp,sp,16
ffffffffc0204752:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204754:	00003697          	auipc	a3,0x3
ffffffffc0204758:	8e468693          	addi	a3,a3,-1820 # ffffffffc0207038 <default_pmm_manager+0xb50>
ffffffffc020475c:	00002617          	auipc	a2,0x2
ffffffffc0204760:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0206138 <commands+0x828>
ffffffffc0204764:	3d600593          	li	a1,982
ffffffffc0204768:	00002517          	auipc	a0,0x2
ffffffffc020476c:	7e850513          	addi	a0,a0,2024 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204770:	d1ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204774:	00003617          	auipc	a2,0x3
ffffffffc0204778:	87c60613          	addi	a2,a2,-1924 # ffffffffc0206ff0 <default_pmm_manager+0xb08>
ffffffffc020477c:	3cd00593          	li	a1,973
ffffffffc0204780:	00002517          	auipc	a0,0x2
ffffffffc0204784:	7d050513          	addi	a0,a0,2000 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204788:	d07fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020478c:	00003697          	auipc	a3,0x3
ffffffffc0204790:	93c68693          	addi	a3,a3,-1732 # ffffffffc02070c8 <default_pmm_manager+0xbe0>
ffffffffc0204794:	00002617          	auipc	a2,0x2
ffffffffc0204798:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206138 <commands+0x828>
ffffffffc020479c:	3d900593          	li	a1,985
ffffffffc02047a0:	00002517          	auipc	a0,0x2
ffffffffc02047a4:	7b050513          	addi	a0,a0,1968 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc02047a8:	ce7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02047ac:	00003697          	auipc	a3,0x3
ffffffffc02047b0:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0207098 <default_pmm_manager+0xbb0>
ffffffffc02047b4:	00002617          	auipc	a2,0x2
ffffffffc02047b8:	98460613          	addi	a2,a2,-1660 # ffffffffc0206138 <commands+0x828>
ffffffffc02047bc:	3d800593          	li	a1,984
ffffffffc02047c0:	00002517          	auipc	a0,0x2
ffffffffc02047c4:	79050513          	addi	a0,a0,1936 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc02047c8:	cc7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc02047cc:	00003697          	auipc	a3,0x3
ffffffffc02047d0:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0207088 <default_pmm_manager+0xba0>
ffffffffc02047d4:	00002617          	auipc	a2,0x2
ffffffffc02047d8:	96460613          	addi	a2,a2,-1692 # ffffffffc0206138 <commands+0x828>
ffffffffc02047dc:	3d700593          	li	a1,983
ffffffffc02047e0:	00002517          	auipc	a0,0x2
ffffffffc02047e4:	77050513          	addi	a0,a0,1904 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc02047e8:	ca7fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02047ec <do_execve>:
{
ffffffffc02047ec:	7171                	addi	sp,sp,-176
ffffffffc02047ee:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02047f0:	000a6d97          	auipc	s11,0xa6
ffffffffc02047f4:	df8d8d93          	addi	s11,s11,-520 # ffffffffc02aa5e8 <current>
ffffffffc02047f8:	000db783          	ld	a5,0(s11)
{
ffffffffc02047fc:	e54e                	sd	s3,136(sp)
ffffffffc02047fe:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204800:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204804:	e94a                	sd	s2,144(sp)
ffffffffc0204806:	f4de                	sd	s7,104(sp)
ffffffffc0204808:	892a                	mv	s2,a0
ffffffffc020480a:	8bb2                	mv	s7,a2
ffffffffc020480c:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020480e:	862e                	mv	a2,a1
ffffffffc0204810:	4681                	li	a3,0
ffffffffc0204812:	85aa                	mv	a1,a0
ffffffffc0204814:	854e                	mv	a0,s3
{
ffffffffc0204816:	f506                	sd	ra,168(sp)
ffffffffc0204818:	f122                	sd	s0,160(sp)
ffffffffc020481a:	e152                	sd	s4,128(sp)
ffffffffc020481c:	fcd6                	sd	s5,120(sp)
ffffffffc020481e:	f8da                	sd	s6,112(sp)
ffffffffc0204820:	f0e2                	sd	s8,96(sp)
ffffffffc0204822:	ece6                	sd	s9,88(sp)
ffffffffc0204824:	e8ea                	sd	s10,80(sp)
ffffffffc0204826:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204828:	cfeff0ef          	jal	ra,ffffffffc0203d26 <user_mem_check>
ffffffffc020482c:	40050a63          	beqz	a0,ffffffffc0204c40 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204830:	4641                	li	a2,16
ffffffffc0204832:	4581                	li	a1,0
ffffffffc0204834:	1808                	addi	a0,sp,48
ffffffffc0204836:	643000ef          	jal	ra,ffffffffc0205678 <memset>
    memcpy(local_name, name, len);
ffffffffc020483a:	47bd                	li	a5,15
ffffffffc020483c:	8626                	mv	a2,s1
ffffffffc020483e:	1e97e263          	bltu	a5,s1,ffffffffc0204a22 <do_execve+0x236>
ffffffffc0204842:	85ca                	mv	a1,s2
ffffffffc0204844:	1808                	addi	a0,sp,48
ffffffffc0204846:	645000ef          	jal	ra,ffffffffc020568a <memcpy>
    if (mm != NULL)
ffffffffc020484a:	1e098363          	beqz	s3,ffffffffc0204a30 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc020484e:	00002517          	auipc	a0,0x2
ffffffffc0204852:	4ca50513          	addi	a0,a0,1226 # ffffffffc0206d18 <default_pmm_manager+0x830>
ffffffffc0204856:	977fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc020485a:	000a6797          	auipc	a5,0xa6
ffffffffc020485e:	d5e7b783          	ld	a5,-674(a5) # ffffffffc02aa5b8 <boot_pgdir_pa>
ffffffffc0204862:	577d                	li	a4,-1
ffffffffc0204864:	177e                	slli	a4,a4,0x3f
ffffffffc0204866:	83b1                	srli	a5,a5,0xc
ffffffffc0204868:	8fd9                	or	a5,a5,a4
ffffffffc020486a:	18079073          	csrw	satp,a5
ffffffffc020486e:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b68>
ffffffffc0204872:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204876:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020487a:	2c070463          	beqz	a4,ffffffffc0204b42 <do_execve+0x356>
        current->mm = NULL;
ffffffffc020487e:	000db783          	ld	a5,0(s11)
ffffffffc0204882:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204886:	e2bfe0ef          	jal	ra,ffffffffc02036b0 <mm_create>
ffffffffc020488a:	84aa                	mv	s1,a0
ffffffffc020488c:	1c050d63          	beqz	a0,ffffffffc0204a66 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204890:	4505                	li	a0,1
ffffffffc0204892:	dfafd0ef          	jal	ra,ffffffffc0201e8c <alloc_pages>
ffffffffc0204896:	3a050963          	beqz	a0,ffffffffc0204c48 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc020489a:	000a6c97          	auipc	s9,0xa6
ffffffffc020489e:	d36c8c93          	addi	s9,s9,-714 # ffffffffc02aa5d0 <pages>
ffffffffc02048a2:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02048a6:	000a6c17          	auipc	s8,0xa6
ffffffffc02048aa:	d22c0c13          	addi	s8,s8,-734 # ffffffffc02aa5c8 <npage>
    return page - pages + nbase;
ffffffffc02048ae:	00003717          	auipc	a4,0x3
ffffffffc02048b2:	f3a73703          	ld	a4,-198(a4) # ffffffffc02077e8 <nbase>
ffffffffc02048b6:	40d506b3          	sub	a3,a0,a3
ffffffffc02048ba:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02048bc:	5afd                	li	s5,-1
ffffffffc02048be:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02048c2:	96ba                	add	a3,a3,a4
ffffffffc02048c4:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02048c6:	00cad713          	srli	a4,s5,0xc
ffffffffc02048ca:	ec3a                	sd	a4,24(sp)
ffffffffc02048cc:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02048ce:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02048d0:	38f77063          	bgeu	a4,a5,ffffffffc0204c50 <do_execve+0x464>
ffffffffc02048d4:	000a6b17          	auipc	s6,0xa6
ffffffffc02048d8:	d0cb0b13          	addi	s6,s6,-756 # ffffffffc02aa5e0 <va_pa_offset>
ffffffffc02048dc:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02048e0:	6605                	lui	a2,0x1
ffffffffc02048e2:	000a6597          	auipc	a1,0xa6
ffffffffc02048e6:	cde5b583          	ld	a1,-802(a1) # ffffffffc02aa5c0 <boot_pgdir_va>
ffffffffc02048ea:	9936                	add	s2,s2,a3
ffffffffc02048ec:	854a                	mv	a0,s2
ffffffffc02048ee:	59d000ef          	jal	ra,ffffffffc020568a <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02048f2:	7782                	ld	a5,32(sp)
ffffffffc02048f4:	4398                	lw	a4,0(a5)
ffffffffc02048f6:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02048fa:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02048fe:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9477>
ffffffffc0204902:	14f71863          	bne	a4,a5,ffffffffc0204a52 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204906:	7682                	ld	a3,32(sp)
ffffffffc0204908:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020490c:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204910:	00371793          	slli	a5,a4,0x3
ffffffffc0204914:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204916:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204918:	078e                	slli	a5,a5,0x3
ffffffffc020491a:	97ce                	add	a5,a5,s3
ffffffffc020491c:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc020491e:	00f9fc63          	bgeu	s3,a5,ffffffffc0204936 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204922:	0009a783          	lw	a5,0(s3)
ffffffffc0204926:	4705                	li	a4,1
ffffffffc0204928:	14e78163          	beq	a5,a4,ffffffffc0204a6a <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc020492c:	77a2                	ld	a5,40(sp)
ffffffffc020492e:	03898993          	addi	s3,s3,56
ffffffffc0204932:	fef9e8e3          	bltu	s3,a5,ffffffffc0204922 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204936:	4701                	li	a4,0
ffffffffc0204938:	46ad                	li	a3,11
ffffffffc020493a:	00100637          	lui	a2,0x100
ffffffffc020493e:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204942:	8526                	mv	a0,s1
ffffffffc0204944:	efffe0ef          	jal	ra,ffffffffc0203842 <mm_map>
ffffffffc0204948:	8a2a                	mv	s4,a0
ffffffffc020494a:	1e051263          	bnez	a0,ffffffffc0204b2e <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc020494e:	6c88                	ld	a0,24(s1)
ffffffffc0204950:	467d                	li	a2,31
ffffffffc0204952:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204956:	c75fe0ef          	jal	ra,ffffffffc02035ca <pgdir_alloc_page>
ffffffffc020495a:	38050363          	beqz	a0,ffffffffc0204ce0 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc020495e:	6c88                	ld	a0,24(s1)
ffffffffc0204960:	467d                	li	a2,31
ffffffffc0204962:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204966:	c65fe0ef          	jal	ra,ffffffffc02035ca <pgdir_alloc_page>
ffffffffc020496a:	34050b63          	beqz	a0,ffffffffc0204cc0 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020496e:	6c88                	ld	a0,24(s1)
ffffffffc0204970:	467d                	li	a2,31
ffffffffc0204972:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204976:	c55fe0ef          	jal	ra,ffffffffc02035ca <pgdir_alloc_page>
ffffffffc020497a:	32050363          	beqz	a0,ffffffffc0204ca0 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc020497e:	6c88                	ld	a0,24(s1)
ffffffffc0204980:	467d                	li	a2,31
ffffffffc0204982:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204986:	c45fe0ef          	jal	ra,ffffffffc02035ca <pgdir_alloc_page>
ffffffffc020498a:	2e050b63          	beqz	a0,ffffffffc0204c80 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc020498e:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204990:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204994:	6c94                	ld	a3,24(s1)
ffffffffc0204996:	2785                	addiw	a5,a5,1
ffffffffc0204998:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc020499a:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc020499c:	c02007b7          	lui	a5,0xc0200
ffffffffc02049a0:	2cf6e463          	bltu	a3,a5,ffffffffc0204c68 <do_execve+0x47c>
ffffffffc02049a4:	000b3783          	ld	a5,0(s6)
ffffffffc02049a8:	577d                	li	a4,-1
ffffffffc02049aa:	177e                	slli	a4,a4,0x3f
ffffffffc02049ac:	8e9d                	sub	a3,a3,a5
ffffffffc02049ae:	00c6d793          	srli	a5,a3,0xc
ffffffffc02049b2:	f654                	sd	a3,168(a2)
ffffffffc02049b4:	8fd9                	or	a5,a5,a4
ffffffffc02049b6:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02049ba:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02049bc:	4581                	li	a1,0
ffffffffc02049be:	12000613          	li	a2,288
ffffffffc02049c2:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc02049c4:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02049c8:	4b1000ef          	jal	ra,ffffffffc0205678 <memset>
    tf->epc = elf->e_entry;
ffffffffc02049cc:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02049ce:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02049d2:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc02049d6:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc02049d8:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02049da:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4fac>
    tf->gpr.sp = USTACKTOP;
ffffffffc02049de:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02049e0:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02049e4:	4641                	li	a2,16
ffffffffc02049e6:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc02049e8:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc02049ea:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc02049ee:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02049f2:	854a                	mv	a0,s2
ffffffffc02049f4:	485000ef          	jal	ra,ffffffffc0205678 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02049f8:	463d                	li	a2,15
ffffffffc02049fa:	180c                	addi	a1,sp,48
ffffffffc02049fc:	854a                	mv	a0,s2
ffffffffc02049fe:	48d000ef          	jal	ra,ffffffffc020568a <memcpy>
}
ffffffffc0204a02:	70aa                	ld	ra,168(sp)
ffffffffc0204a04:	740a                	ld	s0,160(sp)
ffffffffc0204a06:	64ea                	ld	s1,152(sp)
ffffffffc0204a08:	694a                	ld	s2,144(sp)
ffffffffc0204a0a:	69aa                	ld	s3,136(sp)
ffffffffc0204a0c:	7ae6                	ld	s5,120(sp)
ffffffffc0204a0e:	7b46                	ld	s6,112(sp)
ffffffffc0204a10:	7ba6                	ld	s7,104(sp)
ffffffffc0204a12:	7c06                	ld	s8,96(sp)
ffffffffc0204a14:	6ce6                	ld	s9,88(sp)
ffffffffc0204a16:	6d46                	ld	s10,80(sp)
ffffffffc0204a18:	6da6                	ld	s11,72(sp)
ffffffffc0204a1a:	8552                	mv	a0,s4
ffffffffc0204a1c:	6a0a                	ld	s4,128(sp)
ffffffffc0204a1e:	614d                	addi	sp,sp,176
ffffffffc0204a20:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204a22:	463d                	li	a2,15
ffffffffc0204a24:	85ca                	mv	a1,s2
ffffffffc0204a26:	1808                	addi	a0,sp,48
ffffffffc0204a28:	463000ef          	jal	ra,ffffffffc020568a <memcpy>
    if (mm != NULL)
ffffffffc0204a2c:	e20991e3          	bnez	s3,ffffffffc020484e <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204a30:	000db783          	ld	a5,0(s11)
ffffffffc0204a34:	779c                	ld	a5,40(a5)
ffffffffc0204a36:	e40788e3          	beqz	a5,ffffffffc0204886 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a3a:	00002617          	auipc	a2,0x2
ffffffffc0204a3e:	6de60613          	addi	a2,a2,1758 # ffffffffc0207118 <default_pmm_manager+0xc30>
ffffffffc0204a42:	25300593          	li	a1,595
ffffffffc0204a46:	00002517          	auipc	a0,0x2
ffffffffc0204a4a:	50a50513          	addi	a0,a0,1290 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204a4e:	a41fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204a52:	8526                	mv	a0,s1
ffffffffc0204a54:	c4cff0ef          	jal	ra,ffffffffc0203ea0 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204a58:	8526                	mv	a0,s1
ffffffffc0204a5a:	d97fe0ef          	jal	ra,ffffffffc02037f0 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204a5e:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204a60:	8552                	mv	a0,s4
ffffffffc0204a62:	94bff0ef          	jal	ra,ffffffffc02043ac <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204a66:	5a71                	li	s4,-4
ffffffffc0204a68:	bfe5                	j	ffffffffc0204a60 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204a6a:	0289b603          	ld	a2,40(s3)
ffffffffc0204a6e:	0209b783          	ld	a5,32(s3)
ffffffffc0204a72:	1cf66d63          	bltu	a2,a5,ffffffffc0204c4c <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204a76:	0049a783          	lw	a5,4(s3)
ffffffffc0204a7a:	0017f693          	andi	a3,a5,1
ffffffffc0204a7e:	c291                	beqz	a3,ffffffffc0204a82 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204a80:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204a82:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a86:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204a88:	e779                	bnez	a4,ffffffffc0204b56 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204a8a:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204a8c:	c781                	beqz	a5,ffffffffc0204a94 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204a8e:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204a92:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204a94:	0026f793          	andi	a5,a3,2
ffffffffc0204a98:	e3f1                	bnez	a5,ffffffffc0204b5c <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204a9a:	0046f793          	andi	a5,a3,4
ffffffffc0204a9e:	c399                	beqz	a5,ffffffffc0204aa4 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204aa0:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204aa4:	0109b583          	ld	a1,16(s3)
ffffffffc0204aa8:	4701                	li	a4,0
ffffffffc0204aaa:	8526                	mv	a0,s1
ffffffffc0204aac:	d97fe0ef          	jal	ra,ffffffffc0203842 <mm_map>
ffffffffc0204ab0:	8a2a                	mv	s4,a0
ffffffffc0204ab2:	ed35                	bnez	a0,ffffffffc0204b2e <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204ab4:	0109bb83          	ld	s7,16(s3)
ffffffffc0204ab8:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204aba:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204abe:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204ac2:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204ac6:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204ac8:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204aca:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204acc:	054be963          	bltu	s7,s4,ffffffffc0204b1e <do_execve+0x332>
ffffffffc0204ad0:	aa95                	j	ffffffffc0204c44 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204ad2:	6785                	lui	a5,0x1
ffffffffc0204ad4:	415b8533          	sub	a0,s7,s5
ffffffffc0204ad8:	9abe                	add	s5,s5,a5
ffffffffc0204ada:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204ade:	015a7463          	bgeu	s4,s5,ffffffffc0204ae6 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204ae2:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204ae6:	000cb683          	ld	a3,0(s9)
ffffffffc0204aea:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204aec:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204af0:	40d406b3          	sub	a3,s0,a3
ffffffffc0204af4:	8699                	srai	a3,a3,0x6
ffffffffc0204af6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204af8:	67e2                	ld	a5,24(sp)
ffffffffc0204afa:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204afe:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b00:	14b87863          	bgeu	a6,a1,ffffffffc0204c50 <do_execve+0x464>
ffffffffc0204b04:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b08:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204b0a:	9bb2                	add	s7,s7,a2
ffffffffc0204b0c:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b0e:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204b10:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b12:	379000ef          	jal	ra,ffffffffc020568a <memcpy>
            start += size, from += size;
ffffffffc0204b16:	6622                	ld	a2,8(sp)
ffffffffc0204b18:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204b1a:	054bf363          	bgeu	s7,s4,ffffffffc0204b60 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b1e:	6c88                	ld	a0,24(s1)
ffffffffc0204b20:	866a                	mv	a2,s10
ffffffffc0204b22:	85d6                	mv	a1,s5
ffffffffc0204b24:	aa7fe0ef          	jal	ra,ffffffffc02035ca <pgdir_alloc_page>
ffffffffc0204b28:	842a                	mv	s0,a0
ffffffffc0204b2a:	f545                	bnez	a0,ffffffffc0204ad2 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204b2c:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204b2e:	8526                	mv	a0,s1
ffffffffc0204b30:	e5dfe0ef          	jal	ra,ffffffffc020398c <exit_mmap>
    put_pgdir(mm);
ffffffffc0204b34:	8526                	mv	a0,s1
ffffffffc0204b36:	b6aff0ef          	jal	ra,ffffffffc0203ea0 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204b3a:	8526                	mv	a0,s1
ffffffffc0204b3c:	cb5fe0ef          	jal	ra,ffffffffc02037f0 <mm_destroy>
    return ret;
ffffffffc0204b40:	b705                	j	ffffffffc0204a60 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204b42:	854e                	mv	a0,s3
ffffffffc0204b44:	e49fe0ef          	jal	ra,ffffffffc020398c <exit_mmap>
            put_pgdir(mm);
ffffffffc0204b48:	854e                	mv	a0,s3
ffffffffc0204b4a:	b56ff0ef          	jal	ra,ffffffffc0203ea0 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204b4e:	854e                	mv	a0,s3
ffffffffc0204b50:	ca1fe0ef          	jal	ra,ffffffffc02037f0 <mm_destroy>
ffffffffc0204b54:	b32d                	j	ffffffffc020487e <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204b56:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b5a:	fb95                	bnez	a5,ffffffffc0204a8e <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b5c:	4d5d                	li	s10,23
ffffffffc0204b5e:	bf35                	j	ffffffffc0204a9a <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204b60:	0109b683          	ld	a3,16(s3)
ffffffffc0204b64:	0289b903          	ld	s2,40(s3)
ffffffffc0204b68:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204b6a:	075bfd63          	bgeu	s7,s5,ffffffffc0204be4 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204b6e:	db790fe3          	beq	s2,s7,ffffffffc020492c <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204b72:	6785                	lui	a5,0x1
ffffffffc0204b74:	00fb8533          	add	a0,s7,a5
ffffffffc0204b78:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204b7c:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204b80:	0b597d63          	bgeu	s2,s5,ffffffffc0204c3a <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204b84:	000cb683          	ld	a3,0(s9)
ffffffffc0204b88:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b8a:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204b8e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b92:	8699                	srai	a3,a3,0x6
ffffffffc0204b94:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b96:	67e2                	ld	a5,24(sp)
ffffffffc0204b98:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b9c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b9e:	0ac5f963          	bgeu	a1,a2,ffffffffc0204c50 <do_execve+0x464>
ffffffffc0204ba2:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ba6:	8652                	mv	a2,s4
ffffffffc0204ba8:	4581                	li	a1,0
ffffffffc0204baa:	96c2                	add	a3,a3,a6
ffffffffc0204bac:	9536                	add	a0,a0,a3
ffffffffc0204bae:	2cb000ef          	jal	ra,ffffffffc0205678 <memset>
            start += size;
ffffffffc0204bb2:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204bb6:	03597463          	bgeu	s2,s5,ffffffffc0204bde <do_execve+0x3f2>
ffffffffc0204bba:	d6e909e3          	beq	s2,a4,ffffffffc020492c <do_execve+0x140>
ffffffffc0204bbe:	00002697          	auipc	a3,0x2
ffffffffc0204bc2:	58268693          	addi	a3,a3,1410 # ffffffffc0207140 <default_pmm_manager+0xc58>
ffffffffc0204bc6:	00001617          	auipc	a2,0x1
ffffffffc0204bca:	57260613          	addi	a2,a2,1394 # ffffffffc0206138 <commands+0x828>
ffffffffc0204bce:	2bc00593          	li	a1,700
ffffffffc0204bd2:	00002517          	auipc	a0,0x2
ffffffffc0204bd6:	37e50513          	addi	a0,a0,894 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204bda:	8b5fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204bde:	ff5710e3          	bne	a4,s5,ffffffffc0204bbe <do_execve+0x3d2>
ffffffffc0204be2:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204be4:	d52bf4e3          	bgeu	s7,s2,ffffffffc020492c <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204be8:	6c88                	ld	a0,24(s1)
ffffffffc0204bea:	866a                	mv	a2,s10
ffffffffc0204bec:	85d6                	mv	a1,s5
ffffffffc0204bee:	9ddfe0ef          	jal	ra,ffffffffc02035ca <pgdir_alloc_page>
ffffffffc0204bf2:	842a                	mv	s0,a0
ffffffffc0204bf4:	dd05                	beqz	a0,ffffffffc0204b2c <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204bf6:	6785                	lui	a5,0x1
ffffffffc0204bf8:	415b8533          	sub	a0,s7,s5
ffffffffc0204bfc:	9abe                	add	s5,s5,a5
ffffffffc0204bfe:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204c02:	01597463          	bgeu	s2,s5,ffffffffc0204c0a <do_execve+0x41e>
                size -= la - end;
ffffffffc0204c06:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204c0a:	000cb683          	ld	a3,0(s9)
ffffffffc0204c0e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c10:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c14:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c18:	8699                	srai	a3,a3,0x6
ffffffffc0204c1a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c1c:	67e2                	ld	a5,24(sp)
ffffffffc0204c1e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c22:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c24:	02b87663          	bgeu	a6,a1,ffffffffc0204c50 <do_execve+0x464>
ffffffffc0204c28:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c2c:	4581                	li	a1,0
            start += size;
ffffffffc0204c2e:	9bb2                	add	s7,s7,a2
ffffffffc0204c30:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c32:	9536                	add	a0,a0,a3
ffffffffc0204c34:	245000ef          	jal	ra,ffffffffc0205678 <memset>
ffffffffc0204c38:	b775                	j	ffffffffc0204be4 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c3a:	417a8a33          	sub	s4,s5,s7
ffffffffc0204c3e:	b799                	j	ffffffffc0204b84 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204c40:	5a75                	li	s4,-3
ffffffffc0204c42:	b3c1                	j	ffffffffc0204a02 <do_execve+0x216>
        while (start < end)
ffffffffc0204c44:	86de                	mv	a3,s7
ffffffffc0204c46:	bf39                	j	ffffffffc0204b64 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204c48:	5a71                	li	s4,-4
ffffffffc0204c4a:	bdc5                	j	ffffffffc0204b3a <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204c4c:	5a61                	li	s4,-8
ffffffffc0204c4e:	b5c5                	j	ffffffffc0204b2e <do_execve+0x342>
ffffffffc0204c50:	00002617          	auipc	a2,0x2
ffffffffc0204c54:	8d060613          	addi	a2,a2,-1840 # ffffffffc0206520 <default_pmm_manager+0x38>
ffffffffc0204c58:	07100593          	li	a1,113
ffffffffc0204c5c:	00002517          	auipc	a0,0x2
ffffffffc0204c60:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0206548 <default_pmm_manager+0x60>
ffffffffc0204c64:	82bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204c68:	00002617          	auipc	a2,0x2
ffffffffc0204c6c:	96060613          	addi	a2,a2,-1696 # ffffffffc02065c8 <default_pmm_manager+0xe0>
ffffffffc0204c70:	2db00593          	li	a1,731
ffffffffc0204c74:	00002517          	auipc	a0,0x2
ffffffffc0204c78:	2dc50513          	addi	a0,a0,732 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204c7c:	813fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c80:	00002697          	auipc	a3,0x2
ffffffffc0204c84:	5d868693          	addi	a3,a3,1496 # ffffffffc0207258 <default_pmm_manager+0xd70>
ffffffffc0204c88:	00001617          	auipc	a2,0x1
ffffffffc0204c8c:	4b060613          	addi	a2,a2,1200 # ffffffffc0206138 <commands+0x828>
ffffffffc0204c90:	2d600593          	li	a1,726
ffffffffc0204c94:	00002517          	auipc	a0,0x2
ffffffffc0204c98:	2bc50513          	addi	a0,a0,700 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204c9c:	ff2fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ca0:	00002697          	auipc	a3,0x2
ffffffffc0204ca4:	57068693          	addi	a3,a3,1392 # ffffffffc0207210 <default_pmm_manager+0xd28>
ffffffffc0204ca8:	00001617          	auipc	a2,0x1
ffffffffc0204cac:	49060613          	addi	a2,a2,1168 # ffffffffc0206138 <commands+0x828>
ffffffffc0204cb0:	2d500593          	li	a1,725
ffffffffc0204cb4:	00002517          	auipc	a0,0x2
ffffffffc0204cb8:	29c50513          	addi	a0,a0,668 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204cbc:	fd2fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cc0:	00002697          	auipc	a3,0x2
ffffffffc0204cc4:	50868693          	addi	a3,a3,1288 # ffffffffc02071c8 <default_pmm_manager+0xce0>
ffffffffc0204cc8:	00001617          	auipc	a2,0x1
ffffffffc0204ccc:	47060613          	addi	a2,a2,1136 # ffffffffc0206138 <commands+0x828>
ffffffffc0204cd0:	2d400593          	li	a1,724
ffffffffc0204cd4:	00002517          	auipc	a0,0x2
ffffffffc0204cd8:	27c50513          	addi	a0,a0,636 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204cdc:	fb2fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ce0:	00002697          	auipc	a3,0x2
ffffffffc0204ce4:	4a068693          	addi	a3,a3,1184 # ffffffffc0207180 <default_pmm_manager+0xc98>
ffffffffc0204ce8:	00001617          	auipc	a2,0x1
ffffffffc0204cec:	45060613          	addi	a2,a2,1104 # ffffffffc0206138 <commands+0x828>
ffffffffc0204cf0:	2d300593          	li	a1,723
ffffffffc0204cf4:	00002517          	auipc	a0,0x2
ffffffffc0204cf8:	25c50513          	addi	a0,a0,604 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204cfc:	f92fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204d00 <do_yield>:
    current->need_resched = 1;
ffffffffc0204d00:	000a6797          	auipc	a5,0xa6
ffffffffc0204d04:	8e87b783          	ld	a5,-1816(a5) # ffffffffc02aa5e8 <current>
ffffffffc0204d08:	4705                	li	a4,1
ffffffffc0204d0a:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d0c:	4501                	li	a0,0
ffffffffc0204d0e:	8082                	ret

ffffffffc0204d10 <do_wait>:
{
ffffffffc0204d10:	1101                	addi	sp,sp,-32
ffffffffc0204d12:	e822                	sd	s0,16(sp)
ffffffffc0204d14:	e426                	sd	s1,8(sp)
ffffffffc0204d16:	ec06                	sd	ra,24(sp)
ffffffffc0204d18:	842e                	mv	s0,a1
ffffffffc0204d1a:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204d1c:	c999                	beqz	a1,ffffffffc0204d32 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204d1e:	000a6797          	auipc	a5,0xa6
ffffffffc0204d22:	8ca7b783          	ld	a5,-1846(a5) # ffffffffc02aa5e8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d26:	7788                	ld	a0,40(a5)
ffffffffc0204d28:	4685                	li	a3,1
ffffffffc0204d2a:	4611                	li	a2,4
ffffffffc0204d2c:	ffbfe0ef          	jal	ra,ffffffffc0203d26 <user_mem_check>
ffffffffc0204d30:	c909                	beqz	a0,ffffffffc0204d42 <do_wait+0x32>
ffffffffc0204d32:	85a2                	mv	a1,s0
}
ffffffffc0204d34:	6442                	ld	s0,16(sp)
ffffffffc0204d36:	60e2                	ld	ra,24(sp)
ffffffffc0204d38:	8526                	mv	a0,s1
ffffffffc0204d3a:	64a2                	ld	s1,8(sp)
ffffffffc0204d3c:	6105                	addi	sp,sp,32
ffffffffc0204d3e:	fb8ff06f          	j	ffffffffc02044f6 <do_wait.part.0>
ffffffffc0204d42:	60e2                	ld	ra,24(sp)
ffffffffc0204d44:	6442                	ld	s0,16(sp)
ffffffffc0204d46:	64a2                	ld	s1,8(sp)
ffffffffc0204d48:	5575                	li	a0,-3
ffffffffc0204d4a:	6105                	addi	sp,sp,32
ffffffffc0204d4c:	8082                	ret

ffffffffc0204d4e <do_kill>:
{
ffffffffc0204d4e:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d50:	6789                	lui	a5,0x2
{
ffffffffc0204d52:	e406                	sd	ra,8(sp)
ffffffffc0204d54:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d56:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d5a:	17f9                	addi	a5,a5,-2
ffffffffc0204d5c:	02e7e963          	bltu	a5,a4,ffffffffc0204d8e <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d60:	842a                	mv	s0,a0
ffffffffc0204d62:	45a9                	li	a1,10
ffffffffc0204d64:	2501                	sext.w	a0,a0
ffffffffc0204d66:	46c000ef          	jal	ra,ffffffffc02051d2 <hash32>
ffffffffc0204d6a:	02051793          	slli	a5,a0,0x20
ffffffffc0204d6e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204d72:	000a2797          	auipc	a5,0xa2
ffffffffc0204d76:	80678793          	addi	a5,a5,-2042 # ffffffffc02a6578 <hash_list>
ffffffffc0204d7a:	953e                	add	a0,a0,a5
ffffffffc0204d7c:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204d7e:	a029                	j	ffffffffc0204d88 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204d80:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204d84:	00870b63          	beq	a4,s0,ffffffffc0204d9a <do_kill+0x4c>
ffffffffc0204d88:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204d8a:	fef51be3          	bne	a0,a5,ffffffffc0204d80 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204d8e:	5475                	li	s0,-3
}
ffffffffc0204d90:	60a2                	ld	ra,8(sp)
ffffffffc0204d92:	8522                	mv	a0,s0
ffffffffc0204d94:	6402                	ld	s0,0(sp)
ffffffffc0204d96:	0141                	addi	sp,sp,16
ffffffffc0204d98:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204d9a:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204d9e:	00177693          	andi	a3,a4,1
ffffffffc0204da2:	e295                	bnez	a3,ffffffffc0204dc6 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204da4:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204da6:	00176713          	ori	a4,a4,1
ffffffffc0204daa:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204dae:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204db0:	fe06d0e3          	bgez	a3,ffffffffc0204d90 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204db4:	f2878513          	addi	a0,a5,-216
ffffffffc0204db8:	22e000ef          	jal	ra,ffffffffc0204fe6 <wakeup_proc>
}
ffffffffc0204dbc:	60a2                	ld	ra,8(sp)
ffffffffc0204dbe:	8522                	mv	a0,s0
ffffffffc0204dc0:	6402                	ld	s0,0(sp)
ffffffffc0204dc2:	0141                	addi	sp,sp,16
ffffffffc0204dc4:	8082                	ret
        return -E_KILLED;
ffffffffc0204dc6:	545d                	li	s0,-9
ffffffffc0204dc8:	b7e1                	j	ffffffffc0204d90 <do_kill+0x42>

ffffffffc0204dca <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204dca:	1101                	addi	sp,sp,-32
ffffffffc0204dcc:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204dce:	000a5797          	auipc	a5,0xa5
ffffffffc0204dd2:	7aa78793          	addi	a5,a5,1962 # ffffffffc02aa578 <proc_list>
ffffffffc0204dd6:	ec06                	sd	ra,24(sp)
ffffffffc0204dd8:	e822                	sd	s0,16(sp)
ffffffffc0204dda:	e04a                	sd	s2,0(sp)
ffffffffc0204ddc:	000a1497          	auipc	s1,0xa1
ffffffffc0204de0:	79c48493          	addi	s1,s1,1948 # ffffffffc02a6578 <hash_list>
ffffffffc0204de4:	e79c                	sd	a5,8(a5)
ffffffffc0204de6:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204de8:	000a5717          	auipc	a4,0xa5
ffffffffc0204dec:	79070713          	addi	a4,a4,1936 # ffffffffc02aa578 <proc_list>
ffffffffc0204df0:	87a6                	mv	a5,s1
ffffffffc0204df2:	e79c                	sd	a5,8(a5)
ffffffffc0204df4:	e39c                	sd	a5,0(a5)
ffffffffc0204df6:	07c1                	addi	a5,a5,16
ffffffffc0204df8:	fef71de3          	bne	a4,a5,ffffffffc0204df2 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204dfc:	fc7fe0ef          	jal	ra,ffffffffc0203dc2 <alloc_proc>
ffffffffc0204e00:	000a5917          	auipc	s2,0xa5
ffffffffc0204e04:	7f090913          	addi	s2,s2,2032 # ffffffffc02aa5f0 <idleproc>
ffffffffc0204e08:	00a93023          	sd	a0,0(s2)
ffffffffc0204e0c:	0e050f63          	beqz	a0,ffffffffc0204f0a <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e10:	4789                	li	a5,2
ffffffffc0204e12:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e14:	00003797          	auipc	a5,0x3
ffffffffc0204e18:	1ec78793          	addi	a5,a5,492 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e1c:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e20:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204e22:	4785                	li	a5,1
ffffffffc0204e24:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e26:	4641                	li	a2,16
ffffffffc0204e28:	4581                	li	a1,0
ffffffffc0204e2a:	8522                	mv	a0,s0
ffffffffc0204e2c:	04d000ef          	jal	ra,ffffffffc0205678 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e30:	463d                	li	a2,15
ffffffffc0204e32:	00002597          	auipc	a1,0x2
ffffffffc0204e36:	48658593          	addi	a1,a1,1158 # ffffffffc02072b8 <default_pmm_manager+0xdd0>
ffffffffc0204e3a:	8522                	mv	a0,s0
ffffffffc0204e3c:	04f000ef          	jal	ra,ffffffffc020568a <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e40:	000a5717          	auipc	a4,0xa5
ffffffffc0204e44:	7c070713          	addi	a4,a4,1984 # ffffffffc02aa600 <nr_process>
ffffffffc0204e48:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204e4a:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e4e:	4601                	li	a2,0
    nr_process++;
ffffffffc0204e50:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e52:	4581                	li	a1,0
ffffffffc0204e54:	00000517          	auipc	a0,0x0
ffffffffc0204e58:	87450513          	addi	a0,a0,-1932 # ffffffffc02046c8 <init_main>
    nr_process++;
ffffffffc0204e5c:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204e5e:	000a5797          	auipc	a5,0xa5
ffffffffc0204e62:	78d7b523          	sd	a3,1930(a5) # ffffffffc02aa5e8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204e66:	cf6ff0ef          	jal	ra,ffffffffc020435c <kernel_thread>
ffffffffc0204e6a:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204e6c:	08a05363          	blez	a0,ffffffffc0204ef2 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e70:	6789                	lui	a5,0x2
ffffffffc0204e72:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e76:	17f9                	addi	a5,a5,-2
ffffffffc0204e78:	2501                	sext.w	a0,a0
ffffffffc0204e7a:	02e7e363          	bltu	a5,a4,ffffffffc0204ea0 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e7e:	45a9                	li	a1,10
ffffffffc0204e80:	352000ef          	jal	ra,ffffffffc02051d2 <hash32>
ffffffffc0204e84:	02051793          	slli	a5,a0,0x20
ffffffffc0204e88:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204e8c:	96a6                	add	a3,a3,s1
ffffffffc0204e8e:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204e90:	a029                	j	ffffffffc0204e9a <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204e92:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c6c>
ffffffffc0204e96:	04870b63          	beq	a4,s0,ffffffffc0204eec <proc_init+0x122>
    return listelm->next;
ffffffffc0204e9a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204e9c:	fef69be3          	bne	a3,a5,ffffffffc0204e92 <proc_init+0xc8>
    return NULL;
ffffffffc0204ea0:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ea2:	0b478493          	addi	s1,a5,180
ffffffffc0204ea6:	4641                	li	a2,16
ffffffffc0204ea8:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204eaa:	000a5417          	auipc	s0,0xa5
ffffffffc0204eae:	74e40413          	addi	s0,s0,1870 # ffffffffc02aa5f8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204eb2:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204eb4:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204eb6:	7c2000ef          	jal	ra,ffffffffc0205678 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204eba:	463d                	li	a2,15
ffffffffc0204ebc:	00002597          	auipc	a1,0x2
ffffffffc0204ec0:	42458593          	addi	a1,a1,1060 # ffffffffc02072e0 <default_pmm_manager+0xdf8>
ffffffffc0204ec4:	8526                	mv	a0,s1
ffffffffc0204ec6:	7c4000ef          	jal	ra,ffffffffc020568a <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204eca:	00093783          	ld	a5,0(s2)
ffffffffc0204ece:	cbb5                	beqz	a5,ffffffffc0204f42 <proc_init+0x178>
ffffffffc0204ed0:	43dc                	lw	a5,4(a5)
ffffffffc0204ed2:	eba5                	bnez	a5,ffffffffc0204f42 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204ed4:	601c                	ld	a5,0(s0)
ffffffffc0204ed6:	c7b1                	beqz	a5,ffffffffc0204f22 <proc_init+0x158>
ffffffffc0204ed8:	43d8                	lw	a4,4(a5)
ffffffffc0204eda:	4785                	li	a5,1
ffffffffc0204edc:	04f71363          	bne	a4,a5,ffffffffc0204f22 <proc_init+0x158>
}
ffffffffc0204ee0:	60e2                	ld	ra,24(sp)
ffffffffc0204ee2:	6442                	ld	s0,16(sp)
ffffffffc0204ee4:	64a2                	ld	s1,8(sp)
ffffffffc0204ee6:	6902                	ld	s2,0(sp)
ffffffffc0204ee8:	6105                	addi	sp,sp,32
ffffffffc0204eea:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204eec:	f2878793          	addi	a5,a5,-216
ffffffffc0204ef0:	bf4d                	j	ffffffffc0204ea2 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204ef2:	00002617          	auipc	a2,0x2
ffffffffc0204ef6:	3ce60613          	addi	a2,a2,974 # ffffffffc02072c0 <default_pmm_manager+0xdd8>
ffffffffc0204efa:	3fc00593          	li	a1,1020
ffffffffc0204efe:	00002517          	auipc	a0,0x2
ffffffffc0204f02:	05250513          	addi	a0,a0,82 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204f06:	d88fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f0a:	00002617          	auipc	a2,0x2
ffffffffc0204f0e:	39660613          	addi	a2,a2,918 # ffffffffc02072a0 <default_pmm_manager+0xdb8>
ffffffffc0204f12:	3ed00593          	li	a1,1005
ffffffffc0204f16:	00002517          	auipc	a0,0x2
ffffffffc0204f1a:	03a50513          	addi	a0,a0,58 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204f1e:	d70fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f22:	00002697          	auipc	a3,0x2
ffffffffc0204f26:	3ee68693          	addi	a3,a3,1006 # ffffffffc0207310 <default_pmm_manager+0xe28>
ffffffffc0204f2a:	00001617          	auipc	a2,0x1
ffffffffc0204f2e:	20e60613          	addi	a2,a2,526 # ffffffffc0206138 <commands+0x828>
ffffffffc0204f32:	40300593          	li	a1,1027
ffffffffc0204f36:	00002517          	auipc	a0,0x2
ffffffffc0204f3a:	01a50513          	addi	a0,a0,26 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204f3e:	d50fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f42:	00002697          	auipc	a3,0x2
ffffffffc0204f46:	3a668693          	addi	a3,a3,934 # ffffffffc02072e8 <default_pmm_manager+0xe00>
ffffffffc0204f4a:	00001617          	auipc	a2,0x1
ffffffffc0204f4e:	1ee60613          	addi	a2,a2,494 # ffffffffc0206138 <commands+0x828>
ffffffffc0204f52:	40200593          	li	a1,1026
ffffffffc0204f56:	00002517          	auipc	a0,0x2
ffffffffc0204f5a:	ffa50513          	addi	a0,a0,-6 # ffffffffc0206f50 <default_pmm_manager+0xa68>
ffffffffc0204f5e:	d30fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204f62 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204f62:	1141                	addi	sp,sp,-16
ffffffffc0204f64:	e022                	sd	s0,0(sp)
ffffffffc0204f66:	e406                	sd	ra,8(sp)
ffffffffc0204f68:	000a5417          	auipc	s0,0xa5
ffffffffc0204f6c:	68040413          	addi	s0,s0,1664 # ffffffffc02aa5e8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204f70:	6018                	ld	a4,0(s0)
ffffffffc0204f72:	6f1c                	ld	a5,24(a4)
ffffffffc0204f74:	dffd                	beqz	a5,ffffffffc0204f72 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204f76:	0f0000ef          	jal	ra,ffffffffc0205066 <schedule>
ffffffffc0204f7a:	bfdd                	j	ffffffffc0204f70 <cpu_idle+0xe>

ffffffffc0204f7c <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204f7c:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204f80:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204f84:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204f86:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204f88:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204f8c:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204f90:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204f94:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204f98:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204f9c:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204fa0:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204fa4:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204fa8:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204fac:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204fb0:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204fb4:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204fb8:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204fba:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204fbc:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204fc0:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204fc4:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204fc8:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204fcc:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204fd0:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204fd4:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204fd8:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204fdc:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204fe0:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204fe4:	8082                	ret

ffffffffc0204fe6 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204fe6:	4118                	lw	a4,0(a0)
{
ffffffffc0204fe8:	1101                	addi	sp,sp,-32
ffffffffc0204fea:	ec06                	sd	ra,24(sp)
ffffffffc0204fec:	e822                	sd	s0,16(sp)
ffffffffc0204fee:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204ff0:	478d                	li	a5,3
ffffffffc0204ff2:	04f70b63          	beq	a4,a5,ffffffffc0205048 <wakeup_proc+0x62>
ffffffffc0204ff6:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204ff8:	100027f3          	csrr	a5,sstatus
ffffffffc0204ffc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204ffe:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205000:	ef9d                	bnez	a5,ffffffffc020503e <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205002:	4789                	li	a5,2
ffffffffc0205004:	02f70163          	beq	a4,a5,ffffffffc0205026 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205008:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc020500a:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc020500e:	e491                	bnez	s1,ffffffffc020501a <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205010:	60e2                	ld	ra,24(sp)
ffffffffc0205012:	6442                	ld	s0,16(sp)
ffffffffc0205014:	64a2                	ld	s1,8(sp)
ffffffffc0205016:	6105                	addi	sp,sp,32
ffffffffc0205018:	8082                	ret
ffffffffc020501a:	6442                	ld	s0,16(sp)
ffffffffc020501c:	60e2                	ld	ra,24(sp)
ffffffffc020501e:	64a2                	ld	s1,8(sp)
ffffffffc0205020:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205022:	98dfb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205026:	00002617          	auipc	a2,0x2
ffffffffc020502a:	34a60613          	addi	a2,a2,842 # ffffffffc0207370 <default_pmm_manager+0xe88>
ffffffffc020502e:	45d1                	li	a1,20
ffffffffc0205030:	00002517          	auipc	a0,0x2
ffffffffc0205034:	32850513          	addi	a0,a0,808 # ffffffffc0207358 <default_pmm_manager+0xe70>
ffffffffc0205038:	cbefb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc020503c:	bfc9                	j	ffffffffc020500e <wakeup_proc+0x28>
        intr_disable();
ffffffffc020503e:	977fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205042:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205044:	4485                	li	s1,1
ffffffffc0205046:	bf75                	j	ffffffffc0205002 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205048:	00002697          	auipc	a3,0x2
ffffffffc020504c:	2f068693          	addi	a3,a3,752 # ffffffffc0207338 <default_pmm_manager+0xe50>
ffffffffc0205050:	00001617          	auipc	a2,0x1
ffffffffc0205054:	0e860613          	addi	a2,a2,232 # ffffffffc0206138 <commands+0x828>
ffffffffc0205058:	45a5                	li	a1,9
ffffffffc020505a:	00002517          	auipc	a0,0x2
ffffffffc020505e:	2fe50513          	addi	a0,a0,766 # ffffffffc0207358 <default_pmm_manager+0xe70>
ffffffffc0205062:	c2cfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205066 <schedule>:

void schedule(void)
{
ffffffffc0205066:	1141                	addi	sp,sp,-16
ffffffffc0205068:	e406                	sd	ra,8(sp)
ffffffffc020506a:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020506c:	100027f3          	csrr	a5,sstatus
ffffffffc0205070:	8b89                	andi	a5,a5,2
ffffffffc0205072:	4401                	li	s0,0
ffffffffc0205074:	efbd                	bnez	a5,ffffffffc02050f2 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205076:	000a5897          	auipc	a7,0xa5
ffffffffc020507a:	5728b883          	ld	a7,1394(a7) # ffffffffc02aa5e8 <current>
ffffffffc020507e:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205082:	000a5517          	auipc	a0,0xa5
ffffffffc0205086:	56e53503          	ld	a0,1390(a0) # ffffffffc02aa5f0 <idleproc>
ffffffffc020508a:	04a88e63          	beq	a7,a0,ffffffffc02050e6 <schedule+0x80>
ffffffffc020508e:	0c888693          	addi	a3,a7,200
ffffffffc0205092:	000a5617          	auipc	a2,0xa5
ffffffffc0205096:	4e660613          	addi	a2,a2,1254 # ffffffffc02aa578 <proc_list>
        le = last;
ffffffffc020509a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020509c:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc020509e:	4809                	li	a6,2
ffffffffc02050a0:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02050a2:	00c78863          	beq	a5,a2,ffffffffc02050b2 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02050a6:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02050aa:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02050ae:	03070163          	beq	a4,a6,ffffffffc02050d0 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02050b2:	fef697e3          	bne	a3,a5,ffffffffc02050a0 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02050b6:	ed89                	bnez	a1,ffffffffc02050d0 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02050b8:	451c                	lw	a5,8(a0)
ffffffffc02050ba:	2785                	addiw	a5,a5,1
ffffffffc02050bc:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02050be:	00a88463          	beq	a7,a0,ffffffffc02050c6 <schedule+0x60>
        {
            proc_run(next);
ffffffffc02050c2:	e55fe0ef          	jal	ra,ffffffffc0203f16 <proc_run>
    if (flag)
ffffffffc02050c6:	e819                	bnez	s0,ffffffffc02050dc <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02050c8:	60a2                	ld	ra,8(sp)
ffffffffc02050ca:	6402                	ld	s0,0(sp)
ffffffffc02050cc:	0141                	addi	sp,sp,16
ffffffffc02050ce:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02050d0:	4198                	lw	a4,0(a1)
ffffffffc02050d2:	4789                	li	a5,2
ffffffffc02050d4:	fef712e3          	bne	a4,a5,ffffffffc02050b8 <schedule+0x52>
ffffffffc02050d8:	852e                	mv	a0,a1
ffffffffc02050da:	bff9                	j	ffffffffc02050b8 <schedule+0x52>
}
ffffffffc02050dc:	6402                	ld	s0,0(sp)
ffffffffc02050de:	60a2                	ld	ra,8(sp)
ffffffffc02050e0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02050e2:	8cdfb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02050e6:	000a5617          	auipc	a2,0xa5
ffffffffc02050ea:	49260613          	addi	a2,a2,1170 # ffffffffc02aa578 <proc_list>
ffffffffc02050ee:	86b2                	mv	a3,a2
ffffffffc02050f0:	b76d                	j	ffffffffc020509a <schedule+0x34>
        intr_disable();
ffffffffc02050f2:	8c3fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02050f6:	4405                	li	s0,1
ffffffffc02050f8:	bfbd                	j	ffffffffc0205076 <schedule+0x10>

ffffffffc02050fa <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02050fa:	000a5797          	auipc	a5,0xa5
ffffffffc02050fe:	4ee7b783          	ld	a5,1262(a5) # ffffffffc02aa5e8 <current>
}
ffffffffc0205102:	43c8                	lw	a0,4(a5)
ffffffffc0205104:	8082                	ret

ffffffffc0205106 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205106:	4501                	li	a0,0
ffffffffc0205108:	8082                	ret

ffffffffc020510a <sys_putc>:
    cputchar(c);
ffffffffc020510a:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020510c:	1141                	addi	sp,sp,-16
ffffffffc020510e:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205110:	8bafb0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc0205114:	60a2                	ld	ra,8(sp)
ffffffffc0205116:	4501                	li	a0,0
ffffffffc0205118:	0141                	addi	sp,sp,16
ffffffffc020511a:	8082                	ret

ffffffffc020511c <sys_kill>:
    return do_kill(pid);
ffffffffc020511c:	4108                	lw	a0,0(a0)
ffffffffc020511e:	c31ff06f          	j	ffffffffc0204d4e <do_kill>

ffffffffc0205122 <sys_yield>:
    return do_yield();
ffffffffc0205122:	bdfff06f          	j	ffffffffc0204d00 <do_yield>

ffffffffc0205126 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205126:	6d14                	ld	a3,24(a0)
ffffffffc0205128:	6910                	ld	a2,16(a0)
ffffffffc020512a:	650c                	ld	a1,8(a0)
ffffffffc020512c:	6108                	ld	a0,0(a0)
ffffffffc020512e:	ebeff06f          	j	ffffffffc02047ec <do_execve>

ffffffffc0205132 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205132:	650c                	ld	a1,8(a0)
ffffffffc0205134:	4108                	lw	a0,0(a0)
ffffffffc0205136:	bdbff06f          	j	ffffffffc0204d10 <do_wait>

ffffffffc020513a <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020513a:	000a5797          	auipc	a5,0xa5
ffffffffc020513e:	4ae7b783          	ld	a5,1198(a5) # ffffffffc02aa5e8 <current>
ffffffffc0205142:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205144:	4501                	li	a0,0
ffffffffc0205146:	6a0c                	ld	a1,16(a2)
ffffffffc0205148:	e37fe06f          	j	ffffffffc0203f7e <do_fork>

ffffffffc020514c <sys_exit>:
    return do_exit(error_code);
ffffffffc020514c:	4108                	lw	a0,0(a0)
ffffffffc020514e:	a5eff06f          	j	ffffffffc02043ac <do_exit>

ffffffffc0205152 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205152:	715d                	addi	sp,sp,-80
ffffffffc0205154:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205156:	000a5497          	auipc	s1,0xa5
ffffffffc020515a:	49248493          	addi	s1,s1,1170 # ffffffffc02aa5e8 <current>
ffffffffc020515e:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205160:	e0a2                	sd	s0,64(sp)
ffffffffc0205162:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205164:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205166:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205168:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020516a:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020516e:	0327ee63          	bltu	a5,s2,ffffffffc02051aa <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205172:	00391713          	slli	a4,s2,0x3
ffffffffc0205176:	00002797          	auipc	a5,0x2
ffffffffc020517a:	26278793          	addi	a5,a5,610 # ffffffffc02073d8 <syscalls>
ffffffffc020517e:	97ba                	add	a5,a5,a4
ffffffffc0205180:	639c                	ld	a5,0(a5)
ffffffffc0205182:	c785                	beqz	a5,ffffffffc02051aa <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205184:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205186:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205188:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020518a:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc020518c:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020518e:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205190:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205192:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205194:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205196:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205198:	0028                	addi	a0,sp,8
ffffffffc020519a:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020519c:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020519e:	e828                	sd	a0,80(s0)
}
ffffffffc02051a0:	6406                	ld	s0,64(sp)
ffffffffc02051a2:	74e2                	ld	s1,56(sp)
ffffffffc02051a4:	7942                	ld	s2,48(sp)
ffffffffc02051a6:	6161                	addi	sp,sp,80
ffffffffc02051a8:	8082                	ret
    print_trapframe(tf);
ffffffffc02051aa:	8522                	mv	a0,s0
ffffffffc02051ac:	9f9fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02051b0:	609c                	ld	a5,0(s1)
ffffffffc02051b2:	86ca                	mv	a3,s2
ffffffffc02051b4:	00002617          	auipc	a2,0x2
ffffffffc02051b8:	1dc60613          	addi	a2,a2,476 # ffffffffc0207390 <default_pmm_manager+0xea8>
ffffffffc02051bc:	43d8                	lw	a4,4(a5)
ffffffffc02051be:	06200593          	li	a1,98
ffffffffc02051c2:	0b478793          	addi	a5,a5,180
ffffffffc02051c6:	00002517          	auipc	a0,0x2
ffffffffc02051ca:	1fa50513          	addi	a0,a0,506 # ffffffffc02073c0 <default_pmm_manager+0xed8>
ffffffffc02051ce:	ac0fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02051d2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02051d2:	9e3707b7          	lui	a5,0x9e370
ffffffffc02051d6:	2785                	addiw	a5,a5,1
ffffffffc02051d8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02051dc:	02000793          	li	a5,32
ffffffffc02051e0:	9f8d                	subw	a5,a5,a1
}
ffffffffc02051e2:	00f5553b          	srlw	a0,a0,a5
ffffffffc02051e6:	8082                	ret

ffffffffc02051e8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02051e8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02051ec:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02051ee:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02051f2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02051f4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02051f8:	f022                	sd	s0,32(sp)
ffffffffc02051fa:	ec26                	sd	s1,24(sp)
ffffffffc02051fc:	e84a                	sd	s2,16(sp)
ffffffffc02051fe:	f406                	sd	ra,40(sp)
ffffffffc0205200:	e44e                	sd	s3,8(sp)
ffffffffc0205202:	84aa                	mv	s1,a0
ffffffffc0205204:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205206:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020520a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020520c:	03067e63          	bgeu	a2,a6,ffffffffc0205248 <printnum+0x60>
ffffffffc0205210:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205212:	00805763          	blez	s0,ffffffffc0205220 <printnum+0x38>
ffffffffc0205216:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205218:	85ca                	mv	a1,s2
ffffffffc020521a:	854e                	mv	a0,s3
ffffffffc020521c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020521e:	fc65                	bnez	s0,ffffffffc0205216 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205220:	1a02                	slli	s4,s4,0x20
ffffffffc0205222:	00002797          	auipc	a5,0x2
ffffffffc0205226:	2b678793          	addi	a5,a5,694 # ffffffffc02074d8 <syscalls+0x100>
ffffffffc020522a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020522e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205230:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205232:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205236:	70a2                	ld	ra,40(sp)
ffffffffc0205238:	69a2                	ld	s3,8(sp)
ffffffffc020523a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020523c:	85ca                	mv	a1,s2
ffffffffc020523e:	87a6                	mv	a5,s1
}
ffffffffc0205240:	6942                	ld	s2,16(sp)
ffffffffc0205242:	64e2                	ld	s1,24(sp)
ffffffffc0205244:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205246:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205248:	03065633          	divu	a2,a2,a6
ffffffffc020524c:	8722                	mv	a4,s0
ffffffffc020524e:	f9bff0ef          	jal	ra,ffffffffc02051e8 <printnum>
ffffffffc0205252:	b7f9                	j	ffffffffc0205220 <printnum+0x38>

ffffffffc0205254 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205254:	7119                	addi	sp,sp,-128
ffffffffc0205256:	f4a6                	sd	s1,104(sp)
ffffffffc0205258:	f0ca                	sd	s2,96(sp)
ffffffffc020525a:	ecce                	sd	s3,88(sp)
ffffffffc020525c:	e8d2                	sd	s4,80(sp)
ffffffffc020525e:	e4d6                	sd	s5,72(sp)
ffffffffc0205260:	e0da                	sd	s6,64(sp)
ffffffffc0205262:	fc5e                	sd	s7,56(sp)
ffffffffc0205264:	f06a                	sd	s10,32(sp)
ffffffffc0205266:	fc86                	sd	ra,120(sp)
ffffffffc0205268:	f8a2                	sd	s0,112(sp)
ffffffffc020526a:	f862                	sd	s8,48(sp)
ffffffffc020526c:	f466                	sd	s9,40(sp)
ffffffffc020526e:	ec6e                	sd	s11,24(sp)
ffffffffc0205270:	892a                	mv	s2,a0
ffffffffc0205272:	84ae                	mv	s1,a1
ffffffffc0205274:	8d32                	mv	s10,a2
ffffffffc0205276:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205278:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020527c:	5b7d                	li	s6,-1
ffffffffc020527e:	00002a97          	auipc	s5,0x2
ffffffffc0205282:	286a8a93          	addi	s5,s5,646 # ffffffffc0207504 <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205286:	00002b97          	auipc	s7,0x2
ffffffffc020528a:	49ab8b93          	addi	s7,s7,1178 # ffffffffc0207720 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020528e:	000d4503          	lbu	a0,0(s10)
ffffffffc0205292:	001d0413          	addi	s0,s10,1
ffffffffc0205296:	01350a63          	beq	a0,s3,ffffffffc02052aa <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020529a:	c121                	beqz	a0,ffffffffc02052da <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020529c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020529e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02052a0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052a2:	fff44503          	lbu	a0,-1(s0)
ffffffffc02052a6:	ff351ae3          	bne	a0,s3,ffffffffc020529a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052aa:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02052ae:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02052b2:	4c81                	li	s9,0
ffffffffc02052b4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02052b6:	5c7d                	li	s8,-1
ffffffffc02052b8:	5dfd                	li	s11,-1
ffffffffc02052ba:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02052be:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052c0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02052c4:	0ff5f593          	zext.b	a1,a1
ffffffffc02052c8:	00140d13          	addi	s10,s0,1
ffffffffc02052cc:	04b56263          	bltu	a0,a1,ffffffffc0205310 <vprintfmt+0xbc>
ffffffffc02052d0:	058a                	slli	a1,a1,0x2
ffffffffc02052d2:	95d6                	add	a1,a1,s5
ffffffffc02052d4:	4194                	lw	a3,0(a1)
ffffffffc02052d6:	96d6                	add	a3,a3,s5
ffffffffc02052d8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02052da:	70e6                	ld	ra,120(sp)
ffffffffc02052dc:	7446                	ld	s0,112(sp)
ffffffffc02052de:	74a6                	ld	s1,104(sp)
ffffffffc02052e0:	7906                	ld	s2,96(sp)
ffffffffc02052e2:	69e6                	ld	s3,88(sp)
ffffffffc02052e4:	6a46                	ld	s4,80(sp)
ffffffffc02052e6:	6aa6                	ld	s5,72(sp)
ffffffffc02052e8:	6b06                	ld	s6,64(sp)
ffffffffc02052ea:	7be2                	ld	s7,56(sp)
ffffffffc02052ec:	7c42                	ld	s8,48(sp)
ffffffffc02052ee:	7ca2                	ld	s9,40(sp)
ffffffffc02052f0:	7d02                	ld	s10,32(sp)
ffffffffc02052f2:	6de2                	ld	s11,24(sp)
ffffffffc02052f4:	6109                	addi	sp,sp,128
ffffffffc02052f6:	8082                	ret
            padc = '0';
ffffffffc02052f8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02052fa:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052fe:	846a                	mv	s0,s10
ffffffffc0205300:	00140d13          	addi	s10,s0,1
ffffffffc0205304:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205308:	0ff5f593          	zext.b	a1,a1
ffffffffc020530c:	fcb572e3          	bgeu	a0,a1,ffffffffc02052d0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205310:	85a6                	mv	a1,s1
ffffffffc0205312:	02500513          	li	a0,37
ffffffffc0205316:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205318:	fff44783          	lbu	a5,-1(s0)
ffffffffc020531c:	8d22                	mv	s10,s0
ffffffffc020531e:	f73788e3          	beq	a5,s3,ffffffffc020528e <vprintfmt+0x3a>
ffffffffc0205322:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205326:	1d7d                	addi	s10,s10,-1
ffffffffc0205328:	ff379de3          	bne	a5,s3,ffffffffc0205322 <vprintfmt+0xce>
ffffffffc020532c:	b78d                	j	ffffffffc020528e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020532e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205332:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205336:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205338:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020533c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205340:	02d86463          	bltu	a6,a3,ffffffffc0205368 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205344:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205348:	002c169b          	slliw	a3,s8,0x2
ffffffffc020534c:	0186873b          	addw	a4,a3,s8
ffffffffc0205350:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205354:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205356:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020535a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020535c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205360:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205364:	fed870e3          	bgeu	a6,a3,ffffffffc0205344 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205368:	f40ddce3          	bgez	s11,ffffffffc02052c0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020536c:	8de2                	mv	s11,s8
ffffffffc020536e:	5c7d                	li	s8,-1
ffffffffc0205370:	bf81                	j	ffffffffc02052c0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205372:	fffdc693          	not	a3,s11
ffffffffc0205376:	96fd                	srai	a3,a3,0x3f
ffffffffc0205378:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020537c:	00144603          	lbu	a2,1(s0)
ffffffffc0205380:	2d81                	sext.w	s11,s11
ffffffffc0205382:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205384:	bf35                	j	ffffffffc02052c0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205386:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020538a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020538e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205390:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205392:	bfd9                	j	ffffffffc0205368 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205394:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205396:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020539a:	01174463          	blt	a4,a7,ffffffffc02053a2 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020539e:	1a088e63          	beqz	a7,ffffffffc020555a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02053a2:	000a3603          	ld	a2,0(s4)
ffffffffc02053a6:	46c1                	li	a3,16
ffffffffc02053a8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02053aa:	2781                	sext.w	a5,a5
ffffffffc02053ac:	876e                	mv	a4,s11
ffffffffc02053ae:	85a6                	mv	a1,s1
ffffffffc02053b0:	854a                	mv	a0,s2
ffffffffc02053b2:	e37ff0ef          	jal	ra,ffffffffc02051e8 <printnum>
            break;
ffffffffc02053b6:	bde1                	j	ffffffffc020528e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02053b8:	000a2503          	lw	a0,0(s4)
ffffffffc02053bc:	85a6                	mv	a1,s1
ffffffffc02053be:	0a21                	addi	s4,s4,8
ffffffffc02053c0:	9902                	jalr	s2
            break;
ffffffffc02053c2:	b5f1                	j	ffffffffc020528e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02053c4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053c6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02053ca:	01174463          	blt	a4,a7,ffffffffc02053d2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02053ce:	18088163          	beqz	a7,ffffffffc0205550 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02053d2:	000a3603          	ld	a2,0(s4)
ffffffffc02053d6:	46a9                	li	a3,10
ffffffffc02053d8:	8a2e                	mv	s4,a1
ffffffffc02053da:	bfc1                	j	ffffffffc02053aa <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053dc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02053e0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02053e4:	bdf1                	j	ffffffffc02052c0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02053e6:	85a6                	mv	a1,s1
ffffffffc02053e8:	02500513          	li	a0,37
ffffffffc02053ec:	9902                	jalr	s2
            break;
ffffffffc02053ee:	b545                	j	ffffffffc020528e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053f0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02053f4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053f6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02053f8:	b5e1                	j	ffffffffc02052c0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02053fa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053fc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205400:	01174463          	blt	a4,a7,ffffffffc0205408 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205404:	14088163          	beqz	a7,ffffffffc0205546 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205408:	000a3603          	ld	a2,0(s4)
ffffffffc020540c:	46a1                	li	a3,8
ffffffffc020540e:	8a2e                	mv	s4,a1
ffffffffc0205410:	bf69                	j	ffffffffc02053aa <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205412:	03000513          	li	a0,48
ffffffffc0205416:	85a6                	mv	a1,s1
ffffffffc0205418:	e03e                	sd	a5,0(sp)
ffffffffc020541a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020541c:	85a6                	mv	a1,s1
ffffffffc020541e:	07800513          	li	a0,120
ffffffffc0205422:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205424:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205426:	6782                	ld	a5,0(sp)
ffffffffc0205428:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020542a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020542e:	bfb5                	j	ffffffffc02053aa <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205430:	000a3403          	ld	s0,0(s4)
ffffffffc0205434:	008a0713          	addi	a4,s4,8
ffffffffc0205438:	e03a                	sd	a4,0(sp)
ffffffffc020543a:	14040263          	beqz	s0,ffffffffc020557e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020543e:	0fb05763          	blez	s11,ffffffffc020552c <vprintfmt+0x2d8>
ffffffffc0205442:	02d00693          	li	a3,45
ffffffffc0205446:	0cd79163          	bne	a5,a3,ffffffffc0205508 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020544a:	00044783          	lbu	a5,0(s0)
ffffffffc020544e:	0007851b          	sext.w	a0,a5
ffffffffc0205452:	cf85                	beqz	a5,ffffffffc020548a <vprintfmt+0x236>
ffffffffc0205454:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205458:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020545c:	000c4563          	bltz	s8,ffffffffc0205466 <vprintfmt+0x212>
ffffffffc0205460:	3c7d                	addiw	s8,s8,-1
ffffffffc0205462:	036c0263          	beq	s8,s6,ffffffffc0205486 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205466:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205468:	0e0c8e63          	beqz	s9,ffffffffc0205564 <vprintfmt+0x310>
ffffffffc020546c:	3781                	addiw	a5,a5,-32
ffffffffc020546e:	0ef47b63          	bgeu	s0,a5,ffffffffc0205564 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205472:	03f00513          	li	a0,63
ffffffffc0205476:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205478:	000a4783          	lbu	a5,0(s4)
ffffffffc020547c:	3dfd                	addiw	s11,s11,-1
ffffffffc020547e:	0a05                	addi	s4,s4,1
ffffffffc0205480:	0007851b          	sext.w	a0,a5
ffffffffc0205484:	ffe1                	bnez	a5,ffffffffc020545c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205486:	01b05963          	blez	s11,ffffffffc0205498 <vprintfmt+0x244>
ffffffffc020548a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020548c:	85a6                	mv	a1,s1
ffffffffc020548e:	02000513          	li	a0,32
ffffffffc0205492:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205494:	fe0d9be3          	bnez	s11,ffffffffc020548a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205498:	6a02                	ld	s4,0(sp)
ffffffffc020549a:	bbd5                	j	ffffffffc020528e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020549c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020549e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02054a2:	01174463          	blt	a4,a7,ffffffffc02054aa <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02054a6:	08088d63          	beqz	a7,ffffffffc0205540 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02054aa:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02054ae:	0a044d63          	bltz	s0,ffffffffc0205568 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02054b2:	8622                	mv	a2,s0
ffffffffc02054b4:	8a66                	mv	s4,s9
ffffffffc02054b6:	46a9                	li	a3,10
ffffffffc02054b8:	bdcd                	j	ffffffffc02053aa <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02054ba:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02054be:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02054c0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02054c2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02054c6:	8fb5                	xor	a5,a5,a3
ffffffffc02054c8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02054cc:	02d74163          	blt	a4,a3,ffffffffc02054ee <vprintfmt+0x29a>
ffffffffc02054d0:	00369793          	slli	a5,a3,0x3
ffffffffc02054d4:	97de                	add	a5,a5,s7
ffffffffc02054d6:	639c                	ld	a5,0(a5)
ffffffffc02054d8:	cb99                	beqz	a5,ffffffffc02054ee <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02054da:	86be                	mv	a3,a5
ffffffffc02054dc:	00000617          	auipc	a2,0x0
ffffffffc02054e0:	1f460613          	addi	a2,a2,500 # ffffffffc02056d0 <etext+0x2e>
ffffffffc02054e4:	85a6                	mv	a1,s1
ffffffffc02054e6:	854a                	mv	a0,s2
ffffffffc02054e8:	0ce000ef          	jal	ra,ffffffffc02055b6 <printfmt>
ffffffffc02054ec:	b34d                	j	ffffffffc020528e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02054ee:	00002617          	auipc	a2,0x2
ffffffffc02054f2:	00a60613          	addi	a2,a2,10 # ffffffffc02074f8 <syscalls+0x120>
ffffffffc02054f6:	85a6                	mv	a1,s1
ffffffffc02054f8:	854a                	mv	a0,s2
ffffffffc02054fa:	0bc000ef          	jal	ra,ffffffffc02055b6 <printfmt>
ffffffffc02054fe:	bb41                	j	ffffffffc020528e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205500:	00002417          	auipc	s0,0x2
ffffffffc0205504:	ff040413          	addi	s0,s0,-16 # ffffffffc02074f0 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205508:	85e2                	mv	a1,s8
ffffffffc020550a:	8522                	mv	a0,s0
ffffffffc020550c:	e43e                	sd	a5,8(sp)
ffffffffc020550e:	0e2000ef          	jal	ra,ffffffffc02055f0 <strnlen>
ffffffffc0205512:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205516:	01b05b63          	blez	s11,ffffffffc020552c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020551a:	67a2                	ld	a5,8(sp)
ffffffffc020551c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205520:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205522:	85a6                	mv	a1,s1
ffffffffc0205524:	8552                	mv	a0,s4
ffffffffc0205526:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205528:	fe0d9ce3          	bnez	s11,ffffffffc0205520 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020552c:	00044783          	lbu	a5,0(s0)
ffffffffc0205530:	00140a13          	addi	s4,s0,1
ffffffffc0205534:	0007851b          	sext.w	a0,a5
ffffffffc0205538:	d3a5                	beqz	a5,ffffffffc0205498 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020553a:	05e00413          	li	s0,94
ffffffffc020553e:	bf39                	j	ffffffffc020545c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205540:	000a2403          	lw	s0,0(s4)
ffffffffc0205544:	b7ad                	j	ffffffffc02054ae <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205546:	000a6603          	lwu	a2,0(s4)
ffffffffc020554a:	46a1                	li	a3,8
ffffffffc020554c:	8a2e                	mv	s4,a1
ffffffffc020554e:	bdb1                	j	ffffffffc02053aa <vprintfmt+0x156>
ffffffffc0205550:	000a6603          	lwu	a2,0(s4)
ffffffffc0205554:	46a9                	li	a3,10
ffffffffc0205556:	8a2e                	mv	s4,a1
ffffffffc0205558:	bd89                	j	ffffffffc02053aa <vprintfmt+0x156>
ffffffffc020555a:	000a6603          	lwu	a2,0(s4)
ffffffffc020555e:	46c1                	li	a3,16
ffffffffc0205560:	8a2e                	mv	s4,a1
ffffffffc0205562:	b5a1                	j	ffffffffc02053aa <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205564:	9902                	jalr	s2
ffffffffc0205566:	bf09                	j	ffffffffc0205478 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205568:	85a6                	mv	a1,s1
ffffffffc020556a:	02d00513          	li	a0,45
ffffffffc020556e:	e03e                	sd	a5,0(sp)
ffffffffc0205570:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205572:	6782                	ld	a5,0(sp)
ffffffffc0205574:	8a66                	mv	s4,s9
ffffffffc0205576:	40800633          	neg	a2,s0
ffffffffc020557a:	46a9                	li	a3,10
ffffffffc020557c:	b53d                	j	ffffffffc02053aa <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020557e:	03b05163          	blez	s11,ffffffffc02055a0 <vprintfmt+0x34c>
ffffffffc0205582:	02d00693          	li	a3,45
ffffffffc0205586:	f6d79de3          	bne	a5,a3,ffffffffc0205500 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020558a:	00002417          	auipc	s0,0x2
ffffffffc020558e:	f6640413          	addi	s0,s0,-154 # ffffffffc02074f0 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205592:	02800793          	li	a5,40
ffffffffc0205596:	02800513          	li	a0,40
ffffffffc020559a:	00140a13          	addi	s4,s0,1
ffffffffc020559e:	bd6d                	j	ffffffffc0205458 <vprintfmt+0x204>
ffffffffc02055a0:	00002a17          	auipc	s4,0x2
ffffffffc02055a4:	f51a0a13          	addi	s4,s4,-175 # ffffffffc02074f1 <syscalls+0x119>
ffffffffc02055a8:	02800513          	li	a0,40
ffffffffc02055ac:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055b0:	05e00413          	li	s0,94
ffffffffc02055b4:	b565                	j	ffffffffc020545c <vprintfmt+0x208>

ffffffffc02055b6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055b6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02055b8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055bc:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02055be:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055c0:	ec06                	sd	ra,24(sp)
ffffffffc02055c2:	f83a                	sd	a4,48(sp)
ffffffffc02055c4:	fc3e                	sd	a5,56(sp)
ffffffffc02055c6:	e0c2                	sd	a6,64(sp)
ffffffffc02055c8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02055ca:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02055cc:	c89ff0ef          	jal	ra,ffffffffc0205254 <vprintfmt>
}
ffffffffc02055d0:	60e2                	ld	ra,24(sp)
ffffffffc02055d2:	6161                	addi	sp,sp,80
ffffffffc02055d4:	8082                	ret

ffffffffc02055d6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02055d6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02055da:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02055dc:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02055de:	cb81                	beqz	a5,ffffffffc02055ee <strlen+0x18>
        cnt ++;
ffffffffc02055e0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02055e2:	00a707b3          	add	a5,a4,a0
ffffffffc02055e6:	0007c783          	lbu	a5,0(a5)
ffffffffc02055ea:	fbfd                	bnez	a5,ffffffffc02055e0 <strlen+0xa>
ffffffffc02055ec:	8082                	ret
    }
    return cnt;
}
ffffffffc02055ee:	8082                	ret

ffffffffc02055f0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02055f0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02055f2:	e589                	bnez	a1,ffffffffc02055fc <strnlen+0xc>
ffffffffc02055f4:	a811                	j	ffffffffc0205608 <strnlen+0x18>
        cnt ++;
ffffffffc02055f6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02055f8:	00f58863          	beq	a1,a5,ffffffffc0205608 <strnlen+0x18>
ffffffffc02055fc:	00f50733          	add	a4,a0,a5
ffffffffc0205600:	00074703          	lbu	a4,0(a4)
ffffffffc0205604:	fb6d                	bnez	a4,ffffffffc02055f6 <strnlen+0x6>
ffffffffc0205606:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205608:	852e                	mv	a0,a1
ffffffffc020560a:	8082                	ret

ffffffffc020560c <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020560c:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020560e:	0005c703          	lbu	a4,0(a1)
ffffffffc0205612:	0785                	addi	a5,a5,1
ffffffffc0205614:	0585                	addi	a1,a1,1
ffffffffc0205616:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020561a:	fb75                	bnez	a4,ffffffffc020560e <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020561c:	8082                	ret

ffffffffc020561e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020561e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205622:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205626:	cb89                	beqz	a5,ffffffffc0205638 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205628:	0505                	addi	a0,a0,1
ffffffffc020562a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020562c:	fee789e3          	beq	a5,a4,ffffffffc020561e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205630:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205634:	9d19                	subw	a0,a0,a4
ffffffffc0205636:	8082                	ret
ffffffffc0205638:	4501                	li	a0,0
ffffffffc020563a:	bfed                	j	ffffffffc0205634 <strcmp+0x16>

ffffffffc020563c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020563c:	c20d                	beqz	a2,ffffffffc020565e <strncmp+0x22>
ffffffffc020563e:	962e                	add	a2,a2,a1
ffffffffc0205640:	a031                	j	ffffffffc020564c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205642:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205644:	00e79a63          	bne	a5,a4,ffffffffc0205658 <strncmp+0x1c>
ffffffffc0205648:	00b60b63          	beq	a2,a1,ffffffffc020565e <strncmp+0x22>
ffffffffc020564c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205650:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205652:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205656:	f7f5                	bnez	a5,ffffffffc0205642 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205658:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020565c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020565e:	4501                	li	a0,0
ffffffffc0205660:	8082                	ret

ffffffffc0205662 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205662:	00054783          	lbu	a5,0(a0)
ffffffffc0205666:	c799                	beqz	a5,ffffffffc0205674 <strchr+0x12>
        if (*s == c) {
ffffffffc0205668:	00f58763          	beq	a1,a5,ffffffffc0205676 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020566c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205670:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205672:	fbfd                	bnez	a5,ffffffffc0205668 <strchr+0x6>
    }
    return NULL;
ffffffffc0205674:	4501                	li	a0,0
}
ffffffffc0205676:	8082                	ret

ffffffffc0205678 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205678:	ca01                	beqz	a2,ffffffffc0205688 <memset+0x10>
ffffffffc020567a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020567c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020567e:	0785                	addi	a5,a5,1
ffffffffc0205680:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205684:	fec79de3          	bne	a5,a2,ffffffffc020567e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205688:	8082                	ret

ffffffffc020568a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020568a:	ca19                	beqz	a2,ffffffffc02056a0 <memcpy+0x16>
ffffffffc020568c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020568e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205690:	0005c703          	lbu	a4,0(a1)
ffffffffc0205694:	0585                	addi	a1,a1,1
ffffffffc0205696:	0785                	addi	a5,a5,1
ffffffffc0205698:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020569c:	fec59ae3          	bne	a1,a2,ffffffffc0205690 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02056a0:	8082                	ret
