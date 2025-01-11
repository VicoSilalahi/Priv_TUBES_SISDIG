-- Deskripsi
-- Fungsi   : Register 128 bit
-- Input    : Clk, En, Res, D (128 bit)
-- Output   : Q (128 bit)
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_128bit is
    port (
        Clk, En, Res : in std_logic; -- Clk clock, En enable, Res reset
        D : in std_logic_vector (127 downto 0); -- Input data
        Q : out std_logic_vector (127 downto 0) -- Output data
    );
end register_128bit;

architecture behavior of register_128bit is

signal temp_data : std_logic_vector (127 downto 0) := (others => '0'); -- sinyal untuk menyimpan data

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if Res = '1' then -- Reset merupakan active high
                temp_data <= (others => '0');
            else -- Jika reset = '0'
                if En = '1' then -- Jika enable
                    temp_data <= D;
                end if; 
            end if;
        end if;
    end process;

    Q <= temp_data; -- Sambungkan output dengan sinyal temp
end architecture;