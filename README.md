temp-throttle
=============

Linux shell script for throttling system CPU frequency based on a desired maximum temperature (celsius).

Set a maximum temperature for your system using this script. If the maximum temperature is exceeded, the script will limit the speed of your CPU cores incrementally until the system is again below your desired maximum temperature. (If your system remains above maximum temperature after completely limiting your CPU cores, it will simply stay limited until temperatures drop below the maximum desired.)


This script must be run with root or sudo privileges. Only Celsius temperatures are supported. This example will limit system temperatures to 80 Celsius:

```
sudo ./temp_throttle.sh 80
```

Another way to set the temperature is to use a config file which contains
```
MAX_TEMP=80
```
and is named **~/.temp_throttle.conf** or **/etc/temp_throttle.conf**


For more instructions, see here:  
http://seperohacker.blogspot.com/2012/10/linux-keep-your-cpu-cool-with-frequency.html


Author: Sepero (sepero 111 @ gmx . com)

Links: http://github.com/Sepero/temp-throttle/  
Links: http://seperohacker.blogspot.com/2012/10/linux-keep-your-cpu-cool-with-frequency.html  

License: GNU GPL 2.0
