/*
 * CollectP.nc - data collector (record managment) interface
 * between data collection and mass storage.
 *
 * Copyright 2008, 2014, 2017: Eric B. Decker
 * All rights reserved.
 * Mam-Mark Project
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

#include "Collect.h"
#include "typed_data.h"

module CollectP {
  provides {
    interface Collect;
    interface Init;
    interface CollectEvent;
  }
  uses {
    interface SSWrite as SSW;
    interface Panic;
    interface LocalTime<TMilli>;
  }
}

implementation {
  dc_control_t dcc;

  command error_t Init.init() {
    dcc.majik_a = DC_MAJIK;
    dcc.majik_b = DC_MAJIK;
    return SUCCESS;
  }


  void finish_sector() {
    unsigned int i;

    /* won't change checksum */
    for (i = 0; i < dcc.remaining; i++)
      *dcc.cur_ptr++ = 0;       /* zero out the rest */
    dcc.remaining = 0;
    dcc.chksum += (dcc.seq & 0xff);
    dcc.chksum += (dcc.seq >> 8);
    (*(uint16_t *) dcc.cur_ptr) = dcc.seq++;
    dcc.cur_ptr += 2;
    (*(uint16_t *) dcc.cur_ptr) = dcc.chksum;
    call SSW.buffer_full(dcc.handle);
    dcc.handle = NULL;
    dcc.cur_buf = NULL;
    dcc.cur_ptr = NULL;
  }


  void align_next() {
    unsigned int count;
    uint8_t *ptr;

    ptr = dcc.cur_ptr;
    count = (unsigned int) ptr & 0x03;
    if (dcc.remaining == 0 || !count)   /* nothing to align */
      return;
    if (dcc.remaining < 4) {
      finish_sector();
      return;
    }

    /*
     * we know there are at least 5 bytes left
     * chew bytes until aligned.  1, 2, or 3 bytes
     * actually 4 - count at this point.
     *
     * won't change checksum
     */
    switch (count) {
      case 1: *ptr++ = 0;
      case 2: *ptr++ = 0;
      case 3: *ptr++ = 0;
    }
    dcc.cur_ptr = ptr;
    dcc.remaining -= (4 - count);
  }


  void copy_out(uint8_t *data, uint16_t dlen) {
    uint16_t num_to_copy, chksum;
    uint8_t *ptr;
    unsigned int i;

    if (!data || !dlen)            /* nothing to do? */
      return;
    while (dlen > 0) {
      if (dcc.cur_buf == NULL) {
        /*
         * nobody home, try to go get one.
         *
         * get_free_buf_handle either works or panics.
         */
        dcc.handle = call SSW.get_free_buf_handle();
        dcc.cur_ptr = dcc.cur_buf = call SSW.buf_handle_to_buf(dcc.handle);
        dcc.remaining = DC_BLK_SIZE;
        dcc.chksum = 0;
      }
      num_to_copy = ((dlen < dcc.remaining) ? dlen : dcc.remaining);
      chksum = dcc.chksum;
      ptr = dcc.cur_ptr;
      for (i = 0; i < num_to_copy; i++) {
        chksum += *data;
        *ptr++  = *data++;
      }
      dcc.chksum = chksum;
      dcc.cur_ptr = ptr;
      dlen -= num_to_copy;
      dcc.remaining -= num_to_copy;
      if (dcc.remaining == 0) {
        finish_sector();
      }
    }
  }


  /*
   * All data fields are assumed to be little endian on both sides, tag and
   * host side.
   *
   * header is constrained to be 32 bit aligned (a(4)).  The size of header
   * is not constrained and may be any size.  data is not constrained and
   * will be copied immediately after the header (contiguous).
   *
   * hlen is the actual size of the header, dlen is the actual size of the
   * data.  hlen + dlen should match what is laid down in header->len.
   *
   * All dblk headers are assumed to start on a 32 bit boundary (aligned(4)).
   *
   * After writing a header/data combination (the whole typed_data block),
   * we align the next potential typed_data block onto a 32 bit boundary.
   * In other words we always keep typed_data blocks aligned in memory as
   * well as on the disk sector.
   *
   * dblk headers are constrained to fit completely into a data sector.  Data
   * immediately follows the dblk header as long as there is space.  Data
   * can flow into as many sectors as needed following the dblk header.
   */
  command void Collect.collect(dt_header_t *header, uint16_t hlen,
                               uint8_t     *data,   uint16_t dlen) {
    dt_header_t dt_hdr;

    if (dcc.majik_a != DC_MAJIK || dcc.majik_b != DC_MAJIK)
      call Panic.panic(PANIC_SS, 1, dcc.majik_a, dcc.majik_b, 0, 0);
    if ((uint32_t) header & 0x3 || (uint32_t) dcc.cur_ptr & 0x03 || dcc.remaining > DC_BLK_SIZE)
      call Panic.panic(PANIC_SS, 2, (parg_t) header, (parg_t) dcc.cur_ptr, dcc.remaining, 0);
    if (header->len != (hlen + dlen) ||
        header->dtype > DT_MAX       ||
        hlen > DT_MAX_HEADER         ||
        (hlen + dlen) < 4)
      call Panic.panic(PANIC_SS, 3, hlen, dlen, header->len, header->dtype);

    if (dlen > DC_MAX_DLEN)
      call Panic.panic(PANIC_SS, 1, (parg_t) data, dlen, 0, 0);

    while(1) {
      if (dcc.remaining == 0 || dcc.remaining >= hlen) {
        /*
         * Either no space remains (will grab a new sector/buffer) or the
         * header will fit in what's left.  Just push the header out followed
         * by the data.
         *
         * The header will fit in the DC_BLK_SIZE bytes in the sector in what
         * is left.  checked for max above.
         */
        copy_out((void *)header, hlen);
        copy_out((void *)data,   dlen);
        align_next();
        return;
      }

      /*
       * there is some space remaining but the header won't fit.  We should
       * always have at least 4 bytes remaining so should be able to laydown
       * the DT_TINTRYALF record (2 bytes len and 2 bytes dtype).
       */
      if (dcc.remaining < 4)
        call Panic.panic(PANIC_SS, 4, dcc.remaining, 0, 0, 0);
      dt_hdr.len = 4;
      dt_hdr.dtype = DT_TINTRYALF;
      copy_out((void *) &dt_hdr, 4);

      /*
       * If we had exactly 4 bytes left, the DT_TINTRYALF will have filled
       * it forcing a finish_sector, leaving no remaining bytes.  But if we
       * still have some remaining then flush the current sector out and start
       * fresh.
       */
      if (dcc.remaining)
        finish_sector();

      /* and try again in the new sector */
    }
  }


  command void CollectEvent.logEvent(uint16_t ev, uint32_t arg0, uint32_t arg1,
                                                  uint32_t arg2, uint32_t arg3) {
    dt_event_t  e;
    dt_event_t *ep;

    ep = &e;
    ep->len = sizeof(e);
    ep->dtype = DT_EVENT;
    ep->stamp_ms = call LocalTime.get();
    ep->arg0 = arg0;
    ep->arg1 = arg1;
    ep->arg2 = arg2;
    ep->arg3 = arg3;
    ep->ev = ev;
    call Collect.collect((void *)ep, sizeof(e), NULL, 0);
  }

  async event void Panic.hook() { }

}
