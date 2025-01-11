-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 27 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : Cipher Block LEA 128 bit
-- Input    : Plaintext(31 downto 0), Master_Key(31 downto 0), Clock, Start, Stop
-- Output   : Ciphertext(31 downto 0)
-- Note : 
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cypher_block is
  port(
    Plaintext, Master_Key : in std_logic_vector(127 downto 0);
    Start, Stop : in std_logic;
    Clock : in std_logic;
    Ciphertext : out std_logic_vector(127 downto 0);
    o_isdone : out std_logic
  );
end cypher_block;

architecture rtl of cypher_block is
-- Define components

component reverse_32bit_for_LEA_input is
  port (
    A : in std_logic_vector(31 downto 0); -- Input data
    Q : out std_logic_vector(31 downto 0) -- Output data
  );
end component;

component lea_encrypt_fsm is
  port (
    is_done, start, stop, clock : in std_logic; -- sinyal input FSM
    P_MUX, K_MUX, C_MUX, En_Reg_All, En_Counter, Res_Counter, Res_Reg_All : out std_logic -- sinyal output FSM
  );
end component;

component bitwise_xor_32bit is
  port (
    A, B : in std_logic_vector(31 downto 0); -- data yang ingin di-bitwise XOR
    Q : out std_logic_vector(31 downto 0) -- output
  );
end component;

component counter_24_32bit is
  port (
    Clk, En_Counter, Res_Counter : in std_logic;
    Count : out std_logic_vector(4 downto 0);
    is_done : out std_logic
  );
end component;

component modular_addition_32bit is
  port (
    A, B : in std_logic_vector(31 downto 0);
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component mux2to1_32bit is
  port (
    A_0 : in std_logic_vector(31 downto 0); -- Input saat selector '0'
    B_1 : in std_logic_vector(31 downto 0); -- Input saat selector '1'
    Sel : in std_logic; -- Selector MUX
    Data : out std_logic_vector(31 downto 0) -- Output data
  );
end component;

component register_32bit is
  port (
    Clk, En, Res : in std_logic; -- Clk clock, En enable, Res reset
    D : in std_logic_vector (31 downto 0); -- Input data
    Q : out std_logic_vector (31 downto 0) -- Output data
  );
end component;

component rol1_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component rol2_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component rol3_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component rol6_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component rol9_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component rol11_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component ror3_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

component ror5_32bit is
  port (
    A : in std_logic_vector(31 downto 0); -- Input
    Q : out std_logic_vector(31 downto 0)
  );
end component;

-- Define signals
-- Delta initial value
signal delta_0 : std_logic_vector(31 downto 0) := "11000011111011111110100111011011";
signal delta_1 : std_logic_vector(31 downto 0) := "01000100011000100110101100000010";
signal delta_2 : std_logic_vector(31 downto 0) := "01111001111000100111110010001010";
signal delta_3 : std_logic_vector(31 downto 0) := "01111000110111110011000011101100";

-- Control signals
signal is_done_signal : std_logic := '0';
signal start_signal : std_logic := '0';
signal stop_signal : std_logic := '0';
signal P_MUX_signal : std_logic := '0';
signal K_MUX_signal : std_logic := '0';
signal C_MUX_signal : std_logic := '0';
signal En_Reg_All_signal : std_logic := '0';
signal En_Counter_signal : std_logic := '0';
signal Res_Counter_signal : std_logic := '0';
signal Res_Reg_All_signal : std_logic := '0';

-- State representation signal (input plaintext dan master key harus diubah urutannya dulu seperti berikut)
signal Master_Key_for_process_0 : std_logic_vector(31 downto 0);
signal Master_Key_for_process_1 : std_logic_vector(31 downto 0);
signal Master_Key_for_process_2 : std_logic_vector(31 downto 0);
signal Master_Key_for_process_3 : std_logic_vector(31 downto 0);

signal Plaintext_for_process_0 : std_logic_vector(31 downto 0);
signal Plaintext_for_process_1 : std_logic_vector(31 downto 0);
signal Plaintext_for_process_2 : std_logic_vector(31 downto 0);
signal Plaintext_for_process_3 : std_logic_vector(31 downto 0);

signal Ciphertext_after_process_0 : std_logic_vector(31 downto 0);
signal Ciphertext_after_process_1 : std_logic_vector(31 downto 0);
signal Ciphertext_after_process_2 : std_logic_vector(31 downto 0);
signal Ciphertext_after_process_3 : std_logic_vector(31 downto 0);
-- Signals in key schedule
signal output_CMUX0_to_DREG_C0 : std_logic_vector(31 downto 0);
signal QREG_C0 : std_logic_vector(31 downto 0);
signal output_ROL1_to_CMUX_0 : std_logic_vector(31 downto 0);
signal QREG_C1 : std_logic_vector(31 downto 0);
signal output_CMUX1_to_DREG_C1 : std_logic_vector(31 downto 0);
signal QREG_C2 : std_logic_vector(31 downto 0);
signal output_ROL1_to_CMUX_1 : std_logic_vector(31 downto 0);
signal output_CMUX2_to_DREG_C2 : std_logic_vector(31 downto 0);
signal output_ROL1_to_CMUX_2 : std_logic_vector(31 downto 0);
signal QREG_C3 : std_logic_vector(31 downto 0);
signal output_CMUX3_to_DREG_C3 : std_logic_vector(31 downto 0);
signal output_ROL1_to_CMUX_3 : std_logic_vector(31 downto 0);

signal output_ROL1_to_mod_addition_t1 : std_logic_vector(31 downto 0);
signal output_ROL2_to_mod_addition_t2 : std_logic_vector(31 downto 0);
signal output_ROL3_to_mod_addition_t3 : std_logic_vector(31 downto 0);
signal output_ROL1_to_TMUX_0 : std_logic_vector(31 downto 0);
signal output_TMUX0_to_DREG_T0 : std_logic_vector(31 downto 0);
signal QREG_T0 : std_logic_vector(31 downto 0);
signal output_ROL3_to_TMUX_1 : std_logic_vector(31 downto 0);
signal output_TMUX1_to_DREG_T1 : std_logic_vector(31 downto 0);
signal QREG_T1 : std_logic_vector(31 downto 0);
signal output_ROL6_to_TMUX_2 : std_logic_vector(31 downto 0);
signal output_TMUX2_to_DREG_T2 : std_logic_vector(31 downto 0);
signal QREG_T2 : std_logic_vector(31 downto 0);
signal output_ROL11_to_TMUX_3 : std_logic_vector(31 downto 0);
signal output_TMUX3_to_DREG_T3 : std_logic_vector(31 downto 0);
signal QREG_T3 : std_logic_vector(31 downto 0);

signal QMOD_ADD_T0 : STD_LOGIC_VECTOR(31 downto 0);
signal QMOD_ADD_T1 : STD_LOGIC_VECTOR(31 downto 0);
signal QMOD_ADD_T2 : STD_LOGIC_VECTOR(31 downto 0);
signal QMOD_ADD_T3 : STD_LOGIC_VECTOR(31 downto 0);

-- Signal round keys
signal RK0 : STD_LOGIC_VECTOR(31 downto 0);
signal RK1 : STD_LOGIC_VECTOR(31 downto 0);
signal RK2 : STD_LOGIC_VECTOR(31 downto 0);
signal RK3 : STD_LOGIC_VECTOR(31 downto 0);
signal RK4 : STD_LOGIC_VECTOR(31 downto 0);
signal RK5 : STD_LOGIC_VECTOR(31 downto 0);

-- Signal round function
signal output_ROL9_to_PMUX_0 : STD_LOGIC_VECTOR(31 downto 0);
signal output_PMUX0_to_DREG_P0 : STD_LOGIC_VECTOR(31 downto 0);
signal QREG_P0 : STD_LOGIC_VECTOR(31 downto 0);
signal output_ROR5_to_PMUX_1 : STD_LOGIC_VECTOR(31 downto 0);
signal output_PMUX1_to_DREG_P1 : STD_LOGIC_VECTOR(31 downto 0);
signal QREG_P1 : STD_LOGIC_VECTOR(31 downto 0);
signal output_ROR3_to_PMUX_2 : STD_LOGIC_VECTOR(31 downto 0);
signal output_PMUX2_to_DREG_P2 : STD_LOGIC_VECTOR(31 downto 0);
signal QREG_P2 : STD_LOGIC_VECTOR(31 downto 0);
signal output_PMUX3_to_DREG_P3 : STD_LOGIC_VECTOR(31 downto 0);
signal QREG_P3 : STD_LOGIC_VECTOR(31 downto 0);
signal QXOR_X0_RK_0 : STD_LOGIC_VECTOR(31 downto 0);
signal QXOR_X1_RK_1 : STD_LOGIC_VECTOR(31 downto 0);
signal QXOR_X1_RK_2 : STD_LOGIC_VECTOR(31 downto 0);
signal QXOR_X2_RK_3 : STD_LOGIC_VECTOR(31 downto 0);
signal QXOR_X2_RK_4 : STD_LOGIC_VECTOR(31 downto 0);
signal QXOR_X3_RK_5 : STD_LOGIC_VECTOR(31 downto 0);
signal QMOD_ADD_XOR_0_XOR_1 : STD_LOGIC_VECTOR(31 downto 0);
signal QMOD_ADD_XOR_2_XOR_3 : STD_LOGIC_VECTOR(31 downto 0);
signal QMOD_ADD_XOR_4_XOR_5 : STD_LOGIC_VECTOR(31 downto 0);

-- Unused signal (dump)
signal count_not_used_signal : std_logic_vector(4 downto 0) := (others => '0');

begin
-- Perubahan urutan per byte untuk plaintext, master key untuk diproses
-- Untuk master key
K_0: reverse_32bit_for_LEA_input
 port map(
    A => Master_Key(127 downto 96),
    Q => Master_Key_for_process_0
);
K_1: reverse_32bit_for_LEA_input
 port map(
    A => Master_Key(95 downto 64),
    Q => Master_Key_for_process_1
);
K_2: reverse_32bit_for_LEA_input
 port map(
    A => Master_Key(63 downto 32),
    Q => Master_Key_for_process_2
);
K_3: reverse_32bit_for_LEA_input
 port map(
    A => Master_Key(31 downto 0),
    Q => Master_Key_for_process_3
);

-- Untuk Plaintext
P_0: reverse_32bit_for_LEA_input
 port map(
    A => Plaintext(127 downto 96),
    Q => Plaintext_for_process_0
);
P_1: reverse_32bit_for_LEA_input
 port map(
    A => Plaintext(95 downto 64),
    Q => Plaintext_for_process_1
);
P_2: reverse_32bit_for_LEA_input
 port map(
    A => Plaintext(63 downto 32),
    Q => Plaintext_for_process_2
);
P_3: reverse_32bit_for_LEA_input
 port map(
    A => Plaintext(31 downto 0),
    Q => Plaintext_for_process_3
);

-- Untuk Cipherblock yg akan disambung ke port out, maka harus didubah lagi urutannya
C_0: reverse_32bit_for_LEA_input
 port map(
    A => QREG_P0,
    Q => Ciphertext_after_process_0
);
C_1: reverse_32bit_for_LEA_input
 port map(
    A => QREG_P1,
    Q => Ciphertext_after_process_1
);
C_2: reverse_32bit_for_LEA_input
 port map(
    A => QREG_P2,
    Q => Ciphertext_after_process_2
);
C_3: reverse_32bit_for_LEA_input
 port map(
    A => QREG_P3,
    Q => Ciphertext_after_process_3
);

-- Bagian FSM
CONTROL_CIRCUIT : lea_encrypt_fsm
 port map(
    is_done => is_done_signal,
    start => start_signal,
    stop => stop_signal,
    clock => Clock,
    P_MUX => P_MUX_signal,
    K_MUX => K_MUX_signal,
    C_MUX => C_MUX_signal,
    En_Reg_All => En_Reg_All_signal,
    En_Counter => En_Counter_signal,
    Res_Counter => Res_Counter_signal,
    Res_Reg_All => Res_Reg_All_signal
);
start_signal <= Start;
stop_signal <= Stop;
o_isdone <= is_done_signal;

-- Bagian counter
counter_24_32bit_inst: counter_24_32bit
 port map(
    Clk => Clock,
    En_Counter => En_Counter_signal,
    Res_Counter => Res_Counter_signal,
    Count => count_not_used_signal,
    is_done => is_done_signal
);

-- Bagian key schedule
-- Bagian konstanta
REG_C0 : register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_CMUX0_to_DREG_C0,
    Q => QREG_C0
);

C_MUX0: mux2to1_32bit
 port map(
    A_0 => delta_0,
    B_1 => output_ROL1_to_CMUX_0,
    Sel => C_MUX_signal,
    Data => output_CMUX0_to_DREG_C0
);

ROL1_CMUX_0: rol1_32bit
 port map(
    A => QREG_C1,
    Q => output_ROL1_to_CMUX_0
);

REG_C1: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_CMUX1_to_DREG_C1,
    Q => QREG_C1
);

C_MUX1: mux2to1_32bit
 port map(
    A_0 => delta_1,
    B_1 => output_ROL1_to_CMUX_1,
    Sel => C_MUX_signal,
    Data => output_CMUX1_to_DREG_C1
);

ROL1_CMUX_1: rol1_32bit
 port map(
    A => QREG_C2,
    Q => output_ROL1_to_CMUX_1
);

REG_C2: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_CMUX2_to_DREG_C2,
    Q => QREG_C2
);

C_MUX2 : mux2to1_32bit
 port map(
    A_0 => delta_2,
    B_1 => output_ROL1_to_CMUX_2,
    Sel => C_MUX_signal,
    Data => output_CMUX2_to_DREG_C2
);

ROL1_CMUX_2: rol1_32bit
 port map(
    A => QREG_C3,
    Q => output_ROL1_to_CMUX_2
);

REG_C3: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_CMUX3_to_DREG_C3,
    Q => QREG_C3
);

C_MUX3: mux2to1_32bit
 port map(
    A_0 => delta_3,
    B_1 => output_ROL1_to_CMUX_3,
    Sel => C_MUX_signal,
    Data => output_CMUX3_to_DREG_C3
);

ROL1_CMUX_3: rol1_32bit
 port map(
    A => QREG_C0,
    Q => output_ROL1_to_CMUX_3
);
-- Bagian T
ROL1_T1: rol1_32bit
 port map(
    A => QREG_C0,
    Q => output_ROL1_to_mod_addition_t1
);

ROL2_T2: rol2_32bit
 port map(
    A => QREG_C0,
    Q => output_ROL2_to_mod_addition_t2
);

ROL3_T3: rol3_32bit
 port map(
    A => QREG_C0,
    Q => output_ROL3_to_mod_addition_t3
);

T_MUX0: mux2to1_32bit
 port map(
    A_0 => Master_Key_for_process_0, -- T0 adalah bagian MSB, dimasukkan urutan seperti ini
    B_1 => output_ROL1_to_TMUX_0,
    Sel => K_MUX_signal,
    Data => output_TMUX0_to_DREG_T0
);

REG_T0: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_TMUX0_to_DREG_T0,
    Q => QREG_T0
);

T_MUX1: mux2to1_32bit
 port map(
    A_0 => Master_Key_for_process_1,
    B_1 => output_ROL3_to_TMUX_1,
    Sel => K_MUX_signal,
    Data => output_TMUX1_to_DREG_T1
);

REG_T1: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_TMUX1_to_DREG_T1,
    Q => QREG_T1
);

T_MUX2: mux2to1_32bit
 port map(
    A_0 => Master_Key_for_process_2,
    B_1 => output_ROL6_to_TMUX_2,
    Sel => K_MUX_signal,
    Data => output_TMUX2_to_DREG_T2
);

REG_T2: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_TMUX2_to_DREG_T2,
    Q => QREG_T2
);

T_MUX3: mux2to1_32bit
 port map(
    A_0 => Master_Key_for_process_3,
    B_1 => output_ROL11_to_TMUX_3,
    Sel => K_MUX_signal,
    Data => output_TMUX3_to_DREG_T3
);

REG_T3: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_TMUX3_to_DREG_T3,
    Q => QREG_T3
);

MOD_ADDITION_T0: modular_addition_32bit
 port map(
    A => QREG_C0,
    B => QREG_T0,
    Q => QMOD_ADD_T0
);

MOD_ADDITION_T1: modular_addition_32bit
 port map(
    A => output_ROL1_to_mod_addition_t1,
    B => QREG_T1,
    Q => QMOD_ADD_T1
);

MOD_ADDITION_T2: modular_addition_32bit
 port map(
    A => output_ROL2_to_mod_addition_t2,
    B => QREG_T2,
    Q => QMOD_ADD_T2
);

MOD_ADDITION_T3: modular_addition_32bit
 port map(
    A => output_ROL3_to_mod_addition_t3,
    B => QREG_T3,
    Q => QMOD_ADD_T3
);

ROL1_MOD_ADDITION_T0: rol1_32bit
 port map(
    A => QMOD_ADD_T0,
    Q => output_ROL1_to_TMUX_0
);

ROL3_MOD_ADDITION_T1: rol3_32bit
 port map(
    A => QMOD_ADD_T1,
    Q => output_ROL3_to_TMUX_1
);

ROL6_MOD_ADDITION_T2: rol6_32bit
 port map(
    A => QMOD_ADD_T2,
    Q => output_ROL6_to_TMUX_2
);

ROL11_MOD_ADDITION_T3: rol11_32bit
 port map(
    A => QMOD_ADD_T3,
    Q => output_ROL11_to_TMUX_3
);

-- Round Keys
RK0 <= output_ROL1_to_TMUX_0;
RK1 <= output_ROL3_to_TMUX_1;
RK2 <= output_ROL6_to_TMUX_2;
RK3 <= output_ROL3_to_TMUX_1;
RK4 <= output_ROL11_to_TMUX_3;
RK5 <= output_ROL3_to_TMUX_1;

-- Bagian round function
P_MUX0: mux2to1_32bit
 port map(
    A_0 => Plaintext_for_process_0, -- Sinyal yang sudah diubah urutan bitnya agar sesuai spesifikasi
    B_1 => output_ROL9_to_PMUX_0,
    Sel => P_MUX_signal,
    Data => output_PMUX0_to_DREG_P0 
);

REG_P0: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_PMUX0_to_DREG_P0,
    Q => QREG_P0
);

P_MUX1: mux2to1_32bit
 port map(
    A_0 => Plaintext_for_process_1,
    B_1 => output_ROR5_to_PMUX_1,
    Sel => P_MUX_signal,
    Data => output_PMUX1_to_DREG_P1
);

REG_P1: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_PMUX1_to_DREG_P1,
    Q => QREG_P1
);

P_MUX2: mux2to1_32bit
 port map(
    A_0 => Plaintext_for_process_2,
    B_1 => output_ROR3_to_PMUX_2,
    Sel => P_MUX_signal,
    Data => output_PMUX2_to_DREG_P2
);

REG_P2: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_PMUX2_to_DREG_P2,
    Q => QREG_P2
);

P_MUX3: mux2to1_32bit
 port map(
    A_0 => Plaintext_for_process_3,
    B_1 => QREG_P0,
    Sel => P_MUX_signal,
    Data => output_PMUX3_to_DREG_P3
);

REG_P3: register_32bit
 port map(
    Clk => Clock,
    En => En_Reg_All_signal,
    Res => Res_Reg_All_signal,
    D => output_PMUX3_to_DREG_P3,
    Q => QREG_P3
);

XOR_X0_RK_0: bitwise_xor_32bit
 port map(
    A => QREG_P0,
    B => RK0,
    Q => QXOR_X0_RK_0
);

XOR_X1_RK_1: bitwise_xor_32bit
 port map(
    A => QREG_P1,
    B => RK1,
    Q => QXOR_X1_RK_1
);

XOR_X1_RK_2: bitwise_xor_32bit
 port map(
    A => QREG_P1,
    B => RK2,
    Q => QXOR_X1_RK_2
);

XOR_X2_RK_3: bitwise_xor_32bit
 port map(
    A => QREG_P2,
    B => RK3,
    Q => QXOR_X2_RK_3
);

XOR_X2_RK_4: bitwise_xor_32bit
 port map(
    A => QREG_P2,
    B => RK4,
    Q => QXOR_X2_RK_4
);

XOR_X3_RK_5: bitwise_xor_32bit
 port map(
    A => QREG_P3,
    B => RK5,
    Q => QXOR_X3_RK_5
);

MOD_ADD_XOR_0_XOR_1: modular_addition_32bit
 port map(
    A => QXOR_X0_RK_0,
    B => QXOR_X1_RK_1,
    Q => QMOD_ADD_XOR_0_XOR_1
);

MOD_ADD_XOR_2_XOR_3: modular_addition_32bit
 port map(
    A => QXOR_X1_RK_2,
    B => QXOR_X2_RK_3,
    Q => QMOD_ADD_XOR_2_XOR_3
);

MOD_ADD_XOR_4_XOR_5: modular_addition_32bit
 port map(
    A => QXOR_X2_RK_4,
    B => QXOR_X3_RK_5,
    Q => QMOD_ADD_XOR_4_XOR_5
);

ROL9_TO_PMUX_0: rol9_32bit
 port map(
    A => QMOD_ADD_XOR_0_XOR_1,
    Q => output_ROL9_to_PMUX_0
);

ROR5_TO_PMUX_1: ror5_32bit
 port map(
    A => QMOD_ADD_XOR_2_XOR_3,
    Q => output_ROR5_to_PMUX_1
);

ROR3_TO_PMUX_2: ror3_32bit
 port map(
    A => QMOD_ADD_XOR_4_XOR_5,
    Q => output_ROR3_to_PMUX_2
);

-- Output Machine
Ciphertext(127 downto 96) <= Ciphertext_after_process_0; -- C0
Ciphertext(95 downto 64) <= Ciphertext_after_process_1; -- C1
Ciphertext(63 downto 32) <= Ciphertext_after_process_2; -- C2
Ciphertext(31 downto 0) <= Ciphertext_after_process_3; -- C3

end architecture;