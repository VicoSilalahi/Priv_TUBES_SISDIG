------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB
--
-- Didasarkan dari kode milik Adrian Sami Pratama - 13223074
-- Dibuat ulang oleh Vico A.C. Silalahi - 13223067
--
------------------------------------------------------------------------------------------------------------------------
-- Deskripsi
-- Multiplexer 2 input 1 output dengan besar data 32-bit
--
------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2to1_32bit is
  port (
    i_A : in std_logic_vector(31 downto 0);
    i_B : in std_logic_vector(31 downto 0);
    i_S : in std_logic;
    o_C : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of mux2to1_32bit is
  signal temp_data : std_logic_vector(31 downto 0) := (others => '0');
begin
  process (i_A, i_B, i_S)
  begin
    if i_S = '0' then
      temp_data <= i_A;
    else
      temp_data <= i_B;
    end if;
  end process;

  o_C <= temp_data;
end architecture;