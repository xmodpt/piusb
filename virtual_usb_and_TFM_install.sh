#!/bin/bash
cat << "EOF"
 _____                 _                                _____  _____
|  __ \               | |                              |  __ \|_   _|
| |__) |__ _ ___ _ __ | |__   ___ _ __ _ __ _   _     | |__) | | |  
|  _  // _` / __| '_ \| '_ \ / _ \ '__| '__| | | |    |  ___/  | |  
| | \ \ (_| \__ \ |_) | |_) |  __/ |  | |  | |_| |    | |     _| |_ 
|_|  \_\__,_|___/ .__/|_.__/ \___|_|  |_|   \__, |    |_|    |_____|
                | |                          __/ |                   
                |_|                         |___/      
              
       Virtual USB Drive + File Manager              
               All-in-One Installer               

# Pi USB Drive Configuration Script
# This script configures a Raspberry Pi Zero W as a USB flash drive with selectable size
# and installs TinyFileManager for web-based file management





EOF

# Exit on error
set -e

# Must run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Try using sudo."
  exit 1
fi

echo "=====================================================
Raspberry Pi USB Flash Drive + TinyFileManager Installation
=====================================================
This tool will:
1. Configure your Pi to appear as a USB flash drive
2. Install TinyFileManager for web-based access to your files"
echo

echo "Would you like to:"
echo "1. Install USB drive configuration only"
echo "2. Install TinyFileManager only"
echo "3. Install both (recommended)"

read -p "Enter your choice (1-3): " INSTALL_CHOICE

# Default to installing both if invalid choice
if [[ "$INSTALL_CHOICE" != "1" && "$INSTALL_CHOICE" != "2" ]]; then
  INSTALL_CHOICE="3"
  echo "Installing both USB drive and TinyFileManager..."
elif [[ "$INSTALL_CHOICE" == "1" ]]; then
  echo "Installing USB drive configuration only..."
elif [[ "$INSTALL_CHOICE" == "2" ]]; then
  echo "Installing TinyFileManager only..."
fi

# Function to install USB drive configuration
install_usb_drive() {
  echo "=====================================================
Raspberry Pi USB Flash Drive Configuration Tool
=====================================================
This tool will configure your Pi to appear as a USB flash drive
when connected to a computer via USB."
  echo

  # Check for existing setup
  USB_FILE_PATH="/piusb.bin"
  EXISTING_SIZE="None"

  if [ -f "$USB_FILE_PATH" ]; then
    # Get current size in MB
    EXISTING_SIZE=$(du -m "$USB_FILE_PATH" | cut -f1)
    echo "DETECTED: Existing USB drive image ($EXISTING_SIZE MB)"
    
    read -p "Do you want to keep the existing setup? (y/n): " KEEP_EXISTING
    if [[ "$KEEP_EXISTING" == "y" || "$KEEP_EXISTING" == "Y" ]]; then
      echo "Keeping existing USB drive image."
      # Just ensure the modules are properly configured
      CONFIG_ONLY=true
    else
      echo "Will create a new USB drive image."
      CONFIG_ONLY=false
    fi
  else
    CONFIG_ONLY=false
  fi

  if [ "$CONFIG_ONLY" = false ]; then
    # Choose USB drive size
    echo
    echo "Please select the size for your USB drive:"
    echo "1. 4GB"
    echo "2. 8GB"
    echo "3. 16GB"
    echo "4. 32GB"
    echo "5. Custom size (specify in MB)"
    
    read -p "Enter selection (1-5): " SIZE_CHOICE
    
    case $SIZE_CHOICE in
      1) SIZE_MB=4096 ;;
      2) SIZE_MB=8192 ;;
      3) SIZE_MB=16384 ;;
      4) SIZE_MB=32768 ;;
      5) read -p "Enter custom size in MB: " SIZE_MB ;;
      *) echo "Invalid choice. Using 4GB as default."; SIZE_MB=4096 ;;
    esac
    
    echo "Selected size: $SIZE_MB MB"
    
    # Confirm before proceeding
    echo
    echo "WARNING: This will create a $SIZE_MB MB file on your Pi."
    echo "Make sure you have enough free space on your SD card."
    read -p "Continue? (y/n): " CONFIRM
    
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
      echo "Operation cancelled."
      exit 0
    fi
    
    # Check available space
    AVAILABLE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$AVAILABLE_SPACE" -lt "$SIZE_MB" ]; then
      echo "ERROR: Not enough space available on SD card."
      echo "Available: $AVAILABLE_SPACE MB, Required: $SIZE_MB MB"
      echo "Please free up space or choose a smaller size."
      exit 1
    fi
    
    # Create the USB image file
    echo
    echo "Creating USB image file ($SIZE_MB MB)..."
    echo "This may take some time depending on the size."
    
    # Remove existing file if present
    if [ -f "$USB_FILE_PATH" ]; then
      rm "$USB_FILE_PATH"
    fi
    
    # Create new file with dd
    dd if=/dev/zero of="$USB_FILE_PATH" bs=1M count="$SIZE_MB" status=progress
    
    # Format as FAT32
    echo "Formatting USB image as FAT32..."
    mkdosfs "$USB_FILE_PATH" -F 32
    
    echo "USB image file created successfully."
  fi

  # Configure USB gadget mode
  echo
  echo "Configuring USB gadget mode..."

  # Set up dtoverlay in config.txt
  CONFIG_PATH="/boot/firmware/config.txt"
  if [ ! -f "$CONFIG_PATH" ]; then
    CONFIG_PATH="/boot/config.txt"
  fi

  # Add dtoverlay=dwc2 under [all] section
#   if ! grep -q "dtoverlay=dwc2" "$CONFIG_PATH"; then
#     # Check if [all] section exists
#     if ! grep -q "\[all\]" "$CONFIG_PATH"; then
#       # Add [all] section at the end of the file
#       echo -e "\n[all]" >> "$CONFIG_PATH"
#     fi
    
#     # Append dtoverlay=dwc2 after [all] section
#     sed -i '/\[all\]/a dtoverlay=dwc2' "$CONFIG_PATH"
#     echo "Added dwc2 overlay to $CONFIG_PATH under [all] section"
#   fi

# echo -e "\ndtoverlay=dwc2" | sudo tee -a /boot/firmware/config.txt
# First make a backup
sudo cp "$CONFIG_PATH" "${CONFIG_PATH}.backup"

# Create a temporary file with the [all] section properly configured
sudo grep -v "\[all\]" "$CONFIG_PATH" > temp_config.txt
echo -e "[all]\ndtoverlay=dwc2" | sudo tee -a temp_config.txt
sudo mv temp_config.txt "$CONFIG_PATH"


  # Set up modules-load in cmdline.txt
  CMDLINE_PATH="/boot/firmware/cmdline.txt"
  if [ ! -f "$CMDLINE_PATH" ]; then
    CMDLINE_PATH="/boot/cmdline.txt"
  fi

  if ! grep -q "modules-load=dwc2,g_mass_storage" "$CMDLINE_PATH"; then
    sed -i 's/rootwait/rootwait modules-load=dwc2,g_mass_storage/' "$CMDLINE_PATH"
    echo "Added modules-load to $CMDLINE_PATH"
  fi

  # Create mount point and set up fstab
  MOUNT_POINT="/mnt/usb_share"
  mkdir -p "$MOUNT_POINT"

  # Make sure /piusb.bin is properly in /etc/fstab
  if grep -q "$USB_FILE_PATH" /etc/fstab; then
    # Remove the existing entry to update it
    sed -i "\|$USB_FILE_PATH|d" /etc/fstab
  fi

  # Add the updated entry to fstab (no 'noauto' flag)
  echo "$USB_FILE_PATH $MOUNT_POINT vfat users,umask=000 0 0" >> /etc/fstab
  echo "Updated $USB_FILE_PATH in fstab"

  # Create systemd service for mounting the USB drive
  echo "Creating systemd service for auto-mounting..."

  cat > /etc/systemd/system/piusb-mount.service << EOF
[Unit]
Description=Mount Pi USB Drive Image
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/mount $MOUNT_POINT
RemainAfterExit=yes
ExecStop=/bin/umount $MOUNT_POINT

[Install]
WantedBy=multi-user.target
EOF

  # Reload systemd, enable and start the service
  systemctl daemon-reload
  systemctl enable piusb-mount.service
  systemctl start piusb-mount.service
  echo "Created and enabled piusb-mount.service"

  # Try to mount the USB image
  echo "Mounting USB image to $MOUNT_POINT..."
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Already mounted."
  else
    if ! mount "$MOUNT_POINT"; then
      echo "Warning: Failed to mount directly, trying with explicit options..."
      if ! mount -t vfat -o loop,rw "$USB_FILE_PATH" "$MOUNT_POINT"; then
        echo "Could not mount the USB image file. Will continue setup anyway."
      fi
    fi
  fi

  # Add a README file
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Creating a README.txt file on the USB drive..."
    cat > "$MOUNT_POINT/README.txt" << EOF
This is a Raspberry Pi Zero W configured as a USB drive.
Created on $(date)
EOF
  fi

  # Configure Samba share
  echo "Setting up Samba share for network access..."
  if ! dpkg -l | grep -q "samba"; then
    apt-get update
    apt-get install -y samba samba-common-bin
  fi

  # Backup original config if it exists and we haven't done so
  if [ -f "/etc/samba/smb.conf" ] && [ ! -f "/etc/samba/smb.conf.backup" ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    echo "Original Samba config backed up to /etc/samba/smb.conf.backup"
  fi

  # Check if USB share already exists in Samba config
  if ! grep -q "\[usb\]" /etc/samba/smb.conf; then
    cat >> /etc/samba/smb.conf << EOF

[usb]
   comment = USB Flash Drive
   path = $MOUNT_POINT
   browseable = yes
   writeable = yes
   only guest = no
   create mask = 0777
   directory mask = 0777
   public = yes
   guest ok = yes
EOF
    echo "Added USB share to Samba config"
  fi

  # Configure global section for guest access if not already done
  if ! grep -q "map to guest = bad user" /etc/samba/smb.conf; then
    sed -i '/\[global\]/a \   map to guest = bad user\n   guest account = pi\n   usershare allow guests = yes' /etc/samba/smb.conf
    echo "Configured Samba for guest access"
  fi

  # Restart Samba
  systemctl restart smbd
  systemctl restart nmbd

  # Configure USB mass storage module with specific USB identifiers
  echo "Setting up USB mass storage module..."
  if grep -q "g_mass_storage" /etc/modules; then
    sed -i '/g_mass_storage/d' /etc/modules
  fi

  # Add new configuration with USB drive identifiers
  echo "g_mass_storage file=$USB_FILE_PATH stall=0 ro=0 removable=1 idVendor=0x0951 idProduct=0x1666 iManufacturer=Kingston iProduct=DataTraveler iSerialNumber=74A53CDF" >> /etc/modules
  echo "Configured USB mass storage module"

  # Create test script for manual loading
  cat > /home/pi/test_usb_gadget.sh << EOF
#!/bin/bash
# This script manually loads the USB gadget module

# Unload existing modules
sudo modprobe -r g_mass_storage
sudo modprobe -r dwc2

# Load modules in correct order
sudo modprobe dwc2
sudo modprobe g_mass_storage file=$USB_FILE_PATH stall=0 ro=0 removable=1 idVendor=0x0951 idProduct=0x1666 iManufacturer=Kingston iProduct=DataTraveler iSerialNumber=74A53CDF


echo "USB gadget should now be active"
echo "Check your computer for a new USB drive"
EOF
  chmod +x /home/pi/test_usb_gadget.sh

  # Create a simple README for the user
  cat > /home/pi/README_USB_DRIVE.txt << EOF
Raspberry Pi USB Drive Configuration
===================================

Your Raspberry Pi has been configured as a USB flash drive.

- USB Image File: $USB_FILE_PATH
- Size: $(du -h "$USB_FILE_PATH" | cut -f1)
- Mount Point: $MOUNT_POINT
- Samba Share: \\\\$(hostname)\\usb

Usage Instructions:
------------------
1. Connect your Pi to a computer via the USB port (not the PWR port)
2. Your Pi should appear as a USB drive on the computer
3. You can also access the drive over your network via Samba

Troubleshooting:
---------------
If the USB drive is not detected after reboot, try:
  sudo /home/pi/test_usb_gadget.sh

To check systemd service status:
  sudo systemctl status piusb-mount.service

To manually start the systemd service:
  sudo systemctl start piusb-mount.service

For changes to take effect completely, please reboot your Pi:
  sudo reboot
EOF

  echo
  echo "=====================================================
USB Drive Setup complete!
=====================================================
Your Raspberry Pi has been configured as a USB flash drive.
- Size: $(if [ -f "$USB_FILE_PATH" ]; then du -h "$USB_FILE_PATH" | cut -f1; else echo "Unknown"; fi)
- It will be accessible as a USB drive when connected to a computer
- It is also shared on your network via Samba as: \\\\$(hostname)\\usb
- A README file has been created at: /home/pi/README_USB_DRIVE.txt

Configuration changes made:
- Added dtoverlay=dwc2 under [all] section in $CONFIG_PATH
- Added /piusb.bin to /etc/fstab with proper mounting options
- Created and enabled systemd service for automatic mounting
- Systemd configuration has been reloaded and mount attempted"
}

# Function to install TinyFileManager
install_tiny_file_manager() {
  cat << "EOF"
 _____  _              _____ _ _      __  __                                   
|_   _|(_)            |  ___(_) |    |  \/  |                                  
  | |   _  _ __  _   _| |_   _| | ___|  \\/  | __ _ _ __   __ _  __ _  ___ _ __ 
  | |  | || '_ \| | | |  _| | | |/ _ \ |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|
  | |  | || | | | |_| | |   | | |  __/ |  | | (_| | | | | (_| | (_| |  __/ |   
  \_/  |_||_| |_|\__, \_|   |_|_|\___\_|  |_/\__,_|_| |_|\__,_|\__, |\___|_|   
                  __/ |                                          __/ |          
                 |___/                                          |___/           
                                 _____           _        _ _                 
                                |_   _|         | |      | | |                
                                  | |  _ __  ___| |_ __ _| | | ___ _ __      
                                  | | | '_ \/ __| __/ _` | | |/ _ \ '__|     
                                 _| |_| | | \__ \ || (_| | | |  __/ |        
                                 \___/|_| |_|___/\__\__,_|_|_|\___|_|        

- Install TinyFileManager on Raspberry Pi
- This script installs Apache, PHP, and TinyFileManager
- Configured to only access /mnt/usb_share directory

EOF

  echo "===== Updating system packages ====="
  apt update && apt upgrade -y

  echo "===== Installing Apache web server ====="
  apt install -y apache2

  # Verify Apache installation
  if [ ! -f "/etc/apache2/apache2.conf" ]; then
      echo "Apache configuration file not found. Attempting to repair..."
      apt remove --purge -y apache2 apache2-*
      rm -rf /etc/apache2
      apt clean
      apt update
      apt install -y apache2
      
      # Check again
      if [ ! -f "/etc/apache2/apache2.conf" ]; then
          echo "ERROR: Failed to install Apache properly. Please check your system."
          exit 1
      fi
  fi

  # Make sure Apache is enabled and started
  systemctl enable apache2
  systemctl start apache2

  # Verify Apache is running
  if ! systemctl is-active --quiet apache2; then
      echo "WARNING: Apache is not running. Checking error logs..."
      journalctl -u apache2 --no-pager -n 20
      echo "Attempting to fix common issues..."
      
      # Fix common issues
      mkdir -p /var/log/apache2
      chown -R www-data:www-data /var/log/apache2
      chmod -R 755 /var/log/apache2
      
      # Try starting again
      systemctl start apache2
      
      if ! systemctl is-active --quiet apache2; then
          echo "ERROR: Could not start Apache. Please check logs and fix manually."
          echo "You can continue with the installation, but TinyFileManager won't work until Apache is running."
      fi
  fi

  echo "===== Installing PHP and required extensions ====="
  apt install -y php php-zip php-json php-mbstring php-gd php-curl libapache2-mod-php

  echo "===== Creating web directory if not exists ====="
  # Now placing directly in the web root
  # No need for a subdirectory anymore

  echo "===== Making sure /mnt/usb_share exists ====="
  mkdir -p /mnt/usb_share
  chmod 755 /mnt/usb_share || echo "Warning: Could not change permissions on /mnt/usb_share - it may be mounted with a filesystem that doesn't support Linux permissions"
  chown www-data:www-data /mnt/usb_share 2>/dev/null || echo "Warning: Could not change ownership of /mnt/usb_share - it may be mounted with a filesystem that doesn't support Linux ownership"

  # Add a workaround for non-Linux filesystems
  echo "===== Adding Apache user to necessary groups for access ====="
  usermod -a -G plugdev,dialout www-data
  # Set permissive umask for Apache to ensure it can write to the directory
  echo "umask 0002" >> /etc/apache2/envvars

  # Remove any existing index.html that would take precedence over our index.php
  if [ -f "/var/www/html/index.html" ]; then
      echo "===== Removing existing index.html ====="
      rm -f /var/www/html/index.html
  fi

  echo "===== Downloading TinyFileManager as index.php ====="
  wget -O /var/www/html/index.php https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php

  echo "===== Configuring TinyFileManager to only access /mnt/usb_share ====="
  # Create a backup of the original file
  cp /var/www/html/index.php /var/www/html/index.php.backup

  # Modify the file to restrict access to /mnt/usb_share
  sed -i "s|\$root_path = \$_SERVER\['DOCUMENT_ROOT'\];|\$root_path = '/mnt/usb_share';|g" /var/www/html/index.php
  sed -i "s|\$root_url = '';|\$root_url = '';|g" /var/www/html/index.php
  sed -i "s|// \$directories_users|//\$directories_users|g" /var/www/html/index.php

  # Set dark theme as default
  sed -i "s|'theme' => 'light'|'theme' => 'dark'|g" /var/www/html/index.php

  echo "===== Setting proper permissions ====="
  chown -R www-data:www-data /var/www/html/index.php
  chmod 644 /var/www/html/index.php

  echo "===== Restarting Apache ====="
  if systemctl is-active --quiet apache2; then
      systemctl restart apache2
      if ! systemctl is-active --quiet apache2; then
          echo "WARNING: Apache failed to restart. Attempting to start..."
          systemctl start apache2
      fi
  else
      echo "WARNING: Apache is not running. Attempting to start..."
      systemctl start apache2
  fi

  # Final check
  if ! systemctl is-active --quiet apache2; then
      echo "ERROR: Apache is not running. TinyFileManager will not be accessible."
      echo "Please fix Apache issues before accessing TinyFileManager."
  fi

  # Setup USB gadget service if the test script exists
  echo "===== Setting up USB gadget to run on boot ====="

  # Check if test_usb_gadget.sh exists
  TEST_SCRIPT="/home/pi/test_usb_gadget.sh"
  if [ ! -f "$TEST_SCRIPT" ]; then
      echo "WARNING: The test_usb_gadget.sh script was not found at $TEST_SCRIPT."
      echo "The USB gadget service will not be configured."
  else
      # Make sure the test script is executable
      chmod +x "$TEST_SCRIPT"
      
      # Create the systemd service file
      cat > /etc/systemd/system/usb-gadget.service << EOF
[Unit]
Description=USB Gadget Setup
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/home/pi/test_usb_gadget.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

      # Set correct permissions for the service file
      chmod 644 /etc/systemd/system/usb-gadget.service
      
      # Enable the service to run at boot
      systemctl enable usb-gadget.service
      
      # Start the service now
      if systemctl start usb-gadget.service; then
          echo "✓ USB gadget service started successfully."
      else
          echo "! USB gadget service failed to start. Check status with: systemctl status usb-gadget.service"
      fi
      
      echo "✓ USB gadget service configured to run at boot."
  fi

  # Get the IP address to display in the final message
  IP_ADDRESS=$(hostname -I | awk '{print $1}')

  echo "===== TinyFileManager Installation completed! ====="
  echo "You can now access TinyFileManager at: http://$IP_ADDRESS/"
  echo "TinyFileManager is restricted to only view and manage files in /mnt/usb_share"
  echo ""
  echo "Default login credentials:"
  echo "Administrator: admin/admin@123"
  echo "User: user/12345"
  echo ""
  echo "IMPORTANT: Please change the default login credentials for security reasons!"
  echo "You can modify the credentials by editing the /var/www/html/index.php file."
  echo ""
  echo "NOTE: If /mnt/usb_share is mounted as FAT32 or NTFS filesystem, you may need to"
  echo "manually adjust the mount options to allow the web server to write to it."
  echo "You can do this by adding 'umask=0002,uid=www-data,gid=www-data' to your mount options."
}

# Install components based on the user's choice
if [[ "$INSTALL_CHOICE" == "1" || "$INSTALL_CHOICE" == "3" ]]; then
  install_usb_drive
fi

if [[ "$INSTALL_CHOICE" == "2" || "$INSTALL_CHOICE" == "3" ]]; then
  install_tiny_file_manager
fi

# Final message for combined installation
if [[ "$INSTALL_CHOICE" == "3" ]]; then
  # Get the IP address to display in the final message
  IP_ADDRESS=$(hostname -I | awk '{print $1}')
  
  echo ""
  echo "=====================================================
All-In-One Installation Complete!
=====================================================
Your Raspberry Pi has been configured with:

1. USB Drive Configuration:
   - Connect your Pi via USB to use it as a USB drive
   - Access it on your network via Samba: \\\\$(hostname)\\usb

2. TinyFileManager Web Interface:
   - Web access: http://$IP_ADDRESS/
   - Default login: admin/admin@123 (change this!)

For full functionality, please reboot your Pi:
  sudo reboot

The system will reboot in 5 seconds to apply all changes..."

  # Schedule a reboot in 5 seconds
  (sleep 5 && reboot) &
elif [[ "$INSTALL_CHOICE" == "1" ]]; then
  echo ""
  echo "Please reboot your Pi for all settings to take effect:
  sudo reboot"
  
  # Ask about rebooting
  read -p "Would you like to reboot now? (y/n): " REBOOT_NOW
  if [[ "$REBOOT_NOW" == "y" || "$REBOOT_NOW" == "Y" ]]; then
    echo "Rebooting in 5 seconds..."
    (sleep 5 && reboot) &
  fi
fi