#include "LiquidCrystalKtms.h"

#include <stdio.h>
//#include <string.h>
#include <inttypes.h>
#include "WProgram.h"
/*

d0    a
d1    b
d2    c
d3    dp
d4    d
d5    e
d6    f
d7    g


0    0x77
1    0x06
2    0xb3
3    0x97
4    0xcc
5    0xd5
6    0xf5
7    0x07
8    0xf7
9    0xd7
a    0xe7
b    0xf4
c    0x71
d    0xd6
e    0xf1
f    0xe1
g    0xc7
h    0xe4
i    0x20
j    0x36
k    0xe0
l    0x70
m    0xc1
n    0xa4
o    0xb4
p    0xe3
q    0xc7
r    0x61
s    0xdc
t    0xf0
u    0x76
v    0xc2
w    0xc2
x    0xc2
y    0xc2
z    0xc2
*/



LiquidCrystalKtms::LiquidCrystalKtms
	(
	uint8_t nsck, 
	uint8_t si, 
	uint8_t cd, 
	uint8_t nreset, 
	uint8_t nbusy,  
	uint8_t ncs)
{
	_nsck= nsck;
	_si = si;
	_cd= cd;
	_nreset =nreset;
	_nbusy = nbusy;
	_ncs = ncs;
	
  pinMode(_nsck, OUTPUT);
  pinMode(_si, OUTPUT);
  pinMode(_cd, OUTPUT);
  pinMode(_nreset, OUTPUT);
  pinMode(_ncs, OUTPUT);
  pinMode(_nbusy, INPUT);
      
      
  digitalWrite(_nreset, 0x01);
  digitalWrite(_nreset, 0x00);
  delayMicroseconds(100);

  digitalWrite(_nreset, 1);      
  digitalWrite(_ncs, 1);
  digitalWrite(_si, 0);
  digitalWrite(_cd, 1);
  digitalWrite(_nsck, 1);

  delayMicroseconds(100);
    
    /*
  SET UP/ INILIZATION Sequence
  */
  
  command( 0x40); //0x40 1 0 M=0(4-share-1/3 duty; FF=0)
  command( 0x30); //0x30 1 0 Unsynchronized XFR (sync would be 31)
  command( 0x18); //0x18 1 0 blink off
  command( 0x11); //0x11 1 0 Display ON
  command( 0x15); //0x15 1 0 Segment Decoder ON
  command( 0x20); //0x20 1 0 Clear Data and pointer
}

void LiquidCrystalKtms::clear()
{
  command(0x20);  // clear display, set cursor position to zero
}

void LiquidCrystalKtms::home()
{
setCursor(0,0);
}

void LiquidCrystalKtms::setCursor(uint8_t col, uint8_t row)
{
  command ( 0xe0 | (col & 0x1f) ); 
}

void LiquidCrystalKtms::command(uint8_t value) {
  send(value, 1);delayMicroseconds(1000);
}


void LiquidCrystalKtms::write(uint8_t value) {
  send(value-'0', 0);
}

void LiquidCrystalKtms::print(const char c[])
{
	int len = strlen(c);
	for(int i=len; i >0; i--) 
  {
    write(c[i-1]);
   }
}



//void LiquidCrystalKtms::write(uint8_t value) {
//	clear();
//	send(0xe0, 1 );
 // send(0xd0 | ((value-'0') & 0x0f), 1);
//}

void LiquidCrystalKtms::send(uint8_t value, uint8_t mode) 
{
	if( 1== mode) 
		{
			digitalWrite(_ncs, 0);
	    while ( 0 == _nbusy  ) delayMicroseconds(10);
    }
    
  digitalWrite(_cd, mode);    // 1 = cmd, 0= data
  digitalWrite(_nsck, 1);
  for (int i = 0; i < 8; i++) 
    {
    	delayMicroseconds(50);
     
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds(50);
      
      digitalWrite(_nsck, 1);
     }
 delayMicroseconds(50);
 
 if( 1== mode)
 	  {
 	  digitalWrite(_ncs, 1);
    while ( 0 == _nbusy  ) delayMicroseconds(10);
 	  }


}



/*
void LiquidCrystalKtms::send(uint8_t value, uint8_t mode) 
{
	if( 1== mode) digitalWrite(_ncs, 0);
  digitalWrite(_cd, mode);    // 1 = cmd, 0= data
  digitalWrite(_nsck, 1);
 
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
    	delayMicroseconds(50);
      digitalWrite(_nsck, 0);
      digitalWrite(_si, 0x80 == (value & 0x80));
      value = value << 1;
      delayMicroseconds( 50);
      digitalWrite(_nsck, 1);
 
 
  while ( 0 == _nbusy  ) delayMicroseconds(10);
 
 if( 1== mode)
 	  {
 	  digitalWrite(_ncs, 1);
 	  }
}
*/