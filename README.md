# Disk Temp Fan Controller

## Description
This project is designed to control CPU fan speeds using disk temperatures. This was originally designed to work with TrueNAS Scale but should work with any computer (though the provided Bash scripts will need to be adapted or rewritten for that specific system).

This project was adapted from the very helpful [esp32-fan-controller](https://github.com/KlausMu/esp32-fan-controller) project for the Fabrica-IO platform. If you want a version not on Fabrica-IO and with MQTT and other features, definitely check it out.

### Principle
[Fabrica-IO](https://gabrica-io.com) is used as the fan control platform on an ESP32 hooked up to a computer fan or fans. A script running on the computer or NAS reads the disk temperatures, calculates an appropriate PWM value from those temperatures, and makes a webhook request to the EPS32 to set the fan speed. Example scripts are provided below with further details.

## Setup
> [!NOTE]
> Currently, reading from the fan's tachometer is not supported. You can either ignore anything related to that or hook it up now to be ready if/when a software update adds it in.

### Hardware

An example of the hardware needed is provided below, you don't need these exact items.

1. One or more 4-pin PWM CPU fans.
2. ESP32, this project uses the [ESP32-S3 Zero](https://www.aliexpress.us/item/3256806984814685.html), but any Fabrica-IO compatible device should work by tweaking the pins used.
3. Optional: [4-pin fan cable](https://www.amazon.com/skineat-Extension-Cable%EF%BC%8C4-Cable%EF%BC%8CCable-pc%EF%BC%8C3-Pin/dp/B08FT643QL), can optionally add fan splitters or hubs to control more fans.
4. Optional: [4-pin Molex](https://www.amazon.com/YiKaiEn-Molex-Video-Power-Supply/dp/B0BQRTBJWX) or [SATA](https://www.amazon.com/Express-Graphics-Video-Power-Adapter/dp/B0793N7TP9) power cable to get power from the computer power supply.
5. Optional: 0.1 nF (100 pF), 10 uF, and 100 uF capacitors. 10 KΩ and 3.3 KΩ resistors for reading the fan tachometer.

#### Assembly

Hardware assembly is based off of [this guide](https://github.com/KlausMu/esp32-fan-controller). Please follow the wiring guide outline [here](https://github.com/KlausMu/esp32-fan-controller/wiki/01-Wiring-diagram#wiring-diagram-for-fan-and-bme280) for hooking up the fan and connect the fan PWM to `pin 6` on the ESP32. Ignore the BME280. If you don't want to use the tachometer from the fan (__WIP__) you can also ignore everything connected to the `tacho` wire, otherwise connect it as shown using `pin 4` on the ESP32. You can either hook up to the fan directly or use the optional fan cable from above.

You can use the 4-pin Molex or SATA connector (see [pinout](https://www.smpspowersupply.com/connectors-pinouts.html)) to harvest the GND, 12V, and 5V lines from the computer's power supply. Hook up the 5V line to the `5V pin` on the ESP32. The 12V line can be connected to the 12V line on the fan cable, either by soldering to the fan cable from above or soldering the fan in directly.

Be sure to connect all the grounds (GND) together.

For added power smoothing, optionally connect the 10 uF capacitor across 5V and GND, and the 100 uF capacitor across 12V and GND.

![Example assembled device](photos/FanHub.jpg)

Plug in power form the computer power supply, then hook up the fan or fans, and that's it!

## Software

### Fabrica-IO

1. Follow the [Fabirca-IO guide](https://github.com/FabricaIO/FabricaIO-App/wiki/App-Usage#using-the-fabrica-io-app) for installing and setting up the Fabrica-IO app.
2. Copy the [fabricaio.json](fabricaio.json) file to the project directory and then load the project in the app.
3. Compile and flash the program using the Fabrica-IO app.
4. See [this guide](https://github.com/FabricaIO/FabricaIO-esp32hub/wiki/WiFi-and-Web-Interface#connecting-to-wifi) for connecting to, and setting up, the default web interface on the ESP32.
5. From the `Storage Manager` section on the web interface restore the [Backup.json](Backup.json) file to add the default configuration. Adjust the configuration through the web interface as needed.

### Script drive_temp_hook.sh

The [drive_temp_hook.sh](drive_temp_hook.sh) script should be copied to the host computer. This script use `smartctl` from [smartmontools](https://www.smartmontools.org/). You should be able to install `smartmontools` from your package manager (apt, yum, etc...), or there are instructions on their website.

The script runs every 10 seconds in an infinite loop and checks a list of disks for the hottest disk. That list should be updated to include all the relevant disks. Alternatively, all disks can be monitored by uncommenting the `smartctl-based function` in the script. Adjust the time of the loop as desired.

The script uses a linear fan curve to map the disk temperatures between 35-47 C to PWM values between 32-255. Customize these values and fan curve as needed.

The line reading `curl "http://Fabrica:Fabrica@fanhub.local/actors/add?actor=fancontrol&id=1&payload=${pwm}" > /dev/null 2>&1` will need to be updated from the default user name and password to whichever one was set in the web interface. Also, sometimes the mDNS address `fanhub.local` will take a few minutes to update or be flakey, so that can be substituted with the IP address for more reliability if one is reserved for the ESP32.

If you need to test or troubleshoot, uncomment the `echo` statements in the script. It's not recommended to leave those uncommented when not testing.

### Script temp_launcher.sh

The [temp_launcher.sh](temp_launcher.sh) script is intended to be used from a cron job or similar, and should be placed in the same directory as the `drive_temp_hook.sh` script.

This script will check if the `drive_temp_hook.sh` is running, and if not, will start it. A cron interval of 5 minutes (`*/5 * * * *`) is a good starting point to ensure the `drive_temp_hook.sh` script is always running.

If you need to test or troubleshoot, uncomment the `echo` statements in the script. It's not recommended to leave those uncommented when not testing.
