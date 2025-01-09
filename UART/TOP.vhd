library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TOP is
  generic (
    g_CLKS_PER_BIT : integer := 20834 -- Must match the value used in UART_RX
  );
  port (
    i_Clk       : in std_logic; -- System clock
    i_RX_Serial : in std_logic; -- UART RX input pin to receive FROM client
    o_TX_Serial : out std_logic := '1'; -- UART TX output pin to transmit TO Client
    reset       : in std_logic  := '0';

    -- FOR FPGA testing Simulation IOs only, TODO: Delete Later
    o_LED_compare : out std_logic := '1'
  );
end UART_TOP;

architecture rtl of UART_TOP is
  -- Signal for RX
  signal s_RX_DV    : std_logic;
  signal s_RX_128DV : std_logic;
  signal s_RX_Byte  : std_logic_vector(7 downto 0);
  signal s_RX_Block : std_logic_vector(127 downto 0);

  -- Signal for TX
  signal s_TX_DV     : std_logic := '0';
  signal s_TX_Block  : std_logic_vector(127 downto 0);
  signal s_TX_Active : std_logic;
  signal s_TX_Done   : std_logic;

  -- Button handling
  signal s_button_sync : std_logic := '0';
  signal s_button_prev : std_logic := '0';
  signal s_button_edge : std_logic := '0';

  -- Component declaration for UART_RX
  component UART_RX
    generic (
      g_CLKS_PER_BIT : integer := 20834
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

  -- Component declaration for UART_TX
  component UART_TX is
    generic (
      g_CLKS_PER_BIT : integer := 20834
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
  -- Define the clock frequency (e.g., 50 MHz)
  constant clk_freq         : integer := 50000000; -- Adjust to your FPGA's clock frequency
  constant one_second_count : integer := clk_freq; -- Number of clock cycles in 1 second

  -- Signals
  signal rx_led_timer : integer   := 0; -- Timer to track 1-second interval
  signal led_output   : std_logic := '0'; -- LED output signal

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

  -- process (s_RX_Block)
  --   constant tocompare : std_logic_vector(127 downto 0) := x"ffffffffffffffffffffffffffffffff";

  -- begin
  --   if s_RX_Block = tocompare then
  --     o_LED_compare <= '0';
  --   else
  --     o_LED_compare <= '1';
  --   end if;
  -- end process;

  -- Synchronize and debounce the button
  -- process (i_Clk)
  -- begin
  --   if rising_edge(i_Clk) then
  --     s_button_sync <= i_button;            -- Synchronize button to clock domain
  --     s_button_edge <= s_button_sync and not s_button_prev; -- Detect rising edge
  --     s_button_prev <= s_button_sync;       -- Store previous button state
  --   end if;
  -- end process;

  -- -- Control TX_DV signal
  -- process (i_Clk)
  -- begin
  --   if rising_edge(i_Clk) then
  --     if s_button_edge = '1' then
  --       s_TX_DV <= '1';  -- Assert TX_DV for one clock cycle
  --     else
  --       s_TX_DV <= '0';  -- Deassert TX_DV
  --     end if;
  --   end if;
  -- end process;

  -- -- Connect signals
  -- s_TX_Block   <= s_RX_Block; -- For Testing Purposes, transmit the same data received
  -- o_button_LED <= i_button_LED;
  -- o_LED        <= '1';
  -- Process to handle the LED timer
  process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      if reset = '1' then
        -- Reset the timer and LED output
        rx_led_timer <= 0;
        led_output   <= '0';
      elsif s_RX_DV = '1' then
        -- Start/Restart the timer on RX event
        rx_led_timer <= one_second_count;
        led_output   <= '1'; -- Turn on LED
      elsif rx_led_timer > 0 then
        -- Decrement timer if active
        rx_led_timer <= rx_led_timer - 1;
        if rx_led_timer = 1 then
          -- Turn off LED when timer expires
          led_output <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Assign LED output to the FPGA pin
  o_LED_compare <= not led_output;
end rtl;
