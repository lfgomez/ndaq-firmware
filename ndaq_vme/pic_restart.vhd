-- PIC Time Restart
-- v SVN controlled.

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

--
entity pic_restart is
	port
	(	signal rst		: in	std_logic;
		signal clk	        : in	std_logic;
		signal output_restart   : out	std_logic := '0'
	);
end pic_restart;

architecture rtl of pic_restart is

	-- Build an enumerated type for the state machine
	type pdet_state_t	is (idle, p_on, p_reset);

	-- Register to hold the current state
	signal pdet_state	: pdet_state_t := idle;

	-- Attribute "safe" implements a safe state machine.
	-- This is a state machine that can recover from an
	-- illegal state (by returning to the reset state).
	attribute syn_encoding	: string;
	attribute syn_encoding of pdet_state_t		: type is "safe, one-hot";
	
	signal counterWait		: std_logic_vector(15 downto 0); --unsigned(15 downto 0);
	signal counterOn		: std_logic_vector(15 downto 0);--unsigned(15 downto 0);

	signal i_output_restart : std_logic;
	
	
	
	
begin

	input_register:
	process (clk, rst)
	begin
		if (rst = '1') then
		--	counterWait	<= x"0000";
		--	counterOn	<= x"0000";
		end if;
	end process;
	
	pulse_detect_fsm:
	process (rst,clk) begin
		if (rst = '1') then
			pdet_state <= idle;
		elsif (clk'event and clk = '1') then
				case (pdet_state) is
						
					when idle =>
						counterWait <= counterWait + 1;
						
						if (counterWait = x"4000") then
						    pdet_state <= p_on;
						else
						    pdet_state <= idle;
						    end if;
												
					when p_on =>
							counterOn <= counterOn + 1;
							 
						    if (counterOn = x"0080") then
							    pdet_state <= idle;
						    else
							    pdet_state <= p_on;
						    end if;

					when p_reset =>
							  counterWait <= x"0000";
							  counterOn <= x"0000";
							  pdet_state <= idle;
							  

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
				i_output_restart <= '1';

			when others	=>
				i_output_restart <= '0';
			
		end case;
	end process;
	
	output_register:
	process (clk, rst)
	begin
		if (rst = '1') then
			
			output_restart <= '0';
			
		elsif (rising_edge(clk)) then
		
			output_restart <= i_output_restart;
			
		end if;
	end process;
	
end rtl;