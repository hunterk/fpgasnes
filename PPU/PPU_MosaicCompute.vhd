----------------------------------------------------------------------------------
-- Create Date:   	
-- Design Name:		PPU_MosaicCompute.vhd
-- Module Name:		PPU_MosaicCompute
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_MosaicCompute is
    Port (
		clock				: in STD_LOGIC;
		
		X					: in STD_LOGIC_VECTOR(8 downto 0);
		Y					: in STD_LOGIC_VECTOR(8 downto 0);
		R2106_MosaicSize	: in STD_LOGIC_VECTOR(3 downto 0);
		R2106_Reset			: in STD_LOGIC;
		
		XMosaicSig			: out STD_LOGIC;
		XNormal				: out STD_LOGIC_VECTOR(8 downto 0);
		YNormal				: out STD_LOGIC_VECTOR(8 downto 0);
		YMosaic				: out STD_LOGIC_VECTOR(8 downto 0)
	);
end PPU_MosaicCompute;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture ArchPPU_System of PPU_MosaicCompute is

	signal XCounter  : STD_LOGIC_VECTOR(3 downto 0);
	signal YCounter  : STD_LOGIC_VECTOR(4 downto 0);
	
	signal regY			: STD_LOGIC_VECTOR(8 downto 0);
	
begin
	process(clock, X, Y,
			R2106_MosaicSize, R2106_Reset, YCounter, XCounter)
			
		variable sXMosaicSig	: STD_LOGIC;
		variable sSize			: STD_LOGIC_VECTOR(4 downto 0);
		
	begin
		-- Y Resolution is twice the normal resolution. We need to double the counter for mosaic.

		sSize := R2106_MosaicSize & '1';
--		-- Reset X Counter at the beginning of each line
--		-- or when reaching the end of X pixel blocks.
--		-- At the beginning of each line, we check the Y Counter.
		if (clock'event and clock = '1') then
			if (R2106_MosaicSize /= "0000") then
				--
				-- Only at the beginning of the line.
				--
				if (X = "000000000") then
	
					-- When reach limit
					-- When first line
					-- When reset append on this line
					if ((YCounter = sSize) or (R2106_Reset='1') or (Y="000000000")) then
						YCounter	<= "00000";
						regY		<= Y;
					else
						YCounter	<= YCounter + 1;
					end if;
	
					XMosaicSig <= '1';
					XCounter <= "0000";
				else
					if (XCounter = R2106_MosaicSize) then
						XCounter <= "0000";
						XMosaicSig <= '1';
					else
						XCounter <= XCounter + 1;
						XMosaicSig <= '0';
					end if;
				end if;
	
				YMosaic <= regY;
			else
				XMosaicSig <= '1';
				YMosaic <= Y;
			end if;
			
			XNormal <= X;
			YNormal <= Y;
		end if;
		
		--
		-- Y Output Mosaic
		--
--		if ((YCounter = "00000") or (Y="000000000") or (R2106_MosaicSize="0000")) then
--			YMosaic <= Y;
--		else
--		end if;
		
		--
		-- X Output Mosaic
		--
--		XMosaicSig <= sXMosaicSig;
	end process;
end architecture;
