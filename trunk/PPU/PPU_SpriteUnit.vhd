----------------------------------------------------------------------------------
-- Create Date:
-- Design Name:		PPU_SpriteUnit.vhd
-- Module Name:		PPU_SpriteUnit
--
-- Description: 	
--	Tile loading order / pixel order is done by sprite loader unit.
--  This unit just display continously 64 pix max per sprite.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PPU_SpriteUnit is
	port (
		clock			: in	STD_LOGIC;
		bankSwap		: in	STD_LOGIC;
		
		--
		-- Loading Side.
		--
		writeE			: in	STD_LOGIC;
		SpriteAddrWR	: in	STD_LOGIC;
		wordIn	 		: in	STD_LOGIC_VECTOR(15 downto 0);
		storeX			: in	STD_LOGIC;
		storePal_Prio	: in	STD_LOGIC;
		PalIn_Prio		: in	STD_LOGIC_VECTOR( 4 downto 0);  -- OOPPP 
		X				: in	STD_LOGIC_VECTOR( 8 downto 0);	-- TODO : Sprite on 256 pix even in Hi-Res ? 

		--
		-- Rendering Side.
		--
		CurrentX		: in	STD_LOGIC_VECTOR( 7 downto 0);
		pixel			: out	STD_LOGIC_VECTOR( 3 downto 0);
		pal				: out	STD_LOGIC_VECTOR( 2 downto 0);
		prio			: out	STD_LOGIC_VECTOR( 1 downto 0);
		isValid			: out	STD_LOGIC
	);
end entity PPU_SpriteUnit;

architecture ArchPPU_SpriteUnit of PPU_SpriteUnit is
	
--	component SpriteRam is
--		Port ( 	
--			clock			: in  STD_LOGIC;
--			data			: in  STD_LOGIC_VECTOR(15 DOWNTO 0);
--			address			: in  STD_LOGIC_VECTOR(2 DOWNTO 0);
--
--			we				: in  STD_LOGIC;
--			q				: out STD_LOGIC_VECTOR(15 DOWNTO 0)
--		);
--	end component;
	
	signal	-- B1LData,
			B1LDataOut,
			-- B2LData,
			B2LDataOut,
			-- B1HData,
			B1HDataOut,
			-- B2HData,
			B2HDataOut,
			pixLo, pixHi : STD_LOGIC_VECTOR(15 DOWNTO 0);

--	signal	B1LAddress,B2LAddress,B1HAddress,B2HAddress	: STD_LOGIC_VECTOR(2 DOWNTO 0);
	signal	B1LWEnable,B2LWEnable,B1HWEnable,B2HWEnable	: STD_LOGIC;
	
	signal	sPixel		: STD_LOGIC_VECTOR(3 downto 0);
	signal  DX			: STD_LOGIC_VECTOR(7 downto 0);
	signal  regStartX	: STD_LOGIC_VECTOR(8 downto 0);

	signal  regPal_Prio	: STD_LOGIC_VECTOR(4 downto 0);
begin
	--
	-- Store Start X.
	--
	process(clock, X, storeX, X, storePal_Prio, PalIn_Prio)
	begin
		if rising_edge(clock) then
			if (storeX = '1') then
				regStartX <= X;
			end if;
			
			if (storePal_Prio = '1') then
				regPal_Prio <= PalIn_Prio;
			end if;
		end if;
	end process;
	
	pal		<= regPal_Prio(2 downto 0);
	prio	<= regPal_Prio(4 downto 3);
	
	--
	-- Read Bank access control.
	--
	process(CurrentX, bankSwap,
			B2LDataOut, B2HDataOut, 
			B1LDataOut, B1HDataOut,
			regStartX)
		variable xPick	: STD_LOGIC_VECTOR(2 downto 0);
		variable maxX	: STD_LOGIC_VECTOR(7 downto 0); 
	begin
		--
		-- Extract the correct pixels from the output.
		--
		if (bankSwap='1') then
			pixLo  <= B2LDataOut;
			pixHi  <= B2HDataOut;
		else
			pixLo  <= B1LDataOut;
			pixHi  <= B1HDataOut;
		end if;
		
		-- DX <= CurrentX + regStartX; -- TODO : X - regStartX actually., just for compile now.
		-- TODO make sure that signed X rules works. (and overflow)
		DX <= CurrentX(7 downto 0) + regStartX(7 downto 0);

		-- Flip done at loading level.
		xPick := DX(2 downto 0);

		if ((DX >= "00000000") and (DX < "00001000")) then
			case xPick is
			when "000" => sPixel <= pixHi(7) & pixHi(15) & pixLo(7) & pixLo(15);
			when "001" => sPixel <= pixHi(6) & pixHi(14) & pixLo(6) & pixLo(14);
			when "010" => sPixel <= pixHi(5) & pixHi(13) & pixLo(5) & pixLo(13);
			when "011" => sPixel <= pixHi(4) & pixHi(12) & pixLo(4) & pixLo(12);
			when "100" => sPixel <= pixHi(3) & pixHi(11) & pixLo(3) & pixLo(11);
			when "101" => sPixel <= pixHi(2) & pixHi(10) & pixLo(2) & pixLo(10);
			when "110" => sPixel <= pixHi(1) & pixHi(9) & pixLo(1) & pixLo(9);
			when others => sPixel<= pixHi(0) & pixHi(8) & pixLo(0) & pixLo(8);
			end case;
		else
			sPixel <= "0000";
		end if;
		
		if (sPixel = "0000") then
			isValid <= '0';
		else
			isValid <= '1';
		end if;
	end process;
	pixel <= sPixel;
	
	
	--
	-- Write bank access control.
	--
	process(writeE,bankSwap,SpriteAddrWR,wordIn,DX)
	begin
		--
		-- Write signal
		--
		if (writeE='1') then
			if (SpriteAddrWR = '1') then
				--
				-- Access High Bank
				--
				B1LWEnable <= '0';
				B2LWEnable <= '0';

				B1HWEnable <= bankSwap;
				B2HWEnable <= not(bankSwap);
			else
				--
				-- Access Low Bank
				--
				B1LWEnable <= bankSwap;
				B2LWEnable <= not(bankSwap);
				
				B1HWEnable <= '0';
				B2HWEnable <= '0';
			end if;
		else
			B1LWEnable <= '0';
			B1HWEnable <= '0';
			B2LWEnable <= '0';
			B2HWEnable <= '0';
		end if;
		
		--
		-- Address Signal
		--
--		if (bankSwap='1') then
--			-- Bank 1 is storage.
--			B1LAddress	<= SpriteAddrWR(2 downto 0);
--			B1HAddress	<= SpriteAddrWR(2 downto 0);
--			
--			-- Bank 2 is pixel reading.
--			B2LAddress	<= DX(5 downto 3);
--			B2HAddress	<= DX(5 downto 3);
--		else
--			-- Bank 1 is pixel reading.
--			B1LAddress	<= DX(5 downto 3);
--			B1HAddress	<= DX(5 downto 3);
--			
--			-- Bank 2 is storage.
--			B2LAddress	<= SpriteAddrWR(2 downto 0);
--			B2HAddress	<= SpriteAddrWR(2 downto 0);			
--		end if;
	end process;

	-- We do not care about the data,
	-- as WEnable decides anyway if data is going to be used or not.
--	B1LData		<= wordIn;
--	B1HData		<= wordIn;
--	B2LData		<= wordIn;
--	B2HData		<= wordIn;

	--
	-- Tile Memory.
	--
	process(clock, wordIn)
	begin
		if rising_edge(clock) then
			if (B1LWEnable = '1') then
				B1LDataOut <= wordIn;
			end if;
			if (B1HWEnable = '1') then
				B1HDataOut <= wordIn;
			end if;
			if (B2LWEnable = '1') then
				B2LDataOut <= wordIn;
			end if;
			if (B2HWEnable = '1') then
				B2HDataOut <= wordIn;
			end if;
		end if;
	end process;
	
--	instanceBank1Low : SpriteRam port map
--	( 	clock	=> clock,
--		data	=> B1LData,
--		address	=> B1LAddress,
--		we		=> B1LWEnable,
--		q		=> B1LDataOut
--	);
--
--	instanceBank1High : SpriteRam port map
--	( 	clock	=> clock,
--		data	=> B1HData,
--		address	=> B1HAddress,
--		we		=> B1HWEnable,
--		q		=> B1HDataOut
--	);
--
--	instanceBank2Low : SpriteRam port map
--	( 	clock	=> clock,
--		data	=> B2LData,
--		address	=> B2LAddress,
--		we		=> B2LWEnable,
--		q		=> B2LDataOut
--	);
--
--	instanceBank2High : SpriteRam port map
--	( 	clock	=> clock,
--		data	=> B2HData,
--		address	=> B2HAddress,
--		we		=> B2HWEnable,
--		q		=> B2HDataOut
--	);
end ArchPPU_SpriteUnit;
