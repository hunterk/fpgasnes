----------------------------------------------------------------------------------
-- Create Date:   	 
-- Design Name:		
-- Module Name:		
--
-- Description: 	
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

entity PPU_MainSub is
    Port ( 	
			clock			: in STD_LOGIC;
			
			--
			-- Input
			--

			R2105_BGMode	: in  STD_LOGIC_VECTOR ( 2 downto 0);
			R2105_BG3Priority
							: in STD_LOGIC;
			
			Enable_BG		: in  STD_LOGIC_VECTOR ( 4 downto 0); -- 212C or 212D (Main/Sub)
			Enable_Win		: in  STD_LOGIC_VECTOR ( 4 downto 0); -- R212E_WMASK_MAIN / R212F_WMASK_SUB
			
			R2130_DIRECTCOLOR	: in STD_LOGIC;
			
			BG1Index 		: in STD_LOGIC_VECTOR ( 7 downto 0);
			BG2Index 		: in STD_LOGIC_VECTOR ( 6 downto 0);
			BG3Index 		: in STD_LOGIC_VECTOR ( 1 downto 0);
			BG4Index 		: in STD_LOGIC_VECTOR ( 1 downto 0);
			
			BG1Palette		: in STD_LOGIC_VECTOR ( 2 downto 0);
			BG2Palette		: in STD_LOGIC_VECTOR ( 2 downto 0);
			BG3Palette		: in STD_LOGIC_VECTOR ( 2 downto 0);
			BG4Palette		: in STD_LOGIC_VECTOR ( 2 downto 0);

			BGPriority		: in STD_LOGIC_VECTOR ( 3 downto 0);
			
			OBJIndex		: in STD_LOGIC_VECTOR ( 3 downto 0);
			OBJPalette		: in STD_LOGIC_VECTOR ( 2 downto 0);
			OBJPriority		: in STD_LOGIC_VECTOR ( 1 downto 0);
			
			---
			--- Window General Side
			---
			R21232425_W1_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R21232425_W2_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R21232425_W1_INV		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R21232425_W2_INV		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
						
			R212AB_WMASK_LSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R212AB_WMASK_MSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
						
			
			---
			--- Window Pixel Side
			---
			W1_Inside		: in STD_LOGIC;
			W2_Inside		: in STD_LOGIC;
			
			---
			--- CGRAM Read Side
			---
			PaletteIndex	: out STD_LOGIC_VECTOR( 7 downto 0);
			ColorIn			: in  STD_LOGIC_VECTOR(14 downto 0);
			
			---
			--- RGB Output
			---
			RGB				: out STD_LOGIC_VECTOR(14 downto 0);
			selectOut		: out STD_LOGIC_VECTOR(2 downto 0)
			);
end PPU_MainSub;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_MainSub of PPU_MainSub is
	component PPU_WindowClip is
		Port ( 	
			InsideW1 : in STD_LOGIC;
			InsideW2 : in STD_LOGIC;
			EnableW1 : in STD_LOGIC;
			EnableW2 : in STD_LOGIC;
			InversionW1 : in STD_LOGIC;
			InversionW2 : in STD_LOGIC;
			EnableSubMain : in STD_LOGIC;
			WindowMaskLogicReg : in STD_LOGIC_VECTOR(1 downto 0);			
			inside	 : out STD_LOGIC
		);
	end component;

	component PPU_PriorityUnit is
		Port (
			BG4_valid			: in STD_LOGIC;
			BG3_valid			: in STD_LOGIC;
			BG2_valid			: in STD_LOGIC;
			BG1_valid			: in STD_LOGIC;
			OBJ_valid			: in STD_LOGIC;
			BG4_TilePrio		: in STD_LOGIC;
			BG3_TilePrio		: in STD_LOGIC;
			BG2_TilePrio		: in STD_LOGIC;
			BG1_TilePrio		: in STD_LOGIC;
			OBJ_Prio			: in STD_LOGIC_VECTOR(1 downto 0);

			mode				: in STD_LOGIC_VECTOR(2 downto 0);
			b2105_3				: in STD_LOGIC;	-- Priority bit BG3 for mode 1

			unitSelect			: out STD_LOGIC_VECTOR(2 downto 0)
		);
	end component;

	signal bg0_WC, bg1_WC, bg2_WC, bg3_WC, Obj_WC : STD_LOGIC;
	signal winMsk0,winMsk1,winMsk2,winMsk3,winMskObj,winMskCol : STD_LOGIC_VECTOR(1 downto 0);

	signal unitOut		: STD_LOGIC_VECTOR(2 downto 0);
	signal 	prioBG1Valid,
			prioBG2Valid,
			prioBG3Valid,
			prioBG4Valid,
			prioOBJValid	: STD_LOGIC;
	
	signal indexSelect		: STD_LOGIC_VECTOR(7 downto 0);
	signal BG1NZero			: STD_LOGIC;
	signal directRGB
	     , regDirectRGB		: STD_LOGIC_VECTOR(14 downto 0);
		 
	signal directColor		: STD_LOGIC;
	
	signal validBG2Idx,validBG3Idx,validBG4Idx,validOBJIdx		: STD_LOGIC;

	constant PAL_004COL		: STD_LOGIC_VECTOR := "00";
	constant PAL_016COL		: STD_LOGIC_VECTOR := "01";
	constant PAL_256COL		: STD_LOGIC_VECTOR := "10";
	constant PAL_WHOCARE	: STD_LOGIC_VECTOR := "00";
begin
	--
	-- BG 1 Window Clipping.
	--
	winMsk0 <= R212AB_WMASK_MSB(0) & R212AB_WMASK_LSB(0);
	instanceWC_BG1 : PPU_WindowClip port map
	( 	InsideW1	=> W1_Inside,
		InsideW2	=> W2_Inside,
		EnableW1	=> R21232425_W1_ENABLE(0),
		EnableW2	=> R21232425_W2_ENABLE(0),
		InversionW1	=> R21232425_W1_INV(0),
		InversionW2	=> R21232425_W2_INV(0),
		EnableSubMain
					=> Enable_Win(0),
		WindowMaskLogicReg
					=> winMsk0,
		inside		=> bg0_WC -- Out
	);
	
	--
	-- BG 2 Window Clipping.
	--
	winMsk1 <= R212AB_WMASK_MSB(1) & R212AB_WMASK_LSB(1);
	instanceWC_BG2 : PPU_WindowClip port map
	( 	InsideW1	=> W1_Inside,
		InsideW2	=> W2_Inside,
		EnableW1	=> R21232425_W1_ENABLE(1),
		EnableW2	=> R21232425_W2_ENABLE(1),
		InversionW1	=> R21232425_W1_INV(1),
		InversionW2	=> R21232425_W2_INV(1),
		EnableSubMain
					=> Enable_Win(1),
		WindowMaskLogicReg
					=> winMsk1,
		inside		=> bg1_WC -- Out
	);
	--
	-- BG 3 Window Clipping.
	--
	winMsk2 <= R212AB_WMASK_MSB(2) & R212AB_WMASK_LSB(2);
	instanceWC_BG3 : PPU_WindowClip port map
	( 	InsideW1	=> W1_Inside,
		InsideW2	=> W2_Inside,
		EnableW1	=> R21232425_W1_ENABLE(2),
		EnableW2	=> R21232425_W2_ENABLE(2),
		InversionW1	=> R21232425_W1_INV(2),
		InversionW2	=> R21232425_W2_INV(2),
		EnableSubMain
					=> Enable_Win(2),
		WindowMaskLogicReg
					=> winMsk2,
		inside		=> bg2_WC -- Out
	);
	
	--
	-- BG 4 Window Clipping.
	--
	winMsk3 <= R212AB_WMASK_MSB(3) & R212AB_WMASK_LSB(3);
	instanceWC_BG4 : PPU_WindowClip port map
	( 	InsideW1	=> W1_Inside,
		InsideW2	=> W2_Inside,
		EnableW1	=> R21232425_W1_ENABLE(3),
		EnableW2	=> R21232425_W2_ENABLE(3),
		InversionW1	=> R21232425_W1_INV(3),
		InversionW2	=> R21232425_W2_INV(3),
		EnableSubMain
					=> Enable_Win(3),
		WindowMaskLogicReg
					=> winMsk3,
		inside		=> bg3_WC -- Out
	);
	
	--
	-- TODO OBJ Window Clipping.
	--
	Obj_WC <= '1';
	
	--
	-- Direct color transform.
	--
	-- BG1 Index = BB GGG RRR 
	-- ppp -> bgr
	process (BG1Index,BG1Palette, R2130_DIRECTCOLOR, BG2Index, BG3Index, BG4Index, OBJIndex,BG1NZero)
		variable nPPP : STD_LOGIC;
	begin
		if (BG1Index /= "00000000") then
			BG1NZero 	<= '1';
		else
			BG1NZero 	<= '0';
		end if;
		
		directRGB   <= BG1Index(7 downto 6) & BG1Palette(2) & "00" -- BBb00
					&  BG1Index(5 downto 3) & BG1Palette(1) & "0"  -- GGGg0
					&  BG1Index(2 downto 0) & BG1Palette(0) & "0"; -- RRRr0

		if (BG1Palette /= "000") then
			nPPP := '1';
		else
			nPPP := '0';
		end if;

		if (((BG1NZero='1' or nPPP='1') and R2130_DIRECTCOLOR='1') or (R2130_DIRECTCOLOR='0')) then
			directColor <= '1';
		else
			directColor <= '0';
		end if;
		
		if (BG2Index /= "000000") then
			validBG2Idx <= '1';
		else
			validBG2Idx <= '0';
		end if;

		if (BG3Index /= "00") then
			validBG3Idx <= '1';
		else
			validBG3Idx <= '0';
		end if;
		
		if (BG4Index /= "00") then
			validBG4Idx <= '1';
		else
			validBG4Idx <= '0';
		end if;

		if (OBJIndex /= "0000") then
			validOBJIdx <= '1';
		else
			validOBJIdx <= '0';
		end if;
	end process;
	
	--
	-- Priority.
	--
	prioBG1Valid <= bg0_WC and Enable_BG(0) and BG1NZero and directColor;
	prioBG2Valid <= bg1_WC and Enable_BG(1) and validBG2Idx;
	prioBG3Valid <= bg2_WC and Enable_BG(2) and validBG3Idx;
	prioBG4Valid <= bg3_WC and Enable_BG(3) and validBG4Idx;
	prioOBJValid <= Obj_WC and Enable_BG(4) and validOBJIdx;
	
	instPrioUnit : PPU_PriorityUnit port map
	(
		BG4_valid		=> prioBG4Valid,
		BG3_valid		=> prioBG3Valid,
		BG2_valid		=> prioBG2Valid,
		BG1_valid		=> prioBG1Valid,
		OBJ_valid		=> prioOBJValid,

		BG4_TilePrio	=> BGPriority(3),
		BG3_TilePrio	=> BGPriority(2),
		BG2_TilePrio	=> BGPriority(1),
		BG1_TilePrio	=> BGPriority(0),
		OBJ_Prio		=> OBJPriority,

		mode			=> R2105_BGMode,
		b2105_3			=> R2105_BG3Priority,
		
		unitSelect		=> unitOut
	);

	--
	-- Pixel selector based on output.
	--
	process (unitOut, R2105_BGMode,OBJPalette, OBJIndex, BG1Index, BG1Palette, BG2Index, BG2Palette, BG3Index, BG3Palette, BG4Index, BG4Palette)
		variable BgPalIdx 	: STD_LOGIC_VECTOR(1 downto 0);
		variable BgSize		: STD_LOGIC_VECTOR(1 downto 0);
		variable pal		: STD_LOGIC_VECTOR(2 downto 0);
		variable pal2		: STD_LOGIC_VECTOR(5 downto 0);
		variable index		: STD_LOGIC_VECTOR(7 downto 0);
		
	begin
		---
		--- Compute the size of the BG based on mode.
		--- 
		case R2105_BGMode is
		when CONSTANTS.MODE0 =>
			BgSize := PAL_004COL; -- All BG 4 Colors.
		when CONSTANTS.MODE1 =>
			case unitOut is
			when CONSTANTS.BG1_SEL =>
				BgSize := PAL_016COL; -- BG 1: 16 Col
			when CONSTANTS.BG2_SEL =>
				BgSize := PAL_016COL; -- BG 2: 16 Col
			when CONSTANTS.BG3_SEL =>
				BgSize := PAL_004COL; -- BG 3
			when others =>
				BgSize := PAL_WHOCARE; --
			end case;
		when CONSTANTS.MODE2 =>
			case unitOut is
			when CONSTANTS.BG1_SEL =>
				BgSize := PAL_016COL; -- BG 1: 16 Col
			when CONSTANTS.BG2_SEL =>
				BgSize := PAL_016COL; -- BG 2: 16 Col
			when others =>
				BgSize := PAL_WHOCARE; -- BG3/4/Other
			end case;
		when CONSTANTS.MODE3 =>
			case unitOut is
			when CONSTANTS.BG1_SEL =>
				BgSize := PAL_256COL; -- BG 1: 256 Col
			when CONSTANTS.BG2_SEL =>
				BgSize := PAL_016COL; -- BG 2: 16 Col
			when others =>
				BgSize := PAL_WHOCARE; -- BG3/4/Other
			end case;
		when CONSTANTS.MODE4 =>
			case unitOut is
			when CONSTANTS.BG1_SEL =>
				BgSize := PAL_256COL; -- BG 1: 256 Col
			when CONSTANTS.BG2_SEL =>
				BgSize := PAL_004COL; -- BG 2: 4 Col
			when others =>
				BgSize := PAL_WHOCARE; -- BG3/4/Other
			end case;
		when CONSTANTS.MODE5 =>
			case unitOut is
			when CONSTANTS.BG1_SEL =>
				BgSize := PAL_016COL; -- BG 1: 16 Col
			when CONSTANTS.BG2_SEL =>
				BgSize := PAL_004COL; -- BG 2: 4 Col
			when others =>
				BgSize := PAL_WHOCARE; -- BG3/4/Other
			end case;
		when CONSTANTS.MODE6 =>
			case unitOut is
			when CONSTANTS.BG1_SEL =>
				BgSize := PAL_016COL; -- BG 1: 16 Col
			when CONSTANTS.BG2_SEL =>
				BgSize := PAL_004COL; -- BG 2: 4 Col
			when others =>
				BgSize := PAL_WHOCARE; -- BG3/4/Other
			end case;
		when others =>
			-- Mode 7 : 8 Bit.
			BgSize := PAL_256COL; 
		end case;
		
		---
		--- Index inside palette.
		--- 
		case unitOut is
		when CONSTANTS.OBJECTS_SEL =>
			index := "1" & OBJPalette & OBJIndex;
			pal   := "000";
		when CONSTANTS.BG1_SEL =>
			index := BG1Index;
			pal   := BG1Palette;
		when CONSTANTS.BG2_SEL =>
			index := "0" & BG2Index;
			pal   := BG2Palette;
		when CONSTANTS.BG3_SEL =>
			index := "000000" & BG3Index;
			pal   := BG3Palette;
		when CONSTANTS.BG4_SEL =>
			index := "000000" & BG4Index;
			pal   := BG4Palette;
		when others => -- BACKDROP
			index := "00000000"; -- TODO : Is back drop color palette 0 ???
			pal   := "000";
		end case;
		
		---
		--- Special offset for mode 0
		--- 
		if (R2105_BGMode = CONSTANTS.MODE0) then
			case unitOut is
			when CONSTANTS.BG1_SEL =>
				BgPalIdx	:= "00";
			when CONSTANTS.BG2_SEL =>
				BgPalIdx	:= "01";
			when CONSTANTS.BG3_SEL =>
				BgPalIdx	:= "10";
			when CONSTANTS.BG4_SEL =>
				BgPalIdx	:= "11";
			when others =>
				BgPalIdx	:= "00";
			end case;
			
			indexSelect <= '0' & BGPalIdx & pal & index(1 downto 0);
		else
			---
			--- Select correct palette and compute final index.
			--- 
			case BgSize is
			when PAL_004COL =>
				pal2 := "000" & pal;
			when PAL_016COL =>
				pal2 := "0" & pal & "00";
			when others =>
				pal2 := "000000";
			end case;
		
			indexSelect <= index + (pal2 & "00");
		end if;
	end process;

	--
	-- Pixel Output.
	--

	-- Pipe if we use direct color (no palette read)
	process (clock, directRGB)
	begin
		if rising_edge(clock) then
			regDirectRGB <= directRGB;
		end if;
	end process;
	
	process (R2130_DIRECTCOLOR, unitOut, indexSelect
			,ColorIn, regDirectRGB)
	begin
		PaletteIndex <= indexSelect; -- Read Current pixel
		
		-- Get RGB Value for PREVIOUS PIXEL.
		if (R2130_DIRECTCOLOR='1' and unitOut = CONSTANTS.BG1_SEL) then
			RGB <= regDirectRGB;
		else
			RGB <= ColorIn;
		end if;
	end process;
	
	selectOut <= unitOut;
	
end PPU_MainSub;

