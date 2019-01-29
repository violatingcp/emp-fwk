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
          gPlaybackFrames :    integer := 0;
          gPlaybackOffset :    integer := 0;
          gFileBufferSize :    integer := 1024;
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

begin

  process(clk)
    variable lInitialised    : boolean                                  := false;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    variable lClkCount       : integer                                  := -1;
    variable lDataPipe       : DataPipe_t(gFileBufferSize - 1 downto 0) := (others => kEmptyData);
    -- Conversion from generics to variables
    variable lPlaybackOffset : integer                                  := gPlaybackOffset;
    variable lStripHeader    : boolean                                  := gStripHeader;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  begin

    if(rising_edge(clk)) then

      -- First iteration, load the file    
      if (lInitialised = false) then
        SourceEMPDataFile(
          aFileName       => gFileName,
          aDataPipe       => lDataPipe,
          aPlaybackFrames => gPlaybackFrames,
          aDebugMessages  => gDebugMessages
          );
        lInitialised := true;
      end if;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      DataStimulus
        (
          aClkCount       => lClkCount,
          aDataPipe       => lDataPipe,
          aPayloadD       => LinkData,
          aPlaybackOffset => lPlaybackOffset,
          aStripHeader    => lStripHeader
          );

      if rst = '1' then
        lClkCount := -1;
      else
        lClkCount := lClkCount + 1;
      end if;

    end if;

  end process;


end architecture behavioral;
