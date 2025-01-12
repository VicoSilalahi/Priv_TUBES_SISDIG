import os
import binascii
import serial
import threading
import time

BdRt = 9600
ComLoc = "COM3"

# Function for converting CSV to HEX
def csv_to_hex():
    file_name = input("Input the file name: ")
    try:
        with open(file_name, 'r') as csv_file:
            data = csv_file.read().replace('\n', '').replace(',', '').strip()
        
        # Calculate padding for 128-bit alignment
        bit_length = len(data) * 8  # Assuming 1 byte per character
        padding_bits = (128 - (bit_length % 128)) % 128
        padded_data = data + ('\x00' * (padding_bits // 8))

        # Split into 128-bit chunks and convert to HEX
        hex_output = []
        for i in range(0, len(padded_data), 16):  # 16 bytes = 128 bits
            chunk = padded_data[i:i+16]
            hex_chunk = binascii.hexlify(chunk.encode()).decode()
            hex_output.append(hex_chunk.upper())
        
        with open("output_hex.txt", 'w') as output_file:
            output_file.write("\n".join(hex_output))
        print("HEX conversion completed. Saved to 'output_hex.txt'.")
    except FileNotFoundError:
        print("Error: File not found.")
    except Exception as e:
        print(f"Error: {e}")

# UART Transmit and Receive
def uart_transmit_receive():
    try:
        ser = serial.Serial(ComLoc, baudrate=BdRt, timeout=1)
        print(f"Connected to {ComLoc}.")
        
        def transmit_data():
            nonlocal current_line
            while True:
                user_input = input("Press Enter to transmit next line or type 'exit' to quit: ").strip()
                if user_input.lower() == "exit":
                    ser.close()
                    print("Transmission ended.")
                    break
                if current_line < len(output_lines):
                    line_to_send = output_lines[current_line].strip()
                    ser.write(bytes.fromhex(line_to_send))
                    print(f"Transmitted: {line_to_send}")
                    current_line += 1
                    time.sleep(1)  # Add a 1-second delay between transmissions
                else:
                    print("No more lines to send. Exiting...")
                    ser.close()
                    break
        
        def receive_data():
            with open("capture_hex.txt", 'w') as capture_file:
                while ser.is_open:
                    try:
                        received_data = ser.read(16)  # 16 bytes = 128 bits
                        if received_data:
                            hex_received = binascii.hexlify(received_data).decode().upper()
                            capture_file.write(hex_received + "\n")
                            capture_file.flush()  # Ensure data is written to disk immediately
                            print(f"Received: {hex_received}")
                        else:
                            time.sleep(0.05)  # Reduced sleep time for faster response
                    except Exception as e:
                        print(f"Error in receiving data: {e}")
                        break

        with open("output_hex.txt", 'r') as output_file:
            output_lines = output_file.readlines()

        current_line = 0
        master_key = input("Enter Masterkey (32 Hex): ")
        ser.write(bytes.fromhex(master_key.strip()))
        print(f"Masterkey transmitted: {master_key}")
        
        # Start threads for transmission and reception
        receive_thread = threading.Thread(target=receive_data, daemon=True)
        receive_thread.start()
        transmit_data()
    except FileNotFoundError:
        print("Error: 'output_hex.txt' not found.")
    except serial.SerialException as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"Error: {e}")

# UART Transmit, Receive Automatically After Each Response
def uart_transmit_receive_auto():
    try:
        ser = serial.Serial(ComLoc, baudrate=BdRt, timeout=1)
        print(f"Connected to {ComLoc}.")
        
        def transmit_data_auto():
            nonlocal current_line
            while current_line < len(output_lines):
                # Add delay after user presses Enter before transmitting next line
                time.sleep(0.0034)  # Add a 1-second delay between transmissions
                # Baudrate of 115200 will have
                # a transmit/receive time of (128 + 2*8*16) * (1/115200) = 0.00333333333333333333
                # And given a delay inside the FPGA: let's say 1000 clock of process of 50 Mhz Clock
                # 1000 * (1/50e6) = 2e-5 (less than 0.0001) (Only needs the transmit time to be rounded up a little)
                # Therefore the delay needs to be atleast 0.0034s

                # 128000 = 0.0031s -> 0.004s
                # 115200 = 0.0034s -> 0.004s
                # 57600 = 0.0067s -> 0.007s
                # 9600 = 0.041s -> 0.05s

                if (BdRt == 9600):
                    time.sleep(0.05)
                elif(BdRt == 57600):
                    time.sleep(0.007)
                elif(BdRt == 115200):
                    time.sleep(0.004)
                elif(BdRt == 128000):
                    time.sleep(0.004)
                else:
                    time.sleep(0.1)

                if current_line < len(output_lines):
                    line_to_send = output_lines[current_line].strip()
                    ser.write(bytes.fromhex(line_to_send))
                    print(f"Transmitted: {line_to_send}")
                    current_line += 1

        def receive_data():
            with open("capture_hex.txt", 'w') as capture_file:
                while ser.is_open:
                    try:
                        received_data = ser.read(16)  # 16 bytes = 128 bits
                        if received_data:
                            hex_received = binascii.hexlify(received_data).decode().upper()
                            capture_file.write(hex_received + "\n")
                            capture_file.flush()  # Ensure data is written to disk immediately
                            print(f"Received: {hex_received}")
                        else:
                            time.sleep(0.05)  # Reduced sleep time for faster response
                    except Exception as e:
                        print(f"Error in receiving data: {e}")
                        break

        with open("output_hex.txt", 'r') as output_file:
            output_lines = output_file.readlines()

        current_line = 0
        master_key = input("Enter Masterkey (32 Hex): ")
        ser.write(bytes.fromhex(master_key.strip()))
        print(f"Masterkey transmitted: {master_key}")

        # Wait for user to press Enter after masterkey is transmitted to start auto mode
        input("Press Enter to start automatic transmission after receiving data...")

        # Start threads for transmission and reception
        receive_thread = threading.Thread(target=receive_data, daemon=True)
        receive_thread.start()
        transmit_data_auto()
    except FileNotFoundError:
        print("Error: 'output_hex.txt' not found.")
    except serial.SerialException as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"Error: {e}")

# Main Menu
def main():
    while True:
        print("\nMain Menu:")
        print("1. CSV to HEX")
        print("2. UART Transmit and Receive")
        print("3. UART Transmit and Receive Automatically After Each Response")
        print("4. Exit")
        choice = input("Choose an option: ")
        
        if choice == "1":
            csv_to_hex()
        elif choice == "2":
            uart_transmit_receive()
        elif choice == "3":
            uart_transmit_receive_auto()
        elif choice == "4":
            print("Exiting program. Goodbye!")
            break
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nProgram exited via keyboard interrupt. Goodbye!")
