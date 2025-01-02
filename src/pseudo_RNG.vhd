library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pseudo_RNG is
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    enable  : in  std_logic;
    random_number : out std_logic_vector(127 downto 0)
  );
end entity pseudo_RNG;

architecture behavior of pseudo_RNG is
  signal lfsr : std_logic_vector(127 downto 0) := (others => '1'); -- Initialize with a non-zero value
begin
  process(clk, reset)
  begin
    if reset = '1' then
      lfsr <= (others => '1'); -- Reset to a non-zero value
    elsif rising_edge(clk) then
      if enable = '1' then
        lfsr <= lfsr(126 downto 0) & (lfsr(127) xor lfsr(126) xor lfsr(101) xor lfsr(99));
      end if;
    end if;
  end process;

  random_number <= lfsr;
end architecture behavior;
