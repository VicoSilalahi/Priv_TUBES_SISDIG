-- 1. 2 to 1 MUX of 32-bit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mux_2to1_32bit is
    Port (
        sel : in STD_LOGIC;
        a, b : in STD_LOGIC_VECTOR (31 downto 0);
        y : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mux_2to1_32bit;

architecture Behavioral of mux_2to1_32bit is
begin
    y <= a when sel = '0' else b;
end Behavioral;