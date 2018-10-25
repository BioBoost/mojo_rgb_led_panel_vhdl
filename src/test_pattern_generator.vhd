LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;
USE work.rgbmatrix.ALL;

ENTITY test_pattern_generator IS
  PORT(
    line_address : IN STD_LOGIC_VECTOR(3 DOWNTO 0);         -- 0 to 15
    column_address : IN STD_LOGIC_VECTOR(4 DOWNTO 0);       -- 0 to 31

    -- Outputs
    upper_r : OUT UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
    upper_g : OUT UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
    upper_b : OUT UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
    lower_r : OUT UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
    lower_g : OUT UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0);
    lower_b : OUT UNSIGNED(PIXEL_DEPTH-1 DOWNTO 0)
  );
END test_pattern_generator;

ARCHITECTURE all_black OF test_pattern_generator IS

BEGIN

  upper_r <= to_unsigned(0, PIXEL_DEPTH);
  lower_r <= to_unsigned(0, PIXEL_DEPTH);

  upper_g <= to_unsigned(0, PIXEL_DEPTH);
  lower_g <= to_unsigned(0, PIXEL_DEPTH);

  upper_b <= to_unsigned(0, PIXEL_DEPTH);
  lower_b <= to_unsigned(0, PIXEL_DEPTH);

END all_black;


ARCHITECTURE colored_lines OF test_pattern_generator IS

BEGIN

  upper_r <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "00" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);
  lower_r <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "00" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_g <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "01" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);
  lower_g <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "01" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_b <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "10" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);
  lower_b <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "10" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);

END colored_lines;

ARCHITECTURE boxed OF test_pattern_generator IS

BEGIN
  upper_r <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR line_address = "1111" OR column_address = "00000" OR column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);

  lower_r <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR line_address = "1111" OR column_address = "00000" OR column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_g <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR line_address = "1111" OR column_address = "00000" OR column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);
  
  lower_g <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR line_address = "1111" OR column_address = "00000" OR column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_b <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR line_address = "1111" OR column_address = "00000" OR column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);
  
  lower_b <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR line_address = "1111" OR column_address = "00000" OR column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);

END boxed;


ARCHITECTURE points OF test_pattern_generator IS
BEGIN
  -- Generate red box
  upper_r <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR
    line_address = "1111" OR
    column_address = "00000" OR
    column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);

  lower_r <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    line_address = "0000" OR
    line_address = "1111" OR
    column_address = "00000" OR
    column_address = "11111"
    ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_g <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    NOT(line_address = "0000" OR
    line_address = "1111" OR
    column_address = "00000" OR
    column_address = "11111") AND
    line_address = column_address(3 DOWNTO 0)
    ELSE to_unsigned(0, PIXEL_DEPTH);
  
  lower_g <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    NOT(line_address = "0000" OR
    line_address = "1111" OR
    column_address = "00000" OR
    column_address = "11111") AND
    line_address = column_address(3 DOWNTO 0)
    ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_b <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    NOT(line_address = "0000" OR
    line_address = "1111" OR
    column_address = "00000" OR
    column_address = "11111") AND
    (to_integer(unsigned(line_address)) + to_integer(unsigned(column_address(4 DOWNTO 0))) = 31)
    ELSE to_unsigned(0, PIXEL_DEPTH);

  lower_b <= to_unsigned(50, PIXEL_DEPTH) WHEN 
    NOT(line_address = "0000" OR
    line_address = "1111" OR
    column_address = "00000" OR
    column_address = "11111") AND
    (to_integer(unsigned("1" & line_address)) + to_integer(unsigned(column_address(4 DOWNTO 0))) = 31)
    ELSE to_unsigned(0, PIXEL_DEPTH);

END points;
