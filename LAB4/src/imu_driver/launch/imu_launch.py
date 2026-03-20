from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration


def generate_launch_description():
    port_arg = DeclareLaunchArgument(
        'port',
        default_value='/dev/ttyUSB0',
        description='Serial port for the VectorNav IMU'
    )

    imu_node = Node(
        package='imu_driver',
        executable='imu_driver',
        name='imu_driver',
        arguments=[LaunchConfiguration('port')],
        output='screen'
    )

    return LaunchDescription([
        port_arg,
        imu_node,
    ])