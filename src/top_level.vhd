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

USE work.rgbmatrix.ALL;                 -- Constants & Configuration

ENTITY top_level IS
  PORT (
    rst        : IN STD_LOGIC;
    clk_in     : IN STD_LOGIC;
    div        : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- how fast to run led state machine 3=10MHz
    origin     : IN STD_LOGIC;
    data_valid : IN STD_LOGIC;
    data_in32  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- need to conform to a known LabView CLIP size

    frame   : OUT STD_LOGIC;            -- start of frame (for debug)
    clk_out : OUT STD_LOGIC;
    r1      : OUT STD_LOGIC;
    r2      : OUT STD_LOGIC;
    b1      : OUT STD_LOGIC;
    b2      : OUT STD_LOGIC;
    g1      : OUT STD_LOGIC;
    g2      : OUT STD_LOGIC;
    a       : OUT STD_LOGIC;
    b       : OUT STD_LOGIC;
    c       : OUT STD_LOGIC;
    lat     : OUT STD_LOGIC;
    oe_n    : OUT STD_LOGIC
    );
END top_level;

ARCHITECTURE str OF top_level IS
  -- Reset signals
  --@@@SIGNAL rst, rst_p, jtag_rst_out : STD_LOGIC;

  SIGNAL start, start_dly, wr_start : STD_LOGIC;

  -- Memory signals
  SIGNAL rd_addr       : STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
  SIGNAL data_incoming : STD_LOGIC_VECTOR((DATA_WIDTH/2)-1 DOWNTO 0);
  SIGNAL data_outgoing : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

-- Flags
--signal data_valid : std_logic;
BEGIN

  -- Reset button is an "active low" input, invert it so we can treat is as
  -- "active high", then OR it with the JTAG reset command output signal.
  --@@@
  --rst_p <= rst_n;
  --rst <= rst_p or jtag_rst_out;

  -- LED panel controller
  U_LEDCTRL : ENTITY work.ledctrl
    PORT MAP (
      rst    => rst,
      clk_in => clk_in,
      div    => div,                    -- clk_in / (div+1) is the internal clock rate

      frame       => frame,
      -- Connection to LED panel
      clk_out     => clk_out,
      rgb1(2)     => r1,
      rgb1(1)     => g1,
      rgb1(0)     => b1,
      rgb2(2)     => r2,
      rgb2(1)     => g2,
      rgb2(0)     => b2,
      row_addr(2) => c,
      row_addr(1) => b,
      row_addr(0) => a,
      lat         => lat,
      oe_n        => oe_n,
      -- Connection with framebuffer
      addr        => rd_addr,
      data        => data_outgoing
      );

  --@@@
  -- Virtual JTAG interface
  --U_JTAGIFACE : entity work.jtag_iface
  --    port map (
  --        rst     => rst,
  --        rst_out => jtag_rst_out,
  --        output  => data_incoming,
  --        valid   => data_valid
  --    );

  data_incoming <= data_in32(data_incoming'range);

  -- LabView interface does the synchronizing of data_valid so it stays in sync with data_in32 (hopefully)
  --Sync_DV: ENTITY work.Sync
  --  PORT MAP (
  --    clk    => clk_in,
  --    sync_i => data_valid,
  --    sync_o => dv);

  Sync_DV : ENTITY work.Sync
    PORT MAP (
      clk    => clk_in,
      sync_i => origin,
      sync_o => start);

  -- purpose: Find the rising edge of origin
  -- type   : sequential
  origin_edge : PROCESS (clk_in, rst) IS
  BEGIN  -- PROCESS detect edge of origin
    IF rst = '1' THEN                   -- asynchronous reset (active high)
      start_dly <= '1';
      wr_start  <= '0';
    ELSIF rising_edge(clk_in) THEN      -- rising clock edge

      -- On rising edge of sync'ed origin, assert wr_start for 1 period
      IF (start = '1' AND start_dly = '0') THEN
        wr_start <= '1';
      ELSE
        wr_start <= '0';
      END IF;

      start_dly <= start;
    END IF;
  END PROCESS origin_edge;

  -- wr_start is used to reset the internal write pointer in memory so that
  -- can set the "cursor" at the LED Matrix origin. This is the top left
  -- corner.

  -- Special memory for the framebuffer
  U_MEMORY : ENTITY work.memory
    PORT MAP (
      rst      => rst,
      clk      => clk_in,
      -- Writing side
      wr_start => wr_start,
      wr_en    => data_valid,
      wr_data  => data_incoming,
      -- Reading side
      rd_addr  => rd_addr,
      rd_data  => data_outgoing
      );

END str;
