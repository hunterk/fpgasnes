----------------------------------------------------------------------------------
-- Create Date:   	06/23/2008 
-- Design Name:		PPU_CGRAM.vhd
-- Module Name:		PPU_CGRAM
--
-- Description: 	Memory module storing the palette.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--
-- Can read 2 port at the same time, but write to one port update both RAMs.
--
-- Register side will use writeE,CGAddrWR, wordIn , wordOutWR
-- Graphic  side will use        CGAddrWR, CGAddrR, wordOutWR, wordOutR  : Read two palette index at the same time.
--
entity PPU_CGRAM is
	port (
		clock			: in  STD_LOGIC;
		-- Register side.
		writeE			: in  STD_LOGIC;
		-- Read / Write Port A
		CGAddrWR		: in  STD_LOGIC_VECTOR( 7 downto 0);
		-- Read Port B
		CGAddrR 		: in  STD_LOGIC_VECTOR( 7 downto 0);
		
		-- Data when doing WRITE.
		wordIn	 		: in  STD_LOGIC_VECTOR(14 downto 0);
		
		-- Data Read Port A
		wordOutWR 		: out STD_LOGIC_VECTOR(14 downto 0);
		-- Data Read Port B
		wordOutR		: out STD_LOGIC_VECTOR(14 downto 0)
	);
end entity PPU_CGRAM;

architecture PPU_CGRAM of PPU_CGRAM is
	type ram_type1 is array (0 to 255) of STD_LOGIC_VECTOR(14 downto 0);

	signal RAMBlock1		: ram_type1;
	signal RAMBlock2		: ram_type1;

	signal read_AddressA	: STD_LOGIC_VECTOR(7 downto 0);
	signal read_AddressB	: STD_LOGIC_VECTOR(7 downto 0);
	signal selectAddr		: STD_LOGIC_VECTOR(7 downto 0);
begin
	-- ###########################################################################################
	-- Read and Write main table.
	--
	RAMBlockA: process(clock) is
	begin
		if rising_edge(clock) then
			if (writeE = '1') then
				RAMBlock1(to_integer(unsigned(CGAddrWR))) <= wordIn;
			end if;
			
			read_AddressA <= CGAddrWR;
		end if;
	end process RAMBlockA;
	wordOutWR  	<= RAMBlock1(to_integer(unsigned(read_AddressA)));

	-- ###########################################################################################
	-- Second Read color palette.
	--
	selectAddr <= CGAddrWR when writeE = '1' else CGAddrR;
	
	RAMBlockB: process(clock) is
	begin
		if rising_edge(clock) then
			if (writeE = '1') then
				RAMBlock2(to_integer(unsigned(CGAddrWR))) <= wordIn;
			end if;
			
			read_AddressB <= selectAddr;
		end if;
	end process RAMBlockB;
	wordOutR  	<= RAMBlock2(to_integer(unsigned(read_AddressB)));
end architecture PPU_CGRAM;

-- //CGDATA
-- //note: CGRAM palette data format is 15-bits
-- //(0,bbbbb,ggggg,rrrrr). Highest bit is ignored,
-- //as evidenced by $213b CGRAM data reads.
-- //
-- //anomie indicates writes to CGDATA work the same
-- //as writes to OAMDATA's low table. need to verify
-- //this on hardware.
-- void bPPU::mmio_w2122(uint8 value) {
--   if(!(regs.cgram_addr & 1)) {
--     regs.cgram_latchdata = value;
--   } else {
--     cgram_mmio_write((regs.cgram_addr & 0x01fe),     regs.cgram_latchdata);
--     cgram_mmio_write((regs.cgram_addr & 0x01fe) + 1, value & 0x7f);
--   }
--   regs.cgram_addr++;
--   regs.cgram_addr &= 0x01ff;
-- }
--
-- //CGDATAREAD
-- //note: CGRAM palette data is 15-bits (0,bbbbb,ggggg,rrrrr)
-- //therefore, the high byte read from each color does not
-- //update bit 7 of the PPU2 MDR.
-- uint8 bPPU::mmio_r213b() {
--   if(!(regs.cgram_addr & 1)) {
--     regs.ppu2_mdr  = cgram_mmio_read(regs.cgram_addr) & 0xff;
--   } else {
--     regs.ppu2_mdr &= 0x80;
--     regs.ppu2_mdr |= cgram_mmio_read(regs.cgram_addr) & 0x7f;
--   }
--   regs.cgram_addr++;
--   regs.cgram_addr &= 0x01ff;
--   return regs.ppu2_mdr;
-- }
