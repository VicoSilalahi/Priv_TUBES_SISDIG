import threading
import serial
import time
import binascii

# Shared stop flag for threads
stop_event = threading.Event()

def validate_hex_input(data):
    """Validate that the input is a 128-bit hexadecimal string."""
    if len(data) != 32:
        print("Error: Input must be exactly 32 hexadecimal characters (128 bits).")
        return False
    if not all(c in "0123456789abcdefABCDEF" for c in data):
        print("Error: Input must only contain valid hexadecimal characters (0-9, a-f, A-F).")
        return False
    return True

def transmit(serial_port):
    """Thread for transmitting data."""
    while not stop_event.is_set():
        try:
            data = input("Enter 128-bit HEX data to send (32 characters): ").strip()
            if validate_hex_input(data):
                # Convert hex string to bytes and send
                serial_port.write(bytes.fromhex(data))
                print(f"Sent: {data}")
        except EOFError:
            # Handle Ctrl+D gracefully in some environments
            stop_event.set()
        time.sleep(0.1)

def receive(serial_port):
    """Thread for receiving data."""
    while not stop_event.is_set():
        if serial_port.in_waiting > 0:
            data = serial_port.read(serial_port.in_waiting)
            # Convert data to hexadecimal format
            hex_data = " ".join(f"{byte:02X}" for byte in data)
            print(f"Received: {hex_data}")
        time.sleep(0.1)

def main():
    try:
        # Open the serial port
        serial_port = serial.Serial('COM3', 9600, timeout=1)
        
        # Create threads
        tx_thread = threading.Thread(target=transmit, args=(serial_port,))
        rx_thread = threading.Thread(target=receive, args=(serial_port,))

        # Make threads daemon
        tx_thread.daemon = True
        rx_thread.daemon = True

        # Start threads
        tx_thread.start()
        rx_thread.start()

        # Keep the main program running
        while not stop_event.is_set():
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nStopping...")
        stop_event.set()  # Signal threads to stop

    finally:
        # Close the serial port
        serial_port.close()
        print("Serial port closed. Goodbye!")

if __name__ == "__main__":
    main()
