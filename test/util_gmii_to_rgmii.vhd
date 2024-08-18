library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity util_gmii_to_rgmii is
    port (
        rgmii_rxc : in std_logic;--add
        reset : in std_logic;
        rgmii_td : out std_logic_vector(3 downto 0);
        rgmii_tx_ctl : out std_logic;
        rgmii_txc : out std_logic;
        rgmii_rd : in std_logic_vector(3 downto 0);
        rgmii_rx_ctl : in std_logic;
        gmii_rx_clk : out std_logic;
        gmii_txd : in std_logic_vector(7 downto 0);
        gmii_tx_en : in std_logic;
        gmii_tx_er : in std_logic;
        gmii_tx_clk : out std_logic;
        gmii_crs : out std_logic;
        gmii_col : out std_logic;
        gmii_rxd : out std_logic_vector(7 downto 0);
        gmii_rx_dv : out std_logic;
        gmii_rx_er : out std_logic;
        speed_selection : in std_logic_vector(1 downto 0); -- 1x gigabit, 01 100Mbps, 00 10mbps
        duplex_mode : in std_logic     -- 1 full, 0 half
    );
end entity;

architecture arch_util_gmii_to_rgmii of util_gmii_to_rgmii is

signal gigabit : std_logic;
signal gmii_tx_clk_s : std_logic;
signal gmii_rx_dv_s : std_logic;
signal gmii_rxd_s : std_logic_vector(7 downto 0);
signal rgmii_rx_ctl_delay : std_logic;
signal rgmii_rx_ctl_s : std_logic;
-- registers
signal tx_reset_d1 : std_logic;
signal tx_reset_sync : std_logic;
signal rx_reset_d1 : std_logic;
signal gmii_txd_r : std_logic_vector(7 downto 0);
signal gmii_tx_en_r : std_logic;
signal gmii_tx_er_r : std_logic;
signal gmii_txd_r_d1 : std_logic_vector(7 downto 0);
signal gmii_tx_en_r_d1 : std_logic;
signal gmii_tx_er_r_d1 : std_logic;

signal rgmii_tx_ctl_r : std_logic;
signal gmii_txd_low : std_logic_vector(3 downto 0);
signal gmii_col : std_logic;
signal gmii_crs : std_logic;

signal gmii_rxd : std_logic_vector(7 downto 0);
signal gmii_rx_dv : std_logic;
signal gmii_rx_er : std_logic;
signal gmii_rx_clk_s : std_logic;
signal speed_selection_d0 : std_logic_vector(1 downto 0);
signal speed_selection_d1 : std_logic_vector(1 downto 0);

begin

    process(gmii_rx_clk)
    begin
        if rising_edge(gmii_rx_clk) then
            speed_selection_d0 <= speed_selection;
            speed_selection_d1 <= speed_selection_d0;
        end if;
    end process;    

    gigabit <= '1';
    gmii_tx_clk <= gmii_tx_clk_s;
    gmii_tx_clk_s <= gmii_rx_clk;
    gmii_rx_clk <= rgmii_rxc;

    process(gmii_rx_clk)
    begin
        if rising_edge(gmii_rx_clk) then
            gmii_rxd <= gmii_rxd_s;
            gmii_rx_dv = gmii_rx_dv_s;
            gmii_rx_er <= gmii_rx_dv_s xor rgmii_rx_ctl_s;
        end if;
    end process;


    process(gmii_tx_clk_s)
    begin
        if rising_edge(gmii_rx_clk) then
            tx_reset_d1 <= reset;
            tx_reset_sync <= tx_reset_d1;
        end if;
    end process ;

    process(gmii_tx_clk_s)
    begin
        if rising_edge(gmii_tx_clk_s) then
            rgmii_tx_ctl_r <= gmii_tx_en_r xor gmii_tx_er_r;
            gmii_txd_low <= gmii_txd_r(7 downto 4) when gigabit = '1' else
                            gmii_txd_r(3 downto 0);
            gmii_clk <= '0' when duplex_mode = '1' else
                        (gmii_tx_en_r or gmii_tx_er_r) and (gmii_rx_dv or gmii_rx_er);
            gmii_crs <= '0' when duplex_mode = '0' else
                        (gmii_tx_en_r or gmii_tx_er_r or gmii_rx_dv or gmii_rx_er);                
        end if;
    end process;

    process(gmii_tx_clk_s)
    begin
        if tx_reset_sync = '1' then
            gmii_txd_r <= (others=>'0');
            gmii_tx_en_r <= '0';
            gmii_tx_er_r <= '0';
            gmii_txd_r_d1 <= (others=>'0');
            gmii_tx_en_e_d1 <= '0';
            gmii_tx_er_r_d1 <= '0';
        elsif rising_edge(gmii_tx_clk_s) then
            gmii_txd_r <= gmii_txd;
            gmii_tx_en_r <= gmii_tx_en;
            gmii_tx_er_r <= gmii_tx_er;
            gmii_txd_r_d1 <= gmii_txd_r;
            gmii_tx_en_e_d1 <= gmii_tx_en_r;
            gmii_tx_er_r_d1 <= gmii_tx_er_r;
        end if;
    end process;    

impl_ODDRE1 : ODDRE1
    generic map(
        IS_C_INVERTED => 0,      -- Optional inversion for C
        IS_D1_INVERTED => 0,     -- Unsupported, do not use
        IS_D2_INVERTED => 0,     -- Unsupported, do not use
        SRVAL => 0               -- Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
    )
    port map (
        Q => rgmii_txc,   -- 1-bit output: Data output to IOB
        C => gmii_tx_clk_s,   -- 1-bit input: High-speed clock input
        D1 => 1, -- 1-bit input: Parallel data input 1
        D2 => 0, -- 1-bit input: Parallel data input 2
        SR => 0  -- 1-bit input: Active High Async Reset
    );


impl_gen_tx_data : for i in gmii_txd_low'range generate
impl_ODDRE1_2 : ODDRE1 
    generic map(
        IS_C_INVERTED => 0,      -- Optional inversion for C
        IS_D1_INVERTED => 0,     -- Unsupported, do not use
        IS_D2_INVERTED => 0,     -- Unsupported, do not use
        SRVAL => 0               -- Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
    )
    port map (
        Q => rgmii_td(i),   -- 1-bit output: Data output to IOB
        C => gmii_tx_clk_s,   -- 1-bit input: High-speed clock input
        D1 => gmii_txd_r_d1(i), -- 1-bit input: Parallel data input 1
        D2 => gmii_txd_low(i), -- 1-bit input: Parallel data input 2
        SR => 0  -- 1-bit input: Active High Async Reset
    );
    end generate;



impl_ODDRE2 : ODDRE1
    generic map(
        IS_C_INVERTED => 0,      -- Optional inversion for C
        IS_D1_INVERTED => 0,     -- Unsupported, do not use
        IS_D2_INVERTED => 0,     -- Unsupported, do not use
        SRVAL => 0               -- Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
    )
    port map (
        Q => rgmii_tx_ctl,   -- 1-bit output: Data output to IOB
        C => gmii_tx_clk_s,   -- 1-bit input: High-speed clock input
        D1 => gmii_tx_en_r_d1, -- 1-bit input: Parallel data input 1
        D2 => rgmii_tx_ctl_r, -- 1-bit input: Parallel data input 2
        SR => 0  -- 1-bit input: Active High Async Reset
    );


impl_gen_tx_data : for i in gmii_txd_low'range generate
impl_IDDRE1 : IDDRE1 
    generic map(
        DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
        IS_CB_INVERTED => '1',          -- Optional inversion for CB
        IS_C_INVERTED => '0'            -- Optional inversion for C
    )
    port map (
        Q1 => gmii_rxd_s(i), -- 1-bit output: Registered parallel output 1
        Q2 => gmii_rxd_s(i+4), -- 1-bit output: Registered parallel output 2
        C => gmii_rx_clk,   -- 1-bit input: High-speed clock
        CB => gmii_rx_clk, -- 1-bit input: Inversion of High-speed clock C
        D => rgmii_rd(i),   -- 1-bit input: Serial Data Input
        R => 0    -- 1-bit input: Active High Async Reset
    );
    end generate;


impl_IDDRE1_2 : IDDRE1 
    generic map(
        DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
        IS_CB_INVERTED => '1',          -- Optional inversion for CB
        IS_C_INVERTED => '0'            -- Optional inversion for C
    )
    port map (
        Q1 => gmii_rx_dv_s, -- 1-bit output: Registered parallel output 1
        Q2 => rgmii_rx_ctl_s, -- 1-bit output: Registered parallel output 2
        C => gmii_rx_clk,   -- 1-bit input: High-speed clock
        CB => gmii_rx_clk, -- 1-bit input: Inversion of High-speed clock C
        D => rgmii_rx_ctl,   -- 1-bit input: Serial Data Input
        R => 0    -- 1-bit input: Active High Async Reset
    );


end architecture;