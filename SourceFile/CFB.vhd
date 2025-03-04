------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB
--
--
------------------------------------------------------------------------------------------------------------------------
-- Deskripsi
-- MODE Enkripsi CFB "Ciphertext Feedback" yaitu, penggunaan Initialization Vector unik untuk iterasi pertama
-- Untuk iterasi selanjutnya IV akan diganti menjadi Hasil Enkripsi IV sebelumnya XOR dengan plaintext sebelumnya
--
-- Fungsi     : Iterative Encryption for Data Stream
-- Input      : clk, reset, start -> Internal Clock, reset, dan sinyal start
--            : ds, ptxr -> Status signals from and to UART (Data Sent and Plaintext Ready)
--            : masterkey, plaintext -> Input from TOP entity after receiving from UART
-- Output     : ciphertext -> UART Will capture the ciphertext at State SEND_DATA
--            : o_SEND_DATA, o_SM -> Signal to UART -> Which State is it right now (Visualizer)
------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity CFB is
  port (
    clk         : in std_logic;
    reset       : in std_logic;
    start       : in std_logic;
    ds, ptxr    : in std_logic; -- Status signals for UART
    masterkey   : in std_logic_vector(127 downto 0);
    plaintext   : in std_logic_vector(127 downto 0);
    ciphertext  : out std_logic_vector(127 downto 0);
    o_SEND_DATA : out std_logic;
    o_SM        : out std_logic_vector(2 downto 0) -- LED Based on which STATE is the FSM on right now
  );
end entity;

architecture rtl of CFB is
  -- LEA-128 Encryption Component Declaration
  component LEA_128 is
    port (
      i_clk                    : in std_logic;
      i_start, i_reset         : in std_logic;
      i_plaintext, i_masterkey : in std_logic_vector(127 downto 0);
      o_ciphertext             : out std_logic_vector(127 downto 0);
      o_isdone                 : out std_logic
    );
  end component;

  component register_128bit is -- Register to hold the values of IV and Key on the top entity
    port (
      Clk, En, Res : in std_logic;
      D            : in std_logic_vector (127 downto 0);
      Q            : out std_logic_vector (127 downto 0)
    );
  end component;

  component mux2to1_128bit is -- Multiplexer 2 in 1 out for data size 128-bit
    port (
      i_A : in std_logic_vector(127 downto 0);
      i_B : in std_logic_vector(127 downto 0);
      i_S : in std_logic;
      o_C : out std_logic_vector(127 downto 0)
    );
  end component;

  -- Control Signals (Output)
  signal S_IN, S_IV, En_IV, En_Key, DataValid, START_LEA, STOP_LEA : std_logic := '0';
  signal T_in, X_in, C_out                                         : std_logic_vector(127 downto 0);

  -- Control Signals (input)
  signal isdone          : std_logic;
  signal data_sent       : std_logic := '0';
  signal plaintext_ready : std_logic := '0';
  signal s_SEND_DATA     : std_logic := '0';

  -- initialization Vector
  constant IV : std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";

  -- Value for the next Inisialization Vector to be fed into LEA-128, Produce of XOR-ing LEA-128 output and Plaintext
  -- Which means it's the same as Ciphertext
  signal next_IV  : std_logic_vector(127 downto 0);
  signal OutMUXIV : std_logic_vector(127 downto 0);

  -- Top Entity FSM
  type state is (IDLE, LOAD_KEY, ENCRYPT, LOAD_IV, SEND_DATA, WAIT_FOR_PLAINTEXT);
  signal currentstate, nextstate : state := IDLE;

begin
  -- Register for Masterkey Input, Will not change except when reset
  Key : register_128bit
  port map
  (
    Clk => Clk,
    En  => En_Key, -- Enable Signal, will be on only when loading the Masterkey, which is at the beginning, and reset
    Res => reset, -- Activated or not is fine, because UART Input will changeit anyways
    D   => masterkey,
    Q   => T_in -- Masterkey
  );

  -- Register for Plaintext/initialization Vector input, Will Change after every complete encryption
  Ptx : register_128bit
  port map
  (
    Clk => Clk,
    En  => En_IV, -- Enable Signal, will be on when loading the next plaintext value from UART
    Res => reset,
    D   => OutMUXIV, -- Input from Multiplexer IVMUX
    Q   => X_in -- To Be Fed into LEA-128 Encryption as "Plaintext" for the next iteration of Encryption
  );

  -- Initialization Vector 
  next_IV    <= plaintext xor C_out;
  ciphertext <= plaintext xor C_out;

  IVMUX : mux2to1_128bit -- Multiplexer for the next IV to be fed into LEA-128
  port map
  (
    i_A => next_IV, -- Feedback from LEA-128 XOR'ed with Input Plaintext
    i_B => IV, -- Const IV of 128'h0
    i_S => S_IV, -- Selector with '0' selecting A, and '1' selecting B
    o_C => OutMUXIV -- Output to be fed into IV Register
  );

  -- LEA Encryption for 128-bit Masterkey
  -- cypher_block_inst : cypher_block
  -- port map
  -- (
  --   Plaintext  => X_in, -- Plaintext to be fed into the LEA-128. INPUT FROM 
  --   Master_Key => T_in, -- Masterkey of 128-bit, which will be key scheduled into 192-bit. Value won't change
  --   Start      => START_LEA, -- Signal to initiate the begining of encryption process
  --   Stop       => STOP_LEA, -- To be determined whether useful or not
  --   Clock      => Clk,
  --   Ciphertext => C_out, -- Output of the LEA-128 Encryption. To be XOR'ed with Actual Plaintext
  --   o_isdone   => isdone -- Output signal on which is '1' when all 24 rounds are done, to be fed into the top entity FSM
  -- );

  LEA_128_inst : LEA_128
  port map
  (
    i_clk        => Clk,
    i_start      => START_LEA, -- Signal to initiate the begining of encryption process
    i_reset      => STOP_LEA,
    i_plaintext  => X_in, -- Plaintext to be fed into the LEA-128. INPUT FROM 
    i_masterkey  => T_in, -- Masterkey of 128-bit, which will be key scheduled into 192-bit. Value won't change
    o_ciphertext => C_out, -- Output of the LEA-128 Encryption. To be XOR'ed with Actual Plaintext
    o_isdone     => isdone -- Output signal on which is '1' when all 24 rounds are done, to be fed into the top entity FSM
  );

  -- UART Signals Instantiation
  plaintext_ready <= ptxr;
  data_sent       <= ds;
  o_SEND_DATA     <= s_SEND_DATA;
  -- FSM process
  process (clk, reset)
  begin
    if reset = '1' then
      currentstate <= IDLE; -- Set the default state during reset
    elsif rising_edge(clk) then
      currentstate <= nextstate; -- Update the state on the clock edge
    end if;
  end process;

  -- State transition logic
  process (currentstate, start, reset, isdone, data_sent, plaintext_ready)
  begin
    case currentstate is
      when IDLE =>
        if start = '1' then
          nextstate <= LOAD_KEY;
        else
          nextstate <= IDLE;
        end if;

      when LOAD_KEY =>
        nextstate <= WAIT_FOR_PLAINTEXT; -- Assuming key loading is instantaneous

      when ENCRYPT =>
        if isdone = '1' then
          nextstate <= LOAD_IV; -- Transition to LOAD_IV after encryption is done
        else
          nextstate <= ENCRYPT;
        end if;

      when LOAD_IV =>
        nextstate <= SEND_DATA; -- Stay in LOAD_IV for one clock cycle

      when SEND_DATA =>
        if data_sent = '1' then
          nextstate <= WAIT_FOR_PLAINTEXT;
        else
          nextstate <= SEND_DATA;
        end if;

      when WAIT_FOR_PLAINTEXT =>
        if plaintext_ready = '1' then
          nextstate <= ENCRYPT;
        else
          nextstate <= WAIT_FOR_PLAINTEXT;
        end if;

      when others =>
        nextstate <= IDLE;
    end case;
  end process;

  -- Output control logic
  process (currentstate)
  begin
    case currentstate is
      when IDLE => -- Currently Waiting for Key to LOAD via UART RX
        S_IV        <= '0';
        En_IV       <= '0';
        En_Key      <= '1';
        START_LEA   <= '0';
        s_SEND_DATA <= '0';
        o_SM        <= "000";

      when LOAD_KEY => -- Start button is pressed, initiating KEY Loading
        S_IV        <= '0';
        En_IV       <= '0';
        En_Key      <= '0';
        START_LEA   <= '0';
        s_SEND_DATA <= '0';
        o_SM        <= "001";

      when ENCRYPT =>
        S_IV        <= '1'; -- Selecting IV register input from plaintext
        En_IV       <= '0';
        En_Key      <= '0';
        START_LEA   <= '1';
        s_SEND_DATA <= '0';
        o_SM        <= "010";

      when LOAD_IV => -- Loading the next IV
        S_IV        <= '0'; -- Selecting next_IV as the input to the IV register
        En_IV       <= '1'; -- Enable IV register to load next_IV
        En_Key      <= '0';
        START_LEA   <= '0';
        s_SEND_DATA <= '0';
        o_SM        <= "011";

      when SEND_DATA => -- Send Signals to TOP to start Data Transmit
        S_IV        <= '1'; -- Maintain IV register value
        En_IV       <= '0'; -- Disable IV register to hold value
        En_Key      <= '0';
        START_LEA   <= '0';
        s_SEND_DATA <= '1'; -- Start data transmission
        o_SM        <= "100";

      when WAIT_FOR_PLAINTEXT => -- Waiting for Plaintext Ready AKA Data has been received
        S_IV        <= '0';
        En_IV       <= '0';
        En_Key      <= '0';
        START_LEA   <= '0';
        s_SEND_DATA <= '0';
        o_SM        <= "101";

      when others =>
        S_IV        <= '0';
        En_IV       <= '0';
        En_Key      <= '0';
        START_LEA   <= '0';
        s_SEND_DATA <= '0';
    end case;
  end process;
end architecture;