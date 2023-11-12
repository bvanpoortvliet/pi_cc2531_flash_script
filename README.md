# pi_cc2531_flash_script
Quick and dirty script to grab sources, install wiringpi, and flash CC2531 chip via Raspberry Pi.
..Not that the [instructions](https://www.zigbee2mqtt.io/guide/adapters/flashing/alternative_flashing_methods.html) were not clear but this is easier.

1). wget this script  
2). run `bash ./cc2531_flash.sh` to flash, use `sudo` if you need to install wiringpi  
3). script will start downloading wiringpi, flashing software and (router) firmware that needs to be flashed  
4). script checks if there's a (sort of) valid chip_id present  
5). script propmts for flash confirmation upon which it will start running  

As stated, this is a quick and dirty script without too much errorhandling. Optimization suggestions are always welcome, just create an issue.  
