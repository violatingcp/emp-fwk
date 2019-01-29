
# The main control / status register for the chip.

## Controls

```
<node id="nuke" mask="0x1"/>
```

Set to issue a hard reset to all logic. This should return the device to power-on
reset state, with the exception that the MMCM generating the primary control clock
is not reset. Edge sensitive, but a delay block ensures that a return ipbus packet
is sent before oblivion ensues, if UDP is being used. Note that this will reset the
packet ID counter in the UDP block, so the control hub will not be happy.

```            
<node id="clk40_rst" mask="0x2"/>
```

Resets all logic in the LHC-locked clock domains, including the MMCM used to
generate the clocks. Level-sensitive; note that the MMCM should be held in reset
when switching LHC clock sources.
            
```
<node id="clk40_sel" mask="0x4"/>
```

Selects the source of the LHC clock. Zero specifies a 40.000MHz clock generated
from an onboard 125MHz crystal. One specifies the 40.079MHz backplane clock sent
from the AMC13. Other future options may be added.

            <node id="quad_sel" mask="0x1f00"/>

Selects the quad to map into the control register and capture buffer space. Only
one quad exists in the current release, so changing this is pointless...
            
            <node id="brd_ctrl" mask="0xffff0000"/>
            
Controls GPIO lines used for various purposes on different boards (e.g. on the GLIB,
controls the configuration of the clock distribution crosspoint switches).
            
        </node>
        <node id="stat" address="0x1">
            <node id="clk40_lock" mask="0x1"/>
            
Indicates the lock status of the LHC clock MMCM block.
            
            <node id="clk40_stop" mask="0x2"/>
            
Indicates that the clock is absent at the input of the LHC clock MMCM block (note:
does not appear to work in 7-series devices).
            
        </node>
            
    </node>
    <node id="buf_test" module="file://trans_buffer_test.xml" address="0x4">
    <node id="xpoint" module="file://mp7_xpoint.xml" address="0x6"/>
    <node id="i2c" module="file://opencores_i2c.xml" address="0x8"/>
</node>
