-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 21 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : Bitwise XOR 32 bit
-- Input    : A (32 bit), B(32 bit)
-- Output   : Q (32 bit)
-- Note : aman, bisa langsung bitwise XOR dengan cara ini
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bitwise_xor_32bit is
    port (
        A, B : in std_logic_vector(31 downto 0); -- data yang ingin di-bitwise XOR
        Q : out std_logic_vector(31 downto 0) -- output
    );
end bitwise_xor_32bit;

architecture behavior of bitwise_xor_32bit is

begin

Q <= A xor B;

end architecture;