/**
 * This module provides functions for handling Tagnet TLVs
 *<p>
 * A Tagnet TLV consists of three fields: (1) the one byte type field,
 * (2) a one byte length field, and (3) zero or more bytes of value.
 * The value field is interpreted based on the type field.
 *</p>
 *<p>
 * There are functions to copy, compare, and inspect TLVs as
 * well as to convert a TLV to/from a C type. See TagnetTLV.nc
 * for more details on these functions.
 *</p>
 *<p>
 * The Tagnet TLV is defined in TagnetTLV.h and consists of three fields:
 *</p>
 *<dl>
 *  <dt>type</dt> <dd>byte field defining data types, typically stored in a compressed format</dd>
 *  <dt>length</dt> <dd>byte field specifying length of the value field</dd>
 *  <dt>value</dt> <dd>field of zero or more bytes interpreted in context of type</dd>
 *</dl>
 *<p>
 * The structure definition for the Tagnet TLV is:
 *</p>
 *<code>
 * typedef struct tagnet_tlv_t {<br>
 *   tagnet_tlv_type_t typ;<br>
 *   uint8_t           len;<br>
 *   uint8_t           val[];<br>
 * } tagnet_tlv_t;<br>
 *</code>
 *<p>
 * Possible Tagnet TLV types include (see TagnetTLV.h for definitive list):
 *</p>
 *<code>
 * typedef enum {<br>
 *   TN_TLV_NONE=0,<br>
 *   TN_TLV_STRING=1,<br>
 *   TN_TLV_INTEGER=2,<br>
 *   TN_TLV_GPS_XYZ=3,<br>
 *   TN_TLV_UTC_TIME=4,<br>
 *   TN_TLV_NODE_ID=5,<br>
 *   TN_TLV_NODE_NAME=6,<br>
 *   TN_TLV_OFFSET=7,<br>
 *   TN_TLV_SIZE=8,<br>
 *   TN_TLV_EOF=9,<br>
 *   TN_TLV_VERSION=10,<br>
 *   _TN_TLV_COUNT   // limit of enum values<br>
 * } tagnet_tlv_type_t;<br>
 *</code>
 *
 * @author Daniel J. Maltbie <dmaltbie@daloma.org>
 *
 * @Copyright (c) 2017 Daniel J. Maltbie
 * All rights reserved.
 */
/*
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

#include <TagnetTLV.h>

module TagnetTlvP {
  provides interface TagnetTLV;
}
implementation {

  int  _copy_bytes(uint8_t *s, uint8_t *d, int l) {
    int      x;
    for (x = 0; x < l; x++)  d[x] =  s[x];
    return l;
  }

  bool  _cmp_bytes(uint8_t *s, uint8_t *d, int l) {
    int      x;
    for (x = 0; x < l; x++)  if (d[x] != s[x]) return FALSE;
    return TRUE;
  }

  command uint8_t   TagnetTLV.copy_tlv(tagnet_tlv_t *s,  tagnet_tlv_t *d, uint8_t limit) {
    uint8_t l = SIZEOF_TLV(s);
    if (l > limit)
      return 0;
    return _copy_bytes((uint8_t *) s, (uint8_t *) d, l);
  }

  command bool   TagnetTLV.eq_tlv(tagnet_tlv_t *s, tagnet_tlv_t *t) {
    if ((s->typ >= _TN_TLV_COUNT) || (t->typ >= _TN_TLV_COUNT)) {
//      panic_warn();
      return FALSE;
    }
    return (_cmp_bytes((uint8_t *)s, (uint8_t *)t, SIZEOF_TLV(s)));
  }

  command uint8_t   TagnetTLV.get_len(tagnet_tlv_t *t) {
    if (t->typ >= _TN_TLV_COUNT) {
//      panic_warn();
      return 0;
    }
    return SIZEOF_TLV(t);
  }

  command uint8_t   TagnetTLV.get_len_v(tagnet_tlv_t *t) {
    if (t->typ >= _TN_TLV_COUNT) {
//      panic_warn();
      return 0;
    }
    return t->len;
  }

  command tagnet_tlv_t  *TagnetTLV.get_next_tlv(tagnet_tlv_t *t, uint8_t limit) {
//  command __attribute__((optimize("O0"))) tagnet_tlv_t  *TagnetTLV.get_next_tlv(tagnet_tlv_t *t, uint8_t limit) {
    tagnet_tlv_t      *next_tlv;
    int                nx;

    if ((t->len == 0) || (t->typ == TN_TLV_NONE))
      return NULL;
    if (t->typ >= _TN_TLV_COUNT) {
//      panic_warn();
      return NULL;
    }
    nx = SIZEOF_TLV(t);
    if (nx < limit) {
      nx += (int) t;
      next_tlv = (tagnet_tlv_t *) nx;
      if ((next_tlv->len > 0)
          && (next_tlv->len < (limit - sizeof(tagnet_tlv_t)))
            && (next_tlv->typ != TN_TLV_NONE)
              && (next_tlv->typ < _TN_TLV_COUNT)) {
        return next_tlv;
      }
    }
    return NULL;
  }

  command tagnet_tlv_type_t TagnetTLV.get_tlv_type(tagnet_tlv_t *t) {
    if (t->typ >= _TN_TLV_COUNT) {
//      panic_warn();
      return TN_TLV_NONE;
    }
    return t->typ;
  }

  command uint8_t  TagnetTLV.gps_xyz_to_tlv(tagnet_gps_xyz_t *xyz,  tagnet_tlv_t *t, uint8_t limit) {
    int32_t    x;
    uint8_t   *v = (void *) xyz;

    nop();
    t->typ = TN_TLV_GPS_XYZ;
    t->len = TN_GPS_XYZ_LEN;
    for (x = 0; x < TN_GPS_XYZ_LEN; x++) {
      if (x >= limit) break;
      t->val[x] = v[x];
    }
    return (x == TN_GPS_XYZ_LEN) ? SIZEOF_TLV(t) : 0;
  }

  command uint8_t  TagnetTLV.integer_to_tlv(int32_t i,  tagnet_tlv_t *t, uint8_t limit) {
    int32_t    c = 0;
    bool       first = TRUE;
    int32_t    x;
    uint8_t    v;

    // assert n.to_bytes(length, 'big') == bytes( (n >> i*8) & 0xff for i in reversed(range(length)))
    nop();
    t->typ = TN_TLV_INTEGER;
    for (x = 3; x >= 0; x = x-1) {
      v = (uint8_t) (i >> (x*8));
      if (v || !first) {
        t->val[c++] = v;
        first = FALSE;
      }
    }
    if (c == 0) t->val[c++] = 0;
    t->len = c;
    nop();
    return SIZEOF_TLV(t);
  }

  command bool   TagnetTLV.is_special_tlv(tagnet_tlv_t *t) {
    switch (t->typ) {
      case TN_TLV_OFFSET:
      case TN_TLV_NODE_ID:
      case TN_TLV_GPS_XYZ:
      case TN_TLV_UTC_TIME:
        return TRUE;
      default:
        return FALSE;
    }
    return FALSE; // shouldn't get here
  }

  command int   TagnetTLV.repr_tlv(tagnet_tlv_t *t,  uint8_t *b, uint8_t limit) {
    switch (t->typ) {
      case TN_TLV_STRING:
        if (t->len > limit) return -1;
        return _copy_bytes((uint8_t *)&t->val[0], b,  t->len);
      default:
        return -1;
    }
    return -1;   // shouldn't get here
  }

  command uint8_t   TagnetTLV.string_to_tlv(uint8_t *s, uint8_t length,
                                                    tagnet_tlv_t *t, uint8_t limit) {
    if ((length + sizeof(tagnet_tlv_t)) < limit) {
      _copy_bytes(s, (uint8_t *)&t->val[0], length);
      t->len = length;
      t->typ = TN_TLV_STRING;
      return SIZEOF_TLV(t);
    }
    return 0;
  }

  command int32_t   TagnetTLV.tlv_to_integer(tagnet_tlv_t *t) {
    return t->val[0];   // zzz need to fix
  }

  command uint8_t   *TagnetTLV.tlv_to_string(tagnet_tlv_t *t, int *len) {
    uint8_t  *s = (uint8_t *)t + sizeof(tagnet_tlv_t);
    *len = t->len;
    return s;
  }

}
