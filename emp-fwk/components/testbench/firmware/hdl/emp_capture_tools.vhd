
--! Using the IEEE Library
library IEEE;

--! Writing to and from files
use IEEE.STD_LOGIC_TEXTIO.all;
--! Writing to and from files
use STD.TEXTIO.all;

--! Using STD_LOGIC
use IEEE.STD_LOGIC_1164.all;
--! Using NUMERIC TYPES
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;                 -- for UNIFORM , TRUNC functions

library extras;
use extras.strings.all;
use extras.strings_unbounded.all;
use extras.strings_maps.all;
use extras.strings_maps_constants.all;


--! Using the "emp_data" data-types
use work.emp_data_types.all;

--! Using the emp helper functions and constants
use work.emp_testbench_helpers.all;

--! Use emp device declaration
use work.emp_device_decl.all;

--! Reading an writing emp data to file
use work.emp_data_textio.all;


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
package emp_capture_tools is

  type DataPipe_t is array(natural range <>) of ldata(N_LINKS - 1 downto 0);  -- ( timeslice )( link number )
  --type LinkIdArray_t is array(N_LINKS - 1 downto 0) of integer range -1 to N_LINKS - 1;  -- (-1 : not present)

  constant kIdleWord  : lword                       := (X"5555555555bcbcbc", '0', '0', '1');
  constant kEmptyData : ldata(N_LINKS - 1 downto 0) := (others => kIdleWord);

  type CurrentReadState_t is(Uninitialized, Payload, Flushing, Finished);

  -- --------------------------------------------------------------------------
  procedure SourceEMPDataFile(aFileName        : in    string;
                              aDataPipe        : inout DataPipe_t;
                              aNumFramesInPipe : inout natural;
                              aDebugMessages   : in    boolean := false
                              );


  -- --------------------------------------------------------------------------
  procedure DataStimulus(
      variable aClkCount        : in  integer;
      variable aDataPipe        : in  DataPipe_t;
      variable aNumFramesInPipe : in  natural;
      variable aPlaybackLength  : in  natural := 0;
      variable aPlaybackOffset  : in  natural := 0;
      variable aPlaybackLoop    : in  boolean := false;
      variable aStripHeader     : in  boolean := false;
      aDebugMessages            : in  boolean := false;
      -- -----------------------------------------------------
      signal aPayloadD          : out ldata(N_LINKS-1 downto 0)
    );

end package emp_capture_tools;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------



---- -------------------------------------------------------------------------------------------------------------------------------------------------------------
package body emp_capture_tools is

-- ----------------------------------------------------------
  procedure SourceEMPDataFile(aFileName        : in    string;
                              aDataPipe        : inout DataPipe_t;
                              aNumFramesInPipe : inout natural;
                              aDebugMessages   : in    boolean := false
                              ) is
    variable L, DEBUG         : line;
    file InFile               : text;
    variable CurrentReadState : CurrentReadState_t := Uninitialized;
    variable lCounter, lFrame : integer            := 0;
    variable lNCols           : natural;
    variable lLinkIds         : LinkIdArray_t      := (others => -1);

  begin
-- -----------------------------------------------------------------------------------------------------

-- Open File
    file_open(InFile, aFileName, read_mode);

-- Debug
    if aDebugMessages then
      WRITE(DEBUG, string' ("UNINITIALIZED : "));
      WRITE(DEBUG, lCounter);
      WRITELINE(OUTPUT, DEBUG);
    end if;
-- Strip File Headers
    for i in 0 to 1 loop
      READLINE(InFile, L);

      -- Debug
      if aDebugMessages then
        WRITE(DEBUG, string' ("FILE HEADER ("));
        WRITE(DEBUG, i);
        WRITE(DEBUG, string' (") : "));
        WRITE(DEBUG, L.all);
        WRITELINE(OUTPUT, DEBUG);
      end if;
    end loop;

    READLINE(InFile, L);
    READLINKIDS(L, lLinkIds, lNCols);

    if aDebugMessages then
      WRITE(DEBUG, string' ("LINK IDs/Columns : "));
      for i in lLinkIds 'range loop
        WRITE(DEBUG, i);
        WRITE(DEBUG, string'(":="));
        WRITE(DEBUG, lLinkIds (i));
        WRITE(DEBUG, string'(" "));
      end loop;
      WRITELINE(OUTPUT, DEBUG);
    end if;
    CurrentReadState := Payload;
    lCounter         := 0;

    inf_loop : while not (endfile(InFile) or lFrame >= aDataPipe'length) loop

      READLINE(InFile, L);
      trim(L, side => both);

      case CurrentReadState is
-- ----------------------------------------------
        when Payload =>
          if L'length = 0 then
            CurrentReadState := Flushing;
          else
            READ(L, lLinkIds, lNCols, aDataPipe(lFrame));
            -- Debug
            if aDebugMessages then
              WRITE(DEBUG, string' ("PAYLOAD : "));
              WRITE(DEBUG, lCounter);
              WRITE(DEBUG, string' (" : "));
              WRITE(DEBUG, aDataPipe(lFrame));
              WRITELINE(OUTPUT, DEBUG);
            end if;
            lCounter := lCounter + 1;
          end if;
-- ----------------------------------------------
        when Flushing =>
          WRITE(DEBUG, string' ("FLUSHING : "));
          WRITELINE(OUTPUT, DEBUG);
          WRITELINE(OUTPUT, L);
-- ----------------------------------------------
        when others =>
          WRITE(DEBUG, string' ("SOMETHING HAS GONE WRONG"));
          WRITELINE(OUTPUT, DEBUG);
-- ----------------------------------------------
      end case;

      lFrame := lFrame + 1;

    end loop;
-- -----------------------------------------------------------------------------------------------------
    file_close(InFile);

    aNumFramesInPipe := lCounter;
    WRITE(DEBUG, string' (" Loaded frames "));
    WRITE(DEBUG, aNumFramesInPipe);
    WRITELINE(output, DEBUG);

    return;

  end procedure SourceEMPDataFile;
-- ----------------------------------------------------------



-- -----------------------------------------------------------------------------------------------------
  procedure DataStimulus
    (
      variable aClkCount        : in  integer;
      variable aDataPipe        : in  DataPipe_t;
      variable aNumFramesInPipe : in  natural;
      variable aPlaybackLength  : in  natural := 0;
      variable aPlaybackOffset  : in  natural := 0;
      variable aPlaybackLoop    : in  boolean := false;
      variable aStripHeader     : in  boolean := false;
      aDebugMessages            : in  boolean := false;
      -- -----------------------------------------------------
      signal aPayloadD          : out ldata(N_LINKS-1 downto 0)
    ) is

    variable lPlaybackLength    : natural   := aPlaybackLength;
    variable lFrame             : integer   := 0;
    variable lLastValid         : std_logic := '0';
    variable L, DEBUG           : line;

  begin
-- -----------------------------------------------------------------------------------------------------
  

    if aClkCount < 0 then
      if aDebugMessages then
        WRITE(DEBUG, string' ("Reset is high (clk_count ="));
        WRITE(DEBUG, aClkCount);
        WRITE(DEBUG, string' (") - padding with idles"));
        WRITELINE(OUTPUT, DEBUG);
      end if;
      aPayloadD <= (others => kIdleWord);
      return;
    end if;    
    -- Fall back on the total number of frames in pipe if caplen == 0
    if lPlaybackLength = 0 then
      lPlaybackLength := aNumFramesInPipe;
    end if;

    -- Calculate the current framed based on the loop mode flag
    if aPlaybackLoop then
      lFrame := (aClkCount-aPlaybackOffset) mod lPlaybackLength;
    else
      lFrame := (aClkCount-aPlaybackOffset);
    end if;

    if aDebugMessages then
      WRITE(DEBUG, string' ("Playing frame : "));
      WRITE(DEBUG, lFrame);
      WRITE(DEBUG, string' (" in clock cycle "));
      WRITE(DEBUG, aClkCount);
      WRITELINE(OUTPUT, DEBUG);
    end if;

    if (lFrame >= 0 and (lFrame < lPlaybackLength and lFrame < aNumFramesInPipe))  then

      --aPayloadD <= aDataPipe(lFrame);
      for i in 0 to N_LINKS-1 loop
        aPayloadD(i) <= aDataPipe(lFrame)(i);
        -- Header stripping: datavaild is forced low on the first frame of the packet
        if (aStripHeader) then
          if (lFrame = 0) then
            lLastValid := '0';
          else
            lLastValid := aDataPipe(lFrame-1)(i).valid;
          end if;

          aPayloadD(i).valid <= (aDataPipe(lFrame)(i).valid and lLastValid);
        end if;
      end loop;
    else
      aPayloadD <= (others => kIdleWord);
    end if;
-- -----------------------------------------------------------------------------------------------------
  end DataStimulus;

end package body emp_capture_tools;
