library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
  port (
    clk        : in std_logic;
    reset      : in std_logic;
    start      : in std_logic;
    masterkey  : in std_logic_vector(127 downto 0);
    plaintext  : in std_logic_vector(127 downto 0);
    ciphertext : out std_logic_vector(127 downto 0)
  );
end entity;

architecture rtl of top is
  component LEA_encrypt is -- Main component of LEA-128 Encryption
    port (
      Plaintext, Master_Key : in std_logic_vector(127 downto 0);
      Start                 : in std_logic; -- Signal to initiate the beginning of encryption
      Stop                  : in std_logic; -- ToDo: TO BE DETERMINED WHETHER USEFUL OR NOT
      Clock                 : in std_logic;
      Ciphertext            : out std_logic_vector(127 downto 0); -- Output of LEA-128 Encryption. NOT FINAL CIPHERTEXT
      o_isdone              : out std_logic -- Signal output when 24 rounds are done, ToDo: Determine the behavior to FSM
    );
  end component;

  component register_128bit is -- Register to hold the values of IV and Key on the top entity
    port (
      Clk, En, Res : in std_logic;
      D            : in std_logic_vector (127 downto 0);
      Q            : out std_logic_vector (127 downto 0)
    );
  end component;

  component mux2to1_128bit is -- Multiplexer 2 in 2 out for data size 128-bit
    port (
      A_0  : in std_logic_vector(127 downto 0);
      B_1  : in std_logic_vector(127 downto 0);
      Sel  : in std_logic;
      Data : out std_logic_vector(127 downto 0)
    );
  end component;

  -- Top Entity Output
  signal S_IN, S_IV, En_IV, En_Key, DataValid, START_LEA, STOP_LEA : std_logic := '0';
  -- type arr is array (natural range <>) of std_logic_vector(31 downto 0);
  -- signal T, X : arr(3 downto 0);
  signal T, X, C : std_logic_vector(127 downto 0);

  -- Top Entity Input
  -- To be used when UART is Ready
  signal is_busy : std_logic;
  -- Future ToDo:
  signal isdone : std_logic;

  -- initialization Vector
  constant IV : std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";

  -- Value for the next Inisialization Vector to be fed into LEA-128, Produce of XOR-ing LEA-128 output and Plaintext
  -- Which means it's the same as Ciphertext
  signal next_IV : std_logic_vector(127 downto 0);

  signal OutMUXIV : std_logic_vector(127 downto 0);

  -- Top Entity FSM
  type state is (IDLE, REGKEY, LEA);
  signal currentstate, nextstate : state := IDLE;
  /*
  Currentstate: 
  */

begin
  -- Register for Masterkey Input, Will not change except when reset
  Key : register_128bit
  port map
  (
    Clk => Clk,
    En  => En_Key, -- Enable Signal, will be on only when loading the Masterkey, which is at the beginning, and reset
    Res => reset, -- Activated or not is fine, because UART Input will changeit anyways
    D   => masterkey,
    Q   => T
  );

  -- Register for Plaintext/initialization Vector input, Will Change after every complete encryption
  Ptx : register_128bit
  port map
  (
    Clk => Clk,
    En  => En_IV, -- Enable Signal, will be on when loading the next plaintext value from UART
    Res => reset,
    D   => OutMUXIV, -- Input from Multiplexer IVMUX
    Q   => X -- To Be Fed into LEA-128 Encryption as "Plaintext" for the next iteration of Encryption
  );

  -- Initialization Vector 
  next_IV <= plaintext xor C;

  IVMUX : mux2to1_128bit -- Multiplexer for the next IV to be fed into LEA-128
  port map
  (
    A_0  => next_IV, -- Feedback from LEA-128 XOR'ed with Input Plaintext
    B_1  => IV, -- Const IV of 128'h0
    Sel  => S_IV, -- Selector with '0' selecting A, and '1' selecting B
    Data => OutMUXIV -- Output to be fed into IV Register
  );

  -- LEA Encryption for 128-bit Masterkey
  LEA_encrypt_inst : LEA_encrypt
  port map
  (
    Plaintext  => X, -- Plaintext to be fed into the LEA-128. INPUT FROM 
    Master_Key => T, -- Masterkey of 128-bit, which will be key scheduled into 192-bit. Value of master-key won't change
    Start      => START_LEA, -- Signal to initiate the begining of encryption process
    Stop       => STOP_LEA, -- To be determined whether useful or not
    Clock      => Clk,
    Ciphertext => C, -- Output of the LEA-128 Encryption. To be XOR'ed with Actual Plaintext
    o_isdone   => isdone -- Output signal on which is '1' when all 24 rounds are done, to be fed into the top entity FSM
  );

  process (clk)
  begin
    if rising_edge(clk) then
      currentstate <= nextstate;
      case currentstate is
        when IDLE =>
          if start = '1' then
            nextstate <= REGKEY;
          else
            nextstate <= IDLE;
          end if;

        when REGKEY =>
          nextstate <= LEA;
        when LEA =>
          if reset = '1' then
            nextstate <= IDLE;
          else
            nextstate <= LEA;
          end if;
        when others =>
          nextstate <= IDLE;
      end case;
    end if;
  end process;

  process (currentstate)
  begin
    if currentstate = IDLE then
      S_IV      <= '0';
      en_IV     <= '1';
      en_KEY    <= '1';
      START_LEA <= '0';
    elsif currentstate = REGKEY then
      S_IV      <= '0';
      en_IV     <= '0';
      en_KEY    <= '0';
      START_LEA <= '0';
    elsif currentstate = LEA then
      S_IV      <= '1';
      en_IV     <= '1';
      en_KEY    <= '0';
      START_LEA <= '1';
    end if;
  end process;

end architecture;

/*
ToDO
1. FSM For Top Entity
    Signals:
        S_IV: Controls the multiplexer to select the IV source.
        En_IV, En_Key: Enable signals for the IV and key registers.
        START_LEA: Initiates the encryption process.
        isdone: Indicates the completion of the encryption by the LEA_encrypt component.

Proposed FSM:

States:

    IDLE: The initial state. Waits for the start signal.
    LOAD_KEY: Loads the master key from the UART (not yet implemented).
    ENCRYPT: Initiates the LEA_encrypt process.
    SEND_DATA: Sends the ciphertext to the PC via UART (not yet implemented).
    WAIT_FOR_PLAINTEXT: Waits for the next plaintext input from the PC.

State Transitions:

    IDLE -> LOAD_KEY: Upon receiving the start signal, transition to the LOAD_KEY state.
    LOAD_KEY -> ENCRYPT: After loading the master key, transition to the ENCRYPT state.
    ENCRYPT -> SEND_DATA: When the isdone signal from LEA_encrypt is asserted, transition to the SEND_DATA state.
    SEND_DATA -> WAIT_FOR_PLAINTEXT: After sending the ciphertext, transition to the WAIT_FOR_PLAINTEXT state.
    WAIT_FOR_PLAINTEXT -> ENCRYPT: Upon receiving the next plaintext from the PC, transition back to the ENCRYPT state.

State Actions:

    IDLE:
        Set S_IV to '0' to select the initial IV.
        Enable the key register (En_Key) to load the master key.
        Disable the IV register (En_IV).
        Deassert START_LEA.
    LOAD_KEY:
        Set S_IV to '0'.
        Disable the key register (En_Key).
        Disable the IV register (En_IV).
        Deassert START_LEA.
    ENCRYPT:
        Set S_IV to '1' to select the calculated next IV.
        Enable the IV register (En_IV).
        Disable the key register (En_Key).
        Assert START_LEA to initiate encryption.
    SEND_DATA:
        Set S_IV to '1'.
        Disable the key register (En_Key).
        Disable the IV register (En_IV).
        Deassert START_LEA.
        Send the ciphertext to the PC via UART (not yet implemented).
    WAIT_FOR_PLAINTEXT:
        Set S_IV to '0'.
        Disable the key register (En_Key).
        Disable the IV register (En_IV).
        Deassert START_LEA.
        Wait for the next plaintext input from the PC.



*/