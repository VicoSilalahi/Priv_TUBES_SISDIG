library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reverse_32bit_for_LEA_input is
    port (
        A : in std_logic_vector(31 downto 0); -- Input data
        Q : out std_logic_vector(31 downto 0) -- Output data
    );
end reverse_32bit_for_LEA_input;

architecture rtl of reverse_32bit_for_LEA_input is

begin
-- 8 bit ke 3
Q(31) <= A(7);
Q(30) <= A(6);
Q(29) <= A(5);
Q(28) <= A(4);
Q(27) <= A(3);
Q(26) <= A(2);
Q(25) <= A(1);
Q(24) <= A(0);
-- 8 bit ke 2
Q(23) <= A(15);
Q(22) <= A(14);
Q(21) <= A(13);
Q(20) <= A(12);
Q(19) <= A(11);
Q(18) <= A(10);
Q(17) <= A(9);
Q(16) <= A(8);
-- 8 bit ke 1
Q(15) <= A(23);
Q(14) <= A(22);
Q(13) <= A(21);
Q(12) <= A(20);
Q(11) <= A(19);
Q(10) <= A(18);
Q(9) <= A(17);
Q(8) <= A(16);
-- 8 bit ke 0
Q(7) <= A(31);
Q(6) <= A(30);
Q(5) <= A(29);
Q(4) <= A(28);
Q(3) <= A(27);
Q(2) <= A(26);
Q(1) <= A(25);
Q(0) <= A(24);
    
end architecture;