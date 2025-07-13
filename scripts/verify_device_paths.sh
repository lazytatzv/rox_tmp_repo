#!/bin/bash

# Script to verify that all device paths have been updated to use /dev/servo
# Usage: ./scripts/verify_device_paths.sh

echo "=== Servo Device Path Verification ==="
echo

# Function to check for old device paths
check_old_paths() {
    echo "Checking for old device paths (/dev/ttyACM*)..."
    echo
    
    local found_old=false
    
    # Search for ttyACM references in source files
    for file in $(find . -name "*.py" -o -name "*.cpp" -o -name "*.yaml" -o -name "*.launch" 2>/dev/null); do
        if [[ -f "$file" ]] && grep -l "ttyACM" "$file" 2>/dev/null; then
            echo "❌ Found old device path in: $file"
            grep -n "ttyACM" "$file" | head -3
            echo
            found_old=true
        fi
    done
    
    if [[ "$found_old" == false ]]; then
        echo "✅ No old device paths found"
    fi
    echo
}

# Function to check for new device paths
check_new_paths() {
    echo "Checking for new device paths (/dev/servo)..."
    echo
    
    local found_new=false
    local expected_files=(
        "ros_ws/config/mecanum.yaml"
        "resources/serial_reader.py"
        "resources/send_command_with_crc.cpp"
        "ros_ws/src/mecanum_wheel_controller/src/mecanum_wheel_controller_node.cpp"
    )
    
    for file in "${expected_files[@]}"; do
        if [[ -f "$file" ]] && grep -l "/dev/servo" "$file" 2>/dev/null; then
            echo "✅ Found new device path in: $file"
            grep -n "/dev/servo" "$file" | head -2
            echo
            found_new=true
        else
            echo "❌ Missing new device path in: $file"
            echo
        fi
    done
    
    if [[ "$found_new" == false ]]; then
        echo "❌ No new device paths found in expected files"
    fi
}

# Function to check udev rules
check_udev_rules() {
    echo "Checking udev rules..."
    echo
    
    if [[ -f "99-servo-motor.rules" ]]; then
        echo "✅ udev rules file exists: 99-servo-motor.rules"
        echo "Rules preview:"
        grep -v "^#" 99-servo-motor.rules | grep -v "^$" | head -5
        echo
    else
        echo "❌ udev rules file not found: 99-servo-motor.rules"
        echo
    fi
}

# Function to check setup script
check_setup_script() {
    echo "Checking setup script..."
    echo
    
    if [[ -f "scripts/setup_servo_udev.sh" ]] && [[ -x "scripts/setup_servo_udev.sh" ]]; then
        echo "✅ Setup script exists and is executable: scripts/setup_servo_udev.sh"
    else
        echo "❌ Setup script missing or not executable: scripts/setup_servo_udev.sh"
    fi
    echo
}

# Function to check documentation
check_documentation() {
    echo "Checking documentation..."
    echo
    
    if [[ -f "docs/servo-device-setup.md" ]]; then
        echo "✅ Documentation exists: docs/servo-device-setup.md"
    else
        echo "❌ Documentation missing: docs/servo-device-setup.md"
    fi
    
    if grep -l "servo-device-setup.md" README.md 2>/dev/null; then
        echo "✅ README.md updated with servo setup information"
    else
        echo "❌ README.md not updated with servo setup information"
    fi
    echo
}

# Main execution
main() {
    check_old_paths
    check_new_paths
    check_udev_rules
    check_setup_script
    check_documentation
    
    echo "=== Verification Complete ==="
}

# Run main function
main "$@"