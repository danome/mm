/**
 * Copyright (c) 2017 Daniel J. Maltbie
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
 * @author Daniel J. Maltbie <dmaltbie@daloma.org>
 *
 */

#include "Tagnet.h"
#include "TagnetTLV.h"

generic module TagnetNameElementImplP(int my_id, char uq_id[]) @safe() {
  uses interface     TagnetMessage  as  Super;
  provides interface TagnetMessage  as  Sub[uint8_t id];
  uses interface     TagnetName     as  TName;
  uses interface     TagnetHeader   as  THdr;
  uses interface     TagnetPayload  as  TPload;
  uses interface     TagnetTLV      as  TTLV;
}
implementation {
  enum { SUB_COUNT = uniqueCount(uq_id) };

  event bool Super.evaluate(message_t *msg) {
//  event __attribute__((optimize("O0"))) bool Super.evaluate(message_t *msg) {
    tagnet_tlv_t    *name_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].name_tlv;
    tagnet_tlv_t    *help_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].help_tlv;
    tagnet_tlv_t    *this_tlv;
    tagnet_tlv_t    *next_tlv;
    uint8_t          matched = FALSE;
    int              i;
    
    this_tlv = call TName.this_element(msg);
    if (call TTLV.get_tlv_type(this_tlv) == TN_TLV_NODE_ID) { // node_id is special
      if (call TTLV.eq_tlv(name_tlv, this_tlv)                // if   me == this
          || call TTLV.eq_tlv(name_tlv,
                              (tagnet_tlv_t *)TN_NONE_TLV)    // or   me == none
          || call TTLV.eq_tlv(this_tlv,
                         (tagnet_tlv_t *)TN_BCAST_NID_TLV)) { // or this == bcast
        matched = TRUE;
      }
    } else if (call TTLV.eq_tlv(name_tlv, this_tlv)) {
      matched = TRUE;                                         // else me == this
    }
    tn_trace_rec(my_id, 1);
    if (matched) {                        // further processing if name matched
      next_tlv = call TName.next_element(msg);
      if (next_tlv == NULL) {                   // end of name, execute request
        call THdr.set_response(msg);
        call TPload.reset_payload(msg);
        call THdr.set_error(msg, TE_PKT_OK);
        switch (call THdr.get_message_type(msg)) {      // process message type
          case TN_GET:
            call TPload.add_integer(msg, SUB_COUNT);
            for (i=0;i<SUB_COUNT;i++) {
              signal Sub.add_name_tlv[i](msg);
              signal Sub.add_value_tlv[i](msg);
            }
            tn_trace_rec(my_id, 2);
            return TRUE;
          case TN_HEAD:
            call TPload.add_tlv(msg, help_tlv);
            tn_trace_rec(my_id, 3);
            return TRUE;
          default:
            break;
        }
      } else {                                         // else check subordinates
        for (i=0; i<SUB_COUNT; i++) {
          tn_trace_rec(my_id, 3);
          if (signal Sub.evaluate[i](msg)) {         // subordinate matched, done
            return TRUE;
          }
        }
      }
    }
    call THdr.set_error(msg, TE_PKT_NO_MATCH);
    tn_trace_rec(my_id, 255);
    return FALSE;                                   // no match, do nothing
  }

  command uint8_t Sub.get_full_name[uint8_t id](uint8_t *buf, uint8_t limit) {
    uint8_t       l;
    tagnet_tlv_t    *name_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].name_tlv;

    l = call TTLV.copy_tlv(name_tlv, (tagnet_tlv_t*)buf, limit);
    if ((l) && (limit >= l)) {
      return call Super.get_full_name((uint8_t *)(buf + l), limit - l);
    } else {
//      panic();
    }
    return 0;
  }

  event void Super.add_name_tlv(message_t* msg) {
    uint8_t       s;
    tagnet_tlv_t    *name_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].name_tlv;

    s = call TPload.add_tlv(msg, name_tlv);
    if (s) {
      call TPload.next_element(msg);
    } else {
//      panic();
    }
  }

  event void Super.add_value_tlv(message_t* msg) {
    uint8_t       s;

    s = call TPload.add_integer(msg, SUB_COUNT);
    if (s) {
      call TPload.next_element(msg);
    } else {
//      panic();
    }
  }

  event void Super.add_help_tlv(message_t* msg) {
    uint8_t       s;
    tagnet_tlv_t    *help_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].help_tlv;

    s = call TPload.add_tlv(msg, help_tlv);
    if (s) {
      call TPload.next_element(msg);
    } else {
//      panic();
    }
  }

  default event bool Sub.evaluate[uint8_t id](message_t* msg) {
    return TRUE;
  }
  default event void Sub.add_name_tlv[uint8_t id](message_t *msg) {
  }
  default event void Sub.add_value_tlv[uint8_t id](message_t *msg) {
  }
  default event void Sub.add_help_tlv[uint8_t id](message_t *msg) {
  }
}
