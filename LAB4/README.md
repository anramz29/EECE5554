# LAB4 — GPS + IMU Driver

ROS 2 workspace with a GPS driver (SparkFun NEO-M9N) and an IMU driver (VectorNav VN-100) that can be launched together with a single launch file.

## Prerequisites

- ROS 2 (tested on Humble)
- Python dependencies: `pyserial`
- Hardware connected:
  - GPS on `/dev/ttyACM0` (default)
  - IMU on `/dev/ttyUSB0` (default)

## Build

From the workspace root (`LAB4/`):

```bash
colcon build
source install/setup.bash
```

## Launch Both Nodes

Use the `lab4_bringup` launch file to start both the GPS and IMU drivers at once:

```bash
ros2 launch lab4_bringup lab4.launch.py
```

### Custom Serial Ports

If your devices are on different ports, override the defaults:

```bash
ros2 launch lab4_bringup lab4.launch.py gps_port:=/dev/ttyACM1 imu_port:=/dev/ttyUSB1
```

| Argument   | Default        | Description                  |
|------------|----------------|------------------------------|
| `gps_port` | `/dev/ttyACM0` | Serial port for the GPS      |
| `imu_port` | `/dev/ttyUSB0` | Serial port for the VN-100 IMU |

## Published Topics

| Topic | Message Type | Node |
|-------|-------------|------|
| `/gps` | `gps_driver_msgs/GpsMsg` | `gps_driver` |
| `/imu` | `imu_msg/IMUmsg` | `imu_driver` |

## Recording a Bag

A helper script records both topics to a named bag under `src/data/`:

```bash
cd src
./record_bag.sh
```

You will be prompted for a bag name. Press `Ctrl+C` to stop recording.
