#include <LiquidCrystalKtms.h>
//#include <OneWire.h>
//#include <Wire.h>
#include <avr/interrupt.h>
#include <avr/io.h>

#define INIT_TIMER_COUNT 6
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT

/*uint8_t  nsck=2,    //3
si=3,  //4
cd=4,  //5
nreset=5,  //6
nbusy=6,   //7
ncs=7; //8
*/
LiquidCrystalKtms lcd(7,8,9,10,11,12);
char msg1[13] ={0};
char msg2[] ="012345678901";

int val; 
int encoder0PinA = 2;
int encoder0PinB = 3;
int n = LOW;
int cnt =0;


volatile unsigned int encoder0Pos = 10000;
int int_counter = 0;
volatile int second = 0;
int oldSecond = 0;
long starttime = 0;


// Aruino runs at 16 Mhz, so we have 1000 Overflows per second...
// 1/ ((16000000 / 64) / 256) = 1 / 1000
ISR(TIMER2_OVF_vect) 
{
  RESET_TIMER2;
  if (100 == int_counter++) {
    second++;
    int_counter = 0;
  }
//  doEncoderA();
//  doEncoderB();
};


void setup() 
{
  pinMode(encoder0PinA, INPUT); 
  pinMode(encoder0PinB, INPUT); 
  attachInterrupt(0, doEncoderA, CHANGE);
  attachInterrupt(1, doEncoderB, CHANGE);  

  //Timer2 Settings: Timer Prescaler /256, WGM mode 0
  TCCR2A = 0;

//  TCCR2B = 1<<CS22 | 1<<CS21;    //256

  TCCR2B = 1<<CS22 | 0<<CS21 | 0<<CS20;   //64 

  //Timer2 Overflow Interrupt Enable  
  TIMSK2 = 1<<TOIE2;
  //reset timer
  TCNT2 = 0;
}





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






void loop()                     // run over and over again
{
     
  //ltoa( encoder0Pos, msg1, 10);
  ltoa ( second, msg1, 10);
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
