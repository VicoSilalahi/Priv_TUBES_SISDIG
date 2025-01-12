------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB
--
------------------------------------------------------------------------------------------------------------------------
-- Deskripsi
-- Multiplexer 2 input 1 output dengan besar data 128-bit
--
------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2to1_128bit is
  port (
    i_A : in std_logic_vector(127 downto 0);
    i_B : in std_logic_vector(127 downto 0);
    i_S : in std_logic;
    o_C : out std_logic_vector(127 downto 0)
  );
end entity;

architecture rtl of mux2to1_128bit is
begin
  process (i_S)
  begin
    if i_S = '0' then
      o_C <= i_A;
    else
      o_C <= i_B;
    end if;
  end process;
end architecture;