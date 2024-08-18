library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_tx_mode is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        mac_send_end : in std_logic;
        arp_tx_req : in std_logic;
        arp_tx_ready : in std_logic;
        arp_tx_data : in std_logic_vector(7 downto 0);
        arp_tx_end : in std_logic;
        arp_tx_ack : out std_logic;
        ip_tx_req : in std_logic;
        ip_tx_ready : in std_logic;
        ip_tx_data : in std_logic_vector(7 downto 0);
        ip_tx_end : in std_logic;
        ip_tx_ack : out std_logic;
        mac_tx_ack : in std_logic;
        mac_tx_req : out std_logic;		 
        mac_tx_ready : out std_logic;
        mac_tx_data : out std_logic_vector(7 downto 0);
        mac_tx_end : out std_logic
    );
end entity;

architecture arch_mac_tx_mode of mac_tx_mode is

signal timeout : std_logic_vector(15 downto 0);

type fsm is ( IDLE, ARP_WAIT, ARP, IP_WAIT, IP);
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
                    if arp_tx_req = '1' then
                        next_state <= ARP_WAIT;
                    elsif ip_tx_req = '1' then
                        next_state <= IP_WAIT;
                    else
                        next_state <= IDLE;
                    end if;
                when ARP_WAIT =>
                    if mac_tx_ack = '1' then
                        next_state <= ARP;
                    else
                        next_state <= IP;
                    end if;
                when ARP =>
                    if mac_send_end = '1' then
                        next_state <= IDLE;
                    elsif tiemout = (timeout'range=>'1') then
                        next_state <= IDLE;
                    else
                        next_state <= ARP;
                    end if;
                when IP_WAIT =>
                    if mac_tx_ack = '1' then
                        next_state <= IP;
                    else
                        next_state <= IP_WAIT;
                    end if;
                when IP =>
                    if mac_send_end = '1' then
                        next_state <= IDLE;
                    elsif timeout = (timeout'range=>'1') then
                        next_state <= IDLE;
                    else
                        next_state <= IP;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            timeout <= (others=>'0');
        elsif rising_edge(clk) then
            if state = ARP or state = IP then
                timeout <= timeout + 1;
            else
                timeout <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_tx_ack <= '0';
        elsif rising_edge(clk) then
            if state = ARP then
                arp_tx_ack <= '1';
            else
                arp_tx_ack <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ip_tx_ack <= '0';
        elsif rising_edge(Clk) then
            if state = IP then
                ip_tx_ack <= '1';
            else
                ip_tx_ack <= '0';
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mac_tx_req <= '0';
        elsif rising_edge(clk) then
            if state = ARP_WAIT or state = IP_WAIT then
                mac_tx_req <= '1';
            else
                mac_tx_req <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mac_tx_ready <= '0';
            mac_tx_data <= (others=>'0');
            mac_tx_end <= '0';
        elsif rising_edge(Clk) then
            if state = ARP then
                mac_tx_ready <= arp_tx_ready;
                mac_tx_data <= arp_tx_data;
                mac_tx_end <= arp_tx_end;
            elsif state = IP then
                mac_tx_ready <= ip_tx_ready;
                mac_tx_data <= ip_tx_data;
                mac_tx_end <= ip_tx_end;
            else
                mac_tx_ready <= '0';
                mac_tx_data <= (others=>'0');
                mac_tx_end <= '0';
            end if;
        end if; 
    end process;

end architecture;