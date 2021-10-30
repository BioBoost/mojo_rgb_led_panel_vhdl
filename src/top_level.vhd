-- Adafruit RGB LED Matrix Display Driver
-- Top Level Entity
-- 
-- Copyright (c) 2012 Brian Nezvadovitz <http://nezzen.net>
-- This software is distributed under the terms of the MIT License shown below.
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.rgbmatrix.ALL;                 -- Constants & Configuration

ENTITY top_level IS
  PORT (
    rst_n             : IN STD_LOGIC;
    clk               : IN STD_LOGIC;
    cclk              : IN STD_LOGIC;    -- configuration clock (?) from AVR (to detect when AVR ready)

    -- Outputs to the 8 onboard LEDs
    leds              : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Shared TOP RGB LED Panel Connections
    t_board_clock       : OUT STD_LOGIC;
    t_line_select       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    t_latch             : OUT STD_LOGIC;
    t_output_enable_n   : OUT STD_LOGIC;

    -- Shared BOTTOM RGB LED Panel Connections
    b_board_clock       : OUT STD_LOGIC;
    b_line_select       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    b_latch             : OUT STD_LOGIC;
    b_output_enable_n   : OUT STD_LOGIC;

    -- RGB LED Panel Connections
    top_rgb_0         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_rgb_0      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    top_rgb_1         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_rgb_1      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    top_rgb_2         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_rgb_2      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    top_rgb_3         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_rgb_3      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    top_rgb_4         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_rgb_4      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    top_rgb_5         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_rgb_5      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Connection with AVR
    spi_sck   : in  std_logic;    -- SPI clock to from AVR
    spi_ss    : in  std_logic;    -- SPI slave select from AVR
    spi_mosi  : in  std_logic;    -- SPI serial data master out, slave in (AVR -> FPGA)
    spi_miso  : out std_logic;    -- SPI serial data master in, slave out (AVR <- FPGA)
    spi_channel : out std_logic_vector(3 downto 0);  -- analog read channel (input to AVR service task)
    avr_tx    : in  std_logic;    -- serial data transmited from AVR/USB (FPGA recieve)
    avr_rx    : out std_logic;    -- serial data for AVR/USB to receive (FPGA transmit)
    avr_rx_busy : in  std_logic;   -- AVR/USB buffer full (don't send data when true)
    
    -- SPI slave interface
    pi_spi_slave_mosi   : IN STD_LOGIC;
    pi_spi_slave_miso   : OUT STD_LOGIC;
    pi_spi_slave_n_ss   : IN STD_LOGIC;
    pi_spi_slave_sck    : IN STD_LOGIC
  );
END top_level;

ARCHITECTURE str OF top_level IS
  SIGNAL rst_p : STD_LOGIC;

  COMPONENT command_receiver IS
    PORT(
      -- FPGA signal
      clk          : IN     STD_LOGIC;          --clock of FPGA
      reset_n      : IN     STD_LOGIC;          --active low reset

      -- SPI signals
      spi_slave_sck   : IN     STD_LOGIC;       --spi clk from master
      spi_slave_n_ss  : IN     STD_LOGIC;       --active low slave select
      spi_slave_mosi  : IN     STD_LOGIC;       --master out, slave in
      spi_slave_miso  : OUT    STD_LOGIC := 'Z'; --master in, slave out

      -- For debugging
      state : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

      -- Panel selection
      panel_id : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

      -- Buffer control
      buffer_selection : IN STD_LOGIC;   -- Toggle to switch buffers (keep stable to keep buffers as is)

      -- Buffer writing
      line_address : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);         -- 0 to 31
      column_address : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);       -- 0 to 31
      w_red : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      w_green : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      w_blue : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      write_enable : OUT STD_LOGIC;       -- '1' to allow writing to memory

      -- Display selection
      enable_display : IN STD_LOGIC := '1';     -- When '0' the displays are turned off
      boot_mode : OUT STD_LOGIC := '0'          -- When in bootmode test patterns are displayed
    );
  END COMPONENT;

  SIGNAL panel_id : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL buffer_selection : STD_LOGIC;
  SIGNAL line_address : STD_LOGIC_VECTOR(4 DOWNTO 0);         -- 0 to 31
  SIGNAL column_address : STD_LOGIC_VECTOR(4 DOWNTO 0);       -- 0 to 31
  SIGNAL w_red : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL w_green : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL w_blue : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL write_enable : STD_LOGIC;
  SIGNAL boot_mode : STD_LOGIC;


  SIGNAL write_enable_panel_0 : STD_LOGIC;
  SIGNAL write_enable_panel_1 : STD_LOGIC;
  SIGNAL write_enable_panel_2 : STD_LOGIC;
  SIGNAL write_enable_panel_3 : STD_LOGIC;
  SIGNAL write_enable_panel_4 : STD_LOGIC;
  SIGNAL write_enable_panel_5 : STD_LOGIC;

BEGIN

-- NOTE: If you are not using the avr_interface component, then you should uncomment the
--       following lines to keep the AVR output lines in a high-impeadence state.  When
--       using the avr_interface, this will be done automatically and these lines should
--       be commented out (or else "multiple signals connected to output" errors).
  spi_miso <= 'Z';            -- keep AVR output lines high-Z
  avr_rx <= 'Z';            -- keep AVR output lines high-Z
  spi_channel <= "ZZZZ";        -- keep AVR output lines high-Z

  -- Some debugging
  --leds(7 DOWNTO 0) <= (OTHERS => '0');
  rst_p <= not rst_n;

  -- Panel selection
  write_enable_panel_0 <= '1' WHEN (panel_id = x"00" OR panel_id = x"FF") AND write_enable = '1' ELSE '0';
  write_enable_panel_1 <= '1' WHEN (panel_id = x"01" OR panel_id = x"FF") AND write_enable = '1' ELSE '0';
  write_enable_panel_2 <= '1' WHEN (panel_id = x"02" OR panel_id = x"FF") AND write_enable = '1' ELSE '0';
  write_enable_panel_3 <= '1' WHEN (panel_id = x"03" OR panel_id = x"FF") AND write_enable = '1' ELSE '0';
  write_enable_panel_4 <= '1' WHEN (panel_id = x"04" OR panel_id = x"FF") AND write_enable = '1' ELSE '0';
  write_enable_panel_5 <= '1' WHEN (panel_id = x"05" OR panel_id = x"FF") AND write_enable = '1' ELSE '0';

  -- LED panel controller
  U_LEDCTRL_0 : ENTITY work.ledctrl
    PORT MAP (
      rst         => rst_p,
      clk_in      => clk,

      -- Connection to LED panel
      clk_out     => t_board_clock,
      rgb1        => top_rgb_0,
      rgb2        => bottom_rgb_0,
      row_addr    => t_line_select,
      lat         => t_latch,
      oe_n        => t_output_enable_n,

      -- Buffer control
      buffer_selection => buffer_selection,

      -- Buffer writing
      line_address => line_address,
      column_address => column_address,
      w_red => w_red,
      w_green => w_green,
      w_blue => w_blue,
      write_enable => write_enable_panel_0,
      boot_mode => boot_mode
    );

  -- LED panel controller
  U_LEDCTRL_1 : ENTITY work.ledctrl
    PORT MAP (
      rst         => rst_p,
      clk_in      => clk,

      -- Connection to LED panel
      clk_out     => open,
      rgb1        => top_rgb_1,
      rgb2        => bottom_rgb_1,
      row_addr    => open,
      lat         => open,
      oe_n        => open,

      -- Buffer control
      buffer_selection => buffer_selection,

      -- Buffer writing
      line_address => line_address,
      column_address => column_address,
      w_red => w_red,
      w_green => w_green,
      w_blue => w_blue,
      write_enable => write_enable_panel_1,
      boot_mode => boot_mode
    );

  -- LED panel controller
  U_LEDCTRL_2 : ENTITY work.ledctrl
    PORT MAP (
      rst         => rst_p,
      clk_in      => clk,

      -- Connection to LED panel
      clk_out     => open,
      rgb1        => top_rgb_2,
      rgb2        => bottom_rgb_2,
      row_addr    => open,
      lat         => open,
      oe_n        => open,

      -- Buffer control
      buffer_selection => buffer_selection,

      -- Buffer writing
      line_address => line_address,
      column_address => column_address,
      w_red => w_red,
      w_green => w_green,
      w_blue => w_blue,
      write_enable => write_enable_panel_2,
      boot_mode => boot_mode
    );

  -- LED panel controller
  U_LEDCTRL_3 : ENTITY work.ledctrl
    PORT MAP (
      rst         => rst_p,
      clk_in      => clk,

      -- Connection to LED panel
      clk_out     => b_board_clock,
      rgb1        => top_rgb_3,
      rgb2        => bottom_rgb_3,
      row_addr    => b_line_select,
      lat         => b_latch,
      oe_n        => b_output_enable_n,

      -- Buffer control
      buffer_selection => buffer_selection,

      -- Buffer writing
      line_address => line_address,
      column_address => column_address,
      w_red => w_red,
      w_green => w_green,
      w_blue => w_blue,
      write_enable => write_enable_panel_3,
      boot_mode => boot_mode
    );

  -- LED panel controller
  U_LEDCTRL_4 : ENTITY work.ledctrl
    PORT MAP (
      rst         => rst_p,
      clk_in      => clk,

      -- Connection to LED panel
      clk_out     => open,
      rgb1        => top_rgb_4,
      rgb2        => bottom_rgb_4,
      row_addr    => open,
      lat         => open,
      oe_n        => open,

      -- Buffer control
      buffer_selection => buffer_selection,

      -- Buffer writing
      line_address => line_address,
      column_address => column_address,
      w_red => w_red,
      w_green => w_green,
      w_blue => w_blue,
      write_enable => write_enable_panel_4,
      boot_mode => boot_mode
    );

  -- LED panel controller
  U_LEDCTRL_5 : ENTITY work.ledctrl
    PORT MAP (
      rst         => rst_p,
      clk_in      => clk,

      -- Connection to LED panel
      clk_out     => open,
      rgb1        => top_rgb_5,
      rgb2        => bottom_rgb_5,
      row_addr    => open,
      lat         => open,
      oe_n        => open,

      -- Buffer control
      buffer_selection => buffer_selection,

      -- Buffer writing
      line_address => line_address,
      column_address => column_address,
      w_red => w_red,
      w_green => w_green,
      w_blue => w_blue,
      write_enable => write_enable_panel_5,
      boot_mode => boot_mode
    );

  U_command_receiver : ENTITY work.command_receiver
    PORT MAP(
      -- FPGA signal
      clk            => clk,
      reset_n        => rst_n,
      -- SPI signals
      spi_slave_sck  => pi_spi_slave_sck,
      spi_slave_n_ss => pi_spi_slave_n_ss,
      spi_slave_mosi => pi_spi_slave_mosi,
      spi_slave_miso => pi_spi_slave_miso,

      -- For debugging
      state => leds,

      -- Panel selection
      panel_id => panel_id,

      -- Buffer control
      buffer_selection => buffer_selection,

      -- Buffer writing
      line_address => line_address,
      column_address => column_address,
      w_red => w_red,
      w_green => w_green,
      w_blue => w_blue,
      write_enable => write_enable,
      boot_mode => boot_mode
    );

END str;
