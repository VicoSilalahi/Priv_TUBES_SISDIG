import serial
import threading

# Configure the serial port
ser = serial.Serial(
    port='COM8',  # Replace with your port name
    baudrate=9600,
    timeout=1
)

# Function to transmit data
def transmit_data():
    while True:
        data_to_send = input("Enter ASCII data to send: ")
        ser.write(data_to_send.encode())  # Transmit ASCII data
        print(f"Sent: {data_to_send}")

# Function to receive data
def receive_data():
    while True:
        if ser.in_waiting > 0:
            received_data = ser.read(ser.in_waiting)  # Read all available bytes
            binary_output = ' '.join(format(byte, '08b') for byte in received_data)
            print(f"Received (binary): {binary_output}")

# Create threads for transmission and reception
transmit_thread = threading.Thread(target=transmit_data)
receive_thread = threading.Thread(target=receive_data)

# Start the threads
transmit_thread.start()
receive_thread.start()

# Ensure the threads run indefinitely
transmit_thread.join()
receive_thread.join()

