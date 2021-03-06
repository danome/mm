/*
 * ms_unix.c - Mass Storage Interface - Unix version
 * Copyright 2006, 2010, Eric B. Decker
 * Mam-Mark Project
 *
 * Low level interface for Unix based boxes.
 * Tested on Linux and Mac OS X.
 *
 * Sep 2010, added support for Panic0 (sector 2) block.
 */


#include <mm_types.h>
#include <mm_byteswap.h>

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#include <ms.h>
#include <ms_util.h>
#include <fs_loc.h>


static int fd = -1;

#if defined(__APPLE__)
#define loff_t		off_t
#define lseek64		lseek
#elif defined(__linux__)
extern __off64_t lseek64(int __fd, __off64_t __offset, int __whence);
#endif


fs_loc_t loc;
uint32_t msc_dblk_nxt;                  /* 1st empty dblk */

uint32_t     msc_panic0_blk;            /* panic control block, where it lives */
panic0_hdr_t p0c;			/* panic0 control */

uint8_t ms_buf[MS_BUF_SIZE];

extern int verbose;
extern int debug;

int
check_panic0_values(panic0_hdr_t *p) {
  int rtn;
  uint32_t start, end;

  rtn = 0;
  start = loc.locators[FS_LOC_PANIC].start;
  end   = loc.locators[FS_LOC_PANIC].end;
  if (start != p->panic_start) {
    fprintf(stderr, "*** panic0 mismatch: (start) %x/%x\n",
	    start, p->panic_start);
    rtn = 1;
  }
  if (end != p->panic_end) {
    fprintf(stderr, "*** panic0 mismatch: (end) %x/%x\n",
	    end, p->panic_end);
    rtn = 1;
  }
  return rtn;
}


ms_rtn
ms_init(char *device_name) {
    fs_loc_t  *fsl;
    panic0_hdr_t *php;
    uint32_t   blk, lower, upper;
    int        empty;
    uint8_t   *dp;
    ms_rtn     rtn;

    assert(device_name);
    rtn = MS_OK;
    fd = open(device_name, O_RDWR);
    if (fd < 0) {
	if (errno != EROFS) {
	    fprintf(stderr, "ms_init: open fail: %s, %s (%d)\n",
		    device_name, strerror(errno), errno);
	    return MS_INTERNAL;
	}
	if (verbose)
	  fprintf(stderr, "ms_init: ROFS, trying read only\n");
	fd = open(device_name, O_RDONLY);
	if (fd < 0) {
	    fprintf(stderr, "ms_init: readonly open fail: %s, %s (%d)\n",
		    device_name, strerror(errno), errno);
	    return MS_INTERNAL;
	}
	rtn = MS_READONLY;
    }

    /*
     * locator (loc) is initilized to zeros by the bss zero
     * ditto for other globals.
     */

    dp = ms_buf;
    if (verbose || debug)
      fprintf(stderr, "*** reading MBR (sector 0)\n");
    ms_read_blk_fail(0, dp);

    fsl = (void *) dp + FS_LOC_OFFSET;
    empty = msu_check_fs_loc(fsl);
    fprintf(stderr, "fs_loc:  %s (%d)\n", msu_check_string(empty), empty);

    /*
     * if non-zero says the fs_loc has a problem.  That is okay since we
     * maybe creating one.
     */
    if (empty)
      return rtn;

    memcpy(&loc, fsl, sizeof(fs_loc_t));

    /*
     * see if there is a valid panic0 block.  The data in the block
     * must match the panic data in the dblock locator for panic.
     * Otherwise flag no panic block.
     */
    if (verbose || debug)
      fprintf(stderr, "*** reading PANIC0 (sector %u)\n", PANIC0_SECTOR);
    ms_read_blk_fail(PANIC0_SECTOR, dp);
    php = (void *) dp;
    empty = msu_check_panic0_blk(php);
    fprintf(stderr, "panic0:    %s (%d)\n", msu_check_string(empty), empty);

    if (empty == 0) {
      /*
       * Only check the Panic0 block if we think it is present.
       *
       * the PANIC0 block information should agree with what is
       * in the dblk.  Otherwise bitch and flag the panic0 block
       * as not being present.  This will force a rewrite.
       */
      p0c.sig_a       = CF_LE_32(php->sig_a);
      p0c.panic_start = CF_LE_32(php->panic_start);
      p0c.panic_nxt   = CF_LE_32(php->panic_nxt);
      p0c.panic_end   = CF_LE_32(php->panic_end);
      p0c.fubar       = CF_LE_32(php->fubar);
      p0c.sig_b       = CF_LE_32(php->sig_b);
      p0c.chksum      = CF_LE_32(php->chksum);
      empty = check_panic0_values(&p0c);
      if (empty)
	msc_panic0_blk = 0;                     /* non-zero says sometings wrong */
      else
	msc_panic0_blk  = PANIC0_SECTOR;	/* flag it as being present */
    }

    /*
     * Scan the rest of the dblk (using binary search) looking for where
     * the next block will start.  ie.  look for 1st empty sector.
     *
     * Note: first sector of the DBLK area is reserved for the DBLK directory.
     */
    lower = loc.locators[FS_LOC_DBLK].start + 1;
    upper = loc.locators[FS_LOC_DBLK].end;
    empty = 0;
    blk = lower;
    ms_read_blk_fail(blk, dp);
    empty = msu_blk_empty(dp);
    if (!empty) {
      /*
       * if the 1st block isn't empty then we need to scan for the first
       * empty block.  We use a binary search
       */
      while (lower != upper) {
	blk = (upper - lower)/2 + lower;
	if (blk == lower)
          blk = lower = upper;
	ms_read_blk_fail(blk, dp);
	if (msu_blk_empty(dp)) {
          upper = blk;
          empty = 1;
	} else {
          lower = blk;
          empty = 0;
	}
      }
    }
    if (empty)
	msc_dblk_nxt = blk;
    if (verbose || debug) {
      fprintf(stderr, "fs_loc:  p:   s: %-8x   e: %x\n",
	      loc.locators[FS_LOC_PANIC].start,
              loc.locators[FS_LOC_PANIC].end);
      fprintf(stderr, "         c:   s: %-8x   e: %x\n",
	      loc.locators[FS_LOC_CONFIG].start,
              loc.locators[FS_LOC_CONFIG].end);
      fprintf(stderr, "         i:   s: %-8x   e: %x\n",
	      loc.locators[FS_LOC_IMAGE].start,
              loc.locators[FS_LOC_IMAGE].end);
      fprintf(stderr, "         d:   s: %-8x   e: %-8x   n: %x\n",
	      loc.locators[FS_LOC_DBLK].start,
              loc.locators[FS_LOC_DBLK].end,
              msc_dblk_nxt);
      if (msc_dblk_nxt == 0)
	fprintf(stderr, "*** dblk_nxt not set ***\n");
      fprintf(stderr, "panic0:  p:   s: %-8x   e: %-8x   n: %x\n",
	      p0c.panic_start, p0c.panic_end, p0c.panic_nxt);
    }
    return rtn;
}


ms_rtn
ms_read_blk(uint32_t blk_id, void *buf) {
    loff_t off, pos;
    int got;

    off = blk_id * MS_BLOCK_SIZE;
    pos = lseek64(fd, off, SEEK_SET);
    if (pos == -1) {
	fprintf(stderr, "ms_read_blk: seek fail: %s (%d)\n",
		strerror(errno), errno);
	return(MS_READ_FAIL);
    }
    got = read(fd, buf, MS_BLOCK_SIZE);
    if (got == -1) {
	fprintf(stderr, "ms_read_blk: read fail: %s (%d)\n",
		strerror(errno), errno);
	return(MS_READ_FAIL);
    }
    if (got != MS_BLOCK_SIZE) {
	fprintf(stderr, "ms_read_blk: read too short, req: %d, got: %d\n",
		MS_BLOCK_SIZE, got);
	return(MS_READ_TOO_SHORT);
    }
    return(MS_OK);
}


ms_rtn
ms_read_blk_fail(uint32_t blk_id, void *buf) {
    ms_rtn err;

    err = ms_read_blk(blk_id, buf);
    if (err) {
      fprintf(stderr, "*** ms_read_blk fail: %d\n", err);
      exit(1);
    }
    return(err);
}


ms_rtn
ms_read8(uint32_t blk_id, void *buf) {
    loff_t off, pos;
    int got;

    off = blk_id * MS_BLOCK_SIZE;
    pos = lseek64(fd, off, SEEK_SET);
    if (pos == -1) {
	fprintf(stderr, "ms_read8: seek fail: %s (%d)\n",
		strerror(errno), errno);
	return(MS_READ_FAIL);
    }
    got = read(fd, buf, 8);
    if (got == -1) {
	fprintf(stderr, "ms_read8: read fail: %s (%d)\n",
		strerror(errno), errno);
	return(MS_READ_FAIL);
    }
    if (got != 8) {
	fprintf(stderr, "ms_read8: read too short, req: %d, got: %d\n",
		8, got);
	return(MS_READ_TOO_SHORT);
    }
    return(MS_OK);
}


ms_rtn
ms_write_blk(uint32_t blk_id, void *buf) {
    loff_t off, pos;
    int wrote;

    off = blk_id * MS_BLOCK_SIZE;
    pos = lseek64(fd, off, SEEK_SET);
    if (pos == -1) {
	fprintf(stderr, "ms_write_blk: seek fail: %s (%d)\n",
		strerror(errno), errno);
	return(MS_WRITE_FAIL);
    }
    wrote = write(fd, buf, MS_BLOCK_SIZE);
    if (wrote == -1) {
	fprintf(stderr, "ms_write_blk: write fail: %s (%d)\n",
		strerror(errno), errno);
	return(MS_WRITE_FAIL);
    }
    if (wrote != MS_BLOCK_SIZE) {
	fprintf(stderr, "ms_write_blk: write too short, req: %d, wrote: %d\n",
		MS_BLOCK_SIZE, wrote);
	return(MS_WRITE_TOO_SHORT);
    }
    return(MS_OK);
}


char *
ms_dsp_err(ms_rtn err) {
    switch (err) {
      case MS_OK:		return("ok");
      case MS_FAIL:		return("fail");
      case MS_READONLY:		return("readonly");
      case MS_INTERNAL:		return("internal");
      case MS_READ_FAIL:	return("read fail");
      case MS_READ_TOO_SHORT:	return("read too short");
      case MS_WRITE_FAIL:	return("write fail");
      case MS_WRITE_TOO_SHORT:	return("write too short");
    }
    return("unknown");
}
