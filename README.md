# mainsail-installer
This is an install script to setup [Klipper](https://github.com/KevinOConnor/klipper), the [Klipper API](https://github.com/Arksine/klipper/tree/work-web_server-20200131), and the [Web Interface](https://github.com/meteyou/mainsail) on a clean SD card image with Raspbian.

Thanks to tinpec for cleaning up the first pass of my ASCII art :)

# How to Install
Flash an SD card with the Raspbian image.  
Be sure to place a file named `ssh` to enable SSH.  
Create a file called `wpa_supplicant.conf` and add the contents to configure wireless access.  
Sample contents look like this:  

    country=US
    update_config=1
    ctrl_interface=/var/run/wpa_supplicant

    network={
     scan_ssid=1
     ssid="<YOUR_WIRELESS_SSID>"
     psk="<YOUR_WIRELESS_PASSWORD>"
    }  

Copy the contents of this repository to ~/mainsail-installer on the pi.  
Copy a working `printer.cfg` to your home directory. The script will copy a sample `printer.cfg` if no config is detected but it may cause issues in its current form.  
Run `chmod +x ~/mainsail-installer/mainsail-installer.sh` to make executable.  
Run `~/mainsail-installer/mainsail-installer.sh` to start the install.  

Note: This script will require input for `make menuconfig` during the Klipper install but is otherwise completely automated.

# Known Issues
* Be sure to use your working `printer.cfg` from your current printer. The installer will use a simple config otherwise but it will cause issues currently.  
* The install process for Klipper will only compile the MCU firmware. You may get connection errors if the firmware on the board is not already flashed for Klipper.  
* ~~Installer will only report a wireless IP address at the end. If you have a wired connection, it won\'t display an address.~~  
* ~~Error detection isn\'t terribly robust.~~

# To Do List
* Clean up `printer.cfg` handling  
* Add MCU flashing  
* ~~Add 'support' for wired or wireless connections~~  
* ~~Better error handling~~  
* ~~Add MJPEG install & configure webcam~~