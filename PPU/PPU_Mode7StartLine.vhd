----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		Mode7LineStart.vhd
-- Module Name:		Mode7LineStart
--
-- Description: 	Compute Texture X,Y coordinate from Screen [0,Y]
--					
--					This unit is NOT optimized AT ALL.
--					It rely on using the DSP feature of available FPGA
--					
--					- Wanted also to avoid timing issue, so everything is setup 
--					in one clock cycle.
--					- Export the result with more precision that the console would handle.
--					- Still opportunity for tuning...
--
-- 
--   TODO : Support FLIPX, FLIPY HERE : 255-X, 255-Y
--			Thus generate also OPPOSITE ABCD based on flip.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_Mode7StartLine is
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
end PPU_Mode7StartLine;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_Mode7StartLine of PPU_Mode7StartLine is
	signal CLX			: STD_LOGIC_VECTOR	(12 downto 0);
	signal CLY			: STD_LOGIC_VECTOR	(12 downto 0);

	signal M7A_signed	: signed			(M7_A'high downto 0);
	signal M7B_signed	: signed			(M7_B'high downto 0);
	signal M7C_signed	: signed			(M7_C'high downto 0);
	signal M7D_signed	: signed			(M7_D'high downto 0);

	signal sScreenY		: signed			(ScreenY'high downto 0);

	signal sCLX			: signed			(12 downto 0);
	signal sCLY			: signed			(12 downto 0);
	
	signal tmp1X		: signed			(28 downto 0);
	signal tmp1Y		: signed			(28 downto 0);

	signal tmp2X		: signed			(25 downto 0);
	signal tmp2Y		: signed			(25 downto 0);

	signal tmp3X		: signed			(28 downto 0);
	signal tmp3Y		: signed			(28 downto 0);

	signal outX			: STD_LOGIC_VECTOR	(28 downto 0);
	signal outY			: STD_LOGIC_VECTOR	(28 downto 0);
begin
	-- 13 bit.
	-- CL* = Off* - C*
	CLX			<= M7_OFFSX + not(M7_CX) + 1;
	CLY			<= M7_OFFSY + not(M7_CY) + 1;

	sCLX		<= signed(CLX);
	sCLY		<= signed(CLY);
	sScreenY	<= signed(ScreenY);
	
	-- 16 bit.
	M7A_signed	<= signed(M7_A);
	M7B_signed	<= signed(M7_B);
	M7C_signed	<= signed(M7_C);
	M7D_signed	<= signed(M7_D);

	-- TODO : ScreenX also : needed for FlipX in Mode7.
	
	tmp1X		<= M7A_signed * sCLX;		-- 16 + 13
	tmp2X		<= M7B_signed * sScreenY;	-- 16 + 10
	tmp3X		<= M7B_signed * sCLY;		-- 16 + 13
	
	tmp1Y		<= M7C_signed * sCLX;		-- 16 + 13
	tmp2Y		<= M7D_signed * sScreenY;	-- 16 + 10
	tmp3Y		<= M7D_signed * sCLY;		-- 16 + 13

	-- Full Accuracy implementation.
	-- => SNES Accuracy is equiv to set all the 5..0 bit of mul result to ZERO. (= simplify mul unit)
	outX		<= STD_LOGIC_VECTOR(tmp1X) + (STD_LOGIC_VECTOR(tmp2X) & "000") + STD_LOGIC_VECTOR(tmp3X) + ("00000000" & M7_CX & "00000000");
	outY		<= STD_LOGIC_VECTOR(tmp1Y) + (STD_LOGIC_VECTOR(tmp2Y) & "000") + STD_LOGIC_VECTOR(tmp3Y) + ("00000000" & M7_CY & "00000000");

	-- 10.8
	TX			<= outX;
	TY			<= outY;

end PPU_Mode7StartLine;
