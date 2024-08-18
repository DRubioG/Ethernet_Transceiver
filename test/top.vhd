library ieee;
use ieee.std_logic_std.all;
use ieee.numeric_std.all;

entity top is
    port (
        sys_clk_p : in std_logic;
        sys_clk_n : in std_logic;
        rst_n : in std_logic;
        e_mdc : out std_logic;
        e_mio : inout std_logic;
        e_reset : out std_logic;
        rgmii_txd : out std_logic_vector(3 downto 0);
        rgmii_txctl : out std_logic;
        rgmii_txc : out std_logic;
        rgmii_rxd : in std_logic_vector(3 downto 0);
        rgmii_rxctl : in std_logic;
        rgmii_rxc : in std_logic
    );
end entity;

architecture arch_top of top is

component ethernet_test is
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
end component;

signal sys_clk : std_logic;
signal locked : std_logic;
signal rst_delay : unsigned(4 downto 0);

begin

    process(sys_clk, rst_n)
    begin
        if rst_n = '0' then
            rst_delay <= (others=>'0');
        elsif rising_edge(sys_clk) then
            rst_delay <= reset_delay +1;
        end if;
    end process;

    process(sys_clk, rst_n)
    begin
        if rst_n = '0' then
            e_reset <= '0';
        elsif rising_edge(clk) then
            if rst_delay = unsigned(19) then
                e_reset <= 1;
            else
                e_reset <= '0';
            end if;
        end if;
    end process;

impl_ethernet_test : ethernet_test
    port map (
        rst_n => locked,
        sys_clk => sys_clk,
        e_mdc => e_mdc,
        e_mdio => e_mdio,
        rgmii_txd => rgmii_txd,
        rgmii_txctl => rgmii_txctl,
        rgmii_txc => rgmii_txc,
        rgmii_rxd => rgmii_rxd,
        rgmii_rxctl => rgmii_rxctl,
        rgmii_rxc => rgmii_rxc
    );

end architecture;