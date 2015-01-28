-- Push Buttom Emulator
-- v SVN controlled.

library ieee;
use ieee.std_logic_1164.all;
--
entity tpush is
	port
	(	signal rst		: in	std_logic;
		signal clk	        : in	std_logic;
		signal timer		: in	std_logic_vector(7 downto 0);
		signal state0		: in	std_logic;
		signal state1		: in	std_logic;		
		signal trigger		: in 	std_logic;
		signal triggerout	: out 	std_logic := '0';
		signal output_sig       : out	std_logic := 'Z'
	);
end tpush;

architecture rtl of pll_lock is

	-- Build an enumerated type for the state machine
	type pdet_state_t	is (idle, p_on, p_reset);

	-- Register to hold the current state
	signal pdet_state	: pdet_state_t := idle;

	-- Attribute "safe" implements a safe state machine.
	-- This is a state machine that can recover from an
	-- illegal state (by returning to the reset state).
	attribute syn_encoding	: string;
	attribute syn_encoding of pdet_state_t		: type is "safe, one-hot";
	
	signal counter		: std_logic_vector(7 downto 0);
	signal r_trigger	: std_logic;
	signal s_trigger	: std_logic;
	signal i_output_sig	: std_logic;
	signal i_triggerout	: std_logic; 
	
	
	
	
begin

	input_register:
	process (clk, rst)
	begin
		if (rst = '1') then
			counter		<= x"00";
			r_trigger	<= '0';
			s_trigger	<= '0';
			i_triggerout	<= '0';
		elsif (rising_edge(clk)) then
			r_trigger <= trigger;
			s_trigger <= r_trigger;
		end if;
	end process;
	
	pulse_detect_fsm:
	process (rst,clk) begin
		if (rst = '1') then
			pdet_state <= idle;
		elsif (clk'event and clk = '1') then
				case (pdet_state) is
						
					when idle =>
						if (r_trigger = '1') and (s_trigger = '0') then
							pdet_state	<=	p_on;
						else
							pdet_state	<=	idle;
						end if;
												
					when p_on =>
						    counter <= counter + 1;
						    if (counter = timer) then
							    counter <= (others => x"00");
							    state <= p_reset;
						    else
							    state <= p_on;
						    end if;

					when p_reset =>
							    state <= idle;
						    
					when others =>
						pdet_state	<=	idle;
				
				end case;
		end if;
	end process;
	
	fsm_outputs:
	process (pdet_state)
	begin
		case (pdet_state) is

			when p_on	=>
				i_output_sig	<= state1;
				i_triggerout	<= '0';

			when p_reset	=>
				i_output_sig	<= state1;
				i_triggerout	<= '1';

			when others	=>
				i_output_sig	<= state0;
				i_triggerout	<= '0';
			
		end case;
	end process;
	
	output_register:
	process (clk, rst)
	begin
		if (rst = '1') then
			
			output_sig	<= 'Z';
			i_triggerout	<= '0';
			
		elsif (rising_edge(clk)) then
		
			output_sig 	<= i_output_sig;
			triggerout	<= i_triggerout;
			
		end if;
	end process;
	
end rtl;