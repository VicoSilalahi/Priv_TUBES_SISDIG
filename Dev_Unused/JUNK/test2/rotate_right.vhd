-- 7. Rotate Right by 3, 5
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rotate_right is
  Port (
      data_in : in STD_LOGIC_VECTOR (31 downto 0);
      sel : in INTEGER range 0 to 31;
      data_out : out STD_LOGIC_VECTOR (31 downto 0)
  );
end rotate_right;

architecture Behavioral of rotate_right is
begin
  process (data_in, sel)
  begin
      data_out <= data_in(sel-1 downto 0) & data_in(31 downto sel);
  end process;
end Behavioral;
