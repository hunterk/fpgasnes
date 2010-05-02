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

use CONSTREG.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_SpriteSystem is
    Port (
		clock					: in STD_LOGIC;
		
		-- ##############################################################
		--   Load Data to sprites.
		-- ##############################################################
		loadBank			: in STD_LOGIC;
		spriteNum			: in STD_LOGIC_VECTOR(5 downto 0);
		store					: in STD_LOGIC;	-- Store BPP
		storeHiBPP			: in STD_LOGIC;
		storePP				: in STD_LOGIC;

		bppData				: in STD_LOGIC_VECTOR(15 downto 0);
		storeX				: in STD_LOGIC_VECTOR(8 downto 0);
		storePalPrio			: in STD_LOGIC_VECTOR(4 downto 0);
		
		-- ##############################################################
		--   Read data for display.
		-- ##############################################################
		X						: in STD_LOGIC_VECTOR(7 downto 0);
		pal					: out STD_LOGIC_VECTOR(2 downto 0);
		prio					: out STD_LOGIC_VECTOR(1 downto 0);
		index					: out STD_LOGIC_VECTOR(3 downto 0)
	);
end PPU_SpriteSystem;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture APPU_SpriteSystem of PPU_SpriteSystem is
	
	--
	-- Priority selector for sprites.
	--
	component PPU_SpriteSelector is
		Port (
			Sprites			: in STD_LOGIC_VECTOR (33 downto 0);

			Spr1,Spr2,Spr3,Spr4,Spr5,Spr6,Spr7,Spr8,
			Spr9,Spr10,Spr11,Spr12,Spr13,Spr14,Spr15,Spr16,
			Spr17,Spr18,Spr19,Spr20,Spr21,Spr22,Spr23,Spr24,
			Spr25,Spr26,Spr27,Spr28,Spr29,Spr30,Spr31,Spr32,
			Spr33,Spr34
							: in STD_LOGIC_VECTOR (8 downto 0);	-- OOPPPxxxx

			OutSpr			: out STD_LOGIC_VECTOR(8 downto 0)
		);
	end component;

	component PPU_SpriteUnit is
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
	end component;
	
	signal	storeUnits, storePPUnits	: STD_LOGIC_VECTOR(33 downto 0);
	signal	isValid			: STD_LOGIC_VECTOR(33 downto 0);
	
	signal
			pixel0,
			pixel1,
			pixel2,
			pixel3,
			pixel4,
			pixel5,
			pixel6,
			pixel7,
			pixel8,
			pixel9,
			pixel10,
			pixel11,
			pixel12,
			pixel13,
			pixel14,
			pixel15,
			pixel16,
			pixel17,
			pixel18,
			pixel19,
			pixel20,
			pixel21,
			pixel22,
			pixel23,
			pixel24,
			pixel25,
			pixel26,
			pixel27,
			pixel28,
			pixel29,
			pixel30,
			pixel31,
			pixel32,
			pixel33,
			outResult
			: STD_LOGIC_VECTOR(8 downto 0);
begin

	process(spriteNum,store,storePP)
		variable selector34	: STD_LOGIC_VECTOR(33 downto 0);
		variable selector8	: STD_LOGIC_VECTOR(7 downto 0);
		
	begin
		case spriteNum(2 downto 0) is
		when "000" =>
			selector8 := "00000001";
		when "001" =>
			selector8 := "00000010";
		when "010" =>
			selector8 := "00000100";
		when "011" =>
			selector8 := "00001000";
		when "100" =>
			selector8 := "00010000";
		when "101" =>
			selector8 := "00100000";
		when "110" =>
			selector8 := "01000000";
		when others =>
			selector8 := "10000000";
		end case;

		case (spriteNum(5 downto 3)) is
		when "000" =>
			selector34 := "00" & "00000000" & "00000000" & "00000000" & selector8; 
		when "001" =>
			selector34 := "00" & "00000000" & "00000000" & selector8 & "00000000"; 
		when "010" =>
			selector34 := "00" & "00000000" & selector8 & "00000000" & "00000000"; 
		when "011" =>
			selector34 := "00" & selector8 & "00000000" & "00000000" & "00000000"; 
		when "100" =>
			selector34 := selector8(1 downto 0) & "00000000" & "00000000" & "00000000" & "00000000"; 
		when others =>
			selector34 := "00" & "00000000" & "00000000" & "00000000" & "00000000"; 
		end case;
		
		for i in 33 downto 0 loop
			storeUnits(i)	<= selector34(i) and store;
			storePPUnits(i)	<= selector34(i) and storePP;
		end loop;
	end process;

	sp0 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(0),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(0),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel0(3 downto 0),
		pal				=> pixel0(6 downto 4),
		prio			=> pixel0(8 downto 7),
		isValid			=> isValid(0)
	);

	sp1 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(1),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(1),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel1(3 downto 0),
		pal				=> pixel1(6 downto 4),
		prio			=> pixel1(8 downto 7),
		isValid			=> isValid(1)
	);

	sp2 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(2),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(2),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel2(3 downto 0),
		pal				=> pixel2(6 downto 4),
		prio			=> pixel2(8 downto 7),
		isValid			=> isValid(2)
	);
	
	sp3 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(3),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(3),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel3(3 downto 0),
		pal				=> pixel3(6 downto 4),
		prio			=> pixel3(8 downto 7),
		isValid			=> isValid(3)
	);
	
	sp4 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(4),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(4),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel4(3 downto 0),
		pal				=> pixel4(6 downto 4),
		prio			=> pixel4(8 downto 7),
		isValid			=> isValid(4)
	);
	
	sp5 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(5),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(5),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel5(3 downto 0),
		pal				=> pixel5(6 downto 4),
		prio			=> pixel5(8 downto 7),
		isValid			=> isValid(5)
	);
	
	sp6 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(6),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(6),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel6(3 downto 0),
		pal				=> pixel6(6 downto 4),
		prio			=> pixel6(8 downto 7),
		isValid			=> isValid(6)
	);
	
	sp7 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(7),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(7),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel7(3 downto 0),
		pal				=> pixel7(6 downto 4),
		prio			=> pixel7(8 downto 7),
		isValid			=> isValid(7)
	);
	
	sp8 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(8),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(8),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel8(3 downto 0),
		pal				=> pixel8(6 downto 4),
		prio			=> pixel8(8 downto 7),
		isValid			=> isValid(8)
	);
	
	sp9 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(9),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(9),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel9(3 downto 0),
		pal				=> pixel9(6 downto 4),
		prio			=> pixel9(8 downto 7),
		isValid			=> isValid(9)
	);
	
	sp10 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(10),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(10),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel10(3 downto 0),
		pal				=> pixel10(6 downto 4),
		prio			=> pixel10(8 downto 7),
		isValid			=> isValid(10)
	);
	
	sp11 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(11),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(11),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel11(3 downto 0),
		pal				=> pixel11(6 downto 4),
		prio			=> pixel11(8 downto 7),
		isValid			=> isValid(11)
	);
	
	sp12 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(12),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(12),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel12(3 downto 0),
		pal				=> pixel12(6 downto 4),
		prio			=> pixel12(8 downto 7),
		isValid			=> isValid(12)
	);
	
	sp13 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(13),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(13),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel13(3 downto 0),
		pal				=> pixel13(6 downto 4),
		prio			=> pixel13(8 downto 7),
		isValid			=> isValid(13)
	);
	
	sp14 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(14),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(14),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel14(3 downto 0),
		pal				=> pixel14(6 downto 4),
		prio			=> pixel14(8 downto 7),
		isValid			=> isValid(14)
	);
	
	sp15 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(15),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(15),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel15(3 downto 0),
		pal				=> pixel15(6 downto 4),
		prio			=> pixel15(8 downto 7),
		isValid			=> isValid(15)
	);
	
	sp16 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(16),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(16),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel16(3 downto 0),
		pal				=> pixel16(6 downto 4),
		prio			=> pixel16(8 downto 7),
		isValid			=> isValid(16)
	);
	
	sp17 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(17),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(17),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel17(3 downto 0),
		pal				=> pixel17(6 downto 4),
		prio			=> pixel17(8 downto 7),
		isValid			=> isValid(17)
	);
	
	sp18 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(18),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(18),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel18(3 downto 0),
		pal				=> pixel18(6 downto 4),
		prio			=> pixel18(8 downto 7),
		isValid			=> isValid(18)
	);
	
	sp19 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(19),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(19),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel19(3 downto 0),
		pal				=> pixel19(6 downto 4),
		prio			=> pixel19(8 downto 7),
		isValid			=> isValid(19)
	);
	
	sp20 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(20),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(20),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel20(3 downto 0),
		pal				=> pixel20(6 downto 4),
		prio			=> pixel20(8 downto 7),
		isValid			=> isValid(20)
	);
	
	sp21 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(21),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(21),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel21(3 downto 0),
		pal				=> pixel21(6 downto 4),
		prio			=> pixel21(8 downto 7),
		isValid			=> isValid(21)
	);
	
	sp22 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(22),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(22),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel22(3 downto 0),
		pal				=> pixel22(6 downto 4),
		prio			=> pixel22(8 downto 7),
		isValid			=> isValid(22)
	);
	
	sp23 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(23),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(23),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel23(3 downto 0),
		pal				=> pixel23(6 downto 4),
		prio			=> pixel23(8 downto 7),
		isValid			=> isValid(23)
	);
	
	sp24 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(24),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(24),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel24(3 downto 0),
		pal				=> pixel24(6 downto 4),
		prio			=> pixel24(8 downto 7),
		isValid			=> isValid(24)
	);
	
	sp25 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(25),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(25),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel25(3 downto 0),
		pal				=> pixel25(6 downto 4),
		prio			=> pixel25(8 downto 7),
		isValid			=> isValid(25)
	);
	
	sp26 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(26),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(26),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel26(3 downto 0),
		pal				=> pixel26(6 downto 4),
		prio			=> pixel26(8 downto 7),
		isValid			=> isValid(26)
	);
	
	sp27 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(27),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(27),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel27(3 downto 0),
		pal				=> pixel27(6 downto 4),
		prio			=> pixel27(8 downto 7),
		isValid			=> isValid(27)
	);
	
	sp28 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(28),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(28),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel28(3 downto 0),
		pal				=> pixel28(6 downto 4),
		prio			=> pixel28(8 downto 7),
		isValid			=> isValid(28)
	);
		
	sp29 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(29),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(29),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel29(3 downto 0),
		pal				=> pixel29(6 downto 4),
		prio			=> pixel29(8 downto 7),
		isValid			=> isValid(29)
	);
		
	sp30 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(30),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(30),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel30(3 downto 0),
		pal				=> pixel30(6 downto 4),
		prio			=> pixel30(8 downto 7),
		isValid			=> isValid(30)
	);
		
	sp31 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(31),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(31),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel31(3 downto 0),
		pal				=> pixel31(6 downto 4),
		prio			=> pixel31(8 downto 7),
		isValid			=> isValid(31)
	);
		
	sp32 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(32),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(32),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel32(3 downto 0),
		pal				=> pixel32(6 downto 4),
		prio			=> pixel32(8 downto 7),
		isValid			=> isValid(32)
	);
		
	sp33 : PPU_SpriteUnit port map
	(
		clock,
		loadBank,

		writeE			=> storeUnits(33),
		hiBPP			=> storeHiBPP,
		wordIn			=> bppData,
		storeAll		=> storePPUnits(33),
		PalIn_Prio		=> storePalPrio,
		X				=> storeX,
		CurrentX		=> X,
		pixel			=> pixel33(3 downto 0),
		pal				=> pixel33(6 downto 4),
		prio			=> pixel33(8 downto 7),
		isValid			=> isValid(33)
	);
		
	
	-----------------------------------------------------
	--
	-- Sprite Selector.
	--
	-----------------------------------------------------
	spPrio : PPU_SpriteSelector port map
	(
		Sprites => isValid,

		Spr1	=> pixel0,
		Spr2	=> pixel1,
		Spr3	=> pixel2,
		Spr4	=> pixel3,
		Spr5	=> pixel4,
		Spr6	=> pixel5,
		Spr7	=> pixel6,
		Spr8	=> pixel7,
		Spr9	=> pixel8,
		Spr10	=> pixel9,
		Spr11	=> pixel10,
		Spr12	=> pixel11,
		Spr13	=> pixel12,
		Spr14	=> pixel13,
		Spr15	=> pixel14,
		Spr16	=> pixel15,
		Spr17	=> pixel16,
		Spr18	=> pixel17,
		Spr19	=> pixel18,
		Spr20	=> pixel19,
		Spr21	=> pixel20,
		Spr22	=> pixel21,
		Spr23	=> pixel22,
		Spr24	=> pixel23,
		Spr25	=> pixel24,
		Spr26	=> pixel25,
		Spr27	=> pixel26,
		Spr28	=> pixel27,
		Spr29	=> pixel28,
		Spr30	=> pixel29,
		Spr31	=> pixel30,
		Spr32	=> pixel31,
		Spr33	=> pixel32,
		Spr34	=> pixel33,
		OutSpr	=> outResult
	);
	
	index	<= outResult(3 downto 0);
	pal		<= outResult(6 downto 4);
	prio	<= outResult(8 downto 7);
	
end APPU_SpriteSystem;
