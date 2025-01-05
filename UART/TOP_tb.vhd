library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_tb is
end;

architecture bench of TOP_tb is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant g_CLKS_PER_BIT : integer := 87;
  constant g_BIT_PERIOD   : time    := 8680 ns;

  -- Ports
  signal i_Clk       : std_logic := '0';
  signal i_reset     : std_logic := '0';
  signal i_button    : std_logic := '0';
  signal i_RX_Serial : std_logic := '1'; -- Idle state for UART
  signal o_TX_Serial : std_logic;

  -- Procedure for Sending 8-Bit Byte
  procedure UART_WRITE_BYTE (
    i_data_in       : in std_logic_vector(7 downto 0);
    signal o_serial : out std_logic) is
  begin
    -- Send Start Bit
    o_serial <= '0';
    wait for g_BIT_PERIOD;

    -- Send Data Byte
    for ii in 0 to 7 loop
      o_serial <= i_data_in(ii);
      wait for g_BIT_PERIOD;
    end loop;

    -- Send Stop Bit
    o_serial <= '1';
    wait for g_BIT_PERIOD;
  end procedure;

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
  end procedure;

begin
  -- Instantiate TOP entity
  TOP_inst : entity work.TOP
    generic map(
      g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
    port map(
      i_Clk       => i_Clk,
      i_reset     => i_reset,
      i_button    => i_button,
      i_RX_Serial => i_RX_Serial,
      o_TX_Serial => o_TX_Serial
    );

  -- Generate clock signal
  i_Clk <= not i_Clk after clk_period / 2;

  -- Stimulus process
  stim_proc: process
    constant c_TEST_BLOCK : std_logic_vector(127 downto 0) :=
      x"0F1E2D3C4B5A69788796A5B4C3D2E1F0";
  begin
    -- Apply reset
    i_reset <= '1';
    wait for 20 ns;
    i_reset <= '0';
    wait for 20 ns;

    -- Send 128-bit block
    UART_WRITE_BLOCK(c_TEST_BLOCK, i_RX_Serial);
    wait for 100 * g_BIT_PERIOD;

    -- Simulate button press to trigger transmission
    i_button <= '1';
    wait for clk_period;
    i_button <= '0';

    -- Wait to observe feedback data being transmitted
    wait for 200 * g_BIT_PERIOD;

    -- End simulation
    assert false report "Simulation Complete" severity failure;
  end process;
end architecture;
