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
    Port (	clock		: in	STD_LOGIC;
			reset		: in	STD_LOGIC;
			VGADACCLOCK : out	STD_LOGIC;
			
			-- ##############################################################
			--   CPU Side.
			-- ##############################################################
			Address 	: in   STD_LOGIC_VECTOR (5 downto 0);
			CPUwrite	: in   STD_LOGIC;
			DataIn	  	: in   STD_LOGIC_VECTOR (7 downto 0);
			
			R			: out  STD_LOGIC_VECTOR (7 downto 0);
			G			: out  STD_LOGIC_VECTOR (7 downto 0);
			B			: out  STD_LOGIC_VECTOR (7 downto 0);
			HSync		: out  STD_LOGIC;
			VSync		: out  STD_LOGIC;
			CSync		: out  STD_LOGIC;
			DE			: out  STD_LOGIC);
end TestVGA;

architecture Behavioral of TestVGA is
	component PPU_System is
		Port (
			clock				: in STD_LOGIC;
			reset				: in STD_LOGIC;
			
			X					: in STD_LOGIC_VECTOR(8 downto 0);
			Y					: in STD_LOGIC_VECTOR(8 downto 0);
			
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
		
    signal intHSync : std_logic := '0';
    signal intVSync : std_logic := '0';
    signal intX     : std_logic_vector(9 downto 0)  := "0000000000";
    signal intY     : std_logic_vector(9 downto 0)  := "0000000000";
    signal clockdiv : std_logic_vector(2 downto 0)  := "000";
	 signal showPixel : std_logic := '0';
	signal frame		: std_logic_vector(1 downto 0) := "00";
	
	signal clockSnes : STD_LOGIC;
	signal validPix : STD_LOGIC;
	
	signal DataOut : STD_LOGIC_VECTOR(7 downto 0);
	
	signal regR,regG,regB : STD_LOGIC_VECTOR(4 downto 0);
	signal XSnes : STD_LOGIC_VECTOR(9 downto 0);
	signal YSnes : STD_LOGIC_VECTOR(9 downto 0);
			
begin
	-- #####################################################################################################
	--
	--   Part generating the VGA signal
	--
	-- #####################################################################################################
	
	process(clock)
	begin
      if (clock'event) and (clock='1') then
			clockdiv <= clockdiv + 1;
		end if;
	end process;

	VGADACCLOCK <= clockdiv(1);
	clockSnes	<= clockdiv(2);
	XSnes	<= intX + 850;
	YSnes	<= intY + 980;
	
	-- Use cloc div 4 here.
	process(clockdiv(1),intX, intY)
	begin
		-- First STAGE : Clocked X and Y. every 4 clock tick.
		--
		if (clockdiv(1)'event) and (clockdiv(1)='1') then
			-- Trick : Y increment take one clock cycle, so we do it on 799. X and Y are on the same clock.
	      if (intX >= 799) then -- 799x4
	         intX <= "0000000000"; -- 10 Bit Counter.
			 	intY <= intY + 1;
				if (intY >= 524) then -- and intX>=799 written upper. : correct test, dont wait 0,525.
					intY <= "0000000000";
					frame <= frame + 1;
				end if;
	      else
	         intX <= intX + 1;
	      end if;
	   end if;
		
		--
      if (intX >= 0) and (intX <= 96) then
         intHSync <= '0';
      else
         intHSync <= '1';
      end if;

      if (intY < 2) then
         intVSync <= '0';
      else
         intVSync <= '1';
      end if;	 

		-- Show pixel.
      if (intX >= 144) and (intX < 700 ) then -- Show pixel.
			if ((intY>=0) and (intY<480)) then
				showPixel <= '1';
			else
				showPixel <= '0';
			end if;
	   else
         showPixel <= '0';
      end if;
	end process;
	
	-- #####################################################################################################
	--
	--   Part embedding the PPU.
	--
	-- #####################################################################################################
	
	instanceSystem : PPU_System port map
	(
		clock			=> clockSnes,
		reset			=> reset,
		
		X				=> XSnes(9 downto 1),
		Y				=> YSnes(9 downto 1),
		
		-- ##############################################################
		--   CPU Side.
		-- ##############################################################
		Address 		=> Address,
		CPUwrite		=> CPUwrite,
		DataIn	  		=> DataIn,
		DataOut	  		=> DataOut,

		-- ##############################################################
		--   Video output Side.
		-- ##############################################################
		Red			=> regR,
		Green		=> regG,
		Blue		=> regB
	);

	-- 5 Bit --> 8 Bit
	process(XSnes, regR, regG, regB, showPixel)
		variable isXM1  : STD_LOGIC;
		variable isX512 : STD_LOGIC;
		variable isYM1  : STD_LOGIC;
		variable isY480 : STD_LOGIC;
		variable isSX512 : STD_LOGIC;
		variable isSY480 : STD_LOGIC;
	begin
		if (XSnes = 1023) then isXM1  := '1'; else isXM1  := '0'; end if;
		if (YSnes = 1023) then isYM1  := '1'; else isYM1  := '0'; end if;
		if (XSnes = 512)  then isX512 := '1'; else isX512 := '0'; end if;
		if (YSnes = 480)  then isY480 := '1'; else isY480 := '0'; end if;

		if (XSnes >= 512)  then isSX512 := '1'; else isSX512 := '0'; end if;
		if (YSnes >= 480)  then isSY480 := '1'; else isSY480 := '0'; end if;

		if (isXM1 = '0' and isYM1 = '0' and isX512 = '0' and isY480 = '0') then
			if (isSX512 = '0' and isSY480 = '0') then
				R <= regR & regR(4 downto 2);
				G <= regG & regG(4 downto 2);
				B <= regB & regB(4 downto 2);
			else
				R <= "00000000";
				G <= "00000000";
				B <= "00000000";
			end if;
		else
			if (isXM1 = '1' or isX512 = '1') then
				R <= "11111111";
				G <= "00000000";
				B <= "00000000";
			else
				R <= "11111111";
				G <= "11111111";
				B <= "00000000";
			end if;
		end if;
	end process;

	HSync <= intHSync;
	VSync <= intVSync;
	CSync <= '0';
	DE <= '1';
end Behavioral;

