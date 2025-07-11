#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from std_msgs.msg import ColorRGBA
from color_sensor.tcs34725 import TCS34725
from color_sensor.tca9548a import TCS9548A

class ColorPublisher(Node):

    def __init__(self, tca9548_channel, integration_time=0x00):
        super().__init__('color_publisher')
        self.tca9548 = TCS9548A(1, 0x70)
        self.tca9548_channel = tca9548_channel
        self.tca9548.enable_channel(tca9548_channel)
        self.get_logger().info(f'Enabled TCA9548A channel {tca9548_channel}')
        # Initialize TCS34725 sensor with the specified integration time
        self.TCS34725 = TCS34725(1, 0x29)
        self.TCS34725.change_integration_time(integration_time)
        self.TCS34725.change_gain(0x02)  # Set gain to 16x
        self.TCS34725.enable()
        node_name = f'color_publisher_{tca9548_channel}'
        self.publisher_ = self.create_publisher(ColorRGBA, node_name, 10)
        timer_period = 0.1  # seconds
        self.timer = self.create_timer(timer_period, self.timer_callback)
        self.get_logger().info('Color Publisher Node has been started.')

    def timer_callback(self):
        self.tca9548.enable_channel(self.tca9548_channel)
        msg = ColorRGBA()
        c, r, g, b = self.TCS34725.read_colors()
        msg.r = r / 65535.0  # Normalize to [0, 1]
        msg.g = g / 65535.0  # Normalize to [0, 1]
        msg.b = b / 65535.0  # Normalize to [0, 1]
        msg.a = c / 65535.0  # Normalize to [0, 1]
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: R:{msg.r} G:{msg.g} B:{msg.b} C:{msg.a}')

    def __del__(self):
        self.TCS34725.disable()
        self.get_logger().info('Color Publisher Node has been shut down.')
    
def main(args=None):
    rclpy.init(args=args)
    color_publisher_1 = ColorPublisher(0, 0xFC)
    #color_publisher_2 = ColorPublisher(1, 0xFC)
    
    executors = rclpy.executors.SingleThreadedExecutor()
    executors.add_node(color_publisher_1)
    #executors.add_node(color_publisher_2)
    try:
        executors.spin()
    except KeyboardInterrupt:
        pass
    finally:
        color_publisher_1.destroy_node()
        #color_publisher_2.destroy_node()
        rclpy.shutdown()
        print("Color Publisher Nodes have been shut down.")

if __name__ == '__main__':
    main()
