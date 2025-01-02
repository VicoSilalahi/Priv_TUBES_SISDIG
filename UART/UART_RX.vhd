library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 87 -- Needs to be set correctly
    -- To determine CLKS_PER_BIT:
    -- CLKS_PER_BIT = BIT_PERIOD/CLOCK_PERIOD
    -- BIT_PERIOD = 1/BAUD_RATE
    -- CLOCK PERIOD = 1/Hz
  );
  port (
    i_Clk       : in std_logic; -- Internal Clock
    i_RX_Serial : in std_logic; -- Input RX Pin (Receive from Client/PC)
    o_RX_DV     : out std_logic; -- Output Signal when a byte has been received ToDo: Create the mechanism for 128-bit DV
    o_RX_Byte   : out std_logic_vector(7 downto 0); -- ToDo: Remove doesn't need outside of simulation
    o_RX_block  : out std_logic_vector(127 downto 0) -- Output of the UART Receiver, sized 128-bit to be input into TOP
  );
end UART_RX;
architecture rtl of UART_RX is

  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits, -- FSM States
    s_RX_Stop_Bit, s_Cleanup);
  signal r_SM_Main : t_SM_Main := s_Idle; -- FSM Signals

  signal r_RX_Data_R : std_logic := '0'; -- Apparently Double-register the incoming data to avoid metastability
  signal r_RX_Data   : std_logic := '0'; -- ^^

  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT - 1 := 0; -- Clock Counter for the process to find its middle
  signal r_Bit_Index : integer range 0 to 7                  := 0; -- 8 Bits Total
  signal r_RX_Byte   : std_logic_vector(7 downto 0)          := (others => '0'); -- Internal signal for the Byte register
  signal r_RX_DV     : std_logic                             := '0'; -- Internal signal for when a byte has been received
  -- ToDo: Create the internal signal mechanism for 128-bit DV

  type MEM is array (15 downto 0) of std_logic_vector(7 downto 0); -- Just a type for the array of 16-Bytes = 128-bits
  signal MEM_UART    : MEM                   := (others => (others => '0')); -- The signal for the array of 128-bit buffer
  signal r_MEM_Index : integer range 0 to 15 := 0; -- Indexing for the input process of MEM_UART

  signal r_RX_block : std_logic_vector(127 downto 0) := (others => '0'); -- Concatenated Version of MEM_UART

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

          if r_RX_Data = '0' then -- Start bit detected
            r_SM_Main <= s_RX_Start_Bit;
          else
            r_SM_Main <= s_Idle;
          end if;

        when s_RX_Start_Bit =>
          if r_Clk_Count = (g_CLKS_PER_BIT - 1)/2 then -- Clock Indexing
            -- ToDo: Figure out whether this clock indexing mechanism could be its own process
            if r_RX_Data = '0' then
              r_Clk_Count <= 0;
              r_SM_Main   <= s_RX_Data_Bits;
            else
              r_SM_Main <= s_Idle;
            end if;
          else
            r_Clk_Count <= r_Clk_Count + 1;
          end if;

        when s_RX_Data_Bits =>
          if r_Clk_Count < g_CLKS_PER_BIT - 1 then -- Clock Indexing
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count            <= 0;
            r_RX_Byte(r_Bit_Index) <= r_RX_Data;

            if r_Bit_Index < 7 then -- Bit Indexing
              r_Bit_Index <= r_Bit_Index + 1;
            else
              r_Bit_Index <= 0; -- Reset the Bit Indexing when it reaches 7 (8 Bytes Received)
              r_SM_Main   <= s_RX_Stop_Bit;
            end if;
          end if;

        when s_RX_Stop_Bit =>
          if r_Clk_Count < g_CLKS_PER_BIT - 1 then -- Clock Indexing
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_RX_DV               <= '1'; -- Outputs the signal of DataValid for each Byte received
            MEM_UART(r_MEM_Index) <= r_RX_Byte; -- Store in memory
            r_MEM_Index           <= (r_MEM_Index + 1) mod 16; -- Block Indexing that Wraps around for each 16 Bytes
            -- ToDo: Create the mechanism for 128-bit DV here. By making an if statement to check the r_MEM_Index
            r_Clk_Count           <= 0; -- Reset the Clock Index
            r_SM_Main             <= s_Cleanup;
          end if;

        when s_Cleanup =>
          r_SM_Main <= s_Idle;
          r_RX_DV   <= '0';

        when others =>
          r_SM_Main <= s_Idle;
      end case;
    end if;
  end process p_UART_RX;

  -- Signal to be Output
  o_RX_DV    <= r_RX_DV;
  o_RX_Byte  <= r_RX_Byte;
  o_RX_block <= r_RX_block;

  -- Update 128-Bit Buffer to append each MEM_UART Array
  r_RX_block <= MEM_UART(15) & MEM_UART(14) & MEM_UART(13) & MEM_UART(12) &
    MEM_UART(11) & MEM_UART(10) & MEM_UART(9) & MEM_UART(8) &
    MEM_UART(7) & MEM_UART(6) & MEM_UART(5) & MEM_UART(4) &
    MEM_UART(3) & MEM_UART(2) & MEM_UART(1) & MEM_UART(0);

end rtl;
