----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPUTTileAdress.vhd
-- Module Name:		PPUTTileAdress
--
-- Description: 	Compute a tile adress from tile coordinate in BG and
--                  BG tile mode and BG base adress.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPUBGTileAdress is
    Port ( 	BGTileMapBase 		: in STD_LOGIC_VECTOR (5 downto 0);
				TileCoordX		: in STD_LOGIC_VECTOR (5 downto 0);
				TileCoordY		: in STD_LOGIC_VECTOR (5 downto 0);
				SX				: in STD_LOGIC;
				SY				: in STD_LOGIC;
				
				BGTileAdr		: out STD_LOGIC_VECTOR(14 downto 0) --
	);
end PPUBGTileAdress;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPUBGTileAdress of PPUBGTileAdress is
	signal AdrUp				: std_logic_vector(6 downto 0);
	signal XD : std_logic;
	signal YD : std_logic;
begin
	--
	-- Create Adress HIGH
	--
	--  AAAAAA0|0.0000.0000 Adress
	-- +      Y|Y.YYYX.XXXX Y(3..0) & X(4..0) 
	--       X |            If SX => X(5), else 0
	--      Y  |            If SX and SY => Y(5) else 0
	--       Y |            If SY => Y(5) else 0
	--      == 
	--      YX 
	--      DD
	--
	--  000000
	--
	-- Compute Flags
	--
	process (TileCoordX,TileCoordY,SX,SY)
	begin
		YD <=  TileCoordY(5) and SY and SX;
		XD <= (TileCoordY(5) and SY and not(SX)) or (TileCoordX(5) and SX);
	end process;

	--
	-- Compute Upper Part.
	--
	process (BGTileMapBase,XD,YD, TileCoordY)
	begin
		AdrUp <= (BGTileMapBase & '0') + ("0000" & YD & XD & TileCoordY(4));
	end process;
	-- 7 Bit / 9 Bit
	BGTileAdr <= AdrUp(5 downto 0) & TileCoordY(3 downto 0) & TileCoordX(4 downto 0);
	
end PPUBGTileAdress;
