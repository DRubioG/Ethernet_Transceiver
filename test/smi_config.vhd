library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smi_config is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        mdc : out std_logic;      --mdc interface
        mdio : inout std_logic;     --mdio interface
        speed : out std_logic_vector(1 downto 0);    --ethernet speed 00:10M 01:100M 10:1000M
        link : out std_logic;     --ethernet link signal
        led : out std_logic_vector(3 downto 0)       --led 1110: 10M  1100: 100M 1000:1000M  1111: not link
    );
end entity;

architecture arch_smi_config of smi_config is

signal phy_addr : std_logic_vector(4 downto 0);   --phy address 5'b0001
signal reg_addr : std_logic_vector(4 downto 0);   --phy register address
signal write_req : std_logic;   --write smi request
signal write_data : std_logic_vector(15 downto 0);   --write smi data
signal read_req : std_logic;   --read smi request
signal read_data : std_logic_vector(15 downto 0);   --read smi data
signal data_valid : std_logic;   --read smi data valid
signal done : std_logic;	 --write or read finished
signal read_data_buf : std_logic_vector(15 downto 0);   --read register data latch
signal timer  : std_logic_vector(31 downto 0);	 --wait counter 
signal phy_init_end : std_logic;
signal tm_cnt : std_logic_vector(25 downto 0);

type fsm is (IDLE, R_GEN_REQ, R_REG, R_CHECK, ETH_UNLINK,
            ETH_1000M. ETH_100M, ETH_10M, R_WAIT, R_GEN_REQ1,
            R_REG1, R_CHECK1);

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


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            tm_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            if phy_init_end = '0' then
                tm_cnt <= tm_cnt + 1;
            else
                tm_cnt <= tm_cnt;
            end if;
        end if;
    end process;

    process(clk, rst_n) 
    begin
        if rst_n = '0' then
            phy_init_end <= '0';
        elsif rising_edge(clk) then
            if tm_cnt >= then
                phy_init_end <= '1';
            end if;
        end if;
    end process;


    process(clk, phy_init_end)
    begin
        if phy_init_end = '1' then
            case state is
                when IDLE => 
                    next_state <= R_GEN_REQ1;
                when R_GEN_REQ1 =>
                    next_state <= R_REG1;
                when R_REG1 =>
                    if done = '1' then
                        next_state <= R_CHECK1;
                    else
                        next_state <= R_REG1;
                    end if;
                when R_CHECK1 =>
                    if read_data(2) = '0' then
                        next_state <= ETH_UNLINK;
                    else
                        next_state <= R_GEN_REQ;
                    end if;
                when R_GEN_REQ =>
                    next_state <= R_REG;
                when R_REG =>
                    if done = '1' then
                        next_state <= R_CHECK;
                    else
                        next_state <= R_REG;
                    end if;
                when R_CHECK =>
                    if read_data(6 downto 4) = "100" then
                        next_state <= ETH_1000M;
                    elsif read_data(6 downto 4) = "010" then
                        next_state <= ETH_100M;
                    elsif read_data(6 downto 4) = "001" then
                        next_state <= ETH_10M;
                    else
                        next_state <= R_CHECK;
                    end if;
                when ETH_UNLINK =>
                    next_state <= R_WAIT;
                when ETH_1000M =>
                    next_state <= R_WAIT;
                when ETH_100M =>
                    next_state <= R_WAIT;
                when ETH_10M =>
                    next_state <= R_WAIT;
                when R_WAIT =>
                    if timer = then
                        next_state <= R_GEN_REQ1;
                    else
                        next_state <= R_WAIT;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        else
            next_state <= state;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            speed <= "11";
        elsif rising_edge(clk) then
            if state = ETH_10M then
                speed <= "00";
            elsif state = ETH_100M then
                speed <= "01";
            elsif state = ETH_1000M then
                speed <= "10";
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            link <= '0';
        elsif rising_edge(clk) then
            if state = ETH_UNLINK then
                link <= '0';
            elsif state = ETH_10M or state = ETH_100M or state = ETH_1000M then
                link <= '1';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            led <= (others=>'0');
        elsif rising_edge(clk) then
            case speed is
                when "00" =>
                    led <= "1110";
                when "01" =>
                    led <= "1100";
                when "10" =>
                    led <= "1000";
                when others =>
                    led <= (others=>'1');
            end case;
        else
            led <= (others=>'1');
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            timer <= (others=>'0');
        elsif rising_edge(clk) then
            if state = R_WAIT then
                timer <= timer + 1;
            else
                timer <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            read_req <= '0';
        elsif rising_edge(clk) then
            if state = R_GEN_REQ or state = R_GEN_REQ1 then
                read_req <= '1';
            else    
                read_req <= '0';
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            read_data_buf <= (others=>'0');
        elsif rising_edge(clk) then
            read_data_buf <= read_data;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            phy_addr <= (others=>'0');
        elsif rising_edge(clk) then
            phy_addr <= (0=>'1', others=>'0');
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            reg_addr <= (others=>'0');
        elsif rising_edge(clk) then
            if state = R_REG1 then
                reg_addr <= (0=>'1', others=>'0');
            elsif state = R_REG then
                reg_addr <= (others=>'1');
            end if;
        end if;
    end process;


impl_smi_read_write : smi_read_write

end architecture;     