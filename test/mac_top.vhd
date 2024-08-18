library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_top is
    port(
        gmii_tx_clk : in std_logic;
        gmii_rx_clk : in std_logic;
        rst_n : in std_logic;
        source_mac_addr : in std_logic_vector(47 downto 0);       --source mac address
        TTL : in std_logic_vector(7 downto 0);
        source_ip_addr : in std_logic_vector(31 downto 0);
        destination_ip_addr : in std_logic_vector(31 downto 0);
        udp_send_source_port : in std_logic_vector(15 downto 0);
        udp_send_destination_port : in std_logic_vector(15 downto 0);
        ram_wr_data : in std_logic_vector(7 downto 0);
        ram_wr_en : in std_logic;
        udp_ram_data_req : in std_logic;
        udp_send_data_length : in std_logic_vector(15 downto 0);
        udp_tx_end : in std_logic;
        almost_full : in std_logic;
        udp_tx_req : in std_logic;
        arp_request_req : in std_logic;
        mac_data_valid : in std_logic;
        mac_send_end : in std_logic;
        mac_tx_data : in std_logic_vector(7 downto 0);
        rx_dv : in std_logic;
        mac_rx_datain : in std_logic_vector(7 downto 0);
        udp_rec_ram_rdata : in std_logic_vector(7 downto 0);
        udp_rec_ram_read_addr : in std_logic_vector(10 downto 0);
        udp_rec_data_length : in std_logic_vector(15 downto 0);
        udp_rec_data_valid : in std_logic;
        arp_found : in std_logic;
        mac_not_exist : in std_logic;
    );
end entity;
       

architecture arch_mac_top of mac_top is

signal arp_reply_ack : std_logic;
signal arp_reply_req : std_logic;
signal arp_rec_source_ip_addr : std_logic_vector(31 downto 0);
signal arp_rec_source_mac_addr : std_logic_vector(47 downto 0);
signal destination_mac_addr : std_logic_vector(47 downto 0);
signal mac_rx_dataout : std_logic_vector(7 downto 0);
signal upper_layer_data_length : std_logic_vector(15 downto 0);
signal icmp_rx_req : std_logic;
signal icmp_rev_error : std_logic;
signal upper_data_req : std_logic;
signal icmp_tx_ready : std_logic;
signal icmp_tx_data : std_logic_vector(7 downto 0);
signal icmp_tx_end : std_logic;
signal icmp_tx_req : std_logic;
signal icmp_tx_ack : std_logic;
signal icmp_send_data_length : std_logic_vector(15 downto 0);

begin

mac_tx0 : mac_tx_top 
    port map (
        clk                       => gmii_tx_clk,
        rst_n                     => rst_n,
        destination_mac_addr      => destination_mac_addr, --destination mac address
        source_mac_addr           => source_mac_addr,       --source mac address
        TTL                       => TTL,
        source_ip_addr            => source_ip_addr,
        destination_ip_addr       => destination_ip_addr,
        udp_send_source_port      => udp_send_source_port,
        udp_send_destination_port => udp_send_destination_port,
        arp_reply_ack             => arp_reply_ack,
        arp_reply_req             => arp_reply_req,
        arp_rec_source_ip_addr    => arp_rec_source_ip_addr,
        arp_rec_source_mac_addr   => arp_rec_source_mac_addr,
        arp_request_req           => arp_request_req,
        ram_wr_data               => ram_wr_data,
        ram_wr_en                 => ram_wr_en,
        udp_tx_req                => udp_tx_req,
        udp_send_data_length      => udp_send_data_length,
        udp_ram_data_req          => udp_ram_data_req,
        udp_tx_end                => udp_tx_end,
        almost_full               => almost_full,  
        upper_data_req            => upper_data_req,
        icmp_tx_ready             => icmp_tx_ready,
        icmp_tx_data              => icmp_tx_data,
        icmp_tx_end               => icmp_tx_end,
        icmp_tx_req               => icmp_tx_req,
        icmp_tx_ack               => icmp_tx_ack,
        icmp_send_data_length     => icmp_send_data_length,
        mac_data_valid            => mac_data_valid,
        mac_send_end              => mac_send_end,
        mac_tx_data               => mac_tx_data
    );


               
mac_rx0 : mac_rx_top 
    port map (
        clk                     => gmii_rx_clk,
        rst_n                   => rst_n,
        rx_dv                   => rx_dv,
        mac_rx_datain           => mac_rx_datain,
        local_ip_addr           => source_ip_addr,
        local_mac_addr          => source_mac_addr,
        arp_reply_ack           => arp_reply_ack,
        arp_reply_req           => arp_reply_req,
        arp_rec_source_ip_addr  => arp_rec_source_ip_addr,
        arp_rec_source_mac_addr => arp_rec_source_mac_addr,
        udp_rec_ram_rdata       => udp_rec_ram_rdata,
        udp_rec_ram_read_addr   => udp_rec_ram_read_addr,
        udp_rec_data_length     => udp_rec_data_length,
        udp_rec_data_valid      => udp_rec_data_valid,
        mac_rx_dataout          => mac_rx_dataout,
        upper_layer_data_length => upper_layer_data_length,
        ip_total_data_length    => icmp_send_data_length,
        icmp_rx_req             => icmp_rx_req,
        icmp_rev_error          => icmp_rev_error,
        arp_found               => arp_found
    ) ;


icmp0 : icmp_reply 
    port map (
        clk                     => gmii_rx_clk,
        rst_n                   => rst_n,
        mac_send_end            => mac_send_end,
        icmp_rx_data            => mac_rx_dataout,
        icmp_rx_req             => icmp_rx_req,
        icmp_rev_error          => icmp_rev_error,        
        upper_layer_data_length => upper_layer_data_length,        
        icmp_data_req           => upper_data_req,
        icmp_tx_ready           => icmp_tx_ready,
        icmp_tx_data            => icmp_tx_data,
        icmp_tx_end             => icmp_tx_end,
        ip_tx_ack               => icmp_tx_ack,
        icmp_tx_req             => icmp_tx_req 
    );


cache0 : arp_cache 
    port map (
        clk                        => gmii_tx_clk,
        rst_n                      => rst_n,
        arp_found                  => arp_found,
        arp_rec_source_ip_addr     => arp_rec_source_ip_addr ,
        arp_rec_source_mac_addr    => arp_rec_source_mac_addr,
        destination_ip_addr        => destination_ip_addr,
        destination_mac_addr       => destination_mac_addr,
        mac_not_exist              => mac_not_exist
    );



    
end architecture;