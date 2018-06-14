--------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use ieee.math_real.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb IS
END tb;
 
ARCHITECTURE behavior OF tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT X3S500E
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         MOSI_i : in  std_logic;
         MISO_o : out  std_logic;
         SCLK_i : in  std_logic;
         SS_i : in  std_logic;
         test : OUT  std_logic_vector(3 downto 0);
         led1 : OUT  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal MOSI_i : std_logic := '0';
   signal SCLK_i : std_logic := '0';
   signal SS_i : std_logic := '0';

 	--Outputs
   signal MISO_o : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 22 ns;

	signal mspi_ready : std_logic;
	signal mspi_din_vld, mspi_dout_vld : std_logic;
--	signal mosi, miso, sclk, ss: std_logic;
	signal mspi_din, mspi_dout : std_logic_vector(7 downto 0);
	signal stlv_temp1 : std_logic_vector(7 downto 0);
	signal stlv_temp1a : std_logic_vector(7 downto 0);

	constant SLAVE_COUNT:  integer:= 2;

	signal addr: std_logic_vector(integer(ceil(log2(real(SLAVE_COUNT))))-1 downto 0); -- SPI slave address
--	signal addr: std_logic_vector(1 downto 0);
	type state_dout is (idle_dout, start_dout, time_delay_dout, done_dout);
	signal state_dout_reg, state_dout_next: state_dout;

	signal time_delay_reg, time_delay_next: unsigned(23 downto 0);
	signal test1: std_logic_vector(3 downto 0);
	signal addr2: std_logic_vector(1 downto 0);

	signal skip: std_logic;
	constant TIME_DELAY:  integer:= 50000;
	signal led2: std_logic_vector(3 downto 0);
	signal ss: std_logic;
	signal sample: unsigned(7 downto 0);
	signal last: std_logic;
	signal my_reset: std_logic;

BEGIN
 
my_reset <= not reset; 
 
	-- Instantiate the Unit Under Test (UUT)
   uut: X3S500E PORT MAP (
          clk => clk,
          reset => reset,
          MOSI_i => MOSI_i,
          MISO_o => MISO_o,
          SCLK_i => SCLK_i,
          SS_i =>ss,
          test => test1,
          led1 => led2
        );

spi_master_unit: entity work.SPI_MASTER(RTL)
	generic map(CLK_FREQ=>50000000,SCLK_FREQ=>10000,SLAVE_COUNT=>2)
	port map(CLK=>clk, RST=>my_reset,
	SCLK=>SCLK_i,
	CS_N=>addr2,
	MOSI=>MOSI_i,
	MISO=>MISO_o,
	ADDR=>addr,
	READY=>mspi_ready,
	DIN=>mspi_din,
	DIN_LAST=>last,
	DIN_VLD=>mspi_din_vld,
	DOUT=>mspi_dout,
	DOUT_VLD=>mspi_dout_vld);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
 	reset_proc: process
 	begin
 		reset <= '0';
 		wait for 100 ns;
 		reset <= '1';
 		wait;
 	end process;

ss <= addr(0);

   -- Stimulus process
echo_dout_unit2: process(clk, reset, state_dout_reg)
begin
	if reset = '0' then
		state_dout_reg <= idle_dout;
		stlv_temp1 <= (others=>'0');
		stlv_temp1a <= (others=>'0');
		mspi_din_vld <= '1';
		mspi_din <= (others=>'0');
		skip <= '0';
		time_delay_reg <= (others=>'0');
		time_delay_next <= (others=>'0');
		addr <= (others=>'0');
		sample <= (others=>'0');
		last <= '0';

	else if clk'event and clk = '1' then
		case state_dout_reg is
			when idle_dout =>
				if mspi_ready = '1' then
					last <= '1';
					mspi_din <= conv_std_logic_vector(conv_integer(sample),8);  -- write
					skip <= not skip;
					if skip = '1' then
						addr <= not addr;
						sample <= sample + 1;
					end if;
					mspi_din_vld <= '1';
					state_dout_next <= start_dout;
				end if;
			when start_dout =>
				last <= '0';
				mspi_din_vld <= '0';			
				if mspi_dout_vld = '1' then
-- mspi_dout is what gets received by MISO
					stlv_temp1a <= mspi_dout;
					state_dout_next <= time_delay_dout;
				end if;
			when time_delay_dout =>
				if time_delay_reg > TIME_DELAY then
					time_delay_next <= (others=>'0');
					state_dout_next <= done_dout;
				else
					time_delay_next <= time_delay_reg + 1;
				end if;	
			when done_dout =>	
				state_dout_next <= idle_dout;
		end case;
		time_delay_reg <= time_delay_next;
		state_dout_reg <= state_dout_next;
		end if;
	end if;
end process;	

END;
