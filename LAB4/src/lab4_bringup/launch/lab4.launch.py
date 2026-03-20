from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    gps_port_arg = DeclareLaunchArgument(
        'gps_port',
        default_value='/dev/ttyACM0',
        description='Serial port for the GPS (e.g. /dev/ttyACM0)'
    )

    imu_port_arg = DeclareLaunchArgument(
        'imu_port',
        default_value='/dev/ttyUSB0',
        description='Serial port for the VectorNav IMU (e.g. /dev/ttyUSB0)'
    )

    gps_node = Node(
        package='gps_driver',
        executable='driver',
        name='gps_driver',
        output='screen',
        arguments=['--port', LaunchConfiguration('gps_port')],
    )

    imu_node = Node(
        package='imu_driver',
        executable='imu_driver',
        name='imu_driver',
        output='screen',
        arguments=[LaunchConfiguration('imu_port')],
    )

    return LaunchDescription([
        gps_port_arg,
        imu_port_arg,
        gps_node,
        imu_node,
    ])
