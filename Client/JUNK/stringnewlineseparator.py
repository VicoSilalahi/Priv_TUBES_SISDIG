def separate_string_in_file(filename, chunk_size=32):
  """
  Reads a string from a file, separates it into chunks of specified size, 
  and writes each chunk to a new line in the same file.

  Args:
    filename: The name of the file to read and write to.
    chunk_size: The desired size of each chunk.
  """

  try:
    with open(filename, 'r+') as file:
      original_string = file.read().strip()  # Read and strip the string

      chunks = []
      for i in range(0, len(original_string), chunk_size):
        chunk = original_string[i:i + chunk_size]
        chunks.append(chunk)

      # Overwrite the file with the separated chunks
      file.seek(0)  # Move the file pointer to the beginning
      file.truncate(0)  # Clear the existing content
      file.write('\n'.join(chunks))

  except FileNotFoundError:
    print(f"Error: File '{filename}' not found.")

# Example usage
filename = "input.txt"  # Replace with the actual filename
separate_string_in_file(filename, chunk_size=32)