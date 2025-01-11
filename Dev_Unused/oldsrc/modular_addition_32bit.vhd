-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 21 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : Modular addition mod 2^32 32 bit
-- Input    : A (32 bit), B(32 bit)
-- Output   : Q (32 bit)
-- Note : Otomatis modular addition, tanpa harus pake mod
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity modular_addition_32bit is
    port (
        A, B : in std_logic_vector(31 downto 0);
        Q : out std_logic_vector(31 downto 0)
    );
end modular_addition_32bit;

architecture rtl of modular_addition_32bit is

signal sum : unsigned(31 downto 0) := (others => '0');

begin
process(A,B)
begin
    sum <= unsigned(A)+unsigned(B);
end process;

Q <= std_logic_vector(sum);
end architecture;