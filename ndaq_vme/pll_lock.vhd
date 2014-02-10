-- AD9510 Pll lock checker
-- v SVN controlled.

library ieee;
use ieee.std_logic_1164.all;
--
entity pll_lock is
	port
	(	signal rst		: in	std_logic;
		signal clk	        : in	std_logic;
		signal fifo0		: in	std_logic;
		signal fifo1		: in	std_logic;
		signal fifo2		: in	std_logic;
		signal fifo3		: in	std_logic;
		signal pll_lock         : in	std_logic;
		signal pll_locked       : out	std_logic := '0'
	);
end pll_lock;

architecture rtl of pll_lock is

	-- Build an enumerated type for the state machine
	type pdet_state_t	is (idle, p_locked, p_unlocked);

	-- Register to hold the current state
	signal pdet_state	: pdet_state_t := idle;

	-- Attribute "safe" implements a safe state machine.
	-- This is a state machine that can recover from an
	-- illegal state (by returning to the reset state).
	attribute syn_encoding	: string;
	attribute syn_encoding of pdet_state_t		: type is "safe, one-hot";
	
	signal	fifos 		: std_logic := '0';
	signal	r_fifos 	: std_logic := '0';
	signal	r_pll_lock 	: std_logic := '0';
	signal	i_pll_locked 	: std_logic := '0';
	
begin

	input_register:
	process (clk, rst)
	begin
		if (rst = '1') then
			r_pll_lock	<= '0';
		elsif (rising_edge(clk)) then
			fifos	<= (fifo0 or fifo1 or fifo2 or fifo3);
			r_fifos <= fifos;
			r_pll_lock <= pll_lock;
		end if;
	end process;
	
	pulse_detect_fsm:
	process (rst,clk) begin
		if (rst = '1') then
			pdet_state <= idle;
		elsif (clk'event and clk = '1') then
				case (pdet_state) is
						
					when idle =>
						if (r_pll_lock = '0') then
							pdet_state	<=	p_locked;
						else
							pdet_state	<=	idle;
						end if;
												
					when p_locked =>
						if (r_pll_lock = '1') then
							pdet_state	<=	p_unlocked;
						else
							pdet_state	<=	p_locked;
						end if;

					when p_unlocked =>
						if ((not(r_fifos) and fifos)='1') then
							pdet_state	<=	idle;
						else
							pdet_state	<=	p_unlocked;
						end if;
	
					when others =>
						pdet_state	<=	idle;
				
				end case;
		end if;
	end process;
	
	fsm_outputs:
	process (pdet_state)
	begin
		case (pdet_state) is

			when p_locked	=>
				i_pll_locked	<= '1';

			when others	=>
				i_pll_locked	<= '0';
			
		end case;
	end process;
	
	output_register:
	process (clk, rst)
	begin
		if (rst = '1') then
			
			pll_locked	<= '0';
			
		elsif (rising_edge(clk)) then
		
			pll_locked <= i_pll_locked;
			
		end if;
	end process;
	
end rtl;