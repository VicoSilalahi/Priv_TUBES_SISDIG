library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 115     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0);
    o_RX_block  : out std_logic_vector(127 downto 0)
    );
end UART_RX;
 
 
architecture rtl of UART_RX is
 
  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,
                     s_RX_Stop_Bit, s_Cleanup);
  signal r_SM_Main : t_SM_Main := s_Idle;
 
  signal r_RX_Data_R : std_logic := '0';
  signal r_RX_Data   : std_logic := '0';
   
  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_DV     : std_logic := '0';

  type MEM is array (15 downto 0) of std_logic_vector(7 downto 0);
  signal MEM_UART : MEM := (others => (others => '0'));

  signal r_MEM_Index : integer range 0 to 15 := 0;  -- For 16 slots
  signal r_RX_block  : std_logic_vector(127 downto 0) := (others => '0');

begin
 
  -- Purpose: Double-register the incoming data to avoid metastability
  p_SAMPLE : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      r_RX_Data_R <= i_RX_Serial;
      r_RX_Data   <= r_RX_Data_R; 
    end if; 
  end process p_SAMPLE;
 
  -- Purpose: Control RX state machine and store data in memory
  p_UART_RX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      case r_SM_Main is
        when s_Idle =>
          r_RX_DV     <= '0';
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;
 
          if r_RX_Data = '0' then       -- Start bit detected
            r_SM_Main <= s_RX_Start_Bit;
          else
            r_SM_Main <= s_Idle;
          end if;
 
        when s_RX_Start_Bit =>
          if r_Clk_Count = (g_CLKS_PER_BIT-1)/2 then
            if r_RX_Data = '0' then
              r_Clk_Count <= 0;
              r_SM_Main   <= s_RX_Data_Bits;
            else
              r_SM_Main   <= s_Idle;
            end if;
          else
            r_Clk_Count <= r_Clk_Count + 1;
          end if;
         
        when s_RX_Data_Bits =>
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count            <= 0;
            r_RX_Byte(r_Bit_Index) <= r_RX_Data;
             
            if r_Bit_Index < 7 then
              r_Bit_Index <= r_Bit_Index + 1;
            else
              r_Bit_Index <= 0;
              r_SM_Main   <= s_RX_Stop_Bit;
            end if;
          end if;
           
        when s_RX_Stop_Bit =>
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_RX_DV     <= '1';
            MEM_UART(r_MEM_Index) <= r_RX_Byte;  -- Store in memory
            r_MEM_Index <= (r_MEM_Index + 1) mod 16;  -- Wrap around
            -- Update 128-bit output
            -- r_RX_block <= MEM_UART(15) & MEM_UART(14) & MEM_UART(13) & MEM_UART(12) &
            --               MEM_UART(11) & MEM_UART(10) & MEM_UART(9)  & MEM_UART(8)  &
            --               MEM_UART(7)  & MEM_UART(6)  & MEM_UART(5)  & MEM_UART(4)  &
            --               MEM_UART(3)  & MEM_UART(2)  & MEM_UART(1)  & MEM_UART(0);
            r_Clk_Count <= 0;
            r_SM_Main   <= s_Cleanup;
          end if;
            
        when s_Cleanup =>
          r_SM_Main <= s_Idle;
          r_RX_DV   <= '0';

        when others =>
          r_SM_Main <= s_Idle;
      end case;
    end if;
  end process p_UART_RX;
 
  o_RX_DV   <= r_RX_DV;
  o_RX_Byte <= r_RX_Byte;
  o_RX_block <= r_RX_block;
  r_RX_block <= MEM_UART(15) & MEM_UART(14) & MEM_UART(13) & MEM_UART(12) &
  MEM_UART(11) & MEM_UART(10) & MEM_UART(9)  & MEM_UART(8)  &
  MEM_UART(7)  & MEM_UART(6)  & MEM_UART(5)  & MEM_UART(4)  &
  MEM_UART(3)  & MEM_UART(2)  & MEM_UART(1)  & MEM_UART(0);
   
end rtl;
