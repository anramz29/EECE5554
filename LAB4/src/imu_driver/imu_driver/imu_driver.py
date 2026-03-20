import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Imu, MagneticField
from imu_msg.msg import IMUmsg
import serial
import sys
import math


def verify_checksum(sentence):
    """Verify the NMEA-style checksum of a VectorNav sentence."""
    try:
        # Strip leading $ and split on *
        if '$' in sentence:
            sentence = sentence[sentence.index('$') + 1:]
        data, checksum = sentence.rsplit('*', 1)
        checksum = checksum.strip()
        calculated = 0
        for ch in data:
            calculated ^= ord(ch)
        return format(calculated, '02X').upper() == checksum.upper()
    except Exception:
        return False


def parse_vnymr(line):
    """
    Parse a $VNYMR sentence.
    Format:
      $VNYMR,Yaw,Pitch,Roll,MagX,MagY,MagZ,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ*Checksum
    Returns a dict with all fields, or None if invalid.
    """
    line = line.strip()
    if not line.startswith('$VNYMR'):
        return None
    if not verify_checksum(line):
        return None
    try:
        # Remove $ and checksum
        body = line[1:line.index('*')]
        fields = body.split(',')
        if len(fields) != 13:
            return None
        return {
            'yaw':    float(fields[1]),
            'pitch':  float(fields[2]),
            'roll':   float(fields[3]),
            'mag_x':  float(fields[4]),
            'mag_y':  float(fields[5]),
            'mag_z':  float(fields[6]),
            'accel_x': float(fields[7]),
            'accel_y': float(fields[8]),
            'accel_z': float(fields[9]),
            'gyro_x': float(fields[10]),
            'gyro_y': float(fields[11]),
            'gyro_z': float(fields[12]),
        }
    except (ValueError, IndexError):
        return None


def euler_to_quaternion(roll_deg, pitch_deg, yaw_deg):
    """Convert Euler angles (degrees) to quaternion (x, y, z, w)."""
    r = math.radians(roll_deg)
    p = math.radians(pitch_deg)
    y = math.radians(yaw_deg)

    cy = math.cos(y * 0.5)
    sy = math.sin(y * 0.5)
    cp = math.cos(p * 0.5)
    sp = math.sin(p * 0.5)
    cr = math.cos(r * 0.5)
    sr = math.sin(r * 0.5)

    qw = cr * cp * cy + sr * sp * sy
    qx = sr * cp * cy - cr * sp * sy
    qy = cr * sp * cy + sr * cp * sy
    qz = cr * cp * sy - sr * sp * cy

    return qx, qy, qz, qw


class IMUDriver(Node):
    def __init__(self, port):
        super().__init__('imu_driver')
        self.publisher_ = self.create_publisher(IMUmsg, 'imu', 10)
        self.port = port
        self.serial_conn = None
        self.connect()
        # Timer at 40 Hz
        self.timer = self.create_timer(1.0 / 40.0, self.read_and_publish)

    def connect(self):
        try:
            self.serial_conn = serial.Serial(self.port, baudrate=115200, timeout=1)
            self.get_logger().info(f'Connected to serial port: {self.port}')
            self.set_output_rate_40hz()
        except serial.SerialException as e:
            self.get_logger().error(f'Failed to open serial port {self.port}: {e}')
            sys.exit(1)

    def set_output_rate_40hz(self):
        """
        Write to VectorNav register 07 (Async Data Output Frequency) to set 40 Hz.
        Command format: $VNWRG,07,40*XX
        The checksum is calculated over 'VNWRG,07,40'
        """
        cmd_body = 'VNWRG,07,40'
        checksum = 0
        for ch in cmd_body:
            checksum ^= ord(ch)
        cmd = f'${cmd_body}*{checksum:02X}\r\n'
        self.get_logger().info(f'Setting output rate to 40 Hz: {cmd.strip()}')
        self.serial_conn.write(cmd.encode('ascii'))

    def read_and_publish(self):
        if self.serial_conn is None or not self.serial_conn.is_open:
            return
        try:
            raw = self.serial_conn.readline().decode('ascii', errors='ignore')
        except serial.SerialException as e:
            self.get_logger().error(f'Serial read error: {e}')
            return

        data = parse_vnymr(raw)
        if data is None:
            return

        now = self.get_clock().now()
        sec = now.nanoseconds // 10**9
        nanosec = now.nanoseconds % 10**9

        # Build custom message
        msg = IMUmsg()

        # Header
        msg.header.frame_id = 'IMU1_Frame'
        msg.header.stamp.sec = sec
        msg.header.stamp.nanosec = nanosec

        # IMU message
        qx, qy, qz, qw = euler_to_quaternion(data['roll'], data['pitch'], data['yaw'])
        msg.imu.header.frame_id = 'IMU1_Frame'
        msg.imu.header.stamp.sec = sec
        msg.imu.header.stamp.nanosec = nanosec
        msg.imu.orientation.x = qx
        msg.imu.orientation.y = qy
        msg.imu.orientation.z = qz
        msg.imu.orientation.w = qw
        msg.imu.angular_velocity.x = data['gyro_x']
        msg.imu.angular_velocity.y = data['gyro_y']
        msg.imu.angular_velocity.z = data['gyro_z']
        msg.imu.linear_acceleration.x = data['accel_x']
        msg.imu.linear_acceleration.y = data['accel_y']
        msg.imu.linear_acceleration.z = data['accel_z']

        # Magnetic field message (VectorNav outputs in Gauss, convert to Tesla)
        msg.mag_field.header.frame_id = 'IMU1_Frame'
        msg.mag_field.header.stamp.sec = sec
        msg.mag_field.header.stamp.nanosec = nanosec
        msg.mag_field.magnetic_field.x = data['mag_x'] * 1e-4
        msg.mag_field.magnetic_field.y = data['mag_y'] * 1e-4
        msg.mag_field.magnetic_field.z = data['mag_z'] * 1e-4

        # Raw string (optional but useful for debugging)
        msg.raw_imu_string = raw.strip()

        self.publisher_.publish(msg)


def main(args=None):
    rclpy.init(args=args)

    if len(sys.argv) < 2:
        print('Usage: ros2 run imu_driver imu_driver <serial_port>')
        print('Example: ros2 run imu_driver imu_driver /dev/ttyUSB0')
        sys.exit(1)

    port = sys.argv[1]
    node = IMUDriver(port)

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        if node.serial_conn and node.serial_conn.is_open:
            node.serial_conn.close()
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()