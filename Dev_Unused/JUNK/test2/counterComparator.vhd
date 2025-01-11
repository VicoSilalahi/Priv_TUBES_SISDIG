library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity counterComparator is
  port (
    clk    : in std_logic; -- Clock signal
    resCTR : in std_logic; -- Reset signal (active high)
    enCTR  : in std_logic; -- Enable signal
    isDone : out std_logic -- Output signal, high when counter hits 23
  );
end counterComparator;

architecture Behavioral of counterComparator is
  signal counter : integer range 0 to 23 := 0; -- Counter signal
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if resCTR = '1' then
        counter <= 0; -- Reset the counter
      elsif enCTR = '1' then
        if counter = 23 then
          counter <= 0; -- Reset counter after reaching 23
        else
          counter <= counter + 1; -- Increment counter
        end if;
      end if;
    end if;
  end process;

  -- Set isDone to '1' when counter is 23, '0' otherwise
  isDone <= '1' when counter = 23 else
    '0';
end Behavioral;
