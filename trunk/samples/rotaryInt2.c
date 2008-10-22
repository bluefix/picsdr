/*  to read the other two transitions - just use another attachInterrupt()
in the setup and duplicate the doEncoder function into say, 
doEncoderA and doEncoderB. 
You also need to move the other encoder wire over to pin 3 (interrupt 1). 
*/ 

Code for reading encoder using 2 interrupts on pin 2 & pin3

note: the code below uses 2 interrupts to read the full resolution of the encoder. Using 1 interrupt reads half the resolution by only checking EncoderPin A for position, but it frees up an interrupt pin.

#define encoder0PinA 2

#define encoder0PinB 3

/*
public class rotaryEncoderInt
{

public:
   rotaryEncoderInt( uint8_t pinA, uint8_t pinB, void *handler);

*/

volatile unsigned int encoder0Pos = 0;

void setup() {

  pinMode(encoder0PinA, INPUT); 
  pinMode(encoder0PinB, INPUT); 

// encoder pin on interrupt 0 (pin 2)

  attachInterrupt(0, doEncoderA, CHANGE);

// encoder pin on interrupt 1 (pin 3)

  attachInterrupt(1, doEncoderB, CHANGE);  

  Serial.begin (9600);

}

void loop(){ //Do stuff here }

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
  Serial.println (encoder0Pos, DEC);          
  // use for debugging - remember to comment out

}

void doEncoderB(){

  // look for a low-to-high on channel B
  if (digitalRead(encoder0PinB) == HIGH) {   

   // check channel A to see which way encoder is turning
    if (digitalRead(encoder0PinA) == HIGH) {  
      encoder0Pos = encoder0Pos + 1;         // CW
    } 
    else {
      encoder0Pos = encoder0Pos - 1;         // CCW
    }
  }

  // Look for a high-to-low on channel B

  else { 
    // check channel B to see which way encoder is turning  
    if (digitalRead(encoder0PinA) == LOW) {   
      encoder0Pos = encoder0Pos + 1;          // CW
    } 
    else {
      encoder0Pos = encoder0Pos - 1;          // CCW
    }
  }

} 