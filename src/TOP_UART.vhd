library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use ieee.math_real.all

entity TOP_UART is
  generic (
    c_CLKS_PER_BIT : integer := 5208
    -- To determine CLKS_PER_BIT:
    -- CLKS_PER_BIT = BIT_PERIOD/CLOCK_PERIOD
    -- BIT_PERIOD = 1/BAUD_RATE
    -- CLOCK PERIOD = 1/Hz
    -- HZ / BaudRate
  );
  port (
    i_clk       : in std_logic;
    i_start     : in std_logic;
    reset       : in std_logic;
    i_RX_Serial : in std_logic;
    o_TX_Serial : out std_logic
  );
end entity;

architecture rtl of TOP_UART is
  -- RX Signals
  signal s_RX_DV    : std_logic := '0';
  signal s_RX_128DV : std_logic := '0';
  signal s_RX_Byte  : std_logic_vector(7 downto 0);
  signal s_RX_Block : std_logic_vector(127 downto 0);

  -- RX Component Declaration
  component UART_RX is
    generic (
      g_CLKS_PER_BIT : integer := c_CLKS_PER_BIT
    );
    port (
      i_Clk       : in std_logic; -- Internal Clock
      i_RX_Serial : in std_logic; -- Input RX Pin (Receive from Client/PC)
      o_RX_DV     : out std_logic; -- Output Signal when a byte has been received TODO: Create the mechanism for 128-bit DV
      o_RX_128DV  : out std_logic;
      o_RX_Byte   : out std_logic_vector(7 downto 0); -- TODO: Remove doesn't need outside of simulation
      o_RX_Block  : out std_logic_vector(127 downto 0) -- Output of the UART Receiver, sized 128-bit to be input into TOP
    );
  end component;

  -- TX Signals
  signal s_TX_DV     : std_logic := '0';
  signal s_TX_Block  : std_logic_vector(127 downto 0);
  signal s_TX_Active : std_logic := '0';
  signal s_TX_Done   : std_logic := '0';

  -- TX Component Declaration
  component UART_TX is
    generic (
      g_CLKS_PER_BIT : integer := c_CLKS_PER_BIT
    );
    port (
      i_Clk       : in std_logic; -- Internal Clock
      i_TX_DV     : in std_logic; -- Input to indicate that the data is ready to be sent/Send immediately
      i_TX_Block  : in std_logic_vector(127 downto 0); -- Input of 128-bits block
      o_TX_Active : out std_logic; -- Indicate that TX line is active, maybe useful for LED Indicator. TODO: On TOP put LED
      o_TX_Serial : out std_logic := '1'; -- TX Line communicates to Client/PC
      o_TX_Done   : out std_logic -- Indicates 128-bit is done
    );
  end component;
  -- CFB Signals
  signal s_CFB_start  : std_logic := '0';
  signal s_Data_Sent  : std_logic := '0';
  signal s_Ptx_Ready  : std_logic := '0';
  signal s_Masterkey  : std_logic_vector(127 downto 0);
  signal s_Plaintext  : std_logic_vector(127 downto 0);
  signal s_Ciphertext : std_logic_vector(127 downto 0);
  signal s_SEND_DATA  : std_logic := '0';
  -- CFB Component Declaration
  component CFB is
    port (
      clk         : in std_logic;
      reset       : in std_logic;
      start       : in std_logic;
      ds, ptxr    : in std_logic; -- temporary simulation input for UART RX READY AND UART TX DONE
      masterkey   : in std_logic_vector(127 downto 0);
      plaintext   : in std_logic_vector(127 downto 0);
      ciphertext  : out std_logic_vector(127 downto 0);
      o_SEND_DATA : out std_logic
    );
  end component;

  -- Registers and MUX
  signal s_Masterkey_reg : std_logic_vector(127 downto 0) := (others => '0');
  signal s_Plaintext_reg : std_logic_vector(127 downto 0) := (others => '0');

  -- FSM Signals
  type FSM is (RXKEY, RXPLAINTEXT);
  signal currentstate, nextstate : FSM := RXKEY;
    
begin
    -- UART_RX Instantiation
    UART_RX_inst : UART_RX
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map (
      i_Clk       => i_Clk,
      i_RX_Serial => i_RX_Serial,
      o_RX_DV     => s_RX_DV,
      o_RX_128DV  => s_RX_128DV,
      o_RX_Byte   => s_RX_Byte,
      o_RX_Block  => s_RX_Block
    );
  
    -- UART_TX Instantiation
    UART_TX_inst : UART_TX
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map (
      i_Clk       => i_Clk,
      i_TX_DV     => s_TX_DV,
      i_TX_Block  => s_TX_Block,
      o_TX_Active => s_TX_Active,
      o_TX_Serial => o_TX_Serial,
      o_TX_Done   => s_TX_Done
    );
  
    -- CFB Instantiation
    CFB_inst : CFB
    port map (
      clk         => i_Clk,
      reset       => reset,
      start       => s_CFB_start,
      ds          => s_Data_Sent,
      ptxr        => s_Ptx_Ready,
      masterkey   => s_Masterkey_reg,
      plaintext   => s_Plaintext_reg,
      ciphertext  => s_Ciphertext,
      o_SEND_DATA => s_SEND_DATA
    );
  
    -- FSM Process
    process (i_Clk, reset)
    begin
      if reset = '1' then
        currentstate <= RXKEY;
        s_Masterkey_reg <= (others => '0');
        s_Plaintext_reg <= (others => '0');
      elsif rising_edge(i_Clk) then
        currentstate <= nextstate;
      end if;
    end process;
  
    -- Next State Logic
    process (currentstate, i_start, s_RX_Block, s_RX_128DV)
    begin
      -- Default assignments
      nextstate <= currentstate;
  
      case currentstate is
        when RXKEY =>
          if i_start = '1' then
            nextstate <= RXPLAINTEXT;
          end if;
        when RXPLAINTEXT =>
          if i_start = '0' then
            nextstate <= RXKEY;
          end if;
      end case;
    end process;
  
    -- Output Logic for Registers
    process (i_Clk, reset)
    begin
      if reset = '1' then
        s_Masterkey_reg <= (others => '0');
        s_Plaintext_reg <= (others => '0');
      elsif rising_edge(i_Clk) then
        if s_RX_128DV = '1' then
          case currentstate is
            when RXKEY =>
              s_Masterkey_reg <= s_RX_Block;
            when RXPLAINTEXT =>
              s_Plaintext_reg <= s_RX_Block;
            when others =>
              null;
          end case;
        end if;
      end if;
    end process;
  
    -- Output Assignments
    s_TX_Block  <= s_Ciphertext;
    s_TX_DV     <= s_SEND_DATA;
    s_CFB_start <= not i_start;
  
  end architecture;