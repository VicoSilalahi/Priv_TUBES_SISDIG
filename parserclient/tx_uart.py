import serial

def send_128bit_data(serial_port, baud_rate, data_blocks):
    try:
        # Open the serial port
        with serial.Serial(port=serial_port, baudrate=baud_rate, timeout=1) as ser:
            for i, block in enumerate(data_blocks):
                # Ensure the block is exactly 16 bytes (128 bits)
                if len(block) != 16:
                    raise ValueError(f"Block {i + 1} must be 16 bytes long, but got {len(block)} bytes.")
                
                # Send the data block
                ser.write(block)
                print(f"Sent block {i + 1}: {block.hex()}")
        
        print("All blocks sent successfully.")
    
    except serial.SerialException as e:
        print(f"Serial communication error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example Usage
if __name__ == "__main__":
    # Define the serial port and baud rate
    serial_port = "COM3"  # Replace with your port (e.g., "/dev/ttyUSB0" on Linux)
    baud_rate = 9600      # Match the FPGA's UART settings

    # Define 128-bit data blocks (each block is 16 bytes)
    data_blocks = [
        bytes.fromhex("4e616d652c4167652c4c6f636174696f"),  # Example block 1
        bytes.fromhex("6e0a416c6963652c33302c4e65772059"),  # Example block 2
        bytes.fromhex("6f726b0a426f622c32352c53616e2046")   # Example block 3
    ]

    send_128bit_data(serial_port, baud_rate, data_blocks)
