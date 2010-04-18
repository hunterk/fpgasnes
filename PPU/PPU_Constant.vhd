--------------------------------------------------------------------------------
-- Design Name:		PPU_BRIGHTNESS.vhd
-- Module Name:		PPU_BRIGHTNESS
--
-- Description: 	Compute the RGB values post brightness processed.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package CONSTANTS is
	--
	-- Constant for register storage when reading VRAM.
	--
	constant STR_BG1_TILE	: STD_LOGIC_VECTOR := "0000";
	constant STR_BG2_TILE	: STD_LOGIC_VECTOR := "0001";
	constant STR_BG3_TILE	: STD_LOGIC_VECTOR := "0010";
	constant STR_BG4_TILE	: STD_LOGIC_VECTOR := "0011";
	constant STR_BG3V_TILE	: STD_LOGIC_VECTOR := "1100";
	constant STR_BG1_BPP01	: STD_LOGIC_VECTOR := "0100";
	constant STR_BG1_BPP23	: STD_LOGIC_VECTOR := "0101";
	constant STR_BG1_BPP45	: STD_LOGIC_VECTOR := "0110";
	constant STR_BG1_BPP67	: STD_LOGIC_VECTOR := "0111";
	constant STR_BG2_BPP01	: STD_LOGIC_VECTOR := "1000";
	constant STR_BG2_BPP23	: STD_LOGIC_VECTOR := "1001";
	constant STR_BG3_BPP01	: STD_LOGIC_VECTOR := "1010";
	constant STR_BG4_BPP01	: STD_LOGIC_VECTOR := "1011";
	constant STR_NONE		: STD_LOGIC_VECTOR := "1111";
	
	constant MODE0			: STD_LOGIC_VECTOR := "000";
	constant MODE1			: STD_LOGIC_VECTOR := "001";
	constant MODE2			: STD_LOGIC_VECTOR := "010";
	constant MODE3			: STD_LOGIC_VECTOR := "011";
	constant MODE4			: STD_LOGIC_VECTOR := "100";
	constant MODE5			: STD_LOGIC_VECTOR := "101";
	constant MODE6			: STD_LOGIC_VECTOR := "110";
	constant MODE7			: STD_LOGIC_VECTOR := "111";
	
	constant NEVER			: STD_LOGIC_VECTOR := "00";
	constant OUTSIDE		: STD_LOGIC_VECTOR := "01";
	constant INSIDE			: STD_LOGIC_VECTOR := "10";
	constant ALWAYS			: STD_LOGIC_VECTOR := "11";
		
	constant OBJECTS_SEL	: STD_LOGIC_VECTOR := "000";
	constant BG1_SEL		: STD_LOGIC_VECTOR := "001";
	constant BG2_SEL		: STD_LOGIC_VECTOR := "010";
	constant BG3_SEL		: STD_LOGIC_VECTOR := "011";
	constant BG4_SEL		: STD_LOGIC_VECTOR := "100";
	constant BACKDROP_SEL	: STD_LOGIC_VECTOR := "111";
	
	-- 24 pix shift.
	-- constant OFFSETX_TO0		: STD_LOGIC_VECTOR := x"1E6"; -- X + Offset = 0 when X = 17 (512-17)
	
	-- 16 pix shift.
	constant OFFSETX_TO0		: STD_LOGIC_VECTOR := x"1EE";
	
	constant OFFSETXMODE7_TO0	: STD_LOGIC_VECTOR := x"1FE"; -- X + Offset = 0 when X = 2
end CONSTANTS;

--package PIXFCTE is
--end PIXFCTE;
