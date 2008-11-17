


/*
  Jesper Hansen <jesperh@telia.com>
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software Foundation, 
  Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


	DRAM Test Code
	--------------


	PIN assignements on STK200 board

	Port A	
		0..7 	Data 0..7 and address 0..7

	Port C	
		0		A8
		1		A9R
		2		-RAS
		3		-CAS
		4		-OE
		5		-WR			

*/


#include <io.h>
#include <progmem.h>
#include <signal.h>
#include <interrupt.h>

#include "uart.h"
#include "delay.h"



// At 8 MHz clock, the clock period is 125 nS
// 
// 12.8 mS @ prescaler 5 (f/1024) (128 uS) requires
// a counter preload value of -125 = 0xff83

#define TI1_H	0xff
#define TI1_L	0x83


// Executes a 1024 cycle CAS-before-RAS refresh sequence 
// on every timer interrupt (every 16 mS)
// This takes about 1.6 mS @ 8 MHz, so the refresh overhead 
// is about 10 %
// 
SIGNAL(SIG_OVERFLOW1)	//timer 1 overflow every 16 mS
{
	int i;

	outp(TI1_H, TCNT1H);					//reload timer 
	outp(TI1_L, TCNT1L);

	for (i=0;i<1024;i++)	// 1024 cycles
	{
		cbi(PORTC,PC3);		// CAS lo
		cbi(PORTC,PC2);		// RAS lo

		sbi(PORTC,PC3);		// CAS hi
		sbi(PORTC,PC2);		// RAS hi
	}
}



//
// Write a byte to a memory location
// This function executes in about 3 uS @ 8 MHz
//
void WRmem(unsigned long address, unsigned char data)
{
	register unsigned char alo,ami,ahi;
	
	alo = address;			// split into addressing bytes
	ami = address >> 8;
	ahi = ami >> 2;
	
	// Port A as output
	outp(0xff, DDRA);

	cli();					// turn off refresh while writing data

	outp(alo, PORTA);		// lower address
	outp(ami|0xFC, PORTC);	// lower address
	cbi(PORTC, PC2);		// RAS lo

	outp(ahi, PORTA);		// high address
	cbi(PORTC, PC3);		// CAS lo
	
	outp(data, PORTA);		// data
	cbi(PORTC, PC5);		// WR lo
	outp(0xff,PORTC);		// WR, RAS, CAS hi	

	sei();
}

//
// Read a byte from a memory location
// This function executes in about 3.6 uS @ 8 MHz
//
unsigned char RDmem(unsigned long address)
{
	register unsigned char b;
	register unsigned char alo,ami,ahi;

	alo = address;			// split into addressing bytes
	ami = address >> 8;
	ahi = ami >> 2;

	// Port A as output
	outp(0xff, DDRA);

	cli();					// turn off refresh while reading data
	
	outp(alo, PORTA);		// lower address
	outp(ami|0xFC, PORTC);	// lower address
	cbi(PORTC, PC2);		// RAS lo

	outp(ahi, PORTA);		// high address
	cbi(PORTC, PC3);		// CAS lo

	// port A input and activate pullups
	outp(0x00, DDRA);
	outp(0xff, PORTA);

	cbi(PORTC, PC4);		// OE lo
	asm volatile ("nop");
	b = inp(PINA);			// data
	outp(0xff,PORTC);		// OE, RAS, CAS hi	

	sei();
	return b;
}



int main(void) 
{

 	unsigned int  i;
  	unsigned char c;
	unsigned long addr;
 

//------------------------------
// Initialize ports
//------------------------------

	// A-port set to all inputs, pullups activated
	outp(0xff, PORTA);
	outp(0x00, DDRA);

	// C-port set to all outputs, set to 1 
	outp(0xff, PORTC);
	outp(0xff, DDRC);


//----------------------------------------------------------------------------
// More init
//----------------------------------------------------------------------------

	// Timer initialization
	
	outp(0, TCCR1A);
	outp(5, TCCR1B);		// prescaler fClk/1024  tPeriod = 128 uS
	outp(TI1_H, TCNT1H);	// load counter register
	outp(TI1_L, TCNT1L);	// load counter register
	sbi(TIMSK, TOIE1);		// enable timer1 interrupt

	UART_Init();	// init RS-232 link
					// interrupts are also enabled here, starting refresh	

	// say hello
  	PRINT("Memorytest 0.1\r\n");

 //----------------------------------------------------------------------------
 // Let things loose
 //----------------------------------------------------------------------------                        


	delay(20000);	// wait 20 mS to allow refresh to run at least once





	//
	// do a very simple memory test
	//


	addr = 0x1234;			// some address

	for (i=0;i<100;i++)		// write a pattern
		WRmem(addr+i,i);


	while (1)				// loop forever
	{
		for (i=0;i<50;i++)	// delay 5 seconds
			delay(10000);	
	
		for (i=0;i<100;i++)		
		{
			c = RDmem(addr+i);	// get a byte
			UART_Printfu08(c);	// print to console
			UART_SendByte(' ');	// print a space
		}
		EOL();					// print CR/LF
	}

}





