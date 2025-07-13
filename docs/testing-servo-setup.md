# Testing the Servo Device Setup

This document provides step-by-step instructions to test the servo device setup with udev rules.

## Prerequisites

1. A servo motor controller connected via USB (Arduino, CH340, FTDI, etc.)
2. Linux system with udev support
3. Docker and docker-compose installed

## Testing Steps

### 1. Before Setup - Identify Current Device

```bash
# Check current device assignment
ls -la /dev/ttyACM* /dev/ttyUSB* 2>/dev/null

# Get device information
lsusb | grep -i "serial\|arduino\|ch340\|ftdi"

# Check device details (replace ttyACM0 with your actual device)
udevadm info -a -n /dev/ttyACM0 | grep -E "idVendor|idProduct|serial"
```

### 2. Run the Setup Script

```bash
# From the project root directory
./scripts/setup_servo_udev.sh
```

Follow the prompts to install the udev rules.

### 3. Verify the Setup

```bash
# Check if servo symlink was created
ls -la /dev/servo*

# If no symlink appears, disconnect and reconnect the device
# Then check again
ls -la /dev/servo*

# Run verification script
./scripts/verify_device_paths.sh
```

### 4. Test in Docker

```bash
# Build and start the Docker container
docker-compose up -d

# Enter the container
docker exec -it ros2_rox_container bash

# Inside the container, check if servo device is available
ls -la /dev/servo*

# Test device access (this should not give permission errors)
stat /dev/servo
```

### 5. Test the Application

```bash
# Inside the container, build the ROS workspace
cd /root/ros_ws
colcon build
source install/setup.bash

# Test the serial reader (should use /dev/servo)
python3 /root/ros_ws/../resources/serial_reader.py

# Or test the C++ command sender
cd /root/ros_ws/../resources
g++ send_command_with_crc.cpp -lboost_system -lpthread -o send_command
./send_command
```

## Troubleshooting

### Device Not Found

If `/dev/servo` is not created:

1. Check if the device is connected: `lsusb`
2. Check kernel messages: `dmesg | tail`
3. Verify the udev rule matches your device:
   ```bash
   udevadm info -a -n /dev/ttyACM0 | grep -E "idVendor|idProduct"
   ```
4. Update the udev rules file to match your device's vendor/product ID

### Permission Denied

If you get permission errors:

1. Add your user to the dialout group:
   ```bash
   sudo usermod -a -G dialout $USER
   # Log out and log back in
   ```

2. Check device permissions:
   ```bash
   ls -la /dev/servo
   ```

### Docker Issues

1. Ensure Docker has access to devices:
   ```bash
   docker run --rm -it --device=/dev/servo:/dev/servo ubuntu:latest ls -la /dev/servo
   ```

2. Check if the container mounts the device correctly:
   ```bash
   docker exec -it ros2_rox_container ls -la /dev/
   ```

## Expected Results

- ✅ `/dev/servo` symlink created and points to actual device
- ✅ Application can connect to servo motor using `/dev/servo`
- ✅ Device remains accessible after disconnecting/reconnecting USB
- ✅ Docker container can access the device
- ✅ No hardcoded `/dev/ttyACM*` references in configuration files

## Reverting Changes

To revert to the original setup:

```bash
# Remove udev rules
sudo rm /etc/udev/rules.d/99-servo-motor.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Restore original configuration (if needed)
git checkout HEAD~1 -- ros_ws/config/mecanum.yaml resources/
```