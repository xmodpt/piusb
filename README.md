# Raspberry Pi Virtual USB Drive + File Manager for 3D Printing

![Pi Logo](https://i.imgur.com/362AXY0.png)
## Introduction

This project transforms a Raspberry Pi Zero W into the perfect companion for your 3D printer. By emulating a USB flash drive and providing a web-based file manager, it creates a seamless bridge between your design workflow and your 3D printer.

### The 3D Printing Problem

Managing 3D printing files typically involves a cumbersome workflow:
- Design your model on your computer
- Export to STL/G-code
- Copy to an SD card or USB drive
- Physically transfer to your printer
- Repeat for every iteration

### The Solution

This script turns your Raspberry Pi into:
1. A virtual USB flash drive that connects directly to your 3D printer
2. A web-accessible file manager for remotely uploading and managing your print files

Simply upload your files through the web interface from anywhere on your network, and they'll be immediately available to your printer through the USB connection. No more shuffling SD cards or USB drives between devices!

## Features

### 🔌 USB Drive Emulation for 3D Printers
- Configurable storage size (4GB, 8GB, 16GB, 32GB, or custom)
- Appears as a Kingston DataTraveler USB drive to your 3D printer
- Persists your G-code files between prints and power cycles
- Full read/write capability for printer firmware interaction
- Compatible with most 3D printers that support USB storage

![Tiny File Manager](https://i.imgur.com/IGjy2kM.png)

### 📂 TinyFileManager Web Interface for G-code Management
- Browser-based file management from any device
- Upload new designs directly from your slicer computer
- Organize designs in folders by project or type
- Preview G-code files before printing
- Delete failed designs or old versions
- Archive completed projects
- Secure login system

### 🌐 Network Accessibility for Flexible Workflow
- Access your print files from any device on your network
- Samba share for Windows/Mac/Linux direct access
- Web interface accessible from tablets, phones, or computers
- SSH access for advanced management and automation
- Maintain a library of your designs in one accessible location

## 📋 Prerequisites

- Raspberry Pi Zero W (or any Pi with USB OTG capability)
- Micro SD card (8GB minimum, 16GB+ recommended)
- Power supply for Raspberry Pi
- Computer with SD card reader
- WiFi network for Pi to connect to

## 🛠️ Installation Guide

### Step 1: Prepare Raspberry Pi SD Card

#### Option A: Using Raspberry Pi Imager (Recommended)

1. Download [Raspberry Pi Imager](https://www.raspberrypi.org/software/)
2. Install and launch the application
3. Click "Choose OS" → Raspberry Pi OS (other) → Raspberry Pi OS Lite (64-bit)
4. Click "Choose Storage" and select your SD card
5. Click the gear icon (⚙️) to access advanced options:
   - Enable SSH
   - Set username and password
   - Configure your WiFi network
   - Set locale settings
6. Click "Write" and wait for completion

#### Option B: Manual Setup

1. Download [Raspberry Pi OS Lite (64-bit)](https://www.raspberrypi.org/software/operating-systems/)
2. Flash the image to your SD card using [balenaEtcher](https://www.balena.io/etcher/) or similar
3. After flashing, create two files on the boot partition:

   Create an empty file named `ssh` (no extension):
   ```
   # On Windows: Use Notepad, save as "ssh" with "All Files" file type
   # On Mac/Linux: touch /Volumes/boot/ssh or equivalent path
   ```

   Create `wpa_supplicant.conf` with your WiFi details:
   ```
   country=US
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1
   
   network={
       ssid="YOUR_WIFI_NAME"
       psk="YOUR_WIFI_PASSWORD"
       key_mgmt=WPA-PSK
   }
   ```

### Step 2: Boot and Access the Raspberry Pi

1. Insert the SD card into the Pi and power it on
2. Wait 1-2 minutes for first boot and WiFi connection
3. Find the Pi's IP address:
   - Check your router's connected devices list
   - Use an IP scanner like [Advanced IP Scanner](https://www.advanced-ip-scanner.com/) (Windows) or `nmap -sn 192.168.1.0/24` (Mac/Linux)
4. Connect via SSH:n\
   ![putty_logo](https://www.putty.org/Putty.png)\
   Download [Putty](https://www.putty.org/)\
   or\
   use your terminal app and connect to:\
   ```
   ssh pi@your_pi_ip_address
   ```
   Default credentials (if not changed during setup):
   - Username: `pi`
   - Password: `raspberry`

### Step 3: Install the Script

1. Download the installation script:
   ```bash
   wget -O virtual_usb_and_TFM_install.sh wget --output-document=virtual_usb_and_TFM_install.sh "https://git.io/JJgRE"
   ```

2. Make it executable:
   ```bash
   chmod +x virtual_usb_and_TFM_install.sh
   ```

3. Run with sudo:
   ```bash
   sudo ./virtual_usb_and_TFM_install.sh
   ```

4. Follow the on-screen prompts:
   - Choose which components to install (USB drive, TinyFileManager, or both)
   - Select your preferred USB drive size
   - Confirm your choices when prompted

5. Reboot when installation completes:
   ```bash
   sudo reboot
   ```

## 🚀 Usage Instructions

### 3D Printer Setup

1. Connect the Raspberry Pi to your 3D printer using the Pi's **USB port** (not the PWR port) with a data-capable micro USB cable
2. Power on both the Pi and your 3D printer
3. The Pi will appear to your printer as a "Kingston DataTraveler" USB drive
4. Your 3D printer should now recognize the Pi as external storage

### Managing 3D Print Files

1. Access TinyFileManager by navigating to `http://your_pi_ip_address/` in any web browser
2. Login with default credentials:
   - Administrator: `admin / admin@123`
   - User: `user / 12345`
3. **Important:** Change the default passwords immediately
4. Upload your files directly through the web interface
5. Organize files by creating folders for different projects or print types
6. Your uploaded files will be instantly available to your 3D printer
7. Use the preview feature to verify G-code before printing

### Network Share Access

- Windows: Open File Explorer and enter `\\your_pi_hostname\usb` in the address bar
- Mac: In Finder, press Cmd+K and enter `smb://your_pi_hostname/usb`
- Linux: Mount using `mount -t cifs //your_pi_hostname/usb /mnt/usb -o guest`

## ⚙️ Customization

### Changing TinyFileManager Credentials

1. Edit the config file:
   ```bash
   sudo nano /var/www/html/index.php
   ```

2. Find the `$auth_users` section (around line 50)
3. Modify usernames and password hashes
4. Save and exit (Ctrl+X, Y, Enter)

### Increasing USB Drive Size

1. Run the installation script again:
   ```bash
   sudo ./virtual_usb_and_TFM_install.sh
   ```
2. Choose option 1 (USB drive configuration only)
3. Select "n" when asked to keep existing setup (this will delete all contents of the old drive)
4. Choose a larger size
5. Reboot when finished

## 🔍 Troubleshooting

### USB Drive Not Detected

If your computer doesn't recognize the USB drive:

1. SSH into your Pi
2. Run the test script:
   ```bash
   sudo /home/pi/test_usb_gadget.sh
   ```
3. Try a different USB cable (must support data, not just power)
4. Ensure you're using the correct USB port on the Pi (not the PWR port)

### TinyFileManager Access Issues

If you can't access the web interface:

1. Verify Apache is running:
   ```bash
   sudo systemctl status apache2
   ```
2. Check if you can ping your Pi
3. Verify no firewall is blocking port 80

### Permission Problems

If you encounter permission errors when saving files:

1. SSH into your Pi
2. Run:
   ```bash
   sudo chmod -R 777 /mnt/usb_share
   ```
   Note: This is a permissive setting for convenience; adjust as needed for security

## 📋 Technical Details

The script makes the following changes to your system:

- Modifies `/boot/config.txt` to enable USB OTG mode
- Adds required kernel modules to `/etc/modules`
- Creates a USB drive image file at `/piusb.bin`
- Sets up `/mnt/usb_share` as mount point
- Creates systemd services for automatic mounting
- Installs and configures Apache, PHP, and TinyFileManager
- Configures Samba for network sharing

### 3D Printer Compatibility

This solution has been tested with various 3D printers including:
- Elegoo Mars 2 / Pro
- Elegoo Mars 3 / Pro
- Anycubic Photon
- Creality Ender series
- Prusa i3 variants
- Anycubic printers
- Any 3D printer that can read from standard USB storage

Note: Some 3D printers may have specific USB implementation quirks. The script uses standard USB mass storage identifiers that should work with most devices.

### Workflow Integration Ideas

- **Slicer Integration**: Save G-code outputs directly to the network share
- **Print Archive**: Keep a library of successful prints for future reference
- **Remote Management**: Start prints remotely by organizing "ready to print" folders
- **Print Farm Management**: Use multiple Pis to create a centralized file system for multiple printers

## 🔄 Uninstallation

To revert all changes:

```bash
# Remove TinyFileManager components
sudo apt remove -y apache2 php* libapache2-mod-php
sudo rm -rf /var/www/html/index.php

# Remove USB drive configuration
sudo rm /piusb.bin
sudo sed -i '/dwc2/d' /boot/config.txt
sudo sed -i 's/modules-load=dwc2,g_mass_storage//' /boot/cmdline.txt
sudo sed -i '/piusb.bin/d' /etc/fstab
sudo systemctl disable piusb-mount.service
sudo systemctl disable usb-gadget.service
sudo rm /etc/systemd/system/piusb-mount.service
sudo rm /etc/systemd/system/usb-gadget.service

# Reboot
sudo reboot
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [TinyFileManager](https://github.com/prasathmani/tinyfilemanager) for the web file management interface
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/) for USB OTG guidance
