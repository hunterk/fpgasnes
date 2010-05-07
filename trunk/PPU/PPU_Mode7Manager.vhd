----------------------------------------------------------------------------------
-- Create Date:   	
-- Design Name:		PPU_Mode7Manager.vhd
-- Module Name:		PPU_Mode7Manager
-- Description:		
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_Mode7Manager is
    Port ( 	
		clock         		: in STD_LOGIC;
		
		X_NonMosaic			: in STD_LOGIC_VECTOR(7 downto 0);
		YMosaic				: in STD_LOGIC_VECTOR(7 downto 0);
		
		R210D_M7_HOFS		: in STD_LOGIC_VECTOR(12 downto 0);
		R210E_M7_VOFS		: in STD_LOGIC_VECTOR(12 downto 0);

		R211A_M7_HFLIP		: in STD_LOGIC;
		R211A_M7_VFLIP		: in STD_LOGIC;
		
		R211B_M7A			: in STD_LOGIC_VECTOR(15 downto 0);
		R211C_M7B			: in STD_LOGIC_VECTOR(15 downto 0);
		R211D_M7C			: in STD_LOGIC_VECTOR(15 downto 0);
		R211E_M7D			: in STD_LOGIC_VECTOR(15 downto 0);
		
		R211F_M7CX			: in STD_LOGIC_VECTOR(12 downto 0);
		R2120_M7CY			: in STD_LOGIC_VECTOR(12 downto 0);

		-- Integer format.
		Mode7XOut			: out STD_LOGIC_VECTOR(20 downto 0);
		Mode7YOut			: out STD_LOGIC_VECTOR(20 downto 0)
	);
end PPU_Mode7Manager;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture ArchiPPU_Mode7Manager of PPU_Mode7Manager is

--	component PPU_Mode7Incr is
--    Port (
--		clock		: in  STD_LOGIC;
--		
--		-- 10.8 Format.
--		load		: in STD_LOGIC;
--		inc			: in STD_LOGIC;
--		LoadX		: in STD_LOGIC_VECTOR(26 downto 0);
--		LoadY		: in STD_LOGIC_VECTOR(26 downto 0);
--		
--		--  8.8 Format. 
--		M7_A 		: in STD_LOGIC_VECTOR(15 downto 0);
--		M7_C 		: in STD_LOGIC_VECTOR(15 downto 0);
--		
--		-- 10.8 Format.
--		TX			: out STD_LOGIC_VECTOR(26 downto 0);
--		TY			: out STD_LOGIC_VECTOR(26 downto 0)
--	);
--	end component;

	component PPU_Mode7StartLine is
    Port (
		-- 8.8 Format.
		M7_A 		: in STD_LOGIC_VECTOR (15 downto 0);
		M7_B		: in STD_LOGIC_VECTOR (15 downto 0);
		M7_C		: in STD_LOGIC_VECTOR (15 downto 0);
		M7_D		: in STD_LOGIC_VECTOR (15 downto 0);
		-- 13.0 Format
		M7_CX		: in STD_LOGIC_VECTOR (12 downto 0);
		M7_CY		: in STD_LOGIC_VECTOR (12 downto 0);
		M7_OFFSX	: in STD_LOGIC_VECTOR (12 downto 0);
		M7_OFFSY	: in STD_LOGIC_VECTOR (12 downto 0);
		
		-- 10.0 Format
		ScreenY		: in STD_LOGIC_VECTOR ( 9 downto 0);
		ScreenX		: in STD_LOGIC_VECTOR ( 9 downto 0);

		-- x.8 Format.
		TX			: out STD_LOGIC_VECTOR(28 downto 0);
		TY			: out STD_LOGIC_VECTOR(28 downto 0)
	);
	end component;
	
	signal sMA				: STD_LOGIC_VECTOR(15 downto 0);
	signal sMC				: STD_LOGIC_VECTOR(15 downto 0);

	signal sLoad			: STD_LOGIC;
	signal sInc  			: STD_LOGIC;

	signal sScreenY			: STD_LOGIC_VECTOR(9 downto 0);
	signal sScreenX			: STD_LOGIC_VECTOR(9 downto 0);
	
	signal sTX,sTY			: STD_LOGIC_VECTOR(28 downto 0);
	signal finalTX,finalTY	: STD_LOGIC_VECTOR(28 downto 0);
	
begin
	-- TODO A : BAD : mosaic is flipped also...
	-- TODO B : sScreenY <-- NEED NEXT LINE Y AND HANDLE FLIPY,
	-- but we MUST take care about MOSAIC (+1 is not a solution)
	-- --> Have mosaic output 2 Y bit --> update currentY, nextY.
	--
--	process (R211A_M7_VFLIP, YMosaic)
--	begin
--		if (R211A_M7_VFLIP = '1') then
--			sScreenY <= "11" & not(YMosaic);
--		else
--			sScreenY <= "00" & YMosaic;
--		end if;
--	end process;
--	
--	process (R211A_M7_HFLIP,R211B_M7A,R211D_M7C)
--	begin
--		if (R211A_M7_HFLIP = '1') then
--			sMA <= not(R211B_M7A) + 1;
--			sMC <= not(R211D_M7C) + 1;
--			sScreenX	<= "0011111111"; -- 255
--		else
--			sMA <= R211B_M7A;
--			sMC <= R211D_M7C;
--			sScreenX	<= "0000000000"; -- 0
--		end if;
--	end process;

	sScreenX	<= "00" & X_NonMosaic;
	sScreenY	<= "00" & YMosaic;
	
	instancePPU_Mode7StartLine : PPU_Mode7StartLine port map
	(
		M7_A 		=> R211B_M7A,
		M7_B		=> R211C_M7B,
		M7_C		=> R211D_M7C,
		M7_D		=> R211E_M7D,
	                  
		M7_CX		=> R211F_M7CX,
		M7_CY		=> R2120_M7CY,
	
		M7_OFFSX	=> R210D_M7_HOFS,
		M7_OFFSY	=> R210E_M7_VOFS,
	
		ScreenY		=> sScreenY,
		ScreenX		=> sScreenX,
	
		TX			=> sTX,
		TY			=> sTY
	);
	
--	instancePPU_PPU_Mode7Incr : PPU_Mode7Incr port map
--	(
--		clock		=> clock,
--		
--		-- 10.8 Format.
--		load		=> sLoad,
--		inc			=> sInc,
--		LoadX		=> sTX(26 downto 0),
--		LoadY		=> sTY(26 downto 0),
--		
--		--  8.8 Format. 
--		M7_A 		=> sMA,
--		M7_C 		=> sMC,
--		
--		-- 10.8 Format.
--		TX			=> finalTX(26 downto 0),
--		TY			=> finalTY(26 downto 0)
--	);
	

	--
	-- Output 20.0 Format.
	--
	Mode7XOut <= sTX(28 downto 8);
	Mode7YOut <= sTY(28 downto 8);
	
	-- Constant step for debugging purpose.
--	Mode7XOut <= "0000000000000" & X_NonMosaic;
--	Mode7YOut <= "0000000000000" & YMosaic;
end ArchiPPU_Mode7Manager;
