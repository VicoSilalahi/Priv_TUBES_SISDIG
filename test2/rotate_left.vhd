-- 6. Rotate Left by 1, 2, 3, 6, 9, 11
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rotate_left is
  Port (
      data_in : in STD_LOGIC_VECTOR (31 downto 0);
      sel : in INTEGER range 0 to 31;
      data_out : out STD_LOGIC_VECTOR (31 downto 0)
  );
end rotate_left;

architecture Behavioral of rotate_left is
begin
  process (data_in, sel)
  begin
      data_out <= data_in(31-sel downto 0) & data_in(31 downto 32-sel);
  end process;
end Behavioral;