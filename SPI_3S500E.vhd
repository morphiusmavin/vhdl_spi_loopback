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

entity X3S500E is
	port(
		clk, reset: in std_logic;

--		MOSI_o : out std_logic;
--		MISO_i : in std_logic;
--		SCLK_o : out std_logic;
--		SS_o : out std_logic_vector(1 downto 0);
		MOSI_i : in std_logic;
		MISO_o : out std_logic;
		SCLK_i : in std_logic;
		SS_i : in std_logic;
		test : out std_logic_vector(3 downto 0);
		led1: out std_logic_vector(3 downto 0)
		);
end X3S500E;

architecture truck_arch of X3S500E is

	type state_dout is (idle_dout, start_dout, done_dout, wait_dout);
	signal state_dout_reg, state_dout_next: state_dout;

	signal time_delay_reg, time_delay_next: unsigned(23 downto 0);
	signal time_delay_reg7, time_delay_next7: unsigned(23 downto 0);

	signal mspi_ready : std_logic;
	signal mspi_din_vld, mspi_dout_vld : std_logic;
--	signal mosi, miso, sclk, ss: std_logic;
	signal mspi_din, mspi_dout : std_logic_vector(7 downto 0);
	signal echo_data : std_logic_vector(7 downto 0);
	constant TIME_DELAY:  integer:= 50000;
	signal my_reset: std_logic;

begin

my_reset <= not reset;

spi_slave_unit: entity work. SPI_SLAVE(RTL)
	port map(CLK=>clk, RST=>my_reset,
	SCLK=>SCLK_i,
	CS_N=>SS_i,
	MOSI=>MOSI_i,
	MISO=>MISO_o,
	READY=>mspi_ready,
	DIN=>mspi_din,
	DIN_VLD=>mspi_din_vld,
	DOUT=>mspi_dout,
	DOUT_VLD=>mspi_dout_vld);

echo_dout_unit2: process(clk, reset, state_dout_reg)
variable temp1: integer range 0 to 255:= 0;
variable temp2: integer range 0 to 255:= 255;
variable temp3: integer range 0 to 7:= 1;
begin
	if reset = '0' then
		state_dout_reg <= idle_dout;
		echo_data <= (others=>'0');
		mspi_din_vld <= '0';
		mspi_din <= (others=>'0');
		time_delay_reg7 <= (others=>'0');
		time_delay_next7 <= (others=>'0');
		led1 <= "1010";
		test <= (others=>'0');

	else if clk'event and clk = '1' then
		case state_dout_reg is
			when idle_dout =>
				mspi_din_vld <= '0';
				if mspi_ready = '1' then
					state_dout_next <= start_dout;
				end if;
			when start_dout =>
				state_dout_next <= done_dout;
			when done_dout =>
				if mspi_dout_vld = '1' then
					echo_data <= mspi_dout;  -- mspi_dout is what gets received by MISO
					led1 <= echo_data(3 downto 0);
--					state_dout_next <= wait_dout;
					state_dout_next <= wait_dout;
				end if;
			when wait_dout =>
				mspi_din <= echo_data;		-- write
				mspi_din_vld <= '1';
				state_dout_next <= idle_dout;
		end case;
		time_delay_reg7 <= time_delay_next7;
		state_dout_reg <= state_dout_next;
		end if;
	end if;
end process;	


end truck_arch;


