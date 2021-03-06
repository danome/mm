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
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef __PLATFORM_PIN_DEFS__
#define __PLATFORM_PIN_DEFS__

/* gps -gsd4e/org */

#define GSD4E_AWAKE_PORT    P6
#define GSD4E_AWAKE_PIN     1
#define GSD4E_AWAKE_BIT     (1 << GSD4E_AWAKE_PIN)
#define GSD4E_AWAKE_P       (GSD4E_AWAKE_PORT->IN & GSD4E_AWAKE_BIT)

#define GSD4E_CTS_PORT      P1
#define GSD4E_CTS_PIN       5
#define GSD4E_CTS           BITBAND_PERI(GSD4E_CTS_PORT->OUT, GSD4E_CTS_PIN)

#define GSD4E_ONOFF_PORT    P4
#define GSD4E_ONOFF_PIN     0
#define GSD4E_ONOFF         BITBAND_PERI(GSD4E_ONOFF_PORT->OUT, GSD4E_ONOFF_PIN)

#define GSD4E_RESETN_PORT   P6
#define GSD4E_RESETN_PIN    0
#define GSD4E_RESETN        BITBAND_PERI(GSD4E_RESETN_PORT->OUT, GSD4E_RESETN_PIN)
#define GSD4E_RESETN_FLOAT  BITBAND_PERI(GSD4E_RESETN_PORT->DIR, GSD4E_RESETN_PIN) = 0;
#define GSD4E_RESETN_OUTPUT BITBAND_PERI(GSD4E_RESETN_PORT->DIR, GSD4E_RESETN_PIN) = 1;

#define GSD4E_RTS_PORT      P4
#define GSD4E_RTS_PIN       5
#define GSD4E_RTS_BIT       (1 << GSD4E_RTS_PIN)
#define GSD4E_RTS_P         (GSD4E_RTS_PORT->IN & GSD4E_RTS_BIT)

#define GSD4E_TM_PORT       P7
#define GSD4E_TM_PIN        3
#define GSD4E_TM_BIT        (1 << GSD4E_TM_PIN)
#define GSD4E_TM_P          (GSD4E_TM_PORT->IN & GSD4E_TM_BIT)

#define GSD4E_PINS_MODULE   do { P3->SEL0 |=  0x0c; } while (0)
#define GSD4E_PINS_PORT     do { P3->SEL0 &= ~0x0c; } while (0)

/* radio - si446x - (B2) */
#define SI446X_CTS_PORT     P2
#define SI446X_CTS_PIN      3
#define SI446X_CTS_BIT      (1 << SI446X_CTS_PIN)
#define SI446X_CTS_P        (SI446X_CTS_PORT->IN & SI446X_CTS_BIT)

#define SI446X_SDN_PORT     P5
#define SI446X_SDN_PIN      0
#define SI446X_SDN_BIT      (1 << SI446X_SDN_PIN)
#define SI446X_SDN_IN       (SI446X_SDN_PORT->IN & SI446X_SDN_BIT)
#define SI446X_SHUTDOWN     BITBAND_PERI(SI446X_SDN_PORT->OUT, SI446X_SDN_PIN) = 1
#define SI446X_UNSHUT       BITBAND_PERI(SI446X_SDN_PORT->OUT, SI446X_SDN_PIN) = 0

#define SI446X_IRQN_PORT    P5
#define SI446X_IRQN_PIN     1
#define SI446X_IRQN_BIT     (1 << SI446X_IRQN_PIN)
#define SI446X_IRQN_P       (P5->IN & SI446X_IRQN_BIT)
#define SI446X_IRQN_PORT_PIN 0x51

#define SI446X_CSN_PORT     P5
#define SI446X_CSN_PIN      2
#define SI446X_CSN_BIT      (1 << SI446X_CSN_PIN)
#define SI446X_CSN_IN       (SI446X_CSN_PORT->IN & SI446X_CSN_BIT)
#define SI446X_CSN          BITBAND_PERI(SI446X_CSN_PORT->OUT, SI446X_CSN_PIN)


/* micro SDs */
#define SD0_CSN_PORT        P10
#define SD0_CSN_PIN         0
#define SD0_CSN             BITBAND_PERI(SD0_CSN_PORT->OUT, SD0_CSN_PIN)

#define SD0_ACCESS_SENSE_BIT     0x08
#define SD0_ACCESS_SENSE_N       FALSE
#define SD0_ACCESS_ENA_N
#define SD0_PWR_ENA

/*
 * see hardware.h for what port is assigned to SD0 for SPI.
 * The DMA channels used depend on this.  We need RX/TX triggers
 * and the address of what data port to hit.
 */
#define SD0_DMA_TX_TRIGGER MSP432_DMA_CH6_B3_TX0
#define SD0_DMA_RX_TRIGGER MSP432_DMA_CH7_B3_RX0
#define SD0_DMA_TX_ADDR    EUSCI_B3->TXBUF
#define SD0_DMA_RX_ADDR    EUSCI_B3->RXBUF

/*
 * SD0_PINS_SPI will connect the 3 spi lines on SD0 to the SPI.  This is
 * done by simply switching the pins to the module.  We need to disconnect
 * the pins when we power off the SDs to avoid powering the chip via the
 * input pins.
 *
 * We also need to switch sd_csn (10.0) from input to output, the value
 * should be a 1 which deselects the sd and tri-states.  The output is
 * already set to 1 (for the resistor pull up).  So simply switching from
 * input to output is fine.
 *
 * We assume that sd0_csn is a 1.
 */
#define SD0_PINS_PORT  do {                                 \
    BITBAND_PERI(SD0_CSN_PORT->DIR, SD0_CSN_PIN) = 0;       \
    P10->SEL0 = 0;                                          \
  } while (0)

#define SD0_PINS_SPI    do {                                \
    BITBAND_PERI(SD0_CSN_PORT->DIR, SD0_CSN_PIN) = 1;       \
    P10->SEL0 = 0x0E;                                       \
} while (0)


/* SD1, dock sd
 * SD1 is on P7,0-2 and sd1_csn is P9.4
 */
#define SD1_CSN_PORT        P9
#define SD1_CSN_PIN         4
#define SD1_CSN             BITBAND_PERI(SD1_CSN_PORT->OUT, SD1_CSN_PIN)

#define SD1_ACCESS_SENSE_BIT     0x08
#define SD1_ACCESS_SENSE_N       FALSE
#define SD1_ACCESS_ENA_N
#define SD1_PWR_ENA

#define SD1_DMA_TX_TRIGGER MSP432_DMA_CH2_A1_TX
#define SD1_DMA_RX_TRIGGER MSP432_DMA_CH3_A1_RX
#define SD1_DMA_TX_ADDR    EUSCI_A1->TXBUF
#define SD1_DMA_RX_ADDR    EUSCI_A1->RXBUF

/*
 * SD1 is on P7.0-2 and sd1_csn is P9.4
 */
#define SD1_PINS_PORT  do {                                 \
    BITBAND_PERI(SD1_CSN_PORT->DIR, SD1_CSN_PIN) = 0;       \
    P7->SEL0 = 0;                                           \
  } while (0)

#define SD1_PINS_SPI    do {                                \
    BITBAND_PERI(SD1_CSN_PORT->DIR, SD1_CSN_PIN) = 1;       \
    P7->SEL0 = 0x07;                                        \
} while (0)


/*
 * TMP bus consists of two tmp sensors off of an I2C eUSCI.
 * when the TMP bus is powered down we want to set the bus
 * pins (SCL and SDA) to inputs.
 *
 * On initialization the pins are initially set to inputs
 * and then kicked over to the module when the i2c bus
 * is powered up.
 */

#define TMP_SDA_PORT    P1
#define TMP_SDA_PIN     6
#define TMP_SCL_PORT    P1
#define TMP_SCL_PIN     7
#define TMP_PWR_PORT
#define TMP_PWR_PIN

#define TMP_PINS_PORT   do { \
    BITBAND_PERI(TMP_SDA_PORT->SEL0, TMP_SDA_PIN) = 0; \
    BITBAND_PERI(TMP_SCL_PORT->SEL0, TMP_SCL_PIN) = 0; \
} while (0)


#define TMP_PINS_MODULE do { \
    BITBAND_PERI(TMP_SDA_PORT->SEL0, TMP_SDA_PIN) = 1; \
    BITBAND_PERI(TMP_SCL_PORT->SEL0, TMP_SCL_PIN) = 1; \
} while (0)


/*
 * always return SCL as being high.  This tells battery_connected that
 * the battery is indeed up.   This is to fake out battery_connected
 * and why we don't actually read SCL.
 */
#define TMP_GET_SCL_MODULE_STATE BITBAND_PERI(TMP_SCL_PORT->SEL0, TMP_SCL_PIN)
#define TMP_GET_SCL              (1)
#define TMP_GET_PWR_STATE        (1)

/* nothing to do always powered on */
#define TMP_I2C_PWR_ON  do { \
} while (0)

#define TMP_I2C_PWR_OFF do { \
} while (0)


#define TELL_PORT       P8
#define TELL_PIN        6
#define TELL_BIT        (1 << TELL_PIN)
#define TELL            BITBAND_PERI(TELL_PORT->OUT, TELL_PIN)
#define TOGGLE_TELL     TELL ^= 1;
#define TELL0           TELL_PORT->OUT = 0;
#define TELL1           TELL_PORT->OUT = TELL_BIT;
#define WIGGLE_TELL     do { TELL = 1; TELL = 0; } while(0)

#define TELL_EXC_PORT   P8
#define TELL_EXC_PIN    5
#define TELL_EXC_BIT    (1 << TELL_EXC_PIN)
#define TELL_EXC        BITBAND_PERI(TELL_EXC_PORT->OUT, TELL_EXC_PIN)
#define TOGGLE_TELL_EXC TELL_EXC ^= 1;
#define TELL_EXC0       TELL_EXC_PORT->OUT = 0;
#define TELL_EXC1       TELL_EXC_PORT->OUT = TELL_EXC_BIT;
#define WIGGLE_EXC      do { TELL_EXC = 1; TELL_EXC = 0; } while(0)

#define WIGGLE_DELAY    6

#define WIGGLE_PARAM(x) do {                                    \
    uint32_t t0, i;                                             \
    WIGGLE_TELL; WIGGLE_TELL; WIGGLE_TELL;                         \
    t0 = USECS_VAL; while ((USECS_VAL - t0) < WIGGLE_DELAY) ;   \
    for (i = 0; i < x; i++) WIGGLE_TELL;                 \
    t0 = USECS_VAL; while ((USECS_VAL - t0) < WIGGLE_DELAY) ;   \
    WIGGLE_TELL; WIGGLE_TELL; WIGGLE_TELL; } while(0)


#endif    /* __PLATFORM_PIN_DEFS__ */
