library ieee;
use ieee.std_logic_std.all;
use ieee.numeric_std.all;

entity gmii_arbi is
    port(
        clk : in std_logic;
        st_n : in std_logic;
        speed : in std_logic_vector(1 downto 0);  
        link : in std_logic;                                            
        gmii_rx_dv : in std_logic;
        gmii_rxd : in std_logic_vector(7 downto 0);
        gmii_tx_en : in std_logic;
        gmii_txd : in std_logic_vector(7 downto 0);                       
        pack_total_len : out std_logic_vector(31 downto 0);
        e_rst_n : out std_logic;
        e_rx_dv : out std_logic;
        e_rxd : out std_logic_vector(7 downto 0);
        e_tx_en : out std_logic;
        e_txd : out std_logic_vector(7 downto 0)
    );
end entity;

architecture arch_gmii_arbi of gmii_arbi is

signal eth_1000m_en : std_logic;
signal eth_10_100m_en : std_logic;
signal eth_100m_en : std_logic;
signal eth_10m_en : std_logic;
signal speed_d0 : std_logic_vector(1 downto 0);
signal speed_d1 : std_logic_vector(1 downto 0);
signal speed_d2 : std_logic_vector(1 downto 0);
signal link_d0 : std_logic;
signal link_d1 : std_logic;
signal link_d2 : std_logic;
signal e10_100_tx_en : std_logic;
signal e10_100_txd : std_logic_vector(7 downto 0);
signal e10_100_rx_dv : std_logic;
signal e10_100_rxd : std_logic_vector(7 downto 0);
signal e_rst_en : std_logic;
signal e_rst_cnt : std_logic_vector(7 downto 0);

begin

    eth_10_100m_en <= eth_100m_en or eth_10m_en;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            speed_d0 <= (others=>'0');
            speed_d1 <= (others=>'0');
            speed_d2 <= (others=>'0');
            link_d0 <= '0';
            link_d1 <= '0';
            link_d2 <= '0';
        elsif rising_edge(clk) then
            speed_d0 <= speed;
            speed_d1 <= speed_d0;
            speed_d2 <= speed_d1;
            link_d0  <= link;
            link_d1  <= link_d0;
            link_d2  <= link_d1;
        end if;
    end process;

    process(rst_n, clk)
    begin
        if rst_n = '0' then
            eth_1000m_en   <= '0';
            eth_100m_en    <= '0';
            eth_10m_en     <= '0';
            pack_total_len <= ;
        elsif rising_edge(clk) then
            if speed_d2 = "10" then     -- 1000 M
                eth_1000m_en   <= '1';
                eth_100m_en    <= '0';
                eth_10m_en     <= '0';
                pack_total_len <= 32'd125000000;
            elsif speed_d2 = "01" then  -- 100 M
                eth_1000m_en   <= '0';
                eth_100m_en    <= '1';
                eth_10m_en     <= '0';
                pack_total_len <= 32'd25000000;
            elsif speed_d2 = "00" then  -- 10 M
                eth_1000m_en   <= '0';
                eth_100m_en    <= '0';
                eth_10m_en     <= '1';
                pack_total_len <= 32'd2500000;
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            e_rx_dv   <= '0';
            e_rxd     <= (others=>'0')
            e_tx_en   <= '0';
            e_txd     <= (others=>'0');
        elsif rising_edge(clk) then
            if eth_1000m_en = '1' then
                e_rx_dv   <= gmii_rx_dv;
                e_rxd     <= gmii_rxd;
                e_tx_en   <= gmii_tx_en;
                e_txd     <= gmii_txd;
            elsif eth_100m_en or eth_10m_en then
                e_rx_dv   <= e10_100_rx_dv;
                e_rxd     <= e10_100_rxd;
                e_tx_en   <= e10_100_tx_en;
                e_txd     <= e10_100_txd;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            e_rst_en <= '1';
        elsif rising_edge(clk) then
            if speed_d2 /= speed_d1 then
                e_rst_en <= '0';
            elsif e_rst_cnt = then
                e_rst_n <= '1';
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin   
        if rst_n = '0' then
            e_rst_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            if e_rst_en = '1' then
                e_rst_cnt <= e_rst_cnt +1;
            else
                e_rst_cnt <= (others=>'0');
            end if;
        end if;
    end process;

end architecture;