----------------------------------------------------------------------------------
-- Create Date:   	
-- Design Name:		PPU_ComputeVRAMAddress.VHD
-- Module Name:		PPU_ComputeVRAMAddress
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

entity PPU_ComputeVRAMAddress is
    Port (
		--
		-- Upper module real time info.
		--
		stateCounter 			: in  STD_LOGIC_VECTOR(2 downto 0);

		ScreenX					: in STD_LOGIC_VECTOR (4 downto 0);
		ScreenY					: in STD_LOGIC_VECTOR (8 downto 0);
		screenYMosaic			: in STD_LOGIC_VECTOR (8 downto 0);
		
		-- Tile(9 downto 0) : Char
		-- Tile(14) : FlipH
		-- Tile(15) : FlipV
		
		regBG1_Char,
		regBG2_Char,
		regBG3_Char,
		regBG4_Char				: in STD_LOGIC_VECTOR (9 downto 0);
		
		regBG1_FlipV 			: in STD_LOGIC;
		regBG2_FlipV 			: in STD_LOGIC;
		regBG3_FlipV 			: in STD_LOGIC;
		regBG4_FlipV 			: in STD_LOGIC;
		regBG1_FlipH 			: in STD_LOGIC;
		regBG2_FlipH 			: in STD_LOGIC;
		regBG3_FlipH 			: in STD_LOGIC;
		regBG4_FlipH 			: in STD_LOGIC;
		
		regBG1_FlipXCond16Pix	: in STD_LOGIC;
		regBG1_FlipYCond16Pix	: in STD_LOGIC;
		regBG2_FlipXCond16Pix	: in STD_LOGIC;
		regBG2_FlipYCond16Pix	: in STD_LOGIC;
		regBG3_FlipXCond16Pix	: in STD_LOGIC;
		regBG3_FlipYCond16Pix	: in STD_LOGIC;
		regBG4_FlipXCond16Pix	: in STD_LOGIC;
		regBG4_FlipYCond16Pix	: in STD_LOGIC;
		
		-- 10 Bit for coord, and we add without the 3 bit LSB = 7 Bit.
		regTileBG3BankHBOffset	: in STD_LOGIC_VECTOR (9 downto 0);
		regTileBG3BankVBOffset	: in STD_LOGIC_VECTOR (9 downto 0);
		regTileBG3BankHB		: in STD_LOGIC_VECTOR (2 downto 0);	-- Bit 15/14/13 From tile reg.
		regTileBG3BankVB		: in STD_LOGIC_VECTOR (1 downto 0);	-- Bit 14/13    From tile reg.
		validBG3				: in STD_LOGIC;
		
		--
		-- Global Registers.
		--
		R2105_BGSize			: in STD_LOGIC_VECTOR (3 downto 0);
		R2106_BGMosaicEnable	: in STD_LOGIC_VECTOR (3 downto 0);
		
		R2107_BG1AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);
		R2108_BG2AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);
		R2109_BG3AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);
		R210A_BG4AddrTileMap	: in STD_LOGIC_VECTOR (5 downto 0);

		-- Specification gives 4 BIT for pixel buffer address
		-- But does not fit in 15 bit word adress calculation
		-- Moreover, BSnes do ALSO use only 3 LSB BIT.
		R210B_BG1PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		R210B_BG2PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		R210C_BG3PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		R210C_BG4PixAddr		: in STD_LOGIC_VECTOR (2 downto 0);
		
		R2105_BGMode			: in STD_LOGIC_VECTOR (2 downto 0);
		
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
		--
		--
		VRAMAddress				: out STD_LOGIC_VECTOR(14 downto 0);	-- 64K word
		VRAMRead				: out STD_LOGIC;
		
		-- Bit info for flip X/Y for 16 pix tile for current BG.
		-- Used based on RegisterStorage value : BGTILE1,2,3,4
		
		TileXCondOut			: out STD_LOGIC;
		TileYCondOut			: out STD_LOGIC;
		RegisterStorage			: out STD_LOGIC_VECTOR (3 downto 0)
	);
end PPU_ComputeVRAMAddress;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture APPU_ComputeVRAMAddress of PPU_ComputeVRAMAddress is
	component PPUBGTileAdress is
		Port ( 	BGTileMapBase 	: in STD_LOGIC_VECTOR(5 downto 0);
				TileCoordX	  	: in STD_LOGIC_VECTOR(5 downto 0);
				TileCoordY	  	: in STD_LOGIC_VECTOR(5 downto 0);
				SX				: in STD_LOGIC;
				SY				: in STD_LOGIC;
				
				BGTileAdr		: out STD_LOGIC_VECTOR(14 downto 0) -- Adress in Word : 15 bit to access 65K bytes.
		);
	end component;
	
	type STATE_TYPE	is (BG1_TILE,
						BG2_TILE,
						BG3_TILE,
						BG3_TILEOFF0,
						BG3_TILEOFF8,
						
						BG4_TILE,
						BG1_BPP01,
						BG1_BPP23,
						BG1_BPP45,
						
						BG1_BPP67,
						BG2_BPP01,
						BG2_BPP23,
						BG3_BPP01,
						
						BG4_BPP01,
						BG_MODE7,
						NONE);

	signal command : STATE_TYPE;
	
	signal useTileOff 		: STD_LOGIC;
	
	signal readS			: STD_LOGIC;
	signal tileRead			: STD_LOGIC;
	signal bgSelect			: STD_LOGIC_VECTOR(1 downto 0);
	signal offsetTile		: STD_LOGIC;
	signal offsetVTile		: STD_LOGIC;
	signal TileXCond		: STD_LOGIC;
	signal TileYCond		: STD_LOGIC;
	
	signal addrTileMap		: STD_LOGIC_VECTOR(5 downto 0);
	signal pixAddress		: STD_LOGIC_VECTOR(2 downto 0);
	signal offsetH			: STD_LOGIC_VECTOR(9 downto 0);
	signal offsetV			: STD_LOGIC_VECTOR(9 downto 0);
	signal mapSX			: STD_LOGIC;
	signal mapSY			: STD_LOGIC;
	
	----------------------------------------------------------
	--  Constant during the whole rendering.
	----------------------------------------------------------
	-- Select the shift amount based on the number of bitplanes
	-- to compute the correct tile adress for each BG
	-- based on current graphic mode.
	signal bg1Selector		: STD_LOGIC_VECTOR(1 downto 0);
	signal bg2Selector		: STD_LOGIC_VECTOR(1 downto 0);
	signal bg3Selector		: STD_LOGIC_VECTOR(1 downto 0);
	signal bg4Selector		: STD_LOGIC_VECTOR(1 downto 0);
	
	----------------------------------------------------------
	--  Current Tile/Pixel VRAM Read Information.
	----------------------------------------------------------

	--- PIXEL READ RELATED ---
	-- Select the bitplan we are going to read from VRAM.
	signal bppSelect		: STD_LOGIC_VECTOR(1 downto 0);
	-- Select the size of the bitplans for current BG.
	signal bgBPPSelector	: STD_LOGIC_VECTOR(1 downto 0);
	-- Current Character used for pixel adressing.
	signal char				: STD_LOGIC_VECTOR(9 downto 0);
	signal flipV,flipH		: STD_LOGIC;
	signal mosaicEnable		: STD_LOGIC;
	
	--- TILE READ RELATED ---
	-- Size of the Tile (8 Pixel/16 pixel mode)
	signal tileSize			: STD_LOGIC;
	-- Tile X coordinate in Tile unit.
	signal TileCoordX		: STD_LOGIC_VECTOR(5 downto 0);
	-- Tile Y coordinate in Tile unit.
	signal TileCoordY		: STD_LOGIC_VECTOR(5 downto 0);

	signal sVRAMAdrReadA	: STD_LOGIC_VECTOR(14 downto 0);
	signal outTileAdr		: STD_LOGIC_VECTOR(14 downto 0);


	signal ValidBitH,ValidBitV : STD_LOGIC;
	
	---
	--- Constant for BPP Format.
	---
	constant BPP2	: STD_LOGIC_VECTOR := "00";
	constant BPP4	: STD_LOGIC_VECTOR := "01";
	constant BPP8	: STD_LOGIC_VECTOR := "10";

	constant BG1	: STD_LOGIC_VECTOR := "00";
	constant BG2	: STD_LOGIC_VECTOR := "01";
	constant BG3	: STD_LOGIC_VECTOR := "10";
	constant BG4	: STD_LOGIC_VECTOR := "11";
	
	constant BPP01		: STD_LOGIC_VECTOR := "00";
	constant BPP23		: STD_LOGIC_VECTOR := "01";
	constant BPP45		: STD_LOGIC_VECTOR := "10";
	constant BPP67		: STD_LOGIC_VECTOR := "11";
	constant BPPIGNORE	: STD_LOGIC_VECTOR := "00";
begin
	--
	-- Step 0 : Logic State Machine : Micro State selector.
	--
	process(stateCounter, R2105_BGMode)
	begin
		bg3Selector	<= BPP2; -- 2 BPP
		bg4Selector	<= BPP2; -- 2 BPP
		
		case R2105_BGMode is
		when CONSTANTS.MODE0 =>
			case stateCounter is
			when "000"  => command <= BG3_TILE;
			when "001"  => command <= BG1_TILE;
			when "010"  => command <= BG2_TILE;
			when "011"  => command <= BG4_TILE;
			when "100"  => command <= BG1_BPP01;
			when "101"  => command <= BG2_BPP01;
			when "110"  => command <= BG3_BPP01;
			when others => command <= BG4_BPP01;
			end case;
			bg1Selector	<= BPP2; -- 2 BPP
			bg2Selector	<= BPP2; -- 2 BPP
			useTileOff	<= '0';
		when CONSTANTS.MODE1 =>
			case stateCounter is
			when "000"  => command <= BG3_TILE;
			when "001"  => command <= BG1_TILE;
			when "010"  => command <= BG2_TILE;
			when "011"  => command <= BG1_BPP23;
			when "100"  => command <= BG1_BPP01;
			when "101"  => command <= BG2_BPP01;
			when "110"  => command <= BG2_BPP23;
			when others => command <= BG3_BPP01;
			end case;
			bg1Selector	<= BPP4; -- 4 BPP
			bg2Selector	<= BPP4; -- 4 BPP
			useTileOff	<= '0';
		when CONSTANTS.MODE2 =>
			case stateCounter is
			when "000"  => command <= BG3_TILEOFF0;
			when "001"  => command <= BG3_TILEOFF8;
			when "010"  => command <= BG1_TILE;
			when "011"  => command <= BG2_TILE;
			when "100"  => command <= BG1_BPP23;
			when "101"  => command <= BG1_BPP01;
			when "110"  => command <= BG2_BPP01;
			when others => command <= BG2_BPP23;
			end case;
			bg1Selector	<= BPP4; -- 4 BPP
			bg2Selector	<= BPP4; -- 4 BPP
			useTileOff	<= '1';
		when CONSTANTS.MODE3 =>
			case stateCounter is
			when "000"  => command <= BG1_TILE;
			when "001"  => command <= BG2_TILE;
			when "010"  => command <= BG1_BPP45;
			when "011"  => command <= BG1_BPP23;
			when "100"  => command <= BG1_BPP01;
			when "101"  => command <= BG2_BPP01;
			when "110"  => command <= BG2_BPP23;
			when others => command <= BG1_BPP67;
			end case;
			bg1Selector	<= BPP8; -- 8 BPP
			bg2Selector	<= BPP4; -- 4 BPP
			useTileOff	<= '0';
		when CONSTANTS.MODE4 =>
			case stateCounter is
			when "000"  => command <= BG3_TILEOFF0;
			when "001"  => command <= BG1_TILE;
			when "010"  => command <= BG2_TILE;
			when "011"  => command <= BG1_BPP45;
			when "100"  => command <= BG1_BPP23;
			when "101"  => command <= BG1_BPP01;
			when "110"  => command <= BG2_BPP01;
			when others => command <= BG1_BPP67;
			end case;
			bg1Selector	<= BPP8; -- 8 BPP
			bg2Selector	<= BPP2; -- 2 BPP
			useTileOff	<= '1';
		when CONSTANTS.MODE5 =>
			case stateCounter is
			when "000"  => command <= BG2_TILE;
			when "001"  => command <= BG1_TILE;
			when "010"  => command <= BG2_BPP01;
			when "011"  => command <= BG1_BPP23;
			when "100"  => command <= BG1_BPP01;
			when "101"  => command <= NONE;
			when "110"  => command <= NONE;
			when others => command <= NONE;
			end case;
			bg1Selector	<= BPP4; -- 4 BPP
			bg2Selector	<= BPP2; -- 2 BPP
			useTileOff	<= '0';
		when CONSTANTS.MODE6 =>
			case stateCounter is
			when "000"  => command <= BG3_TILEOFF0;
			when "001"  => command <= BG3_TILEOFF8;
			when "010"  => command <= BG1_TILE;	-- Need 2 Cycle between the READ AND that BPP can read tile info.
			when "011"  => command <= NONE;
			when "100"  => command <= BG1_BPP01;
			when "101"  => command <= BG1_BPP23;
			when "110"  => command <= NONE;
			when others => command <= NONE;
			end case;
			bg1Selector	<= BPP4; -- 4 BPP
			bg2Selector	<= BPP2; -- 2 BPP
			useTileOff	<= '1';
		when others =>
			case stateCounter is
			when "000"  => command <= BG_MODE7;
			when "001"  => command <= BG_MODE7;
			when "010"  => command <= BG_MODE7;
			when "011"  => command <= BG_MODE7;
			when "100"  => command <= BG_MODE7;
			when "101"  => command <= BG_MODE7;
			when "110"  => command <= BG_MODE7;
			when others => command <= BG_MODE7;
			end case;
			-- Mode 7 specific code ignore this.
			bg1Selector	<= BPP2; -- 2 BPP
			bg2Selector	<= BPP2; -- 2 BPP
			useTileOff	<= '0';
		end case;
	end process;

	--
	-- Step 1 :
	-- Depending on selected command of state table
	-- Select data path.
	--
	process(command, R2106_BGMosaicEnable,
			readS)
	begin
		case command is
		when BG1_TILE   =>
			bgSelect	<= BG1;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '1';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(0);
			RegisterStorage <= CONSTANTS.STR_BG1_TILE;
		when BG2_TILE   =>
			bgSelect	<= BG2;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '1';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(1);
			RegisterStorage <= CONSTANTS.STR_BG2_TILE;
		when BG3_TILE   =>
			bgSelect	<= BG3;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '1';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(2);
			RegisterStorage <= CONSTANTS.STR_BG3_TILE;
		when BG4_TILE   =>
			bgSelect	<= BG4;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '1';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(3);
			RegisterStorage <= CONSTANTS.STR_BG4_TILE;
		when BG1_BPP01  =>
			bgSelect	<= BG1;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP01;
			mosaicEnable <= R2106_BGMosaicEnable(0);
			RegisterStorage <= CONSTANTS.STR_BG1_BPP01;
		when BG1_BPP23  =>
			bgSelect	<= BG1;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP23;
			mosaicEnable <= R2106_BGMosaicEnable(0);
			RegisterStorage <= CONSTANTS.STR_BG1_BPP23;
		when BG1_BPP45  =>
			bgSelect	<= BG1;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP45;
			mosaicEnable <= R2106_BGMosaicEnable(0);
			RegisterStorage <= CONSTANTS.STR_BG1_BPP45;
		when BG1_BPP67  =>
			bgSelect	<= BG1;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP67;
			mosaicEnable <= R2106_BGMosaicEnable(0);
			RegisterStorage <= CONSTANTS.STR_BG1_BPP67;
		when BG2_BPP01  =>
			bgSelect	<= BG2;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP01;
			mosaicEnable <= R2106_BGMosaicEnable(1);
			RegisterStorage <= CONSTANTS.STR_BG2_BPP01;
		when BG2_BPP23  =>
			bgSelect	<= BG2;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP23;
			mosaicEnable <= R2106_BGMosaicEnable(1);
			RegisterStorage <= CONSTANTS.STR_BG2_BPP23;
		when BG3_BPP01  =>
			bgSelect	<= BG3;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP01;
			mosaicEnable <= R2106_BGMosaicEnable(2);
			RegisterStorage <= CONSTANTS.STR_BG3_BPP01;
		when BG4_BPP01  =>
			bgSelect	<= BG4;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPP01;
			mosaicEnable <= R2106_BGMosaicEnable(3);
			RegisterStorage <= CONSTANTS.STR_BG4_BPP01;
		when BG3_TILEOFF0 =>
			bgSelect	<= BG3;
			offsetTile	<= '1';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '1';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(2);
			RegisterStorage <= CONSTANTS.STR_BG3_TILE; -- Same as BG3TILE
		when BG3_TILEOFF8 =>
			bgSelect	<= BG3;
			offsetTile	<= '1';
			offsetVTile <= '1';
			readS		<= '1';
			tileRead	<= '1';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(2);
			RegisterStorage <= CONSTANTS.STR_BG3V_TILE; -- Special for +8 V offset
		when BG_MODE7   =>
			bgSelect	<= BG1;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '1';
			tileRead	<= '0';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(0);
			RegisterStorage <= CONSTANTS.STR_NONE; -- Dont care
		when others		=>
			bgSelect	<= BG1;
			offsetTile	<= '0';
			offsetVTile <= '0';
			readS		<= '0';
			tileRead	<= '0';
			bppSelect	<= BPPIGNORE;
			mosaicEnable <= R2106_BGMosaicEnable(0);
			RegisterStorage <= CONSTANTS.STR_NONE; -- Dont care
		end case;
		
		VRAMRead <= readS;
	end process;
	
	--
	-- Step 2 : 
	-- Depending on data path mode
	-- Select information for address computation.
	--
	process(bgSelect,
	
			regBG1_Char,regBG1_FlipV,regBG1_FlipH,
			regBG2_Char,regBG2_FlipV,regBG2_FlipH,
			regBG3_Char,regBG3_FlipV,regBG3_FlipH,
			regBG4_Char,regBG4_FlipV,regBG4_FlipH,

			regBG1_FlipXCond16Pix, regBG1_FlipYCond16Pix,
			regBG2_FlipXCond16Pix, regBG2_FlipYCond16Pix,
			regBG3_FlipXCond16Pix, regBG3_FlipYCond16Pix,
			regBG4_FlipXCond16Pix, regBG4_FlipYCond16Pix,
			
			R210789A_BGsMapSX,
			R210789A_BGsMapSY,
			R2107_BG1AddrTileMap,
			R210B_BG1PixAddr,
			R210D_BG1_HOFS,
			R210E_BG1_VOFS,
			R2108_BG2AddrTileMap,
			R210B_BG2PixAddr,
			R210F_BG2_HOFS,
			R2110_BG2_VOFS,
			R2109_BG3AddrTileMap,
			R210C_BG3PixAddr,
			R2111_BG3_HOFS,
			R2112_BG3_VOFS,
			R210A_BG4AddrTileMap,
			R210C_BG4PixAddr,
			R2113_BG4_HOFS,
			R2114_BG4_VOFS,
			R2105_BGSize,
			bg1Selector,
			bg2Selector,
			bg3Selector,
			bg4Selector
			)
	begin
		case bgSelect is
		when BG1 =>
			addrTileMap 	<= R2107_BG1AddrTileMap;
			pixAddress		<= R210B_BG1PixAddr;
			offsetH			<= R210D_BG1_HOFS;
			offsetV			<= R210E_BG1_VOFS;
			mapSX			<= R210789A_BGsMapSX(0);
			mapSY			<= R210789A_BGsMapSY(0);
			tileSize		<= R2105_BGSize(0);
			bgBPPSelector	<= bg1Selector;
			char			<= regBG1_Char;
			flipV			<= regBG1_FlipV;
			flipH			<= regBG1_FlipH;
			TileXCond		<= regBG1_FlipXCond16Pix;
			TileYCond		<= regBG1_FlipYCond16Pix;
		when BG2 =>
			addrTileMap 	<= R2108_BG2AddrTileMap;
			pixAddress		<= R210B_BG2PixAddr;
			offsetH			<= R210F_BG2_HOFS;
			offsetV			<= R2110_BG2_VOFS;
			mapSX			<= R210789A_BGsMapSX(1);
			mapSY			<= R210789A_BGsMapSY(1);
			tileSize		<= R2105_BGSize(1);
			bgBPPSelector 	<= bg2Selector;
			char			<= regBG2_Char;
			flipV			<= regBG2_FlipV;
			flipH			<= regBG2_FlipH;
			TileXCond		<= regBG2_FlipXCond16Pix;
			TileYCond		<= regBG2_FlipYCond16Pix;
		when BG3 =>
			addrTileMap 	<= R2109_BG3AddrTileMap;
			pixAddress		<= R210C_BG3PixAddr;
			offsetH			<= R2111_BG3_HOFS;
			offsetV			<= R2112_BG3_VOFS;
			mapSX			<= R210789A_BGsMapSX(2);
			mapSY			<= R210789A_BGsMapSY(2);
			tileSize		<= R2105_BGSize(2);
			bgBPPSelector 	<= bg3Selector;
			char			<= regBG3_Char;
			flipV			<= regBG3_FlipV;
			flipH			<= regBG3_FlipH;
			TileXCond		<= regBG3_FlipXCond16Pix;
			TileYCond		<= regBG3_FlipYCond16Pix;
		when others =>
			addrTileMap 	<= R210A_BG4AddrTileMap;
			pixAddress		<= R210C_BG4PixAddr;
			offsetH			<= R2113_BG4_HOFS;
			offsetV			<= R2114_BG4_VOFS;
			mapSX			<= R210789A_BGsMapSX(3);
			mapSY			<= R210789A_BGsMapSY(3);
			tileSize		<= R2105_BGSize(3);
			bgBPPSelector 	<= bg4Selector;
			char			<= regBG4_Char;
			flipV			<= regBG4_FlipV;
			flipH			<= regBG4_FlipH;
			TileXCond		<= regBG4_FlipXCond16Pix;
			TileYCond		<= regBG4_FlipYCond16Pix;
		end case;
	end process;
	
	--
	-- Step 3 : Compute VRAM loading adress.
	--
	process(	tileRead,
				R2105_BGMode,
				bgBPPSelector,
				flipV,
				char,
				pixAddress,
				outTileAdr,
				bppSelect,
				screenX,
				screenY,
				offsetH,
				offsetV,
				tileSize,
				mosaicEnable,
				offsetTile,
				screenYMosaic,
				offsetVTile,
				regTileBG3BankHB,
				regTileBG3BankVB,
				regTileBG3BankHBOffset,
				regTileBG3BankVBOffset,
				validBG3,
				useTileOff,
				TileXCond,
				flipH,
				TileYCond,
				bgSelect,
				
				ValidBitH,
				ValidBitV
	)
		variable tmpX				: STD_LOGIC_VECTOR(7 downto 0);
		variable tmpY				: STD_LOGIC_VECTOR(8 downto 0);
		variable coordX,coordY		: STD_LOGIC_VECTOR(9 downto 0);
		variable coordXF,coordYF	: STD_LOGIC_VECTOR(9 downto 0);
		variable coordXF2,coordYF2	: STD_LOGIC_VECTOR(9 downto 0);
		variable charR				: STD_LOGIC_VECTOR(11 downto 0);
		variable lChar,lChar2		: STD_LOGIC_VECTOR(9 downto 0);
		variable pixY				: STD_LOGIC_VECTOR(2 downto 0);
	begin
		--
		-- Select X,Y at left tile coordinate based on BG mode.
		--
		tmpX := ScreenX & "000";

		-- We apply the mosaic to Y coordinate only
		-- And only for normal BG.
		if (mosaicEnable = '0' or offsetTile='1') then
			tmpY := screenY;
		else
			tmpY := screenYMosaic;
		end if;
		
		
		--
		-- Add BG Offset to the screen coordinate.
		--
		coordX	:= ("00" & tmpX) + (offsetH(9 downto 3) & ("000"));
		coordY	:= ("0"  & tmpY) + offsetV;
		
		if (tileRead = '1') then			

			--
			-- Apply Per Tile Offset to other BG, with BG3
			--
			
			-- Read BG3 for offset.
--			if (offsetTile='1') then
--				--
--				-- Compute BG3 Coordinate. (+8 Y)
--				--
--				coordXF2 := coordX;
--				
--				if (offsetVTile = '1') then
--					coordYF2 := coordY + 8;
--				else
--					coordYF2 := coordY;
--				end if;
--				
--				ValidBitH <= '0';
--				ValidBitV <= '0';
--			else
--				--
--				--
--				--
--				if (bgSelect = "00") then
--					ValidBitH <= regTileBG3BankHB(0) and validBG3; -- 0x2000 For BG1
--				else
--					if (bgSelect = "01") then
--						ValidBitH <= regTileBG3BankHB(1) and validBG3; -- 0x4000 For BG2
--					else
--						ValidBitH <= '0';
--					end if;
--				end if;
--
--				if (R2105_BGMode = CONSTANTS.MODE4) then
--					ValidBitV <= '0';
--				else
--					if (bgSelect = "00") then
--						ValidBitV <= regTileBG3BankVB(0) and validBG3; -- 0x2000 For BG1
--					else
--						if (bgSelect = "01") then
--							ValidBitV <= regTileBG3BankVB(1) and validBG3; -- 0x4000 For BG2
--						else
--							ValidBitV <= '0';
--						end if;
--					end if;
--				end if;
--				
--				if (useTileOff='1') then
--					if ((ValidBitH='1' and R2105_BGMode/=CONSTANTS.MODE4) or (R2105_BGMode=CONSTANTS.MODE4 and ValidBitH='1' and regTileBG3BankHB(2)='0')) then
--						-- (2+8) + (7+3)
--						-- vhopppcc cccccXXX
--						-- cc ccccc = 9..3
--						coordXF2	:= ("00" & tmpX) + (regTileBG3BankHBOffset(9 downto 3) & offsetH(2 downto 0)); -- TODO : multiple of 8 ??? Pixels resolution ???
--					else
--						coordXF2	:= coordX;
--					end if;
--					
--					if (ValidBitV='1') then
--						coordYF2	:= ("0" & tmpY) + (regTileBG3BankVBOffset);
--					else
--						if (R2105_BGMode=CONSTANTS.MODE4 and ValidBitH='1' and regTileBG3BankHB(2)='1') then
--							coordYF2	:= ("0" & tmpY) + (regTileBG3BankHBOffset); -- USE HORIZ REG FOR VERTICAL.
--						else
--							coordYF2	:= coordY;
--						end if;
--					end if;					
--				else
					coordXF2	:= coordX;
					coordYF2	:= coordY;
--				end if;
--			end if;
			
			--
			-- Compute Mirroring
			--
			TileXCondOut <= coordXF2(3) and (tileSize or R2105_BGMode(2));
			TileYCondOut <= coordYF2(3) and  tileSize;
			
			--
			-- Convert Screen coordinate into tile coordinate.
			--
			
			-- Force 16 pixel for mode 5/6.(7 used a different path : no problem)
			if (TileSize = '1' or R2105_BGMode(2)='1') then
				TileCoordX <= coordXF2(9 downto 4);
			else
				TileCoordX <= coordXF2(8 downto 3);
			end if;

			-- Vertical 8/16 pixel based on user selection.
			if (TileSize = '1') then
				TileCoordY <= coordYF2(9 downto 4);
			else
				TileCoordY <= coordYF2(8 downto 3);
			end if;
			
			----------------------------------------------------------
			--- Here instancePPUTileAdr block instance does the work.
			----------------------------------------------------------
			
			sVRAMAdrReadA <= outTileAdr;
		else
			--
			-- Check 16 Pix Tile Flip.
			--
			if (TileXCond='1' and FlipH='1') then
				lChar := char + 1;
			else
				lChar := char;
			end if;
			
			if (TileYCond='1' and FlipV='1') then
				lChar2 := lChar + 16;
			else
				lChar2 := lChar;
			end if;
			
			--
			-- Bitmap to read. (We shift the char adress based on BG format)
			--
			case bgBPPSelector is
			when BPP2 => -- 2BPP
				charR	:= "00" & lChar2;
			when BPP4 => -- 4BPP
				charR 	:= "0" & lChar2 & "0";			
			when others => -- 8BPP
				charR	:= lChar2 & "00";
			end case;
			
			--
			-- Apply vertical flip.
			--
			if (flipV = '1') then
				pixY := not(coordY(2 downto 0));
			else
				pixY := coordY(2 downto 0);
			end if;
			
			-- 15 bit Adress in WORD
			-- Byte address : (Base<<13) + (TileNumber * 8*NumBitplanes) 
			-- Word address : (Base<<12) + (TileNumber * 4*NumBitplanes)
			-- Word address : (Base<<12) + (TileNumber * [8/16/32])
			-- Word address : (Base<<12) + (TileNumber << [3/4/5])

			--  In word adress.
			--  BBBB ---- ---- ----
			--         CC CCCC CCCC (2 BPP)
			--  000 0000 000P PYYY +  (BPP Select + Y read)
			--
			sVRAMAdrReadA <= (pixAddress & "000000000000") + (charR & "000") + ("0000000000" & bppSelect & pixY);

			TileCoordX <= "000000";
			TileCoordY <= "000000";
			TileXCondOut <= '0';
			TileYCondOut <= '0';
			ValidBitH	<= '0';
			ValidBitV	<= '0';
		end if;
	end process;
	
	VRAMAddress <= sVRAMAdrReadA;
	
	instancePPUTileAdr : PPUBGTileAdress port map
	( 	BGTileMapBase	=> addrTileMap,
		TileCoordX		=> TileCoordX,
		TileCoordY		=> TileCoordY,
		SX				=> mapSX,
		SY				=> mapSY,
		BGTileAdr		=> outTileAdr -- out
	);
	
end architecture;