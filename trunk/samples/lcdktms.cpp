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

 int val; 
 int encoder0PinA = 2;
 int encoder0PinB = 3;
 //int encoder0Pos = 0; int encoder0PinALast = LOW;
 int n = LOW;
 int cnt =0;


//int ledPin = 11;                // LED connected to digital pin 13
//OneWire ds(10);  // on pin 10


//LiquidCrystalKtms lcd(2,3,4,5,6,7);
//LiquidCrystalKtms lcd(6,7,8,9,10,11);
LiquidCrystalKtms lcd(7,8,9,10,11,12);

   char msg1[13] ={0};
   char msg2[] ="012345678901";



volatile unsigned int encoder0Pos = 10000;
int int_counter = 0;
volatile int second = 0;
int oldSecond = 0;
long starttime = 0;


// Aruino runs at 16 Mhz, so we have 1000 Overflows per second...
// 1/ ((16000000 / 64) / 256) = 1 / 1000
ISR(TIMER2_OVF_vect) {
  RESET_TIMER2;
  int_counter += 1;
  if (int_counter == 1000) {
    second+=1;
    int_counter = 0;
  }
};

/*

#include <avr/interrupt.h>  
#include <avr/io.h>

//Timer2 overflow interrupt vector handler, called (16,000,000/256)/256 times per second
ISR(TIMER2_OVF_vect) {
  //let 10 indicates interrupt fired
  digitalWrite(10,true);
};  

void setup() {
  pinMode(9,OUTPUT);
  pinMode(10,OUTPUT);

  //Timer2 Settings: Timer Prescaler /256, WGM mode 0
  TCCR2A = 0;
  TCCR2B = 1<<CS22 | 1<<CS21;

  //Timer2 Overflow Interrupt Enable  
  TIMSK2 = 1<<TOIE2;

  //reset timer
  TCNT2 = 0;

  //led 9 indicate ready
  digitalWrite(9,true);
}

void loop() {
}
 



*/

void setup() {

  pinMode(encoder0PinA, INPUT); 
  pinMode(encoder0PinB, INPUT); 

// encoder pin on interrupt 0 (pin 2)

  attachInterrupt(0, doEncoderA, CHANGE);

// encoder pin on interrupt 1 (pin 3)

  attachInterrupt(1, doEncoderB, CHANGE);  

//  Serial.begin (9600);


//  pinMode(9,OUTPUT);
//  pinMode(10,OUTPUT);

  //Timer2 Settings: Timer Prescaler /256, WGM mode 0
  TCCR2A = 0;
  TCCR2B = 1<<CS22 | 1<<CS21;

  //Timer2 Overflow Interrupt Enable  
  TIMSK2 = 1<<TOIE2;

  //reset timer
  TCNT2 = 0;

/*
//Timer2 Settings: Timer Prescaler /64,
  TCCR2 |= ((1<<CS22) | (0<<CS21) | (0<<CS20));
  // Use normal mode
  TCCR2 |= (0<<WGM21) | (0<<WGM20);
  // Use internal clock - external clock not used in Arduino
  ASSR |= (0<<AS2);
  TIMSK |= (1<<TOIE2) | (0<<OCIE2);	  //Timer2 Overflow Interrupt Enable
  RESET_TIMER2;
  sei();
  starttime = millis();

#define TIMER_CLOCK_FREQ 2000000.0 //2MHz for /8 prescale from 16MHz

//Setup Timer2.
//Configures the ATMega168 8-Bit Timer2 to generate an interrupt
//at the specified frequency.
//Returns the timer load value which must be loaded into TCNT2
//inside your ISR routine.
//See the example usage below.
unsigned char SetupTimer2(float timeoutFrequency){
  unsigned char result; //The timer load value.

  //Calculate the timer load value
  result=(int)((257.0-(TIMER_CLOCK_FREQ/timeoutFrequency))+0.5);
  //The 257 really should be 256 but I get better results with 257.

  //Timer2 Settings: Timer Prescaler /8, mode 0
  //Timer clock = 16MHz/8 = 2Mhz or 0.5us
  //The /8 prescale gives us a good range to work with
  //so we just hard code this for now.
  TCCR2A = 0;
  TCCR2B = 0<<CS22 | 1<<CS21 | 0<<CS20;

  //Timer2 Overflow Interrupt Enable
  TIMSK2 = 1<<TOIE2;

  //load the timer for its first cycle
  TCNT2=result;

  return(result);
}


*/

  //led 9 indicate ready
 // digitalWrite(9,true);

}





void doEncoderA(){

  // look for a low-to-high on channel A
  if (digitalRead(encoder0PinA) == HIGH) { 

    // check channel B to see which way encoder is turning
    if (digitalRead(encoder0PinB) == LOW) {  
      encoder0Pos = encoder0Pos + 1;         // CW
    } 
    else {
      encoder0Pos = encoder0Pos - 1;         // CCW
    }
  }
  // look for a high-to-low on channel A
  else                                        
  { 
    // check channel B to see which way encoder is turning  
    if (digitalRead(encoder0PinB) == HIGH) {   
      encoder0Pos = encoder0Pos + 1;          // CW
    } 
    else {
      encoder0Pos = encoder0Pos - 1;          // CCW
    }
  }
  //Serial.println (encoder0Pos, DEC);          
  // use for debugging - remember to comment out

}

void doEncoderB()
{

  // look for a low-to-high on channel B
  if (digitalRead(encoder0PinB) == HIGH) 
  {   

   // check channel A to see which way encoder is turning
    if (digitalRead(encoder0PinA) == HIGH) 
    {  
      encoder0Pos = encoder0Pos + 1;         // CW
    } 
    else 
    {
      encoder0Pos = encoder0Pos - 1;         // CCW
    }
  }

  // Look for a high-to-low on channel B

  else { 
    // check channel B to see which way encoder is turning  
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
/*
  // digitalWrite(ledPin, HIGH);   // sets the LED on

   n = digitalRead(encoder0PinA);
   if ((encoder0PinALast == LOW) && (n == HIGH)) {
     if (digitalRead(encoder0PinB) == LOW) {
       encoder0Pos--;
     } else {
       encoder0Pos++;
     }
     if (encoder0Pos > 255)
         encoder0Pos =0;
         
     
     //digitalWrite(ledPin, LOW);    // sets the LED off
     analogWrite( ledPin, encoder0Pos);
     Serial.print (encoder0Pos);
     
     if(cnt%50)
          Serial.print ("\n");
     else
          Serial.print ("-");  
   } 
   encoder0PinALast = n;
   */
   
   /*
   #include <OneWire.h>

// DS18S20 Temperature chip i/o


OneWire  ds(10);  // on pin 10

void setup(void) {
  // initialize inputs/outputs
  // start serial port
  SetupTimer2(TIMER_CLOCK_FREQ);
  Serial.begin(9600);
}




void loop(void) {
/*
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
      //Serial.print("No more addresses.\n");
      ds.reset_search();
      return;
  }
  
  Serial.print("R=");  //R=28 Not sure what this is
  for( i = 0; i < 8; i++) {
    Serial.print(addr[i], HEX);
    Serial.print(" ");
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("CRC is not valid!\n");
      return;
  }
  
  if ( addr[0] != 0x28) {
      Serial.print("Device is not a DS18S20 family device.\n");
      return;
  }

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  
  delay(1000);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.
  
  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  Serial.print("P=");  
  Serial.print(present,HEX);
  Serial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    Serial.print(data[i], HEX);
    Serial.print(" ");
  }

  Serial.print(" CRC=");
  Serial.print( OneWire::crc8( data, 8), HEX);
  Serial.println();
}

   */
 
  //strcpy( msg1, "            ");
  
//  for( int i=0; i< 12; i++)
//     msg1[i] = ' ';  
     
  ltoa( encoder0Pos, msg1, 10);
  
  digitalWrite(12, 0); //delay(1);
  lcd.print( msg1);
  digitalWrite(12, 1);
  
  delay(100);


  
 
//  digitalWrite(12, 0);//delay(1);
 // lcd.print( msg2);
 // digitalWrite(12, 1);

 // delay(1000);

  if (oldSecond != second) {
    Serial.print(second);
    Serial.print(". ->");
    Serial.print(millis() - starttime);
    Serial.println(".");
 //   digitalWrite(ledPin, HIGH);
    delay(100);
 //   digitalWrite(ledPin, LOW);
    oldSecond = second;
  }


}






/*
dds60
// Arduino using DDS60/AD9851 with 30MHz Osc clock ~ Bare Bones Test 16
// For AD9851 array values see http://www.analog.com/Analog_Root/static/techSupport/designTools/interactiveTools/dds/ad9851.html
// For AD9851 datasheet see http://www.analog.com/en/prod/0%2C2877%2CAD9851%2C00.html
// For DDS60 see http://www.amqrp.org/kits/dds60/index.html
// For Arduino see http://www.arduino.cc/en/Guide/HomePage
// by Mike Bowthorpe

byte DATA = 10; //DATA on pin 10/3
byte CLOCK = 9; //CLOCK on pin 9/2
byte LOAD = 8; //LOAD on pin 8/1
byte pin13 = 13;

void setup()
{
pinMode (DATA, OUTPUT); // sets pin 10 as OUPUT
pinMode (CLOCK, OUTPUT); // sets pin 9 as OUTPUT
pinMode (LOAD, OUTPUT); // sets pin 8 as OUTPUT
pinMode (pin13, OUTPUT);
}

void loop()
{
{

shiftOut(DATA,CLOCK,LSBFIRST,(0,119,250,137,230)); // 5 values W0, W1, W2, W3, W4 to give 14.06000 MHz with 30MHz Osc

digitalWrite (LOAD, HIGH); // Turn on pin 8/1 LOAD FQ-UD
digitalWrite (LOAD, LOW); // Turn pin 8 off

}
}
*/






 



/*

#include <avr/interrupt.h>
#include <avr/io.h>

#define INIT_TIMER_COUNT 6
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT

int ledPin = 13;
int int_counter = 0;
volatile int second = 0;
int oldSecond = 0;
long starttime = 0;

// Aruino runs at 16 Mhz, so we have 1000 Overflows per second...
// 1/ ((16000000 / 64) / 256) = 1 / 1000
ISR(TIMER2_OVF_vect) {
  RESET_TIMER2;
  int_counter += 1;
  if (int_counter == 1000) {
    second+=1;
    int_counter = 0;
  }
};

void setup() {
  Serial.begin(9600);
  Serial.println("Initializing timerinterrupt");
  //Timer2 Settings: Timer Prescaler /64,
  TCCR2 |= ((1<<CS22) | (0<<CS21) | (0<<CS20));
  // Use normal mode
  TCCR2 |= (0<<WGM21) | (0<<WGM20);
  // Use internal clock - external clock not used in Arduino
  ASSR |= (0<<AS2);
  TIMSK |= (1<<TOIE2) | (0<<OCIE2);	  //Timer2 Overflow Interrupt Enable
  RESET_TIMER2;
  sei();
  starttime = millis();
}

void loop() {
  if (oldSecond != second) {
    Serial.print(second);
    Serial.print(". ->");
    Serial.print(millis() - starttime);
    Serial.println(".");
    digitalWrite(ledPin, HIGH);
    delay(100);
    digitalWrite(ledPin, LOW);
    oldSecond = second;
  }
}
 

#include <avr/interrupt.h>  
#include <avr/io.h>

//Timer2 overflow interrupt vector handler, called (16,000,000/256)/256 times per second
ISR(TIMER2_OVF_vect) {
  //let 10 indicates interrupt fired
  digitalWrite(10,true);
};  

void setup() {
  pinMode(9,OUTPUT);
  pinMode(10,OUTPUT);

  //Timer2 Settings: Timer Prescaler /256, WGM mode 0
  TCCR2A = 0;
  TCCR2B = 1<<CS22 | 1<<CS21;

  //Timer2 Overflow Interrupt Enable  
  TIMSK2 = 1<<TOIE2;

  //reset timer
  TCNT2 = 0;

  //led 9 indicate ready
  digitalWrite(9,true);
}

void loop() {
}
 



*/






   1. #include < avr / interrupt.h >  
   2. #include < avr / io.h >  
   3.   
   4. #define INIT_TIMER_COUNT 6  
   5. #define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT  
   6.   
   7. int ledPin = 13;  
   8. int int_counter = 0;  
   9. volatile int second = 0;  
  10. int oldSecond = 0;  
  11. long starttime = 0;  
  12.   
  13. // Aruino runs at 16 Mhz, so we have 1000 Overflows per second...  
  14. // 1/ ((16000000 / 64) / 256) = 1 / 1000  
  15. ISR(TIMER2_OVF_vect) {  
  16.   RESET_TIMER2;  
  17.   int_counter += 1;  
  18.   if (int_counter == 1000) {  
  19.     second+=1;  
  20.     int_counter = 0;  
  21.   }   
  22. };  
  23.   
  24. void setup() {  
  25.   Serial.begin(9600);  
  26.   Serial.println("Initializing timerinterrupt");  
  27.   //Timer2 Settings: Timer Prescaler /64,   
  28.   TCCR2 |= (1< <CS22);      
  29.   TCCR2 &= ~((1<<CS21) | (1<<CS20));       
  30.   // Use normal mode  
  31.   TCCR2 &= ~((1<<WGM21) | (1<<WGM20));    
  32.   // Use internal clock - external clock not used in Arduino  
  33.   ASSR |= (0<<AS2);  
  34.   //Timer2 Overflow Interrupt Enable  
  35.   TIMSK |= (1<<TOIE2) | (0<<OCIE2);    
  36.   RESET_TIMER2;                 
  37.   sei();  
  38.   starttime = millis();  
  39. }  
  40.   
  41. void loop() {  
  42.   if (oldSecond != second) {  
  43.     Serial.print(second);  
  44.     Serial.print(". ->");  
  45.     Serial.print(millis() - starttime);  
  46.     Serial.println(".");  
  47.     digitalWrite(ledPin, HIGH);  
  48.     delay(100);  
  49.     digitalWrite(ledPin, LOW);  
  50.     oldSecond = second;  
  51.   }  
  52. }  