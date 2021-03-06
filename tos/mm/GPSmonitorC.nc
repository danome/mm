/**
 * Copyright (c) 2017 Eric B. Decker
 * All rights reserved
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include <TagnetTLV.h>

configuration GPSmonitorC {
  provides interface TagnetAdapter<tagnet_gps_xyz_t> as InfoSensGpsXyz;
  uses     interface GPSReceive;
}

implementation {
  components GPSmonitorP;
  InfoSensGpsXyz = GPSmonitorP;
  GPSReceive     = GPSmonitorP;

  components PanicC;
  GPSmonitorP.Panic -> PanicC;

  components CollectC;
  GPSmonitorP.CollectEvent -> CollectC;
  GPSmonitorP.Collect -> CollectC;
}
