def hex_to_bytes_string(hex_string):
  """
  Separates a hex string into individual bytes in the format "0xXX" and 
  concatenates them into a single string.

  Args:
    hex_string: The hex string to be separated.

  Returns:
    A string containing the separated bytes in the format "0xXX 0xYY ...".
  """

  if len(hex_string) % 2 != 0:
    raise ValueError("Invalid hex string: must have an even number of characters.")

  bytes_list = []
  for i in range(0, len(hex_string), 2):
    byte = hex_string[i:i+2]
    bytes_list.append("0x" + byte)

  return " ".join(bytes_list)

# Example usage

while(True):
  hex_in = input()
  print(hex_to_bytes_string(hex_in))