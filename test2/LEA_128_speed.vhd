library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity LEA_128_speed is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    i_key : in std_logic_vector(127 downto 0);
    i_ptx : in std_logic_vector(127 downto 0);
    start : in std_logic
  );
end entity;

architecture Behavioral of LEA_128_speed is
  component mux_2to1_32bit is
    port (
      sel  : in std_logic;
      a, b : in std_logic_vector (31 downto 0);
      y    : out std_logic_vector (31 downto 0)
    );
  end component;

  component demux_1to2_32bit is
    port (
      sel    : in std_logic;
      a      : in std_logic_vector (31 downto 0);
      y0, y1 : out std_logic_vector (31 downto 0)
    );
  end component;

  component register_32bit is
    port (
      clk, reset, enable : in std_logic;
      d                  : in std_logic_vector (31 downto 0);
      q                  : out std_logic_vector (31 downto 0)
    );
  end component;

  component constant_roll is
    port (
      clk                            : in std_logic;
      reset                          : in std_logic;
      enable                         : in std_logic;
      Cout_0, Cout_1, Cout_2, Cout_3 : out std_logic_vector(31 downto 0)
    );
  end component;

  component counterComparator is
    port (
      clk    : in std_logic;
      resCTR : in std_logic;
      enCTR  : in std_logic;
      isDone : out std_logic
    );
  end component;

  type chunk_32 is array (natural range <>) of std_logic_vector(31 downto 0);
  signal RK, internalRK                         : chunk_32(3 downto 0);
  signal X, internalX                           : chunk_32(3 downto 0);
  signal sPTX, sKEY                             : std_logic;
  signal enREG, enCTR, resREG, resCONST, resCTR : std_logic;

  signal outMuxX, outMuxK : chunk_32(3 downto 0);
  signal outRegX, outRegK : chunk_32(3 downto 0);
  signal Cout             : chunk_32(3 downto 0);

  signal isDone : std_logic;

  type STATE is (S_Idle, S_Round, S_End, S_Reset);
  signal Current_State, Next_State : STATE := S_Idle;

begin

  X(0) <= i_ptx(127 downto 96);
  X(1) <= i_ptx(95 downto 64);
  X(2) <= i_ptx(63 downto 32);
  X(3) <= i_ptx(31 downto 0);

  RK(0) <= i_key(127 downto 96);
  RK(1) <= i_key(95 downto 64);
  RK(2) <= i_key(63 downto 32);
  RK(3) <= i_key(31 downto 0);

  -- Round Function
  muxX_inst : for i in 0 to 3 generate
    muxX : mux_2to1_32bit
    port map
    (
      sel => sPTX,
      a   => X(i),
      b   => internalX(i),
      y   => outMuxX(i)
    );
  end generate;

  regX_inst : for i in 0 to 3 generate
    regX : register_32bit
    port map
    (
      clk    => clk,
      reset  => reset,
      enable => enREG,
      d      => outMuxX(i),
      q      => outRegX(i)
    );
  end generate;

  internalX(0) <= std_logic_vector(SHIFT_LEFT(unsigned(outRegX(0) xor internalRK(0)) + unsigned(outRegX(1) xor internalRK(1)), 9));
  internalX(1) <= std_logic_vector(SHIFT_LEFT(unsigned(outRegX(1) xor internalRK(2)) + unsigned(outRegX(2) xor internalRK(1)), 5));
  internalX(2) <= std_logic_vector(SHIFT_LEFT(unsigned(outRegX(2) xor internalRK(3)) + unsigned(outRegX(3) xor internalRK(1)), 3));
  internalX(3) <= outRegX(0);

  -- Key Schedule
  -- Constant Rolling
  constant_roll_inst : constant_roll
  port map
  (
    clk    => clk,
    reset  => reset,
    enable => enREG,
    Cout_0 => Cout(0),
    Cout_1 => Cout(1),
    Cout_2 => Cout(2),
    Cout_3 => Cout(3)
  );

  muxK_inst : for i in 0 to 3 generate
    muxK : mux_2to1_32bit
    port map
    (
      sel => sKEY,
      a   => RK(i),
      b   => internalRK(i),
      y   => outMuxK(i)
    );
  end generate;

  regK_inst : for i in 0 to 3 generate
    regK : register_32bit
    port map
    (
      clk    => clk,
      reset  => reset,
      enable => enREG,
      d      => outMuxK(i),
      q      => outRegK(i)
    );
  end generate;

  internalRK(0) <= std_logic_vector(SHIFT_LEFT(unsigned(outRegK(0)) + unsigned(Cout(0)), 1));
  internalRK(1) <= std_logic_vector(SHIFT_LEFT(unsigned(outRegK(1)) + unsigned(Cout(1)), 3));
  internalRK(2) <= std_logic_vector(SHIFT_LEFT(unsigned(outRegK(2)) + unsigned(Cout(2)), 6));
  internalRK(3) <= std_logic_vector(SHIFT_LEFT(unsigned(outRegK(3)) + unsigned(Cout(3)), 11));
  -- Counter and Comparator
  counterComparator_inst : counterComparator
  port map
  (
    clk    => clk,
    resCTR => resCTR,
    enCTR  => enCTR,
    isDone => isDone
  );

  -- FSM
  -- S_Idle, S_Round, S_End, S_Reset
  -- is_done, start, stop
  -- sPTX, sKEY, enREG, enCTR, resREG, resCONST, resCTR

  process (clk)
  begin
    if reset = '1' then
      Next_State <= S_Reset;
    end if;
    if rising_edge(clk) then
      Current_State <= Next_State;
    end if;
  end process;

  process (Next_State, Current_State)
  begin
    Next_State <= Current_State;
    case Current_State is
      when S_Idle =>
        if start = '1' then
          Next_State <= S_Round;
        end if;
        sPTX     <= '0';
        sKEY     <= '0';
        enREG    <= '1';
        enCTR    <= '1';
        resREG   <= '0';
        resCONST <= '0';
        resCTR   <= '0';
      when S_Round =>
        if isDone = '1' then
          Next_State <= S_End;
        end if;
        sPTX     <= '1';
        sKEY     <= '1';
        enREG    <= '1';
        enCTR    <= '1';
        resREG   <= '0';
        resCONST <= '0';
        resCTR   <= '0';
      when S_End =>
        sPTX     <= '0';
        sKEY     <= '0';
        enREG    <= '0';
        enCTR    <= '0';
        resREG   <= '0';
        resCONST <= '0';
        resCTR   <= '0';
      when others =>
        Next_State <= S_Reset;
        sPTX       <= '0';
        sKEY       <= '0';
        enREG      <= '0';
        enCTR      <= '0';
        resREG     <= '1';
        resCONST   <= '1';
        resCTR     <= '1';
    end case;

  end process;
end Behavioral;