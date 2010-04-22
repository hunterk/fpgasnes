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

--  Pix_Main, Pix_Sub, Pal_Main, Pal_Sub as input.
--
--  if (!Mode_Add) {
--	  Pal_Sub = BACK;
--	  Pix_Sub = Fixed_Color_reg;
--  } else {
--	  Pal_Sub = Pal_Sub;
--    Pix_Sub = Pix_Sub;
--  }
--
--  if (OutsideWinColMain) {
--	  Pix_Main = 0; --- Reset RGB to 0
--	  if (OutsideColSub) {
--		Pix_Sub = 0; --- Reset RGB to 0
--	  } else {
--      Pix_Sub = Pix_Sub;
--    }
--  } else {
--    Pix_Main = Pix_Main
--    Pix_Sub = Pix_Sub;
--  }
--  
--  useAddSub = (Main_NotSprite && ColWindowSubValid  && BG_MainPixel_ColorEnabled);
--  halve = useAddSub && (halfEnable     && ColWindow_MainValid && (!(Mode_Add && Pal_Sub==BACK)));
--  
--  pixel = useAddSub ? addSub(Pix_Main, Pix_Sub, halve, operation);

entity PPU_OutputPixel is
    Port (
		winColSubInside 	: in STD_LOGIC;
		winColMainInside 	: in STD_LOGIC;
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
		
	signal trace					: STD_LOGIC_VECTOR(4 downto 0);
begin
	process(addSubScreen_2130, fixedColorR, fixedColorG, fixedColorB, subSelect, subColor, mainColor,
			winColMainInside, winColSubInside, pixSub, bgSub, pixMain)
	begin
		if (addSubScreen_2130 = '0') then
			bgSub	<= CONSTANTS.BACKDROP_SEL;
			pixSub	<= fixedColorB & fixedColorG & fixedColorR;
			trace(0)	<= '0';
		else
			bgSub	<= subSelect;
			pixSub	<= subColor;
			trace(0)	<= '1';
		end if;
		
		if (winColMainInside = '0') then
			if (winColSubInside = '0') then
				pixSub2 <= "000000000000000";
				trace(2 downto 1)	<= "00";
			else
				pixSub2 <= pixSub;
				trace(2 downto 1)	<= "01";
			end if;
			pixMain <= "000000000000000";
		else
			trace(2 downto 1)	<= "11";
			pixMain <= mainColor;
			pixSub2 <= pixSub;
		end if;
	end process;
	
	process(half_2130, winColMainInside, addSubScreen_2130,bgSub)
	begin
		if (half_2130='1' and winColMainInside = '1') then
			if (addSubScreen_2130='1' and bgSub = CONSTANTS.BACKDROP_SEL) then
				halve <= '0';
				trace(4 downto 3)	<= "00";
			else
				halve <= '1';
				trace(4 downto 3)	<= "01";
			end if;
		else
			halve <= '0';
			trace(4 downto 3)	<= "10";
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

	process (	colorMathROut,colorMathGOut,colorMathBOut,winColSubInside,
				mainSelect,	enableMath_2131, pixMain )
		variable enable : STD_LOGIC;
	begin
		case mainSelect is
		when CONSTANTS.OBJECTS_SEL => 
			enable := enableMath_2131(4); -- Obj  
		when CONSTANTS.BG1_SEL =>
			enable := enableMath_2131(0); -- BG1
		when CONSTANTS.BG2_SEL =>
			enable := enableMath_2131(1); -- BG2
		when CONSTANTS.BG3_SEL =>
			enable := enableMath_2131(2); -- BG3
		when CONSTANTS.BG4_SEL =>
			enable := enableMath_2131(3); -- BG4
		when others =>
			enable := enableMath_2131(5); -- BACKDROP
		end case;
		
		if (enable = '1' and winColSubInside = '1' and  mainSelect /= CONSTANTS.OBJECTS_SEL) then
			resultColor <= colorMathBOut & colorMathGOut & colorMathROut;
		else
			resultColor <= pixMain;
		end if;
	end process;
end PPU_OutputPixel;

-- inline uint16 bPPU::get_pixel_normal(uint32 x) {
--   pixel_t &p = pixel_cache[x];
--   uint16 src_main, src_sub;
--   uint8  bg_sub;
--   src_main = p.src_main;
-- 
--   if(!regs.addsub_mode) {
--     bg_sub  = BACK;
--     src_sub = regs.color_rgb;
--   } else {
--     bg_sub  = p.bg_sub;
--     src_sub = p.src_sub;
--   }
-- 
--   if(!window[COL].main[x]) {
--     if(!window[COL].sub[x]) {
--       return 0x0000;
--     }
--     src_main = 0x0000;
--   }
-- 
--   if(!p.ce_main && regs.color_enabled[p.bg_main] && window[COL].sub[x]) {
--     bool halve = false;
--     if(regs.color_halve && window[COL].main[x]) {
--       if(regs.addsub_mode && bg_sub == BACK);
--       else {
--         halve = true;
--       }
--     }
--     return addsub(src_main, src_sub, halve);
--   }
-- 
--  return src_main;
-- }


-- 2130_cc  cc = Clip colors to black before math 00 => Never, 01 => Outside Color Window only, 10 => Inside Color Window only, 11 => Always
-- 2130_mm  mm = Prevent color math  : 00 => Never, 01 => Outside Color Window only, 10 => Inside Color Window only, 11 => Always
-- 2130_s   s     = Add subscreen (instead of fixed color)
-- (2130_d  d     = Direct color mode for 256-color BGs)
-- 2131_s   s    = Add/subtract select   0 => Add the colors, 1 => Subtract the colors
-- 2131_h   h    = Half color math. When set, the result of the color math is
--             divided by 2 (except when $2130 bit 1 is set and the fixed color is
--             used, or when color is cliped).
-- 2131_EnableMath   4/3/2/1/o/b = Enable color math on BG1/BG2/BG3/BG4/OBJ/Backdrop

-- The Color Window
-- ----------------

-- The color window is rather different. The color window itself can be set
-- to clip the colors of pixels to black (before math, so it's almost the same
-- effect you'd get by setting all entries in the palette to black, then fixing
-- them before you do subscreen addition--the only difference is that half math
-- will not occur), and to prevent all color math effects from occurring. These
-- can be applied never, always, inside the "clip" windows specified for the color
-- window, or outside the "clip" window.

-- Bits "cc" of register $2130 controls whether the pixel colors (and half-math)
-- will be clipped inside the window, outside the window, never, or always. Bits
-- mm do the same for preventing color math.

-- Consider the main screen set up so BGs 1 and 2 are visible in an 8x8
-- checkerboard pattern, with all the BG1 pixels red and all the BG2 pixels blue.
-- The subscreen is filled with a green BG, and color math is enabled on BG 1
-- only. You'll end up with a yellow and blue checkerboard. Turn on the color
-- window to clip colors, and you'll get a green and black checkerboard since
-- the subscreen is only added (to a black pixel) where BG1 would be visible. If
-- you clip math instead, you'll get the same display you'd get with color math
-- disabled on all BGs.

-- In hires modes, we use the previous main-screen pixel to determine whether the
-- color window effect should be applied to a subscreen pixel. See "Color Math"
-- below for details.
