#!/bin/bash
WIRINGPI_DOWNLOAD_URL="https://github.com/WiringPi/WiringPi/releases/download/2.61-1/wiringpi-2.61-1-armhf.deb" # TODO: Make url @latest release instead of fixed version
FLASH_CC2531_DOWNLOAD_URL="https://github.com/jmichault/flash_cc2531.git"
CC2531_DEFAULT_20211115_DOWNLOAD_URL="https://github.com/Koenkk/Z-Stack-firmware/raw/Z-Stack_Home_1.2_20211115/20211116/coordinator/Z-Stack_Home_1.2/bin/default/CC2531_DEFAULT_20211115.zip"
wiringpi_installed_check=$(gpio -v)

#pinout print statement
echo "
 ██████╗ ██████╗██████╗ ███████╗██████╗  ██╗                        
██╔════╝██╔════╝╚════██╗██╔════╝╚════██╗███║                        
██║     ██║      █████╔╝███████╗ █████╔╝╚██║                        
██║     ██║     ██╔═══╝ ╚════██║ ╚═══██╗ ██║                        
╚██████╗╚██████╗███████╗███████║██████╔╝ ██║                        
 ╚═════╝ ╚═════╝╚══════╝╚══════╝╚═════╝  ╚═╝                        
                                                                    
███████╗██╗██████╗ ███╗   ███╗██╗    ██╗ █████╗ ██████╗ ███████╗    
██╔════╝██║██╔══██╗████╗ ████║██║    ██║██╔══██╗██╔══██╗██╔════╝    
█████╗  ██║██████╔╝██╔████╔██║██║ █╗ ██║███████║██████╔╝█████╗      
██╔══╝  ██║██╔══██╗██║╚██╔╝██║██║███╗██║██╔══██║██╔══██╗██╔══╝      
██║     ██║██║  ██║██║ ╚═╝ ██║╚███╔███╔╝██║  ██║██║  ██║███████╗    
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝    
                                                                    
███████╗██╗      █████╗ ███████╗██╗  ██╗███████╗██████╗             
██╔════╝██║     ██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗            
█████╗  ██║     ███████║███████╗███████║█████╗  ██████╔╝            
██╔══╝  ██║     ██╔══██║╚════██║██╔══██║██╔══╝  ██╔══██╗            
██║     ███████╗██║  ██║███████║██║  ██║███████╗██║  ██║            
╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝                                  
..for Raspberry Pi - v1 | 11-11-2023

=======================| Connections |=========================
pin 1 (GND)   --> pin 39 (GND)
pin 3 (DC)    --> pin 36 (GPIO27, BCM16)
pin 4 (DD)    --> pin 38 (GPIO28, BCM20)
pin 7 (reset) --> pin 35 (GPIO24, BCM19)

========================| Resources |==========================
https://www.zigbee2mqtt.io/guide/adapters/flashing/alternative_flashing_methods.html
https://github.com/jmichault/flash_cc2531
https://github.com/WiringPi/WiringPi/releases
"

check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "\n[info] Please run as root."
    exit
  fi
}

install_wiringpi() {
  if [[ -z $wiringpi_installed_check ]]; then
    echo "[info] Wiringpi not installed, installing now."
    check_root
    wget $WIRINGPI_DOWNLOAD_URL -O /tmp/wiringpi.deb
    dpkg -i /tmp/wiringpi.deb
  else
    echo "[info] Wiringpi install found, moving on."
  fi
}

get_flash_cc531() {
  cd /tmp
  git clone $FLASH_CC2531_DOWNLOAD_URL
  cd /tmp/flash_cc2531
  chipid_output=$(./cc_chipid)
  wget $CC2531_DEFAULT_20211115_DOWNLOAD_URL
  unzip CC2531_DEFAULT_20211115.zip
  echo $chipid_output
}

run_flash_sequence() {
  echo "[info] Erasing.."
  ././cc_erase
  echo -e "[info] Flashing.. \n..this can take up to 5 minutes"
  ./cc_write CC2531ZNP-Prod.hex
  ## TODO: Check if last line of ./cc_write contains  "flash OK."" for verification
}

cleanup() {
  rm -r /tmp/flash_cc2531 /tmp/wiringpi.deb
}

#============================== main =====================================
install_wiringpi
get_flash_cc531

if [[ "$chipid_output" != *"ffff"* && "$chipid_output" != *"0000"* ]]; then
  echo "Assuming chipid is valid because it does not contain ffff or 0000."
  echo -e "\n[input] Start flashing? (Y/N)?"
  read confirm_flash

  if [[ "$confirm_flash" == "Y" || "$confirm_flash" == "y" ]]; then
    echo -e "\n\n[info] Erasing.."
    run_flash_sequence
  else
    echo -e "\n[error] Aborting."
    cleanup
  fi

else
  echo "[error] chipid variable contains ffff or 0000, assuming the wiring is incorrect. Exiting."
  echo "More troubleshooting tips are here -> https://www.zigbee2mqtt.io/guide/adapters/flashing/alternative_flashing_methods.html"
  cleanup
  exit 1
fi

cleanup
