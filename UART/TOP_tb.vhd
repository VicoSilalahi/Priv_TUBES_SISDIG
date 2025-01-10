
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TOP_tb is
end;

architecture bench of UART_TOP_tb is
  -- Clock period
  constant clk_period : time := 100 ns;
  -- Generics
  constant g_CLKS_PER_BIT : integer := 87;
  -- Ports
  signal i_Clk       : std_logic := '0';
  signal i_RX_Serial : std_logic;
  signal i_button    : std_logic := '1';
  signal o_TX_Serial : std_logic := '1';
  signal o_LED_87    : std_logic;
  signal o_LED_86    : std_logic;
  signal reset       : std_logic;
  signal i_TX_block  : std_logic_vector(127 downto 0);
  signal o_RX_block  : std_logic_vector(127 downto 0);

  constant c_CLKS_PER_BIT : integer := 87;
  constant c_BIT_PERIOD   : time    := 8680 ns;

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

  UART_TOP_inst : entity work.UART_TOP
    generic map(
      g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
    port map
    (
      i_Clk       => i_Clk,
      i_RX_Serial => i_RX_Serial,
      i_button    => i_button,
      o_TX_Serial => o_TX_Serial,
      o_LED_87    => o_LED_87,
      o_LED_86    => o_LED_86,
      reset       => reset,
      i_TX_block  => i_TX_block,
      o_RX_block  => o_RX_block
    );

  i_RX_Serial <= o_TX_Serial;
  i_clk <= not i_clk after clk_period/2;

  process
    constant testConstant1 : std_logic_vector(127 downto 0) := x"31323334353637383132333435363738";
  begin
    wait until rising_edge(i_Clk);
    i_TX_block <= x"31323334353637383132333435363738";
    i_button <= not i_button;
    wait for 2 * clk_period;
    i_button <= not i_button;

    wait for 20 * c_BIT_PERIOD;

    assert false
      report "Simulation Completed"
      severity failure;
    
  end process;

end;