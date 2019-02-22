LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL;

ENTITY command_receiver IS
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
    buffer_selection : OUT STD_LOGIC;   -- Toggle to switch to other buffer (0 selects buffer 0 for writing)

    -- Buffer writing
    line_address : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);         -- 0 to 31
    column_address : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);       -- 0 to 31
    w_red : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    w_green : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    w_blue : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    write_enable : OUT STD_LOGIC ;       -- '1' to allow writing to memory
    boot_mode : OUT STD_LOGIC := '0'     -- When in bootmode test patterns are displayed
  );
END command_receiver;

ARCHITECTURE logic OF command_receiver IS

  -- Our simple SPI slave
  COMPONENT simple_spi_slave IS
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
  END COMPONENT;

  -- We do gamma correction here instead of in led panel.
  -- This because otherwise we are wasting a lot of hardware resources
  -- Also dont think gamma correction is task of a panel
  COMPONENT GammaCorrection IS
    PORT (
      input   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      output  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
  END COMPONENT;

  SIGNAL gamma_correction_input : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL gamma_correction_output : STD_LOGIC_VECTOR(7 DOWNTO 0);

  SIGNAL spi_request_data : STD_LOGIC;
  SIGNAL spi_busy : STD_LOGIC;
  SIGNAL spi_data_ready : STD_LOGIC;
  SIGNAL spi_rx_data : STD_LOGIC_VECTOR(7 DOWNTO 0);    -- Intermediate

  -- Information received for setting RGB data
  SIGNAL r_command : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL next_r_command : STD_LOGIC_VECTOR(7 DOWNTO 0);

  SIGNAL i_panel_id : UNSIGNED(7 DOWNTO 0);
  SIGNAL next_panel_id : UNSIGNED(7 DOWNTO 0);

  SIGNAL s_red_value : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_green_value : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_blue_value : STD_LOGIC_VECTOR(7 DOWNTO 0);

  SIGNAL next_red_value : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL next_green_value : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL next_blue_value : STD_LOGIC_VECTOR(7 DOWNTO 0);

  SIGNAL pixel_counter : UNSIGNED(4 DOWNTO 0);
  SIGNAL next_pixel_counter : UNSIGNED(4 DOWNTO 0);

  SIGNAL s_buffer_selection : STD_LOGIC;
  SIGNAL next_buffer_selection : STD_LOGIC;

  SIGNAL i_line_address : UNSIGNED(4 DOWNTO 0);
  SIGNAL next_line_address : UNSIGNED(4 DOWNTO 0);

  SIGNAL s_boot_mode : STD_LOGIC;
  SIGNAL next_boot_mode : STD_LOGIC;

  -- Frame Mode:
  --    If '1' then we receive frame by frame
  --    If '0' we receive line by line
  SIGNAL s_frame_mode : STD_LOGIC;
  SIGNAL next_frame_mode : STD_LOGIC;

  -- State machine
  TYPE STATE_TYPE IS (INIT,
                      EXPECT_CMD, RECEIVE_CMD,
                      EXPECT_PANEL_ID, RECEIVE_PANEL_ID,
                      EXPECT_LINE_ADDR, RECEIVE_LINE_ADDR,
                      EXPECT_R_DATA, RECEIVE_R_DATA,
                      EXPECT_G_DATA, RECEIVE_G_DATA,
                      EXPECT_B_DATA, RECEIVE_B_DATA,
                      WRITE_RGB_TO_MEMORY,
                      PREPARE_WRITE_RGB_TO_MEMORY,
                      FINISH_WRITE_RGB_TO_MEMORY
                      );
  SIGNAL current_state, next_state : STATE_TYPE;

BEGIN

  -- Map internal signals to interface signals
  buffer_selection <= s_buffer_selection;
  line_address <= STD_LOGIC_VECTOR(i_line_address);
  column_address <= STD_LOGIC_VECTOR(pixel_counter);
  panel_id <= STD_LOGIC_VECTOR(i_panel_id);
  w_red <= s_red_value;
  w_green <= s_green_value;
  w_blue <= s_blue_value;
  boot_mode <= s_boot_mode;
  
  spi_slave_interface : ENTITY work.simple_spi_slave
    PORT MAP(
      -- FPGA signal
      fpga_clock   => clk,
      reset_n      => reset_n,

      -- SPI signals
      sclk         => spi_slave_sck,
      ss_n         => spi_slave_n_ss,
      mosi         => spi_slave_mosi,
      miso         => open,
      -- Request signals
      rx_req       => spi_request_data,

      -- Status bits
      rrdy         => spi_data_ready,
      busy         => spi_busy,

      -- Data paths
      rx_data      => spi_rx_data
    );

  gamma_correction : ENTITY work.GammaCorrection
  PORT MAP (
    input   => gamma_correction_input,
    output  => gamma_correction_output
  );

  -- Sequential FSM
  -- Nothing more than setting the next state on rithm of clock
  seq: PROCESS(reset_n, clk) IS
  BEGIN
    IF (reset_n = '0') THEN
      current_state <= INIT;
      pixel_counter <= (OTHERS => '0');
    ELSIF (rising_edge(clk)) THEN
      current_state <= next_state;
      pixel_counter <= next_pixel_counter;
    END IF;
  END PROCESS seq;

  state <= spi_rx_data;

  -- This process sets some outputs that need to keep their state retained through the
  -- state machine process
  sync_outputs: PROCESS(reset_n, clk) IS
  BEGIN
    IF (reset_n = '0') THEN
      s_buffer_selection <= '0';
      i_line_address <= (OTHERS => '0');
      r_command <= (OTHERS => '0');
      i_panel_id <= (OTHERS => '0');
      s_red_value <= (OTHERS => '0');
      s_green_value <= (OTHERS => '0');
      s_blue_value <= (OTHERS => '0');
      s_boot_mode <= '1';     -- Start in boot-mode
      s_frame_mode <= '0';    -- Start in line by line mode

    ELSIF (rising_edge(clk)) THEN
      s_buffer_selection <= next_buffer_selection;
      i_line_address <= next_line_address;
      r_command <= next_r_command;
      i_panel_id <= next_panel_id;
      s_red_value <= next_red_value;
      s_green_value <= next_green_value;
      s_blue_value <= next_blue_value;
      s_boot_mode <= next_boot_mode;
      s_frame_mode <= next_frame_mode;

    END IF;
  END PROCESS;

  -- Combinatorial logic for determining next state
  -- We also determine the output here
  com_ns: PROCESS(current_state, spi_busy, spi_data_ready, spi_rx_data, i_line_address, r_command, i_panel_id,
    s_red_value, s_green_value, s_blue_value, s_buffer_selection, pixel_counter, s_boot_mode,
    s_frame_mode, gamma_correction_output) IS
  BEGIN
    -- Default assingments
    next_buffer_selection <= s_buffer_selection;
    next_line_address <= i_line_address;
    next_r_command <= r_command;
    next_panel_id <= i_panel_id;
    next_red_value <= s_red_value;
    next_green_value <= s_green_value;
    next_blue_value <= s_blue_value;
    next_pixel_counter <= pixel_counter;
    write_enable <= '0';
    spi_request_data <= '0';
    next_boot_mode <= s_boot_mode;
    next_frame_mode <= s_frame_mode;

    CASE current_state IS
      WHEN INIT =>
        next_state <= EXPECT_CMD;
        next_buffer_selection <= '0';
        next_boot_mode <= '1';
        next_frame_mode <= '0';

      WHEN EXPECT_CMD =>
        -- Clear all previous data
        next_line_address <= (OTHERS => '0');
        next_panel_id <= (OTHERS => '0');
        next_r_command <= (OTHERS => '0');
        next_red_value <= (OTHERS => '0');
        next_green_value <= (OTHERS => '0');
        next_blue_value <= (OTHERS => '0');
        next_pixel_counter <= (OTHERS => '0');
        next_frame_mode <= '0';

        IF(spi_busy = '0' AND spi_data_ready = '1') THEN  --new message from spi
          spi_request_data <= '1';                        --request message from spi
          next_state <= RECEIVE_CMD;                      --retrieve message from spi
          next_boot_mode <= '0';                          -- First command received will stop boot mode
        ELSE                                              --no new message from spi
          spi_request_data <= '0';
          next_state <= EXPECT_CMD;                       --wait for new message from spi
        END IF;

      WHEN RECEIVE_CMD =>
        next_r_command <= spi_rx_data;       --retrieve message from spi
        spi_request_data <= '0';        --stop requesting
        next_frame_mode <= '0';

        CASE spi_rx_data IS
          WHEN x"01" =>
            -- RGB DATA
            next_state <= EXPECT_PANEL_ID;

          -- When this command is received we expect a full frame of data
          -- that follows (just block of RGB data)
          WHEN x"03" =>
             next_frame_mode <= '1';
             next_state <= EXPECT_R_DATA;

          WHEN x"08" =>
            -- Switch buffers
            next_buffer_selection <= not s_buffer_selection;
            next_state <= EXPECT_CMD;

          WHEN x"20" =>
            -- Switch buffers
            next_buffer_selection <= not s_buffer_selection;
            next_state <= EXPECT_CMD;

          -- Command not supported (yet)
          WHEN OTHERS => next_state <= EXPECT_CMD;
        END CASE;

      WHEN EXPECT_PANEL_ID =>
        IF(spi_busy = '0' AND spi_data_ready = '1') THEN  --new message from spi
          spi_request_data <= '1';                        --request message from spi
          next_state <= RECEIVE_PANEL_ID;                 --retrieve message from spi
        ELSE                                              --no new message from spi
          spi_request_data <= '0';
          next_state <= EXPECT_PANEL_ID;                  --wait for new message from spi
        END IF;

      WHEN RECEIVE_PANEL_ID =>
        next_panel_id <= unsigned(spi_rx_data);       --retrieve message from spi
        spi_request_data <= '0';       --stop requesting
        next_state <= EXPECT_LINE_ADDR;

      WHEN EXPECT_LINE_ADDR =>
        IF(spi_busy = '0' AND spi_data_ready = '1') THEN  --new message from spi
          spi_request_data <= '1';                        --request message from spi
          next_state <= RECEIVE_LINE_ADDR;                 --retrieve message from spi
        ELSE                                              --no new message from spi
          spi_request_data <= '0';
          next_state <= EXPECT_LINE_ADDR;                  --wait for new message from spi
        END IF;

      WHEN RECEIVE_LINE_ADDR =>
        next_line_address <= unsigned(spi_rx_data(4 downto 0));       --retrieve message from spi
        spi_request_data <= '0';           --stop requesting
        next_state <= EXPECT_R_DATA;
        next_pixel_counter <= (OTHERS => '0');

      WHEN EXPECT_R_DATA =>
        IF(spi_busy = '0' AND spi_data_ready = '1') THEN  --new message from spi
          spi_request_data <= '1';                        --request message from spi
          next_state <= RECEIVE_R_DATA;                 --retrieve message from spi
        ELSE                                              --no new message from spi
          spi_request_data <= '0';
          next_state <= EXPECT_R_DATA;                  --wait for new message from spi
        END IF;

      WHEN RECEIVE_R_DATA =>
        gamma_correction_input <= spi_rx_data;       --retrieve message from spi
        next_red_value <= gamma_correction_output;   --gamma correct the value

        spi_request_data <= '0';           --stop requesting
        next_state <= EXPECT_G_DATA;

      WHEN EXPECT_G_DATA =>
        IF(spi_busy = '0' AND spi_data_ready = '1') THEN  --new message from spi
          spi_request_data <= '1';                        --request message from spi
          next_state <= RECEIVE_G_DATA;                 --retrieve message from spi
        ELSE                                              --no new message from spi
          spi_request_data <= '0';
          next_state <= EXPECT_G_DATA;                  --wait for new message from spi
        END IF;

      WHEN RECEIVE_G_DATA =>
        gamma_correction_input <= spi_rx_data;       --retrieve message from spi
        next_green_value <= gamma_correction_output;   --gamma correct the value
        spi_request_data <= '0';           --stop requesting
        next_state <= EXPECT_B_DATA;

      WHEN EXPECT_B_DATA =>
        IF(spi_busy = '0' AND spi_data_ready = '1') THEN  --new message from spi
          spi_request_data <= '1';                        --request message from spi
          next_state <= RECEIVE_B_DATA;                 --retrieve message from spi
        ELSE                                              --no new message from spi
          spi_request_data <= '0';
          next_state <= EXPECT_B_DATA;                  --wait for new message from spi
        END IF;

      WHEN RECEIVE_B_DATA =>
        gamma_correction_input <= spi_rx_data;       --retrieve message from spi
        next_blue_value <= gamma_correction_output;   --gamma correct the value
        spi_request_data <= '0';           --stop requesting
        next_state <= PREPARE_WRITE_RGB_TO_MEMORY;
      
      WHEN PREPARE_WRITE_RGB_TO_MEMORY =>
        -- Give memory time to clock in the data
        next_state <= WRITE_RGB_TO_MEMORY;
        write_enable <= '1';

      WHEN WRITE_RGB_TO_MEMORY =>
        -- Give memory time to clock in the data
        next_state <= FINISH_WRITE_RGB_TO_MEMORY;
        write_enable <= '1';

      WHEN FINISH_WRITE_RGB_TO_MEMORY =>
        -- Give memory time to clock in the data
        write_enable <= '1';

        IF (s_frame_mode = '0') THEN
          IF (pixel_counter = 31) THEN
            next_pixel_counter <= (OTHERS => '0');
            next_state <= EXPECT_CMD;
          ELSE
            next_pixel_counter <= pixel_counter + 1;
            next_state <= EXPECT_R_DATA;
          END IF;
        ELSE
          next_state <= EXPECT_R_DATA;

          -- Increment pixel counter
          next_pixel_counter <= pixel_counter + 1;

          IF (pixel_counter = 31) THEN
            next_pixel_counter <= (OTHERS => '0');

            next_panel_id <= i_panel_id + 1;          
            IF (i_panel_id = 2) THEN
              next_panel_id <= (OTHERS => '0');

              next_line_address <= i_line_address + 1;
              IF (i_line_address = 31) THEN
                -- switch to bottom
                next_line_address <= (OTHERS => '0');
                next_panel_id <= to_unsigned(3, next_panel_id'length);
              END IF;
            ELSIF (i_panel_id = 5) THEN
              next_panel_id <= to_unsigned(3, next_panel_id'length);

              next_line_address <= i_line_address + 1;
              IF (i_line_address = 31) THEN
                -- done
                next_line_address <= (OTHERS => '0');
                next_panel_id <= (OTHERS => '0');
                next_state <= EXPECT_CMD;   -- Finished the frame
              END IF;
            END IF;
          END IF;

        END IF;
      
      WHEN OTHERS => next_state <= INIT;

    END CASE;
  END PROCESS com_ns;


END logic;