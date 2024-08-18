library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arp_tx is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        
        destination_mac_addr : in std_logic_vector(47 downto 0); --destination mac address
        source_mac_addr : in std_logic_vector(47 downto 0); --source mac address
        source_ip_addr : in std_logic_vector(31 downto 0); --source ip address
        destination_ip_addr : in std_logic_vector(31 downto 0); --destination ip address
        
        mac_data_req : in std_logic;            --mac layer request data
        arp_request_req : in std_logic;         --arp request
        arp_reply_ack : out std_logic;           --arp reply ack to arp rx module
        arp_reply_req : in std_logic;           --arp reply request from arp rx module
        arp_tx_req : in std_logic;
        arp_rec_source_ip_addr : in std_logic_vector(31 downto 0);
        arp_rec_source_mac_addr : in std_logic_vector(47 downto 0);
        mac_send_end : in std_logic;
        mac_tx_ack : in std_logic;
        
        arp_tx_ready : out std_logic;
        arp_tx_data : out std_logic_vector(7 downto 0);
        arp_tx_end : out std_logic
    );
end entity;

architecture arch_arp_tx of arp_tx is

constant mac_type : std_logic_vector(15 downto 0) := x"0806";
constant hardware_type : std_logic_vector(15 downto 0) := x"0001";
constant protocol_type : std_logic_vector(15 downto 0) := x"0800";
constant mac_length : std_logic_vector(7 downto 0) := x"06";
constant ip_length : std_logic_vector(7 downto 0) := x"04";
constant ARP_REQUEST_CODE : std_logic_vector(15 downto 0) := x"0001";
constant ARP_REPLY_CODE : std_logic_vector(15 downto 0) := x"0002";


signal op ;

signal arp_destination_ip_addr ;
signal arp_destination_mac_addr  ;
signal arp_send_cnt ;
signal timeout ;
signal mac_send_end_d0 ;

type fsm is (IDLE, ARP_REQUEST_WAIT_0, ARP_REQUEST_WAIT_1, ARP_REQUEST,
            ARP_REPLY_WAIT_0, ARP_REPLY_WAIT_1, ARP_REPPLY, ARP_END);
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
                    if arp_request_req = '1' then
                        next_state <= ARP_REQUEST_WAIT_0;
                    elsif arp_reply_req = '1' then
                        next_state <= ARP_REPLY_WAIT_0;
                    else
                        next_state <= IDLE;
                    end if;
                when ARP_REQUEST_WAIT_0 =>
                    if mac_tx_ack = '1' then
                        next_state <= ARP_REQUEST_WAIT_1;
                    else
                        next_state <= ARP_REQUEST_WAIT_0;
                    end if;
                when ARP_REQUEST_WAIT_1 =>
                    if mac_data_req = '1' then
                        next_state <= ARP_REQUEST;
                    elsif timeout = (timeout'range=>'1') then
                        next_state <= IDLE;
                    else
                        next_state <= ARP_REQUEST_WAIT_1;
                    end if;
                when ARP_REQUEST =>
                    if arp_tx_end = '1' then
                        next_state <= ARP_END;
                    else 
                        next_state <= ARP_REQUEST;
                    end if;
                when ARP_REPLY_WAIT_0 =>
                    if mac_tx_ack = '1' then
                        next_state <= ARP_REPLY_WAIT_1;
                    else
                        next_state <= ARP_REPLY_WAIT_0;
                    end if;
                when ARP_REPLY_WAIT_1 =>
                    if mac_data_req = '1' then
                        next_state <= ARP_REPLY;
                    elsif timeout = (timeout'range=>'1') then
                        next_state <= IDLE;
                    else
                        next_state <= ARP_REPLY_WAIT_1;
                    end if; 
                when ARP_REPLY =>
                    if arp_tx_end = '1' then
                        next_state <= ARP_END;
                    else
                        next_state <= ARP_REPLY;
                    end if;
                when ARP_END =>
                    if mac_send_end_d0 = '1' then
                        next_state <= IDLE;
                    else
                        next_state <= ARP_END;
                    end if;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mac_send_end_d0 <= '0';
        else
            mac_send_end_d0 <= mac_send_end;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_tx_req <= '0';
        elsif state = ARP_REQUEST_WAIT_0 or state = ARP_REPLY_WAIT_0 then
            arp_tx_req <= '1';
        else
            arp_tx_req <= '0';
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            op <= (others=>'0);
        elsif rising_edge(clk) then
            if state = ARP_REPLY then
                op <= AR_REPLY_CODE;
            else
                op <= ARP_REQUEST_CODE;
            end if; 
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_tx_ready <= '0';
        elsif rising_edge(clk) then
            if state = ARP_REQUEST_WAIT_1 or state = ARP_REPLY_WAIT_1 then
                arp_tx_ready <= '1';
            else
                arp_tx_ready <= '0';
            end if;
        end if; 
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_tx_end <= '0';
        elsif rising_edge(clk) then
            if (state = ARP_REQUES and arp_send_cnt = 59) or (state = ARP_REPLY and arp_send_cnt = 59) then
                arp_tx_end <= '1';
            else
                arp_tx_end <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            timeout <= (others=>'0');
        elsif rising_edge(Clk) then
            if state = ARP_REQUEST_WAIT_1 or state = ARP_REPLY_WAIT_1 then
                timeout <= timeout +1;
            else
                timeout <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_destination_ip_addr <= (others=>'0');
        elsif rising_edge(clk) then
            if state = ARP_REQUEST_WAIT_1 then
                arp_destination_ip_addr <= destination_ip_addr;
            elsif state = ARP_REPLY_WAIT_1 then
                arp_destination_ip_addr -= arp_rec_source_ip_addr;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_destination_mac_addr <= (others=>'0');
        elsif rising_edge(clk) then
            if state = ARP_REQUEST_WAIT_1 then
                arp_destination_mac_addr <= destination_mac_addr;
            elsif state = ARP_REPLY_WAIT_1 then
                arp_destination_mac_addr <= arp_rec_source_mac_addr;
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_reply_ack <= '0';
        elsif rising_edge(clk) then
            if state = ARP_REPLY_WAIT_1 then
                arp_reply_ack <= '1';
            else 
                arp_reply_ack <= '0';
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_send_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            if state = ARP_REQUEST or state = ARP_REPLY then
                arp_send_cnt <= arp_send_Cnt + 1;
            else
                arp_send <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            arp_tx_data <= (others=>'0');
        elsif rising_edge(clk) then
            if state = ARP_REQUEST or state = ARP_REPLY then
                case arp_send_cnt is
                    when 0 => arp_tx_data <= arp_destination_mac_addr(47 downto 40);
                    when 1 => arp_tx_data <= arp_destination_mac_addr(39 downto 32);
                    when 2 => arp_tx_data <= arp_destination_mac_addr(31 downto 24);
                    when 3 => arp_tx_data <= arp_destination_mac_addr(23 downto 16);
                    when 4 => arp_tx_data <= arp_destination_mac_addr(15 downto 8);
                    when 5 => arp_tx_data <= arp_destination_mac_addr(7 downto 0);
                    when 6 => arp_tx_data <= source_mac_addr(47 downto 40);
                    when 7 => arp_tx_data <= source_mac_addr(39 downto 32);
                    when 8 => arp_tx_data <= source_mac_addr(31 downto 24);
                    when 9 => arp_tx_data <= source_mac_addr(23 downto 16);
                    when 10 => arp_tx_data <= source_mac_addr(15 downto 8);
                    when 11 => arp_tx_data <= source_mac_addr(7 downto 0);
                    when 12 => arp_tx_data <= mac_type(15 downto 8);
                    when 13 => arp_tx_data <= mac_type(7 downto 0);
                    when 14 => arp_tx_data <= hardware_type(15 downto 8);
                    when 15 => arp_tx_data <= hardware_type(7 downto 0);
                    when 16 => arp_tx_data <= protocol_type(15 downto 8);
                    when 17 => arp_tx_data <= protocol_type(7 downto 0);
                    when 18 => arp_tx_data <= mac_length;
                    when 19 => arp_tx_data <= ip_length;
                    when 20 => arp_tx_data <= op(15 downto 8);
                    when 21 => arp_tx_data <= op(7 downto 0);
                    when 22 => arp_tx_data <= source_mac_addr(47 downto 40);
                    when 23 => arp_tx_data <= source_mac_addr(39 downto 32);
                    when 24 => arp_tx_data <= source_mac_addr(31 downto 24);
                    when 25 => arp_tx_data <= source_mac_addr(23 downto 16);
                    when 26 => arp_tx_data <= source_mac_addr(15 downto 8);
                    when 27 => arp_tx_data <= source_mac_addr(7 downto 0);
                    when 28 => arp_tx_data <= source_ip_addr(31 downto 24);
                    when 29 => arp_tx_data <= source_ip_addr(23 downto 16);
                    when 30 => arp_tx_data <= source_ip_addr(15 downto 8);
                    when 31 => arp_tx_data <= source_ip_addr(7 downto 0);
                    when 32 => arp_tx_data <= arp_destination_mac_addr(47 downto 40);
                    when 33 => arp_tx_data <= arp_destination_mac_addr(39 downto 32);
                    when 34 => arp_tx_data <= arp_destination_mac_addr(31 downto 24);
                    when 35 => arp_tx_data <= arp_destination_mac_addr(23 downto 16);
                    when 36 => arp_tx_data <= arp_destination_mac_addr(15 downto 8);
                    when 37 => arp_tx_data <= arp_destination_mac_addr(7 downto 0);
                    when 38 => arp_tx_data <= arp_destination_ip_addr(31 downto 24);
                    when 39 => arp_tx_data <= arp_destination_ip_addr(23 downto 16);
                    when 40 => arp_tx_data <= arp_destination_ip_addr(15 downto 8);
                    when 41 => arp_tx_data <= arp_destination_ip_addr(7 downto 0);
                    when others => arp_tx_data <= (others=>'0');
                end case;
            else
                arp_tx_data <= (others=>'0');
            end if;
        end if; 
    end process;



end architecture;