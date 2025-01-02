library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_Echo_Top is
  generic (
    g_CLKS_PER_BIT : integer := 20833 -- Adjust for your clock frequency and baud rate
  );
  port (
    i_Clk         : in std_logic;
    i_RX_Serial   : in std_logic;
    i_Button      : in std_logic; -- Button for triggering transmission
    o_TX_Serial   : out std_logic;
    o_RX_LED      : out std_logic; -- LED to indicate a message was received
    i_Button_LED2 : in std_logic;
    o_LED2        : out std_logic
  );
end UART_Echo_Top;

architecture rtl of UART_Echo_Top is

  -- Signals for UART_RX
  signal w_RX_DV    : std_logic;
  signal w_RX_Byte  : std_logic_vector(7 downto 0);
  signal w_RX_Block : std_logic_vector(127 downto 0);

  -- Signals for UART_TX
  signal w_TX_Active : std_logic;
  signal w_TX_Done   : std_logic;
  signal r_TX_DV     : std_logic := '0';
  signal w_TX_DV     : std_logic;
  signal r_TX_Block  : std_logic_vector(127 downto 0) := (others => '0');

  -- Button debouncing signal
  signal r_Button_Pressed : std_logic := '0';
  signal r_Button_Last    : std_logic := '1'; -- Assume initially unpressed

begin

  -- Instantiate UART_RX
  UART_RX_INST : entity work.UART_RX
    generic map(
      g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
    port map
    (
      i_Clk       => i_Clk,
      i_RX_Serial => i_RX_Serial,
      o_RX_DV     => w_RX_DV,
      o_RX_Byte   => w_RX_Byte,
      o_RX_block  => w_RX_Block
    );

  -- Instantiate UART_TX
  UART_TX_INST : entity work.UART_TX
    generic map(
      g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
    port map
    (
      i_Clk       => i_Clk,
      i_TX_DV     => r_TX_DV,
      i_TX_Block  => r_TX_Block,
      o_TX_Active => w_TX_Active,
      o_TX_Serial => o_TX_Serial,
      o_TX_Done   => w_TX_Done
    );

  -- Button Debouncing Process
  process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      if i_Button = '0' and r_Button_Last = '1' then -- Detect falling edge
        r_Button_Pressed <= '1';
      else
        r_Button_Pressed <= '0';
      end if;
      r_Button_Last <= i_Button;
    end if;
  end process;

  -- Control Logic for Transmission
  process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      if w_RX_DV = '1' then
        -- Store received block for retransmission
        r_TX_Block <= w_RX_Block;
        o_RX_LED   <= '1'; -- Indicate a message was received
      elsif r_Button_Pressed = '1' and w_TX_Active = '0' then
        -- Trigger transmission when button is pressed and TX is idle
        r_TX_DV  <= '1';
        o_RX_LED <= '0'; -- Turn off LED to indicate message is being sent
      else
        -- Default state
        r_TX_DV <= '0';
      end if;
    end if;
  end process;

  o_LED2 <= i_Button_LED2;

end rtl;