library IEEE;
use IEEE.STD_LOGIC_1164.all;

package tb_decl is

--! Useful constants
  constant TB_INITSETTLECYCLES   : integer := 0;
  constant TB_STARTFRAME         : integer := 0;
  constant TB_NUMFRAMES          : integer := 1024;
  constant TB_PLAYBACKBUFFERSIZE : integer := 1024;
  constant TB_STRIPHEADER        : boolean := false;
  constant TB_INSERTHEADER       : boolean := false;

end package;  -- tb_decl 
