----------------------------------------------------------------------------------
-- Design Name:	PPU_WindowClip.vhd
-- Module Name:	PPU_WindowClip
--
-- Description: Perform window clipping for one pixel with all the windows attributes.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_WindowClip is
    Port ( 	
			--
			-- Input
			--
			InsideW1 	: in STD_LOGIC;
			InsideW2 	: in STD_LOGIC;
			EnableW1 	: in STD_LOGIC;
			EnableW2 	: in STD_LOGIC;
			InversionW1 : in STD_LOGIC;
			InversionW2 : in STD_LOGIC;
			
			EnableSubMain : in STD_LOGIC;
			
			WindowMaskLogicReg : in STD_LOGIC_VECTOR(1 downto 0);
			
			inside	 : out STD_LOGIC
	);
end PPU_WindowClip;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture PPU_WindowClip of PPU_WindowClip is
	signal out1,out2,outMask : STD_LOGIC;
	signal WindowMaskLogic : STD_LOGIC_VECTOR(1 downto 0);

	constant WIN_OR			: STD_LOGIC_VECTOR := "00";
	constant WIN_AND		: STD_LOGIC_VECTOR := "01";
	constant WIN_XOR		: STD_LOGIC_VECTOR := "10";
	constant WIN_NXOR		: STD_LOGIC_VECTOR := "11";
begin
	out1 <= ((InsideW1 xor InversionW1) or (not(EnableW1)));
	out2 <= ((InsideW2 xor InversionW2) or (not(EnableW2)));
	
	process(EnableW1, EnableW2, WindowMaskLogicReg,WindowMaskLogic,
				out1, out2)
	begin
	
		if (not(EnableW1='1' and EnableW2='1')) then
			WindowMaskLogic <= WIN_AND;
		else
			WindowMaskLogic <= WindowMaskLogicReg;
		end if;
		
		case WindowMaskLogic is
		when WIN_OR  =>
			outMask <= 	out1 or out2;
		when WIN_AND =>
			outMask <=	out1 and out2;
		when WIN_XOR =>
			outMask <=	out1 xor out2;
		when others  =>
			outMask <=	not(out1 xor out2);
		end case;
	end process;
	
	inside <= (outMask or (not(EnableSubMain)));
end PPU_WindowClip;
