/*

  Nokia 6100 Display Test
  Copyright 2005 Thomas Pfeifer (http://thomaspfeifer.net)


  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


  Target: AVR-ATMega8
  Compiler: AVRGcc

  Note: This will only work with Philips-Controller-Displays (brown flexible
  PCB). The ones with Epson-Controller (green PCB) will NOT work.

*/

//#### CONFIG ####

#define F_CPU 8000000UL  // 8 MHz

#define SPIPORT PORTB
#define SPIDDR DDRB
#define CS 2
#define CLK 5
#define SDA 3
#define RESET 4

#define USR UCSRA
#define UCR UCSRB
#define UBRR UBRRL
#define BAUD_RATE 38400
//#define MODE565

//#################



#include <avr/io.h>
#include <avr/delay.h>

#define cbi(reg, bit) (reg&=~(1<<bit))
#define sbi(reg, bit) (reg|= (1<<bit))

#define CS0 cbi(SPIPORT,CS);
#define CS1 sbi(SPIPORT,CS);
#define CLK0 cbi(SPIPORT,CLK);
#define CLK1 sbi(SPIPORT,CLK);
#define SDA0 cbi(SPIPORT,SDA);
#define SDA1 sbi(SPIPORT,SDA);
#define RESET0 cbi(SPIPORT,RESET);
#define RESET1 sbi(SPIPORT,RESET);

#define byte unsigned char
byte n=0;
byte s1,s2;
byte r,g,b;

void sendCMD(byte cmd);
void sendData(byte cmd);
void shiftBits(byte b);
void setPixel(byte r,byte g,byte b);

void waitms(int ms) {
  int i;
  for (i=0;i<ms;i++) _delay_ms(1);
}

int main (void) {

  SPIDDR=(1<<SDA)|(1<<CLK)|(1<<CS)|(1<<RESET); //Port-Direction Setup


  //Init Uart and send OK
  UCR = (1<<RXEN)|(1<<TXEN);
  UBRR=(F_CPU / (BAUD_RATE * 16L) - 1);
  loop_until_bit_is_set(USR, UDRE);
  UDR = 'O';
  loop_until_bit_is_set(USR, UDRE);
  UDR = 'K';


  CS0
  SDA0
  CLK1

  RESET1
  RESET0
  RESET1

  CLK1
  SDA1
  CLK1

  waitms(10);

  //Software Reset
  sendCMD(0x01);

  //Sleep Out
  sendCMD(0x11);

  //Booster ON
  sendCMD(0x03);

  waitms(10);

  //Display On
  sendCMD(0x29);

  //Normal display mode
  sendCMD(0x13);

  //Display inversion on
  sendCMD(0x21);

  //Data order
  sendCMD(0xBA);

  //Memory data access control
  sendCMD(0x36);

 //sendData(8|64);   //rgb + MirrorX
  sendData(8|128);   //rgb + MirrorY

#ifdef MODE565
  sendCMD(0x3A);
  sendData(5);   //16-Bit per Pixel
#else
  //sendCMD(0x3A);
  //sendData(3);   //12-Bit per Pixel (default)
#endif


  //Set Constrast
  //sendCMD(0x25);
  //sendData(63);


  //Column Adress Set
  sendCMD(0x2A);
  sendData(0);
  sendData(131);

  //Page Adress Set
  sendCMD(0x2B);
  sendData(0);
  sendData(131);

  //Memory Write
  sendCMD(0x2C);

	int i;
  //Test-Picture

  //red bar
  for (i=0;i<132*33;i++) {
    setPixel(255,0,0);
  }

  //green bar
  for (i=0;i<132*33;i++) {
    setPixel(0,255,0);
  }

  //blue bar
  for (i=0;i<132*33;i++) {
    setPixel(0,0,255);
  }

  //white bar
  for (i=0;i<132*33;i++) {
    setPixel(255,255,255);
  }


  //wait for RGB-Data on serial line and display on lcd

  while(1==1) {

    loop_until_bit_is_set(UCSRA, RXC);
    r = UDR;
    loop_until_bit_is_set(UCSRA, RXC);
    g = UDR;
    loop_until_bit_is_set(UCSRA, RXC);
    b = UDR;
    setPixel(r,g,b);

  }

}



void shiftBits(byte b) {

  CLK0
  if ((b&128)!=0) SDA1 else SDA0
  CLK1

  CLK0
  if ((b&64)!=0) SDA1 else SDA0
  CLK1

  CLK0
  if ((b&32)!=0) SDA1 else SDA0
  CLK1

  CLK0
  if ((b&16)!=0) SDA1 else SDA0
  CLK1

  CLK0
  if ((b&8)!=0) SDA1 else SDA0
  CLK1

  CLK0
  if ((b&4)!=0) SDA1 else SDA0
  CLK1

  CLK0
  if ((b&2)!=0) SDA1 else SDA0
  CLK1

  CLK0
  if ((b&1)!=0) SDA1 else SDA0
  CLK1

}




//send data
void sendData(byte data) {

  CLK0
  SDA1                                                 //1 for param
  CLK1

  shiftBits(data);
}

//send cmd
void sendCMD(byte data) {

  CLK0
  SDA0                                                 //1 for cmd
  CLK1

  shiftBits(data);
}

//converts a 3*8Bit-RGB-Pixel to the 2-Byte-RGBRGB Format of the Display
void setPixel(byte r,byte g,byte b) {
#ifdef MODE565
   sendData((r&248)|g>>5);
   sendData((g&7)<<5|b>>3);
#else
  if (n==0) {
    s1=(r & 240) | (g>>4);
    s2=(b & 240);
    n=1;
  } else {
    n=0;
    sendData(s1);
    sendData(s2|(r>>4));
    sendData((g&240) | (b>>4));
  }
#endif
}
