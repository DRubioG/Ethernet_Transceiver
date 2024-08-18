library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc is
    port(
        Clk : in std_logic;
        Reset : in std_logic;
        Data_in : in std_logic_vector(7 downto 0);
        Enable : in std_logic;
        Crc : out std_logic_vector(31 downto 0);
        CrcNext : out std_logic_vector(31 downto 0)
    );
end entity;

architecture arch_crc of crc is

signal Data : std_logic_vector(7 downto 0);

begin
    Data <= Data_in(0) & Data_in(1) & Data_in(2) & Data_in(3) & Data_in(4) & Data_in(5) & Data_in(6) & Data_in(7);

    CrcNext(0) <= Crc(24) xor Crc(30) xor Data(0) xor Data(6);
    CrcNext(1) <= Crc(24) xor Crc(25) xor Crc(30) xor Crc(31) xor Data(0) xor Data(1) xor Data(6) xor Data(7);
    CrcNext(2) <= Crc(24) xor Crc(25) xor Crc(26) xor Crc(30) xor Crc(31) xor Data(0) xor Data(1) xor Data(2) xor Data(6) xor Data(7);
    CrcNext(3) <= Crc(25) xor Crc(26) xor Crc(27) xor Crc(31) xor Data(1) xor Data(2) xor Data(3) xor Data(7);
    CrcNext(4) <= Crc(24) xor Crc(26) xor Crc(27) xor Crc(28) xor Crc(30) xor Data(0) xor Data(2) xor Data(3) xor Data(4) xor Data(6);
    CrcNext(5) <= Crc(24) xor Crc(25) xor Crc(27) xor Crc(28) xor Crc(29) xor Crc(30) xor Crc(31) xor Data(0) xor Data(1) xor Data(3) xor Data(4) xor Data(5) xor Data(6) xor Data(7);
    CrcNext(6) <= Crc(25) xor Crc(26) xor Crc(28) xor Crc(29) xor Crc(30) xor Crc(31) xor Data(1) xor Data(2) xor Data(4) xor Data(5) xor Data(6) xor Data(7);
    CrcNext(7) <= Crc(24) xor Crc(26) xor Crc(27) xor Crc(29) xor Crc(31) xor Data(0) xor Data(2) xor Data(3) xor Data(5) xor Data(7);
    CrcNext(8) <= Crc(0) xor Crc(24) xor Crc(25) xor Crc(27) xor Crc(28) xor Data(0) xor Data(1) xor Data(3) xor Data(4);
    CrcNext(9) <= Crc(1) xor Crc(25) xor Crc(26) xor Crc(28) xor Crc(29) xor Data(1) xor Data(2) xor Data(4) xor Data(5);
    CrcNext(10) <= Crc(2) xor Crc(24) xor Crc(26) xor Crc(27) xor Crc(29) xor Data(0) xor Data(2) xor Data(3) xor Data(5);
    CrcNext(11) <= Crc(3) xor Crc(24) xor Crc(25) xor Crc(27) xor Crc(28) xor Data(0) xor Data(1) xor Data(3) xor Data(4);
    CrcNext(12) <= Crc(4) xor Crc(24) xor Crc(25) xor Crc(26) xor Crc(28) xor Crc(29) xor Crc(30) xor Data(0) xor Data(1) xor Data(2) xor Data(4) xor Data(5) xor Data(6);
    CrcNext(13) <= Crc(5) xor Crc(25) xor Crc(26) xor Crc(27) xor Crc(29) xor Crc(30) xor Crc(31) xor Data(1) xor Data(2) xor Data(3) xor Data(5) xor Data(6) xor Data(7);
    CrcNext(14) <= Crc(6) xor Crc(26) xor Crc(27) xor Crc(28) xor Crc(30) xor Crc(31) xor Data(2) xor Data(3) xor Data(4) xor Data(6) xor Data(7);
    CrcNext(15) <=  Crc(7) xor Crc(27) xor Crc(28) xor Crc(29) xor Crc(31) xor Data(3) xor Data(4) xor Data(5) xor Data(7);
    CrcNext(16) <= Crc(8) xor Crc(24) xor Crc(28) xor Crc(29) xor Data(0) xor Data(4) xor Data(5);
    CrcNext(17) <= Crc(9) xor Crc(25) xor Crc(29) xor Crc(30) xor Data(1) xor Data(5) xor Data(6);
    CrcNext(18) <= Crc(10) xor Crc(26) xor Crc(30) xor Crc(31) xor Data(2) xor Data(6) xor Data(7);
    CrcNext(19) <= Crc(11) xor Crc(27) xor Crc(31) xor Data(3) xor Data(7);
    CrcNext(20) <= Crc(12) xor Crc(28) xor Data(4);
    CrcNext(21) <= Crc(13) xor Crc(29) xor Data(5);
    CrcNext(22) <= Crc(14) xor Crc(24) xor Data(0);
    CrcNext(23) <= Crc(15) xor Crc(24) xor Crc(25) xor Crc(30) xor Data(0) xor Data(1) xor Data(6);
    CrcNext(24) <= Crc(16) xor Crc(25) xor Crc(26) xor Crc(31) xor Data(1) xor Data(2) xor Data(7);
    CrcNext(25) <= Crc(17) xor Crc(26) xor Crc(27) xor Data(2) xor Data(3);
    CrcNext(26) <= Crc(18) xor Crc(24) xor Crc(27) xor Crc(28) xor Crc(30) xor Data(0) xor Data(3) xor Data(4) xor Data(6);
    CrcNext(27) <= Crc(19) xor Crc(25) xor Crc(28) xor Crc(29) xor Crc(31) xor Data(1) xor Data(4) xor Data(5) xor Data(7);
    CrcNext(28) <= Crc(20) xor Crc(26) xor Crc(29) xor Crc(30) xor Data(2) xor Data(5) xor Data(6);
    CrcNext(29) <= Crc(21) xor Crc(27) xor Crc(30) xor Crc(31) xor Data(3) xor Data(6) xor Data(7);
    CrcNext(30) <= Crc(22) xor Crc(28) xor Crc(31) xor Data(4) xor Data(7);
    CrcNext(31) <= Crc(23) xor Crc(29) xor Data(5);



    process(clk, reset)
    begin
        if reset = '1' then
            crc <= (others=>'1');
        elsif rising_edge(clk) then
            if enable = '1' then
                crc <= crcnext;
            end if;
        end if;
    end process;

end architecture;