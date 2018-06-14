-- SPI_3S500E.vhd - 6/13/2018 -- Dan Hampleman - test program as part of a larger project
-- a loopback test for 2 different slaves in the uut and a master in the test bench
-- slave1 & 2 gets MOSI, MISO, SCLK while slave1 gets SS(0) and slave2 gets SS(1)
-- spi_master.vhd and spi_slave.vhd use active low reset but I use active high
-- use my_reset to invert it
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use ieee.math_real.all;

entity X3S500E is
	port(
		clk, reset: in std_logic;

		MOSI_i : in std_logic;
		MISO_o : out std_logic;
		SCLK_i : in std_logic;
		SS_i : in std_logic_vector(1 downto 0);
		test : out std_logic_vector(3 downto 0);
		led1: out std_logic_vector(3 downto 0)
		);
end X3S500E;

architecture truck_arch of X3S500E is

	type state_dout1 is (idle_dout1, start_dout1, done_dout1, wait_dout1);
	signal state_dout_reg1, state_dout_next1: state_dout1;

	type state_dout2 is (idle_dout2, start_dout2, done_dout2, wait_dout2);
	signal state_dout_reg2, state_dout_next2: state_dout2;

	signal mspi_ready1 : std_logic;
	signal mspi_din_vld1, mspi_dout_vld1 : std_logic;
	signal mspi_din1, mspi_dout1 : std_logic_vector(7 downto 0);

	signal mspi_ready2 : std_logic;
	signal mspi_din_vld2, mspi_dout_vld2 : std_logic;
	signal mspi_din2, mspi_dout2 : std_logic_vector(7 downto 0);

	signal echo_data1 : std_logic_vector(7 downto 0);
	signal echo_data2 : std_logic_vector(7 downto 0);
	signal MISO1, MISO2: std_logic;
	
	constant TIME_DELAY:  integer:= 50000;
	signal my_reset: std_logic;
	constant SLAVE_COUNT:  integer:= 2;
	signal addr: std_logic_vector(integer(ceil(log2(real(SLAVE_COUNT))))-1 downto 0); -- SPI slave address

begin

my_reset <= not reset;

MISO_o <= MISO1 and MISO2;

spi_slave_unit1: entity work. SPI_SLAVE(RTL)
	port map(CLK=>clk, RST=>my_reset,
	SCLK=>SCLK_i,
	CS_N=>SS_i(0),
	MOSI=>MOSI_i,
	MISO=>MISO1,
	READY=>mspi_ready1,
	DIN=>mspi_din1,
	DIN_VLD=>mspi_din_vld1,
	DOUT=>mspi_dout1,
	DOUT_VLD=>mspi_dout_vld1);

spi_slave_unit2: entity work. SPI_SLAVE(RTL)
	port map(CLK=>clk, RST=>my_reset,
	SCLK=>SCLK_i,
	CS_N=>SS_i(1),
	MOSI=>MOSI_i,
	MISO=>MISO2,
	READY=>mspi_ready2,
	DIN=>mspi_din2,
	DIN_VLD=>mspi_din_vld2,
	DOUT=>mspi_dout2,
	DOUT_VLD=>mspi_dout_vld2);

echo_dout_unit1: process(clk, reset, state_dout_reg1)
begin
	if reset = '0' then
		state_dout_reg1 <= idle_dout1;
		echo_data1 <= (others=>'0');
		mspi_din_vld1 <= '0';
		mspi_din1 <= (others=>'0');

	else if clk'event and clk = '1' then
		case state_dout_reg1 is
			when idle_dout1 =>
				mspi_din_vld1 <= '0';
				if mspi_ready1 = '1' then
					state_dout_next1 <= start_dout1;
				end if;
			when start_dout1 =>
				state_dout_next1 <= done_dout1;
			when done_dout1 =>
				if mspi_dout_vld1 = '1' then
					echo_data1 <= mspi_dout1;  -- mspi_dout is what gets received by MISO
					state_dout_next1 <= wait_dout1;
				end if;
			when wait_dout1 =>
				mspi_din1 <= echo_data1;		-- write
				mspi_din_vld1 <= '1';
				state_dout_next1 <= idle_dout1;
		end case;
		state_dout_reg1 <= state_dout_next1;
		end if;
	end if;
end process;	

echo_dout_unit2: process(clk, reset, state_dout_reg2)
begin
	if reset = '0' then
		state_dout_reg2 <= idle_dout2;
		echo_data2 <= (others=>'0');
		mspi_din_vld2 <= '0';
		mspi_din2 <= (others=>'0');
		led1 <= "1010";
		test <= (others=>'0');

	else if clk'event and clk = '1' then
		case state_dout_reg2 is
			when idle_dout2 =>
				mspi_din_vld2 <= '0';
				if mspi_ready2 = '1' then
					state_dout_next2 <= start_dout2;
				end if;
			when start_dout2 =>
				state_dout_next2 <= done_dout2;
			when done_dout2 =>
				if mspi_dout_vld2 = '1' then
					echo_data2 <= mspi_dout2;  -- mspi_dout is what gets received by MISO
					led1 <= echo_data2(3 downto 0);
--					state_dout_next <= wait_dout;
					state_dout_next2 <= wait_dout2;
				end if;
			when wait_dout2 =>
				mspi_din2 <= echo_data2;		-- write
				mspi_din_vld2 <= '1';
				state_dout_next2 <= idle_dout2;
		end case;
		state_dout_reg2 <= state_dout_next2;
		end if;
	end if;
end process;	

end truck_arch;


