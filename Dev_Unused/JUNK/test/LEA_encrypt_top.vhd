library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LEA_encrypt_top is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    masterkey : in std_logic_vector(128 downto 0);
    plaintext : in std_logic_vector(128 downto 0);
    ciphertext : out std_logic_vector(128 downto 0)
  );
end entity;