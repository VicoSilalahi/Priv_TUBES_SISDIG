
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_UART_tb is
end;

architecture bench of TOP_UART_tb is
  -- Clock period
  constant clk_period : time := 100 ns;
  -- Generics
  --   constant c_CLKS_PER_BIT : integer := 5208;
  constant c_CLKS_PER_BIT : integer := 87;
  constant c_BIT_PERIOD   : time    := 8680 ns;
  -- Ports
  signal i_clk       : std_logic := '0';
  signal i_start     : std_logic := '1';
  signal reset       : std_logic := '0';
  signal i_RX_Serial : std_logic;
  signal o_TX_Serial : std_logic;
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

  TOP_UART_inst : entity work.TOP_UART
    generic map(
      c_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map
    (
      i_clk       => i_clk,
      i_start     => i_start,
      reset       => reset,
      i_RX_Serial => i_RX_Serial,
      o_TX_Serial => o_TX_Serial
    );
  i_clk <= not i_clk after clk_period/2;

  process
    constant c_TEST_MasterKey : std_logic_vector(127 downto 0) := x"0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    constant c_TEST_BLOCK_1   : std_logic_vector(127 downto 0) := x"0F1E2D3C4B5A69788796A5B4C3D2E1F0";
    constant c_TEST_BLOCK_2   : std_logic_vector(127 downto 0) := x"01020304050607080910111213141516";
    constant c_TEST_BLOCK_3   : std_logic_vector(127 downto 0) := x"0F1E2D3C4B5A69788796A5B4C3D2E1F0";
    -- constant c_TEST_BLOCK_2 : std_logic_vector(127 downto 0) := x"01020304050607080910111213141516";
  begin

    wait until rising_edge(i_clk);
    -- Send 128-bit Block
    UART_WRITE_BLOCK(c_TEST_MasterKey, i_RX_Serial);
    wait for 100 * c_BIT_PERIOD;

    i_start <= '0';
    wait for 100 * c_BIT_PERIOD;
    i_start <= '1';
    -- UART_WRITE_BLOCK(c_TEST_BLOCK_1, i_RX_Serial);
    wait for 100 * c_BIT_PERIOD;
    assert false
        report "Simulation Complete"
        severity failure;
    
  end process;
end;