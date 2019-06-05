--! Using the IEEE Library
library IEEE;
--! Using STD_LOGIC
use IEEE.STD_LOGIC_1164.all;
--! Writing to and from files
use IEEE.STD_LOGIC_TEXTIO.all;
--! Using NUMERIC TYPES
use IEEE.NUMERIC_STD.all;
--! Writing to and from files
use STD.TEXTIO.all;

--! Using the "mp7_data" data-types
use work.emp_data_types.all;
use work.emp_capture_tools.all;
use work.emp_testbench_helpers.all;
use work.emp_device_decl.all;


--! @brief An entity providing a EMPCaptureFileReader
--! @details Detailed description
entity EMPCaptureFileReader is
  generic(gFileName       :    string;
          gPlaybackLength :    natural := 0;
          gPlaybackOffset :    natural := 0;
          gPlaybackLoop   :    boolean := false;
          gStripHeader    :    boolean := false;
          gDebugMessages  : in boolean := false
          );
  port(
    clk      : in  std_logic;
    rst      : in  std_logic;
    LinkData : out ldata(N_LINKS-1 downto 0) := (others => LWORD_NULL)
    );
end entity EMPCaptureFileReader;

--! @brief Architecture definition for entity EMPCaptureFileReader
--! @details Detailed description
architecture behavioral of EMPCaptureFileReader is

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper function to calculate the size of the file
  impure function get_line_count return positive is
      file file_pointer : text;
      variable line_data, debug : line;
      variable lineCount : natural := 0;
  begin
      file_open(file_pointer, gFileName, read_mode);
      while not endfile(file_pointer) loop
          readline(file_pointer, line_data);
          lineCount := lineCount + 1;
      end loop;
      file_close(file_pointer);


      write(debug, string' ("Source file length: "));
      write(debug, lineCount);
      writeline(output, debug);
      write(debug, string' ("       file path: "));
      write(debug, gFileName);
      writeline(output, debug);

      return lineCount;
  end function get_line_count;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  constant kMemorySize : positive := get_line_count;
  -- To be continued. see here
  --https://stackoverflow.com/questions/42583061/vhdl-arrays-how-do-i-declare-an-array-of-unknown-size-and-use-it
begin

  process(clk)
    variable lInitialised     : boolean                              := false;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    variable lClkCount        : integer                              := -1;
    variable lDataPipe        : DataPipe_t(kMemorySize - 1 downto 0) := (others => kEmptyData);
    variable lNumFramesInPipe : natural                              := 0;
    -- Conversion from generics to variables
    variable lPlaybackOffset  : natural                              := gPlaybackOffset;
    variable lPlaybackLength  : natural                              := gPlaybackLength;
    variable lStripHeader     : boolean                              := gStripHeader;
    variable lPlaybackLoop    : boolean                              := gPlaybackLoop;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  begin

    if(rising_edge(clk)) then

      -- First iteration, load the file    
      if (lInitialised = false) then
        SourceEMPDataFile(
          aFileName        => gFileName,
          aDataPipe        => lDataPipe,
          aNumFramesInPipe => lNumFramesInPipe,
          aDebugMessages   => gDebugMessages
          );
        lInitialised := true;
      end if;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      DataStimulus
        (
          aClkCount        => lClkCount,
          aDataPipe        => lDataPipe,
          aNumFramesInPipe => lNumFramesInPipe,
          aPlaybackLength  => lPlaybackLength,
          aPlaybackOffset  => lPlaybackOffset,
          aPlaybackLoop    => lPlaybackLoop,
          aStripHeader     => lStripHeader,
          aDebugMessages   => gDebugMessages,
          aPayloadD        => LinkData
          );

      if rst = '1' then
        lClkCount := -1;
      else
        lClkCount := lClkCount + 1;
      end if;

    end if;

  end process;


end architecture behavioral;
