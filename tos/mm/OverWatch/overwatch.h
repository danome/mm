/*
 * Copyright (c) 2017 Daniel J. Maltbie, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef __OVERWATCH_H__
#define __OVERWATCH_H__

/*
 * return codes for owl_startup
 */

typedef enum {
  OWLS_CONTINUE = 0,
  OWLS_REBOOT,
  OWLS_BOOT_NIB,
} owls_rtn_t;


/*
 * definintions for NIB access
 *
 * NIB_BASE:    where the NIB image starts
 * NIB_INFO:    where the NIB's image_info block starts
 * NIB_VEC_COUNT: count of how many vectors need to be summed when verifing
 *              the NIBs vector table.  Each entry is 4 bytes wide.
 */

#define NIB_BASE        0x00020000
#define NIB_INFO        (NIB_BASE + 0x140)
#define NIB_VEC_COUNT   (64 + 14 + 2)


/*
 * ow_boot_mode_t
 *
 * The OverWatcher supports three possible bootable instances:
 *
 * GOLD       Factory installed "Golden" image of the Tag
 *            application code.  Handles Chirp mode?
 *            When all else fails this is the image we run.
 *
 * OWT        OverWatch TinyOS.
 *            The Golden Image implementing the OverWatch
 *            functionality.  OWT is OverWatch Tinyos.  It is
 *            a specialized application and support infrastructure
 *            for implementing OverWatch functionality.
 *
 * NIB        Normal Image Block (Bank 1).
 *            The installable application code is in bank 1 of
 *            Flash (upper 128K)
 */

typedef enum {
  OW_BOOT_GOLD  = 0,
  OW_BOOT_OWT   = 1,
  OW_BOOT_NIB   = 2,
} ow_boot_mode_t;


/*
 * ow_request_t
 *
 * When a running image needs to make a request of OverWatch
 * these are the possible requests that can be made.
 *
 * REQ_BOOT     boot according to boot_mode
 *
 * REQ_INSTALL  Install new code image into the NIB (Bank 1).
 *              Image is marked as active in the Image Directory.
 *
 * REQ_REBOOT   Running image crashed.  Reboot the current ow_boot_mode,
 *               test for too many boot failures and fall back accordingly.
 */

typedef enum  {
  OW_REQ_BOOT           = 0,            /* just boot, see ow_boot_mode */
  OW_REQ_INSTALL        = 1,
  OW_REQ_REBOOT         = 2,            /* crash, rebooting */
} ow_request_t;


/*
 * OWT implements the following actions.  For various reasons
 * these actions must be handled using TinyOS code.
 *
 * ACT_INIT     The OW control block has been reinitialized and we must
 *              determine what is our current boot state.  This information
 *              is out on the SD so we need to ask the ImageManager for the
 *              current state.
 *
 * ACT_INSTALL  OWT will install the SD image marked as active into
 *              the NIB and reboot.
 *
 * ACT_EJECT    The currently executing image (it must be the NIB) has
 *              had too many problems.  Mark it as ejected, and make the
 *              Backup Image (if present) as the new active.  (Will
 *              need to be installed.
 *
 *              If no backup is available, then run the Golden image.
 */

typedef enum  {
  OWT_ACT_NONE = 0,
  OWT_ACT_INIT,
  OWT_ACT_INSTALL,
  OWT_ACT_EJECT,
} owt_action_t;


/* Reboot reasons */
typedef enum {
  ORR_NONE              = 0,
  ORR_FAIL,                             /* catch all for the time being */
  ORR_PWR_FAIL,                         /* lost the control block, full pwr fail */
  ORR_PANIC,
  ORR_HARD_FAULT,
  ORR_BAD_OWT_ACT,
} ow_reboot_reason_t;


/*
 * OW_SIG
 *
 * Used to identify that the ow_control_block has been properly
 * initialized.  If the sig is valid we assume it is sane.  If we want to
 * be extra paranoid we can checksum it.  But that is a pain.
 */
#define OW_SIG 0xFABAFABA


/*
 * ow_control_block_t
 */
typedef struct {
  uint32_t           ow_sig_a;
  uint32_t           cycle;             /* req input, time since last boot */
  uint32_t           time;              /* req input, time since last boot */
  uint32_t           hard_reset;
  ow_request_t       ow_req;            /* req input */
  ow_reboot_reason_t reboot_reason;     /* req input */
  uint8_t            ow_from_nib;       /* input */

  ow_boot_mode_t     ow_boot_mode;      /* control knob */
  owt_action_t       owt_action;        /* input to OWT, further actions */

  uint32_t           strange;           /* strange shit */
  uint32_t           vec_chk_fail;
  uint32_t           image_chk_fail;

  uint32_t           ow_sig_b;

  /*
   * Persistent storage.
   *
   * OverWatch keeps track of some system parameters.
   * This is persistent in that it survives across reboots.
   * However it is not nonvolitle ram and doesn't survive
   * across power fails.
   *
   * "elapsed" cells keep a running total of how long we have been
   * up since last full pwr cycle (full means we lost RAM).
   *
   *   elapsed_upper is essentially cycle
   *   elapsed_lower is the lower 32 bits of ms time.
   */

  uint32_t      elapsed_lower;
  uint32_t      elapsed_upper;
  uint32_t      reboot_count;
  ow_reboot_reason_t
                last_reboot_reason;
  uint32_t      ow_sig_c;
} ow_control_block_t;


/*
 * The ow_control_block lives in a well-defined section of SRAM and
 * is outside of any areas utilized by any of the typical software modules.
 *
 * ow_control_block_t ow_control_block __attribute__ ((section(".overwatch_data")));
 *
 * typically the ow_control_block will reside in OverWatchP.  Outside the implementation
 * block as it needs to be found by other modules and the startup code.
 */

#endif  /* __OVERWATCH_H__ */