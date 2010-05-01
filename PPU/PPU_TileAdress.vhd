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
	signal relAdr: STD_LOGIC_VECTOR(11 downto 0);
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
		variable adrsFormat : STD_LOGIC_VECTOR(1 downto 0);
	begin
		adrsFormat := SY & SX;
		
		case adrsFormat is
		when "00" =>
			relAdr <= "00"                                & TileCoordY(4 downto 0) & TileCoordX(4 downto 0);
		when "01" =>
			relAdr <= "0" & TileCoordX(5)                 & TileCoordY(4 downto 0) & TileCoordX(4 downto 0);
		when "10" =>
			relAdr <= "0" & TileCoordY(5)                 & TileCoordY(4 downto 0) & TileCoordX(4 downto 0);
		when others => -- "11"
			relAdr <=       TileCoordY(5) & TileCoordX(5) & TileCoordY(4 downto 0) & TileCoordX(4 downto 0);
		end case;
	end process;

	--
	-- Compute Base Adress + Offset.
	--
	BGTileAdr <= (BGTileMapBase(4 downto 0) & "0000000000") + ("000" & relAdr);	
	
end PPUBGTileAdress;
