

/*
  http://www.myplace.nu/avr/countermeasures/counter.c
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



	Project: CounterMeasures


  	40 MHz Frequency Counter
  	------------------------
    
	CPU : 		At90S2313

	Date:  		2001-03-02

	Author : 	Jesper Hansen





	Current consumption about 40-45 mA.

	Measures to > 50 MHz
	

*/


#include <io.h>
#include <signal.h>
#include <interrupt.h>


// PORT D bits

// al counter control bits active low

#define CLEAR	PD6
#define OE_H	PD5
#define	OE_L	PD4

// PD3..0 is lower data bus


// PORT B

// PB7..4 is high data bus
// PB3 is OC1 output 
// PB2..0 is 74HC138 select bits for display common



// constants/macros 
#define F_CPU        4000000               		// 4MHz processor 
#define CYCLES_PER_US ((F_CPU+500000)/1000000) 	// cpu cycles per microsecond 


// display data

#define SEG_a	0x01
#define SEG_b	0x02
#define SEG_c	0x04
#define SEG_d	0x08
#define SEG_e	0x10
#define SEG_f	0x20
#define SEG_g	0x40
#define SEG_dot	0x80


unsigned char digits[] = {
	(SEG_a|SEG_b|SEG_c|SEG_d|SEG_e|SEG_f),			// 0
	(SEG_b|SEG_c),									// 1
	(SEG_a|SEG_b|SEG_d|SEG_e|SEG_g),				// 2
	(SEG_a|SEG_b|SEG_c|SEG_d|SEG_g),				// 3
	(SEG_b|SEG_c|SEG_c|SEG_f|SEG_g),				// 4
	(SEG_a|SEG_c|SEG_d|SEG_f|SEG_g),				// 5
	(SEG_a|SEG_c|SEG_d|SEG_e|SEG_f|SEG_g),			// 6
	(SEG_a|SEG_b|SEG_c),							// 7
	(SEG_a|SEG_b|SEG_c|SEG_d|SEG_e|SEG_f|SEG_g),	// 8
	(SEG_a|SEG_b|SEG_c|SEG_d|SEG_f|SEG_g),			// 9
	
	(SEG_a),										// mode 0 indicator	(Hz)
	(SEG_g),										// mode 1 indicator (kHz)
	(SEG_d),										// mode 2 indicator (MHz)
};


/****************************************************************************/


// timer 0 interrupt handles multiplex and refresh of the displays
// timer is clocked at 62500 Hz

#define TI0_L		(256-125)		// 500 Hz -> 2 mS

volatile unsigned char 	active_led = 0;

volatile unsigned long 	led_value = 0;	// four BCD nibbles
volatile unsigned char 	decimal_point = 0;
volatile unsigned char 	mode_setting = 0;



SIGNAL(SIG_OVERFLOW0)	//timer 0 overflow
{
	unsigned char a,b;

	// reload timer
	outp(TI0_L, TCNT0);

	// all displays off by setting all commons high
	outp(inp(PORTB) | 0x07, PORTB);
	
	if (active_led == 5)
	{
		b = digits[10 + mode_setting];
	}
	else
	{
		a = led_value >> (( 4 - active_led ) * 4);
	
		b = digits[a & 0x0f];
	
		if (decimal_point == (4 - active_led) )
			b |= SEG_dot;
	}

	a = b & 0xf0; 	// hi part
	b = b & 0x0f; 	// lo part

	// set digit data on port
	outp( (inp(PORTB) & 0x0f) | a, PORTB);	// high part
	outp( (inp(PORTD) & 0xf0) | b, PORTD);	// low part

	// set common		
	outp( (inp(PORTB) & 0xf8) | active_led, PORTB);

	active_led = (active_led+1) % 6;
}





/****************************************************************************/
/*  helpers  ****************************************************************/
/****************************************************************************/


void delay(unsigned short us) 
{
    unsigned short  delay_loops;
    register unsigned short  i;

    delay_loops = (us+3)/5*CYCLES_PER_US; // +3 for rounding up (dirty) 

	// one loop takes 5 cpu cycles 
    for (i=0; i < delay_loops; i++) {};
} 


//
// read 16 bit counter value 
//
unsigned int read_counters(void)
{
	unsigned int counter_value;

	// stop display refresh while reading counters
	cli();

	// turn off all segments
	outp(inp(PORTB) | 0x07, PORTB);
	
	// set high B port to input
	outp(0x0f,DDRB);

	// set low D port to input
	outp(0xf0,DDRD);


	// activate OE_H
	cbi(PORTD,OE_H);
	asm volatile("nop");
	sbi(PORTD,OE_H);			// one pulse to latch count
	asm volatile("nop");
	cbi(PORTD,OE_H);
	asm volatile("nop");
	
	// read hi
	counter_value = (inp(PINB) & 0xf0);
	// read lo
	counter_value |= (inp(PIND) & 0x0f);
	// deactivate OE_H
	sbi(PORTD,OE_H);


	counter_value <<= 8;

	
	// activate OE_L
	cbi(PORTD,OE_L);
	asm volatile("nop");
	sbi(PORTD,OE_L);			// one pulse to latch count
	asm volatile("nop");
	cbi(PORTD,OE_L);
	asm volatile("nop");

	// read hi
	counter_value |= (inp(PINB) & 0xf0);
	// read lo
	counter_value |= (inp(PIND) & 0x0f);
	// deactivate OE_L
	sbi(PORTD,OE_L);


	// set B port back to output
	outp(0xff,DDRB);

	// set D port back to output
	outp(0xff,DDRD);

	// re-enable display refresh
	sei();	
	return counter_value;
}


//
// do a capture
//
void capture(unsigned int compare)
{

	cbi(PORTD,CLEAR);		// clear external counters
	asm volatile("nop");
	sbi(PORTD,CLEAR);		// remove clear
	
	outp(0,TCNT1H);			// clear timer
	outp(0,TCNT1L);

	outp(compare >> 8,OCR1H);	// set the compare1 register to the
	outp(compare,OCR1L);		// required value

	outp(0x40,TCCR1A);			// set OC1 bit to toggle on compare

	sbi(TIFR,OCF1A);			// clear overflov/compare flags

	if (compare == 15625)
		outp(0x0C,TCCR1B);		// start with fClk/256 (15625 Hz) and compare clear
	else
		outp(0x0A,TCCR1B);		// start with fClk/8 (500 kHz) and compare clear

	while ( ! (unsigned char) ( inp(TIFR) & BV(OCF1A)) );	// wait for bit
	sbi(TIFR,OCF1A);	// clear flags
	
	// counter input now enabled
	// for the specified time
	
	while ( ! (unsigned char) ( inp(TIFR) & BV(OCF1A)) );	// wait again for bit

	outp(0,TCCR1B);		// stop timer
	
	// counter input disabled
}



/****************************************************************************/
/*  main  *******************************************************************/
/****************************************************************************/

int main(void) 
{
	int i,j;
	unsigned char dp,ms;
	unsigned long lv;
	unsigned int count;

	// set all PORTB as outputs
	outp(0xff,DDRB);
	
	// set all bits hi
	outp(0xff,PORTB);


	// set all PORTD as outputs
	outp(0xff,DDRD);
	
	// set all bits hi
	outp(0xff,PORTD);


	// setup timer 0

	outp(0x03, TCCR0);		// prescaler f/64  tPeriod = 1/62500 Hz -> 16 uS


	// enable timer 0 interrupt
	sbi(TIMSK, TOIE0);

	// start things running
	sei();


/*
	compare values at fclk/8 (500 kHz, 2 uS) :
	
 	  500 	= 1 mS
	 5000 	= 10 mS
	50000	= 100 mS
	
	at fclk/256 (15.625 kHz, 64 uS) :
	
 	15625  	= 1 S

*/


	// first make sure the OC1 pin is in a controlled state
	// we want it to be HIGH initially

	// There's no way to set/clear it directly, but it can be forced to 
	// a defined state by a compare match, se by setting a low compare value
	// and start the timer, it can be forced into set state


	outp(0,TCNT1H);		// clear timer
	outp(0,TCNT1L);

	outp(0,OCR1H);		// set compare to 200
	outp(200,OCR1L);

	outp(0xC0,TCCR1A);	// set OC1 bit to set on compare

	// start timer and wait for one compare match
	outp(0x01,TCCR1B);		// start with fClk/1 (4 MHz)
	while ( ! (unsigned char) ( inp(TIFR) & BV(OCF1A)) );	// wait for bit
	sbi(TIFR,OCF1A);	// clear flags

	outp(0,TCCR1B);		// stop timer

	// compare bit no HI, start 
	// doing some useful work


	while (1)
	{
		// try a capture at min gate
		capture(500);		// 1 mS
		// get the data		
		count = read_counters();
		dp = 3;		// decimal point
		ms = 2;		// indicate MHz
		
		if (count < 4096)		// less than 4.096 MHz
		{
			// try a capture at next gate value
			capture(5000);		// 10 mS
			// get the data		
			count = read_counters();
			dp = 4;		// decimal point
			ms = 2;		// indicate MHz

			if (count < 4096)	// less than 409.6 kHz
			{
				// try a capture at next gate value
				capture(50000);	// 100 mS
				// get the data		
				count = read_counters();
				dp = 3;		// decimal point
				ms = 1;		// indicate kHz
			
				if (count < 4096)	// less than 40.96 kHz
				{
					// try a capture at next gate value
					capture(15625);		// 1 S
					// get the data		
					count = read_counters();
					dp = 0;		// decimal point
					ms = 0;		// indicate Hz
				}
			}
		}
		
		// convert BINARY counter_value (int) to BCD in led_value (long)
		lv = 0;
		for (j=0;j<8;j++)
		{
			i = count % 10;
			lv >>= 4;
			lv |= ((unsigned long)i << 28);
			count /= 10;
		}

		// set display variables
		decimal_point = dp;
		mode_setting = ms;
		led_value = lv;

	} // loop

}



