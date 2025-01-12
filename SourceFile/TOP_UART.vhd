------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB
--
--
------------------------------------------------------------------------------------------------------------------------
-- Deskripsi
-- TOP Entity dari LEA-128 Enkripsi CFB, berpusat pada implementasi UART dan komunikasi dengan CFB
--
-- Fungsi     : UART Receive and Transmit TOP entity to communicate with CFB
-- Input      : i_clk, i_start, reset -> Internal Clock, reset, dan sinyal start
--            : ds, ptxr -> Status signals from and to UART (Data Sent and Plaintext Ready)
--            : i_RX_Serial -> RX pin for receiving data
-- Output     : o_TX_Serial -> TX pin for transmitting data
--            : o_LED -> Show which STATE it is right now (CFB)
------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_UART is
  generic (
    c_CLKS_PER_BIT : integer := 868
    -- To determine CLKS_PER_BIT:
    -- CLKS_PER_BIT = BIT_PERIOD/CLOCK_PERIOD
    -- BIT_PERIOD = 1/BAUD_RATE
    -- CLOCK PERIOD = 1/Hz
    --
    -- HZ / BaudRate
    -- 9600 : 5208
    -- 57600 : 868
  );
  port (
    i_clk       : in std_logic;
    i_start     : in std_logic;
    reset       : in std_logic;
    i_RX_Serial : in std_logic;
    o_TX_Serial : out std_logic;
    o_LED       : out std_logic_vector(2 downto 0)
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
      o_RX_DV     : out std_logic; -- Output Signal when a byte has been received
      o_RX_128DV  : out std_logic;
      o_RX_Byte   : out std_logic_vector(7 downto 0); -- Useless on this scope
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
      o_TX_Active : out std_logic; -- Indicate that TX line is active, maybe useful for LED Indicator.
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
      ds, ptxr    : in std_logic; -- UART TX and RX Signals
      masterkey   : in std_logic_vector(127 downto 0);
      plaintext   : in std_logic_vector(127 downto 0);
      ciphertext  : out std_logic_vector(127 downto 0);
      o_SEND_DATA : out std_logic;
      o_SM        : out std_logic_vector(2 downto 0)
    );
  end component;

  component register_128bit is
    port (
      Clk, En, Res : in std_logic; -- Clk clock, En enable, Res reset
      D            : in std_logic_vector (127 downto 0); -- Input data
      Q            : out std_logic_vector (127 downto 0) -- Output data
    );
  end component;
  component reverseinput is -- Reverse Input for RX and TX
    port (
      A : in std_logic_vector(127 downto 0);
      B : out std_logic_vector(127 downto 0)
    );
  end component;

  signal En_Key, En_Ptx : std_logic := '0';
  -- FSM Signals
  type FSM is (RXKEY, RXPLAINTEXT);
  signal currentstate, nextstate : FSM := RXKEY;

  signal s_CFBSM        : std_logic_vector(2 downto 0); -- State LED signal
  signal s_reset        : std_logic := '0';
  signal s_RX_Block_inv : std_logic_vector(127 downto 0);

begin
  -- UART_RX Instantiation
  UART_RX_inst : UART_RX
  generic map(
    g_CLKS_PER_BIT => c_CLKS_PER_BIT
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

  -- UART_TX Instantiation
  UART_TX_inst : UART_TX
  generic map(
    g_CLKS_PER_BIT => c_CLKS_PER_BIT
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

  -- CFB Instantiation
  CFB_inst : CFB
  port map
  (
    clk         => i_Clk,
    reset       => s_reset,
    start       => s_CFB_start,
    ds          => s_Data_Sent,
    ptxr        => s_Ptx_Ready,
    masterkey   => s_Masterkey,
    plaintext   => s_Plaintext,
    ciphertext  => s_Ciphertext,
    o_SEND_DATA => s_SEND_DATA,
    o_SM        => s_CFBSM
  );

  -- Masterkey Register instantiation
  Masterkey_REG : register_128bit
  port map
  (
    Clk => i_clk,
    En  => En_Key,
    Res => s_reset,
    D   => s_RX_Block_inv,
    Q   => s_Masterkey
  );

  -- Plaintext Register instantiation
  Plaintext_REG : register_128bit
  port map
  (
    Clk => i_clk,
    En  => En_Ptx,
    Res => s_reset,
    D   => s_RX_Block_inv,
    Q   => s_Plaintext
  );

  -- RX State Representation
  RX_BLOCK_REVERSE : reverseinput
  port map
  (
    A => s_RX_Block,
    B => s_RX_Block_inv
  );
  
  -- TX RX State Representation
  TX_BLOCK_REVERSE : reverseinput
  port map
  (
    A => s_Ciphertext,
    B => s_TX_Block
  );

  -- FSM Process
  process (i_Clk, reset)
  begin

    if rising_edge(i_Clk) then
      currentstate <= nextstate;
    end if;
  end process;

  -- Next State Logic
  process (currentstate, i_start)
  begin
    -- Default assignments
    nextstate <= currentstate;

    case currentstate is
      when RXKEY =>
        if i_start = '0' then
          nextstate <= RXPLAINTEXT;
        end if;
      when RXPLAINTEXT =>
        if s_reset = '1' then
          nextstate <= RXKEY;
        else
          nextstate <= RXPLAINTEXT;
        end if;
    end case;
  end process;

  process (currentstate)
  begin
    case currentstate is
      when RXKEY =>
        En_Ptx <= '0';
        En_Key <= '1';
      when RXPLAINTEXT =>
        En_Ptx <= '1';
        En_Key <= '0';
    end case;
  end process;

  -- Output Assignments
  s_TX_DV     <= s_SEND_DATA;
  s_CFB_start <= not i_start;
  s_Data_Sent <= s_TX_Done;
  s_Ptx_Ready <= s_RX_128DV;
  o_LED       <= s_CFBSM;
  s_reset     <= not reset;

end architecture;