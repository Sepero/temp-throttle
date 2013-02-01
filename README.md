temp-throttle
=============

A shell script for throttling system CPU frequency based on a desired maximum temperature.

Set a desired maximum temperature for your system using this script. If the maximum tempurature is exeeded, the script will limit the speed of your CPU cores incrementally until the system is again below your desired maximum temperature. (If your system remains above maximum temperature after completely limiting your CPU cores, it will simply stay limited until temperatures drop below the maximum desired.)


This script must be run with root priviledges. Only celcius temperatures are supported. This example will limit system temperatures to 80 Celcius:

    sudo ./temp_throttle 80


For more information and mildly user friendly instructions, see here:
http://seperohacker.blogspot.com/2012/10/linux-keep-your-cpu-cool-with-frequency.html
