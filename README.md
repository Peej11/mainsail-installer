# mainsail-installer
This is an install script to setup [Klipper](https://github.com/KevinOConnor/klipper), the [Klipper API](https://github.com/Arksine/klipper/tree/work-web_server-20200131), and the [Web Interface](https://github.com/meteyou/mainsail) on a clean SD card image with Raspbian.  
Thanks to tinpec for cleaning up the first pass of my ASCII art and Fulg for bypassing the manual `make menuconfig` in klipper :)

# What does this installer do?  
The installer will give you the option to configure several common items from running `sudo raspi-config`: change password, change hostname, and configure timezone. Hostname and timezone do impact how the Web UI displays information.

You will be prompted to download a sample Voron config from Github for your printer\'s model if you don\'t already have a config. There is a sparse config as a backup to allow the Web UI to start.  

The installer will install Klipper, the Klipper API, and the Web Interface.  

The installer will automatically compile the MCU firmware for the controller you select. It will not attempt to flash the MCU.  

The installer will provide the option to setup mjpg-streamer if you want to use a webcam. If selected, it will also configure the Web UI to display the camera feed.  

# How to Install
Flash an SD card with the Raspbian image from [here](https://www.raspberrypi.org/downloads/raspbian/).  
Be sure to place a file named `ssh` on the /boot partition to enable SSH.  
Create a file called `wpa_supplicant.conf` on the /boot partition and add the contents to configure wireless access.  

Sample contents look like this:  

    country=US
    update_config=1
    ctrl_interface=/var/run/wpa_supplicant

    network={
     scan_ssid=1
     ssid="<YOUR_WIRELESS_SSID>"
     psk="<YOUR_WIRELESS_PASSWORD>"
    }  

Boot and SSH into your pi. Default credentials are pi/raspberry.  
Copy the contents of this repository to ~/mainsail-installer on the pi.  
Copy a working `printer.cfg` to your home directory. (The script will copy a sparse `printer.cfg` if no config is detected to allow the UI to connect to Klipper.)  
Run `chmod +x ~/mainsail-installer/mainsail_install.sh` to make executable.  
Run `~/mainsail-installer/mainsail_install.sh` to start the install.  

# Known Issues
* There are not currently any default configs for V0 or V1. Wget will fail in these instances.
* If you try to use a PiCam, mjpg-streamer will fail to start. Enable the camera with `sudo raspi-config` and restart.  
* ~~The installer works best if you use your working `printer.cfg` from your current printer. The installer will download a stock config based on user input if available. Otherwise it will fallback to a simple config but it will cause issues currently.~~  
* ~~The install process for Klipper will only compile the MCU firmware. You may get connection errors if the firmware on the board is not already flashed for Klipper.~~  
* ~~Installer will only report a wireless IP address at the end. If you have a wired connection, it won\'t display an address.~~  
* ~~Error detection isn\'t terribly robust.~~  
* ~~If the Klipper service fails to start, the installer may show as failed. You can run `cat /tmp/klippy.log` to check for errors.~~

# To Do List
* Add MCU flashing  
* Validate IP address input  
* Add V0 and V1 printer.cfg links when available
* Add PiCam support
* ~~Clean up `printer.cfg` handling~~  
* ~~Add 'support' for wired or wireless connections~~  
* ~~Better error handling~~  
* ~~Add MJPEG install & configure webcam~~  
