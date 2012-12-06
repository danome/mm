/**
 * Basic defines for tmp102/tmp112.
 * See p. 7 and on of tmp102/tmp112 data sheets.
 *
 * tmp112 is an extended range version of the 102.  Interface is the
 * same.
 *
 *  @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef __TMP112_H__
#define __TMP112_H__

#define TMP112_TEMP	0
#define TMP112_CONFIG	1
#define TMP112_TLOW	2
#define TMP112_THIGH	3

/*
 * config register bits
 */
#define TMP112_CONFIG_ONESHOT	0x8000
#define TMP112_CONFIG_RES_MASK	0x6000
#define TMP112_CONFIG_RES_3	0x6000
#define TMP112_CONFIG_FLT_MASK	0x1800
#define TMP112_CONFIG_FAULT_1	0x0000
#define TMP112_CONFIG_FAULT_2	0x0800
#define TMP112_CONFIG_FAULT_4	0x1000
#define TMP112_CONFIG_FAULT_6	0x1800
#define TMP112_CONFIG_POLARITY	0x0400
#define TMP112_CONFIG_TM	0x0200
#define TMP112_CONFIG_OFF	0x0100

/* byte 2, lsb */
#define TMP112_CONFIG_8HZ	0x00c0
#define TMP112_CONFIG_4HZ	0x0080
#define TMP112_CONFIG_1HZ	0x0040
#define TMP112_CONFIG_25HZ	0x0000
#define TMP112_CONFIG_AL	0x0020
#define TMP112_CONFIG_EM	0x0010

#endif	/* __TMP112_H__ */
