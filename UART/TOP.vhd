-- TOP Entity Test for UART RX and TX
-- Testing: Inputting UART into FPGA, and then pressing a button to receive again to Client (PC)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP is
  generic (
    g_CLKS_PER_BIT : integer := 87 -- Adjust for your clock frequency and baud rate
  );
  port (
    i_Clk       : in std_logic;
    i_reset     : in std_logic; -- Reset/Clear Memory of TX (MEM_UART)
    i_button    : in std_logic; -- Button to start transmission from FPGA to Client (PC)
    i_RX_Serial : in std_logic;
    o_TX_Serial : out std_logic -- TX Line for UART_TX
  );
end entity;

architecture rtl of TOP is
  type arr32 is array (natural range <>) of std_logic_vector(31 downto 0);
  type BYTE is array (natural range <>) of std_logic_vector(7 downto 0);

  -- Signals for UART_TX
  signal TX_DV     : std_logic;
  signal TX_Block  : std_logic_vector(127 downto 0);
  signal TX_Active : std_logic;
  signal TX_Done   : std_logic;

  -- Signals foor UART_RX
  signal RX_DV    : std_logic;
  signal RX_128DV : std_logic;
  signal RX_Byte  : std_logic_vector(7 downto 0); -- Useless?
  signal RX_Block : std_logic_vector(127 downto 0);

  component UART_RX is
    generic (
      g_CLKS_PER_BIT : integer := 87 -- Needs to be set correctly
      -- To determine CLKS_PER_BIT:
      -- CLKS_PER_BIT = BIT_PERIOD/CLOCK_PERIOD
      -- BIT_PERIOD = 1/BAUD_RATE
      -- CLOCK PERIOD = 1/Hz
    );
    port (
      i_Clk       : in std_logic; -- Internal Clock
      i_RX_Serial : in std_logic; -- Input RX Pin (Receive from Client/PC)
      o_RX_DV     : out std_logic; -- Output Signal when a byte has been received ToDo: Create the mechanism for 128-bit DV
      o_RX_128DV  : out std_logic;
      o_RX_Byte   : out std_logic_vector(7 downto 0); -- ToDo: Remove doesn't need outside of simulation
      o_RX_block  : out std_logic_vector(127 downto 0) -- Output of the UART Receiver, sized 128-bit to be input into TOP
    );
  end component;

  component UART_TX is
    generic (
      g_CLKS_PER_BIT : integer := 87 -- Needs to be set correctly
      -- To determine CLKS_PER_BIT:
      -- CLKS_PER_BIT = BIT_PERIOD/CLOCK_PERIOD
      -- BIT_PERIOD = 1/BAUD_RATE
      -- CLOCK PERIOD = 1/Hz
    );
    port (
      i_Clk       : in std_logic; -- Internal Clock
      i_TX_DV     : in std_logic; -- Input to indicate that the data is ready to be sent/Send immediately
      i_TX_Block  : in std_logic_vector(127 downto 0); -- Input of 128-bits block
      o_TX_Active : out std_logic; -- Indicate that TX line is active, maybe useful for LED Indicator. ToDo: On TOP put LED
      o_TX_Serial : out std_logic; -- TX Line communicates to Client/PC
      o_TX_Done   : out std_logic -- Indicates 128-bit is done
    );
  end component;

  signal feedback_enabled : std_logic := '0'; -- Flag to prevent retransmission until TX is done
begin
  -- Component Instantiation
  -- RX
  UART_RX_inst : UART_RX
  generic map(
    g_CLKS_PER_BIT => g_CLKS_PER_BIT
  )
  port map
  (
    i_Clk       => i_Clk,
    i_RX_Serial => i_RX_Serial,
    o_RX_DV     => RX_DV,
    o_RX_128DV  => RX_128DV,
    o_RX_Byte   => RX_Byte,
    o_RX_block  => RX_Block
  );
  -- TX
  UART_TX_inst : UART_TX
  generic map(
    g_CLKS_PER_BIT => g_CLKS_PER_BIT
  )
  port map
  (
    i_Clk       => i_Clk,
    i_TX_DV     => TX_DV,
    i_TX_Block  => TX_Block,
    o_TX_Active => TX_Active,
    o_TX_Serial => o_TX_Serial,
    o_TX_Done   => TX_Done
  );

  TX_Block <= RX_Block;

  -- Feedback Logic
  -- To feedback to PC again, TODO: Read from RX that all 128-bit is received (use RX_128DV) then drive TX_DV high to send the data in TX_Block
  process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      -- If RX_128DV is high (indicating 128-bit block is ready) and not already transmitting
      if RX_128DV = '1' and feedback_enabled = '0' then
        TX_DV            <= '1'; -- Start transmission
        feedback_enabled <= '1'; -- Prevent retriggering until TX is complete
      elsif TX_Done = '1' then
        TX_DV            <= '0'; -- Transmission done, clear TX_DV
        feedback_enabled <= '0'; -- Allow next transmission
      end if;
    end if;
  end process;
end architecture;