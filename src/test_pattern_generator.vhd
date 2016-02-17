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

ARCHITECTURE colored_lines OF test_pattern_generator IS

BEGIN

  upper_r <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "00" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);
  lower_r <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "00" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_g <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "01" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);
  lower_g <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "01" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);

  upper_b <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "10" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);
  lower_b <= to_unsigned(255, PIXEL_DEPTH) WHEN line_address(1 DOWNTO 0) = "10" OR line_address(1 DOWNTO 0) = "11" ELSE to_unsigned(0, PIXEL_DEPTH);

END colored_lines;
