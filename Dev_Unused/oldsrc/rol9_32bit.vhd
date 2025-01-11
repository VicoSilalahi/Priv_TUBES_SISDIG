-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 23 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : Rotate left 9 times
-- Input    : A (input data) (32 bit)
-- Output   : Q (output data) (32 bit)
-- Note     : 
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rol9_32bit is
    port (
        A : in std_logic_vector(31 downto 0); -- Input
        Q : out std_logic_vector(31 downto 0)
    );
end rol9_32bit;

architecture behavior of rol9_32bit is

signal temp : unsigned(31 downto 0) := (others => '0'); -- Mengubah menjadi unsigned, karena library hanya dapat digunakan pada unsigned

begin
process(A)
begin
    temp <= unsigned(A) rol 9; -- ROL (rotate left) 9 kali
end process;
Q <= std_logic_vector(temp);
end architecture;