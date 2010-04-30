----------------------------------------------------------------------------------
-- Create Date:   	
-- Design Name:		PPU_System.vhd
-- Module Name:		PPU_System
--
-- TODO : Mode7, HiRes, Interlace, Per Tile offset Valid, Sprites, Mosaic unit to complete.
-- TODO : CGRAM, VRAM, OAMRAM write/read from register unit also.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_System is
    Port (
		clock				: in STD_LOGIC;
		reset				: in STD_LOGIC;
		
		X					: in STD_LOGIC_VECTOR(8 downto 0);
		Y					: in STD_LOGIC_VECTOR(8 downto 0);
		
		-- ##############################################################
		--   CPU Side.
		-- ##############################################################
		Address 			: in STD_LOGIC_VECTOR(5 downto 0);
		CPUwrite			: in STD_LOGIC;
		DataIn	  			: in  STD_LOGIC_VECTOR(7 downto 0);
		DataOut	  			: out STD_LOGIC_VECTOR(7 downto 0);

		-- ##############################################################
		--   Video output Side.
		-- ##############################################################
		Red					: out STD_LOGIC_VECTOR(4 downto 0);
		Green				: out STD_LOGIC_VECTOR(4 downto 0);
		Blue				: out STD_LOGIC_VECTOR(4 downto 0)
	);
end PPU_System;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture ArchiPPU_System of PPU_System is
	--
	-- Mosaic Unit.
	--
	component PPU_MosaicCompute is
	Port (
		clock				: in STD_LOGIC;
		X					: in STD_LOGIC_VECTOR(8 downto 0);
		Y					: in STD_LOGIC_VECTOR(8 downto 0);
		R2106_MosaicSize	: in STD_LOGIC_VECTOR(3 downto 0);
		R2106_Reset			: in STD_LOGIC;
		
		XMosaicSig			: out STD_LOGIC;
		XNormal				: out STD_LOGIC_VECTOR(8 downto 0);
		YNormal				: out STD_LOGIC_VECTOR(8 downto 0);
		YMosaic				: out STD_LOGIC_VECTOR(8 downto 0)
	);
	end component;
	
	--
	-- Register Block.
	--
	component PPU_Registers is
    Port (
		clock				: in STD_LOGIC;
		reset				: in STD_LOGIC;
	
		-- ##############################################################
		-- CPU Side.
		-- ##############################################################
		Address 			: in STD_LOGIC_VECTOR(5 downto 0);
		CPUwrite			: in STD_LOGIC;
		DataIn	  			: in  STD_LOGIC_VECTOR(7 downto 0);
		DataOut	  			: out STD_LOGIC_VECTOR(7 downto 0);

		-- ##############################################################
		-- Module VRAM Read / Write Side
		-- ##############################################################
		VRAMAddress_PostTranslation : out STD_LOGIC_VECTOR(14 downto 0);
		VRAMDataIn	 		: in  STD_LOGIC_VECTOR(15 downto 0);
		VRAMDataOut	  		: out STD_LOGIC_VECTOR(7 downto 0);
		
		-- Need both to allow arbitration with other blocks using VRAM.
		VRAMwrite			: out STD_LOGIC;
		VRAMread			: out STD_LOGIC;
		VRAMlowHigh			: out STD_LOGIC;
		
		-- ##############################################################
		-- Module CGRAM Read / Write Side
		-- ##############################################################
		CGRAMAddress		: out STD_LOGIC_VECTOR(7 downto 0);
		CGRAMDataIn			: in  STD_LOGIC_VECTOR(14 downto 0);
		CGRAMDataOut		: out STD_LOGIC_VECTOR(14 downto 0);
		-- Need both to allow arbitration with other blocks using Palette
		CGRAMwrite			: out STD_LOGIC;
		
		-- ##############################################################
		--   PPU Register exposed to rendering logic blocks + internal Logic
		-- ##############################################################
		
		R2100_DisplayDisabled	: out STD_LOGIC;
		R2100_Brigthness		: out STD_LOGIC_VECTOR (3 downto 0);
		
		R2101_OAMBaseSize		: out STD_LOGIC_VECTOR (2 downto 0); 
		R2101_OAMNameSelect		: out STD_LOGIC_VECTOR (1 downto 0);
		R2101_OAMNameBase		: out STD_LOGIC_VECTOR (2 downto 0);
		-- BSnes has cache version.

		R2102_OAMPriority		: out STD_LOGIC;
		R2102_OAMBaseAdr		: out STD_LOGIC_VECTOR (8 downto 0);
		-- TODO : FirstSprite
		
		R2105_BGSize			: out STD_LOGIC_VECTOR (3 downto 0);
		R2105_BG3Priority		: out STD_LOGIC;
		R2105_BGMode			: out STD_LOGIC_VECTOR (2 downto 0);

		R2106_MosaicSize		: out STD_LOGIC_VECTOR (3 downto 0);
		R2106_BGMosaicEnable	: out STD_LOGIC_VECTOR (3 downto 0);
		
		R2107_BG1AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
		R2108_BG2AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
		R2109_BG3AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
		R210A_BG4AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
		R210789A_BGsMapSX		: out STD_LOGIC_VECTOR (3 downto 0);
		R210789A_BGsMapSY		: out STD_LOGIC_VECTOR (3 downto 0);
		
		R210B_BG1PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);
		R210B_BG2PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);
		R210C_BG3PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);
		R210C_BG4PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);

		R210D_M7_HOFS			: out STD_LOGIC_VECTOR(12 downto 0);
		R210D_BG1_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
		R210E_M7_VOFS			: out STD_LOGIC_VECTOR(12 downto 0);
		R210E_BG1_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);
		R210F_BG2_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
		R2110_BG2_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);
		R2111_BG3_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
		R2112_BG3_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);
		R2113_BG4_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
		R2114_BG4_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);

		-- Internal R2115_VRAM_INCMODE		: out STD_LOGIC;				
		-- Internal R2115_VRAM_INCREMENT	: out STD_LOGIC_VECTOR (1 downto 0);
		
		-- 2116,2117,2118,2119 => VRAM adress / write.
		
		R211A_M7_REPEAT			: out STD_LOGIC;
		R211A_M7_HFLIP			: out STD_LOGIC;
		R211A_M7_VFLIP			: out STD_LOGIC;
		R211A_M7_FILL			: out STD_LOGIC;
		
		R211B_M7A				: out STD_LOGIC_VECTOR(15 downto 0);
		R211C_M7B				: out STD_LOGIC_VECTOR(15 downto 0);
		R211D_M7C				: out STD_LOGIC_VECTOR(15 downto 0);
		R211E_M7D				: out STD_LOGIC_VECTOR(15 downto 0);
		
		R211F_M7CX				: out STD_LOGIC_VECTOR(12 downto 0);
		R2120_M7CY				: out STD_LOGIC_VECTOR(12 downto 0);
		
		-- 2121,2122 => CGRAM address / write.
		
		-- Note : top 5,4 -> OBJ/COL, 0..3 -> BG NUM by convention.
		R21232425_W1_ENABLE		: out STD_LOGIC_VECTOR (5 downto 0);
		R21232425_W2_ENABLE		: out STD_LOGIC_VECTOR (5 downto 0);
		R21232425_W1_INV		: out STD_LOGIC_VECTOR (5 downto 0);
		R21232425_W2_INV		: out STD_LOGIC_VECTOR (5 downto 0);
		
		R2126_W1_LEFT			: out STD_LOGIC_VECTOR (7 downto 0);
		R2127_W1_RIGHT			: out STD_LOGIC_VECTOR (7 downto 0);
		R2128_W2_LEFT			: out STD_LOGIC_VECTOR (7 downto 0);
		R2129_W2_RIGHT			: out STD_LOGIC_VECTOR (7 downto 0);
		
		R212AB_WMASK_LSB		: out STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
		R212AB_WMASK_MSB		: out STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
		
		R212C_MAIN				: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
		R212D_SUB				: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
		
		R212E_WMASK_MAIN		: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
		R212F_WMASK_SUB			: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj

		R2130_CLIPCOLORMATH		: out STD_LOGIC_VECTOR (1 downto 0);
		R2130_PREVENTCOLORMATH	: out STD_LOGIC_VECTOR (1 downto 0);
		R2130_ADDSUBSCR			: out STD_LOGIC;
		R2130_DIRECTCOLOR		: out STD_LOGIC;

		R2131_COLORMATH_SUB		: out STD_LOGIC;
		R2131_COLORMATH_HALF	: out STD_LOGIC;
		R2131_ENABLEMATH_UNIT	: out STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Backdrop

		R2132_FIXEDCOLOR_R		: out STD_LOGIC_VECTOR (4 downto 0);
		R2132_FIXEDCOLOR_G		: out STD_LOGIC_VECTOR (4 downto 0);
		R2132_FIXEDCOLOR_B		: out STD_LOGIC_VECTOR (4 downto 0);
		
		R2133_EXT_SYNC			: out STD_LOGIC;
		R2133_M7_EXTBG			: out STD_LOGIC;
		R2133_HIRES				: out STD_LOGIC;
		R2133_OVERSCAN			: out STD_LOGIC;
		R2133_OBJ_INTERLACE		: out STD_LOGIC;
		R2133_SCR_INTERLACE		: out STD_LOGIC
	);
	end component;
	
	component PPU_Mode7Manager is
	Port (
		clock         		: in STD_LOGIC;
		
		lineStart			: in STD_LOGIC;
		X_NonMosaic			: in STD_LOGIC_VECTOR(7 downto 0);
		YMosaic				: in STD_LOGIC_VECTOR(7 downto 0);
		
		R210D_M7_HOFS		: in STD_LOGIC_VECTOR(12 downto 0);
		R210E_M7_VOFS		: in STD_LOGIC_VECTOR(12 downto 0);

		R211A_M7_HFLIP		: in STD_LOGIC;
		R211A_M7_VFLIP		: in STD_LOGIC;
		
		R211B_M7A			: in STD_LOGIC_VECTOR(15 downto 0);
		R211C_M7B			: in STD_LOGIC_VECTOR(15 downto 0);
		R211D_M7C			: in STD_LOGIC_VECTOR(15 downto 0);
		R211E_M7D			: in STD_LOGIC_VECTOR(15 downto 0);
		
		R211F_M7CX			: in STD_LOGIC_VECTOR(12 downto 0);
		R2120_M7CY			: in STD_LOGIC_VECTOR(12 downto 0);
		
		Mode7XOut			: out STD_LOGIC_VECTOR(20 downto 0);
		Mode7YOut			: out STD_LOGIC_VECTOR(20 downto 0)
	);
	end component;
				
	--
	-- VRAM Block
	--
	component PPU_VRAMsync_ram is
	Port (
		clock         : in  STD_LOGIC;
		
		-- Port 1 Read (8 Bit) / Write (16 Bit)
		writeE        : in  STD_LOGIC;
		writeImpair	  : in  STD_LOGIC;
		AddressPair   : in  STD_LOGIC_VECTOR(14 downto 0);
		
		-- Port 2 Read (8 Bit)
		AddressImpair : in  STD_LOGIC_VECTOR(14 downto 0);
		
		-- Write Mode
		datain		  : in  STD_LOGIC_VECTOR( 7 downto 0);
		
		-- Read Mode
		dataoutPair	  : out STD_LOGIC_VECTOR( 7 downto 0);
		dataoutImpair : out STD_LOGIC_VECTOR( 7 downto 0)
	);
	end component;
	
	--
	-- CGRAM Block.
	--
	component PPU_CGRAM is
	Port (
		clock			: in  STD_LOGIC;
		-- Register side.
		writeE			: in  STD_LOGIC;
		-- Read / Write Port A
		CGAddrWR		: in  STD_LOGIC_VECTOR( 7 downto 0);
		-- Read Port B
		CGAddrR 		: in  STD_LOGIC_VECTOR( 7 downto 0);
		
		-- Data when doing WRITE.
		wordIn	 		: in  STD_LOGIC_VECTOR(14 downto 0);
		
		-- Data Read Port A
		wordOutWR 		: out STD_LOGIC_VECTOR(14 downto 0);
		-- Data Read Port B
		wordOutR		: out STD_LOGIC_VECTOR(14 downto 0)
	);
	end component;
	
	--
	-- Line Cache Unit.
	--
	component PPU_LineCache is
	Port (
		clock				: in STD_LOGIC;
		
		Write				: in STD_LOGIC;
		
		AdrWrite			: in STD_LOGIC_VECTOR(7 downto 0);
		DataWrite			: in STD_LOGIC_VECTOR(27 downto 0);

		AdrRead				: in STD_LOGIC_VECTOR(7 downto 0);
		DataRead			: out STD_LOGIC_VECTOR(27 downto 0)
	);
	end component;
				
	--
	-- Fetch Block.
	--
	component PPU_PixelFetch is
    Port (
		clock					: in  STD_LOGIC;
		startLine				: in  STD_LOGIC;

		ScreenY_PostMosaic		: in STD_LOGIC_VECTOR (8 downto 0);
		ScreenX_NonMosaic		: in STD_LOGIC_VECTOR (8 downto 0);
		ScreenY_NonMosaic		: in STD_LOGIC_VECTOR (8 downto 0);
		MosaicXSig				: in STD_LOGIC;
		
		Mode7X					: in STD_LOGIC_VECTOR (20 downto 0);
		Mode7Y					: in STD_LOGIC_VECTOR (20 downto 0);
		
		R211A_M7_REPEAT			: in STD_LOGIC;
		R211A_M7_FILL			: in STD_LOGIC;
		
		R2105_BGSize			: in STD_LOGIC_VECTOR (3 downto 0);
		R2106_BGMosaicEnable	: in STD_LOGIC_VECTOR (3 downto 0);
		
		R2107_BG1AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);
		R2108_BG2AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);
		R2109_BG3AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);
		R210A_BG4AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);
		
		R210B_BG1PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		R210B_BG2PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		R210C_BG3PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		R210C_BG4PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		
		R2105_BGMode			: in STD_LOGIC_VECTOR (2 downto 0);
		R2133_HIRES				: in STD_LOGIC;
		
		R210D_BG1_HOFS			: in STD_LOGIC_VECTOR (9 downto 0);
		R210E_BG1_VOFS			: in STD_LOGIC_VECTOR (9 downto 0);

		R210F_BG2_HOFS			: in STD_LOGIC_VECTOR (9 downto 0);
		R2110_BG2_VOFS			: in STD_LOGIC_VECTOR (9 downto 0);

		R2111_BG3_HOFS			: in STD_LOGIC_VECTOR (9 downto 0);
		R2112_BG3_VOFS			: in STD_LOGIC_VECTOR (9 downto 0);

		R2113_BG4_HOFS			: in STD_LOGIC_VECTOR (9 downto 0);
		R2114_BG4_VOFS			: in STD_LOGIC_VECTOR (9 downto 0);
		
		R210789A_BGsMapSX		: in STD_LOGIC_VECTOR (3 downto 0);
		R210789A_BGsMapSY		: in STD_LOGIC_VECTOR (3 downto 0);
	
		--
		-- Memory is divided into 8 byte width RAM chip.
		-- Mode7 need to access those chip seperatly.
		--
		VRAMAddressPair			: out STD_LOGIC_VECTOR(14 downto 0);	-- 64K word
		VRAMAddressImpair		: out STD_LOGIC_VECTOR(14 downto 0);	-- 64K word
		VRAMRead				: out STD_LOGIC;
		VRAMDataPair			: in  STD_LOGIC_VECTOR( 7 downto 0); 
		VRAMDataImpair			: in  STD_LOGIC_VECTOR( 7 downto 0);
		
		--
		-- Line Memory
		--
		LineCacheAddress		: out STD_LOGIC_VECTOR (7 downto 0);	-- Again 256 pixel only --> HiRes should fit.
		LineCacheData			: out STD_LOGIC_VECTOR(27 downto 0);
		WriteS					: out STD_LOGIC
	);
	end component;

	--
	-- Lower block.
	--
	component PPU_Chipset_Low is
    Port (
		--
		-- General Side.
		--
		clock				: in STD_LOGIC;
		reset				: in STD_LOGIC;
		drawPixel			: in STD_LOGIC;

		xCoord				: in STD_LOGIC_VECTOR(7 downto 0);
		
		--
		-- Memory Line Cache Side.
		--
		Address 			: out STD_LOGIC_VECTOR(7 downto 0);
		DataPixels 			: in  STD_LOGIC_VECTOR(27 downto 0);

		--
		-- Palette reading.
		--
		MainIndex			: out STD_LOGIC_VECTOR(7 downto 0);
		MainColor			: in  STD_LOGIC_VECTOR(14 downto 0);

		SubIndex			: out STD_LOGIC_VECTOR(7 downto 0);
		SubColor			: in  STD_LOGIC_VECTOR(14 downto 0);
		
		--
		-- Register Side.
		--
				
		R2100_DisplayDisabled	: in STD_LOGIC;
		R2100_Brigthness		: in STD_LOGIC_VECTOR (3 downto 0);

		R2105_BGMode			: in STD_LOGIC_VECTOR (2 downto 0);
		R2105_BG3Priority		: in STD_LOGIC;

		-- Note : top 5,4 -> OBJ/COL, 0..3 -> BG NUM by convention.
		R21232425_W1_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0);
		R21232425_W2_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0);
		R21232425_W1_INV		: in STD_LOGIC_VECTOR (5 downto 0);
		R21232425_W2_INV		: in STD_LOGIC_VECTOR (5 downto 0);
		
		R2126_W1_LEFT			: in STD_LOGIC_VECTOR (7 downto 0);
		R2127_W1_RIGHT			: in STD_LOGIC_VECTOR (7 downto 0);
		R2128_W2_LEFT			: in STD_LOGIC_VECTOR (7 downto 0);
		R2129_W2_RIGHT			: in STD_LOGIC_VECTOR (7 downto 0);
		
		R212AB_WMASK_LSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
		R212AB_WMASK_MSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
		
		R212C_MAIN				: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
		R212D_SUB				: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
		
		R212E_WMASK_MAIN		: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
		R212F_WMASK_SUB			: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj

		R2130_CLIPCOLORMATH		: in STD_LOGIC_VECTOR (1 downto 0);
		R2130_PREVENTCOLORMATH	: in STD_LOGIC_VECTOR (1 downto 0);
		R2130_ADDSUBSCR			: in STD_LOGIC;
		R2130_DIRECTCOLOR		: in STD_LOGIC;

		R2131_COLORMATH_SUB		: in STD_LOGIC;
		R2131_COLORMATH_HALF	: in STD_LOGIC;
		R2131_ENABLEMATH_UNIT	: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Backdrop

		R2132_FIXEDCOLOR_R		: in STD_LOGIC_VECTOR (4 downto 0);
		R2132_FIXEDCOLOR_G		: in STD_LOGIC_VECTOR (4 downto 0);
		R2132_FIXEDCOLOR_B		: in STD_LOGIC_VECTOR (4 downto 0);
						
		R2133_M7_EXTBG			: in  STD_LOGIC;

		--
		-- Video Side
		--
		Red						: out STD_LOGIC_VECTOR(4 downto 0);
		Green					: out STD_LOGIC_VECTOR(4 downto 0);
		Blue					: out STD_LOGIC_VECTOR(4 downto 0)
	);
	end component;
	
	-- todo CGRAM signal
	-- todo Line Cache signal
	-- todo VRAM signal
	signal drawPixel : STD_LOGIC;
	signal visibleX,visibleY : STD_LOGIC;
	signal startline : STD_LOGIC;
	
	signal XMosaicSig,writeCGRAMSig		: STD_LOGIC;
	signal readWriteAdrCGRAM, readOnlyAdrCGRAM	: STD_LOGIC_VECTOR(7 downto 0);
	
	signal writeDataCGRAM, readDataCGRAM,
			readOnlyDataCGRAM : STD_LOGIC_VECTOR(14 downto 0);
	
	signal VRAMWrite	: STD_LOGIC;
	signal VRAMPairAddress, VRAMImpairAddress : STD_LOGIC_VECTOR(14 downto 0);
	
	-- Write Mode
	signal VRAMDataWrite : STD_LOGIC_VECTOR(7 downto 0);
	signal VRAMDataPair, VRAMDataImpair : STD_LOGIC_VECTOR(7 downto 0);
	
	-- chipset low
	signal sLineCacheReadAdr			: STD_LOGIC_VECTOR(7 downto 0);
	signal sLineCacheRead				: STD_LOGIC;
	signal sLineCacheReadData			: STD_LOGIC_VECTOR(27 downto 0);

	signal sPaletteMainReadAdr			: STD_LOGIC_VECTOR( 7 downto 0);
	signal sPaletteMainReadData			: STD_LOGIC_VECTOR(14 downto 0);

	signal sPaletteSubReadAdr			: STD_LOGIC_VECTOR( 7 downto 0);
	signal sPaletteSubReadData			: STD_LOGIC_VECTOR(14 downto 0);

	-- fetch
	signal YMosaic						: STD_LOGIC_VECTOR(8 downto 0);
	signal sVRAMReadAdrPairFromFetch	: STD_LOGIC_VECTOR(14 downto 0);
	signal sVRAMReadAdrImpairFromFetch	: STD_LOGIC_VECTOR(14 downto 0);
	signal sVRAMReadSigFromFetch		: STD_LOGIC;
	signal sVRAMReadDataPairToFetch		: STD_LOGIC_VECTOR(7 downto 0);
	signal sVRAMReadDataImpairToFetch	: STD_LOGIC_VECTOR(7 downto 0);
    
	signal sLineCacheWriteAdr			: STD_LOGIC_VECTOR(7 downto 0);
	signal sLineCacheWriteData			: STD_LOGIC_VECTOR(27 downto 0);
	signal sLineCacheWrite				: STD_LOGIC;

	-- registers.
	signal sVRAMAdrFromRegisters		: STD_LOGIC_VECTOR(14 downto 0);
	signal sVRAMDataToRegisters			: STD_LOGIC_VECTOR(15 downto 0);
	signal sVRAMDataFromRegisters		: STD_LOGIC_VECTOR( 7 downto 0);
	signal sVRAMWriteFromRegisters			: STD_LOGIC;
	signal sVRAMReadFromRegisters			: STD_LOGIC;
	signal sVRAMWriteLowHightFromRegisters	: STD_LOGIC;
	signal VRAMWriteImpair					: STD_LOGIC;
	
	signal sCGRAMAdressReadWriteFromRegisters	: STD_LOGIC_VECTOR(7 downto 0);
	signal sCGRAMDataReadToRegisters	: STD_LOGIC_VECTOR(14 downto 0);
	signal sCGRAMDataWriteFromRegisters	: STD_LOGIC_VECTOR(14 downto 0);
	signal sCGRAMWriteSigFromRegisters	: STD_LOGIC;
		
	signal R2100_DisplayDisabled		: STD_LOGIC;
	signal R2100_Brigthness				: STD_LOGIC_VECTOR (3 downto 0);
		                                
	signal todoR2101_OAMBaseSize			: STD_LOGIC_VECTOR (2 downto 0);
	signal todoR2101_OAMNameSelect			: STD_LOGIC_VECTOR (1 downto 0);
	signal todoR2101_OAMNameBase			: STD_LOGIC_VECTOR (2 downto 0);
                                        
	                                    
	signal todoR2102_OAMPriority			: STD_LOGIC;
	signal todoR2102_OAMBaseAdr			: STD_LOGIC_VECTOR (8 downto 0);
		                                
		                                
	signal R2105_BGSize					: STD_LOGIC_VECTOR (3 downto 0);
	signal R2105_BG3Priority			: STD_LOGIC;
	signal R2105_BGMode					: STD_LOGIC_VECTOR (2 downto 0);
                                        
	signal R2106_MosaicSize				: STD_LOGIC_VECTOR (3 downto 0);
	signal R2106_BGMosaicEnable			: STD_LOGIC_VECTOR (3 downto 0);
	signal R2106_Reset					: STD_LOGIC;
		                                
	signal R2107_BG1AddrTileMap			: STD_LOGIC_VECTOR (5 downto 0);
	signal R2108_BG2AddrTileMap			: STD_LOGIC_VECTOR (5 downto 0);
	signal R2109_BG3AddrTileMap			: STD_LOGIC_VECTOR (5 downto 0);
	signal R210A_BG4AddrTileMap			: STD_LOGIC_VECTOR (5 downto 0);
	signal R210789A_BGsMapSX			: STD_LOGIC_VECTOR (3 downto 0);
	signal R210789A_BGsMapSY			: STD_LOGIC_VECTOR (3 downto 0);
		                                
	signal R210B_BG1PixAddr				: STD_LOGIC_VECTOR (2 downto 0);
	signal R210B_BG2PixAddr				: STD_LOGIC_VECTOR (2 downto 0);
	signal R210C_BG3PixAddr				: STD_LOGIC_VECTOR (2 downto 0);
	signal R210C_BG4PixAddr				: STD_LOGIC_VECTOR (2 downto 0);
                                        
	signal R210D_M7_HOFS				: STD_LOGIC_VECTOR(12 downto 0);
	signal R210D_BG1_HOFS				: STD_LOGIC_VECTOR (9 downto 0);
	signal R210E_M7_VOFS				: STD_LOGIC_VECTOR(12 downto 0);
	signal R210E_BG1_VOFS				: STD_LOGIC_VECTOR (9 downto 0);
	signal R210F_BG2_HOFS				: STD_LOGIC_VECTOR (9 downto 0);
	signal R2110_BG2_VOFS				: STD_LOGIC_VECTOR (9 downto 0);
	signal R2111_BG3_HOFS				: STD_LOGIC_VECTOR (9 downto 0);
	signal R2112_BG3_VOFS				: STD_LOGIC_VECTOR (9 downto 0);
	signal R2113_BG4_HOFS				: STD_LOGIC_VECTOR (9 downto 0);
	signal R2114_BG4_VOFS				: STD_LOGIC_VECTOR (9 downto 0);
                                      
	signal R211A_M7_REPEAT				: STD_LOGIC;
	signal R211A_M7_HFLIP				: STD_LOGIC;
	signal R211A_M7_VFLIP				: STD_LOGIC;
	signal R211A_M7_FILL				: STD_LOGIC;
		
	signal R211B_M7A					: STD_LOGIC_VECTOR(15 downto 0);
	signal R211C_M7B					: STD_LOGIC_VECTOR(15 downto 0);
	signal R211D_M7C					: STD_LOGIC_VECTOR(15 downto 0);
	signal R211E_M7D					: STD_LOGIC_VECTOR(15 downto 0);
	                                    
	signal R211F_M7CX					: STD_LOGIC_VECTOR(12 downto 0);
	signal R2120_M7CY					: STD_LOGIC_VECTOR(12 downto 0);
		                              
	signal R21232425_W1_ENABLE			: STD_LOGIC_VECTOR (5 downto 0);
	signal R21232425_W2_ENABLE          : STD_LOGIC_VECTOR (5 downto 0);
	signal R21232425_W1_INV             : STD_LOGIC_VECTOR (5 downto 0);
	signal R21232425_W2_INV             : STD_LOGIC_VECTOR (5 downto 0);
		                                
	signal R2126_W1_LEFT                : STD_LOGIC_VECTOR (7 downto 0);
	signal R2127_W1_RIGHT               : STD_LOGIC_VECTOR (7 downto 0);
	signal R2128_W2_LEFT                : STD_LOGIC_VECTOR (7 downto 0);
	signal R2129_W2_RIGHT               : STD_LOGIC_VECTOR (7 downto 0);
		                                
	signal R212AB_WMASK_LSB             : STD_LOGIC_VECTOR (5 downto 0);
	signal R212AB_WMASK_MSB             : STD_LOGIC_VECTOR (5 downto 0);
                                        
	signal R212C_MAIN                   : STD_LOGIC_VECTOR (4 downto 0);
	signal R212D_SUB                    : STD_LOGIC_VECTOR (4 downto 0);
		                                
	signal R212E_WMASK_MAIN             : STD_LOGIC_VECTOR (4 downto 0);
	signal R212F_WMASK_SUB              : STD_LOGIC_VECTOR (4 downto 0);
                                        
	signal R2130_CLIPCOLORMATH          : STD_LOGIC_VECTOR (1 downto 0);
	signal R2130_PREVENTCOLORMATH       : STD_LOGIC_VECTOR (1 downto 0);
	signal R2130_ADDSUBSCR              : STD_LOGIC;
	signal R2130_DIRECTCOLOR            : STD_LOGIC;
                                        
	signal R2131_COLORMATH_SUB          : STD_LOGIC;
	signal R2131_COLORMATH_HALF         : STD_LOGIC;
	signal R2131_ENABLEMATH_UNIT        : STD_LOGIC_VECTOR (5 downto 0);
                                        
	signal R2132_FIXEDCOLOR_R           : STD_LOGIC_VECTOR (4 downto 0);
	signal R2132_FIXEDCOLOR_G           : STD_LOGIC_VECTOR (4 downto 0);
	signal R2132_FIXEDCOLOR_B           : STD_LOGIC_VECTOR (4 downto 0);
		                              
	signal todoR2133_EXT_SYNC			: STD_LOGIC;
	signal R2133_M7_EXTBG				: STD_LOGIC;
	signal R2133_HIRES					: STD_LOGIC;
	signal R2133_OVERSCAN				: STD_LOGIC;
	signal todoR2133_OBJ_INTERLACE		: STD_LOGIC;
	signal todoR2133_SCR_INTERLACE		: STD_LOGIC;

	signal sMode7x,sMode7y				: STD_LOGIC_VECTOR(20 downto 0);
	signal NormalX, NormalY				: STD_LOGIC_VECTOR(8 downto 0);
begin
	
	--
	-- CPU Side / Register setup.
	--
	instanceRegisters : PPU_Registers port map
	(
		clock		=> clock,
		reset		=> reset,
		
		-- ##############################################################
		-- CPU Side.
		-- ##############################################################
		Address 	=> Address,
		CPUwrite	=> CPUWrite,
		DataIn		=> DataIn,
		DataOut		=> DataOut,

		-- ##############################################################
		-- Module VRAM Read / Write Side
		-- ##############################################################
		VRAMAddress_PostTranslation
					=> sVRAMAdrFromRegisters,
		VRAMDataIn	
					=> sVRAMDataToRegisters,
		VRAMDataOut	
					=> sVRAMDataFromRegisters,
		-- Need both to allow arbitration with other blocks using VRAM.
		VRAMwrite	=> sVRAMWriteFromRegisters,
		VRAMread	=> sVRAMReadFromRegisters,
		VRAMlowHigh	=> sVRAMWriteLowHightFromRegisters,
		
		-- ##############################################################
		-- Module CGRAM Read / Write Side
		-- ##############################################################
		CGRAMAddress	=> sCGRAMAdressReadWriteFromRegisters,
		CGRAMDataIn		=> sCGRAMDataReadToRegisters,
		CGRAMDataOut	=> sCGRAMDataWriteFromRegisters,
		CGRAMWrite		=> sCGRAMWriteSigFromRegisters,
		
		-- ##############################################################
		--   PPU Register exposed to rendering logic blocks + internal Logic
		-- ##############################################################		
		R2100_DisplayDisabled	=> R2100_DisplayDisabled,
		R2100_Brigthness		=> R2100_Brigthness,
		
		R2101_OAMBaseSize		=> todoR2101_OAMBaseSize,
		R2101_OAMNameSelect		=> todoR2101_OAMNameSelect,
		R2101_OAMNameBase		=> todoR2101_OAMNameBase,

		R2102_OAMPriority		=> todoR2102_OAMPriority,
		R2102_OAMBaseAdr		=> todoR2102_OAMBaseAdr,
		-- TODO : FirstSprite
		
		R2105_BGSize			=> R2105_BGSize,
		R2105_BG3Priority		=> R2105_BG3Priority,
		R2105_BGMode			=> R2105_BGMode,
                                   
		R2106_MosaicSize		=> R2106_MosaicSize,
		R2106_BGMosaicEnable	=> R2106_BGMosaicEnable,
		                           
		R2107_BG1AddrTileMap	=> R2107_BG1AddrTileMap,
		R2108_BG2AddrTileMap	=> R2108_BG2AddrTileMap,
		R2109_BG3AddrTileMap	=> R2109_BG3AddrTileMap,
		R210A_BG4AddrTileMap	=> R210A_BG4AddrTileMap,
		R210789A_BGsMapSX		=> R210789A_BGsMapSX,
		R210789A_BGsMapSY		=> R210789A_BGsMapSY,
		                           
		R210B_BG1PixAddr		=> R210B_BG1PixAddr,
		R210B_BG2PixAddr		=> R210B_BG2PixAddr,
		R210C_BG3PixAddr		=> R210C_BG3PixAddr,
		R210C_BG4PixAddr		=> R210C_BG4PixAddr,
                                   
		R210D_M7_HOFS			=> R210D_M7_HOFS,
		R210D_BG1_HOFS			=> R210D_BG1_HOFS,
		R210E_M7_VOFS			=> R210E_M7_VOFS,
		R210E_BG1_VOFS			=> R210E_BG1_VOFS,
		R210F_BG2_HOFS			=> R210F_BG2_HOFS,
		R2110_BG2_VOFS			=> R2110_BG2_VOFS,
		R2111_BG3_HOFS			=> R2111_BG3_HOFS,
		R2112_BG3_VOFS			=> R2112_BG3_VOFS,
		R2113_BG4_HOFS			=> R2113_BG4_HOFS,
		R2114_BG4_VOFS			=> R2114_BG4_VOFS,
                                
		R211A_M7_REPEAT			=> R211A_M7_REPEAT,
		R211A_M7_HFLIP			=> R211A_M7_HFLIP,
		R211A_M7_VFLIP			=> R211A_M7_VFLIP,
		R211A_M7_FILL			=> R211A_M7_FILL,
		                           
		R211B_M7A				=> R211B_M7A,
		R211C_M7B				=> R211C_M7B,
		R211D_M7C				=> R211D_M7C,
		R211E_M7D				=> R211E_M7D,
		                           
		R211F_M7CX				=> R211F_M7CX,
		R2120_M7CY				=> R2120_M7CY,
		                           
		R21232425_W1_ENABLE		=> R21232425_W1_ENABLE,
		R21232425_W2_ENABLE		=> R21232425_W2_ENABLE,
		R21232425_W1_INV		=> R21232425_W1_INV,
		R21232425_W2_INV		=> R21232425_W2_INV,
		                           
		R2126_W1_LEFT			=> R2126_W1_LEFT,
		R2127_W1_RIGHT			=> R2127_W1_RIGHT,
		R2128_W2_LEFT			=> R2128_W2_LEFT,
		R2129_W2_RIGHT			=> R2129_W2_RIGHT,
		                           
		R212AB_WMASK_LSB		=> R212AB_WMASK_LSB, -- 4 : Obj, 5 : Col
		R212AB_WMASK_MSB		=> R212AB_WMASK_MSB, -- 4 : Obj, 5 : Col

		R212C_MAIN				=> R212C_MAIN, -- 4 : Obj
		R212D_SUB				=> R212D_SUB, -- 4 : Obj
		                           
		R212E_WMASK_MAIN		=> R212E_WMASK_MAIN, -- 4 : Obj
		R212F_WMASK_SUB			=> R212F_WMASK_SUB, -- 4 : Obj
                                   
		R2130_CLIPCOLORMATH		=> R2130_CLIPCOLORMATH,
		R2130_PREVENTCOLORMATH	=> R2130_PREVENTCOLORMATH,
		R2130_ADDSUBSCR			=> R2130_ADDSUBSCR,
		R2130_DIRECTCOLOR		=> R2130_DIRECTCOLOR,
                                   
		R2131_COLORMATH_SUB		=> R2131_COLORMATH_SUB,
		R2131_COLORMATH_HALF	=> R2131_COLORMATH_HALF,
		R2131_ENABLEMATH_UNIT	=> R2131_ENABLEMATH_UNIT, -- 4 : Obj, 5 : Backdrop
                                   
		R2132_FIXEDCOLOR_R		=> R2132_FIXEDCOLOR_R,
		R2132_FIXEDCOLOR_G		=> R2132_FIXEDCOLOR_G,
		R2132_FIXEDCOLOR_B		=> R2132_FIXEDCOLOR_B,
		                           
		R2133_EXT_SYNC			=> todoR2133_EXT_SYNC,
		R2133_M7_EXTBG			=> R2133_M7_EXTBG,
		R2133_HIRES				=> R2133_HIRES,
		R2133_OVERSCAN			=> R2133_OVERSCAN,
		R2133_OBJ_INTERLACE		=> todoR2133_OBJ_INTERLACE,
		R2133_SCR_INTERLACE		=> todoR2133_SCR_INTERLACE 
	);

	--
	-- Internal Mosaic Management.
	--
	instanceMosaic : PPU_MosaicCompute port map
	(
		clock					=> clock,
		X						=> X,
		Y						=> Y,
		
		R2106_MosaicSize		=> R2106_MosaicSize,
		R2106_Reset				=> R2106_Reset,
		XMosaicSig				=> XMosaicSig,
		XNormal					=> NormalX,
		YNormal					=> NormalY,
		YMosaic					=> YMosaic
	);
	
	instanceCGRAM : PPU_CGRAM port map
	(
		clock					=> clock,
		
		-- Register side.
		writeE					=> writeCGRAMSig,
		-- Read / Write Port A
		CGAddrWR				=> readWriteAdrCGRAM,
		CGAddrR 				=> readOnlyAdrCGRAM,
		-- Data when doing WRITE.
		wordIn	 				=> writeDataCGRAM,
		-- Data Read Port A
		wordOutWR 				=> readDataCGRAM,
		-- Data Read Port B
		wordOutR				=> readOnlyDataCGRAM
	);
	
	instanceVRAM : PPU_VRAMsync_ram port map
	(
		clock					=> clock,
		
		-- Port 1 Read (8 Bit) / Write (8 Bit)
		writeE					=> VRAMWrite,
		writeImpair				=> VRAMWriteImpair,
		AddressPair				=> VRAMPairAddress,
		
		-- Port 2 Read (8 Bit)
		AddressImpair			=> VRAMImpairAddress,
		
		-- Write Mode
		datain					=> VRAMDataWrite,
		
		-- Read Mode
		dataoutPair				=> VRAMDataPair,
		dataoutImpair			=> VRAMDataImpair
	);
	--
	-- TODO : Arbitration, glue, VRAM, CGRAM
	-- --> Arbitration based on X/Y coordinate / Display valid register.
	-- --> Necessary for palette/VRAM/OAM...
	
	
	--
	-- Arbitration during one frame.
	--
	process(clock,visibleX,visibleY,R2133_OVERSCAN,
			sVRAMReadAdrPairFromFetch,
			sVRAMReadAdrImpairFromFetch,
			sVRAMWriteLowHightFromRegisters,
			VRAMDataPair,
			VRAMDataImpair,
			sPaletteSubReadAdr,
			readDataCGRAM,
			sVRAMWriteFromRegisters,
			sVRAMAdrFromRegisters,
			sVRAMDataFromRegisters,
			sCGRAMAdressReadWriteFromRegisters,
			sCGRAMDataWriteFromRegisters,
			sCGRAMWriteSigFromRegisters,
			readOnlyDataCGRAM,
			sPaletteMainReadAdr,
			NormalX, NormalY, R2100_DisplayDisabled
			)
	begin
		--
		-- Find the region.
		--
		if (NormalX>=0 and NormalX<=258) then
			visibleX <= '1';
		else
			visibleX <= '0';
		end if;
		
		if (NormalY>=0) and ((NormalY<=447 and R2133_OVERSCAN='0') or (NormalY<=479 and R2133_OVERSCAN='1')) then
			visibleY <= '1';
		else
			visibleY <= '0';
		end if;
		
		--
		-- VRAM Arbitration.
		--
		-- TODO : now for testing arbitration give higher priority to CPU WRITE and PPU VRAM access.
		if (visibleX='1' and visibleY='1' and R2100_DisplayDisabled='0' and CPUwrite='0') then
			--- INSIDE SCREEN     ---
			--=======================
			VRAMWrite					<= '0';
			VRAMPairAddress				<= sVRAMReadAdrPairFromFetch;
			VRAMImpairAddress			<= sVRAMReadAdrImpairFromFetch;
			
			VRAMWriteImpair				<= sVRAMWriteLowHightFromRegisters;
			VRAMDataWrite				<= "00000000";
						
			sVRAMReadDataPairToFetch	<= VRAMDataPair;
			sVRAMReadDataImpairToFetch	<= VRAMDataImpair;
			
			--
			-- CGRAM Arbitration.
			--
			
			-- CGRAM unit 1 read inside screen.
			readWriteAdrCGRAM			<= sPaletteSubReadAdr;			
			sPaletteSubReadData			<= readDataCGRAM;
			writeCGRAMSig				<= '0';

			-- CG RAM Unit 2 always read.
			readOnlyAdrCGRAM			<= sPaletteMainReadAdr;
			sPaletteMainReadData		<= readOnlyDataCGRAM;
			
			sCGRAMDataReadToRegisters	<= "000000000000000";
			writeDataCGRAM				<= "000000000000000";
			
		else
			--- OUTSIDE OF SCREEN ---
			--=======================
			VRAMWrite					<= '0'; -- TODO : rollback later on cpu flags : sVRAMWriteFromRegisters;			-- do write ?
			VRAMWriteImpair				<= sVRAMWriteLowHightFromRegisters; -- if write, which block ?

			VRAMPairAddress				<= sVRAMAdrFromRegisters;			-- Adress same for both block in read/write.
			VRAMImpairAddress			<= sVRAMAdrFromRegisters;

			VRAMDataWrite				<= sVRAMDataFromRegisters;			-- Read 16 bit and select correct chunk internally.
			sVRAMDataToRegisters		<= VRAMDataImpair & VRAMDataPair;

			sVRAMReadDataPairToFetch	<= "00000000";
			sVRAMReadDataImpairToFetch	<= "00000000";
			
			--
			-- CGRAM Arbitration.
			--
			
			-- CG RAM Unit 1 accessed by CPU as read/write.
			readWriteAdrCGRAM			<= sCGRAMAdressReadWriteFromRegisters;
			sPaletteSubReadData			<= "000000000000000";
			sCGRAMDataReadToRegisters 	<= readDataCGRAM;
			writeDataCGRAM				<= sCGRAMDataWriteFromRegisters;
			writeCGRAMSig				<= '0'; -- TODO : rollback later to cpu flags. sCGRAMWriteSigFromRegisters;
			
			-- CG RAM Unit 2 always read.
			readOnlyAdrCGRAM			<= sPaletteMainReadAdr;
			sPaletteMainReadData		<= readOnlyDataCGRAM;
						
		end if;
		
		-- Main rendering use second port for palette : always accessible.
		sPaletteMainReadData	<= readOnlyDataCGRAM;
		readOnlyAdrCGRAM 		<= sPaletteMainReadAdr;
		
		-- Last X Pixel of line AND with valid Y range.
		if (NormalX >= 267) then
			startline <= '1';
		else
			startline <= '0';
		end if;
		
		-- Within visible range.
		drawPixel <= visibleX and visibleY;
	end process;
	
	--
	-- Create BG Cache for current line.
	--
	
	instanceMode7Manager : PPU_Mode7Manager port map
	(
		clock         		=> clock,
		
		lineStart			=> startline,
		X_NonMosaic			=> NormalX(7 downto 0),
		YMosaic				=> NormalY(8 downto 1), -- TODO : Not always YMosaic in this case... depends on BG selected also.
		
		R210D_M7_HOFS		=> R210D_M7_HOFS,
		R210E_M7_VOFS		=> R210E_M7_VOFS,
                            
		R211A_M7_HFLIP		=> R211A_M7_HFLIP,
		R211A_M7_VFLIP		=> R211A_M7_VFLIP,
		                     
		R211B_M7A			=> R211B_M7A,
		R211C_M7B			=> R211C_M7B,
		R211D_M7C			=> R211D_M7C,
		R211E_M7D			=> R211E_M7D,
		                     
		R211F_M7CX			=> R211F_M7CX,
		R2120_M7CY			=> R2120_M7CY,
		
		Mode7XOut			=> sMode7x,
		Mode7YOut			=> sMode7y
	);
	
	instancePixelFetch : PPU_PixelFetch port map
	(
		clock					=> clock,
		startLine				=> startline,

		ScreenY_PostMosaic		=> YMosaic,
		ScreenX_NonMosaic		=> NormalX,
		ScreenY_NonMosaic		=> NormalY,
		MosaicXSig				=> XMosaicSig,
		
		Mode7X					=> sMode7x,
		Mode7Y					=> sMode7y,
		
		R211A_M7_REPEAT			=> R211A_M7_REPEAT,
		R211A_M7_FILL			=> R211A_M7_FILL,

		R2105_BGSize			=> R2105_BGSize,
		R2106_BGMosaicEnable	=> R2106_BGMosaicEnable,
		                           
		R2107_BG1AddrTileMap	=> R2107_BG1AddrTileMap,
		R2108_BG2AddrTileMap	=> R2108_BG2AddrTileMap,
		R2109_BG3AddrTileMap	=> R2109_BG3AddrTileMap,
		R210A_BG4AddrTileMap	=> R210A_BG4AddrTileMap,
		                           
		R210B_BG1PixAddr		=> R210B_BG1PixAddr,
		R210B_BG2PixAddr		=> R210B_BG2PixAddr,
		R210C_BG3PixAddr		=> R210C_BG3PixAddr,
		R210C_BG4PixAddr		=> R210C_BG4PixAddr,
		                           
		R2105_BGMode			=> R2105_BGMode,
		R2133_HIRES				=> R2133_HIRES,
		                           
		R210D_BG1_HOFS			=> R210D_BG1_HOFS,
		R210E_BG1_VOFS			=> R210E_BG1_VOFS,
                                   
		R210F_BG2_HOFS			=> R210F_BG2_HOFS,
		R2110_BG2_VOFS			=> R2110_BG2_VOFS,
                                   
		R2111_BG3_HOFS			=> R2111_BG3_HOFS,
		R2112_BG3_VOFS			=> R2112_BG3_VOFS,
                                   
		R2113_BG4_HOFS			=> R2113_BG4_HOFS,
		R2114_BG4_VOFS			=> R2114_BG4_VOFS,
		                           
		R210789A_BGsMapSX		=> R210789A_BGsMapSX,
		R210789A_BGsMapSY		=> R210789A_BGsMapSY,
	                             
		VRAMAddressPair			=> sVRAMReadAdrPairFromFetch,
		VRAMAddressImpair		=> sVRAMReadAdrImpairFromFetch,
		VRAMRead				=> sVRAMReadSigFromFetch,
		VRAMDataPair			=> sVRAMReadDataPairToFetch,
		VRAMDataImpair			=> sVRAMReadDataImpairToFetch,
		
		LineCacheAddress		=> sLineCacheWriteAdr,
		LineCacheData			=> sLineCacheWriteData,
		WriteS					=> sLineCacheWrite
	);
	
	--
	-- Cache line.
	--
	instanceLineCache : PPU_LineCache port map
	(
		clock		=> clock,
		
		Write		=> sLineCacheWrite,
		
		AdrWrite	=> sLineCacheWriteAdr,
		DataWrite	=> sLineCacheWriteData,

		AdrRead		=> sLineCacheReadAdr,	-- TODO think about reading one pixel ahead to X match readData
		DataRead	=> sLineCacheReadData
	);

	--
	-- Display BG of previous line from cache.
	-- TODO : Sprite support.
	--

	instanceChipsetLow : PPU_Chipset_Low port map
    (
		--
		-- General Side.
		--
		clock					=> clock,
		reset					=> reset,
		drawPixel				=> drawPixel,

		-- TODO : move to 9..0 when support HiRes + Sprite. : need to find outside of screen and support pixel precision.
		xCoord					=> NormalX(7 downto 0),
		
		--
		-- Memory Line Cache Side.
		--
		Address 				=> sLineCacheReadAdr,
		DataPixels 				=> sLineCacheReadData,

		MainIndex				=> sPaletteMainReadAdr,
		MainColor				=> sPaletteMainReadData,
		
		SubIndex				=> sPaletteSubReadAdr,
		SubColor				=> sPaletteSubReadData,
		
		--
		-- Register Side.
		--
		R2100_DisplayDisabled	=> R2100_DisplayDisabled,
		R2100_Brigthness		=> R2100_Brigthness,
		
		R2105_BGMode			=> R2105_BGMode,
		R2105_BG3Priority		=> R2105_BG3Priority,

		R21232425_W1_ENABLE		=> R21232425_W1_ENABLE,
		R21232425_W2_ENABLE		=> R21232425_W2_ENABLE,
		R21232425_W1_INV		=> R21232425_W1_INV,
		R21232425_W2_INV		=> R21232425_W2_INV,
		                           
		R2126_W1_LEFT			=> R2126_W1_LEFT,
		R2127_W1_RIGHT			=> R2127_W1_RIGHT,
		R2128_W2_LEFT			=> R2128_W2_LEFT,
		R2129_W2_RIGHT			=> R2129_W2_RIGHT,
		                           
		R212AB_WMASK_LSB		=> R212AB_WMASK_LSB,
		R212AB_WMASK_MSB		=> R212AB_WMASK_MSB,
		                           
		R212C_MAIN				=> R212C_MAIN,
		R212D_SUB				=> R212D_SUB,
		                           
		R212E_WMASK_MAIN		=> R212E_WMASK_MAIN,
		R212F_WMASK_SUB			=> R212F_WMASK_SUB,
                                   
		R2130_CLIPCOLORMATH		=> R2130_CLIPCOLORMATH,
		R2130_PREVENTCOLORMATH	=> R2130_PREVENTCOLORMATH,
		R2130_ADDSUBSCR			=> R2130_ADDSUBSCR,
		R2130_DIRECTCOLOR		=> R2130_DIRECTCOLOR,
                                   
		R2131_COLORMATH_SUB		=> R2131_COLORMATH_SUB,
		R2131_COLORMATH_HALF	=> R2131_COLORMATH_HALF,
		R2131_ENABLEMATH_UNIT	=> R2131_ENABLEMATH_UNIT,
                                   
		R2132_FIXEDCOLOR_R		=> R2132_FIXEDCOLOR_R,
		R2132_FIXEDCOLOR_G		=> R2132_FIXEDCOLOR_G,
		R2132_FIXEDCOLOR_B		=> R2132_FIXEDCOLOR_B,

		R2133_M7_EXTBG			=> R2133_M7_EXTBG,
                                
		--
		-- Video Side
		--
		Red						=> Red,
		Green					=> Green,
		Blue					=> Blue
	);
end ArchiPPU_System;














