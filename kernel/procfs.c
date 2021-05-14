#include "types.h"
#include "stat.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "proc.h"


int 
procfsisdir(struct inode *ip) {
  return 0;
}

void 
procfsiread(struct inode* dp, struct inode *ip) {
}

int
procfsread(struct inode *ip, int user_dst, uint64 dst, int off, int n) {
  return 0;
}

int
procfswrite(struct inode *ip, int user_dst, uint64 buf, int off, int n)
{
  return 0;
}

void
procfsinit(void)
{
  devsw[PROCFS].isdir = procfsisdir;
  devsw[PROCFS].inode_read = procfsiread;
  devsw[PROCFS].write = procfswrite;
  devsw[PROCFS].read = procfsread;
}

