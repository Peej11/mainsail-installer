#!/bin/sh
# This will install Mainsail for Klipper on a clean Raspbian image

COL_RED='\e[0;31m'
COL_NONE='\e[0m'
ERROR=0
SYSTEM_IP="$(ip route get 1.1.1.1 | awk '{print $7}' | head -n1)"
MAINSAIL_FILE="https://github.com/meteyou/mainsail/releases/download/v0.0.10/mainsail-alpha-0.0.10.zip"
GUI_JSON="{\"webcam\":{\"url\":\"http://${SYSTEM_IP}:8081/?action=stream\"},\"gui\":{\"dashboard\":{\"boolWebcam\":true,\"boolTempchart\":true,\"boolConsole\":false,\"hiddenMacros\":[]},\"webcam\":{\"bool\":false},\"gcodefiles\":{\"countPerPage\":10}}}"
CURRENT_HOSTNAME="$(hostname)"
KLIPPER_DIR=/home/pi/klipper
KLIPPER_CONFIG_FRAGMENT=${KLIPPER_DIR}/.config_fragment
V0_CONFIG=""
V1_250_CONFIG=""
V1_300_CONFIG=""
V2_250_CONFIG="https://raw.githubusercontent.com/VoronDesign/Voron-2/Voron2.4/firmware/klipper_configurations/VORON2_stock_250_printer.cfg"
V2_300_CONFIG="https://raw.githubusercontent.com/VoronDesign/Voron-2/Voron2.4/firmware/klipper_configurations/VORON2_stock_300_printer.cfg"
V2_350_CONFIG="https://raw.githubusercontent.com/VoronDesign/Voron-2/Voron2.4/firmware/klipper_configurations/VORON2_stock_350_printer.cfg"


verify_ready() {
  if [ "$EUID" -eq 0 ]; then
    echo "This script must not run as root"
    exit -1
  fi
}

ascii_art() {
  echo -e "
  ${COL_NONE}
             ██╗  ██╗██╗     ██╗██████╗ ██████╗ ███████╗██████╗ 
             ██║ ██╔╝██║     ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗   
             █████╔╝ ██║     ██║██████╔╝██████╔╝█████╗  ██████╔╝         
             ██╔═██╗ ██║     ██║██╔═══╝ ██╔═══╝ ██╔══╝  ██╔══██╗         
             ██║  ██╗███████╗██║██║     ██║     ███████╗██║  ██║            
             ╚═╝  ╚═╝╚══════╝╚═╝╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝
  
         ███╗   ███╗ █████╗ ██╗███╗   ██╗███████╗ █████╗ ██╗██╗      
         ████╗ ████║██╔══██╗██║████╗  ██║██╔════╝██╔══██╗██║██║      
         ██╔████╔██║███████║██║██╔██╗ ██║███████╗███████║██║██║         
         ██║╚██╔╝██║██╔══██║██║██║╚██╗██║╚════██║██╔══██║██║██║      
         ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║███████║██║  ██║██║███████╗ 
         ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝ 
  
   ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗  
   ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗ 
   ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝ 
   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗ 
   ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║ 
   ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ 
  ${COL_RED}
                                    ###
                                ###########
                            ###################
                        ###########################
                     ##################################
                 ##########################################
             #################################################
         #########################################################
     #################################################################
   ########################          #########           ###############
   ######################           #########           ################
   #####################          #########           ##################
   ###################           #########           ###################
   ##################          #########           #####################
   ################           #########           ######################
   ###############          #########           ########################
   #############           #########           #########################
   ############          #########           ###########################
   ###########          #########           ############################
   ############################           #########          ###########
   ###########################           #########          ############
   #########################           #########           #############
   ########################           #########          ###############
   ######################           #########           ################
   #####################           #########          ##################
   ###################           #########           ###################
   ##################           #########          #####################
   ################           #########           ######################
   ###############           #########          ########################
     #################################################################
         #########################################################
             #################################################
                 ##########################################
                     ##################################
                         ##########################
                             ##################
                                ###########
                                    ###
  ${COL_NONE}
  "
  sleep 2
}

set_config_var() {
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

clear_config_var() {
  lua - "$1" "$2" <<EOF > "$2.bak"
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
  if line:match("^%s*"..key.."=.*$") then
    line="#"..line
  end
  print(line)
end
EOF
mv "$2.bak" "$2"
}

get_config_var() {
  lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
local found=false
for line in file:lines() do
  local val = line:match("^%s*"..key.."=(.*)$")
  if (val ~= nil) then
    print(val)
    found=true
    break
  end
end
if not found then
   print(0)
end
EOF
}

clean_image_warning() {
  if (whiptail --title "Confirm Install" --yesno "This installer is intended to run on a clean Raspbian image. Do you want to continue?" 8 78); then
    CONTINUE_INSTALL="Y"
  else
    exit 0
  fi
}

get_inputs() {
  IP_ADDRESS_RESPONSE=$(whiptail --title "Provide IP Address" --inputbox "Please provide your IP address.\nThis will be used to allow access to the Web UI.\nYou can provide an address range using CIDR notation to whitelist an entire subnet.\nIf you want to whitelist a specific client provide just that client's IP address.\nYou can edit this later in your printer.cfg under the api_server section." 12 90 "192.168.0.0/24" 3>&1 1>&2 2>&3)
  
  if (whiptail --title "Setup Webcam" --yesno "Do you want to setup mjpeg-streamer to use a webcam?" 8 78); then
    WEBCAM_SETUP_RESPONSE="Y"
  whiptail --title "Verify Webcam" --msgbox "You must have your webcam connected or the mjpeg-streamer service won't start." 8 78
  else
    WEBCAM_SETUP_RESPONSE="N"
  fi
  
  if (whiptail --title "Change Hostname" --yesno "Do you want to change the system hostname?" 8 78); then
    CHANGE_HOSTNAME_RESPONSE="Y"
    NEW_HOSTNAME=$(whiptail --title "Hostname" --inputbox "Please provide a hostname." 8 78 3>&1 1>&2 2>&3)
  else
    CHANGE_HOSTNAME_RESPONSE="N"
  fi
  
  if (whiptail --title "Change Timezone" --yesno "Do you want to change the timezone? This will allow the Web UI to show correct times in various locations. The current timezone is $(cat /etc/timezone)." 9 78); then
    CHANGE_TIMEZONE_RESPONSE="Y"
    sudo dpkg-reconfigure tzdata
  else
    CHANGE_TIMEZONE_RESPONSE="N"
  fi
  
  MCU_SETUP_RESPONSE=$(whiptail --title "Select MCU" --menu "Which MCU do you need to prepare Klipper for? This will selection will run make menuconfig in the background." 16 70 7 \
      "SKR" "Bigtreetech SKR 1.3, SKR 1.4, SKR Mini E3" \
      "RAMPS" "RAMPs 1.4 or variant" \
      "Duet" "Duet or Duet Wifi" \
      "Einsy" "Einsy Rambo" \
      "F6" "FYSETC F6" \
      "sBase" "MKS sBase" 3>&2 2>&1 1>&3
    )
  
  if (whiptail --title "Verify printer.cfg" --yesno "Do you already have a working printer.cfg you will use for this setup?" 8 78); then
    whiptail --title "Verify printer.cfg" --msgbox "Ensure your printer.cfg is already copied to /home/pi before continuing." 8 78
  else
    PRINTER_MODEL=$(whiptail --title "Select printer" --menu "What printer model do you have?" 12 48 4 \
      "V0" "" \
      "V1" ""\
      "V2" "" 3>&2 2>&1 1>&3
    )
  fi
  
  case $PRINTER_MODEL in
    "V0")
      whiptail --title "Download printer.cfg" --msgbox "The default V0 config will be downloaded from Github." 8 78
      cd /home/pi
      wget -O "printer.cfg" $V0_CONFIG
    ;;
    "V1")
      PRINTER_MODEL=$(whiptail --title "Select printer size" --menu "What size is your printer?" 12 48 4 \
      "250^3" "" \
      "300^3" "" 3>&2 2>&1 1>&3)
    case $PRINTER_MODEL in
      "250^3")
        whiptail --title "Download printer.cfg" --msgbox "The default V1 - 250^3 config will be downloaded from Github." 8 78
        cd /home/pi
        wget -O "printer.cfg" $V1_250_CONFIG
      ;;
      "300^3")
        whiptail --title "Download printer.cfg" --msgbox "The default V1 - 300^3 config will be downloaded from Github." 8 78
        cd /home/pi
        wget -O "printer.cfg" $V1_300_CONFIG
      ;;
    esac
    ;;
    "V2")
      PRINTER_MODEL=$(whiptail --title "Select printer size" --menu "What size is your printer?" 12 48 4 \
      "250^3" "" \
      "300^3" "" \
      "350^3" "" 3>&2 2>&1 1>&3)
    case $PRINTER_MODEL in
      "250^3")
        whiptail --title "Download printer.cfg" --msgbox "The default V2 - 250^3 config will be downloaded from Github." 8 78
        cd /home/pi
        wget -O "printer.cfg" $V2_250_CONFIG
      ;;
      "300^3")
        whiptail --title "Download printer.cfg" --msgbox "The default V2 - 300^3 config will be downloaded from Github." 8 78
        cd /home/pi
        wget -O "printer.cfg" $V2_300_CONFIG
      ;;
      "350^3")
        whiptail --title "Download printer.cfg" --msgbox "The default V2 - 350^3 config will be downloaded from Github." 8 78
        cd /home/pi
        wget -O "printer.cfg" $V2_350_CONFIG
      ;;
    esac
    ;;
  esac   
 
  whiptail --title "IMPORTANT NOTICE" --msgbox "This installer will take several minutes to complete.\nYou should be able to access Mainsail in your browser at ${SYSTEM_IP} after the install completes." 10 105
}

verify_inputs() {
  if (whiptail --title "Verify Settings" --yesno "Please confirm the installer settings before continuing:\n\nIP whitelist for Web UI: $IP_ADDRESS_RESPONSE\nConfigure mjpeg-streamer: $WEBCAM_SETUP_RESPONSE\nChange system hostname: $CHANGE_HOSTNAME_RESPONSE\nMCU firmware version: $MCU_SETUP_RESPONSE" 12 78); then
    echo
    echo
    echo "#################"
    echo "Beginning Install"
    echo "#################"
    echo
  else
    get_inputs
  fi
}

do_lpc_config() {
  echo
  echo "DO LPC CONFIG"
  echo
  cat <<'EOF' >> ${KLIPPER_CONFIG_FRAGMENT}
CONFIG_MACH_LPC176X=y
CONFIG_STEP_DELAY=2
CONFIG_BOARD_DIRECTORY="lpc176x"
CONFIG_MCU="lpc1768"
CONFIG_CLOCK_FREQ=100000000
CONFIG_USBSERIAL=y
CONFIG_FLASH_START=0x4000
CONFIG_FLASH_SIZE=0x80000
CONFIG_RAM_START=0x10000000
CONFIG_RAM_SIZE=0x7fe0
CONFIG_STACK_SIZE=512
CONFIG_LPC_SELECT=y
CONFIG_MACH_LPC1768=y
CONFIG_SMOOTHIEWARE_BOOTLOADER=y
CONFIG_USB_VENDOR_ID=0x2341
CONFIG_USB_DEVICE_ID=0xabcd
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
CONFIG_USB_SERIAL_NUMBER="12345"
CONFIG_HAVE_GPIO=y
CONFIG_HAVE_GPIO_ADC=y
CONFIG_HAVE_GPIO_SPI=y
CONFIG_HAVE_GPIO_I2C=y
CONFIG_HAVE_GPIO_BITBANGING=y
CONFIG_HAVE_CHIPID=y
CONFIG_INLINE_STEPPER_HACK=y
EOF
}

do_duet_config() {
  echo
  echo "DO DUETWIFI CONFIG"
  echo
  cat <<'EOF' >> ${KLIPPER_CONFIG_FRAGMENT}
CONFIG_MACH_ATSAM=y
CONFIG_STEP_DELAY=2
CONFIG_BOARD_DIRECTORY="atsam"
CONFIG_MCU="sam4e8e"
CONFIG_CLOCK_FREQ=120000000
CONFIG_USBSERIAL=y
CONFIG_ATSAM_SELECT=y
CONFIG_MACH_SAM4E8E=y
CONFIG_MACH_SAM4=y
CONFIG_MACH_SAM4E=y
CONFIG_FLASH_START=0x400000
CONFIG_FLASH_SIZE=0x80000
CONFIG_RAM_START=0x20000000
CONFIG_RAM_SIZE=0x20000
CONFIG_STACK_SIZE=512
CONFIG_USB_VENDOR_ID=0x2341
CONFIG_USB_DEVICE_ID=0xabcd
CONFIG_USB_SERIAL_NUMBER_CHIPID=y
CONFIG_USB_SERIAL_NUMBER="12345"
CONFIG_HAVE_GPIO=y
CONFIG_HAVE_GPIO_ADC=y
CONFIG_HAVE_GPIO_SPI=y
CONFIG_HAVE_GPIO_I2C=y
CONFIG_HAVE_GPIO_HARD_PWM=y
CONFIG_HAVE_GPIO_BITBANGING=y
CONFIG_HAVE_CHIPID=y
CONFIG_INLINE_STEPPER_HACK=y
EOF
}

do_avr_config() {
  echo
  echo "DO AVR CONFIG"
  echo
  cat <<'EOF' >> ${KLIPPER_CONFIG_FRAGMENT}
CONFIG_MACH_AVR=y
CONFIG_AVR_SELECT=y
CONFIG_STEP_DELAY=-1
CONFIG_BOARD_DIRECTORY="avr"
CONFIG_MACH_atmega2560=y
CONFIG_MCU="atmega2560"
CONFIG_AVRDUDE_PROTOCOL="wiring"
CONFIG_CLOCK_FREQ=16000000
CONFIG_AVR_CLKPR=-1
CONFIG_AVR_STACK_SIZE=256
CONFIG_AVR_WATCHDOG=y
CONFIG_SERIAL=y
CONFIG_SERIAL_BAUD_U2X=y
CONFIG_SERIAL_PORT=0
CONFIG_SERIAL_BAUD=250000
CONFIG_HAVE_GPIO=y
CONFIG_HAVE_GPIO_ADC=y
CONFIG_HAVE_GPIO_SPI=y
CONFIG_HAVE_GPIO_I2C=y
CONFIG_HAVE_GPIO_HARD_PWM=y
CONFIG_HAVE_GPIO_BITBANGING=y
CONFIG_INLINE_STEPPER_HACK=y
EOF
}

install_packages() {  
  cd /home/pi
  
  echo
  echo
  echo "##################################"
  echo "Running apt update and apt upgrade"
  echo "##################################"
  echo
  sleep .5
  sudo apt update && sudo apt upgrade -y
  echo
  echo
  echo "###################"
  echo "Installing packages"
  echo "###################"
  echo
  sleep .5
  sudo apt install git lua5.1 -y
}

install_printer_config() {  
  echo
  echo
  echo "########################"
  echo "Checking for printer.cfg"
  echo "########################"
  echo
  sleep .5
    
  if [ -e "/home/pi/printer.cfg" ]; then  
    echo "Printer.cfg exists"
    echo "Verifying virtual_sdcard and api_server are enabled"
	if [ -e "/home/pi/mainsail-installer/empty_printer.cfg" ]; then
      rm /home/pi/mainsail-installer/empty_printer.cfg
    fi
    sleep .5

    if [ $(grep '^\[virtual_sdcard\]$' /home/pi/printer.cfg) ]; then
      echo "Virtual SDcard is already configured"
    else
      echo "Virtual SDcard is not configured in printer.cfg"
      echo "Configuring Virtual SDcard"
      printf "\n\n" >> /home/pi/printer.cfg
	  echo "[virtual_sdcard]" >> /home/pi/printer.cfg
      echo "path: /home/pi/sdcard" >> /home/pi/printer.cfg
    fi
    
    if [ $(grep '^\[api_server\]$' /home/pi/printer.cfg) ]; then
      echo "API Server is already configured"
    else
      echo "API Server is not configured in printer.cfg"
      echo "Configuring API Server"
      printf "\n\n" >> /home/pi/printer.cfg
	  echo "[api_server]" >> /home/pi/printer.cfg
      echo "trusted_clients:" >> /home/pi/printer.cfg
      echo " $IP_ADDRESS_RESPONSE" >> /home/pi/printer.cfg
      echo " 127.0.0.0/24" >> /home/pi/printer.cfg
    fi
  
  else
    echo "Printer.cfg does not exist"
    echo "Copying sample file for Mainsail to use."
    sleep .5
    mv /home/pi/mainsail-installer/empty_printer.cfg /home/pi/printer.cfg
    chown pi:pi /home/pi/printer.cfg
    chmod 644 /home/pi/printer.cfg
  fi
}

install_klipper() {
  echo
  echo
  echo "##################"
  echo "Installing Klipper"
  echo "##################"
  echo
  sleep .5
  git clone https://github.com/KevinOConnor/klipper
  /home/pi/klipper/scripts/install-octopi.sh
  
  echo "Building and Flashing the MCU"
  cd $KLIPPER_DIR
				  
  
  case "$MCU_SETUP_RESPONSE" in
    "RAMPS") do_avr_config ;;
    "SKR") do_lpc_config ;;
    "Duet") do_duet_config ;;
    "Einsy") do_avr_config ;;
    "sBase") do_lpc_config ;;
    "F6") do_avr_config ;;
  esac
  
  scripts/kconfig/merge_config.sh $KLIPPER_CONFIG_FRAGMENT
  make clean
  make
  
  RET=$?
  if [ $RET -ne 0 ]; then
    whipstd --msgbox "Klipper build failed?!" 8 60
  fi
  
  sudo service klipper stop
}
  
install_api() {
  echo
  echo
  echo "###########################"
  echo "Configuring the Klipper API"
  echo "###########################"
  echo
  sleep .5
  cd /home/pi/klipper
  git remote add arksine https://github.com/Arksine/klipper.git
  git fetch arksine
  git checkout arksine/work-web_server-20200131
  cd /home/pi/klipper
  sudo service klipper stop
  git clean -x -d -n
  /home/pi/klipper/scripts/install-moonraker.sh
  echo "Creating Virtual SD"
  sleep .5
  mkdir /home/pi/sdcard
  sudo service klipper restart
}

test_api() {  
  echo
  echo
  echo "###################"
  echo "Testing API Service"
  echo "###################"
  echo
  sleep 5
  echo "The API response is:"
  API_RESPONSE="$(curl -sG4 http://localhost:7125/printer/info)"
  echo ${API_RESPONSE}
  echo
  echo
  
  if [ $(curl -sG4 "http://localhost:7125/printer/info" | grep '^{"result"' -c) = 1 ]; then
    echo "The Klipper API service is working correctly"
  else
    echo "The Klipper API service is not working correctly"
    ERROR=1
    KLIPPER_API_ERROR="The Klipper API was not configured correctly"
  fi
}

install_nginx() {  
  echo
  echo
  echo "###########################################"
  echo "Install Webserver and Reverse Proxy (Nginx)"
  echo "###########################################"
  echo
  sleep .5
  sudo apt install nginx -y
  sudo mv /home/pi/mainsail-installer/nginx.cfg /etc/nginx/sites-available/mainsail
  sudo chown pi:pi /etc/nginx/sites-available/mainsail
  sudo chmod 644 /etc/nginx/sites-available/mainsail
  echo "Creating directory for static files"
  sleep .5
  mkdir /home/pi/mainsail
  
  if [ -e "/etc/nginx/sites-enabled/default" ]; then
    sudo rm /etc/nginx/sites-enabled/default
  fi
  
  if [ ! -e "/etc/nginx/sites-enabled/mainsail" ]; then
    sudo ln -s /etc/nginx/sites-available/mainsail /etc/nginx/sites-enabled/
  fi
}

test_nginx() {  
  sudo service nginx restart
  echo
  echo
  echo "#####################"
  echo "Testing Nginx Service"
  echo "#####################"
  echo
  sleep 5
  echo "The API response is:"
  API_RESPONSE="$(curl -sG4 http://localhost/printer/info)"
  echo ${API_RESPONSE}
  echo
  echo
  
  if [ $(curl -sG4 "http://localhost:7125/printer/info" | grep '^{"result"' -c) = 1 ]; then
    echo "Nginx is configured correctly"
    sleep 2
  else
    echo "Nginx is not configured correctly"
    ERROR=1
    NGINX_ERROR="Nginx was not configured correctly"
    sleep 5
  fi
  echo
  echo
}

install_mainsail() {  
  echo
  echo
  echo "###################################"
  echo "Installing and Configuring Mainsail"
  echo "###################################"
  echo
  sleep .5
  cd /home/pi/mainsail
  wget -q -O mainsail.zip ${MAINSAIL_FILE} && unzip mainsail.zip && rm mainsail.zip
}

install_mjpg_streamer() {
  
  if [ $WEBCAM_SETUP_RESPONSE = "Y" ]; then
    echo
    echo
    echo "########################"
    echo "Installing mjpg-streamer"
    echo "########################"
    echo
    sleep .5
    sudo apt-get install build-essential imagemagick libv4l-dev libjpeg-dev cmake -y
    sudo apt update --fix-missing
    sudo apt-get install build-essential imagemagick libv4l-dev libjpeg-dev cmake -y
    cd /tmp
    git clone https://github.com/jacksonliam/mjpg-streamer.git
    cd mjpg-streamer/mjpg-streamer-experimental
    make
    sudo make install
    mv /home/pi/mainsail-installer/mjpg-streamer.sh /home/pi/mjpg-streamer.sh
    chmod +x /home/pi/mjpg-streamer.sh
    (crontab -l 2>/dev/null; echo "@reboot /home/pi/mjpg-streamer.sh start") | crontab -
    /home/pi/mjpg-streamer.sh start
    echo ${GUI_JSON} > /home/pi/sdcard/gui.json
  fi
}

set_hostname() {
  if [ $CHANGE_HOSTNAME_RESPONSE = "Y" ]; then
    echo
    echo
    echo "Setting hostname to $NEW_HOSTNAME"
    sudo sed -i -e 's/${CURRENT_HOSTNAME}/${HOSTNAME}/g' /etc/hostname
    sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    sudo hostnamectl set-hostname $NEW_HOSTNAME
  fi
}

display_info_finish() {  
  if [ $ERROR = 0 ]; then
    echo
    echo
    echo "The installer did not detect any errors."
    echo "You should be able to access Mainsail in your browser at ${SYSTEM_IP}"
  else
    echo
    echo
    echo "The installer encountered the following errors during install"
    echo ${KLIPPER_API_ERROR}
    echo ${NGINX_ERROR}
  fi
  
  if [ $CHANGE_HOSTNAME_RESPONSE = "Y" ]; then
    echo "You should reboot the system after changing the hostname."
    echo "System will reboot in 10 seconds."
    sleep 10
    sudo shutdown -r now
  fi
}

# Run the installation
verify_ready
ascii_art
clean_image_warning
get_inputs
verify_inputs
install_packages
install_printer_config
install_klipper
install_api
test_api
install_nginx
test_nginx
install_mainsail
install_mjpg_streamer
set_hostname
display_info_finish
