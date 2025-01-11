library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg.all;

entity keyschedule_precompute is
  port (
    -- clk   : in std_logic;
    -- reset : in std_logic;
    K     : in std_logic_vector(127 downto 0);
    K_precomputed : out arr_out(0 to 23)
  );
end entity;

architecture rtl of keyschedule_precompute is

component keyschedule is
  port (
    K    : in std_logic_vector(127 downto 0);
    nr   : in integer range 0 to 23;
    K_nr : out std_logic_vector(191 downto 0)
  );
end component;

begin

  KEYSCHEDULEROUNDS: for i in 0 to 23 generate
    keyschedule_i: keyschedule
      port map (
        K => K,
        nr => i,
        K_nr => K_precomputed(i)
      );
    end generate;

end architecture;