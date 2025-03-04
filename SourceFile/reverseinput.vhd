------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB
--
------------------------------------------------------------------------------------------------------------------------
-- Deskripsi
-- State Representation untuk LEA-128 dan UART RX dan UART TX
--
------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reverseinput is
  port (
    A : in std_logic_vector(127 downto 0);
    B : out std_logic_vector(127 downto 0)
  );
end entity;

architecture rtl of reverseinput is

begin

  process (A)
  begin
    for i in 0 to 15 loop
      B(127 - 8 * i downto 120 - 8 * i) <= A(8 * (i + 1) - 1 downto 8 * i);
    end loop;
  end process;

end architecture;