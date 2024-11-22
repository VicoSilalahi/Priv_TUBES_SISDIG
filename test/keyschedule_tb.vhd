library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyschedule_tb is
end;

architecture bench of keyschedule_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  -- Ports
  signal K    : std_logic_vector(127 downto 0);
  signal nr   : integer range 0 to 23;
  signal K_nr : std_logic_vector(191 downto 0);
begin

  keyschedule_inst : entity work.keyschedule
    port map
    (
      K    => K,
      nr   => nr,
      K_nr => K_nr
    );
  -- clk <= not clk after clk_period/2;
  stim : process
  begin
    K  <= x"0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    nr <= 0;
    wait for 5 * clk_period;
  end process;
end;