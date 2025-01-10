
import threading
import serial
import time

# Shared stop flag for threads
stop_event = threading.Event()

def transmit(serial_port):
    """Thread for transmitting data."""
    while not stop_event.is_set():
        data = input("Enter data to send (or Ctrl+C to quit): ")
        serial_port.write(data.encode())
        print(f"Sent: {data}")
        time.sleep(0.1)

def receive(serial_port):
    """Thread for receiving data."""
    while not stop_event.is_set():
        if serial_port.in_waiting > 0:
            data = serial_port.read(serial_port.in_waiting)
            print(f"Received: {data}")
        time.sleep(0.1)

def main():
    try:
        # Open the serial port
        serial_port = serial.Serial('COM6', 9600, timeout=1)
        
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

