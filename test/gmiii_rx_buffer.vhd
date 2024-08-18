library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gmii_rx_buffer is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        eth_100m_en : in std_logic;   --ethernet 100M enable
        eth_10m_en : in std_logic;    --ethernet 100M enable
        link : in std_logic;          --ethernet link signal
        gmii_rx_dv : in std_logic;    --gmii rx dv
        gmii_rxd : in std_logic_vector(7 downto 0);      --gmii rxd
        e10_100_rx_dv : out std_logic; --ethernet 10/100 rx_dv
        e10_100_rxd : out std_logic   --ethernet 10/100 rxd
    );
end entity;

architecture arch_gmii_rx_buffer of gmii_rx_buffer is

signal rx_cnt : std_logic_vector(15 downto 0);   --write fifo counter
signal rx_wren : std_logic;   --write fifo wren
signal rx_wdata : std_logic_vector(7 downto 0);   --write fifo data
signal rx_data_cnt : std_logic_vector(15 downto 0);   --read fifo counter
signal rx_rden : std_logic;   --read fifo rden
signal rx_rdata : std_logic_vector(7 downto 0);   --read fifo data
signal rxd_high : std_logic_vector(3 downto 0);   --rxd high 4 bit
signal rxd_low : std_logic_vector(3 downto 0);   --rxd low 4 bit
signal gmii_rx_dv_d0 : std_logic;
signal gmii_rx_dv_d1 : std_logic;
signal gmii_rx_dv_d2 : std_logic;
signal pack_len : std_logic_vector(15 downto 0);   --package length                  
signal len_cnt : std_logic_vector(1 downto 0);   --length latch counter
signal pack_num : std_logic_vector(4 downto 0);   --length fifo usedw
signal rx_len_wren : std_logic;   --length wren
signal rx_len_wdata : std_logic_vector(15 downto 0);   --length write data
signal rx_len_rden : std_logic;   --length rden
signal rx_len : std_logic_vector(15 downto 0);   --legnth read data

type fsm is (IDLE, CHECK_FIFO, LEN_LATCH, REC_WAIT, READ_FIFO, REC_END);
signal state, next_state : fsm;

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    next_state <= CHECK_FIFO;
                when CHECK_FIFO =>
                    if pack_num > (pack_num'range=>'0') then
                        next_state <= LEN_LATCH;
                    else
                        nex_state <= CHECK_FIFO;
                    end if; 
                when LEN_LATCH =>
                    if len_cnt = "11" then
                        next_state <= REC_WAIT;
                    else
                        next_state <= LEN_LATCH;
                    end if;
                when REC_WAIT =>
                    next_state <= READ_FIFO;
                when READ_FIFO =>
                    if rx_data_cnt = pack_len - 1 then
                        next_state <= REC_END;
                    else
                        next_state <= READ_FIFO;
                    end if;
                when REC_END =>
                    next_state <= IDLE;
                when others =>  
                    next_state <= IDLE;
            end case;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            gmii_rx_dv_d0 <= '0';
            gmii_rx_dv_d1 <= '0';
            gmii_rx_dv_d2 <= '0';
        elsif rising_edge(clk) then
            gmii_rx_dv_d0 <= gmii_rx_dv;
            gmii_rx_dv_d1 <= gmii_rx_dv_d0;
            gmii_rx_dv_d2 <= gmii_rx_dv_d1;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            rx_len_wren <= '0';
        elsif rising_edge(clk) then
            if gmii_rx_dv = '0' and gmiii_rx_dv_d0 = '1' then
                rx_len_wren <= eth_100m_en or eth_10m_en;
            else
                rx_len_wren <= '0';
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            rx_cnt <= (others=>'0');
        elsif rising_edge(clk) then 
            if (eth_10m_en = '1') and (gmiii_rx_dv or gmiii_rx_dv_d0) then
                rx_cnt <= rx_cnt + 1;
            elsif (eth_100m_en = '1') and (gmiii_rx_dv or gmiii_rx_dv_d1) then
                rx_cnt <= rx_cnt + 1;
            elsif state = REC_WAIT then
                rx_cnt <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            rx_len_wdata <= (others=>'0');
        elsif rising_edge(clk) then 
            rx_len_wdata <= rx_cnt;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            rxd_high <= (others=>'0');
            rxd_low <= (others=>'0');
        elsif rising_edge(clk) then
            if rx_cnt(0) = '1' then
                rxd_high <= gmii_rxd;
            else
                rxd_low <= gmiii_rxd;
            end if;
        else
            rxd_high <= (others=>'0');
            rxd_low <= (others=>'0');
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            rw_wren <= '0';
            rx_wdara <= (others=>'0');
        elsif rising_edge(clk) then
            if gmii_rx_dv_d1 = '1' then
                if rx_cnt(0) = '1' then
                    rx_wren <= '0';
                else
                    rx_wdata <= rxd_high & rxd_low;
                    rx_wren <= eth_100m_en or eth_10m_en;
                end if;
            end if;
        else
            rx_wren <= '0';
            rx_wdata <= (others=>'0');
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            rx_len_rden <= '0';
        elsif rising_edge(clk) then 
            if state = LEN_LATCH and len_cnt = "00" then
                rx_len_rden <= eth_100m_en or eth_10m_en;
            else
                rx_len_rden <= '0';
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            len_cmt <= "00";
        elsif rising_edge(clk) then
            if state = LEN_LATCH then
                len_cnt <= len_cnt + 1;
            else
                len_cnt <= "00";
            end if;
        end if;
    end process;

    process(clk, rst_n) 
    begin
        if rst_n = '0' then
            pack_len <= (others=>'0');
        elsif rising_edge(clk) then
            pack_len <= "0" & rx_len(rx_len'LENGTH-1 downto 1);
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            rx_data_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            if state = READ_FIFO then
                rx_data_cnt <= rx_data_cnt + 1;
            else
                rx_data_cnt <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then

        elsif rising_edge(clk) then
            if state = READ_FIFO then
                rx_rden <= eth_100m_en or eth_10m_en;
            else
                rx_rden <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then 
            e10_100_rx_dv <= '0';
        elsif rising_edge(clk) then
            e10_100_rx_dv <= rx_rden;
        end if;
    end process;


    e10_100_rxd <= rx_rdata;

rx_fifo : 


rx_len_fifo : 

end architecture;