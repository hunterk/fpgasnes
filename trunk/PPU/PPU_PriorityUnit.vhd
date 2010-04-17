----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_PriorityUnit.vhd
-- Module Name:		PPU_PriorityUnit
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use CONSTANTS.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_PriorityUnit is
    Port (
		--
		-- Current Pixel information.
		--
		BG4_valid			: in STD_LOGIC;
		BG3_valid			: in STD_LOGIC;
		BG2_valid			: in STD_LOGIC;
		BG1_valid			: in STD_LOGIC;
		OBJ_valid			: in STD_LOGIC;
		BG4_TilePrio		: in STD_LOGIC;
		BG3_TilePrio		: in STD_LOGIC;
		BG2_TilePrio		: in STD_LOGIC;
		BG1_TilePrio		: in STD_LOGIC;
		OBJ_Prio			: in STD_LOGIC_VECTOR(1 downto 0);

		--
		-- General Information.
		--
		mode				: in STD_LOGIC_VECTOR(2 downto 0);
		b2105_3				: in STD_LOGIC;	-- Priority bit BG3 for mode 1

		--
		-- 000 : Obj
		-- 001 : BG 1
		-- 010 : BG 2
		-- 011 : BG 3
		-- 100 : BG 4
		-- 111 : NONE
		--
		unitSelect			: out STD_LOGIC_VECTOR(2 downto 0)
	);
end PPU_PriorityUnit;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_PriorityUnit of PPU_PriorityUnit is
	signal res					: STD_LOGIC_VECTOR(2 downto 0);
	signal specialBitMode1		: STD_LOGIC;
	signal mode01				: STD_LOGIC;
	signal mode7				: STD_LOGIC;
begin
	process (mode, b2105_3)
	begin
		-- OPTIMIZE : May optimize test mode="001" test if HW compiler does not optimize.
		if (mode=CONSTANTS.MODE0 or mode=CONSTANTS.MODE1) then
			mode01 <= '1'; 
		else
			mode01 <= '0';
		end if;
		
		if (mode=CONSTANTS.MODE7) then
			mode7	<= '1';
		else
			mode7	<= '0';
		end if;
		
		if (b2105_3='1' and mode=CONSTANTS.MODE1) then
			specialBitMode1 <= '1';
		else
			specialBitMode1 <= '0';
		end if;
	end process;
	
	-- The background priority is (from 'front' to 'back'):
	--  BG3 tiles with  priority 1 and (bit 3 of $2105 is set and mode3)
	--  Sprites   with  priority 3
	--  BG1 tiles with  priority 1 and (!mode7)
	--  Sprites   with  priority 2 and (mode >= 2)
	--  BG2 tiles with  priority 1
	--  Sprites   with (priority 2 and (mode <  2)) || (priority 1 and mode >= 2)
	--  BG1 tiles with  priority 0 or  (mode7)
	--  Sprites   with  priority 0 and (mode >= 2)
	--  BG2 tiles with  priority 0
	--  Sprites   with  priority 1 and (mode <  2)
	--  BG3 tiles with  priority 1 and not(bit 3 of $2105 is set and mode3)
	--  BG4 tiles with  priority 1
	--  Sprites   with  priority 0 and (mode <  2)
	--  BG3 tiles with  priority 0
	--  BG4 tiles with  priority 0
	
	process (BG4_valid,BG3_valid,BG2_valid,BG1_valid,OBJ_valid,
			 BG4_TilePrio,BG3_TilePrio,BG2_TilePrio,BG1_TilePrio,OBJ_Prio,
			 specialBitMode1,mode7,mode01)
	begin
		--  BG3 tiles with  priority 1 and (bit 3 of $2105 is set and mode3)
		if (BG3_valid='1' and BG3_TilePrio = '1' and specialBitMode1='1') then
			res <= CONSTANTS.BG3_SEL;
		else
			--  Sprites   with  priority 3
			if (OBJ_valid='1' and OBJ_Prio="11") then
				res <= CONSTANTS.OBJECTS_SEL;
			else
				--  BG1 tiles with  priority 1 and (!mode7)
				if (BG1_valid='1' and BG1_TilePrio='1' and mode7='0') then
					res <= CONSTANTS.BG1_SEL;
				else
					--  Sprites   with  priority 2 and (mode >= 2)
					if (OBJ_valid='1' and OBJ_Prio="10" and mode01='0') then
						res <= CONSTANTS.OBJECTS_SEL;
					else
						--  BG2 tiles with  priority 1
						if (BG2_valid='1' and BG2_TilePrio='1') then
							res <= CONSTANTS.BG2_SEL;
						else
							--  Sprites   with (priority 2 and (mode <  2)) || (priority 1 and mode >= 2)
							if (OBJ_valid='1' and ((OBJ_Prio="10" and mode01='1') or (OBJ_Prio="01" and mode01='0'))) then
								res <= CONSTANTS.OBJECTS_SEL;
							else
								--  BG1 tiles with  priority 0 or  (mode7)
								if (BG1_valid='1' and ((BG1_TilePrio='0') or (mode7='1'))) then
									res <= CONSTANTS.BG1_SEL;
								else
									--  Sprites   with  priority 0 and (mode >= 2)
									if (OBJ_valid='1' and OBJ_Prio="00" and mode01='0') then
										res <= CONSTANTS.OBJECTS_SEL;
									else
										--  BG2 tiles with  priority 0
										if (BG2_valid='1' and BG2_TilePrio='0') then
											res <= CONSTANTS.BG2_SEL;
										else
											--  Sprites   with  priority 1 and (mode <  2)
											if (OBJ_valid='1' and OBJ_Prio="01" and mode01='1') then
												res <= CONSTANTS.OBJECTS_SEL;
											else
												--  BG3 tiles with  priority 1 and not(bit 3 of $2105 is set and mode3)
												if (BG3_valid='1' and BG3_TilePrio='1' and specialBitMode1='0') then
													res <= CONSTANTS.BG3_SEL;
												else
													--  BG4 tiles with  priority 1
													if (BG4_valid='1' and BG4_TilePrio='1') then
														res <= CONSTANTS.BG4_SEL;
													else
														--  Sprites   with  priority 0 and (mode <  2)
														if (OBJ_valid='1' and OBJ_Prio="00" and mode01='1') then
															res <= CONSTANTS.OBJECTS_SEL;
														else
															--  BG3 tiles with  priority 0
															if (BG3_valid='1' and BG3_TilePrio='0') then
																res <= CONSTANTS.BG3_SEL;
															else
																--  BG4 tiles with  priority 0
																if (BG4_valid='1' and BG4_TilePrio='0') then
																	res <= CONSTANTS.BG4_SEL;
																else
																	res <= CONSTANTS.BACKDROP_SEL;
																end if;
															end if;
														end if;
													end if;
												end if;
											end if;
										end if;
									end if;
								end if;
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

	unitSelect <= res;
	
end PPU_PriorityUnit;
