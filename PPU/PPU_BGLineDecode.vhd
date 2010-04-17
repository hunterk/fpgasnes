----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_BGLineDecode.vhd
-- Module Name:		PPU_BGLineDecode
--
-- Description: 	Decode bitplan/palette and priority from line cache.
--
-- TODO : HiRes support.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

use CONSTANTS.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_BGLineDecode is
    Port ( 	
			--
			-- Input
			--

			--
			-- Low 16 Bit for all modes :
			-- PPP PPP PPP PPP OOOO   <-- PPP : Palette Index, O : Priority 0/1 for tile.  
			-- 444 333 222 111 4321
			-- 
			-- High 12 Bit for mode
			---------------------
			--     2222 2222 1111 <- Bit 27..16
			--     7654 3210 9876
			---------------------
			-- 0 : 44xx 1133 xx22
			-- 1 : xx11 1133 2222
			-- 2 : xx11 11xx 2222
			-- 3 : 1111 1111 2222 <- 8 bit mode is encoded as [76321054]
			-- 4 : 1111 1111 xx22
			-- 5 : xx11 11xx xx22 <- 
			-- 6 : xx11 11xx xxxx
			-- 7 : 1111 1111 xxxx			
			PixelData 		: in  STD_LOGIC_VECTOR (27 downto 0); -- 12 BPP + 16 (4 prio + 4xPPP) = 28

			R2105_BGMode	: in  STD_LOGIC_VECTOR ( 2 downto 0);
			R2133_M7_EXTBG	: in  STD_LOGIC;

			--
			-- Output
			--
			BG1Index 		: out STD_LOGIC_VECTOR ( 7 downto 0);
			BG2Index 		: out STD_LOGIC_VECTOR ( 6 downto 0);
			BG3Index 		: out STD_LOGIC_VECTOR ( 1 downto 0);
			BG4Index 		: out STD_LOGIC_VECTOR ( 1 downto 0);
			
			BG1Palette		: out STD_LOGIC_VECTOR ( 2 downto 0);
			BG2Palette		: out STD_LOGIC_VECTOR ( 2 downto 0);
			BG3Palette		: out STD_LOGIC_VECTOR ( 2 downto 0);
			BG4Palette		: out STD_LOGIC_VECTOR ( 2 downto 0);

			BGPriority		: out STD_LOGIC_VECTOR ( 3 downto 0)
	);
end PPU_BGLineDecode;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_BGLineDecode of PPU_BGLineDecode is
	signal bg1_2	: STD_LOGIC_VECTOR ( 7 downto 0);
	signal bg1_4	: STD_LOGIC_VECTOR ( 7 downto 0);
	signal bg2_2	: STD_LOGIC_VECTOR ( 6 downto 0);
	signal bg2_4	: STD_LOGIC_VECTOR ( 6 downto 0);
	signal bg3_2	: STD_LOGIC_VECTOR ( 1 downto 0);
	signal bg4_2	: STD_LOGIC_VECTOR ( 1 downto 0);
	signal tmp8		: STD_LOGIC_VECTOR ( 7 downto 0);
	signal exts		: STD_LOGIC;
	
begin
	bg1_2	<= "000000" & PixelData(23 downto 22);
	bg1_4	<=   "0000" & PixelData(25 downto 22);

	bg2_4	<=    "000" & PixelData(19 downto 16); -- 4 BPP
	bg2_2	<=  "00000" & PixelData(17 downto 16); -- 2 BPP

	bg3_2	<=            PixelData(21 downto 20);

	bg4_2	<=            PixelData(27 downto 26);

	--         bg4_2                     bg3_2                     bg1_4
	tmp8	<= PixelData(27 downto 26) & PixelData(21 downto 20) & PixelData(25 downto 22); -- 8

	exts		<= R2133_M7_EXTBG;
	
	process(	R2105_BGMode,
				tmp8,
				bg1_4,
				bg1_2,
				bg2_2,
				bg2_4,
				bg3_2,
				bg4_2,
				exts,
				PixelData)
	begin
		case (R2105_BGMode) is
		when CONSTANTS.MODE0 =>
			-- 0 : 44xx 1133 xx22
			BG1Index <= bg1_2; -- 2
			BG2Index <= bg2_2; -- 2
			BG3Index <= bg3_2; -- 2
			BG4Index <= bg4_2; -- 2
			
		when CONSTANTS.MODE1 =>
			-- 1 : xx11 1133 2222
			BG1Index <= bg1_4; -- 4
			BG2Index <= bg2_4; -- 4
			BG3Index <= bg3_2; -- 2
			BG4Index <=  "00";

		when CONSTANTS.MODE2  =>
			-- 2 : xx11 11xx 2222
			BG1Index <= bg1_4; -- 4
			BG2Index <= bg2_4; -- 4
			BG3Index <=  "00";
			BG4Index <=  "00";
			
		when CONSTANTS.MODE3  =>
			-- 3 : 1111 1111 2222 <- 8 bit mode is encoded as [76321054]
			BG1Index <=  tmp8;
			BG2Index <= bg2_4; -- 4
			BG3Index <=  "00";
			BG4Index <=  "00";
			
		when CONSTANTS.MODE4  =>
			-- 4 : 1111 1111 xx22
			BG1Index <=  tmp8;
			BG2Index <= bg2_2; -- 2
			BG3Index <=  "00";
			BG4Index <=  "00";
			
		when CONSTANTS.MODE5  =>
			-- 5 : xx11 11xx xx22
			BG1Index <= bg1_4; -- 4
			BG2Index <= bg2_2; -- 2
			BG3Index <=  "00";
			BG4Index <=  "00";			 
		when CONSTANTS.MODE6  =>
			-- 6 : xx11 11xx xxxx
			BG1Index <= bg1_4; -- 4
			BG2Index <=	"0000000";
			BG3Index <=  "00";
			BG4Index <=  "00";
		when others =>
			-- 7 : 1111 1111 xxxx
			BG1Index <=  tmp8;
			BG2Index <=  tmp8(6 downto 0) and 	(	exts &
													exts &
													exts &
													exts &
													exts &
													exts &
													exts); -- 7
			BG3Index <=  "00";
			BG4Index <=  "00";
		end case;

		if (R2105_BGMode = CONSTANTS.MODE7) then
			BGPriority <= "00" & (exts and PixelData(27)) & "0";
		else 
			BGPriority <= PixelData( 3 downto 0 );
		end if;
	end process;
	--
	-- Second 16 bit block in pixel info : palette and priority as is.
	--
	BG4Palette <= PixelData(15 downto 13);
	BG3Palette <= PixelData(12 downto 10);
	BG2Palette <= PixelData( 9 downto 7 );
	BG1Palette <= PixelData( 6 downto 4 );
	
end PPU_BGLineDecode;
