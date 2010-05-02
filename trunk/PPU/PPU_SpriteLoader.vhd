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

use CONSTREG.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_SpriteLoader is
    Port ( 	
		clock					: in STD_LOGIC;
		Interlace			: in STD_LOGIC;

		-- ##############################################################
		--   OAM Read / Write from CPU.
		-- ##############################################################
		Address 				: in STD_LOGIC_VECTOR(10 downto 0);
		CPUwrite			: in STD_LOGIC;
		DataIn	  			: in  STD_LOGIC_VECTOR(7 downto 0);
		DataOut	  			: out STD_LOGIC_VECTOR(7 downto 0);

		-- ##############################################################
		--   Line base system & Memory access.
		-- ##############################################################
		startLine			: in STD_LOGIC;
		startIndex			: in STD_LOGIC_VECTOR(8 downto 0);
		VRAMAdress		: out STD_LOGIC_VECTOR(14 downto 0);
		VRAMDataIn		: in	STD_LOGIC_VECTOR(15 downto 0);
		
		-- ##############################################################
		--   Storage adress of read result into sprite unit.
		-- ##############################################################
		tileNumber			: out STD_LOGIC_VECTOR(5 downto 0);	-- 0..33
		asBPP23				: out STD_LOGIC;
		pal					: out STD_LOGIC_VECTOR(2 downto 0);
		prio					: out STD_LOGIC_VECTOR(1 downto 0);
		FlipH					: out STD_LOGIC;
		
		endVSync			: in STD_LOGIC;
		R213E_TimeOver	: out STD_LOGIC;
		R213E_RangeOver: out	STD_LOGIC
	);
end PPU_SpriteLoader;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture APPU_SpriteLoader of PPU_SpriteLoader is
begin
	--
	-- TODO.
	--
	
	--
	-- Perform HFlip when loading into the sprite unit,
	-- (avoid 34x flip logic + 34x2 bit registers and associated store logic)
	--
	process(bppIn, flipH)
	begin
		if (flipH = '1') then
			bppOut <= 	bppIn(8) & bppIn(9) & bppIn(10) & bppIn(11) & bppIn(12) & bppIn(13) & bppIn(14) & bppIn(15) &
							bppIn(0) & bppIn(1) & bppIn(2) & bppIn(3) & bppIn(4) & bppIn(5) & bppIn(6) & bppIn(7);
		else
			bppOut <= bppIn;
		end if;
	end process;
end APPU_SpriteLoader;


----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_SpriteInside is
    Port ( 	
		ScrX		: in STD_LOGIC_VECTOR(7 downto 0);
		ScrY		: in STD_LOGIC_VECTOR(7 downto 0);
		Interlace : in STD_LOGIC;
		
		X			: in STD_LOGIC_VECTOR(9 downto 0);
		Y			: in STD_LOGIC_VECTOR(8 downto 0);
		sprSize	: in STD_LOGIC_VECTOR(2 downto 0); -- Direct value from register.

		inside		: out STD_LOGIC
	);
end PPU_SpriteInside;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture APPU_SpriteInside of PPU_SpriteInside is
begin
--
--  //if sprite is entirely offscreen and doesn't wrap around to the left side of the screen,
--  //then it is not counted. this *should* be 256, and not 255, even though dot 256 is offscreen.

--  sprite_item *spr = &sprite_list[active_sprite];
--  if(spr->x > 256 && (spr->x + spr->width - 1) < 512) return false;
--
--  int spr_height = (regs.oam_interlace == false) ? (spr->height) : (spr->height >> 1);
--  if(line >= spr->y && line < (spr->y + spr_height)) return true;
--  if((spr->y + spr_height) >= 256 && line < ((spr->y + spr_height) & 255)) return true;
--  return false;
--
end PPU_SpriteInside;
