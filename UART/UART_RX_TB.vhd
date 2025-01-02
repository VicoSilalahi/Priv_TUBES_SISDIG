library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_RX_tb is
end UART_RX_tb;

-- To determine CLKS_PER_BIT:
-- CLKS_PER_BIT = BIT_PERIOD/CLOCK_PERIOD
-- BIT_PERIOD = 1/BAUD_RATE
-- CLOCK PERIOD = 1/Hz

architecture behave of UART_RX_tb is

  -- Updated UART_RX Component Declaration
  component uart_rx is
    generic (
      g_CLKS_PER_BIT : integer := 87 -- Needs to be set correctly
    );
    port (
      i_clk       : in std_logic;
      i_rx_serial : in std_logic;
      o_rx_dv     : out std_logic;
      o_rx_byte   : out std_logic_vector(7 downto 0);
      o_rx_block  : out std_logic_vector(127 downto 0)
    );
  end component uart_rx;

  constant c_CLKS_PER_BIT : integer := 87;
  constant c_BIT_PERIOD   : time := 8680 ns;

  signal r_CLOCK     : std_logic := '0';
  signal r_TX_DV     : std_logic := '0';
  signal r_TX_BYTE   : std_logic_vector(7 downto 0) := (others => '0');
  signal w_RX_DV     : std_logic;
  signal w_RX_BYTE   : std_logic_vector(7 downto 0);
  signal w_RX_BLOCK  : std_logic_vector(127 downto 0);
  signal r_RX_SERIAL : std_logic := '1';

  -- Procedure for Sending 8-Bit Byte
  procedure UART_WRITE_BYTE (
    i_data_in       : in std_logic_vector(7 downto 0);
    signal o_serial : out std_logic) is
  begin
    -- Send Start Bit
    o_serial <= '0';
    wait for c_BIT_PERIOD;

    -- Send Data Byte
    for ii in 0 to 7 loop
      o_serial <= i_data_in(ii);
      wait for c_BIT_PERIOD;
    end loop;

    -- Send Stop Bit
    o_serial <= '1';
    wait for c_BIT_PERIOD;
  end UART_WRITE_BYTE;

  -- Procedure for Sending 128-Bit Block
  procedure UART_WRITE_BLOCK (
    i_data_block    : in std_logic_vector(127 downto 0);
    signal o_serial : out std_logic) is
    variable v_byte : std_logic_vector(7 downto 0);
  begin
    -- Send Each Byte in Block
    for ii in 0 to 15 loop
      v_byte := i_data_block((ii + 1) * 8 - 1 downto ii * 8);
      UART_WRITE_BYTE(v_byte, o_serial);
    end loop;
  end UART_WRITE_BLOCK;

begin

  -- Instantiate UART_RX
  UART_RX_INST : uart_rx
    generic map(
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map(
      i_clk       => r_CLOCK,
      i_rx_serial => r_RX_SERIAL,
      o_rx_dv     => w_RX_DV,
      o_rx_byte   => w_RX_BYTE,
      o_rx_block  => w_RX_BLOCK
    );

  -- Clock Generation (10 MHz)
  r_CLOCK <= not r_CLOCK after 50 ns;

  -- Test Process
  process
    constant c_TEST_BLOCK : std_logic_vector(127 downto 0) := 
      x"0F1E2D3C4B5A69788796A5B4C3D2E1F0";
  begin
    -- Wait for System Initialization
    wait until rising_edge(r_CLOCK);

    -- Send 128-bit Block
    UART_WRITE_BLOCK(c_TEST_BLOCK, r_RX_SERIAL);
    wait for 17 * c_BIT_PERIOD;

    -- Validate Received Block
    wait until rising_edge(r_CLOCK);
    if w_RX_BLOCK = c_TEST_BLOCK then
      report "Test Passed - Correct Block Received" severity note;
    else
      report "Test Failed - Incorrect Block Received" severity error;
    end if;

    -- End Simulation
    assert false report "Simulation Complete" severity failure;
  end process;

end behave;