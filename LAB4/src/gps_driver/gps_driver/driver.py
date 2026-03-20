#!/usr/bin/env python3
import argparse
import serial
import rclpy
from rclpy.node import Node
from std_msgs.msg import Header
from gps_driver_msgs.msg import GpsMsg
import utm

def nmea_to_decimal(dm: str, hemi: str) -> float:
    """
    NMEA lat/lon format:
      lat:  DDMM.MMMM
      lon: DDDMM.MMMM
    """
    if dm == '' or hemi == '':
        raise ValueError("Empty lat/lon field")

    raw = float(dm)
    deg = int(raw // 100)
    minutes = raw - deg * 100
    dec = deg + minutes / 60.0

    if hemi in ['S', 'W']:
        dec *= -1.0
    return dec

def parse_gpgga(sentence: str):
    """
    Example:
    $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
    """
    if not sentence.startswith("$GPGGA") and not sentence.startswith("$GNGGA"):
        return None

    # strip checksum part
    body = sentence.split('*')[0]
    fields = body.split(',')

    # indices per NMEA GGA
    utc = fields[1]
    lat_dm, lat_hemi = fields[2], fields[3]
    lon_dm, lon_hemi = fields[4], fields[5]
    fix_quality = fields[6]
    hdop = fields[8]
    alt = fields[9]

    # require a fix
    if fix_quality == '' or fix_quality == '0':
        return None

    lat = nmea_to_decimal(lat_dm, lat_hemi)
    lon = nmea_to_decimal(lon_dm, lon_hemi)
    altitude = float(alt) if alt != '' else float('nan')
    hdop_v = float(hdop) if hdop != '' else float('nan')

    # UTM conversion
    easting, northing, zone_num, zone_letter = utm.from_latlon(lat, lon)

    return {
        "utc": utc,
        "lat": lat,
        "lon": lon,
        "alt": altitude,
        "hdop": hdop_v,
        "easting": float(easting),
        "northing": float(northing),
        "zone": str(zone_num),
        "letter": str(zone_letter),
    }

def gpgga_utc_to_ros_time(utc_str: str):
    """
    Convert HHMMSS(.ss) UTC to a ROS2 builtin time.
    Lab wants you to use GPGGA time, not system time. :contentReference[oaicite:3]{index=3}
    We don’t know the date here, so we encode “seconds since midnight” into stamp.
    """
    if not utc_str:
        return (0, 0)

    # HHMMSS.SS
    hh = int(utc_str[0:2])
    mm = int(utc_str[2:4])
    ss = float(utc_str[4:])

    total = hh * 3600 + mm * 60 + ss
    sec = int(total)
    nsec = int((total - sec) * 1e9)
    return (sec, nsec)

class GPSDriver(Node):
    def __init__(self, port: str, baud: int = 4800):
        super().__init__('gps_driver')
        self.publisher_ = self.create_publisher(GpsMsg, '/gps', 10)

        self.ser = serial.Serial(port, baudrate=baud, timeout=1.0)
        self.get_logger().info(f"Reading GPS on {port} @ {baud} baud")

        # read loop timer
        self.timer = self.create_timer(0.05, self.read_once)

    def read_once(self):
        try:
            line = self.ser.readline().decode('ascii', errors='ignore').strip()
            if not line:
                return

            parsed = parse_gpgga(line)
            if parsed is None:
                return

            msg = GpsMsg()

            # Header
            hdr = Header()
            hdr.frame_id = "GPS1_Frame"  # required constant frame_id :contentReference[oaicite:4]{index=4}

            sec, nsec = gpgga_utc_to_ros_time(parsed["utc"])
            hdr.stamp.sec = sec
            hdr.stamp.nanosec = nsec

            msg.header = hdr
            msg.latitude = parsed["lat"]
            msg.longitude = parsed["lon"]
            msg.altitude = parsed["alt"]
            msg.hdop = parsed["hdop"]
            msg.utm_easting = parsed["easting"]
            msg.utm_northing = parsed["northing"]
            msg.utc = parsed["utc"]
            msg.zone = parsed["zone"]
            msg.letter = parsed["letter"]

            



            self.publisher_.publish(msg)

        except Exception as e:
            self.get_logger().warn(f"Read/parse error: {e}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', '-p', required=True, help='Serial port, e.g. /dev/ttyUSB2 or /dev/pts/6')
    parser.add_argument('--baud', '-b', type=int, default=4800)
    args, _ = parser.parse_known_args()


    rclpy.init()
    node = GPSDriver(port=args.port, baud=args.baud)
    try:
        rclpy.spin(node)
    finally:
        try:
            node.ser.close()
        except Exception:
            pass
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
