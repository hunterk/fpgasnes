
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PPU_VRAMsync_ram is
	port (
		clock         : in  STD_LOGIC;
		
		-- Port 1 Read (8 Bit) / Write (16 Bit)
		writeE        : in  STD_LOGIC;
		AddressPair   : in  STD_LOGIC_VECTOR(14 downto 0);
		
		-- Port 2 Read (8 Bit)
		AddressImpair : in  STD_LOGIC_VECTOR(14 downto 0);
		
		-- Write Mode
		datain		  : in  STD_LOGIC_VECTOR(15 downto 0);
		
		-- Read Mode
		dataoutPair	  : out STD_LOGIC_VECTOR( 7 downto 0);
		dataoutImpair : out STD_LOGIC_VECTOR( 7 downto 0)
	);
end entity PPU_VRAMsync_ram;

architecture PPU_VRAMsync_ram of PPU_VRAMsync_ram is

   type ram_type is array (0 to 32767) of std_logic_vector(7 downto 0);
   signal RAMPair	: ram_type;
   signal RAMImpair : ram_type;

   signal read_addressPair   : std_logic_vector(14 downto 0);
   signal read_addressImpair : std_logic_vector(14 downto 0);
   signal impair             : std_logic_vector(14 downto 0);

begin

  RAMBlock1: process(clock) is
  begin
	if rising_edge(clock) then
		if writeE = '1' then
			RAMPair(to_integer(unsigned(AddressPair))) <= datain(15 downto 8);
		end if;
		read_addressPair <= AddressPair;
	end if;
  end process RAMBlock1;
  dataoutPair   <= RAMPair  (to_integer(unsigned(read_addressPair  )));
  
  impair		<= AddressImpair when writeE='0' else AddressPair;
  
  RAMBlock2: process(clock) is
  begin
	if rising_edge(clock) then
		if writeE = '1' then
			RAMImpair(to_integer(unsigned(impair))) <= datain(7 downto 0);
		end if;
		read_addressImpair <= impair;
	end if;
  end process RAMBlock2;
  
  dataoutImpair <= RAMImpair(to_integer(unsigned(read_addressImpair)));

end architecture PPU_VRAMsync_ram;
