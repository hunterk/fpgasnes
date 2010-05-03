----------------------------------------------------------------------------------
-- Create Date:   		
-- Design Name:		
-- Module Name:		
-- Description:		
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------
-- Connectivity.
----------------------------------------------------------------------------------

entity PPU_OAMRAM is
    Port (
		clock : in STD_LOGIC;
		write : in STD_LOGIC;
		
		-- CPU / Register side.
		-- TODO : make sure that CPU side understand it is a BYTE and not a WORD adress.
		AdressReadWrite		: in STD_LOGIC_VECTOR(9 downto 0);
		DataIn				: in STD_LOGIC_VECTOR(7 downto 0);
		DataOut				: out STD_LOGIC_VECTOR(7 downto 0);

		-- Sprite Side
		SpriteNumber		: in STD_LOGIC_VECTOR(6 downto 0);
		X					: out STD_LOGIC_VECTOR(8 downto 0);
		Y					: out STD_LOGIC_VECTOR(7 downto 0);
		Char				: out STD_LOGIC_VECTOR(7 downto 0);
		NameTable			: out STD_LOGIC;
		FlipH				: out STD_LOGIC;
		FlipV				: out STD_LOGIC;
		Priority			: out STD_LOGIC_VECTOR(1 downto 0);
		Palette				: out STD_LOGIC_VECTOR(2 downto 0);
		Size				: out STD_LOGIC
	);
end PPU_OAMRAM;

----------------------------------------------------------------------------------
-- Synthetizable logic.
----------------------------------------------------------------------------------

architecture APPU_OAMRAM of PPU_OAMRAM is
	type ram_type1 is array (0 to 127) of STD_LOGIC_VECTOR(7 downto 0);
	type ram_type2 is array (0 to  31) of STD_LOGIC_VECTOR(7 downto 0);
	
	signal RAMBlockA1		: ram_type1; -- X
	signal RAMBlockA2		: ram_type1; -- Y
	signal RAMBlockA3		: ram_type1; -- Char
	signal RAMBlockA4		: ram_type1; -- Other
	signal RAMBlockA5		: ram_type2; -- X and S
	signal RAMBlockB1		: ram_type1; -- X
	signal RAMBlockB2		: ram_type1; -- Y
	signal RAMBlockB3		: ram_type1; -- Char
	signal RAMBlockB4		: ram_type1; -- Other
	signal RAMBlockB5		: ram_type2; -- X and S
	
	signal chipAdr			: STD_LOGIC_VECTOR(6 downto 0);
	signal chip5Adr			: STD_LOGIC_VECTOR(4 downto 0);
	signal sel				: STD_LOGIC_VECTOR(4 downto 0);
	
	signal sXTop			: STD_LOGIC;
	signal sSize			: STD_LOGIC;

	signal PipeAdr			: STD_LOGIC_VECTOR(2 downto 0);

	signal 	dataOutA1,
			dataOutB1,
			dataOutA2,
			dataOutB2,
			dataOutA3,
			dataOutB3,
			dataOutA4,
			dataOutB4,
			dataOutA5,
			dataOutB5
			: STD_LOGIC_VECTOR(7 downto 0);
			
	signal	read_AddressA1,
			read_AddressB1,
			read_AddressA2,
			read_AddressB2,
			read_AddressA3,
			read_AddressB3,
			read_AddressA4,
			read_AddressB4
			: STD_LOGIC_VECTOR(6 downto 0);
			
	signal	read_AddressA5,
			read_AddressB5
			: STD_LOGIC_VECTOR(4 downto 0);
begin
	-- s : adresss
	-- c : chip select
	--
	-- 9876543210
	-- 0ssssssscc
	-- 1----sssss

	chipAdr		<= AdressReadWrite(8 downto 2);
	chip5Adr	<= AdressReadWrite(4 downto 0);
	
	process(AdressReadWrite)
	begin
		if (AdressReadWrite(9) = '1') then
			sel <= "10000";
		else
			case (AdressReadWrite(1 downto 0)) is
			when "00" =>	sel <= "00001";
			when "01" =>	sel <= "00010";
			when "10" =>	sel <= "00100";
			when others =>	sel <= "01000";
			end case;
		end if;
	end process;

	process(clock, AdressReadWrite)
	begin
		if rising_edge(clock) then
			PipeAdr <= AdressReadWrite(9) & AdressReadWrite(1 downto 0);
		end if;
	end process;
	
	----------------------------------------------------------------------
	-- Block 1 / double port.
	----------------------------------------------------------------------
	RBA1: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(0)='1') then
				RAMBlockA1(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			
			read_AddressA1 <= chipAdr;
		end if;
	end process RBA1;
	dataOutA1  <= RAMBlockA1(to_integer(unsigned(read_AddressA1)));

	RBB1: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(0)='1') then
				RAMBlockB1(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			read_AddressB1 <= SpriteNumber;
		end if;
	end process RBB1;
	dataOutB1  <= RAMBlockB1(to_integer(unsigned(read_AddressB1)));
	
	----------------------------------------------------------------------
	-- Block 2 / double port.
	----------------------------------------------------------------------
	RBA2: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(1)='1') then
				RAMBlockA2(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			
			read_AddressA2 <= chipAdr;
		end if;
	end process RBA2;
	dataOutA2  <= RAMBlockA2(to_integer(unsigned(read_AddressA2)));

	RBB2: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(1)='1') then
				RAMBlockB2(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			read_AddressB2 <= SpriteNumber;
		end if;
	end process RBB2;
	dataOutB2  <= RAMBlockB2(to_integer(unsigned(read_AddressB2)));
	
	----------------------------------------------------------------------
	-- Block 3 / double port.
	----------------------------------------------------------------------
	RBA3: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(2)='1') then
				RAMBlockA3(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			
			read_AddressA3 <= chipAdr;
		end if;
	end process RBA3;
	dataOutA3  <= RAMBlockA3(to_integer(unsigned(read_AddressA3)));

	RBB3: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(2)='1') then
				RAMBlockB3(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			read_AddressB3 <= SpriteNumber;
		end if;
	end process RBB3;
	dataOutB3  <= RAMBlockB3(to_integer(unsigned(read_AddressB3)));
	
	----------------------------------------------------------------------
	-- Block 4 / double port.
	----------------------------------------------------------------------
	RBA4: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(3)='1') then
				RAMBlockA4(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			
			read_AddressA4 <= chipAdr;
		end if;
	end process RBA4;
	dataOutA4  <= RAMBlockA4(to_integer(unsigned(read_AddressA4)));

	RBB4: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(3)='1') then
				RAMBlockB4(to_integer(unsigned(chipAdr))) <= DataIn;
			end if;
			read_AddressB4 <= SpriteNumber;
		end if;
	end process RBB4;
	dataOutB4  <= RAMBlockB4(to_integer(unsigned(read_AddressB4)));
	
	----------------------------------------------------------------------
	-- Block 5 / double port.
	----------------------------------------------------------------------
	RBA5: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(4)='1') then
				RAMBlockA5(to_integer(unsigned(chip5Adr))) <= DataIn;
			end if;
			
			read_AddressA5 <= chip5Adr;
		end if;
	end process RBA5;
	dataOutA5  <= RAMBlockA5(to_integer(unsigned(read_AddressA5)));

	RBB5: process(clock) is
	begin
		if rising_edge(clock) then
			if (write = '1' and sel(4)='1') then
				RAMBlockB5(to_integer(unsigned(chip5Adr))) <= DataIn;
			end if;
			read_AddressB5 <= SpriteNumber(6 downto 2);
		end if;
	end process RBB5;
	dataOutB5  <= RAMBlockB5(to_integer(unsigned(read_AddressB5)));	


	process(PipeAdr, dataOutA1,dataOutA2,dataOutA3,dataOutA4,dataOutA5)
	begin
		if (PipeAdr(2) = '1') then
			DataOut <= dataOutA5;
		else
			case (PipeAdr(1 downto 0)) is
			when "00" =>
				DataOut <= dataOutA1;
			when "01" =>
				DataOut <= dataOutA2;
			when "10" =>
				DataOut <= dataOutA3;
			when others =>
				DataOut <= dataOutA4;
			end case;
		end if;
	end process;
		
	process(SpriteNumber, dataOutB5)
	begin
		case (SpriteNumber(1 downto 0)) is -- select bit i
		when "00" =>
			sXTop <= dataOutB5(0);
			sSize <= dataOutB5(1);
		when "01" =>
			sXTop <= dataOutB5(2);
			sSize <= dataOutB5(3);
		when "10" =>
			sXTop <= dataOutB5(4);
			sSize <= dataOutB5(5);
		when others => -- 11
			sXTop <= dataOutB5(6);
			sSize <= dataOutB5(7);
		end case;
	end process;

	X			<= sXTop & dataOutB1;
	Y			<= dataOutB2;
	Char		<= dataOutB3;
	
	-- vhoopppN
	NameTable	<= dataOutB4(0);
	Palette		<= dataOutB4(3 downto 1);
	Priority	<= dataOutB4(5 downto 4);
	FlipH		<= dataOutB4(6);
	FlipV		<= dataOutB4(7);
	Size 		<= sSize;	
end APPU_OAMRAM;
