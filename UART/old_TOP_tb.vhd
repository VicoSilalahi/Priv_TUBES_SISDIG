library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TOP_tb is
end UART_TOP_tb;

architecture behave of UART_TOP_tb is

  -- Component declaration for UART_TOP
  component UART_TOP is
    generic (
      g_CLKS_PER_BIT : integer := 87
    );
    port (
      i_Clk       : in std_logic;
      i_RX_Serial : in std_logic;
      o_TX_Serial : out std_logic;

      i_button    : in std_logic;
      o_RX_DV     : out std_logic;
      o_RX_128DV  : out std_logic;
      o_RX_Byte   : out std_logic_vector(7 downto 0);
      o_RX_block  : out std_logic_vector(127 downto 0)
    );
  end component;

  constant c_CLKS_PER_BIT : integer := 87;
  constant c_BIT_PERIOD   : time    := 8680 ns;

  signal r_CLOCK     : std_logic := '0';
  signal r_RX_SERIAL : std_logic := '1';
  signal r_TX_Serial : std_logic := '1';
  signal w_button    : std_logic := '1';
  signal w_RX_DV     : std_logic;
  signal w_RX_128DV  : std_logic;
  signal w_RX_BYTE   : std_logic_vector(7 downto 0);
  signal w_RX_BLOCK  : std_logic_vector(127 downto 0);

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

  -- Instantiate UART_TOP
  UART_TOP_INST : UART_TOP
  generic map(
    g_CLKS_PER_BIT => c_CLKS_PER_BIT
  )
  port map
  (
    i_Clk       => r_CLOCK,
    i_RX_Serial => r_RX_SERIAL,
    o_TX_Serial => r_TX_Serial,
    i_button    => w_button,
    o_RX_DV     => w_RX_DV,
    o_RX_128DV  => w_RX_128DV,
    o_RX_Byte   => w_RX_BYTE,
    o_RX_block  => w_RX_BLOCK
  );

  -- Clock Generation (10 MHz)
  r_CLOCK <= not r_CLOCK after 50 ns;

  r_RX_SERIAL <= r_TX_Serial;

  -- Test Process
  process
    constant c_TEST_BLOCK_1 : std_logic_vector(127 downto 0) := x"0F1E2D3C4B5A69788796A5B4C3D2E1F0";
    constant c_TEST_BLOCK_2 : std_logic_vector(127 downto 0) := x"01020304050607080910111213141516";
  begin
    -- Wait for System Initialization
    wait until rising_edge(r_CLOCK);

    -- Test Block 1
    UART_WRITE_BLOCK(c_TEST_BLOCK_1, r_RX_SERIAL);
    wait for 17 * c_BIT_PERIOD;

    -- Validate Received Block 1
    wait until rising_edge(r_CLOCK);
    if w_RX_BLOCK = c_TEST_BLOCK_1 then
      report "Test Passed - Correct Block 1 Received" severity note;
    else
      report "Test Failed - Incorrect Block 1 Received" severity error;
    end if;


    w_button <= '0';
    wait for 1 * c_BIT_PERIOD;
    w_button <= '1';
    wait for 500 * c_BIT_PERIOD;

    -- -- Test Block 2
    -- UART_WRITE_BLOCK(c_TEST_BLOCK_2, r_RX_SERIAL);
    -- wait for 17 * c_BIT_PERIOD;

    -- -- Validate Received Block 2
    -- wait until rising_edge(r_CLOCK);
    -- if w_RX_BLOCK = c_TEST_BLOCK_2 then
    --   report "Test Passed - Correct Block 2 Received" severity note;
    -- else
    --   report "Test Failed - Incorrect Block 2 Received" severity error;
    -- end if;

    -- End Simulation
    assert false report "Simulation Complete" severity failure;
  end process;

end behave;
