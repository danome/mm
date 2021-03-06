/*
 * Copyright (c) 2010, 2016-2017 Eric B. Decker, Carl Davis, Daniel Maltbie
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
 * @author Carl Davis
 *
 * SDnC instantiates the driver SDsp, (SD, split phase, event driven) and
 * connects it to the hardware port for the platform.
 *
 * read, write, and erase are for clients.  SDsa is SD stand alone which
 * is used if the system crashes/panics.
 *
 * SD_Arb provides an arbitrated interface for clients.  The port the
 * hardware is attached to is specified via HplSDnC (Hardware presentation
 * layer, SD, unit n).  ResourceDefaultOwner (RDO) from the Arbiter must be
 * wired into RDO of the driver.  RDO is responsible for powering up and
 * down the SD.  The SD is powered down when no clients are using it.
 */

configuration SD1C {
  provides {
    interface SDread[uint8_t cid];
    interface SDwrite[uint8_t cid];
    interface SDerase[uint8_t cid];
    interface SDsa;
    interface SDraw;
  }
  uses interface ResourceDefaultOwner;          /* power control */
}

implementation {
  components new SDspP() as SDdvrP;

  SDread   = SDdvrP;
  SDwrite  = SDdvrP;
  SDerase  = SDdvrP;
  SDsa     = SDdvrP;
  SDraw    = SDdvrP;

  ResourceDefaultOwner = SDdvrP;

  components MainC;
  MainC.SoftwareInit -> SDdvrP;

  components PanicC;
  SDdvrP.Panic -> PanicC;

  components new TimerMilliC() as SDTimer;
  SDdvrP.SDtimer -> SDTimer;

  components HplSD1C as HW;
  SDdvrP.HW -> HW;

  components LocalTimeMilliC;
  SDdvrP.lt -> LocalTimeMilliC;

  components PlatformC;
  SDdvrP.Platform    -> PlatformC;
}
