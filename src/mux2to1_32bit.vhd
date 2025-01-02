-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 21 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : MUX 2 to 1 32 bit
-- Input    : A_0 (32 bit), B_1 (32 bit), Sel
-- Output   : Data (32 bit)
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2to1_32bit is
    port (
        A_0 : in std_logic_vector(31 downto 0); -- Input saat selector '0'
        B_1 : in std_logic_vector(31 downto 0); -- Input saat selector '1'
        Sel : in std_logic; -- Selector MUX
        Data : out std_logic_vector(31 downto 0) -- Output data
    );
end mux2to1_32bit;

architecture rtl of mux2to1_32bit is
signal temp_data : std_logic_vector(31 downto 0) := (others => '0'); -- Sinyal untuk dijadikan initial value pada output
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