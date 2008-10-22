#include <OneWire.h>

#include <OneWire.h>

#include <Wire.h>

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


#include <OneWire.h>


 int val; 
 int encoder0PinA = 3;
 int encoder0PinB = 4;
 int encoder0Pos = 0;
 int encoder0PinALast = LOW;
 int n = LOW;
 int cnt =0;

int ledPin = 11;                // LED connected to digital pin 13
OneWire ds(10);  // on pin 10



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
/*
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
  Serial.begin(9600);
}



void loop(void) {
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
 
