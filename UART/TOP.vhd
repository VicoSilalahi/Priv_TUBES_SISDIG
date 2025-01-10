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
  -- Process to generate the timed pulse
  process (i_Clk, reset)
  begin
    if reset = '1' then
      clk_counter   <= 0;
      pulse_counter <= 0;
      pulse_active  <= '0';
      time_elapsed  <= '0';
    elsif rising_edge(i_Clk) then
      if time_elapsed = '0' then
        -- Count clock cycles for m seconds
        if clk_counter < M_COUNT - 1 then
          clk_counter <= clk_counter + 1;
        else
          clk_counter  <= 0;
          time_elapsed <= '1'; -- m seconds elapsed
        end if;
      elsif pulse_active = '1' then
        -- Count clock cycles for n cycles
        if pulse_counter < N_CYCLES - 1 then
          pulse_counter <= pulse_counter + 1;
        else
          pulse_counter <= 0;
          pulse_active  <= '0'; -- End the pulse
          time_elapsed  <= '0'; -- Reset time elapsed for the next cycle
        end if;
      else
        -- Trigger the pulse
        pulse_active <= '1';
      end if;
    end if;
  end process;

  s_TX_DV <= pulse_active; -- Assign pulse signal to output
end rtl;
