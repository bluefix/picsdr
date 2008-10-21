
#ifndef LiquidCrystalNum_h
#define LiquidCrystalNum_h


#include <inttypes.h>
#include "WPrint.h"
/*
Notes on Serial LCD Module KTM-S1201.
SET UP/ INILIZATION Sequence
Hex Data Byte C/D line CS (Chip Select) Comments
0x40 1 0 M=0(4-share-1/3 duty; FF=0)
0x30 1 0 Unsynchronized XFR (sync would be 31)
0x18 1 0 blink off
0x11 1 0 Display ON
0x15 1 0 Segment Decoder ON
0x20 1 0 Clear Data and pointer
When sending data and using the 7 segment decoder, Just send it as binary
Note the address pointer works right to left i.e. When reset the first digit to be sent is the right most.
So, for example to display “123”
Hex Data Byte C/D line CS(Chip Select) Comments
0x03 0 0 Number 3
0x02 0 0 Number 2
0x01 0 0 Number 1
1 Raise chip select
When sending serial byte, the MSB goes first, and the SCK line needs to be pulsed low for each bit. The CS
(Chip select) should be low for the entire sequence, and not raised until all data bytes are sent. You then
must raise the CS to display the data sent.
To turn a decimal point on use this
Hex Data Byte C/D line CS(Chip Select) Comments
0x14 1 0 Segment Decoder off
0xE0 1 0 Set pointer 0 (incr by 2 for each digit)
0xB8 1 0 Decimal point on
0x15 1 0 Segment Decoder ON
1 Raise chip select
The controller chip is a NEC UPD7225
The following NEC documents will be helpful.
Document # IEA-1254A, Application note
Document # S14308EJ6V1DS00, Data Sheet
I found them by searching http://www.necel.com
Cleaning:
Occasionally you will see a missing segment. It is very simple to clean the LCD contacts and fix. There are 8 metal tabs that hold
the metal bezel on, twist each of these about 45 degrees to release them & slowly remove the bezel. Note the orientation of
everything so you re-assemble It the same way. The glass will just come off. There are two rubber connectors, one at left and right
ends. (Not the white strips) Take these off, and carefully clean both ends, the PCB contacts and glass where they connect. You
can use water or diluted household alcohol and a Q-tip. Allow them to dry completely before re-assembling. And you should be
good to go. If your display is really messed up then you probably put in back in the opposite direction, if so just take it apart reverse
it and reassemble.
Copyright, 2008 DCP Enterprises, Las Vegas, NV


*/
class LiquidCrystalNum : print
{
  private:
    uint8_t _control_rs;
    uint8_t _control_rw;
    uint8_t _control_e;
    uint8_t _port;
    void display_init(void)
    {
    // sck    out    or strb
    // sdat   out    or d0
    // c/d    out    or ra0
    // cs     out    or   e 
    // rst    out
    // -busy  in
    
    shift_out( 0x40);    waitForRdy();
    shift_out( 0x30);    waitForRdy();
    shift_out( 0x18);    waitForRdy();
    shift_out( 0x11);    waitForRdy();
    shift_out( 0x15);    waitForRdy();
    shift_out( 0x20);    waitForRdy();
    
    }
    
    void display_start(void);
    void display_wait(void);
    void display_control_write(uint8_t);
    uint8_t display_control_read(void);
    void display_data_write(uint8_t);
    uint8_t display_data_read(void);
    
    
    void display_write(char *, uint8_t);
    void printNumber(unsigned long, uint8_t);
  public:
    //LiquidCrystal();
    LiquidCrystal(uint8_t, uint8_t, uint8_t, uint8_t);
//    uint8_t read(void);
    void clear(void);
    void home(void);
    void setCursor(uint8_t, uint8_t);
    virtual void write(uint8_t);

/*
    void print(char);
    void print(char[]);
    void print(String &);
    void print(uint8_t);
    void print(int);
    void print(long);
    void print(long, int);
    void println(void);
    void println(char);
    void println(char[]);
    void println(String &);
    void println(uint8_t);
    void println(int);
    void println(long);
    void println(long, int);
*/
};