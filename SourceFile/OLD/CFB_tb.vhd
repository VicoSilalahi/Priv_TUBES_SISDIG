library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CFB_tb is
end entity;

architecture bench of CFB_tb is

  -- Clock period
  constant clk_period : time := 10 ns;

  -- Ports
  signal clk             : std_logic := '0';
  signal reset           : std_logic := '0';
  signal start           : std_logic := '0';
  signal data_sent       : std_logic := '0';
  signal plaintext_ready : std_logic := '0';
  signal masterkey       : std_logic_vector(127 downto 0);
  signal plaintext       : std_logic_vector(127 downto 0);
  signal ciphertext      : std_logic_vector(127 downto 0);

begin

  -- DUT instantiation
  top_inst : entity work.CFB
    port map
    (
      clk        => clk,
      reset      => reset,
      start      => start,
      ds         => data_sent,
      ptxr       => plaintext_ready,
      masterkey  => masterkey,
      plaintext  => plaintext,
      ciphertext => ciphertext
    );

  -- Clock generation process
  clk <= not clk after 5 ns;

  process
  begin
    start     <= '0';
    masterkey <= x"0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    wait for 1 * clk_period; -- Adjust the plaintext update delay
    start     <= '1';
    wait for 1 * clk_period;
    start <= '0';
    wait for 5 *clk_period;
    plaintext <= x"4c6f72656d20697073756d20646f6c6f";
    plaintext_ready <= '1';
    wait for 1 * clk_period;
    plaintext_ready <= '0';
    wait for 50 * clk_period;

    -- 1 Iteration
    wait for 50 * clk_period; -- Adjust the delay between plaintext changes
    data_sent <= '1';
    wait for clk_period;
    data_sent       <= '0';
    plaintext       <= x"722073697420616d65742c20636f6e73";
    plaintext_ready <= '1';
    wait for 1 * clk_period;
    plaintext_ready <= '0';
    wait for 50 * clk_period;

    -- 1 Iteration
    wait for 50 * clk_period; -- Adjust the delay between plaintext changes
    data_sent <= '1';
    wait for clk_period;
    data_sent       <= '0';
    plaintext       <= x"65637465747572206164697069736369";
    plaintext_ready <= '1';
    wait for 1 * clk_period;
    plaintext_ready <= '0';
    wait for 50 * clk_period;

    -- 1 Iteration
    wait for 50 * clk_period; -- Adjust the delay between plaintext changes
    data_sent <= '1';
    wait for clk_period;
    data_sent       <= '0';
    plaintext       <= x"01234567890123456789012345678901";
    plaintext_ready <= '1';
    wait for 1 * clk_period;
    plaintext_ready <= '0';
    wait for 50 * clk_period;

    assert false
    report "Simulation capped at this point"
      severity failure;
  end process;

end architecture;