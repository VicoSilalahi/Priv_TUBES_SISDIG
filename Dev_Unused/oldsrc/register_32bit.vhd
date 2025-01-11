-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 21 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : Register 32 bit
-- Input    : Clk, En, Res, D (32 bit)
-- Output   : Q (32 bit)
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_32bit is
    port (
        Clk, En, Res : in std_logic; -- Clk clock, En enable, Res reset
        D : in std_logic_vector (31 downto 0); -- Input data
        Q : out std_logic_vector (31 downto 0) -- Output data
    );
end register_32bit;

architecture behavior of register_32bit is

signal temp_data : std_logic_vector (31 downto 0) := (others => '0'); -- sinyal untuk menyimpan data

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