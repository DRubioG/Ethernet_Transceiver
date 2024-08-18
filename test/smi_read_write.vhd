library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity smi_read_write is
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        mdc : out std_logic;           --mdc interface
        mdio : inout std_logic;          --mdio interface
        phy_addr : in std_logic_vector(4 downto 0);      --phy address
        reg_addr : in std_logic_vector(4 downto 0);      --phy register address
        write_req : in std_logic;    --write smi request
        write_data : in std_logic_vector(15 downto 0);    --write smi data
        read_req : in std_logic;      --read smi request
        read_data : out std_logic_vector(15 downto 0);     --read smi data
        data_valid : out std_logic;    --read smi data valid
        done : out std_logic           --write or read finished
    );
end entity;

architecture arch_smi_read_write of smi_read_write is


constant ST : std_logic_vector(1 downto 0) := "01";
constant W_OP : std_logic_vector(1 downto 0) := "01";
constant R_OP : std_logic_vector(1 downto 0) := "10";
constant W_TA : std_logic_vector(1 downto 0) := "10";

signal cycle : std_logic_vector(15 downto 0);         --REF_CLK*1000/MDC_CLK
signal mdc_cnt : std_logic_vector(15 downto 0);         --mdc counter
signal mdc_d0 : std_logic;
signal mdc_posedge : std_logic;         --mdc posedge
signal mdc_negedge : std_logic;         --mdc negedge
signal mdio_en : std_logic;         --mdio direction select
signal mdio_out : std_logic;         --mdio output data
signal write_cnt : std_logic_vector(5 downto 0);         --write bit counter
signal read_cnt : std_logic_vector(4 downto 0);         --read bit counter
signal mdio_in : std_logic_vector(3 downto 0);         --mdio input data

type fsm is (IDLE, W_MDIO, R_MDIO, R_TA, R_DATA, W_END, R_END);
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
                    mdio_en <= '1';
                    if write_req = '1' then
                        next_state <= WMDIO;
                    elsif read_req = '1' then
                        next_state <= R_MDIO;
                    else
                        next_state <= IDLE;
                    end if;
                when W_MDIO =>
                    mdio_en <= '1';
                    if write_cnt = then
                        next_state <= W_END;
                    else
                        next_state <= W_MDIO;
                    end if;
                when R_MDIO =>
                    if write_cnt = then
                        next_state <= R_TA;
                        mdio_en <= '0';
                    else
                        next_state <= R_MDIO;
                        mdio_en <= '1';
                    end if;
                when R_TA =>
                    mdio_en <= '0';
                    if write_cnt = then
                        next_state <= R_DATA;
                    else
                        next_state <= R_TA;
                    end if;
                when R_DATA =>
                    mdio_en <= '0';
                    if read_cnt = and mdc_negedge = '1' then
                        next_state <= R_END;
                    else
                        next_state <= R_DATA;
                    end if;
                when W_END | R_END =>
                    next_state <= IDLE;
                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    data_valid <= (state = R_END);

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            done <= '0';
        elsif rising_edge(clk) then
            if state = W_END or state = R_END then
                done <= '1';
            else
                done <= '0';
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mdc_cnt <= (others=>'0');
        elsif rising_edge(clk) then    
            if mdc_cnt = cycle -1 then
                mdc_cnt <= (others=>'0');
            else
                mdc_cnt <= mdc_cnt + 1;
            end if;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mdc <= '0';
        elsif rising_edge(clk) then
            if mdc_cnt = cycle/2-1 then
                mdc <= not mdc;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mdc_d0 <= '0';
            mdc_posedge <= '0';
            mdc_negedge <= '0';
        elsif rising_edge(clk) then
            mdc_d0 <= mdc;
            mdc_posedge <= not mdc_d0 and mdc;
            mdc_negedge <= not mdc and mdc_d0;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            write_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            if state = W_MDIO or state = R_MDIO or state = R_TA then
                if mdc_negedge = '1' then
                    write_cnt <= write_cnt + 1;
                end if;
            else
                write_cnt <= (others=>'0');
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            read_cnt <= (others=>'0');
        elsif rising_edge(clk) then
            if state = R_DATA then
                if mdc_posedge = '1' then
                    read_cnt <= read_cnt + 1;
                end if;
            else
                read_cnt <= (others=>'0');
            end if;
        end if; 
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mdio_out <= '1';
        elsif rising_edge(clk) then
            if state = W_MDIO then
                case write_cnt is
                    when 1 => mdio_out <= ST(1);
                    when 2 => mdio_out <= ST(0);
                    when 3 => mdio_out <= w_OP(1);
                    when 4 => mdio_out <= W_OP(1);
                    when 5 => mdio_out <= phy_addr(4);
                    when 6 => mdio_out <= phy_addr(3);
                    when 7 => mdio_out <= phy_addr(2);
                    when 8 => mdio_out <= phy_addr(1);
                    when 9 => mdio_out <= phy_addr(0);
                    when 10 => mdio_out <= reg_addr(4);
                    when 11 => mdio_out <= reg_addr(3);
                    when 12 => mdio_out <= reg_addr(2);
                    when 13 => mdio_out <= reg_addr(1);
                    when 14 => mdio_out <= reg_addr(0);
                    when 15 => mdio_out <= W_TA(1);
                    when 16 => mdio_out <= W_TS(0);
                    when 17 => mdio_out <= write_data(15);
                    when 18 => mdio_out <= write_data(14);
                    when 19 => mdio_out <= write_data(13);
                    when 20 => mdio_out <= write_data(12);
                    when 21 => mdio_out <= write_data(11);
                    when 22 => mdio_out <= write_data(10);
                    when 23 => mdio_out <= write_data(9);
                    when 24 => mdio_out <= write_data(8);
                    when 25 => mdio_out <= write_data(7);
                    when 26 => mdio_out <= write_data(6);
                    when 27 => mdio_out <= write_data(5);
                    when 28 => mdio_out <= write_data(4);
                    when 29 => mdio_out <= write_data(3);
                    when 30 => mdio_out <= write_data(2);
                    when 31 => mdio_out <= write_data(1);
                    when 32 => mdio_out <= write_data(0);
                    when others => mdio_out <= 'Z';
                end case;
            elsif state = R_MDIO then
                case write_cnt is
                    when 1 => mdio_out <= ST(1);
                    when 2 => mdio_out <= ST(0);
                    when 3 => mdio_out <= R_OP(1);
                    when 4 => mdio_out <= R_OP(0);
                    when 5 => mdio_out <= phy_addr(4);
                    when 6 => mdio_out <= phy_addr(3);
                    when 7 => mdio_out <= phy_addr(2);
                    when 8 => mdio_out <= phy_addr(1);
                    when 9 => mdio_out <= phy_addr(0);
                    when 10 => mdio_out <= reg_addr(4);
                    when 11 => mdio_out <= reg_addr(3);
                    when 12 => mdio_out <= reg_addr(2);
                    when 13 => mdio_out <= reg_addr(1);
                    when 14 => mdio_out <= reg_addr(0);
                    when others =>  mdio_out <= mdio_out;
                end case;
            else
                mdio_out <= '1';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mdio_in <= (others=>'0');
        elsif rising_edge(clk) then
            mdio_in <= mdio_in(2 downto 0) & mdio;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            read_data <= (others=>'0');
        elsif rising_edge(clk) then
            if state = R_DATA then
                if mdc_posedge = '1' then
                    read_data <= read(14 downto 0) & mdio_in(3);
                end if;
            elsif state = R_MDIO then
                read_data <= (others=>'0');
            end if;
        end if;
    end process;

end architecture;