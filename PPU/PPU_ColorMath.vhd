----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		ColorMath.vhd
-- Module Name:		ColorMath
--
-- Description: 	Blending Unit of SNES PPU Chipset for ONE component.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_ColorMath is
    Port ( 	InputA  : in STD_LOGIC_VECTOR(4 downto 0);
			InputB  : in STD_LOGIC_VECTOR(4 downto 0);
			
			AddSub 	: in STD_LOGIC;
			Div2	: in STD_LOGIC;
			
			Output  : out STD_LOGIC_VECTOR(4 downto 0)	
		);
end PPU_ColorMath;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_ColorMath of PPU_ColorMath is
	signal source2				: std_logic_vector(4 downto 0);
	signal source2PostOp		: std_logic_vector(6 downto 0);
	signal resultBeforeShift	: std_logic_vector(6 downto 0);
	signal resultAfterShift		: std_logic_vector(6 downto 0);
	
	signal Ro : std_logic;
	signal Rs : std_logic;

	signal s1	: std_logic_vector(6 downto 0);
	signal s2	: std_logic_vector(6 downto 0);
	signal s3	: std_logic_vector(6 downto 0);
begin
	--
	-- Select Source
	--
	source2 <= InputB;
	
	--
	-- Add / Sub
	-- 5 bit -> 7 Bit
	process (source2, AddSub, s2, s1)
	variable slocal : STD_LOGIC_VECTOR(6 downto 0);
	begin
		s2 <= ("11" & not(source2));
		slocal := s2 + 1;
		if (AddSub = '1') then  -- SUB
			s1 <= slocal;
		else
			s1 <= "00" & source2; -- ADD
		end if;
		
		source2PostOp <= s1;
	end process;
	
	--
	-- Perform Operation
	-- 5 Bit -> 6 Bit.
	process (InputA, source2PostOp, s3)
	begin
		s3 <= ("00" & InputA);
		resultBeforeShift <= s3 + source2PostOp;
	end process;

	--
	-- Perform Shift after operation.
	--
	process (resultBeforeShift, Div2)
	begin
		if (Div2 = '1') then
			resultAfterShift <= resultBeforeShift(6) & resultBeforeShift(6 downto 1);
		else
			resultAfterShift <= resultBeforeShift;
		end if;
	end process;
	
	--
	-- Clamp Result
	--
	process (resultAfterShift, source2PostOp, Ro, Rs)
	begin
		-- Clamp to 31-0 range.
		--  Behaviour
		--  Overflow / source2PostOp Sign   -> Operation.
		--      0           x         -> Value
		--      1    /      0         -> 255	(Clamp overflow)
		--      1    /      1         -> 0		(Clamp underflow)
		--
		--  Logic : (val & not(Overflow))     | (Overflow & not(sign))
		--          (Value if no overflow)    |  0 if no overflow, 1 if overflow and + value.
		--                 else 0
		--
		--  Demonstration.
		--  O S  V&(~O) (O&(~S))   Complete Formula
		--  0 0    V   |   0    -->     V
		--  0 1    V   |   0    -->     V
		--  1 0    0   |   1    -->     1
		--  1 1    0   |   0    -->     0
		--
		Ro <= not(resultAfterShift(6));				-- 0 if underflow.
		Rs <= resultAfterShift(5) and not(AddSub);	-- 1 if  overflow when doing addition. (Add=0)
		
		Output <= (resultAfterShift(4 downto 0) and (Ro&Ro&Ro&Ro&Ro)) or (Rs&Rs&Rs&Rs&Rs);
	end process;
end PPU_ColorMath;
