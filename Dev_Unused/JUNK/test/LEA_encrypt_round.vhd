library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LEA_encrypt is
  port (
    i_plaintext     : in std_logic_vector(127 downto 0);
    i_masterkey     : in std_logic_vector(127 downto 0);
    i_clk           : in std_logic;
    i_start, i_stop : in std_logic;
    o_ciphertext    : out std_logic_vector(127 downto 0)
  );
end entity;

architecture rtl of LEA_encrypt is
  type arr is array (natural range <>) of std_logic_vector(31 downto 0);

  constant delta : arr (3 downto 0) := ("01111000110111110011000011101100", "01111001111000100111110010001010", "01000100011000100110101100000010", "11000011111011111110100111011011");

  signal is_done, START_LEA, STOP_LEA                     : std_logic := '0';
  signal P_MUX, K_MUX, C_MUX                              : std_logic := '0';
  signal En_Reg_All, Res_Reg_All, En_Counter, Res_Counter : std_logic := '0';

  signal s_Master_key : arr(3 downto 0);
  signal s_Plaintext  : arr(3 downto 0);
  signal s_Ciphertext : arr(3 downto 0);

  -- output_CMUXi_to_DREG_Ci
  signal T : arr(3 downto 0);
  -- QREG_Ci
  signal C : arr(3 downto 0);




  
begin

end architecture;