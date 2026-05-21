# EECE5554 — Robotics Sensing and Navigation

Course lab repository for EECE5554 at Northeastern University. Each lab builds toward a complete sensor fusion stack using ROS 2 Humble.

**Author:** Adrian Ramirez (ramirez.adr@northeastern.edu)

---

## Final Report (For the Class)

**Magnetic Interference and Calibration: A Comparative Analysis of Magnetometers**
*Malia Howe, Shayda Moezzi, Adrian Ramirez — EECE5554, April 2026*

Capstone report for the course. Benchmarked four magnetometer calibration algorithms (MinMax, Magcal, Scalar EKF, and Levenberg-Marquardt) across an industrial-grade VN-100 and a consumer-grade iPhone 11 under controlled hard iron, soft iron, and combined distortion conditions at 7 cm and 30 cm separation distances.

Key findings:
- The iPhone 11 outperformed the VN-100 (13–19% vs 22–34% mean magnitude error), attributed to the VN-100's Vector Processing Engine violating algorithm independence assumptions
- Magcal and Levenberg-Marquardt produced the most consistent calibration output (~0.92 µT and ~0.94 µT std dev)
- MinMax was fastest but most sensitive to distortion intensity
- Scalar EKF achieved competitive accuracy but had the highest standard deviation and slowest runtime

Full report: [`EECE5554_Final_Report.pdf`](./EECE5554_Final_Report.pdf)

---

## Repository Structure

| Directory | Topic |
|-----------|-------|
| [LAB0](#lab0) | ROS 2 Publisher / Subscriber basics |
| [LAB1](#lab1) | GPS Driver (SparkFun NEO-M9N) |
| [gnss (LAB2)](#gnss) | RTK GNSS Driver & Accuracy Analysis |
| [LAB3](#lab3) | IMU Driver (VectorNav VN-100) |
| [LAB4](#lab4) | GPS + IMU Integration with EKF |
| [LAB5](#lab5) | Camera Calibration & Image Mosaicking |


---

## Prerequisites

- ROS 2 Humble
- Python 3
- `colcon` build tool
- Jupyter (for analysis notebooks)

```bash
source /opt/ros/humble/setup.bash
```

---

## LAB0

**Simple ROS 2 pub/sub demo.**

A minimal talker/listener pair using `std_msgs/String`. Entry point for verifying the ROS 2 environment.

```bash
cd LAB0
colcon build
source install/setup.bash
ros2 run simple_chatter talker
ros2 run simple_chatter listener
```

---

## LAB1

**GPS Driver for the SparkFun NEO-M9N.**

Parses NMEA GPGGA sentences over serial, converts to decimal degrees and UTM, and publishes a custom `GpsMsg`.

**Custom message:** `gps_driver_msgs/GpsMsg`
- `latitude`, `longitude`, `altitude`, `hdop`
- `utm_easting`, `utm_northing`, `utm_zone`, `utm_letter`
- `utc_time`

```bash
cd LAB1
colcon build
source install/setup.bash
ros2 launch gps_driver launch.py port:=/dev/ttyACM0
```

Launch argument: `port` (default `/dev/ttyACM0`)

Analysis notebook: `LAB1/src/analysis.ipynb`

---

## LAB3

**IMU Driver for the VectorNav VN-100.**

Communicates over serial at 40 Hz. Publishes accelerometer, gyroscope, and magnetometer data as a combined custom message. Includes Allan deviation analysis for noise characterization.

**Custom message:** `imu_msg/IMUmsg`
- `sensor_msgs/Imu` (accel + gyro)
- `sensor_msgs/MagneticField`
- Raw device string

```bash
cd LAB3
colcon build
source install/setup.bash
ros2 launch imu_driver imu_launch.py port:=/dev/ttyUSB0
```

Record data:

```bash
bash LAB3/src/record_bag.sh
```

Analysis notebook: `LAB3/src/analysis/analysis.ipynb`

---

## LAB4

**GPS + IMU Sensor Fusion with EKF-SLAM.**

Brings up both drivers simultaneously via a single launch file. Includes complementary filter yaw estimation and an Extended Kalman Filter for position tracking.

```bash
cd LAB4
colcon build
source install/setup.bash
ros2 launch lab4_bringup lab4.launch.py gps_port:=/dev/ttyACM0 imu_port:=/dev/ttyUSB0
```

Record data:

```bash
bash LAB4/src/record_bag.sh
```

Analysis notebook: `LAB4/src/analysis/analysis.ipynb`

Key outputs: trajectory comparison, position error, yaw from complementary filter vs. IMU, magnetometer calibration.

---

## LAB5

**Camera Calibration & Panoramic Image Stitching.**

Uses a checkerboard pattern to compute the intrinsic matrix K and lens distortion coefficients. Applies rectification, Harris corner detection, and homography-based mosaicking to construct panoramic images.

**Tools:** MATLAB (`harris.m`, `mosaic.m`)

Calibration data and results: `LAB5/images/chessboards/`

Mural stitching results: `LAB5/images/Murals/`

---

## GNSS

**RTK GNSS Driver for centimeter-level positioning.**

Parses GNGGA sentences from an RTK-capable receiver. Publishes fix quality, HDOP, and full UTM coordinates. Datasets include open-sky, occluded, walking, and vehicle scenarios for accuracy comparison.

**Custom message:** `rtk_driver_msgs/CustomRTK`
- `latitude`, `longitude`, `altitude`, `hdop`, `fix_quality`
- `utm_easting`, `utm_northing`, `utm_zone`, `utm_letter`
- `utc_time`, raw `GNGGA` sentence

```bash
cd gnss
colcon build
source install/setup.bash
ros2 launch rtk_driver rtk_driver_launch.py
```

Analysis notebook: `gnss/analysis.ipynb`

---

## Data Format

All rosbag2 data uses the `.db3` format with `metadata.yaml`. Topics recorded:

| Topic | Type |
|-------|------|
| `/gps` | `gps_driver_msgs/GpsMsg` |
| `/imu` | `imu_msg/IMUmsg` |
| `/rtk` | `rtk_driver_msgs/CustomRTK` |