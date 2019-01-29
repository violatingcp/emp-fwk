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

--! Using the EMP data-types
use work.emp_data_types.all;
use work.emp_project_decl.all;
use work.emp_device_decl.all;
use work.emp_framework_decl.all;
use work.emp_testbench_helpers.all;

--! @brief An entity providing a EMPCaptureFileWriter
--! @details Detailed description
entity EMPCaptureFileWriter is
  generic(
    gFileName      :    string;
    gCaptureOffset : in integer := 0;
    gCaptureLength : in integer := 1024;
    gInsertHeader  :    boolean := false;
    gDebugMessages : in boolean := false
    );
  port(
    clk      : in std_logic;
    rst      : in std_logic;
    LinkData : in ldata(N_LINKS - 1 downto 0) := (others => LWORD_NULL)
    );
end entity EMPCaptureFileWriter;

--! @brief Architecture definition for entity EMPCaptureFileWriter
--! @details Detailed description
architecture behavioral of EMPCaptureFileWriter is

  type CurrentWriteState_t is(Uninitialized, Payload);

-- ----------------------------------------------------------
  function hstring(aValue : std_logic_vector) return string is
    constant ne      : integer         := (aValue'length + 3) / 4;
    variable lResult : string(1 to ne);
    constant LUT     : string(1 to 16) := "0123456789abcdef";
  begin
    for i in 0 to ne-1 loop
      lResult(ne-i) := LUT(TO_INTEGER(unsigned(aValue(4 * i + 3 downto 4 * i))) + 1);
    end loop;
    return lResult;
  end function hstring;
-- ----------------------------------------------------------

-- ----------------------------------------------------------
  procedure WRITE(L : inout line; VALUE : in lword := LWORD_NULL) is
    variable TEMP : character;
  begin
    WRITE(L, VALUE.valid);
    WRITE(L, string' ("v"));
    WRITE(L, hstring(VALUE.data));
  end procedure WRITE;
-- ----------------------------------------------------------


-- ----------------------------------------------------------
  function PADDED_INT(VAL : integer; WIDTH : integer) return string is
    variable ret : string(WIDTH downto 1) := (others => '0');
  begin
    if integer'image(VAL) 'length >= WIDTH then
      return integer'image(VAL);
    end if;

    ret(integer'image(VAL) 'length downto 1) := integer'image(VAL);
    return ret;
  end function PADDED_INT;
-- ----------------------------------------------------------



-- ----------------------------------------------------------
  procedure EMPCaptureFileWriterProc(aFileName          : in    string;
                                     file OutFile       :       text;
                                     lCurrentWriteState : inout CurrentWriteState_t;
                                     aFrameCounter      : inout integer;
                                     LinkData           : in    ldata(N_LINKS-1 downto 0);
                                     IsHeader           :       std_logic_vector(N_LINKS-1 downto 0);
                                     aDebugMessages     : in    boolean := false
                                     ) is
    variable L, DEBUG : line;
  begin
    if lCurrentWriteState = Uninitialized then
-- Debug
      if aDebugMessages then
        WRITE(DEBUG, string' ("UNINITIALIZED : "));
        WRITE(DEBUG, aFrameCounter);
        WRITELINE(OUTPUT, DEBUG);
      end if;
-- Open File
      FILE_OPEN(OutFile, aFileName, write_mode);

      WRITE(L, string' ("Board ALGO_TESTBENCH"));
      WRITELINE(OutFile, L);

      WRITE(L, string' (" Quad/Chan :"));
      for q in 0 to N_REGION-1 loop
        if REGION_CONF(q).buf_o_kind /= no_buf then
          for c in 0 to 3 loop
            WRITE(L, string' ("        q"));
            WRITE(L, PADDED_INT(q, 2));
            WRITE(L, string' ("c"));
            WRITE(L, c);
            WRITE(L, string' ("      "));
          end loop;
        end if;
      end loop;
      WRITELINE(OutFile, L);

      WRITE(L, string' ("      Link :"));
      for q in 0 to N_REGION-1 loop
        if REGION_CONF(q).buf_o_kind /= no_buf then
          for c in 0 to 3 loop
            WRITE(L, string' ("         "));
            WRITE(L, PADDED_INT(q*4+c, 3));
            WRITE(L, string' ("       "));
          end loop;
        end if;
      end loop;
      WRITELINE(OutFile, L);

      lCurrentWriteState := Payload;
    end if;

    if aDebugMessages then
      WRITE(DEBUG, string' ("CAPTURING FRAME "));
      WRITE(DEBUG, aFrameCounter);
      WRITELINE(OUTPUT, DEBUG);
    end if;

    WRITE(L, string' ("Frame "));
    WRITE(L, PADDED_INT(aFrameCounter, 4));
    WRITE(L, string' (" :"));

    for q in 0 to N_REGION-1 loop
      if REGION_CONF(q).buf_o_kind /= no_buf then
        for c in 0 to 3 loop
          if REGION_CONF(q).buf_o_kind /= no_buf then
            if IsHeader(q*4+c) /= '0' then
              WRITE(L, string' (" 1v00001000"));
            else
              WRITE(L, string' (" "));
              WRITE(L, LinkData(q*4+c));
            end if;
          end if;
        end loop;
      end if;
    end loop;

    WRITELINE(OutFile, L);

  end procedure EMPCaptureFileWriterProc;
-- ----------------------------------------------------------

begin
  process(clk)
    file OutFile                : text;
    variable lCurrentWriteState : CurrentWriteState_t                  := Uninitialized;
    variable lClkCount          : integer                              := -1;
    variable lFrame             : integer                              := 0;
    variable LinkData_d         : ldata(N_LINKS-1 downto 0)            := (others => LWORD_NULL);
    variable IsHeader           : std_logic_vector(N_LINKS-1 downto 0) := (others => '0');
  begin

    if rising_edge(clk) then

      lFrame := lClkCount-gCaptureOffset;

      if (lFrame >= 0 and lFrame < gCaptureLength) then
        if ( gInsertHeader ) then
          for q IN 0 to N_LINKS-1 loop
            IsHeader( q ) := LinkData( q ) .valid and not LinkData_d( q ) .valid;
          end loop;
        end if;
        EMPCaptureFileWriterProc(gFileName, OutFile, lCurrentWriteState, lFrame, LinkData_d, IsHeader, gDebugMessages);
        lFrame   := lFrame + 1;
      end if;

      LinkData_d := LinkData;

      if rst = '1' then
        lClkCount := -1;
      else
        lClkCount := lClkCount + 1;
      end if;

    end if;
  end process;
end architecture behavioral;
