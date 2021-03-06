/*
 * Copyright (c) 2015 Eric B. Decker
 * Copyright (c) 2017 Eric B. Decker, Daniel J. Maltbie
 * All rights reserved.
 */


#include <Tasklet.h>
#include "message.h"
#include "Tagnet.h"
#include "TagnetTLV.h"

#ifndef PACKED
#define PACKED __attribute__((__packed__))
#endif

tagnet_tlv_t   *test_t1;
tagnet_tlv_t   *test_t2;
message_t      *test_msg0;
message_t      *test_msg1;
message_t      *test_msg2;
message_t        my_msg0;
message_t        my_msg1;
message_t        my_msg2;

int32_t          tn_gps_xyz_count = 0;

#define xHDR_LEN 25
#define xHOPS 11
#define xMSG_LEN 45
#define xNAME_LEN 71
#define xPLOAD_LEN 23

uint32_t gt0, gt1;
uint16_t tt0, tt1;

uint16_t global_node_id = 42;

#define TN_TEST_DBG
//#define TN_TEST_DBG __attribute__((optimize("O0")))

module testTagnetP {
  provides {
    interface Init;
    interface TagnetAdapter<tagnet_gps_xyz_t>  as  InfoSensGpsXyz;
  } uses {
    interface Boot;

    interface TagnetName;
    interface TagnetPayload;
    interface TagnetTLV;
    interface TagnetHeader;

    interface Tagnet;

    interface Timer<TMilli> as rcTimer;
    interface Timer<TMilli> as txTimer;
    interface LocalTime<TMilli>;

    interface Leds;
    interface Panic;
    interface Random;

    interface RadioState;
    interface RadioPacket;
    interface RadioSend;
    interface RadioReceive;
  }
}

implementation {

  typedef enum {
    DISABLED = 0,
    RUN  = 1,
    PEND = 2,
    PING = 3,
    PONG = 4,
    REP  = 5,
  } test_mode_t;

  /*
   * radio state info
   */
  typedef enum {
    OFF = 0,
    STARTING,
    ACTIVE,
    STOPPING,
    STANDBY,
  } radio_state_t;


  event void txTimer.fired() {
    nop();
    nop();
  }

  tasklet_async event void RadioSend.ready() {
    nop();
    nop();
  }

  tasklet_async event void RadioSend.sendDone(error_t error) {
    nop();
    nop();
  }

  tasklet_async event message_t* RadioReceive.receive(message_t *msg) {
    nop();
    nop();
    return msg;
  }

  tasklet_async event bool RadioReceive.header(message_t *msg) {
    nop();
    nop();
    return TRUE;
  }

  async event void RadioState.done() {
    nop();
    nop();
  }

  event void rcTimer.fired() {
    nop();
    nop();
  }

//  command uint8_t TagnetMessage.get_full_name[uint8_t id](uint8_t *buf, uint8_t len) {
//    return len;
//  }

  /*
   * operating system hooks
   */
  command error_t Init.init() {
    return SUCCESS;
  }

  message_t*  TN_TEST_DBG buildMsg(uint8_t i) {
     int          name_len = 0;
     message_t*   msg;
     uint8_t*     buf;
     int          n;

    switch (i) {
      case 0:
        nop();
        msg = &my_msg0;
        call TagnetHeader.reset_header(msg);
        call TagnetName.reset_name(msg);
        call TagnetPayload.reset_payload(msg);
        buf = (uint8_t *) &msg->data[0];
        for (n = 0; n < TOSH_DATA_LENGTH; n++) {
          buf[n] = 0xdd;
        }
        return msg;
        break;
      case 1:
        nop();
        msg = &my_msg1;
        call TagnetHeader.reset_header(msg);
        buf = (uint8_t *) &msg->data[0];
        for (n = 0; n < TOSH_DATA_LENGTH; n++) {
          buf[n] = 0xdd;
        }
        name_len = call TagnetTLV.copy_tlv((tagnet_tlv_t *) &TN_BCAST_NID_TLV,
                                            (tagnet_tlv_t *) buf,
                                            (TOSH_DATA_LENGTH - name_len));
        buf += name_len;
        name_len += call TagnetTLV.copy_tlv((tagnet_tlv_t *)TN_TAG_TLV, (tagnet_tlv_t *) buf,
                                            (TOSH_DATA_LENGTH - name_len));
        return msg;
        break;
      case 2:
        nop();
        msg = &my_msg2;
        call TagnetHeader.reset_header(msg);
        buf = (uint8_t *) &msg->data[0];
        for (n = 0; n < TOSH_DATA_LENGTH; n++) {
          buf[n] = 0xdd;
        }
        name_len += call TagnetTLV.copy_tlv((tagnet_tlv_t *) &TN_BCAST_NID_TLV,
                                            (tagnet_tlv_t *) buf,
                                            (TOSH_DATA_LENGTH - name_len));
        buf += name_len;
        name_len += call TagnetTLV.copy_tlv((tagnet_tlv_t *)TN_TAG_TLV, (tagnet_tlv_t *) buf,
                                            (TOSH_DATA_LENGTH - name_len));
        return msg;
        break;
      default:
        break;
    }
    return NULL;
  }


  void TN_TEST_DBG test_tagnet_header() {

    test_msg1 = buildMsg(1);
    nop();
    call TagnetHeader.set_message_len(test_msg1, xHDR_LEN);
    if (call TagnetHeader.get_message_len(test_msg1) != xHDR_LEN) {
      call Panic.panic(-1, 66, 0, 0, 0, 0);
    }
    nop();
    if (call TagnetHeader.get_header_len(test_msg1) != sizeof(si446x_packet_header_t)) {
      call Panic.panic(-1, 64, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_hops(test_msg1, xHOPS);
    call TagnetHeader.set_message_type(test_msg1, TN_GET);
    if (call TagnetHeader.get_hops(test_msg1) != xHOPS) {
      call Panic.panic(-1, 67, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_message_len(test_msg1, xMSG_LEN);
    if (call TagnetHeader.get_message_len(test_msg1) != xMSG_LEN) {
      call Panic.panic(-1, 68, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_message_type(test_msg1, TN_PUT);
    call TagnetHeader.set_hops(test_msg1, xHOPS);
    if (call TagnetHeader.get_message_type(test_msg1) != TN_PUT) {
      call Panic.panic(-1, 69, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_name_len(test_msg1, xNAME_LEN);
    if (call TagnetHeader.get_name_len(test_msg1) != xNAME_LEN) {
      call Panic.panic(-1, 70, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_pload_type_raw(test_msg1);
    if (!call TagnetHeader.is_pload_type_raw(test_msg1) || call TagnetHeader.is_pload_type_tlv(test_msg1)) {
      call Panic.panic(-1, 71, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_pload_type_tlv(test_msg1);
    if (call TagnetHeader.is_pload_type_raw(test_msg1) || !call TagnetHeader.is_pload_type_tlv(test_msg1)) {
      call Panic.panic(-1, 72, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_request(test_msg1);
    if (!call TagnetHeader.is_request(test_msg1) || call TagnetHeader.is_response(test_msg1)) {
      call Panic.panic(-1, 73, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_response(test_msg1);
    if (call TagnetHeader.is_request(test_msg1) || !call TagnetHeader.is_response(test_msg1)) {
      call Panic.panic(-1, 74, 0, 0, 0, 0);
    }
    nop();
    call TagnetHeader.set_error(test_msg1, TE_BAD_MESSAGE);
    call TagnetHeader.set_request(test_msg1);
    call TagnetHeader.set_response(test_msg1);
    call TagnetHeader.set_pload_type_tlv(test_msg1);
    call TagnetHeader.set_pload_type_raw(test_msg1);
    if (call TagnetHeader.get_error(test_msg1) != TE_BAD_MESSAGE) {
      call Panic.panic(-1, 65, 0, 0, 0, 0);
    }
    nop();
// bytes_available(test_msg1)
  }

  void TN_TEST_DBG test_tagnet_tlv() {
    int             max      =  TOSH_DATA_LENGTH;
    uint8_t         tlv64[]  =  {TN_TLV_INTEGER,1,64};
    uint8_t         my_tlv_b[10] = {0,0,0,0,0,0,0,0,0,0};
    tagnet_tlv_t   *my_tlv   = (tagnet_tlv_t *) &my_tlv_b[0];
    uint8_t        *test_str =  NULL;
    int             test_str_len;

    nop();
    nop();

    test_msg1 = buildMsg(1);
    test_msg2 = buildMsg(2);
    test_t1 = (tagnet_tlv_t *)&test_msg1->data[0];
    test_t2 = (tagnet_tlv_t *)&test_msg2->data[0];
    if (!call TagnetTLV.eq_tlv(test_t1, test_t2)) {
      call Panic.panic(-1, 1, (int) test_t1, (int) test_t2, 0, 0);
    }
    test_t1 = call TagnetTLV.get_next_tlv(test_t1, max);
    test_t2 = call TagnetTLV.get_next_tlv(test_t2, max);
    if (!call TagnetTLV.eq_tlv(test_t1, test_t2)) {
      call Panic.panic(-1, 2, (int) test_t1, (int) test_t2, 0, 0);
    }
    if (!call TagnetTLV.eq_tlv(test_t1, (tagnet_tlv_t *)TN_TAG_TLV)) {
      call Panic.panic(-1, 3, (int) test_t1, (int) test_t2, 0, 0);
    }
    nop();
    if (call TagnetTLV.get_len(test_t1) != (test_t1->len + sizeof(tagnet_tlv_t))) {
      call Panic.panic(-1, 4, (int) test_t1, 0, 0, 0);
    }
    nop();
    if (call TagnetTLV.get_len_v(test_t1) != test_t1->len) {
      call Panic.panic(-1, 4, (int) test_t1, 0, 0, 0);
    }
    nop();
    if (call TagnetTLV.get_tlv_type(test_t1) != TN_TAG_TLV[0]) {
      call Panic.panic(-1, 5, (int) test_t1, 0, 0, 0);
    }
    nop();
    test_str_len = call TagnetTLV.string_to_tlv((uint8_t *)&TN_TAG_TLV[2],
                                                TN_TAG_TLV[1], my_tlv,
                                                sizeof(my_tlv_b));
    if (test_str_len != SIZEOF_TLV(((tagnet_tlv_t *)&TN_TAG_TLV))) {
      call Panic.panic(-1, 8, (int) my_tlv, test_str_len, 0, 0);
    }
    nop();
    test_str = call TagnetTLV.tlv_to_string(test_t1, (void *) &test_str_len);
    if ((test_str_len != 3) || (test_str[0] != 't')) {
      call Panic.panic(-1, 9, (int) test_t1, (int) test_str, test_str_len, 0);
    }
    nop();
    if (call TagnetTLV.integer_to_tlv(64, test_t1, max) != 3) {
      call Panic.panic(-1, 6, (int) test_t1, 0, 0, 0);
    }
    nop();
    if (call TagnetTLV.tlv_to_integer((tagnet_tlv_t *)&tlv64[0]) != 64) {
      call Panic.panic(-1, 7, (int) test_t1, 0, 0, 0);
    }
    nop();
    if (call TagnetTLV.is_special_tlv(test_t1)) {
      call Panic.panic(-1, 10, (int) test_t1, 0, 0, 0);
    }
    nop();
    if (call TagnetTLV.get_next_tlv(test_t1, max)) {
      call Panic.panic(-1, 11, (int) test_t1, 0, 0, 0);
    }
    nop();
    if (call TagnetTLV.get_len_v(test_t1) != test_t1->len) {
      call Panic.panic(-1, 12, (int) test_t1, 0, 0, 0);
    }
    nop();
  }

  void TN_TEST_DBG test_tagnet_name() {
    tagnet_tlv_t    *first_tlv;
    tagnet_tlv_t    *next_tlv;
    int              len;

    nop();
    nop();

    test_msg1 = buildMsg(1);

    call TagnetHeader.reset_header(test_msg1);
    call TagnetName.reset_name(test_msg1);
    len = call TagnetName.add_element(test_msg1, (tagnet_tlv_t *)TN_TAG_TLV);
    len += call TagnetName.add_element(test_msg1, (tagnet_tlv_t *) &TN_BCAST_NID_TLV);
    call TagnetHeader.set_name_len(test_msg1, len);
    if (call TagnetHeader.get_name_len(test_msg1)
        !=  (SIZEOF_TLV(((tagnet_tlv_t *)&TN_TAG_TLV))
             + SIZEOF_TLV(((tagnet_tlv_t *)TN_BCAST_NID_TLV)))) {
      call Panic.panic(-1, 31, (int) test_msg1, 0, 0, 0);
    }
    nop();
    first_tlv = call TagnetName.first_element(test_msg1);
    if (!call TagnetTLV.eq_tlv(first_tlv, (tagnet_tlv_t *)TN_TAG_TLV)){
      call Panic.panic(-1, 32, (int) test_msg1, 0, 0, 0);
    }
    nop();
    if (!call TagnetTLV.eq_tlv(first_tlv, call TagnetName.this_element(test_msg1))) {
      call Panic.panic(-1, 33, (int) test_msg1, 0, 0, 0);
    }
    nop();
    next_tlv = call TagnetName.next_element(test_msg1);
    if (!call TagnetTLV.eq_tlv(next_tlv, (tagnet_tlv_t *) &TN_BCAST_NID_TLV)) {
      call Panic.panic(-1, 34, (int) test_msg1, 0, 0, 0);
    }
    nop();
    if (call TagnetHeader.get_name_len(test_msg1)
        !=  (SIZEOF_TLV(((tagnet_tlv_t *)&TN_TAG_TLV))
             + SIZEOF_TLV(((tagnet_tlv_t *)TN_BCAST_NID_TLV)))) {
      call Panic.panic(-1, 35, (int) test_msg1, 0, 0, 0);
    }
    nop();
    next_tlv = call TagnetName.next_element(test_msg1);
    if (next_tlv != NULL){
      call Panic.panic(-1, 36, (int) test_msg1, 0, 0, 0);
    }
    if (call TagnetHeader.get_name_len(test_msg1) != len) {
      call Panic.panic(-1, 37, (int) test_msg1, 0, 0, 0);
    }
    nop();
  }

  void TN_TEST_DBG test_tagnet_payload() {
    tagnet_tlv_t    *first_tlv;
    tagnet_tlv_t    *next_tlv;
    int              name_len, data_len;

    nop();
    nop();

    test_msg1 = buildMsg(1);
    call TagnetHeader.reset_header(test_msg1);
    call TagnetName.reset_name(test_msg1);
    call TagnetPayload.reset_payload(test_msg1);
    name_len = call TagnetName.add_element(test_msg1, (tagnet_tlv_t *)TN_TAG_TLV);
    name_len += call TagnetName.add_element(test_msg1, (tagnet_tlv_t *) &TN_BCAST_NID_TLV);
    nop();
    data_len = call TagnetPayload.add_tlv(test_msg1, (tagnet_tlv_t *) &TN_BCAST_NID_TLV);
    data_len += call TagnetPayload.add_integer(test_msg1, xPLOAD_LEN);
    data_len += call TagnetPayload.add_string(test_msg1, "tag", 3);
    nop();
    first_tlv = call TagnetPayload.first_element(test_msg1);
    if (!call TagnetTLV.eq_tlv(first_tlv, (tagnet_tlv_t *) &TN_BCAST_NID_TLV)){
      call Panic.panic(-1, 71, (int) test_msg1, (int) first_tlv, 0, 0);
    }
    nop();
    next_tlv = call TagnetPayload.next_element(test_msg1);
    if (!(call TagnetTLV.get_tlv_type(next_tlv) == TN_TLV_INTEGER)) {
      call Panic.panic(-1, 72, (int) test_msg1, (int) first_tlv, (int) next_tlv, 0);
    }
    nop();
    next_tlv = call TagnetPayload.next_element(test_msg1);
    if (!(call TagnetTLV.get_tlv_type(next_tlv) == TN_TLV_STRING)) {
      call Panic.panic(-1, 73, (int) test_msg1, (int) first_tlv, (int) next_tlv, 0);
    }
    nop();
    next_tlv = call TagnetPayload.next_element(test_msg1);
    if (next_tlv) {
      call Panic.panic(-1, 74, (int) test_msg1, (int) first_tlv, (int) next_tlv, 0);
    }
  }

  void TN_TEST_DBG test_tagnet_poll_ev() {
    tagnet_tlv_t    *next_tlv;
    int              name_len;
    int              data_len;

    nop();
    nop();
    test_msg0 = buildMsg(0);
    call TagnetHeader.set_message_type(test_msg0, TN_POLL);
    call TagnetHeader.set_request(test_msg0);
    call TagnetHeader.set_hops(test_msg0, 15);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_TAG_ID].name_tlv;
    name_len  = call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_POLL_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_POLL_NID_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_POLL_EV_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    nop();
    if (call TagnetName.get_len(test_msg0) != name_len) {
      call Panic.panic(-1, 91, (int) test_msg0, name_len, 0, 0);
    }
    nop();
    data_len  = call TagnetPayload.add_integer(test_msg0, xPLOAD_LEN);
    data_len += call TagnetPayload.add_string(test_msg0, "tag", 3);
    nop();
    if (call TagnetPayload.get_len(test_msg0) != data_len) {
      call Panic.panic(-1, 92, (int) test_msg0, data_len, 0, 0);
    }
    nop();
    if (call Tagnet.process_message(test_msg0)) {
      call Panic.panic(-1, 93, (int) test_msg0, 0, 0, 0);
    }
    nop();
  }

  void TN_TEST_DBG test_tagnet_poll_cnt() {
    tagnet_tlv_t    *next_tlv;
    int              name_len;
    int              data_len;

    nop();
    nop();
    test_msg0 = buildMsg(0);
    call TagnetHeader.set_message_type(test_msg0, TN_GET);
    call TagnetHeader.set_request(test_msg0);
    call TagnetHeader.set_hops(test_msg0, 15);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_TAG_ID].name_tlv;
    name_len  = call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_POLL_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_POLL_NID_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_POLL_CNT_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    nop();
    if (call TagnetName.get_len(test_msg0) != name_len) {
      call Panic.panic(-1, 94, (int) test_msg0, name_len, 0, 0);
    }
    nop();
    data_len  = call TagnetPayload.add_integer(test_msg0, xPLOAD_LEN);
    data_len += call TagnetPayload.add_string(test_msg0, "tag", 3);
    nop();
    if (call TagnetPayload.get_len(test_msg0) != data_len) {
      call Panic.panic(-1, 95, (int) test_msg0, data_len, 0, 0);
    }
    nop();
    if (call Tagnet.process_message(test_msg0)) {
      call Panic.panic(-1, 96, (int) test_msg0, 0, 0, 0);
    }
    nop();
  }

  void __attribute__((optimize("O0"))) test_tagnet_gps_xyz() {
    tagnet_tlv_t    *next_tlv;
    int              name_len;

    nop();
    nop();
    test_msg0 = buildMsg(0);
    call TagnetHeader.set_message_type(test_msg0, TN_GET);
    call TagnetHeader.set_request(test_msg0);
    call TagnetHeader.set_hops(test_msg0, 15);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_TAG_ID].name_tlv;
    name_len  = call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_INFO_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_INFO_NID_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_INFO_SENS_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_INFO_SENS_GPS_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    next_tlv  = (tagnet_tlv_t *)tn_name_data_descriptors[TN_INFO_SENS_GPS_XYZ_ID].name_tlv;
    name_len += call TagnetName.add_element(test_msg0, next_tlv);
    nop();
    if (call TagnetName.get_len(test_msg0) != name_len) {
      call Panic.panic(-1, 94, (int) test_msg0, name_len, 0, 0);
    }
    nop();
    if (call Tagnet.process_message(test_msg0)) {
      call Panic.panic(-1, 96, (int) test_msg0, 0, 0, 0);
    }
    nop();
  }

  void TN_TEST_DBG test_tagnet_message() {
    nop();
    nop();
    test_tagnet_poll_ev();
    test_tagnet_poll_cnt();
    test_tagnet_gps_xyz();
  }

  command bool InfoSensGpsXYZ.get_value(tagnet_gps_xyz_t *t, uint8_t *l) {
    nop();
    nop();
    tn_gps_xyz_count++;
    return TRUE;
  }

  event void Boot.booted() {

    nop();
    nop();

    test_tagnet_tlv();
    test_tagnet_header();
    test_tagnet_name();
    test_tagnet_payload();
    test_tagnet_message();

//    call rcTimer.startOneShot(0);
  }

//  default event bool TagnetMessage.evaluate[uint8_t id](message_t* msg) { return TRUE; };

  async event void Panic.hook() { }
}
