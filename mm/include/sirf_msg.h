/*
 * Copyright (c) 2017 Eric B. Decker
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

#ifndef __SIRF_MSG_H__
#define __SIRF_MSG_H__

/*
 * Various external SirfBin/Sirf structures and definitions that are protocol
 * dependent (external to the chip).
 */

#ifndef PACKED
#define PACKED __attribute__((__packed__))
#endif

#define NMEA_START       '$'
#define NMEA_END         '*'

#define SIRFBIN_A0      0xa0
#define SIRFBIN_A2      0xa2
#define SIRFBIN_B0      0xb0
#define SIRFBIN_B3      0xb3

/* overhead: start (2), len (2), checksum (2), end (2) */
#define SIRFBIN_OVERHEAD   8

#define MID_NAVDATA	   2
#define NAVDATA_LEN	   41

#define MID_SWVER          6

#define MID_CLOCKSTATUS	   7
#define CLOCKSTATUS_LEN	   20

#define MID_GEODETIC	   41
#define GEODETIC_LEN	   91

/*
 * max size (sirfbin length) message we will receive
 *
 * If we are eavesdropping then we want to see everything
 * and the largest we have seen is MID 4 (len 0xbc, 188 + 8)
 * 196, we round up to 200.
 */
#define SIRFBIN_MAX_MSG         200
#define SIRFBIN_MAX_SW_VER      88

/* actual size of expected PEEK response */
#define SIRFBIN_PEEK_RSP_LEN    32


typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint8_t   data[0];
} PACKED sb_header_t;


/* MID 2, Nav Data */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  int32_t   xpos;                       /* meters  */
  int32_t   ypos;                       /* meters  */
  int32_t   zpos;                       /* meters  */
  int16_t   xvel;                       /* m/s * 8 */
  int16_t   yvel;                       /* m/s * 8 */
  int16_t   zvel;                       /* m/s * 8 */
  uint8_t   mode1;                      /* see below */
  uint8_t   hdop;                       /* * 5 */
  uint8_t   mode2;                      /* see below */
  uint16_t  week;                       /* gps week, 10 lsb, don't use */
  uint32_t  tow;                        /* *100, time of week */
  uint8_t   nsats;                      /* SVs in fix */
  uint8_t   data[0];

  /* ch1 PRN - ch12 PRN - pseudo-random noise values */

} PACKED sb_nav_data_t;


/* MODE1, bit map */

#define SB_NAV_M1_PMODE_MASK            0x07
#define SB_NAV_M1_TPMODE_MASK           0x08
#define SB_NAV_M1_ALTMODE_MASK          0x30
#define SB_NAV_M1_DOPMASK_MASK          0x40
#define SB_NAV_M1_DGPS_MASK             0x80

/* Position Mode */
#define SB_NAV_M1_PMODE_NONE            0
#define SB_NAV_M1_PMODE_SV1KF           1
#define SB_NAV_M1_PMODE_SV2KF           2
#define SB_NAV_M1_PMODE_SV3KF           3
#define SB_NAV_M1_PMODE_SVODKF          4
#define SB_NAV_M1_PMODE_2D              5
#define SB_NAV_M1_PMODE_3D              6
#define SB_NAV_M1_PMODE_DR              7

/* TricklePower Mode */
#define SB_NAV_M1_TPMODE_FULL           0x00
#define SB_NAV_M1_TPMODE_TRICKLE        0x08

/* Altitude Mode */
#define SB_NAV_M1_ALTMODE_NONE          0x00
#define SB_NAV_M1_ALTMODE_KFHOLD        0x10
#define SB_NAV_M1_ALTMODE_USERHOLD      0x20
#define SB_NAV_M1_ALTMODE_ALWAYS        0x30

/* Dilution of Precision */
#define SB_NAV_M1_DOPMASK_OK            0x00
#define SB_NAV_M1_DOPMASK_EXCEEDED      0x40

/* Differential GPS */
#define SB_NAV_M1_DGPS_NONE             0x00
#define SB_NAV_M1_DGPS_APPLIED          0x80


/* MODE2, bit map */
/* for the time being, we don't care about M2 */
#define SB_NAV_M2_SOL_VALIDATED         0x02
#define SB_NAV_M2_VEL_INVALID           0x10
#define SB_NAV_M2_ALTHOLD_DISABLED      0x20


/* MID 4, Tracker Data */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint16_t  week;                       /* modulo 1024 */
  uint32_t  tow;                        /* time * 100 (ms) */
  uint8_t   chans;
  uint8_t   data[0];

  /* for each chan:
   *   SVid, Az, El, State, C/NO 1:10
   */
} PACKED sb_tracker_data_t;


/* MID 6, s/w version */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint8_t   data[0];
} PACKED sb_soft_version_data_t;


/* MID 7, clock status */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint16_t  week_x;                     /* extended week */
  uint32_t  tow;                        /* tow * 100 */
  uint8_t   nsats;
  uint32_t  drift;
  uint32_t  bias;
  uint32_t  esttime_ms;                 /* ms, @ start of measurement */
} PACKED sb_clock_status_data_t;

/* MID 10, error data */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint16_t  submsg;
  uint16_t  count;
  uint8_t   data[0];
} PACKED sb_error_data_t;

/* MID 14, almanac data */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint8_t   satid;
  uint16_t  weekstatus;
  uint8_t  data[0];
} PACKED sb_almanac_status_data_t;


/* MID 28, nav lib data */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint8_t   chan;
  uint32_t  time_tag;
  uint8_t   sat_id;
  uint64_t  soft_time;
  uint64_t  pseudo_range;
  uint32_t  car_freq;
  uint64_t  car_phase;
  uint16_t  time_in_track;
  uint8_t   sync_flags;
  uint8_t   c_no_1;
  uint8_t   c_no_2;
  uint8_t   c_no_3;
  uint8_t   c_no_4;
  uint8_t   c_no_5;
  uint8_t   c_no_6;
  uint8_t   c_no_7;
  uint8_t   c_no_8;
  uint8_t   c_no_9;
  uint8_t   c_no_10;
  uint16_t  delta_range_intv;
  uint16_t  mean_delta_time_range;
  uint16_t  extrap_time;
  uint8_t   phase_err_cnt;
  uint8_t   low_pow_cnt;
} PACKED sb_nav_lib_data_t;


/* MID 41, geodetic data */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint16_t  nav_valid;                  /* bit mask */
  uint16_t  nav_type;
  uint16_t  week_x;                     /* extended */
  uint32_t  tow;			/* seconds x 1e3 */
  uint16_t  utc_year;
  uint8_t   utc_month;
  uint8_t   utc_day;
  uint8_t   utc_hour;
  uint8_t   utc_min;
  uint16_t  utc_ms;			/* x 1e3 (millisecs) */
  uint32_t  sat_mask;
  int32_t   lat;
  int32_t   lon;
  int32_t   alt_elipsoid;               /* m * 100 */
  int32_t   alt_msl;                    /* m * 100 */
  uint8_t   map_datum;
  uint16_t  sog;                        /* m/s * 100 */
  uint16_t  cog;                        /* deg cw from N_t * 100 */
  uint16_t  mag_var;
  int16_t   climb;
  int16_t   heading_rate;
  uint32_t  ehpe;
  uint32_t  evpe;
  uint32_t  ete;
  uint16_t  ehve;
  int32_t   clock_bias;
  int32_t   clock_bias_err;
  int32_t   clock_drift;
  int32_t   clock_drift_err;
  uint32_t  distance;
  uint16_t  distance_err;
  uint16_t  head_err;
  uint8_t   nsats;                      /* num_svs, num sat vehicles */
  uint8_t   hdop;
  uint8_t   additional_mode;
} PACKED sb_geodetic_t;


/* MID 52, 1PPS data */
typedef struct {
  uint8_t   start1;
  uint8_t   start2;
  uint16_t  len;
  uint8_t   mid;
  uint8_t   hr;
  uint8_t   min;
  uint8_t   sec;
  uint8_t   day;
  uint8_t   mo;
  uint16_t  year;
  int16_t   utcintoff;                  /* secs */
  uint32_t  utcfracoff;                 /* nanosecs, * 10^9 */
  uint8_t   status;
  uint32_t  reserved;
} PACKED sb_pps_data_t;

#define SB_PPS_STATUS_VALID  1
#define SB_PPS_STATUS_UTC    2
#define SB_PPS_STATUS_UTCGPS 4
#define SB_PPS_STATUS_UTCGPS 4


#endif  /* __SIRF_MSG_H__ */
