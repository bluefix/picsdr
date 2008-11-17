

#include <stdio.h>
#include <delay.h>
#include <90s8515.h>
#include <stdlib.h>   
#include <math.h>

//Maximum coordinates for x and y direction
#define ymax 127
#define xmax 255

//Initial settings for options
#define initspeed 4
#define initsize 3
#define initscore 10

//The states used in the state machine
#define menu 1		//menu screen
#define option 2	//options screen
#define play1 4		//1 player mode
#define play2 6		//2 player mode
#define paused 8	//Pause game during game
#define gamedone 9	//Game done screen once game is over

// LCD Control lines (PORTC)
#define	LCDreset        0x00    // Reset the Display
#define	LCDnop          0x47    // No operation
#define	CmdSetup        0x47    // Set A0 high
#define	CmdWrite        0x43    // Set WR low
#define	DataSetup       0x07    // Set A0 low
#define	DataWrite       0x03    // Set WR low
#define	StatusRead      0x05    // Set RD low, A0 low
#define	DataRead        0x45    // Set RD low, A0 high

// LCD Commands (PORTD)
#define	SystemSet	0x40	// Initialize system
#define	SleepIn		0x53	// Enter standby mode
#define	DispOFF		0x58	// Display Off
#define	DispON		0x59	// Display On
#define	Scroll		0x44	// Initialize Address & Regions
#define	CSRForm		0x5D	// Set cursor type
#define	CharAddr	0x5C	// Set address of character RAM
#define	CSRRight	0x4C	// Cursor direction = right
#define	CSRLeft		0x4D	// Cursor direction = left
#define	CSRUp		0x4E	// Cursor direction = up
#define	CSRDown		0x4F	// Cursor direction = down
#define	HorzScroll	0x5A	// Set horz scroll position
#define	Overlay		0x5B	// Set Display Format
#define	CSRW		0x46	// Set cursor address
#define	CSRR		0x47	// Read cursor address
#define	MWRITE		0x42	// Write to display memory
#define	MREAD		0x43	// Read from display memory	

#define TextAddress     0x0000  // Character layer base address
#define GraphicsAddress 0x03E8  // Graphics layer base address = 1000

// LCD Subroutines 
void WriteCMD(unsigned char CommandCode);	//write command
void WriteDATA(unsigned char CommandCode);      //write command parameters
void clearLCD(void);                            //clear LCD
void clearText(void);

void butcheck(void);				//Checks which button has been pushed
void initialize(void);				
void mainmenu(void);				//sets up menu screen
void options(void);				//sets up options screen
void gamescreen(void);				//sets up game screen
void game(void);      				//does game checks during game play
void pausescreen(void);				//sets up the paused screen
void drawball();				//draws ball according to ballx,bally
void eraseball();				//erases ball according to ballx,bally
void drawline(int, int); 			//draws a line on either side of the screen
void textPos(int, int); //col, row		//sets up position of cursor to write text
void letterWrite(char);				//prints out a letter to the LCD
void wordWrite(char, char, char, char);		//prints out 4 letters to the LCD
void disInt(char);				//prints out an integer or character to the LCD
void eraseline(int, int);			//erases a line on either side of the screen
void donescreen();				//The game over screen indicating the winning player

char clkon;		//indicates whether clock signal to controller is on or off
char clkcnt;		//keeps count of how many times the clk signal has been inverted
char str;		//keeps count of how many times the strobe signal has been inverted

int i;
int pos;		//keeps position on the LCD screen of where to print
unsigned char pos_lo;	//keeps low byte of pos
unsigned char pos_hi;	//keeps high byte of pos

unsigned char nint;	//keeps the current reading of control 1's button during the clock signal
unsigned char nint2;	//keeps the current reading of control 2's button during the clock signal
unsigned char state; 	//keeps the current state of the state machine
unsigned char tstate;	//temporary storage of the current state of the state machine

int but;		//keeps current button push of control 1
int but2;		//keeps current button push of control 2
int eitherbut;		//tells whether a button on either control was pushed
int oldbut, oldbut2, butbak, butbak2;	//These were used to debounce the controllers
int beep;		//makes the speaker beep if there is a paddle hit by turning on timer 1
int showscore;		//will make the program display the current score for a certain period of time
char random;		//used to generate random numbers
int players; 		//indicates the number of players           
int score1, score2;	//Keeps the score for the respective player
char size;		//size of the paddle
char winscore;		//score needed to win the game
float ballx, bally	//current coordinates of ball
float oldballx, oldbally, newballx, newbally;	//These variables are used to minimize the flicker on the LCD
int speed, speedx, speedy;	//speed of the ball, and in the specified directions
int dirx, diry;			//direction the ball is currently going
int paddle1, paddle2;		//position of both paddles
int tpaddle1, tpaddle2, tballx, tbally, tdirx, tdiry; 	//storage variables used during the pause option
int mainoptionselected;		//tells which option is currently selected in the menu
int optionselected;		//tells which option is currently selected in the options screen
int pauseoption;		//tells which option is currently selected in the pause screen
int waitcont;			//makes program wait for button push
char butready;			//indicates if button is fully read from the controller
char ballmove;			//flag indicating program to move the ball
char ball;			//counter to set up the ball speed

/*Timer0 overflow interrupt is used to set up a 1 msec time base for the program.
It is also used to invert the appropriate clock and strobe signals going to
both controllers and then reading the data pins from both of the controllers.
It also sets a flag high when it is time for the ball to make its next move. The button pushes
can be read every 125 msec which is enough time in between.  */
//Strobe = PORTB.0
//CLOCK = PORTB.7
//Data for 1st controller = PINA.0
//Data for 2nd controller = PINA.7

interrupt [TIM0_OVF] void timer0_overflow(void)
  {       
  TCNT0=256-62;
  if (++ball == 25) ballmove = 1;
  
  if (butready == 0) {
  if (clkon == 0) {	
  	if (PORTB.0 == 1) PORTB.0 = 0;
    else PORTB.0 = 1;  
  	if (++str == 2) {	//reads in first bit of the controllers after strobe is done
  		str = 0;
  		clkon = 1;
  	  	but = (!PINA.0);
  	  	but2 = (!PINA.7);
  	  	but = but << 6;
  	  	but2 = but2 << 7;
  		nint = (nint >> 1) | but;
  		nint2 = (nint2 >> 1) | but2;
  	}               
  }
  else {               		//reads in rest of the bits when clock has gone high
  	if (PORTB.7 == 1) PORTB.7 = 0;
    else PORTB.7 = 1;          
    if (PORTB.7 == 1) {
    	but = (!PINA.0);
    	but2 = (!PINA.7);
    	but = but << 6;
    	but2 = but2 << 7;
     	nint = (nint >> 1) | but;
     	nint2 = (nint2 >> 1) | but2;
    }
   	if (++clkcnt == 14) {
   		clkcnt = 0;
   		clkon = 0;
   		but = nint;
   		but2 = nint2;
		butbak = but;
		butbak2 = but2;
   		if ((state==menu || state==option || state==paused || state==gamedone) && but == oldbut) but = 0;
   		if ((state==menu || state==option || state==paused || state==gamedone) && but2 == oldbut2) but2 = 0;
   		eitherbut = but | but2;
   		oldbut = butbak;
   		oldbut2 = butbak2;
   		nint = 0;
   		nint2 = 0;
   	
   		butready = 1;
  }
  }
  }     
 }
 
/* Timer 1 compare-match A ISR was used solely to send sound to the speaker
by toggling a port pin at a certain frequency. */

interrupt [TIM1_COMPA] void cmpA_overflow(void)  
{
  if (PORTB.5 == 1) PORTB.5 = 0;
  else PORTB.5 = 1;		//toggle the port to make a sound
}

//These next 3 procedures were used from the a final project from last
//year, the Tilt Maze.  The source code can be see at
//http://instruct1.cit.cornell.edu/courses/ee476/FinalProjects/s2001/kmo15/m1dc.c
/*********************************************************************/
/* WriteCMD() :  Sends Command to LCD controller                     */
/*********************************************************************/
void WriteCMD(unsigned char CommandCode) {
  PORTD = CommandCode;
  PORTC = CmdSetup;
  PORTC = CmdWrite;
  PORTC = CmdSetup;
  return;
} // end WriteCMD

/*********************************************************************/
/* WriteDATA() :  Sends parameters or data to LCD controller         */
/*********************************************************************/
void WriteDATA(unsigned char CommandCode) {
  PORTD = CommandCode;
  PORTC = DataSetup;
  PORTC = DataWrite;
  PORTC = DataSetup;
  return;
} // end WriteDATA

/*********************************************************************/
/* clearLCD() :  Clears the LCD display memory                       */
/*********************************************************************/
void clearLCD(void) {

unsigned short i;

  WriteCMD(CSRRight);

  WriteCMD(CSRW);
  WriteDATA(0x00);
  WriteDATA(0x00);

  WriteCMD(MWRITE);

  for (i=0; i<1000; i++) {  
    WriteDATA(0x20);    // write " " to character memory
    }
    
  WriteCMD(CSRW);
  WriteDATA(0xE8);
  WriteDATA(0x03);

  WriteCMD(MWRITE);

  for (i=0; i<8000; i++) {
    WriteDATA(0x00);    // erase graphics memory
  }
  return;
} // end clearLCD

/*  This procedure is used to clear any text that is being currently displayed on the LCD.
It clears the character memory. */

void clearText(void) {
unsigned short i;

  WriteCMD(CSRRight);

  WriteCMD(CSRW);
  WriteDATA(0x00);
  WriteDATA(0x00);

  WriteCMD(MWRITE);

  for (i=0; i<1000; i++) {  
    WriteDATA(0x20);    // write " " to character memory
}

/* This procedure is used to test any button pushes.  It checks which state the statemachine
is currently in and then chooses the appropriate actions according to the button push.  */

void butcheck(void) {
    if (eitherbut != 0) {	//Only if either control 1 or 2 has had a button push
     	if (state == menu) {	//menu options screen
     		if (eitherbut & 32) {	//if down was pushed, move cursor down
				mainoptionselected++;
				if (mainoptionselected == 3) mainoptionselected=0;
     			eraseball();
     			ballx = 112;
     			bally = 50 + 16*mainoptionselected;
				drawball();	 	
     		}
     		
     		if (eitherbut & 16) {	//if up was pushed, move cursor up
     		 	mainoptionselected--;
				if (mainoptionselected == -1) mainoptionselected=2;
				eraseball();
     			ballx = 112;
     			bally = 50 + 16*mainoptionselected;
				drawball();
     		}
     		
     		if (eitherbut & 1) {	//if button A was pushed
     		 	if (mainoptionselected == 0) {	//go to 1 player mode
				players = 1;
				state = play1;
				gamescreen();
			}
				if (mainoptionselected == 1) {	//go to 2 player mode
				players = 2;
				state = play2;
				gamescreen();
			}
				if (mainoptionselected == 2) {	//go to options screen
					state = option;
					options();
				}
     		}
     	}    
     	
     	if (state == option) {	//options screen
     		switch (eitherbut) {
     			case 128: //if right was pushed, increase the current option selected by 1 unless option is at
				//maximum in which case decrease option to the minimum number.
					if (optionselected == 0) {  
						speed+=1;
						if (speed == 11) speed = 1;
						textPos(6, 25);
						disInt(speed);
					}
					if (optionselected == 1) {
						size++;
						if (size == 6) size = 1;
						textPos(8, 25);
						disInt(size);
					}
					if (optionselected == 2) {
						winscore++;
						textPos(10, 25);
						disInt(winscore);
				}
				break;
     		    
     			case 64: //if left was pushed, decrease the current option selected by 1 unless option is at
				//minimum in which case increase option to the maximum number.
					if (optionselected == 0) {
						speed-=1;
					if (speed == 0) speed = 10;
						textPos(6, 25);
						disInt(speed);
					}
					if (optionselected == 1) {
						size--;
						if (size == 0) size = 5;
						textPos(8, 25);
						disInt(size);
					}
					if (optionselected == 2) {
						winscore--;
						if (winscore == 0) winscore = 1;  
						textPos(10, 25);
						disInt(winscore);
					}
					break;
     		
   				case 16:  //if up is pushed, move cursor up 1, unless it's all the way up
					  //in which case move cursor to the bottom option. 
					optionselected--;
					if (optionselected == -1) optionselected=3;
					eraseball();
	     				ballx = 70;
     					bally = 50 + 16*optionselected;
					drawball();
					break;
					
				case 32:  //if down is pushed, move cursor down 1, unless it's all the way down
					  //in which case move cursor to the top option. 
					optionselected++;
					if (optionselected == 4) optionselected=0;
					eraseball();
     					ballx = 70;
     					bally = 50 + 16*optionselected;
					drawball();
					break;
				
				case 2:   //if button b is pushed, return to the main menu.
					state = menu;
				 	optionselected = 0;
				 	clearLCD();
				 	mainmenu();
				 	break;
     		    
     				case 1:   //if button a is pushed and the cursor is on the default option
					//reset all the options to the initial settings.
					if (optionselected == 3) {
     			 		speed = initspeed;
					size = initsize;
					winscore = initscore;
					textPos(6, 25);
					disInt(speed);
					textPos(8, 25);
					disInt(size);
					textPos(10, 25);
					disInt(winscore);
     					}                  
     					break;
     		}
     	}
     	
     	if (state == play1) {	//1 player game mode
     	 	if (eitherbut & 16) {	//if up is pushed, move paddles 1 and 2 up 2 pixels unless it's already at the top
     	 		paddle1 -= 2;
     	 		if (paddle1 < 0) paddle1 = 0;
     	 		paddle2 = paddle1;
     	 		drawline(0, paddle1);
     	 		drawline(1, paddle1);
     	 	}
     	  	if (eitherbut & 32) {  //if down is pushed, move paddles 1 and 2 down 2 pixels unless it's already at
					//the bottom
     	 		paddle1 += 2;
     	 		if ((paddle1 + size * 8) > 127) paddle1 = 127 - size * 8;
     	 		paddle2 = paddle1;
     	 		drawline(0, paddle1);
     	 		drawline(1, paddle1);
     	 	}
     	 	if (eitherbut & 8) {  //if start is pushed, save current state of game and go to the pause screen.
     	 		tstate = state;
     	 	 	state = paused;
     	 	 	tpaddle1 = paddle1;
     	 	 	tpaddle2 = paddle2;
     	 	 	tballx = ballx;
     	 	 	tbally = bally;
     	 	 	tdirx = dirx;
     	 	 	tdiry = diry;
     	 	 	pausescreen();
     	 	}
     	 	
     	
     	  }
     	   
     	if (state == play2) {  //2 player game mode
     	 	switch (but) {
     	 	 	case 16:  //if up is pressed on control 1, move paddle1 up 2 pixels unless already at top of LCD
     	 		paddle1 -= 2;
     	 		if (paddle1 < 0) paddle1 = 0;
     	 		drawline(0, paddle1);        
     	 		break;
     	 		
     	 		case 32:  //if down is pressed on control 1, move paddle1 down 2 pixels unless already at bottom
     	 		paddle1 += 2;
     	 		if ((paddle1 + size * 8) > 127) paddle1 = 127 - size * 8;
     	 		drawline(0, paddle1);            
     	 		break;
     	 	
     	 	}
     	 	if (eitherbut & 8) {  //if either controller presses start, save current game state, and go to pause screen.
     	 		tstate = state;
     	 	 	state = paused;
     	 	 	tpaddle1 = paddle1;
     	 	 	tpaddle2 = paddle2;
     	 	 	tballx = ballx;
     	 	 	tbally = bally;
     	 	 	tdirx = dirx;
     	 	 	tdiry = diry;
     	 	 	pausescreen();
     	 	}
     	}
     	
     	if (state == paused) {  //paused state
     	 	switch (eitherbut) {  
     	 	 	case 16:  //if either control presses up, move cursor up 1
			pauseoption--;
			if (pauseoption == -1) pauseoption=1; //used to see if cursor is on the top option
			eraseball();
   			ballx = 70;
     			bally = 50 + 16*pauseoption;
			drawball();
     	 	        break;
     	 	        
     	 	        case 32:  //if either control presses down, move cursor down 1
			pauseoption++;
			if (pauseoption == 2) pauseoption=0;  //used to see if cursor is on the bottom option
			eraseball();
   			ballx = 70;
     			bally = 50 + 16*pauseoption;
			drawball();
			break; 
     	 	        
     	 	        case 1:	 //if either control presses A
			if (pauseoption == 0) { //if the option is resume, then load up saved state, and continue game
     	 	        eraseball();
			state = tstate;
			paddle1 = tpaddle1;
			paddle2 = tpaddle2;
			ballx = tballx;
			bally = tbally;
			dirx = tdirx;
			diry = tdiry; 
			clearLCD();
			drawline(0, tpaddle1);
			drawline(1, tpaddle2);
			drawball();
			}
			if (pauseoption == 1) {  //if the option is exit, then clear screen, and go to the menu
				clearLCD();
				state = menu;
				mainmenu();
			}
			break;
     	 	}
     	
     	}
    }    
    
    if (but2 != 0) {	//check if button 2 is pressed
     	if (state==play2) {  //2 player game mode
     			switch (but2) {          
     			
     	 	 	case 16: //if control 2 presses up, move paddle2 up by 2 pixels unless already at top of LCD
			if ((paddle2-2)>=0) {eraseline(1,paddle2);}
     	 		paddle2 -= 2;
     	 		if (paddle2 < 0) paddle2 = 0;
     	 		drawline(1, paddle2);        
     	 		break;
     	 		
     	 		case 32:  //if control 2 presses down, move paddle2 down by 2 pixels unless already at bottom
			if ((paddle2+2)<=127) {eraseline(1,paddle2);}
     	 		paddle2 += 2;
     	 		if ((paddle2 + size * 8) > 127) paddle2 = 127 - size * 8;
     	 		drawline(1, paddle2);            
     	 		break;
     	 	
     	 	}	
     	}
    
    }
    if (eitherbut && state == gamedone) {state = menu; clearText(); mainmenu();} //used to get out of gameover screen
    if (eitherbut && waitcont) {waitcont = 0; clearText();}	//used to get out of 'push any button' screen
}

//The main procedure just has an endless while loop which will call button checking function and the
//ball moving and checking function at the appropriate times which are given by flags set by timer0 int.

void main(void)
  {  
  initialize();   //initialize all the proper variables
  mainmenu();	  //start with the menu screen

  while(1)
    {
    	random++;	//generate some random number
      if (butready == 1) {	//call button check function if button is ready to be checked
       	butcheck();
       	butready = 0;
      }
      if ((ballmove == 1) && ((state == play1) || (state == play2))) {  //move and check ball
       	ball = 0;   
       	ballmove = 0;
       	game();
      }
  }  
}

//This procedure will draw out the main menu screen on to the LCD.

void mainmenu(void) {
	tpaddle1 = tpaddle2 = 45;
	score1 = 0;
	score2 = 0;
	textPos(2, 14);
	wordWrite('P','O','N','G');
	textPos(6,15);
	wordWrite('1',' ','P','l'); wordWrite('a','y','e','r'); wordWrite(' ','G','a','m'); letterWrite('e');
	textPos(8,15);
	wordWrite('2',' ','P','l'); wordWrite('a','y','e','r'); wordWrite(' ','G','a','m'); letterWrite('e');
	textPos(10,15);
	wordWrite('O','p','t','i'); wordWrite('o','n','s',' ');
	eraseball();
	ballx = 112;
	bally = 50 + 16*mainoptionselected;
	drawball();         
}
 
//This procecure is used to display a variable onto the screen.

void disInt(char num) {
	char temp[7];
	temp[0] = 0; 
   	temp[1] = 0;
   	temp[2] = 0;
   	temp[3] = 0;
   	temp[4] = 0;
	
	itoa(num, temp);
	WriteCMD(MWRITE);          
	WriteDATA(temp[0]);
	WriteDATA(temp[1]);
	WriteDATA(temp[2]);
	WriteDATA(temp[3]);
	WriteDATA(temp[4]);
}
 
//This procedure is used to draw the options menu onto the LCD.

void options(void) {
	/* Display
		Options
		
		Ball speed		1		option 0
		Paddle size		3		option 1
		Winning score		10		option 2
		Reset defaults				option 3
		*/                              
	clearLCD();
	textPos(2, 12);
	wordWrite('O','P','T','I'); wordWrite('O', 'N', 'S', ' ');
	
	textPos(6, 10);
	wordWrite('B','a','l','l'); wordWrite(' ','S','p','e'); wordWrite('e','d',' ',' ');
	textPos(6, 25);
	disInt(speed);
	
	textPos(8,10);
	wordWrite('P','a','d','d'); wordWrite('l','e',' ','S'); wordWrite('i','z','e',' ');       
	textPos(8, 25);
	disInt(size);
	textPos(10,10);
	wordWrite('W','i','n','n'); wordWrite('i','n','g',' '); wordWrite('S','c','o','r'); letterWrite('e');
	textPos(10, 25);
	disInt(winscore);
	textPos(12,10);
	wordWrite('R','e','s','e'); wordWrite('t',' ','D','e'); wordWrite('f','a','u','l'); letterWrite('t');letterWrite('s');
	
	ballx = 70;
	bally = 50 + 16*optionselected;
	drawball(); 

}

//This procedure will draw out the initial game screen onto the screen.
//It will also choose a random spot for where the ball will initially start.

void gamescreen(void) {
clearLCD();
// if (players == 1) display (One Player Game)
// if (players == 2) display (Two Player Game)
// display (Player 1 press Start to begin)

ballx = (xmax - 1) * (random & 1);
bally = (ymax - 1) * (random & 1);
if (ballx == 0) dirx = 1; //0 - left, 1 - right
else dirx = 0;
if (bally == 0) diry = 1; //0 - down, 1 - up
else diry = 0;
paddle1 = tpaddle1;
paddle2 = tpaddle2;
drawline(0, paddle1);
drawline(1, paddle2);
drawball();
waitcont = 0;
TCCR0 = 4;
speedx = speed;
speedy = speed;
//press any button to continue
}

/* This procedure will figure whether the ball has hit a paddle if the ball is going off the screen.
If there is no paddle in the way of the ball, then according to the game, the appropriate scoring will
take place.  If the ball is not going off the screen, then the next coordinates of the ball will be figured
out and then the new ball will be drawn onto the screen. */

void game(void) {
  if (waitcont) {
    textPos(9, 2);
    wordWrite('P','r','e','s'); wordWrite('s',' ','a','n');
    wordWrite('y',' ','b','u'); wordWrite('t','t','o','n'); wordWrite(' ','t','o',' ');
    wordWrite('c','o','n','t'); wordWrite('i','n','u','e');
    textPos(16,0);
    return;
  }

	oldballx = ballx; oldbally = bally;
   if ((showscore == 0) | (players == 1)) {
	if (ballx <= (speedx) && dirx == 0) {  //Checks if ball is going off the left side of the screen
		if ((paddle1 <= bally) && (paddle1 + 8 * size) >= bally) {  //Checks if paddle1 is in the way
			beep = 2;		//beep if there is a paddle hit
			dirx = 1;		//change direction of the ball
			if (players == 1) {score1++; showscore = 10;}	//increase score if in 1 player mode, display score
			if (score1 == winscore) state = gamedone;	//end game if winscore has been reached in 1 players
		}
		else {
			if (players == 1) state = gamedone;	//end game if in 1 player mode
			else {
				dirx = 1;	//change direction of ball
				score2++;	//increase score for player 2
			        showscore = 10;	//set up screen so score is showing
				if (score2 == winscore) state = gamedone;  //end game if winscore has been reached in 2 players
			}
		}
	}
	if (ballx >= (xmax - speedx) && dirx == 1) {  //Checks if ball is going off the right side of the screen
		if ((paddle2 <= bally) && (paddle2 + 8 * size) >= bally) {  //checks if paddle2 is in the way
			beep = 2;		//beep if there is a paddle hit
			dirx = 0;		//change direction
			if (players == 1) { score1++; showscore = 10;}  //increase score if in 1 player mode, display score
			if (score1 == winscore) state = gamedone;  //end game if winscore has been reached in 1 players
		}
		else {
			if (players == 1) state = gamedone;  //end game if in 1 players
			else {
				dirx = 0;	//change direction
			        showscore = 10;	//set up screen so score is showing
				score1++;	//increase score for player 1
				if (score1 == winscore) state = gamedone; //end game if winscore has been reached in 2 players
			}
		}
	}
	}
	//These next 2 if statements are used to calculate the next x coordinate of the ball
	if (ballx > (speedx) && dirx == 0)	ballx = ballx - speed; //- (speed * ((random & 7) + 1) / 80);
	if (ballx < (xmax - speedx) && dirx == 1) ballx = ballx + speed; // + (speed * ((random & 7) + 1) / 80);

	//This if statement are used to calculate the y component of the speed of the ball
	if (bally < (speedy + 1) && diry == 0) {
		diry = 1;
		if (speedy == speed && (random & 1)) speedy+=1;
		if (speedy == (speed + 1) && !(random & 1)) speedy-=1;
		
	}
	
	//This if statement is to see if the ball has hit the sides of the screen
	if (bally > (ymax - speedy - 1) && diry == 1){
		diry = 0;
	}

	//These next 2 if statements calculate the next y coordinate of the ball
	if (bally >= (speedy + 1) && diry == 0)	bally = bally - speedy; //- (speed * ((random & 7) + 1) / 80);
	if (bally <= (ymax - speedy - 1) && diry == 1) bally = bally + speedy; //+ (speed * ((random & 7) + 1) / 80);

	if ((showscore == 0) | (players == 1)) drawball();  //only draws the ball if the ball is still in play
	newballx = ballx; newbally = bally;
	ballx = oldballx; bally = oldbally;
	if ((showscore == 0) | (players == 1)) eraseball();  //only erases the ball if the ball is still in play
	drawline(0, paddle1);			//draw paddle1
	drawline(1, paddle2);			//draw paddle2
	ballx = newballx; bally = newbally;
	beep--; if (beep == -1) beep = 0;

	if ((--showscore == 0) & (players==2)) { //stop showing the score, and show 'hit any button' screen
	  waitcont=1;
	  gamescreen();
	}
	
	if (showscore == -1) showscore = 0;
	
	if (beep) {  //If there's a paddle hit, turn on timer 1 to give sound
	    TCNT1=0;   
	    TCCR1B = 9;	//start timer 1
	}
	else {TCCR1B=0; PORTB.5 = 0;}			//turn off timer 1 

	if (showscore) {  //Show the score of the current game for any game mode
		if (state == gamedone) clearLCD();
	       	textPos(0, 2);
		wordWrite('P', 'l', 'a', 'y'); wordWrite('e', 'r', ' ', '1');
		letterWrite(':'); letterWrite(' ');
		disInt(score1);   
		if (players == 2) {  //show 2nd player score if in 2 player game mode
			textPos(0, 20);
			wordWrite('P', 'l', 'a', 'y'); wordWrite('e', 'r', ' ', '2');
			letterWrite(':'); letterWrite(' ');
			disInt(score2);
		}
		textPos(16,0);
	}
	else { 
		clearText();
	}   
	
	if (state == gamedone) {TCCR1B=0; PORTB.5 = 0; donescreen();}  //turn off timer1 and go to game over screen
}   

//This procedure draws out the the game over screen onto the LCD.

void donescreen(void) {
  clearLCD();
  textPos(2, 12);
  wordWrite('G','A','M','E'); wordWrite(' ', 'O', 'V', 'E'); letterWrite('R');
  if (players == 1) {
    if (score1 == winscore) {
      textPos(6,13);
      wordWrite('Y', 'o', 'u', ' ');
      wordWrite('W', 'i', 'n', '!');
    }
    else {
      textPos(6,13);
      wordWrite('Y','o','u',' ');
      wordWrite('L','o','s','t');
      textPos(7,7);
      wordWrite('P','l','e','a');
      wordWrite('s','e',' ','T');
      wordWrite('r','y',' ','A');
      wordWrite('g','a','i','n');
      wordWrite('.','.','.',' ');
    }
  }
  if (players == 2) {
    textPos(6, 5);
    wordWrite(' ', 'P','l','a');
    wordWrite('y', 'e','r',' ');
    if (score1 == winscore) letterWrite('1');
    else letterWrite('2');
    letterWrite(' ');
    wordWrite('i','s',' ','t');
    wordWrite('h','e',' ','W');
    wordWrite('i','n','n','e');
    letterWrite('r');
    letterWrite('!');
  }
  /*
  Press any button to
  return to the Main Menu
  */
  textPos(9, 3);
  wordWrite('P','r','e','s'); wordWrite('s',' ','a','n');
  wordWrite('y',' ','b','u'); wordWrite('t','t','o','n'); wordWrite(' ','t','o',' ');
  textPos(10, 3);
  wordWrite('r','e','t','u'); wordWrite('r','n',' ','t');
  wordWrite('o',' ','t','h'); wordWrite('e',' ','M','a');
  wordWrite('i','n',' ','M'); wordWrite('e','n','u','.');
  textPos(16,0);
  delay_ms(500);
}

//This procedure draws out the pause screen onto the LCD.

void pausescreen(void) {
textPos(2, 12);
wordWrite('G','A','M','E'); wordWrite(' ', 'P', 'A', 'U'); wordWrite('S','E','D',' ');
textPos(6, 10);
wordWrite('R','e','s','u'); wordWrite('m','e',' ',' ');
textPos(8,10);
wordWrite('E','x','i','t');
       
ballx = 70;
bally = 50 + 16*pauseoption;
drawball();
}

//This function draws the ball according to the current ball coordinates (ballx,bally). 

void drawball() {
	int bx, by, ball4;
	bx = ballx;
	by = bally;
	ball4 = (bx >> 2) & 1;
	pos = bx >> 3;
	pos += (by - 1) * 40;
	pos = pos + GraphicsAddress;
	
	WriteCMD(CSRRight);
	pos_lo = pos;
	pos_hi = pos >> 8;
	WriteCMD(CSRW);
	WriteDATA(pos_lo);
	WriteDATA(pos_hi);
	WriteCMD(MWRITE);
	if (ball4) WriteDATA(0b00000110);
	else WriteDATA(0b01100000);
	for (i=0; i<2; i++) {
		pos +=40;
		pos_lo = pos;
		pos_hi = pos >> 8;
		WriteCMD(CSRW);
		WriteDATA(pos_lo);
		WriteDATA(pos_hi);
		WriteCMD(MWRITE);
		if (ball4) WriteDATA(0b00001111);
		else WriteDATA(0b11110000);
	}
	pos += 40;
	pos_lo = pos;
	pos_hi = pos >> 8;
	WriteCMD(CSRW);
	WriteDATA(pos_lo);
	WriteDATA(pos_hi);
	WriteCMD(MWRITE);
	if (ball4) WriteDATA(0b00000110);
	else WriteDATA(0b01100000);
}

//This function erases the ball according to the current coordinates of the ball.

void eraseball() {
	int bx, by;
	bx = ballx;
	by = bally;
	pos = bx >> 3;
	pos += (by - 1) * 40;
	pos = pos + GraphicsAddress;
	for (i=0; i<4; i++) {
		WriteCMD(CSRRight);
		pos_lo = pos;
		pos_hi = pos >> 8;
		WriteCMD(CSRW);
		WriteDATA(pos_lo);
		WriteDATA(pos_hi);
		WriteCMD(MWRITE);
		WriteDATA(0b00000000);
		pos += 40;
	}
}

//This function draws a paddle according to which paddle it is, and the size of the paddle and where the top of the
//paddle is currently.

void drawline(int side, int top) {
	int ln;
	if (side==0) pos = 0;
	else pos = 31;
	pos += (top-2) * 40;
	pos = pos + GraphicsAddress;			//add GraphicsAddreess offset
	
	WriteCMD(CSRRight);
	for (ln=0; ln < 2; ln++) {
		pos_lo = pos;     	//lo byte
		pos_hi = pos >> 8;  //hi byte
		WriteCMD(CSRW);
		WriteDATA(pos_lo);
		WriteDATA(pos_hi);
	
		WriteCMD(MWRITE);
		WriteDATA(0b00000000);
		pos += 40;
	}
    for (ln=0; ln < size*8; ln++)
	{   
		pos_lo = pos;     	//lo byte
		pos_hi = pos >> 8;  //hi byte
		WriteCMD(CSRW);
		WriteDATA(pos_lo);
		WriteDATA(pos_hi);
		
		WriteCMD(MWRITE);
		if (side == 0) WriteDATA(0b11100000);
		else WriteDATA(0b00000111);
		pos = pos+40;
	}
	for (ln=0; ln < 2; ln++) {
		pos_lo = pos;     	//lo byte
		pos_hi = pos >> 8;  //hi byte
		WriteCMD(CSRW);
		WriteDATA(pos_lo);
		WriteDATA(pos_hi);
	
		WriteCMD(MWRITE);
		WriteDATA(0b00000000);
		pos += 40;
	}
}

//This function will erase a paddle according to which paddle it is and the size and where the top of the paddle
//is located.

void eraseline(int side, int top) {
  int ln;
	if (side==0) pos = 0;
	else pos = 31;
	pos += top * 40;
	pos = pos + GraphicsAddress;			//add GraphicsAddreess offset
	
	WriteCMD(CSRRight);
	pos_lo = pos;     	//lo byte
	pos_hi = pos >> 8;  //hi byte
	WriteCMD(CSRW);
	WriteDATA(pos_lo);
	WriteDATA(pos_hi);
	
	WriteCMD(MWRITE);
	WriteDATA(0b00000000);
	pos += 40;
    for (ln=0; ln < size*8; ln++)
	{   
		pos_lo = pos;     	//lo byte
		pos_hi = pos >> 8;  //hi byte
		WriteCMD(CSRW);
		WriteDATA(pos_lo);
		WriteDATA(pos_hi);
		
		WriteCMD(MWRITE);
		if (side == 0) WriteDATA(0b00000000);
		else WriteDATA(0b00000000);
		pos = pos+40;
	}
	WriteCMD(MWRITE);
	WriteDATA(0b00000000);
}

//This function will set up a cursor to write text according to the row and column that is given.

void textPos(int row, int col) {
  int loc;
  unsigned char loc_lo, loc_hi;
  loc = col + 40*row;
  loc_lo = loc;
  loc_hi = loc>>8;
  
  WriteCMD(CSRRight);
  WriteCMD(CSRW);
  WriteDATA(loc_lo);
  WriteDATA(loc_hi);
}

//This function will write a letter to the LCD.

void letterWrite(char letter) {
  WriteCMD(MWRITE);         
  WriteDATA(letter);
}

//This function will write 4 letters to the LCD.

void wordWrite(char let1, char let2, char let3, char let4) {
  letterWrite(let1);
  letterWrite(let2);
  letterWrite(let3);
  letterWrite(let4);
}

void initialize(void)
{
  DDRA=0x00;    // PORT A - controller input
  DDRB=0xff;    // PORT B - controller output
  DDRD=0xff;    // PORT D - LCD
  DDRC=0xff;    // PORT C - LCD
  PORTD=0;

  //set up timer 0
  TCNT0=256-62;
  TIMSK=2;              //turn on timer 0 overflow ISR
  TCCR0=4;              //prescalar to 64

  TIMSK=TIMSK | 0x40;	//turn on timer 1 compare match interrupt
  TCCR1B = 0;		//disable timer 1 until song starts  
  TCNT1 = 0;     		//and zero the timer 
  OCR1A=7648/2; 	//and load the correct time out for timer 1  

  str = clkon = clkcnt = 0;  
    
	players = 1;
	score1 = 0;
	score2 = 0;
	speed = initspeed;
	speedx = speedy = speed;
	size = initsize;
	winscore = initscore;
	ballx = 0;
	bally = 0;
	dirx = 0;
	diry = 0;
	paddle1 = 0;
	paddle2 = 0; 
	mainoptionselected = 0;
	pauseoption = optionselected = 0;
	gamestate = 0;
	random = 0;
    but = but2 = oldbut = oldbut2 = butbak = butbak2 = butready = eitherbut = 0;
    nint = nint2 = ball = ballmove = 0;
    tballx = tbally = tdirx = tdiry = 0;
    tpaddle1 = 45;
    tpaddle2 = 45;
   

  //These next lines will initialize the LCD screen for proper use 
  PORTC = LCDnop;
  PORTC = LCDreset;
  PORTC = LCDnop;
  
  WriteCMD(SystemSet);
  WriteDATA(0x30);
  WriteDATA(0x87);
  WriteDATA(0x07);
  WriteDATA(0x27);
  WriteDATA(0x2F);
  WriteDATA(0xC7);
  WriteDATA(0x28);
  WriteDATA(0x00);

  WriteCMD(Overlay);
  WriteDATA(0x00);

  WriteCMD(Scroll);
  WriteDATA(0x00);
  WriteDATA(0x00);
  WriteDATA(0xC8);
  WriteDATA(0xE8);
  WriteDATA(0x03);
  WriteDATA(0xC8);
		
  WriteCMD(CSRForm);
  WriteDATA(0x04);
  WriteDATA(0x86);
	
  WriteCMD(CSRRight);
		
  WriteCMD(HorzScroll);
  WriteDATA(0x00);
  
  WriteCMD(DispON);
  WriteDATA(0x16);
	
  clearLCD();
  state = tstate = menu;
  //crank up the ISRs
  #asm
        sei
  #endasm 
}


