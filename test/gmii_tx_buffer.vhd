library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gmii_tx_buffer is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        eth_10_100m_en : in std_logic;      --ethernet 10M/100M enable
        link : in std_logic;                --ethernet link signal
        gmii_tx_en : in std_logic;          --gmii tx enable
        gmii_txd : in std_logic_vector(7 downto 0);            --gmii txd
        e10_100_tx_en : out std_logic;       --ethernet 10/100M tx enable
        e10_100_txd : out std_logic_vector(7 downto 0)         --ethernet 10/100M txd
    );
end entity;

architecture arch_gmii_tx_buffer of gmii_tx_buffer is

signal tx_wdata : std_logic_vector(7 downto 0);      --tx data fifo write data
signal tx_wren : std_logic;      --tx data fifo write enable
signal tx_rden : std_logic;      --tx data fifo read enable
signal tx_data_cnt : std_logic_vector(15 downto 0);      --tx data counter
signal tx_rdata : std_logic_vector(7 downto 0);      --tx fifo read data                              
signal pack_len : std_logic_vector(16 downto 0);      --package length
signal tx_en : std_logic;      --tx enable
signal txd_high : std_logic_vector(3 downto 0);      --high 4 bits
signal txd_low : std_logic_vector(3 downto 0);      --low 4 bits
signal tx_en_d0 : std_logic; 
signal tx_en_d1 : std_logic;
signal tx_len_cnt : std_logic_vector(15 downto 0);    --tx length counter
signal gmii_tx_en_d0 : std_logic;                          
signal len_cnt : std_logic_vector(1 downto 0);    --length latch counter
signal pack_num : std_logic_vector(4 downto 0);    --length fifo usedw
signal tx_len_wren : std_logic;    --length fifo wren
signal tx_len_rden : std_logic;    --length fifo rden
signal tx_len_wdata : std_logic_vector(15 downto 0);    --length fifo write data
signal tx_len : std_logic_vector(15 downto 0);    --length fifo read data

type fsm is (IDLE, CHECK_FIFO, LEN_LATCH, SEND_WAIT, SEND, SEND_WAIT_1, WAIT_END);
signal state, next_state : fsm;

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE => 
                    next_state <= CHECK_FIFO;
                when CHECK_FIFO =>
                    if pack_num > (pack_num'range=>'0') then  --check length fifo, if usedw > 0 ,there is a package in data fifo
                        next_state <= LEN_LATCH;
                    else
                        next_state <= CHECK_FIFO;
                    end if;
                when LEN_LATCH =>
                    if len_cnt = "11" then  -- wait for read length fifo data
                        next_state <= SEND_WAIT;
                    else
                        next_state <= LEN_LATCH;
                    end if;
                when SEND_WAIT =>
                    next_state <= SEND;
                when SEND =>
                    if tx_data_cnt = pack_len - 1 then  -- read data fifo and send out
                        next_state <= SEND_WAIT_1;
                    else
                        next_state <= SEND;
                    end if;
                when SEND_WAIT_1 =>
                    if tx_data_cnt = pack_len + 1 then -- wait some clock for data latch
                        next_state <= SEND_END;
                    else
                        next_state <= SEND_WAIT_1;
                    end if;
                when SEND_END =>
                    next_state <= IDLE;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_len_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            gmii_tx_en_d0 <= gmii_tx_en;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_len_wren <= '0';
        elsif rising_edge(clk) then
            if gmii_tx_en = '0' and gmii_tx_en_d0 = '1' then
                tx_len_wren <= eth_10_100m_en;
            else
                tx_len_wren <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_len_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            if gmii_tx_en = '1' then
                tx_len_cnt <= tx_len_cnt + 1;
            elsif tx_len_wren = '1' then
                tx_len_cnt <= (others=>'0');
            end if;
        end if;
    end process;

    tx_len_wdata <= tx_len_cnt;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_len_rden <= '0';
        elsif rising_edge(clk) then
            if state = LEN_LATCH and len_cnt = "00" then
                tx_len_rden <= eth_10_100m_en;
            else
                tx_len_rden <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then

        elsif rising_edge(clk) then
            if state = LEN_LATCH  then
                len_cnt <= len_cnt + 1;
            else 
                len_cnt <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            pack_len <= (others=>'0');
        elsif rising_edge(clk) then
            pack_len <= tx_len(tx_len'range-2 downto 1) & '0'; --2*tx_len; 
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_wren <= '0';
            tx_wdata <= (others=>'0');
        elsif rising_edge(clk) then
            tx_wren <= gmii_tx_en and eth_10_100m_en;
            tx_wdata <= gmii_txd;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_data_cnt <= (others='0');
        elsif rising_edge(Clk) then
            if state = SEND or state = SEND_WAIT_1 then
                tx_data_cnt <= tx_data_cnt + 1;
            else
                tx_data_cnt <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_rden <= '0';
        elsif rising_edge(clk) then
            if state = SEND then
                tx_rden <= not tx_data_cnt(0) and eth_10_100m_en;
            else
                tx_rden <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tx_en <= '0';
        elsif rising_edge(clk) then
            if state = SEND then
                tx_en <= '1';
            else
                tx_en <= '0';
            end if;
        end if;
    end process;


    process(clk, rst_n) 
    begin
        if rst_n = '0' then
            tx_en_d0 <= '0';
            tx_en_d1 <= '0';
        elsif rising_edge(clk) then
            tx_en_d0 <= tx_en;
            tx_en_d1 <= tx_en_d0;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            txd_high <= (others='0');
            txd_low <= (others=>'0');
        elsif rising_edge(clk) then
            if tx_data_cnt(0) then
                txd_high <= tx_data(7 downto 4);
            else
                txd_low <= tx_rdata(3 downto 0);
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            e10_100_tx_en <= '0';
        elsif rising_edge(clk) then
            e10_100_tx_en <= tx_en_d1;
        end if;
    end process;
    
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            e10_100_txd <= (others=>'0');
        elsif rising_edge(clk) then
            if tx_data_cnt(0) then
                e10_100_txd <= txd_low & tx_low;
            else
                e10_100_txd <= txd_high & txd_high;
            end if;
        end if;
    end process;


impl_tx_fifo : 



impl_rx_fifo : 

end architecture;