----------------------------------------------------------------------------------
-- Create Date:
-- Design Name:		PPU_SpriteUnit.vhd
-- Module Name:		PPU_SpriteUnit
--
-- Description:
--	Tile loading order / pixel order is done by sprite loader unit.
--  This unit just display continously 8 pixel for one tile.
-- TODO : X Computation not correct (not likely matching specs)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PPU_SpriteUnit is
	port (
		clock				: in	STD_LOGIC;
		loadBank		: in	STD_LOGIC;
		
		--
		-- Loading Side.
		--
		writeE			: in	STD_LOGIC;
		hiBPP				: in	STD_LOGIC;
		wordIn	 		: in	STD_LOGIC_VECTOR(15 downto 0);
		storeAll			: in	STD_LOGIC;
		PalIn_Prio		: in	STD_LOGIC_VECTOR( 4 downto 0);  -- OOPPP 
		X					: in	STD_LOGIC_VECTOR( 8 downto 0);	-- TODO : Sprite on 256 pix even in Hi-Res ? 

		--
		-- Rendering Side.
		--
		CurrentX		: in	STD_LOGIC_VECTOR( 7 downto 0);
		pixel				: out	STD_LOGIC_VECTOR( 3 downto 0);
		pal				: out	STD_LOGIC_VECTOR( 2 downto 0);
		prio				: out	STD_LOGIC_VECTOR( 1 downto 0);
		isValid			: out	STD_LOGIC
	);
end entity PPU_SpriteUnit;

architecture ArchPPU_SpriteUnit of PPU_SpriteUnit is
	
	signal	
			B0LDataOut,
			B1LDataOut,
			B0HDataOut,
			B1HDataOut,
			pixLo, pixHi : STD_LOGIC_VECTOR(15 DOWNTO 0);

	signal	B0LWEnable,B1LWEnable,B0HWEnable,B1HWEnable	: STD_LOGIC;
	
	signal	sPixel		: STD_LOGIC_VECTOR(3 downto 0);
	signal  DX			: STD_LOGIC_VECTOR(8 downto 0);
	signal  reg0StartX,reg1StartX	: STD_LOGIC_VECTOR(8 downto 0);

	signal  reg0Pal_Prio,reg1Pal_Prio	: STD_LOGIC_VECTOR(4 downto 0);

begin
	--
	-- Read Bank access control.
	--
	process(loadBank,
			B0LDataOut, B0HDataOut, 
			B1LDataOut, B1HDataOut,
			reg0Pal_Prio, reg1Pal_Prio,
			reg0StartX, reg1StartX,
			CurrentX
			)
		variable xPick		: STD_LOGIC_VECTOR(2 downto 0);
		variable vX		: STD_LOGIC_VECTOR(8 downto 0);
	begin
		--
		-- Extract the correct pixels from the output.
		--
		if (loadBank='1') then		-- We store in bank 1, so we display bank 0.
			pixLo	<= B0LDataOut;
			pixHi	<= B0HDataOut;
			pal	<= reg0Pal_Prio(2 downto 0);
			prio	<= reg0Pal_Prio(4 downto 3);
			vX		:= reg0StartX;
		else
			pixLo	<= B1LDataOut;
			pixHi	<= B1HDataOut;
			pal	<= reg1Pal_Prio(2 downto 0);
			prio	<= reg1Pal_Prio(4 downto 3);
			vX		:= reg1StartX;
		end if;
		
		-- DX <= CurrentX + regStartX; -- TODO : X - regStartX actually., just for compile now.
		-- TODO make sure that signed X rules works. (and overflow)
		DX <= ('0' & CurrentX(7 downto 0)) + vX(8 downto 0);

		-- Flip done at loading level.
		xPick := DX(2 downto 0);

		-- Pixel 0..7 only.
		if (DX(8 downto 3) = "000000") then
			case xPick is
			when "000" =>	sPixel <= pixHi(8) & pixHi(0) & pixLo(8) & pixLo(0);
			when "001" =>	sPixel <= pixHi(9) & pixHi(1) & pixLo(9) & pixLo(1);
			when "010" =>	sPixel <= pixHi(10) & pixHi(2) & pixLo(10) & pixLo(2);
			when "011" =>	sPixel <= pixHi(11) & pixHi(3) & pixLo(11) & pixLo(3);
			when "100" =>	sPixel <= pixHi(12) & pixHi(4) & pixLo(12) & pixLo(4);
			when "101" =>	sPixel <= pixHi(13) & pixHi(5) & pixLo(13) & pixLo(5);
			when "110" =>	sPixel <= pixHi(14) & pixHi(6) & pixLo(14) & pixLo(6);
			when others =>	sPixel <= pixHi(15) & pixHi(7) & pixLo(15) & pixLo(7);
			end case;
		else
			sPixel <= "0000";
		end if;
		
		if (sPixel = "0000") then
			isValid <= '0';
		else
			isValid <= '1';
		end if;
		
		pixel <= sPixel;
	end process;
	
	
	--
	-- Write bank access control.
	--
	process(writeE,hiBPP,loadBank)
	begin
		--
		-- Write signal
		--
		if (writeE='1') then
			if (hiBPP = '1') then
				--
				-- Access High Bank
				--
				B0LWEnable <= '0';
				B1LWEnable <= '0';

				B0HWEnable <= not(loadBank);
				B1HWEnable <= loadBank;
			else
				--
				-- Access Low Bank
				--
				B0LWEnable <= not(loadBank);
				B1LWEnable <= loadBank;
				
				B0HWEnable <= '0';
				B1HWEnable <= '0';
			end if;
		else
			B0LWEnable <= '0';
			B0HWEnable <= '0';
			B1LWEnable <= '0';
			B1HWEnable <= '0';
		end if;
	end process;

	--
	-- Tile Memory Storage.
	--
	process(clock, wordIn)
	begin
		if rising_edge(clock) then
			--
			-- Store bitmap.
			--
			if (B0LWEnable = '1') then
				B0LDataOut <= wordIn;
			end if;
			if (B0HWEnable = '1') then
				B0HDataOut <= wordIn;
			end if;
			if (B1LWEnable = '1') then
				B1LDataOut <= wordIn;
			end if;
			if (B1HWEnable = '1') then
				B1HDataOut <= wordIn;
			end if;
			
			--
			-- Store Palette & Prio
			--
			if (storeAll = '1') then
				if (loadBank='1') then
					reg1StartX		<= X;
					reg1Pal_Prio	<= PalIn_Prio;
				else
					reg0StartX		<= X;
					reg0Pal_Prio	<= PalIn_Prio;
				end if;
			end if;
		end if;
	end process;
end ArchPPU_SpriteUnit;
