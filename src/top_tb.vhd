library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end entity;

architecture bench of top_tb is

  -- Clock period
  constant clk_period : time := 5 ns;

  -- Ports
  signal clk : std_logic;
  signal reset : std_logic;
  signal start : std_logic;
  signal masterkey : std_logic_vector(127 downto 0);
  signal plaintext : std_logic_vector(127 downto 0);
  signal ciphertext : std_logic_vector(127 downto 0);

begin

  -- DUT instantiation
  top_inst : entity work.top
  port map (
    clk => clk,
    reset => reset,
    start => start,
    masterkey => masterkey,
    plaintext => plaintext,
    ciphertext => ciphertext
  );

  -- Clock generation process
  process
  begin
    wait for clk_period / 2;
    clk <= not clk;
    loop
      wait for clk_period;
      clk <= not clk;
    end loop;
  end process;

--   -- Reset pulse (modify as needed)
--   process
--   begin
--     wait for 10 * clk_period; -- Adjust the reset pulse duration
--     reset <= '0';
--     wait for 5 * clk_period; -- Adjust the reset pulse delay
--     reset <= '1';
--   end process;

  -- Start signal (modify as needed)
--   process
--   begin
--     wait for 20 * clk_period; -- Adjust the start signal delay
--     start <= '1';
--     wait for 10 * clk_period; -- Adjust the start signal duration
--     start <= '0';
--   end process;

  -- Plaintext stimulus (modify as needed)
  process
  begin
    start <= '0';
    masterkey <= x"0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    wait for 40 * clk_period; -- Adjust the plaintext update delay
    start <= '1';
    plaintext <= x"0123456789ABCDEF0123456789ABCDEF";
    wait for 1000 * clk_period; -- Adjust the delay between plaintext changes
    plaintext <= x"FEDCBA9876543210FEDCBA9876543210";
    wait;
  end process;

end architecture;