library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX is
  generic (
    g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
  );
  port (
    i_Clk       : in  std_logic;
    i_TX_DV     : in  std_logic;
    i_TX_Block  : in  std_logic_vector(127 downto 0);
    o_TX_Active : out std_logic;
    o_TX_Serial : out std_logic;
    o_TX_Done   : out std_logic
  );
end UART_TX;

architecture RTL of UART_TX is

  type t_SM_Main is (s_Idle, s_TX_Start_Bit, s_TX_Data_Bits,
                     s_TX_Stop_Bit, s_Cleanup, s_Next_Byte);
  signal r_SM_Main : t_SM_Main := s_Idle;

  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0; -- 8 Bits Total
  signal r_Byte_Index : integer range 0 to 15 := 0; -- 16 Bytes Total
  signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_TX_Block  : std_logic_vector(127 downto 0) := (others => '0');
  signal r_TX_Done   : std_logic := '0';
  signal r_Block_Done : std_logic := '0';

begin

  p_UART_TX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then

      case r_SM_Main is

        when s_Idle =>
          o_TX_Active <= '0';
          o_TX_Serial <= '1'; -- Drive Line High for Idle
          r_TX_Done   <= '0';
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;
          r_Byte_Index <= 0;

          if i_TX_DV = '1' then
            r_TX_Block <= i_TX_Block; -- Load input block
            r_TX_Data <= i_TX_Block(7 downto 0); -- Load the first byte
            r_SM_Main <= s_TX_Start_Bit;
          else
            r_SM_Main <= s_Idle;
          end if;

        -- Send Start Bit (Start bit = 0)
        when s_TX_Start_Bit =>
          o_TX_Active <= '1';
          o_TX_Serial <= '0';

          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count <= 0;
            r_SM_Main <= s_TX_Data_Bits;
          end if;

        -- Send Data Bits
        when s_TX_Data_Bits =>
          o_TX_Serial <= r_TX_Data(r_Bit_Index);

          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count <= 0;

            if r_Bit_Index < 7 then
              r_Bit_Index <= r_Bit_Index + 1;
            else
              r_Bit_Index <= 0;
              r_SM_Main <= s_TX_Stop_Bit;
            end if;
          end if;

        -- Send Stop Bit (Stop bit = 1)
        when s_TX_Stop_Bit =>
          o_TX_Serial <= '1';

          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count <= 0;
            r_SM_Main <= s_Next_Byte;
          end if;

        -- Load Next Byte
        when s_Next_Byte =>
          if r_Byte_Index < 15 then
            r_Byte_Index <= r_Byte_Index + 1;
            r_TX_Data <= r_TX_Block((r_Byte_Index + 1) * 8 - 1 downto r_Byte_Index * 8);
            r_SM_Main <= s_TX_Start_Bit;
          else
            r_Block_Done <= '1';
            r_SM_Main <= s_Cleanup;
          end if;

        -- Cleanup State
        when s_Cleanup =>
          o_TX_Active <= '0';
          r_TX_Done   <= '1';
          r_SM_Main   <= s_Idle;

        when others =>
          r_SM_Main <= s_Idle;

      end case;

    end if;
  end process p_UART_TX;

  o_TX_Done <= r_Block_Done;

end RTL;
