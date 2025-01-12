library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity counter_24 is
  port (
    clk    : in std_logic;
    enable : in std_logic;
    reset  : in std_logic;
    isdone : out std_logic
  );
end entity;

architecture rtl of counter_24 is
  signal internal_counter : unsigned(4 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        internal_counter <= (others => '0');
      elsif enable = '1' then
        internal_counter <= internal_counter + 1; -- Menggunakan Unsigned supaya dapat diaddition
      end if;
    end if;
  end process;

  isdone <= '1' when internal_counter = 23 else
    '0';
end architecture;