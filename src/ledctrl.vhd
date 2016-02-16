-- Adafruit RGB LED Matrix Display Driver
-- Finite state machine to control the LED matrix hardware
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

-- For some great documentation on how the RGB LED panel works, see this page:
-- http://www.rayslogic.com/propeller/Programming/AdafruitRGB/AdafruitRGB.htm
-- or this page
-- http://www.ladyada.net/wiki/tutorials/products/rgbledmatrix/index.html#how_the_matrix_works

-- S. Goadhouse  2014/04/16
--
-- Modified to use updated clk_div which was changed to output a clock enable
-- so that all of VHDL runs on the same clock domain. Also changed RGB outputs
-- so that they transition on falling edge of clk_out. This maximizes the
-- setup and hold times. clk_out, lat and oe_n are now output directly from
-- f/fs to minimize clock to output delay. Lengthed oe_n deassert time by one
-- 10 MHz period.
--
-- Modified the state machine extensively in order to minimize the LED
-- ghosting. Going with suggestions found on Adafruit forums.
--
-- 1. Write all 0's to the row shift register first before start PWM refreshes.
-- 2. Perform all PWM sub-periods on a single row before advancing to the next row.
--    1. This minimizes the number of row transitions which is where the ghost appears
--    2. May want to try writing all 0's to a row at the end of PWM and before advancing to the next row.
--
-- 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.rgbmatrix.ALL;

ENTITY ledctrl IS
  PORT (
    rst      : IN  STD_LOGIC;
    clk_in   : IN  STD_LOGIC;

    -- LED Panel IO
    clk_out  : OUT STD_LOGIC;
    rgb1     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    rgb2     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    row_addr : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    lat      : OUT STD_LOGIC;
    oe_n     : OUT STD_LOGIC;

    -- Buffer control
    buffer_selection : IN STD_LOGIC;   -- Toggle to switch to other buffer (0 selects buffer 0 for writing)

    -- Buffer writing
    line_address : IN STD_LOGIC_VECTOR(4 DOWNTO 0);         -- 0 to 31
    column_address : IN STD_LOGIC_VECTOR(4 DOWNTO 0);       -- 0 to 31
    w_red : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    w_green : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    w_blue : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    write_enable : IN STD_LOGIC       -- '1' to allow writing to memory
  );

END ledctrl;

ARCHITECTURE bhv OF ledctrl IS

  -- Internal signals
  SIGNAL clk_en : STD_LOGIC;

  -- Essential state machine signals
  TYPE STATE_TYPE IS (INIT, READ_PIXEL_DATA, INCR_COL_ADDR, LATCH, INCR_ROW_ADDR);
  SIGNAL state, next_state : STATE_TYPE;

  -- State machine signals
  SIGNAL col_count, next_col_count : UNSIGNED(PANEL_WIDTH_VECTOR_SIZE-1 DOWNTO 0);
  SIGNAL bpp_count, next_bpp_count : UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
  SIGNAL s_row_addr, next_row_addr : STD_LOGIC_VECTOR(row_addr'range);
  SIGNAL next_rgb1, next_rgb2      : STD_LOGIC_VECTOR(rgb1'range);
  SIGNAL s_oe_n, s_lat, s_clk_out  : STD_LOGIC;

  SIGNAL update_rgb : STD_LOGIC;        -- If '1', then update the RGB outputs
  SIGNAL frame, next_frame : STD_LOGIC; -- If '1', then clocking in pixels at start of a frame

  -- Read and write signal used in combination with switching buffers
  SIGNAL buffer_read_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL upper_buffer_read_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL lower_buffer_read_data : STD_LOGIC_VECTOR(23 DOWNTO 0);

  -- First upper buffer
  SIGNAL upper_buffer_0_read_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL upper_buffer_0_write_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL upper_buffer_0_read_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL upper_buffer_0_write_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL upper_buffer_0_write_enable : STD_LOGIC_VECTOR(0 DOWNTO 0);

  -- Second upper buffer
  SIGNAL upper_buffer_1_read_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL upper_buffer_1_write_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL upper_buffer_1_read_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL upper_buffer_1_write_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL upper_buffer_1_write_enable : STD_LOGIC_VECTOR(0 DOWNTO 0);

  -- First lower buffer
  SIGNAL lower_buffer_0_read_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL lower_buffer_0_write_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL lower_buffer_0_read_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL lower_buffer_0_write_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL lower_buffer_0_write_enable : STD_LOGIC_VECTOR(0 DOWNTO 0);

  -- Second lower buffer
  SIGNAL lower_buffer_1_read_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL lower_buffer_1_write_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL lower_buffer_1_read_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL lower_buffer_1_write_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL lower_buffer_1_write_enable : STD_LOGIC_VECTOR(0 DOWNTO 0);


  SIGNAL write_address : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL write_data : STD_LOGIC_VECTOR(23 DOWNTO 0);

  COMPONENT half_frame_buffer_block_ram
    PORT (
      -- Write signals
      clka : IN STD_LOGIC;
      wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      dina : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
      -- Read signals
      clkb : IN STD_LOGIC;
      addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
      doutb : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
  END COMPONENT;

BEGIN

  ----------------------------------------------------------------------------------------------------------------------
  -- For a 16 x 32 RGB matrix with 24-bit pixel depth (8-bit per R,G & B), 5 MHz clock =~ 30 frames per second
  -- but this rate has a noticable flicker.  So 10 MHz clock =~ 76 fps is better.  div = 3 for 10 MHz
  -- ie. 40 MHz / (div+1) = 10 MHz
  ----------------------------------------------------------------------------------------------------------------------
  U_CLKDIV : ENTITY work.clk_div_dyn
    PORT MAP (
      rst    => rst,
      clk_in => clk_in,
      div    => to_unsigned(CLOCK_DIVIDER, 8),
      clk_en => clk_en);

  top_frame_buffer_0 : half_frame_buffer_block_ram
    PORT MAP (
      -- Write signals
      clka  => clk_in,
      wea   => upper_buffer_0_write_enable,
      addra => upper_buffer_0_write_address,
      dina  => upper_buffer_0_write_data,
      -- Read signals
      clkb  => clk_in,
      addrb => upper_buffer_0_read_address,
      doutb => upper_buffer_0_read_data
    );

  bottom_frame_buffer_0 : half_frame_buffer_block_ram
    PORT MAP (
      -- Write signals
      clka  => clk_in,
      wea   => lower_buffer_0_write_enable,
      addra => lower_buffer_0_write_address,
      dina  => lower_buffer_0_write_data,
      -- Read signals
      clkb  => clk_in,
      addrb => lower_buffer_0_read_address,
      doutb => lower_buffer_0_read_data
    );

  top_frame_buffer_1 : half_frame_buffer_block_ram
    PORT MAP (
      -- Write signals
      clka  => clk_in,
      wea   => upper_buffer_1_write_enable,
      addra => upper_buffer_1_write_address,
      dina  => upper_buffer_1_write_data,
      -- Read signals
      clkb  => clk_in,
      addrb => upper_buffer_1_read_address,
      doutb => upper_buffer_1_read_data
    );

  bottom_frame_buffer_1 : half_frame_buffer_block_ram
    PORT MAP (
      -- Write signals
      clka  => clk_in,
      wea   => lower_buffer_1_write_enable,
      addra => lower_buffer_1_write_address,
      dina  => lower_buffer_1_write_data,
      -- Read signals
      clkb  => clk_in,
      addrb => lower_buffer_1_read_address,
      doutb => lower_buffer_1_read_data
    );

  ----------------------------------------------------------------------------------------------------------------------
  -- Breakout internal signals to the output port
  row_addr <= s_row_addr;

  -- Frame buffer memory contains packed pixels (RGB)
  -- for a total of 24 bits
  -- Addressing is line selection (0 to 15) & (pixel selection)
  buffer_read_address <= s_row_addr & STD_LOGIC_VECTOR(col_count);

  -- Write address and data has to be constructed (we hide layout of buffer)
  write_address <= line_address(3 DOWNTO 0) & column_address;
  write_data <= w_red & w_green & w_blue;
    -- Correct memory for writing is selected based on line_address(4) and buffer_selection

  -----------------------------------------------------------------------------------------------------------------
  ------------------------ BUFFER SELECTION -----------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------
  lower_buffer_0_write_enable(0) <= ((not buffer_selection) AND line_address(4) AND write_enable);
  upper_buffer_0_write_enable(0) <= ((not buffer_selection) AND (not line_address(4)) AND write_enable);

  lower_buffer_1_write_enable(0) <= ((buffer_selection) AND line_address(4) AND write_enable);
  upper_buffer_1_write_enable(0) <= ((buffer_selection) AND (not line_address(4)) AND write_enable);

  lower_buffer_0_write_address <= write_address;
  upper_buffer_0_write_address <= write_address;
  lower_buffer_1_write_address <= write_address;
  upper_buffer_1_write_address <= write_address;

  lower_buffer_0_write_data <= write_data;
  upper_buffer_0_write_data <= write_data;

  lower_buffer_1_write_data <= write_data;
  upper_buffer_1_write_data <= write_data;

  lower_buffer_0_read_address <= buffer_read_address;
  upper_buffer_0_read_address <= buffer_read_address;

  lower_buffer_1_read_address <= buffer_read_address;
  upper_buffer_1_read_address <= buffer_read_address;

  lower_buffer_read_data <= lower_buffer_0_read_data WHEN buffer_selection = '1' ELSE lower_buffer_1_read_data;
  upper_buffer_read_data <= upper_buffer_0_read_data WHEN buffer_selection = '1' ELSE upper_buffer_1_read_data;


  ----------------------------------------------------------------------------------------------------------------------
  -- State register
  PROCESS(rst, clk_in)
  BEGIN
    IF(rst = '1') THEN
      state      <= INIT;
      col_count  <= (OTHERS => '0');
      bpp_count  <= (OTHERS => '1');    -- first state transition incrs bpp_count so start at -1 so first bpp_count = 0
      s_row_addr <= (OTHERS => '1');    -- this inits to 1111 because the row_addr is incr when bpp_count = 255
      frame      <= '0';
      rgb1       <= (OTHERS => '0');
      rgb2       <= (OTHERS => '0');
      oe_n       <= '1';                -- active low, so do not enable LED Matrix output
      lat        <= '0';
      clk_out    <= '0';
    ELSIF(rising_edge(clk_in)) THEN
      IF (clk_en = '1') THEN

        -- Run all f/f clocks at the slower clk_en rate
        state      <= next_state;
        col_count  <= next_col_count;
        bpp_count  <= next_bpp_count;
        s_row_addr <= next_row_addr;
        frame      <= next_frame;

        IF (update_rgb = '1') THEN
          rgb1 <= next_rgb1;
          rgb2 <= next_rgb2;
        END IF;

        -- Use f/fs to eliminate variable delays due to combinatorial logic output.
        -- Also, this allows the RGB data to transition on the falling edge of
        -- clk_out in order to maximum the setup and hold times.
        oe_n    <= s_oe_n;
        lat     <= s_lat;
        clk_out <= s_clk_out;

      END IF;
    END IF;
  END PROCESS;

  -- Next-state logic
  PROCESS(state, col_count, bpp_count, s_row_addr, upper_buffer_read_data, lower_buffer_read_data) IS

    -- Internal breakouts
    VARIABLE upper_r, upper_g, upper_b : UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
    VARIABLE lower_r, lower_g, lower_b : UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
    VARIABLE r1, g1, b1, r2, g2, b2    : STD_LOGIC;

  BEGIN

    -- Pixel data is combination of RGB pixels
    -- Each color is represented by 8 bits
    -- So 3 colors per pixel and 8 bits per color
    -- makes for a total of 24 bits
    -- | R | G | B |
    -- | 23 .... 0 |
    upper_r := unsigned(upper_buffer_read_data(3*PIXEL_DEPTH-1 DOWNTO 2*PIXEL_DEPTH));
    upper_g := unsigned(upper_buffer_read_data(2*PIXEL_DEPTH-1 DOWNTO PIXEL_DEPTH));
    upper_b := unsigned(upper_buffer_read_data(PIXEL_DEPTH-1 DOWNTO 0));
    lower_r := unsigned(lower_buffer_read_data(3*PIXEL_DEPTH-1 DOWNTO 2*PIXEL_DEPTH));
    lower_g := unsigned(lower_buffer_read_data(2*PIXEL_DEPTH-1 DOWNTO PIXEL_DEPTH));
    lower_b := unsigned(lower_buffer_read_data(PIXEL_DEPTH-1 DOWNTO 0));

    r1 := '0'; g1 := '0'; b1 := '0';    -- Defaults
    r2 := '0'; g2 := '0'; b2 := '0';    -- Defaults

    -- Default register next-state assignments
    next_col_count <= col_count;
    next_bpp_count <= bpp_count;
    next_row_addr  <= s_row_addr;

    -- Default signal assignments
    s_clk_out  <= '0';
    s_lat      <= '0';
    s_oe_n     <= '1';    -- this signal is "active low"
    update_rgb <= '0';
    next_frame <= '0';

    -- States
    CASE state IS
      WHEN INIT =>
        -- If PIXEL_DEPTH = 8, there are 255 passes per frame refresh. So to
        -- count to 255 starting from 0, when reach 254, must roll over to 0
        -- on the next count.  The reason using 255 passes instead of 256 is
        -- because 0 = 0% duty cycle and therefore 255 = 100% duty cycle.
        -- For 255 to be 100%, then it must be 255/255 and not 255/256.
        --
        -- However, having said all that, to minimize ghosting, before
        -- starting PWM, make the first pass through the row write all 0's.
        -- So actually count 0 to 255 but 0 means to right all 0's.
        IF(bpp_count >= UNSIGNED(to_signed(-1, PIXEL_DEPTH))) THEN
          next_bpp_count <= (OTHERS => '0');
          next_state     <= INCR_ROW_ADDR;
        ELSE
          next_bpp_count <= bpp_count + 1;
          next_state     <= READ_PIXEL_DATA;
        END IF;

      WHEN INCR_ROW_ADDR =>
        -- display is disabled during row_addr (select lines) update
        IF (s_row_addr = "1111") THEN
          next_frame <= '1';                -- indicate at start of a frame (incrementing row to 0)
        END IF;
        next_row_addr  <= STD_LOGIC_VECTOR(UNSIGNED(s_row_addr) + 1);
        next_state <= READ_PIXEL_DATA;

      WHEN READ_PIXEL_DATA =>
        IF (bpp_count /= 0) THEN
          -- If bpp_count = 0, then shift in all 0's, otherwise, 
          -- Do parallel comparisons against BPP counter to gain multibit color
          IF(upper_r >= bpp_count) THEN r1 := '1'; END IF;
          IF(upper_g >= bpp_count) THEN g1 := '1'; END IF;
          IF(upper_b >= bpp_count) THEN b1 := '1'; END IF;
          IF(lower_r >= bpp_count) THEN r2 := '1'; END IF;
          IF(lower_g >= bpp_count) THEN g2 := '1'; END IF;
          IF(lower_b >= bpp_count) THEN b2 := '1'; END IF;
        END IF;
        update_rgb     <= '1';              -- clock out these new RGB values

        IF(col_count = PANEL_WIDTH-1) THEN      -- check if at the rightmost side of the image
          s_oe_n     <= '1';                -- disable display before latch in new LED anodes
          next_state <= LATCH;
        ELSE
          s_oe_n     <= '0';                -- enable display while simply updating the shift register
          next_state <= INCR_COL_ADDR;
        END IF;
        
      WHEN INCR_COL_ADDR =>
        s_clk_out     <= '1';               -- pulse the output clock
        s_oe_n        <= '0';               -- enable display
        next_col_count <= col_count + 1;    -- update/increment column counter
        next_state    <= READ_PIXEL_DATA;
        
      WHEN LATCH =>
        -- display is disabled during latching
        s_lat      <= '1';                  -- latch the data
        next_col_count <= (OTHERS => '0');  -- reset the column counter
        next_state <= INIT;                 -- restart state machine
        
      WHEN OTHERS => NULL;
    END CASE;

    next_rgb1 <= r1 & g1 & b1;
    next_rgb2 <= r2 & g2 & b2;

  END PROCESS;

END bhv;
