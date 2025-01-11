# python script.py --input_dir /path/to/plaintext_files \
#                  --key_file /path/to/key.txt \
#                  --output_dir /path/to/ciphertext_files \
#                  --serial_port COM3 \
#                  --baud_rate 9600


import os
import serial
import argparse


def send_key(serial_port, key):
    """
    Sends the encryption key to the FPGA over UART.
    """
    try:
        print("Sending encryption key...")
        serial_port.write(key)
        print(f"Key sent: {key.hex()}")
    except Exception as e:
        print(f"Error sending key: {e}")


def send_block(serial_port, block):
    """
    Sends a 128-bit (16-byte) plaintext block to the FPGA.
    """
    try:
        print(f"Sending plaintext block: {block.hex()}")
        serial_port.write(block)
    except Exception as e:
        print(f"Error sending block: {e}")


def receive_message(serial_port, expected_bytes=16):
    """
    Receives a message from the FPGA. Waits for `expected_bytes` length.
    """
    try:
        response = serial_port.read(expected_bytes)
        if len(response) < expected_bytes:
            print(f"Received incomplete message: {response.hex()} ({len(response)} bytes)")
        else:
            print(f"Received message: {response.hex()}")
        return response
    except Exception as e:
        print(f"Error receiving message: {e}")
        return None


def process_plaintext_file(file_path):
    """
    Reads the plaintext from a file and converts it into 128-bit (16-byte) blocks.
    Pads the last block with zero bytes if necessary.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            content = file.read()
        # Convert the content to bytes
        content_bytes = content.encode("utf-8")
        # Split into 128-bit (16-byte) blocks
        blocks = [
            content_bytes[i:i + 16]
            for i in range(0, len(content_bytes), 16)
        ]
        # Pad the last block if necessary
        if len(blocks[-1]) < 16:
            blocks[-1] = blocks[-1].ljust(16, b'\x00')
        return blocks
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")
        return []


def main():
    # Set up argparse for input/output directories and key file
    parser = argparse.ArgumentParser(description="Send plaintext files to FPGA and receive ciphertext.")
    parser.add_argument(
        "--input_dir",
        type=str,
        required=True,
        help="Directory containing plaintext .txt files to be sent."
    )
    parser.add_argument(
        "--key_file",
        type=str,
        required=True,
        help="Path to a .txt file containing the 128-bit encryption key (as hex)."
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        required=True,
        help="Directory to save the ciphertext .txt files."
    )
    parser.add_argument(
        "--serial_port",
        type=str,
        required=True,
        help="Serial port for UART communication (e.g., COM3 or /dev/ttyUSB0)."
    )
    parser.add_argument(
        "--baud_rate",
        type=int,
        default=9600,
        help="Baud rate for UART communication (default: 9600)."
    )
    args = parser.parse_args()

    # Load the key from the key file
    try:
        with open(args.key_file, "r", encoding="utf-8") as key_file:
            key_hex = key_file.read().strip()
        key = bytes.fromhex(key_hex)
    except Exception as e:
        print(f"Error loading key from {args.key_file}: {e}")
        return

    # Create output directory if it doesn't exist
    os.makedirs(args.output_dir, exist_ok=True)

    # Process plaintext files in the input directory
    plaintext_files = [
        os.path.join(args.input_dir, f)
        for f in os.listdir(args.input_dir)
        if f.endswith(".txt")
    ]
    if not plaintext_files:
        print(f"No .txt files found in directory {args.input_dir}.")
        return

    try:
        # Open the serial port
        with serial.Serial(port=args.serial_port, baudrate=args.baud_rate, timeout=1) as ser:
            # Step 1: Send the encryption key
            send_key(ser, key)

            # Step 2: Wait for the FPGA to send a blank message (instruction to start)
            print("Waiting for FPGA blank message...")
            blank_message = receive_message(ser, expected_bytes=1)
            if blank_message != b'\x00':
                print("Unexpected message from FPGA, aborting.")
                return

            print("FPGA ready to receive plaintext.")

            # Step 3: Send each plaintext file and save the corresponding ciphertext
            for file_path in plaintext_files:
                print(f"Processing file: {file_path}")
                blocks = process_plaintext_file(file_path)

                for block_index, block in enumerate(blocks):
                    # Send the next plaintext block
                    send_block(ser, block)

                    # Wait for the ciphertext response from the FPGA
                    print("Waiting for ciphertext from FPGA...")
                    ciphertext = receive_message(ser, expected_bytes=16)
                    if ciphertext is None:
                        print("Failed to receive ciphertext, aborting.")
                        return

                    # Save the ciphertext to the output directory
                    output_file_name = f"{os.path.basename(file_path)}_block_{block_index + 1}.txt"
                    output_file_path = os.path.join(args.output_dir, output_file_name)
                    with open(output_file_path, "w", encoding="utf-8") as output_file:
                        output_file.write(ciphertext.hex())
                    print(f"Ciphertext saved to: {output_file_path}")

            print("All plaintext files processed successfully.")

    except serial.SerialException as e:
        print(f"Serial communication error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")


if __name__ == "__main__":
    main()
