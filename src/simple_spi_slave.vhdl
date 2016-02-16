LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

ENTITY simple_spi_slave IS
  GENERIC(
    cpol    : STD_LOGIC := '0';  --spi clock polarity mode
    cpha    : STD_LOGIC := '0';  --spi clock phase mode
    d_width : INTEGER := 8);     --data width in bits
  PORT(
    -- FPGA signal
    fpga_clock   : IN     STD_LOGIC;          --clock of FPGA
    reset_n      : IN     STD_LOGIC;          --active low reset

    -- SPI signals
    sclk         : IN     STD_LOGIC;          --spi clk from master
    ss_n         : IN     STD_LOGIC;  --active low slave select
    mosi         : IN     STD_LOGIC;  --master out, slave in
    miso         : OUT    STD_LOGIC := 'Z'; --master in, slave out

    -- Request signals
    rx_req       : IN     STD_LOGIC;  --'1' while busy = '0' moves data to the rx_data output

    -- Status bits
    rrdy         : OUT    STD_LOGIC := '0';  --receive ready bit
    busy         : OUT    STD_LOGIC := '0';  --busy signal to logic ('1' during transaction)

    -- Data paths
    rx_data      : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0')  --receive register output to logic
  );
END simple_spi_slave;

ARCHITECTURE logic OF simple_spi_slave IS
  SIGNAL sync_clk : STD_LOGIC;
  SIGNAL data_reg : STD_LOGIC_VECTOR (7 downto 0);
  SIGNAL bits_received : UNSIGNED (7 downto 0);   -- How large ??
  SIGNAL next_bits_received : UNSIGNED (7 downto 0);   -- How large ??

  SIGNAL data_buffer : STD_LOGIC_VECTOR (7 downto 0);   -- Keeps output data stable while receiving

  TYPE READY_STATE IS (WAITING, READY, DONE);
  SIGNAL current_rrdy_state, next_rrdy_state : READY_STATE;

BEGIN
  -- Other clock domain so we sample clock
  PROCESS(fpga_clock, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      sync_clk <= '0';
    ELSIF(rising_edge(fpga_clock)) THEN
      sync_clk <= sclk;
    END IF;
  END PROCESS;

  -- Our SPI is never too busy :)
  busy <= '0';

  -- Data receival
  PROCESS(sync_clk, reset_n, ss_n, mosi, next_bits_received)
  BEGIN
    IF (reset_n = '0') THEN
      data_reg <= (OTHERS => '0');
      bits_received <= (OTHERS => '0');
    ELSIF(rising_edge(sync_clk)) THEN
      IF (ss_n = '0') THEN    -- Only take in data when select is low
        --data_reg <= mosi & data_reg(7 DOWNTO 1);    -- LSB FIRST
        data_reg <= data_reg(6 DOWNTO 0) & mosi;
        bits_received <= next_bits_received;
      ELSE -- reset data and count
        data_reg <= (OTHERS => '0');
        bits_received <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  -- Following two processes set the ready bit based on FSM
  -- rrdy should be disabled once the upper layer requests the data
  -- and it should stay low until next byte is ready
  seq: PROCESS(reset_n, fpga_clock) IS
  BEGIN
    IF (reset_n = '0') THEN
      current_rrdy_state <= WAITING;
    ELSIF (rising_edge(fpga_clock)) THEN
      current_rrdy_state <= next_rrdy_state;
    END IF;
  END PROCESS seq;

  com_ns: PROCESS(current_rrdy_state, bits_received, rx_req) IS
  BEGIN
    CASE current_rrdy_state IS

      WHEN WAITING =>
        rrdy <= '0';
        IF (bits_received = 8) THEN
          next_rrdy_state <= READY;
        ELSE
          next_rrdy_state <= WAITING;
        END IF;

      WHEN READY =>
        IF (bits_received = 8) THEN
          rrdy <= '1';
          IF (rx_req = '1') THEN
            next_rrdy_state <= DONE;
          ELSE
            next_rrdy_state <= READY;
          END IF;
        ELSE
          rrdy <= '0';
          next_rrdy_state <= WAITING;
        END IF;

      WHEN DONE =>
        rrdy <= '0';
        IF (bits_received /= 8) THEN
          next_rrdy_state <= WAITING;
        ELSE
          next_rrdy_state <= DONE;
        END IF;

      WHEN OTHERS => next_rrdy_state <= WAITING;

    END CASE;
  END PROCESS com_ns;     

  -- Buffer data to it stays stable while receiving the next data byte
  -- Note that data will not be outputted as long as read request has not been issued
  rx_data <= data_buffer;

  -- Data output
  PROCESS(reset_n, fpga_clock)
  BEGIN
    IF (reset_n = '0') THEN
      data_buffer <= (OTHERS => '0');
    ELSIF(rising_edge(fpga_clock)) THEN
      IF (rx_req = '1') THEN
        data_buffer <= data_reg;
      ELSE
        data_buffer <= data_buffer;
      END IF;
    END IF;
  END PROCESS;

  -- Count
  PROCESS(reset_n, bits_received)
  BEGIN
    IF (reset_n = '0') THEN
      next_bits_received <= (OTHERS => '0');
    ELSE
      IF (bits_received = 8) THEN
        next_bits_received <= TO_UNSIGNED(1, 8);
      ELSE
        next_bits_received <= bits_received + 1;
      END IF;
    END IF;
  END PROCESS;

END logic;
