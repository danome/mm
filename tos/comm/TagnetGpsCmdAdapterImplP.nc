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

#include <TinyError.h>
#include <TagnetTLV.h>

generic module TagnetGpsCmdAdapterImplP (int my_id) @safe() {
  uses interface  TagnetMessage           as  Super;
  uses interface  TagnetAdapter<uint8_t>  as  Adapter;
  uses interface  TagnetName              as  TName;
  uses interface  TagnetHeader            as  THdr;
  uses interface  TagnetPayload           as  TPload;
  uses interface  TagnetTLV               as  TTLV;
}
implementation {
  enum { my_adapter_id = unique(UQ_TAGNET_ADAPTER_LIST) };

  event bool Super.evaluate(message_t *msg) {
    uint32_t          ln       = 0;
    tagnet_tlv_t     *name_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].name_tlv;
    tagnet_tlv_t     *this_tlv = call TName.this_element(msg);
    tagnet_tlv_t     *cmd_tlv;
    uint8_t          *cmd = NULL;

    nop();
    nop();                      /* BRK */
    if (call TName.is_last_element(msg) &&          // end of name and me == this
        (call TTLV.eq_tlv(name_tlv, this_tlv))) {
      tn_trace_rec(my_id, 1);
      call THdr.set_response(msg);
      call THdr.set_error(msg, TE_PKT_OK);
      switch (call THdr.get_message_type(msg)) {      // process message type
        case TN_GET:
          tn_trace_rec(my_id, 2);
          call TPload.reset_payload(msg);
          cmd_tlv = call TPload.first_element(msg);
          if (call THdr.is_pload_type_raw(msg)) {
            cmd = (uint8_t *) cmd_tlv;
            ln = call TPload.get_len(msg);
          } else {
            cmd = call TTLV.tlv_to_block(cmd_tlv, &ln);
          }
          return TRUE;
          break;
        case TN_PUT:
          tn_trace_rec(my_id, 2);
          cmd_tlv = call TPload.first_element(msg);
          if (call THdr.is_pload_type_raw(msg)) {
            cmd = (uint8_t *) cmd_tlv;
            ln = call TPload.get_len(msg);
          } else {
            cmd = call TTLV.tlv_to_block(cmd_tlv, &ln);
          }
          call TPload.reset_payload(msg);
          if (call Adapter.set_value(cmd, &ln)) {
            call TPload.add_block(msg, cmd, ln);
          } else {
            call TPload.add_error(msg, EINVAL);
          }
          return TRUE;
          break;
        case TN_HEAD:
          tn_trace_rec(my_id, 3);
          call TPload.reset_payload(msg);                // no params
          call TPload.add_size(msg, 0);
          return TRUE;
        default:
          break;
      }
    }
    call THdr.set_error(msg, TE_PKT_NO_MATCH);
    tn_trace_rec(my_id, 255);
    return FALSE;
  }

 event void Super.add_name_tlv(message_t* msg) {
    int                     s;
    tagnet_tlv_t    *name_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].name_tlv;

    s = call TPload.add_tlv(msg, name_tlv);
    if (s) {
      call TPload.next_element(msg);
    } else {
//      panic();
    }
  }

  event void Super.add_value_tlv(message_t* msg) {
    // write only value, can't get value so nothing is added to rsp message
  }

  event void Super.add_help_tlv(message_t* msg) {
    int                     s;
    tagnet_tlv_t    *help_tlv = (tagnet_tlv_t *)tn_name_data_descriptors[my_id].help_tlv;

    s = call TPload.add_tlv(msg, help_tlv);
    if (s) {
      call TPload.next_element(msg);
    } else {
//      panic();
    }
  }
}