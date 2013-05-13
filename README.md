temp-throttle
=============

A shell script for throttling system CPU frequency based on a desired maximum temperature.

Set a desired maximum temperature for your system using this script. If the maximum temperature is exceeded, the script will limit the speed of your CPU cores incrementally until the system is again below your desired maximum temperature. (If your system remains above maximum temperature after completely limiting your CPU cores, it will simply stay limited until temperatures drop below the maximum desired.)


This script must be run with root or sudo privileges. Only Celsius temperatures are supported. This example will limit system temperatures to 80 Celsius:

    sudo ./temp_throttle 80


For more information and a bit friendly instructions, see here:  
http://seperohacker.blogspot.com/2012/10/linux-keep-your-cpu-cool-with-frequency.html


Authors: Sepero (sepero 111 @ gmail . com)

Links: http://github.com/Sepero/temp-throttle/
Links: http://seperohacker.blogspot.com/2012/10/linux-keep-your-cpu-cool-with-frequency.html

License: GNU GPL 2.0

Usage: temp_throttle.sh max_temp
USE CELSIUS TEMPERATURES.
