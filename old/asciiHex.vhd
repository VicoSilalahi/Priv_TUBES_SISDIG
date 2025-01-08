-- Template kode untuk ASCII - HEX (7 Segments) Converter
-- Kode ASCII yang harus diterjemahkan adalah:
-- angka 0, 1, 2, 3, 4, 5, 6, 7, 8, dan 9.
-- huruf A, B, C, D, E, F, G, H, I, dan J.
-- Tampilan pada HEX (7 Segments) sebagai berikut:
-- 1 -> 1
-- 2 -> 2
-- 3 -> 3
-- 4 -> 4
-- 5 -> 5
-- 6 -> 6
-- 7 -> 7
-- 8 -> 8
-- 9 -> 9
-- 0 -> 0
-- A -> A
-- B -> b
-- C -> c
-- D -> d
-- E -> E
-- F -> F
-- G -> G
-- H -> H
-- I -> I (di sebelah kiri, tidak seperti angka 1)
-- J -> j (tanpa titik)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity asciiHex is
  port (
    i_ascii : in std_logic_vector (7 downto 0);
    o_hex   : out std_logic_vector (6 downto 0)
  );
end asciiHex;
architecture behavior of asciiHex is
begin

  process (i_ascii)
  begin
    case i_ascii is
      when "00110000" => o_hex <= "0000001"; -- 0
      when "00110001" => o_hex <= "1001111"; -- 1
      when "00110010" => o_hex <= "0010010"; -- 2
      when "00110011" => o_hex <= "0000110"; -- 3
      when "00110100" => o_hex <= "1001100"; -- 4
      when "00110101" => o_hex <= "0100100"; -- 5
      when "00110110" => o_hex <= "0100000"; -- 6
      when "00110111" => o_hex <= "0001111"; -- 7
      when "00111000" => o_hex <= "0000000"; -- 8
      when "00111001" => o_hex <= "0000100"; -- 9
      when "01000001" => o_hex <= "0001000"; -- A
      when "01000010" => o_hex <= "1100000"; -- b
      when "01000011" => o_hex <= "1110010"; -- c
      when "01000100" => o_hex <= "1000010"; -- d
      when "01000101" => o_hex <= "0110000"; -- E
      when "01000110" => o_hex <= "0111000"; -- F
      when "01000111" => o_hex <= "0100000"; -- G
      when "01001000" => o_hex <= "1001000"; -- H
      when "01001001" => o_hex <= "1111001"; -- I
      when "01001010" => o_hex <= "0111000"; -- j
      when others => o_hex <= "1111111";
    end case;
  end process;

end behavior;