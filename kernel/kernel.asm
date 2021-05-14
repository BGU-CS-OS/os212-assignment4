
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	bbc78793          	addi	a5,a5,-1092 # 80005c20 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(struct inode *ip, int user_src, uint64 src, int off, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04e05663          	blez	a4,80000152 <consolewrite+0x5e>
    8000010a:	8a2e                	mv	s4,a1
    8000010c:	84b2                	mv	s1,a2
    8000010e:	89ba                	mv	s3,a4
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	322080e7          	jalr	802(ra) # 80002440 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(struct inode *ip, int user_dst, uint64 dst, int off, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aae                	mv	s5,a1
    80000174:	8a32                	mv	s4,a2
    80000176:	89ba                	mv	s3,a4
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00070b1b          	sext.w	s6,a4
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7d4080e7          	jalr	2004(ra) # 80001986 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e84080e7          	jalr	-380(ra) # 80002046 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	1ec080e7          	jalr	492(ra) # 800023ea <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	1b8080e7          	jalr	440(ra) # 80002496 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	da0080e7          	jalr	-608(ra) # 800021d2 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	fb98                	sd	a4,48(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ff98                	sd	a4,56(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	954080e7          	jalr	-1708(ra) # 800021d2 <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	73c080e7          	jalr	1852(ra) # 80002046 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e0e080e7          	jalr	-498(ra) # 8000196a <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	ddc080e7          	jalr	-548(ra) # 8000196a <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dd0080e7          	jalr	-560(ra) # 8000196a <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	db8080e7          	jalr	-584(ra) # 8000196a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	d78080e7          	jalr	-648(ra) # 8000196a <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d4c080e7          	jalr	-692(ra) # 8000196a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	ae6080e7          	jalr	-1306(ra) # 8000195a <cpuid>
    procfsinit();    // procfs file system
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	aca080e7          	jalr	-1334(ra) # 8000195a <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0e0080e7          	jalr	224(ra) # 80000f8a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	798080e7          	jalr	1944(ra) # 8000264a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	da6080e7          	jalr	-602(ra) # 80005c60 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fd2080e7          	jalr	-46(ra) # 80001e94 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	318080e7          	jalr	792(ra) # 8000122a <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	070080e7          	jalr	112(ra) # 80000f8a <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	988080e7          	jalr	-1656(ra) # 800018aa <procinit>
    trapinit();      // trap vectors
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	6f8080e7          	jalr	1784(ra) # 80002622 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	718080e7          	jalr	1816(ra) # 8000264a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	d10080e7          	jalr	-752(ra) # 80005c4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	d1e080e7          	jalr	-738(ra) # 80005c60 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	e40080e7          	jalr	-448(ra) # 80002d8a <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	4d2080e7          	jalr	1234(ra) # 80003424 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	520080e7          	jalr	1312(ra) # 8000447a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e20080e7          	jalr	-480(ra) # 80005d82 <virtio_disk_init>
    procfsinit();    // procfs file system
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	612080e7          	jalr	1554(ra) # 8000257c <procfsinit>
    userinit();      // first user process
    80000f72:	00001097          	auipc	ra,0x1
    80000f76:	cec080e7          	jalr	-788(ra) # 80001c5e <userinit>
    __sync_synchronize();
    80000f7a:	0ff0000f          	fence
    started = 1;
    80000f7e:	4785                	li	a5,1
    80000f80:	00008717          	auipc	a4,0x8
    80000f84:	08f72c23          	sw	a5,152(a4) # 80009018 <started>
    80000f88:	bf2d                	j	80000ec2 <main+0x56>

0000000080000f8a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8a:	1141                	addi	sp,sp,-16
    80000f8c:	e422                	sd	s0,8(sp)
    80000f8e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f90:	00008797          	auipc	a5,0x8
    80000f94:	0907b783          	ld	a5,144(a5) # 80009020 <kernel_pagetable>
    80000f98:	83b1                	srli	a5,a5,0xc
    80000f9a:	577d                	li	a4,-1
    80000f9c:	177e                	slli	a4,a4,0x3f
    80000f9e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa8:	6422                	ld	s0,8(sp)
    80000faa:	0141                	addi	sp,sp,16
    80000fac:	8082                	ret

0000000080000fae <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fae:	7139                	addi	sp,sp,-64
    80000fb0:	fc06                	sd	ra,56(sp)
    80000fb2:	f822                	sd	s0,48(sp)
    80000fb4:	f426                	sd	s1,40(sp)
    80000fb6:	f04a                	sd	s2,32(sp)
    80000fb8:	ec4e                	sd	s3,24(sp)
    80000fba:	e852                	sd	s4,16(sp)
    80000fbc:	e456                	sd	s5,8(sp)
    80000fbe:	e05a                	sd	s6,0(sp)
    80000fc0:	0080                	addi	s0,sp,64
    80000fc2:	84aa                	mv	s1,a0
    80000fc4:	89ae                	mv	s3,a1
    80000fc6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc8:	57fd                	li	a5,-1
    80000fca:	83e9                	srli	a5,a5,0x1a
    80000fcc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fce:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd0:	04b7f263          	bgeu	a5,a1,80001014 <walk+0x66>
    panic("walk");
    80000fd4:	00007517          	auipc	a0,0x7
    80000fd8:	0fc50513          	addi	a0,a0,252 # 800080d0 <digits+0x90>
    80000fdc:	fffff097          	auipc	ra,0xfffff
    80000fe0:	54e080e7          	jalr	1358(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe4:	060a8663          	beqz	s5,80001050 <walk+0xa2>
    80000fe8:	00000097          	auipc	ra,0x0
    80000fec:	aea080e7          	jalr	-1302(ra) # 80000ad2 <kalloc>
    80000ff0:	84aa                	mv	s1,a0
    80000ff2:	c529                	beqz	a0,8000103c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff4:	6605                	lui	a2,0x1
    80000ff6:	4581                	li	a1,0
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	cc6080e7          	jalr	-826(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001000:	00c4d793          	srli	a5,s1,0xc
    80001004:	07aa                	slli	a5,a5,0xa
    80001006:	0017e793          	ori	a5,a5,1
    8000100a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100e:	3a5d                	addiw	s4,s4,-9
    80001010:	036a0063          	beq	s4,s6,80001030 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001014:	0149d933          	srl	s2,s3,s4
    80001018:	1ff97913          	andi	s2,s2,511
    8000101c:	090e                	slli	s2,s2,0x3
    8000101e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001020:	00093483          	ld	s1,0(s2)
    80001024:	0014f793          	andi	a5,s1,1
    80001028:	dfd5                	beqz	a5,80000fe4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102a:	80a9                	srli	s1,s1,0xa
    8000102c:	04b2                	slli	s1,s1,0xc
    8000102e:	b7c5                	j	8000100e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001030:	00c9d513          	srli	a0,s3,0xc
    80001034:	1ff57513          	andi	a0,a0,511
    80001038:	050e                	slli	a0,a0,0x3
    8000103a:	9526                	add	a0,a0,s1
}
    8000103c:	70e2                	ld	ra,56(sp)
    8000103e:	7442                	ld	s0,48(sp)
    80001040:	74a2                	ld	s1,40(sp)
    80001042:	7902                	ld	s2,32(sp)
    80001044:	69e2                	ld	s3,24(sp)
    80001046:	6a42                	ld	s4,16(sp)
    80001048:	6aa2                	ld	s5,8(sp)
    8000104a:	6b02                	ld	s6,0(sp)
    8000104c:	6121                	addi	sp,sp,64
    8000104e:	8082                	ret
        return 0;
    80001050:	4501                	li	a0,0
    80001052:	b7ed                	j	8000103c <walk+0x8e>

0000000080001054 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001054:	57fd                	li	a5,-1
    80001056:	83e9                	srli	a5,a5,0x1a
    80001058:	00b7f463          	bgeu	a5,a1,80001060 <walkaddr+0xc>
    return 0;
    8000105c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105e:	8082                	ret
{
    80001060:	1141                	addi	sp,sp,-16
    80001062:	e406                	sd	ra,8(sp)
    80001064:	e022                	sd	s0,0(sp)
    80001066:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001068:	4601                	li	a2,0
    8000106a:	00000097          	auipc	ra,0x0
    8000106e:	f44080e7          	jalr	-188(ra) # 80000fae <walk>
  if(pte == 0)
    80001072:	c105                	beqz	a0,80001092 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001074:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001076:	0117f693          	andi	a3,a5,17
    8000107a:	4745                	li	a4,17
    return 0;
    8000107c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107e:	00e68663          	beq	a3,a4,8000108a <walkaddr+0x36>
}
    80001082:	60a2                	ld	ra,8(sp)
    80001084:	6402                	ld	s0,0(sp)
    80001086:	0141                	addi	sp,sp,16
    80001088:	8082                	ret
  pa = PTE2PA(*pte);
    8000108a:	00a7d513          	srli	a0,a5,0xa
    8000108e:	0532                	slli	a0,a0,0xc
  return pa;
    80001090:	bfcd                	j	80001082 <walkaddr+0x2e>
    return 0;
    80001092:	4501                	li	a0,0
    80001094:	b7fd                	j	80001082 <walkaddr+0x2e>

0000000080001096 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001096:	715d                	addi	sp,sp,-80
    80001098:	e486                	sd	ra,72(sp)
    8000109a:	e0a2                	sd	s0,64(sp)
    8000109c:	fc26                	sd	s1,56(sp)
    8000109e:	f84a                	sd	s2,48(sp)
    800010a0:	f44e                	sd	s3,40(sp)
    800010a2:	f052                	sd	s4,32(sp)
    800010a4:	ec56                	sd	s5,24(sp)
    800010a6:	e85a                	sd	s6,16(sp)
    800010a8:	e45e                	sd	s7,8(sp)
    800010aa:	0880                	addi	s0,sp,80
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	167d                	addi	a2,a2,-1
    800010b8:	00b609b3          	add	s3,a2,a1
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	edc080e7          	jalr	-292(ra) # 80000fae <walk>
    800010da:	c51d                	beqz	a0,80001108 <mappages+0x72>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	ef81                	bnez	a5,800010f8 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	03390863          	beq	s2,s3,80001120 <mappages+0x8a>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x32>
      panic("remap");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	42a080e7          	jalr	1066(ra) # 8000052a <panic>
      return -1;
    80001108:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000110a:	60a6                	ld	ra,72(sp)
    8000110c:	6406                	ld	s0,64(sp)
    8000110e:	74e2                	ld	s1,56(sp)
    80001110:	7942                	ld	s2,48(sp)
    80001112:	79a2                	ld	s3,40(sp)
    80001114:	7a02                	ld	s4,32(sp)
    80001116:	6ae2                	ld	s5,24(sp)
    80001118:	6b42                	ld	s6,16(sp)
    8000111a:	6ba2                	ld	s7,8(sp)
    8000111c:	6161                	addi	sp,sp,80
    8000111e:	8082                	ret
  return 0;
    80001120:	4501                	li	a0,0
    80001122:	b7e5                	j	8000110a <mappages+0x74>

0000000080001124 <kvmmap>:
{
    80001124:	1141                	addi	sp,sp,-16
    80001126:	e406                	sd	ra,8(sp)
    80001128:	e022                	sd	s0,0(sp)
    8000112a:	0800                	addi	s0,sp,16
    8000112c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000112e:	86b2                	mv	a3,a2
    80001130:	863e                	mv	a2,a5
    80001132:	00000097          	auipc	ra,0x0
    80001136:	f64080e7          	jalr	-156(ra) # 80001096 <mappages>
    8000113a:	e509                	bnez	a0,80001144 <kvmmap+0x20>
}
    8000113c:	60a2                	ld	ra,8(sp)
    8000113e:	6402                	ld	s0,0(sp)
    80001140:	0141                	addi	sp,sp,16
    80001142:	8082                	ret
    panic("kvmmap");
    80001144:	00007517          	auipc	a0,0x7
    80001148:	f9c50513          	addi	a0,a0,-100 # 800080e0 <digits+0xa0>
    8000114c:	fffff097          	auipc	ra,0xfffff
    80001150:	3de080e7          	jalr	990(ra) # 8000052a <panic>

0000000080001154 <kvmmake>:
{
    80001154:	1101                	addi	sp,sp,-32
    80001156:	ec06                	sd	ra,24(sp)
    80001158:	e822                	sd	s0,16(sp)
    8000115a:	e426                	sd	s1,8(sp)
    8000115c:	e04a                	sd	s2,0(sp)
    8000115e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001160:	00000097          	auipc	ra,0x0
    80001164:	972080e7          	jalr	-1678(ra) # 80000ad2 <kalloc>
    80001168:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000116a:	6605                	lui	a2,0x1
    8000116c:	4581                	li	a1,0
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	b50080e7          	jalr	-1200(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001176:	4719                	li	a4,6
    80001178:	6685                	lui	a3,0x1
    8000117a:	10000637          	lui	a2,0x10000
    8000117e:	100005b7          	lui	a1,0x10000
    80001182:	8526                	mv	a0,s1
    80001184:	00000097          	auipc	ra,0x0
    80001188:	fa0080e7          	jalr	-96(ra) # 80001124 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000118c:	4719                	li	a4,6
    8000118e:	6685                	lui	a3,0x1
    80001190:	10001637          	lui	a2,0x10001
    80001194:	100015b7          	lui	a1,0x10001
    80001198:	8526                	mv	a0,s1
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	f8a080e7          	jalr	-118(ra) # 80001124 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	004006b7          	lui	a3,0x400
    800011a8:	0c000637          	lui	a2,0xc000
    800011ac:	0c0005b7          	lui	a1,0xc000
    800011b0:	8526                	mv	a0,s1
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	f72080e7          	jalr	-142(ra) # 80001124 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ba:	00007917          	auipc	s2,0x7
    800011be:	e4690913          	addi	s2,s2,-442 # 80008000 <etext>
    800011c2:	4729                	li	a4,10
    800011c4:	80007697          	auipc	a3,0x80007
    800011c8:	e3c68693          	addi	a3,a3,-452 # 8000 <_entry-0x7fff8000>
    800011cc:	4605                	li	a2,1
    800011ce:	067e                	slli	a2,a2,0x1f
    800011d0:	85b2                	mv	a1,a2
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f50080e7          	jalr	-176(ra) # 80001124 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	46c5                	li	a3,17
    800011e0:	06ee                	slli	a3,a3,0x1b
    800011e2:	412686b3          	sub	a3,a3,s2
    800011e6:	864a                	mv	a2,s2
    800011e8:	85ca                	mv	a1,s2
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f38080e7          	jalr	-200(ra) # 80001124 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011f4:	4729                	li	a4,10
    800011f6:	6685                	lui	a3,0x1
    800011f8:	00006617          	auipc	a2,0x6
    800011fc:	e0860613          	addi	a2,a2,-504 # 80007000 <_trampoline>
    80001200:	040005b7          	lui	a1,0x4000
    80001204:	15fd                	addi	a1,a1,-1
    80001206:	05b2                	slli	a1,a1,0xc
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f1a080e7          	jalr	-230(ra) # 80001124 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001212:	8526                	mv	a0,s1
    80001214:	00000097          	auipc	ra,0x0
    80001218:	600080e7          	jalr	1536(ra) # 80001814 <proc_mapstacks>
}
    8000121c:	8526                	mv	a0,s1
    8000121e:	60e2                	ld	ra,24(sp)
    80001220:	6442                	ld	s0,16(sp)
    80001222:	64a2                	ld	s1,8(sp)
    80001224:	6902                	ld	s2,0(sp)
    80001226:	6105                	addi	sp,sp,32
    80001228:	8082                	ret

000000008000122a <kvminit>:
{
    8000122a:	1141                	addi	sp,sp,-16
    8000122c:	e406                	sd	ra,8(sp)
    8000122e:	e022                	sd	s0,0(sp)
    80001230:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001232:	00000097          	auipc	ra,0x0
    80001236:	f22080e7          	jalr	-222(ra) # 80001154 <kvmmake>
    8000123a:	00008797          	auipc	a5,0x8
    8000123e:	dea7b323          	sd	a0,-538(a5) # 80009020 <kernel_pagetable>
}
    80001242:	60a2                	ld	ra,8(sp)
    80001244:	6402                	ld	s0,0(sp)
    80001246:	0141                	addi	sp,sp,16
    80001248:	8082                	ret

000000008000124a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000124a:	715d                	addi	sp,sp,-80
    8000124c:	e486                	sd	ra,72(sp)
    8000124e:	e0a2                	sd	s0,64(sp)
    80001250:	fc26                	sd	s1,56(sp)
    80001252:	f84a                	sd	s2,48(sp)
    80001254:	f44e                	sd	s3,40(sp)
    80001256:	f052                	sd	s4,32(sp)
    80001258:	ec56                	sd	s5,24(sp)
    8000125a:	e85a                	sd	s6,16(sp)
    8000125c:	e45e                	sd	s7,8(sp)
    8000125e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001260:	03459793          	slli	a5,a1,0x34
    80001264:	e795                	bnez	a5,80001290 <uvmunmap+0x46>
    80001266:	8a2a                	mv	s4,a0
    80001268:	892e                	mv	s2,a1
    8000126a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	0632                	slli	a2,a2,0xc
    8000126e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001272:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001274:	6b05                	lui	s6,0x1
    80001276:	0735e263          	bltu	a1,s3,800012da <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000127a:	60a6                	ld	ra,72(sp)
    8000127c:	6406                	ld	s0,64(sp)
    8000127e:	74e2                	ld	s1,56(sp)
    80001280:	7942                	ld	s2,48(sp)
    80001282:	79a2                	ld	s3,40(sp)
    80001284:	7a02                	ld	s4,32(sp)
    80001286:	6ae2                	ld	s5,24(sp)
    80001288:	6b42                	ld	s6,16(sp)
    8000128a:	6ba2                	ld	s7,8(sp)
    8000128c:	6161                	addi	sp,sp,80
    8000128e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001290:	00007517          	auipc	a0,0x7
    80001294:	e5850513          	addi	a0,a0,-424 # 800080e8 <digits+0xa8>
    80001298:	fffff097          	auipc	ra,0xfffff
    8000129c:	292080e7          	jalr	658(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	282080e7          	jalr	642(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6050513          	addi	a0,a0,-416 # 80008110 <digits+0xd0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	272080e7          	jalr	626(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	262080e7          	jalr	610(ra) # 8000052a <panic>
    *pte = 0;
    800012d0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d4:	995a                	add	s2,s2,s6
    800012d6:	fb3972e3          	bgeu	s2,s3,8000127a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012da:	4601                	li	a2,0
    800012dc:	85ca                	mv	a1,s2
    800012de:	8552                	mv	a0,s4
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	cce080e7          	jalr	-818(ra) # 80000fae <walk>
    800012e8:	84aa                	mv	s1,a0
    800012ea:	d95d                	beqz	a0,800012a0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012ec:	6108                	ld	a0,0(a0)
    800012ee:	00157793          	andi	a5,a0,1
    800012f2:	dfdd                	beqz	a5,800012b0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f4:	3ff57793          	andi	a5,a0,1023
    800012f8:	fd7784e3          	beq	a5,s7,800012c0 <uvmunmap+0x76>
    if(do_free){
    800012fc:	fc0a8ae3          	beqz	s5,800012d0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001300:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001302:	0532                	slli	a0,a0,0xc
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	6d2080e7          	jalr	1746(ra) # 800009d6 <kfree>
    8000130c:	b7d1                	j	800012d0 <uvmunmap+0x86>

000000008000130e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000130e:	1101                	addi	sp,sp,-32
    80001310:	ec06                	sd	ra,24(sp)
    80001312:	e822                	sd	s0,16(sp)
    80001314:	e426                	sd	s1,8(sp)
    80001316:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	7ba080e7          	jalr	1978(ra) # 80000ad2 <kalloc>
    80001320:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001322:	c519                	beqz	a0,80001330 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001324:	6605                	lui	a2,0x1
    80001326:	4581                	li	a1,0
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	996080e7          	jalr	-1642(ra) # 80000cbe <memset>
  return pagetable;
}
    80001330:	8526                	mv	a0,s1
    80001332:	60e2                	ld	ra,24(sp)
    80001334:	6442                	ld	s0,16(sp)
    80001336:	64a2                	ld	s1,8(sp)
    80001338:	6105                	addi	sp,sp,32
    8000133a:	8082                	ret

000000008000133c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000133c:	7179                	addi	sp,sp,-48
    8000133e:	f406                	sd	ra,40(sp)
    80001340:	f022                	sd	s0,32(sp)
    80001342:	ec26                	sd	s1,24(sp)
    80001344:	e84a                	sd	s2,16(sp)
    80001346:	e44e                	sd	s3,8(sp)
    80001348:	e052                	sd	s4,0(sp)
    8000134a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000134c:	6785                	lui	a5,0x1
    8000134e:	04f67863          	bgeu	a2,a5,8000139e <uvminit+0x62>
    80001352:	8a2a                	mv	s4,a0
    80001354:	89ae                	mv	s3,a1
    80001356:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001358:	fffff097          	auipc	ra,0xfffff
    8000135c:	77a080e7          	jalr	1914(ra) # 80000ad2 <kalloc>
    80001360:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001362:	6605                	lui	a2,0x1
    80001364:	4581                	li	a1,0
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	958080e7          	jalr	-1704(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000136e:	4779                	li	a4,30
    80001370:	86ca                	mv	a3,s2
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	8552                	mv	a0,s4
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	d1e080e7          	jalr	-738(ra) # 80001096 <mappages>
  memmove(mem, src, sz);
    80001380:	8626                	mv	a2,s1
    80001382:	85ce                	mv	a1,s3
    80001384:	854a                	mv	a0,s2
    80001386:	00000097          	auipc	ra,0x0
    8000138a:	994080e7          	jalr	-1644(ra) # 80000d1a <memmove>
}
    8000138e:	70a2                	ld	ra,40(sp)
    80001390:	7402                	ld	s0,32(sp)
    80001392:	64e2                	ld	s1,24(sp)
    80001394:	6942                	ld	s2,16(sp)
    80001396:	69a2                	ld	s3,8(sp)
    80001398:	6a02                	ld	s4,0(sp)
    8000139a:	6145                	addi	sp,sp,48
    8000139c:	8082                	ret
    panic("inituvm: more than a page");
    8000139e:	00007517          	auipc	a0,0x7
    800013a2:	da250513          	addi	a0,a0,-606 # 80008140 <digits+0x100>
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	184080e7          	jalr	388(ra) # 8000052a <panic>

00000000800013ae <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ae:	1101                	addi	sp,sp,-32
    800013b0:	ec06                	sd	ra,24(sp)
    800013b2:	e822                	sd	s0,16(sp)
    800013b4:	e426                	sd	s1,8(sp)
    800013b6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ba:	00b67d63          	bgeu	a2,a1,800013d4 <uvmdealloc+0x26>
    800013be:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c0:	6785                	lui	a5,0x1
    800013c2:	17fd                	addi	a5,a5,-1
    800013c4:	00f60733          	add	a4,a2,a5
    800013c8:	767d                	lui	a2,0xfffff
    800013ca:	8f71                	and	a4,a4,a2
    800013cc:	97ae                	add	a5,a5,a1
    800013ce:	8ff1                	and	a5,a5,a2
    800013d0:	00f76863          	bltu	a4,a5,800013e0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d4:	8526                	mv	a0,s1
    800013d6:	60e2                	ld	ra,24(sp)
    800013d8:	6442                	ld	s0,16(sp)
    800013da:	64a2                	ld	s1,8(sp)
    800013dc:	6105                	addi	sp,sp,32
    800013de:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e0:	8f99                	sub	a5,a5,a4
    800013e2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e4:	4685                	li	a3,1
    800013e6:	0007861b          	sext.w	a2,a5
    800013ea:	85ba                	mv	a1,a4
    800013ec:	00000097          	auipc	ra,0x0
    800013f0:	e5e080e7          	jalr	-418(ra) # 8000124a <uvmunmap>
    800013f4:	b7c5                	j	800013d4 <uvmdealloc+0x26>

00000000800013f6 <uvmalloc>:
  if(newsz < oldsz)
    800013f6:	0ab66163          	bltu	a2,a1,80001498 <uvmalloc+0xa2>
{
    800013fa:	7139                	addi	sp,sp,-64
    800013fc:	fc06                	sd	ra,56(sp)
    800013fe:	f822                	sd	s0,48(sp)
    80001400:	f426                	sd	s1,40(sp)
    80001402:	f04a                	sd	s2,32(sp)
    80001404:	ec4e                	sd	s3,24(sp)
    80001406:	e852                	sd	s4,16(sp)
    80001408:	e456                	sd	s5,8(sp)
    8000140a:	0080                	addi	s0,sp,64
    8000140c:	8aaa                	mv	s5,a0
    8000140e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001410:	6985                	lui	s3,0x1
    80001412:	19fd                	addi	s3,s3,-1
    80001414:	95ce                	add	a1,a1,s3
    80001416:	79fd                	lui	s3,0xfffff
    80001418:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000141c:	08c9f063          	bgeu	s3,a2,8000149c <uvmalloc+0xa6>
    80001420:	894e                	mv	s2,s3
    mem = kalloc();
    80001422:	fffff097          	auipc	ra,0xfffff
    80001426:	6b0080e7          	jalr	1712(ra) # 80000ad2 <kalloc>
    8000142a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000142c:	c51d                	beqz	a0,8000145a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000142e:	6605                	lui	a2,0x1
    80001430:	4581                	li	a1,0
    80001432:	00000097          	auipc	ra,0x0
    80001436:	88c080e7          	jalr	-1908(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000143a:	4779                	li	a4,30
    8000143c:	86a6                	mv	a3,s1
    8000143e:	6605                	lui	a2,0x1
    80001440:	85ca                	mv	a1,s2
    80001442:	8556                	mv	a0,s5
    80001444:	00000097          	auipc	ra,0x0
    80001448:	c52080e7          	jalr	-942(ra) # 80001096 <mappages>
    8000144c:	e905                	bnez	a0,8000147c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000144e:	6785                	lui	a5,0x1
    80001450:	993e                	add	s2,s2,a5
    80001452:	fd4968e3          	bltu	s2,s4,80001422 <uvmalloc+0x2c>
  return newsz;
    80001456:	8552                	mv	a0,s4
    80001458:	a809                	j	8000146a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000145a:	864e                	mv	a2,s3
    8000145c:	85ca                	mv	a1,s2
    8000145e:	8556                	mv	a0,s5
    80001460:	00000097          	auipc	ra,0x0
    80001464:	f4e080e7          	jalr	-178(ra) # 800013ae <uvmdealloc>
      return 0;
    80001468:	4501                	li	a0,0
}
    8000146a:	70e2                	ld	ra,56(sp)
    8000146c:	7442                	ld	s0,48(sp)
    8000146e:	74a2                	ld	s1,40(sp)
    80001470:	7902                	ld	s2,32(sp)
    80001472:	69e2                	ld	s3,24(sp)
    80001474:	6a42                	ld	s4,16(sp)
    80001476:	6aa2                	ld	s5,8(sp)
    80001478:	6121                	addi	sp,sp,64
    8000147a:	8082                	ret
      kfree(mem);
    8000147c:	8526                	mv	a0,s1
    8000147e:	fffff097          	auipc	ra,0xfffff
    80001482:	558080e7          	jalr	1368(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f22080e7          	jalr	-222(ra) # 800013ae <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
    80001496:	bfd1                	j	8000146a <uvmalloc+0x74>
    return oldsz;
    80001498:	852e                	mv	a0,a1
}
    8000149a:	8082                	ret
  return newsz;
    8000149c:	8532                	mv	a0,a2
    8000149e:	b7f1                	j	8000146a <uvmalloc+0x74>

00000000800014a0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014a0:	7179                	addi	sp,sp,-48
    800014a2:	f406                	sd	ra,40(sp)
    800014a4:	f022                	sd	s0,32(sp)
    800014a6:	ec26                	sd	s1,24(sp)
    800014a8:	e84a                	sd	s2,16(sp)
    800014aa:	e44e                	sd	s3,8(sp)
    800014ac:	e052                	sd	s4,0(sp)
    800014ae:	1800                	addi	s0,sp,48
    800014b0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014b2:	84aa                	mv	s1,a0
    800014b4:	6905                	lui	s2,0x1
    800014b6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b8:	4985                	li	s3,1
    800014ba:	a821                	j	800014d2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014bc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014be:	0532                	slli	a0,a0,0xc
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	fe0080e7          	jalr	-32(ra) # 800014a0 <freewalk>
      pagetable[i] = 0;
    800014c8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014cc:	04a1                	addi	s1,s1,8
    800014ce:	03248163          	beq	s1,s2,800014f0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014d2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	00f57793          	andi	a5,a0,15
    800014d8:	ff3782e3          	beq	a5,s3,800014bc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014dc:	8905                	andi	a0,a0,1
    800014de:	d57d                	beqz	a0,800014cc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014e0:	00007517          	auipc	a0,0x7
    800014e4:	c8050513          	addi	a0,a0,-896 # 80008160 <digits+0x120>
    800014e8:	fffff097          	auipc	ra,0xfffff
    800014ec:	042080e7          	jalr	66(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014f0:	8552                	mv	a0,s4
    800014f2:	fffff097          	auipc	ra,0xfffff
    800014f6:	4e4080e7          	jalr	1252(ra) # 800009d6 <kfree>
}
    800014fa:	70a2                	ld	ra,40(sp)
    800014fc:	7402                	ld	s0,32(sp)
    800014fe:	64e2                	ld	s1,24(sp)
    80001500:	6942                	ld	s2,16(sp)
    80001502:	69a2                	ld	s3,8(sp)
    80001504:	6a02                	ld	s4,0(sp)
    80001506:	6145                	addi	sp,sp,48
    80001508:	8082                	ret

000000008000150a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000150a:	1101                	addi	sp,sp,-32
    8000150c:	ec06                	sd	ra,24(sp)
    8000150e:	e822                	sd	s0,16(sp)
    80001510:	e426                	sd	s1,8(sp)
    80001512:	1000                	addi	s0,sp,32
    80001514:	84aa                	mv	s1,a0
  if(sz > 0)
    80001516:	e999                	bnez	a1,8000152c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001518:	8526                	mv	a0,s1
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	f86080e7          	jalr	-122(ra) # 800014a0 <freewalk>
}
    80001522:	60e2                	ld	ra,24(sp)
    80001524:	6442                	ld	s0,16(sp)
    80001526:	64a2                	ld	s1,8(sp)
    80001528:	6105                	addi	sp,sp,32
    8000152a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000152c:	6605                	lui	a2,0x1
    8000152e:	167d                	addi	a2,a2,-1
    80001530:	962e                	add	a2,a2,a1
    80001532:	4685                	li	a3,1
    80001534:	8231                	srli	a2,a2,0xc
    80001536:	4581                	li	a1,0
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	d12080e7          	jalr	-750(ra) # 8000124a <uvmunmap>
    80001540:	bfe1                	j	80001518 <uvmfree+0xe>

0000000080001542 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001542:	c679                	beqz	a2,80001610 <uvmcopy+0xce>
{
    80001544:	715d                	addi	sp,sp,-80
    80001546:	e486                	sd	ra,72(sp)
    80001548:	e0a2                	sd	s0,64(sp)
    8000154a:	fc26                	sd	s1,56(sp)
    8000154c:	f84a                	sd	s2,48(sp)
    8000154e:	f44e                	sd	s3,40(sp)
    80001550:	f052                	sd	s4,32(sp)
    80001552:	ec56                	sd	s5,24(sp)
    80001554:	e85a                	sd	s6,16(sp)
    80001556:	e45e                	sd	s7,8(sp)
    80001558:	0880                	addi	s0,sp,80
    8000155a:	8b2a                	mv	s6,a0
    8000155c:	8aae                	mv	s5,a1
    8000155e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001560:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001562:	4601                	li	a2,0
    80001564:	85ce                	mv	a1,s3
    80001566:	855a                	mv	a0,s6
    80001568:	00000097          	auipc	ra,0x0
    8000156c:	a46080e7          	jalr	-1466(ra) # 80000fae <walk>
    80001570:	c531                	beqz	a0,800015bc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001572:	6118                	ld	a4,0(a0)
    80001574:	00177793          	andi	a5,a4,1
    80001578:	cbb1                	beqz	a5,800015cc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000157a:	00a75593          	srli	a1,a4,0xa
    8000157e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001582:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	54c080e7          	jalr	1356(ra) # 80000ad2 <kalloc>
    8000158e:	892a                	mv	s2,a0
    80001590:	c939                	beqz	a0,800015e6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001592:	6605                	lui	a2,0x1
    80001594:	85de                	mv	a1,s7
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	784080e7          	jalr	1924(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000159e:	8726                	mv	a4,s1
    800015a0:	86ca                	mv	a3,s2
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85ce                	mv	a1,s3
    800015a6:	8556                	mv	a0,s5
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	aee080e7          	jalr	-1298(ra) # 80001096 <mappages>
    800015b0:	e515                	bnez	a0,800015dc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015b2:	6785                	lui	a5,0x1
    800015b4:	99be                	add	s3,s3,a5
    800015b6:	fb49e6e3          	bltu	s3,s4,80001562 <uvmcopy+0x20>
    800015ba:	a081                	j	800015fa <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015bc:	00007517          	auipc	a0,0x7
    800015c0:	bb450513          	addi	a0,a0,-1100 # 80008170 <digits+0x130>
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	f66080e7          	jalr	-154(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bc450513          	addi	a0,a0,-1084 # 80008190 <digits+0x150>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f56080e7          	jalr	-170(ra) # 8000052a <panic>
      kfree(mem);
    800015dc:	854a                	mv	a0,s2
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	3f8080e7          	jalr	1016(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015e6:	4685                	li	a3,1
    800015e8:	00c9d613          	srli	a2,s3,0xc
    800015ec:	4581                	li	a1,0
    800015ee:	8556                	mv	a0,s5
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	c5a080e7          	jalr	-934(ra) # 8000124a <uvmunmap>
  return -1;
    800015f8:	557d                	li	a0,-1
}
    800015fa:	60a6                	ld	ra,72(sp)
    800015fc:	6406                	ld	s0,64(sp)
    800015fe:	74e2                	ld	s1,56(sp)
    80001600:	7942                	ld	s2,48(sp)
    80001602:	79a2                	ld	s3,40(sp)
    80001604:	7a02                	ld	s4,32(sp)
    80001606:	6ae2                	ld	s5,24(sp)
    80001608:	6b42                	ld	s6,16(sp)
    8000160a:	6ba2                	ld	s7,8(sp)
    8000160c:	6161                	addi	sp,sp,80
    8000160e:	8082                	ret
  return 0;
    80001610:	4501                	li	a0,0
}
    80001612:	8082                	ret

0000000080001614 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001614:	1141                	addi	sp,sp,-16
    80001616:	e406                	sd	ra,8(sp)
    80001618:	e022                	sd	s0,0(sp)
    8000161a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000161c:	4601                	li	a2,0
    8000161e:	00000097          	auipc	ra,0x0
    80001622:	990080e7          	jalr	-1648(ra) # 80000fae <walk>
  if(pte == 0)
    80001626:	c901                	beqz	a0,80001636 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001628:	611c                	ld	a5,0(a0)
    8000162a:	9bbd                	andi	a5,a5,-17
    8000162c:	e11c                	sd	a5,0(a0)
}
    8000162e:	60a2                	ld	ra,8(sp)
    80001630:	6402                	ld	s0,0(sp)
    80001632:	0141                	addi	sp,sp,16
    80001634:	8082                	ret
    panic("uvmclear");
    80001636:	00007517          	auipc	a0,0x7
    8000163a:	b7a50513          	addi	a0,a0,-1158 # 800081b0 <digits+0x170>
    8000163e:	fffff097          	auipc	ra,0xfffff
    80001642:	eec080e7          	jalr	-276(ra) # 8000052a <panic>

0000000080001646 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001646:	c6bd                	beqz	a3,800016b4 <copyout+0x6e>
{
    80001648:	715d                	addi	sp,sp,-80
    8000164a:	e486                	sd	ra,72(sp)
    8000164c:	e0a2                	sd	s0,64(sp)
    8000164e:	fc26                	sd	s1,56(sp)
    80001650:	f84a                	sd	s2,48(sp)
    80001652:	f44e                	sd	s3,40(sp)
    80001654:	f052                	sd	s4,32(sp)
    80001656:	ec56                	sd	s5,24(sp)
    80001658:	e85a                	sd	s6,16(sp)
    8000165a:	e45e                	sd	s7,8(sp)
    8000165c:	e062                	sd	s8,0(sp)
    8000165e:	0880                	addi	s0,sp,80
    80001660:	8b2a                	mv	s6,a0
    80001662:	8c2e                	mv	s8,a1
    80001664:	8a32                	mv	s4,a2
    80001666:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001668:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000166a:	6a85                	lui	s5,0x1
    8000166c:	a015                	j	80001690 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000166e:	9562                	add	a0,a0,s8
    80001670:	0004861b          	sext.w	a2,s1
    80001674:	85d2                	mv	a1,s4
    80001676:	41250533          	sub	a0,a0,s2
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	6a0080e7          	jalr	1696(ra) # 80000d1a <memmove>

    len -= n;
    80001682:	409989b3          	sub	s3,s3,s1
    src += n;
    80001686:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001688:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000168c:	02098263          	beqz	s3,800016b0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001690:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001694:	85ca                	mv	a1,s2
    80001696:	855a                	mv	a0,s6
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	9bc080e7          	jalr	-1604(ra) # 80001054 <walkaddr>
    if(pa0 == 0)
    800016a0:	cd01                	beqz	a0,800016b8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016a2:	418904b3          	sub	s1,s2,s8
    800016a6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a8:	fc99f3e3          	bgeu	s3,s1,8000166e <copyout+0x28>
    800016ac:	84ce                	mv	s1,s3
    800016ae:	b7c1                	j	8000166e <copyout+0x28>
  }
  return 0;
    800016b0:	4501                	li	a0,0
    800016b2:	a021                	j	800016ba <copyout+0x74>
    800016b4:	4501                	li	a0,0
}
    800016b6:	8082                	ret
      return -1;
    800016b8:	557d                	li	a0,-1
}
    800016ba:	60a6                	ld	ra,72(sp)
    800016bc:	6406                	ld	s0,64(sp)
    800016be:	74e2                	ld	s1,56(sp)
    800016c0:	7942                	ld	s2,48(sp)
    800016c2:	79a2                	ld	s3,40(sp)
    800016c4:	7a02                	ld	s4,32(sp)
    800016c6:	6ae2                	ld	s5,24(sp)
    800016c8:	6b42                	ld	s6,16(sp)
    800016ca:	6ba2                	ld	s7,8(sp)
    800016cc:	6c02                	ld	s8,0(sp)
    800016ce:	6161                	addi	sp,sp,80
    800016d0:	8082                	ret

00000000800016d2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016d2:	caa5                	beqz	a3,80001742 <copyin+0x70>
{
    800016d4:	715d                	addi	sp,sp,-80
    800016d6:	e486                	sd	ra,72(sp)
    800016d8:	e0a2                	sd	s0,64(sp)
    800016da:	fc26                	sd	s1,56(sp)
    800016dc:	f84a                	sd	s2,48(sp)
    800016de:	f44e                	sd	s3,40(sp)
    800016e0:	f052                	sd	s4,32(sp)
    800016e2:	ec56                	sd	s5,24(sp)
    800016e4:	e85a                	sd	s6,16(sp)
    800016e6:	e45e                	sd	s7,8(sp)
    800016e8:	e062                	sd	s8,0(sp)
    800016ea:	0880                	addi	s0,sp,80
    800016ec:	8b2a                	mv	s6,a0
    800016ee:	8a2e                	mv	s4,a1
    800016f0:	8c32                	mv	s8,a2
    800016f2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016f4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016f6:	6a85                	lui	s5,0x1
    800016f8:	a01d                	j	8000171e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016fa:	018505b3          	add	a1,a0,s8
    800016fe:	0004861b          	sext.w	a2,s1
    80001702:	412585b3          	sub	a1,a1,s2
    80001706:	8552                	mv	a0,s4
    80001708:	fffff097          	auipc	ra,0xfffff
    8000170c:	612080e7          	jalr	1554(ra) # 80000d1a <memmove>

    len -= n;
    80001710:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001714:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001716:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000171a:	02098263          	beqz	s3,8000173e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000171e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001722:	85ca                	mv	a1,s2
    80001724:	855a                	mv	a0,s6
    80001726:	00000097          	auipc	ra,0x0
    8000172a:	92e080e7          	jalr	-1746(ra) # 80001054 <walkaddr>
    if(pa0 == 0)
    8000172e:	cd01                	beqz	a0,80001746 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001730:	418904b3          	sub	s1,s2,s8
    80001734:	94d6                	add	s1,s1,s5
    if(n > len)
    80001736:	fc99f2e3          	bgeu	s3,s1,800016fa <copyin+0x28>
    8000173a:	84ce                	mv	s1,s3
    8000173c:	bf7d                	j	800016fa <copyin+0x28>
  }
  return 0;
    8000173e:	4501                	li	a0,0
    80001740:	a021                	j	80001748 <copyin+0x76>
    80001742:	4501                	li	a0,0
}
    80001744:	8082                	ret
      return -1;
    80001746:	557d                	li	a0,-1
}
    80001748:	60a6                	ld	ra,72(sp)
    8000174a:	6406                	ld	s0,64(sp)
    8000174c:	74e2                	ld	s1,56(sp)
    8000174e:	7942                	ld	s2,48(sp)
    80001750:	79a2                	ld	s3,40(sp)
    80001752:	7a02                	ld	s4,32(sp)
    80001754:	6ae2                	ld	s5,24(sp)
    80001756:	6b42                	ld	s6,16(sp)
    80001758:	6ba2                	ld	s7,8(sp)
    8000175a:	6c02                	ld	s8,0(sp)
    8000175c:	6161                	addi	sp,sp,80
    8000175e:	8082                	ret

0000000080001760 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001760:	c6c5                	beqz	a3,80001808 <copyinstr+0xa8>
{
    80001762:	715d                	addi	sp,sp,-80
    80001764:	e486                	sd	ra,72(sp)
    80001766:	e0a2                	sd	s0,64(sp)
    80001768:	fc26                	sd	s1,56(sp)
    8000176a:	f84a                	sd	s2,48(sp)
    8000176c:	f44e                	sd	s3,40(sp)
    8000176e:	f052                	sd	s4,32(sp)
    80001770:	ec56                	sd	s5,24(sp)
    80001772:	e85a                	sd	s6,16(sp)
    80001774:	e45e                	sd	s7,8(sp)
    80001776:	0880                	addi	s0,sp,80
    80001778:	8a2a                	mv	s4,a0
    8000177a:	8b2e                	mv	s6,a1
    8000177c:	8bb2                	mv	s7,a2
    8000177e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001780:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001782:	6985                	lui	s3,0x1
    80001784:	a035                	j	800017b0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001786:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000178a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000178c:	0017b793          	seqz	a5,a5
    80001790:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001794:	60a6                	ld	ra,72(sp)
    80001796:	6406                	ld	s0,64(sp)
    80001798:	74e2                	ld	s1,56(sp)
    8000179a:	7942                	ld	s2,48(sp)
    8000179c:	79a2                	ld	s3,40(sp)
    8000179e:	7a02                	ld	s4,32(sp)
    800017a0:	6ae2                	ld	s5,24(sp)
    800017a2:	6b42                	ld	s6,16(sp)
    800017a4:	6ba2                	ld	s7,8(sp)
    800017a6:	6161                	addi	sp,sp,80
    800017a8:	8082                	ret
    srcva = va0 + PGSIZE;
    800017aa:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ae:	c8a9                	beqz	s1,80001800 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017b0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017b4:	85ca                	mv	a1,s2
    800017b6:	8552                	mv	a0,s4
    800017b8:	00000097          	auipc	ra,0x0
    800017bc:	89c080e7          	jalr	-1892(ra) # 80001054 <walkaddr>
    if(pa0 == 0)
    800017c0:	c131                	beqz	a0,80001804 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017c2:	41790833          	sub	a6,s2,s7
    800017c6:	984e                	add	a6,a6,s3
    if(n > max)
    800017c8:	0104f363          	bgeu	s1,a6,800017ce <copyinstr+0x6e>
    800017cc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ce:	955e                	add	a0,a0,s7
    800017d0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017d4:	fc080be3          	beqz	a6,800017aa <copyinstr+0x4a>
    800017d8:	985a                	add	a6,a6,s6
    800017da:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017dc:	41650633          	sub	a2,a0,s6
    800017e0:	14fd                	addi	s1,s1,-1
    800017e2:	9b26                	add	s6,s6,s1
    800017e4:	00f60733          	add	a4,a2,a5
    800017e8:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017ec:	df49                	beqz	a4,80001786 <copyinstr+0x26>
        *dst = *p;
    800017ee:	00e78023          	sb	a4,0(a5)
      --max;
    800017f2:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017f6:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f8:	ff0796e3          	bne	a5,a6,800017e4 <copyinstr+0x84>
      dst++;
    800017fc:	8b42                	mv	s6,a6
    800017fe:	b775                	j	800017aa <copyinstr+0x4a>
    80001800:	4781                	li	a5,0
    80001802:	b769                	j	8000178c <copyinstr+0x2c>
      return -1;
    80001804:	557d                	li	a0,-1
    80001806:	b779                	j	80001794 <copyinstr+0x34>
  int got_null = 0;
    80001808:	4781                	li	a5,0
  if(got_null){
    8000180a:	0017b793          	seqz	a5,a5
    8000180e:	40f00533          	neg	a0,a5
}
    80001812:	8082                	ret

0000000080001814 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001814:	7139                	addi	sp,sp,-64
    80001816:	fc06                	sd	ra,56(sp)
    80001818:	f822                	sd	s0,48(sp)
    8000181a:	f426                	sd	s1,40(sp)
    8000181c:	f04a                	sd	s2,32(sp)
    8000181e:	ec4e                	sd	s3,24(sp)
    80001820:	e852                	sd	s4,16(sp)
    80001822:	e456                	sd	s5,8(sp)
    80001824:	e05a                	sd	s6,0(sp)
    80001826:	0080                	addi	s0,sp,64
    80001828:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000182a:	00010497          	auipc	s1,0x10
    8000182e:	ea648493          	addi	s1,s1,-346 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001832:	8b26                	mv	s6,s1
    80001834:	00006a97          	auipc	s5,0x6
    80001838:	7cca8a93          	addi	s5,s5,1996 # 80008000 <etext>
    8000183c:	04000937          	lui	s2,0x4000
    80001840:	197d                	addi	s2,s2,-1
    80001842:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001844:	00016a17          	auipc	s4,0x16
    80001848:	88ca0a13          	addi	s4,s4,-1908 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000184c:	fffff097          	auipc	ra,0xfffff
    80001850:	286080e7          	jalr	646(ra) # 80000ad2 <kalloc>
    80001854:	862a                	mv	a2,a0
    if(pa == 0)
    80001856:	c131                	beqz	a0,8000189a <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001858:	416485b3          	sub	a1,s1,s6
    8000185c:	858d                	srai	a1,a1,0x3
    8000185e:	000ab783          	ld	a5,0(s5)
    80001862:	02f585b3          	mul	a1,a1,a5
    80001866:	2585                	addiw	a1,a1,1
    80001868:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000186c:	4719                	li	a4,6
    8000186e:	6685                	lui	a3,0x1
    80001870:	40b905b3          	sub	a1,s2,a1
    80001874:	854e                	mv	a0,s3
    80001876:	00000097          	auipc	ra,0x0
    8000187a:	8ae080e7          	jalr	-1874(ra) # 80001124 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187e:	16848493          	addi	s1,s1,360
    80001882:	fd4495e3          	bne	s1,s4,8000184c <proc_mapstacks+0x38>
  }
}
    80001886:	70e2                	ld	ra,56(sp)
    80001888:	7442                	ld	s0,48(sp)
    8000188a:	74a2                	ld	s1,40(sp)
    8000188c:	7902                	ld	s2,32(sp)
    8000188e:	69e2                	ld	s3,24(sp)
    80001890:	6a42                	ld	s4,16(sp)
    80001892:	6aa2                	ld	s5,8(sp)
    80001894:	6b02                	ld	s6,0(sp)
    80001896:	6121                	addi	sp,sp,64
    80001898:	8082                	ret
      panic("kalloc");
    8000189a:	00007517          	auipc	a0,0x7
    8000189e:	92650513          	addi	a0,a0,-1754 # 800081c0 <digits+0x180>
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	c88080e7          	jalr	-888(ra) # 8000052a <panic>

00000000800018aa <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018aa:	7139                	addi	sp,sp,-64
    800018ac:	fc06                	sd	ra,56(sp)
    800018ae:	f822                	sd	s0,48(sp)
    800018b0:	f426                	sd	s1,40(sp)
    800018b2:	f04a                	sd	s2,32(sp)
    800018b4:	ec4e                	sd	s3,24(sp)
    800018b6:	e852                	sd	s4,16(sp)
    800018b8:	e456                	sd	s5,8(sp)
    800018ba:	e05a                	sd	s6,0(sp)
    800018bc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018be:	00007597          	auipc	a1,0x7
    800018c2:	90a58593          	addi	a1,a1,-1782 # 800081c8 <digits+0x188>
    800018c6:	00010517          	auipc	a0,0x10
    800018ca:	9da50513          	addi	a0,a0,-1574 # 800112a0 <pid_lock>
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	264080e7          	jalr	612(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018d6:	00007597          	auipc	a1,0x7
    800018da:	8fa58593          	addi	a1,a1,-1798 # 800081d0 <digits+0x190>
    800018de:	00010517          	auipc	a0,0x10
    800018e2:	9da50513          	addi	a0,a0,-1574 # 800112b8 <wait_lock>
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	24c080e7          	jalr	588(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ee:	00010497          	auipc	s1,0x10
    800018f2:	de248493          	addi	s1,s1,-542 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    800018f6:	00007b17          	auipc	s6,0x7
    800018fa:	8eab0b13          	addi	s6,s6,-1814 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    800018fe:	8aa6                	mv	s5,s1
    80001900:	00006a17          	auipc	s4,0x6
    80001904:	700a0a13          	addi	s4,s4,1792 # 80008000 <etext>
    80001908:	04000937          	lui	s2,0x4000
    8000190c:	197d                	addi	s2,s2,-1
    8000190e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00015997          	auipc	s3,0x15
    80001914:	7c098993          	addi	s3,s3,1984 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001918:	85da                	mv	a1,s6
    8000191a:	8526                	mv	a0,s1
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	216080e7          	jalr	534(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001924:	415487b3          	sub	a5,s1,s5
    80001928:	878d                	srai	a5,a5,0x3
    8000192a:	000a3703          	ld	a4,0(s4)
    8000192e:	02e787b3          	mul	a5,a5,a4
    80001932:	2785                	addiw	a5,a5,1
    80001934:	00d7979b          	slliw	a5,a5,0xd
    80001938:	40f907b3          	sub	a5,s2,a5
    8000193c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193e:	16848493          	addi	s1,s1,360
    80001942:	fd349be3          	bne	s1,s3,80001918 <procinit+0x6e>
  }
}
    80001946:	70e2                	ld	ra,56(sp)
    80001948:	7442                	ld	s0,48(sp)
    8000194a:	74a2                	ld	s1,40(sp)
    8000194c:	7902                	ld	s2,32(sp)
    8000194e:	69e2                	ld	s3,24(sp)
    80001950:	6a42                	ld	s4,16(sp)
    80001952:	6aa2                	ld	s5,8(sp)
    80001954:	6b02                	ld	s6,0(sp)
    80001956:	6121                	addi	sp,sp,64
    80001958:	8082                	ret

000000008000195a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000195a:	1141                	addi	sp,sp,-16
    8000195c:	e422                	sd	s0,8(sp)
    8000195e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001960:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001962:	2501                	sext.w	a0,a0
    80001964:	6422                	ld	s0,8(sp)
    80001966:	0141                	addi	sp,sp,16
    80001968:	8082                	ret

000000008000196a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
    80001970:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001972:	2781                	sext.w	a5,a5
    80001974:	079e                	slli	a5,a5,0x7
  return c;
}
    80001976:	00010517          	auipc	a0,0x10
    8000197a:	95a50513          	addi	a0,a0,-1702 # 800112d0 <cpus>
    8000197e:	953e                	add	a0,a0,a5
    80001980:	6422                	ld	s0,8(sp)
    80001982:	0141                	addi	sp,sp,16
    80001984:	8082                	ret

0000000080001986 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001986:	1101                	addi	sp,sp,-32
    80001988:	ec06                	sd	ra,24(sp)
    8000198a:	e822                	sd	s0,16(sp)
    8000198c:	e426                	sd	s1,8(sp)
    8000198e:	1000                	addi	s0,sp,32
  push_off();
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	1e6080e7          	jalr	486(ra) # 80000b76 <push_off>
    80001998:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000199a:	2781                	sext.w	a5,a5
    8000199c:	079e                	slli	a5,a5,0x7
    8000199e:	00010717          	auipc	a4,0x10
    800019a2:	90270713          	addi	a4,a4,-1790 # 800112a0 <pid_lock>
    800019a6:	97ba                	add	a5,a5,a4
    800019a8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	26c080e7          	jalr	620(ra) # 80000c16 <pop_off>
  return p;
}
    800019b2:	8526                	mv	a0,s1
    800019b4:	60e2                	ld	ra,24(sp)
    800019b6:	6442                	ld	s0,16(sp)
    800019b8:	64a2                	ld	s1,8(sp)
    800019ba:	6105                	addi	sp,sp,32
    800019bc:	8082                	ret

00000000800019be <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019be:	1141                	addi	sp,sp,-16
    800019c0:	e406                	sd	ra,8(sp)
    800019c2:	e022                	sd	s0,0(sp)
    800019c4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019c6:	00000097          	auipc	ra,0x0
    800019ca:	fc0080e7          	jalr	-64(ra) # 80001986 <myproc>
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	2a8080e7          	jalr	680(ra) # 80000c76 <release>

  if (first) {
    800019d6:	00007797          	auipc	a5,0x7
    800019da:	e2a7a783          	lw	a5,-470(a5) # 80008800 <first.1>
    800019de:	eb89                	bnez	a5,800019f0 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019e0:	00001097          	auipc	ra,0x1
    800019e4:	c82080e7          	jalr	-894(ra) # 80002662 <usertrapret>
}
    800019e8:	60a2                	ld	ra,8(sp)
    800019ea:	6402                	ld	s0,0(sp)
    800019ec:	0141                	addi	sp,sp,16
    800019ee:	8082                	ret
    first = 0;
    800019f0:	00007797          	auipc	a5,0x7
    800019f4:	e007a823          	sw	zero,-496(a5) # 80008800 <first.1>
    fsinit(ROOTDEV);
    800019f8:	4505                	li	a0,1
    800019fa:	00002097          	auipc	ra,0x2
    800019fe:	9aa080e7          	jalr	-1622(ra) # 800033a4 <fsinit>
    80001a02:	bff9                	j	800019e0 <forkret+0x22>

0000000080001a04 <allocpid>:
allocpid() {
    80001a04:	1101                	addi	sp,sp,-32
    80001a06:	ec06                	sd	ra,24(sp)
    80001a08:	e822                	sd	s0,16(sp)
    80001a0a:	e426                	sd	s1,8(sp)
    80001a0c:	e04a                	sd	s2,0(sp)
    80001a0e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a10:	00010917          	auipc	s2,0x10
    80001a14:	89090913          	addi	s2,s2,-1904 # 800112a0 <pid_lock>
    80001a18:	854a                	mv	a0,s2
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	1a8080e7          	jalr	424(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	de278793          	addi	a5,a5,-542 # 80008804 <nextpid>
    80001a2a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a2c:	0014871b          	addiw	a4,s1,1
    80001a30:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a32:	854a                	mv	a0,s2
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	242080e7          	jalr	578(ra) # 80000c76 <release>
}
    80001a3c:	8526                	mv	a0,s1
    80001a3e:	60e2                	ld	ra,24(sp)
    80001a40:	6442                	ld	s0,16(sp)
    80001a42:	64a2                	ld	s1,8(sp)
    80001a44:	6902                	ld	s2,0(sp)
    80001a46:	6105                	addi	sp,sp,32
    80001a48:	8082                	ret

0000000080001a4a <proc_pagetable>:
{
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	e04a                	sd	s2,0(sp)
    80001a54:	1000                	addi	s0,sp,32
    80001a56:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a58:	00000097          	auipc	ra,0x0
    80001a5c:	8b6080e7          	jalr	-1866(ra) # 8000130e <uvmcreate>
    80001a60:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a62:	c121                	beqz	a0,80001aa2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a64:	4729                	li	a4,10
    80001a66:	00005697          	auipc	a3,0x5
    80001a6a:	59a68693          	addi	a3,a3,1434 # 80007000 <_trampoline>
    80001a6e:	6605                	lui	a2,0x1
    80001a70:	040005b7          	lui	a1,0x4000
    80001a74:	15fd                	addi	a1,a1,-1
    80001a76:	05b2                	slli	a1,a1,0xc
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	61e080e7          	jalr	1566(ra) # 80001096 <mappages>
    80001a80:	02054863          	bltz	a0,80001ab0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a84:	4719                	li	a4,6
    80001a86:	05893683          	ld	a3,88(s2)
    80001a8a:	6605                	lui	a2,0x1
    80001a8c:	020005b7          	lui	a1,0x2000
    80001a90:	15fd                	addi	a1,a1,-1
    80001a92:	05b6                	slli	a1,a1,0xd
    80001a94:	8526                	mv	a0,s1
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	600080e7          	jalr	1536(ra) # 80001096 <mappages>
    80001a9e:	02054163          	bltz	a0,80001ac0 <proc_pagetable+0x76>
}
    80001aa2:	8526                	mv	a0,s1
    80001aa4:	60e2                	ld	ra,24(sp)
    80001aa6:	6442                	ld	s0,16(sp)
    80001aa8:	64a2                	ld	s1,8(sp)
    80001aaa:	6902                	ld	s2,0(sp)
    80001aac:	6105                	addi	sp,sp,32
    80001aae:	8082                	ret
    uvmfree(pagetable, 0);
    80001ab0:	4581                	li	a1,0
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	00000097          	auipc	ra,0x0
    80001ab8:	a56080e7          	jalr	-1450(ra) # 8000150a <uvmfree>
    return 0;
    80001abc:	4481                	li	s1,0
    80001abe:	b7d5                	j	80001aa2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ac0:	4681                	li	a3,0
    80001ac2:	4605                	li	a2,1
    80001ac4:	040005b7          	lui	a1,0x4000
    80001ac8:	15fd                	addi	a1,a1,-1
    80001aca:	05b2                	slli	a1,a1,0xc
    80001acc:	8526                	mv	a0,s1
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	77c080e7          	jalr	1916(ra) # 8000124a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a30080e7          	jalr	-1488(ra) # 8000150a <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	bf7d                	j	80001aa2 <proc_pagetable+0x58>

0000000080001ae6 <proc_freepagetable>:
{
    80001ae6:	1101                	addi	sp,sp,-32
    80001ae8:	ec06                	sd	ra,24(sp)
    80001aea:	e822                	sd	s0,16(sp)
    80001aec:	e426                	sd	s1,8(sp)
    80001aee:	e04a                	sd	s2,0(sp)
    80001af0:	1000                	addi	s0,sp,32
    80001af2:	84aa                	mv	s1,a0
    80001af4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af6:	4681                	li	a3,0
    80001af8:	4605                	li	a2,1
    80001afa:	040005b7          	lui	a1,0x4000
    80001afe:	15fd                	addi	a1,a1,-1
    80001b00:	05b2                	slli	a1,a1,0xc
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	748080e7          	jalr	1864(ra) # 8000124a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b0a:	4681                	li	a3,0
    80001b0c:	4605                	li	a2,1
    80001b0e:	020005b7          	lui	a1,0x2000
    80001b12:	15fd                	addi	a1,a1,-1
    80001b14:	05b6                	slli	a1,a1,0xd
    80001b16:	8526                	mv	a0,s1
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	732080e7          	jalr	1842(ra) # 8000124a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b20:	85ca                	mv	a1,s2
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	9e6080e7          	jalr	-1562(ra) # 8000150a <uvmfree>
}
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6902                	ld	s2,0(sp)
    80001b34:	6105                	addi	sp,sp,32
    80001b36:	8082                	ret

0000000080001b38 <freeproc>:
{
    80001b38:	1101                	addi	sp,sp,-32
    80001b3a:	ec06                	sd	ra,24(sp)
    80001b3c:	e822                	sd	s0,16(sp)
    80001b3e:	e426                	sd	s1,8(sp)
    80001b40:	1000                	addi	s0,sp,32
    80001b42:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b44:	6d28                	ld	a0,88(a0)
    80001b46:	c509                	beqz	a0,80001b50 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	e8e080e7          	jalr	-370(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b50:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b54:	68a8                	ld	a0,80(s1)
    80001b56:	c511                	beqz	a0,80001b62 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b58:	64ac                	ld	a1,72(s1)
    80001b5a:	00000097          	auipc	ra,0x0
    80001b5e:	f8c080e7          	jalr	-116(ra) # 80001ae6 <proc_freepagetable>
  p->pagetable = 0;
    80001b62:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b66:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b6a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b6e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b72:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b76:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b7a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b7e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b82:	0004ac23          	sw	zero,24(s1)
}
    80001b86:	60e2                	ld	ra,24(sp)
    80001b88:	6442                	ld	s0,16(sp)
    80001b8a:	64a2                	ld	s1,8(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <allocproc>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	e04a                	sd	s2,0(sp)
    80001b9a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b9c:	00010497          	auipc	s1,0x10
    80001ba0:	b3448493          	addi	s1,s1,-1228 # 800116d0 <proc>
    80001ba4:	00015917          	auipc	s2,0x15
    80001ba8:	52c90913          	addi	s2,s2,1324 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bac:	8526                	mv	a0,s1
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	014080e7          	jalr	20(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bb6:	4c9c                	lw	a5,24(s1)
    80001bb8:	cf81                	beqz	a5,80001bd0 <allocproc+0x40>
      release(&p->lock);
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	0ba080e7          	jalr	186(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc4:	16848493          	addi	s1,s1,360
    80001bc8:	ff2492e3          	bne	s1,s2,80001bac <allocproc+0x1c>
  return 0;
    80001bcc:	4481                	li	s1,0
    80001bce:	a889                	j	80001c20 <allocproc+0x90>
  p->pid = allocpid();
    80001bd0:	00000097          	auipc	ra,0x0
    80001bd4:	e34080e7          	jalr	-460(ra) # 80001a04 <allocpid>
    80001bd8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bda:	4785                	li	a5,1
    80001bdc:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	ef4080e7          	jalr	-268(ra) # 80000ad2 <kalloc>
    80001be6:	892a                	mv	s2,a0
    80001be8:	eca8                	sd	a0,88(s1)
    80001bea:	c131                	beqz	a0,80001c2e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bec:	8526                	mv	a0,s1
    80001bee:	00000097          	auipc	ra,0x0
    80001bf2:	e5c080e7          	jalr	-420(ra) # 80001a4a <proc_pagetable>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bfa:	c531                	beqz	a0,80001c46 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001bfc:	07000613          	li	a2,112
    80001c00:	4581                	li	a1,0
    80001c02:	06048513          	addi	a0,s1,96
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	0b8080e7          	jalr	184(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c0e:	00000797          	auipc	a5,0x0
    80001c12:	db078793          	addi	a5,a5,-592 # 800019be <forkret>
    80001c16:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c18:	60bc                	ld	a5,64(s1)
    80001c1a:	6705                	lui	a4,0x1
    80001c1c:	97ba                	add	a5,a5,a4
    80001c1e:	f4bc                	sd	a5,104(s1)
}
    80001c20:	8526                	mv	a0,s1
    80001c22:	60e2                	ld	ra,24(sp)
    80001c24:	6442                	ld	s0,16(sp)
    80001c26:	64a2                	ld	s1,8(sp)
    80001c28:	6902                	ld	s2,0(sp)
    80001c2a:	6105                	addi	sp,sp,32
    80001c2c:	8082                	ret
    freeproc(p);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	f08080e7          	jalr	-248(ra) # 80001b38 <freeproc>
    release(&p->lock);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	03c080e7          	jalr	60(ra) # 80000c76 <release>
    return 0;
    80001c42:	84ca                	mv	s1,s2
    80001c44:	bff1                	j	80001c20 <allocproc+0x90>
    freeproc(p);
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	ef0080e7          	jalr	-272(ra) # 80001b38 <freeproc>
    release(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	024080e7          	jalr	36(ra) # 80000c76 <release>
    return 0;
    80001c5a:	84ca                	mv	s1,s2
    80001c5c:	b7d1                	j	80001c20 <allocproc+0x90>

0000000080001c5e <userinit>:
{
    80001c5e:	1101                	addi	sp,sp,-32
    80001c60:	ec06                	sd	ra,24(sp)
    80001c62:	e822                	sd	s0,16(sp)
    80001c64:	e426                	sd	s1,8(sp)
    80001c66:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	f28080e7          	jalr	-216(ra) # 80001b90 <allocproc>
    80001c70:	84aa                	mv	s1,a0
  initproc = p;
    80001c72:	00007797          	auipc	a5,0x7
    80001c76:	3aa7bb23          	sd	a0,950(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c7a:	03400613          	li	a2,52
    80001c7e:	00007597          	auipc	a1,0x7
    80001c82:	b9258593          	addi	a1,a1,-1134 # 80008810 <initcode>
    80001c86:	6928                	ld	a0,80(a0)
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	6b4080e7          	jalr	1716(ra) # 8000133c <uvminit>
  p->sz = PGSIZE;
    80001c90:	6785                	lui	a5,0x1
    80001c92:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001c94:	6cb8                	ld	a4,88(s1)
    80001c96:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001c9a:	6cb8                	ld	a4,88(s1)
    80001c9c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001c9e:	4641                	li	a2,16
    80001ca0:	00006597          	auipc	a1,0x6
    80001ca4:	54858593          	addi	a1,a1,1352 # 800081e8 <digits+0x1a8>
    80001ca8:	15848513          	addi	a0,s1,344
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	164080e7          	jalr	356(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cb4:	00006517          	auipc	a0,0x6
    80001cb8:	54450513          	addi	a0,a0,1348 # 800081f8 <digits+0x1b8>
    80001cbc:	00002097          	auipc	ra,0x2
    80001cc0:	1b6080e7          	jalr	438(ra) # 80003e72 <namei>
    80001cc4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cc8:	478d                	li	a5,3
    80001cca:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	fa8080e7          	jalr	-88(ra) # 80000c76 <release>
}
    80001cd6:	60e2                	ld	ra,24(sp)
    80001cd8:	6442                	ld	s0,16(sp)
    80001cda:	64a2                	ld	s1,8(sp)
    80001cdc:	6105                	addi	sp,sp,32
    80001cde:	8082                	ret

0000000080001ce0 <growproc>:
{
    80001ce0:	1101                	addi	sp,sp,-32
    80001ce2:	ec06                	sd	ra,24(sp)
    80001ce4:	e822                	sd	s0,16(sp)
    80001ce6:	e426                	sd	s1,8(sp)
    80001ce8:	e04a                	sd	s2,0(sp)
    80001cea:	1000                	addi	s0,sp,32
    80001cec:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	c98080e7          	jalr	-872(ra) # 80001986 <myproc>
    80001cf6:	892a                	mv	s2,a0
  sz = p->sz;
    80001cf8:	652c                	ld	a1,72(a0)
    80001cfa:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001cfe:	00904f63          	bgtz	s1,80001d1c <growproc+0x3c>
  } else if(n < 0){
    80001d02:	0204cc63          	bltz	s1,80001d3a <growproc+0x5a>
  p->sz = sz;
    80001d06:	1602                	slli	a2,a2,0x20
    80001d08:	9201                	srli	a2,a2,0x20
    80001d0a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d0e:	4501                	li	a0,0
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6902                	ld	s2,0(sp)
    80001d18:	6105                	addi	sp,sp,32
    80001d1a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d1c:	9e25                	addw	a2,a2,s1
    80001d1e:	1602                	slli	a2,a2,0x20
    80001d20:	9201                	srli	a2,a2,0x20
    80001d22:	1582                	slli	a1,a1,0x20
    80001d24:	9181                	srli	a1,a1,0x20
    80001d26:	6928                	ld	a0,80(a0)
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	6ce080e7          	jalr	1742(ra) # 800013f6 <uvmalloc>
    80001d30:	0005061b          	sext.w	a2,a0
    80001d34:	fa69                	bnez	a2,80001d06 <growproc+0x26>
      return -1;
    80001d36:	557d                	li	a0,-1
    80001d38:	bfe1                	j	80001d10 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d3a:	9e25                	addw	a2,a2,s1
    80001d3c:	1602                	slli	a2,a2,0x20
    80001d3e:	9201                	srli	a2,a2,0x20
    80001d40:	1582                	slli	a1,a1,0x20
    80001d42:	9181                	srli	a1,a1,0x20
    80001d44:	6928                	ld	a0,80(a0)
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	668080e7          	jalr	1640(ra) # 800013ae <uvmdealloc>
    80001d4e:	0005061b          	sext.w	a2,a0
    80001d52:	bf55                	j	80001d06 <growproc+0x26>

0000000080001d54 <fork>:
{
    80001d54:	7139                	addi	sp,sp,-64
    80001d56:	fc06                	sd	ra,56(sp)
    80001d58:	f822                	sd	s0,48(sp)
    80001d5a:	f426                	sd	s1,40(sp)
    80001d5c:	f04a                	sd	s2,32(sp)
    80001d5e:	ec4e                	sd	s3,24(sp)
    80001d60:	e852                	sd	s4,16(sp)
    80001d62:	e456                	sd	s5,8(sp)
    80001d64:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	c20080e7          	jalr	-992(ra) # 80001986 <myproc>
    80001d6e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	e20080e7          	jalr	-480(ra) # 80001b90 <allocproc>
    80001d78:	10050c63          	beqz	a0,80001e90 <fork+0x13c>
    80001d7c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d7e:	048ab603          	ld	a2,72(s5)
    80001d82:	692c                	ld	a1,80(a0)
    80001d84:	050ab503          	ld	a0,80(s5)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	7ba080e7          	jalr	1978(ra) # 80001542 <uvmcopy>
    80001d90:	04054863          	bltz	a0,80001de0 <fork+0x8c>
  np->sz = p->sz;
    80001d94:	048ab783          	ld	a5,72(s5)
    80001d98:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001d9c:	058ab683          	ld	a3,88(s5)
    80001da0:	87b6                	mv	a5,a3
    80001da2:	058a3703          	ld	a4,88(s4)
    80001da6:	12068693          	addi	a3,a3,288
    80001daa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dae:	6788                	ld	a0,8(a5)
    80001db0:	6b8c                	ld	a1,16(a5)
    80001db2:	6f90                	ld	a2,24(a5)
    80001db4:	01073023          	sd	a6,0(a4)
    80001db8:	e708                	sd	a0,8(a4)
    80001dba:	eb0c                	sd	a1,16(a4)
    80001dbc:	ef10                	sd	a2,24(a4)
    80001dbe:	02078793          	addi	a5,a5,32
    80001dc2:	02070713          	addi	a4,a4,32
    80001dc6:	fed792e3          	bne	a5,a3,80001daa <fork+0x56>
  np->trapframe->a0 = 0;
    80001dca:	058a3783          	ld	a5,88(s4)
    80001dce:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dd2:	0d0a8493          	addi	s1,s5,208
    80001dd6:	0d0a0913          	addi	s2,s4,208
    80001dda:	150a8993          	addi	s3,s5,336
    80001dde:	a00d                	j	80001e00 <fork+0xac>
    freeproc(np);
    80001de0:	8552                	mv	a0,s4
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	d56080e7          	jalr	-682(ra) # 80001b38 <freeproc>
    release(&np->lock);
    80001dea:	8552                	mv	a0,s4
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	e8a080e7          	jalr	-374(ra) # 80000c76 <release>
    return -1;
    80001df4:	597d                	li	s2,-1
    80001df6:	a059                	j	80001e7c <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001df8:	04a1                	addi	s1,s1,8
    80001dfa:	0921                	addi	s2,s2,8
    80001dfc:	01348b63          	beq	s1,s3,80001e12 <fork+0xbe>
    if(p->ofile[i])
    80001e00:	6088                	ld	a0,0(s1)
    80001e02:	d97d                	beqz	a0,80001df8 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e04:	00002097          	auipc	ra,0x2
    80001e08:	708080e7          	jalr	1800(ra) # 8000450c <filedup>
    80001e0c:	00a93023          	sd	a0,0(s2)
    80001e10:	b7e5                	j	80001df8 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e12:	150ab503          	ld	a0,336(s5)
    80001e16:	00001097          	auipc	ra,0x1
    80001e1a:	7c8080e7          	jalr	1992(ra) # 800035de <idup>
    80001e1e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e22:	4641                	li	a2,16
    80001e24:	158a8593          	addi	a1,s5,344
    80001e28:	158a0513          	addi	a0,s4,344
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	fe4080e7          	jalr	-28(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e34:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e38:	8552                	mv	a0,s4
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e3c080e7          	jalr	-452(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e42:	0000f497          	auipc	s1,0xf
    80001e46:	47648493          	addi	s1,s1,1142 # 800112b8 <wait_lock>
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	d76080e7          	jalr	-650(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e54:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e1c080e7          	jalr	-484(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e62:	8552                	mv	a0,s4
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	d5e080e7          	jalr	-674(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e6c:	478d                	li	a5,3
    80001e6e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e72:	8552                	mv	a0,s4
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e02080e7          	jalr	-510(ra) # 80000c76 <release>
}
    80001e7c:	854a                	mv	a0,s2
    80001e7e:	70e2                	ld	ra,56(sp)
    80001e80:	7442                	ld	s0,48(sp)
    80001e82:	74a2                	ld	s1,40(sp)
    80001e84:	7902                	ld	s2,32(sp)
    80001e86:	69e2                	ld	s3,24(sp)
    80001e88:	6a42                	ld	s4,16(sp)
    80001e8a:	6aa2                	ld	s5,8(sp)
    80001e8c:	6121                	addi	sp,sp,64
    80001e8e:	8082                	ret
    return -1;
    80001e90:	597d                	li	s2,-1
    80001e92:	b7ed                	j	80001e7c <fork+0x128>

0000000080001e94 <scheduler>:
{
    80001e94:	7139                	addi	sp,sp,-64
    80001e96:	fc06                	sd	ra,56(sp)
    80001e98:	f822                	sd	s0,48(sp)
    80001e9a:	f426                	sd	s1,40(sp)
    80001e9c:	f04a                	sd	s2,32(sp)
    80001e9e:	ec4e                	sd	s3,24(sp)
    80001ea0:	e852                	sd	s4,16(sp)
    80001ea2:	e456                	sd	s5,8(sp)
    80001ea4:	e05a                	sd	s6,0(sp)
    80001ea6:	0080                	addi	s0,sp,64
    80001ea8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eaa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eac:	00779a93          	slli	s5,a5,0x7
    80001eb0:	0000f717          	auipc	a4,0xf
    80001eb4:	3f070713          	addi	a4,a4,1008 # 800112a0 <pid_lock>
    80001eb8:	9756                	add	a4,a4,s5
    80001eba:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	41a70713          	addi	a4,a4,1050 # 800112d8 <cpus+0x8>
    80001ec6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ec8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eca:	4b11                	li	s6,4
        c->proc = p;
    80001ecc:	079e                	slli	a5,a5,0x7
    80001ece:	0000fa17          	auipc	s4,0xf
    80001ed2:	3d2a0a13          	addi	s4,s4,978 # 800112a0 <pid_lock>
    80001ed6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ed8:	00015917          	auipc	s2,0x15
    80001edc:	1f890913          	addi	s2,s2,504 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ee4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ee8:	10079073          	csrw	sstatus,a5
    80001eec:	0000f497          	auipc	s1,0xf
    80001ef0:	7e448493          	addi	s1,s1,2020 # 800116d0 <proc>
    80001ef4:	a811                	j	80001f08 <scheduler+0x74>
      release(&p->lock);
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	d7e080e7          	jalr	-642(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f00:	16848493          	addi	s1,s1,360
    80001f04:	fd248ee3          	beq	s1,s2,80001ee0 <scheduler+0x4c>
      acquire(&p->lock);
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	cb8080e7          	jalr	-840(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f12:	4c9c                	lw	a5,24(s1)
    80001f14:	ff3791e3          	bne	a5,s3,80001ef6 <scheduler+0x62>
        p->state = RUNNING;
    80001f18:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f1c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f20:	06048593          	addi	a1,s1,96
    80001f24:	8556                	mv	a0,s5
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	692080e7          	jalr	1682(ra) # 800025b8 <swtch>
        c->proc = 0;
    80001f2e:	020a3823          	sd	zero,48(s4)
    80001f32:	b7d1                	j	80001ef6 <scheduler+0x62>

0000000080001f34 <sched>:
{
    80001f34:	7179                	addi	sp,sp,-48
    80001f36:	f406                	sd	ra,40(sp)
    80001f38:	f022                	sd	s0,32(sp)
    80001f3a:	ec26                	sd	s1,24(sp)
    80001f3c:	e84a                	sd	s2,16(sp)
    80001f3e:	e44e                	sd	s3,8(sp)
    80001f40:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	a44080e7          	jalr	-1468(ra) # 80001986 <myproc>
    80001f4a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	bfc080e7          	jalr	-1028(ra) # 80000b48 <holding>
    80001f54:	c93d                	beqz	a0,80001fca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f56:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f58:	2781                	sext.w	a5,a5
    80001f5a:	079e                	slli	a5,a5,0x7
    80001f5c:	0000f717          	auipc	a4,0xf
    80001f60:	34470713          	addi	a4,a4,836 # 800112a0 <pid_lock>
    80001f64:	97ba                	add	a5,a5,a4
    80001f66:	0a87a703          	lw	a4,168(a5)
    80001f6a:	4785                	li	a5,1
    80001f6c:	06f71763          	bne	a4,a5,80001fda <sched+0xa6>
  if(p->state == RUNNING)
    80001f70:	4c98                	lw	a4,24(s1)
    80001f72:	4791                	li	a5,4
    80001f74:	06f70b63          	beq	a4,a5,80001fea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f78:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f7c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f7e:	efb5                	bnez	a5,80001ffa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f80:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f82:	0000f917          	auipc	s2,0xf
    80001f86:	31e90913          	addi	s2,s2,798 # 800112a0 <pid_lock>
    80001f8a:	2781                	sext.w	a5,a5
    80001f8c:	079e                	slli	a5,a5,0x7
    80001f8e:	97ca                	add	a5,a5,s2
    80001f90:	0ac7a983          	lw	s3,172(a5)
    80001f94:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	0000f597          	auipc	a1,0xf
    80001f9e:	33e58593          	addi	a1,a1,830 # 800112d8 <cpus+0x8>
    80001fa2:	95be                	add	a1,a1,a5
    80001fa4:	06048513          	addi	a0,s1,96
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	610080e7          	jalr	1552(ra) # 800025b8 <swtch>
    80001fb0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	slli	a5,a5,0x7
    80001fb6:	97ca                	add	a5,a5,s2
    80001fb8:	0b37a623          	sw	s3,172(a5)
}
    80001fbc:	70a2                	ld	ra,40(sp)
    80001fbe:	7402                	ld	s0,32(sp)
    80001fc0:	64e2                	ld	s1,24(sp)
    80001fc2:	6942                	ld	s2,16(sp)
    80001fc4:	69a2                	ld	s3,8(sp)
    80001fc6:	6145                	addi	sp,sp,48
    80001fc8:	8082                	ret
    panic("sched p->lock");
    80001fca:	00006517          	auipc	a0,0x6
    80001fce:	23650513          	addi	a0,a0,566 # 80008200 <digits+0x1c0>
    80001fd2:	ffffe097          	auipc	ra,0xffffe
    80001fd6:	558080e7          	jalr	1368(ra) # 8000052a <panic>
    panic("sched locks");
    80001fda:	00006517          	auipc	a0,0x6
    80001fde:	23650513          	addi	a0,a0,566 # 80008210 <digits+0x1d0>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	548080e7          	jalr	1352(ra) # 8000052a <panic>
    panic("sched running");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	23650513          	addi	a0,a0,566 # 80008220 <digits+0x1e0>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	538080e7          	jalr	1336(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	23650513          	addi	a0,a0,566 # 80008230 <digits+0x1f0>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	528080e7          	jalr	1320(ra) # 8000052a <panic>

000000008000200a <yield>:
{
    8000200a:	1101                	addi	sp,sp,-32
    8000200c:	ec06                	sd	ra,24(sp)
    8000200e:	e822                	sd	s0,16(sp)
    80002010:	e426                	sd	s1,8(sp)
    80002012:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	972080e7          	jalr	-1678(ra) # 80001986 <myproc>
    8000201c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	ba4080e7          	jalr	-1116(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002026:	478d                	li	a5,3
    80002028:	cc9c                	sw	a5,24(s1)
  sched();
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	f0a080e7          	jalr	-246(ra) # 80001f34 <sched>
  release(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	c42080e7          	jalr	-958(ra) # 80000c76 <release>
}
    8000203c:	60e2                	ld	ra,24(sp)
    8000203e:	6442                	ld	s0,16(sp)
    80002040:	64a2                	ld	s1,8(sp)
    80002042:	6105                	addi	sp,sp,32
    80002044:	8082                	ret

0000000080002046 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002046:	7179                	addi	sp,sp,-48
    80002048:	f406                	sd	ra,40(sp)
    8000204a:	f022                	sd	s0,32(sp)
    8000204c:	ec26                	sd	s1,24(sp)
    8000204e:	e84a                	sd	s2,16(sp)
    80002050:	e44e                	sd	s3,8(sp)
    80002052:	1800                	addi	s0,sp,48
    80002054:	89aa                	mv	s3,a0
    80002056:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	92e080e7          	jalr	-1746(ra) # 80001986 <myproc>
    80002060:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	b60080e7          	jalr	-1184(ra) # 80000bc2 <acquire>
  release(lk);
    8000206a:	854a                	mv	a0,s2
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	c0a080e7          	jalr	-1014(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002074:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002078:	4789                	li	a5,2
    8000207a:	cc9c                	sw	a5,24(s1)

  sched();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	eb8080e7          	jalr	-328(ra) # 80001f34 <sched>

  // Tidy up.
  p->chan = 0;
    80002084:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002088:	8526                	mv	a0,s1
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	bec080e7          	jalr	-1044(ra) # 80000c76 <release>
  acquire(lk);
    80002092:	854a                	mv	a0,s2
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b2e080e7          	jalr	-1234(ra) # 80000bc2 <acquire>
}
    8000209c:	70a2                	ld	ra,40(sp)
    8000209e:	7402                	ld	s0,32(sp)
    800020a0:	64e2                	ld	s1,24(sp)
    800020a2:	6942                	ld	s2,16(sp)
    800020a4:	69a2                	ld	s3,8(sp)
    800020a6:	6145                	addi	sp,sp,48
    800020a8:	8082                	ret

00000000800020aa <wait>:
{
    800020aa:	715d                	addi	sp,sp,-80
    800020ac:	e486                	sd	ra,72(sp)
    800020ae:	e0a2                	sd	s0,64(sp)
    800020b0:	fc26                	sd	s1,56(sp)
    800020b2:	f84a                	sd	s2,48(sp)
    800020b4:	f44e                	sd	s3,40(sp)
    800020b6:	f052                	sd	s4,32(sp)
    800020b8:	ec56                	sd	s5,24(sp)
    800020ba:	e85a                	sd	s6,16(sp)
    800020bc:	e45e                	sd	s7,8(sp)
    800020be:	e062                	sd	s8,0(sp)
    800020c0:	0880                	addi	s0,sp,80
    800020c2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	8c2080e7          	jalr	-1854(ra) # 80001986 <myproc>
    800020cc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020ce:	0000f517          	auipc	a0,0xf
    800020d2:	1ea50513          	addi	a0,a0,490 # 800112b8 <wait_lock>
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	aec080e7          	jalr	-1300(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020de:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020e0:	4a15                	li	s4,5
        havekids = 1;
    800020e2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020e4:	00015997          	auipc	s3,0x15
    800020e8:	fec98993          	addi	s3,s3,-20 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020ec:	0000fc17          	auipc	s8,0xf
    800020f0:	1ccc0c13          	addi	s8,s8,460 # 800112b8 <wait_lock>
    havekids = 0;
    800020f4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020f6:	0000f497          	auipc	s1,0xf
    800020fa:	5da48493          	addi	s1,s1,1498 # 800116d0 <proc>
    800020fe:	a0bd                	j	8000216c <wait+0xc2>
          pid = np->pid;
    80002100:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002104:	000b0e63          	beqz	s6,80002120 <wait+0x76>
    80002108:	4691                	li	a3,4
    8000210a:	02c48613          	addi	a2,s1,44
    8000210e:	85da                	mv	a1,s6
    80002110:	05093503          	ld	a0,80(s2)
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	532080e7          	jalr	1330(ra) # 80001646 <copyout>
    8000211c:	02054563          	bltz	a0,80002146 <wait+0x9c>
          freeproc(np);
    80002120:	8526                	mv	a0,s1
    80002122:	00000097          	auipc	ra,0x0
    80002126:	a16080e7          	jalr	-1514(ra) # 80001b38 <freeproc>
          release(&np->lock);
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	b4a080e7          	jalr	-1206(ra) # 80000c76 <release>
          release(&wait_lock);
    80002134:	0000f517          	auipc	a0,0xf
    80002138:	18450513          	addi	a0,a0,388 # 800112b8 <wait_lock>
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b3a080e7          	jalr	-1222(ra) # 80000c76 <release>
          return pid;
    80002144:	a09d                	j	800021aa <wait+0x100>
            release(&np->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b2e080e7          	jalr	-1234(ra) # 80000c76 <release>
            release(&wait_lock);
    80002150:	0000f517          	auipc	a0,0xf
    80002154:	16850513          	addi	a0,a0,360 # 800112b8 <wait_lock>
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b1e080e7          	jalr	-1250(ra) # 80000c76 <release>
            return -1;
    80002160:	59fd                	li	s3,-1
    80002162:	a0a1                	j	800021aa <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002164:	16848493          	addi	s1,s1,360
    80002168:	03348463          	beq	s1,s3,80002190 <wait+0xe6>
      if(np->parent == p){
    8000216c:	7c9c                	ld	a5,56(s1)
    8000216e:	ff279be3          	bne	a5,s2,80002164 <wait+0xba>
        acquire(&np->lock);
    80002172:	8526                	mv	a0,s1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	a4e080e7          	jalr	-1458(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000217c:	4c9c                	lw	a5,24(s1)
    8000217e:	f94781e3          	beq	a5,s4,80002100 <wait+0x56>
        release(&np->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	af2080e7          	jalr	-1294(ra) # 80000c76 <release>
        havekids = 1;
    8000218c:	8756                	mv	a4,s5
    8000218e:	bfd9                	j	80002164 <wait+0xba>
    if(!havekids || p->killed){
    80002190:	c701                	beqz	a4,80002198 <wait+0xee>
    80002192:	02892783          	lw	a5,40(s2)
    80002196:	c79d                	beqz	a5,800021c4 <wait+0x11a>
      release(&wait_lock);
    80002198:	0000f517          	auipc	a0,0xf
    8000219c:	12050513          	addi	a0,a0,288 # 800112b8 <wait_lock>
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	ad6080e7          	jalr	-1322(ra) # 80000c76 <release>
      return -1;
    800021a8:	59fd                	li	s3,-1
}
    800021aa:	854e                	mv	a0,s3
    800021ac:	60a6                	ld	ra,72(sp)
    800021ae:	6406                	ld	s0,64(sp)
    800021b0:	74e2                	ld	s1,56(sp)
    800021b2:	7942                	ld	s2,48(sp)
    800021b4:	79a2                	ld	s3,40(sp)
    800021b6:	7a02                	ld	s4,32(sp)
    800021b8:	6ae2                	ld	s5,24(sp)
    800021ba:	6b42                	ld	s6,16(sp)
    800021bc:	6ba2                	ld	s7,8(sp)
    800021be:	6c02                	ld	s8,0(sp)
    800021c0:	6161                	addi	sp,sp,80
    800021c2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021c4:	85e2                	mv	a1,s8
    800021c6:	854a                	mv	a0,s2
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	e7e080e7          	jalr	-386(ra) # 80002046 <sleep>
    havekids = 0;
    800021d0:	b715                	j	800020f4 <wait+0x4a>

00000000800021d2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021d2:	7139                	addi	sp,sp,-64
    800021d4:	fc06                	sd	ra,56(sp)
    800021d6:	f822                	sd	s0,48(sp)
    800021d8:	f426                	sd	s1,40(sp)
    800021da:	f04a                	sd	s2,32(sp)
    800021dc:	ec4e                	sd	s3,24(sp)
    800021de:	e852                	sd	s4,16(sp)
    800021e0:	e456                	sd	s5,8(sp)
    800021e2:	0080                	addi	s0,sp,64
    800021e4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021e6:	0000f497          	auipc	s1,0xf
    800021ea:	4ea48493          	addi	s1,s1,1258 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021ee:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021f0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f2:	00015917          	auipc	s2,0x15
    800021f6:	ede90913          	addi	s2,s2,-290 # 800170d0 <tickslock>
    800021fa:	a811                	j	8000220e <wakeup+0x3c>
      }
      release(&p->lock);
    800021fc:	8526                	mv	a0,s1
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a78080e7          	jalr	-1416(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	16848493          	addi	s1,s1,360
    8000220a:	03248663          	beq	s1,s2,80002236 <wakeup+0x64>
    if(p != myproc()){
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	778080e7          	jalr	1912(ra) # 80001986 <myproc>
    80002216:	fea488e3          	beq	s1,a0,80002206 <wakeup+0x34>
      acquire(&p->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9a6080e7          	jalr	-1626(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002224:	4c9c                	lw	a5,24(s1)
    80002226:	fd379be3          	bne	a5,s3,800021fc <wakeup+0x2a>
    8000222a:	709c                	ld	a5,32(s1)
    8000222c:	fd4798e3          	bne	a5,s4,800021fc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002230:	0154ac23          	sw	s5,24(s1)
    80002234:	b7e1                	j	800021fc <wakeup+0x2a>
    }
  }
}
    80002236:	70e2                	ld	ra,56(sp)
    80002238:	7442                	ld	s0,48(sp)
    8000223a:	74a2                	ld	s1,40(sp)
    8000223c:	7902                	ld	s2,32(sp)
    8000223e:	69e2                	ld	s3,24(sp)
    80002240:	6a42                	ld	s4,16(sp)
    80002242:	6aa2                	ld	s5,8(sp)
    80002244:	6121                	addi	sp,sp,64
    80002246:	8082                	ret

0000000080002248 <reparent>:
{
    80002248:	7179                	addi	sp,sp,-48
    8000224a:	f406                	sd	ra,40(sp)
    8000224c:	f022                	sd	s0,32(sp)
    8000224e:	ec26                	sd	s1,24(sp)
    80002250:	e84a                	sd	s2,16(sp)
    80002252:	e44e                	sd	s3,8(sp)
    80002254:	e052                	sd	s4,0(sp)
    80002256:	1800                	addi	s0,sp,48
    80002258:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000225a:	0000f497          	auipc	s1,0xf
    8000225e:	47648493          	addi	s1,s1,1142 # 800116d0 <proc>
      pp->parent = initproc;
    80002262:	00007a17          	auipc	s4,0x7
    80002266:	dc6a0a13          	addi	s4,s4,-570 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226a:	00015997          	auipc	s3,0x15
    8000226e:	e6698993          	addi	s3,s3,-410 # 800170d0 <tickslock>
    80002272:	a029                	j	8000227c <reparent+0x34>
    80002274:	16848493          	addi	s1,s1,360
    80002278:	01348d63          	beq	s1,s3,80002292 <reparent+0x4a>
    if(pp->parent == p){
    8000227c:	7c9c                	ld	a5,56(s1)
    8000227e:	ff279be3          	bne	a5,s2,80002274 <reparent+0x2c>
      pp->parent = initproc;
    80002282:	000a3503          	ld	a0,0(s4)
    80002286:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	f4a080e7          	jalr	-182(ra) # 800021d2 <wakeup>
    80002290:	b7d5                	j	80002274 <reparent+0x2c>
}
    80002292:	70a2                	ld	ra,40(sp)
    80002294:	7402                	ld	s0,32(sp)
    80002296:	64e2                	ld	s1,24(sp)
    80002298:	6942                	ld	s2,16(sp)
    8000229a:	69a2                	ld	s3,8(sp)
    8000229c:	6a02                	ld	s4,0(sp)
    8000229e:	6145                	addi	sp,sp,48
    800022a0:	8082                	ret

00000000800022a2 <exit>:
{
    800022a2:	7179                	addi	sp,sp,-48
    800022a4:	f406                	sd	ra,40(sp)
    800022a6:	f022                	sd	s0,32(sp)
    800022a8:	ec26                	sd	s1,24(sp)
    800022aa:	e84a                	sd	s2,16(sp)
    800022ac:	e44e                	sd	s3,8(sp)
    800022ae:	e052                	sd	s4,0(sp)
    800022b0:	1800                	addi	s0,sp,48
    800022b2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	6d2080e7          	jalr	1746(ra) # 80001986 <myproc>
    800022bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022be:	00007797          	auipc	a5,0x7
    800022c2:	d6a7b783          	ld	a5,-662(a5) # 80009028 <initproc>
    800022c6:	0d050493          	addi	s1,a0,208
    800022ca:	15050913          	addi	s2,a0,336
    800022ce:	02a79363          	bne	a5,a0,800022f4 <exit+0x52>
    panic("init exiting");
    800022d2:	00006517          	auipc	a0,0x6
    800022d6:	f7650513          	addi	a0,a0,-138 # 80008248 <digits+0x208>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	250080e7          	jalr	592(ra) # 8000052a <panic>
      fileclose(f);
    800022e2:	00002097          	auipc	ra,0x2
    800022e6:	27c080e7          	jalr	636(ra) # 8000455e <fileclose>
      p->ofile[fd] = 0;
    800022ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022ee:	04a1                	addi	s1,s1,8
    800022f0:	01248563          	beq	s1,s2,800022fa <exit+0x58>
    if(p->ofile[fd]){
    800022f4:	6088                	ld	a0,0(s1)
    800022f6:	f575                	bnez	a0,800022e2 <exit+0x40>
    800022f8:	bfdd                	j	800022ee <exit+0x4c>
  begin_op();
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	d98080e7          	jalr	-616(ra) # 80004092 <begin_op>
  iput(p->cwd);
    80002302:	1509b503          	ld	a0,336(s3)
    80002306:	00001097          	auipc	ra,0x1
    8000230a:	4d0080e7          	jalr	1232(ra) # 800037d6 <iput>
  end_op();
    8000230e:	00002097          	auipc	ra,0x2
    80002312:	e04080e7          	jalr	-508(ra) # 80004112 <end_op>
  p->cwd = 0;
    80002316:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000231a:	0000f497          	auipc	s1,0xf
    8000231e:	f9e48493          	addi	s1,s1,-98 # 800112b8 <wait_lock>
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	89e080e7          	jalr	-1890(ra) # 80000bc2 <acquire>
  reparent(p);
    8000232c:	854e                	mv	a0,s3
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	f1a080e7          	jalr	-230(ra) # 80002248 <reparent>
  wakeup(p->parent);
    80002336:	0389b503          	ld	a0,56(s3)
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	e98080e7          	jalr	-360(ra) # 800021d2 <wakeup>
  acquire(&p->lock);
    80002342:	854e                	mv	a0,s3
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	87e080e7          	jalr	-1922(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000234c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002350:	4795                	li	a5,5
    80002352:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	91e080e7          	jalr	-1762(ra) # 80000c76 <release>
  sched();
    80002360:	00000097          	auipc	ra,0x0
    80002364:	bd4080e7          	jalr	-1068(ra) # 80001f34 <sched>
  panic("zombie exit");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	ef050513          	addi	a0,a0,-272 # 80008258 <digits+0x218>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1ba080e7          	jalr	442(ra) # 8000052a <panic>

0000000080002378 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002378:	7179                	addi	sp,sp,-48
    8000237a:	f406                	sd	ra,40(sp)
    8000237c:	f022                	sd	s0,32(sp)
    8000237e:	ec26                	sd	s1,24(sp)
    80002380:	e84a                	sd	s2,16(sp)
    80002382:	e44e                	sd	s3,8(sp)
    80002384:	1800                	addi	s0,sp,48
    80002386:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002388:	0000f497          	auipc	s1,0xf
    8000238c:	34848493          	addi	s1,s1,840 # 800116d0 <proc>
    80002390:	00015997          	auipc	s3,0x15
    80002394:	d4098993          	addi	s3,s3,-704 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	828080e7          	jalr	-2008(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023a2:	589c                	lw	a5,48(s1)
    800023a4:	01278d63          	beq	a5,s2,800023be <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	8cc080e7          	jalr	-1844(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023b2:	16848493          	addi	s1,s1,360
    800023b6:	ff3491e3          	bne	s1,s3,80002398 <kill+0x20>
  }
  return -1;
    800023ba:	557d                	li	a0,-1
    800023bc:	a829                	j	800023d6 <kill+0x5e>
      p->killed = 1;
    800023be:	4785                	li	a5,1
    800023c0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023c2:	4c98                	lw	a4,24(s1)
    800023c4:	4789                	li	a5,2
    800023c6:	00f70f63          	beq	a4,a5,800023e4 <kill+0x6c>
      release(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8aa080e7          	jalr	-1878(ra) # 80000c76 <release>
      return 0;
    800023d4:	4501                	li	a0,0
}
    800023d6:	70a2                	ld	ra,40(sp)
    800023d8:	7402                	ld	s0,32(sp)
    800023da:	64e2                	ld	s1,24(sp)
    800023dc:	6942                	ld	s2,16(sp)
    800023de:	69a2                	ld	s3,8(sp)
    800023e0:	6145                	addi	sp,sp,48
    800023e2:	8082                	ret
        p->state = RUNNABLE;
    800023e4:	478d                	li	a5,3
    800023e6:	cc9c                	sw	a5,24(s1)
    800023e8:	b7cd                	j	800023ca <kill+0x52>

00000000800023ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023ea:	7179                	addi	sp,sp,-48
    800023ec:	f406                	sd	ra,40(sp)
    800023ee:	f022                	sd	s0,32(sp)
    800023f0:	ec26                	sd	s1,24(sp)
    800023f2:	e84a                	sd	s2,16(sp)
    800023f4:	e44e                	sd	s3,8(sp)
    800023f6:	e052                	sd	s4,0(sp)
    800023f8:	1800                	addi	s0,sp,48
    800023fa:	84aa                	mv	s1,a0
    800023fc:	892e                	mv	s2,a1
    800023fe:	89b2                	mv	s3,a2
    80002400:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	584080e7          	jalr	1412(ra) # 80001986 <myproc>
  if(user_dst){
    8000240a:	c08d                	beqz	s1,8000242c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000240c:	86d2                	mv	a3,s4
    8000240e:	864e                	mv	a2,s3
    80002410:	85ca                	mv	a1,s2
    80002412:	6928                	ld	a0,80(a0)
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	232080e7          	jalr	562(ra) # 80001646 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000241c:	70a2                	ld	ra,40(sp)
    8000241e:	7402                	ld	s0,32(sp)
    80002420:	64e2                	ld	s1,24(sp)
    80002422:	6942                	ld	s2,16(sp)
    80002424:	69a2                	ld	s3,8(sp)
    80002426:	6a02                	ld	s4,0(sp)
    80002428:	6145                	addi	sp,sp,48
    8000242a:	8082                	ret
    memmove((char *)dst, src, len);
    8000242c:	000a061b          	sext.w	a2,s4
    80002430:	85ce                	mv	a1,s3
    80002432:	854a                	mv	a0,s2
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	8e6080e7          	jalr	-1818(ra) # 80000d1a <memmove>
    return 0;
    8000243c:	8526                	mv	a0,s1
    8000243e:	bff9                	j	8000241c <either_copyout+0x32>

0000000080002440 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002440:	7179                	addi	sp,sp,-48
    80002442:	f406                	sd	ra,40(sp)
    80002444:	f022                	sd	s0,32(sp)
    80002446:	ec26                	sd	s1,24(sp)
    80002448:	e84a                	sd	s2,16(sp)
    8000244a:	e44e                	sd	s3,8(sp)
    8000244c:	e052                	sd	s4,0(sp)
    8000244e:	1800                	addi	s0,sp,48
    80002450:	892a                	mv	s2,a0
    80002452:	84ae                	mv	s1,a1
    80002454:	89b2                	mv	s3,a2
    80002456:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	52e080e7          	jalr	1326(ra) # 80001986 <myproc>
  if(user_src){
    80002460:	c08d                	beqz	s1,80002482 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002462:	86d2                	mv	a3,s4
    80002464:	864e                	mv	a2,s3
    80002466:	85ca                	mv	a1,s2
    80002468:	6928                	ld	a0,80(a0)
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	268080e7          	jalr	616(ra) # 800016d2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002472:	70a2                	ld	ra,40(sp)
    80002474:	7402                	ld	s0,32(sp)
    80002476:	64e2                	ld	s1,24(sp)
    80002478:	6942                	ld	s2,16(sp)
    8000247a:	69a2                	ld	s3,8(sp)
    8000247c:	6a02                	ld	s4,0(sp)
    8000247e:	6145                	addi	sp,sp,48
    80002480:	8082                	ret
    memmove(dst, (char*)src, len);
    80002482:	000a061b          	sext.w	a2,s4
    80002486:	85ce                	mv	a1,s3
    80002488:	854a                	mv	a0,s2
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	890080e7          	jalr	-1904(ra) # 80000d1a <memmove>
    return 0;
    80002492:	8526                	mv	a0,s1
    80002494:	bff9                	j	80002472 <either_copyin+0x32>

0000000080002496 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002496:	715d                	addi	sp,sp,-80
    80002498:	e486                	sd	ra,72(sp)
    8000249a:	e0a2                	sd	s0,64(sp)
    8000249c:	fc26                	sd	s1,56(sp)
    8000249e:	f84a                	sd	s2,48(sp)
    800024a0:	f44e                	sd	s3,40(sp)
    800024a2:	f052                	sd	s4,32(sp)
    800024a4:	ec56                	sd	s5,24(sp)
    800024a6:	e85a                	sd	s6,16(sp)
    800024a8:	e45e                	sd	s7,8(sp)
    800024aa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024ac:	00006517          	auipc	a0,0x6
    800024b0:	c1c50513          	addi	a0,a0,-996 # 800080c8 <digits+0x88>
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	0c0080e7          	jalr	192(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024bc:	0000f497          	auipc	s1,0xf
    800024c0:	36c48493          	addi	s1,s1,876 # 80011828 <proc+0x158>
    800024c4:	00015917          	auipc	s2,0x15
    800024c8:	d6490913          	addi	s2,s2,-668 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024cc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024ce:	00006997          	auipc	s3,0x6
    800024d2:	d9a98993          	addi	s3,s3,-614 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800024d6:	00006a97          	auipc	s5,0x6
    800024da:	d9aa8a93          	addi	s5,s5,-614 # 80008270 <digits+0x230>
    printf("\n");
    800024de:	00006a17          	auipc	s4,0x6
    800024e2:	beaa0a13          	addi	s4,s4,-1046 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024e6:	00006b97          	auipc	s7,0x6
    800024ea:	dc2b8b93          	addi	s7,s7,-574 # 800082a8 <states.0>
    800024ee:	a00d                	j	80002510 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800024f0:	ed86a583          	lw	a1,-296(a3)
    800024f4:	8556                	mv	a0,s5
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	07e080e7          	jalr	126(ra) # 80000574 <printf>
    printf("\n");
    800024fe:	8552                	mv	a0,s4
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	074080e7          	jalr	116(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002508:	16848493          	addi	s1,s1,360
    8000250c:	03248263          	beq	s1,s2,80002530 <procdump+0x9a>
    if(p->state == UNUSED)
    80002510:	86a6                	mv	a3,s1
    80002512:	ec04a783          	lw	a5,-320(s1)
    80002516:	dbed                	beqz	a5,80002508 <procdump+0x72>
      state = "???";
    80002518:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000251a:	fcfb6be3          	bltu	s6,a5,800024f0 <procdump+0x5a>
    8000251e:	02079713          	slli	a4,a5,0x20
    80002522:	01d75793          	srli	a5,a4,0x1d
    80002526:	97de                	add	a5,a5,s7
    80002528:	6390                	ld	a2,0(a5)
    8000252a:	f279                	bnez	a2,800024f0 <procdump+0x5a>
      state = "???";
    8000252c:	864e                	mv	a2,s3
    8000252e:	b7c9                	j	800024f0 <procdump+0x5a>
  }
}
    80002530:	60a6                	ld	ra,72(sp)
    80002532:	6406                	ld	s0,64(sp)
    80002534:	74e2                	ld	s1,56(sp)
    80002536:	7942                	ld	s2,48(sp)
    80002538:	79a2                	ld	s3,40(sp)
    8000253a:	7a02                	ld	s4,32(sp)
    8000253c:	6ae2                	ld	s5,24(sp)
    8000253e:	6b42                	ld	s6,16(sp)
    80002540:	6ba2                	ld	s7,8(sp)
    80002542:	6161                	addi	sp,sp,80
    80002544:	8082                	ret

0000000080002546 <procfsisdir>:
#include "memlayout.h"
#include "proc.h"


int 
procfsisdir(struct inode *ip) {
    80002546:	1141                	addi	sp,sp,-16
    80002548:	e422                	sd	s0,8(sp)
    8000254a:	0800                	addi	s0,sp,16
  return 0;
}
    8000254c:	4501                	li	a0,0
    8000254e:	6422                	ld	s0,8(sp)
    80002550:	0141                	addi	sp,sp,16
    80002552:	8082                	ret

0000000080002554 <procfsiread>:

void 
procfsiread(struct inode* dp, struct inode *ip) {
    80002554:	1141                	addi	sp,sp,-16
    80002556:	e422                	sd	s0,8(sp)
    80002558:	0800                	addi	s0,sp,16
}
    8000255a:	6422                	ld	s0,8(sp)
    8000255c:	0141                	addi	sp,sp,16
    8000255e:	8082                	ret

0000000080002560 <procfsread>:

int
procfsread(struct inode *ip, int user_dst, uint64 dst, int off, int n) {
    80002560:	1141                	addi	sp,sp,-16
    80002562:	e422                	sd	s0,8(sp)
    80002564:	0800                	addi	s0,sp,16
  return 0;
}
    80002566:	4501                	li	a0,0
    80002568:	6422                	ld	s0,8(sp)
    8000256a:	0141                	addi	sp,sp,16
    8000256c:	8082                	ret

000000008000256e <procfswrite>:

int
procfswrite(struct inode *ip, int user_dst, uint64 buf, int off, int n)
{
    8000256e:	1141                	addi	sp,sp,-16
    80002570:	e422                	sd	s0,8(sp)
    80002572:	0800                	addi	s0,sp,16
  return 0;
}
    80002574:	4501                	li	a0,0
    80002576:	6422                	ld	s0,8(sp)
    80002578:	0141                	addi	sp,sp,16
    8000257a:	8082                	ret

000000008000257c <procfsinit>:

void
procfsinit(void)
{
    8000257c:	1141                	addi	sp,sp,-16
    8000257e:	e422                	sd	s0,8(sp)
    80002580:	0800                	addi	s0,sp,16
  devsw[PROCFS].isdir = procfsisdir;
    80002582:	0001f797          	auipc	a5,0x1f
    80002586:	d9678793          	addi	a5,a5,-618 # 80021318 <devsw>
    8000258a:	00000717          	auipc	a4,0x0
    8000258e:	fbc70713          	addi	a4,a4,-68 # 80002546 <procfsisdir>
    80002592:	e3b8                	sd	a4,64(a5)
  devsw[PROCFS].inode_read = procfsiread;
    80002594:	00000717          	auipc	a4,0x0
    80002598:	fc070713          	addi	a4,a4,-64 # 80002554 <procfsiread>
    8000259c:	e7b8                	sd	a4,72(a5)
  devsw[PROCFS].write = procfswrite;
    8000259e:	00000717          	auipc	a4,0x0
    800025a2:	fd070713          	addi	a4,a4,-48 # 8000256e <procfswrite>
    800025a6:	efb8                	sd	a4,88(a5)
  devsw[PROCFS].read = procfsread;
    800025a8:	00000717          	auipc	a4,0x0
    800025ac:	fb870713          	addi	a4,a4,-72 # 80002560 <procfsread>
    800025b0:	ebb8                	sd	a4,80(a5)
}
    800025b2:	6422                	ld	s0,8(sp)
    800025b4:	0141                	addi	sp,sp,16
    800025b6:	8082                	ret

00000000800025b8 <swtch>:
    800025b8:	00153023          	sd	ra,0(a0)
    800025bc:	00253423          	sd	sp,8(a0)
    800025c0:	e900                	sd	s0,16(a0)
    800025c2:	ed04                	sd	s1,24(a0)
    800025c4:	03253023          	sd	s2,32(a0)
    800025c8:	03353423          	sd	s3,40(a0)
    800025cc:	03453823          	sd	s4,48(a0)
    800025d0:	03553c23          	sd	s5,56(a0)
    800025d4:	05653023          	sd	s6,64(a0)
    800025d8:	05753423          	sd	s7,72(a0)
    800025dc:	05853823          	sd	s8,80(a0)
    800025e0:	05953c23          	sd	s9,88(a0)
    800025e4:	07a53023          	sd	s10,96(a0)
    800025e8:	07b53423          	sd	s11,104(a0)
    800025ec:	0005b083          	ld	ra,0(a1)
    800025f0:	0085b103          	ld	sp,8(a1)
    800025f4:	6980                	ld	s0,16(a1)
    800025f6:	6d84                	ld	s1,24(a1)
    800025f8:	0205b903          	ld	s2,32(a1)
    800025fc:	0285b983          	ld	s3,40(a1)
    80002600:	0305ba03          	ld	s4,48(a1)
    80002604:	0385ba83          	ld	s5,56(a1)
    80002608:	0405bb03          	ld	s6,64(a1)
    8000260c:	0485bb83          	ld	s7,72(a1)
    80002610:	0505bc03          	ld	s8,80(a1)
    80002614:	0585bc83          	ld	s9,88(a1)
    80002618:	0605bd03          	ld	s10,96(a1)
    8000261c:	0685bd83          	ld	s11,104(a1)
    80002620:	8082                	ret

0000000080002622 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002622:	1141                	addi	sp,sp,-16
    80002624:	e406                	sd	ra,8(sp)
    80002626:	e022                	sd	s0,0(sp)
    80002628:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000262a:	00006597          	auipc	a1,0x6
    8000262e:	cae58593          	addi	a1,a1,-850 # 800082d8 <states.0+0x30>
    80002632:	00015517          	auipc	a0,0x15
    80002636:	a9e50513          	addi	a0,a0,-1378 # 800170d0 <tickslock>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	4f8080e7          	jalr	1272(ra) # 80000b32 <initlock>
}
    80002642:	60a2                	ld	ra,8(sp)
    80002644:	6402                	ld	s0,0(sp)
    80002646:	0141                	addi	sp,sp,16
    80002648:	8082                	ret

000000008000264a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000264a:	1141                	addi	sp,sp,-16
    8000264c:	e422                	sd	s0,8(sp)
    8000264e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002650:	00003797          	auipc	a5,0x3
    80002654:	54078793          	addi	a5,a5,1344 # 80005b90 <kernelvec>
    80002658:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000265c:	6422                	ld	s0,8(sp)
    8000265e:	0141                	addi	sp,sp,16
    80002660:	8082                	ret

0000000080002662 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002662:	1141                	addi	sp,sp,-16
    80002664:	e406                	sd	ra,8(sp)
    80002666:	e022                	sd	s0,0(sp)
    80002668:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	31c080e7          	jalr	796(ra) # 80001986 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002672:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002676:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002678:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000267c:	00005617          	auipc	a2,0x5
    80002680:	98460613          	addi	a2,a2,-1660 # 80007000 <_trampoline>
    80002684:	00005697          	auipc	a3,0x5
    80002688:	97c68693          	addi	a3,a3,-1668 # 80007000 <_trampoline>
    8000268c:	8e91                	sub	a3,a3,a2
    8000268e:	040007b7          	lui	a5,0x4000
    80002692:	17fd                	addi	a5,a5,-1
    80002694:	07b2                	slli	a5,a5,0xc
    80002696:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002698:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000269c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000269e:	180026f3          	csrr	a3,satp
    800026a2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026a4:	6d38                	ld	a4,88(a0)
    800026a6:	6134                	ld	a3,64(a0)
    800026a8:	6585                	lui	a1,0x1
    800026aa:	96ae                	add	a3,a3,a1
    800026ac:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ae:	6d38                	ld	a4,88(a0)
    800026b0:	00000697          	auipc	a3,0x0
    800026b4:	13868693          	addi	a3,a3,312 # 800027e8 <usertrap>
    800026b8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ba:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026bc:	8692                	mv	a3,tp
    800026be:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026c4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026c8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026cc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026d0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026d2:	6f18                	ld	a4,24(a4)
    800026d4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026d8:	692c                	ld	a1,80(a0)
    800026da:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026dc:	00005717          	auipc	a4,0x5
    800026e0:	9b470713          	addi	a4,a4,-1612 # 80007090 <userret>
    800026e4:	8f11                	sub	a4,a4,a2
    800026e6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026e8:	577d                	li	a4,-1
    800026ea:	177e                	slli	a4,a4,0x3f
    800026ec:	8dd9                	or	a1,a1,a4
    800026ee:	02000537          	lui	a0,0x2000
    800026f2:	157d                	addi	a0,a0,-1
    800026f4:	0536                	slli	a0,a0,0xd
    800026f6:	9782                	jalr	a5
}
    800026f8:	60a2                	ld	ra,8(sp)
    800026fa:	6402                	ld	s0,0(sp)
    800026fc:	0141                	addi	sp,sp,16
    800026fe:	8082                	ret

0000000080002700 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002700:	1101                	addi	sp,sp,-32
    80002702:	ec06                	sd	ra,24(sp)
    80002704:	e822                	sd	s0,16(sp)
    80002706:	e426                	sd	s1,8(sp)
    80002708:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000270a:	00015497          	auipc	s1,0x15
    8000270e:	9c648493          	addi	s1,s1,-1594 # 800170d0 <tickslock>
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	4ae080e7          	jalr	1198(ra) # 80000bc2 <acquire>
  ticks++;
    8000271c:	00007517          	auipc	a0,0x7
    80002720:	91450513          	addi	a0,a0,-1772 # 80009030 <ticks>
    80002724:	411c                	lw	a5,0(a0)
    80002726:	2785                	addiw	a5,a5,1
    80002728:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000272a:	00000097          	auipc	ra,0x0
    8000272e:	aa8080e7          	jalr	-1368(ra) # 800021d2 <wakeup>
  release(&tickslock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	542080e7          	jalr	1346(ra) # 80000c76 <release>
}
    8000273c:	60e2                	ld	ra,24(sp)
    8000273e:	6442                	ld	s0,16(sp)
    80002740:	64a2                	ld	s1,8(sp)
    80002742:	6105                	addi	sp,sp,32
    80002744:	8082                	ret

0000000080002746 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002746:	1101                	addi	sp,sp,-32
    80002748:	ec06                	sd	ra,24(sp)
    8000274a:	e822                	sd	s0,16(sp)
    8000274c:	e426                	sd	s1,8(sp)
    8000274e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002750:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002754:	00074d63          	bltz	a4,8000276e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002758:	57fd                	li	a5,-1
    8000275a:	17fe                	slli	a5,a5,0x3f
    8000275c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000275e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002760:	06f70363          	beq	a4,a5,800027c6 <devintr+0x80>
  }
}
    80002764:	60e2                	ld	ra,24(sp)
    80002766:	6442                	ld	s0,16(sp)
    80002768:	64a2                	ld	s1,8(sp)
    8000276a:	6105                	addi	sp,sp,32
    8000276c:	8082                	ret
     (scause & 0xff) == 9){
    8000276e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002772:	46a5                	li	a3,9
    80002774:	fed792e3          	bne	a5,a3,80002758 <devintr+0x12>
    int irq = plic_claim();
    80002778:	00003097          	auipc	ra,0x3
    8000277c:	520080e7          	jalr	1312(ra) # 80005c98 <plic_claim>
    80002780:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002782:	47a9                	li	a5,10
    80002784:	02f50763          	beq	a0,a5,800027b2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002788:	4785                	li	a5,1
    8000278a:	02f50963          	beq	a0,a5,800027bc <devintr+0x76>
    return 1;
    8000278e:	4505                	li	a0,1
    } else if(irq){
    80002790:	d8f1                	beqz	s1,80002764 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002792:	85a6                	mv	a1,s1
    80002794:	00006517          	auipc	a0,0x6
    80002798:	b4c50513          	addi	a0,a0,-1204 # 800082e0 <states.0+0x38>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	dd8080e7          	jalr	-552(ra) # 80000574 <printf>
      plic_complete(irq);
    800027a4:	8526                	mv	a0,s1
    800027a6:	00003097          	auipc	ra,0x3
    800027aa:	516080e7          	jalr	1302(ra) # 80005cbc <plic_complete>
    return 1;
    800027ae:	4505                	li	a0,1
    800027b0:	bf55                	j	80002764 <devintr+0x1e>
      uartintr();
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	1d4080e7          	jalr	468(ra) # 80000986 <uartintr>
    800027ba:	b7ed                	j	800027a4 <devintr+0x5e>
      virtio_disk_intr();
    800027bc:	00004097          	auipc	ra,0x4
    800027c0:	992080e7          	jalr	-1646(ra) # 8000614e <virtio_disk_intr>
    800027c4:	b7c5                	j	800027a4 <devintr+0x5e>
    if(cpuid() == 0){
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	194080e7          	jalr	404(ra) # 8000195a <cpuid>
    800027ce:	c901                	beqz	a0,800027de <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027d0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027d4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027d6:	14479073          	csrw	sip,a5
    return 2;
    800027da:	4509                	li	a0,2
    800027dc:	b761                	j	80002764 <devintr+0x1e>
      clockintr();
    800027de:	00000097          	auipc	ra,0x0
    800027e2:	f22080e7          	jalr	-222(ra) # 80002700 <clockintr>
    800027e6:	b7ed                	j	800027d0 <devintr+0x8a>

00000000800027e8 <usertrap>:
{
    800027e8:	1101                	addi	sp,sp,-32
    800027ea:	ec06                	sd	ra,24(sp)
    800027ec:	e822                	sd	s0,16(sp)
    800027ee:	e426                	sd	s1,8(sp)
    800027f0:	e04a                	sd	s2,0(sp)
    800027f2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027f8:	1007f793          	andi	a5,a5,256
    800027fc:	e3ad                	bnez	a5,8000285e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027fe:	00003797          	auipc	a5,0x3
    80002802:	39278793          	addi	a5,a5,914 # 80005b90 <kernelvec>
    80002806:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000280a:	fffff097          	auipc	ra,0xfffff
    8000280e:	17c080e7          	jalr	380(ra) # 80001986 <myproc>
    80002812:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002814:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002816:	14102773          	csrr	a4,sepc
    8000281a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000281c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002820:	47a1                	li	a5,8
    80002822:	04f71c63          	bne	a4,a5,8000287a <usertrap+0x92>
    if(p->killed)
    80002826:	551c                	lw	a5,40(a0)
    80002828:	e3b9                	bnez	a5,8000286e <usertrap+0x86>
    p->trapframe->epc += 4;
    8000282a:	6cb8                	ld	a4,88(s1)
    8000282c:	6f1c                	ld	a5,24(a4)
    8000282e:	0791                	addi	a5,a5,4
    80002830:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002832:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002836:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000283a:	10079073          	csrw	sstatus,a5
    syscall();
    8000283e:	00000097          	auipc	ra,0x0
    80002842:	2e0080e7          	jalr	736(ra) # 80002b1e <syscall>
  if(p->killed)
    80002846:	549c                	lw	a5,40(s1)
    80002848:	ebc1                	bnez	a5,800028d8 <usertrap+0xf0>
  usertrapret();
    8000284a:	00000097          	auipc	ra,0x0
    8000284e:	e18080e7          	jalr	-488(ra) # 80002662 <usertrapret>
}
    80002852:	60e2                	ld	ra,24(sp)
    80002854:	6442                	ld	s0,16(sp)
    80002856:	64a2                	ld	s1,8(sp)
    80002858:	6902                	ld	s2,0(sp)
    8000285a:	6105                	addi	sp,sp,32
    8000285c:	8082                	ret
    panic("usertrap: not from user mode");
    8000285e:	00006517          	auipc	a0,0x6
    80002862:	aa250513          	addi	a0,a0,-1374 # 80008300 <states.0+0x58>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	cc4080e7          	jalr	-828(ra) # 8000052a <panic>
      exit(-1);
    8000286e:	557d                	li	a0,-1
    80002870:	00000097          	auipc	ra,0x0
    80002874:	a32080e7          	jalr	-1486(ra) # 800022a2 <exit>
    80002878:	bf4d                	j	8000282a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	ecc080e7          	jalr	-308(ra) # 80002746 <devintr>
    80002882:	892a                	mv	s2,a0
    80002884:	c501                	beqz	a0,8000288c <usertrap+0xa4>
  if(p->killed)
    80002886:	549c                	lw	a5,40(s1)
    80002888:	c3a1                	beqz	a5,800028c8 <usertrap+0xe0>
    8000288a:	a815                	j	800028be <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002890:	5890                	lw	a2,48(s1)
    80002892:	00006517          	auipc	a0,0x6
    80002896:	a8e50513          	addi	a0,a0,-1394 # 80008320 <states.0+0x78>
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	cda080e7          	jalr	-806(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028a6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028aa:	00006517          	auipc	a0,0x6
    800028ae:	aa650513          	addi	a0,a0,-1370 # 80008350 <states.0+0xa8>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	cc2080e7          	jalr	-830(ra) # 80000574 <printf>
    p->killed = 1;
    800028ba:	4785                	li	a5,1
    800028bc:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028be:	557d                	li	a0,-1
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	9e2080e7          	jalr	-1566(ra) # 800022a2 <exit>
  if(which_dev == 2)
    800028c8:	4789                	li	a5,2
    800028ca:	f8f910e3          	bne	s2,a5,8000284a <usertrap+0x62>
    yield();
    800028ce:	fffff097          	auipc	ra,0xfffff
    800028d2:	73c080e7          	jalr	1852(ra) # 8000200a <yield>
    800028d6:	bf95                	j	8000284a <usertrap+0x62>
  int which_dev = 0;
    800028d8:	4901                	li	s2,0
    800028da:	b7d5                	j	800028be <usertrap+0xd6>

00000000800028dc <kerneltrap>:
{
    800028dc:	7179                	addi	sp,sp,-48
    800028de:	f406                	sd	ra,40(sp)
    800028e0:	f022                	sd	s0,32(sp)
    800028e2:	ec26                	sd	s1,24(sp)
    800028e4:	e84a                	sd	s2,16(sp)
    800028e6:	e44e                	sd	s3,8(sp)
    800028e8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ea:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ee:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028f6:	1004f793          	andi	a5,s1,256
    800028fa:	cb85                	beqz	a5,8000292a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002900:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002902:	ef85                	bnez	a5,8000293a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002904:	00000097          	auipc	ra,0x0
    80002908:	e42080e7          	jalr	-446(ra) # 80002746 <devintr>
    8000290c:	cd1d                	beqz	a0,8000294a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000290e:	4789                	li	a5,2
    80002910:	06f50a63          	beq	a0,a5,80002984 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002914:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002918:	10049073          	csrw	sstatus,s1
}
    8000291c:	70a2                	ld	ra,40(sp)
    8000291e:	7402                	ld	s0,32(sp)
    80002920:	64e2                	ld	s1,24(sp)
    80002922:	6942                	ld	s2,16(sp)
    80002924:	69a2                	ld	s3,8(sp)
    80002926:	6145                	addi	sp,sp,48
    80002928:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000292a:	00006517          	auipc	a0,0x6
    8000292e:	a4650513          	addi	a0,a0,-1466 # 80008370 <states.0+0xc8>
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	bf8080e7          	jalr	-1032(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	a5e50513          	addi	a0,a0,-1442 # 80008398 <states.0+0xf0>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	be8080e7          	jalr	-1048(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000294a:	85ce                	mv	a1,s3
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	a6c50513          	addi	a0,a0,-1428 # 800083b8 <states.0+0x110>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	c20080e7          	jalr	-992(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002960:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002964:	00006517          	auipc	a0,0x6
    80002968:	a6450513          	addi	a0,a0,-1436 # 800083c8 <states.0+0x120>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c08080e7          	jalr	-1016(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002974:	00006517          	auipc	a0,0x6
    80002978:	a6c50513          	addi	a0,a0,-1428 # 800083e0 <states.0+0x138>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	bae080e7          	jalr	-1106(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	002080e7          	jalr	2(ra) # 80001986 <myproc>
    8000298c:	d541                	beqz	a0,80002914 <kerneltrap+0x38>
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	ff8080e7          	jalr	-8(ra) # 80001986 <myproc>
    80002996:	4d18                	lw	a4,24(a0)
    80002998:	4791                	li	a5,4
    8000299a:	f6f71de3          	bne	a4,a5,80002914 <kerneltrap+0x38>
    yield();
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	66c080e7          	jalr	1644(ra) # 8000200a <yield>
    800029a6:	b7bd                	j	80002914 <kerneltrap+0x38>

00000000800029a8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029a8:	1101                	addi	sp,sp,-32
    800029aa:	ec06                	sd	ra,24(sp)
    800029ac:	e822                	sd	s0,16(sp)
    800029ae:	e426                	sd	s1,8(sp)
    800029b0:	1000                	addi	s0,sp,32
    800029b2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	fd2080e7          	jalr	-46(ra) # 80001986 <myproc>
  switch (n) {
    800029bc:	4795                	li	a5,5
    800029be:	0497e163          	bltu	a5,s1,80002a00 <argraw+0x58>
    800029c2:	048a                	slli	s1,s1,0x2
    800029c4:	00006717          	auipc	a4,0x6
    800029c8:	a5470713          	addi	a4,a4,-1452 # 80008418 <states.0+0x170>
    800029cc:	94ba                	add	s1,s1,a4
    800029ce:	409c                	lw	a5,0(s1)
    800029d0:	97ba                	add	a5,a5,a4
    800029d2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029d4:	6d3c                	ld	a5,88(a0)
    800029d6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029d8:	60e2                	ld	ra,24(sp)
    800029da:	6442                	ld	s0,16(sp)
    800029dc:	64a2                	ld	s1,8(sp)
    800029de:	6105                	addi	sp,sp,32
    800029e0:	8082                	ret
    return p->trapframe->a1;
    800029e2:	6d3c                	ld	a5,88(a0)
    800029e4:	7fa8                	ld	a0,120(a5)
    800029e6:	bfcd                	j	800029d8 <argraw+0x30>
    return p->trapframe->a2;
    800029e8:	6d3c                	ld	a5,88(a0)
    800029ea:	63c8                	ld	a0,128(a5)
    800029ec:	b7f5                	j	800029d8 <argraw+0x30>
    return p->trapframe->a3;
    800029ee:	6d3c                	ld	a5,88(a0)
    800029f0:	67c8                	ld	a0,136(a5)
    800029f2:	b7dd                	j	800029d8 <argraw+0x30>
    return p->trapframe->a4;
    800029f4:	6d3c                	ld	a5,88(a0)
    800029f6:	6bc8                	ld	a0,144(a5)
    800029f8:	b7c5                	j	800029d8 <argraw+0x30>
    return p->trapframe->a5;
    800029fa:	6d3c                	ld	a5,88(a0)
    800029fc:	6fc8                	ld	a0,152(a5)
    800029fe:	bfe9                	j	800029d8 <argraw+0x30>
  panic("argraw");
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	9f050513          	addi	a0,a0,-1552 # 800083f0 <states.0+0x148>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b22080e7          	jalr	-1246(ra) # 8000052a <panic>

0000000080002a10 <fetchaddr>:
{
    80002a10:	1101                	addi	sp,sp,-32
    80002a12:	ec06                	sd	ra,24(sp)
    80002a14:	e822                	sd	s0,16(sp)
    80002a16:	e426                	sd	s1,8(sp)
    80002a18:	e04a                	sd	s2,0(sp)
    80002a1a:	1000                	addi	s0,sp,32
    80002a1c:	84aa                	mv	s1,a0
    80002a1e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a20:	fffff097          	auipc	ra,0xfffff
    80002a24:	f66080e7          	jalr	-154(ra) # 80001986 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a28:	653c                	ld	a5,72(a0)
    80002a2a:	02f4f863          	bgeu	s1,a5,80002a5a <fetchaddr+0x4a>
    80002a2e:	00848713          	addi	a4,s1,8
    80002a32:	02e7e663          	bltu	a5,a4,80002a5e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a36:	46a1                	li	a3,8
    80002a38:	8626                	mv	a2,s1
    80002a3a:	85ca                	mv	a1,s2
    80002a3c:	6928                	ld	a0,80(a0)
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	c94080e7          	jalr	-876(ra) # 800016d2 <copyin>
    80002a46:	00a03533          	snez	a0,a0
    80002a4a:	40a00533          	neg	a0,a0
}
    80002a4e:	60e2                	ld	ra,24(sp)
    80002a50:	6442                	ld	s0,16(sp)
    80002a52:	64a2                	ld	s1,8(sp)
    80002a54:	6902                	ld	s2,0(sp)
    80002a56:	6105                	addi	sp,sp,32
    80002a58:	8082                	ret
    return -1;
    80002a5a:	557d                	li	a0,-1
    80002a5c:	bfcd                	j	80002a4e <fetchaddr+0x3e>
    80002a5e:	557d                	li	a0,-1
    80002a60:	b7fd                	j	80002a4e <fetchaddr+0x3e>

0000000080002a62 <fetchstr>:
{
    80002a62:	7179                	addi	sp,sp,-48
    80002a64:	f406                	sd	ra,40(sp)
    80002a66:	f022                	sd	s0,32(sp)
    80002a68:	ec26                	sd	s1,24(sp)
    80002a6a:	e84a                	sd	s2,16(sp)
    80002a6c:	e44e                	sd	s3,8(sp)
    80002a6e:	1800                	addi	s0,sp,48
    80002a70:	892a                	mv	s2,a0
    80002a72:	84ae                	mv	s1,a1
    80002a74:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	f10080e7          	jalr	-240(ra) # 80001986 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a7e:	86ce                	mv	a3,s3
    80002a80:	864a                	mv	a2,s2
    80002a82:	85a6                	mv	a1,s1
    80002a84:	6928                	ld	a0,80(a0)
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	cda080e7          	jalr	-806(ra) # 80001760 <copyinstr>
  if(err < 0)
    80002a8e:	00054763          	bltz	a0,80002a9c <fetchstr+0x3a>
  return strlen(buf);
    80002a92:	8526                	mv	a0,s1
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	3ae080e7          	jalr	942(ra) # 80000e42 <strlen>
}
    80002a9c:	70a2                	ld	ra,40(sp)
    80002a9e:	7402                	ld	s0,32(sp)
    80002aa0:	64e2                	ld	s1,24(sp)
    80002aa2:	6942                	ld	s2,16(sp)
    80002aa4:	69a2                	ld	s3,8(sp)
    80002aa6:	6145                	addi	sp,sp,48
    80002aa8:	8082                	ret

0000000080002aaa <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002aaa:	1101                	addi	sp,sp,-32
    80002aac:	ec06                	sd	ra,24(sp)
    80002aae:	e822                	sd	s0,16(sp)
    80002ab0:	e426                	sd	s1,8(sp)
    80002ab2:	1000                	addi	s0,sp,32
    80002ab4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	ef2080e7          	jalr	-270(ra) # 800029a8 <argraw>
    80002abe:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ac0:	4501                	li	a0,0
    80002ac2:	60e2                	ld	ra,24(sp)
    80002ac4:	6442                	ld	s0,16(sp)
    80002ac6:	64a2                	ld	s1,8(sp)
    80002ac8:	6105                	addi	sp,sp,32
    80002aca:	8082                	ret

0000000080002acc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002acc:	1101                	addi	sp,sp,-32
    80002ace:	ec06                	sd	ra,24(sp)
    80002ad0:	e822                	sd	s0,16(sp)
    80002ad2:	e426                	sd	s1,8(sp)
    80002ad4:	1000                	addi	s0,sp,32
    80002ad6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	ed0080e7          	jalr	-304(ra) # 800029a8 <argraw>
    80002ae0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ae2:	4501                	li	a0,0
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret

0000000080002aee <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aee:	1101                	addi	sp,sp,-32
    80002af0:	ec06                	sd	ra,24(sp)
    80002af2:	e822                	sd	s0,16(sp)
    80002af4:	e426                	sd	s1,8(sp)
    80002af6:	e04a                	sd	s2,0(sp)
    80002af8:	1000                	addi	s0,sp,32
    80002afa:	84ae                	mv	s1,a1
    80002afc:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	eaa080e7          	jalr	-342(ra) # 800029a8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b06:	864a                	mv	a2,s2
    80002b08:	85a6                	mv	a1,s1
    80002b0a:	00000097          	auipc	ra,0x0
    80002b0e:	f58080e7          	jalr	-168(ra) # 80002a62 <fetchstr>
}
    80002b12:	60e2                	ld	ra,24(sp)
    80002b14:	6442                	ld	s0,16(sp)
    80002b16:	64a2                	ld	s1,8(sp)
    80002b18:	6902                	ld	s2,0(sp)
    80002b1a:	6105                	addi	sp,sp,32
    80002b1c:	8082                	ret

0000000080002b1e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b1e:	1101                	addi	sp,sp,-32
    80002b20:	ec06                	sd	ra,24(sp)
    80002b22:	e822                	sd	s0,16(sp)
    80002b24:	e426                	sd	s1,8(sp)
    80002b26:	e04a                	sd	s2,0(sp)
    80002b28:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	e5c080e7          	jalr	-420(ra) # 80001986 <myproc>
    80002b32:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b34:	05853903          	ld	s2,88(a0)
    80002b38:	0a893783          	ld	a5,168(s2)
    80002b3c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b40:	37fd                	addiw	a5,a5,-1
    80002b42:	4751                	li	a4,20
    80002b44:	00f76f63          	bltu	a4,a5,80002b62 <syscall+0x44>
    80002b48:	00369713          	slli	a4,a3,0x3
    80002b4c:	00006797          	auipc	a5,0x6
    80002b50:	8e478793          	addi	a5,a5,-1820 # 80008430 <syscalls>
    80002b54:	97ba                	add	a5,a5,a4
    80002b56:	639c                	ld	a5,0(a5)
    80002b58:	c789                	beqz	a5,80002b62 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b5a:	9782                	jalr	a5
    80002b5c:	06a93823          	sd	a0,112(s2)
    80002b60:	a839                	j	80002b7e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b62:	15848613          	addi	a2,s1,344
    80002b66:	588c                	lw	a1,48(s1)
    80002b68:	00006517          	auipc	a0,0x6
    80002b6c:	89050513          	addi	a0,a0,-1904 # 800083f8 <states.0+0x150>
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	a04080e7          	jalr	-1532(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b78:	6cbc                	ld	a5,88(s1)
    80002b7a:	577d                	li	a4,-1
    80002b7c:	fbb8                	sd	a4,112(a5)
  }
}
    80002b7e:	60e2                	ld	ra,24(sp)
    80002b80:	6442                	ld	s0,16(sp)
    80002b82:	64a2                	ld	s1,8(sp)
    80002b84:	6902                	ld	s2,0(sp)
    80002b86:	6105                	addi	sp,sp,32
    80002b88:	8082                	ret

0000000080002b8a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b8a:	1101                	addi	sp,sp,-32
    80002b8c:	ec06                	sd	ra,24(sp)
    80002b8e:	e822                	sd	s0,16(sp)
    80002b90:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b92:	fec40593          	addi	a1,s0,-20
    80002b96:	4501                	li	a0,0
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	f12080e7          	jalr	-238(ra) # 80002aaa <argint>
    return -1;
    80002ba0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ba2:	00054963          	bltz	a0,80002bb4 <sys_exit+0x2a>
  exit(n);
    80002ba6:	fec42503          	lw	a0,-20(s0)
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	6f8080e7          	jalr	1784(ra) # 800022a2 <exit>
  return 0;  // not reached
    80002bb2:	4781                	li	a5,0
}
    80002bb4:	853e                	mv	a0,a5
    80002bb6:	60e2                	ld	ra,24(sp)
    80002bb8:	6442                	ld	s0,16(sp)
    80002bba:	6105                	addi	sp,sp,32
    80002bbc:	8082                	ret

0000000080002bbe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bbe:	1141                	addi	sp,sp,-16
    80002bc0:	e406                	sd	ra,8(sp)
    80002bc2:	e022                	sd	s0,0(sp)
    80002bc4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	dc0080e7          	jalr	-576(ra) # 80001986 <myproc>
}
    80002bce:	5908                	lw	a0,48(a0)
    80002bd0:	60a2                	ld	ra,8(sp)
    80002bd2:	6402                	ld	s0,0(sp)
    80002bd4:	0141                	addi	sp,sp,16
    80002bd6:	8082                	ret

0000000080002bd8 <sys_fork>:

uint64
sys_fork(void)
{
    80002bd8:	1141                	addi	sp,sp,-16
    80002bda:	e406                	sd	ra,8(sp)
    80002bdc:	e022                	sd	s0,0(sp)
    80002bde:	0800                	addi	s0,sp,16
  return fork();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	174080e7          	jalr	372(ra) # 80001d54 <fork>
}
    80002be8:	60a2                	ld	ra,8(sp)
    80002bea:	6402                	ld	s0,0(sp)
    80002bec:	0141                	addi	sp,sp,16
    80002bee:	8082                	ret

0000000080002bf0 <sys_wait>:

uint64
sys_wait(void)
{
    80002bf0:	1101                	addi	sp,sp,-32
    80002bf2:	ec06                	sd	ra,24(sp)
    80002bf4:	e822                	sd	s0,16(sp)
    80002bf6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bf8:	fe840593          	addi	a1,s0,-24
    80002bfc:	4501                	li	a0,0
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	ece080e7          	jalr	-306(ra) # 80002acc <argaddr>
    80002c06:	87aa                	mv	a5,a0
    return -1;
    80002c08:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c0a:	0007c863          	bltz	a5,80002c1a <sys_wait+0x2a>
  return wait(p);
    80002c0e:	fe843503          	ld	a0,-24(s0)
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	498080e7          	jalr	1176(ra) # 800020aa <wait>
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret

0000000080002c22 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c22:	7179                	addi	sp,sp,-48
    80002c24:	f406                	sd	ra,40(sp)
    80002c26:	f022                	sd	s0,32(sp)
    80002c28:	ec26                	sd	s1,24(sp)
    80002c2a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c2c:	fdc40593          	addi	a1,s0,-36
    80002c30:	4501                	li	a0,0
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	e78080e7          	jalr	-392(ra) # 80002aaa <argint>
    return -1;
    80002c3a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c3c:	00054f63          	bltz	a0,80002c5a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	d46080e7          	jalr	-698(ra) # 80001986 <myproc>
    80002c48:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c4a:	fdc42503          	lw	a0,-36(s0)
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	092080e7          	jalr	146(ra) # 80001ce0 <growproc>
    80002c56:	00054863          	bltz	a0,80002c66 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c5a:	8526                	mv	a0,s1
    80002c5c:	70a2                	ld	ra,40(sp)
    80002c5e:	7402                	ld	s0,32(sp)
    80002c60:	64e2                	ld	s1,24(sp)
    80002c62:	6145                	addi	sp,sp,48
    80002c64:	8082                	ret
    return -1;
    80002c66:	54fd                	li	s1,-1
    80002c68:	bfcd                	j	80002c5a <sys_sbrk+0x38>

0000000080002c6a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c6a:	7139                	addi	sp,sp,-64
    80002c6c:	fc06                	sd	ra,56(sp)
    80002c6e:	f822                	sd	s0,48(sp)
    80002c70:	f426                	sd	s1,40(sp)
    80002c72:	f04a                	sd	s2,32(sp)
    80002c74:	ec4e                	sd	s3,24(sp)
    80002c76:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c78:	fcc40593          	addi	a1,s0,-52
    80002c7c:	4501                	li	a0,0
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	e2c080e7          	jalr	-468(ra) # 80002aaa <argint>
    return -1;
    80002c86:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c88:	06054563          	bltz	a0,80002cf2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c8c:	00014517          	auipc	a0,0x14
    80002c90:	44450513          	addi	a0,a0,1092 # 800170d0 <tickslock>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	f2e080e7          	jalr	-210(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002c9c:	00006917          	auipc	s2,0x6
    80002ca0:	39492903          	lw	s2,916(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002ca4:	fcc42783          	lw	a5,-52(s0)
    80002ca8:	cf85                	beqz	a5,80002ce0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002caa:	00014997          	auipc	s3,0x14
    80002cae:	42698993          	addi	s3,s3,1062 # 800170d0 <tickslock>
    80002cb2:	00006497          	auipc	s1,0x6
    80002cb6:	37e48493          	addi	s1,s1,894 # 80009030 <ticks>
    if(myproc()->killed){
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	ccc080e7          	jalr	-820(ra) # 80001986 <myproc>
    80002cc2:	551c                	lw	a5,40(a0)
    80002cc4:	ef9d                	bnez	a5,80002d02 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cc6:	85ce                	mv	a1,s3
    80002cc8:	8526                	mv	a0,s1
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	37c080e7          	jalr	892(ra) # 80002046 <sleep>
  while(ticks - ticks0 < n){
    80002cd2:	409c                	lw	a5,0(s1)
    80002cd4:	412787bb          	subw	a5,a5,s2
    80002cd8:	fcc42703          	lw	a4,-52(s0)
    80002cdc:	fce7efe3          	bltu	a5,a4,80002cba <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ce0:	00014517          	auipc	a0,0x14
    80002ce4:	3f050513          	addi	a0,a0,1008 # 800170d0 <tickslock>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	f8e080e7          	jalr	-114(ra) # 80000c76 <release>
  return 0;
    80002cf0:	4781                	li	a5,0
}
    80002cf2:	853e                	mv	a0,a5
    80002cf4:	70e2                	ld	ra,56(sp)
    80002cf6:	7442                	ld	s0,48(sp)
    80002cf8:	74a2                	ld	s1,40(sp)
    80002cfa:	7902                	ld	s2,32(sp)
    80002cfc:	69e2                	ld	s3,24(sp)
    80002cfe:	6121                	addi	sp,sp,64
    80002d00:	8082                	ret
      release(&tickslock);
    80002d02:	00014517          	auipc	a0,0x14
    80002d06:	3ce50513          	addi	a0,a0,974 # 800170d0 <tickslock>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	f6c080e7          	jalr	-148(ra) # 80000c76 <release>
      return -1;
    80002d12:	57fd                	li	a5,-1
    80002d14:	bff9                	j	80002cf2 <sys_sleep+0x88>

0000000080002d16 <sys_kill>:

uint64
sys_kill(void)
{
    80002d16:	1101                	addi	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d1e:	fec40593          	addi	a1,s0,-20
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	d86080e7          	jalr	-634(ra) # 80002aaa <argint>
    80002d2c:	87aa                	mv	a5,a0
    return -1;
    80002d2e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d30:	0007c863          	bltz	a5,80002d40 <sys_kill+0x2a>
  return kill(pid);
    80002d34:	fec42503          	lw	a0,-20(s0)
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	640080e7          	jalr	1600(ra) # 80002378 <kill>
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	6105                	addi	sp,sp,32
    80002d46:	8082                	ret

0000000080002d48 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d48:	1101                	addi	sp,sp,-32
    80002d4a:	ec06                	sd	ra,24(sp)
    80002d4c:	e822                	sd	s0,16(sp)
    80002d4e:	e426                	sd	s1,8(sp)
    80002d50:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d52:	00014517          	auipc	a0,0x14
    80002d56:	37e50513          	addi	a0,a0,894 # 800170d0 <tickslock>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	e68080e7          	jalr	-408(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002d62:	00006497          	auipc	s1,0x6
    80002d66:	2ce4a483          	lw	s1,718(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d6a:	00014517          	auipc	a0,0x14
    80002d6e:	36650513          	addi	a0,a0,870 # 800170d0 <tickslock>
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	f04080e7          	jalr	-252(ra) # 80000c76 <release>
  return xticks;
}
    80002d7a:	02049513          	slli	a0,s1,0x20
    80002d7e:	9101                	srli	a0,a0,0x20
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6105                	addi	sp,sp,32
    80002d88:	8082                	ret

0000000080002d8a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d8a:	7179                	addi	sp,sp,-48
    80002d8c:	f406                	sd	ra,40(sp)
    80002d8e:	f022                	sd	s0,32(sp)
    80002d90:	ec26                	sd	s1,24(sp)
    80002d92:	e84a                	sd	s2,16(sp)
    80002d94:	e44e                	sd	s3,8(sp)
    80002d96:	e052                	sd	s4,0(sp)
    80002d98:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d9a:	00005597          	auipc	a1,0x5
    80002d9e:	74658593          	addi	a1,a1,1862 # 800084e0 <syscalls+0xb0>
    80002da2:	00014517          	auipc	a0,0x14
    80002da6:	34650513          	addi	a0,a0,838 # 800170e8 <bcache>
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	d88080e7          	jalr	-632(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002db2:	0001c797          	auipc	a5,0x1c
    80002db6:	33678793          	addi	a5,a5,822 # 8001f0e8 <bcache+0x8000>
    80002dba:	0001c717          	auipc	a4,0x1c
    80002dbe:	59670713          	addi	a4,a4,1430 # 8001f350 <bcache+0x8268>
    80002dc2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dc6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dca:	00014497          	auipc	s1,0x14
    80002dce:	33648493          	addi	s1,s1,822 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002dd2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dd4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dd6:	00005a17          	auipc	s4,0x5
    80002dda:	712a0a13          	addi	s4,s4,1810 # 800084e8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dde:	2b893783          	ld	a5,696(s2)
    80002de2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002de4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002de8:	85d2                	mv	a1,s4
    80002dea:	01048513          	addi	a0,s1,16
    80002dee:	00001097          	auipc	ra,0x1
    80002df2:	562080e7          	jalr	1378(ra) # 80004350 <initsleeplock>
    bcache.head.next->prev = b;
    80002df6:	2b893783          	ld	a5,696(s2)
    80002dfa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dfc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e00:	45848493          	addi	s1,s1,1112
    80002e04:	fd349de3          	bne	s1,s3,80002dde <binit+0x54>
  }
}
    80002e08:	70a2                	ld	ra,40(sp)
    80002e0a:	7402                	ld	s0,32(sp)
    80002e0c:	64e2                	ld	s1,24(sp)
    80002e0e:	6942                	ld	s2,16(sp)
    80002e10:	69a2                	ld	s3,8(sp)
    80002e12:	6a02                	ld	s4,0(sp)
    80002e14:	6145                	addi	sp,sp,48
    80002e16:	8082                	ret

0000000080002e18 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e18:	7179                	addi	sp,sp,-48
    80002e1a:	f406                	sd	ra,40(sp)
    80002e1c:	f022                	sd	s0,32(sp)
    80002e1e:	ec26                	sd	s1,24(sp)
    80002e20:	e84a                	sd	s2,16(sp)
    80002e22:	e44e                	sd	s3,8(sp)
    80002e24:	1800                	addi	s0,sp,48
    80002e26:	892a                	mv	s2,a0
    80002e28:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e2a:	00014517          	auipc	a0,0x14
    80002e2e:	2be50513          	addi	a0,a0,702 # 800170e8 <bcache>
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	d90080e7          	jalr	-624(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e3a:	0001c497          	auipc	s1,0x1c
    80002e3e:	5664b483          	ld	s1,1382(s1) # 8001f3a0 <bcache+0x82b8>
    80002e42:	0001c797          	auipc	a5,0x1c
    80002e46:	50e78793          	addi	a5,a5,1294 # 8001f350 <bcache+0x8268>
    80002e4a:	02f48f63          	beq	s1,a5,80002e88 <bread+0x70>
    80002e4e:	873e                	mv	a4,a5
    80002e50:	a021                	j	80002e58 <bread+0x40>
    80002e52:	68a4                	ld	s1,80(s1)
    80002e54:	02e48a63          	beq	s1,a4,80002e88 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e58:	449c                	lw	a5,8(s1)
    80002e5a:	ff279ce3          	bne	a5,s2,80002e52 <bread+0x3a>
    80002e5e:	44dc                	lw	a5,12(s1)
    80002e60:	ff3799e3          	bne	a5,s3,80002e52 <bread+0x3a>
      b->refcnt++;
    80002e64:	40bc                	lw	a5,64(s1)
    80002e66:	2785                	addiw	a5,a5,1
    80002e68:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e6a:	00014517          	auipc	a0,0x14
    80002e6e:	27e50513          	addi	a0,a0,638 # 800170e8 <bcache>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	e04080e7          	jalr	-508(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002e7a:	01048513          	addi	a0,s1,16
    80002e7e:	00001097          	auipc	ra,0x1
    80002e82:	50c080e7          	jalr	1292(ra) # 8000438a <acquiresleep>
      return b;
    80002e86:	a8b9                	j	80002ee4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e88:	0001c497          	auipc	s1,0x1c
    80002e8c:	5104b483          	ld	s1,1296(s1) # 8001f398 <bcache+0x82b0>
    80002e90:	0001c797          	auipc	a5,0x1c
    80002e94:	4c078793          	addi	a5,a5,1216 # 8001f350 <bcache+0x8268>
    80002e98:	00f48863          	beq	s1,a5,80002ea8 <bread+0x90>
    80002e9c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e9e:	40bc                	lw	a5,64(s1)
    80002ea0:	cf81                	beqz	a5,80002eb8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ea2:	64a4                	ld	s1,72(s1)
    80002ea4:	fee49de3          	bne	s1,a4,80002e9e <bread+0x86>
  panic("bget: no buffers");
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	64850513          	addi	a0,a0,1608 # 800084f0 <syscalls+0xc0>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	67a080e7          	jalr	1658(ra) # 8000052a <panic>
      b->dev = dev;
    80002eb8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ebc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ec0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ec4:	4785                	li	a5,1
    80002ec6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ec8:	00014517          	auipc	a0,0x14
    80002ecc:	22050513          	addi	a0,a0,544 # 800170e8 <bcache>
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	da6080e7          	jalr	-602(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002ed8:	01048513          	addi	a0,s1,16
    80002edc:	00001097          	auipc	ra,0x1
    80002ee0:	4ae080e7          	jalr	1198(ra) # 8000438a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ee4:	409c                	lw	a5,0(s1)
    80002ee6:	cb89                	beqz	a5,80002ef8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ee8:	8526                	mv	a0,s1
    80002eea:	70a2                	ld	ra,40(sp)
    80002eec:	7402                	ld	s0,32(sp)
    80002eee:	64e2                	ld	s1,24(sp)
    80002ef0:	6942                	ld	s2,16(sp)
    80002ef2:	69a2                	ld	s3,8(sp)
    80002ef4:	6145                	addi	sp,sp,48
    80002ef6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ef8:	4581                	li	a1,0
    80002efa:	8526                	mv	a0,s1
    80002efc:	00003097          	auipc	ra,0x3
    80002f00:	fca080e7          	jalr	-54(ra) # 80005ec6 <virtio_disk_rw>
    b->valid = 1;
    80002f04:	4785                	li	a5,1
    80002f06:	c09c                	sw	a5,0(s1)
  return b;
    80002f08:	b7c5                	j	80002ee8 <bread+0xd0>

0000000080002f0a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f0a:	1101                	addi	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	e426                	sd	s1,8(sp)
    80002f12:	1000                	addi	s0,sp,32
    80002f14:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f16:	0541                	addi	a0,a0,16
    80002f18:	00001097          	auipc	ra,0x1
    80002f1c:	50c080e7          	jalr	1292(ra) # 80004424 <holdingsleep>
    80002f20:	cd01                	beqz	a0,80002f38 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f22:	4585                	li	a1,1
    80002f24:	8526                	mv	a0,s1
    80002f26:	00003097          	auipc	ra,0x3
    80002f2a:	fa0080e7          	jalr	-96(ra) # 80005ec6 <virtio_disk_rw>
}
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	64a2                	ld	s1,8(sp)
    80002f34:	6105                	addi	sp,sp,32
    80002f36:	8082                	ret
    panic("bwrite");
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	5d050513          	addi	a0,a0,1488 # 80008508 <syscalls+0xd8>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	5ea080e7          	jalr	1514(ra) # 8000052a <panic>

0000000080002f48 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f48:	1101                	addi	sp,sp,-32
    80002f4a:	ec06                	sd	ra,24(sp)
    80002f4c:	e822                	sd	s0,16(sp)
    80002f4e:	e426                	sd	s1,8(sp)
    80002f50:	e04a                	sd	s2,0(sp)
    80002f52:	1000                	addi	s0,sp,32
    80002f54:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f56:	01050913          	addi	s2,a0,16
    80002f5a:	854a                	mv	a0,s2
    80002f5c:	00001097          	auipc	ra,0x1
    80002f60:	4c8080e7          	jalr	1224(ra) # 80004424 <holdingsleep>
    80002f64:	c92d                	beqz	a0,80002fd6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f66:	854a                	mv	a0,s2
    80002f68:	00001097          	auipc	ra,0x1
    80002f6c:	478080e7          	jalr	1144(ra) # 800043e0 <releasesleep>

  acquire(&bcache.lock);
    80002f70:	00014517          	auipc	a0,0x14
    80002f74:	17850513          	addi	a0,a0,376 # 800170e8 <bcache>
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	c4a080e7          	jalr	-950(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002f80:	40bc                	lw	a5,64(s1)
    80002f82:	37fd                	addiw	a5,a5,-1
    80002f84:	0007871b          	sext.w	a4,a5
    80002f88:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f8a:	eb05                	bnez	a4,80002fba <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f8c:	68bc                	ld	a5,80(s1)
    80002f8e:	64b8                	ld	a4,72(s1)
    80002f90:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f92:	64bc                	ld	a5,72(s1)
    80002f94:	68b8                	ld	a4,80(s1)
    80002f96:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f98:	0001c797          	auipc	a5,0x1c
    80002f9c:	15078793          	addi	a5,a5,336 # 8001f0e8 <bcache+0x8000>
    80002fa0:	2b87b703          	ld	a4,696(a5)
    80002fa4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fa6:	0001c717          	auipc	a4,0x1c
    80002faa:	3aa70713          	addi	a4,a4,938 # 8001f350 <bcache+0x8268>
    80002fae:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fb0:	2b87b703          	ld	a4,696(a5)
    80002fb4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fb6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fba:	00014517          	auipc	a0,0x14
    80002fbe:	12e50513          	addi	a0,a0,302 # 800170e8 <bcache>
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	cb4080e7          	jalr	-844(ra) # 80000c76 <release>
}
    80002fca:	60e2                	ld	ra,24(sp)
    80002fcc:	6442                	ld	s0,16(sp)
    80002fce:	64a2                	ld	s1,8(sp)
    80002fd0:	6902                	ld	s2,0(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret
    panic("brelse");
    80002fd6:	00005517          	auipc	a0,0x5
    80002fda:	53a50513          	addi	a0,a0,1338 # 80008510 <syscalls+0xe0>
    80002fde:	ffffd097          	auipc	ra,0xffffd
    80002fe2:	54c080e7          	jalr	1356(ra) # 8000052a <panic>

0000000080002fe6 <bpin>:

void
bpin(struct buf *b) {
    80002fe6:	1101                	addi	sp,sp,-32
    80002fe8:	ec06                	sd	ra,24(sp)
    80002fea:	e822                	sd	s0,16(sp)
    80002fec:	e426                	sd	s1,8(sp)
    80002fee:	1000                	addi	s0,sp,32
    80002ff0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ff2:	00014517          	auipc	a0,0x14
    80002ff6:	0f650513          	addi	a0,a0,246 # 800170e8 <bcache>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	bc8080e7          	jalr	-1080(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003002:	40bc                	lw	a5,64(s1)
    80003004:	2785                	addiw	a5,a5,1
    80003006:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003008:	00014517          	auipc	a0,0x14
    8000300c:	0e050513          	addi	a0,a0,224 # 800170e8 <bcache>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	c66080e7          	jalr	-922(ra) # 80000c76 <release>
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	64a2                	ld	s1,8(sp)
    8000301e:	6105                	addi	sp,sp,32
    80003020:	8082                	ret

0000000080003022 <bunpin>:

void
bunpin(struct buf *b) {
    80003022:	1101                	addi	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	e426                	sd	s1,8(sp)
    8000302a:	1000                	addi	s0,sp,32
    8000302c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000302e:	00014517          	auipc	a0,0x14
    80003032:	0ba50513          	addi	a0,a0,186 # 800170e8 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	b8c080e7          	jalr	-1140(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000303e:	40bc                	lw	a5,64(s1)
    80003040:	37fd                	addiw	a5,a5,-1
    80003042:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003044:	00014517          	auipc	a0,0x14
    80003048:	0a450513          	addi	a0,a0,164 # 800170e8 <bcache>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c2a080e7          	jalr	-982(ra) # 80000c76 <release>
}
    80003054:	60e2                	ld	ra,24(sp)
    80003056:	6442                	ld	s0,16(sp)
    80003058:	64a2                	ld	s1,8(sp)
    8000305a:	6105                	addi	sp,sp,32
    8000305c:	8082                	ret

000000008000305e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	e04a                	sd	s2,0(sp)
    80003068:	1000                	addi	s0,sp,32
    8000306a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000306c:	00d5d59b          	srliw	a1,a1,0xd
    80003070:	0001c797          	auipc	a5,0x1c
    80003074:	7547a783          	lw	a5,1876(a5) # 8001f7c4 <sb+0x1c>
    80003078:	9dbd                	addw	a1,a1,a5
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	d9e080e7          	jalr	-610(ra) # 80002e18 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003082:	0074f713          	andi	a4,s1,7
    80003086:	4785                	li	a5,1
    80003088:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000308c:	14ce                	slli	s1,s1,0x33
    8000308e:	90d9                	srli	s1,s1,0x36
    80003090:	00950733          	add	a4,a0,s1
    80003094:	05874703          	lbu	a4,88(a4)
    80003098:	00e7f6b3          	and	a3,a5,a4
    8000309c:	c69d                	beqz	a3,800030ca <bfree+0x6c>
    8000309e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030a0:	94aa                	add	s1,s1,a0
    800030a2:	fff7c793          	not	a5,a5
    800030a6:	8ff9                	and	a5,a5,a4
    800030a8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030ac:	00001097          	auipc	ra,0x1
    800030b0:	1be080e7          	jalr	446(ra) # 8000426a <log_write>
  brelse(bp);
    800030b4:	854a                	mv	a0,s2
    800030b6:	00000097          	auipc	ra,0x0
    800030ba:	e92080e7          	jalr	-366(ra) # 80002f48 <brelse>
}
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	64a2                	ld	s1,8(sp)
    800030c4:	6902                	ld	s2,0(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret
    panic("freeing free block");
    800030ca:	00005517          	auipc	a0,0x5
    800030ce:	44e50513          	addi	a0,a0,1102 # 80008518 <syscalls+0xe8>
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	458080e7          	jalr	1112(ra) # 8000052a <panic>

00000000800030da <balloc>:
{
    800030da:	711d                	addi	sp,sp,-96
    800030dc:	ec86                	sd	ra,88(sp)
    800030de:	e8a2                	sd	s0,80(sp)
    800030e0:	e4a6                	sd	s1,72(sp)
    800030e2:	e0ca                	sd	s2,64(sp)
    800030e4:	fc4e                	sd	s3,56(sp)
    800030e6:	f852                	sd	s4,48(sp)
    800030e8:	f456                	sd	s5,40(sp)
    800030ea:	f05a                	sd	s6,32(sp)
    800030ec:	ec5e                	sd	s7,24(sp)
    800030ee:	e862                	sd	s8,16(sp)
    800030f0:	e466                	sd	s9,8(sp)
    800030f2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030f4:	0001c797          	auipc	a5,0x1c
    800030f8:	6b87a783          	lw	a5,1720(a5) # 8001f7ac <sb+0x4>
    800030fc:	cbd1                	beqz	a5,80003190 <balloc+0xb6>
    800030fe:	8baa                	mv	s7,a0
    80003100:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003102:	0001cb17          	auipc	s6,0x1c
    80003106:	6a6b0b13          	addi	s6,s6,1702 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000310a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000310c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000310e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003110:	6c89                	lui	s9,0x2
    80003112:	a831                	j	8000312e <balloc+0x54>
    brelse(bp);
    80003114:	854a                	mv	a0,s2
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	e32080e7          	jalr	-462(ra) # 80002f48 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000311e:	015c87bb          	addw	a5,s9,s5
    80003122:	00078a9b          	sext.w	s5,a5
    80003126:	004b2703          	lw	a4,4(s6)
    8000312a:	06eaf363          	bgeu	s5,a4,80003190 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000312e:	41fad79b          	sraiw	a5,s5,0x1f
    80003132:	0137d79b          	srliw	a5,a5,0x13
    80003136:	015787bb          	addw	a5,a5,s5
    8000313a:	40d7d79b          	sraiw	a5,a5,0xd
    8000313e:	01cb2583          	lw	a1,28(s6)
    80003142:	9dbd                	addw	a1,a1,a5
    80003144:	855e                	mv	a0,s7
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	cd2080e7          	jalr	-814(ra) # 80002e18 <bread>
    8000314e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003150:	004b2503          	lw	a0,4(s6)
    80003154:	000a849b          	sext.w	s1,s5
    80003158:	8662                	mv	a2,s8
    8000315a:	faa4fde3          	bgeu	s1,a0,80003114 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000315e:	41f6579b          	sraiw	a5,a2,0x1f
    80003162:	01d7d69b          	srliw	a3,a5,0x1d
    80003166:	00c6873b          	addw	a4,a3,a2
    8000316a:	00777793          	andi	a5,a4,7
    8000316e:	9f95                	subw	a5,a5,a3
    80003170:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003174:	4037571b          	sraiw	a4,a4,0x3
    80003178:	00e906b3          	add	a3,s2,a4
    8000317c:	0586c683          	lbu	a3,88(a3)
    80003180:	00d7f5b3          	and	a1,a5,a3
    80003184:	cd91                	beqz	a1,800031a0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003186:	2605                	addiw	a2,a2,1
    80003188:	2485                	addiw	s1,s1,1
    8000318a:	fd4618e3          	bne	a2,s4,8000315a <balloc+0x80>
    8000318e:	b759                	j	80003114 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003190:	00005517          	auipc	a0,0x5
    80003194:	3a050513          	addi	a0,a0,928 # 80008530 <syscalls+0x100>
    80003198:	ffffd097          	auipc	ra,0xffffd
    8000319c:	392080e7          	jalr	914(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031a0:	974a                	add	a4,a4,s2
    800031a2:	8fd5                	or	a5,a5,a3
    800031a4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031a8:	854a                	mv	a0,s2
    800031aa:	00001097          	auipc	ra,0x1
    800031ae:	0c0080e7          	jalr	192(ra) # 8000426a <log_write>
        brelse(bp);
    800031b2:	854a                	mv	a0,s2
    800031b4:	00000097          	auipc	ra,0x0
    800031b8:	d94080e7          	jalr	-620(ra) # 80002f48 <brelse>
  bp = bread(dev, bno);
    800031bc:	85a6                	mv	a1,s1
    800031be:	855e                	mv	a0,s7
    800031c0:	00000097          	auipc	ra,0x0
    800031c4:	c58080e7          	jalr	-936(ra) # 80002e18 <bread>
    800031c8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031ca:	40000613          	li	a2,1024
    800031ce:	4581                	li	a1,0
    800031d0:	05850513          	addi	a0,a0,88
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	aea080e7          	jalr	-1302(ra) # 80000cbe <memset>
  log_write(bp);
    800031dc:	854a                	mv	a0,s2
    800031de:	00001097          	auipc	ra,0x1
    800031e2:	08c080e7          	jalr	140(ra) # 8000426a <log_write>
  brelse(bp);
    800031e6:	854a                	mv	a0,s2
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	d60080e7          	jalr	-672(ra) # 80002f48 <brelse>
}
    800031f0:	8526                	mv	a0,s1
    800031f2:	60e6                	ld	ra,88(sp)
    800031f4:	6446                	ld	s0,80(sp)
    800031f6:	64a6                	ld	s1,72(sp)
    800031f8:	6906                	ld	s2,64(sp)
    800031fa:	79e2                	ld	s3,56(sp)
    800031fc:	7a42                	ld	s4,48(sp)
    800031fe:	7aa2                	ld	s5,40(sp)
    80003200:	7b02                	ld	s6,32(sp)
    80003202:	6be2                	ld	s7,24(sp)
    80003204:	6c42                	ld	s8,16(sp)
    80003206:	6ca2                	ld	s9,8(sp)
    80003208:	6125                	addi	sp,sp,96
    8000320a:	8082                	ret

000000008000320c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000320c:	7179                	addi	sp,sp,-48
    8000320e:	f406                	sd	ra,40(sp)
    80003210:	f022                	sd	s0,32(sp)
    80003212:	ec26                	sd	s1,24(sp)
    80003214:	e84a                	sd	s2,16(sp)
    80003216:	e44e                	sd	s3,8(sp)
    80003218:	e052                	sd	s4,0(sp)
    8000321a:	1800                	addi	s0,sp,48
    8000321c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000321e:	47ad                	li	a5,11
    80003220:	04b7fe63          	bgeu	a5,a1,8000327c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003224:	ff45849b          	addiw	s1,a1,-12
    80003228:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000322c:	0ff00793          	li	a5,255
    80003230:	0ae7e463          	bltu	a5,a4,800032d8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003234:	08052583          	lw	a1,128(a0)
    80003238:	c5b5                	beqz	a1,800032a4 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000323a:	00092503          	lw	a0,0(s2)
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	bda080e7          	jalr	-1062(ra) # 80002e18 <bread>
    80003246:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003248:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000324c:	02049713          	slli	a4,s1,0x20
    80003250:	01e75593          	srli	a1,a4,0x1e
    80003254:	00b784b3          	add	s1,a5,a1
    80003258:	0004a983          	lw	s3,0(s1)
    8000325c:	04098e63          	beqz	s3,800032b8 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003260:	8552                	mv	a0,s4
    80003262:	00000097          	auipc	ra,0x0
    80003266:	ce6080e7          	jalr	-794(ra) # 80002f48 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000326a:	854e                	mv	a0,s3
    8000326c:	70a2                	ld	ra,40(sp)
    8000326e:	7402                	ld	s0,32(sp)
    80003270:	64e2                	ld	s1,24(sp)
    80003272:	6942                	ld	s2,16(sp)
    80003274:	69a2                	ld	s3,8(sp)
    80003276:	6a02                	ld	s4,0(sp)
    80003278:	6145                	addi	sp,sp,48
    8000327a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000327c:	02059793          	slli	a5,a1,0x20
    80003280:	01e7d593          	srli	a1,a5,0x1e
    80003284:	00b504b3          	add	s1,a0,a1
    80003288:	0504a983          	lw	s3,80(s1)
    8000328c:	fc099fe3          	bnez	s3,8000326a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003290:	4108                	lw	a0,0(a0)
    80003292:	00000097          	auipc	ra,0x0
    80003296:	e48080e7          	jalr	-440(ra) # 800030da <balloc>
    8000329a:	0005099b          	sext.w	s3,a0
    8000329e:	0534a823          	sw	s3,80(s1)
    800032a2:	b7e1                	j	8000326a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032a4:	4108                	lw	a0,0(a0)
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	e34080e7          	jalr	-460(ra) # 800030da <balloc>
    800032ae:	0005059b          	sext.w	a1,a0
    800032b2:	08b92023          	sw	a1,128(s2)
    800032b6:	b751                	j	8000323a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032b8:	00092503          	lw	a0,0(s2)
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	e1e080e7          	jalr	-482(ra) # 800030da <balloc>
    800032c4:	0005099b          	sext.w	s3,a0
    800032c8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032cc:	8552                	mv	a0,s4
    800032ce:	00001097          	auipc	ra,0x1
    800032d2:	f9c080e7          	jalr	-100(ra) # 8000426a <log_write>
    800032d6:	b769                	j	80003260 <bmap+0x54>
  panic("bmap: out of range");
    800032d8:	00005517          	auipc	a0,0x5
    800032dc:	27050513          	addi	a0,a0,624 # 80008548 <syscalls+0x118>
    800032e0:	ffffd097          	auipc	ra,0xffffd
    800032e4:	24a080e7          	jalr	586(ra) # 8000052a <panic>

00000000800032e8 <iget>:
{
    800032e8:	7179                	addi	sp,sp,-48
    800032ea:	f406                	sd	ra,40(sp)
    800032ec:	f022                	sd	s0,32(sp)
    800032ee:	ec26                	sd	s1,24(sp)
    800032f0:	e84a                	sd	s2,16(sp)
    800032f2:	e44e                	sd	s3,8(sp)
    800032f4:	e052                	sd	s4,0(sp)
    800032f6:	1800                	addi	s0,sp,48
    800032f8:	89aa                	mv	s3,a0
    800032fa:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032fc:	0001c517          	auipc	a0,0x1c
    80003300:	4cc50513          	addi	a0,a0,1228 # 8001f7c8 <itable>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	8be080e7          	jalr	-1858(ra) # 80000bc2 <acquire>
  empty = 0;
    8000330c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000330e:	0001c497          	auipc	s1,0x1c
    80003312:	4d248493          	addi	s1,s1,1234 # 8001f7e0 <itable+0x18>
    80003316:	0001e697          	auipc	a3,0x1e
    8000331a:	f5a68693          	addi	a3,a3,-166 # 80021270 <log>
    8000331e:	a039                	j	8000332c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003320:	02090b63          	beqz	s2,80003356 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003324:	08848493          	addi	s1,s1,136
    80003328:	02d48a63          	beq	s1,a3,8000335c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000332c:	449c                	lw	a5,8(s1)
    8000332e:	fef059e3          	blez	a5,80003320 <iget+0x38>
    80003332:	4098                	lw	a4,0(s1)
    80003334:	ff3716e3          	bne	a4,s3,80003320 <iget+0x38>
    80003338:	40d8                	lw	a4,4(s1)
    8000333a:	ff4713e3          	bne	a4,s4,80003320 <iget+0x38>
      ip->ref++;
    8000333e:	2785                	addiw	a5,a5,1
    80003340:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003342:	0001c517          	auipc	a0,0x1c
    80003346:	48650513          	addi	a0,a0,1158 # 8001f7c8 <itable>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	92c080e7          	jalr	-1748(ra) # 80000c76 <release>
      return ip;
    80003352:	8926                	mv	s2,s1
    80003354:	a03d                	j	80003382 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003356:	f7f9                	bnez	a5,80003324 <iget+0x3c>
    80003358:	8926                	mv	s2,s1
    8000335a:	b7e9                	j	80003324 <iget+0x3c>
  if(empty == 0)
    8000335c:	02090c63          	beqz	s2,80003394 <iget+0xac>
  ip->dev = dev;
    80003360:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003364:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003368:	4785                	li	a5,1
    8000336a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000336e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003372:	0001c517          	auipc	a0,0x1c
    80003376:	45650513          	addi	a0,a0,1110 # 8001f7c8 <itable>
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	8fc080e7          	jalr	-1796(ra) # 80000c76 <release>
}
    80003382:	854a                	mv	a0,s2
    80003384:	70a2                	ld	ra,40(sp)
    80003386:	7402                	ld	s0,32(sp)
    80003388:	64e2                	ld	s1,24(sp)
    8000338a:	6942                	ld	s2,16(sp)
    8000338c:	69a2                	ld	s3,8(sp)
    8000338e:	6a02                	ld	s4,0(sp)
    80003390:	6145                	addi	sp,sp,48
    80003392:	8082                	ret
    panic("iget: no inodes");
    80003394:	00005517          	auipc	a0,0x5
    80003398:	1cc50513          	addi	a0,a0,460 # 80008560 <syscalls+0x130>
    8000339c:	ffffd097          	auipc	ra,0xffffd
    800033a0:	18e080e7          	jalr	398(ra) # 8000052a <panic>

00000000800033a4 <fsinit>:
fsinit(int dev) {
    800033a4:	7179                	addi	sp,sp,-48
    800033a6:	f406                	sd	ra,40(sp)
    800033a8:	f022                	sd	s0,32(sp)
    800033aa:	ec26                	sd	s1,24(sp)
    800033ac:	e84a                	sd	s2,16(sp)
    800033ae:	e44e                	sd	s3,8(sp)
    800033b0:	1800                	addi	s0,sp,48
    800033b2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033b4:	4585                	li	a1,1
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	a62080e7          	jalr	-1438(ra) # 80002e18 <bread>
    800033be:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033c0:	0001c997          	auipc	s3,0x1c
    800033c4:	3e898993          	addi	s3,s3,1000 # 8001f7a8 <sb>
    800033c8:	02000613          	li	a2,32
    800033cc:	05850593          	addi	a1,a0,88
    800033d0:	854e                	mv	a0,s3
    800033d2:	ffffe097          	auipc	ra,0xffffe
    800033d6:	948080e7          	jalr	-1720(ra) # 80000d1a <memmove>
  brelse(bp);
    800033da:	8526                	mv	a0,s1
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	b6c080e7          	jalr	-1172(ra) # 80002f48 <brelse>
  if(sb.magic != FSMAGIC)
    800033e4:	0009a703          	lw	a4,0(s3)
    800033e8:	102037b7          	lui	a5,0x10203
    800033ec:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033f0:	02f71263          	bne	a4,a5,80003414 <fsinit+0x70>
  initlog(dev, &sb);
    800033f4:	0001c597          	auipc	a1,0x1c
    800033f8:	3b458593          	addi	a1,a1,948 # 8001f7a8 <sb>
    800033fc:	854a                	mv	a0,s2
    800033fe:	00001097          	auipc	ra,0x1
    80003402:	bee080e7          	jalr	-1042(ra) # 80003fec <initlog>
}
    80003406:	70a2                	ld	ra,40(sp)
    80003408:	7402                	ld	s0,32(sp)
    8000340a:	64e2                	ld	s1,24(sp)
    8000340c:	6942                	ld	s2,16(sp)
    8000340e:	69a2                	ld	s3,8(sp)
    80003410:	6145                	addi	sp,sp,48
    80003412:	8082                	ret
    panic("invalid file system");
    80003414:	00005517          	auipc	a0,0x5
    80003418:	15c50513          	addi	a0,a0,348 # 80008570 <syscalls+0x140>
    8000341c:	ffffd097          	auipc	ra,0xffffd
    80003420:	10e080e7          	jalr	270(ra) # 8000052a <panic>

0000000080003424 <iinit>:
{
    80003424:	7179                	addi	sp,sp,-48
    80003426:	f406                	sd	ra,40(sp)
    80003428:	f022                	sd	s0,32(sp)
    8000342a:	ec26                	sd	s1,24(sp)
    8000342c:	e84a                	sd	s2,16(sp)
    8000342e:	e44e                	sd	s3,8(sp)
    80003430:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003432:	00005597          	auipc	a1,0x5
    80003436:	15658593          	addi	a1,a1,342 # 80008588 <syscalls+0x158>
    8000343a:	0001c517          	auipc	a0,0x1c
    8000343e:	38e50513          	addi	a0,a0,910 # 8001f7c8 <itable>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	6f0080e7          	jalr	1776(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000344a:	0001c497          	auipc	s1,0x1c
    8000344e:	3a648493          	addi	s1,s1,934 # 8001f7f0 <itable+0x28>
    80003452:	0001e997          	auipc	s3,0x1e
    80003456:	e2e98993          	addi	s3,s3,-466 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000345a:	00005917          	auipc	s2,0x5
    8000345e:	13690913          	addi	s2,s2,310 # 80008590 <syscalls+0x160>
    80003462:	85ca                	mv	a1,s2
    80003464:	8526                	mv	a0,s1
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	eea080e7          	jalr	-278(ra) # 80004350 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000346e:	08848493          	addi	s1,s1,136
    80003472:	ff3498e3          	bne	s1,s3,80003462 <iinit+0x3e>
}
    80003476:	70a2                	ld	ra,40(sp)
    80003478:	7402                	ld	s0,32(sp)
    8000347a:	64e2                	ld	s1,24(sp)
    8000347c:	6942                	ld	s2,16(sp)
    8000347e:	69a2                	ld	s3,8(sp)
    80003480:	6145                	addi	sp,sp,48
    80003482:	8082                	ret

0000000080003484 <ialloc>:
{
    80003484:	715d                	addi	sp,sp,-80
    80003486:	e486                	sd	ra,72(sp)
    80003488:	e0a2                	sd	s0,64(sp)
    8000348a:	fc26                	sd	s1,56(sp)
    8000348c:	f84a                	sd	s2,48(sp)
    8000348e:	f44e                	sd	s3,40(sp)
    80003490:	f052                	sd	s4,32(sp)
    80003492:	ec56                	sd	s5,24(sp)
    80003494:	e85a                	sd	s6,16(sp)
    80003496:	e45e                	sd	s7,8(sp)
    80003498:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000349a:	0001c717          	auipc	a4,0x1c
    8000349e:	31a72703          	lw	a4,794(a4) # 8001f7b4 <sb+0xc>
    800034a2:	4785                	li	a5,1
    800034a4:	04e7fa63          	bgeu	a5,a4,800034f8 <ialloc+0x74>
    800034a8:	8aaa                	mv	s5,a0
    800034aa:	8bae                	mv	s7,a1
    800034ac:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034ae:	0001ca17          	auipc	s4,0x1c
    800034b2:	2faa0a13          	addi	s4,s4,762 # 8001f7a8 <sb>
    800034b6:	00048b1b          	sext.w	s6,s1
    800034ba:	0044d793          	srli	a5,s1,0x4
    800034be:	018a2583          	lw	a1,24(s4)
    800034c2:	9dbd                	addw	a1,a1,a5
    800034c4:	8556                	mv	a0,s5
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	952080e7          	jalr	-1710(ra) # 80002e18 <bread>
    800034ce:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034d0:	05850993          	addi	s3,a0,88
    800034d4:	00f4f793          	andi	a5,s1,15
    800034d8:	079a                	slli	a5,a5,0x6
    800034da:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034dc:	00099783          	lh	a5,0(s3)
    800034e0:	c785                	beqz	a5,80003508 <ialloc+0x84>
    brelse(bp);
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	a66080e7          	jalr	-1434(ra) # 80002f48 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034ea:	0485                	addi	s1,s1,1
    800034ec:	00ca2703          	lw	a4,12(s4)
    800034f0:	0004879b          	sext.w	a5,s1
    800034f4:	fce7e1e3          	bltu	a5,a4,800034b6 <ialloc+0x32>
  panic("ialloc: no inodes");
    800034f8:	00005517          	auipc	a0,0x5
    800034fc:	0a050513          	addi	a0,a0,160 # 80008598 <syscalls+0x168>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	02a080e7          	jalr	42(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003508:	04000613          	li	a2,64
    8000350c:	4581                	li	a1,0
    8000350e:	854e                	mv	a0,s3
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	7ae080e7          	jalr	1966(ra) # 80000cbe <memset>
      dip->type = type;
    80003518:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000351c:	854a                	mv	a0,s2
    8000351e:	00001097          	auipc	ra,0x1
    80003522:	d4c080e7          	jalr	-692(ra) # 8000426a <log_write>
      brelse(bp);
    80003526:	854a                	mv	a0,s2
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	a20080e7          	jalr	-1504(ra) # 80002f48 <brelse>
      return iget(dev, inum);
    80003530:	85da                	mv	a1,s6
    80003532:	8556                	mv	a0,s5
    80003534:	00000097          	auipc	ra,0x0
    80003538:	db4080e7          	jalr	-588(ra) # 800032e8 <iget>
}
    8000353c:	60a6                	ld	ra,72(sp)
    8000353e:	6406                	ld	s0,64(sp)
    80003540:	74e2                	ld	s1,56(sp)
    80003542:	7942                	ld	s2,48(sp)
    80003544:	79a2                	ld	s3,40(sp)
    80003546:	7a02                	ld	s4,32(sp)
    80003548:	6ae2                	ld	s5,24(sp)
    8000354a:	6b42                	ld	s6,16(sp)
    8000354c:	6ba2                	ld	s7,8(sp)
    8000354e:	6161                	addi	sp,sp,80
    80003550:	8082                	ret

0000000080003552 <iupdate>:
{
    80003552:	1101                	addi	sp,sp,-32
    80003554:	ec06                	sd	ra,24(sp)
    80003556:	e822                	sd	s0,16(sp)
    80003558:	e426                	sd	s1,8(sp)
    8000355a:	e04a                	sd	s2,0(sp)
    8000355c:	1000                	addi	s0,sp,32
    8000355e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003560:	415c                	lw	a5,4(a0)
    80003562:	0047d79b          	srliw	a5,a5,0x4
    80003566:	0001c597          	auipc	a1,0x1c
    8000356a:	25a5a583          	lw	a1,602(a1) # 8001f7c0 <sb+0x18>
    8000356e:	9dbd                	addw	a1,a1,a5
    80003570:	4108                	lw	a0,0(a0)
    80003572:	00000097          	auipc	ra,0x0
    80003576:	8a6080e7          	jalr	-1882(ra) # 80002e18 <bread>
    8000357a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000357c:	05850793          	addi	a5,a0,88
    80003580:	40c8                	lw	a0,4(s1)
    80003582:	893d                	andi	a0,a0,15
    80003584:	051a                	slli	a0,a0,0x6
    80003586:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003588:	04449703          	lh	a4,68(s1)
    8000358c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003590:	04649703          	lh	a4,70(s1)
    80003594:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003598:	04849703          	lh	a4,72(s1)
    8000359c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035a0:	04a49703          	lh	a4,74(s1)
    800035a4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035a8:	44f8                	lw	a4,76(s1)
    800035aa:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035ac:	03400613          	li	a2,52
    800035b0:	05048593          	addi	a1,s1,80
    800035b4:	0531                	addi	a0,a0,12
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	764080e7          	jalr	1892(ra) # 80000d1a <memmove>
  log_write(bp);
    800035be:	854a                	mv	a0,s2
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	caa080e7          	jalr	-854(ra) # 8000426a <log_write>
  brelse(bp);
    800035c8:	854a                	mv	a0,s2
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	97e080e7          	jalr	-1666(ra) # 80002f48 <brelse>
}
    800035d2:	60e2                	ld	ra,24(sp)
    800035d4:	6442                	ld	s0,16(sp)
    800035d6:	64a2                	ld	s1,8(sp)
    800035d8:	6902                	ld	s2,0(sp)
    800035da:	6105                	addi	sp,sp,32
    800035dc:	8082                	ret

00000000800035de <idup>:
{
    800035de:	1101                	addi	sp,sp,-32
    800035e0:	ec06                	sd	ra,24(sp)
    800035e2:	e822                	sd	s0,16(sp)
    800035e4:	e426                	sd	s1,8(sp)
    800035e6:	1000                	addi	s0,sp,32
    800035e8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035ea:	0001c517          	auipc	a0,0x1c
    800035ee:	1de50513          	addi	a0,a0,478 # 8001f7c8 <itable>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	5d0080e7          	jalr	1488(ra) # 80000bc2 <acquire>
  ip->ref++;
    800035fa:	449c                	lw	a5,8(s1)
    800035fc:	2785                	addiw	a5,a5,1
    800035fe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003600:	0001c517          	auipc	a0,0x1c
    80003604:	1c850513          	addi	a0,a0,456 # 8001f7c8 <itable>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	66e080e7          	jalr	1646(ra) # 80000c76 <release>
}
    80003610:	8526                	mv	a0,s1
    80003612:	60e2                	ld	ra,24(sp)
    80003614:	6442                	ld	s0,16(sp)
    80003616:	64a2                	ld	s1,8(sp)
    80003618:	6105                	addi	sp,sp,32
    8000361a:	8082                	ret

000000008000361c <ilock>:
{
    8000361c:	1101                	addi	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	e426                	sd	s1,8(sp)
    80003624:	e04a                	sd	s2,0(sp)
    80003626:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003628:	c115                	beqz	a0,8000364c <ilock+0x30>
    8000362a:	84aa                	mv	s1,a0
    8000362c:	451c                	lw	a5,8(a0)
    8000362e:	00f05f63          	blez	a5,8000364c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003632:	0541                	addi	a0,a0,16
    80003634:	00001097          	auipc	ra,0x1
    80003638:	d56080e7          	jalr	-682(ra) # 8000438a <acquiresleep>
  if(ip->valid == 0){
    8000363c:	40bc                	lw	a5,64(s1)
    8000363e:	cf99                	beqz	a5,8000365c <ilock+0x40>
}
    80003640:	60e2                	ld	ra,24(sp)
    80003642:	6442                	ld	s0,16(sp)
    80003644:	64a2                	ld	s1,8(sp)
    80003646:	6902                	ld	s2,0(sp)
    80003648:	6105                	addi	sp,sp,32
    8000364a:	8082                	ret
    panic("ilock");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	f6450513          	addi	a0,a0,-156 # 800085b0 <syscalls+0x180>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	ed6080e7          	jalr	-298(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000365c:	40dc                	lw	a5,4(s1)
    8000365e:	0047d79b          	srliw	a5,a5,0x4
    80003662:	0001c597          	auipc	a1,0x1c
    80003666:	15e5a583          	lw	a1,350(a1) # 8001f7c0 <sb+0x18>
    8000366a:	9dbd                	addw	a1,a1,a5
    8000366c:	4088                	lw	a0,0(s1)
    8000366e:	fffff097          	auipc	ra,0xfffff
    80003672:	7aa080e7          	jalr	1962(ra) # 80002e18 <bread>
    80003676:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003678:	05850593          	addi	a1,a0,88
    8000367c:	40dc                	lw	a5,4(s1)
    8000367e:	8bbd                	andi	a5,a5,15
    80003680:	079a                	slli	a5,a5,0x6
    80003682:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003684:	00059783          	lh	a5,0(a1)
    80003688:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000368c:	00259783          	lh	a5,2(a1)
    80003690:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003694:	00459783          	lh	a5,4(a1)
    80003698:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000369c:	00659783          	lh	a5,6(a1)
    800036a0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036a4:	459c                	lw	a5,8(a1)
    800036a6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036a8:	03400613          	li	a2,52
    800036ac:	05b1                	addi	a1,a1,12
    800036ae:	05048513          	addi	a0,s1,80
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	668080e7          	jalr	1640(ra) # 80000d1a <memmove>
    brelse(bp);
    800036ba:	854a                	mv	a0,s2
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	88c080e7          	jalr	-1908(ra) # 80002f48 <brelse>
    ip->valid = 1;
    800036c4:	4785                	li	a5,1
    800036c6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036c8:	04449783          	lh	a5,68(s1)
    800036cc:	fbb5                	bnez	a5,80003640 <ilock+0x24>
      panic("ilock: no type");
    800036ce:	00005517          	auipc	a0,0x5
    800036d2:	eea50513          	addi	a0,a0,-278 # 800085b8 <syscalls+0x188>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	e54080e7          	jalr	-428(ra) # 8000052a <panic>

00000000800036de <iunlock>:
{
    800036de:	1101                	addi	sp,sp,-32
    800036e0:	ec06                	sd	ra,24(sp)
    800036e2:	e822                	sd	s0,16(sp)
    800036e4:	e426                	sd	s1,8(sp)
    800036e6:	e04a                	sd	s2,0(sp)
    800036e8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036ea:	c905                	beqz	a0,8000371a <iunlock+0x3c>
    800036ec:	84aa                	mv	s1,a0
    800036ee:	01050913          	addi	s2,a0,16
    800036f2:	854a                	mv	a0,s2
    800036f4:	00001097          	auipc	ra,0x1
    800036f8:	d30080e7          	jalr	-720(ra) # 80004424 <holdingsleep>
    800036fc:	cd19                	beqz	a0,8000371a <iunlock+0x3c>
    800036fe:	449c                	lw	a5,8(s1)
    80003700:	00f05d63          	blez	a5,8000371a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003704:	854a                	mv	a0,s2
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	cda080e7          	jalr	-806(ra) # 800043e0 <releasesleep>
}
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6902                	ld	s2,0(sp)
    80003716:	6105                	addi	sp,sp,32
    80003718:	8082                	ret
    panic("iunlock");
    8000371a:	00005517          	auipc	a0,0x5
    8000371e:	eae50513          	addi	a0,a0,-338 # 800085c8 <syscalls+0x198>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	e08080e7          	jalr	-504(ra) # 8000052a <panic>

000000008000372a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000372a:	7179                	addi	sp,sp,-48
    8000372c:	f406                	sd	ra,40(sp)
    8000372e:	f022                	sd	s0,32(sp)
    80003730:	ec26                	sd	s1,24(sp)
    80003732:	e84a                	sd	s2,16(sp)
    80003734:	e44e                	sd	s3,8(sp)
    80003736:	e052                	sd	s4,0(sp)
    80003738:	1800                	addi	s0,sp,48
    8000373a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000373c:	05050493          	addi	s1,a0,80
    80003740:	08050913          	addi	s2,a0,128
    80003744:	a021                	j	8000374c <itrunc+0x22>
    80003746:	0491                	addi	s1,s1,4
    80003748:	01248d63          	beq	s1,s2,80003762 <itrunc+0x38>
    if(ip->addrs[i]){
    8000374c:	408c                	lw	a1,0(s1)
    8000374e:	dde5                	beqz	a1,80003746 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003750:	0009a503          	lw	a0,0(s3)
    80003754:	00000097          	auipc	ra,0x0
    80003758:	90a080e7          	jalr	-1782(ra) # 8000305e <bfree>
      ip->addrs[i] = 0;
    8000375c:	0004a023          	sw	zero,0(s1)
    80003760:	b7dd                	j	80003746 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003762:	0809a583          	lw	a1,128(s3)
    80003766:	e185                	bnez	a1,80003786 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003768:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000376c:	854e                	mv	a0,s3
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	de4080e7          	jalr	-540(ra) # 80003552 <iupdate>
}
    80003776:	70a2                	ld	ra,40(sp)
    80003778:	7402                	ld	s0,32(sp)
    8000377a:	64e2                	ld	s1,24(sp)
    8000377c:	6942                	ld	s2,16(sp)
    8000377e:	69a2                	ld	s3,8(sp)
    80003780:	6a02                	ld	s4,0(sp)
    80003782:	6145                	addi	sp,sp,48
    80003784:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003786:	0009a503          	lw	a0,0(s3)
    8000378a:	fffff097          	auipc	ra,0xfffff
    8000378e:	68e080e7          	jalr	1678(ra) # 80002e18 <bread>
    80003792:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003794:	05850493          	addi	s1,a0,88
    80003798:	45850913          	addi	s2,a0,1112
    8000379c:	a021                	j	800037a4 <itrunc+0x7a>
    8000379e:	0491                	addi	s1,s1,4
    800037a0:	01248b63          	beq	s1,s2,800037b6 <itrunc+0x8c>
      if(a[j])
    800037a4:	408c                	lw	a1,0(s1)
    800037a6:	dde5                	beqz	a1,8000379e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037a8:	0009a503          	lw	a0,0(s3)
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	8b2080e7          	jalr	-1870(ra) # 8000305e <bfree>
    800037b4:	b7ed                	j	8000379e <itrunc+0x74>
    brelse(bp);
    800037b6:	8552                	mv	a0,s4
    800037b8:	fffff097          	auipc	ra,0xfffff
    800037bc:	790080e7          	jalr	1936(ra) # 80002f48 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037c0:	0809a583          	lw	a1,128(s3)
    800037c4:	0009a503          	lw	a0,0(s3)
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	896080e7          	jalr	-1898(ra) # 8000305e <bfree>
    ip->addrs[NDIRECT] = 0;
    800037d0:	0809a023          	sw	zero,128(s3)
    800037d4:	bf51                	j	80003768 <itrunc+0x3e>

00000000800037d6 <iput>:
{
    800037d6:	1101                	addi	sp,sp,-32
    800037d8:	ec06                	sd	ra,24(sp)
    800037da:	e822                	sd	s0,16(sp)
    800037dc:	e426                	sd	s1,8(sp)
    800037de:	e04a                	sd	s2,0(sp)
    800037e0:	1000                	addi	s0,sp,32
    800037e2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037e4:	0001c517          	auipc	a0,0x1c
    800037e8:	fe450513          	addi	a0,a0,-28 # 8001f7c8 <itable>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	3d6080e7          	jalr	982(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037f4:	4498                	lw	a4,8(s1)
    800037f6:	4785                	li	a5,1
    800037f8:	02f70363          	beq	a4,a5,8000381e <iput+0x48>
  ip->ref--;
    800037fc:	449c                	lw	a5,8(s1)
    800037fe:	37fd                	addiw	a5,a5,-1
    80003800:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003802:	0001c517          	auipc	a0,0x1c
    80003806:	fc650513          	addi	a0,a0,-58 # 8001f7c8 <itable>
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	46c080e7          	jalr	1132(ra) # 80000c76 <release>
}
    80003812:	60e2                	ld	ra,24(sp)
    80003814:	6442                	ld	s0,16(sp)
    80003816:	64a2                	ld	s1,8(sp)
    80003818:	6902                	ld	s2,0(sp)
    8000381a:	6105                	addi	sp,sp,32
    8000381c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000381e:	40bc                	lw	a5,64(s1)
    80003820:	dff1                	beqz	a5,800037fc <iput+0x26>
    80003822:	04a49783          	lh	a5,74(s1)
    80003826:	fbf9                	bnez	a5,800037fc <iput+0x26>
    acquiresleep(&ip->lock);
    80003828:	01048913          	addi	s2,s1,16
    8000382c:	854a                	mv	a0,s2
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	b5c080e7          	jalr	-1188(ra) # 8000438a <acquiresleep>
    release(&itable.lock);
    80003836:	0001c517          	auipc	a0,0x1c
    8000383a:	f9250513          	addi	a0,a0,-110 # 8001f7c8 <itable>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	438080e7          	jalr	1080(ra) # 80000c76 <release>
    itrunc(ip);
    80003846:	8526                	mv	a0,s1
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	ee2080e7          	jalr	-286(ra) # 8000372a <itrunc>
    ip->type = 0;
    80003850:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003854:	8526                	mv	a0,s1
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	cfc080e7          	jalr	-772(ra) # 80003552 <iupdate>
    ip->valid = 0;
    8000385e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003862:	854a                	mv	a0,s2
    80003864:	00001097          	auipc	ra,0x1
    80003868:	b7c080e7          	jalr	-1156(ra) # 800043e0 <releasesleep>
    acquire(&itable.lock);
    8000386c:	0001c517          	auipc	a0,0x1c
    80003870:	f5c50513          	addi	a0,a0,-164 # 8001f7c8 <itable>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	34e080e7          	jalr	846(ra) # 80000bc2 <acquire>
    8000387c:	b741                	j	800037fc <iput+0x26>

000000008000387e <iunlockput>:
{
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	1000                	addi	s0,sp,32
    80003888:	84aa                	mv	s1,a0
  iunlock(ip);
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	e54080e7          	jalr	-428(ra) # 800036de <iunlock>
  iput(ip);
    80003892:	8526                	mv	a0,s1
    80003894:	00000097          	auipc	ra,0x0
    80003898:	f42080e7          	jalr	-190(ra) # 800037d6 <iput>
}
    8000389c:	60e2                	ld	ra,24(sp)
    8000389e:	6442                	ld	s0,16(sp)
    800038a0:	64a2                	ld	s1,8(sp)
    800038a2:	6105                	addi	sp,sp,32
    800038a4:	8082                	ret

00000000800038a6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038a6:	1141                	addi	sp,sp,-16
    800038a8:	e422                	sd	s0,8(sp)
    800038aa:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038ac:	411c                	lw	a5,0(a0)
    800038ae:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038b0:	415c                	lw	a5,4(a0)
    800038b2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038b4:	04451783          	lh	a5,68(a0)
    800038b8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038bc:	04a51783          	lh	a5,74(a0)
    800038c0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038c4:	04c56783          	lwu	a5,76(a0)
    800038c8:	e99c                	sd	a5,16(a1)
}
    800038ca:	6422                	ld	s0,8(sp)
    800038cc:	0141                	addi	sp,sp,16
    800038ce:	8082                	ret

00000000800038d0 <readi>:
// Caller must hold ip->lock.
// If user_dst==1, then dst is a user virtual address;
// otherwise, dst is a kernel address.
int
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
    800038d0:	7159                	addi	sp,sp,-112
    800038d2:	f486                	sd	ra,104(sp)
    800038d4:	f0a2                	sd	s0,96(sp)
    800038d6:	eca6                	sd	s1,88(sp)
    800038d8:	e8ca                	sd	s2,80(sp)
    800038da:	e4ce                	sd	s3,72(sp)
    800038dc:	e0d2                	sd	s4,64(sp)
    800038de:	fc56                	sd	s5,56(sp)
    800038e0:	f85a                	sd	s6,48(sp)
    800038e2:	f45e                	sd	s7,40(sp)
    800038e4:	f062                	sd	s8,32(sp)
    800038e6:	ec66                	sd	s9,24(sp)
    800038e8:	e86a                	sd	s10,16(sp)
    800038ea:	e46e                	sd	s11,8(sp)
    800038ec:	1880                	addi	s0,sp,112
    800038ee:	8b2a                	mv	s6,a0
    800038f0:	8c2e                	mv	s8,a1
    800038f2:	8ab2                	mv	s5,a2
    800038f4:	84b6                	mv	s1,a3
    800038f6:	8bba                	mv	s7,a4
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEVICE){
    800038f8:	04451703          	lh	a4,68(a0)
    800038fc:	478d                	li	a5,3
    800038fe:	02f70563          	beq	a4,a5,80003928 <readi+0x58>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
      return -1;
    return devsw[ip->major].read(ip, user_dst, dst, off, n);
  }

  if(off > ip->size || off + n < off)
    80003902:	457c                	lw	a5,76(a0)
    return 0;
    80003904:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003906:	04d7e463          	bltu	a5,a3,8000394e <readi+0x7e>
    8000390a:	0176873b          	addw	a4,a3,s7
    8000390e:	04d76063          	bltu	a4,a3,8000394e <readi+0x7e>
  if(off + n > ip->size)
    80003912:	00e7f463          	bgeu	a5,a4,8000391a <readi+0x4a>
    n = ip->size - off;
    80003916:	40d78bbb          	subw	s7,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000391a:	0c0b8d63          	beqz	s7,800039f4 <readi+0x124>
    8000391e:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003920:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003924:	5cfd                	li	s9,-1
    80003926:	a8bd                	j	800039a4 <readi+0xd4>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
    80003928:	04651783          	lh	a5,70(a0)
    8000392c:	03079693          	slli	a3,a5,0x30
    80003930:	92c1                	srli	a3,a3,0x30
    80003932:	4725                	li	a4,9
    80003934:	0cd76263          	bltu	a4,a3,800039f8 <readi+0x128>
    80003938:	0796                	slli	a5,a5,0x5
    8000393a:	0001e717          	auipc	a4,0x1e
    8000393e:	9de70713          	addi	a4,a4,-1570 # 80021318 <devsw>
    80003942:	97ba                	add	a5,a5,a4
    80003944:	6b9c                	ld	a5,16(a5)
    80003946:	cbdd                	beqz	a5,800039fc <readi+0x12c>
    return devsw[ip->major].read(ip, user_dst, dst, off, n);
    80003948:	875e                	mv	a4,s7
    8000394a:	86a6                	mv	a3,s1
    8000394c:	9782                	jalr	a5
      break;
    }
    brelse(bp);
  }
  return tot;
}
    8000394e:	70a6                	ld	ra,104(sp)
    80003950:	7406                	ld	s0,96(sp)
    80003952:	64e6                	ld	s1,88(sp)
    80003954:	6946                	ld	s2,80(sp)
    80003956:	69a6                	ld	s3,72(sp)
    80003958:	6a06                	ld	s4,64(sp)
    8000395a:	7ae2                	ld	s5,56(sp)
    8000395c:	7b42                	ld	s6,48(sp)
    8000395e:	7ba2                	ld	s7,40(sp)
    80003960:	7c02                	ld	s8,32(sp)
    80003962:	6ce2                	ld	s9,24(sp)
    80003964:	6d42                	ld	s10,16(sp)
    80003966:	6da2                	ld	s11,8(sp)
    80003968:	6165                	addi	sp,sp,112
    8000396a:	8082                	ret
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000396c:	020a1d93          	slli	s11,s4,0x20
    80003970:	020ddd93          	srli	s11,s11,0x20
    80003974:	05898793          	addi	a5,s3,88
    80003978:	86ee                	mv	a3,s11
    8000397a:	963e                	add	a2,a2,a5
    8000397c:	85d6                	mv	a1,s5
    8000397e:	8562                	mv	a0,s8
    80003980:	fffff097          	auipc	ra,0xfffff
    80003984:	a6a080e7          	jalr	-1430(ra) # 800023ea <either_copyout>
    80003988:	05950d63          	beq	a0,s9,800039e2 <readi+0x112>
    brelse(bp);
    8000398c:	854e                	mv	a0,s3
    8000398e:	fffff097          	auipc	ra,0xfffff
    80003992:	5ba080e7          	jalr	1466(ra) # 80002f48 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003996:	012a093b          	addw	s2,s4,s2
    8000399a:	009a04bb          	addw	s1,s4,s1
    8000399e:	9aee                	add	s5,s5,s11
    800039a0:	05797763          	bgeu	s2,s7,800039ee <readi+0x11e>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039a4:	000b2983          	lw	s3,0(s6)
    800039a8:	00a4d59b          	srliw	a1,s1,0xa
    800039ac:	855a                	mv	a0,s6
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	85e080e7          	jalr	-1954(ra) # 8000320c <bmap>
    800039b6:	0005059b          	sext.w	a1,a0
    800039ba:	854e                	mv	a0,s3
    800039bc:	fffff097          	auipc	ra,0xfffff
    800039c0:	45c080e7          	jalr	1116(ra) # 80002e18 <bread>
    800039c4:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039c6:	3ff4f613          	andi	a2,s1,1023
    800039ca:	40cd07bb          	subw	a5,s10,a2
    800039ce:	412b873b          	subw	a4,s7,s2
    800039d2:	8a3e                	mv	s4,a5
    800039d4:	2781                	sext.w	a5,a5
    800039d6:	0007069b          	sext.w	a3,a4
    800039da:	f8f6f9e3          	bgeu	a3,a5,8000396c <readi+0x9c>
    800039de:	8a3a                	mv	s4,a4
    800039e0:	b771                	j	8000396c <readi+0x9c>
      brelse(bp);
    800039e2:	854e                	mv	a0,s3
    800039e4:	fffff097          	auipc	ra,0xfffff
    800039e8:	564080e7          	jalr	1380(ra) # 80002f48 <brelse>
      tot = -1;
    800039ec:	597d                	li	s2,-1
  return tot;
    800039ee:	0009051b          	sext.w	a0,s2
    800039f2:	bfb1                	j	8000394e <readi+0x7e>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f4:	895e                	mv	s2,s7
    800039f6:	bfe5                	j	800039ee <readi+0x11e>
      return -1;
    800039f8:	557d                	li	a0,-1
    800039fa:	bf91                	j	8000394e <readi+0x7e>
    800039fc:	557d                	li	a0,-1
    800039fe:	bf81                	j	8000394e <readi+0x7e>

0000000080003a00 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a00:	457c                	lw	a5,76(a0)
    80003a02:	10d7e863          	bltu	a5,a3,80003b12 <writei+0x112>
{
    80003a06:	7159                	addi	sp,sp,-112
    80003a08:	f486                	sd	ra,104(sp)
    80003a0a:	f0a2                	sd	s0,96(sp)
    80003a0c:	eca6                	sd	s1,88(sp)
    80003a0e:	e8ca                	sd	s2,80(sp)
    80003a10:	e4ce                	sd	s3,72(sp)
    80003a12:	e0d2                	sd	s4,64(sp)
    80003a14:	fc56                	sd	s5,56(sp)
    80003a16:	f85a                	sd	s6,48(sp)
    80003a18:	f45e                	sd	s7,40(sp)
    80003a1a:	f062                	sd	s8,32(sp)
    80003a1c:	ec66                	sd	s9,24(sp)
    80003a1e:	e86a                	sd	s10,16(sp)
    80003a20:	e46e                	sd	s11,8(sp)
    80003a22:	1880                	addi	s0,sp,112
    80003a24:	8b2a                	mv	s6,a0
    80003a26:	8c2e                	mv	s8,a1
    80003a28:	8ab2                	mv	s5,a2
    80003a2a:	8936                	mv	s2,a3
    80003a2c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a2e:	00e687bb          	addw	a5,a3,a4
    80003a32:	0ed7e263          	bltu	a5,a3,80003b16 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a36:	00043737          	lui	a4,0x43
    80003a3a:	0ef76063          	bltu	a4,a5,80003b1a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a3e:	0c0b8863          	beqz	s7,80003b0e <writei+0x10e>
    80003a42:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a44:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a48:	5cfd                	li	s9,-1
    80003a4a:	a091                	j	80003a8e <writei+0x8e>
    80003a4c:	02099d93          	slli	s11,s3,0x20
    80003a50:	020ddd93          	srli	s11,s11,0x20
    80003a54:	05848793          	addi	a5,s1,88
    80003a58:	86ee                	mv	a3,s11
    80003a5a:	8656                	mv	a2,s5
    80003a5c:	85e2                	mv	a1,s8
    80003a5e:	953e                	add	a0,a0,a5
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	9e0080e7          	jalr	-1568(ra) # 80002440 <either_copyin>
    80003a68:	07950263          	beq	a0,s9,80003acc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a6c:	8526                	mv	a0,s1
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	7fc080e7          	jalr	2044(ra) # 8000426a <log_write>
    brelse(bp);
    80003a76:	8526                	mv	a0,s1
    80003a78:	fffff097          	auipc	ra,0xfffff
    80003a7c:	4d0080e7          	jalr	1232(ra) # 80002f48 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a80:	01498a3b          	addw	s4,s3,s4
    80003a84:	0129893b          	addw	s2,s3,s2
    80003a88:	9aee                	add	s5,s5,s11
    80003a8a:	057a7663          	bgeu	s4,s7,80003ad6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a8e:	000b2483          	lw	s1,0(s6)
    80003a92:	00a9559b          	srliw	a1,s2,0xa
    80003a96:	855a                	mv	a0,s6
    80003a98:	fffff097          	auipc	ra,0xfffff
    80003a9c:	774080e7          	jalr	1908(ra) # 8000320c <bmap>
    80003aa0:	0005059b          	sext.w	a1,a0
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	372080e7          	jalr	882(ra) # 80002e18 <bread>
    80003aae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab0:	3ff97513          	andi	a0,s2,1023
    80003ab4:	40ad07bb          	subw	a5,s10,a0
    80003ab8:	414b873b          	subw	a4,s7,s4
    80003abc:	89be                	mv	s3,a5
    80003abe:	2781                	sext.w	a5,a5
    80003ac0:	0007069b          	sext.w	a3,a4
    80003ac4:	f8f6f4e3          	bgeu	a3,a5,80003a4c <writei+0x4c>
    80003ac8:	89ba                	mv	s3,a4
    80003aca:	b749                	j	80003a4c <writei+0x4c>
      brelse(bp);
    80003acc:	8526                	mv	a0,s1
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	47a080e7          	jalr	1146(ra) # 80002f48 <brelse>
  }

  if(off > ip->size)
    80003ad6:	04cb2783          	lw	a5,76(s6)
    80003ada:	0127f463          	bgeu	a5,s2,80003ae2 <writei+0xe2>
    ip->size = off;
    80003ade:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ae2:	855a                	mv	a0,s6
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	a6e080e7          	jalr	-1426(ra) # 80003552 <iupdate>

  return tot;
    80003aec:	000a051b          	sext.w	a0,s4
}
    80003af0:	70a6                	ld	ra,104(sp)
    80003af2:	7406                	ld	s0,96(sp)
    80003af4:	64e6                	ld	s1,88(sp)
    80003af6:	6946                	ld	s2,80(sp)
    80003af8:	69a6                	ld	s3,72(sp)
    80003afa:	6a06                	ld	s4,64(sp)
    80003afc:	7ae2                	ld	s5,56(sp)
    80003afe:	7b42                	ld	s6,48(sp)
    80003b00:	7ba2                	ld	s7,40(sp)
    80003b02:	7c02                	ld	s8,32(sp)
    80003b04:	6ce2                	ld	s9,24(sp)
    80003b06:	6d42                	ld	s10,16(sp)
    80003b08:	6da2                	ld	s11,8(sp)
    80003b0a:	6165                	addi	sp,sp,112
    80003b0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b0e:	8a5e                	mv	s4,s7
    80003b10:	bfc9                	j	80003ae2 <writei+0xe2>
    return -1;
    80003b12:	557d                	li	a0,-1
}
    80003b14:	8082                	ret
    return -1;
    80003b16:	557d                	li	a0,-1
    80003b18:	bfe1                	j	80003af0 <writei+0xf0>
    return -1;
    80003b1a:	557d                	li	a0,-1
    80003b1c:	bfd1                	j	80003af0 <writei+0xf0>

0000000080003b1e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b1e:	1141                	addi	sp,sp,-16
    80003b20:	e406                	sd	ra,8(sp)
    80003b22:	e022                	sd	s0,0(sp)
    80003b24:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b26:	4639                	li	a2,14
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	26e080e7          	jalr	622(ra) # 80000d96 <strncmp>
}
    80003b30:	60a2                	ld	ra,8(sp)
    80003b32:	6402                	ld	s0,0(sp)
    80003b34:	0141                	addi	sp,sp,16
    80003b36:	8082                	ret

0000000080003b38 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b38:	715d                	addi	sp,sp,-80
    80003b3a:	e486                	sd	ra,72(sp)
    80003b3c:	e0a2                	sd	s0,64(sp)
    80003b3e:	fc26                	sd	s1,56(sp)
    80003b40:	f84a                	sd	s2,48(sp)
    80003b42:	f44e                	sd	s3,40(sp)
    80003b44:	f052                	sd	s4,32(sp)
    80003b46:	ec56                	sd	s5,24(sp)
    80003b48:	0880                	addi	s0,sp,80
    80003b4a:	892a                	mv	s2,a0
    80003b4c:	8a2e                	mv	s4,a1
    80003b4e:	8ab2                	mv	s5,a2
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
    80003b50:	04451783          	lh	a5,68(a0)
    80003b54:	0007869b          	sext.w	a3,a5
    80003b58:	4705                	li	a4,1
    80003b5a:	02e68263          	beq	a3,a4,80003b7e <dirlookup+0x46>
    80003b5e:	470d                	li	a4,3
    80003b60:	02e69263          	bne	a3,a4,80003b84 <dirlookup+0x4c>
    80003b64:	04651783          	lh	a5,70(a0)
    80003b68:	00579713          	slli	a4,a5,0x5
    80003b6c:	0001d797          	auipc	a5,0x1d
    80003b70:	7ac78793          	addi	a5,a5,1964 # 80021318 <devsw>
    80003b74:	97ba                	add	a5,a5,a4
    80003b76:	639c                	ld	a5,0(a5)
    80003b78:	c791                	beqz	a5,80003b84 <dirlookup+0x4c>
    80003b7a:	9782                	jalr	a5
    80003b7c:	c501                	beqz	a0,80003b84 <dirlookup+0x4c>
{
    80003b7e:	4481                	li	s1,0
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size || dp->type == T_DEVICE; off += sizeof(de)){
    80003b80:	498d                	li	s3,3
    80003b82:	a091                	j	80003bc6 <dirlookup+0x8e>
    panic("dirlookup not DIR");
    80003b84:	00005517          	auipc	a0,0x5
    80003b88:	a4c50513          	addi	a0,a0,-1460 # 800085d0 <syscalls+0x1a0>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	99e080e7          	jalr	-1634(ra) # 8000052a <panic>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de)){
      if (dp->type == T_DEVICE)
    80003b94:	04491703          	lh	a4,68(s2)
    80003b98:	478d                	li	a5,3
        return 0;
    80003b9a:	4481                	li	s1,0
      if (dp->type == T_DEVICE)
    80003b9c:	00f71c63          	bne	a4,a5,80003bb4 <dirlookup+0x7c>
      return ip;
    }
  }

  return 0;
}
    80003ba0:	8526                	mv	a0,s1
    80003ba2:	60a6                	ld	ra,72(sp)
    80003ba4:	6406                	ld	s0,64(sp)
    80003ba6:	74e2                	ld	s1,56(sp)
    80003ba8:	7942                	ld	s2,48(sp)
    80003baa:	79a2                	ld	s3,40(sp)
    80003bac:	7a02                	ld	s4,32(sp)
    80003bae:	6ae2                	ld	s5,24(sp)
    80003bb0:	6161                	addi	sp,sp,80
    80003bb2:	8082                	ret
      panic("dirlookup read");
    80003bb4:	00005517          	auipc	a0,0x5
    80003bb8:	a3450513          	addi	a0,a0,-1484 # 800085e8 <syscalls+0x1b8>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	96e080e7          	jalr	-1682(ra) # 8000052a <panic>
  for(off = 0; off < dp->size || dp->type == T_DEVICE; off += sizeof(de)){
    80003bc4:	24c1                	addiw	s1,s1,16
    80003bc6:	04c92783          	lw	a5,76(s2)
    80003bca:	00f4e663          	bltu	s1,a5,80003bd6 <dirlookup+0x9e>
    80003bce:	04491783          	lh	a5,68(s2)
    80003bd2:	07379d63          	bne	a5,s3,80003c4c <dirlookup+0x114>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de)){
    80003bd6:	4741                	li	a4,16
    80003bd8:	86a6                	mv	a3,s1
    80003bda:	fb040613          	addi	a2,s0,-80
    80003bde:	4581                	li	a1,0
    80003be0:	854a                	mv	a0,s2
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	cee080e7          	jalr	-786(ra) # 800038d0 <readi>
    80003bea:	47c1                	li	a5,16
    80003bec:	faf514e3          	bne	a0,a5,80003b94 <dirlookup+0x5c>
    if(de.inum == 0)
    80003bf0:	fb045783          	lhu	a5,-80(s0)
    80003bf4:	dbe1                	beqz	a5,80003bc4 <dirlookup+0x8c>
    if(namecmp(name, de.name) == 0){
    80003bf6:	fb240593          	addi	a1,s0,-78
    80003bfa:	8552                	mv	a0,s4
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	f22080e7          	jalr	-222(ra) # 80003b1e <namecmp>
    80003c04:	f161                	bnez	a0,80003bc4 <dirlookup+0x8c>
      if(poff)
    80003c06:	000a8463          	beqz	s5,80003c0e <dirlookup+0xd6>
        *poff = off;
    80003c0a:	009aa023          	sw	s1,0(s5)
      struct inode *ip = iget(dp->dev, inum);
    80003c0e:	fb045583          	lhu	a1,-80(s0)
    80003c12:	00092503          	lw	a0,0(s2)
    80003c16:	fffff097          	auipc	ra,0xfffff
    80003c1a:	6d2080e7          	jalr	1746(ra) # 800032e8 <iget>
    80003c1e:	84aa                	mv	s1,a0
      if (ip->valid == 0 && dp->type == T_DEVICE && devsw[dp->major].inode_read) {
    80003c20:	413c                	lw	a5,64(a0)
    80003c22:	ffbd                	bnez	a5,80003ba0 <dirlookup+0x68>
    80003c24:	04491703          	lh	a4,68(s2)
    80003c28:	478d                	li	a5,3
    80003c2a:	f6f71be3          	bne	a4,a5,80003ba0 <dirlookup+0x68>
    80003c2e:	04691783          	lh	a5,70(s2)
    80003c32:	00579713          	slli	a4,a5,0x5
    80003c36:	0001d797          	auipc	a5,0x1d
    80003c3a:	6e278793          	addi	a5,a5,1762 # 80021318 <devsw>
    80003c3e:	97ba                	add	a5,a5,a4
    80003c40:	679c                	ld	a5,8(a5)
    80003c42:	dfb9                	beqz	a5,80003ba0 <dirlookup+0x68>
        devsw[dp->major].inode_read(dp, ip);
    80003c44:	85aa                	mv	a1,a0
    80003c46:	854a                	mv	a0,s2
    80003c48:	9782                	jalr	a5
    80003c4a:	bf99                	j	80003ba0 <dirlookup+0x68>
  return 0;
    80003c4c:	4481                	li	s1,0
    80003c4e:	bf89                	j	80003ba0 <dirlookup+0x68>

0000000080003c50 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c50:	711d                	addi	sp,sp,-96
    80003c52:	ec86                	sd	ra,88(sp)
    80003c54:	e8a2                	sd	s0,80(sp)
    80003c56:	e4a6                	sd	s1,72(sp)
    80003c58:	e0ca                	sd	s2,64(sp)
    80003c5a:	fc4e                	sd	s3,56(sp)
    80003c5c:	f852                	sd	s4,48(sp)
    80003c5e:	f456                	sd	s5,40(sp)
    80003c60:	f05a                	sd	s6,32(sp)
    80003c62:	ec5e                	sd	s7,24(sp)
    80003c64:	e862                	sd	s8,16(sp)
    80003c66:	e466                	sd	s9,8(sp)
    80003c68:	1080                	addi	s0,sp,96
    80003c6a:	84aa                	mv	s1,a0
    80003c6c:	8aae                	mv	s5,a1
    80003c6e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c70:	00054703          	lbu	a4,0(a0)
    80003c74:	02f00793          	li	a5,47
    80003c78:	02f70363          	beq	a4,a5,80003c9e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c7c:	ffffe097          	auipc	ra,0xffffe
    80003c80:	d0a080e7          	jalr	-758(ra) # 80001986 <myproc>
    80003c84:	15053503          	ld	a0,336(a0)
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	956080e7          	jalr	-1706(ra) # 800035de <idup>
    80003c90:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c92:	02f00913          	li	s2,47
  len = path - s;
    80003c96:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c98:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c9a:	4b85                	li	s7,1
    80003c9c:	a865                	j	80003d54 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c9e:	4585                	li	a1,1
    80003ca0:	4505                	li	a0,1
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	646080e7          	jalr	1606(ra) # 800032e8 <iget>
    80003caa:	89aa                	mv	s3,a0
    80003cac:	b7dd                	j	80003c92 <namex+0x42>
      iunlockput(ip);
    80003cae:	854e                	mv	a0,s3
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	bce080e7          	jalr	-1074(ra) # 8000387e <iunlockput>
      return 0;
    80003cb8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cba:	854e                	mv	a0,s3
    80003cbc:	60e6                	ld	ra,88(sp)
    80003cbe:	6446                	ld	s0,80(sp)
    80003cc0:	64a6                	ld	s1,72(sp)
    80003cc2:	6906                	ld	s2,64(sp)
    80003cc4:	79e2                	ld	s3,56(sp)
    80003cc6:	7a42                	ld	s4,48(sp)
    80003cc8:	7aa2                	ld	s5,40(sp)
    80003cca:	7b02                	ld	s6,32(sp)
    80003ccc:	6be2                	ld	s7,24(sp)
    80003cce:	6c42                	ld	s8,16(sp)
    80003cd0:	6ca2                	ld	s9,8(sp)
    80003cd2:	6125                	addi	sp,sp,96
    80003cd4:	8082                	ret
      iunlock(ip);
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	a06080e7          	jalr	-1530(ra) # 800036de <iunlock>
      return ip;
    80003ce0:	bfe9                	j	80003cba <namex+0x6a>
      iunlockput(ip);
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	b9a080e7          	jalr	-1126(ra) # 8000387e <iunlockput>
      return 0;
    80003cec:	89e6                	mv	s3,s9
    80003cee:	b7f1                	j	80003cba <namex+0x6a>
  len = path - s;
    80003cf0:	40b48633          	sub	a2,s1,a1
    80003cf4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003cf8:	099c5463          	bge	s8,s9,80003d80 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cfc:	4639                	li	a2,14
    80003cfe:	8552                	mv	a0,s4
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	01a080e7          	jalr	26(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003d08:	0004c783          	lbu	a5,0(s1)
    80003d0c:	01279763          	bne	a5,s2,80003d1a <namex+0xca>
    path++;
    80003d10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d12:	0004c783          	lbu	a5,0(s1)
    80003d16:	ff278de3          	beq	a5,s2,80003d10 <namex+0xc0>
    ilock(ip);
    80003d1a:	854e                	mv	a0,s3
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	900080e7          	jalr	-1792(ra) # 8000361c <ilock>
    if(ip->type != T_DIR){
    80003d24:	04499783          	lh	a5,68(s3)
    80003d28:	f97793e3          	bne	a5,s7,80003cae <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d2c:	000a8563          	beqz	s5,80003d36 <namex+0xe6>
    80003d30:	0004c783          	lbu	a5,0(s1)
    80003d34:	d3cd                	beqz	a5,80003cd6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d36:	865a                	mv	a2,s6
    80003d38:	85d2                	mv	a1,s4
    80003d3a:	854e                	mv	a0,s3
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	dfc080e7          	jalr	-516(ra) # 80003b38 <dirlookup>
    80003d44:	8caa                	mv	s9,a0
    80003d46:	dd51                	beqz	a0,80003ce2 <namex+0x92>
    iunlockput(ip);
    80003d48:	854e                	mv	a0,s3
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	b34080e7          	jalr	-1228(ra) # 8000387e <iunlockput>
    ip = next;
    80003d52:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d54:	0004c783          	lbu	a5,0(s1)
    80003d58:	05279763          	bne	a5,s2,80003da6 <namex+0x156>
    path++;
    80003d5c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d5e:	0004c783          	lbu	a5,0(s1)
    80003d62:	ff278de3          	beq	a5,s2,80003d5c <namex+0x10c>
  if(*path == 0)
    80003d66:	c79d                	beqz	a5,80003d94 <namex+0x144>
    path++;
    80003d68:	85a6                	mv	a1,s1
  len = path - s;
    80003d6a:	8cda                	mv	s9,s6
    80003d6c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d6e:	01278963          	beq	a5,s2,80003d80 <namex+0x130>
    80003d72:	dfbd                	beqz	a5,80003cf0 <namex+0xa0>
    path++;
    80003d74:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d76:	0004c783          	lbu	a5,0(s1)
    80003d7a:	ff279ce3          	bne	a5,s2,80003d72 <namex+0x122>
    80003d7e:	bf8d                	j	80003cf0 <namex+0xa0>
    memmove(name, s, len);
    80003d80:	2601                	sext.w	a2,a2
    80003d82:	8552                	mv	a0,s4
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	f96080e7          	jalr	-106(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003d8c:	9cd2                	add	s9,s9,s4
    80003d8e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d92:	bf9d                	j	80003d08 <namex+0xb8>
  if(nameiparent){
    80003d94:	f20a83e3          	beqz	s5,80003cba <namex+0x6a>
    iput(ip);
    80003d98:	854e                	mv	a0,s3
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	a3c080e7          	jalr	-1476(ra) # 800037d6 <iput>
    return 0;
    80003da2:	4981                	li	s3,0
    80003da4:	bf19                	j	80003cba <namex+0x6a>
  if(*path == 0)
    80003da6:	d7fd                	beqz	a5,80003d94 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003da8:	0004c783          	lbu	a5,0(s1)
    80003dac:	85a6                	mv	a1,s1
    80003dae:	b7d1                	j	80003d72 <namex+0x122>

0000000080003db0 <dirlink>:
{
    80003db0:	7139                	addi	sp,sp,-64
    80003db2:	fc06                	sd	ra,56(sp)
    80003db4:	f822                	sd	s0,48(sp)
    80003db6:	f426                	sd	s1,40(sp)
    80003db8:	f04a                	sd	s2,32(sp)
    80003dba:	ec4e                	sd	s3,24(sp)
    80003dbc:	e852                	sd	s4,16(sp)
    80003dbe:	0080                	addi	s0,sp,64
    80003dc0:	892a                	mv	s2,a0
    80003dc2:	8a2e                	mv	s4,a1
    80003dc4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dc6:	4601                	li	a2,0
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	d70080e7          	jalr	-656(ra) # 80003b38 <dirlookup>
    80003dd0:	e93d                	bnez	a0,80003e46 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd2:	04c92483          	lw	s1,76(s2)
    80003dd6:	c49d                	beqz	s1,80003e04 <dirlink+0x54>
    80003dd8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dda:	4741                	li	a4,16
    80003ddc:	86a6                	mv	a3,s1
    80003dde:	fc040613          	addi	a2,s0,-64
    80003de2:	4581                	li	a1,0
    80003de4:	854a                	mv	a0,s2
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	aea080e7          	jalr	-1302(ra) # 800038d0 <readi>
    80003dee:	47c1                	li	a5,16
    80003df0:	06f51163          	bne	a0,a5,80003e52 <dirlink+0xa2>
    if(de.inum == 0)
    80003df4:	fc045783          	lhu	a5,-64(s0)
    80003df8:	c791                	beqz	a5,80003e04 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfa:	24c1                	addiw	s1,s1,16
    80003dfc:	04c92783          	lw	a5,76(s2)
    80003e00:	fcf4ede3          	bltu	s1,a5,80003dda <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e04:	4639                	li	a2,14
    80003e06:	85d2                	mv	a1,s4
    80003e08:	fc240513          	addi	a0,s0,-62
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	fc6080e7          	jalr	-58(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003e14:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e18:	4741                	li	a4,16
    80003e1a:	86a6                	mv	a3,s1
    80003e1c:	fc040613          	addi	a2,s0,-64
    80003e20:	4581                	li	a1,0
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	bdc080e7          	jalr	-1060(ra) # 80003a00 <writei>
    80003e2c:	872a                	mv	a4,a0
    80003e2e:	47c1                	li	a5,16
  return 0;
    80003e30:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e32:	02f71863          	bne	a4,a5,80003e62 <dirlink+0xb2>
}
    80003e36:	70e2                	ld	ra,56(sp)
    80003e38:	7442                	ld	s0,48(sp)
    80003e3a:	74a2                	ld	s1,40(sp)
    80003e3c:	7902                	ld	s2,32(sp)
    80003e3e:	69e2                	ld	s3,24(sp)
    80003e40:	6a42                	ld	s4,16(sp)
    80003e42:	6121                	addi	sp,sp,64
    80003e44:	8082                	ret
    iput(ip);
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	990080e7          	jalr	-1648(ra) # 800037d6 <iput>
    return -1;
    80003e4e:	557d                	li	a0,-1
    80003e50:	b7dd                	j	80003e36 <dirlink+0x86>
      panic("dirlink read");
    80003e52:	00004517          	auipc	a0,0x4
    80003e56:	7a650513          	addi	a0,a0,1958 # 800085f8 <syscalls+0x1c8>
    80003e5a:	ffffc097          	auipc	ra,0xffffc
    80003e5e:	6d0080e7          	jalr	1744(ra) # 8000052a <panic>
    panic("dirlink");
    80003e62:	00005517          	auipc	a0,0x5
    80003e66:	8a650513          	addi	a0,a0,-1882 # 80008708 <syscalls+0x2d8>
    80003e6a:	ffffc097          	auipc	ra,0xffffc
    80003e6e:	6c0080e7          	jalr	1728(ra) # 8000052a <panic>

0000000080003e72 <namei>:

struct inode*
namei(char *path)
{
    80003e72:	1101                	addi	sp,sp,-32
    80003e74:	ec06                	sd	ra,24(sp)
    80003e76:	e822                	sd	s0,16(sp)
    80003e78:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e7a:	fe040613          	addi	a2,s0,-32
    80003e7e:	4581                	li	a1,0
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	dd0080e7          	jalr	-560(ra) # 80003c50 <namex>
}
    80003e88:	60e2                	ld	ra,24(sp)
    80003e8a:	6442                	ld	s0,16(sp)
    80003e8c:	6105                	addi	sp,sp,32
    80003e8e:	8082                	ret

0000000080003e90 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e90:	1141                	addi	sp,sp,-16
    80003e92:	e406                	sd	ra,8(sp)
    80003e94:	e022                	sd	s0,0(sp)
    80003e96:	0800                	addi	s0,sp,16
    80003e98:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e9a:	4585                	li	a1,1
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	db4080e7          	jalr	-588(ra) # 80003c50 <namex>
}
    80003ea4:	60a2                	ld	ra,8(sp)
    80003ea6:	6402                	ld	s0,0(sp)
    80003ea8:	0141                	addi	sp,sp,16
    80003eaa:	8082                	ret

0000000080003eac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	e04a                	sd	s2,0(sp)
    80003eb6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003eb8:	0001d917          	auipc	s2,0x1d
    80003ebc:	3b890913          	addi	s2,s2,952 # 80021270 <log>
    80003ec0:	01892583          	lw	a1,24(s2)
    80003ec4:	02892503          	lw	a0,40(s2)
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	f50080e7          	jalr	-176(ra) # 80002e18 <bread>
    80003ed0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ed2:	02c92683          	lw	a3,44(s2)
    80003ed6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ed8:	02d05863          	blez	a3,80003f08 <write_head+0x5c>
    80003edc:	0001d797          	auipc	a5,0x1d
    80003ee0:	3c478793          	addi	a5,a5,964 # 800212a0 <log+0x30>
    80003ee4:	05c50713          	addi	a4,a0,92
    80003ee8:	36fd                	addiw	a3,a3,-1
    80003eea:	02069613          	slli	a2,a3,0x20
    80003eee:	01e65693          	srli	a3,a2,0x1e
    80003ef2:	0001d617          	auipc	a2,0x1d
    80003ef6:	3b260613          	addi	a2,a2,946 # 800212a4 <log+0x34>
    80003efa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003efc:	4390                	lw	a2,0(a5)
    80003efe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f00:	0791                	addi	a5,a5,4
    80003f02:	0711                	addi	a4,a4,4
    80003f04:	fed79ce3          	bne	a5,a3,80003efc <write_head+0x50>
  }
  bwrite(buf);
    80003f08:	8526                	mv	a0,s1
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	000080e7          	jalr	ra # 80002f0a <bwrite>
  brelse(buf);
    80003f12:	8526                	mv	a0,s1
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	034080e7          	jalr	52(ra) # 80002f48 <brelse>
}
    80003f1c:	60e2                	ld	ra,24(sp)
    80003f1e:	6442                	ld	s0,16(sp)
    80003f20:	64a2                	ld	s1,8(sp)
    80003f22:	6902                	ld	s2,0(sp)
    80003f24:	6105                	addi	sp,sp,32
    80003f26:	8082                	ret

0000000080003f28 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f28:	0001d797          	auipc	a5,0x1d
    80003f2c:	3747a783          	lw	a5,884(a5) # 8002129c <log+0x2c>
    80003f30:	0af05d63          	blez	a5,80003fea <install_trans+0xc2>
{
    80003f34:	7139                	addi	sp,sp,-64
    80003f36:	fc06                	sd	ra,56(sp)
    80003f38:	f822                	sd	s0,48(sp)
    80003f3a:	f426                	sd	s1,40(sp)
    80003f3c:	f04a                	sd	s2,32(sp)
    80003f3e:	ec4e                	sd	s3,24(sp)
    80003f40:	e852                	sd	s4,16(sp)
    80003f42:	e456                	sd	s5,8(sp)
    80003f44:	e05a                	sd	s6,0(sp)
    80003f46:	0080                	addi	s0,sp,64
    80003f48:	8b2a                	mv	s6,a0
    80003f4a:	0001da97          	auipc	s5,0x1d
    80003f4e:	356a8a93          	addi	s5,s5,854 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f52:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f54:	0001d997          	auipc	s3,0x1d
    80003f58:	31c98993          	addi	s3,s3,796 # 80021270 <log>
    80003f5c:	a00d                	j	80003f7e <install_trans+0x56>
    brelse(lbuf);
    80003f5e:	854a                	mv	a0,s2
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	fe8080e7          	jalr	-24(ra) # 80002f48 <brelse>
    brelse(dbuf);
    80003f68:	8526                	mv	a0,s1
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	fde080e7          	jalr	-34(ra) # 80002f48 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f72:	2a05                	addiw	s4,s4,1
    80003f74:	0a91                	addi	s5,s5,4
    80003f76:	02c9a783          	lw	a5,44(s3)
    80003f7a:	04fa5e63          	bge	s4,a5,80003fd6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f7e:	0189a583          	lw	a1,24(s3)
    80003f82:	014585bb          	addw	a1,a1,s4
    80003f86:	2585                	addiw	a1,a1,1
    80003f88:	0289a503          	lw	a0,40(s3)
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	e8c080e7          	jalr	-372(ra) # 80002e18 <bread>
    80003f94:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f96:	000aa583          	lw	a1,0(s5)
    80003f9a:	0289a503          	lw	a0,40(s3)
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	e7a080e7          	jalr	-390(ra) # 80002e18 <bread>
    80003fa6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fa8:	40000613          	li	a2,1024
    80003fac:	05890593          	addi	a1,s2,88
    80003fb0:	05850513          	addi	a0,a0,88
    80003fb4:	ffffd097          	auipc	ra,0xffffd
    80003fb8:	d66080e7          	jalr	-666(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	f4c080e7          	jalr	-180(ra) # 80002f0a <bwrite>
    if(recovering == 0)
    80003fc6:	f80b1ce3          	bnez	s6,80003f5e <install_trans+0x36>
      bunpin(dbuf);
    80003fca:	8526                	mv	a0,s1
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	056080e7          	jalr	86(ra) # 80003022 <bunpin>
    80003fd4:	b769                	j	80003f5e <install_trans+0x36>
}
    80003fd6:	70e2                	ld	ra,56(sp)
    80003fd8:	7442                	ld	s0,48(sp)
    80003fda:	74a2                	ld	s1,40(sp)
    80003fdc:	7902                	ld	s2,32(sp)
    80003fde:	69e2                	ld	s3,24(sp)
    80003fe0:	6a42                	ld	s4,16(sp)
    80003fe2:	6aa2                	ld	s5,8(sp)
    80003fe4:	6b02                	ld	s6,0(sp)
    80003fe6:	6121                	addi	sp,sp,64
    80003fe8:	8082                	ret
    80003fea:	8082                	ret

0000000080003fec <initlog>:
{
    80003fec:	7179                	addi	sp,sp,-48
    80003fee:	f406                	sd	ra,40(sp)
    80003ff0:	f022                	sd	s0,32(sp)
    80003ff2:	ec26                	sd	s1,24(sp)
    80003ff4:	e84a                	sd	s2,16(sp)
    80003ff6:	e44e                	sd	s3,8(sp)
    80003ff8:	1800                	addi	s0,sp,48
    80003ffa:	892a                	mv	s2,a0
    80003ffc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003ffe:	0001d497          	auipc	s1,0x1d
    80004002:	27248493          	addi	s1,s1,626 # 80021270 <log>
    80004006:	00004597          	auipc	a1,0x4
    8000400a:	60258593          	addi	a1,a1,1538 # 80008608 <syscalls+0x1d8>
    8000400e:	8526                	mv	a0,s1
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	b22080e7          	jalr	-1246(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004018:	0149a583          	lw	a1,20(s3)
    8000401c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000401e:	0109a783          	lw	a5,16(s3)
    80004022:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004024:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004028:	854a                	mv	a0,s2
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	dee080e7          	jalr	-530(ra) # 80002e18 <bread>
  log.lh.n = lh->n;
    80004032:	4d34                	lw	a3,88(a0)
    80004034:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004036:	02d05663          	blez	a3,80004062 <initlog+0x76>
    8000403a:	05c50793          	addi	a5,a0,92
    8000403e:	0001d717          	auipc	a4,0x1d
    80004042:	26270713          	addi	a4,a4,610 # 800212a0 <log+0x30>
    80004046:	36fd                	addiw	a3,a3,-1
    80004048:	02069613          	slli	a2,a3,0x20
    8000404c:	01e65693          	srli	a3,a2,0x1e
    80004050:	06050613          	addi	a2,a0,96
    80004054:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004056:	4390                	lw	a2,0(a5)
    80004058:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000405a:	0791                	addi	a5,a5,4
    8000405c:	0711                	addi	a4,a4,4
    8000405e:	fed79ce3          	bne	a5,a3,80004056 <initlog+0x6a>
  brelse(buf);
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	ee6080e7          	jalr	-282(ra) # 80002f48 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000406a:	4505                	li	a0,1
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	ebc080e7          	jalr	-324(ra) # 80003f28 <install_trans>
  log.lh.n = 0;
    80004074:	0001d797          	auipc	a5,0x1d
    80004078:	2207a423          	sw	zero,552(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	e30080e7          	jalr	-464(ra) # 80003eac <write_head>
}
    80004084:	70a2                	ld	ra,40(sp)
    80004086:	7402                	ld	s0,32(sp)
    80004088:	64e2                	ld	s1,24(sp)
    8000408a:	6942                	ld	s2,16(sp)
    8000408c:	69a2                	ld	s3,8(sp)
    8000408e:	6145                	addi	sp,sp,48
    80004090:	8082                	ret

0000000080004092 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004092:	1101                	addi	sp,sp,-32
    80004094:	ec06                	sd	ra,24(sp)
    80004096:	e822                	sd	s0,16(sp)
    80004098:	e426                	sd	s1,8(sp)
    8000409a:	e04a                	sd	s2,0(sp)
    8000409c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000409e:	0001d517          	auipc	a0,0x1d
    800040a2:	1d250513          	addi	a0,a0,466 # 80021270 <log>
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	b1c080e7          	jalr	-1252(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800040ae:	0001d497          	auipc	s1,0x1d
    800040b2:	1c248493          	addi	s1,s1,450 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040b6:	4979                	li	s2,30
    800040b8:	a039                	j	800040c6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040ba:	85a6                	mv	a1,s1
    800040bc:	8526                	mv	a0,s1
    800040be:	ffffe097          	auipc	ra,0xffffe
    800040c2:	f88080e7          	jalr	-120(ra) # 80002046 <sleep>
    if(log.committing){
    800040c6:	50dc                	lw	a5,36(s1)
    800040c8:	fbed                	bnez	a5,800040ba <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ca:	509c                	lw	a5,32(s1)
    800040cc:	0017871b          	addiw	a4,a5,1
    800040d0:	0007069b          	sext.w	a3,a4
    800040d4:	0027179b          	slliw	a5,a4,0x2
    800040d8:	9fb9                	addw	a5,a5,a4
    800040da:	0017979b          	slliw	a5,a5,0x1
    800040de:	54d8                	lw	a4,44(s1)
    800040e0:	9fb9                	addw	a5,a5,a4
    800040e2:	00f95963          	bge	s2,a5,800040f4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040e6:	85a6                	mv	a1,s1
    800040e8:	8526                	mv	a0,s1
    800040ea:	ffffe097          	auipc	ra,0xffffe
    800040ee:	f5c080e7          	jalr	-164(ra) # 80002046 <sleep>
    800040f2:	bfd1                	j	800040c6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040f4:	0001d517          	auipc	a0,0x1d
    800040f8:	17c50513          	addi	a0,a0,380 # 80021270 <log>
    800040fc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040fe:	ffffd097          	auipc	ra,0xffffd
    80004102:	b78080e7          	jalr	-1160(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004106:	60e2                	ld	ra,24(sp)
    80004108:	6442                	ld	s0,16(sp)
    8000410a:	64a2                	ld	s1,8(sp)
    8000410c:	6902                	ld	s2,0(sp)
    8000410e:	6105                	addi	sp,sp,32
    80004110:	8082                	ret

0000000080004112 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004112:	7139                	addi	sp,sp,-64
    80004114:	fc06                	sd	ra,56(sp)
    80004116:	f822                	sd	s0,48(sp)
    80004118:	f426                	sd	s1,40(sp)
    8000411a:	f04a                	sd	s2,32(sp)
    8000411c:	ec4e                	sd	s3,24(sp)
    8000411e:	e852                	sd	s4,16(sp)
    80004120:	e456                	sd	s5,8(sp)
    80004122:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004124:	0001d497          	auipc	s1,0x1d
    80004128:	14c48493          	addi	s1,s1,332 # 80021270 <log>
    8000412c:	8526                	mv	a0,s1
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	a94080e7          	jalr	-1388(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004136:	509c                	lw	a5,32(s1)
    80004138:	37fd                	addiw	a5,a5,-1
    8000413a:	0007891b          	sext.w	s2,a5
    8000413e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004140:	50dc                	lw	a5,36(s1)
    80004142:	e7b9                	bnez	a5,80004190 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004144:	04091e63          	bnez	s2,800041a0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004148:	0001d497          	auipc	s1,0x1d
    8000414c:	12848493          	addi	s1,s1,296 # 80021270 <log>
    80004150:	4785                	li	a5,1
    80004152:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004154:	8526                	mv	a0,s1
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	b20080e7          	jalr	-1248(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000415e:	54dc                	lw	a5,44(s1)
    80004160:	06f04763          	bgtz	a5,800041ce <end_op+0xbc>
    acquire(&log.lock);
    80004164:	0001d497          	auipc	s1,0x1d
    80004168:	10c48493          	addi	s1,s1,268 # 80021270 <log>
    8000416c:	8526                	mv	a0,s1
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	a54080e7          	jalr	-1452(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004176:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000417a:	8526                	mv	a0,s1
    8000417c:	ffffe097          	auipc	ra,0xffffe
    80004180:	056080e7          	jalr	86(ra) # 800021d2 <wakeup>
    release(&log.lock);
    80004184:	8526                	mv	a0,s1
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	af0080e7          	jalr	-1296(ra) # 80000c76 <release>
}
    8000418e:	a03d                	j	800041bc <end_op+0xaa>
    panic("log.committing");
    80004190:	00004517          	auipc	a0,0x4
    80004194:	48050513          	addi	a0,a0,1152 # 80008610 <syscalls+0x1e0>
    80004198:	ffffc097          	auipc	ra,0xffffc
    8000419c:	392080e7          	jalr	914(ra) # 8000052a <panic>
    wakeup(&log);
    800041a0:	0001d497          	auipc	s1,0x1d
    800041a4:	0d048493          	addi	s1,s1,208 # 80021270 <log>
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffe097          	auipc	ra,0xffffe
    800041ae:	028080e7          	jalr	40(ra) # 800021d2 <wakeup>
  release(&log.lock);
    800041b2:	8526                	mv	a0,s1
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	ac2080e7          	jalr	-1342(ra) # 80000c76 <release>
}
    800041bc:	70e2                	ld	ra,56(sp)
    800041be:	7442                	ld	s0,48(sp)
    800041c0:	74a2                	ld	s1,40(sp)
    800041c2:	7902                	ld	s2,32(sp)
    800041c4:	69e2                	ld	s3,24(sp)
    800041c6:	6a42                	ld	s4,16(sp)
    800041c8:	6aa2                	ld	s5,8(sp)
    800041ca:	6121                	addi	sp,sp,64
    800041cc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ce:	0001da97          	auipc	s5,0x1d
    800041d2:	0d2a8a93          	addi	s5,s5,210 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041d6:	0001da17          	auipc	s4,0x1d
    800041da:	09aa0a13          	addi	s4,s4,154 # 80021270 <log>
    800041de:	018a2583          	lw	a1,24(s4)
    800041e2:	012585bb          	addw	a1,a1,s2
    800041e6:	2585                	addiw	a1,a1,1
    800041e8:	028a2503          	lw	a0,40(s4)
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	c2c080e7          	jalr	-980(ra) # 80002e18 <bread>
    800041f4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041f6:	000aa583          	lw	a1,0(s5)
    800041fa:	028a2503          	lw	a0,40(s4)
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	c1a080e7          	jalr	-998(ra) # 80002e18 <bread>
    80004206:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004208:	40000613          	li	a2,1024
    8000420c:	05850593          	addi	a1,a0,88
    80004210:	05848513          	addi	a0,s1,88
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	b06080e7          	jalr	-1274(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000421c:	8526                	mv	a0,s1
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	cec080e7          	jalr	-788(ra) # 80002f0a <bwrite>
    brelse(from);
    80004226:	854e                	mv	a0,s3
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	d20080e7          	jalr	-736(ra) # 80002f48 <brelse>
    brelse(to);
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	d16080e7          	jalr	-746(ra) # 80002f48 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000423a:	2905                	addiw	s2,s2,1
    8000423c:	0a91                	addi	s5,s5,4
    8000423e:	02ca2783          	lw	a5,44(s4)
    80004242:	f8f94ee3          	blt	s2,a5,800041de <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	c66080e7          	jalr	-922(ra) # 80003eac <write_head>
    install_trans(0); // Now install writes to home locations
    8000424e:	4501                	li	a0,0
    80004250:	00000097          	auipc	ra,0x0
    80004254:	cd8080e7          	jalr	-808(ra) # 80003f28 <install_trans>
    log.lh.n = 0;
    80004258:	0001d797          	auipc	a5,0x1d
    8000425c:	0407a223          	sw	zero,68(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004260:	00000097          	auipc	ra,0x0
    80004264:	c4c080e7          	jalr	-948(ra) # 80003eac <write_head>
    80004268:	bdf5                	j	80004164 <end_op+0x52>

000000008000426a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000426a:	1101                	addi	sp,sp,-32
    8000426c:	ec06                	sd	ra,24(sp)
    8000426e:	e822                	sd	s0,16(sp)
    80004270:	e426                	sd	s1,8(sp)
    80004272:	e04a                	sd	s2,0(sp)
    80004274:	1000                	addi	s0,sp,32
    80004276:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004278:	0001d917          	auipc	s2,0x1d
    8000427c:	ff890913          	addi	s2,s2,-8 # 80021270 <log>
    80004280:	854a                	mv	a0,s2
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	940080e7          	jalr	-1728(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000428a:	02c92603          	lw	a2,44(s2)
    8000428e:	47f5                	li	a5,29
    80004290:	06c7c563          	blt	a5,a2,800042fa <log_write+0x90>
    80004294:	0001d797          	auipc	a5,0x1d
    80004298:	ff87a783          	lw	a5,-8(a5) # 8002128c <log+0x1c>
    8000429c:	37fd                	addiw	a5,a5,-1
    8000429e:	04f65e63          	bge	a2,a5,800042fa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042a2:	0001d797          	auipc	a5,0x1d
    800042a6:	fee7a783          	lw	a5,-18(a5) # 80021290 <log+0x20>
    800042aa:	06f05063          	blez	a5,8000430a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042ae:	4781                	li	a5,0
    800042b0:	06c05563          	blez	a2,8000431a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042b4:	44cc                	lw	a1,12(s1)
    800042b6:	0001d717          	auipc	a4,0x1d
    800042ba:	fea70713          	addi	a4,a4,-22 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042be:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042c0:	4314                	lw	a3,0(a4)
    800042c2:	04b68c63          	beq	a3,a1,8000431a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042c6:	2785                	addiw	a5,a5,1
    800042c8:	0711                	addi	a4,a4,4
    800042ca:	fef61be3          	bne	a2,a5,800042c0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ce:	0621                	addi	a2,a2,8
    800042d0:	060a                	slli	a2,a2,0x2
    800042d2:	0001d797          	auipc	a5,0x1d
    800042d6:	f9e78793          	addi	a5,a5,-98 # 80021270 <log>
    800042da:	963e                	add	a2,a2,a5
    800042dc:	44dc                	lw	a5,12(s1)
    800042de:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042e0:	8526                	mv	a0,s1
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	d04080e7          	jalr	-764(ra) # 80002fe6 <bpin>
    log.lh.n++;
    800042ea:	0001d717          	auipc	a4,0x1d
    800042ee:	f8670713          	addi	a4,a4,-122 # 80021270 <log>
    800042f2:	575c                	lw	a5,44(a4)
    800042f4:	2785                	addiw	a5,a5,1
    800042f6:	d75c                	sw	a5,44(a4)
    800042f8:	a835                	j	80004334 <log_write+0xca>
    panic("too big a transaction");
    800042fa:	00004517          	auipc	a0,0x4
    800042fe:	32650513          	addi	a0,a0,806 # 80008620 <syscalls+0x1f0>
    80004302:	ffffc097          	auipc	ra,0xffffc
    80004306:	228080e7          	jalr	552(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000430a:	00004517          	auipc	a0,0x4
    8000430e:	32e50513          	addi	a0,a0,814 # 80008638 <syscalls+0x208>
    80004312:	ffffc097          	auipc	ra,0xffffc
    80004316:	218080e7          	jalr	536(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000431a:	00878713          	addi	a4,a5,8
    8000431e:	00271693          	slli	a3,a4,0x2
    80004322:	0001d717          	auipc	a4,0x1d
    80004326:	f4e70713          	addi	a4,a4,-178 # 80021270 <log>
    8000432a:	9736                	add	a4,a4,a3
    8000432c:	44d4                	lw	a3,12(s1)
    8000432e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004330:	faf608e3          	beq	a2,a5,800042e0 <log_write+0x76>
  }
  release(&log.lock);
    80004334:	0001d517          	auipc	a0,0x1d
    80004338:	f3c50513          	addi	a0,a0,-196 # 80021270 <log>
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	93a080e7          	jalr	-1734(ra) # 80000c76 <release>
}
    80004344:	60e2                	ld	ra,24(sp)
    80004346:	6442                	ld	s0,16(sp)
    80004348:	64a2                	ld	s1,8(sp)
    8000434a:	6902                	ld	s2,0(sp)
    8000434c:	6105                	addi	sp,sp,32
    8000434e:	8082                	ret

0000000080004350 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004350:	1101                	addi	sp,sp,-32
    80004352:	ec06                	sd	ra,24(sp)
    80004354:	e822                	sd	s0,16(sp)
    80004356:	e426                	sd	s1,8(sp)
    80004358:	e04a                	sd	s2,0(sp)
    8000435a:	1000                	addi	s0,sp,32
    8000435c:	84aa                	mv	s1,a0
    8000435e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004360:	00004597          	auipc	a1,0x4
    80004364:	2f858593          	addi	a1,a1,760 # 80008658 <syscalls+0x228>
    80004368:	0521                	addi	a0,a0,8
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	7c8080e7          	jalr	1992(ra) # 80000b32 <initlock>
  lk->name = name;
    80004372:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004376:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000437a:	0204a423          	sw	zero,40(s1)
}
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6902                	ld	s2,0(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000438a:	1101                	addi	sp,sp,-32
    8000438c:	ec06                	sd	ra,24(sp)
    8000438e:	e822                	sd	s0,16(sp)
    80004390:	e426                	sd	s1,8(sp)
    80004392:	e04a                	sd	s2,0(sp)
    80004394:	1000                	addi	s0,sp,32
    80004396:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004398:	00850913          	addi	s2,a0,8
    8000439c:	854a                	mv	a0,s2
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	824080e7          	jalr	-2012(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800043a6:	409c                	lw	a5,0(s1)
    800043a8:	cb89                	beqz	a5,800043ba <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043aa:	85ca                	mv	a1,s2
    800043ac:	8526                	mv	a0,s1
    800043ae:	ffffe097          	auipc	ra,0xffffe
    800043b2:	c98080e7          	jalr	-872(ra) # 80002046 <sleep>
  while (lk->locked) {
    800043b6:	409c                	lw	a5,0(s1)
    800043b8:	fbed                	bnez	a5,800043aa <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043ba:	4785                	li	a5,1
    800043bc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	5c8080e7          	jalr	1480(ra) # 80001986 <myproc>
    800043c6:	591c                	lw	a5,48(a0)
    800043c8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043ca:	854a                	mv	a0,s2
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	8aa080e7          	jalr	-1878(ra) # 80000c76 <release>
}
    800043d4:	60e2                	ld	ra,24(sp)
    800043d6:	6442                	ld	s0,16(sp)
    800043d8:	64a2                	ld	s1,8(sp)
    800043da:	6902                	ld	s2,0(sp)
    800043dc:	6105                	addi	sp,sp,32
    800043de:	8082                	ret

00000000800043e0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043e0:	1101                	addi	sp,sp,-32
    800043e2:	ec06                	sd	ra,24(sp)
    800043e4:	e822                	sd	s0,16(sp)
    800043e6:	e426                	sd	s1,8(sp)
    800043e8:	e04a                	sd	s2,0(sp)
    800043ea:	1000                	addi	s0,sp,32
    800043ec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ee:	00850913          	addi	s2,a0,8
    800043f2:	854a                	mv	a0,s2
    800043f4:	ffffc097          	auipc	ra,0xffffc
    800043f8:	7ce080e7          	jalr	1998(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800043fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004400:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004404:	8526                	mv	a0,s1
    80004406:	ffffe097          	auipc	ra,0xffffe
    8000440a:	dcc080e7          	jalr	-564(ra) # 800021d2 <wakeup>
  release(&lk->lk);
    8000440e:	854a                	mv	a0,s2
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	866080e7          	jalr	-1946(ra) # 80000c76 <release>
}
    80004418:	60e2                	ld	ra,24(sp)
    8000441a:	6442                	ld	s0,16(sp)
    8000441c:	64a2                	ld	s1,8(sp)
    8000441e:	6902                	ld	s2,0(sp)
    80004420:	6105                	addi	sp,sp,32
    80004422:	8082                	ret

0000000080004424 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004424:	7179                	addi	sp,sp,-48
    80004426:	f406                	sd	ra,40(sp)
    80004428:	f022                	sd	s0,32(sp)
    8000442a:	ec26                	sd	s1,24(sp)
    8000442c:	e84a                	sd	s2,16(sp)
    8000442e:	e44e                	sd	s3,8(sp)
    80004430:	1800                	addi	s0,sp,48
    80004432:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004434:	00850913          	addi	s2,a0,8
    80004438:	854a                	mv	a0,s2
    8000443a:	ffffc097          	auipc	ra,0xffffc
    8000443e:	788080e7          	jalr	1928(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004442:	409c                	lw	a5,0(s1)
    80004444:	ef99                	bnez	a5,80004462 <holdingsleep+0x3e>
    80004446:	4481                	li	s1,0
  release(&lk->lk);
    80004448:	854a                	mv	a0,s2
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	82c080e7          	jalr	-2004(ra) # 80000c76 <release>
  return r;
}
    80004452:	8526                	mv	a0,s1
    80004454:	70a2                	ld	ra,40(sp)
    80004456:	7402                	ld	s0,32(sp)
    80004458:	64e2                	ld	s1,24(sp)
    8000445a:	6942                	ld	s2,16(sp)
    8000445c:	69a2                	ld	s3,8(sp)
    8000445e:	6145                	addi	sp,sp,48
    80004460:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004462:	0284a983          	lw	s3,40(s1)
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	520080e7          	jalr	1312(ra) # 80001986 <myproc>
    8000446e:	5904                	lw	s1,48(a0)
    80004470:	413484b3          	sub	s1,s1,s3
    80004474:	0014b493          	seqz	s1,s1
    80004478:	bfc1                	j	80004448 <holdingsleep+0x24>

000000008000447a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000447a:	1141                	addi	sp,sp,-16
    8000447c:	e406                	sd	ra,8(sp)
    8000447e:	e022                	sd	s0,0(sp)
    80004480:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004482:	00004597          	auipc	a1,0x4
    80004486:	1e658593          	addi	a1,a1,486 # 80008668 <syscalls+0x238>
    8000448a:	0001d517          	auipc	a0,0x1d
    8000448e:	fce50513          	addi	a0,a0,-50 # 80021458 <ftable>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	6a0080e7          	jalr	1696(ra) # 80000b32 <initlock>
}
    8000449a:	60a2                	ld	ra,8(sp)
    8000449c:	6402                	ld	s0,0(sp)
    8000449e:	0141                	addi	sp,sp,16
    800044a0:	8082                	ret

00000000800044a2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044a2:	1101                	addi	sp,sp,-32
    800044a4:	ec06                	sd	ra,24(sp)
    800044a6:	e822                	sd	s0,16(sp)
    800044a8:	e426                	sd	s1,8(sp)
    800044aa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ac:	0001d517          	auipc	a0,0x1d
    800044b0:	fac50513          	addi	a0,a0,-84 # 80021458 <ftable>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	70e080e7          	jalr	1806(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044bc:	0001d497          	auipc	s1,0x1d
    800044c0:	fb448493          	addi	s1,s1,-76 # 80021470 <ftable+0x18>
    800044c4:	0001e717          	auipc	a4,0x1e
    800044c8:	f4c70713          	addi	a4,a4,-180 # 80022410 <ftable+0xfb8>
    if(f->ref == 0){
    800044cc:	40dc                	lw	a5,4(s1)
    800044ce:	cf99                	beqz	a5,800044ec <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044d0:	02848493          	addi	s1,s1,40
    800044d4:	fee49ce3          	bne	s1,a4,800044cc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044d8:	0001d517          	auipc	a0,0x1d
    800044dc:	f8050513          	addi	a0,a0,-128 # 80021458 <ftable>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	796080e7          	jalr	1942(ra) # 80000c76 <release>
  return 0;
    800044e8:	4481                	li	s1,0
    800044ea:	a819                	j	80004500 <filealloc+0x5e>
      f->ref = 1;
    800044ec:	4785                	li	a5,1
    800044ee:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044f0:	0001d517          	auipc	a0,0x1d
    800044f4:	f6850513          	addi	a0,a0,-152 # 80021458 <ftable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	77e080e7          	jalr	1918(ra) # 80000c76 <release>
}
    80004500:	8526                	mv	a0,s1
    80004502:	60e2                	ld	ra,24(sp)
    80004504:	6442                	ld	s0,16(sp)
    80004506:	64a2                	ld	s1,8(sp)
    80004508:	6105                	addi	sp,sp,32
    8000450a:	8082                	ret

000000008000450c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000450c:	1101                	addi	sp,sp,-32
    8000450e:	ec06                	sd	ra,24(sp)
    80004510:	e822                	sd	s0,16(sp)
    80004512:	e426                	sd	s1,8(sp)
    80004514:	1000                	addi	s0,sp,32
    80004516:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004518:	0001d517          	auipc	a0,0x1d
    8000451c:	f4050513          	addi	a0,a0,-192 # 80021458 <ftable>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	6a2080e7          	jalr	1698(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004528:	40dc                	lw	a5,4(s1)
    8000452a:	02f05263          	blez	a5,8000454e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000452e:	2785                	addiw	a5,a5,1
    80004530:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004532:	0001d517          	auipc	a0,0x1d
    80004536:	f2650513          	addi	a0,a0,-218 # 80021458 <ftable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	73c080e7          	jalr	1852(ra) # 80000c76 <release>
  return f;
}
    80004542:	8526                	mv	a0,s1
    80004544:	60e2                	ld	ra,24(sp)
    80004546:	6442                	ld	s0,16(sp)
    80004548:	64a2                	ld	s1,8(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret
    panic("filedup");
    8000454e:	00004517          	auipc	a0,0x4
    80004552:	12250513          	addi	a0,a0,290 # 80008670 <syscalls+0x240>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	fd4080e7          	jalr	-44(ra) # 8000052a <panic>

000000008000455e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000455e:	7139                	addi	sp,sp,-64
    80004560:	fc06                	sd	ra,56(sp)
    80004562:	f822                	sd	s0,48(sp)
    80004564:	f426                	sd	s1,40(sp)
    80004566:	f04a                	sd	s2,32(sp)
    80004568:	ec4e                	sd	s3,24(sp)
    8000456a:	e852                	sd	s4,16(sp)
    8000456c:	e456                	sd	s5,8(sp)
    8000456e:	0080                	addi	s0,sp,64
    80004570:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004572:	0001d517          	auipc	a0,0x1d
    80004576:	ee650513          	addi	a0,a0,-282 # 80021458 <ftable>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	648080e7          	jalr	1608(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004582:	40dc                	lw	a5,4(s1)
    80004584:	06f05163          	blez	a5,800045e6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004588:	37fd                	addiw	a5,a5,-1
    8000458a:	0007871b          	sext.w	a4,a5
    8000458e:	c0dc                	sw	a5,4(s1)
    80004590:	06e04363          	bgtz	a4,800045f6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004594:	0004a903          	lw	s2,0(s1)
    80004598:	0094ca83          	lbu	s5,9(s1)
    8000459c:	0104ba03          	ld	s4,16(s1)
    800045a0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045a4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045a8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	eac50513          	addi	a0,a0,-340 # 80021458 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6c2080e7          	jalr	1730(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800045bc:	4785                	li	a5,1
    800045be:	04f90d63          	beq	s2,a5,80004618 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045c2:	3979                	addiw	s2,s2,-2
    800045c4:	4785                	li	a5,1
    800045c6:	0527e063          	bltu	a5,s2,80004606 <fileclose+0xa8>
    begin_op();
    800045ca:	00000097          	auipc	ra,0x0
    800045ce:	ac8080e7          	jalr	-1336(ra) # 80004092 <begin_op>
    iput(ff.ip);
    800045d2:	854e                	mv	a0,s3
    800045d4:	fffff097          	auipc	ra,0xfffff
    800045d8:	202080e7          	jalr	514(ra) # 800037d6 <iput>
    end_op();
    800045dc:	00000097          	auipc	ra,0x0
    800045e0:	b36080e7          	jalr	-1226(ra) # 80004112 <end_op>
    800045e4:	a00d                	j	80004606 <fileclose+0xa8>
    panic("fileclose");
    800045e6:	00004517          	auipc	a0,0x4
    800045ea:	09250513          	addi	a0,a0,146 # 80008678 <syscalls+0x248>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	f3c080e7          	jalr	-196(ra) # 8000052a <panic>
    release(&ftable.lock);
    800045f6:	0001d517          	auipc	a0,0x1d
    800045fa:	e6250513          	addi	a0,a0,-414 # 80021458 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	678080e7          	jalr	1656(ra) # 80000c76 <release>
  }
}
    80004606:	70e2                	ld	ra,56(sp)
    80004608:	7442                	ld	s0,48(sp)
    8000460a:	74a2                	ld	s1,40(sp)
    8000460c:	7902                	ld	s2,32(sp)
    8000460e:	69e2                	ld	s3,24(sp)
    80004610:	6a42                	ld	s4,16(sp)
    80004612:	6aa2                	ld	s5,8(sp)
    80004614:	6121                	addi	sp,sp,64
    80004616:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004618:	85d6                	mv	a1,s5
    8000461a:	8552                	mv	a0,s4
    8000461c:	00000097          	auipc	ra,0x0
    80004620:	35c080e7          	jalr	860(ra) # 80004978 <pipeclose>
    80004624:	b7cd                	j	80004606 <fileclose+0xa8>

0000000080004626 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004626:	715d                	addi	sp,sp,-80
    80004628:	e486                	sd	ra,72(sp)
    8000462a:	e0a2                	sd	s0,64(sp)
    8000462c:	fc26                	sd	s1,56(sp)
    8000462e:	f84a                	sd	s2,48(sp)
    80004630:	f44e                	sd	s3,40(sp)
    80004632:	0880                	addi	s0,sp,80
    80004634:	84aa                	mv	s1,a0
    80004636:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004638:	ffffd097          	auipc	ra,0xffffd
    8000463c:	34e080e7          	jalr	846(ra) # 80001986 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004640:	409c                	lw	a5,0(s1)
    80004642:	37f9                	addiw	a5,a5,-2
    80004644:	4705                	li	a4,1
    80004646:	04f76763          	bltu	a4,a5,80004694 <filestat+0x6e>
    8000464a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000464c:	6c88                	ld	a0,24(s1)
    8000464e:	fffff097          	auipc	ra,0xfffff
    80004652:	fce080e7          	jalr	-50(ra) # 8000361c <ilock>
    stati(f->ip, &st);
    80004656:	fb840593          	addi	a1,s0,-72
    8000465a:	6c88                	ld	a0,24(s1)
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	24a080e7          	jalr	586(ra) # 800038a6 <stati>
    iunlock(f->ip);
    80004664:	6c88                	ld	a0,24(s1)
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	078080e7          	jalr	120(ra) # 800036de <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000466e:	46e1                	li	a3,24
    80004670:	fb840613          	addi	a2,s0,-72
    80004674:	85ce                	mv	a1,s3
    80004676:	05093503          	ld	a0,80(s2)
    8000467a:	ffffd097          	auipc	ra,0xffffd
    8000467e:	fcc080e7          	jalr	-52(ra) # 80001646 <copyout>
    80004682:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004686:	60a6                	ld	ra,72(sp)
    80004688:	6406                	ld	s0,64(sp)
    8000468a:	74e2                	ld	s1,56(sp)
    8000468c:	7942                	ld	s2,48(sp)
    8000468e:	79a2                	ld	s3,40(sp)
    80004690:	6161                	addi	sp,sp,80
    80004692:	8082                	ret
  return -1;
    80004694:	557d                	li	a0,-1
    80004696:	bfc5                	j	80004686 <filestat+0x60>

0000000080004698 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004698:	7179                	addi	sp,sp,-48
    8000469a:	f406                	sd	ra,40(sp)
    8000469c:	f022                	sd	s0,32(sp)
    8000469e:	ec26                	sd	s1,24(sp)
    800046a0:	e84a                	sd	s2,16(sp)
    800046a2:	e44e                	sd	s3,8(sp)
    800046a4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046a6:	00854783          	lbu	a5,8(a0)
    800046aa:	c7d5                	beqz	a5,80004756 <fileread+0xbe>
    800046ac:	84aa                	mv	s1,a0
    800046ae:	89ae                	mv	s3,a1
    800046b0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046b2:	411c                	lw	a5,0(a0)
    800046b4:	4705                	li	a4,1
    800046b6:	04e78963          	beq	a5,a4,80004708 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046ba:	470d                	li	a4,3
    800046bc:	04e78d63          	beq	a5,a4,80004716 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(f->ip, 1, addr, f->off, n);
  } else if(f->type == FD_INODE){
    800046c0:	4709                	li	a4,2
    800046c2:	08e79263          	bne	a5,a4,80004746 <fileread+0xae>
    ilock(f->ip);
    800046c6:	6d08                	ld	a0,24(a0)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	f54080e7          	jalr	-172(ra) # 8000361c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046d0:	874a                	mv	a4,s2
    800046d2:	5094                	lw	a3,32(s1)
    800046d4:	864e                	mv	a2,s3
    800046d6:	4585                	li	a1,1
    800046d8:	6c88                	ld	a0,24(s1)
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	1f6080e7          	jalr	502(ra) # 800038d0 <readi>
    800046e2:	892a                	mv	s2,a0
    800046e4:	00a05563          	blez	a0,800046ee <fileread+0x56>
      f->off += r;
    800046e8:	509c                	lw	a5,32(s1)
    800046ea:	9fa9                	addw	a5,a5,a0
    800046ec:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046ee:	6c88                	ld	a0,24(s1)
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	fee080e7          	jalr	-18(ra) # 800036de <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046f8:	854a                	mv	a0,s2
    800046fa:	70a2                	ld	ra,40(sp)
    800046fc:	7402                	ld	s0,32(sp)
    800046fe:	64e2                	ld	s1,24(sp)
    80004700:	6942                	ld	s2,16(sp)
    80004702:	69a2                	ld	s3,8(sp)
    80004704:	6145                	addi	sp,sp,48
    80004706:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004708:	6908                	ld	a0,16(a0)
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	3d0080e7          	jalr	976(ra) # 80004ada <piperead>
    80004712:	892a                	mv	s2,a0
    80004714:	b7d5                	j	800046f8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004716:	02451783          	lh	a5,36(a0)
    8000471a:	03079693          	slli	a3,a5,0x30
    8000471e:	92c1                	srli	a3,a3,0x30
    80004720:	4725                	li	a4,9
    80004722:	02d76c63          	bltu	a4,a3,8000475a <fileread+0xc2>
    80004726:	0796                	slli	a5,a5,0x5
    80004728:	0001d717          	auipc	a4,0x1d
    8000472c:	bf070713          	addi	a4,a4,-1040 # 80021318 <devsw>
    80004730:	97ba                	add	a5,a5,a4
    80004732:	6b9c                	ld	a5,16(a5)
    80004734:	c78d                	beqz	a5,8000475e <fileread+0xc6>
    r = devsw[f->major].read(f->ip, 1, addr, f->off, n);
    80004736:	8732                	mv	a4,a2
    80004738:	5114                	lw	a3,32(a0)
    8000473a:	862e                	mv	a2,a1
    8000473c:	4585                	li	a1,1
    8000473e:	6d08                	ld	a0,24(a0)
    80004740:	9782                	jalr	a5
    80004742:	892a                	mv	s2,a0
    80004744:	bf55                	j	800046f8 <fileread+0x60>
    panic("fileread");
    80004746:	00004517          	auipc	a0,0x4
    8000474a:	f4250513          	addi	a0,a0,-190 # 80008688 <syscalls+0x258>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	ddc080e7          	jalr	-548(ra) # 8000052a <panic>
    return -1;
    80004756:	597d                	li	s2,-1
    80004758:	b745                	j	800046f8 <fileread+0x60>
      return -1;
    8000475a:	597d                	li	s2,-1
    8000475c:	bf71                	j	800046f8 <fileread+0x60>
    8000475e:	597d                	li	s2,-1
    80004760:	bf61                	j	800046f8 <fileread+0x60>

0000000080004762 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004762:	715d                	addi	sp,sp,-80
    80004764:	e486                	sd	ra,72(sp)
    80004766:	e0a2                	sd	s0,64(sp)
    80004768:	fc26                	sd	s1,56(sp)
    8000476a:	f84a                	sd	s2,48(sp)
    8000476c:	f44e                	sd	s3,40(sp)
    8000476e:	f052                	sd	s4,32(sp)
    80004770:	ec56                	sd	s5,24(sp)
    80004772:	e85a                	sd	s6,16(sp)
    80004774:	e45e                	sd	s7,8(sp)
    80004776:	e062                	sd	s8,0(sp)
    80004778:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000477a:	00954783          	lbu	a5,9(a0)
    8000477e:	10078a63          	beqz	a5,80004892 <filewrite+0x130>
    80004782:	892a                	mv	s2,a0
    80004784:	8aae                	mv	s5,a1
    80004786:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004788:	411c                	lw	a5,0(a0)
    8000478a:	4705                	li	a4,1
    8000478c:	02e78263          	beq	a5,a4,800047b0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004790:	470d                	li	a4,3
    80004792:	02e78663          	beq	a5,a4,800047be <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(f->ip, 1, addr, f->off, n);
  } else if(f->type == FD_INODE){
    80004796:	4709                	li	a4,2
    80004798:	0ee79563          	bne	a5,a4,80004882 <filewrite+0x120>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000479c:	0cc05163          	blez	a2,8000485e <filewrite+0xfc>
    int i = 0;
    800047a0:	4981                	li	s3,0
    800047a2:	6b05                	lui	s6,0x1
    800047a4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047a8:	6b85                	lui	s7,0x1
    800047aa:	c00b8b9b          	addiw	s7,s7,-1024
    800047ae:	a045                	j	8000484e <filewrite+0xec>
    ret = pipewrite(f->pipe, addr, n);
    800047b0:	6908                	ld	a0,16(a0)
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	236080e7          	jalr	566(ra) # 800049e8 <pipewrite>
    800047ba:	8a2a                	mv	s4,a0
    800047bc:	a065                	j	80004864 <filewrite+0x102>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047be:	02451783          	lh	a5,36(a0)
    800047c2:	03079693          	slli	a3,a5,0x30
    800047c6:	92c1                	srli	a3,a3,0x30
    800047c8:	4725                	li	a4,9
    800047ca:	0cd76663          	bltu	a4,a3,80004896 <filewrite+0x134>
    800047ce:	0796                	slli	a5,a5,0x5
    800047d0:	0001d717          	auipc	a4,0x1d
    800047d4:	b4870713          	addi	a4,a4,-1208 # 80021318 <devsw>
    800047d8:	97ba                	add	a5,a5,a4
    800047da:	6f9c                	ld	a5,24(a5)
    800047dc:	cfdd                	beqz	a5,8000489a <filewrite+0x138>
    ret = devsw[f->major].write(f->ip, 1, addr, f->off, n);
    800047de:	8732                	mv	a4,a2
    800047e0:	5114                	lw	a3,32(a0)
    800047e2:	862e                	mv	a2,a1
    800047e4:	4585                	li	a1,1
    800047e6:	6d08                	ld	a0,24(a0)
    800047e8:	9782                	jalr	a5
    800047ea:	8a2a                	mv	s4,a0
    800047ec:	a8a5                	j	80004864 <filewrite+0x102>
    800047ee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047f2:	00000097          	auipc	ra,0x0
    800047f6:	8a0080e7          	jalr	-1888(ra) # 80004092 <begin_op>
      ilock(f->ip);
    800047fa:	01893503          	ld	a0,24(s2)
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	e1e080e7          	jalr	-482(ra) # 8000361c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004806:	8762                	mv	a4,s8
    80004808:	02092683          	lw	a3,32(s2)
    8000480c:	01598633          	add	a2,s3,s5
    80004810:	4585                	li	a1,1
    80004812:	01893503          	ld	a0,24(s2)
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	1ea080e7          	jalr	490(ra) # 80003a00 <writei>
    8000481e:	84aa                	mv	s1,a0
    80004820:	00a05763          	blez	a0,8000482e <filewrite+0xcc>
        f->off += r;
    80004824:	02092783          	lw	a5,32(s2)
    80004828:	9fa9                	addw	a5,a5,a0
    8000482a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000482e:	01893503          	ld	a0,24(s2)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	eac080e7          	jalr	-340(ra) # 800036de <iunlock>
      end_op();
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	8d8080e7          	jalr	-1832(ra) # 80004112 <end_op>

      if(r != n1){
    80004842:	009c1f63          	bne	s8,s1,80004860 <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    80004846:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000484a:	0149db63          	bge	s3,s4,80004860 <filewrite+0xfe>
      int n1 = n - i;
    8000484e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004852:	84be                	mv	s1,a5
    80004854:	2781                	sext.w	a5,a5
    80004856:	f8fb5ce3          	bge	s6,a5,800047ee <filewrite+0x8c>
    8000485a:	84de                	mv	s1,s7
    8000485c:	bf49                	j	800047ee <filewrite+0x8c>
    int i = 0;
    8000485e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004860:	013a1f63          	bne	s4,s3,8000487e <filewrite+0x11c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004864:	8552                	mv	a0,s4
    80004866:	60a6                	ld	ra,72(sp)
    80004868:	6406                	ld	s0,64(sp)
    8000486a:	74e2                	ld	s1,56(sp)
    8000486c:	7942                	ld	s2,48(sp)
    8000486e:	79a2                	ld	s3,40(sp)
    80004870:	7a02                	ld	s4,32(sp)
    80004872:	6ae2                	ld	s5,24(sp)
    80004874:	6b42                	ld	s6,16(sp)
    80004876:	6ba2                	ld	s7,8(sp)
    80004878:	6c02                	ld	s8,0(sp)
    8000487a:	6161                	addi	sp,sp,80
    8000487c:	8082                	ret
    ret = (i == n ? n : -1);
    8000487e:	5a7d                	li	s4,-1
    80004880:	b7d5                	j	80004864 <filewrite+0x102>
    panic("filewrite");
    80004882:	00004517          	auipc	a0,0x4
    80004886:	e1650513          	addi	a0,a0,-490 # 80008698 <syscalls+0x268>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	ca0080e7          	jalr	-864(ra) # 8000052a <panic>
    return -1;
    80004892:	5a7d                	li	s4,-1
    80004894:	bfc1                	j	80004864 <filewrite+0x102>
      return -1;
    80004896:	5a7d                	li	s4,-1
    80004898:	b7f1                	j	80004864 <filewrite+0x102>
    8000489a:	5a7d                	li	s4,-1
    8000489c:	b7e1                	j	80004864 <filewrite+0x102>

000000008000489e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000489e:	7179                	addi	sp,sp,-48
    800048a0:	f406                	sd	ra,40(sp)
    800048a2:	f022                	sd	s0,32(sp)
    800048a4:	ec26                	sd	s1,24(sp)
    800048a6:	e84a                	sd	s2,16(sp)
    800048a8:	e44e                	sd	s3,8(sp)
    800048aa:	e052                	sd	s4,0(sp)
    800048ac:	1800                	addi	s0,sp,48
    800048ae:	84aa                	mv	s1,a0
    800048b0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048b2:	0005b023          	sd	zero,0(a1)
    800048b6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	be8080e7          	jalr	-1048(ra) # 800044a2 <filealloc>
    800048c2:	e088                	sd	a0,0(s1)
    800048c4:	c551                	beqz	a0,80004950 <pipealloc+0xb2>
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	bdc080e7          	jalr	-1060(ra) # 800044a2 <filealloc>
    800048ce:	00aa3023          	sd	a0,0(s4)
    800048d2:	c92d                	beqz	a0,80004944 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	1fe080e7          	jalr	510(ra) # 80000ad2 <kalloc>
    800048dc:	892a                	mv	s2,a0
    800048de:	c125                	beqz	a0,8000493e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048e0:	4985                	li	s3,1
    800048e2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048e6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048ea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048ee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048f2:	00004597          	auipc	a1,0x4
    800048f6:	db658593          	addi	a1,a1,-586 # 800086a8 <syscalls+0x278>
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	238080e7          	jalr	568(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004902:	609c                	ld	a5,0(s1)
    80004904:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004908:	609c                	ld	a5,0(s1)
    8000490a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000490e:	609c                	ld	a5,0(s1)
    80004910:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004914:	609c                	ld	a5,0(s1)
    80004916:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000491a:	000a3783          	ld	a5,0(s4)
    8000491e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004922:	000a3783          	ld	a5,0(s4)
    80004926:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000492a:	000a3783          	ld	a5,0(s4)
    8000492e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004932:	000a3783          	ld	a5,0(s4)
    80004936:	0127b823          	sd	s2,16(a5)
  return 0;
    8000493a:	4501                	li	a0,0
    8000493c:	a025                	j	80004964 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000493e:	6088                	ld	a0,0(s1)
    80004940:	e501                	bnez	a0,80004948 <pipealloc+0xaa>
    80004942:	a039                	j	80004950 <pipealloc+0xb2>
    80004944:	6088                	ld	a0,0(s1)
    80004946:	c51d                	beqz	a0,80004974 <pipealloc+0xd6>
    fileclose(*f0);
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	c16080e7          	jalr	-1002(ra) # 8000455e <fileclose>
  if(*f1)
    80004950:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004954:	557d                	li	a0,-1
  if(*f1)
    80004956:	c799                	beqz	a5,80004964 <pipealloc+0xc6>
    fileclose(*f1);
    80004958:	853e                	mv	a0,a5
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	c04080e7          	jalr	-1020(ra) # 8000455e <fileclose>
  return -1;
    80004962:	557d                	li	a0,-1
}
    80004964:	70a2                	ld	ra,40(sp)
    80004966:	7402                	ld	s0,32(sp)
    80004968:	64e2                	ld	s1,24(sp)
    8000496a:	6942                	ld	s2,16(sp)
    8000496c:	69a2                	ld	s3,8(sp)
    8000496e:	6a02                	ld	s4,0(sp)
    80004970:	6145                	addi	sp,sp,48
    80004972:	8082                	ret
  return -1;
    80004974:	557d                	li	a0,-1
    80004976:	b7fd                	j	80004964 <pipealloc+0xc6>

0000000080004978 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004978:	1101                	addi	sp,sp,-32
    8000497a:	ec06                	sd	ra,24(sp)
    8000497c:	e822                	sd	s0,16(sp)
    8000497e:	e426                	sd	s1,8(sp)
    80004980:	e04a                	sd	s2,0(sp)
    80004982:	1000                	addi	s0,sp,32
    80004984:	84aa                	mv	s1,a0
    80004986:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	23a080e7          	jalr	570(ra) # 80000bc2 <acquire>
  if(writable){
    80004990:	02090d63          	beqz	s2,800049ca <pipeclose+0x52>
    pi->writeopen = 0;
    80004994:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004998:	21848513          	addi	a0,s1,536
    8000499c:	ffffe097          	auipc	ra,0xffffe
    800049a0:	836080e7          	jalr	-1994(ra) # 800021d2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049a4:	2204b783          	ld	a5,544(s1)
    800049a8:	eb95                	bnez	a5,800049dc <pipeclose+0x64>
    release(&pi->lock);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2ca080e7          	jalr	714(ra) # 80000c76 <release>
    kfree((char*)pi);
    800049b4:	8526                	mv	a0,s1
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	020080e7          	jalr	32(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800049be:	60e2                	ld	ra,24(sp)
    800049c0:	6442                	ld	s0,16(sp)
    800049c2:	64a2                	ld	s1,8(sp)
    800049c4:	6902                	ld	s2,0(sp)
    800049c6:	6105                	addi	sp,sp,32
    800049c8:	8082                	ret
    pi->readopen = 0;
    800049ca:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049ce:	21c48513          	addi	a0,s1,540
    800049d2:	ffffe097          	auipc	ra,0xffffe
    800049d6:	800080e7          	jalr	-2048(ra) # 800021d2 <wakeup>
    800049da:	b7e9                	j	800049a4 <pipeclose+0x2c>
    release(&pi->lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	298080e7          	jalr	664(ra) # 80000c76 <release>
}
    800049e6:	bfe1                	j	800049be <pipeclose+0x46>

00000000800049e8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049e8:	711d                	addi	sp,sp,-96
    800049ea:	ec86                	sd	ra,88(sp)
    800049ec:	e8a2                	sd	s0,80(sp)
    800049ee:	e4a6                	sd	s1,72(sp)
    800049f0:	e0ca                	sd	s2,64(sp)
    800049f2:	fc4e                	sd	s3,56(sp)
    800049f4:	f852                	sd	s4,48(sp)
    800049f6:	f456                	sd	s5,40(sp)
    800049f8:	f05a                	sd	s6,32(sp)
    800049fa:	ec5e                	sd	s7,24(sp)
    800049fc:	e862                	sd	s8,16(sp)
    800049fe:	1080                	addi	s0,sp,96
    80004a00:	84aa                	mv	s1,a0
    80004a02:	8aae                	mv	s5,a1
    80004a04:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a06:	ffffd097          	auipc	ra,0xffffd
    80004a0a:	f80080e7          	jalr	-128(ra) # 80001986 <myproc>
    80004a0e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a10:	8526                	mv	a0,s1
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	1b0080e7          	jalr	432(ra) # 80000bc2 <acquire>
  while(i < n){
    80004a1a:	0b405363          	blez	s4,80004ac0 <pipewrite+0xd8>
  int i = 0;
    80004a1e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a20:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a22:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a26:	21c48b93          	addi	s7,s1,540
    80004a2a:	a089                	j	80004a6c <pipewrite+0x84>
      release(&pi->lock);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	248080e7          	jalr	584(ra) # 80000c76 <release>
      return -1;
    80004a36:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a38:	854a                	mv	a0,s2
    80004a3a:	60e6                	ld	ra,88(sp)
    80004a3c:	6446                	ld	s0,80(sp)
    80004a3e:	64a6                	ld	s1,72(sp)
    80004a40:	6906                	ld	s2,64(sp)
    80004a42:	79e2                	ld	s3,56(sp)
    80004a44:	7a42                	ld	s4,48(sp)
    80004a46:	7aa2                	ld	s5,40(sp)
    80004a48:	7b02                	ld	s6,32(sp)
    80004a4a:	6be2                	ld	s7,24(sp)
    80004a4c:	6c42                	ld	s8,16(sp)
    80004a4e:	6125                	addi	sp,sp,96
    80004a50:	8082                	ret
      wakeup(&pi->nread);
    80004a52:	8562                	mv	a0,s8
    80004a54:	ffffd097          	auipc	ra,0xffffd
    80004a58:	77e080e7          	jalr	1918(ra) # 800021d2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a5c:	85a6                	mv	a1,s1
    80004a5e:	855e                	mv	a0,s7
    80004a60:	ffffd097          	auipc	ra,0xffffd
    80004a64:	5e6080e7          	jalr	1510(ra) # 80002046 <sleep>
  while(i < n){
    80004a68:	05495d63          	bge	s2,s4,80004ac2 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004a6c:	2204a783          	lw	a5,544(s1)
    80004a70:	dfd5                	beqz	a5,80004a2c <pipewrite+0x44>
    80004a72:	0289a783          	lw	a5,40(s3)
    80004a76:	fbdd                	bnez	a5,80004a2c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a78:	2184a783          	lw	a5,536(s1)
    80004a7c:	21c4a703          	lw	a4,540(s1)
    80004a80:	2007879b          	addiw	a5,a5,512
    80004a84:	fcf707e3          	beq	a4,a5,80004a52 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a88:	4685                	li	a3,1
    80004a8a:	01590633          	add	a2,s2,s5
    80004a8e:	faf40593          	addi	a1,s0,-81
    80004a92:	0509b503          	ld	a0,80(s3)
    80004a96:	ffffd097          	auipc	ra,0xffffd
    80004a9a:	c3c080e7          	jalr	-964(ra) # 800016d2 <copyin>
    80004a9e:	03650263          	beq	a0,s6,80004ac2 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aa2:	21c4a783          	lw	a5,540(s1)
    80004aa6:	0017871b          	addiw	a4,a5,1
    80004aaa:	20e4ae23          	sw	a4,540(s1)
    80004aae:	1ff7f793          	andi	a5,a5,511
    80004ab2:	97a6                	add	a5,a5,s1
    80004ab4:	faf44703          	lbu	a4,-81(s0)
    80004ab8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004abc:	2905                	addiw	s2,s2,1
    80004abe:	b76d                	j	80004a68 <pipewrite+0x80>
  int i = 0;
    80004ac0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ac2:	21848513          	addi	a0,s1,536
    80004ac6:	ffffd097          	auipc	ra,0xffffd
    80004aca:	70c080e7          	jalr	1804(ra) # 800021d2 <wakeup>
  release(&pi->lock);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	1a6080e7          	jalr	422(ra) # 80000c76 <release>
  return i;
    80004ad8:	b785                	j	80004a38 <pipewrite+0x50>

0000000080004ada <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ada:	715d                	addi	sp,sp,-80
    80004adc:	e486                	sd	ra,72(sp)
    80004ade:	e0a2                	sd	s0,64(sp)
    80004ae0:	fc26                	sd	s1,56(sp)
    80004ae2:	f84a                	sd	s2,48(sp)
    80004ae4:	f44e                	sd	s3,40(sp)
    80004ae6:	f052                	sd	s4,32(sp)
    80004ae8:	ec56                	sd	s5,24(sp)
    80004aea:	e85a                	sd	s6,16(sp)
    80004aec:	0880                	addi	s0,sp,80
    80004aee:	84aa                	mv	s1,a0
    80004af0:	892e                	mv	s2,a1
    80004af2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	e92080e7          	jalr	-366(ra) # 80001986 <myproc>
    80004afc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004afe:	8526                	mv	a0,s1
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	0c2080e7          	jalr	194(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b08:	2184a703          	lw	a4,536(s1)
    80004b0c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b10:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b14:	02f71463          	bne	a4,a5,80004b3c <piperead+0x62>
    80004b18:	2244a783          	lw	a5,548(s1)
    80004b1c:	c385                	beqz	a5,80004b3c <piperead+0x62>
    if(pr->killed){
    80004b1e:	028a2783          	lw	a5,40(s4)
    80004b22:	ebc1                	bnez	a5,80004bb2 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b24:	85a6                	mv	a1,s1
    80004b26:	854e                	mv	a0,s3
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	51e080e7          	jalr	1310(ra) # 80002046 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b30:	2184a703          	lw	a4,536(s1)
    80004b34:	21c4a783          	lw	a5,540(s1)
    80004b38:	fef700e3          	beq	a4,a5,80004b18 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b3c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b3e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b40:	05505363          	blez	s5,80004b86 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b44:	2184a783          	lw	a5,536(s1)
    80004b48:	21c4a703          	lw	a4,540(s1)
    80004b4c:	02f70d63          	beq	a4,a5,80004b86 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b50:	0017871b          	addiw	a4,a5,1
    80004b54:	20e4ac23          	sw	a4,536(s1)
    80004b58:	1ff7f793          	andi	a5,a5,511
    80004b5c:	97a6                	add	a5,a5,s1
    80004b5e:	0187c783          	lbu	a5,24(a5)
    80004b62:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b66:	4685                	li	a3,1
    80004b68:	fbf40613          	addi	a2,s0,-65
    80004b6c:	85ca                	mv	a1,s2
    80004b6e:	050a3503          	ld	a0,80(s4)
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	ad4080e7          	jalr	-1324(ra) # 80001646 <copyout>
    80004b7a:	01650663          	beq	a0,s6,80004b86 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b7e:	2985                	addiw	s3,s3,1
    80004b80:	0905                	addi	s2,s2,1
    80004b82:	fd3a91e3          	bne	s5,s3,80004b44 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b86:	21c48513          	addi	a0,s1,540
    80004b8a:	ffffd097          	auipc	ra,0xffffd
    80004b8e:	648080e7          	jalr	1608(ra) # 800021d2 <wakeup>
  release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	0e2080e7          	jalr	226(ra) # 80000c76 <release>
  return i;
}
    80004b9c:	854e                	mv	a0,s3
    80004b9e:	60a6                	ld	ra,72(sp)
    80004ba0:	6406                	ld	s0,64(sp)
    80004ba2:	74e2                	ld	s1,56(sp)
    80004ba4:	7942                	ld	s2,48(sp)
    80004ba6:	79a2                	ld	s3,40(sp)
    80004ba8:	7a02                	ld	s4,32(sp)
    80004baa:	6ae2                	ld	s5,24(sp)
    80004bac:	6b42                	ld	s6,16(sp)
    80004bae:	6161                	addi	sp,sp,80
    80004bb0:	8082                	ret
      release(&pi->lock);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0c2080e7          	jalr	194(ra) # 80000c76 <release>
      return -1;
    80004bbc:	59fd                	li	s3,-1
    80004bbe:	bff9                	j	80004b9c <piperead+0xc2>

0000000080004bc0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bc0:	de010113          	addi	sp,sp,-544
    80004bc4:	20113c23          	sd	ra,536(sp)
    80004bc8:	20813823          	sd	s0,528(sp)
    80004bcc:	20913423          	sd	s1,520(sp)
    80004bd0:	21213023          	sd	s2,512(sp)
    80004bd4:	ffce                	sd	s3,504(sp)
    80004bd6:	fbd2                	sd	s4,496(sp)
    80004bd8:	f7d6                	sd	s5,488(sp)
    80004bda:	f3da                	sd	s6,480(sp)
    80004bdc:	efde                	sd	s7,472(sp)
    80004bde:	ebe2                	sd	s8,464(sp)
    80004be0:	e7e6                	sd	s9,456(sp)
    80004be2:	e3ea                	sd	s10,448(sp)
    80004be4:	ff6e                	sd	s11,440(sp)
    80004be6:	1400                	addi	s0,sp,544
    80004be8:	892a                	mv	s2,a0
    80004bea:	dea43423          	sd	a0,-536(s0)
    80004bee:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	d94080e7          	jalr	-620(ra) # 80001986 <myproc>
    80004bfa:	84aa                	mv	s1,a0

  begin_op();
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	496080e7          	jalr	1174(ra) # 80004092 <begin_op>

  if((ip = namei(path)) == 0){
    80004c04:	854a                	mv	a0,s2
    80004c06:	fffff097          	auipc	ra,0xfffff
    80004c0a:	26c080e7          	jalr	620(ra) # 80003e72 <namei>
    80004c0e:	c93d                	beqz	a0,80004c84 <exec+0xc4>
    80004c10:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	a0a080e7          	jalr	-1526(ra) # 8000361c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c1a:	04000713          	li	a4,64
    80004c1e:	4681                	li	a3,0
    80004c20:	e4840613          	addi	a2,s0,-440
    80004c24:	4581                	li	a1,0
    80004c26:	8556                	mv	a0,s5
    80004c28:	fffff097          	auipc	ra,0xfffff
    80004c2c:	ca8080e7          	jalr	-856(ra) # 800038d0 <readi>
    80004c30:	04000793          	li	a5,64
    80004c34:	00f51a63          	bne	a0,a5,80004c48 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c38:	e4842703          	lw	a4,-440(s0)
    80004c3c:	464c47b7          	lui	a5,0x464c4
    80004c40:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c44:	04f70663          	beq	a4,a5,80004c90 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c48:	8556                	mv	a0,s5
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	c34080e7          	jalr	-972(ra) # 8000387e <iunlockput>
    end_op();
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	4c0080e7          	jalr	1216(ra) # 80004112 <end_op>
  }
  return -1;
    80004c5a:	557d                	li	a0,-1
}
    80004c5c:	21813083          	ld	ra,536(sp)
    80004c60:	21013403          	ld	s0,528(sp)
    80004c64:	20813483          	ld	s1,520(sp)
    80004c68:	20013903          	ld	s2,512(sp)
    80004c6c:	79fe                	ld	s3,504(sp)
    80004c6e:	7a5e                	ld	s4,496(sp)
    80004c70:	7abe                	ld	s5,488(sp)
    80004c72:	7b1e                	ld	s6,480(sp)
    80004c74:	6bfe                	ld	s7,472(sp)
    80004c76:	6c5e                	ld	s8,464(sp)
    80004c78:	6cbe                	ld	s9,456(sp)
    80004c7a:	6d1e                	ld	s10,448(sp)
    80004c7c:	7dfa                	ld	s11,440(sp)
    80004c7e:	22010113          	addi	sp,sp,544
    80004c82:	8082                	ret
    end_op();
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	48e080e7          	jalr	1166(ra) # 80004112 <end_op>
    return -1;
    80004c8c:	557d                	li	a0,-1
    80004c8e:	b7f9                	j	80004c5c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c90:	8526                	mv	a0,s1
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	db8080e7          	jalr	-584(ra) # 80001a4a <proc_pagetable>
    80004c9a:	8b2a                	mv	s6,a0
    80004c9c:	d555                	beqz	a0,80004c48 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c9e:	e6842783          	lw	a5,-408(s0)
    80004ca2:	e8045703          	lhu	a4,-384(s0)
    80004ca6:	c735                	beqz	a4,80004d12 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ca8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004caa:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cae:	6a05                	lui	s4,0x1
    80004cb0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cb4:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004cb8:	6d85                	lui	s11,0x1
    80004cba:	7d7d                	lui	s10,0xfffff
    80004cbc:	ac1d                	j	80004ef2 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cbe:	00004517          	auipc	a0,0x4
    80004cc2:	9f250513          	addi	a0,a0,-1550 # 800086b0 <syscalls+0x280>
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	864080e7          	jalr	-1948(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cce:	874a                	mv	a4,s2
    80004cd0:	009c86bb          	addw	a3,s9,s1
    80004cd4:	4581                	li	a1,0
    80004cd6:	8556                	mv	a0,s5
    80004cd8:	fffff097          	auipc	ra,0xfffff
    80004cdc:	bf8080e7          	jalr	-1032(ra) # 800038d0 <readi>
    80004ce0:	2501                	sext.w	a0,a0
    80004ce2:	1aa91863          	bne	s2,a0,80004e92 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004ce6:	009d84bb          	addw	s1,s11,s1
    80004cea:	013d09bb          	addw	s3,s10,s3
    80004cee:	1f74f263          	bgeu	s1,s7,80004ed2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004cf2:	02049593          	slli	a1,s1,0x20
    80004cf6:	9181                	srli	a1,a1,0x20
    80004cf8:	95e2                	add	a1,a1,s8
    80004cfa:	855a                	mv	a0,s6
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	358080e7          	jalr	856(ra) # 80001054 <walkaddr>
    80004d04:	862a                	mv	a2,a0
    if(pa == 0)
    80004d06:	dd45                	beqz	a0,80004cbe <exec+0xfe>
      n = PGSIZE;
    80004d08:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d0a:	fd49f2e3          	bgeu	s3,s4,80004cce <exec+0x10e>
      n = sz - i;
    80004d0e:	894e                	mv	s2,s3
    80004d10:	bf7d                	j	80004cce <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d12:	4481                	li	s1,0
  iunlockput(ip);
    80004d14:	8556                	mv	a0,s5
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	b68080e7          	jalr	-1176(ra) # 8000387e <iunlockput>
  end_op();
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	3f4080e7          	jalr	1012(ra) # 80004112 <end_op>
  p = myproc();
    80004d26:	ffffd097          	auipc	ra,0xffffd
    80004d2a:	c60080e7          	jalr	-928(ra) # 80001986 <myproc>
    80004d2e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d30:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d34:	6785                	lui	a5,0x1
    80004d36:	17fd                	addi	a5,a5,-1
    80004d38:	94be                	add	s1,s1,a5
    80004d3a:	77fd                	lui	a5,0xfffff
    80004d3c:	8fe5                	and	a5,a5,s1
    80004d3e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d42:	6609                	lui	a2,0x2
    80004d44:	963e                	add	a2,a2,a5
    80004d46:	85be                	mv	a1,a5
    80004d48:	855a                	mv	a0,s6
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	6ac080e7          	jalr	1708(ra) # 800013f6 <uvmalloc>
    80004d52:	8c2a                	mv	s8,a0
  ip = 0;
    80004d54:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d56:	12050e63          	beqz	a0,80004e92 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d5a:	75f9                	lui	a1,0xffffe
    80004d5c:	95aa                	add	a1,a1,a0
    80004d5e:	855a                	mv	a0,s6
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	8b4080e7          	jalr	-1868(ra) # 80001614 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d68:	7afd                	lui	s5,0xfffff
    80004d6a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d6c:	df043783          	ld	a5,-528(s0)
    80004d70:	6388                	ld	a0,0(a5)
    80004d72:	c925                	beqz	a0,80004de2 <exec+0x222>
    80004d74:	e8840993          	addi	s3,s0,-376
    80004d78:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d7c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d7e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	0c2080e7          	jalr	194(ra) # 80000e42 <strlen>
    80004d88:	0015079b          	addiw	a5,a0,1
    80004d8c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d90:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d94:	13596363          	bltu	s2,s5,80004eba <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d98:	df043d83          	ld	s11,-528(s0)
    80004d9c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004da0:	8552                	mv	a0,s4
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	0a0080e7          	jalr	160(ra) # 80000e42 <strlen>
    80004daa:	0015069b          	addiw	a3,a0,1
    80004dae:	8652                	mv	a2,s4
    80004db0:	85ca                	mv	a1,s2
    80004db2:	855a                	mv	a0,s6
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	892080e7          	jalr	-1902(ra) # 80001646 <copyout>
    80004dbc:	10054363          	bltz	a0,80004ec2 <exec+0x302>
    ustack[argc] = sp;
    80004dc0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dc4:	0485                	addi	s1,s1,1
    80004dc6:	008d8793          	addi	a5,s11,8
    80004dca:	def43823          	sd	a5,-528(s0)
    80004dce:	008db503          	ld	a0,8(s11)
    80004dd2:	c911                	beqz	a0,80004de6 <exec+0x226>
    if(argc >= MAXARG)
    80004dd4:	09a1                	addi	s3,s3,8
    80004dd6:	fb3c95e3          	bne	s9,s3,80004d80 <exec+0x1c0>
  sz = sz1;
    80004dda:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dde:	4a81                	li	s5,0
    80004de0:	a84d                	j	80004e92 <exec+0x2d2>
  sp = sz;
    80004de2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004de4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004de6:	00349793          	slli	a5,s1,0x3
    80004dea:	f9040713          	addi	a4,s0,-112
    80004dee:	97ba                	add	a5,a5,a4
    80004df0:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004df4:	00148693          	addi	a3,s1,1
    80004df8:	068e                	slli	a3,a3,0x3
    80004dfa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dfe:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e02:	01597663          	bgeu	s2,s5,80004e0e <exec+0x24e>
  sz = sz1;
    80004e06:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e0a:	4a81                	li	s5,0
    80004e0c:	a059                	j	80004e92 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e0e:	e8840613          	addi	a2,s0,-376
    80004e12:	85ca                	mv	a1,s2
    80004e14:	855a                	mv	a0,s6
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	830080e7          	jalr	-2000(ra) # 80001646 <copyout>
    80004e1e:	0a054663          	bltz	a0,80004eca <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e22:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e26:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e2a:	de843783          	ld	a5,-536(s0)
    80004e2e:	0007c703          	lbu	a4,0(a5)
    80004e32:	cf11                	beqz	a4,80004e4e <exec+0x28e>
    80004e34:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e36:	02f00693          	li	a3,47
    80004e3a:	a039                	j	80004e48 <exec+0x288>
      last = s+1;
    80004e3c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e40:	0785                	addi	a5,a5,1
    80004e42:	fff7c703          	lbu	a4,-1(a5)
    80004e46:	c701                	beqz	a4,80004e4e <exec+0x28e>
    if(*s == '/')
    80004e48:	fed71ce3          	bne	a4,a3,80004e40 <exec+0x280>
    80004e4c:	bfc5                	j	80004e3c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e4e:	4641                	li	a2,16
    80004e50:	de843583          	ld	a1,-536(s0)
    80004e54:	158b8513          	addi	a0,s7,344
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	fb8080e7          	jalr	-72(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e60:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e64:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e68:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e6c:	058bb783          	ld	a5,88(s7)
    80004e70:	e6043703          	ld	a4,-416(s0)
    80004e74:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e76:	058bb783          	ld	a5,88(s7)
    80004e7a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e7e:	85ea                	mv	a1,s10
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	c66080e7          	jalr	-922(ra) # 80001ae6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e88:	0004851b          	sext.w	a0,s1
    80004e8c:	bbc1                	j	80004c5c <exec+0x9c>
    80004e8e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e92:	df843583          	ld	a1,-520(s0)
    80004e96:	855a                	mv	a0,s6
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	c4e080e7          	jalr	-946(ra) # 80001ae6 <proc_freepagetable>
  if(ip){
    80004ea0:	da0a94e3          	bnez	s5,80004c48 <exec+0x88>
  return -1;
    80004ea4:	557d                	li	a0,-1
    80004ea6:	bb5d                	j	80004c5c <exec+0x9c>
    80004ea8:	de943c23          	sd	s1,-520(s0)
    80004eac:	b7dd                	j	80004e92 <exec+0x2d2>
    80004eae:	de943c23          	sd	s1,-520(s0)
    80004eb2:	b7c5                	j	80004e92 <exec+0x2d2>
    80004eb4:	de943c23          	sd	s1,-520(s0)
    80004eb8:	bfe9                	j	80004e92 <exec+0x2d2>
  sz = sz1;
    80004eba:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ebe:	4a81                	li	s5,0
    80004ec0:	bfc9                	j	80004e92 <exec+0x2d2>
  sz = sz1;
    80004ec2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec6:	4a81                	li	s5,0
    80004ec8:	b7e9                	j	80004e92 <exec+0x2d2>
  sz = sz1;
    80004eca:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ece:	4a81                	li	s5,0
    80004ed0:	b7c9                	j	80004e92 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ed2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed6:	e0843783          	ld	a5,-504(s0)
    80004eda:	0017869b          	addiw	a3,a5,1
    80004ede:	e0d43423          	sd	a3,-504(s0)
    80004ee2:	e0043783          	ld	a5,-512(s0)
    80004ee6:	0387879b          	addiw	a5,a5,56
    80004eea:	e8045703          	lhu	a4,-384(s0)
    80004eee:	e2e6d3e3          	bge	a3,a4,80004d14 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ef2:	2781                	sext.w	a5,a5
    80004ef4:	e0f43023          	sd	a5,-512(s0)
    80004ef8:	03800713          	li	a4,56
    80004efc:	86be                	mv	a3,a5
    80004efe:	e1040613          	addi	a2,s0,-496
    80004f02:	4581                	li	a1,0
    80004f04:	8556                	mv	a0,s5
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	9ca080e7          	jalr	-1590(ra) # 800038d0 <readi>
    80004f0e:	03800793          	li	a5,56
    80004f12:	f6f51ee3          	bne	a0,a5,80004e8e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f16:	e1042783          	lw	a5,-496(s0)
    80004f1a:	4705                	li	a4,1
    80004f1c:	fae79de3          	bne	a5,a4,80004ed6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f20:	e3843603          	ld	a2,-456(s0)
    80004f24:	e3043783          	ld	a5,-464(s0)
    80004f28:	f8f660e3          	bltu	a2,a5,80004ea8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f2c:	e2043783          	ld	a5,-480(s0)
    80004f30:	963e                	add	a2,a2,a5
    80004f32:	f6f66ee3          	bltu	a2,a5,80004eae <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f36:	85a6                	mv	a1,s1
    80004f38:	855a                	mv	a0,s6
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	4bc080e7          	jalr	1212(ra) # 800013f6 <uvmalloc>
    80004f42:	dea43c23          	sd	a0,-520(s0)
    80004f46:	d53d                	beqz	a0,80004eb4 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f48:	e2043c03          	ld	s8,-480(s0)
    80004f4c:	de043783          	ld	a5,-544(s0)
    80004f50:	00fc77b3          	and	a5,s8,a5
    80004f54:	ff9d                	bnez	a5,80004e92 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f56:	e1842c83          	lw	s9,-488(s0)
    80004f5a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f5e:	f60b8ae3          	beqz	s7,80004ed2 <exec+0x312>
    80004f62:	89de                	mv	s3,s7
    80004f64:	4481                	li	s1,0
    80004f66:	b371                	j	80004cf2 <exec+0x132>

0000000080004f68 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f68:	7179                	addi	sp,sp,-48
    80004f6a:	f406                	sd	ra,40(sp)
    80004f6c:	f022                	sd	s0,32(sp)
    80004f6e:	ec26                	sd	s1,24(sp)
    80004f70:	e84a                	sd	s2,16(sp)
    80004f72:	1800                	addi	s0,sp,48
    80004f74:	892e                	mv	s2,a1
    80004f76:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f78:	fdc40593          	addi	a1,s0,-36
    80004f7c:	ffffe097          	auipc	ra,0xffffe
    80004f80:	b2e080e7          	jalr	-1234(ra) # 80002aaa <argint>
    80004f84:	04054063          	bltz	a0,80004fc4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f88:	fdc42703          	lw	a4,-36(s0)
    80004f8c:	47bd                	li	a5,15
    80004f8e:	02e7ed63          	bltu	a5,a4,80004fc8 <argfd+0x60>
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	9f4080e7          	jalr	-1548(ra) # 80001986 <myproc>
    80004f9a:	fdc42703          	lw	a4,-36(s0)
    80004f9e:	01a70793          	addi	a5,a4,26
    80004fa2:	078e                	slli	a5,a5,0x3
    80004fa4:	953e                	add	a0,a0,a5
    80004fa6:	611c                	ld	a5,0(a0)
    80004fa8:	c395                	beqz	a5,80004fcc <argfd+0x64>
    return -1;
  if(pfd)
    80004faa:	00090463          	beqz	s2,80004fb2 <argfd+0x4a>
    *pfd = fd;
    80004fae:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fb2:	4501                	li	a0,0
  if(pf)
    80004fb4:	c091                	beqz	s1,80004fb8 <argfd+0x50>
    *pf = f;
    80004fb6:	e09c                	sd	a5,0(s1)
}
    80004fb8:	70a2                	ld	ra,40(sp)
    80004fba:	7402                	ld	s0,32(sp)
    80004fbc:	64e2                	ld	s1,24(sp)
    80004fbe:	6942                	ld	s2,16(sp)
    80004fc0:	6145                	addi	sp,sp,48
    80004fc2:	8082                	ret
    return -1;
    80004fc4:	557d                	li	a0,-1
    80004fc6:	bfcd                	j	80004fb8 <argfd+0x50>
    return -1;
    80004fc8:	557d                	li	a0,-1
    80004fca:	b7fd                	j	80004fb8 <argfd+0x50>
    80004fcc:	557d                	li	a0,-1
    80004fce:	b7ed                	j	80004fb8 <argfd+0x50>

0000000080004fd0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fd0:	1101                	addi	sp,sp,-32
    80004fd2:	ec06                	sd	ra,24(sp)
    80004fd4:	e822                	sd	s0,16(sp)
    80004fd6:	e426                	sd	s1,8(sp)
    80004fd8:	1000                	addi	s0,sp,32
    80004fda:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	9aa080e7          	jalr	-1622(ra) # 80001986 <myproc>
    80004fe4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fe6:	0d050793          	addi	a5,a0,208
    80004fea:	4501                	li	a0,0
    80004fec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fee:	6398                	ld	a4,0(a5)
    80004ff0:	cb19                	beqz	a4,80005006 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ff2:	2505                	addiw	a0,a0,1
    80004ff4:	07a1                	addi	a5,a5,8
    80004ff6:	fed51ce3          	bne	a0,a3,80004fee <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ffa:	557d                	li	a0,-1
}
    80004ffc:	60e2                	ld	ra,24(sp)
    80004ffe:	6442                	ld	s0,16(sp)
    80005000:	64a2                	ld	s1,8(sp)
    80005002:	6105                	addi	sp,sp,32
    80005004:	8082                	ret
      p->ofile[fd] = f;
    80005006:	01a50793          	addi	a5,a0,26
    8000500a:	078e                	slli	a5,a5,0x3
    8000500c:	963e                	add	a2,a2,a5
    8000500e:	e204                	sd	s1,0(a2)
      return fd;
    80005010:	b7f5                	j	80004ffc <fdalloc+0x2c>

0000000080005012 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005012:	715d                	addi	sp,sp,-80
    80005014:	e486                	sd	ra,72(sp)
    80005016:	e0a2                	sd	s0,64(sp)
    80005018:	fc26                	sd	s1,56(sp)
    8000501a:	f84a                	sd	s2,48(sp)
    8000501c:	f44e                	sd	s3,40(sp)
    8000501e:	f052                	sd	s4,32(sp)
    80005020:	ec56                	sd	s5,24(sp)
    80005022:	0880                	addi	s0,sp,80
    80005024:	89ae                	mv	s3,a1
    80005026:	8ab2                	mv	s5,a2
    80005028:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000502a:	fb040593          	addi	a1,s0,-80
    8000502e:	fffff097          	auipc	ra,0xfffff
    80005032:	e62080e7          	jalr	-414(ra) # 80003e90 <nameiparent>
    80005036:	892a                	mv	s2,a0
    80005038:	12050e63          	beqz	a0,80005174 <create+0x162>
    return 0;

  ilock(dp);
    8000503c:	ffffe097          	auipc	ra,0xffffe
    80005040:	5e0080e7          	jalr	1504(ra) # 8000361c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005044:	4601                	li	a2,0
    80005046:	fb040593          	addi	a1,s0,-80
    8000504a:	854a                	mv	a0,s2
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	aec080e7          	jalr	-1300(ra) # 80003b38 <dirlookup>
    80005054:	84aa                	mv	s1,a0
    80005056:	c921                	beqz	a0,800050a6 <create+0x94>
    iunlockput(dp);
    80005058:	854a                	mv	a0,s2
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	824080e7          	jalr	-2012(ra) # 8000387e <iunlockput>
    ilock(ip);
    80005062:	8526                	mv	a0,s1
    80005064:	ffffe097          	auipc	ra,0xffffe
    80005068:	5b8080e7          	jalr	1464(ra) # 8000361c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000506c:	2981                	sext.w	s3,s3
    8000506e:	4789                	li	a5,2
    80005070:	02f99463          	bne	s3,a5,80005098 <create+0x86>
    80005074:	0444d783          	lhu	a5,68(s1)
    80005078:	37f9                	addiw	a5,a5,-2
    8000507a:	17c2                	slli	a5,a5,0x30
    8000507c:	93c1                	srli	a5,a5,0x30
    8000507e:	4705                	li	a4,1
    80005080:	00f76c63          	bltu	a4,a5,80005098 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005084:	8526                	mv	a0,s1
    80005086:	60a6                	ld	ra,72(sp)
    80005088:	6406                	ld	s0,64(sp)
    8000508a:	74e2                	ld	s1,56(sp)
    8000508c:	7942                	ld	s2,48(sp)
    8000508e:	79a2                	ld	s3,40(sp)
    80005090:	7a02                	ld	s4,32(sp)
    80005092:	6ae2                	ld	s5,24(sp)
    80005094:	6161                	addi	sp,sp,80
    80005096:	8082                	ret
    iunlockput(ip);
    80005098:	8526                	mv	a0,s1
    8000509a:	ffffe097          	auipc	ra,0xffffe
    8000509e:	7e4080e7          	jalr	2020(ra) # 8000387e <iunlockput>
    return 0;
    800050a2:	4481                	li	s1,0
    800050a4:	b7c5                	j	80005084 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050a6:	85ce                	mv	a1,s3
    800050a8:	00092503          	lw	a0,0(s2)
    800050ac:	ffffe097          	auipc	ra,0xffffe
    800050b0:	3d8080e7          	jalr	984(ra) # 80003484 <ialloc>
    800050b4:	84aa                	mv	s1,a0
    800050b6:	c521                	beqz	a0,800050fe <create+0xec>
  ilock(ip);
    800050b8:	ffffe097          	auipc	ra,0xffffe
    800050bc:	564080e7          	jalr	1380(ra) # 8000361c <ilock>
  ip->major = major;
    800050c0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050c4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050c8:	4a05                	li	s4,1
    800050ca:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050ce:	8526                	mv	a0,s1
    800050d0:	ffffe097          	auipc	ra,0xffffe
    800050d4:	482080e7          	jalr	1154(ra) # 80003552 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050d8:	2981                	sext.w	s3,s3
    800050da:	03498a63          	beq	s3,s4,8000510e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800050de:	40d0                	lw	a2,4(s1)
    800050e0:	fb040593          	addi	a1,s0,-80
    800050e4:	854a                	mv	a0,s2
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	cca080e7          	jalr	-822(ra) # 80003db0 <dirlink>
    800050ee:	06054b63          	bltz	a0,80005164 <create+0x152>
  iunlockput(dp);
    800050f2:	854a                	mv	a0,s2
    800050f4:	ffffe097          	auipc	ra,0xffffe
    800050f8:	78a080e7          	jalr	1930(ra) # 8000387e <iunlockput>
  return ip;
    800050fc:	b761                	j	80005084 <create+0x72>
    panic("create: ialloc");
    800050fe:	00003517          	auipc	a0,0x3
    80005102:	5d250513          	addi	a0,a0,1490 # 800086d0 <syscalls+0x2a0>
    80005106:	ffffb097          	auipc	ra,0xffffb
    8000510a:	424080e7          	jalr	1060(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000510e:	04a95783          	lhu	a5,74(s2)
    80005112:	2785                	addiw	a5,a5,1
    80005114:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005118:	854a                	mv	a0,s2
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	438080e7          	jalr	1080(ra) # 80003552 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005122:	40d0                	lw	a2,4(s1)
    80005124:	00003597          	auipc	a1,0x3
    80005128:	5bc58593          	addi	a1,a1,1468 # 800086e0 <syscalls+0x2b0>
    8000512c:	8526                	mv	a0,s1
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	c82080e7          	jalr	-894(ra) # 80003db0 <dirlink>
    80005136:	00054f63          	bltz	a0,80005154 <create+0x142>
    8000513a:	00492603          	lw	a2,4(s2)
    8000513e:	00003597          	auipc	a1,0x3
    80005142:	5aa58593          	addi	a1,a1,1450 # 800086e8 <syscalls+0x2b8>
    80005146:	8526                	mv	a0,s1
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	c68080e7          	jalr	-920(ra) # 80003db0 <dirlink>
    80005150:	f80557e3          	bgez	a0,800050de <create+0xcc>
      panic("create dots");
    80005154:	00003517          	auipc	a0,0x3
    80005158:	59c50513          	addi	a0,a0,1436 # 800086f0 <syscalls+0x2c0>
    8000515c:	ffffb097          	auipc	ra,0xffffb
    80005160:	3ce080e7          	jalr	974(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005164:	00003517          	auipc	a0,0x3
    80005168:	59c50513          	addi	a0,a0,1436 # 80008700 <syscalls+0x2d0>
    8000516c:	ffffb097          	auipc	ra,0xffffb
    80005170:	3be080e7          	jalr	958(ra) # 8000052a <panic>
    return 0;
    80005174:	84aa                	mv	s1,a0
    80005176:	b739                	j	80005084 <create+0x72>

0000000080005178 <sys_dup>:
{
    80005178:	7179                	addi	sp,sp,-48
    8000517a:	f406                	sd	ra,40(sp)
    8000517c:	f022                	sd	s0,32(sp)
    8000517e:	ec26                	sd	s1,24(sp)
    80005180:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005182:	fd840613          	addi	a2,s0,-40
    80005186:	4581                	li	a1,0
    80005188:	4501                	li	a0,0
    8000518a:	00000097          	auipc	ra,0x0
    8000518e:	dde080e7          	jalr	-546(ra) # 80004f68 <argfd>
    return -1;
    80005192:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005194:	02054363          	bltz	a0,800051ba <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005198:	fd843503          	ld	a0,-40(s0)
    8000519c:	00000097          	auipc	ra,0x0
    800051a0:	e34080e7          	jalr	-460(ra) # 80004fd0 <fdalloc>
    800051a4:	84aa                	mv	s1,a0
    return -1;
    800051a6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051a8:	00054963          	bltz	a0,800051ba <sys_dup+0x42>
  filedup(f);
    800051ac:	fd843503          	ld	a0,-40(s0)
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	35c080e7          	jalr	860(ra) # 8000450c <filedup>
  return fd;
    800051b8:	87a6                	mv	a5,s1
}
    800051ba:	853e                	mv	a0,a5
    800051bc:	70a2                	ld	ra,40(sp)
    800051be:	7402                	ld	s0,32(sp)
    800051c0:	64e2                	ld	s1,24(sp)
    800051c2:	6145                	addi	sp,sp,48
    800051c4:	8082                	ret

00000000800051c6 <sys_read>:
{
    800051c6:	7179                	addi	sp,sp,-48
    800051c8:	f406                	sd	ra,40(sp)
    800051ca:	f022                	sd	s0,32(sp)
    800051cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ce:	fe840613          	addi	a2,s0,-24
    800051d2:	4581                	li	a1,0
    800051d4:	4501                	li	a0,0
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	d92080e7          	jalr	-622(ra) # 80004f68 <argfd>
    return -1;
    800051de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e0:	04054163          	bltz	a0,80005222 <sys_read+0x5c>
    800051e4:	fe440593          	addi	a1,s0,-28
    800051e8:	4509                	li	a0,2
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	8c0080e7          	jalr	-1856(ra) # 80002aaa <argint>
    return -1;
    800051f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f4:	02054763          	bltz	a0,80005222 <sys_read+0x5c>
    800051f8:	fd840593          	addi	a1,s0,-40
    800051fc:	4505                	li	a0,1
    800051fe:	ffffe097          	auipc	ra,0xffffe
    80005202:	8ce080e7          	jalr	-1842(ra) # 80002acc <argaddr>
    return -1;
    80005206:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005208:	00054d63          	bltz	a0,80005222 <sys_read+0x5c>
  return fileread(f, p, n);
    8000520c:	fe442603          	lw	a2,-28(s0)
    80005210:	fd843583          	ld	a1,-40(s0)
    80005214:	fe843503          	ld	a0,-24(s0)
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	480080e7          	jalr	1152(ra) # 80004698 <fileread>
    80005220:	87aa                	mv	a5,a0
}
    80005222:	853e                	mv	a0,a5
    80005224:	70a2                	ld	ra,40(sp)
    80005226:	7402                	ld	s0,32(sp)
    80005228:	6145                	addi	sp,sp,48
    8000522a:	8082                	ret

000000008000522c <sys_write>:
{
    8000522c:	7179                	addi	sp,sp,-48
    8000522e:	f406                	sd	ra,40(sp)
    80005230:	f022                	sd	s0,32(sp)
    80005232:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005234:	fe840613          	addi	a2,s0,-24
    80005238:	4581                	li	a1,0
    8000523a:	4501                	li	a0,0
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	d2c080e7          	jalr	-724(ra) # 80004f68 <argfd>
    return -1;
    80005244:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005246:	04054163          	bltz	a0,80005288 <sys_write+0x5c>
    8000524a:	fe440593          	addi	a1,s0,-28
    8000524e:	4509                	li	a0,2
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	85a080e7          	jalr	-1958(ra) # 80002aaa <argint>
    return -1;
    80005258:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525a:	02054763          	bltz	a0,80005288 <sys_write+0x5c>
    8000525e:	fd840593          	addi	a1,s0,-40
    80005262:	4505                	li	a0,1
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	868080e7          	jalr	-1944(ra) # 80002acc <argaddr>
    return -1;
    8000526c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526e:	00054d63          	bltz	a0,80005288 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005272:	fe442603          	lw	a2,-28(s0)
    80005276:	fd843583          	ld	a1,-40(s0)
    8000527a:	fe843503          	ld	a0,-24(s0)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	4e4080e7          	jalr	1252(ra) # 80004762 <filewrite>
    80005286:	87aa                	mv	a5,a0
}
    80005288:	853e                	mv	a0,a5
    8000528a:	70a2                	ld	ra,40(sp)
    8000528c:	7402                	ld	s0,32(sp)
    8000528e:	6145                	addi	sp,sp,48
    80005290:	8082                	ret

0000000080005292 <sys_close>:
{
    80005292:	1101                	addi	sp,sp,-32
    80005294:	ec06                	sd	ra,24(sp)
    80005296:	e822                	sd	s0,16(sp)
    80005298:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000529a:	fe040613          	addi	a2,s0,-32
    8000529e:	fec40593          	addi	a1,s0,-20
    800052a2:	4501                	li	a0,0
    800052a4:	00000097          	auipc	ra,0x0
    800052a8:	cc4080e7          	jalr	-828(ra) # 80004f68 <argfd>
    return -1;
    800052ac:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052ae:	02054463          	bltz	a0,800052d6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052b2:	ffffc097          	auipc	ra,0xffffc
    800052b6:	6d4080e7          	jalr	1748(ra) # 80001986 <myproc>
    800052ba:	fec42783          	lw	a5,-20(s0)
    800052be:	07e9                	addi	a5,a5,26
    800052c0:	078e                	slli	a5,a5,0x3
    800052c2:	97aa                	add	a5,a5,a0
    800052c4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052c8:	fe043503          	ld	a0,-32(s0)
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	292080e7          	jalr	658(ra) # 8000455e <fileclose>
  return 0;
    800052d4:	4781                	li	a5,0
}
    800052d6:	853e                	mv	a0,a5
    800052d8:	60e2                	ld	ra,24(sp)
    800052da:	6442                	ld	s0,16(sp)
    800052dc:	6105                	addi	sp,sp,32
    800052de:	8082                	ret

00000000800052e0 <sys_fstat>:
{
    800052e0:	1101                	addi	sp,sp,-32
    800052e2:	ec06                	sd	ra,24(sp)
    800052e4:	e822                	sd	s0,16(sp)
    800052e6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052e8:	fe840613          	addi	a2,s0,-24
    800052ec:	4581                	li	a1,0
    800052ee:	4501                	li	a0,0
    800052f0:	00000097          	auipc	ra,0x0
    800052f4:	c78080e7          	jalr	-904(ra) # 80004f68 <argfd>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052fa:	02054563          	bltz	a0,80005324 <sys_fstat+0x44>
    800052fe:	fe040593          	addi	a1,s0,-32
    80005302:	4505                	li	a0,1
    80005304:	ffffd097          	auipc	ra,0xffffd
    80005308:	7c8080e7          	jalr	1992(ra) # 80002acc <argaddr>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000530e:	00054b63          	bltz	a0,80005324 <sys_fstat+0x44>
  return filestat(f, st);
    80005312:	fe043583          	ld	a1,-32(s0)
    80005316:	fe843503          	ld	a0,-24(s0)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	30c080e7          	jalr	780(ra) # 80004626 <filestat>
    80005322:	87aa                	mv	a5,a0
}
    80005324:	853e                	mv	a0,a5
    80005326:	60e2                	ld	ra,24(sp)
    80005328:	6442                	ld	s0,16(sp)
    8000532a:	6105                	addi	sp,sp,32
    8000532c:	8082                	ret

000000008000532e <sys_link>:
{
    8000532e:	7169                	addi	sp,sp,-304
    80005330:	f606                	sd	ra,296(sp)
    80005332:	f222                	sd	s0,288(sp)
    80005334:	ee26                	sd	s1,280(sp)
    80005336:	ea4a                	sd	s2,272(sp)
    80005338:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533a:	08000613          	li	a2,128
    8000533e:	ed040593          	addi	a1,s0,-304
    80005342:	4501                	li	a0,0
    80005344:	ffffd097          	auipc	ra,0xffffd
    80005348:	7aa080e7          	jalr	1962(ra) # 80002aee <argstr>
    return -1;
    8000534c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000534e:	10054e63          	bltz	a0,8000546a <sys_link+0x13c>
    80005352:	08000613          	li	a2,128
    80005356:	f5040593          	addi	a1,s0,-176
    8000535a:	4505                	li	a0,1
    8000535c:	ffffd097          	auipc	ra,0xffffd
    80005360:	792080e7          	jalr	1938(ra) # 80002aee <argstr>
    return -1;
    80005364:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005366:	10054263          	bltz	a0,8000546a <sys_link+0x13c>
  begin_op();
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	d28080e7          	jalr	-728(ra) # 80004092 <begin_op>
  if((ip = namei(old)) == 0){
    80005372:	ed040513          	addi	a0,s0,-304
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	afc080e7          	jalr	-1284(ra) # 80003e72 <namei>
    8000537e:	84aa                	mv	s1,a0
    80005380:	c551                	beqz	a0,8000540c <sys_link+0xde>
  ilock(ip);
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	29a080e7          	jalr	666(ra) # 8000361c <ilock>
  if(ip->type == T_DIR){
    8000538a:	04449703          	lh	a4,68(s1)
    8000538e:	4785                	li	a5,1
    80005390:	08f70463          	beq	a4,a5,80005418 <sys_link+0xea>
  ip->nlink++;
    80005394:	04a4d783          	lhu	a5,74(s1)
    80005398:	2785                	addiw	a5,a5,1
    8000539a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000539e:	8526                	mv	a0,s1
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	1b2080e7          	jalr	434(ra) # 80003552 <iupdate>
  iunlock(ip);
    800053a8:	8526                	mv	a0,s1
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	334080e7          	jalr	820(ra) # 800036de <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053b2:	fd040593          	addi	a1,s0,-48
    800053b6:	f5040513          	addi	a0,s0,-176
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	ad6080e7          	jalr	-1322(ra) # 80003e90 <nameiparent>
    800053c2:	892a                	mv	s2,a0
    800053c4:	c935                	beqz	a0,80005438 <sys_link+0x10a>
  ilock(dp);
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	256080e7          	jalr	598(ra) # 8000361c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053ce:	00092703          	lw	a4,0(s2)
    800053d2:	409c                	lw	a5,0(s1)
    800053d4:	04f71d63          	bne	a4,a5,8000542e <sys_link+0x100>
    800053d8:	40d0                	lw	a2,4(s1)
    800053da:	fd040593          	addi	a1,s0,-48
    800053de:	854a                	mv	a0,s2
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	9d0080e7          	jalr	-1584(ra) # 80003db0 <dirlink>
    800053e8:	04054363          	bltz	a0,8000542e <sys_link+0x100>
  iunlockput(dp);
    800053ec:	854a                	mv	a0,s2
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	490080e7          	jalr	1168(ra) # 8000387e <iunlockput>
  iput(ip);
    800053f6:	8526                	mv	a0,s1
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	3de080e7          	jalr	990(ra) # 800037d6 <iput>
  end_op();
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	d12080e7          	jalr	-750(ra) # 80004112 <end_op>
  return 0;
    80005408:	4781                	li	a5,0
    8000540a:	a085                	j	8000546a <sys_link+0x13c>
    end_op();
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	d06080e7          	jalr	-762(ra) # 80004112 <end_op>
    return -1;
    80005414:	57fd                	li	a5,-1
    80005416:	a891                	j	8000546a <sys_link+0x13c>
    iunlockput(ip);
    80005418:	8526                	mv	a0,s1
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	464080e7          	jalr	1124(ra) # 8000387e <iunlockput>
    end_op();
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	cf0080e7          	jalr	-784(ra) # 80004112 <end_op>
    return -1;
    8000542a:	57fd                	li	a5,-1
    8000542c:	a83d                	j	8000546a <sys_link+0x13c>
    iunlockput(dp);
    8000542e:	854a                	mv	a0,s2
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	44e080e7          	jalr	1102(ra) # 8000387e <iunlockput>
  ilock(ip);
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	1e2080e7          	jalr	482(ra) # 8000361c <ilock>
  ip->nlink--;
    80005442:	04a4d783          	lhu	a5,74(s1)
    80005446:	37fd                	addiw	a5,a5,-1
    80005448:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	104080e7          	jalr	260(ra) # 80003552 <iupdate>
  iunlockput(ip);
    80005456:	8526                	mv	a0,s1
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	426080e7          	jalr	1062(ra) # 8000387e <iunlockput>
  end_op();
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	cb2080e7          	jalr	-846(ra) # 80004112 <end_op>
  return -1;
    80005468:	57fd                	li	a5,-1
}
    8000546a:	853e                	mv	a0,a5
    8000546c:	70b2                	ld	ra,296(sp)
    8000546e:	7412                	ld	s0,288(sp)
    80005470:	64f2                	ld	s1,280(sp)
    80005472:	6952                	ld	s2,272(sp)
    80005474:	6155                	addi	sp,sp,304
    80005476:	8082                	ret

0000000080005478 <sys_unlink>:
{
    80005478:	7151                	addi	sp,sp,-240
    8000547a:	f586                	sd	ra,232(sp)
    8000547c:	f1a2                	sd	s0,224(sp)
    8000547e:	eda6                	sd	s1,216(sp)
    80005480:	e9ca                	sd	s2,208(sp)
    80005482:	e5ce                	sd	s3,200(sp)
    80005484:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005486:	08000613          	li	a2,128
    8000548a:	f3040593          	addi	a1,s0,-208
    8000548e:	4501                	li	a0,0
    80005490:	ffffd097          	auipc	ra,0xffffd
    80005494:	65e080e7          	jalr	1630(ra) # 80002aee <argstr>
    80005498:	18054163          	bltz	a0,8000561a <sys_unlink+0x1a2>
  begin_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	bf6080e7          	jalr	-1034(ra) # 80004092 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054a4:	fb040593          	addi	a1,s0,-80
    800054a8:	f3040513          	addi	a0,s0,-208
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	9e4080e7          	jalr	-1564(ra) # 80003e90 <nameiparent>
    800054b4:	84aa                	mv	s1,a0
    800054b6:	c979                	beqz	a0,8000558c <sys_unlink+0x114>
  ilock(dp);
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	164080e7          	jalr	356(ra) # 8000361c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054c0:	00003597          	auipc	a1,0x3
    800054c4:	22058593          	addi	a1,a1,544 # 800086e0 <syscalls+0x2b0>
    800054c8:	fb040513          	addi	a0,s0,-80
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	652080e7          	jalr	1618(ra) # 80003b1e <namecmp>
    800054d4:	14050a63          	beqz	a0,80005628 <sys_unlink+0x1b0>
    800054d8:	00003597          	auipc	a1,0x3
    800054dc:	21058593          	addi	a1,a1,528 # 800086e8 <syscalls+0x2b8>
    800054e0:	fb040513          	addi	a0,s0,-80
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	63a080e7          	jalr	1594(ra) # 80003b1e <namecmp>
    800054ec:	12050e63          	beqz	a0,80005628 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054f0:	f2c40613          	addi	a2,s0,-212
    800054f4:	fb040593          	addi	a1,s0,-80
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	63e080e7          	jalr	1598(ra) # 80003b38 <dirlookup>
    80005502:	892a                	mv	s2,a0
    80005504:	12050263          	beqz	a0,80005628 <sys_unlink+0x1b0>
  ilock(ip);
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	114080e7          	jalr	276(ra) # 8000361c <ilock>
  if(ip->nlink < 1)
    80005510:	04a91783          	lh	a5,74(s2)
    80005514:	08f05263          	blez	a5,80005598 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005518:	04491703          	lh	a4,68(s2)
    8000551c:	4785                	li	a5,1
    8000551e:	08f70563          	beq	a4,a5,800055a8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005522:	4641                	li	a2,16
    80005524:	4581                	li	a1,0
    80005526:	fc040513          	addi	a0,s0,-64
    8000552a:	ffffb097          	auipc	ra,0xffffb
    8000552e:	794080e7          	jalr	1940(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005532:	4741                	li	a4,16
    80005534:	f2c42683          	lw	a3,-212(s0)
    80005538:	fc040613          	addi	a2,s0,-64
    8000553c:	4581                	li	a1,0
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	4c0080e7          	jalr	1216(ra) # 80003a00 <writei>
    80005548:	47c1                	li	a5,16
    8000554a:	0af51563          	bne	a0,a5,800055f4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000554e:	04491703          	lh	a4,68(s2)
    80005552:	4785                	li	a5,1
    80005554:	0af70863          	beq	a4,a5,80005604 <sys_unlink+0x18c>
  iunlockput(dp);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	324080e7          	jalr	804(ra) # 8000387e <iunlockput>
  ip->nlink--;
    80005562:	04a95783          	lhu	a5,74(s2)
    80005566:	37fd                	addiw	a5,a5,-1
    80005568:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000556c:	854a                	mv	a0,s2
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	fe4080e7          	jalr	-28(ra) # 80003552 <iupdate>
  iunlockput(ip);
    80005576:	854a                	mv	a0,s2
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	306080e7          	jalr	774(ra) # 8000387e <iunlockput>
  end_op();
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	b92080e7          	jalr	-1134(ra) # 80004112 <end_op>
  return 0;
    80005588:	4501                	li	a0,0
    8000558a:	a84d                	j	8000563c <sys_unlink+0x1c4>
    end_op();
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	b86080e7          	jalr	-1146(ra) # 80004112 <end_op>
    return -1;
    80005594:	557d                	li	a0,-1
    80005596:	a05d                	j	8000563c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005598:	00003517          	auipc	a0,0x3
    8000559c:	17850513          	addi	a0,a0,376 # 80008710 <syscalls+0x2e0>
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	f8a080e7          	jalr	-118(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055a8:	04c92703          	lw	a4,76(s2)
    800055ac:	02000793          	li	a5,32
    800055b0:	f6e7f9e3          	bgeu	a5,a4,80005522 <sys_unlink+0xaa>
    800055b4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055b8:	4741                	li	a4,16
    800055ba:	86ce                	mv	a3,s3
    800055bc:	f1840613          	addi	a2,s0,-232
    800055c0:	4581                	li	a1,0
    800055c2:	854a                	mv	a0,s2
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	30c080e7          	jalr	780(ra) # 800038d0 <readi>
    800055cc:	47c1                	li	a5,16
    800055ce:	00f51b63          	bne	a0,a5,800055e4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055d2:	f1845783          	lhu	a5,-232(s0)
    800055d6:	e7a1                	bnez	a5,8000561e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055d8:	29c1                	addiw	s3,s3,16
    800055da:	04c92783          	lw	a5,76(s2)
    800055de:	fcf9ede3          	bltu	s3,a5,800055b8 <sys_unlink+0x140>
    800055e2:	b781                	j	80005522 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055e4:	00003517          	auipc	a0,0x3
    800055e8:	14450513          	addi	a0,a0,324 # 80008728 <syscalls+0x2f8>
    800055ec:	ffffb097          	auipc	ra,0xffffb
    800055f0:	f3e080e7          	jalr	-194(ra) # 8000052a <panic>
    panic("unlink: writei");
    800055f4:	00003517          	auipc	a0,0x3
    800055f8:	14c50513          	addi	a0,a0,332 # 80008740 <syscalls+0x310>
    800055fc:	ffffb097          	auipc	ra,0xffffb
    80005600:	f2e080e7          	jalr	-210(ra) # 8000052a <panic>
    dp->nlink--;
    80005604:	04a4d783          	lhu	a5,74(s1)
    80005608:	37fd                	addiw	a5,a5,-1
    8000560a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000560e:	8526                	mv	a0,s1
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	f42080e7          	jalr	-190(ra) # 80003552 <iupdate>
    80005618:	b781                	j	80005558 <sys_unlink+0xe0>
    return -1;
    8000561a:	557d                	li	a0,-1
    8000561c:	a005                	j	8000563c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000561e:	854a                	mv	a0,s2
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	25e080e7          	jalr	606(ra) # 8000387e <iunlockput>
  iunlockput(dp);
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	254080e7          	jalr	596(ra) # 8000387e <iunlockput>
  end_op();
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	ae0080e7          	jalr	-1312(ra) # 80004112 <end_op>
  return -1;
    8000563a:	557d                	li	a0,-1
}
    8000563c:	70ae                	ld	ra,232(sp)
    8000563e:	740e                	ld	s0,224(sp)
    80005640:	64ee                	ld	s1,216(sp)
    80005642:	694e                	ld	s2,208(sp)
    80005644:	69ae                	ld	s3,200(sp)
    80005646:	616d                	addi	sp,sp,240
    80005648:	8082                	ret

000000008000564a <sys_open>:

uint64
sys_open(void)
{
    8000564a:	7131                	addi	sp,sp,-192
    8000564c:	fd06                	sd	ra,184(sp)
    8000564e:	f922                	sd	s0,176(sp)
    80005650:	f526                	sd	s1,168(sp)
    80005652:	f14a                	sd	s2,160(sp)
    80005654:	ed4e                	sd	s3,152(sp)
    80005656:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005658:	08000613          	li	a2,128
    8000565c:	f5040593          	addi	a1,s0,-176
    80005660:	4501                	li	a0,0
    80005662:	ffffd097          	auipc	ra,0xffffd
    80005666:	48c080e7          	jalr	1164(ra) # 80002aee <argstr>
    return -1;
    8000566a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000566c:	0c054163          	bltz	a0,8000572e <sys_open+0xe4>
    80005670:	f4c40593          	addi	a1,s0,-180
    80005674:	4505                	li	a0,1
    80005676:	ffffd097          	auipc	ra,0xffffd
    8000567a:	434080e7          	jalr	1076(ra) # 80002aaa <argint>
    8000567e:	0a054863          	bltz	a0,8000572e <sys_open+0xe4>

  begin_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	a10080e7          	jalr	-1520(ra) # 80004092 <begin_op>

  if(omode & O_CREATE){
    8000568a:	f4c42783          	lw	a5,-180(s0)
    8000568e:	2007f793          	andi	a5,a5,512
    80005692:	cbdd                	beqz	a5,80005748 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005694:	4681                	li	a3,0
    80005696:	4601                	li	a2,0
    80005698:	4589                	li	a1,2
    8000569a:	f5040513          	addi	a0,s0,-176
    8000569e:	00000097          	auipc	ra,0x0
    800056a2:	974080e7          	jalr	-1676(ra) # 80005012 <create>
    800056a6:	892a                	mv	s2,a0
    if(ip == 0){
    800056a8:	c959                	beqz	a0,8000573e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056aa:	04491703          	lh	a4,68(s2)
    800056ae:	478d                	li	a5,3
    800056b0:	00f71763          	bne	a4,a5,800056be <sys_open+0x74>
    800056b4:	04695703          	lhu	a4,70(s2)
    800056b8:	47a5                	li	a5,9
    800056ba:	0ce7ec63          	bltu	a5,a4,80005792 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	de4080e7          	jalr	-540(ra) # 800044a2 <filealloc>
    800056c6:	89aa                	mv	s3,a0
    800056c8:	10050263          	beqz	a0,800057cc <sys_open+0x182>
    800056cc:	00000097          	auipc	ra,0x0
    800056d0:	904080e7          	jalr	-1788(ra) # 80004fd0 <fdalloc>
    800056d4:	84aa                	mv	s1,a0
    800056d6:	0e054663          	bltz	a0,800057c2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056da:	04491703          	lh	a4,68(s2)
    800056de:	478d                	li	a5,3
    800056e0:	0cf70463          	beq	a4,a5,800057a8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056e4:	4789                	li	a5,2
    800056e6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056ea:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056ee:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056f2:	f4c42783          	lw	a5,-180(s0)
    800056f6:	0017c713          	xori	a4,a5,1
    800056fa:	8b05                	andi	a4,a4,1
    800056fc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005700:	0037f713          	andi	a4,a5,3
    80005704:	00e03733          	snez	a4,a4
    80005708:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000570c:	4007f793          	andi	a5,a5,1024
    80005710:	c791                	beqz	a5,8000571c <sys_open+0xd2>
    80005712:	04491703          	lh	a4,68(s2)
    80005716:	4789                	li	a5,2
    80005718:	08f70f63          	beq	a4,a5,800057b6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000571c:	854a                	mv	a0,s2
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	fc0080e7          	jalr	-64(ra) # 800036de <iunlock>
  end_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	9ec080e7          	jalr	-1556(ra) # 80004112 <end_op>

  return fd;
}
    8000572e:	8526                	mv	a0,s1
    80005730:	70ea                	ld	ra,184(sp)
    80005732:	744a                	ld	s0,176(sp)
    80005734:	74aa                	ld	s1,168(sp)
    80005736:	790a                	ld	s2,160(sp)
    80005738:	69ea                	ld	s3,152(sp)
    8000573a:	6129                	addi	sp,sp,192
    8000573c:	8082                	ret
      end_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	9d4080e7          	jalr	-1580(ra) # 80004112 <end_op>
      return -1;
    80005746:	b7e5                	j	8000572e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005748:	f5040513          	addi	a0,s0,-176
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	726080e7          	jalr	1830(ra) # 80003e72 <namei>
    80005754:	892a                	mv	s2,a0
    80005756:	c905                	beqz	a0,80005786 <sys_open+0x13c>
    ilock(ip);
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	ec4080e7          	jalr	-316(ra) # 8000361c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005760:	04491703          	lh	a4,68(s2)
    80005764:	4785                	li	a5,1
    80005766:	f4f712e3          	bne	a4,a5,800056aa <sys_open+0x60>
    8000576a:	f4c42783          	lw	a5,-180(s0)
    8000576e:	dba1                	beqz	a5,800056be <sys_open+0x74>
      iunlockput(ip);
    80005770:	854a                	mv	a0,s2
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	10c080e7          	jalr	268(ra) # 8000387e <iunlockput>
      end_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	998080e7          	jalr	-1640(ra) # 80004112 <end_op>
      return -1;
    80005782:	54fd                	li	s1,-1
    80005784:	b76d                	j	8000572e <sys_open+0xe4>
      end_op();
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	98c080e7          	jalr	-1652(ra) # 80004112 <end_op>
      return -1;
    8000578e:	54fd                	li	s1,-1
    80005790:	bf79                	j	8000572e <sys_open+0xe4>
    iunlockput(ip);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	0ea080e7          	jalr	234(ra) # 8000387e <iunlockput>
    end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	976080e7          	jalr	-1674(ra) # 80004112 <end_op>
    return -1;
    800057a4:	54fd                	li	s1,-1
    800057a6:	b761                	j	8000572e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057a8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057ac:	04691783          	lh	a5,70(s2)
    800057b0:	02f99223          	sh	a5,36(s3)
    800057b4:	bf2d                	j	800056ee <sys_open+0xa4>
    itrunc(ip);
    800057b6:	854a                	mv	a0,s2
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	f72080e7          	jalr	-142(ra) # 8000372a <itrunc>
    800057c0:	bfb1                	j	8000571c <sys_open+0xd2>
      fileclose(f);
    800057c2:	854e                	mv	a0,s3
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	d9a080e7          	jalr	-614(ra) # 8000455e <fileclose>
    iunlockput(ip);
    800057cc:	854a                	mv	a0,s2
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	0b0080e7          	jalr	176(ra) # 8000387e <iunlockput>
    end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	93c080e7          	jalr	-1732(ra) # 80004112 <end_op>
    return -1;
    800057de:	54fd                	li	s1,-1
    800057e0:	b7b9                	j	8000572e <sys_open+0xe4>

00000000800057e2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057e2:	7175                	addi	sp,sp,-144
    800057e4:	e506                	sd	ra,136(sp)
    800057e6:	e122                	sd	s0,128(sp)
    800057e8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	8a8080e7          	jalr	-1880(ra) # 80004092 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057f2:	08000613          	li	a2,128
    800057f6:	f7040593          	addi	a1,s0,-144
    800057fa:	4501                	li	a0,0
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	2f2080e7          	jalr	754(ra) # 80002aee <argstr>
    80005804:	02054963          	bltz	a0,80005836 <sys_mkdir+0x54>
    80005808:	4681                	li	a3,0
    8000580a:	4601                	li	a2,0
    8000580c:	4585                	li	a1,1
    8000580e:	f7040513          	addi	a0,s0,-144
    80005812:	00000097          	auipc	ra,0x0
    80005816:	800080e7          	jalr	-2048(ra) # 80005012 <create>
    8000581a:	cd11                	beqz	a0,80005836 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	062080e7          	jalr	98(ra) # 8000387e <iunlockput>
  end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	8ee080e7          	jalr	-1810(ra) # 80004112 <end_op>
  return 0;
    8000582c:	4501                	li	a0,0
}
    8000582e:	60aa                	ld	ra,136(sp)
    80005830:	640a                	ld	s0,128(sp)
    80005832:	6149                	addi	sp,sp,144
    80005834:	8082                	ret
    end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	8dc080e7          	jalr	-1828(ra) # 80004112 <end_op>
    return -1;
    8000583e:	557d                	li	a0,-1
    80005840:	b7fd                	j	8000582e <sys_mkdir+0x4c>

0000000080005842 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005842:	7135                	addi	sp,sp,-160
    80005844:	ed06                	sd	ra,152(sp)
    80005846:	e922                	sd	s0,144(sp)
    80005848:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	848080e7          	jalr	-1976(ra) # 80004092 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005852:	08000613          	li	a2,128
    80005856:	f7040593          	addi	a1,s0,-144
    8000585a:	4501                	li	a0,0
    8000585c:	ffffd097          	auipc	ra,0xffffd
    80005860:	292080e7          	jalr	658(ra) # 80002aee <argstr>
    80005864:	04054a63          	bltz	a0,800058b8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005868:	f6c40593          	addi	a1,s0,-148
    8000586c:	4505                	li	a0,1
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	23c080e7          	jalr	572(ra) # 80002aaa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005876:	04054163          	bltz	a0,800058b8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000587a:	f6840593          	addi	a1,s0,-152
    8000587e:	4509                	li	a0,2
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	22a080e7          	jalr	554(ra) # 80002aaa <argint>
     argint(1, &major) < 0 ||
    80005888:	02054863          	bltz	a0,800058b8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000588c:	f6841683          	lh	a3,-152(s0)
    80005890:	f6c41603          	lh	a2,-148(s0)
    80005894:	458d                	li	a1,3
    80005896:	f7040513          	addi	a0,s0,-144
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	778080e7          	jalr	1912(ra) # 80005012 <create>
     argint(2, &minor) < 0 ||
    800058a2:	c919                	beqz	a0,800058b8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	fda080e7          	jalr	-38(ra) # 8000387e <iunlockput>
  end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	866080e7          	jalr	-1946(ra) # 80004112 <end_op>
  return 0;
    800058b4:	4501                	li	a0,0
    800058b6:	a031                	j	800058c2 <sys_mknod+0x80>
    end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	85a080e7          	jalr	-1958(ra) # 80004112 <end_op>
    return -1;
    800058c0:	557d                	li	a0,-1
}
    800058c2:	60ea                	ld	ra,152(sp)
    800058c4:	644a                	ld	s0,144(sp)
    800058c6:	610d                	addi	sp,sp,160
    800058c8:	8082                	ret

00000000800058ca <sys_chdir>:

uint64
sys_chdir(void)
{
    800058ca:	7135                	addi	sp,sp,-160
    800058cc:	ed06                	sd	ra,152(sp)
    800058ce:	e922                	sd	s0,144(sp)
    800058d0:	e526                	sd	s1,136(sp)
    800058d2:	e14a                	sd	s2,128(sp)
    800058d4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058d6:	ffffc097          	auipc	ra,0xffffc
    800058da:	0b0080e7          	jalr	176(ra) # 80001986 <myproc>
    800058de:	892a                	mv	s2,a0
  
  begin_op();
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	7b2080e7          	jalr	1970(ra) # 80004092 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058e8:	08000613          	li	a2,128
    800058ec:	f6040593          	addi	a1,s0,-160
    800058f0:	4501                	li	a0,0
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	1fc080e7          	jalr	508(ra) # 80002aee <argstr>
    800058fa:	04054b63          	bltz	a0,80005950 <sys_chdir+0x86>
    800058fe:	f6040513          	addi	a0,s0,-160
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	570080e7          	jalr	1392(ra) # 80003e72 <namei>
    8000590a:	84aa                	mv	s1,a0
    8000590c:	c131                	beqz	a0,80005950 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	d0e080e7          	jalr	-754(ra) # 8000361c <ilock>
  if(ip->type != T_DIR){
    80005916:	04449703          	lh	a4,68(s1)
    8000591a:	4785                	li	a5,1
    8000591c:	04f71063          	bne	a4,a5,8000595c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005920:	8526                	mv	a0,s1
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	dbc080e7          	jalr	-580(ra) # 800036de <iunlock>
  iput(p->cwd);
    8000592a:	15093503          	ld	a0,336(s2)
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	ea8080e7          	jalr	-344(ra) # 800037d6 <iput>
  end_op();
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	7dc080e7          	jalr	2012(ra) # 80004112 <end_op>
  p->cwd = ip;
    8000593e:	14993823          	sd	s1,336(s2)
  return 0;
    80005942:	4501                	li	a0,0
}
    80005944:	60ea                	ld	ra,152(sp)
    80005946:	644a                	ld	s0,144(sp)
    80005948:	64aa                	ld	s1,136(sp)
    8000594a:	690a                	ld	s2,128(sp)
    8000594c:	610d                	addi	sp,sp,160
    8000594e:	8082                	ret
    end_op();
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	7c2080e7          	jalr	1986(ra) # 80004112 <end_op>
    return -1;
    80005958:	557d                	li	a0,-1
    8000595a:	b7ed                	j	80005944 <sys_chdir+0x7a>
    iunlockput(ip);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	f20080e7          	jalr	-224(ra) # 8000387e <iunlockput>
    end_op();
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	7ac080e7          	jalr	1964(ra) # 80004112 <end_op>
    return -1;
    8000596e:	557d                	li	a0,-1
    80005970:	bfd1                	j	80005944 <sys_chdir+0x7a>

0000000080005972 <sys_exec>:

uint64
sys_exec(void)
{
    80005972:	7145                	addi	sp,sp,-464
    80005974:	e786                	sd	ra,456(sp)
    80005976:	e3a2                	sd	s0,448(sp)
    80005978:	ff26                	sd	s1,440(sp)
    8000597a:	fb4a                	sd	s2,432(sp)
    8000597c:	f74e                	sd	s3,424(sp)
    8000597e:	f352                	sd	s4,416(sp)
    80005980:	ef56                	sd	s5,408(sp)
    80005982:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005984:	08000613          	li	a2,128
    80005988:	f4040593          	addi	a1,s0,-192
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	160080e7          	jalr	352(ra) # 80002aee <argstr>
    return -1;
    80005996:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005998:	0c054a63          	bltz	a0,80005a6c <sys_exec+0xfa>
    8000599c:	e3840593          	addi	a1,s0,-456
    800059a0:	4505                	li	a0,1
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	12a080e7          	jalr	298(ra) # 80002acc <argaddr>
    800059aa:	0c054163          	bltz	a0,80005a6c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059ae:	10000613          	li	a2,256
    800059b2:	4581                	li	a1,0
    800059b4:	e4040513          	addi	a0,s0,-448
    800059b8:	ffffb097          	auipc	ra,0xffffb
    800059bc:	306080e7          	jalr	774(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059c0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059c4:	89a6                	mv	s3,s1
    800059c6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059c8:	02000a13          	li	s4,32
    800059cc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059d0:	00391793          	slli	a5,s2,0x3
    800059d4:	e3040593          	addi	a1,s0,-464
    800059d8:	e3843503          	ld	a0,-456(s0)
    800059dc:	953e                	add	a0,a0,a5
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	032080e7          	jalr	50(ra) # 80002a10 <fetchaddr>
    800059e6:	02054a63          	bltz	a0,80005a1a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059ea:	e3043783          	ld	a5,-464(s0)
    800059ee:	c3b9                	beqz	a5,80005a34 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059f0:	ffffb097          	auipc	ra,0xffffb
    800059f4:	0e2080e7          	jalr	226(ra) # 80000ad2 <kalloc>
    800059f8:	85aa                	mv	a1,a0
    800059fa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059fe:	cd11                	beqz	a0,80005a1a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a00:	6605                	lui	a2,0x1
    80005a02:	e3043503          	ld	a0,-464(s0)
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	05c080e7          	jalr	92(ra) # 80002a62 <fetchstr>
    80005a0e:	00054663          	bltz	a0,80005a1a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a12:	0905                	addi	s2,s2,1
    80005a14:	09a1                	addi	s3,s3,8
    80005a16:	fb491be3          	bne	s2,s4,800059cc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a1a:	10048913          	addi	s2,s1,256
    80005a1e:	6088                	ld	a0,0(s1)
    80005a20:	c529                	beqz	a0,80005a6a <sys_exec+0xf8>
    kfree(argv[i]);
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	fb4080e7          	jalr	-76(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a2a:	04a1                	addi	s1,s1,8
    80005a2c:	ff2499e3          	bne	s1,s2,80005a1e <sys_exec+0xac>
  return -1;
    80005a30:	597d                	li	s2,-1
    80005a32:	a82d                	j	80005a6c <sys_exec+0xfa>
      argv[i] = 0;
    80005a34:	0a8e                	slli	s5,s5,0x3
    80005a36:	fc040793          	addi	a5,s0,-64
    80005a3a:	9abe                	add	s5,s5,a5
    80005a3c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005a40:	e4040593          	addi	a1,s0,-448
    80005a44:	f4040513          	addi	a0,s0,-192
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	178080e7          	jalr	376(ra) # 80004bc0 <exec>
    80005a50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a52:	10048993          	addi	s3,s1,256
    80005a56:	6088                	ld	a0,0(s1)
    80005a58:	c911                	beqz	a0,80005a6c <sys_exec+0xfa>
    kfree(argv[i]);
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	f7c080e7          	jalr	-132(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a62:	04a1                	addi	s1,s1,8
    80005a64:	ff3499e3          	bne	s1,s3,80005a56 <sys_exec+0xe4>
    80005a68:	a011                	j	80005a6c <sys_exec+0xfa>
  return -1;
    80005a6a:	597d                	li	s2,-1
}
    80005a6c:	854a                	mv	a0,s2
    80005a6e:	60be                	ld	ra,456(sp)
    80005a70:	641e                	ld	s0,448(sp)
    80005a72:	74fa                	ld	s1,440(sp)
    80005a74:	795a                	ld	s2,432(sp)
    80005a76:	79ba                	ld	s3,424(sp)
    80005a78:	7a1a                	ld	s4,416(sp)
    80005a7a:	6afa                	ld	s5,408(sp)
    80005a7c:	6179                	addi	sp,sp,464
    80005a7e:	8082                	ret

0000000080005a80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a80:	7139                	addi	sp,sp,-64
    80005a82:	fc06                	sd	ra,56(sp)
    80005a84:	f822                	sd	s0,48(sp)
    80005a86:	f426                	sd	s1,40(sp)
    80005a88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a8a:	ffffc097          	auipc	ra,0xffffc
    80005a8e:	efc080e7          	jalr	-260(ra) # 80001986 <myproc>
    80005a92:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a94:	fd840593          	addi	a1,s0,-40
    80005a98:	4501                	li	a0,0
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	032080e7          	jalr	50(ra) # 80002acc <argaddr>
    return -1;
    80005aa2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005aa4:	0e054063          	bltz	a0,80005b84 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005aa8:	fc840593          	addi	a1,s0,-56
    80005aac:	fd040513          	addi	a0,s0,-48
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	dee080e7          	jalr	-530(ra) # 8000489e <pipealloc>
    return -1;
    80005ab8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005aba:	0c054563          	bltz	a0,80005b84 <sys_pipe+0x104>
  fd0 = -1;
    80005abe:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ac2:	fd043503          	ld	a0,-48(s0)
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	50a080e7          	jalr	1290(ra) # 80004fd0 <fdalloc>
    80005ace:	fca42223          	sw	a0,-60(s0)
    80005ad2:	08054c63          	bltz	a0,80005b6a <sys_pipe+0xea>
    80005ad6:	fc843503          	ld	a0,-56(s0)
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	4f6080e7          	jalr	1270(ra) # 80004fd0 <fdalloc>
    80005ae2:	fca42023          	sw	a0,-64(s0)
    80005ae6:	06054863          	bltz	a0,80005b56 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005aea:	4691                	li	a3,4
    80005aec:	fc440613          	addi	a2,s0,-60
    80005af0:	fd843583          	ld	a1,-40(s0)
    80005af4:	68a8                	ld	a0,80(s1)
    80005af6:	ffffc097          	auipc	ra,0xffffc
    80005afa:	b50080e7          	jalr	-1200(ra) # 80001646 <copyout>
    80005afe:	02054063          	bltz	a0,80005b1e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b02:	4691                	li	a3,4
    80005b04:	fc040613          	addi	a2,s0,-64
    80005b08:	fd843583          	ld	a1,-40(s0)
    80005b0c:	0591                	addi	a1,a1,4
    80005b0e:	68a8                	ld	a0,80(s1)
    80005b10:	ffffc097          	auipc	ra,0xffffc
    80005b14:	b36080e7          	jalr	-1226(ra) # 80001646 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b18:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b1a:	06055563          	bgez	a0,80005b84 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b1e:	fc442783          	lw	a5,-60(s0)
    80005b22:	07e9                	addi	a5,a5,26
    80005b24:	078e                	slli	a5,a5,0x3
    80005b26:	97a6                	add	a5,a5,s1
    80005b28:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b2c:	fc042503          	lw	a0,-64(s0)
    80005b30:	0569                	addi	a0,a0,26
    80005b32:	050e                	slli	a0,a0,0x3
    80005b34:	9526                	add	a0,a0,s1
    80005b36:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b3a:	fd043503          	ld	a0,-48(s0)
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	a20080e7          	jalr	-1504(ra) # 8000455e <fileclose>
    fileclose(wf);
    80005b46:	fc843503          	ld	a0,-56(s0)
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	a14080e7          	jalr	-1516(ra) # 8000455e <fileclose>
    return -1;
    80005b52:	57fd                	li	a5,-1
    80005b54:	a805                	j	80005b84 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b56:	fc442783          	lw	a5,-60(s0)
    80005b5a:	0007c863          	bltz	a5,80005b6a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b5e:	01a78513          	addi	a0,a5,26
    80005b62:	050e                	slli	a0,a0,0x3
    80005b64:	9526                	add	a0,a0,s1
    80005b66:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b6a:	fd043503          	ld	a0,-48(s0)
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	9f0080e7          	jalr	-1552(ra) # 8000455e <fileclose>
    fileclose(wf);
    80005b76:	fc843503          	ld	a0,-56(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	9e4080e7          	jalr	-1564(ra) # 8000455e <fileclose>
    return -1;
    80005b82:	57fd                	li	a5,-1
}
    80005b84:	853e                	mv	a0,a5
    80005b86:	70e2                	ld	ra,56(sp)
    80005b88:	7442                	ld	s0,48(sp)
    80005b8a:	74a2                	ld	s1,40(sp)
    80005b8c:	6121                	addi	sp,sp,64
    80005b8e:	8082                	ret

0000000080005b90 <kernelvec>:
    80005b90:	7111                	addi	sp,sp,-256
    80005b92:	e006                	sd	ra,0(sp)
    80005b94:	e40a                	sd	sp,8(sp)
    80005b96:	e80e                	sd	gp,16(sp)
    80005b98:	ec12                	sd	tp,24(sp)
    80005b9a:	f016                	sd	t0,32(sp)
    80005b9c:	f41a                	sd	t1,40(sp)
    80005b9e:	f81e                	sd	t2,48(sp)
    80005ba0:	fc22                	sd	s0,56(sp)
    80005ba2:	e0a6                	sd	s1,64(sp)
    80005ba4:	e4aa                	sd	a0,72(sp)
    80005ba6:	e8ae                	sd	a1,80(sp)
    80005ba8:	ecb2                	sd	a2,88(sp)
    80005baa:	f0b6                	sd	a3,96(sp)
    80005bac:	f4ba                	sd	a4,104(sp)
    80005bae:	f8be                	sd	a5,112(sp)
    80005bb0:	fcc2                	sd	a6,120(sp)
    80005bb2:	e146                	sd	a7,128(sp)
    80005bb4:	e54a                	sd	s2,136(sp)
    80005bb6:	e94e                	sd	s3,144(sp)
    80005bb8:	ed52                	sd	s4,152(sp)
    80005bba:	f156                	sd	s5,160(sp)
    80005bbc:	f55a                	sd	s6,168(sp)
    80005bbe:	f95e                	sd	s7,176(sp)
    80005bc0:	fd62                	sd	s8,184(sp)
    80005bc2:	e1e6                	sd	s9,192(sp)
    80005bc4:	e5ea                	sd	s10,200(sp)
    80005bc6:	e9ee                	sd	s11,208(sp)
    80005bc8:	edf2                	sd	t3,216(sp)
    80005bca:	f1f6                	sd	t4,224(sp)
    80005bcc:	f5fa                	sd	t5,232(sp)
    80005bce:	f9fe                	sd	t6,240(sp)
    80005bd0:	d0dfc0ef          	jal	ra,800028dc <kerneltrap>
    80005bd4:	6082                	ld	ra,0(sp)
    80005bd6:	6122                	ld	sp,8(sp)
    80005bd8:	61c2                	ld	gp,16(sp)
    80005bda:	7282                	ld	t0,32(sp)
    80005bdc:	7322                	ld	t1,40(sp)
    80005bde:	73c2                	ld	t2,48(sp)
    80005be0:	7462                	ld	s0,56(sp)
    80005be2:	6486                	ld	s1,64(sp)
    80005be4:	6526                	ld	a0,72(sp)
    80005be6:	65c6                	ld	a1,80(sp)
    80005be8:	6666                	ld	a2,88(sp)
    80005bea:	7686                	ld	a3,96(sp)
    80005bec:	7726                	ld	a4,104(sp)
    80005bee:	77c6                	ld	a5,112(sp)
    80005bf0:	7866                	ld	a6,120(sp)
    80005bf2:	688a                	ld	a7,128(sp)
    80005bf4:	692a                	ld	s2,136(sp)
    80005bf6:	69ca                	ld	s3,144(sp)
    80005bf8:	6a6a                	ld	s4,152(sp)
    80005bfa:	7a8a                	ld	s5,160(sp)
    80005bfc:	7b2a                	ld	s6,168(sp)
    80005bfe:	7bca                	ld	s7,176(sp)
    80005c00:	7c6a                	ld	s8,184(sp)
    80005c02:	6c8e                	ld	s9,192(sp)
    80005c04:	6d2e                	ld	s10,200(sp)
    80005c06:	6dce                	ld	s11,208(sp)
    80005c08:	6e6e                	ld	t3,216(sp)
    80005c0a:	7e8e                	ld	t4,224(sp)
    80005c0c:	7f2e                	ld	t5,232(sp)
    80005c0e:	7fce                	ld	t6,240(sp)
    80005c10:	6111                	addi	sp,sp,256
    80005c12:	10200073          	sret
    80005c16:	00000013          	nop
    80005c1a:	00000013          	nop
    80005c1e:	0001                	nop

0000000080005c20 <timervec>:
    80005c20:	34051573          	csrrw	a0,mscratch,a0
    80005c24:	e10c                	sd	a1,0(a0)
    80005c26:	e510                	sd	a2,8(a0)
    80005c28:	e914                	sd	a3,16(a0)
    80005c2a:	6d0c                	ld	a1,24(a0)
    80005c2c:	7110                	ld	a2,32(a0)
    80005c2e:	6194                	ld	a3,0(a1)
    80005c30:	96b2                	add	a3,a3,a2
    80005c32:	e194                	sd	a3,0(a1)
    80005c34:	4589                	li	a1,2
    80005c36:	14459073          	csrw	sip,a1
    80005c3a:	6914                	ld	a3,16(a0)
    80005c3c:	6510                	ld	a2,8(a0)
    80005c3e:	610c                	ld	a1,0(a0)
    80005c40:	34051573          	csrrw	a0,mscratch,a0
    80005c44:	30200073          	mret
	...

0000000080005c4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c4a:	1141                	addi	sp,sp,-16
    80005c4c:	e422                	sd	s0,8(sp)
    80005c4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c50:	0c0007b7          	lui	a5,0xc000
    80005c54:	4705                	li	a4,1
    80005c56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c58:	c3d8                	sw	a4,4(a5)
}
    80005c5a:	6422                	ld	s0,8(sp)
    80005c5c:	0141                	addi	sp,sp,16
    80005c5e:	8082                	ret

0000000080005c60 <plicinithart>:

void
plicinithart(void)
{
    80005c60:	1141                	addi	sp,sp,-16
    80005c62:	e406                	sd	ra,8(sp)
    80005c64:	e022                	sd	s0,0(sp)
    80005c66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	cf2080e7          	jalr	-782(ra) # 8000195a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c70:	0085171b          	slliw	a4,a0,0x8
    80005c74:	0c0027b7          	lui	a5,0xc002
    80005c78:	97ba                	add	a5,a5,a4
    80005c7a:	40200713          	li	a4,1026
    80005c7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c82:	00d5151b          	slliw	a0,a0,0xd
    80005c86:	0c2017b7          	lui	a5,0xc201
    80005c8a:	953e                	add	a0,a0,a5
    80005c8c:	00052023          	sw	zero,0(a0)
}
    80005c90:	60a2                	ld	ra,8(sp)
    80005c92:	6402                	ld	s0,0(sp)
    80005c94:	0141                	addi	sp,sp,16
    80005c96:	8082                	ret

0000000080005c98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c98:	1141                	addi	sp,sp,-16
    80005c9a:	e406                	sd	ra,8(sp)
    80005c9c:	e022                	sd	s0,0(sp)
    80005c9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ca0:	ffffc097          	auipc	ra,0xffffc
    80005ca4:	cba080e7          	jalr	-838(ra) # 8000195a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ca8:	00d5179b          	slliw	a5,a0,0xd
    80005cac:	0c201537          	lui	a0,0xc201
    80005cb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005cb2:	4148                	lw	a0,4(a0)
    80005cb4:	60a2                	ld	ra,8(sp)
    80005cb6:	6402                	ld	s0,0(sp)
    80005cb8:	0141                	addi	sp,sp,16
    80005cba:	8082                	ret

0000000080005cbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cbc:	1101                	addi	sp,sp,-32
    80005cbe:	ec06                	sd	ra,24(sp)
    80005cc0:	e822                	sd	s0,16(sp)
    80005cc2:	e426                	sd	s1,8(sp)
    80005cc4:	1000                	addi	s0,sp,32
    80005cc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	c92080e7          	jalr	-878(ra) # 8000195a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cd0:	00d5151b          	slliw	a0,a0,0xd
    80005cd4:	0c2017b7          	lui	a5,0xc201
    80005cd8:	97aa                	add	a5,a5,a0
    80005cda:	c3c4                	sw	s1,4(a5)
}
    80005cdc:	60e2                	ld	ra,24(sp)
    80005cde:	6442                	ld	s0,16(sp)
    80005ce0:	64a2                	ld	s1,8(sp)
    80005ce2:	6105                	addi	sp,sp,32
    80005ce4:	8082                	ret

0000000080005ce6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ce6:	1141                	addi	sp,sp,-16
    80005ce8:	e406                	sd	ra,8(sp)
    80005cea:	e022                	sd	s0,0(sp)
    80005cec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cee:	479d                	li	a5,7
    80005cf0:	06a7c963          	blt	a5,a0,80005d62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005cf4:	0001d797          	auipc	a5,0x1d
    80005cf8:	30c78793          	addi	a5,a5,780 # 80023000 <disk>
    80005cfc:	00a78733          	add	a4,a5,a0
    80005d00:	6789                	lui	a5,0x2
    80005d02:	97ba                	add	a5,a5,a4
    80005d04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d08:	e7ad                	bnez	a5,80005d72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d0a:	00451793          	slli	a5,a0,0x4
    80005d0e:	0001f717          	auipc	a4,0x1f
    80005d12:	2f270713          	addi	a4,a4,754 # 80025000 <disk+0x2000>
    80005d16:	6314                	ld	a3,0(a4)
    80005d18:	96be                	add	a3,a3,a5
    80005d1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d1e:	6314                	ld	a3,0(a4)
    80005d20:	96be                	add	a3,a3,a5
    80005d22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d26:	6314                	ld	a3,0(a4)
    80005d28:	96be                	add	a3,a3,a5
    80005d2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d2e:	6318                	ld	a4,0(a4)
    80005d30:	97ba                	add	a5,a5,a4
    80005d32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d36:	0001d797          	auipc	a5,0x1d
    80005d3a:	2ca78793          	addi	a5,a5,714 # 80023000 <disk>
    80005d3e:	97aa                	add	a5,a5,a0
    80005d40:	6509                	lui	a0,0x2
    80005d42:	953e                	add	a0,a0,a5
    80005d44:	4785                	li	a5,1
    80005d46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d4a:	0001f517          	auipc	a0,0x1f
    80005d4e:	2ce50513          	addi	a0,a0,718 # 80025018 <disk+0x2018>
    80005d52:	ffffc097          	auipc	ra,0xffffc
    80005d56:	480080e7          	jalr	1152(ra) # 800021d2 <wakeup>
}
    80005d5a:	60a2                	ld	ra,8(sp)
    80005d5c:	6402                	ld	s0,0(sp)
    80005d5e:	0141                	addi	sp,sp,16
    80005d60:	8082                	ret
    panic("free_desc 1");
    80005d62:	00003517          	auipc	a0,0x3
    80005d66:	9ee50513          	addi	a0,a0,-1554 # 80008750 <syscalls+0x320>
    80005d6a:	ffffa097          	auipc	ra,0xffffa
    80005d6e:	7c0080e7          	jalr	1984(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005d72:	00003517          	auipc	a0,0x3
    80005d76:	9ee50513          	addi	a0,a0,-1554 # 80008760 <syscalls+0x330>
    80005d7a:	ffffa097          	auipc	ra,0xffffa
    80005d7e:	7b0080e7          	jalr	1968(ra) # 8000052a <panic>

0000000080005d82 <virtio_disk_init>:
{
    80005d82:	1101                	addi	sp,sp,-32
    80005d84:	ec06                	sd	ra,24(sp)
    80005d86:	e822                	sd	s0,16(sp)
    80005d88:	e426                	sd	s1,8(sp)
    80005d8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d8c:	00003597          	auipc	a1,0x3
    80005d90:	9e458593          	addi	a1,a1,-1564 # 80008770 <syscalls+0x340>
    80005d94:	0001f517          	auipc	a0,0x1f
    80005d98:	39450513          	addi	a0,a0,916 # 80025128 <disk+0x2128>
    80005d9c:	ffffb097          	auipc	ra,0xffffb
    80005da0:	d96080e7          	jalr	-618(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005da4:	100017b7          	lui	a5,0x10001
    80005da8:	4398                	lw	a4,0(a5)
    80005daa:	2701                	sext.w	a4,a4
    80005dac:	747277b7          	lui	a5,0x74727
    80005db0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005db4:	0ef71163          	bne	a4,a5,80005e96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005db8:	100017b7          	lui	a5,0x10001
    80005dbc:	43dc                	lw	a5,4(a5)
    80005dbe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dc0:	4705                	li	a4,1
    80005dc2:	0ce79a63          	bne	a5,a4,80005e96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dc6:	100017b7          	lui	a5,0x10001
    80005dca:	479c                	lw	a5,8(a5)
    80005dcc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dce:	4709                	li	a4,2
    80005dd0:	0ce79363          	bne	a5,a4,80005e96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dd4:	100017b7          	lui	a5,0x10001
    80005dd8:	47d8                	lw	a4,12(a5)
    80005dda:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ddc:	554d47b7          	lui	a5,0x554d4
    80005de0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005de4:	0af71963          	bne	a4,a5,80005e96 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005de8:	100017b7          	lui	a5,0x10001
    80005dec:	4705                	li	a4,1
    80005dee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df0:	470d                	li	a4,3
    80005df2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005df4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005df6:	c7ffe737          	lui	a4,0xc7ffe
    80005dfa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dfe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e00:	2701                	sext.w	a4,a4
    80005e02:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e04:	472d                	li	a4,11
    80005e06:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e08:	473d                	li	a4,15
    80005e0a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e0c:	6705                	lui	a4,0x1
    80005e0e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e10:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e14:	5bdc                	lw	a5,52(a5)
    80005e16:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e18:	c7d9                	beqz	a5,80005ea6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e1a:	471d                	li	a4,7
    80005e1c:	08f77d63          	bgeu	a4,a5,80005eb6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e20:	100014b7          	lui	s1,0x10001
    80005e24:	47a1                	li	a5,8
    80005e26:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e28:	6609                	lui	a2,0x2
    80005e2a:	4581                	li	a1,0
    80005e2c:	0001d517          	auipc	a0,0x1d
    80005e30:	1d450513          	addi	a0,a0,468 # 80023000 <disk>
    80005e34:	ffffb097          	auipc	ra,0xffffb
    80005e38:	e8a080e7          	jalr	-374(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e3c:	0001d717          	auipc	a4,0x1d
    80005e40:	1c470713          	addi	a4,a4,452 # 80023000 <disk>
    80005e44:	00c75793          	srli	a5,a4,0xc
    80005e48:	2781                	sext.w	a5,a5
    80005e4a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e4c:	0001f797          	auipc	a5,0x1f
    80005e50:	1b478793          	addi	a5,a5,436 # 80025000 <disk+0x2000>
    80005e54:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e56:	0001d717          	auipc	a4,0x1d
    80005e5a:	22a70713          	addi	a4,a4,554 # 80023080 <disk+0x80>
    80005e5e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e60:	0001e717          	auipc	a4,0x1e
    80005e64:	1a070713          	addi	a4,a4,416 # 80024000 <disk+0x1000>
    80005e68:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e6a:	4705                	li	a4,1
    80005e6c:	00e78c23          	sb	a4,24(a5)
    80005e70:	00e78ca3          	sb	a4,25(a5)
    80005e74:	00e78d23          	sb	a4,26(a5)
    80005e78:	00e78da3          	sb	a4,27(a5)
    80005e7c:	00e78e23          	sb	a4,28(a5)
    80005e80:	00e78ea3          	sb	a4,29(a5)
    80005e84:	00e78f23          	sb	a4,30(a5)
    80005e88:	00e78fa3          	sb	a4,31(a5)
}
    80005e8c:	60e2                	ld	ra,24(sp)
    80005e8e:	6442                	ld	s0,16(sp)
    80005e90:	64a2                	ld	s1,8(sp)
    80005e92:	6105                	addi	sp,sp,32
    80005e94:	8082                	ret
    panic("could not find virtio disk");
    80005e96:	00003517          	auipc	a0,0x3
    80005e9a:	8ea50513          	addi	a0,a0,-1814 # 80008780 <syscalls+0x350>
    80005e9e:	ffffa097          	auipc	ra,0xffffa
    80005ea2:	68c080e7          	jalr	1676(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005ea6:	00003517          	auipc	a0,0x3
    80005eaa:	8fa50513          	addi	a0,a0,-1798 # 800087a0 <syscalls+0x370>
    80005eae:	ffffa097          	auipc	ra,0xffffa
    80005eb2:	67c080e7          	jalr	1660(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80005eb6:	00003517          	auipc	a0,0x3
    80005eba:	90a50513          	addi	a0,a0,-1782 # 800087c0 <syscalls+0x390>
    80005ebe:	ffffa097          	auipc	ra,0xffffa
    80005ec2:	66c080e7          	jalr	1644(ra) # 8000052a <panic>

0000000080005ec6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ec6:	7119                	addi	sp,sp,-128
    80005ec8:	fc86                	sd	ra,120(sp)
    80005eca:	f8a2                	sd	s0,112(sp)
    80005ecc:	f4a6                	sd	s1,104(sp)
    80005ece:	f0ca                	sd	s2,96(sp)
    80005ed0:	ecce                	sd	s3,88(sp)
    80005ed2:	e8d2                	sd	s4,80(sp)
    80005ed4:	e4d6                	sd	s5,72(sp)
    80005ed6:	e0da                	sd	s6,64(sp)
    80005ed8:	fc5e                	sd	s7,56(sp)
    80005eda:	f862                	sd	s8,48(sp)
    80005edc:	f466                	sd	s9,40(sp)
    80005ede:	f06a                	sd	s10,32(sp)
    80005ee0:	ec6e                	sd	s11,24(sp)
    80005ee2:	0100                	addi	s0,sp,128
    80005ee4:	8aaa                	mv	s5,a0
    80005ee6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ee8:	00c52c83          	lw	s9,12(a0)
    80005eec:	001c9c9b          	slliw	s9,s9,0x1
    80005ef0:	1c82                	slli	s9,s9,0x20
    80005ef2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ef6:	0001f517          	auipc	a0,0x1f
    80005efa:	23250513          	addi	a0,a0,562 # 80025128 <disk+0x2128>
    80005efe:	ffffb097          	auipc	ra,0xffffb
    80005f02:	cc4080e7          	jalr	-828(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005f06:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f08:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f0a:	0001dc17          	auipc	s8,0x1d
    80005f0e:	0f6c0c13          	addi	s8,s8,246 # 80023000 <disk>
    80005f12:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f14:	4b0d                	li	s6,3
    80005f16:	a0ad                	j	80005f80 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f18:	00fc0733          	add	a4,s8,a5
    80005f1c:	975e                	add	a4,a4,s7
    80005f1e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f22:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f24:	0207c563          	bltz	a5,80005f4e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f28:	2905                	addiw	s2,s2,1
    80005f2a:	0611                	addi	a2,a2,4
    80005f2c:	19690d63          	beq	s2,s6,800060c6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f30:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f32:	0001f717          	auipc	a4,0x1f
    80005f36:	0e670713          	addi	a4,a4,230 # 80025018 <disk+0x2018>
    80005f3a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f3c:	00074683          	lbu	a3,0(a4)
    80005f40:	fee1                	bnez	a3,80005f18 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f42:	2785                	addiw	a5,a5,1
    80005f44:	0705                	addi	a4,a4,1
    80005f46:	fe979be3          	bne	a5,s1,80005f3c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f4a:	57fd                	li	a5,-1
    80005f4c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f4e:	01205d63          	blez	s2,80005f68 <virtio_disk_rw+0xa2>
    80005f52:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f54:	000a2503          	lw	a0,0(s4)
    80005f58:	00000097          	auipc	ra,0x0
    80005f5c:	d8e080e7          	jalr	-626(ra) # 80005ce6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f60:	2d85                	addiw	s11,s11,1
    80005f62:	0a11                	addi	s4,s4,4
    80005f64:	ffb918e3          	bne	s2,s11,80005f54 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f68:	0001f597          	auipc	a1,0x1f
    80005f6c:	1c058593          	addi	a1,a1,448 # 80025128 <disk+0x2128>
    80005f70:	0001f517          	auipc	a0,0x1f
    80005f74:	0a850513          	addi	a0,a0,168 # 80025018 <disk+0x2018>
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	0ce080e7          	jalr	206(ra) # 80002046 <sleep>
  for(int i = 0; i < 3; i++){
    80005f80:	f8040a13          	addi	s4,s0,-128
{
    80005f84:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f86:	894e                	mv	s2,s3
    80005f88:	b765                	j	80005f30 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f8a:	0001f697          	auipc	a3,0x1f
    80005f8e:	0766b683          	ld	a3,118(a3) # 80025000 <disk+0x2000>
    80005f92:	96ba                	add	a3,a3,a4
    80005f94:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f98:	0001d817          	auipc	a6,0x1d
    80005f9c:	06880813          	addi	a6,a6,104 # 80023000 <disk>
    80005fa0:	0001f697          	auipc	a3,0x1f
    80005fa4:	06068693          	addi	a3,a3,96 # 80025000 <disk+0x2000>
    80005fa8:	6290                	ld	a2,0(a3)
    80005faa:	963a                	add	a2,a2,a4
    80005fac:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80005fb0:	0015e593          	ori	a1,a1,1
    80005fb4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005fb8:	f8842603          	lw	a2,-120(s0)
    80005fbc:	628c                	ld	a1,0(a3)
    80005fbe:	972e                	add	a4,a4,a1
    80005fc0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fc4:	20050593          	addi	a1,a0,512
    80005fc8:	0592                	slli	a1,a1,0x4
    80005fca:	95c2                	add	a1,a1,a6
    80005fcc:	577d                	li	a4,-1
    80005fce:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fd2:	00461713          	slli	a4,a2,0x4
    80005fd6:	6290                	ld	a2,0(a3)
    80005fd8:	963a                	add	a2,a2,a4
    80005fda:	03078793          	addi	a5,a5,48
    80005fde:	97c2                	add	a5,a5,a6
    80005fe0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005fe2:	629c                	ld	a5,0(a3)
    80005fe4:	97ba                	add	a5,a5,a4
    80005fe6:	4605                	li	a2,1
    80005fe8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fea:	629c                	ld	a5,0(a3)
    80005fec:	97ba                	add	a5,a5,a4
    80005fee:	4809                	li	a6,2
    80005ff0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005ff4:	629c                	ld	a5,0(a3)
    80005ff6:	973e                	add	a4,a4,a5
    80005ff8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005ffc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006000:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006004:	6698                	ld	a4,8(a3)
    80006006:	00275783          	lhu	a5,2(a4)
    8000600a:	8b9d                	andi	a5,a5,7
    8000600c:	0786                	slli	a5,a5,0x1
    8000600e:	97ba                	add	a5,a5,a4
    80006010:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006014:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006018:	6698                	ld	a4,8(a3)
    8000601a:	00275783          	lhu	a5,2(a4)
    8000601e:	2785                	addiw	a5,a5,1
    80006020:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006024:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006028:	100017b7          	lui	a5,0x10001
    8000602c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006030:	004aa783          	lw	a5,4(s5)
    80006034:	02c79163          	bne	a5,a2,80006056 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006038:	0001f917          	auipc	s2,0x1f
    8000603c:	0f090913          	addi	s2,s2,240 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006040:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006042:	85ca                	mv	a1,s2
    80006044:	8556                	mv	a0,s5
    80006046:	ffffc097          	auipc	ra,0xffffc
    8000604a:	000080e7          	jalr	ra # 80002046 <sleep>
  while(b->disk == 1) {
    8000604e:	004aa783          	lw	a5,4(s5)
    80006052:	fe9788e3          	beq	a5,s1,80006042 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006056:	f8042903          	lw	s2,-128(s0)
    8000605a:	20090793          	addi	a5,s2,512
    8000605e:	00479713          	slli	a4,a5,0x4
    80006062:	0001d797          	auipc	a5,0x1d
    80006066:	f9e78793          	addi	a5,a5,-98 # 80023000 <disk>
    8000606a:	97ba                	add	a5,a5,a4
    8000606c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006070:	0001f997          	auipc	s3,0x1f
    80006074:	f9098993          	addi	s3,s3,-112 # 80025000 <disk+0x2000>
    80006078:	00491713          	slli	a4,s2,0x4
    8000607c:	0009b783          	ld	a5,0(s3)
    80006080:	97ba                	add	a5,a5,a4
    80006082:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006086:	854a                	mv	a0,s2
    80006088:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000608c:	00000097          	auipc	ra,0x0
    80006090:	c5a080e7          	jalr	-934(ra) # 80005ce6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006094:	8885                	andi	s1,s1,1
    80006096:	f0ed                	bnez	s1,80006078 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006098:	0001f517          	auipc	a0,0x1f
    8000609c:	09050513          	addi	a0,a0,144 # 80025128 <disk+0x2128>
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	bd6080e7          	jalr	-1066(ra) # 80000c76 <release>
}
    800060a8:	70e6                	ld	ra,120(sp)
    800060aa:	7446                	ld	s0,112(sp)
    800060ac:	74a6                	ld	s1,104(sp)
    800060ae:	7906                	ld	s2,96(sp)
    800060b0:	69e6                	ld	s3,88(sp)
    800060b2:	6a46                	ld	s4,80(sp)
    800060b4:	6aa6                	ld	s5,72(sp)
    800060b6:	6b06                	ld	s6,64(sp)
    800060b8:	7be2                	ld	s7,56(sp)
    800060ba:	7c42                	ld	s8,48(sp)
    800060bc:	7ca2                	ld	s9,40(sp)
    800060be:	7d02                	ld	s10,32(sp)
    800060c0:	6de2                	ld	s11,24(sp)
    800060c2:	6109                	addi	sp,sp,128
    800060c4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060c6:	f8042503          	lw	a0,-128(s0)
    800060ca:	20050793          	addi	a5,a0,512
    800060ce:	0792                	slli	a5,a5,0x4
  if(write)
    800060d0:	0001d817          	auipc	a6,0x1d
    800060d4:	f3080813          	addi	a6,a6,-208 # 80023000 <disk>
    800060d8:	00f80733          	add	a4,a6,a5
    800060dc:	01a036b3          	snez	a3,s10
    800060e0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800060e4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060e8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060ec:	7679                	lui	a2,0xffffe
    800060ee:	963e                	add	a2,a2,a5
    800060f0:	0001f697          	auipc	a3,0x1f
    800060f4:	f1068693          	addi	a3,a3,-240 # 80025000 <disk+0x2000>
    800060f8:	6298                	ld	a4,0(a3)
    800060fa:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060fc:	0a878593          	addi	a1,a5,168
    80006100:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006102:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006104:	6298                	ld	a4,0(a3)
    80006106:	9732                	add	a4,a4,a2
    80006108:	45c1                	li	a1,16
    8000610a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000610c:	6298                	ld	a4,0(a3)
    8000610e:	9732                	add	a4,a4,a2
    80006110:	4585                	li	a1,1
    80006112:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006116:	f8442703          	lw	a4,-124(s0)
    8000611a:	628c                	ld	a1,0(a3)
    8000611c:	962e                	add	a2,a2,a1
    8000611e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006122:	0712                	slli	a4,a4,0x4
    80006124:	6290                	ld	a2,0(a3)
    80006126:	963a                	add	a2,a2,a4
    80006128:	058a8593          	addi	a1,s5,88
    8000612c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000612e:	6294                	ld	a3,0(a3)
    80006130:	96ba                	add	a3,a3,a4
    80006132:	40000613          	li	a2,1024
    80006136:	c690                	sw	a2,8(a3)
  if(write)
    80006138:	e40d19e3          	bnez	s10,80005f8a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000613c:	0001f697          	auipc	a3,0x1f
    80006140:	ec46b683          	ld	a3,-316(a3) # 80025000 <disk+0x2000>
    80006144:	96ba                	add	a3,a3,a4
    80006146:	4609                	li	a2,2
    80006148:	00c69623          	sh	a2,12(a3)
    8000614c:	b5b1                	j	80005f98 <virtio_disk_rw+0xd2>

000000008000614e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000614e:	1101                	addi	sp,sp,-32
    80006150:	ec06                	sd	ra,24(sp)
    80006152:	e822                	sd	s0,16(sp)
    80006154:	e426                	sd	s1,8(sp)
    80006156:	e04a                	sd	s2,0(sp)
    80006158:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000615a:	0001f517          	auipc	a0,0x1f
    8000615e:	fce50513          	addi	a0,a0,-50 # 80025128 <disk+0x2128>
    80006162:	ffffb097          	auipc	ra,0xffffb
    80006166:	a60080e7          	jalr	-1440(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000616a:	10001737          	lui	a4,0x10001
    8000616e:	533c                	lw	a5,96(a4)
    80006170:	8b8d                	andi	a5,a5,3
    80006172:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006174:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006178:	0001f797          	auipc	a5,0x1f
    8000617c:	e8878793          	addi	a5,a5,-376 # 80025000 <disk+0x2000>
    80006180:	6b94                	ld	a3,16(a5)
    80006182:	0207d703          	lhu	a4,32(a5)
    80006186:	0026d783          	lhu	a5,2(a3)
    8000618a:	06f70163          	beq	a4,a5,800061ec <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000618e:	0001d917          	auipc	s2,0x1d
    80006192:	e7290913          	addi	s2,s2,-398 # 80023000 <disk>
    80006196:	0001f497          	auipc	s1,0x1f
    8000619a:	e6a48493          	addi	s1,s1,-406 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000619e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061a2:	6898                	ld	a4,16(s1)
    800061a4:	0204d783          	lhu	a5,32(s1)
    800061a8:	8b9d                	andi	a5,a5,7
    800061aa:	078e                	slli	a5,a5,0x3
    800061ac:	97ba                	add	a5,a5,a4
    800061ae:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061b0:	20078713          	addi	a4,a5,512
    800061b4:	0712                	slli	a4,a4,0x4
    800061b6:	974a                	add	a4,a4,s2
    800061b8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061bc:	e731                	bnez	a4,80006208 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061be:	20078793          	addi	a5,a5,512
    800061c2:	0792                	slli	a5,a5,0x4
    800061c4:	97ca                	add	a5,a5,s2
    800061c6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800061c8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061cc:	ffffc097          	auipc	ra,0xffffc
    800061d0:	006080e7          	jalr	6(ra) # 800021d2 <wakeup>

    disk.used_idx += 1;
    800061d4:	0204d783          	lhu	a5,32(s1)
    800061d8:	2785                	addiw	a5,a5,1
    800061da:	17c2                	slli	a5,a5,0x30
    800061dc:	93c1                	srli	a5,a5,0x30
    800061de:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061e2:	6898                	ld	a4,16(s1)
    800061e4:	00275703          	lhu	a4,2(a4)
    800061e8:	faf71be3          	bne	a4,a5,8000619e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061ec:	0001f517          	auipc	a0,0x1f
    800061f0:	f3c50513          	addi	a0,a0,-196 # 80025128 <disk+0x2128>
    800061f4:	ffffb097          	auipc	ra,0xffffb
    800061f8:	a82080e7          	jalr	-1406(ra) # 80000c76 <release>
}
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	64a2                	ld	s1,8(sp)
    80006202:	6902                	ld	s2,0(sp)
    80006204:	6105                	addi	sp,sp,32
    80006206:	8082                	ret
      panic("virtio_disk_intr status");
    80006208:	00002517          	auipc	a0,0x2
    8000620c:	5d850513          	addi	a0,a0,1496 # 800087e0 <syscalls+0x3b0>
    80006210:	ffffa097          	auipc	ra,0xffffa
    80006214:	31a080e7          	jalr	794(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
