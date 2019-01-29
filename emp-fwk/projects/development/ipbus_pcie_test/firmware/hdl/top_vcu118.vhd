-- Top-level design for VCU115 framework firmware


library IEEE;
use IEEE.std_logic_1164.all;

use work.ipbus.all;
use work.pcie_decl.all;

library UNISIM;
use UNISIM.VComponents.all;

entity top is
  port(
        -- PCIe clock and reset
      pcie_sys_clk_p : in std_logic;
      pcie_sys_clk_n : in std_logic;
      pcie_sys_rst_n : in std_logic;  -- active low reset from the pcie edge connector
      -- PCIe lanes
      pcie_rxp       : in std_logic_vector(C_PCIE_LANES-1 downto 0);
      pcie_rxn       : in std_logic_vector(C_PCIE_LANES-1 downto 0);
      pcie_txp       : out std_logic_vector(C_PCIE_LANES-1 downto 0);
      pcie_txn       : out std_logic_vector(C_PCIE_LANES-1 downto 0)
  );

end top;

architecture rtl of top is

  signal ipb_clk, ipb_rst : std_logic;
  
  signal ipb_in_example: ipb_wbus;
  signal ipb_out_example: ipb_rbus;
  

begin

-- Infrastructure

  infra: entity work.ipbus_pcie_test_usp_infra
    port map(
      pcie_sys_clk_p => pcie_sys_clk_p,
      pcie_sys_clk_n => pcie_sys_clk_n,
      pcie_sys_rst_n => pcie_sys_rst_n,
      pcie_rxp       => pcie_rxp,
      pcie_rxn       => pcie_rxn,
      pcie_txp       => pcie_txp,
      pcie_txn       => pcie_txn,
      ipb_clk        => ipb_clk,
      ipb_rst        => ipb_rst,
      ipb_in         => ipb_out_example,
      ipb_out        => ipb_in_example
      );
      
-- ipbus slaves live in the entity below, and can expose top-level ports.
-- The ipbus fabric is instantiated within.

  slaves: entity work.ipbus_example
    port map(
      ipb_clk => ipb_clk,
      ipb_rst => ipb_rst,
      ipb_in => ipb_in_example,
      ipb_out => ipb_out_example
      --nuke: unused output signal
      --soft_rst: unused output signal
      --userled: unused output signal
      );


end rtl;
