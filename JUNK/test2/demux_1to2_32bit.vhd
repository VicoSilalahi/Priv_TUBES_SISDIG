-- 2. 1 to 2 DEMUX of 32-bit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity demux_1to2_32bit is
  Port (
      sel : in STD_LOGIC;
      a : in STD_LOGIC_VECTOR (31 downto 0);
      y0, y1 : out STD_LOGIC_VECTOR (31 downto 0)
  );
end demux_1to2_32bit;

architecture Behavioral of demux_1to2_32bit is
begin
  y0 <= a when sel = '0' else (others => '0');
  y1 <= a when sel = '1' else (others => '0');
end Behavioral;