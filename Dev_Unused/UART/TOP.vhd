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
    i_button    : in std_logic;
    o_TX_Serial : out std_logic := '1'; -- UART TX output pin to transmit TO Client
    o_LED_87    : out std_logic;
    o_LED_86    : out std_logic;
    reset       : in std_logic := '0'

    -- FOR FPGA testing Simulation IOs only, TODO: Delete Later
    -- o_LED_compare : out std_logic := '1'
  );
end UART_TOP;

architecture rtl of UART_TOP is
  signal s_reset : std_logic;

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
      g_CLKS_PER_BIT : integer := 5208
    );
    port (
      i_Clk       : in std_logic;
      i_reset     : in std_logic;
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

  signal clk_counter   : integer   := 0; -- Counter for clock cycles
  signal pulse_counter : integer   := 0; -- Counter for pulse duration
  signal pulse_active  : std_logic := '0'; -- Signal to indicate active pulse
  signal time_elapsed  : std_logic := '0'; -- Indicates the end of m seconds

  constant CLK_FREQ  : integer := 50_000_000; -- Example: 50 MHz clock frequency
  constant M_SECONDS : integer := 2; -- Duration m in seconds
  constant N_CYCLES  : integer := 10; -- Number of cycles the signal stays high
  constant M_COUNT   : integer := CLK_FREQ * M_SECONDS; -- Total clocks for m seconds

begin

  -- Instantiate UART_RX
  UART_RX_inst : UART_RX
  generic map(
    g_CLKS_PER_BIT => g_CLKS_PER_BIT
  )
  port map
  (
    i_Clk       => i_Clk,
    i_reset     => s_reset,
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
  -- Button synchronization and edge detection
  process (i_Clk, reset)
  begin
    s_reset <= not reset;

    -- if s_reset = '1' then
    --   s_button_sync <= '0';
    --   s_button_prev <= '0';
    --   s_button_edge <= '0';
    if rising_edge(i_Clk) then
      -- Synchronize button input to avoid metastability
      s_button_sync <= i_button;
      -- Detect rising edge (button press) and falling edge (button release)
      if s_button_sync = '1' and s_button_prev = '0' then
        s_button_edge <= '1'; -- Rising edge detected (button press)
      else
        s_button_edge <= '0'; -- No rising edge
      end if;
      s_button_prev <= s_button_sync;
    end if;
  end process;

  -- Button press triggers data transmission
  s_TX_DV <= '1' when s_button_edge = '1' else
    '0';

  -- Ensure that the transmission logic works correctly
  process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      if s_TX_DV = '1' then
        -- Start sending data on button press
        s_TX_Block <= s_RX_Block; -- Load the block to be sent
      end if;
    end if;
  end process;

  -- process (i_Clk, reset)
  -- begin
  --   if rising_edge(i_Clk) then
  --     -- Compare s_RX_Block with reference_value
  --     -- if s_RX_Block = "00110001001100100011001100110100001101010011011000110111001110000011000100110010001100110011010000110101001101100011011100111000" then
  --     if s_RX_Block = x"31323334353637383132333435363738" then
  --       o_LED_87 <= '0'; -- Set to '0' if the values match
  --     else
  --       o_LED_87 <= '1'; -- Set to '1' if the values do not match
  --     end if;

  --     -- if s_RX_Block = "00011100111011000110110010101100001011001100110001001100100011000001110011101100011011001010110000101100110011000100110010001100" then
  --     if s_RX_Block = x"1CEC6CAC2CCC4C8C1CEC6CAC2CCC4C8C" then
  --       o_LED_86 <= '0';
  --     else
  --       o_LED_86 <= '1';
  --     end if;
  --   end if;
  -- end process;
  o_LED_87 <= '0' when (s_RX_Block(127 downto 120) = x"38") and (s_RX_Block(119 downto 112) = x"37") else '1'; -- Debugging output
  -- o_LED_86 <= '0' when s_RX_Block = x"1CEC6CAC2CCC4C8C1CEC6CAC2CCC4C8C" else '1';

    -- s_TX_Block <= s_RX_Block;
    -- s_TX_DV    <= not i_button; -- Assign pulse signal to output
    -- o_LED_87   <= '0' when s_RX_Block(127 downto 0) = "00110001" else
    --   '1';
    -- o_LED_86 <= not s_TX_DV;
    -- -- o_LED <= '0' when s_RX_Block /= (others => '0') else '1';
  end rtl;