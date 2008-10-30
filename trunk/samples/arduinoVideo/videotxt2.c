 
//video gen  and Kalidascope
//D.5 is sync:1000 ohm + diode to 75 ohm resistor
//D.6 is video:330 ohm + diode to 75 ohm resistor
                    
#include <Mega163.h>   
#include <stdio.h>
#include <stdlib.h> 
#include <math.h>

//cycles = 63.625 * 8 Note NTSC is 63.55 
//but this line duration makes each frame exactly 1/60 sec
//which is nice for keeping a realtime clock 
#define lineTime 509
 
#define begin {
#define end   }
#define ScreenTop 30
#define ScreenBot 230
#define T0reload 256-60

//NOTE that the first line of CHARs must be in registers!
char syncON, syncOFF, v1, v2, v3, v4, v5, v6, v7, v8; 
int i,LineCount;
int time;
char screen[800], t, ts[10]; 
char gaugeY ;   //state variable for gauge
char figure ;   //state variable for waving figure
char numstr[]="0123456789";
char alphastr1[]="ABCDEFGHIJKLM";
char alphastr2[]="NOPQRSTUVWXYZ"; 
char alphastr3[]="ABCDEFG";
char alphastr4[]="HIJKLMN"; 
char alphastr5[]="OPQRSTU";
char alphastr6[]="VWXYZ";
char cu1[]="CORNELL"; 
char cu2[]="ECE476";

//define some character bitmaps
//5x7 characters
flash char bitmap[38][7]={ 
	//0
	0b01110000,
	0b10001000,
	0b10011000,
	0b10101000,
	0b11001000,
	0b10001000,
	0b01110000,
	//1
	0b00100000,
	0b01100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b01110000,  
	//2
	0b01110000,
	0b10001000,
	0b00001000,
	0b00010000,
	0b00100000,
	0b01000000,
	0b11111000,
    	//3
	0b11111000,
	0b00010000,
	0b00100000,
	0b00010000,
	0b00001000,
	0b10001000,
	0b01110000,
	//4
	0b00010000,
	0b00110000,
	0b01010000,
	0b10010000,
	0b11111000,
	0b00010000,
	0b00010000,
	//5
	0b11111000,
	0b10000000,
	0b11110000,
	0b00001000,
	0b00001000,
	0b10001000,
	0b01110000,
	//6
	0b01000000,
	0b10000000,
	0b10000000,
	0b11110000,
	0b10001000,
	0b10001000,
	0b01110000,
	//7
	0b11111000,
	0b00001000,
	0b00010000,
	0b00100000,
	0b01000000,
	0b10000000,
	0b10000000,
	//8
	0b01110000,
	0b10001000,
	0b10001000,
	0b01110000,
	0b10001000,
	0b10001000,
	0b01110000,
	//9
	0b01110000,
	0b10001000,
	0b10001000,
	0b01111000,
	0b00001000,
	0b00001000,
	0b00010000,  
	//A
	0b01110000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b11111000,
	0b10001000,
	0b10001000,
	//B
	0b11110000,
	0b10001000,
	0b10001000,
	0b11110000,
	0b10001000,
	0b10001000,
	0b11110000,
	//C
	0b01110000,
	0b10001000,
	0b10000000,
	0b10000000,
	0b10000000,
	0b10001000,
	0b01110000,
	//D
	0b11110000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b11110000,
	//E
	0b11111000,
	0b10000000,
	0b10000000,
	0b11111000,
	0b10000000,
	0b10000000,
	0b11111000,
	//F
	0b11111000,
	0b10000000,
	0b10000000,
	0b11111000,
	0b10000000,
	0b10000000,
	0b10000000,
	//G
	0b01110000,
	0b10001000,
	0b10000000,
	0b10011000,
	0b10001000,
	0b10001000,
	0b01110000,
	//H
	0b10001000,
	0b10001000,
	0b10001000,
	0b11111000,
	0b10001000,
	0b10001000,
	0b10001000,
	//I
	0b01110000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b01110000,
	//J
	0b00111000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b00010000,
	0b10010000,
	0b01100000,
	//K
	0b10001000,
	0b10010000,
	0b10100000,
	0b11000000,
	0b10100000,
	0b10010000,
	0b10001000,
	//L
	0b10000000,
	0b10000000,
	0b10000000,
	0b10000000,
	0b10000000,
	0b10000000,
	0b11111000,
	//M
	0b10001000,
	0b11011000,
	0b10101000,
	0b10101000,
	0b10001000,
	0b10001000,
	0b10001000,
	//N
	0b10001000,
	0b10001000,
	0b11001000,
	0b10101000,
	0b10011000,
	0b10001000,
	0b10001000,
	//O
	0b01110000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b01110000,
	//P
	0b11110000,
	0b10001000,
	0b10001000,
	0b11110000,
	0b10000000,
	0b10000000,
	0b10000000,
	//Q
	0b01110000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10101000,
	0b10010000,
	0b01101000,
	//R
	0b11110000,
	0b10001000,
	0b10001000,
	0b11110000,
	0b10100000,
	0b10010000,
	0b10001000,
	//S
	0b01111000,
	0b10000000,
	0b10000000,
	0b01110000,
	0b00001000,
	0b00001000,
	0b11110000,
	//T
	0b11111000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	0b00100000,
	//U
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b01110000,
	//V
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b01010000,
	0b00100000,
	//W
	0b10001000,
	0b10001000,
	0b10001000,
	0b10101000,
	0b10101000,
	0b10101000,
	0b01010000,
	//X
	0b10001000,
	0b10001000,
	0b01010000,
	0b00100000,
	0b01010000,
	0b10001000,
	0b10001000,
	//Y
	0b10001000,
	0b10001000,
	0b10001000,
	0b01010000,
	0b00100000,
	0b00100000,
	0b00100000,
	//Z
	0b11111000,
	0b00001000,
	0b00010000,
	0b00100000,
	0b01000000,
	0b10000000,
	0b11111000,
	//figure1
	0b01110000,
	0b00100000,
	0b01110000,
	0b10101000,
	0b00100000,
	0b01010000,
	0b10001000,
	//figure2
	0b01110000,
	0b10101000,
	0b01110000,
	0b00100000,
	0b00100000,
	0b01010000,
	0b10001000};


//================================ 
//3x5 font numbers, then letters
//packed two per definition for fast 
//copy to the screen at x-position divisible by 4
flash char smallbitmap[39][5]={ 
	//0
    	0b11101110,
	0b10101010,
	0b10101010,
	0b10101010,
	0b11101110,
	//1
	0b01000100,
	0b11001100,
	0b01000100,
	0b01000100,
	0b11101110,
	//2
	0b11101110,
	0b00100010,
	0b11101110,
	0b10001000,
	0b11101110,
	//3
	0b11101110,
	0b00100010,
	0b11101110,
	0b00100010,
	0b11101110,
	//4
	0b10101010,
	0b10101010,
	0b11101110,
	0b00100010,
	0b00100010,
	//5
	0b11101110,
	0b10001000,
	0b11101110,
	0b00100010,
	0b11101110,
	//6
	0b11001100,
	0b10001000,
	0b11101110,
	0b10101010,
	0b11101110,
	//7
	0b11101110,
	0b00100010,
	0b01000100,
	0b10001000,
	0b10001000,
	//8
	0b11101110,
	0b10101010,
	0b11101110,
	0b10101010,
	0b11101110,
	//9
	0b11101110,
	0b10101010,
	0b11101110,
	0b00100010,
	0b01100110,
	//:
	0b00000000,
	0b01000100,
	0b00000000,
	0b01000100,
	0b00000000,
	//=
	0b00000000,
	0b11101110,
	0b00000000,
	0b11101110,
	0b00000000,
	//blank
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	0b00000000,
	//A
	0b11101110,
	0b10101010,
	0b11101110,
	0b10101010,
	0b10101010,
	//B
	0b11001100,
	0b10101010,
	0b11101110,
	0b10101010,
	0b11001100,
	//C
	0b11101110,
	0b10001000,
	0b10001000,
	0b10001000,
	0b11101110,
	//D
	0b11001100,
	0b10101010,
	0b10101010,
	0b10101010,
	0b11001100,
	//E
	0b11101110,
	0b10001000,
	0b11101110,
	0b10001000,
	0b11101110,
	//F
	0b11101110,
	0b10001000,
	0b11101110,
	0b10001000,
	0b10001000,
	//G
	0b11101110,
	0b10001000,
	0b10001000,
	0b10101010,
	0b11101110,
	//H
	0b10101010,
	0b10101010,
	0b11101110,
	0b10101010,
	0b10101010,
	//I
	0b11101110,
	0b01000100,
	0b01000100,
	0b01000100,
	0b11101110,
	//J
	0b00100010,
	0b00100010,
	0b00100010,
	0b10101010,
	0b11101110,
	//K
	0b10001000,
	0b10101010,
	0b11001100,
	0b11001100,
	0b10101010,
	//L
	0b10001000,
	0b10001000,
	0b10001000,
	0b10001000,
	0b11101110,
	//M
	0b10101010,
	0b11101110,
	0b11101110,
	0b10101010,
	0b10101010,
	//N
	0b00000000,
	0b11001100,
	0b10101010,
	0b10101010,
	0b10101010,
	//O
	0b01000100,
	0b10101010,
	0b10101010,
	0b10101010,
	0b01000100,
	//P
	0b11101110,
	0b10101010,
	0b11101110,
	0b10001000,
	0b10001000,
	//Q
	0b01000100,
	0b10101010,
	0b10101010,
	0b11101110,
	0b01100110,
	//R
	0b11101110,
	0b10101010,
	0b11001100,
	0b11101110,
	0b10101010,
	//S
	0b11101110,
	0b10001000,
	0b11101110,
	0b00100010,
	0b11101110,
	//T
	0b11101110,
	0b01000100,
	0b01000100,
	0b01000100,
	0b01000100, 
	//U
	0b10101010,
	0b10101010,
	0b10101010,
	0b10101010,
	0b11101110, 
	//V
	0b10101010,
	0b10101010,
	0b10101010,
	0b10101010,
	0b01000100,
	//W
	0b10101010,
	0b10101010,
	0b11101110,
	0b11101110,
	0b10101010,
	//X
	0b00000000,
	0b10101010,
	0b01000100,
	0b01000100,
	0b10101010,
	//Y
	0b10101010,
	0b10101010,
	0b01000100,
	0b01000100,
	0b01000100,
	//Z
	0b11101110,
	0b00100010,
	0b01000100,
	0b10001000,
	0b11101110
	};
	
//==================================
//This is the sync generator. It MUST be entered from 
//sleep mode to get accurate timing of the sync pulses
//At 8 MHz, all of the sync logic fits in the 5 uSec sync
//pulse
interrupt [TIM1_COMPA] void t1_cmpA(void)  
begin 
  //start the Horizontal sync pulse    
  PORTD = syncON;     
  //count timer 0 at 1/usec
  TCNT0=0;
  //update the curent scanline number
  LineCount ++ ;   
  //begin inverted (Vertical) synch after line 247
  if (LineCount==248)
  begin 
    syncON = 0b00100000;
    syncOFF = 0;
  end
  //back to regular sync after line 250
  if (LineCount==251)	
  begin
    syncON = 0;
    syncOFF = 0b00100000;
  end  
  //start new frame after line 262
  if (LineCount==263) 
  begin
     LineCount = 1;
  end 
  //end sync pulse
  PORTD = syncOFF;  
end  

//==================================
//plot one point 
//at x,y with color 1=white 0=black 2=invert
void video_pt(char x, char y, char c)
begin
	//The following odd construction 
  	//sets/clears exactly one bit at the x,y location
	i=((int)x>>3) + ((int)y<<3) ;  
 	if (c==1) 	screen[i] = screen[i] | 1<<(7-(x & 0x7)); 
  	if (c==0)	screen[i] = screen[i] & ~(1<<(7-(x & 0x7))); 
  	if (c==2)	screen[i] = screen[i] ^ (1<<(7-(x & 0x7)));
end

//==================================
// put a big character on the screen
// c is index into bitmap
void video_putchar(char x, char y, char c)  
begin 
	char j; 
    for (j=0;j<7;j++) 
    begin
        v1 = bitmap[c][j];
        video_pt(x,   y+j, (v1 & 0x80)==0x80);
        video_pt(x+1, y+j, (v1 & 0x40)==0x40); 
        video_pt(x+2, y+j, (v1 & 0x20)==0x20);
        video_pt(x+3, y+j, (v1 & 0x10)==0x10);
        video_pt(x+4, y+j, (v1 & 0x08)==0x08);
    end
end

//==================================
// put a string of big characters on the screen
void video_puts(char x, char y, char *str)
begin
	char i ;
	for (i=0; str[i]!=0; i++)
	begin  
		if (str[i]>=0x30 && str[i]<=0x39) 
			video_putchar(x,y,str[i]-0x30);
		else video_putchar(x,y,str[i]-0x40+9);
		x = x+6;	
	end
end
      
//==================================
// put a small character on the screen
// x-cood must be on divisible by 4 
// c is index into bitmap
void video_smallchar(char x, char y, char c)  
begin 
	char mask;
	i=((int)x>>3) + ((int)y<<3) ;
	if (x == (x & 0xf8)) mask = 0x0f;
	else mask = 0xf0;
	
	screen[i] =    (screen[i] & mask) | (smallbitmap[c][0] & ~mask); 
   	screen[i+8] =  (screen[i+8] & mask) | (smallbitmap[c][1] & ~mask);
   	screen[i+16] = (screen[i+16] & mask) | (smallbitmap[c][2] & ~mask);
    	screen[i+24] = (screen[i+24] & mask) | (smallbitmap[c][3] & ~mask);
   	screen[i+32] = (screen[i+32] & mask) | (smallbitmap[c][4] & ~mask); 
end  

//==================================
// put a string of small characters on the screen
// x-cood must be on divisible by 4 
void video_putsmalls(char x, char y, char *str)
begin
	char i ;
	for (i=0; str[i]!=0; i++)
	begin  
		if (str[i]>=0x30 && str[i]<=0x39) 
			video_smallchar(x,y,str[i]-0x30);
		else video_smallchar(x,y,str[i]-0x40+12);
		x = x+4;	
	end
end
       
//==================================
//plot a line 
//at x1,y1 to x2,y2 with color 1=white 0=black 2=invert 
//NOTE: this function requires signed chars   
//Code is from David Rodgers,
//"Procedural Elements of Computer Graphics",1985
void video_line(char x1, char y1, char x2, char y2, char c)
begin
	char x,y,dx,dy,e,j, temp;
	char s1,s2, xchange;
	x = x1;
	y = y1;
	dx = cabs(x2-x1);
	dy = cabs(y2-y1);
	s1 = csign(x2-x1);
	s2 = csign(y2-y1);
	xchange = 0;   
	if (dy>dx)
	begin
		temp = dx;
		dx = dy;
		dy = temp;
		xchange = 1;
	end 
	e = (dy<<1) - dx;   
	for (j=0; j<=dx; j++)
	begin
		video_pt(x,y,c) ; 
		if (e>=0)
		begin
			if (xchange==1) x = x + s1;
			else y = y + s2;
			e = e - (dx<<1);
		end
		if (xchange==1) y = y + s2;
		else x = x + s1;
		e = e + (dy<<1);
	end
end

//==================================
//return the value of one point 
//at x,y with color 1=white 0=black 2=invert
char video_set((char x, char y)
begin
	//The following construction 
  	//detects exactly one bit at the x,y location
	i=((int)x>>3) + ((int)y<<3) ;  
    return ( screen[i] & 1<<(7-(x & 0x7)));   	
end

//==================================
// set up the ports and timers
void main(void)
begin 
  //init timer 1 to generate sync
  OCR1A = lineTime; 	//One NTSC line
  TCCR1B = 9; 		//full speed; clear-on-match
  TCCR1A = 0x00;	//turn off pwm and oc lines
  TIMSK = 0x10;		//enable interrupt T1 cmp 
  
  //init ports
  DDRD = 0xf0;		//video out and switches
  //D.5 is sync:1000 ohm + diode to 75 ohm resistor
  //D.6 is video:330 ohm + diode to 75 ohm resistor
   
  //init timer 0 to 1/uSec  
  TCCR0 = 2;
  
  //initialize synch constants 
  LineCount = 1;
  syncON = 0b00000000;
  syncOFF = 0b00100000;  
  
  //Print "CORNELL" 
  video_puts(13,3,cu1);
  //Print "ECE476" 
  video_puts(13,91,cu2); 
  
  //Init figure
  figure=0;
  video_putchar(40,75,36);
  
  //side lines 
  video_line(0,0,0,99,1);
  video_line(63,0,63,99,1);
  
  //top line & bottom lines
  video_line(0,0,63,0,1);
  video_line(0,99,63,99,1);
  video_line(0,11,63,11,1);
  video_line(0,89,63,89,1);
  
  //build a fuel gauge
    video_line(5,85,16,85,1);
    video_line(5,40,16,40,1);
    video_line(5,40,5,85,1);
    video_line(16,40,16,85,1);
    
    //Test the numeric chars
    video_putsmalls(4,26,numstr);
    video_smallchar(44,26,10); 
    video_smallchar(48,26,11);
    
   //Test the alpha character set
   video_putsmalls(4,14,alphastr1);
   video_putsmalls(4,20,alphastr2);
   
   //Test the big numbers
   video_puts(2,32,numstr);
   //test big letters
   video_puts(18,40,alphastr3);
   video_puts(18,48,alphastr4);
   video_puts(18,56,alphastr5);
   video_puts(18,64,alphastr6);   		
  //init random num gen
  srand(1);
   
  //init software timer
  t=0;
  time=0;  
  
  //enable sleep mode
  MCUCR = 0b01000000;
  #asm ("sei");
  
  //The following loop executes once/video line during lines
  //1-230, then does all of the frame end processing
  while(1)
  begin
  
    //precompute pixel index for next line
    if (LineCount<ScreenBot && LineCount>=ScreenTop) 
    begin 
       //left-shift 3 would be individual lines
       // <<2 means line-double the pixels 
       //The 0xfff8 truncates the odd line bit
       i=(LineCount-ScreenTop)<<2 & 0xfff8;; 
       
   end
   
   //stall here until next line starts
    //sleep enable; mode=idle  
    //use sleep to make entry into sync ISR uniform time  
       
    #asm ("sleep"); 
     
    //Put code here to execute once/line
    //During the active portion of a line;
    //--TCNT1 goes from about 130 to about 480 
    //--Usable lines 1 to about 240
    
    if (LineCount<ScreenBot && LineCount>ScreenTop) 
    begin
      //load the pixels into registers
      v1 = screen[i]; 
      v2 = screen[i+1];
      v3 = screen[i+2];
      v4 = screen[i+3]; 
      v5 = screen[i+4]; 
      v6 = screen[i+5];
      v7 = screen[i+6];
      v8 = screen[i+7];
        
      //now blast them out to the screen
        PORTD.6=v1 & 0b10000000; 
        PORTD.6=v1 & 0b01000000;
        PORTD.6=v1 & 0b00100000; 
        PORTD.6=v1 & 0b00010000;
        PORTD.6=v1 & 0b00001000; 
        PORTD.6=v1 & 0b00000100;
        PORTD.6=v1 & 0b00000010; 
        PORTD.6=v1 & 0b00000001;
        
        PORTD.6=v2 & 0b10000000; 
        PORTD.6=v2 & 0b01000000;
        PORTD.6=v2 & 0b00100000; 
        PORTD.6=v2 & 0b00010000;
        PORTD.6=v2 & 0b00001000; 
        PORTD.6=v2 & 0b00000100;
        PORTD.6=v2 & 0b00000010; 
        PORTD.6=v2 & 0b00000001; 
        
        PORTD.6=v3 & 0b10000000; 
        PORTD.6=v3 & 0b01000000;
        PORTD.6=v3 & 0b00100000; 
        PORTD.6=v3 & 0b00010000;
        PORTD.6=v3 & 0b00001000; 
        PORTD.6=v3 & 0b00000100;
        PORTD.6=v3 & 0b00000010; 
        PORTD.6=v3 & 0b00000001; 
            
        PORTD.6=v4 & 0b10000000; 
        PORTD.6=v4 & 0b01000000;
        PORTD.6=v4 & 0b00100000; 
        PORTD.6=v4 & 0b00010000;
        PORTD.6=v4 & 0b00001000; 
        PORTD.6=v4 & 0b00000100;
        PORTD.6=v4 & 0b00000010; 
        PORTD.6=v4 & 0b00000001; 
             
        PORTD.6=v5 & 0b10000000; 
        PORTD.6=v5 & 0b01000000;
        PORTD.6=v5 & 0b00100000; 
        PORTD.6=v5 & 0b00010000;
        PORTD.6=v5 & 0b00001000; 
        PORTD.6=v5 & 0b00000100;
        PORTD.6=v5 & 0b00000010; 
        PORTD.6=v5 & 0b00000001;
             
        PORTD.6=v6 & 0b10000000; 
        PORTD.6=v6 & 0b01000000;
        PORTD.6=v6 & 0b00100000; 
        PORTD.6=v6 & 0b00010000;
        PORTD.6=v6 & 0b00001000; 
        PORTD.6=v6 & 0b00000100;
        PORTD.6=v6 & 0b00000010; 
        PORTD.6=v6 & 0b00000001; 
            
        PORTD.6=v7 & 0b10000000; 
        PORTD.6=v7 & 0b01000000;
        PORTD.6=v7 & 0b00100000; 
        PORTD.6=v7 & 0b00010000;
        PORTD.6=v7 & 0b00001000; 
        PORTD.6=v7 & 0b00000100;
        PORTD.6=v7 & 0b00000010; 
        PORTD.6=v7 & 0b00000001;
             
        PORTD.6=v8 & 0b10000000; 
        PORTD.6=v8 & 0b01000000;
        PORTD.6=v8 & 0b00100000; 
        PORTD.6=v8 & 0b00010000;
        PORTD.6=v8 & 0b00001000; 
        PORTD.6=v8 & 0b00000100;
        PORTD.6=v8 & 0b00000010; 
        PORTD.6=v8 & 0b00000001;  
      
        PORTD.6=0 ; 
    end
    
    //The following code executes during the vertical blanking
    //Code here can be as long as  63 uSec/line
    //For a total of 30 lines x 63.5 uSec/line x 8 cycles/uSec 
    // Every 60 uSec or so, you should insert a "sleep"
    //command so that the timer 1 ISR happens at a regular interval,
    //but it may not matter to most TVs
    
    if (LineCount==231)
    begin 
       
 	   //animate the fuel gauge
 	   //erase the old one
 	   gaugeY=84-(t>>1);
 	   video_line(6,gaugeY,15,gaugeY,0);
 	   video_smallchar(8,gaugeY-5,12);  
 	   video_smallchar(12,gaugeY-5,12);
 	   t++ ; // 1/60 second counter
 	   //draw the new one 
 	   gaugeY=84-(t>>1);
 	   video_line(6,gaugeY,14,gaugeY,1);
 	   sprintf(ts,"%03d",(t>>1)); 
 	   video_smallchar(8,gaugeY-5,ts[1]-0x30);  
 	   video_smallchar(12,gaugeY-5,ts[2]-0x30);
 	  
 	   //keep track of seconds    
       if (t > 59)
       begin
       		//erase the last gauge entry  
       		gaugeY=84-(t>>1);
 	   		video_line(6,gaugeY,15,gaugeY,0);
 	   		video_smallchar(8,gaugeY-5,12);  
 	   		video_smallchar(12,gaugeY-5,12);
 	   		
            t=0;
 	   		//inc second count
            time++;
        	//print the time
            sprintf(ts,"%05d",time);
            video_putsmalls(36,83,ts+1);  
            
            //udate figure
            if (figure==0)
            begin
            	figure=1;
            	video_putchar(40,75,37);
            end
            else
            begin
            	figure=0;
            	video_putchar(40,75,36); 
            end
       end   
            
	end  //line 231
  end  //while
end  //main

