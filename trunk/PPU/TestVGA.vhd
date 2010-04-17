----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:49:39 07/25/2008 
-- Design Name: 
-- Module Name:    TestVGA - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TestVGA is
    Port ( clock : in  STD_LOGIC;
			write : in STD_LOGIC;
			R : out  STD_LOGIC_VECTOR (7 downto 0);
			G : out  STD_LOGIC_VECTOR (7 downto 0);
			B : out  STD_LOGIC_VECTOR (7 downto 0);
			HSync : out  STD_LOGIC;
			VSync : out  STD_LOGIC;
			CSync : out  STD_LOGIC;
			DE : out  STD_LOGIC
			);
end TestVGA;

architecture Behavioral of TestVGA is
    signal intHSync : std_logic := '0';
    signal intVSync : std_logic := '0';
    signal intX     : std_logic_vector(9 downto 0)  := "0000000000";
    signal intY     : std_logic_vector(9 downto 0)  := "0000000000";
    signal clockdiv : std_logic_vector(2 downto 0)  := "000";
	 signal showPixel : std_logic := '0';
	 signal frame		: std_logic_vector(1 downto 0) := "00";

	signal Adr : STD_LOGIC_VECTOR(7 downto 0);
	signal Value : STD_LOGIC_VECTOR(7 downto 0);
	signal DataReady : STD_LOGIC;

	signal cpuAddress	: STD_LOGIC_VECTOR(5 downto 0);
	signal CPUwrite		: STD_LOGIC;
	signal DataIn		: STD_LOGIC_VECTOR(7 downto 0);
	signal DataOut		: STD_LOGIC_VECTOR(7 downto 0);
	
	
	component PPU_System is
		Port (
			clock				: in STD_LOGIC;
			reset				: in STD_LOGIC;
			
			X					: in STD_LOGIC_VECTOR(9 downto 0);
			Y					: in STD_LOGIC_VECTOR(8 downto 0);
			ValidPixel			: in STD_LOGIC;
			
			-- ##############################################################
			--   CPU Side.
			-- ##############################################################
			Address 			: in STD_LOGIC_VECTOR(5 downto 0);
			CPUwrite			: in STD_LOGIC;
			DataIn	  			: in  STD_LOGIC_VECTOR(7 downto 0);
			DataOut	  			: out STD_LOGIC_VECTOR(7 downto 0);

			-- ##############################################################
			--   Video output Side.
			-- ##############################################################
			Red					: out STD_LOGIC_VECTOR(4 downto 0);
			Green				: out STD_LOGIC_VECTOR(4 downto 0);
			Blue				: out STD_LOGIC_VECTOR(4 downto 0)
		);
	end component;

	signal regR,regG,regB : STD_LOGIC_VECTOR(4 downto 0);
	signal clockSnes, clockVGA : STD_LOGIC;
	signal reset : STD_LOGIC;
	signal validPix : STD_LOGIC;
begin
	
	process(clock)
	begin
      if (clock'event) and (clock='1') then
			clockdiv <= clockdiv + 1;
		end if;
	end process;

	clockSnes	<= clockdiv(2);
	clockVGA	<= clockdiv(1);
	
	cpuAddress	<= intX(5 downto 0);
	CPUwrite	<= write;
	DataIn		<= intY(7 downto 0);
	
	-- Use cloc div 2 here.
	process(clockVGA,intX, intY)
	begin
		-- First STAGE : Clocked X and Y. every 2 clock tick.
		--
		if (clockVGA'event) and (clockVGA='1') then
			-- Trick : Y increment take one clock cycle, so we do it on 799. X and Y are on the same clock.
	      if (intX >= 799) then -- 799x4
	         intX <= "0000000000"; -- 10 Bit Counter.
			 intY <= intY + 1;
			if (intY >= 524) then -- and intX>=799 written upper. : correct test, dont wait 0,525.
				intY <= "0000000000";
				frame <= frame + 1;
--				reset <= '1';
			else
--				reset <= '0';				
			end if;
	      else
			intX <= intX + 1;
--			reset <= '0';
	      end if;
	   end if;

		-- Show pixel.
--      if (intX >= 144) and (intX < (144+480) ) then -- Show pixel.
--			if (intY>=(31+2)) and (intY<(31+2+480)) then
--      		showPixel <= '1';
--			else
--				showPixel <= '0';
--			end if;
--	   else
--         showPixel <= '0';
--      end if;
	end process;
	
	validPix <= '1';

	process(intX)
	begin
--		if (intX >= 0) and (intX <= 96) then
		if (intX >= 659) and (intX <= 755) then
			intHSync <= '0';
		else
			intHSync <= '1';
		end if;
	end process;
	
	process(intY)
	begin
		if (intY >= 493) and (intY <= 494) then
--		if (intY < 2) then
			intVSync <= '0';
		else
			intVSync <= '1';
		end if;	 
	end process;
		
--	instanceSystem : PPU_System port map
--	(
--		clock			=> clockSnes,
--		reset			=> reset,
--		
--		X				=> intX(9 downto 0),
--		Y				=> intY(8 downto 0),
--		ValidPixel		=> validPix,
--		
--		-- ##############################################################
--		--   CPU Side.
--		-- ##############################################################
--		Address 		=> cpuAddress,
--		CPUwrite		=> CPUwrite,
--		DataIn	  	=> DataIn,
--		DataOut	  	=> DataOut,
--
--		-- ##############################################################
--		--   Video output Side.
--		-- ##############################################################
--		Red			=> regR,
--		Green			=> regG,
--		Blue			=> regB
--	);

	-- 5 Bit --> 8 Bit
	R <= intX(7 downto 0); --regR & regR(2 downto 0);
	G <= intX(7 downto 0); --regG & regG(2 downto 0);
	B <= intY(7 downto 0); --regB & regB(2 downto 0);

	HSync	<= intHSync;
	VSync	<= intVSync;
	CSync	<= '0'; -- 1 When encoding sync on the green channel.
	DE		<= '1';
end Behavioral;

