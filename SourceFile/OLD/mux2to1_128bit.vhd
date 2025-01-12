-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2to1_128bit is
    port (
        A_0 : in std_logic_vector(127 downto 0); -- Input saat selector '0'
        B_1 : in std_logic_vector(127 downto 0); -- Input saat selector '1'
        Sel : in std_logic; -- Selector MUX
        Data : out std_logic_vector(127 downto 0) -- Output data
    );
end mux2to1_128bit;

architecture rtl of mux2to1_128bit is
signal temp_data : std_logic_vector(127 downto 0) := (others => '0'); -- Sinyal untuk dijadikan initial value pada output
begin
process(A_0, B_1, Sel)
begin
    if Sel = '0' then -- Jika selector '0', maka memilih A
        temp_data <= A_0;
    else -- Jika selector '1', maka memilih B_1
        temp_data <= B_1;
    end if;
end process;

Data <= temp_data; -- Sambungkan sinyal temp ke output
end architecture;