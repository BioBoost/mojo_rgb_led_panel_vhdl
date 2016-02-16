--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:47:35 02/16/2016
-- Design Name:   
-- Module Name:   /home/bioboost/mojo/rgb_led_panel_vhdl/ise_files/tb_ledctrl.vhd
-- Project Name:  Mojo-Base-VHDL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ledctrl
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_ledctrl IS
END tb_ledctrl;
 
ARCHITECTURE behavior OF tb_ledctrl IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ledctrl
    PORT(
         rst : IN  std_logic;
         clk_in : IN  std_logic;
         clk_out : OUT  std_logic;
         rgb1 : OUT  std_logic_vector(2 downto 0);
         rgb2 : OUT  std_logic_vector(2 downto 0);
         row_addr : OUT  std_logic_vector(3 downto 0);
         lat : OUT  std_logic;
         oe_n : OUT  std_logic;
         buffer_selection : IN  std_logic;
         line_address : IN  std_logic_vector(4 downto 0);
         column_address : IN  std_logic_vector(4 downto 0);
         w_red : IN  std_logic_vector(7 downto 0);
         w_green : IN  std_logic_vector(7 downto 0);
         w_blue : IN  std_logic_vector(7 downto 0);
         write_enable : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rst : std_logic := '0';
   signal clk_in : std_logic := '0';
   signal buffer_selection : std_logic := '0';
   signal line_address : std_logic_vector(4 downto 0) := (others => '0');
   signal column_address : std_logic_vector(4 downto 0) := (others => '0');
   signal w_red : std_logic_vector(7 downto 0) := (others => '0');
   signal w_green : std_logic_vector(7 downto 0) := (others => '0');
   signal w_blue : std_logic_vector(7 downto 0) := (others => '0');
   signal write_enable : std_logic := '0';

 	--Outputs
   signal clk_out : std_logic;
   signal rgb1 : std_logic_vector(2 downto 0);
   signal rgb2 : std_logic_vector(2 downto 0);
   signal row_addr : std_logic_vector(3 downto 0);
   signal lat : std_logic;
   signal oe_n : std_logic;

   -- Clock period definitions
   constant clk_in_period : time := 10 ns;
   constant clk_out_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ledctrl PORT MAP (
          rst => rst,
          clk_in => clk_in,
          clk_out => clk_out,
          rgb1 => rgb1,
          rgb2 => rgb2,
          row_addr => row_addr,
          lat => lat,
          oe_n => oe_n,
          buffer_selection => buffer_selection,
          line_address => line_address,
          column_address => column_address,
          w_red => w_red,
          w_green => w_green,
          w_blue => w_blue,
          write_enable => write_enable
        );

   -- Clock process definitions
   clk_in_process :process
   begin
		clk_in <= '0';
		wait for clk_in_period/2;
		clk_in <= '1';
		wait for clk_in_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      rst <= '1';
      wait for 100 ns;	
      rst <= '0';

      wait for clk_in_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
