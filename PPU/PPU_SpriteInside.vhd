----------------------------------------------------------------------------------
-- Create Date:   		
-- Design Name:		
-- Module Name:		
-- Description:		
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_SpriteInside is
    Port (
		ScrY		: in STD_LOGIC_VECTOR(7 downto 0); -- TODO Interlace : how Y is used ? Buggy for now
		Interlace	: in STD_LOGIC;
		
		X			: in STD_LOGIC_VECTOR(8 downto 0);
		Y			: in STD_LOGIC_VECTOR(7 downto 0);
		sprTileW	: in STD_LOGIC_VECTOR(3 downto 0);
		sprTileH	: in STD_LOGIC_VECTOR(3 downto 0);

		inside		: out STD_LOGIC
	);
end PPU_SpriteInside;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture APPU_SpriteInside of PPU_SpriteInside is
	signal endX : STD_LOGIC_VECTOR(9 downto 0);
begin
	process(X,sprTileW)
		-- Left sprH computation as 10 bit to handle easier interlace support later on.
		variable sprH		: STD_LOGIC_VECTOR(9 downto 0);
		variable maskSprH	: STD_LOGIC_VECTOR(9 downto 0);
		variable line		: STD_LOGIC_VECTOR(9 downto 0);		
	begin
		line := "00" & ScrY;
		
		endX <= ('0' & X) + ("000" & sprTileW & "000");
		if ((X > 256) and (endX < 513)) then
			inside <= '0';
		else
			if (Interlace = '1') then
				sprH := ("00" & Y) + ("00" & sprTileH & "0000");
			else
				sprH := ("00" & Y) + ("000" & sprTileH & "000");
			end if;
			
			if (line >= Y) and (line < sprH) then
				inside <= '1'
			else
				maskSprH := "00" & sprH(7 downto 0);
				if ((sprH >= 256) && (line < maskSprH)) then
					inside <= '1';
				else
					inside <= '0';
				end if;
			end if;
	end process;
end PPU_SpriteInside;