-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 27 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : Rotate left 2 times
-- Input    : A (input data) (32 bit)
-- Output   : Q (output data) (32 bit)
-- Note     : 
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rol2_32bit is
    port (
        A : in std_logic_vector(31 downto 0); -- Input
        Q : out std_logic_vector(31 downto 0)
    );
end rol2_32bit;

architecture behavior of rol2_32bit is

signal temp : unsigned(31 downto 0) := (others => '0'); -- Mengubah menjadi unsigned, karena library hanya dapat digunakan pada unsigned

begin
process(A)
begin
    temp <= unsigned(A) rol 2; -- ROL (rotate left) 2 kali
end process;
Q <= std_logic_vector(temp);
end architecture;