
/*--------------------------------------------------------------------------------

There are various Li-Ion and Li_Po chargers. I have used a L6924D but they are only surface mount so not easy to use.

All chargers seem to follow the same rules:-

Do not charge when bellow 10 deg C or above 40 deg C
Charge very slowly if less than 3.2 V
Limit voltage to 4.1 or 4.2 V
Stop charging when current falls to 1/20th of max current.

I think that the most important rule for most of the time is the voltage limit. 
Quote:
Originally Posted by jpanhalt 
The charging profile for LiPo batteries is described here:
" These chargers give a constant current charge rate at 75% the cell capacity until the pack voltage reaches 3.6 volts per cell. This charges the pack to about 80% of total capacity. At this point the charger switches to a constant voltage charge rate of 3.6 volts per cell to top off the battery. To charge a fully depleted pack typically takes about one and a half hours. " (Source: RC Hobbies) 

They are WRONG!
A Li-po battery cell is charged with a 4.2V source. The charger's current is limited to the capacity rating of the battery cell. When the cell's voltage reaches 4.2V it is about 75% charged then it will draw less current. When the current drops to about 0.01 of the cell's capacity then it is fully charged and must have the charger turned off.
 don't know either way which is correct. The Kokam battery producer states on its site: http://www.kokam.com/english/biz/rc.html

"Similar to other lithium rechargeable batteries, SLB452128 has typical charge discharge characteristics. SLB452128 can be charged by simple charging process with constant current at the beginning of the charge cycle and followed by constant voltage at the end of the charge cycle." 

Are there other reliable sources that suggest a constant voltage charge for the entire charging cycle? John
So, is the difference between what Kokam and RC Hobbies say and your comment the distinction between "constant current" and "current limited?" What is the practical difference between the two? I suspect "constant current" chargers are also voltage limited.

I use a "sophisticated," LCD-screened, expensive charger, and it still puffs the batteries. And that was starting with a pack at 3.8V per cell. Can't wait until the weather warms up enough, and I can launch my sailplanes in the usual way. LiPo's are great power to weight, but a real expensive PITA.
John

Edit: corrected LCD screen

Current limited, constant current and regulated current have the same meaning for a battery charger. Then the battery determines the current-limited voltage. The voltage has a max of 4.2V.

I don't have a Li-po battery so I don't know if it is normal for them to "puff".
Maybe your charger has its current set too high.

A Li-po battery charger has its voltage set very accurately to exactly 4.2V. Some can charge Li-po cells in series then the voltage is in multiples of 4.2V.

My RC "glider" has an electric motor driving a folding prop. It is powered from a heavy Ni-MH battery. The plane glides like a brick. It is too heavy to climb high and frequently stalls when trying.

My charger is one of those that charges the individual cells through a separate connector. It then balances them, presumably to exactly 4.2V, but I am not sure whether anything else is involved in the balance stage. Among hobbyists, series charging of LiPo packs is quickly losing favor because of the problem of over-charging some of the cells.

With respect to the personal anecdote, the charge current was set at 1.0 A, which was well below the maximum allowed rate of 2.1 A for the cells I was using. 

My glider, which has had only one flight after conversion from a pure glider to electric was a dream to fly. It soared as well or better than it did before conversion.

You need another sailplane, rather than fight trying to keep some brick up. For the type of gliders I fly, it is not so much weight as it is drag. They can go quite fast, but lose little altitude. John



From MC ps401 UG

CHARGE CONTROL
A SBS configuration normally allows the Smart Battery to broadcast the
ChargingVoltage and ChargingCurrent values to the Smart Battery Charger (SMBus
address 12 hex) to ‘control' when to start charge, stop charge and when to signal a valid
‘fully charged' condition. AlarmWarnings are also sent from the Smart Battery (SMBus
address 16 hex) to the Smart Battery Charger.
Alternately, the SMBus Host or a "Level 3" Smart Battery Charger may simply read the
SBData values for ChargingVoltage and ChargingCurrent from the Smart Battery
directly. The Host or "Level 3" Smart Battery Charger is also required to read the
SBData value of BatteryStatus to obtain the appropriate alarm and status bit flags.
When used in this configuration, the ChargingCurrent and ChargingVoltage broadcasts
can be disabled from the Smart Battery by setting the CHARGER_MODE (bit 14) in the
BatteryMode register. The PS401 IC's support all of these functions. (Please refer to
the SBS Smart Battery Charger Specification, for a definition of "Level 3" Smart Battery
Charger.)
The ChargingCurrent and ChargingVoltage registers contain the maximum charging
parameters desired by the particular chemistry, configuration and environmental
conditions. The environmental conditions include the measured temperature and the
measured cell or pack voltages.
For Li-based systems, ChargingVoltage is the product of the EOCVolt and Cells values
from the EEPROM:
ChargingVoltage = EOCVolt x Cells
The ChargingCurrent value is set to a maximum using the ChrgCurr value from the
EEPROM. For lithium systems, both ChargingCurrent and ChargingVoltage values are
maximums. When the current reaches ChrgCurr, it will be held constant at this value.
Then, when the voltage reaches ChrgVolt, the current must be reduced so that the
voltage will be constant and not exceed the maximum. This is accomplished by setting
ChargingCurrent to ChrgCurrOff. For safety reasons, this current change also occurs
when the temperature limits are exceeded. When temperature or voltage limits are
exceeded, the value of ChargingCurrent changes to ChrgCurrOff value from the
EEPROM. When a valid End-Of-Charge (EOC) condition is detected and a fully
charged state is reached, the ChargingCurrent value is set equal to the ChrgCurrOff
value.
______

When ChargingCurrent is set to the ChrgCurrOff value, no broadcasts of either
ChargingCurrent or ChargingVoltage will occur unless a charge current greater than
NullCurr is detected by the A/D measurements. Temperature limits are set using the
ChrgMaxTemp, DischrgMaxTemp and ChrgMinTemp values from OTP EPROM.
These values represent the temperate limits within which ChargingCurrent will be set
to ChrgCurr. Temperatures outside these limits will cause ChargingCurrent to be set
to ChrgCurrOff.
If ChargingCurrent is set to ChrgCurrOff and the measured temperature is greater
than DischrgMaxTemp and less than ChrgMaxTemp and a charge current is
measured which is significantly larger than the ChrgCurrOff value, then
ChargingCurrent will be set to ChrgCurr unless a fully charged condition has already
been reached.
If the CHARGER_MODE bit in BatteryMode is cleared (enabling broadcasts of
ChargingCurrent and ChargingVoltage), then these broadcasts will occur every
NChrgBroadcast measurement cycles. Broadcasts only occur when ChargingCurrent
is set to the ChrgCurr value and/or when the A/D converter measures a charge current
greater than NullCurr.
The Smart Battery Data and Smart Battery Charger Specifications require that
ChargingCurrent and ChargingVoltage broadcasts occur no faster than once per
5 seconds and no slower than once per 60 seconds, when charging is occurring or
desired. This requires that the NChrgBroadcast value must be set between 10 and
120. The SMBus Specification also requires that no broadcasts occur during the first
10 seconds after SMBus initialization. This, therefore, requires the NSilent value be set
to 20 or higher.
Configuration Example:
Measurement cycle is 500 msec
NChrgBroadcast = 100 decimal
NSilent = 24 decimal
ChrgCurr = 2500 decimal
ChrgCurrOff = 10 decimal
ChrgMaxTemp = 650 decimal
DischrgMaxTemp = 550 decimal
ChrgMinTemp = 200 decimal
Results:
ChargingCurrent and ChargingVoltage broadcasts:
100 cycles of 500 msec = every 50 seconds
Broadcast delay after SMBus initialization:
24 cycles of 500 msec = 12 seconds
ChargingCurrent if Temperature > 35°C: 10 mA
ChargingCurrent if Temperature < 0°C: 10 mA
ChargingCurrent if Temperature < 35°C and > 0°C: 2500 mA____________


5.7 FULL CHARGE DETECTION METHODS
For a typical lithium ion constant-current/constant-voltage charge system, the PS401
will monitor the taper current that enters the battery once the battery has reached the
final voltage level of the charger. Once the taper current falls to a certain level indicating
that the battery is full, the End-Of-Charge (EOC) will be triggered. Different taper
currents will be used for different temperatures. See the parameter explanation in the
programming section for details.
When a valid fully charged EOC condition is detected, the following actions occur:
• The FULLY_CHARGED status bit (bit 5) in the SBData value of BatteryStatus
is set to one to indicate a full condition. (This will remain set until
RelativeStateOfCharge drops below the ClrFullyChrg value in OTP EPROM.)
• RelativeStateOfCharge is set to 100%.
• ChargingCurrent is set to ChrgCurrOff value.
• SBData value for MaxError is cleared to zero percent (0%).
• The TERMINATE_CHARGE_ALARM bit (bit 14) is set in BatteryStatus and an
AlarmWarning broadcast is sent to the SMBus Host and Smart Battery Charger
addresses.
• The OverChrg value is incremented for any charge received above 100% after a
valid fully charged EOC condition.
• Control flags for internal operations are set to indicate a valid full charge condition
was achieved.
• Other BatteryStatus or AlarmWarning flag bits may also be set depending on the
conditions causing the EOC.
5.8 TEMPERATURE ALGORITHMS
The PS401 SMBus Smart Battery IC provides multiple temperature alarm set points
and charging conditions. The following EEPROM and OTP EPROM parameters control
how the temperature alarms and charging conditions operate.
HighTempAl: When the measured temperature is greater than HighTempAl,
the OVER_TEMP_ALARM is set. If the battery is charging, then the
TERMINATE_CHARGE_ALARM is also set.
ChrgMinTemp, DischrgMaxTemp and ChrgMaxTemp: If the measured temperature
is less than ChrgMinTemp, the ChargingCurrent is set to ChrgCurrOff and the
ChargingVoltage is set to ChrgVolt, to communicate to the charger that the
non-charging state of current and voltage should be given. When measured
temperature is greater than ChrgMaxTemp and the system is charging, or greater than
DischrgMaxTemp and the system is discharging, then ChargingCurrent is set to
ChrgCurrOff and the ChargingVoltage is set to ChrgVoltOff also. Otherwise,
ChargingCurrent = ChrgCurr and ChargingVoltage = ChrgVolt.

*/    
