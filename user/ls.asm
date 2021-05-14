
user/_ls:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	312080e7          	jalr	786(ra) # 322 <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	2e6080e7          	jalr	742(ra) # 322 <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	2c4080e7          	jalr	708(ra) # 322 <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	a9a98993          	addi	s3,s3,-1382 # b00 <buf.0>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	420080e7          	jalr	1056(ra) # 496 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	2a2080e7          	jalr	674(ra) # 322 <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	294080e7          	jalr	660(ra) # 322 <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	2a4080e7          	jalr	676(ra) # 34c <memset>
  return buf;
  b0:	84ce                	mv	s1,s3
  b2:	bf69                	j	4c <fmtname+0x4c>

00000000000000b4 <ls>:

void
ls(char *path)
{
  b4:	d9010113          	addi	sp,sp,-624
  b8:	26113423          	sd	ra,616(sp)
  bc:	26813023          	sd	s0,608(sp)
  c0:	24913c23          	sd	s1,600(sp)
  c4:	25213823          	sd	s2,592(sp)
  c8:	25313423          	sd	s3,584(sp)
  cc:	25413023          	sd	s4,576(sp)
  d0:	23513c23          	sd	s5,568(sp)
  d4:	1c80                	addi	s0,sp,624
  d6:	892a                	mv	s2,a0
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
  d8:	4581                	li	a1,0
  da:	00000097          	auipc	ra,0x0
  de:	4ae080e7          	jalr	1198(ra) # 588 <open>
  e2:	04054d63          	bltz	a0,13c <ls+0x88>
  e6:	84aa                	mv	s1,a0
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  e8:	d9840593          	addi	a1,s0,-616
  ec:	00000097          	auipc	ra,0x0
  f0:	4b4080e7          	jalr	1204(ra) # 5a0 <fstat>
  f4:	04054f63          	bltz	a0,152 <ls+0x9e>
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }

  switch(st.type){
  f8:	da041783          	lh	a5,-608(s0)
  fc:	0007869b          	sext.w	a3,a5
 100:	4709                	li	a4,2
 102:	06e68863          	beq	a3,a4,172 <ls+0xbe>
 106:	9bf5                	andi	a5,a5,-3
 108:	2781                	sext.w	a5,a5
 10a:	4705                	li	a4,1
 10c:	08e78863          	beq	a5,a4,19c <ls+0xe8>
      }
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 110:	8526                	mv	a0,s1
 112:	00000097          	auipc	ra,0x0
 116:	45e080e7          	jalr	1118(ra) # 570 <close>
}
 11a:	26813083          	ld	ra,616(sp)
 11e:	26013403          	ld	s0,608(sp)
 122:	25813483          	ld	s1,600(sp)
 126:	25013903          	ld	s2,592(sp)
 12a:	24813983          	ld	s3,584(sp)
 12e:	24013a03          	ld	s4,576(sp)
 132:	23813a83          	ld	s5,568(sp)
 136:	27010113          	addi	sp,sp,624
 13a:	8082                	ret
    fprintf(2, "ls: cannot open %s\n", path);
 13c:	864a                	mv	a2,s2
 13e:	00001597          	auipc	a1,0x1
 142:	92a58593          	addi	a1,a1,-1750 # a68 <malloc+0xea>
 146:	4509                	li	a0,2
 148:	00000097          	auipc	ra,0x0
 14c:	74a080e7          	jalr	1866(ra) # 892 <fprintf>
    return;
 150:	b7e9                	j	11a <ls+0x66>
    fprintf(2, "ls: cannot stat %s\n", path);
 152:	864a                	mv	a2,s2
 154:	00001597          	auipc	a1,0x1
 158:	92c58593          	addi	a1,a1,-1748 # a80 <malloc+0x102>
 15c:	4509                	li	a0,2
 15e:	00000097          	auipc	ra,0x0
 162:	734080e7          	jalr	1844(ra) # 892 <fprintf>
    close(fd);
 166:	8526                	mv	a0,s1
 168:	00000097          	auipc	ra,0x0
 16c:	408080e7          	jalr	1032(ra) # 570 <close>
    return;
 170:	b76d                	j	11a <ls+0x66>
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 172:	854a                	mv	a0,s2
 174:	00000097          	auipc	ra,0x0
 178:	e8c080e7          	jalr	-372(ra) # 0 <fmtname>
 17c:	85aa                	mv	a1,a0
 17e:	da843703          	ld	a4,-600(s0)
 182:	d9c42683          	lw	a3,-612(s0)
 186:	da041603          	lh	a2,-608(s0)
 18a:	00001517          	auipc	a0,0x1
 18e:	90e50513          	addi	a0,a0,-1778 # a98 <malloc+0x11a>
 192:	00000097          	auipc	ra,0x0
 196:	72e080e7          	jalr	1838(ra) # 8c0 <printf>
    break;
 19a:	bf9d                	j	110 <ls+0x5c>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 19c:	854a                	mv	a0,s2
 19e:	00000097          	auipc	ra,0x0
 1a2:	184080e7          	jalr	388(ra) # 322 <strlen>
 1a6:	2541                	addiw	a0,a0,16
 1a8:	20000793          	li	a5,512
 1ac:	00a7fb63          	bgeu	a5,a0,1c2 <ls+0x10e>
      printf("ls: path too long\n");
 1b0:	00001517          	auipc	a0,0x1
 1b4:	8f850513          	addi	a0,a0,-1800 # aa8 <malloc+0x12a>
 1b8:	00000097          	auipc	ra,0x0
 1bc:	708080e7          	jalr	1800(ra) # 8c0 <printf>
      break;
 1c0:	bf81                	j	110 <ls+0x5c>
    strcpy(buf, path);
 1c2:	85ca                	mv	a1,s2
 1c4:	dc040513          	addi	a0,s0,-576
 1c8:	00000097          	auipc	ra,0x0
 1cc:	112080e7          	jalr	274(ra) # 2da <strcpy>
    p = buf+strlen(buf);
 1d0:	dc040513          	addi	a0,s0,-576
 1d4:	00000097          	auipc	ra,0x0
 1d8:	14e080e7          	jalr	334(ra) # 322 <strlen>
 1dc:	02051913          	slli	s2,a0,0x20
 1e0:	02095913          	srli	s2,s2,0x20
 1e4:	dc040793          	addi	a5,s0,-576
 1e8:	993e                	add	s2,s2,a5
    *p++ = '/';
 1ea:	00190993          	addi	s3,s2,1
 1ee:	02f00793          	li	a5,47
 1f2:	00f90023          	sb	a5,0(s2)
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 1f6:	00001a17          	auipc	s4,0x1
 1fa:	8caa0a13          	addi	s4,s4,-1846 # ac0 <malloc+0x142>
        printf("ls: cannot stat %s\n", buf);
 1fe:	00001a97          	auipc	s5,0x1
 202:	882a8a93          	addi	s5,s5,-1918 # a80 <malloc+0x102>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 206:	a801                	j	216 <ls+0x162>
        printf("ls: cannot stat %s\n", buf);
 208:	dc040593          	addi	a1,s0,-576
 20c:	8556                	mv	a0,s5
 20e:	00000097          	auipc	ra,0x0
 212:	6b2080e7          	jalr	1714(ra) # 8c0 <printf>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 216:	4641                	li	a2,16
 218:	db040593          	addi	a1,s0,-592
 21c:	8526                	mv	a0,s1
 21e:	00000097          	auipc	ra,0x0
 222:	342080e7          	jalr	834(ra) # 560 <read>
 226:	47c1                	li	a5,16
 228:	eef514e3          	bne	a0,a5,110 <ls+0x5c>
      if(de.inum == 0)
 22c:	db045783          	lhu	a5,-592(s0)
 230:	d3fd                	beqz	a5,216 <ls+0x162>
      memmove(p, de.name, DIRSIZ);
 232:	4639                	li	a2,14
 234:	db240593          	addi	a1,s0,-590
 238:	854e                	mv	a0,s3
 23a:	00000097          	auipc	ra,0x0
 23e:	25c080e7          	jalr	604(ra) # 496 <memmove>
      p[DIRSIZ] = 0;
 242:	000907a3          	sb	zero,15(s2)
      if(stat(buf, &st) < 0){
 246:	d9840593          	addi	a1,s0,-616
 24a:	dc040513          	addi	a0,s0,-576
 24e:	00000097          	auipc	ra,0x0
 252:	1b8080e7          	jalr	440(ra) # 406 <stat>
 256:	fa0549e3          	bltz	a0,208 <ls+0x154>
      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 25a:	dc040513          	addi	a0,s0,-576
 25e:	00000097          	auipc	ra,0x0
 262:	da2080e7          	jalr	-606(ra) # 0 <fmtname>
 266:	85aa                	mv	a1,a0
 268:	da843703          	ld	a4,-600(s0)
 26c:	d9c42683          	lw	a3,-612(s0)
 270:	da041603          	lh	a2,-608(s0)
 274:	8552                	mv	a0,s4
 276:	00000097          	auipc	ra,0x0
 27a:	64a080e7          	jalr	1610(ra) # 8c0 <printf>
 27e:	bf61                	j	216 <ls+0x162>

0000000000000280 <main>:

int
main(int argc, char *argv[])
{
 280:	1101                	addi	sp,sp,-32
 282:	ec06                	sd	ra,24(sp)
 284:	e822                	sd	s0,16(sp)
 286:	e426                	sd	s1,8(sp)
 288:	e04a                	sd	s2,0(sp)
 28a:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
 28c:	4785                	li	a5,1
 28e:	02a7d963          	bge	a5,a0,2c0 <main+0x40>
 292:	00858493          	addi	s1,a1,8
 296:	ffe5091b          	addiw	s2,a0,-2
 29a:	02091793          	slli	a5,s2,0x20
 29e:	01d7d913          	srli	s2,a5,0x1d
 2a2:	05c1                	addi	a1,a1,16
 2a4:	992e                	add	s2,s2,a1
    ls(".");
    exit(0);
  }
  for(i=1; i<argc; i++)
    ls(argv[i]);
 2a6:	6088                	ld	a0,0(s1)
 2a8:	00000097          	auipc	ra,0x0
 2ac:	e0c080e7          	jalr	-500(ra) # b4 <ls>
  for(i=1; i<argc; i++)
 2b0:	04a1                	addi	s1,s1,8
 2b2:	ff249ae3          	bne	s1,s2,2a6 <main+0x26>
  exit(0);
 2b6:	4501                	li	a0,0
 2b8:	00000097          	auipc	ra,0x0
 2bc:	290080e7          	jalr	656(ra) # 548 <exit>
    ls(".");
 2c0:	00001517          	auipc	a0,0x1
 2c4:	81050513          	addi	a0,a0,-2032 # ad0 <malloc+0x152>
 2c8:	00000097          	auipc	ra,0x0
 2cc:	dec080e7          	jalr	-532(ra) # b4 <ls>
    exit(0);
 2d0:	4501                	li	a0,0
 2d2:	00000097          	auipc	ra,0x0
 2d6:	276080e7          	jalr	630(ra) # 548 <exit>

00000000000002da <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2da:	1141                	addi	sp,sp,-16
 2dc:	e422                	sd	s0,8(sp)
 2de:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2e0:	87aa                	mv	a5,a0
 2e2:	0585                	addi	a1,a1,1
 2e4:	0785                	addi	a5,a5,1
 2e6:	fff5c703          	lbu	a4,-1(a1)
 2ea:	fee78fa3          	sb	a4,-1(a5)
 2ee:	fb75                	bnez	a4,2e2 <strcpy+0x8>
    ;
  return os;
}
 2f0:	6422                	ld	s0,8(sp)
 2f2:	0141                	addi	sp,sp,16
 2f4:	8082                	ret

00000000000002f6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2f6:	1141                	addi	sp,sp,-16
 2f8:	e422                	sd	s0,8(sp)
 2fa:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2fc:	00054783          	lbu	a5,0(a0)
 300:	cb91                	beqz	a5,314 <strcmp+0x1e>
 302:	0005c703          	lbu	a4,0(a1)
 306:	00f71763          	bne	a4,a5,314 <strcmp+0x1e>
    p++, q++;
 30a:	0505                	addi	a0,a0,1
 30c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 30e:	00054783          	lbu	a5,0(a0)
 312:	fbe5                	bnez	a5,302 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 314:	0005c503          	lbu	a0,0(a1)
}
 318:	40a7853b          	subw	a0,a5,a0
 31c:	6422                	ld	s0,8(sp)
 31e:	0141                	addi	sp,sp,16
 320:	8082                	ret

0000000000000322 <strlen>:

uint
strlen(const char *s)
{
 322:	1141                	addi	sp,sp,-16
 324:	e422                	sd	s0,8(sp)
 326:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 328:	00054783          	lbu	a5,0(a0)
 32c:	cf91                	beqz	a5,348 <strlen+0x26>
 32e:	0505                	addi	a0,a0,1
 330:	87aa                	mv	a5,a0
 332:	4685                	li	a3,1
 334:	9e89                	subw	a3,a3,a0
 336:	00f6853b          	addw	a0,a3,a5
 33a:	0785                	addi	a5,a5,1
 33c:	fff7c703          	lbu	a4,-1(a5)
 340:	fb7d                	bnez	a4,336 <strlen+0x14>
    ;
  return n;
}
 342:	6422                	ld	s0,8(sp)
 344:	0141                	addi	sp,sp,16
 346:	8082                	ret
  for(n = 0; s[n]; n++)
 348:	4501                	li	a0,0
 34a:	bfe5                	j	342 <strlen+0x20>

000000000000034c <memset>:

void*
memset(void *dst, int c, uint n)
{
 34c:	1141                	addi	sp,sp,-16
 34e:	e422                	sd	s0,8(sp)
 350:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 352:	ca19                	beqz	a2,368 <memset+0x1c>
 354:	87aa                	mv	a5,a0
 356:	1602                	slli	a2,a2,0x20
 358:	9201                	srli	a2,a2,0x20
 35a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 35e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 362:	0785                	addi	a5,a5,1
 364:	fee79de3          	bne	a5,a4,35e <memset+0x12>
  }
  return dst;
}
 368:	6422                	ld	s0,8(sp)
 36a:	0141                	addi	sp,sp,16
 36c:	8082                	ret

000000000000036e <strchr>:

char*
strchr(const char *s, char c)
{
 36e:	1141                	addi	sp,sp,-16
 370:	e422                	sd	s0,8(sp)
 372:	0800                	addi	s0,sp,16
  for(; *s; s++)
 374:	00054783          	lbu	a5,0(a0)
 378:	cb99                	beqz	a5,38e <strchr+0x20>
    if(*s == c)
 37a:	00f58763          	beq	a1,a5,388 <strchr+0x1a>
  for(; *s; s++)
 37e:	0505                	addi	a0,a0,1
 380:	00054783          	lbu	a5,0(a0)
 384:	fbfd                	bnez	a5,37a <strchr+0xc>
      return (char*)s;
  return 0;
 386:	4501                	li	a0,0
}
 388:	6422                	ld	s0,8(sp)
 38a:	0141                	addi	sp,sp,16
 38c:	8082                	ret
  return 0;
 38e:	4501                	li	a0,0
 390:	bfe5                	j	388 <strchr+0x1a>

0000000000000392 <gets>:

char*
gets(char *buf, int max)
{
 392:	711d                	addi	sp,sp,-96
 394:	ec86                	sd	ra,88(sp)
 396:	e8a2                	sd	s0,80(sp)
 398:	e4a6                	sd	s1,72(sp)
 39a:	e0ca                	sd	s2,64(sp)
 39c:	fc4e                	sd	s3,56(sp)
 39e:	f852                	sd	s4,48(sp)
 3a0:	f456                	sd	s5,40(sp)
 3a2:	f05a                	sd	s6,32(sp)
 3a4:	ec5e                	sd	s7,24(sp)
 3a6:	1080                	addi	s0,sp,96
 3a8:	8baa                	mv	s7,a0
 3aa:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3ac:	892a                	mv	s2,a0
 3ae:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3b0:	4aa9                	li	s5,10
 3b2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3b4:	89a6                	mv	s3,s1
 3b6:	2485                	addiw	s1,s1,1
 3b8:	0344d863          	bge	s1,s4,3e8 <gets+0x56>
    cc = read(0, &c, 1);
 3bc:	4605                	li	a2,1
 3be:	faf40593          	addi	a1,s0,-81
 3c2:	4501                	li	a0,0
 3c4:	00000097          	auipc	ra,0x0
 3c8:	19c080e7          	jalr	412(ra) # 560 <read>
    if(cc < 1)
 3cc:	00a05e63          	blez	a0,3e8 <gets+0x56>
    buf[i++] = c;
 3d0:	faf44783          	lbu	a5,-81(s0)
 3d4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3d8:	01578763          	beq	a5,s5,3e6 <gets+0x54>
 3dc:	0905                	addi	s2,s2,1
 3de:	fd679be3          	bne	a5,s6,3b4 <gets+0x22>
  for(i=0; i+1 < max; ){
 3e2:	89a6                	mv	s3,s1
 3e4:	a011                	j	3e8 <gets+0x56>
 3e6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3e8:	99de                	add	s3,s3,s7
 3ea:	00098023          	sb	zero,0(s3)
  return buf;
}
 3ee:	855e                	mv	a0,s7
 3f0:	60e6                	ld	ra,88(sp)
 3f2:	6446                	ld	s0,80(sp)
 3f4:	64a6                	ld	s1,72(sp)
 3f6:	6906                	ld	s2,64(sp)
 3f8:	79e2                	ld	s3,56(sp)
 3fa:	7a42                	ld	s4,48(sp)
 3fc:	7aa2                	ld	s5,40(sp)
 3fe:	7b02                	ld	s6,32(sp)
 400:	6be2                	ld	s7,24(sp)
 402:	6125                	addi	sp,sp,96
 404:	8082                	ret

0000000000000406 <stat>:

int
stat(const char *n, struct stat *st)
{
 406:	1101                	addi	sp,sp,-32
 408:	ec06                	sd	ra,24(sp)
 40a:	e822                	sd	s0,16(sp)
 40c:	e426                	sd	s1,8(sp)
 40e:	e04a                	sd	s2,0(sp)
 410:	1000                	addi	s0,sp,32
 412:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 414:	4581                	li	a1,0
 416:	00000097          	auipc	ra,0x0
 41a:	172080e7          	jalr	370(ra) # 588 <open>
  if(fd < 0)
 41e:	02054563          	bltz	a0,448 <stat+0x42>
 422:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 424:	85ca                	mv	a1,s2
 426:	00000097          	auipc	ra,0x0
 42a:	17a080e7          	jalr	378(ra) # 5a0 <fstat>
 42e:	892a                	mv	s2,a0
  close(fd);
 430:	8526                	mv	a0,s1
 432:	00000097          	auipc	ra,0x0
 436:	13e080e7          	jalr	318(ra) # 570 <close>
  return r;
}
 43a:	854a                	mv	a0,s2
 43c:	60e2                	ld	ra,24(sp)
 43e:	6442                	ld	s0,16(sp)
 440:	64a2                	ld	s1,8(sp)
 442:	6902                	ld	s2,0(sp)
 444:	6105                	addi	sp,sp,32
 446:	8082                	ret
    return -1;
 448:	597d                	li	s2,-1
 44a:	bfc5                	j	43a <stat+0x34>

000000000000044c <atoi>:

int
atoi(const char *s)
{
 44c:	1141                	addi	sp,sp,-16
 44e:	e422                	sd	s0,8(sp)
 450:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 452:	00054603          	lbu	a2,0(a0)
 456:	fd06079b          	addiw	a5,a2,-48
 45a:	0ff7f793          	andi	a5,a5,255
 45e:	4725                	li	a4,9
 460:	02f76963          	bltu	a4,a5,492 <atoi+0x46>
 464:	86aa                	mv	a3,a0
  n = 0;
 466:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 468:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 46a:	0685                	addi	a3,a3,1
 46c:	0025179b          	slliw	a5,a0,0x2
 470:	9fa9                	addw	a5,a5,a0
 472:	0017979b          	slliw	a5,a5,0x1
 476:	9fb1                	addw	a5,a5,a2
 478:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 47c:	0006c603          	lbu	a2,0(a3)
 480:	fd06071b          	addiw	a4,a2,-48
 484:	0ff77713          	andi	a4,a4,255
 488:	fee5f1e3          	bgeu	a1,a4,46a <atoi+0x1e>
  return n;
}
 48c:	6422                	ld	s0,8(sp)
 48e:	0141                	addi	sp,sp,16
 490:	8082                	ret
  n = 0;
 492:	4501                	li	a0,0
 494:	bfe5                	j	48c <atoi+0x40>

0000000000000496 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 496:	1141                	addi	sp,sp,-16
 498:	e422                	sd	s0,8(sp)
 49a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 49c:	02b57463          	bgeu	a0,a1,4c4 <memmove+0x2e>
    while(n-- > 0)
 4a0:	00c05f63          	blez	a2,4be <memmove+0x28>
 4a4:	1602                	slli	a2,a2,0x20
 4a6:	9201                	srli	a2,a2,0x20
 4a8:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4ac:	872a                	mv	a4,a0
      *dst++ = *src++;
 4ae:	0585                	addi	a1,a1,1
 4b0:	0705                	addi	a4,a4,1
 4b2:	fff5c683          	lbu	a3,-1(a1)
 4b6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4ba:	fee79ae3          	bne	a5,a4,4ae <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4be:	6422                	ld	s0,8(sp)
 4c0:	0141                	addi	sp,sp,16
 4c2:	8082                	ret
    dst += n;
 4c4:	00c50733          	add	a4,a0,a2
    src += n;
 4c8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4ca:	fec05ae3          	blez	a2,4be <memmove+0x28>
 4ce:	fff6079b          	addiw	a5,a2,-1
 4d2:	1782                	slli	a5,a5,0x20
 4d4:	9381                	srli	a5,a5,0x20
 4d6:	fff7c793          	not	a5,a5
 4da:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4dc:	15fd                	addi	a1,a1,-1
 4de:	177d                	addi	a4,a4,-1
 4e0:	0005c683          	lbu	a3,0(a1)
 4e4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4e8:	fee79ae3          	bne	a5,a4,4dc <memmove+0x46>
 4ec:	bfc9                	j	4be <memmove+0x28>

00000000000004ee <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4ee:	1141                	addi	sp,sp,-16
 4f0:	e422                	sd	s0,8(sp)
 4f2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4f4:	ca05                	beqz	a2,524 <memcmp+0x36>
 4f6:	fff6069b          	addiw	a3,a2,-1
 4fa:	1682                	slli	a3,a3,0x20
 4fc:	9281                	srli	a3,a3,0x20
 4fe:	0685                	addi	a3,a3,1
 500:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 502:	00054783          	lbu	a5,0(a0)
 506:	0005c703          	lbu	a4,0(a1)
 50a:	00e79863          	bne	a5,a4,51a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 50e:	0505                	addi	a0,a0,1
    p2++;
 510:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 512:	fed518e3          	bne	a0,a3,502 <memcmp+0x14>
  }
  return 0;
 516:	4501                	li	a0,0
 518:	a019                	j	51e <memcmp+0x30>
      return *p1 - *p2;
 51a:	40e7853b          	subw	a0,a5,a4
}
 51e:	6422                	ld	s0,8(sp)
 520:	0141                	addi	sp,sp,16
 522:	8082                	ret
  return 0;
 524:	4501                	li	a0,0
 526:	bfe5                	j	51e <memcmp+0x30>

0000000000000528 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 528:	1141                	addi	sp,sp,-16
 52a:	e406                	sd	ra,8(sp)
 52c:	e022                	sd	s0,0(sp)
 52e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 530:	00000097          	auipc	ra,0x0
 534:	f66080e7          	jalr	-154(ra) # 496 <memmove>
}
 538:	60a2                	ld	ra,8(sp)
 53a:	6402                	ld	s0,0(sp)
 53c:	0141                	addi	sp,sp,16
 53e:	8082                	ret

0000000000000540 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 540:	4885                	li	a7,1
 ecall
 542:	00000073          	ecall
 ret
 546:	8082                	ret

0000000000000548 <exit>:
.global exit
exit:
 li a7, SYS_exit
 548:	4889                	li	a7,2
 ecall
 54a:	00000073          	ecall
 ret
 54e:	8082                	ret

0000000000000550 <wait>:
.global wait
wait:
 li a7, SYS_wait
 550:	488d                	li	a7,3
 ecall
 552:	00000073          	ecall
 ret
 556:	8082                	ret

0000000000000558 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 558:	4891                	li	a7,4
 ecall
 55a:	00000073          	ecall
 ret
 55e:	8082                	ret

0000000000000560 <read>:
.global read
read:
 li a7, SYS_read
 560:	4895                	li	a7,5
 ecall
 562:	00000073          	ecall
 ret
 566:	8082                	ret

0000000000000568 <write>:
.global write
write:
 li a7, SYS_write
 568:	48c1                	li	a7,16
 ecall
 56a:	00000073          	ecall
 ret
 56e:	8082                	ret

0000000000000570 <close>:
.global close
close:
 li a7, SYS_close
 570:	48d5                	li	a7,21
 ecall
 572:	00000073          	ecall
 ret
 576:	8082                	ret

0000000000000578 <kill>:
.global kill
kill:
 li a7, SYS_kill
 578:	4899                	li	a7,6
 ecall
 57a:	00000073          	ecall
 ret
 57e:	8082                	ret

0000000000000580 <exec>:
.global exec
exec:
 li a7, SYS_exec
 580:	489d                	li	a7,7
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <open>:
.global open
open:
 li a7, SYS_open
 588:	48bd                	li	a7,15
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 590:	48c5                	li	a7,17
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 598:	48c9                	li	a7,18
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5a0:	48a1                	li	a7,8
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <link>:
.global link
link:
 li a7, SYS_link
 5a8:	48cd                	li	a7,19
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5b0:	48d1                	li	a7,20
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5b8:	48a5                	li	a7,9
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5c0:	48a9                	li	a7,10
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5c8:	48ad                	li	a7,11
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5d0:	48b1                	li	a7,12
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5d8:	48b5                	li	a7,13
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5e0:	48b9                	li	a7,14
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5e8:	1101                	addi	sp,sp,-32
 5ea:	ec06                	sd	ra,24(sp)
 5ec:	e822                	sd	s0,16(sp)
 5ee:	1000                	addi	s0,sp,32
 5f0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5f4:	4605                	li	a2,1
 5f6:	fef40593          	addi	a1,s0,-17
 5fa:	00000097          	auipc	ra,0x0
 5fe:	f6e080e7          	jalr	-146(ra) # 568 <write>
}
 602:	60e2                	ld	ra,24(sp)
 604:	6442                	ld	s0,16(sp)
 606:	6105                	addi	sp,sp,32
 608:	8082                	ret

000000000000060a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 60a:	7139                	addi	sp,sp,-64
 60c:	fc06                	sd	ra,56(sp)
 60e:	f822                	sd	s0,48(sp)
 610:	f426                	sd	s1,40(sp)
 612:	f04a                	sd	s2,32(sp)
 614:	ec4e                	sd	s3,24(sp)
 616:	0080                	addi	s0,sp,64
 618:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 61a:	c299                	beqz	a3,620 <printint+0x16>
 61c:	0805c863          	bltz	a1,6ac <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 620:	2581                	sext.w	a1,a1
  neg = 0;
 622:	4881                	li	a7,0
 624:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 628:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 62a:	2601                	sext.w	a2,a2
 62c:	00000517          	auipc	a0,0x0
 630:	4b450513          	addi	a0,a0,1204 # ae0 <digits>
 634:	883a                	mv	a6,a4
 636:	2705                	addiw	a4,a4,1
 638:	02c5f7bb          	remuw	a5,a1,a2
 63c:	1782                	slli	a5,a5,0x20
 63e:	9381                	srli	a5,a5,0x20
 640:	97aa                	add	a5,a5,a0
 642:	0007c783          	lbu	a5,0(a5)
 646:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 64a:	0005879b          	sext.w	a5,a1
 64e:	02c5d5bb          	divuw	a1,a1,a2
 652:	0685                	addi	a3,a3,1
 654:	fec7f0e3          	bgeu	a5,a2,634 <printint+0x2a>
  if(neg)
 658:	00088b63          	beqz	a7,66e <printint+0x64>
    buf[i++] = '-';
 65c:	fd040793          	addi	a5,s0,-48
 660:	973e                	add	a4,a4,a5
 662:	02d00793          	li	a5,45
 666:	fef70823          	sb	a5,-16(a4)
 66a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 66e:	02e05863          	blez	a4,69e <printint+0x94>
 672:	fc040793          	addi	a5,s0,-64
 676:	00e78933          	add	s2,a5,a4
 67a:	fff78993          	addi	s3,a5,-1
 67e:	99ba                	add	s3,s3,a4
 680:	377d                	addiw	a4,a4,-1
 682:	1702                	slli	a4,a4,0x20
 684:	9301                	srli	a4,a4,0x20
 686:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 68a:	fff94583          	lbu	a1,-1(s2)
 68e:	8526                	mv	a0,s1
 690:	00000097          	auipc	ra,0x0
 694:	f58080e7          	jalr	-168(ra) # 5e8 <putc>
  while(--i >= 0)
 698:	197d                	addi	s2,s2,-1
 69a:	ff3918e3          	bne	s2,s3,68a <printint+0x80>
}
 69e:	70e2                	ld	ra,56(sp)
 6a0:	7442                	ld	s0,48(sp)
 6a2:	74a2                	ld	s1,40(sp)
 6a4:	7902                	ld	s2,32(sp)
 6a6:	69e2                	ld	s3,24(sp)
 6a8:	6121                	addi	sp,sp,64
 6aa:	8082                	ret
    x = -xx;
 6ac:	40b005bb          	negw	a1,a1
    neg = 1;
 6b0:	4885                	li	a7,1
    x = -xx;
 6b2:	bf8d                	j	624 <printint+0x1a>

00000000000006b4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6b4:	7119                	addi	sp,sp,-128
 6b6:	fc86                	sd	ra,120(sp)
 6b8:	f8a2                	sd	s0,112(sp)
 6ba:	f4a6                	sd	s1,104(sp)
 6bc:	f0ca                	sd	s2,96(sp)
 6be:	ecce                	sd	s3,88(sp)
 6c0:	e8d2                	sd	s4,80(sp)
 6c2:	e4d6                	sd	s5,72(sp)
 6c4:	e0da                	sd	s6,64(sp)
 6c6:	fc5e                	sd	s7,56(sp)
 6c8:	f862                	sd	s8,48(sp)
 6ca:	f466                	sd	s9,40(sp)
 6cc:	f06a                	sd	s10,32(sp)
 6ce:	ec6e                	sd	s11,24(sp)
 6d0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6d2:	0005c903          	lbu	s2,0(a1)
 6d6:	18090f63          	beqz	s2,874 <vprintf+0x1c0>
 6da:	8aaa                	mv	s5,a0
 6dc:	8b32                	mv	s6,a2
 6de:	00158493          	addi	s1,a1,1
  state = 0;
 6e2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6e4:	02500a13          	li	s4,37
      if(c == 'd'){
 6e8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6ec:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6f0:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6f4:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6f8:	00000b97          	auipc	s7,0x0
 6fc:	3e8b8b93          	addi	s7,s7,1000 # ae0 <digits>
 700:	a839                	j	71e <vprintf+0x6a>
        putc(fd, c);
 702:	85ca                	mv	a1,s2
 704:	8556                	mv	a0,s5
 706:	00000097          	auipc	ra,0x0
 70a:	ee2080e7          	jalr	-286(ra) # 5e8 <putc>
 70e:	a019                	j	714 <vprintf+0x60>
    } else if(state == '%'){
 710:	01498f63          	beq	s3,s4,72e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 714:	0485                	addi	s1,s1,1
 716:	fff4c903          	lbu	s2,-1(s1)
 71a:	14090d63          	beqz	s2,874 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 71e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 722:	fe0997e3          	bnez	s3,710 <vprintf+0x5c>
      if(c == '%'){
 726:	fd479ee3          	bne	a5,s4,702 <vprintf+0x4e>
        state = '%';
 72a:	89be                	mv	s3,a5
 72c:	b7e5                	j	714 <vprintf+0x60>
      if(c == 'd'){
 72e:	05878063          	beq	a5,s8,76e <vprintf+0xba>
      } else if(c == 'l') {
 732:	05978c63          	beq	a5,s9,78a <vprintf+0xd6>
      } else if(c == 'x') {
 736:	07a78863          	beq	a5,s10,7a6 <vprintf+0xf2>
      } else if(c == 'p') {
 73a:	09b78463          	beq	a5,s11,7c2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 73e:	07300713          	li	a4,115
 742:	0ce78663          	beq	a5,a4,80e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 746:	06300713          	li	a4,99
 74a:	0ee78e63          	beq	a5,a4,846 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 74e:	11478863          	beq	a5,s4,85e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 752:	85d2                	mv	a1,s4
 754:	8556                	mv	a0,s5
 756:	00000097          	auipc	ra,0x0
 75a:	e92080e7          	jalr	-366(ra) # 5e8 <putc>
        putc(fd, c);
 75e:	85ca                	mv	a1,s2
 760:	8556                	mv	a0,s5
 762:	00000097          	auipc	ra,0x0
 766:	e86080e7          	jalr	-378(ra) # 5e8 <putc>
      }
      state = 0;
 76a:	4981                	li	s3,0
 76c:	b765                	j	714 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 76e:	008b0913          	addi	s2,s6,8
 772:	4685                	li	a3,1
 774:	4629                	li	a2,10
 776:	000b2583          	lw	a1,0(s6)
 77a:	8556                	mv	a0,s5
 77c:	00000097          	auipc	ra,0x0
 780:	e8e080e7          	jalr	-370(ra) # 60a <printint>
 784:	8b4a                	mv	s6,s2
      state = 0;
 786:	4981                	li	s3,0
 788:	b771                	j	714 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 78a:	008b0913          	addi	s2,s6,8
 78e:	4681                	li	a3,0
 790:	4629                	li	a2,10
 792:	000b2583          	lw	a1,0(s6)
 796:	8556                	mv	a0,s5
 798:	00000097          	auipc	ra,0x0
 79c:	e72080e7          	jalr	-398(ra) # 60a <printint>
 7a0:	8b4a                	mv	s6,s2
      state = 0;
 7a2:	4981                	li	s3,0
 7a4:	bf85                	j	714 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7a6:	008b0913          	addi	s2,s6,8
 7aa:	4681                	li	a3,0
 7ac:	4641                	li	a2,16
 7ae:	000b2583          	lw	a1,0(s6)
 7b2:	8556                	mv	a0,s5
 7b4:	00000097          	auipc	ra,0x0
 7b8:	e56080e7          	jalr	-426(ra) # 60a <printint>
 7bc:	8b4a                	mv	s6,s2
      state = 0;
 7be:	4981                	li	s3,0
 7c0:	bf91                	j	714 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7c2:	008b0793          	addi	a5,s6,8
 7c6:	f8f43423          	sd	a5,-120(s0)
 7ca:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7ce:	03000593          	li	a1,48
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	e14080e7          	jalr	-492(ra) # 5e8 <putc>
  putc(fd, 'x');
 7dc:	85ea                	mv	a1,s10
 7de:	8556                	mv	a0,s5
 7e0:	00000097          	auipc	ra,0x0
 7e4:	e08080e7          	jalr	-504(ra) # 5e8 <putc>
 7e8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7ea:	03c9d793          	srli	a5,s3,0x3c
 7ee:	97de                	add	a5,a5,s7
 7f0:	0007c583          	lbu	a1,0(a5)
 7f4:	8556                	mv	a0,s5
 7f6:	00000097          	auipc	ra,0x0
 7fa:	df2080e7          	jalr	-526(ra) # 5e8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7fe:	0992                	slli	s3,s3,0x4
 800:	397d                	addiw	s2,s2,-1
 802:	fe0914e3          	bnez	s2,7ea <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 806:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 80a:	4981                	li	s3,0
 80c:	b721                	j	714 <vprintf+0x60>
        s = va_arg(ap, char*);
 80e:	008b0993          	addi	s3,s6,8
 812:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 816:	02090163          	beqz	s2,838 <vprintf+0x184>
        while(*s != 0){
 81a:	00094583          	lbu	a1,0(s2)
 81e:	c9a1                	beqz	a1,86e <vprintf+0x1ba>
          putc(fd, *s);
 820:	8556                	mv	a0,s5
 822:	00000097          	auipc	ra,0x0
 826:	dc6080e7          	jalr	-570(ra) # 5e8 <putc>
          s++;
 82a:	0905                	addi	s2,s2,1
        while(*s != 0){
 82c:	00094583          	lbu	a1,0(s2)
 830:	f9e5                	bnez	a1,820 <vprintf+0x16c>
        s = va_arg(ap, char*);
 832:	8b4e                	mv	s6,s3
      state = 0;
 834:	4981                	li	s3,0
 836:	bdf9                	j	714 <vprintf+0x60>
          s = "(null)";
 838:	00000917          	auipc	s2,0x0
 83c:	2a090913          	addi	s2,s2,672 # ad8 <malloc+0x15a>
        while(*s != 0){
 840:	02800593          	li	a1,40
 844:	bff1                	j	820 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 846:	008b0913          	addi	s2,s6,8
 84a:	000b4583          	lbu	a1,0(s6)
 84e:	8556                	mv	a0,s5
 850:	00000097          	auipc	ra,0x0
 854:	d98080e7          	jalr	-616(ra) # 5e8 <putc>
 858:	8b4a                	mv	s6,s2
      state = 0;
 85a:	4981                	li	s3,0
 85c:	bd65                	j	714 <vprintf+0x60>
        putc(fd, c);
 85e:	85d2                	mv	a1,s4
 860:	8556                	mv	a0,s5
 862:	00000097          	auipc	ra,0x0
 866:	d86080e7          	jalr	-634(ra) # 5e8 <putc>
      state = 0;
 86a:	4981                	li	s3,0
 86c:	b565                	j	714 <vprintf+0x60>
        s = va_arg(ap, char*);
 86e:	8b4e                	mv	s6,s3
      state = 0;
 870:	4981                	li	s3,0
 872:	b54d                	j	714 <vprintf+0x60>
    }
  }
}
 874:	70e6                	ld	ra,120(sp)
 876:	7446                	ld	s0,112(sp)
 878:	74a6                	ld	s1,104(sp)
 87a:	7906                	ld	s2,96(sp)
 87c:	69e6                	ld	s3,88(sp)
 87e:	6a46                	ld	s4,80(sp)
 880:	6aa6                	ld	s5,72(sp)
 882:	6b06                	ld	s6,64(sp)
 884:	7be2                	ld	s7,56(sp)
 886:	7c42                	ld	s8,48(sp)
 888:	7ca2                	ld	s9,40(sp)
 88a:	7d02                	ld	s10,32(sp)
 88c:	6de2                	ld	s11,24(sp)
 88e:	6109                	addi	sp,sp,128
 890:	8082                	ret

0000000000000892 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 892:	715d                	addi	sp,sp,-80
 894:	ec06                	sd	ra,24(sp)
 896:	e822                	sd	s0,16(sp)
 898:	1000                	addi	s0,sp,32
 89a:	e010                	sd	a2,0(s0)
 89c:	e414                	sd	a3,8(s0)
 89e:	e818                	sd	a4,16(s0)
 8a0:	ec1c                	sd	a5,24(s0)
 8a2:	03043023          	sd	a6,32(s0)
 8a6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8aa:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8ae:	8622                	mv	a2,s0
 8b0:	00000097          	auipc	ra,0x0
 8b4:	e04080e7          	jalr	-508(ra) # 6b4 <vprintf>
}
 8b8:	60e2                	ld	ra,24(sp)
 8ba:	6442                	ld	s0,16(sp)
 8bc:	6161                	addi	sp,sp,80
 8be:	8082                	ret

00000000000008c0 <printf>:

void
printf(const char *fmt, ...)
{
 8c0:	711d                	addi	sp,sp,-96
 8c2:	ec06                	sd	ra,24(sp)
 8c4:	e822                	sd	s0,16(sp)
 8c6:	1000                	addi	s0,sp,32
 8c8:	e40c                	sd	a1,8(s0)
 8ca:	e810                	sd	a2,16(s0)
 8cc:	ec14                	sd	a3,24(s0)
 8ce:	f018                	sd	a4,32(s0)
 8d0:	f41c                	sd	a5,40(s0)
 8d2:	03043823          	sd	a6,48(s0)
 8d6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8da:	00840613          	addi	a2,s0,8
 8de:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8e2:	85aa                	mv	a1,a0
 8e4:	4505                	li	a0,1
 8e6:	00000097          	auipc	ra,0x0
 8ea:	dce080e7          	jalr	-562(ra) # 6b4 <vprintf>
}
 8ee:	60e2                	ld	ra,24(sp)
 8f0:	6442                	ld	s0,16(sp)
 8f2:	6125                	addi	sp,sp,96
 8f4:	8082                	ret

00000000000008f6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8f6:	1141                	addi	sp,sp,-16
 8f8:	e422                	sd	s0,8(sp)
 8fa:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8fc:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 900:	00000797          	auipc	a5,0x0
 904:	1f87b783          	ld	a5,504(a5) # af8 <freep>
 908:	a805                	j	938 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 90a:	4618                	lw	a4,8(a2)
 90c:	9db9                	addw	a1,a1,a4
 90e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 912:	6398                	ld	a4,0(a5)
 914:	6318                	ld	a4,0(a4)
 916:	fee53823          	sd	a4,-16(a0)
 91a:	a091                	j	95e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 91c:	ff852703          	lw	a4,-8(a0)
 920:	9e39                	addw	a2,a2,a4
 922:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 924:	ff053703          	ld	a4,-16(a0)
 928:	e398                	sd	a4,0(a5)
 92a:	a099                	j	970 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 92c:	6398                	ld	a4,0(a5)
 92e:	00e7e463          	bltu	a5,a4,936 <free+0x40>
 932:	00e6ea63          	bltu	a3,a4,946 <free+0x50>
{
 936:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 938:	fed7fae3          	bgeu	a5,a3,92c <free+0x36>
 93c:	6398                	ld	a4,0(a5)
 93e:	00e6e463          	bltu	a3,a4,946 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 942:	fee7eae3          	bltu	a5,a4,936 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 946:	ff852583          	lw	a1,-8(a0)
 94a:	6390                	ld	a2,0(a5)
 94c:	02059813          	slli	a6,a1,0x20
 950:	01c85713          	srli	a4,a6,0x1c
 954:	9736                	add	a4,a4,a3
 956:	fae60ae3          	beq	a2,a4,90a <free+0x14>
    bp->s.ptr = p->s.ptr;
 95a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 95e:	4790                	lw	a2,8(a5)
 960:	02061593          	slli	a1,a2,0x20
 964:	01c5d713          	srli	a4,a1,0x1c
 968:	973e                	add	a4,a4,a5
 96a:	fae689e3          	beq	a3,a4,91c <free+0x26>
  } else
    p->s.ptr = bp;
 96e:	e394                	sd	a3,0(a5)
  freep = p;
 970:	00000717          	auipc	a4,0x0
 974:	18f73423          	sd	a5,392(a4) # af8 <freep>
}
 978:	6422                	ld	s0,8(sp)
 97a:	0141                	addi	sp,sp,16
 97c:	8082                	ret

000000000000097e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 97e:	7139                	addi	sp,sp,-64
 980:	fc06                	sd	ra,56(sp)
 982:	f822                	sd	s0,48(sp)
 984:	f426                	sd	s1,40(sp)
 986:	f04a                	sd	s2,32(sp)
 988:	ec4e                	sd	s3,24(sp)
 98a:	e852                	sd	s4,16(sp)
 98c:	e456                	sd	s5,8(sp)
 98e:	e05a                	sd	s6,0(sp)
 990:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 992:	02051493          	slli	s1,a0,0x20
 996:	9081                	srli	s1,s1,0x20
 998:	04bd                	addi	s1,s1,15
 99a:	8091                	srli	s1,s1,0x4
 99c:	0014899b          	addiw	s3,s1,1
 9a0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9a2:	00000517          	auipc	a0,0x0
 9a6:	15653503          	ld	a0,342(a0) # af8 <freep>
 9aa:	c515                	beqz	a0,9d6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9ac:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9ae:	4798                	lw	a4,8(a5)
 9b0:	02977f63          	bgeu	a4,s1,9ee <malloc+0x70>
 9b4:	8a4e                	mv	s4,s3
 9b6:	0009871b          	sext.w	a4,s3
 9ba:	6685                	lui	a3,0x1
 9bc:	00d77363          	bgeu	a4,a3,9c2 <malloc+0x44>
 9c0:	6a05                	lui	s4,0x1
 9c2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9c6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9ca:	00000917          	auipc	s2,0x0
 9ce:	12e90913          	addi	s2,s2,302 # af8 <freep>
  if(p == (char*)-1)
 9d2:	5afd                	li	s5,-1
 9d4:	a895                	j	a48 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 9d6:	00000797          	auipc	a5,0x0
 9da:	13a78793          	addi	a5,a5,314 # b10 <base>
 9de:	00000717          	auipc	a4,0x0
 9e2:	10f73d23          	sd	a5,282(a4) # af8 <freep>
 9e6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9e8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9ec:	b7e1                	j	9b4 <malloc+0x36>
      if(p->s.size == nunits)
 9ee:	02e48c63          	beq	s1,a4,a26 <malloc+0xa8>
        p->s.size -= nunits;
 9f2:	4137073b          	subw	a4,a4,s3
 9f6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9f8:	02071693          	slli	a3,a4,0x20
 9fc:	01c6d713          	srli	a4,a3,0x1c
 a00:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a02:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a06:	00000717          	auipc	a4,0x0
 a0a:	0ea73923          	sd	a0,242(a4) # af8 <freep>
      return (void*)(p + 1);
 a0e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a12:	70e2                	ld	ra,56(sp)
 a14:	7442                	ld	s0,48(sp)
 a16:	74a2                	ld	s1,40(sp)
 a18:	7902                	ld	s2,32(sp)
 a1a:	69e2                	ld	s3,24(sp)
 a1c:	6a42                	ld	s4,16(sp)
 a1e:	6aa2                	ld	s5,8(sp)
 a20:	6b02                	ld	s6,0(sp)
 a22:	6121                	addi	sp,sp,64
 a24:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a26:	6398                	ld	a4,0(a5)
 a28:	e118                	sd	a4,0(a0)
 a2a:	bff1                	j	a06 <malloc+0x88>
  hp->s.size = nu;
 a2c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a30:	0541                	addi	a0,a0,16
 a32:	00000097          	auipc	ra,0x0
 a36:	ec4080e7          	jalr	-316(ra) # 8f6 <free>
  return freep;
 a3a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a3e:	d971                	beqz	a0,a12 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a40:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a42:	4798                	lw	a4,8(a5)
 a44:	fa9775e3          	bgeu	a4,s1,9ee <malloc+0x70>
    if(p == freep)
 a48:	00093703          	ld	a4,0(s2)
 a4c:	853e                	mv	a0,a5
 a4e:	fef719e3          	bne	a4,a5,a40 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 a52:	8552                	mv	a0,s4
 a54:	00000097          	auipc	ra,0x0
 a58:	b7c080e7          	jalr	-1156(ra) # 5d0 <sbrk>
  if(p == (char*)-1)
 a5c:	fd5518e3          	bne	a0,s5,a2c <malloc+0xae>
        return 0;
 a60:	4501                	li	a0,0
 a62:	bf45                	j	a12 <malloc+0x94>
