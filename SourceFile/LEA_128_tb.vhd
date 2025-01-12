------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LEA_128_tb is
end;

architecture bench of LEA_128_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  -- Ports
  signal i_clk : std_logic := '0';
  signal i_start : std_logic;
  signal i_reset : std_logic;
  signal i_plaintext : std_logic_vector(127 downto 0);
  signal i_masterkey : std_logic_vector(127 downto 0);
  signal o_ciphertext : std_logic_vector(127 downto 0);
  signal o_isdone : std_logic;
begin

  LEA_128_inst : entity work.LEA_128
  port map (
    i_clk => i_clk,
    i_start => i_start,
    i_reset => i_reset,
    i_plaintext => i_plaintext,
    i_masterkey => i_masterkey,
    o_ciphertext => o_ciphertext,
    o_isdone => o_isdone
  );
i_clk <= not i_clk after clk_period/2;


process
begin
  i_plaintext <= "00010000000100010001001000010011000101000001010100010110000101110001100000011001000110100001101100011100000111010001111000011111";
  i_masterkey <= "00001111000111100010110100111100010010110101101001101001011110001000011110010110101001011011010011000011110100101110000111110000";
  i_start <= '0';
  i_reset <= '0';
  wait for 2*clk_period;
  i_start<='1';
  wait for 2*clk_period;
  i_start<='0';
  wait for 50*clk_period;

  assert false
    report "Simulation Completed"
    severity failure;
  
end process;

end;