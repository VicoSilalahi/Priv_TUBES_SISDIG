------------------------------------------------------------------------------------------------------------------------
-- Kelompok 23
-- LEA-128 Enkrispi CFB
--
--
------------------------------------------------------------------------------------------------------------------------
-- Deskripsi
-- UART TX untuk menerima data dari CLIENT
--
-- Fungsi     : UART Receiver
-- Input      : i_Clk -> Internal Clock
--            : i_TX_DV -> Input to indicate that the data is ready to be sent/Send immediately
-- Output     : o_TX_Serial -> TX Pin for transmitting data
--            : o_TX_Done -> Output Signal when 128-bit has been transmitted
--
------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX is
  generic (
    g_CLKS_PER_BIT : integer := 434 -- Needs to be set correctly
    -- To determine CLKS_PER_BIT:
    -- CLKS_PER_BIT = BIT_PERIOD/CLOCK_PERIOD
    -- BIT_PERIOD = 1/BAUD_RATE
    -- CLOCK PERIOD = 1/Hz
  );
  port (
    i_Clk       : in std_logic; -- Internal Clock
    i_TX_DV     : in std_logic; -- Input to indicate that the data is ready to be sent/Send immediately
    i_TX_Block  : in std_logic_vector(127 downto 0); -- Input of 128-bits block
    o_TX_Active : out std_logic; -- Indicate that TX line is active, maybe useful for LED Indicator.
    o_TX_Serial : out std_logic := '1'; -- TX Line communicates to Client/PC
    o_TX_Done   : out std_logic -- Indicates 128-bit is done
  );
end UART_TX;

architecture RTL of UART_TX is

  type t_SM_Main is (s_Idle, s_TX_Start_Bit, s_TX_Data_Bits,
    s_TX_Stop_Bit, s_Cleanup, s_Next_Byte);
  signal r_SM_Main : t_SM_Main := s_Idle;

  signal r_Clk_Count  : integer range 0 to g_CLKS_PER_BIT - 1 := 0; -- Clock Indexer
  signal r_Bit_Index  : integer range 0 to 7                  := 0; -- 8 Bits Total, for indexing r_TX_Data
  signal r_Byte_Index : integer range 1 to 16                 := 1; -- 16 Bytes Total, for indexing r_TX_Block
  signal r_TX_Data    : std_logic_vector(7 downto 0)          := (others => '0'); -- Temporary Buffer for each Byte
  signal r_TX_Block   : std_logic_vector(127 downto 0)        := (others => '0'); -- Internal Signal for the i_TX_Block
  signal r_TX_Done    : std_logic                             := '0'; -- Unused, TODO: Make it a byte sent indicator
  signal r_Block_Done : std_logic                             := '0'; -- 128-bit has been transmitted

begin

  p_UART_TX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then

      case r_SM_Main is

        when s_Idle =>
          o_TX_Active  <= '0'; -- Not Active Right Now
          o_TX_Serial  <= '1'; -- Drive Line High for Idle
          r_TX_Done    <= '0'; -- Hasn't sent a data
          r_Clk_Count  <= 0; -- Resets/Initial clock count
          r_Bit_Index  <= 0;
          r_Byte_Index <= 1;

          if i_TX_DV = '1' then -- Instructed to start the transmission
            r_TX_Block <= i_TX_Block; -- Load input block
            r_TX_Data  <= i_TX_Block(7 downto 0); -- Load the first byte
            r_SM_Main  <= s_TX_Start_Bit;
          else
            r_SM_Main <= s_Idle; -- Loops
          end if;

        when s_TX_Start_Bit => -- Send Start Bit (Start bit = 0)
          o_TX_Active <= '1'; -- Is Active Right Now
          o_TX_Serial <= '0'; -- Start Bit

          if r_Clk_Count < g_CLKS_PER_BIT - 1 then -- Clock Indexing
            -- TODO: Figure out whether this clock indexing mechanism could be its own process
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count <= 0;
            r_SM_Main   <= s_TX_Data_Bits;
          end if;

          -- Send Data Bits
        when s_TX_Data_Bits =>
          o_TX_Serial <= r_TX_Data(r_Bit_Index); -- Load the data r_TX_Data indexed by r_Bit_index to TX Line

          if r_Clk_Count < g_CLKS_PER_BIT - 1 then -- Clock Indexing
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count <= 0; -- Only sends when the Clock Indexing is now g_CLKS_PER_BIT - 1

            if r_Bit_Index < 7 then -- Bit Indexing
              r_Bit_Index <= r_Bit_Index + 1;
            else
              r_Bit_Index <= 0; -- Wrap
              r_SM_Main   <= s_TX_Stop_Bit;
            end if;
          end if;

        when s_TX_Stop_Bit => -- Send Stop Bit (Stop bit = 1)
          o_TX_Serial <= '1'; -- Stop Bit

          if r_Clk_Count < g_CLKS_PER_BIT - 1 then -- Clock Indexing
            r_Clk_Count <= r_Clk_Count + 1;
          else
            r_Clk_Count <= 0;
            r_SM_Main   <= s_Next_Byte; -- Initiate the transmission of the next Byte
          end if;

        when s_Next_Byte => -- Load Next Byte
          if r_Byte_Index < 16 then -- Byte Indexing (0 to 15, for 16 bytes)
            r_Byte_Index <= r_Byte_Index + 1;
            r_TX_Data    <= r_TX_Block((r_Byte_Index * 8) + 7 downto r_Byte_Index * 8); -- Correct byte loading
            r_SM_Main    <= s_TX_Start_Bit;
          else
            -- This condition ensures that the last byte is processed correctly
            r_Block_Done <= '1'; -- Indicates that all Bytes have been transmitted
            r_SM_Main    <= s_Cleanup; -- Cleanup state to return to idle
          end if;

          -- Cleanup State
        when s_Cleanup =>
          o_TX_Active  <= '0';
          r_TX_Done    <= '0';
          r_Block_Done <= '0';
          r_SM_Main    <= s_Idle;

        when others =>
          r_SM_Main <= s_Idle;

      end case;

    end if;
  end process p_UART_TX;

  o_TX_Done <= r_Block_Done; -- Outputs the indicator that 128-bit has been sent

end RTL;
