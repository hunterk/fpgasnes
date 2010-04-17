--------------------------------------------------------------------------------
-- Design Name:		PPU_BRIGHTNESS.vhd
-- Module Name:		PPU_BRIGHTNESS
--
-- Description: 	Compute the RGB values post brightness processed.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PPU_BRIGHTNESS is
    Port ( Rin			: in  STD_LOGIC_VECTOR (4 downto 0);
           Gin			: in  STD_LOGIC_VECTOR (4 downto 0);
           Bin			: in  STD_LOGIC_VECTOR (4 downto 0);
		     BrightNess	: in  STD_LOGIC_VECTOR (3 downto 0);
		   
           ROut: out STD_LOGIC_VECTOR (4 downto 0);
           GOut: out  STD_LOGIC_VECTOR (4 downto 0);
           BOut: out  STD_LOGIC_VECTOR (4 downto 0)
			);
end PPU_BRIGHTNESS;

architecture Behav_PPU_BRIGHTNESS of PPU_BRIGHTNESS is
	signal negBright		: STD_LOGIC_VECTOR (5 downto 0);
	signal tR				: STD_LOGIC_VECTOR (5 downto 0);
	signal tG				: STD_LOGIC_VECTOR (5 downto 0);
	signal tB				: STD_LOGIC_VECTOR (5 downto 0);
	
	signal Ro				: STD_LOGIC;
	signal Bo				: STD_LOGIC;
	signal Go				: STD_LOGIC;
	
begin
	--
	-- Get -Brightness on 5 bit (from +Brightness 4Bit)
	--
	process (BrightNess)
	begin
		negBright <= ("1" & BrightNess & BrightNess(3)) + 1;
	end process;

	process (Rin,Gin,Bin,negBright)
	begin
		-- Comp = Comp - Brigthness
		tR <= ('0' & Rin) + negBright;
		tG <= ('0' & Gin) + negBright;
		tB <= ('0' & Bin) + negBright;
	end process;
	
	--
	-- Clamp Result
	--
	process (tR,tG,tB,Ro,Go,Bo,negBright)
	begin
		-- Clamp to 31-0 range.
		--  Behaviour
		--  Overflow / negBright Sign   -> Operation.
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
		Ro <= not(tR(5));
		Go <= not(tG(5));
		Bo <= not(tB(5));
		
		ROut <= tR(4 downto 0) and (Ro&Ro&Ro&Ro&Ro);
		GOut <= tG(4 downto 0) and (Go&Go&Go&Go&Go);
		BOut <= tB(4 downto 0) and (Bo&Bo&Bo&Bo&Bo);
	end process;
	
end Behav_PPU_BRIGHTNESS;
