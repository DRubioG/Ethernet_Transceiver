library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_test is
    port (
        rst_n : in std_logic; 
        pack_total_len : in std_logic_vector(31 downto 0);  
        gmii_tx_clk : in std_logic; 
        gmii_rx_clk : in std_logic; 
        gmii_rx_dv : in std_logic; 
        gmii_rxd : in std_logic_vector(7 downto 0); 
        gmii_tx_en : out std_logic; 
        gmii_txd : out std_logic_vector(7 downto 0)
    );
end entity;

architecture arch_mac_test of mac_test is

constant UDP_WIDTH : integer := 32 ;
constant UDP_DEPTH : integer := 5 ;


signal gmii_rx_dv_d0 : std_logic;
signal gmii_rxd_d0 : std_logic;
signal gmii_tx_en_tmp : std_logic;
signal gmii_txd_tmp : std_logic;

signal ram_wr_data : std_logic;
signal ram_wr_en : std_logic;
signal udp_ram_data_req : std_logic;
signal udp_send_data_length : std_logic;

signal tx_ram_wr_data : std_logic;
signal tx_ram_wr_en : std_logic;
signal udp_tx_req : std_logic;
signal arp_request_req : std_logic;
signal mac_send_end : std_logic;
signal write_end : std_logic;

signal udp_rec_ram_rdata : std_logic;
signal udp_rec_ram_read_addr : std_logic;
signal udp_rec_data_length : std_logic;
signal udp_rec_data_valid : std_logic;

signal udp_tx_end : std_logic;
signal almost_full : std_logic;

signal udp_ram_wr_en : std_logic;
signal udp_write_end : std_logic;
signal write_ram_end : std_logic;
signal wait_cnt : std_logic;
signal udp_data [UDP_DEPTH-1:0] : std_logic;

signal i : std_logic;
signal j : std_logic;

signal write_sel : std_logic;

signal button_negedge : std_logic;

signal mac_not_exist : std_logic;
signal arp_found : std_logic;


type fsm is (IDLE, ARP_REQ, ARP_SEND, ARP_WAIT, GEN_REQ, WRITE_RAM,
            SEND, WAIT, CHECK_ARP);

signal state, next_state : fsm;

signal ram_cnt : std_logic_vector(15 downto 0);
signal almost_full_d0 : std_logic;
signal almost_full_d1 : std_logic;

begin

    process(gmii_tx_clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
        elsif rising_edge(gmii_tx_clk) then
            state <= next_state;
        end if; 
    end process;

    process(gmii_tx_clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    if wait_cnt = pack_total_len then
                        next_state <= ARP_REQ;
                    else 
                        next_state <= IDLE; 
                    end if;
                when ARP_REQ =>
                    next_state <= ARP_SEND;
                when ARP_SEND =>
                    if mac_send_end = '1' then
                        next_state <= ARP_WAIT;
                    else
                        next_state <= ARP_SEND;
                    end if;
                when ARP_WAIT =>
                    if arp_found = '1' then
                        next_state <= WAIT;
                    else
                        next_state <= ARP_WAIT;
                    end if;
                when GEN_REQ =>
                    if udp_ram_data_req = '1' then
                        next_state <= WRITE_RAM;
                    else
                        next_state <= GEN_REQ;
                    end if;
                when WRITE_RAM =>
                    if TEST_SPEED = '1' then
                        if ram_cnt = udp_send_data_length-1 then

                            next_state <= WAIT;
                            next_state <= WRITE_RAM;
                        end if;
                    end if;
                when SEND =>
                    if udp_tx_end = '1' then
                        next_state <= WAIT;
                    else
                        next_state <= SEND;
                    end if;
                when WAIT =>
                    next_state <= CHECK_ARP;
                    next_state <= WAIT;
                when CHECK_ARP =>
                    if mac_not_exist = '1' then
                        next_state <= ARP_REQ;
                    elsif almost_full_d1 = '1' then
                        next_state <= CHECK_ARP;
                    else
                        next_state <= GEN_REQ;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    write_ram_end <= udp_write_end when write_sel = '1' else
                     write_end;

    tx_ram_wr_data <= udp_rec_ram_rdata when write_sel = '1' else
                      ram_wr_data;
    
    tx_ram_wr_en <= udp_ram_wr_en when write_sel = '1' else
                    ram_wr_en;

    process(gmii_rx_clk, rst_n)
    begin
        if rst_n = '0' then
            gmii_rx_dv_d0 <= '0';
            gmii_rxd_d0 <= (others=>'0');
        elsif rising_edge(gmii_rx_clk) then
            gmii_rx_dv_d0 <= gmii_rx_dv;
            fmii_rxd_d0 <= gmii_rxd;
        end if;
    end process;

    process(gmii_tx_clk, rst_n)
    begin
        if rst_n = '0' then
            gmii_tx_en <= '0';
            gmii_txd <= (others=>'0');
        elsif rising_edge(gmii_tx_clk) then
            gmii_tx_en <= gmii_tx_en_tmp;
            gmii_txd <= gmii_txd_tmp;
        end if;
    end process;

impl_mac_top : mac_top
    port map(
        gmii_tx_clk                 => gmii_tx_clk,
        gmii_rx_clk                 => gmii_rx_clk,
        rst_n                       => rst_n,
        
        source_mac_addr             => x"000A3501FEC0",       --source mac address
        TTL                         => x"80",
        source_ip_addr              => x"C0A80002",
        destination_ip_addr         => x"C0A80003",
        udp_send_source_port        => x"1F90",
        udp_send_destination_port   => x"1F90",
        
        ram_wr_data                 => tx_ram_wr_data,
        ram_wr_en                   => tx_ram_wr_en,
        udp_ram_data_req            => udp_ram_data_req,
        udp_send_data_length        => udp_send_data_length,,
        udp_tx_end                  => udp_tx_end           ,
        almost_full                 => almost_full          , 
        
        udp_tx_req                  => udp_tx_req,
        arp_request_req             => arp_request_req ,
        
        mac_send_end                => mac_send_end,
        mac_data_valid              => gmii_tx_en_tmp,
        mac_tx_data                 => gmii_txd_tmp,
        rx_dv                       => gmii_rx_dv_d0   ,
        mac_rx_datain               => gmii_rxd_d0 ,
        
        udp_rec_ram_rdata           => udp_rec_ram_rdata,
        udp_rec_ram_read_addr       => udp_rec_ram_read_addr,
        udp_rec_data_length         => udp_rec_data_length ,
        
        udp_rec_data_valid          => udp_rec_data_valid,
        arp_found                   => arp_found ,
        mac_not_exist               => mac_not_exist
    );

    process(gmii_tx_clk)
    begin
        udp_data(0) <= 

    end process;


    process(gmii_rx_clk, rst_n)
    begin
        if rst_n = '0' then
            almost_full_d0 <= '0';
            almost_full_d1 <= '0';
        elsif rising_edge(clk) then
            almost_full_d0 <= almost_full;
            almost_full_d1 <= almost_full_d0;
        end if;
    end process;

    process(gmii_rx_clk, rst_n)
    begin
        if rst_n = '0' then
            udp_send_data_length <= (others=>'0');
        elsif rising_edge(gmii_rx_clk) then
            if write_sel = '1' then
                udp_send_data_length <= udp_rec_data_length - 8;
            end if;
        end if;
    end process;


    process(gmii_tx_clk, rst_n)
    begin
        if rst_n = '0' then
            write_sel <= '0';
        elsif rising_edge(clk) then
            if state = WAIT then
                if udp_rec_data_valid = '1' then
                    write_sel <= '1';
                else
                    write_sel <= '0';
                end if;
            end if;
        end if;
    end process;

    udp_tx_req <= (state = REQ_REQ);
    arp_request_req <= (state=ARP_REQ);

    process(gmii_tx_clk, rst_n)
    begin
        if rst_n = '0' then
            wait_cnt <= '0';
        elsif rising_edge(gmii_tx_clk) then
            if (state=IDLE or state=WAIT or state = ARP_WAIT) and state /= next_state then
                wait_cnt <= 0;
            elsif state = IDLE or state = WAIT or state = ARP_WAIT then
                wait_cnt <= 0;
            end if;
        end if;
    end process;

    if TEST_SPEED = '1' generate
        process(gmii_tx_clk, rst_n)
        begin
            if rst_n = '0' then
                ram_cnt <= (others=>'0');
            elsif rising_edge(gmii_tx_clk) then
                if state = WRITE_RAM then
                    ram_cnt <= ram_cnt + 1;
                else
                    ram_cnt <= (others=>'0');
                end if;
            end if;
        end process;

        process(gmii_tx_clk, rst_n)
        begin
            if rst_n = '0' then
                ram_wr_en <= '0';
            elsif rising_edge(gmii_tx_clk) then
                if state = WRITE_RAM then
                    ram_wr_en <= '1';
                else
                    ram_wr_en <= '0';
                end if; 
            end if;
        end process;

        process(gmii_tx_clk, rst_n)
        begin
            if rst_n = '0' then
                ram_wr_data <= (others=>'0');
            elsif rising_edge(gmii_tx_clk) then
                if state = WRITE_RAM then
                    ram_wr_data <= ram_cnt(7 downto 0);
                else
                    ram_wr_data <= (others=>'0');
                end if;
            end if;
        end process;
    end generate;

    if TEST_SPEED = '0' generate
        process(gmii_tx_clk, rst_n)
        begin
            if rst_n = '0' then
                write_end <= '0';
                ram_wr_data <= 0;
                ram_wr_en <= 0;
                i <= 0;
                j <= 0;
            elsif rising_edge(gmii_tx_clk) then
                if state = WRITE_RAM then
                    if i = 5 then
                        ram_wr_en <= '0';
                        write_end <= '1';

                    else
                        ram_wr_en <= '1';
                        write_end <= 0;
                        j <= j + 1;
                        case j is
                            when 0 =>  ram_wr_data <= udp_data(i)(31 downto 24);
                            when 1 =>  ram_wr_data <= udp_data(i)(23 downto 16);
                            when 2 =>  ram_wr_data <= udp_data(i)(15 downto 8);
                            when 3 =>  ram_wr_data <= udp_data(i)(7 downto 0);
                            when others => ram_wr_data <= (others=>'0');
                        end case;

                        if j = 3 then
                            j <= 0;
                            i <= i + 1;
                        end if;
                    end if;
                else
                    wrtie_end <= '0';
                    ram_wr_data <= 0;
                    ram_wr_en <= '0';
                    i <= 0;
                    j <= 0; 
                end if;
            end if;
        end process;
    end generate;

    process(gmii_tx_clk, rst_n)
    begin
        if rst_n = '0' then
            udp_rec_ram_read_addr <= (others=>'0'); 
        elsif rising_edge(gmii_tx_clk) then
            if state = WRITE_RAM then
                udp_rec_ram_read_addr <= udp_rec_ram_read_addr +1;
            else 
                udp_rec_ram_read_addr <= (others=>'0'); 
            end if;
        end if;
    end process;

    process(gmii_tx_clk, rst_n)
    begin
        if rst_n = '0' then
            udp_ram_wr_en <= '0';
        elsif rising_edge(gmii_tx_clk) then
            if state = WRITE_RAM and udp_rec_ram_read_addr < udp_rec_data_length-8 then
                udp_ram_wr_en <= '1';
            else
                udp_ram_wr_en <= '0'; 
            end if;
        end if;
    end process;

    process(gmii_tx_clk, rst_n)
    begin
        if rst_n = '0' then
            udp_write_end <= '0';
        elsif rising_edge(gmii_tx_clk) then
            if state = WRITE_RAM and udp_rec_ram_read_addr = udp_rec_data_length - 8 then
                udp_write_end <= '1';
            else
                udp_write_end <= '0';
            end if;
        end if;
    end process;

end architecture;