/*
 * Copyright (c) 2008, 2017-2018 Eric B. Decker
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 * See COPYING in the top level directory of this source tree.
 *
 * Contact: Eric B. Decker <cire831@gmail.com>
 */

#include <typed_data.h>

interface Collect {
  command void collect(dt_header_t *header, uint16_t hlen,
                       uint8_t     *data,   uint16_t dlen);

  /* collect no timestamp.  Timestamp is filled by caller */
  command void collect_nots(dt_header_t *header, uint16_t hlen,
                            uint8_t     *data,   uint16_t dlen);

  async command uint32_t buf_offset();

  /* signal on Boot that Collect is happy and up */
  event void collectBooted();

  /* begin search for next sync from starting offset.
   * if sync is found from immediate search in dblk map cache,
   * then will return with offset of sync found. If it needs
   * to search the dblk file, it return EBUSY and will signal
   * completion when done. Otherwise, error code indicates
   * non-recoverable error.
   */
  command error_t resyncStart(uint32_t *p_offset, uint32_t term_offset);

  /* indicate search is complete */
  event void resyncDone(error_t err, uint32_t offset);
}
