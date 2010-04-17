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
		
		X					: in STD_LOGIC_VECTOR(7 downto 0);
		Y					: in STD_LOGIC_VECTOR(8 downto 0);
		
		XMosaicSig			: out STD_LOGIC;
		YMosaic				: out STD_LOGIC_VECTOR(8 downto 0)
	);
end PPU_MosaicCompute;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture ArchPPU_System of PPU_MosaicCompute is
begin
	YMosaic		<= Y;
	XMosaicSig	<= '1';
end architecture;
