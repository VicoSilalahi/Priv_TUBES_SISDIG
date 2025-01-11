library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity TOP_TEST_RX is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    i_RX_Serial : in std_logic; 
    o_TX_Serial : out std_logic := '1'
  );
end entity;