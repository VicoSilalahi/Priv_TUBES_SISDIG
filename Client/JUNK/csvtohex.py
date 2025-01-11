import math

def csv_to_hex_split(csv_file, output_prefix):
    try:
        # Open the CSV file and read its content
        with open(csv_file, 'r', encoding='utf-8') as csvfile:
            content = csvfile.read()
        
        # Convert each character to its hexadecimal representation
        hex_representation = ''.join(f"{ord(char):02x}" for char in content)
        
        # Calculate the block size (128 bits = 32 hex characters)
        block_size = 32
        
        # Determine the number of blocks needed
        num_blocks = math.ceil(len(hex_representation) / block_size)
        
        # Split the hex output into 128-bit blocks and write to separate files
        for i in range(num_blocks):
            # Extract the current block
            start = i * block_size
            end = start + block_size
            block = hex_representation[start:end]
            
            # Pad the last block with zeros if necessary
            if len(block) < block_size:
                block = block.ljust(block_size, '0')
            
            # Write the block to a separate text file
            output_file = f"{output_prefix}_block_{i + 1}.txt"
            with open(output_file, 'w', encoding='utf-8') as txtfile:
                txtfile.write(block)
            
            print(f"Written block {i + 1} to {output_file}")
        
        print("Hexadecimal splitting completed.")
    
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
# Replace 'input.csv' with the path to your CSV file
# Replace 'output_prefix' with the desired prefix for output files
csv_to_hex_split('input.csv', 'output')
