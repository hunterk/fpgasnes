----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_PixelFetch.VHD
-- Module Name:		PPU_PixelFetch
--					
--					This unit does the BIG job inside the PPU :
--					Fetch the correct pixel information based on the rendering mode,
--					offset, bg, and some tricks linked to each mode.
--
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
entity PPU_PixelFetch is
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
		
		-- Specification gives 4 BIT for pixel buffer address
		-- But does not fit in 15 bit word adress calculation
		-- Moreover, BSnes do ALSO use only 3 LSB BIT.
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
end PPU_PixelFetch;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_PixelFetch of PPU_PixelFetch is

	component PPU_ComputeVRAMAddress is
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
	end component;
		
	signal stateCounter 			: STD_LOGIC_VECTOR(2 downto 0);
	signal tileOffInactive			: STD_LOGIC;

	signal pixCycle					: STD_LOGIC_VECTOR(2 downto 0);
	signal 	pixOffset1,
			pixOffset2,
			pixOffset3,
			pixOffset4				: STD_LOGIC_VECTOR(2 downto 0);	

	signal regTileBG3BankHBOffset	: STD_LOGIC_VECTOR(9 downto 0);
	signal regTileBG3BankVBOffset	: STD_LOGIC_VECTOR(9 downto 0);
	signal regTileBG3BankHB			: STD_LOGIC_VECTOR(2 downto 0);
	signal regTileBG3BankVB			: STD_LOGIC_VECTOR(1 downto 0);
	
	signal XCondOut,YCondOut		: STD_LOGIC;
	signal regXCondOut, regYCondOut : STD_LOGIC;

	signal regBG3_TileVChar			: STD_LOGIC_VECTOR(9 downto 0);
	signal regBG3_TileVCond			: STD_LOGIC_VECTOR(1 downto 0);
	
	signal	   
		   regBG1_TileA,regBG2_TileA,regBG3_TileA,regBG4_TileA,
		   regBG1_BPP01A,regBG2_BPP01A,regBG3_BPP01A,regBG4_BPP01A,
		   regBG1_BPP01B,regBG2_BPP01B,regBG3_BPP01B,regBG4_BPP01B,
		   regBG1_BPP01C,regBG2_BPP01C,regBG3_BPP01C,regBG4_BPP01C,
		   
		   regBG1_BPP23A,regBG2_BPP23A,regBG1_BPP23B,regBG2_BPP23B,
		   regBG1_BPP23C,regBG2_BPP23C,
		   regBG1_BPP45A,regBG1_BPP67A,regBG1_BPP45B,regBG1_BPP67B,
		   regBG1_BPP45C,regBG1_BPP67C,
		   
		   BG1BPP01,BG1BPP23,BG1BPP45,BG1BPP67,
		   BG2BPP01,BG2BPP23,BG3BPP01,BG4BPP01
		   
		   : STD_LOGIC_VECTOR(15 downto 0);

	signal	regBG1_TileCPal,
			regBG2_TileCPal,
			regBG3_TileCPal,
			regBG4_TileCPal,
			regBG1_TileDPal,
			regBG2_TileDPal,
			regBG3_TileDPal,
			regBG4_TileDPal,
			regBG1_TileBPal,
			regBG2_TileBPal,
			regBG3_TileBPal,
			regBG4_TileBPal			: STD_LOGIC_VECTOR(2 downto 0);

	signal	regBG1_TileDPrio,
			regBG2_TileDPrio,
			regBG3_TileDPrio,
			regBG4_TileDPrio,
			regBG1_TileCPrio,
			regBG2_TileCPrio,
			regBG3_TileCPrio,
			regBG4_TileCPrio,
			regBG1_TileBPrio,
			regBG2_TileBPrio,
			regBG3_TileBPrio,
			regBG4_TileBPrio		: STD_LOGIC;

	signal	regBG1_TileDFlipH,
			regBG2_TileDFlipH,
			regBG3_TileDFlipH,
			regBG4_TileDFlipH,
			regBG1_TileCFlipH,
			regBG2_TileCFlipH,
			regBG3_TileCFlipH,
			regBG4_TileCFlipH,
			regBG1_TileBFlipH,
			regBG2_TileBFlipH,
			regBG3_TileBFlipH,
			regBG4_TileBFlipH		: STD_LOGIC;

	
	signal BG1TILEPAL,BG2TILEPAL,BG3TILEPAL,BG4TILEPAL 			: STD_LOGIC_VECTOR(2 downto 0);
	signal BG1TILEPRIO,BG2TILEPRIO,BG3TILEPRIO,BG4TILEPRIO		: STD_LOGIC;
	signal BG1TILEFLIPH,BG2TILEFLIPH,BG3TILEFLIPH,BG4TILEFLIPH	: STD_LOGIC;
	
	signal dataRead					: STD_LOGIC_VECTOR(15 downto 0);
	
	signal XTileBG1					: STD_LOGIC_VECTOR(2 downto 0);
	signal XTileBG2					: STD_LOGIC_VECTOR(2 downto 0);
	signal XTileBG3					: STD_LOGIC_VECTOR(2 downto 0);
	signal XTileBG4					: STD_LOGIC_VECTOR(2 downto 0);

	signal XTileBG1BeforeFlip		: STD_LOGIC_VECTOR(2 downto 0);
	signal XTileBG2BeforeFlip		: STD_LOGIC_VECTOR(2 downto 0);
	signal XTileBG3BeforeFlip		: STD_LOGIC_VECTOR(2 downto 0);
	signal XTileBG4BeforeFlip		: STD_LOGIC_VECTOR(2 downto 0);

	signal BG1Pix,regBG1Pix			: STD_LOGIC_VECTOR(7 downto 0);
	signal BG2Pix,regBG2Pix			: STD_LOGIC_VECTOR(3 downto 0);
	signal BG3Pix,regBG3Pix			: STD_LOGIC_VECTOR(1 downto 0);
	signal BG4Pix,regBG4Pix			: STD_LOGIC_VECTOR(1 downto 0);

	signal palPrioBlock,regpalPrioBlock	: STD_LOGIC_VECTOR(15 downto 0);
	
	signal number,regNumber			: STD_LOGIC_VECTOR(3 downto 0);
	
	signal regBG1_FlipCond16X		: STD_LOGIC;
	signal regBG1_FlipCond16Y		: STD_LOGIC;
	signal regBG2_FlipCond16X		: STD_LOGIC;
	signal regBG2_FlipCond16Y		: STD_LOGIC;
	signal regBG3_FlipCond16X		: STD_LOGIC;
	signal regBG3_FlipCond16Y		: STD_LOGIC;
	signal regBG4_FlipCond16X		: STD_LOGIC;
	signal regBG4_FlipCond16Y		: STD_LOGIC;
		
	signal Mode7					: STD_LOGIC;

	signal sVRAMAddressPair : STD_LOGIC_VECTOR(14 downto 0);
	signal sVRAMRead : STD_LOGIC;
	signal Mode7Out,Prev2Mode7Out,PrevMode7Out  : STD_LOGIC;
	signal PrevTileValue	: STD_LOGIC_VECTOR(7 downto 0);
	signal PrevMode7X,PrevMode7Y : STD_LOGIC_VECTOR(2 downto 0);
	
	----------------------------------------------------------
	--  Current Tile/Pixel VRAM Read Information.
	----------------------------------------------------------	
	signal selectX1,selectX2,selectX3,selectX4 : STD_LOGIC;
	signal XCounter		: STD_LOGIC_VECTOR(8 downto 0);
	signal r1Counter	: STD_LOGIC_VECTOR(2 downto 0);
	
	signal adrX			: STD_LOGIC_VECTOR(8 downto 0);
	
	signal BSel			: STD_LOGIC_VECTOR(3 downto 0);
	
	constant C_BANK		: STD_LOGIC := '0';
	constant B_BANK		: STD_LOGIC := '1';
begin
	----------------------------------------------------------------
	--- Pipeline 0
	----------------------------------------------------------------
	
	--
	-- Step 0 : State Machine Change Process.
	--
	process(clock,startLine)
	begin
		if (clock'event and clock = '1') then 
			if (startLine = '1') then
				stateCounter <= "111";
--				oldCount	 <= "000";
				XCounter	<= "000000000";
				tileOffInactive <= '1';	-- TODO : use
			else
				if (stateCounter = "111") then
					tileOffInactive <= '0';
				end if;
--				oldCount	 <= stateCounter;
				stateCounter <= stateCounter+1;
				XCounter	<= XCounter+1;
			end if;
		end if;
	end process;

	--
	-- Step 1 : Ask Address computation unit to get the adress.
	--
	instanceComputeVRAMAddress : PPU_ComputeVRAMAddress port map
	(
		--
		-- Upper module real time info.
		--
		stateCounter			=> stateCounter,

		ScreenX					=> XCounter(7 downto 3),
		ScreenY					=> ScreenY_NonMosaic,
		screenYMosaic			=> ScreenY_PostMosaic,
		
		-- Tile(9 downto 0) : Char
		-- Tile(14) : FlipH
		-- Tile(15) : FlipV
		
		regBG1_Char				=> regBG1_TileA(9 downto 0),
		regBG2_Char				=> regBG2_TileA(9 downto 0),
		regBG3_Char				=> regBG3_TileA(9 downto 0),
		regBG4_Char				=> regBG4_TileA(9 downto 0),
		
		regBG1_FlipV 			=> regBG1_TileA(15),
		regBG2_FlipV 			=> regBG2_TileA(15),
		regBG3_FlipV 			=> regBG3_TileA(15),
		regBG4_FlipV 			=> regBG4_TileA(15),

		regBG1_FlipH 			=> regBG1_TileA(14),
		regBG2_FlipH 			=> regBG2_TileA(14),
		regBG3_FlipH 			=> regBG3_TileA(14),
		regBG4_FlipH 			=> regBG4_TileA(14),
		
		regBG1_FlipXCond16Pix	=> regBG1_FlipCond16X,
		regBG1_FlipYCond16Pix	=> regBG1_FlipCond16Y,
		regBG2_FlipXCond16Pix	=> regBG2_FlipCond16X,
		regBG2_FlipYCond16Pix	=> regBG2_FlipCond16Y,
		regBG3_FlipXCond16Pix	=> regBG3_FlipCond16X,
		regBG3_FlipYCond16Pix	=> regBG3_FlipCond16Y,
		regBG4_FlipXCond16Pix	=> regBG4_FlipCond16X,
		regBG4_FlipYCond16Pix	=> regBG4_FlipCond16Y,
		
		-- 10 Bit for coord, and we add without the 3 bit LSB = 7 Bit.
		regTileBG3BankHBOffset	=> regTileBG3BankHBOffset,-- 9..0,
		regTileBG3BankVBOffset	=> regTileBG3BankVBOffset,-- 9..0,
		regTileBG3BankHB		=> regTileBG3BankHB,-- 15..13
		regTileBG3BankVB		=> regTileBG3BankVB,-- 14..13
		
		validBG3 				=> tileOffInactive,
		
		--
		-- Global Registers.
		--
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
	
		VRAMAddress				=> sVRAMAddressPair,
		VRAMRead				=> sVRAMRead,
		
		TileXCondOut			=> XCondOut,
		TileYCondOut			=> YCondOut,
		RegisterStorage			=> number
	);
		
	----------------------------------------------------------------
	--- Pipeline 1
	----------------------------------------------------------------
	
	process(clock, R2105_BGMode, Mode7,
			sVRAMAddressPair,
			sVRAMRead,
			Mode7X,
			Mode7Y,
			R211A_M7_REPEAT,
			R211A_M7_FILL,
			PrevTileValue,
			PrevMode7Y,
			PrevMode7X)
	begin
		if (R2105_BGMode = CONSTANTS.MODE7) then
			Mode7 <= '1';
		else
			Mode7 <= '0';
		end if;
		
		if (mode7 = '0') then
			VRAMAddressPair		<= sVRAMAddressPair;
			VRAMAddressImpair	<= sVRAMAddressPair;
			VRAMRead			<= sVRAMRead;
			Mode7Out			<= '0'; -- Avoid latch.
		else
			if ((Mode7X(20 downto 10) /= "00000000000") or (Mode7Y(20 downto 10) /= "00000000000")) then
				Mode7Out <= '1';
			else
				Mode7Out <= '0';
			end if;
			
			if (Mode7Out='1' and R211A_M7_REPEAT='1' and R211A_M7_FILL='1') then
				VRAMAddressPair		<= '0' & Mode7Y(9 downto 3) & Mode7X(9 downto 3);
			else
				-- Force Tile 0.
				VRAMAddressPair		<= "000000000000000";
			end if;
			
			VRAMAddressImpair	<= '0' & PrevTileValue & PrevMode7Y & PrevMode7X;
			VRAMRead			<= '1';
		end if;
	end process;

	process(clock)
	begin
		if (clock'event and clock = '1') then 
			PrevMode7X		<= Mode7X(2 downto 0);
			PrevMode7Y		<= Mode7Y(2 downto 0);
			Prev2Mode7Out	<= PrevMode7Out;	-- Pipe 2
			PrevMode7Out	<= Mode7Out;		-- Pipe 1
			PrevTileValue	<= VRAMDataPair;
		end if;
	end process;
	
	-- VRAM Read Result (1 cycle later from adress set)
	dataRead <= VRAMDataImpair & VRAMDataPair;
	
	-- Pipe other values.	
	process(clock, XCondOut, YCondOut)
	begin
		-- Because we know number 1 cycle BEFORE the VRAM read gives the result.
		if (clock'event and clock = '1') then
			regXCondOut <= XCondOut;
			regYCondOut <= YCondOut;
			regNumber	<= number;
			r1Counter	<= stateCounter;
		end if;
	end process;
	
	
	----------------------------------------------------------------
	--- Pipeline 2
	----------------------------------------------------------------
	--
	-- Store read value into register.
	--
	process(clock,
			regNumber,
			dataRead,
			regBG1_BPP01A,
			regBG1_BPP23A,
			regBG1_BPP45A,
			regBG1_BPP67A,
			regBG2_BPP01A,
			regBG2_BPP23A,
			regBG3_BPP01A,
			regBG4_BPP01A,
			regBG1_TileA,
			regBG2_TileA,
			regBG3_TileA,
			regBG4_TileA
			)
	begin
		if (clock'event and clock = '1') then
			--
			-- Bank Swapping FIRST.
			--
			if (r1Counter = "111") then
				--
				-- Can be optimized later on.
				--
				regTileBG3BankHBOffset	<= regBG3_TileA(9 downto 0);
				regTileBG3BankVBOffset	<= regBG3_TileVChar;
				regTileBG3BankHB		<= regBG3_TileA(15 downto 13);
				regTileBG3BankVB		<= regBG3_TileVCond;
				
				regBG1_TileDPrio <= regBG1_TileCPrio;
				regBG2_TileDPrio <= regBG2_TileCPrio;
				regBG3_TileDPrio <= regBG3_TileCPrio;
				regBG4_TileDPrio <= regBG4_TileCPrio;

				regBG1_TileDPal <= regBG1_TileCPal;
				regBG2_TileDPal <= regBG2_TileCPal;
				regBG3_TileDPal <= regBG3_TileCPal;
				regBG4_TileDPal <= regBG4_TileCPal;

				regBG1_TileDFlipH <= regBG1_TileCFlipH;
				regBG2_TileDFlipH <= regBG2_TileCFlipH;
				regBG3_TileDFlipH <= regBG3_TileCFlipH;
				regBG4_TileDFlipH <= regBG4_TileCFlipH;
				
				--
				-- B->C
				--
				regBG1_BPP01C <= regBG1_BPP01B;
				regBG1_BPP23C <= regBG1_BPP23B;
				regBG1_BPP45C <= regBG1_BPP45B;
				regBG1_BPP67C <= regBG1_BPP67B;
				 
				regBG2_BPP01C <= regBG2_BPP01B;
				regBG2_BPP23C <= regBG2_BPP23B;
				regBG3_BPP01C <= regBG3_BPP01B;
				regBG4_BPP01C <= regBG4_BPP01B;
				 
				regBG1_TileCPrio <= regBG1_TileBPrio;
				regBG2_TileCPrio <= regBG2_TileBPrio;
				regBG3_TileCPrio <= regBG3_TileBPrio;
				regBG4_TileCPrio <= regBG4_TileBPrio;

				regBG1_TileCPal <= regBG1_TileBPal;
				regBG2_TileCPal <= regBG2_TileBPal;
				regBG3_TileCPal <= regBG3_TileBPal;
				regBG4_TileCPal <= regBG4_TileBPal;

				regBG1_TileCFlipH <= regBG1_TileBFlipH;
				regBG2_TileCFlipH <= regBG2_TileBFlipH;
				regBG3_TileCFlipH <= regBG3_TileBFlipH;
				regBG4_TileCFlipH <= regBG4_TileBFlipH;
				
				--
				-- A->B
				--
				regBG1_BPP01B <= regBG1_BPP01A;
				regBG1_BPP23B <= regBG1_BPP23A;
				regBG1_BPP45B <= regBG1_BPP45A;
				regBG1_BPP67B <= regBG1_BPP67A;
				 
				regBG2_BPP01B <= regBG2_BPP01A;
				regBG2_BPP23B <= regBG2_BPP23A;
				regBG3_BPP01B <= regBG3_BPP01A;
				regBG4_BPP01B <= regBG4_BPP01A;
				 
				regBG1_TileBPrio <= regBG1_TileA(13);
				regBG2_TileBPrio <= regBG2_TileA(13);
				regBG3_TileBPrio <= regBG3_TileA(13);
				regBG4_TileBPrio <= regBG4_TileA(13);

				regBG1_TileBPal <= regBG1_TileA(12 downto 10);
				regBG2_TileBPal <= regBG2_TileA(12 downto 10);
				regBG3_TileBPal <= regBG3_TileA(12 downto 10);
				regBG4_TileBPal <= regBG4_TileA(12 downto 10);

				regBG1_TileBFlipH <= regBG1_TileA(14);
				regBG2_TileBFlipH <= regBG2_TileA(14);
				regBG3_TileBFlipH <= regBG3_TileA(14);
				regBG4_TileBFlipH <= regBG4_TileA(14);
			end if;
			
			--
			-- Register Loading.
			--
			if (regNumber = CONSTANTS.STR_BG1_TILE) then
				regBG1_TileA	<= dataRead;
				
				regBG1_FlipCond16X	<= regXCondOut;
				regBG1_FlipCond16Y	<= regYCondOut;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG2_TILE) then
				regBG2_TileA	<= dataRead;

				regBG2_FlipCond16X	<= regXCondOut;
				regBG2_FlipCond16Y	<= regYCondOut;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG3_TILE) then -- Include Tile Offset also.
				regBG3_TileA	<= dataRead;

				regBG3_FlipCond16X <= regXCondOut;
				regBG3_FlipCond16Y <= regYCondOut;
			end if;
			
			if (regNumber =	CONSTANTS.STR_BG3V_TILE) then
				regBG3_TileVChar	<= dataRead(9 downto 0);
				regBG3_TileVCond	<= dataRead(14 downto 13);
			end if;
						
			if (regNumber = CONSTANTS.STR_BG4_TILE) then
				regBG4_TileA	<= dataRead;
				regBG4_FlipCond16X <= regXCondOut;
				regBG4_FlipCond16Y <= regYCondOut;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG1_BPP01) then
				regBG1_BPP01A	<= dataRead;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG1_BPP23) then
				regBG1_BPP23A	<= dataRead;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG1_BPP45) then
				regBG1_BPP45A	<= dataRead;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG1_BPP67) then
				regBG1_BPP67A	<= dataRead;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG2_BPP01) then
				regBG2_BPP01A	<= dataRead;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG2_BPP23) then
				regBG2_BPP23A	<= dataRead;
			end if;
		
			if (regNumber = CONSTANTS.STR_BG3_BPP01) then
				regBG3_BPP01A	<= dataRead;
			end if;
			
			if (regNumber = CONSTANTS.STR_BG4_BPP01) then
				regBG4_BPP01A	<= dataRead;
			end if;
		end if;
	end process;
	
	--
	-- TODO : the VALID TILE-OFF bit.
	--
	
	--
	-- Select the correct X in the correct bank.
	--
	-- PROBLEM : when bank switch occur, we can NOT read pixel from the bank until the NEXT cycle.
	-- Must read pixel "7/last pixel" when bank switching occurs. : 001 + 6 -> 7
	pixCycle	<= adrX(2 downto 0);
	-- Adjust to get 0 when bank has switched.  001 + 7 -> 000
	
	-- We read only 3 LSB : dont care about increment register.
	pixOffset1	<= R210D_BG1_HOFS(2 downto 0);
	pixOffset2	<= R210F_BG2_HOFS(2 downto 0);
	pixOffset3	<= R2111_BG3_HOFS(2 downto 0);
	pixOffset4	<= R2113_BG4_HOFS(2 downto 0);
	
	process(pixCycle, pixOffset1, pixOffset2, pixOffset3, pixOffset4)
	begin
		XTileBG1BeforeFlip <= pixOffset1 + pixCycle;
		XTileBG2BeforeFlip <= pixOffset2 + pixCycle;
		XTileBG3BeforeFlip <= pixOffset3 + pixCycle;
		XTileBG4BeforeFlip <= pixOffset4 + pixCycle;

		case pixCycle is
		when "000" =>
			selectX1	<= C_BANK;
			selectX2	<= C_BANK;
			selectX3	<= C_BANK;
			selectX4	<= C_BANK;
			
		when "001" =>
			case pixOffset1 is
			when "000" =>	selectX1 <= C_BANK;
			when "001" =>	selectX1 <= C_BANK;
			when "010" =>	selectX1 <= C_BANK;
			when "011" =>	selectX1 <= C_BANK;
			when "100" =>	selectX1 <= C_BANK;
			when "101" =>	selectX1 <= C_BANK;
			when "110" =>	selectX1 <= C_BANK;
			when others =>	selectX1 <= B_BANK;
			end case;

			case pixOffset2 is
			when "000" =>	selectX2 <= C_BANK;
			when "001" =>	selectX2 <= C_BANK;
			when "010" =>	selectX2 <= C_BANK;
			when "011" =>	selectX2 <= C_BANK;
			when "100" =>	selectX2 <= C_BANK;
			when "101" =>	selectX2 <= C_BANK;
			when "110" =>	selectX2 <= C_BANK;
			when others =>	selectX2 <= B_BANK;
			end case;

			case pixOffset3 is
			when "000" =>	selectX3 <= C_BANK;
			when "001" =>	selectX3 <= C_BANK;
			when "010" =>	selectX3 <= C_BANK;
			when "011" =>	selectX3 <= C_BANK;
			when "100" =>	selectX3 <= C_BANK;
			when "101" =>	selectX3 <= C_BANK;
			when "110" =>	selectX3 <= C_BANK;
			when others =>	selectX3 <= B_BANK;
			end case;

			case pixOffset4 is
			when "000" =>	selectX4 <= C_BANK;
			when "001" =>	selectX4 <= C_BANK;
			when "010" =>	selectX4 <= C_BANK;
			when "011" =>	selectX4 <= C_BANK;
			when "100" =>	selectX4 <= C_BANK;
			when "101" =>	selectX4 <= C_BANK;
			when "110" =>	selectX4 <= C_BANK;
			when others =>	selectX4 <= B_BANK;
			end case;
			
		when "010" =>
			case pixOffset1 is
			when "000" =>	selectX1 <= C_BANK;
			when "001" =>	selectX1 <= C_BANK;
			when "010" =>	selectX1 <= C_BANK;
			when "011" =>	selectX1 <= C_BANK;
			when "100" =>	selectX1 <= C_BANK;
			when "101" =>	selectX1 <= C_BANK;
			when "110" =>	selectX1 <= B_BANK;
			when others =>	selectX1 <= B_BANK;
			end case;

			case pixOffset2 is
			when "000" =>	selectX2 <= C_BANK;
			when "001" =>	selectX2 <= C_BANK;
			when "010" =>	selectX2 <= C_BANK;
			when "011" =>	selectX2 <= C_BANK;
			when "100" =>	selectX2 <= C_BANK;
			when "101" =>	selectX2 <= C_BANK;
			when "110" =>	selectX2 <= B_BANK;
			when others =>	selectX2 <= B_BANK;
			end case;

			case pixOffset3 is
			when "000" =>	selectX3 <= C_BANK;
			when "001" =>	selectX3 <= C_BANK;
			when "010" =>	selectX3 <= C_BANK;
			when "011" =>	selectX3 <= C_BANK;
			when "100" =>	selectX3 <= C_BANK;
			when "101" =>	selectX3 <= C_BANK;
			when "110" =>	selectX3 <= B_BANK;
			when others =>	selectX3 <= B_BANK;
			end case;

			case pixOffset4 is
			when "000" =>	selectX4 <= C_BANK;
			when "001" =>	selectX4 <= C_BANK;
			when "010" =>	selectX4 <= C_BANK;
			when "011" =>	selectX4 <= C_BANK;
			when "100" =>	selectX4 <= C_BANK;
			when "101" =>	selectX4 <= C_BANK;
			when "110" =>	selectX4 <= B_BANK;
			when others =>	selectX4 <= B_BANK;
			end case;
			
		when "011" =>
			case pixOffset1 is
			when "000" =>	selectX1 <= C_BANK;
			when "001" =>	selectX1 <= C_BANK;
			when "010" =>	selectX1 <= C_BANK;
			when "011" =>	selectX1 <= C_BANK;
			when "100" =>	selectX1 <= C_BANK;
			when "101" =>	selectX1 <= B_BANK;
			when "110" =>	selectX1 <= B_BANK;
			when others =>	selectX1 <= B_BANK;
			end case;

			case pixOffset2 is
			when "000" =>	selectX2 <= C_BANK;
			when "001" =>	selectX2 <= C_BANK;
			when "010" =>	selectX2 <= C_BANK;
			when "011" =>	selectX2 <= C_BANK;
			when "100" =>	selectX2 <= C_BANK;
			when "101" =>	selectX2 <= B_BANK;
			when "110" =>	selectX2 <= B_BANK;
			when others =>	selectX2 <= B_BANK;
			end case;

			case pixOffset3 is
			when "000" =>	selectX3 <= C_BANK;
			when "001" =>	selectX3 <= C_BANK;
			when "010" =>	selectX3 <= C_BANK;
			when "011" =>	selectX3 <= C_BANK;
			when "100" =>	selectX3 <= C_BANK;
			when "101" =>	selectX3 <= B_BANK;
			when "110" =>	selectX3 <= B_BANK;
			when others =>	selectX3 <= B_BANK;
			end case;

			case pixOffset4 is
			when "000" =>	selectX4 <= C_BANK;
			when "001" =>	selectX4 <= C_BANK;
			when "010" =>	selectX4 <= C_BANK;
			when "011" =>	selectX4 <= C_BANK;
			when "100" =>	selectX4 <= C_BANK;
			when "101" =>	selectX4 <= B_BANK;
			when "110" =>	selectX4 <= B_BANK;
			when others =>	selectX4 <= B_BANK;
			end case;
			
		when "100" =>
			case pixOffset1 is
			when "000" =>	selectX1 <= C_BANK;
			when "001" =>	selectX1 <= C_BANK;
			when "010" =>	selectX1 <= C_BANK;
			when "011" =>	selectX1 <= C_BANK;
			when "100" =>	selectX1 <= B_BANK;
			when "101" =>	selectX1 <= B_BANK;
			when "110" =>	selectX1 <= B_BANK;
			when others =>	selectX1 <= B_BANK;
			end case;

			case pixOffset2 is
			when "000" =>	selectX2 <= C_BANK;
			when "001" =>	selectX2 <= C_BANK;
			when "010" =>	selectX2 <= C_BANK;
			when "011" =>	selectX2 <= C_BANK;
			when "100" =>	selectX2 <= B_BANK;
			when "101" =>	selectX2 <= B_BANK;
			when "110" =>	selectX2 <= B_BANK;
			when others =>	selectX2 <= B_BANK;
			end case;

			case pixOffset3 is
			when "000" =>	selectX3 <= C_BANK;
			when "001" =>	selectX3 <= C_BANK;
			when "010" =>	selectX3 <= C_BANK;
			when "011" =>	selectX3 <= C_BANK;
			when "100" =>	selectX3 <= B_BANK;
			when "101" =>	selectX3 <= B_BANK;
			when "110" =>	selectX3 <= B_BANK;
			when others =>	selectX3 <= B_BANK;
			end case;

			case pixOffset4 is
			when "000" =>	selectX4 <= C_BANK;
			when "001" =>	selectX4 <= C_BANK;
			when "010" =>	selectX4 <= C_BANK;
			when "011" =>	selectX4 <= C_BANK;
			when "100" =>	selectX4 <= B_BANK;
			when "101" =>	selectX4 <= B_BANK;
			when "110" =>	selectX4 <= B_BANK;
			when others =>	selectX4 <= B_BANK;
			end case;

		when "101" =>
			case pixOffset1 is
			when "000" =>	selectX1 <= C_BANK;
			when "001" =>	selectX1 <= C_BANK;
			when "010" =>	selectX1 <= C_BANK;
			when "011" =>	selectX1 <= B_BANK;
			when "100" =>	selectX1 <= B_BANK;
			when "101" =>	selectX1 <= B_BANK;
			when "110" =>	selectX1 <= B_BANK;
			when others =>	selectX1 <= B_BANK;
			end case;

			case pixOffset2 is
			when "000" =>	selectX2 <= C_BANK;
			when "001" =>	selectX2 <= C_BANK;
			when "010" =>	selectX2 <= C_BANK;
			when "011" =>	selectX2 <= B_BANK;
			when "100" =>	selectX2 <= B_BANK;
			when "101" =>	selectX2 <= B_BANK;
			when "110" =>	selectX2 <= B_BANK;
			when others =>	selectX2 <= B_BANK;
			end case;

			case pixOffset3 is
			when "000" =>	selectX3 <= C_BANK;
			when "001" =>	selectX3 <= C_BANK;
			when "010" =>	selectX3 <= C_BANK;
			when "011" =>	selectX3 <= B_BANK;
			when "100" =>	selectX3 <= B_BANK;
			when "101" =>	selectX3 <= B_BANK;
			when "110" =>	selectX3 <= B_BANK;
			when others =>	selectX3 <= B_BANK;
			end case;

			case pixOffset4 is
			when "000" =>	selectX4 <= C_BANK;
			when "001" =>	selectX4 <= C_BANK;
			when "010" =>	selectX4 <= C_BANK;
			when "011" =>	selectX4 <= B_BANK;
			when "100" =>	selectX4 <= B_BANK;
			when "101" =>	selectX4 <= B_BANK;
			when "110" =>	selectX4 <= B_BANK;
			when others =>	selectX4 <= B_BANK;
			end case;

		when "110" =>
			case pixOffset1 is
			when "000" =>	selectX1 <= C_BANK;
			when "001" =>	selectX1 <= C_BANK;
			when "010" =>	selectX1 <= B_BANK;
			when "011" =>	selectX1 <= B_BANK;
			when "100" =>	selectX1 <= B_BANK;
			when "101" =>	selectX1 <= B_BANK;
			when "110" =>	selectX1 <= B_BANK;
			when others =>	selectX1 <= B_BANK;
			end case;

			case pixOffset2 is
			when "000" =>	selectX2 <= C_BANK;
			when "001" =>	selectX2 <= C_BANK;
			when "010" =>	selectX2 <= B_BANK;
			when "011" =>	selectX2 <= B_BANK;
			when "100" =>	selectX2 <= B_BANK;
			when "101" =>	selectX2 <= B_BANK;
			when "110" =>	selectX2 <= B_BANK;
			when others =>	selectX2 <= B_BANK;
			end case;

			case pixOffset3 is
			when "000" =>	selectX3 <= C_BANK;
			when "001" =>	selectX3 <= C_BANK;
			when "010" =>	selectX3 <= B_BANK;
			when "011" =>	selectX3 <= B_BANK;
			when "100" =>	selectX3 <= B_BANK;
			when "101" =>	selectX3 <= B_BANK;
			when "110" =>	selectX3 <= B_BANK;
			when others =>	selectX3 <= B_BANK;
			end case;

			case pixOffset4 is
			when "000" =>	selectX4 <= C_BANK;
			when "001" =>	selectX4 <= C_BANK;
			when "010" =>	selectX4 <= B_BANK;
			when "011" =>	selectX4 <= B_BANK;
			when "100" =>	selectX4 <= B_BANK;
			when "101" =>	selectX4 <= B_BANK;
			when "110" =>	selectX4 <= B_BANK;
			when others =>	selectX4 <= B_BANK;
			end case;

		when others =>
			case pixOffset1 is
			when "000" =>	selectX1 <= C_BANK;
			when "001" =>	selectX1 <= B_BANK;
			when "010" =>	selectX1 <= B_BANK;
			when "011" =>	selectX1 <= B_BANK;
			when "100" =>	selectX1 <= B_BANK;
			when "101" =>	selectX1 <= B_BANK;
			when "110" =>	selectX1 <= B_BANK;
			when others =>	selectX1 <= B_BANK;
			end case;

			case pixOffset2 is
			when "000" =>	selectX2 <= C_BANK;
			when "001" =>	selectX2 <= B_BANK;
			when "010" =>	selectX2 <= B_BANK;
			when "011" =>	selectX2 <= B_BANK;
			when "100" =>	selectX2 <= B_BANK;
			when "101" =>	selectX2 <= B_BANK;
			when "110" =>	selectX2 <= B_BANK;
			when others =>	selectX2 <= B_BANK;
			end case;

			case pixOffset3 is
			when "000" =>	selectX3 <= C_BANK;
			when "001" =>	selectX3 <= B_BANK;
			when "010" =>	selectX3 <= B_BANK;
			when "011" =>	selectX3 <= B_BANK;
			when "100" =>	selectX3 <= B_BANK;
			when "101" =>	selectX3 <= B_BANK;
			when "110" =>	selectX3 <= B_BANK;
			when others =>	selectX3 <= B_BANK;
			end case;

			case pixOffset4 is
			when "000" =>	selectX4 <= C_BANK;
			when "001" =>	selectX4 <= B_BANK;
			when "010" =>	selectX4 <= B_BANK;
			when "011" =>	selectX4 <= B_BANK;
			when "100" =>	selectX4 <= B_BANK;
			when "101" =>	selectX4 <= B_BANK;
			when "110" =>	selectX4 <= B_BANK;
			when others =>	selectX4 <= B_BANK;
			end case;
		end case;
	end process;
	
	process(R2105_BGMode)
	begin
		case R2105_BGMode is
		when CONSTANTS.MODE0 =>
			BSel <= "0000";			-- TODO.
		when CONSTANTS.MODE1 =>
			BSel <= "0100";			-- DONE.
		when CONSTANTS.MODE2 =>
			BSel <= "0000";			-- TODO.
		when CONSTANTS.MODE3 =>
			BSel <= "0000";			-- TODO.
		when CONSTANTS.MODE4 =>
			BSel <= "0000";			-- TODO.
		when CONSTANTS.MODE5 =>
			BSel <= "0000";			-- TODO.
		when CONSTANTS.MODE6 =>
			BSel <= "0000";			-- TODO.
		when others =>
			BSel <= "0000";			-- Who cares.
		end case;
	end process;
		
	--
	-- Select the correct offset register, base adress tile, base adress char.
	--
	process(-- BG 1 Internal registers.
			regBG1_BPP01C,regBG1_BPP23C,regBG1_BPP45C,regBG1_BPP67C,
			regBG1_TileCPrio,regBG1_TileCPal,regBG1_TileCFlipH,
			regBG1_BPP01B,regBG1_BPP23B,regBG1_BPP45B,regBG1_BPP67B,
			regBG1_TileBPrio,regBG1_TileBPal,regBG1_TileBFlipH,
			-- BG 2 Internal registers.
			regBG2_BPP01C,regBG2_BPP23C,
			regBG2_TileCPrio,regBG2_TileCPal,regBG2_TileCFlipH,
			regBG2_BPP01B,regBG2_BPP23B,
			regBG2_TileBPrio,regBG2_TileBPal,regBG2_TileBFlipH,
			-- BG 3 Internal registers.
			regBG3_BPP01C,
			regBG3_TileCPrio,regBG3_TileCPal,regBG3_TileCFlipH,
			regBG3_BPP01B,
			regBG3_TileBPrio,regBG3_TileBPal,regBG3_TileBFlipH,
			-- BG 4 Internal registers.
			regBG4_BPP01C,
			regBG4_TileCPrio,regBG4_TileCPal,regBG4_TileCFlipH,
			regBG4_BPP01B,
			regBG4_TileBPrio,regBG4_TileBPal,regBG4_TileBFlipH,
			
			selectX1,
			selectX2,
			selectX3,
			selectX4,
			BSel
			)
	begin
		---
		--- Stage 1 : Select left or right data.
		---
		if (selectX1 = C_BANK) then
			BG1BPP01 <= regBG1_BPP01C;
			BG1BPP23 <= regBG1_BPP23C;
			BG1BPP45 <= regBG1_BPP45C;
			BG1BPP67 <= regBG1_BPP67C;
			if (BSel(0) = '0') then
				BG1TILEFLIPH <= regBG1_TileCFlipH;
				BG1TILEPRIO  <= regBG1_TileCPrio;
				BG1TILEPAL   <= regBG1_TileCPal;
			else
				BG1TILEFLIPH <= regBG1_TileDFlipH;
				BG1TILEPRIO  <= regBG1_TileDPrio;
				BG1TILEPAL   <= regBG1_TileDPal;
			end if;
		else
			BG1BPP01 <= regBG1_BPP01B;
			BG1BPP23 <= regBG1_BPP23B;
			BG1BPP45 <= regBG1_BPP45B;
			BG1BPP67 <= regBG1_BPP67B;
			if (BSel(0) = '0') then
				BG1TILEFLIPH <= regBG1_TileBFlipH;
				BG1TILEPRIO  <= regBG1_TileBPrio;
				BG1TILEPAL   <= regBG1_TileBPal;
			else
				BG1TILEFLIPH <= regBG1_TileCFlipH;
				BG1TILEPRIO  <= regBG1_TileCPrio;
				BG1TILEPAL   <= regBG1_TileCPal;
			end if;
		end if;

		if (selectX2 = C_BANK) then
			BG2BPP01 <= regBG2_BPP01C;
			BG2BPP23 <= regBG2_BPP23C;
			BG2TILEFLIPH <= regBG2_TileCFlipH;
			BG2TILEPRIO  <= regBG2_TileCPrio;
			BG2TILEPAL   <= regBG2_TileCPal;
			if (BSel(1) = '0') then
				BG2TILEFLIPH <= regBG2_TileCFlipH;
				BG2TILEPRIO  <= regBG2_TileCPrio;
				BG2TILEPAL   <= regBG2_TileCPal;
			else
				BG2TILEFLIPH <= regBG2_TileDFlipH;
				BG2TILEPRIO  <= regBG2_TileDPrio;
				BG2TILEPAL   <= regBG2_TileDPal;
			end if;
		else           
			BG2BPP01 <= regBG2_BPP01B;
			BG2BPP23 <= regBG2_BPP23B;
			if (BSel(1) = '0') then
				BG2TILEFLIPH <= regBG2_TileBFlipH;
				BG2TILEPRIO  <= regBG2_TileBPrio;
				BG2TILEPAL   <= regBG2_TileBPal;
			else
				BG2TILEFLIPH <= regBG2_TileCFlipH;
				BG2TILEPRIO  <= regBG2_TileCPrio;
				BG2TILEPAL   <= regBG2_TileCPal;
			end if;
		end if;
		
		if (selectX3 = C_BANK) then
			BG3BPP01 <= regBG3_BPP01C;
			BG3TILEFLIPH <= regBG3_TileDFlipH;
			if (BSel(2) = '0') then
				BG3TILEFLIPH <= regBG3_TileCFlipH;
				BG3TILEPRIO  <= regBG3_TileCPrio;
				BG3TILEPAL   <= regBG3_TileCPal;
			else
				BG3TILEFLIPH <= regBG3_TileDFlipH;
				BG3TILEPRIO  <= regBG3_TileDPrio;
				BG3TILEPAL   <= regBG3_TileDPal;
			end if;
		else
			BG3BPP01 <= regBG3_BPP01B;
			BG3TILEFLIPH <= regBG3_TileCFlipH;
			if (BSel(2) = '0') then
				BG3TILEFLIPH <= regBG3_TileBFlipH;
				BG3TILEPRIO  <= regBG3_TileBPrio;
				BG3TILEPAL   <= regBG3_TileBPal;
			else
				BG3TILEFLIPH <= regBG3_TileCFlipH;
				BG3TILEPRIO  <= regBG3_TileCPrio;
				BG3TILEPAL   <= regBG3_TileCPal;
			end if;
		end if;

		if (selectX4 = C_BANK) then
			BG4BPP01 <= regBG4_BPP01C;
			BG4TILEFLIPH <= regBG4_TileDFlipH;
			if (BSel(3) = '0') then
				BG4TILEFLIPH <= regBG4_TileCFlipH;
				BG4TILEPRIO  <= regBG4_TileCPrio;
				BG4TILEPAL   <= regBG4_TileCPal;
			else
				BG4TILEFLIPH <= regBG4_TileDFlipH;
				BG4TILEPRIO  <= regBG4_TileDPrio;
				BG4TILEPAL   <= regBG4_TileDPal;
			end if;
		else           
			BG4BPP01 <= regBG4_BPP01B;
			BG4TILEFLIPH <= regBG4_TileCFlipH;
			if (BSel(3) = '0') then
				BG4TILEFLIPH <= regBG4_TileBFlipH;
				BG4TILEPRIO  <= regBG4_TileBPrio;
				BG4TILEPAL   <= regBG4_TileBPal;
			else
				BG4TILEFLIPH <= regBG4_TileCFlipH;
				BG4TILEPRIO  <= regBG4_TileCPrio;
				BG4TILEPAL   <= regBG4_TileCPal;
			end if;
		end if;
--		---
--		--- Stage 1 : Select left or right data.
--		---
--		if (selectX1 = C_BANK) then
--			BG1BPP01 <= regBG1_BPP01C;
--			BG1BPP23 <= regBG1_BPP23C;
--			BG1BPP45 <= regBG1_BPP45C;
--			BG1BPP67 <= regBG1_BPP67C;
--			BG1TILEFLIPH <= regBG1_TileCFlipH;
--			BG1TILEPRIO  <= regBG1_TileCPrio;
--			BG1TILEPAL   <= regBG1_TileCPal;
--		else
--			BG1BPP01 <= regBG1_BPP01B;
--			BG1BPP23 <= regBG1_BPP23B;
--			BG1BPP45 <= regBG1_BPP45B;
--			BG1BPP67 <= regBG1_BPP67B;
--			BG1TILEFLIPH <= regBG1_TileBFlipH;
--			BG1TILEPRIO  <= regBG1_TileBPrio;
--			BG1TILEPAL   <= regBG1_TileBPal;
--		end if;
--
--		if (selectX2 = C_BANK) then
--			BG2BPP01 <= regBG2_BPP01C;
--			BG2BPP23 <= regBG2_BPP23C;
--			BG2TILEFLIPH <= regBG2_TileCFlipH;
--			BG2TILEPRIO  <= regBG2_TileCPrio;
--			BG2TILEPAL   <= regBG2_TileCPal;
--		else           
--			BG2BPP01 <= regBG2_BPP01B;
--			BG2BPP23 <= regBG2_BPP23B;
--			BG2TILEFLIPH <= regBG2_TileBFlipH;
--			BG2TILEPRIO  <= regBG2_TileBPrio;
--			BG2TILEPAL   <= regBG2_TileBPal;
--		end if;
--		
--		if (selectX3 = C_BANK) then
--			BG3BPP01 <= regBG3_BPP01C;
--			BG3TILEFLIPH <= regBG3_TileCFlipH;
--			BG3TILEPRIO  <= regBG3_TileCPrio;
--			BG3TILEPAL   <= regBG3_TileCPal;
--		else
--			BG3BPP01 <= regBG3_BPP01B;
--			BG3TILEFLIPH <= regBG3_TileBFlipH;
--			BG3TILEPRIO  <= regBG3_TileBPrio;
--			BG3TILEPAL   <= regBG3_TileBPal;
--		end if;
--
--		if (selectX4 = C_BANK) then
--			BG4BPP01 <= regBG4_BPP01C;
--			BG4TILEFLIPH <= regBG4_TileCFlipH;
--			BG4TILEPRIO  <= regBG4_TileCPrio;
--			BG4TILEPAL   <= regBG4_TileCPal;
--		else           
--			BG4BPP01 <= regBG4_BPP01B;
--			BG4TILEFLIPH <= regBG4_TileBFlipH;
--			BG4TILEPRIO  <= regBG4_TileBPrio;
--			BG4TILEPAL   <= regBG4_TileBPal;
--		end if;
	end process;
	
	--
	-- Select correct Pixel in tile
	--
	process(BG1TILEFLIPH, BG2TILEFLIPH, BG3TILEFLIPH, BG4TILEFLIPH,
			XTileBG1BeforeFlip,
			XTileBG2BeforeFlip,
			XTileBG3BeforeFlip,
			XTileBG4BeforeFlip
			)
		variable flipH1, flipH2, flipH3, flipH4 : STD_LOGIC;
	begin
		flipH1			:= BG1TILEFLIPH;
		flipH2			:= BG2TILEFLIPH;
		flipH3			:= BG3TILEFLIPH;
		flipH4			:= BG4TILEFLIPH;
		
		-- We do a trick here :
		-- When flip is TRUE, we do as FALSE : we read bit 0 for pixel 0 later on.
		-- where we should read bit 7.
		--
		if (flipH1='1') then
			XTileBG1 <=     XTileBG1BeforeFlip;
		else
			XTileBG1 <= not(XTileBG1BeforeFlip);
		end if;

		if (flipH2='1') then
			XTileBG2 <=     XTileBG2BeforeFlip;
		else
			XTileBG2 <= not(XTileBG2BeforeFlip);
		end if;

		if (flipH3='1') then
			XTileBG3 <=     XTileBG3BeforeFlip;
		else
			XTileBG3 <= not(XTileBG3BeforeFlip);
		end if;

		if (flipH4='1') then
			XTileBG4 <=     XTileBG4BeforeFlip;
		else
			XTileBG4 <= not(XTileBG4BeforeFlip);
		end if;
	end process;
	
	--
	-- Get the correct pixels and fit into 28 bit array.
	--
	process(	Mode7,
				VramDataImpair,
				Prev2Mode7Out,
				R211A_M7_REPEAT,
				R211A_M7_FILL,
				XTileBG1,
				XTileBG2,
				XTileBG3,
				XTileBG4,
				BG1BPP01,
				BG1BPP23,
				BG1BPP45,
				BG1BPP67,
				BG2BPP01,
				BG2BPP23,
				BG3BPP01,
				BG4BPP01,
				BG1TILEPAL,
				BG2TILEPAL,
				BG3TILEPAL,
				BG4TILEPAL,
				BG1TILEPRIO,
				BG2TILEPRIO,
				BG3TILEPRIO,
				BG4TILEPRIO
				)
	begin
		palPrioBlock <= BG4TILEPAL  & BG3TILEPAL  & BG2TILEPAL  & BG1TILEPAL
									& BG4TILEPRIO & BG3TILEPRIO & BG2TILEPRIO & BG1TILEPRIO;

		if (Mode7 = '0') then
			case XTileBG1 is
			when "000"  => BG1Pix <= BG1BPP67( 8) & BG1BPP67(0) & BG1BPP45( 8) & BG1BPP45(0) & BG1BPP23( 8) & BG1BPP23(0) & BG1BPP01( 8) & BG1BPP01(0);
			when "001"  => BG1Pix <= BG1BPP67( 9) & BG1BPP67(1) & BG1BPP45( 9) & BG1BPP45(1) & BG1BPP23( 9) & BG1BPP23(1) & BG1BPP01( 9) & BG1BPP01(1);
			when "010"  => BG1Pix <= BG1BPP67(10) & BG1BPP67(2) & BG1BPP45(10) & BG1BPP45(2) & BG1BPP23(10) & BG1BPP23(2) & BG1BPP01(10) & BG1BPP01(2);
			when "011"  => BG1Pix <= BG1BPP67(11) & BG1BPP67(3) & BG1BPP45(11) & BG1BPP45(3) & BG1BPP23(11) & BG1BPP23(3) & BG1BPP01(11) & BG1BPP01(3);
			when "100"  => BG1Pix <= BG1BPP67(12) & BG1BPP67(4) & BG1BPP45(12) & BG1BPP45(4) & BG1BPP23(12) & BG1BPP23(4) & BG1BPP01(12) & BG1BPP01(4);
			when "101"  => BG1Pix <= BG1BPP67(13) & BG1BPP67(5) & BG1BPP45(13) & BG1BPP45(5) & BG1BPP23(13) & BG1BPP23(5) & BG1BPP01(13) & BG1BPP01(5);
			when "110"  => BG1Pix <= BG1BPP67(14) & BG1BPP67(6) & BG1BPP45(14) & BG1BPP45(6) & BG1BPP23(14) & BG1BPP23(6) & BG1BPP01(14) & BG1BPP01(6);
			when others => BG1Pix <= BG1BPP67(15) & BG1BPP67(7) & BG1BPP45(15) & BG1BPP45(7) & BG1BPP23(15) & BG1BPP23(7) & BG1BPP01(15) & BG1BPP01(7);
			end case;
		else
			if (Prev2Mode7Out='1' and R211A_M7_REPEAT='1' and R211A_M7_FILL='0') then
				BG1Pix <= "00000000";
			else
				BG1Pix <= VRAMDataImpair;
			end if;
		end if;

		case XTileBG2 is
		when "000"  => BG2Pix <= BG2BPP23( 8) & BG2BPP23(0) & BG2BPP01( 8) & BG2BPP01(0);
		when "001"  => BG2Pix <= BG2BPP23( 9) & BG2BPP23(1) & BG2BPP01( 9) & BG2BPP01(1);
		when "010"  => BG2Pix <= BG2BPP23(10) & BG2BPP23(2) & BG2BPP01(10) & BG2BPP01(2);
		when "011"  => BG2Pix <= BG2BPP23(11) & BG2BPP23(3) & BG2BPP01(11) & BG2BPP01(3);
		when "100"  => BG2Pix <= BG2BPP23(12) & BG2BPP23(4) & BG2BPP01(12) & BG2BPP01(4);
		when "101"  => BG2Pix <= BG2BPP23(13) & BG2BPP23(5) & BG2BPP01(13) & BG2BPP01(5);
		when "110"  => BG2Pix <= BG2BPP23(14) & BG2BPP23(6) & BG2BPP01(14) & BG2BPP01(6);
		when others => BG2Pix <= BG2BPP23(15) & BG2BPP23(7) & BG2BPP01(15) & BG2BPP01(7);
		end case;

		case XTileBG3 is
		when "000"  => BG3Pix <= BG3BPP01( 8) & BG3BPP01(0);
		when "001"  => BG3Pix <= BG3BPP01( 9) & BG3BPP01(1);
		when "010"  => BG3Pix <= BG3BPP01(10) & BG3BPP01(2);
		when "011"  => BG3Pix <= BG3BPP01(11) & BG3BPP01(3);
		when "100"  => BG3Pix <= BG3BPP01(12) & BG3BPP01(4);
		when "101"  => BG3Pix <= BG3BPP01(13) & BG3BPP01(5);
		when "110"  => BG3Pix <= BG3BPP01(14) & BG3BPP01(6);
		when others => BG3Pix <= BG3BPP01(15) & BG3BPP01(7);
		end case;
		
		case XTileBG4 is
		when "000"  => BG4Pix <= BG4BPP01( 8) & BG4BPP01(0);
		when "001"  => BG4Pix <= BG4BPP01( 9) & BG4BPP01(1);
		when "010"  => BG4Pix <= BG4BPP01(10) & BG4BPP01(2);
		when "011"  => BG4Pix <= BG4BPP01(11) & BG4BPP01(3);
		when "100"  => BG4Pix <= BG4BPP01(12) & BG4BPP01(4);
		when "101"  => BG4Pix <= BG4BPP01(13) & BG4BPP01(5);
		when "110"  => BG4Pix <= BG4BPP01(14) & BG4BPP01(6);
		when others => BG4Pix <= BG4BPP01(15) & BG4BPP01(7);
		end case;
	end process;
	
	--
	-- Mosaic Register Pipe (on X axis)
	--
	process(	clock,
				ScreenX_NonMosaic,
				R2105_BGMode,
				R2106_BGMosaicEnable,
				MosaicXSig,
				BG1Pix,
				BG2Pix,
				BG3Pix,
				BG4Pix)
	begin
--		if (clock'event and clock = '1') then
--case ScreenY_NonMosaic(6 downto 5) is
--when "00" =>
--
-- Normal BG Stuff.
--

--			if (MosaicXSig = '1' or R2106_BGMosaicEnable(3)='0') then
				regBG4Pix			<= BG4Pix;
				regPalPrioBlock(3)	<= palPrioBlock(3); -- Prio BG 4.
				regPalPrioBlock(15 downto 13)	<= palPrioBlock(15 downto 13); -- Pag BG 4.
--			end if;
			
--			if (MosaicXSig = '1' or R2106_BGMosaicEnable(2)='0') then
				regBG3Pix			<= BG3Pix;
				regPalPrioBlock(2)	<= palPrioBlock(2); -- Prio BG 3.
				regPalPrioBlock(12 downto 10)	<= palPrioBlock(12 downto 10); -- Pal BG 3.
--			end if;
			
--			if (MosaicXSig = '1' or R2106_BGMosaicEnable(1)='0') then
				regBG2Pix			<= BG2Pix;
				regPalPrioBlock(1)	<= palPrioBlock(1); -- Prio BG 2.
				regPalPrioBlock(9 downto 7)	<= palPrioBlock(9 downto 7); -- Pal BG 2.
--			end if;

--			if (MosaicXSig = '1' or R2106_BGMosaicEnable(0)='0') then
				regBG1Pix			<= BG1Pix;
				regPalPrioBlock(0)	<= palPrioBlock(0); -- Prio BG 1.
				regPalPrioBlock(6 downto 4)	<= palPrioBlock(6 downto 4); -- Pal BG 1.
--			end if;
--when "01" =>
--
-- State Counter.
--
--regBG4Pix <= "00";
--regBG3Pix <= "00";
--regBG2Pix <= r1Counter & '0';
--regBG1Pix <= "00000000";
--regPalPrioBlock(15 downto 0)	<= "0000000000000000";
--
--when "10" =>
----
---- Reg Storage
----
--regBG4Pix <= "00";
--regBG3Pix <= "00";
--regBG2Pix <= regNumber;
--regBG1Pix <= "00000000";
--regPalPrioBlock(15 downto 0)	<= "0000000000000000";
--
--when others =>
----
---- Bank Select
----
--regBG4Pix <= "00";
--regBG3Pix <= "00";
--regBG2Pix <= sVRAMAddressPair(3 downto 0);
--regBG1Pix <= "00000000";
--regPalPrioBlock(15 downto 0)	<= "0000000000000000";
--end case;
--
--		end if;
	end process;
	
	process(	ScreenX_NonMosaic,
				R2105_BGMode,
				mode7,
				regPalPrioBlock,
				regBG1Pix,
				regBG2Pix,
				regBG3Pix,
				regBG4Pix
			)
		variable tmpFuckX_ShitVHDL_Fuckinglanguage_stupid_simulation : STD_LOGIC_VECTOR(11 downto 0);
	begin
		if (mode7 = '0') then
			-- 
			-- Palette & Priorities
			--
			LineCacheData(15 downto 0) <= regPalPrioBlock;

			case R2105_BGMode is
			when CONSTANTS.MODE0  =>
			-- 0 : 44xx 1133 xx22
				LineCacheData(27 downto 16) <= regBG4Pix & "00" & regBG1Pix(1 downto 0) & regBG3Pix & "00" & regBG2Pix(1 downto 0);
			when CONSTANTS.MODE1  =>
			-- 1 : xx11 1133 2222
				LineCacheData(27 downto 16) <= "00" & regBG1Pix(3 downto 0) & regBG3Pix & regBG2Pix;
			when CONSTANTS.MODE2  =>
			-- 2 : xx11 11xx 2222
				LineCacheData(27 downto 16) <= "00" & regBG1Pix(3 downto 0) & "00" & regBG2Pix;
			when CONSTANTS.MODE3  =>
			-- 3 : 1111 1111 2222 <- 8 bit mode is encoded as [76321054]
				LineCacheData(27 downto 16) <= regBG1Pix(7 downto 6) & regBG1Pix(3 downto 0) & regBG1Pix(5 downto 4) & regBG2Pix;
			when CONSTANTS.MODE4  =>
			-- 4 : 1111 1111 xx22 <- 8 bit mode is encoded as [76321054]
				LineCacheData(27 downto 16) <= regBG1Pix(7 downto 6) & regBG1Pix(3 downto 0) & regBG1Pix(5 downto 4) & "00" & regBG2Pix(1 downto 0);
			when CONSTANTS.MODE5  =>
			-- 5 : xx11 11xx xx22 <- 
				LineCacheData(27 downto 16) <= "00" & regBG1Pix(3 downto 0) & "0000" & regBG2Pix(1 downto 0);
			when CONSTANTS.MODE6  =>
			-- 6 : xx11 11xx xxxx
				LineCacheData(27 downto 16) <= "00" & regBG1Pix(3 downto 0) & "000000";
			when others =>
			-- 7 : 1111 1111 xxxx			
				LineCacheData(27 downto 16) <= regBG1Pix(7 downto 6) & regBG1Pix(3 downto 0) & regBG1Pix(5 downto 4) & "0000";
			end case;

			tmpFuckX_ShitVHDL_Fuckinglanguage_stupid_simulation := XCounter + CONSTANTS.OFFSETX_TO0; -- +494 => 0 when X = 17 + 1(Pipe mosaic)
		else
			LineCacheData(15 downto 0)	<= "0000000000000000"; -- No palette, prio is handled in BGLineDecoded directly.
			LineCacheData(27 downto 16) <= regBG1Pix(7 downto 6) & regBG1Pix(3 downto 0) & regBG1Pix(5 downto 4) & "0000";
			tmpFuckX_ShitVHDL_Fuckinglanguage_stupid_simulation := XCounter + CONSTANTS.OFFSETXMODE7_TO0; -- +509 => 0 when X = 2 + 1(Pipe mosaic + Read Mode 7 start) 
		end if;

		adrX			 			<= tmpFuckX_ShitVHDL_Fuckinglanguage_stupid_simulation(8 downto 0);

		if ((adrX>=0) and (adrX<=255)) then
			WriteS			 <= '1';
		else
			WriteS			 <= '0';
		end if;
		LineCacheAddress 			<= adrX(7 downto 0);
	end process;
end PPU_PixelFetch;
