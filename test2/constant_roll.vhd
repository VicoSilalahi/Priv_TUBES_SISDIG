library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity constant_roll is
  port (
    clk                            : in std_logic;
    reset                          : in std_logic;
    enable                         : in std_logic;
    Cout_0, Cout_1, Cout_2, Cout_3 : out std_logic_vector(31 downto 0)
  );
end entity;

architecture Behavioural of constant_roll is

  constant C0 : std_logic_vector(31 downto 0) := x"C3EFE9DB";
  constant C1 : std_logic_vector(31 downto 0) := x"44626B02";
  constant C2 : std_logic_vector(31 downto 0) := x"79E27C8A";
  constant C3 : std_logic_vector(31 downto 0) := x"78DF30EC";

  signal regC3, regC2, regC1, regC0 : std_logic_vector(31 downto 0);

  -- Function for bitwise left roll
  -- function roll_left(val : std_logic_vector(31 downto 0)) return std_logic_vector is
  --   variable temp : std_logic_vector(31 downto 0);
  -- begin
  --   temp := val(30 downto 0) & val(31);  -- Shift left by 1 and wrap around MSB
  --   return temp;
  -- end function;

begin

  -- Sequential logic for registers
  process (clk, reset)
  begin
    if reset = '1' then
      -- Initialize registers with constants
      regC3 <= C3;
      regC2 <= C2;
      regC1 <= C1;
      regC0 <= C0;
    elsif rising_edge(clk) then
      if enable = '1' then
        -- Perform roll-left operations and pass data between registers
        regC3 <= shift_left(regC0, 1);
        regC2 <= shift_left(regC3, 1);
        regC1 <= shift_left(regC2, 1);
        regC0 <= shift_left(regC1, 1);
      end if;
    end if;
  end process;

  -- Outputs
  Cout_0 <= regC0;
  Cout_1 <= regC1;
  Cout_2 <= regC2;
  Cout_3 <= regC3;

end Behavioural;
