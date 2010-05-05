----------------------------------------------------------------------------------
-- Create Date:   		
-- Design Name:		
-- Module Name:		
-- Description:		
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_SpriteLoader is
    Port (
		clock				: in	STD_LOGIC;
		OBJInterlace		: in	STD_LOGIC;

		YNonMosaic			: in	STD_LOGIC_VECTOR(8 downto 0);
		
		R2101_OAMBaseSize	: in	STD_LOGIC_VECTOR (2 downto 0); 
		R2101_OAMNameSelect	: in	STD_LOGIC_VECTOR (1 downto 0);
		R2101_OAMNameBase	: in	STD_LOGIC_VECTOR (2 downto 0);

		-- ##############################################################
		--   OAM Read / Write from CPU.
		-- ##############################################################
		Address 			: in	STD_LOGIC_VECTOR(10 downto 0);
		CPUwrite			: in	STD_LOGIC;
		DataIn	  			: in	STD_LOGIC_VECTOR( 7 downto 0);
		DataOut	  			: out	STD_LOGIC_VECTOR( 7 downto 0);

		-- ##############################################################
		--   Line base system & Memory access.
		-- ##############################################################
		startLine			: in	STD_LOGIC;
		startIndex			: in	STD_LOGIC_VECTOR( 6 downto 0);
		VRAMAdress			: out	STD_LOGIC_VECTOR(14 downto 0);
		VRAMDataIn			: in	STD_LOGIC_VECTOR(15 downto 0);
		
		-- ##############################################################
		--   Storage adress of read result into sprite unit.
		-- ##############################################################
		tileNumber			: out	STD_LOGIC_VECTOR( 5 downto 0);	-- 0..33
		store				: out	STD_LOGIC_VECTOR(15 downto 0);
		asBPP23				: out	STD_LOGIC;
		pal					: out	STD_LOGIC_VECTOR( 2 downto 0);
		prio				: out	STD_LOGIC_VECTOR( 1 downto 0);
		XStart				: out	STD_LOGIC_VECTOR( 8 downto 0);
		
		endVSync			: in	STD_LOGIC;
		R213E_TimeOver		: out	STD_LOGIC;
		R213E_RangeOver		: out	STD_LOGIC
	);
end PPU_SpriteLoader;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture APPU_SpriteLoader of PPU_SpriteLoader is
	type STATE_TYPE	is (
		WAIT_START,
		SPRITE_SETUP,
		SPRITE_LOADBPP0,
		SPRITE_LOADBPP1,
		ENDLOADING
	);
	
	component PPU_SpriteInside is
		Port (
			ScrY		: in STD_LOGIC_VECTOR(7 downto 0); -- TODO Interlace : how Y is used ? Buggy for now
			Interlace	: in STD_LOGIC;
			
			X			: in STD_LOGIC_VECTOR(8 downto 0);
			Y			: in STD_LOGIC_VECTOR(7 downto 0);
			sprTileW	: in STD_LOGIC_VECTOR(3 downto 0);
			sprTileH	: in STD_LOGIC_VECTOR(3 downto 0);

			inside		: out STD_LOGIC
		);
	end component;
	
	component PPU_OAMRAM is
		Port (
			clock : in STD_LOGIC;
			write : in STD_LOGIC;
			
			-- CPU / Register side.
			-- TODO : make sure that CPU side understand it is a BYTE and not a WORD adress.
			AdressReadWrite		: in STD_LOGIC_VECTOR(9 downto 0);
			DataIn				: in STD_LOGIC_VECTOR(7 downto 0);
			DataOut				: out STD_LOGIC_VECTOR(7 downto 0);

			-- Sprite Side
			SpriteNumber		: in STD_LOGIC_VECTOR(6 downto 0);
			X					: out STD_LOGIC_VECTOR(8 downto 0);
			Y					: out STD_LOGIC_VECTOR(7 downto 0);
			Char				: out STD_LOGIC_VECTOR(7 downto 0);
			NameTable			: out STD_LOGIC;
			FlipH				: out STD_LOGIC;
			FlipV				: out STD_LOGIC;
			Priority			: out STD_LOGIC_VECTOR(1 downto 0);
			Palette				: out STD_LOGIC_VECTOR(2 downto 0);
			Size				: out STD_LOGIC
		);
	end component;
	
	signal currState, nextState	: STATE_TYPE;
	
	constant SAMESPR	: STD_LOGIC_VECTOR := "00";
	constant NEXTSPR	: STD_LOGIC_VECTOR := "01";
	constant LOADSPR	: STD_LOGIC_VECTOR := "10";
	constant NEXTTILE	: STD_LOGIC_VECTOR := "11";
	
	signal mgtSpriteCounter	: STD_LOGIC_VECTOR(1 downto 0);
	signal loadBPP			: STD_LOGIC_VECTOR(1 downto 0);
	signal sprCounterOffset,
		   sprCounterOffsetNext : STD_LOGIC_VECTOR(7 downto 0); -- 8 Bit to detect 128 reach.
	signal sprCounterLine	: STD_LOGIC_VECTOR(5 downto 0);
	signal totalTileCounter : STD_LOGIC_VECTOR(5 downto 0);
	signal reach35			: STD_LOGIC;
	signal SpriteNum		: STD_LOGIC_VECTOR(6 downto 0);
	
	signal regR213E_TimeOver,regR213E_RangeOver	: STD_LOGIC;	
	signal spriteWidthTile,spriteHeighTile,sprTileCounter	: STD_LOGIC_VECTOR(3 downto 0);
	signal isInside,isTileOutside	: STD_LOGIC;
	signal bppIn		: STD_LOGIC_VECTOR(15 downto 0);
	
	signal sSize		: STD_LOGIC;
	signal sXStart		: STD_LOGIC_VECTOR(8 downto 0);
	signal sYStart		: STD_LOGIC_VECTOR(7 downto 0);
begin

	--##########################################################################
	--  Loader State Machine
	--##########################################################################
	
	--
	-- State Clocking.
	--
	process(clock, nextState)
	begin
		if (clock'event and clock = '1') then 
			currState <= nextState;
		end if;
	end process;
	
	process(currState)
	begin
		case currState is
		--
		-- Wait until the line start.
		--
		when WAIT_START			=>
			loadBPP				<= "00";	-- Dont care.
			mgtSpriteCounter	<= LOADSPR;	-- Load
			if (startLine = '0') then
				nextState <= SPRITE_SETUP;
			else
				nextState <= WAIT_START;
			end if;
			
		--
		-- Setup the current sprite :
		-- - Is 34 tiles fully loaded ?
		-- - Is list completly parsed ? counter = 128 sprites)
		-- - Reached 32 sprites ?
		-- ==> Quit
		--
		-- If current sprite is on current line : LOAD
		-- else go to the next sprite.
		--
		-- We also reset the tile counter for the current sprite.
		--
		when SPRITE_SETUP		=>
			loadBPP				<= "01";	-- Preload BPP0 as the sprite is already loaded
			if (sprCounterOffset(7) = '1' or reach35='1' or sprCounterLine(5)='1') then
				mgtSpriteCounter	<= SAMESPR;
				nextState			<= ENDLOADING;
			else
				if (isInside='1' and (sprTileCounter /= spriteWidthTile)) then
					if (isTileOutside='1') then
						mgtSpriteCounter	<= NEXTTILE;
						nextState			<= SPRITE_SETUP;
					else
						mgtSpriteCounter	<= SAMESPR;
						nextState			<= SPRITE_LOADBPP0;
					end if;
				else
					mgtSpriteCounter	<= NEXTSPR;
					nextState			<= SPRITE_SETUP;
				end if;
			end if;

		--
		-- Load Bitplan 01
		--
		when SPRITE_LOADBPP0	=>
			loadBPP				<= "10"; -- Start load of BPP23 for the next cycle.
			nextState			<= SPRITE_LOADBPP1;
			mgtSpriteCounter	<= SAMESPR;
			
		--
		-- Load Bitplan 23 and go to the next tile.
		--
		when SPRITE_LOADBPP1	=>
			loadBPP				<= "00";
			nextState			<= SPRITE_SETUP;
			mgtSpriteCounter	<= NEXTTILE;
			
		--
		-- Line finished, wait until next line.
		--
		when ENDLOADING			=>
			loadBPP				<= "00";	-- Dont care.
			mgtSpriteCounter	<= SAMESPR;	-- Dont care.
			
			if (startLine='0') then
				nextState <= ENDLOADING;
			else
				nextState <= WAIT_START;
			end if;
			
		when others				=>
			loadBPP				<= "00";	-- Dont care.
			mgtSpriteCounter	<= SAMESPR;	-- Dont care.
			nextState			<= WAIT_START;
		end case;
	end process;

	--##########################################################################
	--  Internal operation of sprite loader.
	--##########################################################################
	
	--
	-- OAM STORAGE.
	--
	OAMMemory : PPU_OAMRAM
	Port map (
		clock				=> clock,
		write				=> CPUWrite,
		
		-- CPU / Register side.
		-- TODO : make sure that CPU side understand it is a BYTE and not a WORD adress.
		AdressReadWrite		=> ???, -- "Address" but need conversion.
		DataIn				=> DataIn,
		DataOut				=> DataOut,
		
		-- Sprite Side
		SpriteNumber		=> SpriteNum,
		X					=> sXStart,
		Y					=> sYStart,
		Char				=> sChar,
		NameTable			=> sName,
		FlipH				=> flipH,
		FlipV				=> flipV,
		Priority			=> sPrio,
		Palette				=> sPal,
		Size				=> sSize
	);

	--
	-- Maintain all counters for current sprite and complete line.
	--
	process(clock, mgtSpriteCounter, isInside)
	begin
		if rising_edge(clock) then
			if (currState = SPRITE_SETUP) then
				if (isInside = '1') then
					sprCounterLine <= sprCounterLine + 1;
				end if;
			end if;
			
			if (mgtSpriteCounter = NEXTSPR) then
				sprCounterOffset <= sprCounterOffsetNext;
			else
				if (mgtSpriteCounter = LOADSPR) then
					sprCounterOffset <= "00000000";
					sprCounterLine	 <= "000000";
					totalTileCounter <= "000000";
				end if;
			end if;
			
			if ((mgtSpriteCounter = LOADSPR) or (mgtSpriteCounter = NEXTSPR)) then
				sprTileCounter <= "0000";
			else
				if (mgtSpriteCounter = NEXTTILE) then
					sprTileCounter		<= sprTileCounter+1;	-- Counter for current sprite.
					totalTileCounter	<= totalTileCounter+1;	-- Counter for current line.
				end if;
			end if;
		end if;
	end process;

	--
	-- Trick to preload OAM data one cycle BEFORE :
	-- OAM Data is then read at the correct cycle.
	--
	process(sprCounterLine)
	begin
		if (mgtSpriteCounter = LOADSPR) then
			sprCounterOffsetNext <= "00000000";
		else
			sprCounterOffsetNext <= sprCounterOffset + 1;
		end if;
		
		-- Modulo 127.
		SpriteNum <= sprCounterOffsetNext(6 downto 0) + startIndex;
	end process;
	
	--
	-- Compute Size Width & Height of current sprite based on mode and current size info.
	--
	process(sSize, R2101_OAMBaseSize)
		variable spSize : STD_LOGIC_VECTOR(3 downto 0);
	begin
		spSize := R2101_OAMBaseSize&sSize;
		case (spSize) is
		when "0000" => 	spriteWidthTile <= "0001"; -- 8 Pixels
						spriteHeighTile	<= "0001";
		when "0001" =>	spriteWidthTile <= "0010"; --16 Pixels
						spriteHeighTile	<= "0010";
		when "0010" =>	spriteWidthTile <= "0001"; -- 8
						spriteHeighTile	<= "0001";
		when "0011" =>	spriteWidthTile <= "0100"; --32
						spriteHeighTile	<= "0100";
		when "0100" =>	spriteWidthTile <= "0001"; -- 8
						spriteHeighTile	<= "0001";
		when "0101" =>	spriteWidthTile <= "1000"; --64
						spriteHeighTile	<= "1000";
		when "0110" =>	spriteWidthTile <= "0010"; --16
						spriteHeighTile	<= "0010";
		when "0111" =>	spriteWidthTile <= "0100"; --32
						spriteHeighTile	<= "0100";
		when "1000" =>	spriteWidthTile <= "0010"; --16
						spriteHeighTile	<= "0010";
		when "1001" =>	spriteWidthTile <= "1000"; --64
						spriteHeighTile	<= "1000";
		when "1010" =>	spriteWidthTile <= "0100"; --32
						spriteHeighTile	<= "0100";
		when "1011" =>	spriteWidthTile <= "1000"; --64
						spriteHeighTile	<= "1000";
		
		when "1100" =>	spriteWidthTile <= "0010"; --W16 H32/16
						if (OBJInterlace = '0') then
							spriteHeighTile	<= "0100";
						else
							spriteHeighTile	<= "0010";
						end if;
		when "1101" =>	spriteWidthTile <= "0100"; --W32 H64/16
						spriteHeighTile	<= "1000";
		
		when "1110" =>	spriteWidthTile <= "0010"; --16
						if (OBJInterlace = '0') then
							spriteHeighTile	<= "0100";
						else
							spriteHeighTile	<= "0010";
						end if;

		when others =>	spriteWidthTile <= "0000"; --32
						spriteHeighTile	<= "0100";		
		end case;
	end process;
	
	sprInsideUnit : PPU_SpriteInside
	Port map (
		ScrY		=> YNonMosaic(7 downto 0), -- TODO modify with interlace support.
		Interlace	=> OBJInterlace,
		
		X			=> sXStart,
		Y			=> sYStart,
		sprTileW	=> spriteWidthTile,
		sprTileH	=> spriteHeighTile,
		
		inside		=> isInside
	);
	
	--
	-- Detect when reach 34 done object. (0..33)
	-- => Test == 34 which means 35 objects is reached.
	--
	reach35 <= '1' when (totalTileCounter = "100010") else '0';
	
	--
	-- Handle PPU Registers concerning OAM. 
	--
	process(clock, totalTileCounter)
	begin
		if rising_edge(clock) then
			if (reach35 = '1') then
				regR213E_TimeOver <= '1';
			end if;

			if (sprCounterLine(5)='1') then
				regR213E_RangeOver	<= '1';
			end if;
			
			if (endVSync = '1') then
				regR213E_TimeOver	<= '0';
				regR213E_RangeOver	<= '0';
			end if;
		end if;
	end process;
	R213E_TimeOver  <= regR213E_TimeOver;
	R213E_RangeOver <= regR213E_RangeOver;

	
	process(flipV, flipH, sName, R2101_OAMNameSelect)
		variable charX	: STD_LOGIC_VECTOR(3 downto 0);
		variable charY	: STD_LOGIC_VECTOR(3 downto 0);
	begin
	
		--
		-- TODO : for rectangular sprite, flip does not flip the sprite completly but
		-- by "square" (see anomie's doc)
		--
		
		-- TODO : Compute Y tile
		-- DistY <= SpriteY - ScrY and handle tile flipping.
--	  int y = (line - spr->y) & 0xff;
--	  if(regs.oam_interlace == true) {
--		y <<= 1;
--	  }
--
--	  if(spr->vflip == true) {
--		if(spr->width == spr->height) {
--		  y = (spr->height - 1) - y;
--		} else {
--		  y = (y < spr->width) ? ((spr->width - 1) - y) : (spr->width + ((spr->width - 1) - (y - spr->width)));
--		}
--	  }

--	  if(regs.oam_interlace == true) {
--		y = (spr->vflip == false) ? (y + field()) : (y - field());
--	  }
--	  y &= 255;

		if (flipV = '1') then
			lineY := not(distY);
			offsetCharY := ;
		else
			lineY := distY;
			offsetCharY := ;
		end if;
		
		if (flipH = '1') then
			offsetCharX := ;
		else
			offsetCharX := ;
		end if;
		
		charY := sChar(7 downto 4) + offsetCharX;
		charY := sChar(3 downto 0) + offsetCharY;

		if (sName = '1') then
			tdAdrOff := "001" + ("0" & R2101_OAMNameSelect);
		else
			-- 15 bits.
			tdAdrOff := "000";
		end if;

		-- 0BB0YY YYXXX XPyyy : WORD adress.
		-- P=bitmaP : 1:BPP23 / 0:BPP 
		-- yyy : pixel in tile
		-- XXXX/YYYY : character.
		VRAMAdress <= (R2101_OAMNameBase(1 downto 0) & '0' & charY & charX & loadBPP(1) & lineY)
				    + (tdAdrOff & "000000000000");
		
		--
		-- Start X for current tile.
		--
		sTileXStart <= sXStart + ("00" & sprTileCounter(2 downto 0) & "000");
		
		--
		-- Check if we need to reject current tile inside the sprite (clipping out of screen)
		-- if(x != 256 && sx >= 256 && (sx + 7) < 512) continue;
		--
		sTileXStart7 := sTileXStart + 7;
		if ((sXStart /= 256) and (sTileXStart >= 256) and (sTileXStart7 < 512)) then
			isTileOutside = '1';
		else
			isTileOutside = '0';
		end if;
		
	end process;
	
	
	
	--##########################################################################
	--  Output value for storage unit.
	--##########################################################################
	
	--
	-- Perform HFlip when loading into the sprite unit,
	-- (avoid 34x flip logic + 34x2 bit registers and associated store logic)
	--
	process(flipH, VRAMDataIn)
		variable bppIn : STD_LOGIC_VECTOR(15 downto 0);
	begin
		bppIn := VRAMDataIn;
		if (flipH = '1') then
			store <= 	bppIn(8) & bppIn(9) & bppIn(10) & bppIn(11) & bppIn(12) & bppIn(13) & bppIn(14) & bppIn(15) &
						bppIn(0) & bppIn(1) & bppIn(2)  & bppIn(3)  & bppIn(4)  & bppIn(5)  & bppIn(6)  & bppIn(7);
		else
			store <= bppIn;
		end if;
	end process;
	
	--
	-- Create output value for storage.
	--
	process(currState)
	begin
		if (currState = SPRITE_LOADBPP1) then
			asBPP23 <= '1';
		else
			asBPP23 <= '0';
		end if;
		
		if (currState = SPRITE_LOADBPP0 or currState = SPRITE_LOADBPP1) then
			tileNumber <= totalTileCounter;
		else
			tileNumber <= "111111";	-- Invalid address.
		end if;
	end process;
	pal		<= sPal;
	prio	<= sPrio;
	XStart	<= sXStart;
	
end APPU_SpriteLoader;



