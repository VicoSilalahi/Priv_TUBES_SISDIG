library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cypher_block_tb is
end;

architecture bench of cypher_block_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  
  -- Ports
  signal Plaintext  : std_logic_vector(127 downto 0);
  signal Master_Key : std_logic_vector(127 downto 0);
  signal Start      : std_logic := '0';
  signal Stop       : std_logic := '0';
  signal Clock      : std_logic := '0';
  signal Ciphertext : std_logic_vector(127 downto 0);
  signal o_isdone   : std_logic;
begin

  -- Instantiate the DUT
  cypher_block_inst : entity work.cypher_block
    port map (
      Plaintext  => Plaintext,
      Master_Key => Master_Key,
      Start      => Start,
      Stop       => Stop,
      Clock      => Clock,
      Ciphertext => Ciphertext,
      o_isdone   => o_isdone
    );

  -- Clock generation
  Clock <= not Clock after clk_period / 2;

  -- Main process
  process
    procedure run_encryption(input_plaintext : std_logic_vector(127 downto 0)) is
    begin
      -- Initialize inputs
      Plaintext <= input_plaintext;
      Start     <= '0';
      Stop      <= '1';
      
      -- Allow setup time
      wait for clk_period;
      Start <= '1';  -- Start encryption
      wait for 2 * clk_period;
      Start <= '0';  -- Deassert Start

      -- Wait for o_isdone
      wait until o_isdone = '1';
      wait for clk_period;  -- Stabilization delay
    end procedure;

  begin
    -- Initialize Master_Key
    Master_Key <= x"0f1e2d3c4b5a69788796a5b4c3d2e1f0";

    -- Run encryption for the first plaintext
    run_encryption(x"101112131415161718191a1b1c1d1e1f");

    -- Run encryption for the second plaintext
    -- run_encryption(x"12345678909876543210192837465019");
    wait until rising_edge(Clock);
    wait for 5 * clk_period;

    -- Simulation completed
    report "Simulation completed: All encryption rounds finished."
      severity note;

    -- End simulation
    assert false
      report "End of simulation"
      severity failure;
  end process;

end;
