--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:54:33 02/15/2016
-- Design Name:   
-- Module Name:   /home/bioboost/mojo/rgb_led_panel_vhdl/ise_files/tb_command_receiver.vhd
-- Project Name:  Mojo-Base-VHDL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: command_receiver
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
use ieee.numeric_std.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_command_receiver IS
END tb_command_receiver;
 
ARCHITECTURE behavior OF tb_command_receiver IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT command_receiver
    PORT(
         clk : IN  std_logic;
         reset_n : IN  std_logic;
         spi_slave_sck : IN  std_logic;
         spi_slave_n_ss : IN  std_logic;
         spi_slave_mosi : IN  std_logic;
         spi_slave_miso : OUT  std_logic;
         state : OUT  std_logic_vector(7 downto 0);
         panel_id : OUT  std_logic_vector(7 downto 0);
         buffer_selection : OUT  std_logic;
         line_address : OUT  std_logic_vector(4 downto 0);
         column_address : OUT  std_logic_vector(4 downto 0);
         w_red : OUT  std_logic_vector(7 downto 0);
         w_green : OUT  std_logic_vector(7 downto 0);
         w_blue : OUT  std_logic_vector(7 downto 0);
         write_enable : OUT STD_LOGIC       -- '1' to allow writing to memory
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset_n : std_logic := '0';
   signal spi_slave_sck : std_logic := '0';
   signal spi_slave_n_ss : std_logic := '0';
   signal spi_slave_mosi : std_logic := '0';

 	--Outputs
   signal spi_slave_miso : std_logic;
   signal state : std_logic_vector(7 downto 0);
   signal panel_id : std_logic_vector(7 downto 0);
   signal buffer_selection : std_logic;
   signal line_address : std_logic_vector(4 downto 0);
   signal column_address : std_logic_vector(4 downto 0);
   signal w_red : std_logic_vector(7 downto 0);
   signal w_green : std_logic_vector(7 downto 0);
   signal w_blue : std_logic_vector(7 downto 0);
   signal write_enable : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;

   signal byte : std_logic_vector(7 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: command_receiver PORT MAP (
          clk => clk,
          reset_n => reset_n,
          spi_slave_sck => spi_slave_sck,
          spi_slave_n_ss => spi_slave_n_ss,
          spi_slave_mosi => spi_slave_mosi,
          spi_slave_miso => spi_slave_miso,
          state => state,
          panel_id => panel_id,
          buffer_selection => buffer_selection,
          line_address => line_address,
          column_address => column_address,
          w_red => w_red,
          w_green => w_green,
          w_blue => w_blue,
          write_enable => write_enable
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   master_side: process
   begin    
      -- hold reset state for 100 ns.
      reset_n <= '0';
      wait for 100 ns;
      reset_n <= '1';

      wait for clk_period*10;

      -- insert stimulus here
      spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
      spi_slave_n_ss <= '0';      -- Address device


      -- switch buffers byte
      byte <= x"08";
      wait for 200 ns;
      for i in 7 DOWNTO 0 loop
        spi_slave_mosi <= byte(i);
        wait for 100 ns;
        spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
        wait for 100 ns;
        spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
      end loop;


      -- switch buffers byte
      byte <= x"08";
      wait for 200 ns;
      for i in 7 DOWNTO 0 loop
        spi_slave_mosi <= byte(i);
        wait for 100 ns;
        spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
        wait for 100 ns;
        spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
      end loop;


      -- Command byte
      byte <= x"01";
		  wait for 200 ns;
      for i in 7 DOWNTO 0 loop
        spi_slave_mosi <= byte(i);
        wait for 100 ns;
        spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
        wait for 100 ns;
        spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
      end loop;


      -- Panel id byte
      byte <= x"05";
		  wait for 200 ns;
      for i in 7 DOWNTO 0 loop
        spi_slave_mosi <= byte(i);
        wait for 100 ns;
        spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
        wait for 100 ns;
        spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
      end loop;


      -- Line address
      byte <= x"AA";
		  wait for 200 ns;
      for i in 7 DOWNTO 0 loop
        spi_slave_mosi <= byte(i);
        wait for 100 ns;
        spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
        wait for 100 ns;
        spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
      end loop;

      for b in 1 TO 32 loop
        byte <= std_logic_vector(to_unsigned(b, 8));
        wait for 200 ns;
        for i in 7 DOWNTO 0 loop
          spi_slave_mosi <= byte(i);
          wait for 100 ns;
          spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
          wait for 100 ns;
          spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
        end loop;
        wait for 200 ns;
        for i in 7 DOWNTO 0 loop
          spi_slave_mosi <= byte(i);
          wait for 100 ns;
          spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
          wait for 100 ns;
          spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
        end loop;
        wait for 200 ns;
        for i in 7 DOWNTO 0 loop
          spi_slave_mosi <= byte(i);
          wait for 100 ns;
          spi_slave_sck <= '1';      -- Rising edge of clock (take in data by slave)
          wait for 100 ns;
          spi_slave_sck <= '0';      -- Default state for clock (POL = 0)
        end loop;
      end loop;













      spi_slave_n_ss <= '1';      -- De-address device



      -- SECOND BYTE
      wait for 250 ns;

      -- End of transaction
      wait for 250 ns;
      spi_slave_n_ss <= '1';      -- De-address device
      wait;
   end process;

END;
