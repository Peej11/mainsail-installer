# mainsail-installer
This is an install script to automate the [Klipper](https://github.com/KevinOConnor/klipper), [Klipper API](https://github.com/Arksine/klipper/tree/work-web_server-20200131), and [Web Interface](https://github.com/meteyou/mainsail) installation process on Raspbian.  

Please read [How to Install](https://github.com/ArmyAg08/mainsail-installer#how-to-install) to get started.  

# What does this installer do?  
The installer will give you the option to configure several common items from running `sudo raspi-config`: change password, change hostname, and configure timezone. Hostname and timezone do impact how the Web UI displays information.

You will be prompted to download a sample Voron config from Github for your printer\'s model if you don\'t already have a config. There is a sparse config as a backup to allow the Web UI to start.  

The installer will install Klipper, the Klipper API, and the Web Interface.  

The installer will automatically compile the MCU firmware for the controller you select. It will not attempt to flash the MCU.  

The installer will provide the option to setup mjpg-streamer if you want to use a webcam. If selected, it will also configure the Web UI to display the camera feed.  

# How to Install
Flash an SD card with the Raspbian Lite image from [here](https://www.raspberrypi.org/downloads/raspbian/).  
Create a file named `ssh` (with no file extension) on the /boot partition to enable SSH.  
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
Copy a working `printer.cfg` to your home directory. (The script will copy a sparse `printer.cfg` if no config is detected to allow the UI to connect to Klipper.)  

Run the following commands to download and launch the installer:  

    wget -q -O mainsail-install.zip https://github.com/ArmyAg08/mainsail-installer/archive/master.zip && unzip -j -d ~/mainsail-installer/ mainsail-install.zip && rm mainsail-install.zip
    chmod +x ~/mainsail-installer/mainsail-install.sh
    ~/mainsail-installer/mainsail-install.sh
	
**IMPORTANT:** Please read all of the prompts carefully. There are many different configuration options to set and choose from.  

# Known Issues
* There are not currently any default configs for V0 or V1. Wget will fail in these instances.  

# To Do List
* Add MCU flashing  
* Add V0 and V1 printer.cfg links when available  
* Add SKR Mini E3 `make menuconfig` support  

Thanks to tinpec for cleaning up the first pass of my ASCII art and Fulg for bypassing the manual `make menuconfig` in klipper and a few of the other Voron devs for helping me hack my way through this :)