-- Nama         : Adrian Sami Pratama
-- NIM          : 13223074
-- Kelompok     : 2
-- Tanggal      : 26 November 2024
-----------------------------------------
-- Deskripsi
-- Fungsi   : FSM untuk cipher block enkripsi LEA
-- Input    : is_done, start, stop
-- Output   : P_MUX, K_MUX, C_MUX, En_Reg_All, En_Counter, Res_Counter
-- Note     : is_done: menandakan sudah 24 round
--            start : input dari luar untuk memulai enkripsi
--            stop : input dari luar untuk reset proses
--            P_MUX : output untuk mengontrol mux pada plaintext
--            K_MUX : output untuk mengontrol mux pada master key
--            C_MUX : output untuk mengontrol mux konstanta
--            En_Reg_All : untuk enable register
--            En_Counter : untuk enable counter
--            Res_Counter : untuk mereset counter
--            Res_Reg_All : untuk mereset semua register
-----------------------------------------
-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lea_encrypt_fsm is
    port (
        is_done, start, stop, clock : in std_logic; -- sinyal input FSM
        P_MUX, K_MUX, C_MUX, En_Reg_All, En_Counter, Res_Counter, Res_Reg_All : out std_logic -- sinyal output FSM
    );
end lea_encrypt_fsm;

architecture behavior of lea_encrypt_fsm is
 type state is (S1, S2, S3, S4);
 signal currentstate: state;
begin
    process(clock)
    begin
        if rising_edge(clock) then
            case currentstate is
                when S1 => -- State awal
                    if start = '1' then -- Jika sudah dipencet start
                        currentstate <= S2; -- Pindah ke S2
                    else
                        currentstate <= S1; -- Kalau idle tetep di S1
                    end if;
                when S2 => -- State sudah start
                    if (is_done = '1') then -- Jika proses belum selesai dan tidak force stop
                        currentstate <= S3;
                    elsif (is_done = '0') then
                        currentstate <= S2;
                    end if;
                when S3 => -- Pada saat proses sudah selesai, maka akan ada delay menunjukkan hasilnya sampai dipencet stop
                        currentstate <= S4; -- Delay 1 clock cycle untuk mengambil hasil ciphertext
                when S4 => -- State sebelum kembali ke state awal untuk mereset
                    currentstate <= S1;
            end case;
        end if;
    end process;

process(currentstate) -- Output untuk setiap state
begin
    if currentstate = S1 then -- Output state awal
        P_MUX <= '0';
        K_MUX <= '0';
        C_MUX <= '0';
        En_Reg_All <= '1'; 
        En_Counter <= '0';
        Res_Counter <= '0';
        Res_Reg_All <= '0';
    elsif currentstate <= S2 then -- Output state saat proses round function
        P_MUX <= '1';
        K_MUX <= '1';
        C_MUX <= '1';
        En_Reg_All <= '1'; 
        En_Counter <= '1';
        Res_Counter <= '0';
        Res_Reg_All <= '0';
    elsif currentstate <= S3 then -- Output saat sudah selesai proses enkripsi
        P_MUX <= '1';
        K_MUX <= '1';
        C_MUX <= '1';
        En_Reg_All <= '0'; 
        En_Counter <= '0';
        Res_Counter <= '0';
        Res_Reg_All <= '0';
    elsif currentstate <= S4 then -- Output saat direset
        P_MUX <= '0';
        K_MUX <= '0';
        C_MUX <= '0';
        En_Reg_All <= '0'; 
        En_Counter <= '0';
        Res_Counter <= '1';
        Res_Reg_All <= '0';
    end if;
end process;

end architecture;