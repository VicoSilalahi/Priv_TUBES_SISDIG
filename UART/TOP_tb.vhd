library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_Echo_Top_tb is
end UART_Echo_Top_tb;

architecture behavior of UART_Echo_Top_tb is

  -- Component Declaration for the Unit Under Test (UUT)
  component UART_Echo_Top
    generic (
      g_CLKS_PER_BIT : integer := 20833
    );
    port (
      i_Clk         : in std_logic; 
      i_RX_Serial   : in std_logic;
      i_Button      : in std_logic;
      o_TX_Serial   : out std_logic;
      o_RX_LED      : out std_logic;
      i_Button_LED2 : in std_logic;
      o_LED2        : out std_logic
    );
  end component;

  -- Testbench Signals
  signal tb_Clk         : std_logic := '0';
  signal tb_RX_Serial   : std_logic := '1';
  signal tb_Button      : std_logic := '1';
  signal tb_Button_LED2 : std_logic := '0';
  signal tb_TX_Serial   : std_logic;
  signal tb_RX_LED      : std_logic;
  signal tb_LED2        : std_logic;

  constant c_CLK_PERIOD : time := 2 ns;

begin

  -- Instantiate the Unit Under Test (UUT)
  UUT: UART_Echo_Top
    generic map (
      g_CLKS_PER_BIT => 20833
    )
    port map (
      i_Clk         => tb_Clk,
      i_RX_Serial   => tb_RX_Serial,
      i_Button      => tb_Button,
      o_TX_Serial   => tb_TX_Serial,
      o_RX_LED      => tb_RX_LED,
      i_Button_LED2 => tb_Button_LED2,
      o_LED2        => tb_LED2
    );

  -- Clock Generation
  clk_process : process
  begin
    tb_Clk <= '0';
    wait for c_CLK_PERIOD / 2;
    tb_Clk <= '1';
    wait for c_CLK_PERIOD / 2;
  end process;

  -- Stimulus Process
  stimulus_process : process
  begin
    -- Initialize Inputs
    tb_Button <= '1';
    tb_RX_Serial <= '1';
    tb_Button_LED2 <= '0';
    wait for 100 ns;

    -- Simulate reception of data
    tb_RX_Serial <= '0';  -- Start bit
    wait for c_CLK_PERIOD * 20833;
    
    tb_RX_Serial <= '1';  -- Data bits (example: 8 data bits = "10101010")
    wait for c_CLK_PERIOD * 20833;
    tb_RX_Serial <= '0';
    wait for c_CLK_PERIOD * 20833;
    tb_RX_Serial <= '1';
    wait for c_CLK_PERIOD * 20833;
    tb_RX_Serial <= '0';
    wait for c_CLK_PERIOD * 20833;
    tb_RX_Serial <= '1';
    wait for c_CLK_PERIOD * 20833;
    tb_RX_Serial <= '0';
    wait for c_CLK_PERIOD * 20833;
    tb_RX_Serial <= '1';
    wait for c_CLK_PERIOD * 20833;
    tb_RX_Serial <= '1'; -- Stop bit
    wait for c_CLK_PERIOD * 20833;

    -- Wait for processing
    wait for 1 us;

    -- Simulate button press
    tb_Button <= '0';
    wait for 20 ns;
    tb_Button <= '1';

    -- Wait for some time to observe output
    wait for 1 us;

    -- Simulate LED2 button press
    tb_Button_LED2 <= '1';
    wait for 100 ns;
    tb_Button_LED2 <= '0';

    wait;
  end process;

end behavior;
