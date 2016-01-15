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

	 -- Some debugging
    --frame             : OUT STD_LOGIC;            -- start of frame (for debug)

	 -- RGB LED Panel Connections
    board_clock       : OUT STD_LOGIC;
    top_rgb           : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_rgb        : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    line_select       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    latch             : OUT STD_LOGIC;
    output_enable_n   : OUT STD_LOGIC;


    spi_sck   : in  std_logic;    -- SPI clock to from AVR
    spi_ss    : in  std_logic;    -- SPI slave select from AVR
    spi_mosi  : in  std_logic;    -- SPI serial data master out, slave in (AVR -> FPGA)
    spi_miso  : out std_logic;    -- SPI serial data master in, slave out (AVR <- FPGA)
    spi_channel : out std_logic_vector(3 downto 0);  -- analog read channel (input to AVR service task)
    avr_tx    : in  std_logic;    -- serial data transmited from AVR/USB (FPGA recieve)
    avr_rx    : out std_logic;    -- serial data for AVR/USB to receive (FPGA transmit)
    avr_rx_busy : in  std_logic     -- AVR/USB buffer full (don't send data when true)
    );
END top_level;

ARCHITECTURE str OF top_level IS
  SIGNAL rst_p : STD_LOGIC;

  SIGNAL frame_buffer_0_address  : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL frame_buffer_0_data     : STD_LOGIC_VECTOR(47 DOWNTO 0);

  --SIGNAL write_address  : STD_LOGIC_VECTOR(8 DOWNTO 0);
  --SIGNAL write_data     : STD_LOGIC_VECTOR(47 DOWNTO 0);
  --SIGNAL write_enable   : STD_LOGIC;

  COMPONENT frame_buffer_block_ram
    PORT (
      clka : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
      clkb : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
    );
  END COMPONENT;

BEGIN

-- NOTE: If you are not using the avr_interface component, then you should uncomment the
--       following lines to keep the AVR output lines in a high-impeadence state.  When
--       using the avr_interface, this will be done automatically and these lines should
--       be commented out (or else "multiple signals connected to output" errors).
  spi_miso <= 'Z';            -- keep AVR output lines high-Z
  avr_rx <= 'Z';            -- keep AVR output lines high-Z
  spi_channel <= "ZZZZ";        -- keep AVR output lines high-Z

  -- Some debugging
  leds(7 DOWNTO 4) <= (OTHERS => '1');
  leds(3 DOWNTO 1) <= (OTHERS => '0');
  rst_p <= not rst_n;

  -- LED panel controller
  U_LEDCTRL : ENTITY work.ledctrl
    PORT MAP (
      rst         => rst_p,
      clk_in      => clk,
      frame       => leds(0),

      -- Connection to LED panel
      clk_out     => board_clock,
      rgb1        => top_rgb,
      rgb2        => bottom_rgb,
      row_addr    => line_select,
      lat         => latch,
      oe_n        => output_enable_n,

      -- Connection with frame buffer
      memory_address  => frame_buffer_0_address,
      memory_data     => frame_buffer_0_data
      );

  -- Frame buffer BLOCK RAM 
  FRAME_BUFFER_0 : frame_buffer_block_ram
    PORT MAP (
      -- Write
      clka    => clk,
      wea     => (OTHERS => '1'),
      addra   => (OTHERS => '0'),
      dina    => (OTHERS => '1'),
      -- Read
      clkb    => clk,
      addrb   => frame_buffer_0_address,
      doutb   => frame_buffer_0_data
    );
END str;
