#!/bin/bash
# temp_throttle.sh max_temp

# USE CELCIUS TEMPERATURES.

if [ $# -ne 1 ]; then
	# If tempurature wasn't given, then print a message and exit.
	echo "Please supply a maximum desired temperature in Celcius." 1>&2
	echo "For example:  temp_throttle.sh 60" 1>&2
	exit 2
else
	#Set the first argument as the maximum desired temperature.
	MAX_TEMP=$1
fi

# The frequency will increase when low temperature is reached.
let LOW_TEMP=$MAX_TEMP-5

CORES=$(nproc) # Get number of CPU cores.
echo -e "Number of CPU cores detected: $CORES\n"

# Temperatures internally are calculated to the thousandth.
MAX_TEMP=${MAX_TEMP}000
LOW_TEMP=${LOW_TEMP}000

# FREQ_LIST is a list (array) of all available cpu frequencies the system allows.
declare -a FREQ_LIST=($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies))
# CURRENT_FREQ relates to the FREQ_LIST by keeping record of the currently set frequency.
let CURRENT_FREQ=1

function set_freq {
	echo ${FREQ_LIST[$1]}
	for((i=0;i<$CORES;i++)); do
		echo ${FREQ_LIST[$1]} > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq
	done
}

function throttle {
	if [ $CURRENT_FREQ -ne $((${#FREQ_LIST[@]}-1)) ]; then
		let CURRENT_FREQ+=1
		echo -n "throttle "
		set_freq $CURRENT_FREQ
	fi
}

function unthrottle {
	if [ $CURRENT_FREQ -ne 0 ]; then
		let CURRENT_FREQ-=1
		echo -n "unthrottle "
		set_freq $CURRENT_FREQ
	fi
}

function get_temp {
	# Get the system temperature.
	# If one of these doesn't work, the try uncommenting another.
	
	TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
	#TEMP=$(cat /sys/class/hwmon/hwmon0/temp1_input) 
	#TEMP=$(cat /sys/class/hwmon/hwmon1/device/temp1_input)
}

while true; do
	get_temp
	if   [ $TEMP -gt $MAX_TEMP ]; then # Throttle if too hot.
		throttle
	elif [ $TEMP -le $LOW_TEMP ]; then # Unthrottle if cool.
		unthrottle
	fi
	sleep 3
done
