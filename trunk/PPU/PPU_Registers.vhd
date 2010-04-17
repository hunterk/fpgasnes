----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_Registers.vhd
-- Module Name:		PPU_Registers
-- Description:		Handle all the register read/write setup of the PPU
--
-- TODO : All read.
-- TODO : OAM Read/Write, CGRAM Read/Write, VRAM Read/Write.
-- TODO : First Sprite logic here.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use CONSTREG.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_Registers is
    Port ( 	
				clock				: in STD_LOGIC;
				reset				: in STD_LOGIC;
			
				-- ##############################################################
				-- CPU Side.
				-- ##############################################################
				Address 			: in STD_LOGIC_VECTOR(5 downto 0);
				CPUwrite			: in STD_LOGIC;
				DataIn	  			: in  STD_LOGIC_VECTOR(7 downto 0);
				DataOut	  			: out STD_LOGIC_VECTOR(7 downto 0);

				-- ##############################################################
				-- Module VRAM Read / Write Side
				-- ##############################################################
				VRAMAddress_PostTranslation : out STD_LOGIC_VECTOR(14 downto 0);
				VRAMDataIn	 		: in  STD_LOGIC_VECTOR(15 downto 0);
				VRAMDataOut	  		: out STD_LOGIC_VECTOR(7 downto 0);
				-- Need both to allow arbitration with other blocks using VRAM.
				VRAMwrite			: out STD_LOGIC;
				VRAMread			: out STD_LOGIC;
				VRAMlowHigh			: out STD_LOGIC;
				
				-- ##############################################################
				-- Module CGRAM Read / Write Side
				-- ##############################################################
				CGRAMAddress		: out STD_LOGIC_VECTOR(7 downto 0);
				CGRAMDataIn			: in  STD_LOGIC_VECTOR(14 downto 0);
				CGRAMDataOut		: out STD_LOGIC_VECTOR(14 downto 0);
				-- Need both to allow arbitration with other blocks using Palette
				CGRAMwrite			: out STD_LOGIC;
				
				-- ##############################################################
				--   PPU Register exposed to rendering logic blocks + internal Logic
				-- ##############################################################
				
				R2100_DisplayEnabled	: out STD_LOGIC;
				R2100_Brigthness		: out STD_LOGIC_VECTOR (3 downto 0);
				
				R2101_OAMBaseSize		: out STD_LOGIC_VECTOR (2 downto 0); 
				R2101_OAMNameSelect		: out STD_LOGIC_VECTOR (1 downto 0);
				R2101_OAMNameBase		: out STD_LOGIC_VECTOR (2 downto 0);
				-- BSnes has cache version.

				R2102_OAMPriority		: out STD_LOGIC;
				R2102_OAMBaseAdr		: out STD_LOGIC_VECTOR (8 downto 0);
				-- TODO : FirstSprite
				
				R2105_BGSize			: out STD_LOGIC_VECTOR (3 downto 0);
				R2105_BG3Priority		: out STD_LOGIC;
				R2105_BGMode			: out STD_LOGIC_VECTOR (2 downto 0);

				R2106_MosaicSize		: out STD_LOGIC_VECTOR (3 downto 0);
				R2106_BGMosaicEnable	: out STD_LOGIC_VECTOR (3 downto 0);
				
				R2107_BG1AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
				R2108_BG2AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
				R2109_BG3AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
				R210A_BG4AddrTileMap	: out STD_LOGIC_VECTOR (5 downto 0);
				R210789A_BGsMapSX		: out STD_LOGIC_VECTOR (3 downto 0);
				R210789A_BGsMapSY		: out STD_LOGIC_VECTOR (3 downto 0);
				
				-- Specification gives 4 BIT for pixel buffer address
				-- But does not fit in 15 bit word adress calculation
				-- Moreover, BSnes do ALSO use only 3 LSB BIT.
				R210B_BG1PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);
				R210B_BG2PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);
				R210C_BG3PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);
				R210C_BG4PixAddr		: out STD_LOGIC_VECTOR (2 downto 0);

				R210D_M7_HOFS			: out STD_LOGIC_VECTOR(12 downto 0);
				R210D_BG1_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
				R210E_M7_VOFS			: out STD_LOGIC_VECTOR(12 downto 0);
				R210E_BG1_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);
				R210F_BG2_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
				R2110_BG2_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);
				R2111_BG3_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
				R2112_BG3_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);
				R2113_BG4_HOFS			: out STD_LOGIC_VECTOR (9 downto 0);
				R2114_BG4_VOFS			: out STD_LOGIC_VECTOR (9 downto 0);

				-- Internal R2115_VRAM_INCMODE		: out STD_LOGIC;				
				-- Internal R2115_VRAM_INCREMENT	: out STD_LOGIC_VECTOR (1 downto 0);
				
				-- 2116,2117,2118,2119 => VRAM adress / write.
				
				R211A_M7_REPEAT			: out STD_LOGIC;
				R211A_M7_HFLIP			: out STD_LOGIC;
				R211A_M7_VFLIP			: out STD_LOGIC;
				R211A_M7_FILL			: out STD_LOGIC;
				
				R211B_M7A				: out STD_LOGIC_VECTOR(15 downto 0);
				R211C_M7B				: out STD_LOGIC_VECTOR(15 downto 0);
				R211D_M7C				: out STD_LOGIC_VECTOR(15 downto 0);
				R211E_M7D				: out STD_LOGIC_VECTOR(15 downto 0);
				
				R211F_M7CX				: out STD_LOGIC_VECTOR(12 downto 0);
				R2120_M7CY				: out STD_LOGIC_VECTOR(12 downto 0);
				
				-- 2121,2122 => CGRAM address / write.
				
				-- Note : top 5,4 -> OBJ/COL, 0..3 -> BG NUM by convention.
				R21232425_W1_ENABLE		: out STD_LOGIC_VECTOR (5 downto 0);
				R21232425_W2_ENABLE		: out STD_LOGIC_VECTOR (5 downto 0);
				R21232425_W1_INV		: out STD_LOGIC_VECTOR (5 downto 0);
				R21232425_W2_INV		: out STD_LOGIC_VECTOR (5 downto 0);
				
				R2126_W1_LEFT			: out STD_LOGIC_VECTOR (7 downto 0);
				R2127_W1_RIGHT			: out STD_LOGIC_VECTOR (7 downto 0);
				R2128_W2_LEFT			: out STD_LOGIC_VECTOR (7 downto 0);
				R2129_W2_RIGHT			: out STD_LOGIC_VECTOR (7 downto 0);
				
				R212AB_WMASK_LSB		: out STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
				R212AB_WMASK_MSB		: out STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
				
				R212C_MAIN				: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
				R212D_SUB				: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
				
				R212E_WMASK_MAIN		: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
				R212F_WMASK_SUB			: out STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj

				R2130_CLIPCOLORMATH		: out STD_LOGIC_VECTOR (1 downto 0);
				R2130_PREVENTCOLORMATH	: out STD_LOGIC_VECTOR (1 downto 0);
				R2130_ADDSUBSCR			: out STD_LOGIC;
				R2130_DIRECTCOLOR		: out STD_LOGIC;

				R2131_COLORMATH_SUB		: out STD_LOGIC;
				R2131_COLORMATH_HALF	: out STD_LOGIC;
				R2131_ENABLEMATH_UNIT	: out STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Backdrop

				R2132_FIXEDCOLOR_R		: out STD_LOGIC_VECTOR (4 downto 0);
				R2132_FIXEDCOLOR_G		: out STD_LOGIC_VECTOR (4 downto 0);
				R2132_FIXEDCOLOR_B		: out STD_LOGIC_VECTOR (4 downto 0);
				
				R2133_EXT_SYNC			: out STD_LOGIC;
				R2133_M7_EXTBG			: out STD_LOGIC;
				R2133_HIRES				: out STD_LOGIC;
				R2133_OVERSCAN			: out STD_LOGIC;
				R2133_OBJ_INTERLACE		: out STD_LOGIC;
				R2133_SCR_INTERLACE		: out STD_LOGIC
				
	);
end PPU_Registers;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_Registers of PPU_Registers is
	signal reg00_DisplayEnabled		: STD_LOGIC;
	signal reg00_Brigthness			: STD_LOGIC_VECTOR (3 downto 0);
	
	signal reg01_OAMBaseSize		: STD_LOGIC_VECTOR (2 downto 0); 
	signal reg01_OAMNameSelect		: STD_LOGIC_VECTOR (1 downto 0);
	signal reg01_OAMNameBase		: STD_LOGIC_VECTOR (2 downto 0);

	signal reg02_OAMPriority		: STD_LOGIC;
	signal reg02_OAMBaseAdr			: STD_LOGIC_VECTOR (8 downto 0);
	
	signal reg05_BGSize				: STD_LOGIC_VECTOR (3 downto 0);
	signal reg05_BG3Priority		: STD_LOGIC;
	signal reg05_BGMode				: STD_LOGIC_VECTOR (2 downto 0);

	signal reg06_MosaicSize			: STD_LOGIC_VECTOR (3 downto 0);
	signal reg06_BGMosaicEnable		: STD_LOGIC_VECTOR (3 downto 0);
	
	signal reg07_BG1AddrTileMap		: STD_LOGIC_VECTOR (5 downto 0);
	signal reg08_BG2AddrTileMap		: STD_LOGIC_VECTOR (5 downto 0);
	signal reg09_BG3AddrTileMap		: STD_LOGIC_VECTOR (5 downto 0);
	signal reg0A_BG4AddrTileMap		: STD_LOGIC_VECTOR (5 downto 0);
	signal reg0789A_BGsMapSX		: STD_LOGIC_VECTOR (3 downto 0);
	signal reg0789A_BGsMapSY		: STD_LOGIC_VECTOR (3 downto 0);
	
	signal reg0B_BG1PixAddr			: STD_LOGIC_VECTOR (2 downto 0);
	signal reg0B_BG2PixAddr			: STD_LOGIC_VECTOR (2 downto 0);
	signal reg0C_BG3PixAddr			: STD_LOGIC_VECTOR (2 downto 0);
	signal reg0C_BG4PixAddr			: STD_LOGIC_VECTOR (2 downto 0);

	signal reg0D_M7_HOFS			: STD_LOGIC_VECTOR(12 downto 0);
	signal reg0D_BG1_HOFS			: STD_LOGIC_VECTOR (9 downto 0);
	signal reg0E_M7_VOFS			: STD_LOGIC_VECTOR(12 downto 0);
	signal reg0E_BG1_VOFS			: STD_LOGIC_VECTOR (9 downto 0);
	signal reg0F_BG2_HOFS			: STD_LOGIC_VECTOR (9 downto 0);
	signal reg10_BG2_VOFS			: STD_LOGIC_VECTOR (9 downto 0);
	signal reg11_BG3_HOFS			: STD_LOGIC_VECTOR (9 downto 0);
	signal reg12_BG3_VOFS			: STD_LOGIC_VECTOR (9 downto 0);
	signal reg13_BG4_HOFS			: STD_LOGIC_VECTOR (9 downto 0);
	signal reg14_BG4_VOFS			: STD_LOGIC_VECTOR (9 downto 0);

	signal reg15_VRAM_INCMODE		: STD_LOGIC;				
	signal reg15_VRAM_MAPPING		: STD_LOGIC_VECTOR (1 downto 0);
	signal reg15_VRAM_INCREMENT		: STD_LOGIC_VECTOR (1 downto 0);
	
	signal reg1A_M7_REPEAT			: STD_LOGIC;
	signal reg1A_M7_HFLIP			: STD_LOGIC;
	signal reg1A_M7_VFLIP			: STD_LOGIC;
	signal reg1A_M7_FILL			: STD_LOGIC;
	
	signal reg1B_M7A				: STD_LOGIC_VECTOR(15 downto 0);
	signal reg1C_M7B				: STD_LOGIC_VECTOR(15 downto 0);
	signal reg1D_M7C				: STD_LOGIC_VECTOR(15 downto 0);
	signal reg1E_M7D				: STD_LOGIC_VECTOR(15 downto 0);
	
	signal reg1F_M7CX				: STD_LOGIC_VECTOR(12 downto 0);
	signal reg20_M7CY				: STD_LOGIC_VECTOR(12 downto 0);
	
	signal reg232425_W1_ENABLE		: STD_LOGIC_VECTOR (5 downto 0);
	signal reg232425_W2_ENABLE		: STD_LOGIC_VECTOR (5 downto 0);
	signal reg232425_W1_INV			: STD_LOGIC_VECTOR (5 downto 0);
	signal reg232425_W2_INV			: STD_LOGIC_VECTOR (5 downto 0);
	
	signal reg26_W1_LEFT			: STD_LOGIC_VECTOR (7 downto 0);
	signal reg27_W1_RIGHT			: STD_LOGIC_VECTOR (7 downto 0);
	signal reg28_W2_LEFT			: STD_LOGIC_VECTOR (7 downto 0);
	signal reg29_W2_RIGHT			: STD_LOGIC_VECTOR (7 downto 0);
	
	signal reg2AB_WMASK_LSB			: STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
	signal reg2AB_WMASK_MSB			: STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Col
	
	signal reg2C_MAIN				: STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
	signal reg2D_SUB				: STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
	
	signal reg2E_WMASK_MAIN			: STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj
	signal reg2F_WMASK_SUB			: STD_LOGIC_VECTOR (4 downto 0); -- 4 : Obj

	signal reg30_CLIPCOLORMATH		: STD_LOGIC_VECTOR (1 downto 0);
	signal reg30_PREVENTCOLORMATH	: STD_LOGIC_VECTOR (1 downto 0);
	signal reg30_ADDSUBSCR			: STD_LOGIC;
	signal reg30_DIRECTCOLOR		: STD_LOGIC;

	signal reg31_COLORMATH_SUB		: STD_LOGIC;
	signal reg31_COLORMATH_HALF		: STD_LOGIC;
	signal reg31_ENABLEMATH_UNIT	: STD_LOGIC_VECTOR (5 downto 0); -- 4 : Obj, 5 : Backdrop

	signal reg32_FIXEDCOLOR_R		: STD_LOGIC_VECTOR (4 downto 0);
	signal reg32_FIXEDCOLOR_G		: STD_LOGIC_VECTOR (4 downto 0);
	signal reg32_FIXEDCOLOR_B		: STD_LOGIC_VECTOR (4 downto 0);
	
	signal reg33_EXT_SYNC			: STD_LOGIC;
	signal reg33_M7_EXTBG			: STD_LOGIC;
	signal reg33_HIRES				: STD_LOGIC;
	signal reg33_OVERSCAN			: STD_LOGIC;
	signal reg33_OBJ_INTERLACE		: STD_LOGIC;
	signal reg33_SCR_INTERLACE		: STD_LOGIC;
	
	signal tmpValM7					: STD_LOGIC_VECTOR (7 downto 0);
	signal tmpValBG					: STD_LOGIC_VECTOR (7 downto 0);	
	
	signal tmpValue					: STD_LOGIC_VECTOR (3 downto 0);
	signal tmpVRAMAddress			: STD_LOGIC_VECTOR(14 downto 0);
	signal regVRAMAddress			: STD_LOGIC_VECTOR(14 downto 0);
	signal tmpVRAMread				: STD_LOGIC;
	signal regPrevCycleRead			: STD_LOGIC;
	signal regVRAMData				: STD_LOGIC_VECTOR(15 downto 0);
	
	signal sCGAddr,CGAddr			: STD_LOGIC_VECTOR(8 downto 0);
	signal sAdrMode					: STD_LOGIC_VECTOR(1 downto 0);
	signal rReadMode, sReadMode	: STD_LOGIC;
	signal sCGWData,rCGWData		: STD_LOGIC_VECTOR(7 downto 0);
	signal sCGData, CGData			: STD_LOGIC_VECTOR(7 downto 0);
	
begin
	
--	CGRAMAddress	<= sCGAddr(8 downto 1);
--	CGRAMwrite		<= not(sReadMode and sCGAddr(0)); -- Write when LSB is 1. = perform write.
--	CGRAMDataOut	<= DataIn(6 downto 0) & rCGWData; -- 15 Bit.
--
--	VRAMDataOut		<= DataIn;
--	VRAMread		<= tmpVRAMread;
--
--	--
--	-- CPU Read result.
--	--
--	process (Address, CPUWrite, 
--			regVRAMData,
--			CGData
--			)
--	begin
--		if (CPUwrite = '0') then
--			case Address is
--			when "111001" => -- 0x39 VMDATALREAD
--				DataOut <= regVRAMData(7 downto 0);
--			when "111010" => -- 0x3A VMDATAHREAD
--				DataOut <= regVRAMData(15 downto 8);
--			when "111011" => -- 0x3B : CGDATAREAD
--				DataOut <= CGData;
--			when others =>
--				--
--				-- TODO : Do other read registers.
--				--
--				DataOut <= "00000010";
--			end case;
--		else
--			DataOut <= "00000001";
--		end if;
--	end process;
--	
--	-- ######################################################################
--	-- ######################################################################
--	-- ######################################################################
--
--	process(Address, CPUWrite,
--			sCGAddr)
--	begin
--		if (CPUWrite = '1') then
--			case Address is
--			when "010001" => -- CGADD
--				sAdrMode	<= "00";
--				sReadMode	<= '1';
--			when "010010" => -- CGDATA
--				sAdrMode	<= "01";
--				sReadMode	<= not(sCGAddr(0));	-- Adr 1 : perform WRITE, else wait.
--			when others   =>
--				sAdrMode	<= "10";
--				sReadMode	<= '1'; -- Avoid Write.
--			end case;
--		else
--			-- CGDATAREAD
--			if (Address = "111011") then
--				sAdrMode	<= "01";
--				sReadMode	<= '1';
--			else
--				-- Others.
--				sAdrMode	<= "10";
--				sReadMode	<= '1'; -- Avoid Write.
--			end if;
--		end if;
--	end process;
--	
--	process(clock, reset, sCGData, sCGWData, sCGAddr, sReadMode)
--	begin
--		if reset = '1' then
--			CGData		<= "00000000";
--			CGAddr		<= "000000000";
--			rCGWData	<= "00000000";
--			rReadMode	<= '0';
--		elsif (clock='1' and clock'event) then
--			CGData		<= sCGData;
--			rCGWData	<= sCGWData;
--			CGAddr		<= sCGAddr;
--			rReadMode	<= sReadMode;
--		end if;
--	end process;
--	
--    process(clock, reset, sAdrMode,DataIn,CGAddr,rReadMode,CGRAMDataIn,CGData,sReadMode,rCGWData)
--    begin
--		--
--		-- Address Management.
--		--
--		if (sAdrMode = "00") then
--			sCGAddr <= DataIn & "0";	-- Set CG Address.
--		else
--			if (sAdrMode = "01") then
--				sCGAddr <= CGAddr + 1;  -- Increment CG Address.
--			else
--				sCGAddr <= CGAddr;		-- No OP.
--			end if;
--		end if;
--
--		--
--		-- Data Management (READ)
--		--
--		if (rReadMode = '1') then		-- Read REGISTER because we want     one cycle LATER after READ occurs.
--			if (CGAddr(0) = '0') then	-- Read REGISTER because we want LSB one cycle LATER after READ occurs.
--				sCGData <= CGRAMDataIn(7 downto 0);					-- Read CGRam
--			else
--				sCGData <= CGData(7) & CGRAMDataIn(14 downto 8);	-- Read CGRam
--			end if;
--		else
--			sCGData <= CGData;								-- No OP.
--		end if;
--		
--		--
--		-- Data Management (WRITE)
--		--
--		if (sReadMode = '0') then		-- Read CURRENT cycle to know if write.
--			sCGWData <= DataIn;
--		else
--			sCGWData <= rCGWData;
--		end if;
--	end process;
--
--	-- ######################################################################
--	-- ######################################################################
--	-- ######################################################################
--	
--	--
--	--
--	--
--	process(Address, DataIn, regVRAMAddress, regVRAMData, CPUWrite, tmpVRAMread, CGData)
--	begin
--		if (CPUwrite = '1') then
--			case Address is
--			when "010110" => -- 0x16 : VMADDL
--				tmpVRAMAddress <= regVRAMAddress(14 downto 8) & DataIn;
--				VRAMwrite	<= '0';
--				tmpVRAMread	<= '1';
--				VRAMlowHigh	<= '0';
--			when "010111" => -- 0x17 : VMADDH
--				tmpVRAMAddress <= DataIn(6 downto 0) & regVRAMAddress(7 downto 0);
--				VRAMwrite	<= '0';
--				tmpVRAMread	<= '1';
--				VRAMlowHigh <= '0';
--			when "011000" => -- 0x18 : VMDATAL
--				tmpVRAMAddress <= regVRAMAddress;
--				VRAMwrite	<= '1';
--				tmpVRAMread	<= '0';
--				VRAMlowHigh <= '0';
--			when "011001" => -- 0x19 : VMDATAH
--				tmpVRAMAddress <= regVRAMAddress;
--				VRAMwrite	<= '1';
--				tmpVRAMread	<= '0';
--				VRAMlowHigh <= '1';
--			when "111001" => -- 0x39 VMDATALREAD
--				tmpVRAMAddress <= regVRAMAddress;
--				VRAMwrite	<= '0';
--				tmpVRAMread	<= '1';
--				VRAMlowHigh <= '0';				
--			when "111010" => -- 0x3A VMDATAHREAD
--				tmpVRAMAddress <= regVRAMAddress;
--				VRAMwrite	<= '0';
--				tmpVRAMread	<= '1';
--				VRAMlowHigh <= '0';
--			when others   =>
--				tmpVRAMAddress <= regVRAMAddress;
--				VRAMwrite	<= '0';
--				tmpVRAMread	<= '0';
--				VRAMlowHigh <= '0';
--			end case;
--		else
--			tmpVRAMAddress <= regVRAMAddress;
--			VRAMwrite	<= '0';
--			tmpVRAMread	<= '0';
--			VRAMlowHigh <= '0';
--		end if;
--	end process;
--		
--	VRAMAddress_PostTranslation <= 	tmpVRAMAddress
--										when reg15_VRAM_MAPPING = "00" else
--									tmpVRAMAddress(14 downto 8) & tmpVRAMAddress(4 downto 0) & tmpVRAMAddress(7 downto 5)
--										when reg15_VRAM_MAPPING = "01" else
--									tmpVRAMAddress(14 downto 9) & tmpVRAMAddress(5 downto 0) & tmpVRAMAddress(8 downto 6)
--										when reg15_VRAM_MAPPING = "10" else
--									tmpVRAMAddress(14 downto 10) & tmpVRAMAddress(6 downto 0) & tmpVRAMAddress(9 downto 7);
--	
--    process(clock, reset, Address, CPUwrite, DataIn)
--    begin
--		if reset = '1' then
--			--
--			-- System Default on reset.
--			--
--			tmpValBG				<= "00000000";
--			tmpValM7				<= "00000000";
--
			reg00_DisplayEnabled	<= CONSTREG.R00_DisplayEnabled;
			reg00_Brigthness		<= CONSTREG.R00_Brigthness;
                                             
			reg01_OAMBaseSize		<= CONSTREG.R01_OAMBaseSize;
			reg01_OAMNameSelect		<= CONSTREG.R01_OAMNameSelect;
			reg01_OAMNameBase		<= CONSTREG.R01_OAMNameBase;
                                             
			reg02_OAMPriority		<= CONSTREG.R02_OAMPriority;
			reg02_OAMBaseAdr		<= CONSTREG.R02_OAMBaseAdr;
                                             
			reg05_BGSize			<= CONSTREG.R05_BGSize;
			reg05_BG3Priority		<= CONSTREG.R05_BG3Priority;
			reg05_BGMode			<= CONSTREG.R05_BGMode;
                                             
			reg06_MosaicSize		<= CONSTREG.R06_MosaicSize;
			reg06_BGMosaicEnable	<= CONSTREG.R06_BGMosaicEnable;
                                             
			reg07_BG1AddrTileMap	<= CONSTREG.R07_BG1AddrTileMap;
			reg08_BG2AddrTileMap	<= CONSTREG.R08_BG2AddrTileMap;
			reg09_BG3AddrTileMap	<= CONSTREG.R09_BG3AddrTileMap;
			reg0A_BG4AddrTileMap	<= CONSTREG.R0A_BG4AddrTileMap;
			reg0789A_BGsMapSX		<= CONSTREG.R0789A_BGsMapSX;
			reg0789A_BGsMapSY		<= CONSTREG.R0789A_BGsMapSY;
                                             
			reg0B_BG1PixAddr		<= CONSTREG.R0B_BG1PixAddr;
			reg0B_BG2PixAddr		<= CONSTREG.R0B_BG2PixAddr;
			reg0C_BG3PixAddr		<= CONSTREG.R0C_BG3PixAddr;
			reg0C_BG4PixAddr		<= CONSTREG.R0C_BG4PixAddr;
                                             
			reg0D_M7_HOFS			<= CONSTREG.R0D_M7_HOFS;
			reg0D_BG1_HOFS			<= CONSTREG.R0D_BG1_HOFS;
			reg0E_M7_VOFS			<= CONSTREG.R0E_M7_VOFS;
			reg0E_BG1_VOFS			<= CONSTREG.R0E_BG1_VOFS;
			reg0F_BG2_HOFS			<= CONSTREG.R0F_BG2_HOFS;
			reg10_BG2_VOFS			<= CONSTREG.R10_BG2_VOFS;
			reg11_BG3_HOFS			<= CONSTREG.R11_BG3_HOFS;
			reg12_BG3_VOFS			<= CONSTREG.R12_BG3_VOFS;
			reg13_BG4_HOFS			<= CONSTREG.R13_BG4_HOFS;
			reg14_BG4_VOFS			<= CONSTREG.R14_BG4_VOFS;
                                             
			reg15_VRAM_INCMODE		<= CONSTREG.R15_VRAM_INCMODE;
			reg15_VRAM_MAPPING		<= CONSTREG.R15_VRAM_MAPPING;
			reg15_VRAM_INCREMENT	<= CONSTREG.R15_VRAM_INCREMENT;
                                             
			reg1A_M7_REPEAT			<= CONSTREG.R1A_M7_REPEAT;
			reg1A_M7_HFLIP			<= CONSTREG.R1A_M7_HFLIP;
			reg1A_M7_VFLIP			<= CONSTREG.R1A_M7_VFLIP;
			reg1A_M7_FILL			<= CONSTREG.R1A_M7_FILL;
                                             
			reg1B_M7A				<= CONSTREG.R1B_M7A;
			reg1C_M7B				<= CONSTREG.R1C_M7B;
			reg1D_M7C				<= CONSTREG.R1D_M7C;
			reg1E_M7D				<= CONSTREG.R1E_M7D;
                                             
			reg1F_M7CX				<= CONSTREG.R1F_M7CX;
			reg20_M7CY				<= CONSTREG.R20_M7CY;
                                             
			reg232425_W1_ENABLE		<= CONSTREG.R232425_W1_ENABLE;
			reg232425_W2_ENABLE		<= CONSTREG.R232425_W2_ENABLE;
			reg232425_W1_INV		<= CONSTREG.R232425_W1_INV;
			reg232425_W2_INV		<= CONSTREG.R232425_W2_INV;
                                             
			reg26_W1_LEFT			<= CONSTREG.R26_W1_LEFT;
			reg27_W1_RIGHT			<= CONSTREG.R27_W1_RIGHT;
			reg28_W2_LEFT			<= CONSTREG.R28_W2_LEFT;
			reg29_W2_RIGHT			<= CONSTREG.R29_W2_RIGHT;
                                             
			reg2AB_WMASK_LSB		<= CONSTREG.R2AB_WMASK_LSB		;
			reg2AB_WMASK_MSB		<= CONSTREG.R2AB_WMASK_MSB		;
                                             
			reg2C_MAIN				<= CONSTREG.R2C_MAIN;
			reg2D_SUB				<= CONSTREG.R2D_SUB;
                                             
			reg2E_WMASK_MAIN		<= CONSTREG.R2E_WMASK_MAIN;
			reg2F_WMASK_SUB			<= CONSTREG.R2F_WMASK_SUB;
                                             
			reg30_CLIPCOLORMATH		<= CONSTREG.R30_CLIPCOLORMATH;
			reg30_PREVENTCOLORMATH	<= CONSTREG.R30_PREVENTCOLORMATH;
			reg30_ADDSUBSCR			<= CONSTREG.R30_ADDSUBSCR;
			reg30_DIRECTCOLOR		<= CONSTREG.R30_DIRECTCOLOR;
                                             
			reg31_COLORMATH_SUB		<= CONSTREG.R31_COLORMATH_SUB;
			reg31_COLORMATH_HALF	<= CONSTREG.R31_COLORMATH_HALF;
			reg31_ENABLEMATH_UNIT	<= CONSTREG.R31_ENABLEMATH_UNIT;
                                             
			reg32_FIXEDCOLOR_R		<= CONSTREG.R32_FIXEDCOLOR_R;
			reg32_FIXEDCOLOR_G		<= CONSTREG.R32_FIXEDCOLOR_G;
			reg32_FIXEDCOLOR_B		<= CONSTREG.R32_FIXEDCOLOR_B;
                                             
			reg33_EXT_SYNC			<= CONSTREG.R33_EXT_SYNC;
			reg33_M7_EXTBG			<= CONSTREG.R33_M7_EXTBG;
			reg33_HIRES				<= CONSTREG.R33_HIRES;
			reg33_OVERSCAN			<= CONSTREG.R33_OVERSCAN;
			reg33_OBJ_INTERLACE		<= CONSTREG.R33_OBJ_INTERLACE;
			reg33_SCR_INTERLACE		<= CONSTREG.R33_SCR_INTERLACE;

--			reg00_DisplayEnabled	<= '0';
--			reg00_Brigthness		<= "1111"; -- Screen Brightness full by default.
--
--			reg01_OAMBaseSize		<= "000";
--			reg01_OAMNameSelect		<= "00";
--			reg01_OAMNameBase		<= "000";
--
--			reg02_OAMPriority		<= '0';
--			reg02_OAMBaseAdr		<= "000000000";
--
--			reg05_BGSize			<= "0000";
--			reg05_BG3Priority		<= '0';
--			reg05_BGMode			<= "000";
--
--			reg06_MosaicSize		<= "0000";
--			reg06_BGMosaicEnable	<= "0000";
--
--			reg07_BG1AddrTileMap	<= "000000";
--			reg08_BG2AddrTileMap	<= "000000";
--			reg09_BG3AddrTileMap	<= "000000";
--			reg0A_BG4AddrTileMap	<= "000000";
--			reg0789A_BGsMapSX		<= "0000";
--			reg0789A_BGsMapSY		<= "0000";
--			
--			reg0B_BG1PixAddr		<= "000";
--			reg0B_BG2PixAddr		<= "000";
--			reg0C_BG3PixAddr		<= "000";
--			reg0C_BG4PixAddr		<= "000";
--
--			reg0D_M7_HOFS			<= "0000000000000";
--			reg0D_BG1_HOFS			<= "0000000000";
--			reg0E_M7_VOFS			<= "0000000000000";
--			reg0E_BG1_VOFS			<= "0000000000";
--			reg0F_BG2_HOFS			<= "0000000000";
--			reg10_BG2_VOFS			<= "0000000000";
--			reg11_BG3_HOFS			<= "0000000000";
--			reg12_BG3_VOFS			<= "0000000000";
--			reg13_BG4_HOFS			<= "0000000000";
--			reg14_BG4_VOFS			<= "0000000000";
--
--			reg15_VRAM_INCMODE		<= '1';	-- Increment on write HIGH default.
--			reg15_VRAM_MAPPING		<= "00";
--			reg15_VRAM_INCREMENT	<= "00"; -- Step of 1 default.
--
--			reg1A_M7_REPEAT			<= '0';
--			reg1A_M7_HFLIP			<= '0';
--			reg1A_M7_VFLIP			<= '0';
--			reg1A_M7_FILL			<= '0';
--
--			reg1B_M7A				<= "0000000000000000";
--			reg1C_M7B				<= "0000000000000000";
--			reg1D_M7C				<= "0000000000000000";
--			reg1E_M7D				<= "0000000000000000";
--
--			reg1F_M7CX				<= "0000000000000";
--			reg20_M7CY				<= "0000000000000";
--
--			reg232425_W1_ENABLE		<= "000000";
--			reg232425_W2_ENABLE		<= "000000";
--			reg232425_W1_INV		<= "000000";
--			reg232425_W2_INV		<= "000000";
--
--			reg26_W1_LEFT			<= "00000000";
--			reg27_W1_RIGHT			<= "00000000";
--			reg28_W2_LEFT			<= "00000000";
--			reg29_W2_RIGHT			<= "00000000";
--
--			reg2AB_WMASK_LSB		<= "000000";
--			reg2AB_WMASK_MSB		<= "000000";
--
--			reg2C_MAIN				<= "00000";
--			reg2D_SUB				<= "00000";
--
--			reg2E_WMASK_MAIN		<= "00000";
--			reg2F_WMASK_SUB			<= "00000";
--
--			reg30_CLIPCOLORMATH		<= "00";
--			reg30_PREVENTCOLORMATH	<= "00";
--			reg30_ADDSUBSCR			<= '0';
--			reg30_DIRECTCOLOR		<= '0';
--
--			reg31_COLORMATH_SUB		<= '0';
--			reg31_COLORMATH_HALF	<= '0';
--			reg31_ENABLEMATH_UNIT	<= "000000";
--
--			reg32_FIXEDCOLOR_R		<= "00000";
--			reg32_FIXEDCOLOR_G		<= "00000";
--			reg32_FIXEDCOLOR_B		<= "00000";
--
--			reg33_EXT_SYNC			<= '0';
--			reg33_M7_EXTBG			<= '0';
--			reg33_HIRES				<= '0';
--			reg33_OVERSCAN			<= '0';
--			reg33_OBJ_INTERLACE		<= '0';
--			reg33_SCR_INTERLACE		<= '0';
			
--			regPrevCycleRead		<= '0';
--			regVRAMData				<= "0000000000000000";
--			
--		elsif (clock='1' and clock'event) then
--			if (regPrevCycleRead = '1') then
--				regVRAMData <= VRAMDataIn;
--			end if;
--			regPrevCycleRead		<= tmpVRAMread;
--			
--			if (CPUwrite = '1') then				
--				--
--				-- Internal Register Update
--				--
--				case (Address) is
--				when "000000" =>
--					reg00_DisplayEnabled	<= DataIn(7);
--					reg00_Brigthness		<= DataIn(3 downto 0);
--					--  BSNES
--					--  if(regs.display_disabled == true && cpu.vcounter() == (!overscan() ? 225 : 240)) {
--					--    regs.oam_addr = regs.oam_baseaddr << 1;
--					--    regs.oam_firstsprite = (regs.oam_priority == false) ? 0 : (regs.oam_addr >> 2) & 127;
--					--  }
--				when "000001" =>
--					reg01_OAMBaseSize		<= DataIn(7 downto 5);
--					reg01_OAMNameSelect		<= DataIn(4 downto 3);
--					reg01_OAMNameBase		<= DataIn(2 downto 0);
--					
--				when "000010" =>
--					reg02_OAMBaseAdr(7 downto 0) <= DataIn(7 downto 0);
--					-- BSNES : regs.oam_firstsprite = (regs.oam_priority == false) ? 0 : (regs.oam_addr >> 2) & 127;
--					
--				when "000011" =>
--					reg02_OAMPriority		<= DataIn(7);
--					reg02_OAMBaseAdr(8)		<= DataIn(0);
--					-- BSNES : regs.oam_firstsprite = (regs.oam_priority == false) ? 0 : (regs.oam_addr >> 2) & 127;
--					
--				when "000100" =>
--					--
--					-- TODO
--					--
--					-- BSNES
--					-- if(regs.oam_addr & 0x0200) {
--					-- 	oam_mmio_write(regs.oam_addr, data);
--					-- } else if((regs.oam_addr & 1) == 0) {
--					--	regs.oam_latchdata = data;
--					-- } else {
--					-- 	oam_mmio_write((regs.oam_addr & ~1) + 0, regs.oam_latchdata);
--					-- 	oam_mmio_write((regs.oam_addr & ~1) + 1, data);
--					-- }
--
--					-- regs.oam_addr++;
--					-- regs.oam_addr &= 0x03ff;
--					-- regs.oam_firstsprite = (regs.oam_priority == false) ? 0 : (regs.oam_addr >> 2) & 127;
--					
--				when "000101" =>
--					reg05_BGSize			<= DataIn(7 downto 4);
--					reg05_BG3Priority		<= DataIn(3);
--					reg05_BGMode			<= DataIn(2 downto 0);
--					
--				when "000110" =>
--					reg06_MosaicSize		<= DataIn(7 downto 4);
--					reg06_BGMosaicEnable	<= DataIn(3 downto 0);
--					
--				when "000111" =>
--					reg07_BG1AddrTileMap	<= DataIn(7 downto 2);
--					reg0789A_BGsMapSX(0)	<= DataIn(0);
--					reg0789A_BGsMapSY(0)	<= DataIn(1);
--					
--				when "001000" =>
--					reg08_BG2AddrTileMap	<= DataIn(7 downto 2);
--					reg0789A_BGsMapSX(1)	<= DataIn(0);
--					reg0789A_BGsMapSY(1)	<= DataIn(1);
--					
--				when "001001" =>
--					reg09_BG3AddrTileMap	<= DataIn(7 downto 2);
--					reg0789A_BGsMapSX(2)	<= DataIn(0);
--					reg0789A_BGsMapSY(2)	<= DataIn(1);
--					
--				when "001010" =>
--					reg0A_BG4AddrTileMap	<= DataIn(7 downto 2);
--					reg0789A_BGsMapSX(3)	<= DataIn(0);
--					reg0789A_BGsMapSY(3)	<= DataIn(1);
--					
--				when "001011" =>
--					reg0B_BG1PixAddr		<= DataIn(2 downto 0);
--					reg0B_BG2PixAddr		<= DataIn(6 downto 4);
--					
--				when "001100" =>
--					reg0C_BG3PixAddr		<= DataIn(2 downto 0);
--					reg0C_BG4PixAddr		<= DataIn(6 downto 4);
--					
--				when "001101" =>
--					-- NOTE : Bit 8 and 9 are exactly the same registers for both output , but we let HW compiler optimize for now,
--					-- we can remove them later on if we want to avoid the warnings.
--					reg0D_M7_HOFS			<= DataIn(4 downto 0) & tmpValM7;
--					reg0D_BG1_HOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValM7				<= DataIn;
--					tmpValBG				<= DataIn;
--					
--				when "001110" =>
--					-- NOTE : Bit 8 and 9 are exactly the same registers for both output , but we let HW compiler optimize for now,
--					-- we can remove them later on if we want to avoid the warnings.
--					reg0E_M7_VOFS			<= DataIn(4 downto 0) & tmpValM7;
--					reg0E_BG1_VOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValM7				<= DataIn;
--					tmpValBG				<= DataIn;
--					
--				when "001111" =>
--					reg0F_BG2_HOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValBG				<= DataIn;
--					
--				when "010000" =>
--					reg10_BG2_VOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValBG				<= DataIn;
--					
--				when "010001" =>
--					reg11_BG3_HOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValBG				<= DataIn;
--					
--				when "010010" =>
--					reg12_BG3_VOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValBG				<= DataIn;
--					
--				when "010011" =>
--					reg13_BG4_HOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValBG				<= DataIn;
--					
--				when "010100" =>
--					reg14_BG4_VOFS			<= DataIn(1 downto 0) & tmpValBG;
--					-- We make sure we use previous value BEFORE writing to register.
--					tmpValBG				<= DataIn;
--					
--				when "010101" =>
--					reg15_VRAM_INCMODE		<= DataIn(7);
--					reg15_VRAM_MAPPING		<= DataIn(3 downto 2);
--					reg15_VRAM_INCREMENT	<= DataIn(1 downto 0);
--					
--				when "010110" => -- 0x16 : VMADDL
--					regVRAMAddress			<= tmpVRAMAddress;
--				when "010111" => -- 0x17 : VMADDH
--					regVRAMAddress			<= tmpVRAMAddress;
--					
--				when "011000" => -- 0x18 : VMDATAL
--					if (reg15_VRAM_INCMODE = '0') then
--						case (reg15_VRAM_INCREMENT) is
--						when "00" =>
--							regVRAMAddress			<= tmpVRAMAddress + 1;
--						when "01" =>
--							regVRAMAddress			<= tmpVRAMAddress + 32;
--						when others =>
--							regVRAMAddress			<= tmpVRAMAddress + 128;
--						end case;
--					end if;
--				when "011001" => -- 0x19 : VMDATAH
--					if (reg15_VRAM_INCMODE = '1') then
--						case (reg15_VRAM_INCREMENT) is
--						when "00" =>
--							regVRAMAddress			<= tmpVRAMAddress + 1;
--						when "01" =>
--							regVRAMAddress			<= tmpVRAMAddress + 32;
--						when others =>
--							regVRAMAddress			<= tmpVRAMAddress + 128;
--						end case;
--					end if;
--				when "011010" =>
--					reg1A_M7_REPEAT			<= DataIn(7);
--					reg1A_M7_FILL			<= DataIn(6);
--					reg1A_M7_HFLIP			<= DataIn(0);
--					reg1A_M7_VFLIP			<= DataIn(1);
--					
--				when "011011" =>
--					reg1B_M7A				<= DataIn & tmpValM7;
--					tmpValM7				<= DataIn;
--					
--				when "011100" =>
--					reg1C_M7B				<= DataIn & tmpValM7;
--					tmpValM7				<= DataIn;
--					
--				when "011101" =>
--					reg1D_M7C				<= DataIn & tmpValM7;
--					tmpValM7				<= DataIn;
--					
--				when "011110" =>
--					reg1E_M7D				<= DataIn & tmpValM7;
--					tmpValM7				<= DataIn;
--					
--				when "011111" =>
--					reg1F_M7CX				<= DataIn(4 downto 0) & tmpValM7;
--					tmpValM7				<= DataIn;
--					
--				when "100000" =>
--					reg20_M7CY				<= DataIn(4 downto 0) & tmpValM7;
--					tmpValM7				<= DataIn;
--					
--				when "100001" =>
--					-- TODO
--					-- Internal CGRam Adress
--					--
--				when "100010" =>
--					-- TODO
--					-- BSNES
--					--  if(!(regs.cgram_addr & 1)) {
--					--    regs.cgram_latchdata = value;
--					--  } else {
--					--    cgram_mmio_write((regs.cgram_addr & 0x01fe),     regs.cgram_latchdata);
--					--    cgram_mmio_write((regs.cgram_addr & 0x01fe) + 1, value & 0x7f);
--					--  }
--					--  regs.cgram_addr++;
--					--  regs.cgram_addr &= 0x01ff;
--				when "100011" =>
--					reg232425_W1_INV(0)			<= DataIn(0);
--					reg232425_W1_ENABLE(0)		<= DataIn(1);
--					reg232425_W2_INV(0)			<= DataIn(2);
--					reg232425_W2_ENABLE(0)		<= DataIn(3);
--					reg232425_W1_INV(1)			<= DataIn(4);
--					reg232425_W1_ENABLE(1)		<= DataIn(5);
--					reg232425_W2_INV(1)			<= DataIn(6);
--					reg232425_W2_ENABLE(1)		<= DataIn(7);
--					
--				when "100100" =>
--					reg232425_W1_INV(2)			<= DataIn(0);
--					reg232425_W1_ENABLE(2)		<= DataIn(1);
--					reg232425_W2_INV(2)			<= DataIn(2);
--					reg232425_W2_ENABLE(2)		<= DataIn(3);
--					reg232425_W1_INV(3)			<= DataIn(4);
--					reg232425_W1_ENABLE(3)		<= DataIn(5);
--					reg232425_W2_INV(3)			<= DataIn(6);
--					reg232425_W2_ENABLE(3)		<= DataIn(7);
--					
--				when "100101" =>
--					reg232425_W1_INV(4)			<= DataIn(0);
--					reg232425_W1_ENABLE(4)		<= DataIn(1);
--					reg232425_W2_INV(4)			<= DataIn(2);
--					reg232425_W2_ENABLE(4)		<= DataIn(3);
--					reg232425_W1_INV(5)			<= DataIn(4);
--					reg232425_W1_ENABLE(5)		<= DataIn(5);
--					reg232425_W2_INV(5)			<= DataIn(6);
--					reg232425_W2_ENABLE(5)		<= DataIn(7);
--				
--				when "100110" =>
--					reg26_W1_LEFT			<= DataIn(7 downto 0);
--				when "100111" =>
--					reg27_W1_RIGHT			<= DataIn(7 downto 0);
--				when "101000" =>
--					reg28_W2_LEFT			<= DataIn(7 downto 0);
--				when "101001" =>
--					reg29_W2_RIGHT			<= DataIn(7 downto 0);
--					
--				when "101010" =>
--					reg2AB_WMASK_LSB(0)		<= DataIn(0);
--					reg2AB_WMASK_MSB(0)		<= DataIn(1);
--					reg2AB_WMASK_LSB(1)		<= DataIn(2);
--					reg2AB_WMASK_MSB(1)		<= DataIn(3);
--					reg2AB_WMASK_LSB(2)		<= DataIn(4);
--					reg2AB_WMASK_MSB(2)		<= DataIn(5);
--					reg2AB_WMASK_LSB(3)		<= DataIn(6);
--					reg2AB_WMASK_MSB(3)		<= DataIn(7);
--					
--				when "101011" =>
--					reg2AB_WMASK_LSB(4)		<= DataIn(0);
--					reg2AB_WMASK_MSB(4)		<= DataIn(1);
--					reg2AB_WMASK_LSB(5)		<= DataIn(2);
--					reg2AB_WMASK_MSB(5)		<= DataIn(3);
--					
--				when "101100" =>
--					reg2C_MAIN				<= DataIn(4 downto 0);
--				when "101101" =>
--					reg2D_SUB				<= DataIn(4 downto 0);
--				when "101110" =>
--					reg2E_WMASK_MAIN		<= DataIn(4 downto 0);
--				when "101111" =>
--					reg2F_WMASK_SUB			<= DataIn(4 downto 0);
--					
--				when "110000" =>
--					reg30_CLIPCOLORMATH		<= DataIn(7 downto 6);
--					reg30_PREVENTCOLORMATH	<= DataIn(5 downto 4);
--					reg30_ADDSUBSCR			<= DataIn(1);
--					reg30_DIRECTCOLOR		<= DataIn(0);
--					
--				when "110001" =>
--					reg31_COLORMATH_SUB		<= DataIn(7);
--					reg31_COLORMATH_HALF	<= DataIn(6);
--					reg31_ENABLEMATH_UNIT	<= DataIn(5 downto 0);
--				when "110010" =>
--					if (DataIn(5) = '1') then
--						reg32_FIXEDCOLOR_R	<= DataIn(4 downto 0);
--					end if;
--					
--					if (DataIn(6) = '1') then
--						reg32_FIXEDCOLOR_G	<= DataIn(4 downto 0);
--					end if;
--					
--					if (DataIn(7) = '1') then
--						reg32_FIXEDCOLOR_B	<= DataIn(4 downto 0);
--					end if;
--					
--				when "110011" =>
--					reg33_EXT_SYNC			<= DataIn(7);
--					reg33_M7_EXTBG			<= DataIn(6);
--					reg33_HIRES				<= DataIn(3);
--					reg33_OVERSCAN			<= DataIn(2);
--					reg33_OBJ_INTERLACE		<= DataIn(1);
--					reg33_SCR_INTERLACE		<= DataIn(0);
--				when others =>
--					--
--					-- DO NOTHING.
--					--
--				end case;
--			else
--				case (Address) is
--				when "111001" => -- 0x39 : VMREADDATAL
--					if (reg15_VRAM_INCMODE = '0') then
--						case (reg15_VRAM_INCREMENT) is
--						when "00" =>
--							regVRAMAddress			<= tmpVRAMAddress + 1;
--						when "01" =>
--							regVRAMAddress			<= tmpVRAMAddress + 32;
--						when others =>
--							regVRAMAddress			<= tmpVRAMAddress + 128;
--						end case;
--					end if;
--				when "111010" => -- 0x3A : VMREADDATAH
--					if (reg15_VRAM_INCMODE = '1') then
--						case (reg15_VRAM_INCREMENT) is
--						when "00" =>
--							regVRAMAddress			<= tmpVRAMAddress + 1;
--						when "01" =>
--							regVRAMAddress			<= tmpVRAMAddress + 32;
--						when others =>
--							regVRAMAddress			<= tmpVRAMAddress + 128;
--						end case;
--					end if;
--				when others =>
--					-- nothing
--				end case;
--			end if;
--	    end if;
--    end process;
	
	R2100_DisplayEnabled	 <= reg00_DisplayEnabled;
	R2100_Brigthness		 <= reg00_Brigthness;

	R2101_OAMBaseSize		 <= reg01_OAMBaseSize;
	R2101_OAMNameSelect		 <= reg01_OAMNameSelect;
	R2101_OAMNameBase		 <= reg01_OAMNameBase;

	R2102_OAMPriority		 <= reg02_OAMPriority;
	R2102_OAMBaseAdr		 <= reg02_OAMBaseAdr;

	R2105_BGSize			 <= reg05_BGSize;
	R2105_BG3Priority		 <= reg05_BG3Priority;
	R2105_BGMode			 <= reg05_BGMode;

	R2106_MosaicSize		 <= reg06_MosaicSize;
	R2106_BGMosaicEnable	 <= reg06_BGMosaicEnable;

	R2107_BG1AddrTileMap	 <= reg07_BG1AddrTileMap;
	R2108_BG2AddrTileMap	 <= reg08_BG2AddrTileMap;
	R2109_BG3AddrTileMap	 <= reg09_BG3AddrTileMap;
	R210A_BG4AddrTileMap	 <= reg0A_BG4AddrTileMap;
	R210789A_BGsMapSX		 <= reg0789A_BGsMapSX;
	R210789A_BGsMapSY		 <= reg0789A_BGsMapSY;
	
	R210B_BG1PixAddr		 <= reg0B_BG1PixAddr;
	R210B_BG2PixAddr		 <= reg0B_BG2PixAddr;
	R210C_BG3PixAddr		 <= reg0C_BG3PixAddr;
	R210C_BG4PixAddr		 <= reg0C_BG4PixAddr;

	R210D_M7_HOFS			 <= reg0D_M7_HOFS;
	R210D_BG1_HOFS			 <= reg0D_BG1_HOFS;
	R210E_M7_VOFS			 <= reg0E_M7_VOFS;
	R210E_BG1_VOFS			 <= reg0E_BG1_VOFS;
	R210F_BG2_HOFS			 <= reg0F_BG2_HOFS;
	R2110_BG2_VOFS			 <= reg10_BG2_VOFS;
	R2111_BG3_HOFS			 <= reg11_BG3_HOFS;
	R2112_BG3_VOFS			 <= reg12_BG3_VOFS;
	R2113_BG4_HOFS			 <= reg13_BG4_HOFS;
	R2114_BG4_VOFS			 <= reg14_BG4_VOFS;

	R211A_M7_REPEAT			 <= reg1A_M7_REPEAT;
	R211A_M7_HFLIP			 <= reg1A_M7_HFLIP;
	R211A_M7_VFLIP			 <= reg1A_M7_VFLIP;
	R211A_M7_FILL			 <= reg1A_M7_FILL;

	R211B_M7A				 <= reg1B_M7A;
	R211C_M7B				 <= reg1C_M7B;
	R211D_M7C				 <= reg1D_M7C;
	R211E_M7D				 <= reg1E_M7D;

	R211F_M7CX				 <= reg1F_M7CX;
	R2120_M7CY				 <= reg20_M7CY;

	R21232425_W1_ENABLE		 <= reg232425_W1_ENABLE;
	R21232425_W2_ENABLE		 <= reg232425_W2_ENABLE;
	R21232425_W1_INV		 <= reg232425_W1_INV;
	R21232425_W2_INV		 <= reg232425_W2_INV;

	R2126_W1_LEFT			 <= reg26_W1_LEFT;
	R2127_W1_RIGHT			 <= reg27_W1_RIGHT;
	R2128_W2_LEFT			 <= reg28_W2_LEFT;
	R2129_W2_RIGHT			 <= reg29_W2_RIGHT;

	R212AB_WMASK_LSB		 <= reg2AB_WMASK_LSB;
	R212AB_WMASK_MSB		 <= reg2AB_WMASK_MSB;

	R212E_WMASK_MAIN		 <= reg2E_WMASK_MAIN;
	R212F_WMASK_SUB			 <= reg2F_WMASK_SUB;

	R2130_CLIPCOLORMATH		 <= reg30_CLIPCOLORMATH;
	R2130_PREVENTCOLORMATH	 <= reg30_PREVENTCOLORMATH;
	R2130_ADDSUBSCR			 <= reg30_ADDSUBSCR;
	R2130_DIRECTCOLOR		 <= reg30_DIRECTCOLOR;

	R2131_COLORMATH_SUB		 <= reg31_COLORMATH_SUB;
	R2131_COLORMATH_HALF	 <= reg31_COLORMATH_HALF;
	R2131_ENABLEMATH_UNIT	 <= reg31_ENABLEMATH_UNIT;

	R2132_FIXEDCOLOR_R		 <= reg32_FIXEDCOLOR_R;
	R2132_FIXEDCOLOR_G		 <= reg32_FIXEDCOLOR_G;
	R2132_FIXEDCOLOR_B		 <= reg32_FIXEDCOLOR_B;

	R2133_EXT_SYNC			 <= reg33_EXT_SYNC;
	R2133_M7_EXTBG			 <= reg33_M7_EXTBG;
	R2133_HIRES				 <= reg33_HIRES;
	R2133_OVERSCAN			 <= reg33_OVERSCAN;
	R2133_OBJ_INTERLACE		 <= reg33_OBJ_INTERLACE;
	R2133_SCR_INTERLACE		 <= reg33_SCR_INTERLACE;
	
	process (reg05_BGMode, reg2C_MAIN, reg2D_SUB, reg33_M7_EXTBG)
	begin
		case (reg05_BGMode) is
		when "000" => tmpValue <= "1111";
		when "001" => tmpValue <= "0111";
		when "010" => tmpValue <= "0011";
		when "011" => tmpValue <= "0011";
		when "100" => tmpValue <= "0011";
		when "101" => tmpValue <= "0011";
		when "110" => tmpValue <= "0011";
		when others => tmpValue <= "00" & reg33_M7_EXTBG &'1';
		end case;
		
		--
		-- Obj Bit as original.
		-- BG Masked by mode.
		--
		R212C_MAIN <= reg2C_MAIN(4) & (tmpValue and reg2C_MAIN(3 downto 0));
		R212D_SUB  <= reg2D_SUB(4)  & (tmpValue and reg2D_SUB (3 downto 0));
	end process;
	
end PPU_Registers;