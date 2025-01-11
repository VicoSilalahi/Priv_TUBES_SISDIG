library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cordicphase is
    port(
        i_CLOCK         : in std_logic;
        i_RX            : in std_logic;
        o_TX            : out std_logic := '1';
        o_RX_BUSY       : out std_logic;
        o_sig_CRRP_DATA : out std_logic;
        o_TX_BUSY       : out std_logic;
        o_DATA_READY    : out std_logic;
        o_DATA          : out std_logic_vector(15 downto 0)
    );
end cordicphase;

architecture behavior of cordicphase is
    -- Basic UART signals
    signal s_RX_BUSY      : std_logic;
    signal s_prev_RX_BUSY : std_logic := '0';
    signal s_rx_data      : std_logic_vector(7 downto 0);
    signal s_TX_START     : std_logic := '0';
    signal s_TX_BUSY      : std_logic;
    signal r_TX_DATA      : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Data handling
    signal r_word_buffer  : std_logic_vector(15 downto 0) := (others => '0');
    signal r_wave_count   : integer range 0 to 1 := 0;
    
    -- Memory
    type memory_type is array(0 to 15) of std_logic_vector(15 downto 0);
    signal r_memory       : memory_type := (others => (others => '0'));
    signal r_mem_index    : integer range 0 to 15 := 0;
    signal r_mem_full     : std_logic := '0';
    
    -- State machine
    type t_state is (IDLE, STORE_MSB, WAIT_LSB, STORE_WORD, SEND_MSB, WAIT_TX1, SEND_LSB, WAIT_FINAL);
    signal r_state : t_state := IDLE;

    -- Components
    component uart1_tx is
        port(
            i_CLOCK   : in std_logic;
            i_START   : in std_logic;
            o_BUSY    : out std_logic;
            i_DATA    : in std_logic_vector(7 downto 0);
            o_TX_LINE : out std_logic := '1'
        );
    end component;
    
    component uart1_rx is
        port(
            i_CLOCK         : in std_logic;
            i_RX            : in std_logic;
            o_DATA          : out std_logic_vector(7 downto 0); 
            o_sig_CRRP_DATA : out std_logic;
            o_BUSY          : out std_logic
        );
    end component;
    
begin
    -- Component instantiation
    u_TX : uart1_tx port map(
        i_CLOCK   => i_CLOCK,
        i_START   => s_TX_START,
        o_BUSY    => s_TX_BUSY,
        i_DATA    => r_TX_DATA,
        o_TX_LINE => o_TX
    );
    
    u_RX : uart1_rx port map(
        i_CLOCK         => i_CLOCK,
        i_RX            => i_RX,
        o_DATA          => s_rx_data,
        o_sig_CRRP_DATA => o_sig_CRRP_DATA,
        o_BUSY          => s_RX_BUSY
    );
    
    -- Main process
    process(i_CLOCK)
    begin
        if rising_edge(i_CLOCK) then
            -- Synchronize busy signals
            s_prev_RX_BUSY <= s_RX_BUSY;
            
            -- Reset TX start when busy
            if s_TX_START = '1' and s_TX_BUSY = '1' then
                s_TX_START <= '0';
            end if;
            
            case r_state is
                when IDLE =>
                    -- Wait for RX to complete (falling edge of busy)
                    if s_RX_BUSY = '0' and s_prev_RX_BUSY = '1' then
                        r_word_buffer(15 downto 8) <= s_rx_data;
                        r_state <= STORE_MSB;
                    end if;
                
                when STORE_MSB =>
                    -- Wait for next byte to start
                    if s_RX_BUSY = '1' then
                        r_state <= WAIT_LSB;
                    end if;
                
                when WAIT_LSB =>
                    -- Wait for LSB reception
                    if s_RX_BUSY = '0' and s_prev_RX_BUSY = '1' then
                        r_word_buffer(7 downto 0) <= s_rx_data;
                        r_state <= STORE_WORD;
                    end if;
                
                when STORE_WORD =>
                    -- Store complete word
                    r_memory(r_mem_index) <= r_word_buffer;
                    r_TX_DATA <= r_word_buffer(15 downto 8);
                    r_state <= SEND_MSB;
                
                when SEND_MSB =>
                    -- Start MSB transmission
                    if s_TX_BUSY = '0' then
                        s_TX_START <= '1';
                        r_state <= WAIT_TX1;
                    end if;
                
                when WAIT_TX1 =>
                    -- Wait for MSB transmission to complete
                    if s_TX_BUSY = '0' and s_TX_START = '0' then
                        r_TX_DATA <= r_word_buffer(7 downto 0);
                        r_state <= SEND_LSB;
                    end if;
                
                when SEND_LSB =>
                    -- Start LSB transmission
                    if s_TX_BUSY = '0' then
                        s_TX_START <= '1';
                        r_state <= WAIT_FINAL;
                    end if;
                
                when WAIT_FINAL =>
                    -- Complete transmission and update indices
                    if s_TX_BUSY = '0' and s_TX_START = '0' then
                        if r_wave_count = 0 then
                            r_wave_count <= 1;
                        else
                            r_wave_count <= 0;
                            if r_mem_index < 7 then
                                r_mem_index <= r_mem_index + 1;
                            else
                                r_mem_index <= 0;
                                r_mem_full <= '1';
                            end if;
                        end if;
                        r_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
    
    -- Output assignments
    o_RX_BUSY <= s_RX_BUSY;
    o_TX_BUSY <= s_TX_BUSY;
    o_DATA_READY <= r_mem_full;
    o_DATA <= r_word_buffer;
end behavior;