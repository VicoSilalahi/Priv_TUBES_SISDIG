-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 24 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : Counter sampai dengan 24. Jika sudah 24, maka akan menandakan enkripsi selesai
-- Input    : En_Counter, Res_Counter, Clk
-- Output   : Count (udh berapa count nya), is_done (akan '1' jika sudah 24)
-- Note     : 
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_24_32bit is
    port (
        Clk, En_Counter, Res_Counter : in std_logic;
        Count : out std_logic_vector(4 downto 0);
        is_done : out std_logic
    );
end counter_24_32bit;

architecture rtl of counter_24_32bit is

signal count_temp : unsigned(4 downto 0) := (others => '0');

begin
process(Clk)
begin
    if rising_edge(Clk) then
        if Res_Counter = '1' then -- Reset active high
            count_temp <= (others => '0'); -- Count menjadi 0, otomatis is_done juga menjadi 0
        elsif En_Counter = '1' then
            count_temp <= count_temp + 1; -- Tambah 1 saat enable dan clock naik
        end if;
    end if;
end process;

Count <= std_logic_vector(count_temp); -- Memasukkan sinyal count dan mengubah menjadi biner
is_done <= count_temp(4) and count_temp(2) and count_temp(1) and count_temp(0); -- Akan satu jika 23, Dilakukan seperti ini agar tidak delay (i from 0 to 24, 24 ga termasuk ngab)

end architecture;