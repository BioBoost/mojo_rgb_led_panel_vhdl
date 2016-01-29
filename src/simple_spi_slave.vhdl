LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

ENTITY simple_spi_slave IS
  PORT(
    fpga_clock   : IN     STD_LOGIC;  -- clock of FPGA
    sclk         : IN     STD_LOGIC;  --spi clk from master
    reset_n      : IN     STD_LOGIC;  --active low reset
    ss_n         : IN     STD_LOGIC;  --active low slave select
    mosi         : IN     STD_LOGIC;  --master out, slave in
    --miso         : OUT    STD_LOGIC := 'Z'); --master in, slave out
    
    -- Status bits
    r_rdy        : OUT    STD_LOGIC;  -- receive ready bit
    -- busy         : OUT    STD_LOGIC;  -- busy signal to logic ('1' during transaction)
    -- Data paths
    rx_data      : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0)  --receive register output to logic
  );
END simple_spi_slave;

ARCHITECTURE logic OF simple_spi_slave IS
  SIGNAL sync_clk : STD_LOGIC;
  SIGNAL data_reg : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL bit_count : UNSIGNED (7 downto 0);   -- How large ??
  SIGNAL next_bit_count : UNSIGNED (7 downto 0);   -- How large ??

BEGIN
  -- busy <= NOT ss_n;  --high during transactions

  -- Other clock domain so we sample clock
  PROCESS(fpga_clock, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      sync_clk <= '0';
    ELSIF(rising_edge(fpga_clock)) THEN
      sync_clk <= sclk;
    END IF;
  END PROCESS;

  -- Data receival
  PROCESS(sync_clk, reset_n, ss_n, mosi)
  BEGIN
    IF (reset_n = '0') THEN
      data_reg <= (OTHERS => '0');
      bit_count <= (OTHERS => '0');
    ELSIF(rising_edge(sync_clk)) THEN
      IF (ss_n = '0') THEN    -- Only take in data when select is low
        data_reg <= mosi & data_reg(7 DOWNTO 1);
        bit_count <= next_bit_count;
      ELSE -- reset data and count
        data_reg <= (OTHERS => '0');
        bit_count <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  -- Data output
  PROCESS(fpga_clock, reset_n, bit_count, data_reg)
  BEGIN
    IF (reset_n = '0') THEN
      rx_data <= (OTHERS => '0');
    ELSIF(rising_edge(fpga_clock)) THEN
      IF (bit_count = 8) THEN
        rx_data <= data_reg;
        r_rdy <= '1';
      ELSE
        rx_data <= data_reg;
        r_rdy <= '0';
      END IF;
    END IF;
  END PROCESS;

  -- Count
  PROCESS(reset_n, bit_count)
  BEGIN
    IF (reset_n = '0') THEN
      next_bit_count <= (OTHERS => '0');
    ELSE
      next_bit_count <= bit_count + 1;
    END IF;
  END PROCESS;

END logic;
