#!/bin/bash

# Usage: temp_throttle.sh --max-temp=65 --max-freq=auto
# USE CELSIUS TEMPERATURES.
# version 2.22

# Credits
# Wolfgang Ocker <weo AT weo1 DOT de> - Patch for unspecified cpu frequencies.

# Additional Links
# http://seperohacker.blogspot.com/2012/10/linux-keep-your-cpu-cool-with-frequency.html

cat << EOF
Author: Sepero 2016 (sepero 111 @ gmx . com)
URL: http://github.com/Sepero/temp-throttle/

EOF

# Generic function for printing an error and exiting.
err_exit () {
    echo ""
    echo -e "\033[31m\033[1m[$(date '+%H:%M:%S')] error\e[0m: $@" 1>&2
    exit 128
}

# Default values
MAX_TEMP=""
MAX_FREQ=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max-temp=*)
            MAX_TEMP="${1#*=}"
            shift 1
            ;;
        --max-freq=*)
            MAX_FREQ="${1#*=}"
            shift 1
            ;;
        *)
            err_exit "Unknown option: $1"
            ;;
    esac
done

# Check if required parameters are provided and in correct format
if [ -z "$MAX_TEMP" ] || ! [[ "$MAX_TEMP" =~ ^[0-9]+$ ]]; then
    err_exit "Please provide a valid --max-temp=65 (in celsius)."
fi

if [ -z "$MAX_FREQ" ]; then
    err_exit "Please provide a --max-freq=auto (use auto or frequency in Mhz)."
elif [ "$MAX_FREQ" != "auto" ] && ! [[ "$MAX_FREQ" =~ ^[0-9]+$ ]]; then
    err_exit "Invalid format for --max-freq. Please provide a valid frequency or 'auto'."
fi

# If --max-freq is set to "auto", retrieve the maximum CPU frequency from /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
if [ "$MAX_FREQ" = "auto" ]; then
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq" ]; then
        MAX_FREQ=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
    else
        err_exit "Could not retrieve maximum CPU frequency. Please specify a value for --max-freq."
    fi
fi

### START Initialize Global variables.

#Tthe frequency will increase when low temperature is reached.
LOW_TEMP=$((MAX_TEMP - 5))

CORES=$(nproc) # Get number of CPU cores.
echo -e "\033[33m\033[1mNumber of CPU cores detected: $CORES\033[0m"
CORES=$((CORES - 1)) # Subtract 1 from $CORES for easier counting later.

# Temperatures internally are calculated to the thousandth.
MAX_TEMP=${MAX_TEMP}000
LOW_TEMP=${LOW_TEMP}000

FREQ_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies"
FREQ_MIN="/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq"

# Store available cpu frequencies in a space separated string FREQ_LIST.
if [ -f $FREQ_FILE ]; then
    # If $FREQ_FILE exists, get frequencies from it.
    FREQ_LIST=$(cat $FREQ_FILE | xargs -n1 | sort -g -r | xargs) || err_exit "Could not read available cpu frequencies from file $FREQ_FILE"
elif [ -f $FREQ_MIN ]; then
    # Else if $FREQ_MIN exists, generate a list of frequencies starting from $FREQ_MIN.
    FREQ_LIST=$(seq $MAX_FREQ -100000 $(cat $FREQ_MIN)) || err_exit "Could not compute available cpu frequencies"
else
    err_exit "Could not determine available cpu frequencies"
fi

FREQ_LIST_LEN=$(echo $FREQ_LIST | wc -w)

# CURRENT_FREQ will save the index of the currently used frequency in FREQ_LIST.
CURRENT_FREQ=2

# This is a list of possible locations to read the current system temperature.
TEMPERATURE_FILES="
/sys/class/thermal/thermal_zone0/temp
/sys/class/thermal/thermal_zone1/temp
/sys/class/thermal/thermal_zone2/temp
/sys/class/hwmon/hwmon0/temp1_input
/sys/class/hwmon/hwmon1/temp1_input
/sys/class/hwmon/hwmon2/temp1_input
/sys/class/hwmon/hwmon0/device/temp1_input
/sys/class/hwmon/hwmon1/device/temp1_input
/sys/class/hwmon/hwmon2/device/temp1_input
null
"

# Store the first temperature location that exists in the variable TEMP_FILE.
# The location stored in $TEMP_FILE will be used for temperature readings.
for file in $TEMPERATURE_FILES; do
    TEMP_FILE=$file
    [ -f $TEMP_FILE ] && break
done

[ "$TEMP_FILE" = "null" ] && err_exit "The location for temperature reading was not found."

### END Initialize Global variables.

### START define script functions.

# Set the maximum frequency for all cpu cores.
set_freq () {
    # From the string FREQ_LIST, we choose the item at index CURRENT_FREQ.
    FREQ_TO_SET=$(echo $FREQ_LIST | cut -d " " -f $CURRENT_FREQ)
    echo $FREQ_TO_SET
    for i in $(seq 0 $CORES); do
        # Try to set core frequency by writing to /sys/devices.
        { echo $FREQ_TO_SET 2> /dev/null > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq; } ||
        # Else, try to set core frequency using command cpufreq-set.
        { cpufreq-set -c $i --max $FREQ_TO_SET > /dev/null; } ||
        # Else, return error message.
        { err_exit "Failed to set frequency CPU core$i. Run script as Root user. Some systems may require to install the package cpufrequtils."; }
    done
}

# Will reduce the frequency of cpus if possible.
throttle () {
    if [ $CURRENT_FREQ -lt $FREQ_LIST_LEN ]; then
        CURRENT_FREQ=$((CURRENT_FREQ + 1))
        echo -en "\033[31m\033[1m[$(date '+%H:%M:%S')] throttle \e[0m"
        set_freq $CURRENT_FREQ
    fi
}

# Will increase the frequency of cpus if possible.
unthrottle () {
    if [ $CURRENT_FREQ -ne 1 ]; then
        CURRENT_FREQ=$((CURRENT_FREQ - 1))
        echo -en "\033[32m\033[1m[$(date '+%H:%M:%S')] unthrottle \e[0m"
        set_freq $CURRENT_FREQ
    fi
}

get_temp () {
    # Het the system temperature. Take the max of all counters
    TEMP=$(cat $TEMPERATURE_FILES 2>/dev/null | xargs -n1 | sort -g -r | head -1)
}

### END define script functions.

echo -e "\033[33m\033[1mInitialize to max CPU frequency\033[0m"
unthrottle

# Main loop
while true; do
    get_temp # Gets the current temperature and set it to the variable TEMP.
    if   [ $TEMP -gt $MAX_TEMP ]; then # Throttle if too hot.
        throttle
    elif [ $TEMP -le $LOW_TEMP ]; then # Unthrottle if cool.
        unthrottle
    fi
    sleep 3 # The amount of time between checking temperatures.
done
