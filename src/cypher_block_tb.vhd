
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cypher_block_tb is
end;

architecture bench of cypher_block_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  -- Ports
  signal Plaintext : std_logic_vector(127 downto 0);
  signal Master_Key : std_logic_vector(127 downto 0);
  signal Start : std_logic;
  signal Stop : std_logic;
  signal Clock : std_logic;
  signal Ciphertext : std_logic_vector(127 downto 0);
begin

  cypher_block_inst : entity work.cypher_block
  port map (
    Plaintext => Plaintext,
    Master_Key => Master_Key,
    Start => Start,
    Stop => Stop,
    Clock => Clock,
    Ciphertext => Ciphertext
  );
-- clk <= not clk after clk_period/2;

end;