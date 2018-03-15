'''sirfbin protocol headers'''

# Copyright (c) 2017-2018 Eric B. Decker, Daniel J. Maltbie
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# See COPYING in the top level directory of this source tree.
#
# Contact: Daniel J. Maltbie <dmaltbie@daloma.org>
#          Eric B. Decker <cire831@gmail.com>

# object descriptors for gps data blocks

import binascii
from   decode_base  import *
from   collections  import OrderedDict

__version__ = '0.1.1 (gh)'

########################################################################
#
# Gps Raw decode messages
#
# warning GPS messages are big endian.  The surrounding header (the dt header
# etc) is little endian (native order).
#

mids_w_sids = [
    # Output
    48, 56, 63, 64, 65, 68, 69, 70, 72, 73, 74, 75, 77,
    90, 91, 92, 93, 225, 233,

    # Input
    161, 172, 177, 178, 205, 211, 212, 213, 215, 216, 218, 219, 220, 221,
    232, 233, 234 ]


gps_nav_obj = aggie(OrderedDict([
    ('xpos',  atom(('>i', '{}'))),
    ('ypos',  atom(('>i', '{}'))),
    ('zpos',  atom(('>i', '{}'))),
    ('xvel',  atom(('>h', '{}'))),
    ('yvel',  atom(('>h', '{}'))),
    ('zvel',  atom(('>h', '{}'))),
    ('mode1', atom(('B', '0x{:02x}'))),
    ('hdop',  atom(('B', '0x{:02x}'))),
    ('mode2', atom(('B', '0x{:02x}'))),
    ('week10',atom(('>H', '{}'))),
    ('tow',   atom(('>I', '{}'))),
    ('nsats', atom(('B', '{}'))),
    ('prns',  atom(('12s', '{}', binascii.hexlify)))]))

gps_navtrk_obj = aggie(OrderedDict([
    ('week10', atom(('>H', '{}'))),
    ('tow',    atom(('>I', '{}'))),
    ('chans',  atom(('B',  '{}')))]))

gps_navtrk_chan = aggie([('sv_id',    atom(('B',  '{:2}'))),
                         ('sv_az23',  atom(('B',  '{:3}'))),
                         ('sv_el2',   atom(('B',  '{:3}'))),
                         ('state',    atom(('>H', '0x{:04x}'))),
                         ('cno0',     atom(('B',  '{}'))),
                         ('cno1',     atom(('B',  '{}'))),
                         ('cno2',     atom(('B',  '{}'))),
                         ('cno3',     atom(('B',  '{}'))),
                         ('cno4',     atom(('B',  '{}'))),
                         ('cno5',     atom(('B',  '{}'))),
                         ('cno6',     atom(('B',  '{}'))),
                         ('cno7',     atom(('B',  '{}'))),
                         ('cno8',     atom(('B',  '{}'))),
                         ('cno9',     atom(('B',  '{}')))])

gps_swver_obj   = aggie(OrderedDict([('str0_len', atom(('B', '{}'))),
                                     ('str1_len', atom(('B', '{}')))]))

gps_vis_obj     = aggie([('vis_sats', atom(('B',  '{}')))])

gps_vis_azel    = aggie([('sv_id',    atom(('B',  '{}'))),
                         ('sv_az',    atom(('>h', '{}'))),
                         ('sv_el',    atom(('>h', '{}')))])

# OkToSend
gps_ots_obj = atom(('B', '{}'))

gps_geo_obj = aggie(OrderedDict([
    ('nav_valid',        atom(('>H', '0x{:04x}'))),
    ('nav_type',         atom(('>H', '0x{:04x}'))),
    ('week_x',           atom(('>H', '{}'))),
    ('tow',              atom(('>I', '{}'))),
    ('utc_year',         atom(('>H', '{}'))),
    ('utc_month',        atom(('B', '{}'))),
    ('utc_day',          atom(('B', '{}'))),
    ('utc_hour',         atom(('B', '{}'))),
    ('utc_min',          atom(('B', '{}'))),
    ('utc_ms',           atom(('>H', '{}'))),
    ('sat_mask',         atom(('>I', '0x{:08x}'))),
    ('lat',              atom(('>i', '{}'))),
    ('lon',              atom(('>i', '{}'))),
    ('alt_elipsoid',     atom(('>i', '{}'))),
    ('alt_msl',          atom(('>i', '{}'))),
    ('map_datum',        atom(('B', '{}'))),
    ('sog',              atom(('>H', '{}'))),
    ('cog',              atom(('>H', '{}'))),
    ('mag_var',          atom(('>H', '{}'))),
    ('climb',            atom(('>h', '{}'))),
    ('heading_rate',     atom(('>h', '{}'))),
    ('ehpe',             atom(('>I', '{}'))),
    ('evpe',             atom(('>I', '{}'))),
    ('ete',              atom(('>I', '{}'))),
    ('ehve',             atom(('>H', '{}'))),
    ('clock_bias',       atom(('>i', '{}'))),
    ('clock_bias_err',   atom(('>i', '{}'))),
    ('clock_drift',      atom(('>i', '{}'))),
    ('clock_drift_err',  atom(('>i', '{}'))),
    ('distance',         atom(('>I', '{}'))),
    ('distance_err',     atom(('>H', '{}'))),
    ('head_err',         atom(('>H', '{}'))),
    ('nsats',            atom(('B', '{}'))),
    ('hdop',             atom(('B', '{}'))),
    ('additional_mode',  atom(('B', '0x{:02x}'))),
]))


# pwr_mode_req, MID 218, has SID
gps_pwr_mode_req_obj = aggie(OrderedDict([
    ('sid',              atom(('B',  '{}'))),
    ('timeout',          atom(('B',  '{}'))),
    ('control',          atom(('B',  '{}'))),
    ('reserved',         atom(('>H', '{}'))),
]))

# pwr_mode_rsp, MID 90, has SID
gps_pwr_mode_rsp_obj = aggie(OrderedDict([
    ('sid',              atom(('B', '{}'))),
    ('error',            atom(('>H', '0x{:02x}'))),
    ('reserved',         atom(('>H', '{}'))),
]))


# statistics, MID 225, 6
gps_statistics_obj    = aggie(OrderedDict([
    ('sid',             atom(('B',  '{}'))),
    ('ttff_reset',      atom(('>H', '{}'))),
    ('ttff_aiding',     atom(('>H', '{}'))),
    ('ttff_nav',        atom(('>H', '{}'))),
    ('pae_n',           atom(('>i', '{}'))),
    ('pae_e',           atom(('>i', '{}'))),
    ('pae_d',           atom(('>i', '{}'))),
    ('time_aiding_err', atom(('>i', '{}'))),
    ('freq_aiding_err', atom(('>h', '{}'))),
    ('pos_unc_horz',    atom(('B',  '{}'))),
    ('pos_unc_vert',    atom(('>H', '{}'))),
    ('time_unc',        atom(('B',  '{}'))),
    ('freq_unc',        atom(('B',  '{}'))),
    ('n_aided_ephem',   atom(('B',  '{}'))),
    ('n_aided_acq',     atom(('B',  '{}'))),
    ('nav_mode',        atom(('B',  '{}'))),
    ('pos_mode',        atom(('B',  '{}'))),
    ('status',          atom(('>H', '{}'))),
    ('start_mode',      atom(('B',  '{}'))),
    ('reserved',        atom(('B',  '{}')))
]))


# start_mode
start_mode_names = {
     0: "cold",
     1: "warm",
     2: "hot",
     3: "fast",
}


# sirfbin header, big endian.
# start: 0xa0a2
# len:   big endian, < 2047
# mid:   byte
raw_gps_hdr_obj = aggie(OrderedDict([('start',   atom(('>H', '0x{:04x}'))),
                                     ('len',     atom(('>H', '0x{:04x}'))),
                                     ('mid',     atom(('B',  '0x{:02x}')))]))