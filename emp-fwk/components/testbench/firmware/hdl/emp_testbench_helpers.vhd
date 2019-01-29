--! Using the IEEE Library
library IEEE;
--! Using STD_LOGIC
use IEEE.STD_LOGIC_1164.all;
--! Using NUMERIC TYPES
use IEEE.NUMERIC_STD.all;

--! Writing to and from files
use STD.TEXTIO.all;

--! EMP device declaration
use work.emp_device_decl.all;


package emp_testbench_helpers is

  constant N_LINKS : integer := N_REGION * 4;

-- To write to a Log File
  --FILE LoggingDestination                   : TEXT OPEN write_mode IS "../../../../TestBench.Out";
-- To write to the Console
  alias LoggingDestination is output;

  type tRetVal is array(natural range <>) of integer range -1 to 5;

  --PROCEDURE CHECK_RESULT( DUT : IN STRING ; INDEX : IN INTEGER ; BX : IN INTEGER ; EXPECTED_LATENCY : IN INTEGER ; TIMEOUT : IN INTEGER ; RETVAL : INOUT INTEGER ; TEST : IN BOOLEAN ; DEBUG : IN BOOLEAN );
  procedure PRINT_CLOCK(clk : in integer);
  --PROCEDURE CREATE_REPORT;
  --PROCEDURE REPORT_RESULT( DUT : IN STRING ; RETVAL : IN tRetVal );
  --PROCEDURE CLOSE_REPORT;

end package emp_testbench_helpers;

package body emp_testbench_helpers is

--  PROCEDURE CHECK_RESULT( DUT : IN STRING ; INDEX : IN INTEGER ; BX : IN INTEGER ; EXPECTED_LATENCY : IN INTEGER ; TIMEOUT : IN INTEGER ; RETVAL : INOUT INTEGER ; TEST : IN BOOLEAN ; DEBUG : IN BOOLEAN ) IS
--    VARIABLE s                : LINE;
--    VARIABLE LatencyMatch     : BOOLEAN;

--  BEGIN
---- RETVAL = 0 : Running
---- RETVAL = 1 : Success
---- RETVAL = 2 : Successful result but wrong latency
---- RETVAL = 3 : Multiple Successful results including correct latency
---- RETVAL = 4 : Multiple Successful results excluding correct latency
---- RETVAL = 5 : Timeout

--    IF( bx <= 0 ) THEN -- IGNORE FIRST FRAME
--      RETURN;
--    END IF;

--    IF( BX >= TIMEOUT ) THEN -- WE HAVE PASSED THE TIME OUT
--      IF( RETVAL = 0 ) THEN -- WE TIMED OUT WHILST STILL RUNNING - REPORT THIS
--        IF DEBUG THEN
--          WRITE( s , DUT );
--          WRITE( s , STRING' ( "[" ) );
--          WRITE( s , INDEX );
--          WRITE( s , STRING' ( "] timed OUT" ) );
--          WRITELINE( LoggingDestination , s );
--        END IF;
--        RETVAL := 5;
--      END IF;
--      RETURN;
--    END IF;


--    IF( NOT TEST ) THEN -- NO MATCH - TRY AGAIN NEXT CLOCK CYCLE
--      RETURN;
--    END IF;

---- WE MUST HAVE A MATCH!

---- TEST THE LATENCY
--    LatencyMatch := ( ( BX-index-1 ) = EXPECTED_LATENCY );

---- UPDATE THE STATE
--    IF( LatencyMatch ) THEN
--      CASE RETVAL IS
--        WHEN 0      => RETVAL      := 1; -- WAS RUNNING , NOW SUCCESS
--        WHEN 1      => RETVAL      := -1; -- SHOULD NEVER OCCUR!
--        WHEN 2      => RETVAL      := 3; -- WAS SUCCESS WRONG LATENCY , NOW SUCCESS( MULTIPLE MATCHES INCLUDING CORRECT LATENCY )
--        WHEN 3      => RETVAL      := -1; -- SHOULD NEVER OCCUR!
--        WHEN 4      => RETVAL      := 3; -- WAS SUCCESS( MULTIPLE MATCHES EXCLUDING CORRECT LATENCY ) , NOW SUCCESS( MULTIPLE MATCHES INCLUDING CORRECT LATENCY )
--        WHEN 5      => RETVAL      := -1; -- SHOULD NEVER OCCUR!
--        WHEN OTHERS => RETVAL := -1; -- SHOULD NEVER OCCUR!
--      END CASE;
--    ELSE
--      CASE RETVAL IS
--        WHEN 0      => RETVAL      := 2; -- WAS RUNNING , NOW SUCCESS WRONG LATENCY
--        WHEN 1      => RETVAL      := 3; -- WAS SUCCESS , NOW SUCCESS( MULTIPLE MATCHES INCLUDING CORRECT LATENCY ) !
--        WHEN 2      => RETVAL      := 4; -- WAS SUCCESS WRONG LATENCY , NOW SUCCESS( MULTIPLE MATCHES EXCLUDING CORRECT LATENCY )
--        WHEN 3      => RETVAL      := 3; -- WAS SUCCESS( MULTIPLE MATCHES INCLUDING CORRECT LATENCY ) , NOW SUCCESS( MULTIPLE MATCHES INCLUDING CORRECT LATENCY )
--        WHEN 4      => RETVAL      := 4; -- WAS SUCCESS( MULTIPLE MATCHES EXCLUDING CORRECT LATENCY ) , NOW SUCCESS( MULTIPLE MATCHES EXCLUDING CORRECT LATENCY )
--        WHEN 5      => RETVAL      := -1; -- SHOULD NEVER OCCUR!
--        WHEN OTHERS => RETVAL := -1; -- SHOULD NEVER OCCUR!
--      END CASE;
--    END IF;

---- REPORT THE MATCH
--    IF DEBUG THEN
--      WRITE( s , DUT );
--      WRITE( s , STRING' ( "[" ) );
--      WRITE( s , INDEX );
--      WRITE( s , STRING' ( "]" ) );
--      WRITE( s , STRING' ( " : latency " ) );
--      WRITE( s , ( BX-index-1 ) );
--      WRITE( s , STRING' ( " clks : " ) );

--      IF( LatencyMatch ) THEN
--        WRITE( s , STRING' ( "Matches expected latency" ) );
--      ELSE
--        WRITE( s , STRING' ( "This does NOT match the expected latency OF " ) );
--        WRITE( s , EXPECTED_LATENCY );
--        WRITE( s , STRING' ( " clks" ) );
--      END IF;

--      WRITELINE( LoggingDestination , s );
--    END IF;
--  END CHECK_RESULT;


  procedure PRINT_CLOCK(clk : in integer) is
    variable s : line;

  begin
    WRITELINE(LoggingDestination, s);
    WRITE(s, string' ("<<<<<<<<<< "));
    WRITE(s, string' ("Clock "));
    WRITE(s, clk);
    WRITE(s, string' (" >>>>>>>>>>"));
    WRITELINE(LoggingDestination, s);
  end PRINT_CLOCK;


  --PROCEDURE CREATE_REPORT IS
  --  VARIABLE s     : LINE;
  --  VARIABLE space : STRING( 70 DOWNTO 1 ) := ( OTHERS => ' ' );

  --BEGIN
  --  WRITELINE( LoggingDestination , s );
  --  WRITE( s , STRING' ( "+----------------------------------------------------------------------------------------------------------------------------------------------------+" ) );
  --  WRITELINE( LoggingDestination , s );
  --  WRITE( s , STRING' ( "|" ) );
  --  WRITE( s , space( 68 DOWNTO 1 ) );
  --  WRITE( s , STRING' ( "FINAL REPORT" ) );
  --  WRITE( s , space( 68 DOWNTO 1 ) );
  --  WRITE( s , STRING' ( "|" ) );
  --  WRITELINE( LoggingDestination , s );
  --  WRITE( s , STRING' ( "+----------------------------------------------------------------------------------------------------------------------------------------------------+" ) );
  --  WRITELINE( LoggingDestination , s );
  --END CREATE_REPORT;

  --PROCEDURE REPORT_RESULT( DUT               : IN STRING ; RETVAL : IN tRetVal ) IS
  --  VARIABLE s                               : LINE;
  --  VARIABLE SUCCESSES , PARTIALS , FAILURES : INTEGER := 0;

  --BEGIN

  --  FOR i IN 0 TO RETVAL'LENGTH - 1 LOOP
  --    WRITE( s , STRING' ( "|" ) );
  --    WRITE( s , DUT , RIGHT , 70 );
  --    WRITE( s , STRING' ( "[" ) );
  --    WRITE( s , i , RIGHT , 2 );
  --    WRITE( s , STRING' ( "] | " ) );

  --    CASE RETVAL( i ) IS
  --      WHEN 0      => WRITE( s , STRING' ( "Test still running! Consider failure by default" ) , RIGHT , 70 );
  --      WHEN 1      => WRITE( s , STRING' ( "Test Successful" ) , RIGHT , 70 );
  --      WHEN 2      => WRITE( s , STRING' ( "Test Successful [Wrong latency]" ) , RIGHT , 70 );
  --      WHEN 3      => WRITE( s , STRING' ( "Test Successful [Multiple matches including correct latency]" ) , RIGHT , 70 );
  --      WHEN 4      => WRITE( s , STRING' ( "Test Successful [Multiple matches excluding correct latency]" ) , RIGHT , 70 );
  --      WHEN 5      => WRITE( s , STRING' ( "Test timed-OUT! Failure!" ) , RIGHT , 70 );
  --      WHEN OTHERS => WRITE( s , STRING' ( "Unknown retval! Consider failure by default" ) , RIGHT , 70 );
  --    END CASE;
  --    WRITE( s , STRING' ( " |" ) );
  --    WRITELINE( LoggingDestination , s );

  --    CASE RETVAL( i ) IS
  --      WHEN 0      => FAILURES      := FAILURES + 1;
  --      WHEN 1      => SUCCESSES     := SUCCESSES + 1;
  --      WHEN 2      => PARTIALS      := PARTIALS + 1;
  --      WHEN 3      => SUCCESSES     := SUCCESSES + 1;
  --      WHEN 4      => PARTIALS      := PARTIALS + 1;
  --      WHEN 5      => FAILURES      := FAILURES + 1;
  --      WHEN OTHERS => FAILURES := FAILURES + 1;
  --    END CASE;
  --  END LOOP;

  --  WRITE( s , STRING' ( "+----------------------------------------------------------------------------------------------------------------------------------------------------+" ) );
  --  WRITELINE( LoggingDestination , s );

  --  WRITE( s , STRING' ( "| " ) );
  --  WRITE( s , DUT , LEFT , 74 );
  --  WRITE( s , STRING' ( "| " ) );
  --  IF( FAILURES > 0 ) THEN
  --    WRITE( s , STRING' ( "FAILURE" ) , LEFT , 70 );
  --  ELSIF( PARTIALS > 0 ) THEN
  --    WRITE( s , STRING' ( "PARTIAL SUCCESS" ) , LEFT , 70 );
  --  ELSE
  --    WRITE( s , STRING' ( "SUCCESS" ) , LEFT , 70 );
  --  END IF;
  --  WRITE( s , STRING' ( " |" ) );
  --  WRITELINE( LoggingDestination , s );

  --  WRITE( s , STRING' ( "+----------------------------------------------------------------------------------------------------------------------------------------------------+" ) );
  --  WRITELINE( LoggingDestination , s );

  --END REPORT_RESULT;

  --PROCEDURE CLOSE_REPORT IS
  --  VARIABLE s : LINE;

  --BEGIN
  --END CLOSE_REPORT;

end emp_testbench_helpers;
