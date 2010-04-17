----------------------------------------------------------------------------------
-- Create Date:   	
-- Design Name:		PPU_LineCache.vhd
-- Module Name:		PPU_LineCache
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_LineCache is
    Port (
		clock				: in STD_LOGIC;
		
		Write				: in STD_LOGIC;
		
		AdrWrite			: in STD_LOGIC_VECTOR(7 downto 0);
		DataWrite			: in STD_LOGIC_VECTOR(27 downto 0);

		AdrRead				: in STD_LOGIC_VECTOR(7 downto 0);
		DataRead			: out STD_LOGIC_VECTOR(27 downto 0)
	);
end PPU_LineCache;
		
----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture ArchPPU_LineCache of PPU_LineCache is
  type ram_type is array (0 to 255)  
        of std_logic_vector (27 downto 0);  
  signal RAM : ram_type;
  signal read_AdrRead : std_logic_vector(7 downto 0);  
begin  
  process (clock)  
  begin  
    if (clock'event and clock = '1') then  
      if (Write = '1') then  
        RAM(conv_integer(AdrWrite)) <= DataWrite;  
      end if;
      read_AdrRead  <= AdrRead;  
    end if;
  end process;
  DataRead <= RAM(conv_integer(read_AdrRead));  
end ArchPPU_LineCache;
