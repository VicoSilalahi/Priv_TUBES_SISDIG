------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB
--
-- Didasarkan dari kode milik Adrian Sami Pratama - 13223074
-- Dibuat ulang oleh Vico A.C. Silalahi - 13223067
--
------------------------------------------------------------------------------------------------------------------------
-- Deskripsi
-- Kode merupakan RTL daripada Datapath LEA-128-SPEED yang didapat dari
-- Efficient Hardware Implementation of the Lightweight Block Encryption Algorithm LEA
-- DOI: 10.3390/s140100975
--
-- Fungsi    : LEA-128 Enkripsi beserta dengan Key-Scheduling dan Round Function
-- Input     : i_clk, i_start, i_reset       : std_logic
--           : i_plaintext, i_masterkey      : std_logic_vector(127 downto 0)
-- Output    : o_ciphertext                  : std_logic_vector(127 downto 0)
--           : o_isdone
--
------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LEA_128 is
  port (
    i_clk                    : in std_logic;
    i_start, i_reset         : in std_logic;
    i_plaintext, i_masterkey : in std_logic_vector(127 downto 0);
    o_ciphertext             : out std_logic_vector(127 downto 0);
    o_isdone                 : out std_logic
  );
end entity;

architecture rtl of LEA_128 is

  -- State Representation of LEA-128
  component reverseinput is
    port (
      A : in std_logic_vector(127 downto 0);
      B : out std_logic_vector(127 downto 0)
    );
  end component;

  -- FSM Component Declaration
  component lea_encrypt_fsm is
    port (
      is_done, start, stop, clock                                           : in std_logic;
      P_MUX, K_MUX, C_MUX, En_Reg_All, En_Counter, Res_Counter, Res_Reg_All : out std_logic
    );
  end component;

  component mux2to1_32bit is
    port (
      i_A  : in std_logic_vector(31 downto 0);
      i_B  : in std_logic_vector(31 downto 0);
      i_S  : in std_logic; -- Data input selector -> '0' will select A, '1' will select B
      o_C : out std_logic_vector(31 downto 0)
    );
  end component;

  component register_32bit is
    port (
      Clk, En, Res : in std_logic;
      D            : in std_logic_vector (31 downto 0); -- Input data
      Q            : out std_logic_vector (31 downto 0) -- Output data
    );
  end component;

  component counter_24 is
    port (
      clk    : in std_logic;
      enable : in std_logic;
      reset  : in std_logic;
      isdone : out std_logic
    );
  end component;

  type Arr32 is array (natural range <>) of std_logic_vector(31 downto 0);
  -- Delta Constants
  constant delta : Arr32(3 downto 0) := (x"78DF30EC", x"79E27C8A", x"44626B02", x"C3EFE9DB");

  -- FSM Signals

  type SM is (S1, S2, S3, S4);
  signal currentstate, nextstate : SM := S1;

  signal s_isdone      : std_logic := '0';
  signal s_start       : std_logic := '0';
  signal s_reset       : std_logic := '0';
  signal s_PMUX        : std_logic := '0';
  signal s_KMUX        : std_logic := '0';
  signal s_CMUX        : std_logic := '0';
  signal s_En_Reg_All  : std_logic := '0';
  signal s_En_Ctr      : std_logic := '0';
  signal s_Res_Reg_All : std_logic := '0';
  signal s_Res_Ctr     : std_logic := '0';

  -- Internal Input and Output
  signal s_masterkey  : Arr32(3 downto 0);
  signal s_plaintext  : Arr32(3 downto 0);
  signal s_ciphertext : Arr32(3 downto 0);

  -- Constant Wires (Intermediary) Signals
  signal w_out_CMUX : Arr32(3 downto 0);
  signal w_C        : Arr32(3 downto 0);
  signal w_in_CMUX  : Arr32(3 downto 0);

  signal w_out_TMUX : Arr32(3 downto 0);
  signal w_T        : Arr32(3 downto 0);
  signal w_in_TMUX  : Arr32(3 downto 0);

  signal w_out_PMUX : Arr32(3 downto 0);
  signal w_P        : Arr32(3 downto 0);
  signal w_in_PMUX  : Arr32(2 downto 0);

  -- Roundkey(192-bit)
  signal s_RoundKey : Arr32(5 downto 0);

begin
  -- Masterkey State Representation Component Declaration
  Masterkey_State_Representation : reverseinput
  port map
  (
    A                => i_masterkey,
    B(127 downto 96) => s_masterkey(3),
    B(95 downto 64)  => s_masterkey(2),
    B(63 downto 32)  => s_masterkey(1),
    B(31 downto 0)   => s_masterkey(0)
  );

  -- Plaintext State Representation Component Declaration
  Plaintext_State_Representation : reverseinput
  port map
  (
    A                => i_plaintext,
    B(127 downto 96) => s_plaintext(3),
    B(95 downto 64)  => s_plaintext(2),
    B(63 downto 32)  => s_plaintext(1),
    B(31 downto 0)   => s_plaintext(0)
  );

  -- Ciphertext State Representation Component Declaration
  Ciphertext_State_Representation : reverseinput
  port map
  (
    A(127 downto 96) => w_P(0),
    A(95 downto 64)  => w_P(1),
    A(63 downto 32)  => w_P(2),
    A(31 downto 0)   => w_P(3),
    B(127 downto 96) => s_ciphertext(3),
    B(95 downto 64)  => s_ciphertext(2),
    B(63 downto 32)  => s_ciphertext(1),
    B(31 downto 0)   => s_ciphertext(0)
  );

  s_start  <= i_start;
  s_reset  <= i_reset;
  o_isdone <= s_isdone;

  -- Counter Component Declaration
  counter_24_inst : counter_24
  port map
  (
    clk    => i_clk,
    enable => s_En_Ctr,
    reset  => s_Res_Ctr,
    isdone => s_isdone
  );
  -- Constant Rolling Section
  -- Constant Register Component Declaration
  gen_C_Registers : for i in 0 to 3 generate
    C_Register : register_32bit
    port map
    (
      Clk => i_clk,
      En  => s_En_Reg_All,
      Res => s_Res_Reg_All,
      D   => w_out_CMUX(i),
      Q   => w_C(i)
    );
  end generate;

  gen_C_Multiplexers : for i in 0 to 3 generate
    C_Multiplexer : mux2to1_32bit
    port map
    (
      i_A  => delta(i),
      i_B  => w_in_CMUX(i),
      i_S  => s_CMUX,
      o_C => w_out_CMUX(i)
    );
  end generate;

  gen_in_CMUXs : for i in 0 to 3 generate
    w_in_CMUX(i) <= std_logic_vector(unsigned(w_C((i + 1) mod 4)) rol 1);
  end generate;
  -- T Section

  gen_T_Registers : for i in 0 to 3 generate
    T_Register : register_32bit
    port map
    (
      Clk => i_clk,
      En  => s_En_Reg_All,
      Res => s_Res_Reg_All,
      D   => w_out_TMUX(i),
      Q   => w_T(i)
    );
  end generate;

  gen_T_Multiplexers : for i in 0 to 3 generate
    T_Multiplexer : mux2to1_32bit
    port map
    (
      i_A  => s_masterkey(i),
      i_B  => w_in_TMUX(i),
      i_S  => s_KMUX,
      o_C => w_out_TMUX(i)
    );
  end generate;

  -- Next T and Round Key Parts
  w_in_TMUX(0) <= std_logic_vector((unsigned(w_C(0)) + unsigned(w_T(0))) rol 1);
  w_in_TMUX(1) <= std_logic_vector(((unsigned(w_C(0)) rol 1) + unsigned(w_T(1))) rol 3);
  w_in_TMUX(2) <= std_logic_vector(((unsigned(w_C(0)) rol 2) + unsigned(w_T(2))) rol 6);
  w_in_TMUX(3) <= std_logic_vector(((unsigned(w_C(0)) rol 3) + unsigned(w_T(3))) rol 11);

  s_RoundKey(0) <= w_in_TMUX(0);
  s_RoundKey(1) <= w_in_TMUX(1);
  s_RoundKey(2) <= w_in_TMUX(2);
  s_RoundKey(3) <= w_in_TMUX(1);
  s_RoundKey(4) <= w_in_TMUX(3);
  s_RoundKey(5) <= w_in_TMUX(1);

  -- Round Function Section
  gen_P_Multiplexers : for i in 0 to 2 generate
    P_Multiplexer : mux2to1_32bit
    port map
    (
      i_A  => s_plaintext(i),
      i_B  => w_in_PMUX(i),
      i_S  => s_PMUX,
      o_C => w_out_PMUX(i)
    );
  end generate;

  PMUX3 : mux2to1_32bit
  port map
  (
    i_A  => s_plaintext(3),
    i_B  => w_P(0),
    i_S  => s_PMUX,
    o_C => w_out_PMUX(3)
  );

  gen_P_Registers : for i in 0 to 3 generate
    P_Register : register_32bit
    port map
    (
      Clk => i_clk,
      En  => s_En_Reg_All,
      Res => s_Res_Reg_All,
      D   => w_out_PMUX(i),
      Q   => w_P(i)
    );
  end generate;

  w_in_PMUX(0) <= std_logic_vector((unsigned(w_P(0) xor s_RoundKey(0)) + unsigned(w_P(1) xor s_RoundKey(1))) rol 9);
  w_in_PMUX(1) <= std_logic_vector(unsigned(w_P(1) xor s_RoundKey(2)) + unsigned(w_P(2) xor s_RoundKey(3)) ror 5);
  w_in_PMUX(2) <= std_logic_vector(unsigned(w_P(2) xor s_RoundKey(4)) + unsigned(w_P(3) xor s_RoundKey(5)) ror 3);

  o_ciphertext(127 downto 96) <= s_ciphertext(0);
  o_ciphertext(95 downto 64)  <= s_ciphertext(1);
  o_ciphertext(63 downto 32)  <= s_ciphertext(2);
  o_ciphertext(31 downto 0)   <= s_ciphertext(3);

  -- FSM CONTROL
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      currentstate <= nextstate;
    end if;
  end process;

  process (currentstate, s_start, s_isdone)
  begin
    case currentstate is
      when S1 =>
        if s_start = '1' then
          nextstate <= S2;
        else
          nextstate <= S1;
        end if;
      when S2 =>
        if s_isdone = '1' then
          nextstate <= S3;
        else
          nextstate <= S2;
        end if;
      when S3 =>
        nextstate <= S4;
      when S4 =>
        nextstate <= S1;
    end case;
  end process;

  process (currentstate) -- Output untuk setiap state
  begin
    if currentstate = S1 then -- Output state awal
      s_PMUX             <= '0';
      s_KMUX             <= '0';
      s_CMUX             <= '0';
      s_En_Reg_All       <= '1';
      s_En_Ctr           <= '0';
      s_Res_Ctr          <= '0';
      s_Res_Reg_All      <= '0';
    elsif currentstate <= S2 then -- Output state saat proses round function
      s_PMUX             <= '1';
      s_KMUX             <= '1';
      s_CMUX             <= '1';
      s_En_Reg_All       <= '1';
      s_En_Ctr           <= '1';
      s_Res_Ctr          <= '0';
      s_Res_Reg_All      <= '0';
    elsif currentstate <= S3 then -- Output saat sudah selesai proses enkripsi
      s_PMUX             <= '1';
      s_KMUX             <= '1';
      s_CMUX             <= '1';
      s_En_Reg_All       <= '0';
      s_En_Ctr           <= '0';
      s_Res_Ctr          <= '0';
      s_Res_Reg_All      <= '0';
    elsif currentstate <= S4 then -- Output saat direset
      s_PMUX             <= '0';
      s_KMUX             <= '0';
      s_CMUX             <= '0';
      s_En_Reg_All       <= '0';
      s_En_Ctr           <= '0';
      s_Res_Ctr          <= '1';
      s_Res_Reg_All      <= '0';
    end if;
  end process;
end architecture;