/*
 * Blink
 *
 * The basic Arduino example.  Turns on an LED on for one second,
 * then off for one second, and so on...  We use pin 13 because,
 * depending on your Arduino board, it has either a built-in LED
 * or a built-in resistor so that you need only an LED.
 *
 * http://www.arduino.cc/en/Tutorial/Blink
 */
 /* Read Quadrature Encoder
  * Connect Encoder to Pins encoder0PinA, encoder0PinB, and +5V.
  *
  * Sketch by max wolf / www.meso.net
  * v. 0.1 - very basic functions - mw 20061220
  *
  */  


 #include "WProgram.h"
void setup();
void loop();
int val; 
 int encoder0PinA = 3;
 int encoder0PinB = 4;
 int encoder0Pos = 0;
 int encoder0PinALast = LOW;
 int n = LOW;
 int cnt =0;

int ledPin = 11;                // LED connected to digital pin 13

void setup()                    // run once, when the sketch starts
{
  pinMode(ledPin, OUTPUT);      // sets the digital pin as output

   pinMode (encoder0PinA,INPUT);
   pinMode (encoder0PinB,INPUT);
   Serial.begin (9600);
   analogWrite( ledPin, 255);
 } 

void loop()                     // run over and over again
{
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
 } 

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

