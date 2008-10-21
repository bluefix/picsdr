


This is Google's cache of http://forum.sparkfun.com/viewtopic.php?t=3866. It is a snapshot of the page as it appeared on Oct 16, 2008 18:10:53 GMT. The current page could have changed in the meantime. Learn more

Text-only versionThese search terms are highlighted: nokia 6100 screen microchip  
 SparkFun Electronics
MicroController Ideas and Support
   FAQ   Search   Memberlist   Usergroups   Register   
 Profile   Log in to check your private messages   Log in  
 

Nokia 6100 LCD and pic 2520

   
       SparkFun Electronics Forum Index -> Code Snippets 
View previous topic :: View next topic   
Author Message 
Pyrofer



Joined: 04 Aug 2006
Posts: 86
Location: London, UK
 Posted: Fri Aug 04, 2006 6:59 am    Post subject: Nokia 6100 LCD and pic 2520   

--------------------------------------------------------------------------------
 
I stole somebody elses 'good' C code for this lcd, compiled it onto my pic and powered it all up however I just get a blank screen, no different to powering up without the PIC connected. 
My code is almost identicle to the working code show in other 6100 topics, I think they all got cut'n'pasted from the same place. I dont see why it isnt working. 

Oh, as its software SPI I changed it to use the port B pins as id already used all the port A and C ones for other things, would this be a problem? 

Before I get a replacement LCD and test the actual screen itself, can anyone give hints on problems they had with getting this working that I could look into?
_________________
www.pyrofersprojects.com 
 
Back to top        
 
 
orphean



Joined: 14 Jul 2006
Posts: 8

 Posted: Fri Aug 04, 2006 8:05 pm    Post subject:    

--------------------------------------------------------------------------------
 
In my experience often times the screen won't work unless you initililize it repeatedly. 

From the code I'm working on I use: 

Code: 
void lcd_init_full(char color) 
{ 
   int i; 
    
   for(i = 0; i < 50; i++) 
   { 
      output_high(LCD_RESET); 
      output_low(LCD_RESET); 
      output_high(LCD_RESET); 
   } 
    
   for(i = 0; i < 10; i++) 
      lcd_init(0); 
    
   #ifdef LCD_USE_FILL 
      fill(0,0,132,132, color); 
   #endif 
    
   lcd_write(0, DISON); 
   delay_ms(300); 
   lcd_write(0,LCD_NOP); 
} 


The repititions aren't tuned at all so its quite possible it requires far less than 50 reset toggles and 10 full inits  I don't turn the display on during the init process but after it, and after I fill the ram with some color so the random pixel trash isn't visible. 

If that doesn't work I'd verify your pins from the MCU to the display are correct. 

Orpheann 
 
Back to top       
 
 
Pyrofer



Joined: 04 Aug 2006
Posts: 86
Location: London, UK
 Posted: Sat Aug 05, 2006 10:24 am    Post subject:    

--------------------------------------------------------------------------------
 
Thanks, ive already stolen that bit of code from you  

Looking through forums it may be the fact i have a 5v pic with level convertion to 3.3v using resistors. 

Im building a new board using entirely 3.3v so ill test it on that soon. 
Ive also fixed the LCD and sparkfun carrier board directly to my board with header pins instead of a cable, just to eliminate interference on the cable as an issue. 

When ive finished the new board and tested it does what I expect ill see if I can get the LCD into life. 

Look at www.pyrofersprojects.com/3dcube.php to see what Ive done with an old LCD (not as good as this one). When the new LCD works ill get better faster graphics.
_________________
www.pyrofersprojects.com 
 
Back to top        
 
 
Kuroi Kenjin



Joined: 30 Jan 2006
Posts: 523
Location: Cleveland area (Ohio)
 Posted: Sat Aug 05, 2006 12:22 pm    Post subject:    

--------------------------------------------------------------------------------
 
That's really freaking cool!
_________________
my website (Last Updated 5/25/2008 - Bug: noticed that images may not load on first hits) 
 
Back to top          
 
 
Pyrofer



Joined: 04 Aug 2006
Posts: 86
Location: London, UK
 Posted: Mon Aug 07, 2006 1:33 pm    Post subject:    

--------------------------------------------------------------------------------
 
It seems it was either the long cable I had, or the 5v-3.3v convertion as now with the new board running 3.3v and the lcd directly on the board with no cable, it works perfectly. 
Im optimising the startup routine now to remove the repitition but still get a good clean start. 

Transfering my graphics routines to the new LCD. 

A quick note, does anybody POWER DOWN this lcd? 

I had another phone screen and was told you have to do the power down sequence or the screen will die. Users confirmed this and it seems that on at least that LCD failure to shutdown properly will eventualy kill the LCD. 

Ill be adding shutdown code to my routine at least, just in case.
_________________
www.pyrofersprojects.com 
 
Back to top        
 
 
Pyrofer



Joined: 04 Aug 2006
Posts: 86
Location: London, UK
 Posted: Tue Aug 08, 2006 2:22 pm    Post subject:    

--------------------------------------------------------------------------------
 
According to the Datasheet, removing Power without shutting down the LCD will cause damage. 

I put in this routine to shutdown the screen, 

write_lcd(0,DISOFF); 
write_lcd(0,PWRCTR); 
write_lcd(1,00); 
write_lcd(0,NOP); 
write_lcd(0,OSCOFF); 
write_lcd(0,SLPIN); 

Also, There is enough ram to do some sort of double buffer.. 
Set scroll to top of ram, draw image on bottom of ram, then change scroll to bottom. 
Clear and redraw top, and move scroll back to top. 

This would allow flicker free drawing of complex shapes. Has anybody worked out the scroll set commands yet? 

Finally, is there a fast way to clear a large amount of ram? I wanted a simple clearscreen, but all I could find was filling the ram with one colour pixel by pixel routines. 
Even on a 20mghz PIC this takes too long, and is a visible redraw of the screen. It may be acceptable with the double buffering but not at all without it.
_________________
www.pyrofersprojects.com 
 
Back to top        
 
 
orphean



Joined: 14 Jul 2006
Posts: 8

 Posted: Sun Aug 13, 2006 2:32 am    Post subject:    

--------------------------------------------------------------------------------
 
Thanks for the info on the shutdown information. 

I've looked at the scroll information in the data sheet but as of yet have not been able to really play with it. 

I searched and searched through the datasheet for a memcopy routine built into the hardware but I didn't find anything. 

The only way I've been able to get reasonably fast animation is using a solid background and writing over the previous position of my 'sprite' with that solid color. 

Keep us in the loop on your projects!  
 
Back to top       
 
 
Pyrofer



Joined: 04 Aug 2006
Posts: 86
Location: London, UK
 Posted: Mon Aug 14, 2006 1:32 am    Post subject:    

--------------------------------------------------------------------------------
 
There is not enough ram to do full double buffered screens  

You can get 4 pixel block scrolling, but thats it. Not so usefull unless you are writing a scrolling shoot-em up type thing, and even then its blocky scrolling. 

In regards to the solid background I had an idea. 

Mine is a scaled bg, with light at the top and dark at the bottom. The Y value is used to get the brightness of the background colour. When you overwrite an area to 'erase' it, you just use the same fill command that blanked the whole screen, but give it a smaller area to draw. 

I modified a write pixel command to allow erasure of individual pixels with the correct background colour. It looks well cool. 

Ill get some pictures up soon. 

I also thought of using a fifo buffer to redraw. The actual screen can update damn fast, so you could in theory load the drawing commands into a fifo, and then have that dump them into the SPI bus at a much higher rate. 
You could even have a hardware Clearscreen generator with a fixed set of commands, as its only like 4 commands then 18000 repeats of one command, this could easily be done by having the pic send the first commands then triggering an external high speed circuit that generates the SPI data for 'blank pixel' really fast 18000 times.
_________________
www.pyrofersprojects.com 
 
Back to top        
 
 
Pyrofer



Joined: 04 Aug 2006
Posts: 86
Location: London, UK
 Posted: Tue Aug 15, 2006 2:00 am    Post subject:    

--------------------------------------------------------------------------------
 
Ive optimised the pixel write command quite a bit. 
I hope nobody is still using the code that I see posted everywhere full of IF statements, you can remove them totally. 
Replace 

Code: 

IF ( data & 128 ) 
output_high(LCDDATA); 
   else 
output_low(LCDDATA); 
 


with this, 
Code: 

output_bit(LCDDATA&128);     // this works! 
 

Its much nicer code, quicker and shorter. You could probably make a struct with bits defined and store the data in that, so you could do, 
Code: 

output_bit(LCDDATA.8); 
 

for bit 8. I havent done this yet, but it should work a tiny bit quicker than having the & as shown in my working example. 

Also, at the start where its 
Code: 

 if (!LCDmode) 
      output_low(LCD_DATA); //when entering commands: SI=LOW at rising edge of 1st SCL 
   else 
      output_high(LCD_DATA); //send data 
 


You can remove that by putting this instead 

Code: 

output_bit(LCD_DATA,LCDmode); 
 


The final code looks like this, 
Code: 

void lcd_write(char LCDmode, unsigned int data)//mode ==0 send a command, mode==1 sends data 
{  
   output_bit(LCD_DATA,LCDmode); //when entering commands: SI=LOW at rising edge of 1st SCL 
   output_low(LCD_CLOCK); 
   output_high(LCD_CLOCK); 
    
   //send data, 8th bit first 
   output_bit(LCD_DATA&128); 
   output_low(LCD_CLOCK); 
   output_high(LCD_CLOCK); 
 


These optimisations dont look like much, but when you do a clearscreen of 18000 pixels, each one with 9 if statements in them, it slows down quite a bit.
_________________
www.pyrofersprojects.com 
 
Back to top        
 
 
Pyrofer



Joined: 04 Aug 2006
Posts: 86
Location: London, UK
 Posted: Sun Aug 20, 2006 10:02 am    Post subject:    

--------------------------------------------------------------------------------
 
Thought people would like to see what ive done with this screen. 

www.pyrofersprojects.com/3dcube.php 

Full solid object 3D. 

Ive pretty much reached the limits of this display with the SPI bus on a PIC. 
I need to get the drawing data into the LCD quicker than the PIC can output it, so the draw speed will never get better. 

I am hoping to swap to the OLED display that has parallel input as well as a working clearscreen command 
_________________
www.pyrofersprojects.com 
 
Back to top        
 
 
Jello



Joined: 05 Apr 2007
Posts: 3

 Posted: Thu Apr 05, 2007 4:47 pm    Post subject: Font code   

--------------------------------------------------------------------------------
 
Hi everyone, 
Boy! no one posted in here a loooong time! 
Anyone got any good font code for the nokia 6100 lcd (philips controller)? 
thx 
 
Back to top       
 
 
blibot



Joined: 06 Aug 2007
Posts: 11

 Posted: Thu Aug 09, 2007 9:09 am    Post subject:    

--------------------------------------------------------------------------------
 
HI, 

Any font code for NOKIA LCD EPSON?. 

Thank you 
 
Back to top        
 
 
reklipz



Joined: 24 Jun 2006
Posts: 615

 Posted: Tue Mar 04, 2008 9:57 pm    Post subject:    

--------------------------------------------------------------------------------
 
Pyrofer, I'm trying to get this LCD to work with a 2550. 

I've tried using the hardware SPI with the first bit bit banged, and this did not work for me, although others have had success with it. 

I then tried to use software SPI, and my routines are as follows: 
Code: 
void LCD_SendData( unsigned char data ) 
{ 
   int i; 
   LATAbits.LATA2 = LCD_SPI_CLK = 0; 
   LATAbits.LATA0 = LCD_SPI_SDO = 1; 
   LATAbits.LATA1 = LCD_CS = 0; 
   Delay10TCYx( 50 ); 
   LATAbits.LATA2 = LCD_SPI_CLK = 1; 
   for( i = 7; i >= 0; i-- ) 
   { 
      Delay10TCYx( 50 ); 
      LATAbits.LATA2 = LCD_SPI_CLK = 0; 
      LATAbits.LATA0 = LCD_SPI_SDO = data >> i; 
      Delay10TCYx( 50 ); 
      LATAbits.LATA2 = LCD_SPI_CLK = 1; 
   }      
   LATAbits.LATA1 = LCD_CS = 1; 
} 

void LCD_SendCommand( unsigned char command ) 
{ 
   int i; 
   LATAbits.LATA2 = LCD_SPI_CLK = 0; 
   LATAbits.LATA0 = LCD_SPI_SDO = 0; 
   LATAbits.LATA1 = LCD_CS = 0; 
   Delay10TCYx( 50 ); 
   LATAbits.LATA2 = LCD_SPI_CLK = 1; 
   for( i = 7; i >= 0; i-- ) 
   { 
      Delay10TCYx( 50 ); 
      LATAbits.LATA2 = LCD_SPI_CLK = 0; 
      LATAbits.LATA0 = LCD_SPI_SDO = command >> i; 
      Delay10TCYx( 50 ); 
      LATAbits.LATA2 = LCD_SPI_CLK = 1; 
   }      
   LATAbits.LATA1 = LCD_CS = 1; 
} 

The LATAbit setting business is for testing purposes, as are the delays. This should not be an issue, and if anything should make the interface more reliable (as it's slower). 

Since I can't get the LCD to work, I'm running the PIC at 500KHz TCY (2MHz FOSC). 

I've got the proper voltages, and can confirm that the signals are reaching the board properly (they are traversing a 1 foot ribbon cable). 

The only response I see from the LCD is it turning a navy bluish when I apply the backlight (it's always on, before communication begins). Setting the reset line low and high causes no visual response from the LCD, nor does sending it what I believe to be the proper start sequence (or shutdown for that matter). 

Do you still have your working code that I can try? 

Thanks much! 

-Nate 

---- edit ---- 
Here's the sequence I send it at startup (delays are much longer that 100ms, but PIC will be clocked higher in the end): 
Code: 
   LCD_RESET = 0; 
   Delay1KTCYx( 120 ); // 100ms 
   LCD_RESET = 1; 
   Delay1KTCYx( 120 ); // 100ms 

   LCD_SendCommand( DISCTL ); 
   LCD_SendData( 0x00 ); 
   LCD_SendData( 0x20 ); 
   LCD_SendData( 0x00 ); 
    
   LCD_SendCommand( COMSCN ); 
   LCD_SendData( 0x01 ); 
   LCD_SendCommand( OSCON ); 
   LCD_SendCommand( SLPOUT ); 
   LCD_SendCommand( VOLCTR ); 
   LCD_SendData( 28 ); 
   LCD_SendData( 0x03 ); 
   LCD_SendCommand( PWRCTR ); 
   LCD_SendData( 0x0F ); 
   LCD_SendCommand( DISINV ); 
   LCD_SendCommand( PTLOUT ); 
   LCD_SendCommand( DATCTL ); 
   LCD_SendData( 0x00 ); 
   LCD_SendData( 0x00 ); 
   LCD_SendData( 0x02 ); 
   LCD_SendCommand( NOP ); 
   Delay10KTCYx( 120 ); 
   LCD_SendData( DISON ); <<--------- :)!!!!!!!!!!! 
    
   LCD_SendCommand( PASET ); 
   LCD_SendData( 50 ); 
   LCD_SendData( 100 ); 
   LCD_SendCommand( CASET ); 
   LCD_SendData( 50 ); 
   LCD_SendData( 100 ); 
    
   LCD_SendCommand( RAMWR ); 

   // loop on total number of pixels / 2 
   for (i = 0; i < 1300; i++) 
   { 
      // use the color value to output three data bytes covering two pixels 
      // write random crap for now... 
      LCD_SendData(0xFF); 
      LCD_SendData(0x80); 
      LCD_SendData(0x80); 
   } 


edit again!! 

After reviewing my post, I noticed this line: LCD_SendData( DISON ); 

Changed it to LCD_SendCommand( DISON ); and VIOLA! It works! 

I'm so happy! 
 
Back to top       
 
 
Display posts from previous: All Posts1 Day7 Days2 Weeks1 Month3 Months6 Months1 Year Oldest FirstNewest First  
 
       SparkFun Electronics Forum Index -> Code Snippets All times are GMT - 7 Hours
 
Page 1 of 1 

 
 Jump to: Select a forum Orientation----------------Start Here AVR Atmel----------------AVR ProgrammersCode PIC Microchip----------------PIC Programmers - Software and HardwareCode SnippetsBoot LoadingUSB Development MSP Texas Instruments----------------MSP Programmers ARM / LPC----------------Everything ARM and LPCOpenOCD General Discussions----------------New Product IdeasProjectsSparkFun Site Questions/CommentsWireless/RFPCB Deal DetailsPCB Design QuestionsGPS  

You cannot post new topics in this forum
You cannot reply to topics in this forum
You cannot edit your posts in this forum
You cannot delete your posts in this forum
You cannot vote in polls in this forum
 



Powered by phpBB © 2001, 2005 phpBB Group
 





Controlling a Nokia 6100 Display with an Atmel-AVRHow to connect a Nokia LCD to a AVR-Controller. > Diese Seite auf Deutsch <
 
The Display (which is used in Nokia 6100, 7210, 6610, 7250 and 6220) has a resolution of 132x132 Pxieln @4096 Colors. The visible area is about 3cm x 3cm in size. It can be found cheap at *bay. Note that there exist two types of Displays:
Green PCB: Epson S1D15G10 Chipset Orange/Brown PCB: Philips PCF8833 Chipset The provided Software does only work with Displays with the Philips chipset. If you want to use a Display with S1D15G10-chipset, take a look here. 
HardwareI have used a AVR ATMega8 to control the Display.
The display works at 3,3V. I use a voltage divider (1.8k, 3.3k to GND) to convert the 5V signals of the controller to 3,3V levels for the display. 
I directly soldered a ribbon cable on the back side of the display.
 
Pinout and connection to AVR:
1 VDD 3,3V   
2 /Reset PB4 
3 SDATA PB3 
4 SCLK PB5 
5 /CS PB2 
6 VLCD 3,3V   
7 NC   
8 GND   
9 LED-   
10 LED+ (6V)   
11 NC   
no responsibility is taken for the correctness of this information.
TestWith the 8-Bit AVR Microcontroller i have build a rainbow-Animation, a simple oscilloscope and a Wireframe-3D-Engine:
 
 
 
SoftwareThe Software can be compiled with AVR-GCC. It display a test picture first.
It is possible to upload a RAW-RGB-Image-File via the serial interface.

 
 
 
 
nokia_6100_display_test.zip (41 KB) - 
Philips PCF8833 Datasheet
Epson S1D15G10 Controller, with an ATMEL AVR ATMega32L
Tags: Nokia tft display 3000 6100 7210 6610 7250 6220 AVR Mikrocontroller Projekte Projekt uC diy selbstbau tutorial µC selbstgebaut schaltung schaltplan schema schematic programmierung elektronik controller Atmel embedded Atmega8
 Permalink: http://thomaspfeifer.net/nokia_6100_display_en.htm
© 2008 Thomas Pfeifer

           
 





Here I made the square with one color!


Here is the part of code that makes the square

// draw a multi-colored square in the center of screen
for (i = 0; i < 4096; i++){
LCD_put_pixel(i, (i % 64) + 32, (i / 64) + 32);
} 
The new written code uses the GNU-GCC AVR compiler, so you don’t have to buy it you can just download it, it is free. Long live the GNU, HIP HOP HUREY, HIP HOP HUREYYY ?. It is still under development but works fine, you can download the code and play with it. Good luck with it.

You can download the LCD Code here. 

Entry Filed under: Electronics, DIY

85 Comments Add your own
1. Richard  |  |  February 17th, 2006 at 5:45 pm
Slight oversight in your schematic - the reset switch in this location will actually short out the voltage regulator! Pin 2 of the switch should be connected the other side of the pull-up resistor. 

2. Refik  |  |  February 17th, 2006 at 7:31 pm
Dear Richard,
Thank you for the comment! However I checked it twice and it is fine, I cheked AVR schematics on other web sites as well. Maybe my schematic drawing is bad and it looks that it is a short circuit but it is not. Anyways thank you for checking it  … 

3. Art  |  |  February 20th, 2006 at 7:41 pm
I got one for ya. I have a friend’s old motorolla cell and I believe it is a cameraphone. Any clues on how to go about interfacing that?

thanks 

4. refikh  |  |  February 21st, 2006 at 12:33 pm
Huh, that one might be hard. You have to find the datasheet of its controller (LCD controller) and see if it is hard to interface it. If it is not you should give it a try. However I recommend you to play with LCDs you can find on the market and buy easily like this one, you will find on the internet other people using it as well. Thanks for the comments Art  . 

5. philipp  |  |  February 24th, 2006 at 2:24 pm
hello
i just want to make a soo soo simple homemade water heater but i dont know bout that
i think thats easybut i dont know.
thanks
where can i found a site about that. 

6. Refik  |  |  February 24th, 2006 at 6:29 pm
Dear Philipp,
Not sure if I can help you there out but did you try to look for Peltier elements?? Look for it on google, maybe it is the next step in your project. Good luck! Thank you for the comments 

7. mo_akbari  |  |  February 26th, 2006 at 10:08 am
hi:
please mail:
Controlling a color graphic LCD, Epson S1D15G10 Controller, with an ATMEL AVR ATMega32L 

8. De4Th  |  |  March 4th, 2006 at 11:22 pm
hi, maybe can u upload compiled script? :/ my C++ skill is low :/ thx, if u can send me via email. big thanks!
:) 

9. tom  |  |  March 5th, 2006 at 1:15 am
do you think it’s possible to seperate the lcd from it’s backlight safely?
that would make it vey useful in combination with a slide projector ,
pretty much the size of a slide. 

10. Andrew  |  |  March 5th, 2006 at 3:54 am
now make it again using a SMT Mega32L and make a watch!

:P

–neg 

11. Long Nguyen  |  |  March 5th, 2006 at 5:35 am
I think you’d better drive a driver for the LCD and include it into the Code field. Then it can display any thing you want 

12. LNguyen  |  |  March 5th, 2006 at 5:37 am
I think you’d better drive a driver for the LCD and include it into the Code field, then it can display anything you want 

13. Andre  |  |  March 5th, 2006 at 2:46 pm
Pretty neat  I’ve got some Samsung E700 OLED displays here, has anyone had any success in getting these to work?

-A 

14. osha  |  |  March 5th, 2006 at 3:03 pm
i want to test some image (my own picture ) on lcd how i can add it on my code?

i work with lpc21xx 

15. [ Bronx Webblog ] »&hellip  |  |  March 6th, 2006 at 1:18 am
[…] Vielleicht wollen die einen oder anderen ja mal ein kleines LCD in Ihren Rechner basteln oder haben anderweitig für ein LCD Verwendung. Verdrahten der Hardware ist ja schön und gut, aber wer schreibt denn bitte mal einen ausführlichen Workshop darüber, mit welchem gecode man direkt solche Displays ansprechen kann. Gibts es mittlerweile nicht sogar schon Bausätze für die Displays? …naja, etwas ist ja immer! Viel Spass beim lesen… […] 

16. Gasper  |  |  March 6th, 2006 at 6:58 am
Hi, 

I was wondering if there was a way to take this lcd, and mirror the lcd from an ipod. I already have an ipod hookup in my car, but I would like to install a tiny lcd at eye level, so i could see the ipod screen and still focus on driving.

any ideas?

thanks 

17. refikh  |  |  March 6th, 2006 at 5:19 pm
Dear De4Th,
you can get the compiler that compiles this code at this address. If you have any troubles downloading it let me know and we will arrange something. 

18. refikh  |  |  March 6th, 2006 at 5:20 pm
Dearm Tom and Gasper,
I haven’t tried it yet, I am not sure if it can be done but a great idea to try it  . 

19. refikh  |  |  March 6th, 2006 at 5:25 pm
Dear Osha,
I would use the USART that comes embedded within most AVR microcontrollers and send from the PC each pixel’s color value. A suggestion would be to make a software that automatically does it for you! 

20. refikh  |  |  March 6th, 2006 at 5:26 pm
Bronx Vielen Dank fuer den Link  

21. johnny  |  |  March 7th, 2006 at 12:09 am
I was going to extend the wire leads on an lcd display for a digital video camera to make the viewfinder into a monacle. do you think i will run into resistance issues extending it from 5 inches to about 3 feet? 

22. tiago  |  |  March 7th, 2006 at 12:46 am
is it possible to connect a mobile phone lcd to a pc so it can be used as a small monitor? thanx 

23. bryon  |  |  March 7th, 2006 at 6:54 pm
Hi,
Have a look at this site: http://www.display3000.com/html/with_muc.html

The have color (65k), 132×132 displays that have integrated AVRs. Commands are sent serially.

They have great prices too. Around $70 for the ATMega8 equipped display.

Oh, I am not affiliated with them. 

24. osha  |  |  March 10th, 2006 at 3:49 pm
in spark fun code example what the meaning of the pagset,caset

and what mean this:
spi_command( PASET ); /* page start/end ram */
spi_data( 2 ); /* for some reason starts at 2 */
spi_data( 131 );

and:

spi_command( CASET ); /* column start/end ram */
spi_data( 0 );
spi_data( 131 );

2)what the meaning of p17,p16,p14,p….,p10

in pageset ,?

thanks 

25. osha  |  |  March 10th, 2006 at 11:56 pm
another Q:

ABOUT WHAT # OF iterations INDICATE:
for(i = 0; i 

26. osha  |  |  March 10th, 2006 at 11:57 pm
for(i = 0; i 

27. SpazGhost  |  |  March 12th, 2006 at 6:17 am
Would it be possible to use something like this hooked to a gumstik like device? You’d have a really interesting little server on your hands with something like that. 

28. F. Eko Mujiyono  |  |  March 20th, 2006 at 5:09 am
I have an erstwhile LCD from Toshiba tecra 8100, Can I use for something useful. I like to use to watch TV or Video. Is any device I can built bu my own to drive this trash? 

29. osha  |  |  March 29th, 2006 at 10:32 pm
i have problem in lcd please any one solve it quiqly:

i bought lcd from sparkfun and i have lpc2138
and when i test code from spark fun there is no any aoutput on lcd ,the only color display on lcd is blue(backlight)

what problem ? 

30. refikh  |  |  April 4th, 2006 at 5:22 pm
Dear Johnny,
I am not sure if you will have issues with the resistance. The only way you will find it out is to check it yourself. 

Hey Tiago,
it can be done but I guess it will require some good coding skills  .

Hey Osha,
I think the code is well documented. 

SpazGhost,
I love your idea, I had something similar in mind to make some really neat ARM application with uClinux  , would be lovely!

Dear Mujiyono,
I guess it can be done, however you will need to find the datasheet for that LCD. Watching TV or Video could be done however I believe most of us would get stuck with encoding the signal to something useful for the LCD. 

Hey osha,
I am not sure about your problem. Did you ask on sparkfun forum? I haven’t played with the LPC2138, but blue means power is there. Check how you wired it and if the signal is being sent correctly! Not sure how to help you really… 

31. Richard Cooke  |  |  April 29th, 2006 at 12:18 am
I’m new to the AVR parts and I don’t quite see how you managed to use the SPI port to talk to the Epson controller chip since according to the datasheet it is expecting a 9 bit serial stream and the AVR works in 8 or 16 bits.

Thanks,

Richard 

32. Last » Blog Archive&hellip  |  |  May 21st, 2006 at 12:13 pm
[…] Controlling a color graphic LCD, Epson S1D15G10 Controller, with an ATMEL AVR ATMega32L […] 

33. Gabriele Giottoli  |  |  May 30th, 2006 at 10:11 am
Hi,

Iìm testing nokia lcd with epson controller with a pic 18f4520
20 Mhz and initially all is good. after two days display is frozen.

I tried other two display and … nothing.

All connections are good. 

I changed some instruction in the init process. 

There is anyone with my problem ? I think that may be an eprom/ram misconfiguration.

Thanks in advance.
GG 

34. Badshah  |  |  June 22nd, 2006 at 5:20 am
Salam (peace)
I am searching for a library which would enable the use of more complex display patterns on these type of graphic LCD displays.
Did you make your own library or were you able to get it from someplace?
keep up the good work,
regards
Badshah 

35. Mayank Mevada  |  |  July 5th, 2006 at 1:54 pm
Hi,
Its good.
Plz share information with others. Do u interface it with 8052? 

36. Kiranjeet  |  |  July 6th, 2006 at 11:05 am
I’m not able to download the zipped code file from this site. can somebody be kind enough to forward it to me… 

37. hadi  |  |  July 25th, 2006 at 6:26 am
Hi
please mail:
controling lcd1*16 and lcd 64*128 in avr studio 

38. RT  |  |  July 31st, 2006 at 1:22 pm
i have one “dallas maxim DS80C410? 8-bit micro controller. is it possible for me to work on any nokia models as said above? 

39. kal-el  |  |  August 27th, 2006 at 9:43 am
i’m looking aroung the net to help me in my thesis i need to run a colored graphic lcd using a picMICRO can you give me a site that would help me in creating my program

can you give me an idea of the cheapest graphic lcd where i can display a picture and the name and would it be possible to interface a hardisk to a pic so that i would be able to use a large database???

hoping to see your reply

thanks in advance 

40. Ronaldo  |  |  September 14th, 2006 at 1:53 pm
osha,
Can you get to work your lcd sparkfun.and lpc2138?
I worked LCD 6100 and sparkfun pcb with LPC2106. 

41. upesh Patel  |  |  September 22nd, 2006 at 1:31 pm
send me circuit of color lcd interface with
atmega32 

42. atomic  |  |  September 29th, 2006 at 11:55 pm
I’m a total newb at this. Can any one help me find a good microcontroller for this project?? Please leave a link, I’m a total newb 

43. Jasper  |  |  September 30th, 2006 at 2:17 pm
Hello there! Wonderful little doodad this LCD. Maybe you can answer one question for me! I cannot get this LCD working but I’m wondering if my pinout is correct. I have the backlight on what I THINK is pin 9 and 10 (9 is - and 10 is +)

THere are tiny little silkscreen numbers on the LCD connector (the one ON the lcd, yea, that TINY one) that give pin 1, 5, 6 and 10. The pinouts on sparkfun lack a drawing to show which pin is which. Any ideas? do I have to enable the backlight in software?
thanks! 

44. Jasper  |  |  September 30th, 2006 at 2:18 pm
Sorry I should have specified that the backlight does NOT light for me with 5-7 volts on pins 9,10 

45. mohammad  |  |  October 9th, 2006 at 1:56 pm
hi
PLZ send this document to my Email.
PLZ send me Graphic Display Driver/C sorce code
to:
olala_1364@yahoo.com
tanQ 

46. Nek Debaggio  |  |  October 10th, 2006 at 8:29 pm
Dear Refik, 

Could you play mpeg(video) on the Nokia LCD 6100 with Epson S1D15G10 Controller that you used above. I am trying to read an mpeg file(video) from flash memory and then play it on the LCD. Any ideas anybody? 

47. dav7  |  |  November 17th, 2006 at 3:51 pm
Hi all,

I have been mentally noodling an idea to make a really really tiny PC (like a little over 2×1 inch) with an LCD touchscreen. I would like it to have an OS and run little apps and all that sort of thing. I don’t expect any of it to be easy but I am willing to try. I just need some help with where to actually start…

(please send any comments to asmqb[at]bigpond.com and replace the [at] with a real at sign.)

thanks in advance. 

48. funkey  |  |  November 29th, 2006 at 2:11 am
hi all,
I have got a nokia 7620’s lcd,i wanted to driver it with 89C52..
Anybody know the IC driver?is it also the enpson’s IC? 

49. soory  |  |  December 10th, 2006 at 9:53 am
I have a project with atmega128
i want to play grafic lcd 128X64
please guide me 

50. Optixx » Blog Archi&hellip  |  |  January 6th, 2007 at 11:52 pm
[…] Finally i threw some code together using the init commands found in this project. Added support for receiving images via uart and wrote an little python client for sending images. […] 

51. atryd  |  |  January 7th, 2007 at 1:53 am
anyone tryed to interface lcd from any type of Pocket Pc - they are cheep now and to get lcd wouldn’t be a problem  the main thing is how to do anything on them - displaying a picture for example like on picture frame 

52. mochen  |  |  February 6th, 2007 at 10:30 pm
tanks 

53. Anand  |  |  February 8th, 2007 at 12:04 am
hi, I wanted to know in the circuit what does IC2 represent? is it voltage regulator? also, what is the range of the load resistor R1? 

54. homerus  |  |  February 19th, 2007 at 9:14 pm
Hey guys,
Any of you knows if it is possible to connect such an lcd to my laptop, in order to run it as a sidshow monitor?
cheers 

55. Anand  |  |  February 19th, 2007 at 11:13 pm
Can anybody help me with this error that I found after compiling the code with CodeVisionAVR.

Error: …code\MyLCD\headers\headers.h(7), included from: test.c: can’t open #include file: macros.h

Error: …code\MyLCD\Source\test.c(1): the program has no ‘main’ function 

56. MANOJ  |  |  February 23rd, 2007 at 2:52 pm
hi,
i am trying to interface lpc2129 with pcf8833 for nokia 6610 graphical lcd. is it possible to use built in SPI of lpc2129? or shall i go for GPIO pins?

please help me ,
thanks ,
manoj 

57. farzad  |  |  February 25th, 2007 at 8:46 pm
hi
i wanna drive a graphic lcd by ATmega32 OR 16 (by codevision software).please help me. 

58. zoamoar  |  |  February 28th, 2007 at 10:17 pm
is the connector the same as in the picture of thomas pfeifer?
http://thomaspfeifer.net/nokia_display_6.jpg

Thomas has the philips chip, and I have the epson chip, like this page. 

59. stanly  |  |  March 3rd, 2007 at 6:13 pm
Helloo all
I just try to puting image to lcd as atmel but i cant succes yet only i just see lcd light is on
i m not thinking there are any wrong about code. i just use 8952 familiy i just using kiie c .
but i m not sure about connections
1 VCC-Digital (3.3V)
2 RESET
3 SDATA
4 SCK
5 CS
6 VCC-Display (3.3V)
7 N/C
8 GND
9 LED GND
10 LED V+ (6-7V) 

i just used this connection
could you pls say i m wrong or not about connection 

60. Pulak  |  |  March 12th, 2007 at 11:07 am
need color display of 4'’ by 3'’ in size with full module like controller/ connector / base etc for making some experience with display. plz. give some advice.

mail me
pulakpurkait@gmail.com 

61. ali  |  |  March 16th, 2007 at 12:52 pm
please send me 

software +pcb for contoroling a color graphic lcd 

62. sarathy  |  |  April 4th, 2007 at 12:21 pm
Hello to all
i am trying to work out the graphical icd with controller ic T6963c.
i’m sure about my coding but not sure in proper initializing. plz tell how to do it?
Thanks 

63. Jello  |  |  April 5th, 2007 at 11:25 pm
Hi,
Nice work!
I am also using the SparkFun break out board using Header1.
Did anyone using this breakout board have to set the jumpers to get it to work?
Thanks! 

64. Montoya  |  |  April 10th, 2007 at 7:36 am
Jello: No, if you test the jumper sockets you will find that they are already jumped. Just make the connections on Header1 and you should be able to get a working display.

e-dsp, could you explain the indexing scheme you used for colors? It seems like there are 256 colors but I don’t know how to tell what’s red, blue and green. I’ve been using trial & error to find colors. 

65. T Bush  |  |  April 18th, 2007 at 2:47 am
Greeting! I envy your ability to do this kind of stuff and had a question I thought one of you might be able to answer. Is it possible to make one of these with a simple ‘video in” for viewing images? 

66. praveen  |  |  April 24th, 2007 at 12:03 pm
hi,

i’m trying interface GLCD with atmega16/32. pls, anybody send me documents and code library for this. thanks. 

67. koosh  |  |  May 3rd, 2007 at 7:48 am
Hi can anyone send me full shematic and code for atmega 32 by mail thanks 

68. praveen  |  |  May 6th, 2007 at 6:44 am
please send me 

software +schematics for contoroling a color graphic lcd with atmega32/128

praveen_cpp@yahoo.co.in 

69. Marius  |  |  May 7th, 2007 at 12:53 pm
please send me

software +schematics for contoroling a color graphic lcd with atmega32/128

cj04vsv@yahoo.com 

70. kool  |  |  May 10th, 2007 at 8:35 am
Hi can anyone send me full shematic and code for atmega 32 by mail thanks ——– s3140675@yahoo.com.au 

71. aida  |  |  May 17th, 2007 at 7:47 am
hi,i would like to ask if you have any codes generated using mikroc software for the nokia 6100 lcd..and do you have the software to transfer images into codes? 

72. bharat  |  |  May 29th, 2007 at 11:30 pm
i am using the atmega16 for lcd interface and using the code given above .but i am not getting the display of square in lcd .can anybody tell me what to do 

73. Nordin  |  |  May 30th, 2007 at 3:14 pm
Hello friends,

Where can I find a connector or like some people say “breakout box” for the 6100 lcd? I have a bunch of those lcd’s, but don’t have something to connect it to my uC r8c/13.

If some guys want to put images on the lcd, the fastest and easiest way is to copy a 16 bit image bmp data to your source. You need to remove the overhead that belongs to the bmp file-layout and that must do the trick.

But a more proffessional way is be able to read from an SD card and than display the image. To make it possible to write or read data to/from the SD card, you can find a lot of stuff on this link: http://elm-chan.org/fsw/ff/00index_e.html 

74. sunny  |  |  May 31st, 2007 at 6:45 pm
HI is there any way you can make a video controller board for a 1.8? xga lcd panel. i have an xga panel but need a controller board through which i can feed images. 

75. Guru  |  |  June 2nd, 2007 at 2:20 pm
Hey guys,
If you haven’t noticed Refikh stopped replying April 4th 2006. You aren’t going to get your answers here right now. And you seriously need to stop spamming the comments -_-. I, too, have a problem with getting the lcd to work, the backlight is turning on, but the square won’t appear. But I’ll figure it out eventually. And also, almost half of your demands are for code and schmatics. Its on the site itself and i downloaded it fine so either you are a n00b, or you are… a n00b. Figure it out yourselves. 

76. loeto  |  |  June 5th, 2007 at 10:23 am
Trying to use nokia knock lcd display and the Atmega32 but its me hard time,can anyone help me with this 

77. manfredi  |  |  June 12th, 2007 at 7:25 pm
cool 

78. vikram  |  |  July 6th, 2007 at 8:22 am
HELLO SIR ..
I HAVE GONE THRU ALL THE DETAILS GIVEN BY U ABT NOKIA LCD…
ITS REALLY HELPFULL
I HAVE WRITTEN MY CODE TO DIPLAY SOME GRAPHICS ON IT..
BUT I CANT FIND THAT DELAY.H HEADER FILE
CAN U PLEASE MAIL ME THAT …
AND ONE THING MORE I AM USING ATMEGA16 ….
SO IS THERE ANY DIFFERENCE IN THE CODE..
PLZ REPLY………

MY E-MAIL ID IS … vicky.rkn@gmail.com 

79. mekdes  |  |  July 12th, 2007 at 3:46 pm
when we interface the LCD with atmega32 at stk500 board the LCD does’t powered on but we program our atmega32 what is the reason behined the LCD for not powering ON please tell me 

80. Interfacing Nokia 6100 co&hellip  |  |  August 5th, 2007 at 10:13 pm
[…] As there are two types of displays: with Epson chipset(S1D15G10) and Philips(PCF8833), he wrote code for Philips chipset. Firmware is written in AVR-GCC language where image can be uploaded via serial cable. Also there are few videos view sample video on how it works AVR-3D-Engine. […] 

81. Karl Kristian Markman  |  |  September 4th, 2007 at 8:25 am
How to tell if there is a Epson or Phillips chipset on it ?? 

82. Mori Nice  |  |  September 6th, 2007 at 3:09 pm
Hi. please help me at Graphic Projects. Very Thanks 

83. rawan  |  |  September 27th, 2007 at 9:39 am
how to build circuit that control the traffic light 

84. Nickolay  |  |  October 1st, 2007 at 5:07 pm
I can’t see where are the values of C1, C2 and R1 if you please can tell me. Thanks 

85. manu  |  |  October 2nd, 2007 at 2:19 pm
Sir,
I am trying to interface Nokia 6610 LCD with LPC2129(ARM 7)
Cav u please give me the example code if you have….

thanks&Regards
manu 

Leave a Comment
Name  Required

Email  Required, hidden

Url 
Anti-spam word: (Required)*
To prove you're a person (not a spam script), type the security word shown in the picture. Click on the picture to hear an audio file of the word.
  


Comment 

 
 
Some HTML allowed:
<a href="" title=""> <abbr title=""> <acronym title=""> <b> <blockquote cite=""> <code> <em> <i> <strike> <strong> 

Trackback this post  |  Subscribe to the comments via RSS Feed

--------------------------------------------------------------------------------
Send to a friend
 xSend to a Friend:
Your name:
Your email:
Friend name:
Friend email:
  Send to a friend: 
Most Recent Posts
How to build your own heart monitoring device, a simple ECG? 
How to manufacture your own PCB cheaply? 
How to build your own wireless receiver and transmitter device? Use RF in your next embedded application design! 
How to measure temperature with the Dallas Maxim DS1820 sensor? 
Controlling a color graphic LCD, Epson S1D15G10 Controller, with an ATMEL AVR ATMega32L 
How to use a LCD with your electronic devices? 
Software Function/Signal generator 
Why do we need Amplifiers? How to build a simple one? LM 741 
What are Fourier Coefficients and how to calculate them? 
What are Fourier series? Basic introduction to Fourier series... 

--------------------------------------------------------------------------------
