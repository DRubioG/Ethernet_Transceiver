library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_tx_top is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        
        destination_mac_addr : in std_logic_vector(47 downto 0); --destination mac address
        source_mac_addr : in std_logic_vector(47 downto 0);       --source mac address
        TTL : in std_logic_vector(7 downto 0);
        source_ip_addr : in std_logic_vector(31 downto 0);
        destination_ip_addr : in std_logic_vector(31 downto 0);
        udp_send_source_port : in std_logic_vector(15 downto 0);
        udp_send_destination_port : in std_logic_vector(15 downto 0);
        
        arp_reply_ack : out std_logic;
        arp_reply_req : in std_logic;
        arp_rec_source_ip_addr : in std_logic_vector(31 downto 0);
        arp_rec_source_mac_addr : in std_logic_vector(47 downto 0);
        arp_request_req : in std_logic;
        
        
        ram_wr_data : in std_logic_vector(7 downto 0);
        ram_wr_en : in std_logic;
        udp_tx_req : in std_logic;
        udp_ram_data_req : out std_logic;
        udp_send_data_length : in std_logic_vector(15 downto 0);
        udp_tx_end : out std_logic;
        almost_full : out std_logic;
        
        upper_data_req : out std_logic;
        icmp_tx_ready : in std_logic;
        icmp_tx_data : in std_logic_vector(7 downto 0);
        icmp_tx_end : in std_logic;
        icmp_tx_req : in std_logic;
        icmp_tx_ack : out std_logic;
        icmp_send_data_length : in std_logic_vector(15 downto 0);
        
        mac_data_valid : out std_logic;
        mac_send_end : out std_logic;
        mac_tx_data : out std_logic_vector(7 downto 0)
    );
end entity;

architecture arch_mac_tx_top of mac_tx_top is

signal crcen : std_logic;
signal crcre : std_logic;
signal crc_din : std_logic_vector(7 downto 0);
signal crc_result : std_logic_vector(31 downto 0);
signal mac_data_req : std_logic;
signal mac_frame_data : std_logic_vector(7 downto 0);
signal mac_tx_ready : std_logic;
signal mac_tx_end : std_logic;
signal ip_tx_ready : std_logic;
signal ip_tx_data : std_logic_vector(7 downto 0);
signal ip_tx_end : std_logic;
signal arp_tx_ready : std_logic;
signal arp_tx_data : std_logic_vector(7 downto 0);
signal arp_tx_end : std_logic;
signal ip_send_data_length : std_logic_vector(15 downto 0);
signal udp_tx_data : std_logic_vector(7 downto 0);
signal udp_data_req : std_logic;
signal udp_tx_ready : std_logic;
signal udp_tx_req_tmp : std_logic;
signal upper_tx_ready : std_logic;
signal upper_layer_data : std_logic_vector(7 downto 0);
signal ip_send_type : std_logic_vector(7 downto 0);
signal arp_tx_req : std_logic;
signal arp_tx_ack : std_logic;
signal ip_tx_req  : std_logic;
signal ip_tx_ack  : std_logic;
signal mac_tx_ack  : std_logic;
signal mac_tx_req  : std_logic;
signal mac_ip_tx_ack : std_logic;
signal mac_arp_tx_ack : std_logic;
signal udp_tx_ack : std_logic;

begin


mac0 : mac_tx 
    port map (
        clk                        => clk,
        rst_n                      => rst_n,
        crc_result                 => crc_result,
        crcen                      => crcen,
        crcre                      => crcre,
        crc_din                    => crc_din,
        mac_tx_req                 => mac_tx_req,
        mac_frame_data             => mac_frame_data,
        mac_tx_ready               => mac_tx_ready,
        mac_tx_end                 => mac_tx_end,
        mac_tx_ack                 => mac_tx_ack,
        mac_tx_data                => mac_tx_data,
        mac_send_end               => mac_send_end,
        mac_data_valid             => mac_data_valid,
        mac_data_req               => mac_data_req    
    ) ;
       
mode0 : mac_tx_mode 
    port map (
        clk                        => clk,
        rst_n                      => rst_n,
        mac_send_end               => mac_send_end,
        arp_tx_req                 => arp_tx_req,
        arp_tx_ready               => arp_tx_ready,
        arp_tx_data                => arp_tx_data,
        arp_tx_end                 => arp_tx_end,
        arp_tx_ack                 => mac_arp_tx_ack,
        ip_tx_req                  => ip_tx_req,
        ip_tx_ready                => ip_tx_ready,
        ip_tx_data                 => ip_tx_data,
        ip_tx_end                  => ip_tx_end,
        ip_tx_ack                  => mac_ip_tx_ack,
        mac_tx_ack                 => mac_tx_ack,
        mac_tx_req                 => mac_tx_req,
        mac_tx_ready               => mac_tx_ready,
        mac_tx_data                => mac_frame_data,
        mac_tx_end                 => mac_tx_end        
    );
            
c0 : crc 
    port map (
        Clk                        => clk,
        Reset                      => crcre,
        Data_in                    => crc_din,
        Enable                     => crcen,
        Crc                        => crc_result,
        CrcNext                    =>           open  
    ) ;
    
arp_tx0 : arp_tx 
    port map(
        clk                        => clk,
        rst_n                      => rst_n,
        destination_mac_addr       => destination_mac_addr, //destination mac address
        source_mac_addr            => source_mac_addr, //source mac address
        source_ip_addr             => source_ip_addr, //source ip address
        destination_ip_addr        => destination_ip_addr, //destination ip address
        mac_data_req               => mac_data_req,
        mac_send_end               => mac_send_end,
        mac_tx_ack                 => mac_arp_tx_ack,		 
        arp_tx_req                 => arp_tx_req, 
        arp_request_req            => arp_request_req,         //arp request
        arp_reply_ack              => arp_reply_ack,
        arp_reply_req              => arp_reply_req,
        arp_rec_source_ip_addr     => arp_rec_source_ip_addr,
        arp_rec_source_mac_addr    => arp_rec_source_mac_addr,
        arp_tx_ready               => arp_tx_ready,
        arp_tx_data                => arp_tx_data,
        arp_tx_end                 => arp_tx_end              
    ) ;
       
       
ip0 : ip_tx 
    port map(
        clk                          => clk,
        rst_n                        => rst_n,
        destination_mac_addr         => destination_mac_addr, //destination mac address
        source_mac_addr              => source_mac_addr,       //source mac address
        ip_send_data_length          => ip_send_data_length,
        TTL                          => TTL,
        ip_send_type                 => ip_send_type,
        source_ip_addr               => source_ip_addr,
        destination_ip_addr          => destination_ip_addr,
        upper_layer_data             => upper_layer_data,
        upper_data_req               => upper_data_req,
        upper_tx_ready               => upper_tx_ready,
        mac_data_req                 => mac_data_req,
        mac_send_end                 => mac_send_end,		
        mac_tx_ack                   => mac_ip_tx_ack,
        ip_tx_req                    => ip_tx_req,
        ip_tx_ack                    => ip_tx_ack,
        ip_tx_ready                  => ip_tx_ready,
        ip_tx_data                   => ip_tx_data,
        ip_tx_end                    => ip_tx_end                  
    ) ;
      
ipmode : ip_tx_mode 
    port map (
        clk                          => clk,
        rst_n                        => rst_n,
        mac_send_end                 => mac_send_end,
        udp_tx_req                   => udp_tx_req_tmp,
        udp_tx_ack                   => udp_tx_ack,
        udp_tx_ready                 => udp_tx_ready,
        udp_tx_data                  => udp_tx_data,
        udp_send_data_length         => udp_send_data_length,
        icmp_tx_req                  => icmp_tx_req,
        icmp_tx_ack                  => icmp_tx_ack,
        icmp_tx_ready                => icmp_tx_ready,
        icmp_tx_data                 => icmp_tx_data,
        icmp_send_data_length        => icmp_send_data_length,
        ip_tx_req                    => ip_tx_req,
        ip_tx_ack                    => ip_tx_ack,
        ip_tx_ready                  => upper_tx_ready,
        ip_tx_data                   => upper_layer_data,
        ip_send_type                 => ip_send_type,
        ip_send_data_length          => ip_send_data_length        
    );
           
udp0 : udp_tx 
    port map(
        clk                            => clk,
        rst_n                          => rst_n,
        source_ip_addr                 => source_ip_addr,
        destination_ip_addr            => destination_ip_addr,
        udp_send_source_port           => udp_send_source_port,
        udp_send_destination_port      => udp_send_destination_port,
        udp_send_data_length           => udp_send_data_length,
        udp_ram_data_req               => udp_ram_data_req,
        mac_send_end                   => mac_send_end,
        ip_tx_req                      => udp_tx_req_tmp,
        ip_tx_ack                      => udp_tx_ack,
        ram_wr_data                    => ram_wr_data,
        ram_wr_en                      => ram_wr_en,
        udp_tx_req                     => udp_tx_req,
        udp_data_req                   => upper_data_req,
        udp_tx_ready                   => udp_tx_ready,
        udp_tx_data                    => udp_tx_data,
        udp_tx_end                     => udp_tx_end,
        almost_full                    => almost_full                      
    ) ;

end architecture;