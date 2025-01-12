------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_UART_tb is
end;

architecture bench of TOP_UART_tb is
  -- Clock period
  constant clk_period : time := 100 ns;
  -- Generics
  constant c_CLKS_PER_BIT : integer := 87;
  constant c_BIT_PERIOD   : time    := 8680 ns;
  -- Clock Frequency / Baudrate
  -- Let's say 10 MHz 115200 bps
  -- 10 Mhz -> Clock Period = 100 ns
  -- Clocks per bit = 87
  -- Bit Period = 1/Baudrate

  -- 

  -- Ports
  signal i_clk       : std_logic:= '0';
  signal i_start     : std_logic:= '1'; -- Inverse in code for button normal behaviour
  signal reset       : std_logic:= '0';
  signal i_RX_Serial : std_logic;
  signal o_TX_Serial : std_logic;

  -- To Simulate Client Sending to RX
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
    constant masterkey : std_logic_vector(127 downto 0) := x"0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    constant ptx_1     : std_logic_vector(127 downto 0) := x"4c6f72656d20697073756d20646f6c6f";
    constant ptx_2     : std_logic_vector(127 downto 0) := x"722073697420616d65742c20636f6e73";
    constant ptx_3     : std_logic_vector(127 downto 0) := x"65637465747572206164697069736369";
    constant ptx_4     : std_logic_vector(127 downto 0) := x"01234567890123456789012345678901";
  begin
    wait until rising_edge(i_clk);
    UART_WRITE_BLOCK(masterkey, i_RX_Serial);
    wait for 17 * c_BIT_PERIOD;
    wait until rising_edge(i_clk);

    i_start <= not i_start;
    wait for 100 * clk_period;
    i_start <= not i_start;

    wait for 1 * c_BIT_PERIOD;

    UART_WRITE_BLOCK(ptx_1, i_RX_Serial);
    wait for 17 * c_BIT_PERIOD;
    wait until rising_edge(i_clk);
    wait for 150 * c_BIT_PERIOD;

    UART_WRITE_BLOCK(ptx_2, i_RX_Serial);
    wait for 17 * c_BIT_PERIOD;
    wait until rising_edge(i_clk);
    wait for 150 * c_BIT_PERIOD;

    UART_WRITE_BLOCK(ptx_3, i_RX_Serial);
    wait for 17 * c_BIT_PERIOD;
    wait until rising_edge(i_clk);
    wait for 150 * c_BIT_PERIOD;



    assert false
      report "Simulation Stopped Here"
      severity failure;
    
  end process;

end;