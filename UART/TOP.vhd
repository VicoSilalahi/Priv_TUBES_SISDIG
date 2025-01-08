library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TOP is
  generic (
    g_CLKS_PER_BIT : integer := 5208 -- Must match the value used in UART_RX
  );
  port (
    i_Clk       : in std_logic; -- System clock
    i_RX_Serial : in std_logic; -- UART RX input pin to receive FROM client
    o_TX_Serial : out std_logic := '1'; -- UART TX output pin to transmitt TO Client
    -- Simulation IOs only, TODO: Delete Later
    i_button     : in std_logic;
    i_button_LED : in std_logic;
    o_button_LED : out std_logic;
    o_LED        : out std_logic
    -- o_RX_DV    : out std_logic; -- Byte-received signal
    -- o_RX_128DV : out std_logic; -- 128-bit data valid signal
    -- o_RX_Byte  : out std_logic_vector(7 downto 0); -- Debug: Received byte
    -- o_RX_Block : out std_logic_vector(127 downto 0) -- 128-bit received data
  );
end UART_TOP;

architecture rtl of UART_TOP is
  -- Signal for RX
  signal s_RX_DV    : std_logic;
  signal s_RX_128DV : std_logic;
  signal s_RX_Byte  : std_logic_vector(7 downto 0);
  signal s_RX_Block : std_logic_vector(127 downto 0);

  -- Component declaration for UART_RX
  component UART_RX
    generic (
      g_CLKS_PER_BIT : integer := 5208
    );
    port (
      i_Clk       : in std_logic;
      i_RX_Serial : in std_logic; -- RX Pin
      o_RX_DV     : out std_logic;
      o_RX_128DV  : out std_logic;
      o_RX_Byte   : out std_logic_vector(7 downto 0);
      o_RX_Block  : out std_logic_vector(127 downto 0)
    );
  end component;

  -- SIgnal for TX
  signal s_TX_DV     : std_logic;
  signal s_TX_Block  : std_logic_vector(127 downto 0);
  signal s_TX_Active : std_logic;
  signal s_TX_Done   : std_logic;

  -- Component declaration for UART_TX
  component UART_TX is
    generic (
      g_CLKS_PER_BIT : integer := 5208
    );
    port (
      i_Clk       : in std_logic; -- Internal Clock
      i_TX_DV     : in std_logic; -- Input to indicate that the data is ready to be sent/Send immediately
      i_TX_Block  : in std_logic_vector(127 downto 0); -- Input of 128-bits block
      o_TX_Active : out std_logic; -- Indicate that TX line is active, maybe useful for LED Indicator. TODO: On TOP put LED
      o_TX_Serial : out std_logic; -- TX Line communicates to Client/PC
      o_TX_Done   : out std_logic -- Indicates 128-bit is done
    );
  end component;

begin

  -- Instantiate UART_RX
  UART_RX_inst : UART_RX
  generic map(
    g_CLKS_PER_BIT => g_CLKS_PER_BIT
  )
  port map
  (
    i_Clk       => i_Clk,
    i_RX_Serial => i_RX_Serial,
    o_RX_DV     => s_RX_DV,
    o_RX_128DV  => s_RX_128DV,
    o_RX_Byte   => s_RX_Byte,
    o_RX_Block  => s_RX_Block
  );

  -- Instantiate UART_TX
  UART_TX_inst : UART_TX
  generic map(
    g_CLKS_PER_BIT => g_CLKS_PER_BIT
  )
  port map
  (
    i_Clk       => i_Clk,
    i_TX_DV     => s_TX_DV,
    i_TX_Block  => s_TX_Block,
    o_TX_Active => s_TX_Active,
    o_TX_Serial => o_TX_Serial,
    o_TX_Done   => s_TX_Done
  );

  -- Signal Processes
  s_TX_Block   <= s_RX_Block; -- For Testing Purposes, that we will transmit the same data that we receive
  s_TX_DV      <= not i_button;
  o_button_LED <= i_button_LED;
  o_LED        <= '1';

  -- Simulation SIgnals
  -- o_RX_DV    <= s_RX_DV;
  -- o_RX_128DV <= s_RX_128DV;
  -- o_RX_Byte  <= s_RX_Byte;
  -- o_RX_Block <= s_RX_Block;
end rtl;
