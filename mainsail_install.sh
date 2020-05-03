#!/bin/bash
# This will install Mainsail for Klipper on a clean Raspbian image

COL_RED='\e[0;31m'
COL_NONE='\e[0m'
ERROR=0
NGINX_ERROR=''
KLIPPER_API_ERROR=''
SYSTEM_IP="$(ip route get 1.1.1.1 | awk '{print $7}' | head -n1)"
MAINSAIL_FILE="https://github.com/meteyou/mainsail/releases/download/v0.0.9/mainsail-alpha-0.0.9.zip"
GUI_JSON="{\"webcam\":{\"url\":\"http://${SYSTEM_IP}:8081/?action=stream\"},\"gui\":{\"dashboard\":{\"boolWebcam\":true,\"boolTempchart\":true,\"boolConsole\":false,\"hiddenMacros\":[]},\"webcam\":{\"bool\":false},\"gcodefiles\":{\"countPerPage\":10}}}"
WEBCAM_SETUP="Y"
CHANGE_HOSTNAME=""
CURRENT_HOSTNAME="$(hostname)"
NEW_HOSTNAME=""


verify_ready()
{
  if [ "$EUID" -eq 0 ]; then
    echo "This script must not run as root"
    exit -1
  fi
}

ascii_art()
{
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
}

clean_image_warning()
{
  echo "This installer is intended to run on a clean Raspbian image." 
  echo "Do you want to continue? (Y/n)"
  read CONTINUE_INSTALL
  
  while [[ $CONTINUE_INSTALL != "Y" ]] && [[ $CONTINUE_INSTALL != "y" ]] && [[ $CONTINUE_INSTALL != "N" ]] && [[ $CONTINUE_INSTALL != "n" ]]
  do
    echo "Do you want to continue? (Y/n)"
    read CONTINUE_INSTALL
  done
  
  if [[ $CONTINUE_INSTALL == "N" ]] || [[ $CONTINUE_INSTALL == "n" ]]; then
    exit 0
  fi
}

get_inputs()
{
  echo
  echo
  echo "Please provide your IP address. This will be used to allow access" 
  echo "to the Web UI. You can provide an address using CIDR notation to whitelist"
  echo "an entire subnet. If you want to whitelist a specific client provide just" 
  echo "that client's IP address. (example CIDR notation - 192.168.0.0/24)"
  read IP_ADDRESS
  
  echo
  echo
  echo "Do you want to setup mjpeg-streamer to use a webcam? (Y/n)"
  read WEBCAM_SETUP
  
  while [[ $WEBCAM_SETUP != "Y" ]] && [[ $WEBCAM_SETUP != "y" ]] && [[ $WEBCAM_SETUP != "N" ]] && [[ $WEBCAM_SETUP != "n" ]]
  do
    echo "Do you want to setup mjpeg-streamer? (Y/n)"
    read WEBCAM_SETUP
  done
  
  if [[ $WEBCAM_SETUP = "Y" ]] || [[ $WEBCAM_SETUP = "y" ]]; then
    echo
    echo
    echo "IMPORTANT"
	echo "You must have your webcam connected or the mjpeg-streamer service won't start."
	sleep 3
  fi
  
  echo
  echo
  echo "Do you want to change the system hostname? (Y/n)"
  read CHANGE_HOSTNAME
  while [[ $CHANGE_HOSTNAME != "Y" ]] && [[ $CHANGE_HOSTNAME != "y" ]] && [[ $CHANGE_HOSTNAME != "N" ]] && [[ $CHANGE_HOSTNAME != "n" ]]
  do
    echo "Do you want to change hostname? (Y/n)"
    read CHANGE_HOSTNAME
  done
  
  if [[ $CHANGE_HOSTNAME == "Y" ]] || [[ $CHANGE_HOSTNAME == "y" ]]; then
    echo "Please provide a new hostname for the system."
	read NEW_HOSTNAME
  fi
  
  echo
  echo
  echo "IMPORTANT NOTES"
  echo "This installer will take several minutes to complete."
  echo "User input is required during the primary Klipper install but is otherwise completely automated." 
  echo "You should be able to access Mainsail in your browser at ${SYSTEM_IP} after the install completes."
  sleep 5
}

install_packages()
{  
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
  echo "##############"
  echo "Installing git"
  echo "##############"
  echo
  sleep .5
  sudo apt install git -y
}

install_printer_config()
{  
  echo
  echo
  echo "########################"
  echo "Checking for printer.cfg"
  echo "########################"
  echo
  sleep .5
  if [ -e "/home/pi/printer.cfg" ]; then  
	echo "Printer.cfg exists"
    echo "Copying contents to file"
    sleep .5
	
	if [[ $(cat /home/pi/printer.cfg | grep \\[virtual_sdcard]) == '[virtual_sdcard]' ]]; then
	  echo "Virtual SDcard is already configured"
    else
	  echo "Virtual SDcard is not configured in printer.cfg"
	  echo "Configuring Virtual SDcard"
	  echo $'\n\n[virtual_sdcard]' >> /home/pi/printer.cfg
	  echo "path: /home/pi/sdcard" >> /home/pi/printer.cfg
	fi
	
	if [[ $(cat /home/pi/printer.cfg | grep \\[remote_api]) == '[remote_api]' ]]; then
	  echo "Remote API is already configured"
    else
	  echo "Remote API is not configured in printer.cfg"
	  echo "Configuring Remote API"
	  echo $'\n\n[remote_api]' >> /home/pi/printer.cfg
	  echo "trusted_clients:" >> /home/pi/printer.cfg
	  echo " $IP_ADDRESS" >> /home/pi/printer.cfg
	  echo " 127.0.0.0/24" >> /home/pi/printer.cfg
	fi
	
  else
    echo "Printer.cfg does not exist"
	echo "Copying sample file for Mainsail to use."
    sleep .5
	cp /home/pi/mainsail-installer/empty_printer.cfg /home/pi/printer.cfg
	chown pi:pi /home/pi/printer.cfg
	chmod 644 /home/pi/printer.cfg
  fi
}

install_klipper()
{
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
  cd /home/pi/klipper
  make menuconfig
  make
  sudo service klipper stop
}
  
install_api()
{
  echo
  echo
  echo "###########################"
  echo "Configuring the Klipper-API"
  echo "###########################"
  echo
  sleep .5
  cd /home/pi/klipper
  git remote add arksine https://github.com/Arksine/klipper.git
  git fetch arksine
  git checkout arksine/work-web_server-20200131
  /home/pi/klippy-env/bin/pip install tornado
  
  echo "Creating Virtual SD"
  sleep .5
  mkdir /home/pi/sdcard
  sudo service klipper restart
}

test_api()
{  
  echo
  echo
  echo "###################"
  echo "Testing API Service"
  echo "###################"
  echo
  sleep 5
  echo "The API response is:"
  strTEST="$(curl -sG4 http://localhost:7125/printer/info)"
  echo ${strTEST}
  echo
  echo
  
  if [[ ${strTEST:0:10} == "{\"result\":" ]]; then
    echo "The Klipper API service is working correctly"
  else
    echo "The Klipper API service is not working correctly"
	ERROR=1
	KLIPPER_API_ERROR="The Klipper API was not configured correctly"
  fi
}

install_nginx()
{  
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

test_nginx()
{  
  sudo service nginx restart
  echo
  echo
  echo "#####################"
  echo "Testing Nginx Service"
  echo "#####################"
  echo
  sleep 5
  echo "The API response is:"
  strTEST="$(curl -sG4 http://localhost/printer/info)"
  echo ${strTEST}
  echo
  echo
  
  if [[ ${strTEST:0:10} == "{\"result\":" ]]; then
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

install_mainsail()
{  
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

setup_webcam()
{
  
  if [[ $WEBCAM_SETUP == "Y" ]] || [[ $WEBCAM_SETUP == "y" ]]; then
    echo
    echo
	echo "#########################"
	echo "Installing mjpeg-streamer"
	echo "#########################"
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

set_hostname()
{
  if [[ $CHANGE_HOSTNAME == "Y" ]] || [[ $CHANGE_HOSTNAME == "y" ]]; then
    echo
    echo
    echo "Setting hostname to $NEW_HOSTNAME"
	sudo echo $NEW_HOSTNAME > /etc/hostname
	sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
	sudo hostnamectl set-hostname $NEW_HOSTNAME
  fi
}

display_info_finish()
{  
  if [[ $ERROR == 0 ]]; then
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
  
  if [[ $CHANGE_HOSTNAME == "Y" ]] || [[ $CHANGE_HOSTNAME == "y" ]]; then
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
install_packages
install_printer_config
install_klipper
install_api
test_api
install_nginx
test_nginx
install_mainsail
setup_webcam
set_hostname
display_info_finish