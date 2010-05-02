----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_SpriteSelector.vhd
-- Module Name:		PPU_SpriteSelector
--
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

entity PPU_SpriteSelector is
    Port (
		Sprites			: in STD_LOGIC_VECTOR (33 downto 0);

		Spr1,Spr2,Spr3,Spr4,Spr5,Spr6,Spr7,Spr8,
		Spr9,Spr10,Spr11,Spr12,Spr13,Spr14,Spr15,Spr16,
		Spr17,Spr18,Spr19,Spr20,Spr21,Spr22,Spr23,Spr24,
		Spr25,Spr26,Spr27,Spr28,Spr29,Spr30,Spr31,Spr32,
		Spr33,Spr34
						: in STD_LOGIC_VECTOR (8 downto 0);	-- OOPPPxxxx

		OutSpr			: out STD_LOGIC_VECTOR(8 downto 0)
	);
end PPU_SpriteSelector;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture ArchPPU_SpriteSelector of PPU_SpriteSelector is
begin
	process(
		Sprites,
		Spr1,Spr2,Spr3,Spr4,Spr5,Spr6,Spr7,Spr8,
		Spr9,Spr10,Spr11,Spr12,Spr13,Spr14,Spr15,Spr16,
		Spr17,Spr18,Spr19,Spr20,Spr21,Spr22,Spr23,Spr24,
		Spr25,Spr26,Spr27,Spr28,Spr29,Spr30,Spr31,Spr32,
		Spr33,Spr34)
	begin
		if (Sprites(0)='1') then
		OutSpr <= Spr1;
		else
		if (Sprites(1)='1') then
		OutSpr <= Spr2;
		else
		if (Sprites(2)='1') then
		OutSpr <= Spr3;
		else
		if (Sprites(3)='1') then
		OutSpr <= Spr4;
		else
		if (Sprites(4)='1') then
		OutSpr <= Spr5;
		else
		if (Sprites(5)='1') then
		OutSpr <= Spr6;
		else
		if (Sprites(6)='1') then
		OutSpr <= Spr7;
		else
		if (Sprites(7)='1') then
		OutSpr <= Spr8;
		else
		if (Sprites(8)='1') then
		OutSpr <= Spr9;
		else
		if (Sprites(9)='1') then
		OutSpr <= Spr10;
		else
		if (Sprites(10)='1') then
		OutSpr <= Spr11;
		else
		if (Sprites(11)='1') then
		OutSpr <= Spr12;
		else
		if (Sprites(12)='1') then
		OutSpr <= Spr13;
		else
		if (Sprites(13)='1') then
		OutSpr <= Spr14;
		else
		if (Sprites(14)='1') then
		OutSpr <= Spr15;
		else
		if (Sprites(15)='1') then
		OutSpr <= Spr16;
		else
		if (Sprites(16)='1') then
		OutSpr <= Spr17;
		else
		if (Sprites(17)='1') then
		OutSpr <= Spr18;
		else
		if (Sprites(18)='1') then
		OutSpr <= Spr19;
		else
		if (Sprites(19)='1') then
		OutSpr <= Spr20;
		else
		if (Sprites(20)='1') then
		OutSpr <= Spr21;
		else
		if (Sprites(21)='1') then
		OutSpr <= Spr22;
		else
		if (Sprites(22)='1') then
		OutSpr <= Spr23;
		else
		if (Sprites(23)='1') then
		OutSpr <= Spr24;
		else
		if (Sprites(24)='1') then
		OutSpr <= Spr25;
		else
		if (Sprites(25)='1') then
		OutSpr <= Spr26;
		else
		if (Sprites(26)='1') then
		OutSpr <= Spr27;
		else
		if (Sprites(27)='1') then
		OutSpr <= Spr28;
		else
		if (Sprites(28)='1') then
		OutSpr <= Spr29;
		else
		if (Sprites(29)='1') then
		OutSpr <= Spr30;
		else
		if (Sprites(30)='1') then
		OutSpr <= Spr31;
		else
		if (Sprites(31)='1') then
		OutSpr <= Spr32;
		else
		if (Sprites(32)='1') then
		OutSpr <= Spr33;
		else
		if (Sprites(33)='1') then
		OutSpr <= Spr34;
		else
		OutSpr <= "000000000";
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
		end if;
	end process;
end ArchPPU_SpriteSelector;
