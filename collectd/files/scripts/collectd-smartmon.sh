#!/bin/dash 
###
# ABOUT  : collectd monitoring script for smartmontools (using smartctl)
# AUTHOR : Samuel B. <samuel_._behan_(at)_dob_._sk> (c) 2012
# LICENSE: GNU GPL v3
# SOURCE: http://devel.dob.sk/collectd-scripts/
#
# This script monitors SMART pre-fail attributes of disk drives using smartmon tools.
# Generates output suitable for Exec plugin of collectd.
###
# Requirements:
#   * smartmontools installed (and smartctl binary)
#   * User & group for collector:collector
#       groupadd collector
#       useradd -d /var/lib/collector -g collector -l -m -s /bin/sh collector
#   * sudo entry for binary (ie. for sys account):
#       collector ALL=(root) NOPASSWD:/usr/sbin/smartctl *
#   * Configuration for collectd.conf
#       LoadPlugin exec
#       <Plugin exec>
#         Exec "collector:collector" "/usr/local/bin/collectd-smartmon" "sda" "sdb"
#       </Plugin>
###
# Parameters:
#   <disk>[:<driver>,<id> ] ...
###
# Typical usage:
#   /etc/collect/smartmon.sh "sda:megaraid,4" "sdb"
#
#   Will monitor disk 4, of megaraid adapter mapped as /dev/sda and additionaly
#   normal disk /dev/sdb. See smartctl manual for more info about adapter driver names.
###
# Typical output:
#   PUTVAL <host>/smartmon-sda4/gauge-raw_read_error_rate interval=300 N:30320489
#   PUTVAL <host>/smartmon-sda4/gauge-spin_up_time interval=300 N:0
#   PUTVAL <host>/smartmon-sda4/gauge-reallocated_sector_count interval=300 N:472
#   PUTVAL <host>/smartmon-sda4/gauge-end_to_end_error interval=300 N:0
#   PUTVAL <host>/smartmon-sda4/gauge-reported_uncorrect interval=300 N:1140
#   PUTVAL <host>/smartmon-sda4/gauge-command_timeout interval=300 N:85900918876
#   PUTVAL <host>/smartmon-sda4/temperature-airflow interval=300 N:31
#   PUTVAL <host>/smartmon-sda4/temperature-temperature interval=300 N:31
#   PUTVAL <host>/smartmon-sda4/gauge-offline_uncorrectable interval=300 N:5
#   PUTVAL <host>/smartmon-sdb/gauge-raw_read_error_rate interval=300 N:0
#   PUTVAL <host>/smartmon-sdb/gauge-spin_up_time interval=300 N:4352
#   ...
#
# Monitoring additional attributes:
#   If it is needed to monitor additional SMART attributes provided by smartctl, you
#   can do it simply by echoing SMART_<Attribute-Name> environment variable as its output
#   by smartctl -A. It's nothing complicated ;)
#
# History:
#   2012-04-17 v0.1.0  - public release
#   2012-09-03 v0.1.1  - fixed dash replacemenet (thx to R.Buehl)
#   2013-08-28 v0.2.0  - Fix sudo command.
#                        Use dash as it's lower overhead.
#                        Improve docs.
#                        Add a few metrics to output.
#                        Re-order & standardise output lines for easier review & updating.
###

if [ -z "$*" ]; then
	echo "Usage: ${basename $0} <disk> <disk>..." >&2
	exit 1
fi

for disk in "$@"; do
	disk=${disk%:*}
	if ! [ -e "/dev/$disk" ]; then
		echo "${basename $0}: disk /dev/$disk not found !" >&2
		exit 1
	fi
done

HOST=`hostname -f`
INTERVAL=300
while true; do
	for disk in "$@"; do
		dsk=${disk%:*}
		drv=${disk#*:}
		id=

		if [ "$disk" != "$drv" ]; then
			drv="-d $drv"
			id=${drv#*,}
		else
			drv=
		fi
#		echo disk=$disk
#		echo drv=$drv
#		echo dsk=$dsk
#		echo id=$id
#		echo `sudo /usr/sbin/smartctl $drv -A "/dev/$dsk" | awk '$3 ~ /^0x/ && $2 ~ /^[a-zA-Z0-9_-]+$/ { gsub(/-/, "_"); print "SMART_" $2 "=" $10 }' 2>/dev/null`
		eval `sudo /usr/sbin/smartctl $drv -A "/dev/$dsk" | awk '$3 ~ /^0x/ && $2 ~ /^[a-zA-Z0-9_-]+$/ { gsub(/-/, "_"); print "SMART_" $2 "=" $10 }' 2>/dev/null`

		[ -n "$SMART_Command_Timeout" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-command_timeout interval=$INTERVAL N:${SMART_Command_Timeout:-U}" &&
			unset SMART_Command_Timeout
		[ -n "$SMART_Current_Pending_Sector" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-current_pending_sector interval=$INTERVAL N:${SMART_Current_Pending_Sector:-U}" &&
			unset SMART_Current_Pending_Sector
		[ -n "$SMART_End_to_End_Error" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-end_to_end_error interval=$INTERVAL N:${SMART_End_to_End_Error:-U}" &&
			unset SMART_End_to_End_Error
		[ -n "$SMART_Hardware_ECC_Recovered" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-hardware_ecc_recovered interval=$INTERVAL N:${SMART_Hardware_ECC_Recovered:-U}" &&
			unset SMART_Hardware_ECC_Recovered
		[ -n "$SMART_Offline_Uncorrectable" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-offline_uncorrectable interval=$INTERVAL N:${SMART_Offline_Uncorrectable:-U}" &&
			unset SMART_Offline_Uncorrectable
		[ -n "$SMART_Raw_Read_Error_Rate" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-raw_read_error_rate interval=$INTERVAL N:${SMART_Raw_Read_Error_Rate:-U}" &&
			unset SMART_Raw_Read_Error_Rate
		[ -n "$SMART_Reallocated_Sector_Ct" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-reallocated_sector_count interval=$INTERVAL N:${SMART_Reallocated_Sector_Ct:-U}" &&
			unset SMART_Reallocated_Sector_Ct
		[ -n "$SMART_Reported_Uncorrect" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-reported_uncorrect interval=$INTERVAL N:${SMART_Reported_Uncorrect:-U}" &&
			unset SMART_Reported_Uncorrect
		[ -n "$SMART_Spin_Up_Time" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-spin_up_time interval=$INTERVAL N:${SMART_Spin_Up_Time:-U}" && 
			unset SMART_Spin_Up_Time
		[ -n "$SMART_Seek_Error_Rate" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-seek_error_rate interval=$INTERVAL N:${SMART_Seek_Error_Rate:-U}" &&
			unset SMART_Seek_Error_Rate
		[ -n "$SMART_Spin_Retry_Count" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-spin_retry_count interval=$INTERVAL N:${SMART_Spin_Retry_Count:-U}" &&
			unset SMART_Spin_Retry_Count
		[ -n "$SMART_Calibration_Retry_Count" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-calibration_retry_count interval=$INTERVAL N:${SMART_Calibration_Retry_Count:-U}" &&
			unset SMART_Calibration_Retry_Count
		[ -n "$SMART_Reallocated_Event_Count" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-reallocated_event_count interval=$INTERVAL N:${SMART_Reallocated_Event_Count:-U}" &&
			unset SMART_Reallocated_Event_Count
		[ -n "$SMART_Multi_Zone_Error_Rate" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-multi_zone_error_rate interval=$INTERVAL N:${SMART_Multi_Zone_Error_Rate:-U}" &&
			unset SMART_Multi_Zone_Error_Rate
		[ -n "$SMART_Reallocated_Sector_Ct" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-reallocated_sector_ct interval=$INTERVAL N:${SMART_Reallocated_Sector_Ct:-U}" &&
			unset SMART_Reallocated_Sector_Ct
		[ -n "$SMART_Wear_Leveling_Count" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-wear_leveling_count interval=$INTERVAL N:${SMART_Wear_Leveling_Count:-U}" &&
			unset SMART_Wear_Leveling_Count
		[ -n "$SMART_Used_Rsvd_Blk_Cnt_Tot" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-used_rsvd_blk_cnt_tot interval=$INTERVAL N:${SMART_Used_Rsvd_Blk_Cnt_Tot:-U}" &&
			unset SMART_Used_Rsvd_Blk_Cnt_Tot
		[ -n "$SMART_Program_Fail_Cnt_Total" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-program_fail_cnt_total interval=$INTERVAL N:${SMART_Program_Fail_Cnt_Total:-U}" &&
			unset SMART_Program_Fail_Cnt_Total
		[ -n "$SMART_Erase_Fail_Count_Total" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-erase_fail_count_total interval=$INTERVAL N:${SMART_Erase_Fail_Count_Total:-U}" &&
			unset SMART_Erase_Fail_Count_Total
		[ -n "$SMART_Runtime_Bad_Block" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-runtime_bad_block interval=$INTERVAL N:${SMART_Runtime_Bad_Block:-U}" &&
			unset SMART_Runtime_Bad_Block
		[ -n "$SMART_UDMA_CRC_Error_Count" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-udma_crc_error_count interval=$INTERVAL N:${SMART_UDMA_CRC_Error_Count:-U}" &&
			unset SMART_UDMA_CRC_Error_Count
		[ -n "$SMART_Total_LBAs_Written" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/gauge-total_lbas_written interval=$INTERVAL N:${SMART_Total_LBAs_Written:-U}" &&
			unset SMART_Total_LBAs_Written
		[ -n "$SMART_Airflow_Temperature_Cel" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/temperature-airflow interval=$INTERVAL N:${SMART_Airflow_Temperature_Cel:-U}" &&
			unset SMART_Airflow_Temperature_Cel
		[ -n "$SMART_Temperature_Celsius" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/temperature-temperature interval=$INTERVAL N:${SMART_Temperature_Celsius:-U}" &&
			unset SMART_Temperature_Celsius
		[ -n "$SMART_Media_Wearout_Indicator" ] &&
			echo "PUTVAL $HOST/smartmon-$dsk$id/guage-media_wearout_indicator interval=$INTERVAL N:${SMART_Media_Wearout_Indicator:-U}" &&
			unset SMART_Media_Wearout_Indicator
	done

	sleep $INTERVAL || true
done
