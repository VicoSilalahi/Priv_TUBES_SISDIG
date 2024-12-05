-- 4. 32-bit XOR
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity xor_32bit is
  Port (
      a, b : in STD_LOGIC_VECTOR (31 downto 0);
      y : out STD_LOGIC_VECTOR (31 downto 0)
  );
end xor_32bit;

architecture Behavioral of xor_32bit is
begin
  y <= a xor b;
end Behavioral;