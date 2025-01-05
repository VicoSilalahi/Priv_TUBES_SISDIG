
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_tb is
end;

architecture bench of TOP_tb is
  -- Clock period
  constant clk_period : time := 100 ns;
  -- Generics
  constant g_CLKS_PER_BIT : integer := 87;
  constant c_BIT_PERIOD   : time    := 8680 ns;
  -- Ports
  signal i_Clk       : std_logic;
  signal i_reset     : std_logic;
  signal i_button    : std_logic;
  signal i_RX_Serial : std_logic;
  signal o_TX_Serial : std_logic;
  signal o_BLOCK     : std_logic_vector(127 downto 0);
-- Procedure for Sending 8-Bit Byte
procedure UART_WRITE_BYTE (
  i_data_in       : in std_logic_vector(7 downto 0);
  signal o_serial : out std_logic) is
  variable v_serial : std_logic;
begin
  -- Send Start Bit
  v_serial := '0';
  o_serial <= v_serial;
  wait for c_BIT_PERIOD;

  -- Send Data Byte
  for ii in 0 to 7 loop
    v_serial := i_data_in(ii);
    o_serial <= v_serial;
    wait for c_BIT_PERIOD;
  end loop;

  -- Send Stop Bit
  v_serial := '1';
  o_serial <= v_serial;
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

  TOP_inst : entity work.TOP
    generic map(
      g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
    port map
    (
      i_Clk       => i_Clk,
      i_reset     => i_reset,
      i_button    => i_button,
      i_RX_Serial => i_RX_Serial,
      o_TX_Serial => o_TX_Serial,
      o_BLOCK     => o_BLOCK
    );

  -- Clock Generation (10 MHz)
  i_Clk <= not i_Clk after 50 ns;

  -- Test Process
  process
    constant c_TEST_BLOCK : std_logic_vector(127 downto 0) :=
    x"0F1E2D3C4B5A69788796A5B4C3D2E1F0";
  begin
    -- Wait for System Initialization
    wait until rising_edge(i_Clk);
    wait for c_BIT_PERIOD;

    -- Send 128-bit Block
    UART_WRITE_BLOCK(c_TEST_BLOCK, i_RX_Serial);
    wait for 17 * c_BIT_PERIOD;

    -- Validate Received Block
    wait until rising_edge(i_Clk);
    if o_BLOCK = c_TEST_BLOCK then
      report "Test Passed - Correct Block Received" severity note;
    else
      report "Test Failed - Incorrect Block Received" severity error;
    end if;
    wait for c_BIT_PERIOD;

    -- End Simulation
    assert false report "Simulation Complete" severity failure;
  end process;

end;