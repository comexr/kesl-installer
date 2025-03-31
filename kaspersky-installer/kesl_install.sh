#!/bin/bash
#Script to easily install Kaspersky and set the right parameters automatically.
#
#Argument options
#Stable = Publically available version (kesl_11.4)
#Testing = Highest available version numer (kesl_11.4)
#Variables:
#$selected_version="stable/testing"
#
#By running the script, it automatically accepts the EULA and other agreements
#Notify the user.

prefix=./kaspersky-installer
download_loc=/tmp
selected_version="stable"
skip_prompts=0
skip_license=0

#Catch for no option
if [[ $# -eq 0 ]]; then
    echo "This script is used to automate the process of installing"
    echo "and configuring Kaspersky Endpoint Security for Linux"
    echo " "
    echo "./kesl_installer.sh [options]"
    echo " "
    echo "options:"
    echo "-h, --help                show this help message"
    echo "-s, --stable              install the stable version of Kaspersky"
    echo "-t, --testing             install the unreleased testing version of Kaspersky"
    echo "-y, --assume-yes          Don't prompt the user for extra input, assume defaults"
    echo "-i, --install		    Assume defaults, only ask for license key"
    echo ""
    echo "When no flags are passed, this help message will be displayed"
    exit 0
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "This script is used to automate the process of installing"
      echo "and configuring Kaspersky Endpoint Security for Linux"
      echo " "
      echo "./kesl_installer.sh [options]"
      echo " "
      echo "options:"
      echo "-h, --help                show this help message"
      echo "-s, --stable              install the stable version of Kaspersky"
      echo "-t, --testing             install the unreleased testing version of Kaspersky"
      echo "-y, --assume-yes          Don't prompt the user for extra input, assume defaults"
      echo "-i, --install		    Assume defaults, only ask for license key"
      echo ""
      echo "When no flags are passed, this help message will be displayed"
      exit 0
      ;;
    -s|--stable)
      shift
      selected_version="stable"
      shift
      ;;
    -t|--testing)
      shift
      selected_version="testing"
      skip_prompts=1
      skip_license=1
      shift
      ;;
    -y|--assume-yes)
      shift
      skip_prompts=1
      skip_license=1
      shift
      ;;
    -i|--install)
      shift
      skip_prompts=1
      skip_license=0
      shift
      ;;
    *)
      break
      ;;
  esac
done

#Set bold and normal text modes
bold=$(tput bold)
normal=$(tput sgr0)

#Manjaro check
[[ $os_name == "manjaro" ]] && (echo -e "Kaspersky is not supported on Manjaro.\nScript will close now."; exit 1)

#Source os information
source /etc/os-release
os_name=$(echo $ID)

#Catch for debian, since new users don't have sudo rights required for this installer
if [[ $os_name == "debian" && $(whoami) != "root" ]]; then
    if ! sudo -v
    then
        echo -e "\nUser not in sudoers file..."
        echo "Please log in as root and re-run this script"
        exit 1
    fi
fi

#root check, needs to be user (not root)
if [[ $EUID == 0 && $os_name != "debian" ]]; then
	echo "Please run script as user!"
	exit 1
fi

#Force password prompt for further permissions
sudo -k
echo "Please enter your password:"
sudo -v &>/dev/null
[ $? -ne 0 ] && (echo "3 Failed attempts, please try again"; exit $?)

#Check if the setup file (doesn't) exist
! cat setup.txt &>/dev/null && (echo "Setup file not found, please make sure you copied the entire \"Kaspersky\" folder."; exit 1)

#reset setup.txt contents before trying to configure Kaspersky with broken settings.
echo -e "Clearing setup file"
sed -i "s/USE_KSN=.*/USE_KSN=/g" $prefix/setup.txt
sed -i "s/LOCALE=.*/LOCALE=/g" $prefix/setup.txt
sed -i "s/ADMIN_USER=.*/ADMIN_USER=/g" $prefix/setup.txt
sed -i "s/INSTALL_LICENSE=.*/INSTALL_LICENSE=/g" $prefix/setup.txt

#Test network connection
echo -e "Testing internet connection...";
if ! nc -zw1 google.com 443 &>/dev/null
then
  echo "Not connected to the Internet..."
  echo "An internet connection is required to install Kaspersky."
  echo "Exiting script"
  exit 1
else
    echo -e "Succes!";
fi

#License agreement prompts
if [[ $skip_prompts == 1 ]]; then 
	echo "Skipping EULA, privacy and KSN agreement checks"
	ksn_answer=1
else
    echo -e "Welcome to the Kaspersky autoinstall script, we will first ask you to accept the license agreements.\n"
    echo "${bold}EULA and Privacy Policy${normal}"
    echo "Please confirm that you have fully read, understand, and accept the End User License Agreement (EULA) and Privacy Policy to continue."
    echo -e "\nNOTE: To quit the EULA and Privacy Policy viewer, press the Q key.\n"
    read -t 20 -n 1 -s -r -p "Press ENTER to display the EULA and Privacy Policy:"
    less $prefix/doc/license.en
    echo -e "\n Read EULA and Privacy Policy from file \"/opt/kaspersky/kesl/doc/license.en\" (utf-8) if it cannot be read here.\n"
    while true; do
        read -r -p "I confirm that I have fully read, understand, and accept the terms and conditions of this End User License Agreement [y/n]:" eula_answer
        case $eula_answer in
            y|Y|yes|Yes)
            break
            ;;
            n|N|no|No)
            echo "License not accepted"
            echo "Stopping script..."
            exit 0
            ;;
            *)
            echo "Invalid input, please try again"
            ;;
        esac
    done
    echo ""
    while true; do
        read -r -p "I am aware and agree that my data will be handled and transmitted (including to third countries) as described in the Privacy Policy. I confirm that I have fully read and understand the Privacy Policy [y/n]:" privacy_answer
        case $privacy_answer in
            y|Y|yes|Yes)
            break
            ;;
            n|N|no|No)
            echo "Privacy license not accepted"
            echo "Stopping script..."
            exit 0
            ;;
            *)
            echo "Invalid input, please try again"
            ;;
        esac
    done
    echo -e "\n${bold}Kaspersky Security Network Statement${normal}"
    echo -e "\nPlease make sure to read the KSN License before Accepting or Declining"
    echo -e "\nNOTE: Declining this License will NOT stop the installation"
    echo -e "NOTE: To quit the KSN License viewer, press the Q key.\n"
    read -t 20 -n 1 -s -r -p "Press ENTER to display the KSN statement"
    less $prefix/doc/ksn_license.en
    echo -e "\n\n"
    while true; do
        read -r -p "I confirm that I have fully read, understand, and accept the terms and conditions of the Kaspersky Security Network Statement [y/n]:" ksn_answer
        case $ksn_answer in
            y|Y|yes|Yes)
            ksn_answer=1
            break
            ;;
            n|N|no|No)
            echo "KSN license not accepted"
            ksn_answer=0
            break
            ;;
            *)
            echo "Invalid input, please try again"
            ;;
        esac
    done
fi

#Function to register the version numbers of the .deb/.rpm files
## REWRITE THIS, LOOKS LIKE A MESS
get_versions () {
    version_os=$1
    version_release=$2
    if [[ ${version_os} == "fedora" || ${version_os} == "opensuse"* ]]; then
        #If user selected --testing, query the Testing folder instead of the main folder
        if [[ ${version_release} == "testing" ]]; then
            for filename in $prefix/Testing/*; do
    	    if [[ $filename == *".rpm" ]]; then
		        if [[ $filename == "$download_loc/kesl-gui.rpm" ]]; then
			        package_kesl_gui=$filename
		        else
			        package_kesl=$filename
		        fi
            fi
            done;
        elif [[ ${version_release} == "stable" ]]; then
            for filename in $download_loc/*; do
    	    if [[ $filename == *".rpm" ]]; then
		        if [[ $filename == "$download_loc/kesl-gui.rpm" ]]; then
			        package_kesl_gui=$filename
		        else
			        package_kesl=$filename
		        fi
            fi
            done;
        fi
    else
        if [[ ${version_release} == "testing" ]]; then
            for filename in $prefix/Testing/*; do
	        if [[ $filename == *".deb" ]]; then
		        if [[ $filename == "$download_loc/kesl.deb" ]]; then
			        package_kesl=$filename
		        elif [[ $filename == "$download_loc/kesl-gui.deb" ]]; then
			        package_kesl_gui=$filename
		        fi
	        fi
            done;
        elif [[ ${version_release} == "stable" ]]; then
            for filename in $download_loc/*; do
	        if [[ $filename == *".deb" ]]; then
		        if [[ $filename == "$download_loc/kesl.deb" ]]; then
			        package_kesl=$filename
		        elif [[ $filename == "$download_loc/kesl-gui.deb" ]]; then
			        package_kesl_gui=$filename
		        fi
	        fi
            done;
        fi
    fi
}

#######################################################################################################################################################################################################
#Fedora NOG TESTEN!!
if [[ $os_name == "fedora" ]]
then
    #Check user flags for the --testing flag
    #If selected, query the Testing folder
    if [[ ${selected_version} == "testing" ]]; then get_versions $os_name $selected_version
    else
        #Check if files already present in folder
        cat $download_loc/kesl*.rpm &>/dev/null
        if [[ $? -ne 0 ]]; then
            #Download files from Kaspersky site
            wget -O $download_loc/kesl.rpm https://products.s.kaspersky-labs.com/endpoints/keslinux10/12.2.0.2412/multilanguage-12.2.0.2412/3935323830307c44454c7c31/kesl-12.2.0-2412.x86_64.rpm && echo "Downloaded kesl" || (echo "Something went wrong, please try again"; exit 1)
            wget -O $download_loc/kesl-gui.rpm https://products.s.kaspersky-labs.com/endpoints/keslinux10/12.2.0.2412/multilanguage-12.2.0.2412/3935323830367c44454c7c31/kesl-gui-12.2.0-2412.x86_64.rpm && echo "Downloaded kesl-gui" || (echo "Something went wrong, please try again"; exit 1)
        else
            echo "Packages already downloaded, skipping"
        fi
        get_versions $os_name $selected_version
    fi
    #Catch to see if the version variables are not empty
	[[ ! $package_kesl_gui || ! $package_kesl ]] && (echo "Can't find .rpm files, make sure you're connected to the internet."; exit 1)
	#Check if packages installed already
	if [[ $selected_version != "testing" && $(dnf list installed | grep kesl) ]]; then echo "Kaspersky already installed, skipping installation"
	else
	#Install packages
        echo -e "Updating database"
        sudo dnf check-update -y &>/dev/null
		echo -e "\n${bold}Installing packages: ${normal}"
		echo -e "	$package_kesl"
		echo -e "	$package_kesl_gui\n"
		echo "If any of these values are wrong, please Press Ctrl+C to cancel this operation"
		[[ $skip_prompts ]] && echo "Check skipped" || read -t 20 -n 1 -s -r -p "Or press any key to continue"; echo ""
		echo "Installing Kaspersky packages..."
		sudo dnf localinstall $package_kesl $package_kesl_gui -y &> /dev/null && (echo "Successfully installed Kaspersky"; exit 0) || (c=$?; echo "Something went wrong, please try again"; (exit $c))
	fi
	echo "Installing perl for autoconfig and samba for file interceptor..."
	sudo dnf install perl samba -y &> /dev/null && (echo "Successfully installed Perl"; exit 0) || (c=$?; echo "Something went wrong, please try again"; (exit $c))
#######################################################################################################################################################################################################
#openSUSE
elif [[ $os_name == "opensuse-"* ]]
then
    if [[ ${selected_version} == "testing" ]]; then get_versions $os_name $selected_version
    else
        cat $download_loc/kesl*.rpm &>/dev/null
        if [[ $? -ne 0 ]]; then
            #Download files from Kaspersky site
            wget -O $download_loc/kesl.rpm https://products.s.kaspersky-labs.com/endpoints/keslinux10/12.2.0.2412/multilanguage-12.2.0.2412/3935323830307c44454c7c31/kesl-12.2.0-2412.x86_64.rpm && echo "Downloaded kesl" || (echo "Something went wrong, please try again"; exit 1)
            wget -O $download_loc/kesl-gui.rpm https://products.s.kaspersky-labs.com/endpoints/keslinux10/12.2.0.2412/multilanguage-12.2.0.2412/3935323830367c44454c7c31/kesl-gui-12.2.0-2412.x86_64.rpm && echo "Downloaded kesl-gui" || (echo "Something went wrong, please try again"; exit 1)
        else
            echo "Packages already downloaded, skipping"
        fi
        get_versions $os_name $selected_version
    fi
	[[ ! $package_kesl_gui || ! $package_kesl ]] && (echo "Can't find .rpm files, make sure you're connected to the internet."; exit 1)
	#Check if packages installed already
	zypper se -i kesl &>/dev/null
	if [[ $? -eq 0 && $selected_version != "testing" ]]; then echo "Kaspersky already installed, skipping installation"
	else
	#Install packages
        echo -e "Updating database"
        sudo zypper -n refresh &>/dev/null
		echo -e "\n${bold}Installing packages: ${normal}"
		echo -e "	$package_kesl"
		echo -e "	$package_kesl_gui\n"
		echo "If any of these values are wrong, please Press Ctrl+C to cancel this operation"
		[[ $skip_prompts ]] && echo "Check skipped" || read -t 20 -n 1 -s -r -p "Or press any key to continue"; echo ""
		echo "Installing Kaspersky packages..."
		sudo zypper -n --no-gpg-checks install $package_kesl $package_kesl_gui &> /dev/null && (echo "Successfully installed Kaspersky"; exit 0) || (c=$?; echo "Something went wrong, please try again"; (exit $c))
	fi
	echo "Installing perl for autoconfig..."
	sudo zypper -n install perl &> /dev/null && (echo "Successfully installed Perl"; exit 0) || (c=$?; echo "Something went wrong, please try again"; (exit $c))
#######################################################################################################################################################################################################
#Debian/Ubuntu
else
	#Automatic fix for broken sources.list file on debian
	if [[ $os_name == "debian" ]]; then cp sources.list /etc/apt/sources.list && (echo "Successfully copied sources.list"; exit 0) || (echo "Couldn't copy files, skipping"; exit 1); fi
    
    #Get files from folder "Testing"
    if [[ ${selected_version} == "testing" ]]; then get_versions $os_name $selected_version
    #Download files from Kaspersky site
    else
        cat $download_loc/kesl*.deb &>/dev/null
        if [[ $? -ne 0 ]]; then
            wget -O $download_loc/kesl.deb https://products.s.kaspersky-labs.com/endpoints/keslinux10/12.1.0.1297/multilanguage-12.1.0.1297/3837323739337c44454c7c31/kesl_12.1.0-1297_amd64.deb && echo "Downloaded kesl_amd64.deb" || (echo "Something went wrong, please try again"; exit 1)
            wget -O $download_loc/kesl-gui.deb https://products.s.kaspersky-labs.com/endpoints/keslinux10/12.1.0.1297/multilanguage-12.1.0.1297/3837323739397c44454c7c31/kesl-gui_12.1.0-1297_amd64.deb || (echo "Something went wrong, please try again"; exit 1)
        else
            echo "Packages already downloaded, skipping"
        fi
        get_versions $os_name $selected_version
    fi
	if [[ ! $package_kesl_gui || ! $package_kesl ]]; then echo "Can't find .deb files, make sure you are connected to the internet"; exit 1; fi
	#Check if packages installed already
    echo "Updating package list"
	sudo apt update &>/dev/null
	if [[ $selected_version != "testing" && $(apt list --installed | grep kesl) ]] &>/dev/null; then echo "Kaspersky already installed, skipping installation"
	else 
		#Install packages
		echo -e "\n${bold}Installing packages: ${normal}"
		echo -e "	$package_kesl"
		echo -e "	$package_kesl_gui\n"
		echo "If any of these values are wrong, please Press Ctrl+C to cancel this operation"
		[[ $skip_prompts ]] && echo "Check skipped" || read -t 20 -n 1 -s -r -p "Or press any key to continue"; echo ""
		echo "Installing Kaspersky packages..."
		sudo apt install $package_kesl $package_kesl_gui samba -y && (echo "Successfully installed Kaspersky"; exit 0) || (c=$?; echo "Something went wrong, please try again"; (exit $c))
    fi
	echo "Installing perl for autoconfig..."
	sudo apt install perl -y &> /dev/null && (echo "Successfully installed Perl"; exit 0) || (c=$?; echo "Something went wrong, please try again"; (exit $c))
fi
#######################################################################################################################################################################################################

echo "Reconfiguring Kaspersky with default settings"

#Get system locale for setup file
setup_locale=$(echo $LANG)
echo -e "\n${bold}System locale found: $setup_locale ${normal}"
echo -e "	This is the locale in which Kaspersky is going to be installed\n"

#Get system Username for setup file
if [[ $os_name == "debian" ]]; then setup_user=$(who -u | awk '{print $1;}')
else setup_user=$(whoami); fi
echo "${bold}Current user found: $setup_user ${normal}"
echo -e "	This user is going to be registered as the Kaspersky admin\n"

#Check if user accepts values
if [[ $skip_prompts == 1 ]]; then echo "Checks skipped"
else
    echo "If any of these values are wrong, please Press Ctrl+C to cancel this operation"
    read -r -p "[Accept values/Change user/Exit script](a/c/e)" answer
    echo ""
    while [[ "${answer}" != @(a|c|e) ]]; do
	    echo "Wrong input, try again"
	    read -r -p "[Accept values/Change user/Exit script](a/c/e)" answer
	    echo ""
    done
    if [[ "${answer}" == "c" ]]; then
	    echo ""
	    read -r -p "Enter username manually: " username_manual
	    #check if user exists in system
	    awk -F: '{ print $1}' /etc/passwd | grep ${username_manual,,} &> /dev/null && echo "Registering \"${username_manual,,}\" as Kaspersky admin" && setup_user="${username_manual,,}" || echo "User \"${username_manual,,}\" not found, defaulting to current user"	
	    echo ""
	    elif [[ "${answer}" == "e" ]]; then echo "User teminated script, exiting"; exit 1
    fi
fi

#Ask for manual license key input
if [[ $skip_license == 1 ]]; then license=""; echo "License key skipped, continuing"
else
	echo "Please enter the Kaspersky license key here"
	echo "If you want to use Kaspersky with the trial key, please leave the field empty."
	echo -e "Enter the License key with the dashes included.\nInput is not case sensitive"
	read -r -p "License Key: " license
fi
#change values in setup.txt
echo "Modifying setup file"
[[ $ksn_answer == 1 ]] && sed -i "s/USE_KSN=/USE_KSN=yes/g" $prefix/setup.txt || sed -i "s/USE_KSN=/USE_KSN=no/g" $prefix/setup.txt
sed -i "s/LOCALE=/LOCALE=${setup_locale}/g" $prefix/setup.txt
sed -i "s/ADMIN_USER=/ADMIN_USER=${setup_user}/g" $prefix/setup.txt
sed -i "s/INSTALL_LICENSE=/INSTALL_LICENSE=${license,,}/g" $prefix/setup.txt

#Run install script with autoinstall config @setup.txt
echo "Running kaspersky autoinstall script..."
echo "This can take a while"
sudo /opt/kaspersky/kesl/bin/kesl-setup.pl --autoinstall=$prefix/setup.txt && (echo "Successfully configured Kaspersky"; exit 0) || (c=$?; echo "Something went wrong, please try again"; (exit $c))

#Elementary en Fedora doen niet aan tray icons
if [[ $os_name != "elementary" && $os_name != "fedora" ]]
then
	[ ! -d /home/$setup_user/.config/autostart ] && echo "Autostart directory not found, creating..."&& mkdir /home/$setup_user/.config/autostart  
	cat /etc/xdg/autostart/kaspersky-kesl.desktop &>/dev/null
	if [[ $? -ne 0 ]]; then echo "Desktop file not found, skipping autostart configuration"
	else
		#Fix tray icon
		echo -e "Modifying .desktop file..."
		if [[ $(echo $XDG_SESSION_DESKTOP) == "gnome" || $(echo $XDG_SESSION_DESKTOP) == "cinnamon" ]]; then 
            sudo sh -c 'sudo echo -e "X-GNOME-Autostart-Delay=5" >> /opt/kaspersky/kesl/resource/autostart.desktop' &>/dev/null
            sudo sh -c 'sudo echo -e "X-GNOME-Autostart-Enabled=true" >> /opt/kaspersky/kesl/resource/autostart.desktop' &>/dev/null
            echo "Modified GNOME .desktop file"
        elif [[ $(echo $XDG_SESSION_DESKTOP) == "xfce" ]]; then 
            sudo sh -c 'sudo echo -e "X-XFCE-Autostart-after=panel" >> /opt/kaspersky/kesl/resource/autostart.desktop' &>/dev/null
            echo "Modified XFCE .desktop file"
        elif [[ $(echo $XDG_SESSION_DESKTOP) == "mate" ]]; then 
            sudo sh -c 'sudo echo -e "X-Mate-autostart-after=panel" >> /opt/kaspersky/kesl/resource/autostart.desktop' &>/dev/null
            sudo sh -c 'sudo echo -e "X-Mate-autostart-enabled=true" >> /opt/kaspersky/kesl/resource/autostart.desktop' &>/dev/null
            sudo sh -c 'sudo echo -e "X-Mate-autostart-delay=5" >> /opt/kaspersky/kesl/resource/autostart.desktop' &>/dev/null
            echo "Modified MATE .desktop file"
        fi 
        #KDE doesn't need desktop file fixes
        cp /opt/kaspersky/kesl/resource/autostart.desktop /home/$setup_user/.config/autostart/kaspersky-kesl.desktop
	fi
fi

#reset setup.txt contents
echo "clearing setup file"
sed -i "s/USE_KSN=.*/USE_KSN=/g" $prefix/setup.txt
sed -i "s/LOCALE=${setup_locale}/LOCALE=/g" $prefix/setup.txt
sed -i "s/ADMIN_USER=${setup_user}/ADMIN_USER=/g" $prefix/setup.txt
sed -i "s/INSTALL_LICENSE=${license}/INSTALL_LICENSE=${license}/g" $prefix/setup.txt

#restart Kaspersky to fix issue 3
#Promt user if they want to apply the fix now, or want to restart the device.
echo "We can restart the services to use Kaspersky without rebooting"
echo "However rebooting is a cleaner way to finalize the installation"; echo ""
read -r -p "Do you want to reboot now? [y/N]" answer
sudo -v &> /dev/null || echo "Please enter your password"; sudo -v &> /dev/null
if [[ ${answer} =~ ^[Yy]$ ]]; then
	echo "Rebooting in: (Press Ctrl+C to cancel)"
	secs=7
	while [ $secs -gt 0 ]; do
   		echo -ne "$secs\033[0K\r"
   		sleep 1
   		: $((secs--))
	done
    sudo reboot
else
	echo "Attempting to restart systemd services..."
	sudo systemctl restart kesl-supervisor.service &>/dev/null
	if [ $? -ne 0 ]; then echo "Cannot restart supervisor service"
	else echo "Restarted: kesl-supervisor.service"; fi
	sudo systemctl restart kesl.service &>/dev/null
	if [ $? -ne 0 ]; then echo "Cannot restart kesl service"
	else echo "Restarted: kesl.service"; fi
fi

# update application
sudo kesl-control --update-application

echo -e "\nKaspersky Endpoint Security for Linux Installed!\n"
sleep 5
exit 0
