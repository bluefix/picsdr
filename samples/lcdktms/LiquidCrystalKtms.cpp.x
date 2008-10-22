#include "LiquidCrystalKtms.h"

#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include "WProgram.h"



LiquidCrystalKtms::LiquidCrystalKtms(
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
  delayMicroseconds(2000);
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
	digitalWrite(_ncs, 0);
  send(value, 1);
  digitalWrite(_ncs, 1);
  delayMicroseconds(100);
}



void LiquidCrystalKtms::write(uint8_t value) {
  digitalWrite(_ncs, 0);
  send(value, 0);
  digitalWrite(_ncs, 1);
  delayMicroseconds(100);
}

void LiquidCrystalKtms::send(uint8_t value, uint8_t mode) 
{
  digitalWrite(_ncs, 0);
  digitalWrite(_cd, mode);    // 1 = cmd, 0= data
  digitalWrite(_ncs, LOW);
  delayMicroseconds(100);
  
  for (int i = 0; i < 8; i++) 
    {
      digitalWrite(_si, (value << i) & 0x80);
      digitalWrite(_nsck, 0x01);
      digitalWrite(_nsck, 0x00);
      delayMicroseconds(100);
      digitalWrite(_nsck, 0x01);
      delayMicroseconds(100);
    }
     delayMicroseconds(100);

    digitalWrite(_ncs, HIGH);
    digitalWrite(_ncs, LOW);
    digitalWrite(_ncs, 1);
    delayMicroseconds(100);
}
