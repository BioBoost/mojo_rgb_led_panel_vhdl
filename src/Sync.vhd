-------------------------------------------------------------------------------
-- Title      : Sync
-- Project    : 
-------------------------------------------------------------------------------
-- File       : Sync.vhd
-- Author     : Stephen Goadhouse  <sgoadhouse@virginia.edu>
-- Company    : 
-- Created    : 2012-01-30
-- Last update: 2012-12-14
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Sync input signal to the clk
-------------------------------------------------------------------------------
-- Copyright (c) 2012 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012-01-30  1.0      SDG     Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Sync IS
  PORT(
    clk    : IN  STD_LOGIC;
    sync_i : IN  STD_LOGIC;
    sync_o : OUT STD_LOGIC
    );
END Sync;

ARCHITECTURE rtl OF Sync IS

  
  SIGNAL sync_m : STD_LOGIC;

  -- Use the KEEP attribute on sync_m in an attempt to prevent XST & MAP from
  -- using function RAM as a shift register in order to implement this
  -- synchronation circuit. Although use of a shift register is efficient use
  -- of FPGA resources, in the case of synchronizing between clock domains, it
  -- may have a detrimental side-effect. Serious metastability issues have
  -- been detected through ChipScope where it takes 50-100 clocks to resolve
  -- the metastability. It is possible that the use of shift registers may be
  -- causing the issue.  There is also evidence found online that indicates
  -- that the shift registers may be to blame. So eliminate them to create the
  -- best possible defense against metastability.
  ATTRIBUTE keep           : STRING;
  ATTRIBUTE keep OF sync_m : SIGNAL IS "TRUE";

BEGIN

  -- purpose: uses two flip/flops to synchronize the input to clk
  -- shielding any potential metastability from sync_o (sync_m gets it).
  sync_proc : PROCESS (clk) IS
  BEGIN  -- PROCESS sync_proc
    IF rising_edge(clk) THEN            -- rising clock edge
      sync_m <= sync_i;
      sync_o <= sync_m;
    END IF;
  END PROCESS sync_proc;

END rtl;
