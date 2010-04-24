----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_OutputPixel.vhd
-- Module Name:		PPU_OutputPixel
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

entity PPU_OutputPixel is
    Port (
		winColSubInside 	: in STD_LOGIC;
		winColMainInside 	: in STD_LOGIC;
		mainObjPal			: in STD_LOGIC;
		mainColor			: in STD_LOGIC_VECTOR(14 downto 0);
		mainSelect			: in STD_LOGIC_VECTOR( 2 downto 0);
		subColor 			: in STD_LOGIC_VECTOR(14 downto 0);
		subSelect			: in STD_LOGIC_VECTOR( 2 downto 0);
		enableMath_2131 	: in STD_LOGIC_VECTOR( 5 downto 0);
		
		fixedColorR			: in STD_LOGIC_VECTOR( 4 downto 0);
		fixedColorG			: in STD_LOGIC_VECTOR( 4 downto 0);
		fixedColorB			: in STD_LOGIC_VECTOR( 4 downto 0);
		
		addSubScreen_2130	: in STD_LOGIC;
		addSub_2131			: in STD_LOGIC;
		half_2130			: in STD_LOGIC;
		resultColor			: out STD_LOGIC_VECTOR(14 downto 0)
	);
end PPU_OutputPixel;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_OutputPixel of PPU_OutputPixel is
	component PPU_ColorMath is
		Port (
			InputA  : in STD_LOGIC_VECTOR(4 downto 0);
			InputB  : in STD_LOGIC_VECTOR(4 downto 0);
	
			AddSub 	: in STD_LOGIC;
			Div2	: in STD_LOGIC;
	
			Output  : out STD_LOGIC_VECTOR(4 downto 0)
		);
	end component;
	
	signal bgSub					: STD_LOGIC_VECTOR(2 downto 0);

	signal pixSub,pixMain,pixSub2	: STD_LOGIC_VECTOR(14 downto 0);
	signal halve					: STD_LOGIC;
	signal colorMathROut, colorMathGOut, colorMathBOut : STD_LOGIC_VECTOR(4 downto 0);
	signal useColorMath				: STD_LOGIC;
	
begin
	process(addSubScreen_2130, fixedColorR, fixedColorG, fixedColorB, subSelect, subColor, mainColor,
			winColMainInside, winColSubInside, pixSub, bgSub, pixMain)
	begin
		--
		-- s     = Add subscreen (instead of fixed color)
		--
		if (addSubScreen_2130 = '1') then
			bgSub	<= subSelect;
			pixSub	<= subColor;
		else
			bgSub	<= CONSTANTS.BACKDROP_SEL;
			pixSub	<= fixedColorB & fixedColorG & fixedColorR;
		end if;
		
		if (winColMainInside = '0') then
			if (winColSubInside = '0') then
				pixSub2 <= "000000000000000";
			else
				pixSub2 <= pixSub;
			end if;

			pixMain <= "000000000000000";
		else
			pixSub2 <= pixSub;
			pixMain <= mainColor;
		end if;
	end process;
	
	process(half_2130, winColMainInside, addSubScreen_2130,bgSub)
	begin
		if (half_2130='1' and winColMainInside = '1') then
			if (addSubScreen_2130='1' and bgSub = CONSTANTS.BACKDROP_SEL) then
				halve <= '0';
			else
				halve <= '1';
			end if;
		else
			halve <= '0';
		end if;
	end process;

	instanceColorMathR : PPU_ColorMath port map
	(
		InputA 	=> pixMain(4 downto 0),
		InputB 	=> pixSub2(4 downto 0),
		AddSub	=> addSub_2131,
		Div2	=> halve,
		Output	=> colorMathROut
	);

	instanceColorMathG : PPU_ColorMath port map
	(
		InputA 	=> pixMain(9 downto 5),
		InputB 	=> pixSub2(9 downto 5),
		AddSub	=> addSub_2131,
		Div2	=> halve,
		Output	=> colorMathGOut
	);

	instanceColorMathB : PPU_ColorMath port map
	(
		InputA 	=> pixMain(14 downto 10),
		InputB 	=> pixSub2(14 downto 10),
		AddSub	=> addSub_2131,
		Div2	=> halve,
		Output	=> colorMathBOut
	);

	process(mainSelect)
		variable enable			: STD_LOGIC;
		variable validSource	: STD_LOGIC;
	begin
		-- regs.color_enabled[p.bg_main]
		case mainSelect is
		when CONSTANTS.OBJECTS_SEL => 
			enable		:= enableMath_2131(4); -- Obj  
			validSource := mainObjPal; -- Palette 0..3 never participate.
		when CONSTANTS.BG1_SEL =>
			enable		:= enableMath_2131(0); -- BG1
			validSource := '1';
		when CONSTANTS.BG2_SEL =>
			enable		:= enableMath_2131(1); -- BG2
			validSource := '1';
		when CONSTANTS.BG3_SEL =>
			enable		:= enableMath_2131(2); -- BG3
			validSource := '1';
		when CONSTANTS.BG4_SEL =>
			enable		:= enableMath_2131(3); -- BG4
			validSource := '1';
		when others =>
			enable		:= enableMath_2131(5); -- BACKDROP
			validSource := '1';
		end case;
		
		if (enable = '1' and winColSubInside = '1' and validSource='1') then
			useColorMath <= '1';
		else
			useColorMath <= '0';
		end if;
	end process;

	process (	colorMathROut,colorMathGOut,colorMathBOut,winColSubInside,
				mainSelect,	enableMath_2131, pixMain )
	begin
		if (useColorMath = '1') then
			resultColor <= colorMathBOut & colorMathGOut & colorMathROut;
		else
			resultColor <= pixMain;
		end if;
	end process;
end PPU_OutputPixel;
