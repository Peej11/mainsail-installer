#!/bin/bash
COL_LIGHT_RED='\e[1;31m'
COL_NC='\e[0m'

echo -e "
${COL_LIGHT_RED}
                                 ##                                
                              ########                                
                           ##############                                
                        ####################                                
                     ##########################             ${COL_NC}   ██╗  ██╗██╗     ██╗██████╗ ██████╗ ███████╗██████╗     ${COL_LIGHT_RED}
                  ################################          ${COL_NC}   ██║ ██╔╝██║     ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗    ${COL_LIGHT_RED}   
               ######################################       ${COL_NC}   █████╔╝ ██║     ██║██████╔╝██████╔╝█████╗  ██████╔╝    ${COL_LIGHT_RED}         
            ############################################    ${COL_NC}   ██╔═██╗ ██║     ██║██╔═══╝ ██╔═══╝ ██╔══╝  ██╔══██╗    ${COL_LIGHT_RED}         
         ####################      ########      ########## ${COL_NC}   ██║  ██╗███████╗██║██║     ██║     ███████╗██║  ██║    ${COL_LIGHT_RED}            
         ##################      ########      ############ ${COL_NC}   ╚═╝  ╚═╝╚══════╝╚═╝╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝    ${COL_LIGHT_RED}
         ################      ########      ##############          
         ##############      ########      ################ ${COL_NC}   ███╗   ███╗ █████╗ ██╗███╗   ██╗███████╗ █████╗ ██╗██╗        ${COL_LIGHT_RED}
         ############      ########      ################## ${COL_NC}   ████╗ ████║██╔══██╗██║████╗  ██║██╔════╝██╔══██╗██║██║        ${COL_LIGHT_RED}
         ##########      ########      #################### ${COL_NC}   ██╔████╔██║███████║██║██╔██╗ ██║███████╗███████║██║██║        ${COL_LIGHT_RED}   
         ######################      ###################### ${COL_NC}   ██║╚██╔╝██║██╔══██║██║██║╚██╗██║╚════██║██╔══██║██║██║        ${COL_LIGHT_RED}
         ####################      ########      ########## ${COL_NC}   ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║███████║██║  ██║██║███████╗   ${COL_LIGHT_RED}
         ##################      ########      ############ ${COL_NC}   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝   ${COL_LIGHT_RED}
         ################      ########      ##############          
         ##############      ########      ################ ${COL_NC}   ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗    ${COL_LIGHT_RED}
         ############      ########      ################## ${COL_NC}   ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗   ${COL_LIGHT_RED}
         ##########      ########      #################### ${COL_NC}   ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝   ${COL_LIGHT_RED}
            ############################################    ${COL_NC}   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗   ${COL_LIGHT_RED}   
               ######################################       ${COL_NC}   ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║   ${COL_LIGHT_RED}
                  ################################          ${COL_NC}   ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝   ${COL_LIGHT_RED}
                     ##########################                               
                        ####################                               
                           ##############                                
                              ########                                
                                 ##
${COL_NC}
"

sleep 1

echo "This installer is intended to run on a new Raspbian image. Do you wish to continue? (Y/n)"
read var_continue

if [ "$var_continue" == "N" ] | [ "$var_continue" == "n" ]; then
  
  exit 0

elif [ "$var_continue" == "Y" ] | [ "$var_continue" == "y" ]; then
  
  cd /home/pi
  
  echo "Running apt update and apt upgrade"
  sleep .5
  sudo apt update -y
  sudo apt upgrade -y

  echo "Installing git"
  sleep .5
  sudo apt install git -y

  echo "Installing Klipper"
  sleep .5
  git clone https://github.com/KevinOConnor/klipper
  ./klipper/scripts/install-octopi.sh
  
  echo "Building and Flashing the MCU"
  cd /home/pi/klipper
  make menuconfig
  make
  
  echo "Changing branch for the Klipper-API"
  sleep .5
  cd /home/pi/klipper
  git remote add arksine https://github.com/Arksine/klipper.git
  git fetch arksine
  git checkout arksine/work-web_server-20200131
  /home/pi/klippy-env/bin/pip install tornado
  
  echo "Checking for printer.cfg"
  sleep .5
  if [ -e "/home/pi/printer.cfg" ]; then  
	echo "Printer.cfg exists. Copying contents to file."
  sleep .5
	## READ THE CONTENTS OF EMPTY_PRINTER.CFG INTO PRINTER.CFG ##
  else
    echo "Printer.cfg does not exist. Copying sample file for Mainsail to use."
  sleep .5
	cp /home/pi/mainsail-installer/empty_printer.cfg /home/pi/printer.cfg
	chown pi:pi /home/pi/printer.cfg
	chmod 644 /home/pi/printer.cfg
  fi
  
  echo "Creating Virtual SD."
  sleep .5
  mkdir /home/pi/sdcard
  
  echo "Testing API Service."
  sleep .5
  ## QUERY THE API SERVICE FOR RESPONSE ##
  
  echo "Install Webserver and Reverse Proxy (Nginx)"
  sleep .5
  sudo apt install nginx -y
  sudo cp /home/pi/mainsail-installer/nginx.cfg /etc/nginx/sites-available/mainsail
  sudo chown pi:pi /etc/nginx/sites-available/mainsail
  sudo chmod 644 /etc/nginx/sites-available/mainsail
  
  if [ -e "/etc/nginx/sites-enabled/default" ]; then
    sudo rm /etc/nginx/sites-enabled/default
  fi
  
  sudo ln -s /etc/nginx/sites-available/mainsail /etc/nginx/sites-enabled/
  sudo service nginx restart
  
  echo "Creating directory for static files"
  sleep .5
  mkdir /home/pi/mainsail
  
  echo "Installing and Configuring Mainsail"
  sleep .5
  cd /home/pi/mainsail
  wget -q -O mainsail.zip https://github.com/meteyou/mainsail/releases/download/v0.0.9/mainsail-alpha-0.0.9.zip && unzip mainsail.zip && rm mainsail.zip
  
  SYS_IP = ip addr show wlan0 | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}'
    
  echo ""
  echo ""
  echo "You can now access Mainsail at: " & $SYS_IP
  echo ""
  echo ""
fi

