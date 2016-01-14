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

    -- Outputs to the 8 onboard LEDs
    leds              : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

	 -- Some debugging
    --frame             : OUT STD_LOGIC;            -- start of frame (for debug)

	 -- RGB LED Panel Connections
    board_clock       : OUT STD_LOGIC;
    top_color         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    bottom_color      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    line_select       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    latch             : OUT STD_LOGIC;
    output_enable_n   : OUT STD_LOGIC
    );
END top_level;

ARCHITECTURE str OF top_level IS
  SIGNAL rst_p : STD_LOGIC;
BEGIN

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
      rgb1        => top_color,
      rgb2        => bottom_color,
      row_addr    => line_select,
      lat         => latch,
      oe_n        => output_enable_n
      );

END str;
