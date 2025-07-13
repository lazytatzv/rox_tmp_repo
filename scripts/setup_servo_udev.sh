#!/bin/bash

# Script to help identify servo motor device characteristics and install udev rules
# Usage: ./scripts/setup_servo_udev.sh

set -e

echo "=== Servo Motor Device Setup Script ==="
echo

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "Warning: Running as root. This script should be run as a regular user."
        echo "It will use sudo when needed."
        echo
    fi
}

# Function to identify connected USB serial devices
identify_devices() {
    echo "1. Identifying connected USB serial devices..."
    echo
    
    echo "Connected ttyACM devices:"
    ls -la /dev/ttyACM* 2>/dev/null || echo "No ttyACM devices found"
    echo
    
    echo "Connected ttyUSB devices:"
    ls -la /dev/ttyUSB* 2>/dev/null || echo "No ttyUSB devices found"
    echo
    
    echo "USB device information:"
    lsusb | grep -i "serial\|arduino\|ch340\|ftdi\|cp210" || echo "No common serial devices found"
    echo
}

# Function to show device details for udev rule creation
show_device_details() {
    echo "2. Device details for udev rule creation:"
    echo
    
    for device in /dev/ttyACM* /dev/ttyUSB*; do
        if [[ -e "$device" ]]; then
            echo "--- Device: $device ---"
            udevadm info -a -n "$device" | grep -E "SUBSYSTEM|KERNEL|idVendor|idProduct|serial|manufacturer|product" | head -10
            echo
        fi
    done
}

# Function to install udev rules
install_udev_rules() {
    echo "3. Installing udev rules..."
    echo
    
    RULES_FILE="99-servo-motor.rules"
    TARGET_DIR="/etc/udev/rules.d"
    
    if [[ ! -f "$RULES_FILE" ]]; then
        echo "Error: $RULES_FILE not found in current directory"
        echo "Please run this script from the project root directory"
        exit 1
    fi
    
    echo "Installing udev rules to $TARGET_DIR/$RULES_FILE"
    sudo cp "$RULES_FILE" "$TARGET_DIR/"
    
    echo "Reloading udev rules..."
    sudo udevadm control --reload-rules
    
    echo "Triggering udev events..."
    sudo udevadm trigger
    
    echo "udev rules installed successfully!"
    echo
}

# Function to test the installation
test_installation() {
    echo "4. Testing installation..."
    echo
    
    echo "Checking for servo device symlinks:"
    ls -la /dev/servo* 2>/dev/null || echo "No servo symlinks found yet"
    echo
    
    echo "If no servo symlinks are found, you may need to:"
    echo "1. Disconnect and reconnect your servo motor device"
    echo "2. Edit the udev rules file to match your specific device"
    echo "3. Check device vendor ID and product ID with: lsusb -v"
    echo
}

# Function to show usage instructions
show_usage() {
    echo "5. Usage in your application:"
    echo
    echo "Update your configuration files to use /dev/servo instead of /dev/ttyACM0"
    echo
    echo "Example changes needed:"
    echo "- ros_ws/config/mecanum.yaml: serial_port: \"/dev/servo\""
    echo "- resources/serial_reader.py: SERIAL_PORT = \"/dev/servo\""
    echo "- resources/send_command_with_crc.cpp: boost::asio::serial_port port(io_context, \"/dev/servo\");"
    echo
}

# Main execution
main() {
    check_root
    identify_devices
    show_device_details
    
    echo "Do you want to install the udev rules? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        install_udev_rules
        test_installation
    else
        echo "Skipping installation. You can run this script again to install later."
        echo
    fi
    
    show_usage
    
    echo "=== Setup Complete ==="
}

# Run main function
main "$@"