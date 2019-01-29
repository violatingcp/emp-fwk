-- pcie_decl
--
-- Defines constants for the PCIe DMA block
--
-- Kristian Harder, Feb 2017

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;

package pcie_decl is

  -- number of PCIe lanes that the core was configured for.
  -- note: changing this here will not change the core configuration!
  constant C_PCIE_LANES : integer := 1;
  -- axi interface width
  constant C_AXI_DATA_WIDTH  : integer := 64;
end pcie_decl;
