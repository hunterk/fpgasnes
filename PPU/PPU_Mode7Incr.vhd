----------------------------------------------------------------------------------
-- Design Name:		Mode7Increment.vhd
-- Module Name:		Mode7Increment
--
-- Description: 	Compute Texture X,Y coordinate for the next horizontal pixel.
--					
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_Mode7Incr is
    Port ( 	
				clock		: in  STD_LOGIC;
				
				-- 10.8 Format.
				load		: in STD_LOGIC;
				inc			: in STD_LOGIC;
				LoadX		: in STD_LOGIC_VECTOR(26 downto 0);
				LoadY		: in STD_LOGIC_VECTOR(26 downto 0);
				
				--  8.8 Format. 
				M7_A 		: in STD_LOGIC_VECTOR(15 downto 0);
				M7_C 		: in STD_LOGIC_VECTOR(15 downto 0);
				
				-- 10.8 Format.
				TX			: out STD_LOGIC_VECTOR(26 downto 0);
				TY			: out STD_LOGIC_VECTOR(26 downto 0)
	);
end PPU_Mode7Incr;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_Mode7Incr of PPU_Mode7Incr is
	signal tmpTX		: STD_LOGIC_VECTOR	(26 downto 0);
	signal tmpTY		: STD_LOGIC_VECTOR	(26 downto 0);
begin
	--
	--
	--
    process(clock, load, inc, LoadX, LoadY, M7_A, M7_C)
    begin
		if (clock='1' and clock'event) then
			if (load = '1') then
				tmpTX <= LoadX;
				tmpTY <= LoadY;				
			else
				if (inc = '1') then
					tmpTX <= tmpTX + (  M7_A(15) & M7_A(15) & M7_A(15) & M7_A(15) & 
										M7_A(15) & M7_A(15) & M7_A(15) & M7_A(15) & 
										M7_A(15) & M7_A(15) & M7_A);
										
					tmpTY <= tmpTY + (  M7_C(15) & M7_C(15) & M7_C(15) & M7_C(15) & 
										M7_C(15) & M7_C(15) & M7_C(15) & M7_C(15) & 
										M7_C(15) & M7_C(15) & M7_C);
				end if;
			end if;
		end if;
	end process;
	
	TX			<= tmpTX;
	TY			<= tmpTY;
end PPU_Mode7Incr;
