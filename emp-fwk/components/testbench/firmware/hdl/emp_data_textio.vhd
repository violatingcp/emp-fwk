
--! Using the IEEE Library
library IEEE;

--! Writing to and from files
use IEEE.STD_LOGIC_TEXTIO.all;
--! Writing to and from files
use STD.TEXTIO.all;

--! Using STD_LOGIC
use IEEE.STD_LOGIC_1164.all;
--! Using NUMERIC TYPES
--use IEEE.NUMERIC_STD.all;
--use IEEE.math_real.all;                 -- for UNIFORM , TRUNC functions

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

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
package emp_data_textio is
  type LinkIdArray_t is array(N_LINKS - 1 downto 0) of integer range -1 to N_LINKS - 1;  -- (-1 : not present)

  procedure READLINKIDS (L : inout line; aLinkToColLUT : out LinkIdArray_t; aNumCols : out natural);
  procedure READ(L : inout line; VALUE : out lword; aGood : out boolean);
  procedure READ(L : inout line; aLinkToColLUT : in LinkIdArray_t; aNumLinkIds : in natural; aValue : out ldata(N_LINKS-1 downto 0));
  procedure WRITE(L : inout line; VALUE : in lword := LWORD_NULL);
  procedure WRITE(L : inout line; VALUE : in ldata(N_LINKS-1 downto 0) := (others => LWORD_NULL));
end package emp_data_textio;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------



---- -------------------------------------------------------------------------------------------------------------------------------------------------------------
package body emp_data_textio is

-- ----------------------------------------------------------
    procedure READLINKIDS (L : inout line; aLinkToColLUT : out LinkIdArray_t; aNumCols : out natural) is
      type ColumnIdArray_t is array(N_LINKS downto 0) of integer range -1 to N_LINKS - 1;  -- Array of column ids of a max size NLinks+1. (-1 : not present)
      
      variable lOK          : boolean;
      variable lColLinkLut  : ColumnIdArray_t := (others => -1);
      variable lCol         : natural       := 0;
      variable lDummyStr    : string(1 to 12);
      variable lId          : integer;
      variable L2, DEBUG    : line;

      ---
      variable lOthersCol   : integer := -1;
      variable lOthersFound : boolean := false;
      variable lSize        : natural := 0;
      variable lMaxCol      : natural := 0;

    begin
      -- Drop the header"      Link : "
      tail(L,L'length-12);
      -- Trim it
      trim(L, side=>both);

      while L'length > 0 loop
        -- Remove leading whitespaces
        trim(L, side=>left);

        -- Check if 'others' is here
        copy(L, L2);
        head(L2,6);
        eq(L2, "others", lOK);
        if lOK = true then
          --Stop if others was found already
          assert (lOthersFound = false) report "Multiple 'others' columns found" severity failure;
          lOthersFound := true;
          lOthersCol := lCol;
          tail(L,L'length-6);
        else
          READ(L, lId, lOK);

          -- Stop if failed
          if lOK = false then
            length(L, lSize);
            assert (lSize = 0) report "Found trailing characters in Link header" severity failure;
            exit;
          end if;

          if lOthersFound then
            lMaxCol := N_LINKS + 1;
          else
            lMaxCol := N_LINKS;
          end if;

          -- Throw if lCol gets bigger than the buffer length
          assert (lCol < lMaxCol) report "Number of columns larger than number of allocated links" severity failure;

          lColLinkLut(lCol) := lId;
        end if;

        lCol := lCol+1;
      end loop;

      --aLinkToColLUT := (others => lOthersCol) when (lOthersFound) else (others => -1);
      if (lOthersFound) then
        aLinkToColLUT := (others => lOthersCol);
      else
        aLinkToColLUT := (others => -1);
      end if;

      -- Fill LinkIds object by inverting the column-link id lut
      for i in 0 to lColLinkLut'length-1 loop
        if (lColLinkLut(i) /= -1) then
          aLinkToColLUT(lColLinkLut(i)) := i;
        end if;

      end loop;

      --aLinkToColLUT := lColLinkLut;
      aNumCols := lCol;

    end READLINKIDS;
-- ----------------------------------------------------------

-- ----------------------------------------------------------
--! Read 1 lword from Lone
    procedure READ(L : inout line; VALUE : out lword; aGood : out boolean) is
      variable TEMP : character;
    begin
      READ(L, TEMP, aGood);
      READ(L, VALUE.valid, aGood);
      READ(L, TEMP, aGood);
      HREAD(L, VALUE.data, aGood);
      VALUE.start := '0';
      VALUE.strobe := '1';

    end procedure READ;
-- ----------------------------------------------------------

-- ----------------------------------------------------------
-- Read up to N_LINKS lword from line
    procedure READ (L : inout line; aLinkToColLUT : in LinkIdArray_t; aNumLinkIds : in natural; aValue : out ldata(N_LINKS-1 downto 0)) is
      variable lRBuffer  : ldata(N_LINKS downto 0)   := (others => LWORD_NULL);
      variable lVBuffer  : ldata(N_LINKS-1 downto 0) := (others => LWORD_NULL);
      variable lValue    : lword;
      variable lCol      : natural                   := 0;
      variable lDummyStr : string(1 to 12);
      variable lGood     : boolean                   := true;
      variable DEBUG     : line;
    begin
      READ(L, lDummyStr);                       -- "Frame XXXX : "

      -- loop over the line
      while L'length > 0 loop
        -- read the next value
        READ(L, lValue, lGood);

        -- Stop if failed
        if lGood = false then
          exit;
        end if;
        -- Or if we're going too far
        assert (lCol < lVBuffer'length) report "ERROR: ROW too long" severity failure;

        lRBuffer(lCol) := lValue;
        lCol                    := lCol+1;
      end loop;
      
      -- and make sure it gets to the end
      assert (lCol = aNumLinkIds) report "ERROR: ROW too short" severity failure;

      -- now remap to destination
      for k in 0 to lVBuffer'length-1 loop
        if (aLinkToColLUT(k) /= -1) then
          lVBuffer(k) := lRBuffer(aLinkToColLUT(k));          
        end if;
      end loop;


      -- push out the result
      aValue := lVBuffer;
    end READ;
-- ----------------------------------------------------------


-- ----------------------------------------------------------
    procedure WRITE(L : inout line; VALUE : in lword := LWORD_NULL) is
      variable TEMP : character;
    begin
      WRITE(L, VALUE.valid);
      WRITE(L, string' ("v"));
      HWRITE(L, VALUE.data);
    end procedure WRITE;
-- ----------------------------------------------------------

-- ----------------------------------------------------------
    procedure WRITE(L : inout line; VALUE : in ldata(N_LINKS-1 downto 0) := (others => LWORD_NULL)) is
    begin
      for i in 0 to N_LINKS-1 loop
        WRITE(L, string' (" "));
        WRITE(L, VALUE(i));
      end loop;
    end procedure WRITE;
-- ----------------------------------------------------------

end package body emp_data_textio;
