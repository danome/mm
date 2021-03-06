/*
 * tagfmtsd - create dblk structures on mass storage
 * Copyright 2006-2008, 2010, 2017 Eric B. Decker
 * Mam-Mark Project
 *
 * typical usage: (format SD media on the Tag)
 *
 * vfat format:     mkdosfs -F 32 -I -n"TagTest" -v /dev/sdb
 * create locators: tagfmtsd -w /dev/sdb
 */

#include <mm_types.h>

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

#include <mm_byteswap.h>
#include <fat_fs.h>
#include <fatxfc.h>
#include <ms.h>


extern fs_loc_t loc;


#define VERSION "tagfmtsd: v3.9.1  2017/08/24\n"

int debug	= 0,
    verbose	= 0,
    do_write	= 0;

/*
 * all sizes in bytes.
 *
 * image_size is set to include all image slots (at 128KiB each) and
 * the directory sector (512 bytes).
 */
uint32_t config_size = 8*1024,
	 panic_size  = 128*1024,
         img_slots   = 4,
	 dblk_size   = 0;


static struct option longopts[] = {
  { "version",	no_argument, NULL, 'V' },
  { "help",	no_argument, NULL, 'h' },
  { NULL,	0,	     NULL, 0 }
};


static void usage(char *name) {
    fprintf(stderr, VERSION);
    fprintf(stderr, "usage: %s [-c <config_size>] [-d <data_size>] [-p <panic size>] [-Dvw] device_file\n", name);
    fprintf(stderr, "  -c <size>    set config size\n");
    fprintf(stderr, "  -d <size>    set dblk size\n");
    fprintf(stderr, "  -h           this usage\n");
    fprintf(stderr, "  --help\n");
    fprintf(stderr, "  -i <n slots> set number of image slots (n x 128KiB\n");
    fprintf(stderr, "  -p <size>    set panic size\n\n");
    fprintf(stderr, "  -D           increment debugging level\n");
    fprintf(stderr, "  -v           verbose mode (increment)\n");
    fprintf(stderr, "  -V           display version\n");
    fprintf(stderr, "  --version\n");
    fprintf(stderr, "  -w           enable write of any changes needed\n");
    fprintf(stderr, "               otherwise just list what is there\n");
    exit(2);
}


void
display_info(void) {
    fat_dir_entry_t *de;
    u32_t rds;

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

    if (p0c.panic_start)
      fprintf(stderr, "panic0:    p: %-8x %-8x  (nxt) %-8x\n",
	      p0c.panic_start, p0c.panic_end,  p0c.panic_nxt);
    else
      fprintf(stderr, "panic0:   no panic0 block\n");

    de = f32_get_de("PANIC001", "   ", &rds);
    if (de) {
	rds = (CF_LE_16(de->starthi) << 16) | CF_LE_16(de->start);
	fprintf(stderr, "PANIC001:  start  0x%04x  size: %10u (0x%x)\n",
                fx_clu2sec(rds),  CF_LE_32(de->size), CF_LE_32(de->size));
    } else
	fprintf(stderr, "PANIC001: not found\n");
    de = f32_get_de("CNFG0001", "   ", &rds);
    if (de) {
	rds = (CF_LE_16(de->starthi) << 16) | CF_LE_16(de->start);
	fprintf(stderr, "CNFG0001:  start  0x%04x  size: %10u (0x%x)\n",
                fx_clu2sec(rds),  CF_LE_32(de->size), CF_LE_32(de->size));
    } else
	fprintf(stderr, "CNFG0001: not found\n");
    de = f32_get_de("IMAGE001", "   ", &rds);
    if (de) {
	rds = (CF_LE_16(de->starthi) << 16) | CF_LE_16(de->start);
	fprintf(stderr, "IMAGE001:  start  0x%04x  size: %10u (0x%x)\n",
		fx_clu2sec(rds), CF_LE_32(de->size), CF_LE_32(de->size));
    } else
	fprintf(stderr, "IMAGE001: not found\n");
    de = f32_get_de("DBLK0001", "   ", &rds);
    if (de) {
	rds = (CF_LE_16(de->starthi) << 16) | CF_LE_16(de->start);
	fprintf(stderr, "DBLK0001:  start  0x%04x  size: %10u (0x%x)\n",
		fx_clu2sec(rds), CF_LE_32(de->size), CF_LE_32(de->size));
    } else
	fprintf(stderr, "DBLK0001: not found\n");
}


int main(int argc, char **argv) {
    int     c;
    int     err;
    uint8_t buf[MS_BUF_SIZE];
    u32_t   image_size;
    int     do_fs_loc, do_panic0;

    while ((c = getopt_long(argc,argv,"c:d:i:p:DhvVw", longopts, NULL)) != EOF)
	switch (c) {
	  case 'c':
	      fprintf(stderr, "-c not implemented yet, defaults to 8192\n");
	      break;
	  case 'd':
	      fprintf(stderr, "-d not implemented yet, defaults to 0 (rest of partition)\n");
	      break;
	  case 'D':
	      debug++;
	      break;
	  case 'h':
	      usage(argv[0]);
	      break;
	  case 'i':
	      fprintf(stderr, "-i not implemented yet, defaults to 4 slots, 128k each\n");
	      break;
	  case 'p':
	      fprintf(stderr, "-p not implemented yet, defaults to 128k\n");
	      break;
	  case 'v':
	      verbose++;
	      break;
	  case 'V':
	      fprintf(stderr, VERSION);
	      exit(0);
	      break;
	  case 'w':
	      do_write++;
	      break;
	  default:
	      usage(argv[0]);
	      break;
	}
    if (optind != argc - 1)
	usage(argv[0]);

    if (verbose)
	fprintf(stderr, VERSION);
    fx_hard_init();
    err = ms_init(argv[optind]);
    if (err == MS_READONLY) {
      fprintf(stderr, "tagfmtsd: %s is read only\n", argv[optind]);
      err = MS_OK;
      do_write = 0;
    }
    if (err) {
	fprintf(stderr, "ms_init: %s (0x%x)\n", ms_dsp_err(err), err);
	exit(1);
    }
    err = fx_set_buf(buf);
    if (err) {
	fprintf(stderr, "fx_set_buf: %s (0x%x)\n", fx_dsp_err(err), err);
	exit(1);
    }
    err = fx_init();
    if (err) {
	fprintf(stderr, "fx_init: %s (0x%x)\n", fx_dsp_err(err), err);
	exit(1);
    }
    if (!do_write) {
	display_info();
	exit(0);
    }
    do_fs_loc = 1;
    do_panic0   = !msc_panic0_blk;
    err = fx_create_contig("PANIC001", "   ", panic_size,
                           &loc.locators[FS_LOC_PANIC].start,
                           &loc.locators[FS_LOC_PANIC].end);
    if (err) {
	fprintf(stderr, "fx_create_contig: PANIC001: %s (0x%x)\n", fx_dsp_err(err), err);
	do_fs_loc = 0;
    }
    err = fx_create_contig("CNFG0001", "   ", config_size,
                           &loc.locators[FS_LOC_CONFIG].start,
                           &loc.locators[FS_LOC_CONFIG].end);
    if (err) {
	fprintf(stderr, "fx_create_contig: CNFG0001: %s (0x%x)\n", fx_dsp_err(err), err);
	do_fs_loc = 0;
    }

    /*
     * each slot is 128KiB (128 * 1024) bytes + 512, directory sector.
     */
    image_size = img_slots * 128 * 1024 + 512;
    err = fx_create_contig("IMAGE001", "   ", image_size,
                           &loc.locators[FS_LOC_IMAGE].start,
                           &loc.locators[FS_LOC_IMAGE].end);
    if (err) {
	fprintf(stderr, "fx_create_contig: IMAGE001: %s (0x%x)\n", fx_dsp_err(err), err);
	do_fs_loc = 0;
    } else {
    }
    err = fx_create_contig("DBLK0001", "   ", dblk_size,
                           &loc.locators[FS_LOC_DBLK].start,
                           &loc.locators[FS_LOC_DBLK].end);
    if (err) {
	fprintf(stderr, "fx_create_contig: DBLK0001: %s (0x%x)\n", fx_dsp_err(err), err);
	do_fs_loc = 0;
    }
    if (do_fs_loc) {
      fprintf(stderr, "*** writing fs locator\n");
      err = fx_write_locator(&loc);
      if (err) {
	fprintf(stderr, "fx_write_locator: %s (0x%x)\n", fx_dsp_err(err), err);
	exit(1);
      }
      do_panic0 = 1;			/* always write if we wrote the dblk locator */
    }

    if (do_panic0) {
      fprintf(stderr, "*** writing PANIC0 blk\n");
      err = fx_write_panic0(loc.locators[FS_LOC_PANIC].start,
                            loc.locators[FS_LOC_PANIC].end);
      if (err) {
	fprintf(stderr, "fx_write_panic: %s (0x%x)\n", fx_dsp_err(err), err);
	exit(1);
      }
    }

    display_info();

    if (!do_fs_loc && !do_panic0)
      fprintf(stderr, "*** no changes written\n");

    return(0);
}

/* Local Variables: */
/* tab-width: 8     */
/* End:             */
