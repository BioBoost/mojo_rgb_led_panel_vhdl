--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:46:45 02/15/2016
-- Design Name:   
-- Module Name:   /home/bioboost/mojo/rgb_led_panel_vhdl/ise_files/tb_simple_spi_slave.vhd
-- Project Name:  Mojo-Base-VHDL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: simple_spi_slave
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
 
ENTITY tb_simple_spi_slave IS
END tb_simple_spi_slave;
 
ARCHITECTURE behavior OF tb_simple_spi_slave IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT simple_spi_slave
    PORT(
         fpga_clock : IN  std_logic;
         reset_n : IN  std_logic;
         sclk : IN  std_logic;
         ss_n : IN  std_logic;
         mosi : IN  std_logic;
         miso : OUT  std_logic;
         rx_req : IN  std_logic;
         rrdy : OUT  std_logic;
         busy : OUT  std_logic;
         rx_data : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal fpga_clock : std_logic := '0';
   signal reset_n : std_logic := '0';
   signal sclk : std_logic := '0';
   signal ss_n : std_logic := '0';
   signal mosi : std_logic := '0';
   signal rx_req : std_logic := '0';

 	--Outputs
   signal miso : std_logic;
   signal rrdy : std_logic;
   signal busy : std_logic;
   signal rx_data : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant fpga_clock_period : time := 10 ns;
   constant sclk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: simple_spi_slave PORT MAP (
          fpga_clock => fpga_clock,
          reset_n => reset_n,
          sclk => sclk,
          ss_n => ss_n,
          mosi => mosi,
          miso => miso,
          rx_req => rx_req,
          rrdy => rrdy,
          busy => busy,
          rx_data => rx_data
        );

   -- Clock process definitions
   fpga_clock_process :process
   begin
		fpga_clock <= '0';
		wait for fpga_clock_period/2;
		fpga_clock <= '1';
		wait for fpga_clock_period/2;
   end process;

   -- Stimulus process
   master_side: process
   begin		
      -- hold reset state for 100 ns.
      reset_n <= '0';
      wait for 100 ns;
      reset_n <= '1';

      wait for fpga_clock_period*10;

      -- insert stimulus here
      sclk <= '0';      -- Default state for clock (POL = 0)
      ss_n <= '0';      -- Address device

      -- Bit 0
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 1
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 2
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 3
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 4
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 5
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 6
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 7
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- SECOND BYTE
      wait for 250 ns;

      -- Bit 0
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 1
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 2
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 3
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 4
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 5
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 6
      mosi <= '0';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)

      -- Bit 7
      mosi <= '1';
      wait for 100 ns;
      sclk <= '1';      -- Rising edge of clock (take in data by slave)
      wait for 100 ns;
      sclk <= '0';      -- Default state for clock (POL = 0)


      -- End of transaction
      wait for 250 ns;
      ss_n <= '1';      -- De-address device
      wait;
   end process;

   -- Get the data from the spi module
   read_data :process
   begin
    wait until rrdy'event and rrdy='1';
    wait for 10 ns;
    rx_req <= '1';
    wait for 20 ns;
    rx_req <= '0';
   end process;

END;
