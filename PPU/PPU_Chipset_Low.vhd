----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_ChipSet_Low.vhd
-- Module Name:		PPU_ChipSet_Low
--
-- TODO : Obj Unit.
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

entity PPU_Chipset_Low is
    Port ( 	
				--
				-- General Side.
				--
				clock				: in STD_LOGIC;
				reset				: in STD_LOGIC;
				drawPixel			: in STD_LOGIC;

				xCoord				: in STD_LOGIC_VECTOR(7 downto 0);
				
				--
				-- Memory Line Cache Side.
				--
				Address 			: out STD_LOGIC_VECTOR(7 downto 0);
				DataPixels 			: in  STD_LOGIC_VECTOR(27 downto 0);

				--
				-- Palette reading.
				--
				MainIndex			: out STD_LOGIC_VECTOR(7 downto 0);
				MainColor			: in  STD_LOGIC_VECTOR(14 downto 0);

				SubIndex			: out STD_LOGIC_VECTOR(7 downto 0);
				SubColor			: in  STD_LOGIC_VECTOR(14 downto 0);
				
				--
				-- Register Side.
				--
				
				--- Same stuff computed in main/sub unit.
				-- BGEnabledMain		: in STD_LOGIC_VECTOR (3 downto 0);
				-- BGEnabledSub			: in STD_LOGIC_VECTOR (3 downto 0);
				
				R2100_DisplayEnabled	: in STD_LOGIC;
				R2100_Brigthness		: in STD_LOGIC_VECTOR (3 downto 0);

				R2105_BGMode			: in STD_LOGIC_VECTOR (2 downto 0);
				R2105_BG3Priority		: in STD_LOGIC;

				-- Note : top 5,4 -> OBJ/COL, 0..3 -> BG NUM by convention.
				R21232425_W1_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0);
				R21232425_W2_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0);
				R21232425_W1_INV		: in STD_LOGIC_VECTOR (5 downto 0);
				R21232425_W2_INV		: in STD_LOGIC_VECTOR (5 downto 0);
				
				R2126_W1_LEFT			: in STD_LOGIC_VECTOR (7 downto 0);
				R2127_W1_RIGHT			: in STD_LOGIC_VECTOR (7 downto 0);
				R2128_W2_LEFT			: in STD_LOGIC_VECTOR (7 downto 0);
				R2129_W2_RIGHT			: in STD_LOGIC_VECTOR (7 downto 0);
				
				R212AB_WMASK_LSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
				R212AB_WMASK_MSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
				
				R212C_MAIN				: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
				R212D_SUB				: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
				
				R212E_WMASK_MAIN		: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
				R212F_WMASK_SUB			: in STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj

				R2130_CLIPCOLORMATH		: in STD_LOGIC_VECTOR (1 downto 0);
				R2130_PREVENTCOLORMATH	: in STD_LOGIC_VECTOR (1 downto 0);
				R2130_ADDSUBSCR			: in STD_LOGIC;
				R2130_DIRECTCOLOR		: in STD_LOGIC;

				R2131_COLORMATH_SUB		: in STD_LOGIC;
				R2131_COLORMATH_HALF	: in STD_LOGIC;
				R2131_ENABLEMATH_UNIT	: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Backdrop

				R2132_FIXEDCOLOR_R		: in STD_LOGIC_VECTOR (4 downto 0);
				R2132_FIXEDCOLOR_G		: in STD_LOGIC_VECTOR (4 downto 0);
				R2132_FIXEDCOLOR_B		: in STD_LOGIC_VECTOR (4 downto 0);
								
				R2133_M7_EXTBG			: in  STD_LOGIC;

				--
				-- Video Side
				--
				Red				: out STD_LOGIC_VECTOR(4 downto 0);
				Green			: out STD_LOGIC_VECTOR(4 downto 0);
				Blue			: out STD_LOGIC_VECTOR(4 downto 0)
	);
end PPU_ChipSet_Low;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture ArchiPPU_ChipSetLow of PPU_ChipSet_Low is
	
	component PPU_BRIGHTNESS is
		Port (
			Rin			: in  STD_LOGIC_VECTOR (4 downto 0);
			Gin			: in  STD_LOGIC_VECTOR (4 downto 0);
			Bin			: in  STD_LOGIC_VECTOR (4 downto 0);
			BrightNess	: in  STD_LOGIC_VECTOR (3 downto 0);

			ROut: out  STD_LOGIC_VECTOR (4 downto 0);
			GOut: out  STD_LOGIC_VECTOR (4 downto 0);
			BOut: out  STD_LOGIC_VECTOR (4 downto 0)
		);
	end component;

	component PPU_BGLineDecode is
		Port (
			PixelData 		: in  STD_LOGIC_VECTOR (27 downto 0); -- 12 BPP + 16 (4 prio + 4xPPP) = 28

			R2105_BGMode	: in  STD_LOGIC_VECTOR ( 2 downto 0);
			R2133_M7_EXTBG	: in  STD_LOGIC;

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
	end component;

	component PPU_MainSub is
		Port ( 	
			clock			: in STD_LOGIC;
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
			
			R21232425_W1_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R21232425_W2_ENABLE		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R21232425_W1_INV		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R21232425_W2_INV		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
						
			R212AB_WMASK_LSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
			R212AB_WMASK_MSB		: in STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
						
			W1_Inside		: in STD_LOGIC;
			W2_Inside		: in STD_LOGIC;
			
			PaletteIndex	: out STD_LOGIC_VECTOR( 7 downto 0);
			ColorIn			: in  STD_LOGIC_VECTOR(14 downto 0);
			
			RGB				: out STD_LOGIC_VECTOR(14 downto 0);
			selectOut		: out STD_LOGIC_VECTOR( 2 downto 0)
		);
	end component;
	
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

	component PPU_OutputPixel is
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
	end component;
	
	signal insideW1		: STD_LOGIC;
	signal insideW2		: STD_LOGIC;
	signal regInsideW1	: STD_LOGIC;
	signal regInsideW2	: STD_LOGIC;
	
	signal sBG1Index	: STD_LOGIC_VECTOR ( 7 downto 0);
	signal sBG2Index	: STD_LOGIC_VECTOR ( 6 downto 0);
	signal sBG3Index	: STD_LOGIC_VECTOR ( 1 downto 0);
	signal sBG4Index	: STD_LOGIC_VECTOR ( 1 downto 0);
	
	signal sBG1Palette	: STD_LOGIC_VECTOR ( 2 downto 0);
	signal sBG2Palette	: STD_LOGIC_VECTOR ( 2 downto 0);
	signal sBG3Palette	: STD_LOGIC_VECTOR ( 2 downto 0);
	signal sBG4Palette	: STD_LOGIC_VECTOR ( 2 downto 0);
	
	signal sBGPriority	: STD_LOGIC_VECTOR ( 3 downto 0);
	
	signal sObjIndex	: STD_LOGIC_VECTOR ( 3 downto 0);
	signal sObjPalette	: STD_LOGIC_VECTOR ( 2 downto 0);
	signal sObjPriority	: STD_LOGIC_VECTOR ( 1 downto 0);

	signal sMainColor, sSubColor, sMixColor : STD_LOGIC_VECTOR (14 downto 0);
	signal selectMain, selectSub : STD_LOGIC_VECTOR(2 downto 0);
	
	signal winMsk : STD_LOGIC_VECTOR (1 downto 0);
	signal insideColor, ALWAYS_ENABLE_HERE : STD_LOGIC;

	signal insideColSub, insideColMain, regInsideColSub, regInsideColMain : STD_LOGIC;

begin
	----------------------------------------------------------
	--  Cycle 0 : Window / Line Read.
	----------------------------------------------------------

	--
	-- Window clipping.
	--
	process(clock, xCoord, R2126_W1_LEFT,R2127_W1_RIGHT,R2128_W2_LEFT,R2129_W2_RIGHT )
	begin
		if ((xCoord >= R2126_W1_LEFT) and (xCoord <= R2127_W1_RIGHT)) then
			insideW1 <= '1';
		else
			insideW1 <= '0';
		end if;
		
		if ((xCoord >= R2128_W2_LEFT) and (xCoord <= R2129_W2_RIGHT)) then
			insideW2 <= '1';
		else
			insideW2 <= '0';
		end if;
		
		--
		-- Pipeline Window to match cache line pixel read. (1 cycle)
		--
		if rising_edge(clock) then
			regInsideW1 <= insideW1;
			regInsideW2 <= insideW2;
		end if;
	end process;
	
	--
	-- Pixel Read
	--
	Address <= xCoord;

	----------------------------------------------------------
	--  Cycle 1 : Process pixel (Window has been piped)
	----------------------------------------------------------
	
	instanceLineDecode : PPU_BGLineDecode port map
	(
			PixelData		=> DataPixels,

			R2105_BGMode	=> R2105_BGMode,
			R2133_M7_EXTBG	=> R2133_M7_EXTBG,

			BG1Index		=> sBG1Index,
			BG2Index 		=> sBG2Index,
			BG3Index 		=> sBG3Index,
			BG4Index 		=> sBG4Index,
			
			BG1Palette		=> sBG1Palette,
			BG2Palette		=> sBG2Palette,
			BG3Palette		=> sBG3Palette,
			BG4Palette		=> sBG4Palette,
			
			BGPriority		=> sBGPriority
	);

	--
	-- Directly use main output.
	--
	
--	MainIndex <= "0" & sBG2Palette & sBG2Index(3 downto 0);
--  BG2
--	MainIndex	<= '0' & DataPixels(9 downto 7) & DataPixels(19 downto 16);
--	Red			<= MainColor(4 downto 0);
--	Green		<= MainColor(9 downto 5);
--	Blue		<= MainColor(14 downto 10);

-- BG3
--	MainIndex	<= "000" & sBG3Palette & sBG3Index(1 downto 0);
	MainIndex	<= "000" & DataPixels(12 downto 10) & DataPixels(21 downto 20); -- BG3
--	MainIndex	<= "0" & DataPixels(9 downto 7) & DataPixels(19 downto 16); -- BG2
--	MainIndex	<= "0" & DataPixels(6 downto 4) & DataPixels(25 downto 22); -- BG1
	Red			<= MainColor(4 downto 0);
	Green		<= MainColor(9 downto 5);
	Blue		<= MainColor(14 downto 10);
--	Red			<= DataPixels(25 downto 22) & '0';
--	Green		<= DataPixels(25 downto 22) & '0';
--	Blue		<= DataPixels(25 downto 22) & '0';
--	process(DataPixels)
--	begin
--		case DataPixels(19 downto 16) is
--		when "0000" =>
--			Red			<= "00000";
--			Green		<= "00000";
--			Blue		<= "00000";
--		when "0001" =>
--			Red			<= "11111";
--			Green		<= "00000";
--			Blue		<= "00000";
--		when "0010" =>
--			Red			<= "00000";
--			Green		<= "11111";
--			Blue		<= "00000";
--		when "0011" =>
--			Red			<= "00000";
--			Green		<= "10000";
--			Blue		<= "00000";
--		when "0100" =>
--			Red			<= "00000";
--			Green		<= "00000";
--			Blue		<= "11111";
--		when "0101" =>
--			Red			<= "00000";
--			Green		<= "00000";
--			Blue		<= "10000";
--		when "0110" =>
--			Red			<= "11111";
--			Green		<= "00000";
--			Blue		<= "11111";
--		when "0111" =>
--			Red			<= "10000";
--			Green		<= "00000";
--			Blue		<= "10000";
--		when "1000" =>
--			Red			<= "11111";
--			Green		<= "11111";
--			Blue		<= "00000";
--		when "1001" =>
--			Red			<= "10000";
--			Green		<= "10000";
--			Blue		<= "00000";
--		when "1010" =>
--			Red			<= "00000";
--			Green		<= "11111";
--			Blue		<= "11111";
--		when "1011" =>
--			Red			<= "00000";
--			Green		<= "10000";
--			Blue		<= "10000";
--		when "1100" =>
--			Red			<= "10000";
--			Green		<= "11111";
--			Blue		<= "10000";
--		when "1101" =>
--			Red			<= "10000";
--			Green		<= "10000";
--			Blue		<= "11111";
--		when "1110" =>
--			Red			<= "11111";
--			Green		<= "11111";
--			Blue		<= "11111";
--		when others =>
--			Red			<= "10000";
--			Green		<= "10000";
--			Blue		<= "10000";
--		end case;
--	end process;

	--
	-- TODO : Sprite Complete unit : x -> OBJ Pixel / Prio / Valid
	--
	
--	--
--	-- Main Unit
--	--
--	instanceMain : PPU_MainSub port map
--	( 	
--		clock				=> clock,
--		R2105_BGMode 		=> R2105_BGMode,
--		R2105_BG3Priority	=> R2105_BG3Priority,
--		Enable_BG			=> R212C_MAIN,
--		Enable_Win			=> R212E_WMASK_MAIN,
--		
--		R2130_DIRECTCOLOR	=> R2130_DIRECTCOLOR,
--		
--		BG1Index			=> sBG1Index,
--		BG2Index			=> sBG2Index,
--		BG3Index			=> sBG3Index,
--		BG4Index			=> sBG4Index,
--		
--		BG1Palette			=> sBG1Palette,
--		BG2Palette			=> sBG2Palette,
--		BG3Palette			=> sBG3Palette,
--		BG4Palette			=> sBG4Palette,
--
--		BGPriority			=> sBGPriority,
--		
--		OBJIndex			=> sObjIndex,
--		OBJPalette			=> sObjPalette,
--		OBJPriority			=> sObjPriority,
--		
--		R21232425_W1_ENABLE	=> R21232425_W1_ENABLE,
--		R21232425_W2_ENABLE	=> R21232425_W2_ENABLE,
--		R21232425_W1_INV	=> R21232425_W1_INV,
--		R21232425_W2_INV	=> R21232425_W2_INV,
--					
--		R212AB_WMASK_LSB	=> R212AB_WMASK_LSB,
--		R212AB_WMASK_MSB	=> R212AB_WMASK_MSB,
--					
--		W1_Inside			=> regInsideW1,
--		W2_Inside			=> regInsideW2,
--		
--		PaletteIndex		=> MainIndex, -- out
--		ColorIn				=> MainColor,
--		
--		RGB					=> sMainColor,
--		selectOut			=> selectMain
--	);
--
--	--
--	-- Sub Unit
--	--
--	instanceSub : PPU_MainSub port map
--	(
--		clock				=> clock,
--		R2105_BGMode 		=> R2105_BGMode,
--		R2105_BG3Priority	=> R2105_BG3Priority,
--		Enable_BG			=> R212D_SUB,
--		Enable_Win			=> R212F_WMASK_SUB,
--		
--		R2130_DIRECTCOLOR	=> R2130_DIRECTCOLOR,
--		
--		BG1Index			=> sBG1Index,
--		BG2Index			=> sBG2Index,
--		BG3Index			=> sBG3Index,
--		BG4Index			=> sBG4Index,
--		
--		BG1Palette			=> sBG1Palette,
--		BG2Palette			=> sBG2Palette,
--		BG3Palette			=> sBG3Palette,
--		BG4Palette			=> sBG4Palette,
--
--		BGPriority			=> sBGPriority,
--		
--		OBJIndex			=> sObjIndex,
--		OBJPalette			=> sObjPalette,
--		OBJPriority			=> sObjPriority,
--		
--		R21232425_W1_ENABLE	=> R21232425_W1_ENABLE,
--		R21232425_W2_ENABLE	=> R21232425_W2_ENABLE,
--		R21232425_W1_INV	=> R21232425_W1_INV,
--		R21232425_W2_INV	=> R21232425_W2_INV,
--					
--		R212AB_WMASK_LSB	=> R212AB_WMASK_LSB,
--		R212AB_WMASK_MSB	=> R212AB_WMASK_MSB,
--					
--		W1_Inside			=> regInsideW1,
--		W2_Inside			=> regInsideW2,
--		
--		PaletteIndex		=> SubIndex,
--		ColorIn				=> SubColor,
--		
--		RGB					=> sSubColor,
--		selectOut			=> selectSub
--	);
--
--	--
--	-- Window Color Management.
--	--
--	winMsk <= R212AB_WMASK_MSB(5) & R212AB_WMASK_LSB(5);
--	ALWAYS_ENABLE_HERE <= '1';
--	instanceWC_Color : PPU_WindowClip port map
--	( 	InsideW1	=> regInsideW1,
--		InsideW2	=> regInsideW2,
--		EnableW1	=> R21232425_W1_ENABLE(5),
--		EnableW2	=> R21232425_W2_ENABLE(5),
--		InversionW1	=> R21232425_W1_INV(5),
--		InversionW2	=> R21232425_W2_INV(5),
--		EnableSubMain
--					=> ALWAYS_ENABLE_HERE,
--		WindowMaskLogicReg
--					=> winMsk,
--		inside		=> insideColor -- Out
--	);
--
--	--
--	process(clock, R2130_CLIPCOLORMATH, R2130_PREVENTCOLORMATH, insideColor)
--	begin
--		case R2130_CLIPCOLORMATH is
--		when CONSTANTS.NEVER =>
--			insideColMain	<= '0'; -- Never
--		when CONSTANTS.OUTSIDE =>
--			insideColMain	<= not(insideColor); -- Outside
--		when CONSTANTS.INSIDE =>
--			insideColMain	<= insideColor; -- Inside
--		when others =>
--			insideColMain	<= '1'; -- Always
--		end case;
--
--		case R2130_PREVENTCOLORMATH is
--		when CONSTANTS.NEVER =>
--			insideColSub	<= '0'; -- Never
--		when CONSTANTS.OUTSIDE =>
--			insideColSub	<= not(insideColor); -- Outside
--		when CONSTANTS.INSIDE =>
--			insideColSub	<= insideColor; -- Inside
--		when others =>
--			insideColSub	<= '1'; -- Always.
--		end case;
--
--		--
--		-- Pipeline Color Window to match palette read.
--		--
--		if rising_edge(clock) then
--			regInsideColSub  <= insideColSub;
--			regInsideColMain <= insideColMain;
--		end if;
--	end process;
--	
--	----------------------------------------------------------------------------------------
--	--  Cycle 2 : Palette reading has occured or Direct color piped / color window piped.
--	----------------------------------------------------------------------------------------
--	
--	--
--	-- Pixel Blend Instance
--	--
--	instanceColorProcess : PPU_OutputPixel port map
--	(
--		winColSubInside 	=> regInsideColSub,
--		winColMainInside 	=> regInsideColMain,
--		mainColor 			=> sMainColor,
--		mainSelect 			=> selectMain,
--		subColor 			=> sSubColor,
--		subSelect 			=> selectSub,
--		enableMath_2131 	=> R2131_ENABLEMATH_UNIT,
--		fixedColorR			=> R2132_FIXEDCOLOR_R,
--		fixedColorG			=> R2132_FIXEDCOLOR_G,
--		fixedColorB			=> R2132_FIXEDCOLOR_B,
--		addSubScreen_2130 	=> R2130_ADDSUBSCR,
--		addSub_2131 		=> R2131_COLORMATH_SUB,
--		half_2130 			=> R2131_COLORMATH_HALF,
--		 
--		resultColor 		=> sMixColor
--	);
--	
--	--
--	-- Brightness
--	--
--	instanceBrightness : PPU_BRIGHTNESS port map
--	(
--		-- BGR order.
--		Rin		=> sMixColor(4 downto 0),
--		Gin		=> sMixColor(9 downto 5),
--		Bin		=> sMixColor(14 downto 10),
--		
--		BrightNess	=> R2100_Brigthness,
--
--		ROut	=> Red,
--		GOut	=> Green,
--		BOut	=> Blue
--	);
end ArchiPPU_ChipSetLow;
