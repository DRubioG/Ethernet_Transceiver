library ieee;
use ieee.std_logic_std.all;
use ieee.numeric_std.all;

entity ethernet_test is
    port (
        rst_n : in std_logic;
        sys_clk : in std_logic;   
        e_mdc : out std_logic;
        e_mdio : inout std_logic;
        rgmii_txd : out std_logic_vector(3 downto 0);
        rgmii_txctl : out std_logic;
        rgmii_txc : out std_logic;
        rgmii_rxd : in std_logic_vector(3 downto 0);
        rgmii_rxctl : in std_logic;
        rgmii_rxc : in std_logic
    );
end entity;

architecture arch_ethernet_test of ethernet_test is
    
    
component gmii_arbi is
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
end component;

signal gmii_txd : std_logic_vector(7 downto 0);
signal gmii_tx_en : std_logic;
signal gmii_tx_er : std_logic;
signal gmii_tx_clk : std_logic;
signal gmii_crs : std_logic;
signal gmii_col : std_logic;
signal gmii_rxd : std_logic_vector(7 downto 0);
signal gmii_rx_dv : std_logic;
signal gmii_rx_er : std_logic;
signal gmii_rx_clk : std_logic;
signal pack_total_len : std_logic_vector(31 downto 0);
signal duplex_mode : std_logic;
signal speed : std_logic_vector(1 downto 0);
signal link : std_logic;
signal e_rx_dv : std_logic;
signal e_rxd : std_logic_vector(7 downto 0);
signal e_txd_en : std_logic;
signal e_txd : std_logic_vector(7 downto 0);
signal e_rst_n : std_logic;

begin




arbi_inst : gmii_arbi 
    port map(
        clk              => gmii_tx_clk      ,
        rst_n            => rst_n            ,
        speed            => speed            ,  
        link             => link             , 
        pack_total_len   => pack_total_len   , 
        e_rst_n          => e_rst_n          ,
        gmii_rx_dv       => gmii_rx_dv       ,
        gmii_rxd         => gmii_rxd         ,
        gmii_tx_en       => gmii_tx_en       ,
        gmii_txd         => gmii_txd         , 
        e_rx_dv          => e_rx_dv          ,
        e_rxd            => e_rxd            ,
        e_tx_en          => e_tx_en          ,
        e_txd            => e_txd            
    );



smi_config_inst : smi_config  
    port map (
        clk       => sys_clk  ,
        rst_n     => rst_n    ,		 
        mdc       => e_mdc    ,
        mdio      => e_mdio   ,
        speed     => speed    ,
        link      => link     
    );
            
util_gmii_to_rgmii_m0 : util_gmii_to_rgmii 
    port map(
        reset                => ~rst_n           ,
        
        rgmii_td             => rgmii_txd       ,
        rgmii_tx_ctl         => rgmii_txctl     ,
        rgmii_txc            => rgmii_txc       ,
        rgmii_rd             => rgmii_rxd       ,
        rgmii_rx_ctl         => rgmii_rxctl     ,
        rgmii_rxc            => rgmii_rxc       ,
                                                
        gmii_txd             => e_txd           ,
        gmii_tx_en           => e_tx_en         ,
        gmii_tx_er           => 1'b0            ,
        gmii_tx_clk          => gmii_tx_clk     ,
        gmii_crs             => gmii_crs        ,
        gmii_col             => gmii_col        ,
        gmii_rxd             => gmii_rxd        ,
        gmii_rx_dv           => gmii_rx_dv      ,
        gmii_rx_er           => gmii_rx_er      ,
        gmii_rx_clk          => gmii_rx_clk     ,
        duplex_mode          => duplex_mode     
    );

            
mac_test0 : mac_test 
    port map(
        gmii_tx_clk          => gmii_tx_clk     ,
        gmii_rx_clk          => gmii_rx_clk     ,
        rst_n                => e_rst_n         ,

        pack_total_len       => pack_total_len  ,
        gmii_rx_dv           => e_rx_dv         ,
        gmii_rxd             => e_rxd           ,
        gmii_tx_en           => gmii_tx_en      ,
        gmii_txd             => gmii_txd        
    ); 


end architecture;