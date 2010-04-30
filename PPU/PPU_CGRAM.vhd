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

	signal RAMBlock1		: ram_type1 := (
"000000000000000",
"111111111011101",
"100111011010110",
"101011100011000",
"101111101011010",
"110011110011100",
"110111111011110",
"111011111111111",
"100001101111111",
"000000000000000",
"000001100100000",
"111111101100000",
"100001101111111",
"101101110111111",
"011001001111011",
"000100011100111",
"000000000000000",
"111111111011101",
"111111111111111",
"000000000000000",
"111111100100000",
"111111110000000",
"111111111100000",
"111111111100000",
"100001101111111",
"000000000000000",
"111111101100000",
"001011100111111",
"100001101111111",
"000000000000000",
"001110011111111",
"000001100100000",
"000000000000000",
"111111111011101",
"000000000000000",
"000110110101111",
"010111001111001",
"010010111100000",
"010101100011100",
"000001100100000",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000000000010110",
"000000000011111",
"000000101111111",
"000001010011111",
"000000000000000",
"111111111011101",
"000000000000000",
"010110101101011",
"011110111101111",
"100111001110011",
"110001100011000",
"111001110011100",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"011010001111101",
"101010100011110",
"110010111111111",
"111101100011111",
"000000000000000",
"111111111011101",
"011100111001110",
"000000000000000",
"110001100011000",
"111111100110100",
"111111110010101",
"111111111111000",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000001110000000",
"001111111110001",
"000001111111001",
"100111111111111",
"000000000000000",
"111111111011101",
"000000000000000",
"011001010110111",
"110011111111011",
"000001000000000",
"000001100100000",
"000001111100000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111011101",
"000000000000000",
"000110101110001",
"010011111111111",
"001111010011011",
"001001101111111",
"000001111111111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111011101",
"000000000000000",
"010100000010111",
"100000000011111",
"100010100101001",
"101100110101101",
"110011000010000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"000000000000000",
"000110101110001",
"001111010011011",
"011101101111111",
"110001101011111",
"101100000011101",
"000000000001010",
"011100100011111",
"100010011000100",
"100111000001000",
"110011101110000",
"011000010110110",
"011010111011111",
"000001111111111",
"000000000000000",
"111111111111111",
"000000000000000",
"011100111001110",
"101001010010100",
"110001100011000",
"111001110011100",
"010110001011111",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000000000010110",
"000000000011111",
"000000101111111",
"000001010011111",
"000000000000000",
"111111111111111",
"000000000000000",
"000000111111111",
"000001100011111",
"000001111111111",
"000000010110111",
"000001000111111",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"011010001111101",
"101010100011110",
"110010111111111",
"111101100011111",
"000000000000000",
"111111111111111",
"000000000000000",
"110110100001000",
"110110110101101",
"111111000110001",
"000000010110111",
"000001000111111",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000001110000000",
"001111111110001",
"000001111111001",
"100111111111111",
"000000000000000",
"111111111111111",
"000000000000000",
"000000000010001",
"000000000010111",
"000000000011111",
"000000010110111",
"000001000111111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"000000000000000",
"000000111100000",
"000001011100000",
"000001111100000",
"000000010110111",
"000001000111111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"000000000000000",
"010010011000101",
"010110101001001",
"010110110101101",
"010001001010011",
"011111100011000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"010010100100011",
"011010111000100",
"011111000100101",
"100011010000110",
"100111011100111",
"100000000011111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000"
);

	signal RAMBlock2		: ram_type1 := (
"000000000000000",
"111111111011101",
"100111011010110",
"101011100011000",
"101111101011010",
"110011110011100",
"110111111011110",
"111011111111111",
"100001101111111",
"000000000000000",
"000001100100000",
"111111101100000",
"100001101111111",
"101101110111111",
"011001001111011",
"000100011100111",
"000000000000000",
"111111111011101",
"111111111111111",
"000000000000000",
"111111100100000",
"111111110000000",
"111111111100000",
"111111111100000",
"100001101111111",
"000000000000000",
"111111101100000",
"001011100111111",
"100001101111111",
"000000000000000",
"001110011111111",
"000001100100000",
"000000000000000",
"111111111011101",
"000000000000000",
"000110110101111",
"010111001111001",
"010010111100000",
"010101100011100",
"000001100100000",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000000000010110",
"000000000011111",
"000000101111111",
"000001010011111",
"000000000000000",
"111111111011101",
"000000000000000",
"010110101101011",
"011110111101111",
"100111001110011",
"110001100011000",
"111001110011100",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"011010001111101",
"101010100011110",
"110010111111111",
"111101100011111",
"000000000000000",
"111111111011101",
"011100111001110",
"000000000000000",
"110001100011000",
"111111100110100",
"111111110010101",
"111111111111000",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000001110000000",
"001111111110001",
"000001111111001",
"100111111111111",
"000000000000000",
"111111111011101",
"000000000000000",
"011001010110111",
"110011111111011",
"000001000000000",
"000001100100000",
"000001111100000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111011101",
"000000000000000",
"000110101110001",
"010011111111111",
"001111010011011",
"001001101111111",
"000001111111111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111011101",
"000000000000000",
"010100000010111",
"100000000011111",
"100010100101001",
"101100110101101",
"110011000010000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"000000000000000",
"000110101110001",
"001111010011011",
"011101101111111",
"110001101011111",
"101100000011101",
"000000000001010",
"011100100011111",
"100010011000100",
"100111000001000",
"110011101110000",
"011000010110110",
"011010111011111",
"000001111111111",
"000000000000000",
"111111111111111",
"000000000000000",
"011100111001110",
"101001010010100",
"110001100011000",
"111001110011100",
"010110001011111",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000000000010110",
"000000000011111",
"000000101111111",
"000001010011111",
"000000000000000",
"111111111111111",
"000000000000000",
"000000111111111",
"000001100011111",
"000001111111111",
"000000010110111",
"000001000111111",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"011010001111101",
"101010100011110",
"110010111111111",
"111101100011111",
"000000000000000",
"111111111111111",
"000000000000000",
"110110100001000",
"110110110101101",
"111111000110001",
"000000010110111",
"000001000111111",
"000000000000000",
"111111111111111",
"000000000000000",
"000001100100000",
"000001110000000",
"001111111110001",
"000001111111001",
"100111111111111",
"000000000000000",
"111111111111111",
"000000000000000",
"000000000010001",
"000000000010111",
"000000000011111",
"000000010110111",
"000001000111111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"000000000000000",
"000000111100000",
"000001011100000",
"000001111100000",
"000000010110111",
"000001000111111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"000000000000000",
"010010011000101",
"010110101001001",
"010110110101101",
"010001001010011",
"011111100011000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"111111111111111",
"010010100100011",
"011010111000100",
"011111000100101",
"100011010000110",
"100111011100111",
"100000000011111",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000",
"000000000000000"
);

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