/*

  Nokia 6100 Display Test
  Copyright 2006 Refik Hadzialic (http://www.e-dsp.com) but this code
  was derived from Thomas Pfeifer's code at
  http://thomaspfeifer.net/nokia_6100_display.htm and Owen Osborn's code
  at http://www.sparkfun.com/datasheets/LCD/Nokia6100_Demo.c. I don't 
  the credits for it. 


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


  Target: AVR-ATMega32
  Compiler: AVRGcc

  Note: 

*/

//#### CONFIG ####

#define F_CPU 4000000UL  // 4 MHz

#define SPIPORT PORTB
#define SPIDDR DDRB
#define CS 2
#define CLK 5
#define SDA 3
#define RESET 4



//#################



#include <avr/io.h>
#include <util/delay.h>

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
void LCD_put_pixel(unsigned char color, unsigned char x, unsigned char y);

void waitms(int ms) {
  int i;
  for (i=0;i<ms;i++) _delay_ms(1);
}

int main (void) {

  SPIDDR=(1<<SDA)|(1<<CLK)|(1<<CS)|(1<<RESET); //Port-Direction Setup


  
  int   i = 0;

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
  sendCMD(0xca);
  
  //added
  sendData(0x03);
  sendData(32);
  sendData(12);
  sendData(0x00);
  
  sendCMD(0xbb);  // comscn
  sendData(0x01);

  sendCMD(0xd1);  // oscon

  sendCMD(0x94);  // sleep out

  sendCMD(0x81);  // electronic volume, this is kinda contrast/brightness
  sendData(5);//ff);       //  this might be different for individual LCDs
  sendData(0x01);//01);     //

  sendCMD(0x20);  // power ctrl
  sendData(0x0f);      //everything on, no external reference resistors
  waitms(100);

  sendCMD(0xa7);  // display mode


  sendCMD(0xbc);  // datctl
  sendData(0x00);
  sendData(0);
  sendData(0x01);
  sendData(0x00);
  
  
  sendCMD(0xce);   // setup color lookup table
    // color table
    //RED
    sendData(0);
    sendData(2);
    sendData(4);
    sendData(6);
    sendData(8);
    sendData(10);
    sendData(12);
    sendData(15);
    // GREEN
    sendData(0);
    sendData(2);
    sendData(4);
    sendData(6);
    sendData(8);
    sendData(10);
    sendData(12);
    sendData(15);
    //BLUE
    sendData(0);
    sendData(4);
    sendData(9);
    sendData(15);


  sendCMD(0x25);  // nop
  
    sendCMD(0x75);   // page start/end ram
  sendData(2);            // for some reason starts at 2
  sendData(131);          
  
  sendCMD(0x15);   // column start/end ram
  sendData(0);          
  sendData(131);


  sendCMD(0x5c);    // write some stuff (background)
  for (i = 0; i < 18000; i++){
    sendData(28);  // 28 is green
  }
  

  sendCMD(0xaf);   // display on

  waitms(200);

 for (i = 0; i < 160; i++){   // this loop adjusts the contrast, change the number of iterations to get
   sendCMD(0xd6);                // desired contrast.  This might be different for individual LCDs
   waitms(2);
 }
  
    // draw a multi-colored square in the center of screen
  for (i = 0; i < 4096; i++){
    LCD_put_pixel(i, (i % 64) + 32, (i / 64) + 32);
  }

  while(1==1) {
  // now add here your code
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

void LCD_put_pixel(unsigned char color, unsigned char x, unsigned char y){
  x += 2;                  // for some reason starts at 2
  sendCMD(0x75);   // page start/end ram
  sendData(x);            
  sendData(132);          
  sendCMD(0x15);   // column start/end ram
  sendData(y);            // for some reason starts at 2
  sendData(131); 
  sendCMD(0x5C);    // write some shit
  sendData(color); 
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
