library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;


entity keyschedule_precompute_tb is
end;

architecture bench of keyschedule_precompute_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  -- Ports
  -- signal clk : std_logic;
  -- signal reset : std_logic;
  signal K : std_logic_vector(127 downto 0);
  signal K_precomputed : arr_out(0 to 23);
begin

  keyschedule_precompute_inst : entity work.keyschedule_precompute
  port map (
    -- clk => clk,
    -- reset => reset,
    K => K,
    K_precomputed => K_precomputed
  );
-- clk <= not clk after clk_period/2;

  stim_proc : process
  begin
    K <= x"0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    wait for clk_period;
  end process;

end;