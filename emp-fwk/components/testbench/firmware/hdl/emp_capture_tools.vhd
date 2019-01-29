
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

  constant kIdleWord : lword := (X"50505050505050bc", '0', '0', '1');
  constant kEmptyData : ldata(N_LINKS - 1 downto 0) := (others => kIdleWord);

  type CurrentReadState_t is(Uninitialized, Gap, Payload, Flushing, Finished);

  procedure SourceEMPDataFile(aFileName       : in    string;
                              aDataPipe       : inout DataPipe_t;
                              aPlaybackFrames : in    integer := 0;
                              aGapLength      : in    integer := 0;
                              aDebugMessages  : in    boolean := false
                              );


  procedure DataStimulus(
      variable aClkCount       : in  integer;
-- -------------
      variable aDataPipe       : in  DataPipe_t;
      signal aPayloadD         : out ldata(N_LINKS - 1 downto 0);
-- -------------
      variable aPlaybackOffset : in  integer := 0;
      variable aStripHeader    : in  boolean := false
  );

end package emp_capture_tools;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------



---- -------------------------------------------------------------------------------------------------------------------------------------------------------------
package body emp_capture_tools is

-- ----------------------------------------------------------
  procedure SourceEMPDataFile(aFileName       : in    string;
                              aDataPipe       : inout DataPipe_t;
                              aPlaybackFrames : in    integer := 0;
                              aGapLength      : in    integer := 0;
                              aDebugMessages  : in    boolean := false
                              ) is
    variable L, DEBUG         : line;
    file InFile               : text;
    variable CurrentReadState : CurrentReadState_t := Uninitialized;
    variable lCounter, lFrame : integer            := 0;
    variable lPayloadLength   : integer;
    variable lNCols           : natural;
    variable lLinkIds         : LinkIdArray_t      := (others => -1);

  begin
-- -----------------------------------------------------------------------------------------------------

-- Open File
    FILE_OPEN(InFile, aFileName, read_mode);

--
    if aPlaybackFrames > 0 then
      lPayloadLength := aDataPipe'length;
    else
      lPayloadLength := aPlaybackFrames;
    end if;

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

    -- early exit
    --return;

    inf_loop : loop

      -- Break if EOF (future) or if the frame counter overruns the length of datapipe
      if endfile(InFile) or lFrame >= aDataPipe'length then
        CurrentReadState := Finished;
        return;
      end if;

      READLINE(InFile, L);
      trim(L, side=>both);

      case CurrentReadState is
-- ----------------------------------------------
        when Gap =>
-- Debug
          if aDebugMessages then
            WRITE(DEBUG, string' ("GAP : "));
            WRITE(DEBUG, lCounter);
            WRITELINE(OUTPUT, DEBUG);
          end if;
-- We will return empty LinkData
          if lCounter = (aGapLength-1) then
-- We are changing state
            CurrentReadState := Payload;
            lCounter         := 0;
          else
            lCounter := lCounter + 1;
          end if;
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
            if lCounter = (lPayloadLength-1) then
              -- We are changing state
              CurrentReadState := Gap;
              lCounter         := 0;
            else
              lCounter := lCounter + 1;
            end if;
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
    FILE_CLOSE(InFile);

  end procedure SourceEMPDataFile;
-- ----------------------------------------------------------



-- -----------------------------------------------------------------------------------------------------
  procedure DataStimulus
    (
      variable aClkCount       : in  integer;
-- -------------
      variable aDataPipe       : in  DataPipe_t;
      signal aPayloadD         : out ldata(N_LINKS-1 downto 0);
-- -------------
      variable aPlaybackOffset : in  integer := 0;
      variable aStripHeader    : in  boolean := false
      ) is

    variable lFrame     : integer   := 0;
    variable lLastValid : std_logic := '0';

    --CONSTANT kIdleWord         : lword := ((others => '0'), '0', '0', '0');
    --constant kIdleWord : lword := (X"50505050505050bc", '0', '0', '1');

  begin
-- -----------------------------------------------------------------------------------------------------
    lFrame := aClkCount-aPlaybackOffset;
    if (lFrame >= 0 and lFrame < aDataPipe'length) then

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
