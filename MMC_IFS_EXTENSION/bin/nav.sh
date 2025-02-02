#!/bin/sh 


NAV_DIR=/fs/mmc0/nav

if [ ! -e $NAV_DIR ]; then
   echo $NAV_DIR does not exist, NAV exiting
   exit 1
fi

# Point to the nav libs on the external storage medium
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/speech
export LD_LIBRARY_PATH=/usr/lib/speech:$LD_LIBRARY_PATH:/usr/lib/wicome

# Navigation specific exports
export CFG_NAVCORE_QNX_AUDIO_CARD=-1
export CFG_NAVCORE_QNX_AUDIO_DEVICE=0
export NNG_CRASHDUMP_FILE="/hbsystem/multicore/navi/3"
      
# TMC driver
export CFG_NAVCORE_TMC_SOURCE="RDS"
# export CFG_NAVCORE_TMC_SOURCE=XM
export CFG_NAVCORE_TMC_DEBUG=1

export NNG_MAXIMUM_MEMORY=31457280
export NNG_MAXIMUM_OS_MEMORY=15728640
export NNG_MAXIMUM_OS_MEMORY_BLOCK_COUNT=256

# This is only necessary for Fiat 334 EU variants
# but it shouldn't cause any harm applying it to all Fiat EU vehicles
IS_FIAT_520_VP4_EU=0
if [[ $VARIANT_PRODUCT = 52* && $VARIANT_MARKET = ECE ]]; then
  IS_FIAT_520_VP4_EU=1
fi

SHOULD_RUN_TTLS=0
if [[ $VARIANT_PRODUCT = 944 && $VARIANT_MARKET = ECE ]]; then
	SHOULD_RUN_TTLS=1
fi

if [[ -e $NAV_DIR/NNG/sys.txt ]]; then
  # If GPS_ONLY flag is set, reconfigure nav to only use GPS
  if [[ -e /fs/etfs/GPS_ONLY || -e /fs/etfs/GPS_DOT || -e /fs/mmc1/LOGGING || $IS_FIAT_520_VP4_EU -eq 1 || $SHOULD_RUN_TTLS -eq 1 ]]; then
    rm -f /tmp/sys.txt
    cp $NAV_DIR/NNG/sys.txt /tmp/sys.txt
    if [[ -e /fs/etfs/GPS_ONLY ]]; then
      echo "\n[gps]\nsource=\"qnx_gps\"" >> /tmp/sys.txt
    fi
    if [[ -e /fs/etfs/GPS_DOT ]]; then
      echo "\n[other]\nuse_show_gps_pos_from_state=1" >> /tmp/sys.txt
    fi
    if [[ -e /fs/mmc1/LOGGING ]]; then
      echo "\n[debug]\nlog_1=\"/hbsystem/multicore/navi/3::3\"\n[opennav]\nserver_logging=\"/hbsystem/multicore/navi/4\"" >> /tmp/sys.txt
    fi
    if [[ $IS_FIAT_520_VP4_EU -eq 1 || $SHOULD_RUN_TTLS -eq 1 ]]; then
      echo "\n[http]\nproxy_type=http\nproxy_host=\"127.0.0.1\"\nproxy_port=3128" >> /tmp/sys.txt
      echo "\n[tmc]\ntomtom_send_content_with_gzip=1\ntomtom_receive_content_with_zip=1\n" >> /tmp/sys.txt
    fi
    ln -sP /tmp/sys.txt $NAV_DIR/NNG/sys.txt
  fi
fi

waitfor /dev/ndr

cd $NAV_DIR/NNG
NaviServer 1> /tmp/nav1.log 2> /tmp/nav2.log &

cd $NAV_DIR/ON
#DL_DEBUG=1 ChryslerOpenNavController --nobreak --disable-watchdog  --tp=/fs/mmc0/app/share/trace/nav.hbtc --bp=/HBpersistence & 
FiatOpenNavController --nobreak --disable-watchdog  --tp=/fs/mmc0/app/share/trace/nav.hbtc --bp=/HBpersistence & 
