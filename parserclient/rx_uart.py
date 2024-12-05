import serial

def receive_128bit_data(serial_port, baud_rate, num_blocks):
    try:
        # Open the serial port
        with serial.Serial(port=serial_port, baudrate=baud_rate, timeout=1) as ser:
            received_blocks = []

            for i in range(num_blocks):
                # Read 16 bytes (128 bits) for each block
                block = ser.read(16)
                
                if len(block) < 16:
                    print(f"Received incomplete block {i + 1}: {block.hex()} ({len(block)} bytes)")
                else:
                    print(f"Received block {i + 1}: {block.hex()}")
                
                received_blocks.append(block)
        
        print("All blocks received.")
        return received_blocks

    except serial.SerialException as e:
        print(f"Serial communication error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example Usage
if __name__ == "__main__":
    # Define the serial port and baud rate
    serial_port = "COM3"  # Replace with your port (e.g., "/dev/ttyUSB0" on Linux)
    baud_rate = 9600      # Match the FPGA's UART settings

    # Define the number of blocks to receive
    num_blocks = 3

    received_blocks = receive_128bit_data(serial_port, baud_rate, num_blocks)
