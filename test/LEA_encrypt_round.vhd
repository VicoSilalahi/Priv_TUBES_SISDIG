library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LEA_encrypt is
  port (
    i_X : in std_logic_vector(127 downto 0);
    i_K : in std_logic_vector(191 downto 0);
    o_C : out std_logic_vector(129 downto 0)
  );
end entity;

architecture rtl of LEA_encrypt is
  type arr is array (natural range <>) of std_logic_vector(31 downto 0);

  signal X    : arr(3 downto 0);
  signal RK   : arr(5 downto 0);
  signal C    : arr(3 downto 0);
  signal X_nr : arr(3 downto 0);
begin
  X(0)  <= i_x(127 downto 96);
  X(1)  <= i_x(95 downto 64);
  X(2)  <= i_x(63 downto 32);
  X(3)  <= i_x(31 downto 0);
  RK(0) <= i_K(191 downto 160);
  RK(1) <= i_K(159 downto 128);
  RK(2) <= i_K(127 downto 96);
  RK(3) <= i_K(95 downto 64);
  RK(4) <= i_K(63 downto 32);
  RK(5) <= i_K(31 downto 0);

  X_nr(0) <= std_logic_vector(SHIFT_LEFT(unsigned(X(0) XOR RK(0)) + unsigned(X(1) XOR RK(1)), 9));
  X_nr(1) <= std_logic_vector(SHIFT_LEFT(unsigned(X(0) XOR RK(0)) + unsigned(X(1) XOR RK(1)), 9));
  X_nr(2) <= std_logic_vector(SHIFT_LEFT(unsigned(X(0) XOR RK(0)) + unsigned(X(1) XOR RK(1)), 9));
  X_nr(3) <= X(0);

  end architecture;