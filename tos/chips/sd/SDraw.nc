/**
 * SD Raw access
 *
 * Copyright (c) 2010, Eric B. Decker, Carl W. Davis
 * Copyright (c) 2017, Eric B. Decker
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
 *
 * @author Eric B. Decker
 * @author Carl W. Davis
 *
 * Raw access to SD operations.
 *
 * The normal SD driver is event driven.   When we panic we stop the normal
 * execution of tinyos so the event driven driver no longer works.   Raw
 * access allows the panic driver to use the SD to dump out the machine state.
 */

#include "sd_cmd.h"

interface SDraw {
  command void      start_op();
  command void      end_op();
  command uint8_t   get();
  command void      put(uint8_t byte);
  command uint8_t   send_cmd(uint8_t cmd, uint32_t arg);
  command uint8_t   raw_acmd(uint8_t cmd, uint32_t arg);
  command uint8_t   raw_cmd(uint8_t cmd, uint32_t arg);
  command void      send_recv(uint8_t *tx, uint8_t *rx, uint16_t len);

  /*
   * Other SD operations
   *
   * See SDspP for definitions
   */
  command uint32_t  blocks();
  command bool      erase_state();

  command uint32_t  ocr();              /*  32 bits */
  command error_t   cid(uint8_t *buf);  /* 128 bits */
  command error_t   csd(uint8_t *buf);  /* 128 bits */
  command error_t   scr(uint8_t *buf);  /*  64 bits */
}
