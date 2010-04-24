library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package CONSTREG is
	constant R00_DisplayDisabled	: STD_LOGIC := '0';
	constant R00_Brigthness		: STD_LOGIC_VECTOR := "1111";

	constant R01_OAMBaseSize		: STD_LOGIC_VECTOR := "011";
	constant R01_OAMNameSelect		: STD_LOGIC_VECTOR := "11";
	constant R01_OAMNameBase		: STD_LOGIC_VECTOR := "011";

	constant R02_OAMPriority		: STD_LOGIC := '0';
	constant R02_OAMBaseAdr		: STD_LOGIC_VECTOR := "000000000";

	constant R05_BGSize			: STD_LOGIC_VECTOR := "0000";
	constant R05_BG3Priority		: STD_LOGIC := '1';
	constant R05_BGMode			: STD_LOGIC_VECTOR := "001";

	constant R06_MosaicSize		: STD_LOGIC_VECTOR := "0000";
	constant R06_BGMosaicEnable	: STD_LOGIC_VECTOR := "0100";

	constant R07_BG1AddrTileMap	: STD_LOGIC_VECTOR := "001000";
	constant R08_BG2AddrTileMap	: STD_LOGIC_VECTOR := "001100";
	constant R09_BG3AddrTileMap	: STD_LOGIC_VECTOR := "010100";
	constant R0A_BG4AddrTileMap	: STD_LOGIC_VECTOR := "000000";
	constant R0789A_BGsMapSX		: STD_LOGIC_VECTOR := "0111";
	constant R0789A_BGsMapSY		: STD_LOGIC_VECTOR := "0111";

	constant R0B_BG1PixAddr		: STD_LOGIC_VECTOR := "000";
	constant R0B_BG2PixAddr		: STD_LOGIC_VECTOR := "000";
	constant R0C_BG3PixAddr		: STD_LOGIC_VECTOR := "100";
	constant R0C_BG4PixAddr		: STD_LOGIC_VECTOR := "000";

	constant R0D_M7_HOFS			: STD_LOGIC_VECTOR := "0000000000000";
	constant R0D_BG1_HOFS			: STD_LOGIC_VECTOR := "0000000111";
	constant R0E_M7_VOFS			: STD_LOGIC_VECTOR := "0000000000000";
	constant R0E_BG1_VOFS			: STD_LOGIC_VECTOR := "0011000000";
	constant R0F_BG2_HOFS			: STD_LOGIC_VECTOR := "0000000010";
	constant R10_BG2_VOFS			: STD_LOGIC_VECTOR := "0011000000";
	constant R11_BG3_HOFS			: STD_LOGIC_VECTOR := "0000000000";
	constant R12_BG3_VOFS			: STD_LOGIC_VECTOR := "0000000000";
	constant R13_BG4_HOFS			: STD_LOGIC_VECTOR := "0000000000";
	constant R14_BG4_VOFS			: STD_LOGIC_VECTOR := "0000000000";

	constant R15_VRAM_INCMODE		: STD_LOGIC := '1';
	constant R15_VRAM_MAPPING		: STD_LOGIC_VECTOR := "00";
	constant R15_VRAM_INCREMENT	: STD_LOGIC_VECTOR := "00";

	constant R1A_M7_REPEAT			: STD_LOGIC := '0';
	constant R1A_M7_HFLIP			: STD_LOGIC := '0';
	constant R1A_M7_VFLIP			: STD_LOGIC := '0';
	constant R1A_M7_FILL			: STD_LOGIC := '0';

	constant R1B_M7A				: STD_LOGIC_VECTOR := "0000000000000000";
	constant R1C_M7B				: STD_LOGIC_VECTOR := "0000000000000000";
	constant R1D_M7C				: STD_LOGIC_VECTOR := "0000000000000000";
	constant R1E_M7D				: STD_LOGIC_VECTOR := "0000000000000000";

	constant R1F_M7CX				: STD_LOGIC_VECTOR := "0000000000000";
	constant R20_M7CY				: STD_LOGIC_VECTOR := "0000000000000";

	-- Enable and ASSIGN window to each
	constant R232425_W1_ENABLE		: STD_LOGIC_VECTOR := "000100";
	constant R232425_W2_ENABLE		: STD_LOGIC_VECTOR := "000000";
	constant R232425_W1_INV		: STD_LOGIC_VECTOR := "000000";
	constant R232425_W2_INV		: STD_LOGIC_VECTOR := "000000";

	constant R26_W1_LEFT			: STD_LOGIC_VECTOR := "00000000";
	constant R27_W1_RIGHT			: STD_LOGIC_VECTOR := "11111111";
	constant R28_W2_LEFT			: STD_LOGIC_VECTOR := "00000000";
	constant R29_W2_RIGHT			: STD_LOGIC_VECTOR := "00000000";

	constant R2AB_WMASK_LSB		: STD_LOGIC_VECTOR := "000000";
	constant R2AB_WMASK_MSB		: STD_LOGIC_VECTOR := "000000";

	constant R2C_MAIN				: STD_LOGIC_VECTOR := "00100";
	constant R2D_SUB				: STD_LOGIC_VECTOR := "10011";

	-- Enable window masking globally per BG/OBJ...
	constant R2E_WMASK_MAIN			: STD_LOGIC_VECTOR := "10100";
	constant R2F_WMASK_SUB			: STD_LOGIC_VECTOR := "00011";

	constant R30_CLIPCOLORMATH		: STD_LOGIC_VECTOR := "00";
	constant R30_PREVENTCOLORMATH	: STD_LOGIC_VECTOR := "01";
	constant R30_ADDSUBSCR			: STD_LOGIC := '1';
	constant R30_DIRECTCOLOR		: STD_LOGIC := '0';

	constant R31_COLORMATH_SUB		: STD_LOGIC := '0';
	constant R31_COLORMATH_HALF	: STD_LOGIC := '0';
	constant R31_ENABLEMATH_UNIT	: STD_LOGIC_VECTOR := "100000";

	constant R32_FIXEDCOLOR_R		: STD_LOGIC_VECTOR := "11111";
	constant R32_FIXEDCOLOR_G		: STD_LOGIC_VECTOR := "00000";
	constant R32_FIXEDCOLOR_B		: STD_LOGIC_VECTOR := "11111";

	constant R33_EXT_SYNC			: STD_LOGIC := '0';
	constant R33_M7_EXTBG			: STD_LOGIC := '0';
	constant R33_HIRES				: STD_LOGIC := '0';
	constant R33_OVERSCAN			: STD_LOGIC := '0';
	constant R33_OBJ_INTERLACE		: STD_LOGIC := '0';
	constant R33_SCR_INTERLACE		: STD_LOGIC := '0';
end CONSTREG;
