#include <LiquidCrystalKtms.h>
//#include <OneWire.h>
//#include <Wire.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#include <avr/pgmspace.h>

#define INIT_TIMER_COUNT 6
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT
const char msg2[] PROGMEM ="012345678901";
PGM_P array[1] PROGMEM = { msg2 };
/*uint8_t  nsck=2,    //3
si=3,  //4
cd=4,  //5
nreset=5,  //6
nbusy=6,   //7
ncs=7; //8
*/
LiquidCrystalKtms lcd(7,8,9,10,11,12);
char msg1[13] ={0,0,0,0,0,0,0,0,0,0,0,0,0};


int val; 
int encoder0PinA = 4;
int encoder0PinB = 5;
int n = LOW;
int cnt =0;

volatile uint32_t encoder0Pos = 10000;
int int_counter = 0;
volatile uint32_t second = 0;
int oldSecond = 0;
long starttime = 0;


// Aruino runs at 16 Mhz, so we have 1000 Overflows per second...
// 1/ ((16000000 / 64) / 256) = 1 / 1000
ISR(TIMER2_OVF_vect) 
{
  RESET_TIMER2;
  if (1 == int_counter++) {
    second++;
    int_counter = 0;
  

  }
  doEncoder();

//  doEncoderA();
//  doEncoderB();
};


void setup() 
{
  pinMode(encoder0PinA, INPUT); 
  pinMode(encoder0PinB, INPUT); 
//  attachInterrupt(0, doEncoderA, CHANGE);
//  attachInterrupt(1, doEncoderB, CHANGE);  

  //Timer2 Settings: Timer Prescaler /256, WGM mode 0
  TCCR2A = 0;

//  TCCR2B = 1<<CS22 | 1<<CS21;    //256

  TCCR2B = 1<<CS22 | 0<<CS21 | 0<<CS20;   //64 

  //Timer2 Overflow Interrupt Enable  
  TIMSK2 = 1<<TOIE2;
  //reset timer
  TCNT2 = 0;
}




/*
void doEncoderA()
{
  if (digitalRead(encoder0PinA) == HIGH) { 
    if (digitalRead(encoder0PinB) == LOW) {  
      encoder0Pos = encoder0Pos + 1;         // CW
    } 
    else {
      encoder0Pos = encoder0Pos - 1;         // CCW
    }
  }
  else                                        
  { 
    if (digitalRead(encoder0PinB) == HIGH) {   
      encoder0Pos = encoder0Pos + 1;          // CW
    } 
    else {
      encoder0Pos = encoder0Pos - 1;          // CCW
    }
  }
}


void doEncoderB()
{
  if (digitalRead(encoder0PinB) == HIGH) 
  {   
    if (digitalRead(encoder0PinA) == HIGH) 
    {  
      encoder0Pos = encoder0Pos + 1;         // CW
    } 
    else 
    {
      encoder0Pos = encoder0Pos - 1;         // CCW
    }
  }
  else { 
    if (digitalRead(encoder0PinA) == LOW) 
      {   
       encoder0Pos = encoder0Pos + 1;          // CW
       } 
    else 
      {
       encoder0Pos = encoder0Pos - 1;          // CCW
      }
     }
} 
*/
/*
gray code
00
01
11
10
*/
static uint8_t prevStateCntr;
static uint8_t prevStateA[5] ;

void doEncoder()
{
    uint8_t curState = (digitalRead(encoder0PinB)<<1 | digitalRead(encoder0PinA));// (PORTD & 0b1100)>>2; //(PORTD & ( 1<<encoder0PinB | 1<<encoder0PinA))<<2;
    uint8_t prevState =prevStateA[prevStateCntr];
    uint8_t prevStateCntrT3 ;
    if(prevStateCntr ==0)
        prevStateCntrT3= 4;
    else
        prevStateCntrT3= prevStateCntr-1;
    uint8_t prevStateT3= prevStateA[prevStateCntrT3];
//3,6,9,12,18    
//    if( /*(0==(prevStateCntr % 2)) &*/ (prevStateA[prevStateCntrT3] == prevStateA[prevStateCntr]) && prevState != curState)
  if( (prevState == curState) && (prevStateT3 != prevState)   )
    {
    if( 0b00==prevStateT3)
    {
     if( 0b01==curState) encoder0Pos++; //increment
     else if( 0b10==curState) encoder0Pos--;//decrement
    }
    else if(0b01 == prevStateT3)
    {
     if( 0b11==curState) encoder0Pos++; //increment
    else if( 0b00==curState) encoder0Pos--;//decrement
    }
    else if(0b11 == prevStateT3)
    {
     if( 0b10==curState) encoder0Pos++; //increment
     else if( 0b01==curState) encoder0Pos--;//decrement
    }
    else if(0b10 == prevStateT3)
    {
     if( 0b00==curState) encoder0Pos++; //increment
     else if( 0b11==curState) encoder0Pos--;//decrement
    }
    
    prevStateCntr ++;
    if(prevStateCntr == 4)
       prevStateCntr=0;
    } // this allows us to filter away noise
    prevStateA[prevStateCntr] = curState;   
    
}



void loop()                     // run over and over again
{
     
  ultoa( encoder0Pos, msg1, 10);
  //ultoa ( second, msg1, 10);
  digitalWrite(12, 0); //delay(1);
  lcd.print( msg1);
  digitalWrite(12, 1);
 
  delay(100);



/*  if (oldSecond != second) {
    Serial.print(second);
    Serial.print(". ->");
    Serial.print(millis() - starttime);
    Serial.println(".");

    delay(100);

    oldSecond = second;
  }
*/

}
