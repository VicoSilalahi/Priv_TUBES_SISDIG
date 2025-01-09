library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX_tb is
end UART_TX_tb;

architecture behave of UART_TX_tb is

  -- Component Declaration for the Unit Under Test (UUT)
  component UART_TX is
    generic (
      g_CLKS_PER_BIT : integer := 87 -- Needs to be set correctly
    );
    port (
      i_Clk       : in  std_logic;
      i_TX_DV     : in  std_logic;
      i_TX_Block  : in  std_logic_vector(127 downto 0);
      o_TX_Active : out std_logic;
      o_TX_Serial : out std_logic;
      o_TX_Done   : out std_logic
    );
  end component;

  -- Test Bench clock period and UART clock settings
  constant c_CLOCK_PERIOD : time := 50 ns;         -- 10 MHz Clock
  constant c_BIT_PERIOD   : time := 8680 ns;       -- For 115200 baud
  constant c_CLKS_PER_BIT : integer := 87;         -- 100000000 / 115200

  -- Signals for UUT
  signal r_Clk       : std_logic := '0';
  signal r_TX_DV     : std_logic := '0';
  signal r_TX_Block  : std_logic_vector(127 downto 0) := (others => '0');
  signal w_TX_Active : std_logic;
  signal w_TX_Serial : std_logic;
  signal w_TX_Done   : std_logic;

begin

  -- Clock generation
  process
  begin
    r_Clk <= '0';
    wait for c_CLOCK_PERIOD / 2;
    r_Clk <= '1';
    wait for c_CLOCK_PERIOD / 2;
  end process;

  -- Instantiate UART_TX Unit Under Test (UUT)
  UART_TX_INST : UART_TX
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map (
      i_Clk       => r_Clk,
      i_TX_DV     => r_TX_DV,
      i_TX_Block  => r_TX_Block,
      o_TX_Active => w_TX_Active,
      o_TX_Serial => w_TX_Serial,
      o_TX_Done   => w_TX_Done
    );

  -- Test process
  process
    -- Procedure to observe the transmitted signal
    procedure UART_OBSERVE_OUTPUT (
      signal i_serial : in std_logic
    ) is
    begin
      -- Observe start bit
      assert i_serial = '0' report "Error: Missing start bit!" severity failure;
      wait for c_BIT_PERIOD;

      -- Observe data bits (128 bits = 16 bytes)
      for byte_index in 0 to 15 loop
        for bit_index in 0 to 7 loop
          wait for c_BIT_PERIOD;
        end loop;
      end loop;

      -- Observe stop bit
      assert i_serial = '1' report "Error: Missing stop bit!" severity failure;
      wait for c_BIT_PERIOD;
    end UART_OBSERVE_OUTPUT;

  begin
    -- Wait for reset period
    wait for 20 * c_CLOCK_PERIOD;

    -- Send a 128-bit block
    r_TX_Block <= X"0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    -- r_TX_Block <= X"00000000000000000000000000000000";
    r_TX_DV <= '1';
    wait for c_CLOCK_PERIOD;
    r_TX_DV <= '0';

    -- Wait for transmission to complete
    wait until w_TX_Done = '1';
    wait until rising_edge(r_Clk);
    wait for 5*c_CLOCK_PERIOD;
    report "128-bit block transmission complete." severity note;

    -- Observe transmitted output
    UART_OBSERVE_OUTPUT(w_TX_Serial);

    -- End simulation
    assert false report "Testbench Complete" severity failure;
  end process;

end behave;
