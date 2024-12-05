-- 5. 32-bit Addition Modulo
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity add_modulo_32bit is
    Port (
        a, b : in STD_LOGIC_VECTOR (31 downto 0);
        y : out STD_LOGIC_VECTOR (31 downto 0)
    );
end add_modulo_32bit;

architecture Behavioral of add_modulo_32bit is
    -- signal sum : STD_LOGIC_VECTOR (32 downto 0);
    signal modulo_result : STD_LOGIC_VECTOR (31 downto 0);
begin
    modulo_result <= std_logic_vector(unsigned(a) + unsigned(b));
    y <= modulo_result;
end Behavioral;