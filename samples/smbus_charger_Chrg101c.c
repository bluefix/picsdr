//--------------------------------------------------------------------------
//                         CHRGR101C.C                       Version: 1.01C
//                      By: Laszlo Kiraly
//                    Email:KiralyL@aol.com
//                     Linear Technology
//                   Applications Department
//          1630 McCarthy Blvd, Milpitas, CA 95035, USA 
//          Phone: (408) 432-1900,  Fax: (408) 434-0507 
/*---------------------------------------------------------------------------
                                                    April 16,1996
This program: 
 Sets-up PWMs and I2C communication.
 It receives data from I2C (including its own address) and store them 
 in i2c_data[10] as the come in, including its own address (0x12). 

               0 charger i2c address (always 0x12) 
               1 ChargingCurrent() CMD (0x14)
               2 charging current data byte L
               3 charging current data byte H       (unsigned int, mA)
               4 charger i2c address (0x12)
               5 ChargingVoltage CND (0x15)
               6 charging voltage data byte L
               7 charging voltage data byte H       (unsigned int, mV)

Revision changes:

- scales current word and loads value to IPWM (PWM2).
- scales voltage word and loads value to VPWM (PWM1).
- 16CC73.H bits for CCP1CON registers need to be specified. 
- thermistor limits were changed   (2/21/96)
- using easy math (2/21/96)
- comments were added                                               (4/11/96)
- init() function was created                                       (4/11/96)
- AlarmWarning() function now checks b15:b12 bits.                  (4/11/96)
* At LT1511 UV shutdown (DCOK-L) uP pulls its shut-down high. 
- The uP enables the charger after valid data received from battery.(4/11/96)
- No broadcast from battery timeout (180 sec. nom.) now implemented.(4/11/96)
- SMBus reset function has been added.                              (4/15/96)
- GIE disable and enable was removed (__int handles them)           (4/16/96)
----------------------------------------------------------------------------
*/
#include <16c73.h>
#include <delay14.h>
//
void load_ipwm( void );                 // scales received value and loads PWM1
void load_vpwm( void );                 // scales ChargingCurrent, loads PWM2
void initiv( char );                    // sets voltage and current PWMs
void ad_th( void );                     // measures thermistor, controls charger
void init_var( void );                  // initializes variables (general)
void clear_smbus( void );               // sends start-stop sequence to SMBus
//
char i2c_data[10];                      // i2C stack
char i2c_counter;                       // i1c stack pointer 
//
bits  flag;                    
                                        // flag.0 is set on return from I2C INT.
                                        // flag.1 blinking speed 1 = high speed
                                        // flag.2 themistor/resistor out of range
                                        // flag.3=1 comm. timeout, inibits cntr  
char LED_counter, ad_counter;
long unsigned ad_val;
long unsigned com_timeout_cntr;
long unsigned clear_smbus_cntr;
char val;
//
//------------------------------------------------------------------------
void __INT( void)
{
  SSPCON.CKP = 0;                       // HOLD CK 0
  flag.0 = 1;

  i2c_data[i2c_counter] = SSPBUF;    
  i2c_counter++;
  if(i2c_counter > 7) 
  {
     i2c_counter=0;			// reset counter if overflows
  }
  PIR1.SSPIF = 0;
  SSPCON.CKP = 1;                       // release ck
}
//
// ----------------------------------------------------------- 
void main()
{
  init_var();				// initializes variables (hardware setup)
  Delay_Ms_4MHz(250);
  Delay_Ms_4MHz(250);
  Delay_Ms_4MHz(250);
  Delay_Ms_4MHz(250);
  //
  i2c_counter = 0;			// clear i2c data pointer
  ad_counter = 5;			// clear 
  //
  com_timeout_cntr = 0;
  clear_smbus_cntr = 0;			// sets time between SMBus inits. 
  //
  SSPADD = 0x12;			// define slave address
  //
  flag = 0;
  flag.1 = 1;				// set fast blinking
  flag.2 = 1;				// thermistor out of both NiMH andliIon
  flag.3 = 1;				// disable com_timeout_cntr
  //
  PIE1.SSPIE  = 1;			// enable i2c interrupt
  INTCON.PEIE = 1;			// enable phripherial INTs.
  INTCON.GIE  = 1;			// general INT enable
  //
  while(1)				// infinite loop in MAIN
  { 
    Delay_Ms_4MHz(20);
    // ---------------------------------------------------------------
    if(com_timeout_cntr == 6250)	// no communication timeout 100-> 2.88sec
    {                                       
       flag.1 = 1;			// set fast blinking
       flag.3 = 1;			// communication timeout cntr disabled
       // 
       PORTC.0 = 1;			// disable charger
       com_timeout_cntr = 0;		// reset timer
       //
       PORTB.3 = 0;			// turn red LED on for 50ms
       Delay_Ms_4MHz(20);
       PORTB.3 = 1;			// red LED off
    }
    //
    if( !flag.3 ) com_timeout_cntr++;	// if no timeout run counter
    else com_timeout_cntr = 0; 
    if( flag.2) flag.3 = 1;		// if th. out of range reset cntr
					// do not override th. based decisions
    //
    // ---------------------------------------------------------------------
    if( flag.3) clear_smbus_cntr++;	// clear SMBus
    if( clear_smbus_cntr == 1000)
    {
      clear_smbus();
      clear_smbus_cntr = 0;
    }
    if( flag.2) clear_smbus_cntr = 0;    
    //
    // -------------------------------------------------------------------
    if(ad_counter == 0)			// is it time to measure thermistor ?
    {					// checks UV (DCOK input) also
      ad_th();				// if ad_counter starts at 5, td=140ms
      ad_counter = 5;
    }
    ad_counter--;
    // -------------------------------------------------------------------
    if(flag.0)				// return from I2C interrupt?
    {                               
        PORTB.3 = 0;			// red LED on 
        Delay_Ms_4MHz(250);
        Delay_Ms_4MHz(250);
        Delay_Ms_4MHz(250);
        Delay_Ms_4MHz(250);
        PORTB.3 = 1;			// red LED off
        flag.0 = 0;
        i2c_counter = 0;		// reset I2C stack pointer
        flag.1 = 0;			// change to slow blinking
    }
    // -------------------------------------------------------------------
    if(i2c_data[1] == 0x16)             // AlarmWarning() on stack ?
    {
       if( i2c_data[3] > 0x0f)
       {         
         PORTC.0 = 1;
         flag.1 = 1;                    // set fast blinking
         i2c_data [1] = 0xF6;           // erase command from stack  
         PORTC.0 = 1;                   // shutdown = 1 (inhibit charger)
         com_timeout_cntr = 0;
         flag.3 = 0;                    // enable com_timeout_cntr 
       }
    }
    // -----------------------------------------------------------------
    if(i2c_data[1] == 0x14)             // ChargingCurrent() on stack ?
    {
      load_ipwm();                      // set PWM
      i2c_data[1] = 0xF4;               // erase command
      flag.1 = 0;                       // set slow blinking
      com_timeout_cntr = 0; 
      flag.3 = 0;			// enable com_timeout_cntr 
    }
    //----------------------------------------------------------------
    if(i2c_data[5] == 0x15)             // ChargingVoltage() on stack ?
    {
      load_vpwm();                      // set output voltage
      i2c_data[5] = 0xF5;               // erase command
      flag.1 = 0;                       // set slow blinking
      PORTC.0 = 0;                      // shutdown = 0 enable charger
      com_timeout_cntr = 0;
      flag.3 = 0;			// enable com_timeout_cntr 
    }
    // -------------- setting LED blinking speed --------------------------
    //
    if(flag.1)                          // fast blinking green requested ?
    {                                   // or shutdown
      LED_counter++;
      if(LED_counter > 1)		// is it time to change status of LED ?
      {
         LED_counter = 0;               // if yes, clear counter 
         if(PORTB.2) PORTB.2=0;         // and toggle LED
         else PORTB.2 = 1;
      }
    } 
    if(!flag.1)                         // slow flashing green - charging 
    {
      LED_counter++;
      if(LED_counter > 4)		// time to change LED status ?
      {
         LED_counter = 0;               // if yes, reset counter
         if(PORTB.2) PORTB.2 = 0;       // and toggle LED
         else PORTB.2 = 1;
      }
    } 
  } // end of while
}   // end of main   
// ------------------------------------------------------------- 
//
void clear_smbus( void )
{
  TRISC.SDA = 1;                    // set as input
  TRISC.SCL = 1;                    // set as input
  //
  PORTC.SDA = 0;                    // to pull down SDA line when TRISC.SDA=L
 
  SSPCON.SSPEN = 0;                 // configure SDA and SCL pins as i/o pins
  //
  if( !PORTC.SCL) goto clsm1;       // SMBus traffic ? jum if yes
  Delay_10xUs_4MHz(1);
  if( !PORTC.SCL) goto clsm1;       // SMBus traffic ? jum if yes
  Delay_10xUs_4MHz(1);
  if( !PORTC.SCL) goto clsm1;       // SMBus traffic ? jum if yes
  //
  TRISC.SDA = 0;                    // SDA ->   ~~~\___    start
  Delay_10xUs_4MHz(1);
  TRISC.SDA = 1;                    // SDA ->   ___/~~~    stop
  //
  clsm1:
  PORTC.SDA = 1;
  TRISC.SDA = 1;                    // set as output
  TRISC.SCL = 1;                    // set as output
  SSPCON.SSPEN = 1;                 // cofigure SDA and SCL as serial port pins 
}
//
//--------------------------------------------------------------
// initialize voltage and current PWMs.
//--------------------------------------------------------------
void initiv( char a )
{
  if( a==1)
  {
    i2c_data[1] = 0x14;           // ChargingCurrent command
    i2c_data[2] = 0x64;           // charging current L byte
    i2c_data[3] = 0x00;           //                  H byte
    i2c_data[5] = 0x15;           // ChargingVoltage command
    i2c_data[6] = 0xFF;           // charging voltage L byte
    i2c_data[7] = 0xFF;           //                  H byte
  } 
  if( a==0)
  {
    i2c_data[1] = 0x14;           // ChargingCurrent command
    i2c_data[2] = 0x32;           // charging current L byte
    i2c_data[3] = 0x00;           //                  H byte
    i2c_data[5] = 0x15;           // ChargingVoltage command
    i2c_data[6] = 0xFF;           // charging voltage L byte
    i2c_data[7] = 0x8F;           //                  H byte
  } 
  load_ipwm();
  load_vpwm();
  // 
  i2c_data[1] = 0;
  i2c_data[5] = 0;
}
//-------------------------------------------------------------
// Measures thermistor and controls the charger accordingly.
// ------------------------------------------------------------
void ad_th( void)
{
  char *ptr;
  char i,j; 

  PORTA.5 = 1;				// use 3.32k pull-up  
  ad_val = 0;

  for( j=0; j<4; j++)
  {  
    PIR1.ADIF = 0;
    ADCON0.GO = 1;
    while(ADCON0.GO);

    ad_val = ad_val + ADRES;
  }
  PORTA.5 = 0;				// turn 3.32k pull-up off 
  ad_val = ad_val / 4;
  //
  ptr = &ad_val;                    
  val = *ptr;
  //
  if( val > 220)		        // -- thermistor too cold---------
  {
     flag.1 = 1;
     flag.2 = 1;
     initiv(1);
  }

  if( (val < 221) && (val > 121) )      // thermistor in-range -----------
  {
     if(flag.2)		                // returns from thermistor error 
     {
        initiv(1);                      // set trickle current
        PORTC.0 = 0;			// start charger
        flag.2 = 0;                     // clear thermistor error flag
     }
  }

  if( (val < 122) && (val > 34) )       // thermistor too hot -----------
  {
     flag.1 = 1;                        // LED fast blinking
     flag.2 = 1;		        // set thermistor  flag
     initiv(1);			        // set trickle charge   
  }  

  if( (val<35) && (val > 10) )          // Li ION  
  {
    if(flag.2)
    {
       initiv(0);
       PORTC.0 = 0;                     // start charger
       flag.2 = 0;                      // clear error flag
    }
  }
  if( val< 11)                          // Thermistor shoted 
  {
     flag.1 = 1;                        // grn LED fast blinking
     flag.2 = 1;		        // set thermistor  flag
     initiv(1);			        // set trickle charge   
  }
}
//----------------------------------------------------------------
// reads current values from i2c_dat[2] and i2c_data[3] locations,
// (L and H bytes) limits  the current, scales current word, and
// loadx PWM registers (10 bit mode)
//-----------------------------------------------------------------
void load_ipwm( void )
{
  long idata;
  char *ptr;
  bits ilowbits;
  //
  ptr = &idata;                     // get address of idata
  //
  *ptr = i2c_data[2];               // load L byte of idata
  *(ptr+1) = i2c_data[3];           // load H byte of idata
  //
  if(idata > 2600) idata = 2600;
  //
  idata >>=2;                       // scale idata 4096mA / 1024 = 4
  ilowbits = *ptr;                  // save L byte 
  //
  idata >>=2;                       // upper 8 bit of data
  //
  CCP2CON.CCP2X = ilowbits.1;       // load lower two LSBits of 10 bit word to PWM
  CCP2CON.CCP2Y = ilowbits.0;
  CCPR2L = *ptr;                    // load upper 8 bit of 10 bit PWM word
} 

//
//---------------------------------------------------------------------
// Reads voltage data from i2c_data[6] (L byte) and i2c_data[7] locations,
// assembles a 16 bit word. Limits the voltage at max 20V, scales vdata
//voltage data word and loads PWM with 10 bit data.
//------------------------------------------------------------------------
void load_vpwm( void )
{
  long unsigned vdata;
  char *ptr;
  bits vlowbits;
  //
  ptr = &vdata;                     // get address of idata
  *ptr = i2c_data[6];               // load L byte of idata
  *(ptr+1) = i2c_data[7];           // load H byte of idata
  //
  if(vdata < 8000) vdata = 8000;    // PWM1 0x000 =8V,  0x3FF = 20V
  if(vdata > 18000) vdata = 18000;  // limit incoming voltage to 20V
  //
  vdata = vdata-6000;               // 
  //
  vdata >>= 4;                      // scale vdata 22-6=16V,  16V/1024=16
  vlowbits = *ptr;                  // save L byte 
  vdata >>= 2;                      // upper 8 bit of data
  //
  CCP1CON.CCP1X = vlowbits.1;       // load lower two LSBits of 10 bit word
  CCP1CON.CCP1Y = vlowbits.0;       // to PWM 9-th and 10-th bits.
  CCPR1L = *ptr;                    // load upper 8 bit of 10 bit PWM word
} 
//---------------------------------------------------------------------------
void init_var( void )
{
//------INIT TMR0--------------  
//
  OPTION = 0b11010111;		// init timer 1, no pull-up at b (bit7=1)
                                // bit7 Port B pull-up enable (1=disable)
                                //      INTEDG 1=INT on rising of RBO/INT
                                //      TOCS TMR0 ck source 0 = internal
                                //      TOSE TMRO source edge 1=H->L on RA4
                                // bit3 PSA prescaler assign. 1=WDT, 0=TMR0
                                //      PS2:PS0 prescaler div. rate 2,4,8,16..
 
//--- TMR2 and PWMs ----------
//
  T2CON = 0x04;			// init timer, bit2 turns it on
                                // bit7 unimplemented
                                // bit6:bit3 postscalaer select 1,2,3..16
                                // bit2 TMR2ON 1=TMR2 on 0=TMR2 off
                                // bit1:bit0 prescaler div. 1, 4 or 16
//      
  CCP1CON = 0b00001100;		// init PWM1
                                // bit7 unimplemented
                                //      unimplemented
                                //      bit1 for 10 bit mode (0 for 8bit)
                                //      bit0 for 10 bit mode (0 for 8bit)
                                // bit3:0 mode select 11xx= PWM mode 
//
  CCP2CON = 0b00001100;		// init PWM2
  
// --- init port A --
  PORTA = 0;
  //        76543210
  TRISA = 0b11011011;           // RA5  3.32k       OUT
                                // RA4  header 4    IN
                                // RA3  header 3    IN
                                // RA2  33.2k       OUT
                                // RA1  UV          IN  
                                // RA0  analog in   IN
// ----init A/D------
  //         76543210
  ADCON0 = 0b01000001;          // Analog digital converter module
                                // bit7 ADCS1   A/D clock select 
                                //      ADCS0   01= fosc/8 -> tconv=16us
                                //      CHS2    channel selection
                                //      CHS1    
                                // bit3 CHS0    000 -> RA0
                                //      GO/DONE_ start conv/finished
                                //      unimplemented
                                //      ADON 1= a/d on 0=a/d off
  //         76543210
  ADCON1 = 0b00000100;          // b7:b3 not implemented
                                // b2:b0 analog port pin config.
                                // 100   RA0=analog  RA1=analog
                                //       RA2=digital RA3=digital, Vref=VDD

// ----init port B---
//
  PORTB  = 12;
  //        76543210
  TRISB = 0b11110011;           // RB7 (pin 28) -> header 11    IN
                                // RB6 (pin 27) -> header 10    IN
                                // RB5 (pin 26) DCOK input      IN
                                // RB4 (pin 25) -> header 5     IN
                                // RB3 red  LED                 OUT
                                // RB2 grn. LED                 OUT
                                // RB1 (pin 22) -> header 9     IN
                                // RBO (pin 21) -> header 8     IN
// ----init.port C---

  PORTC = 1;    
  //        76543210 
  TRISC = 0b11011000;		// init PORTC  	C.2 = CCP1 C.1 = CCP2
                                // RC7 (pin18) header 7
                                // RC6 (pin17) header 6
                                // RC5 (pin16) header 5
                                // RC4 (pin15) SDA  I2C data  -> input
                                // RC3 (pin14) SCL  I2C clock -> input
                                // RC2 (pin13) CCP1 PWM1 pin, -> output
                                // RC1 (pin12) CCP2 PWM2 pin, -> output
                                // RC0 (pin11) shutdown       -> output   

  // -------------------------
  CCPR1L = 10;                  // pulse width1
  CCPR2L = 10;                  // pulse width2
  PR2 = 255;                    // period time 200-> 200us

  //---setting-up I2C communication ----------
  //         76543210
  SSPCON = 0b00110110;      // sync serial port control register
                            // B7 WCOL=0    Write collision det. (SW reset)
                           
                            //    SSPOV=0   receive collision det (SW reset)
                            //    SSPEN=1   enable ser port ( SCK SDO open D)
                            //    CKP = 1   0=enable clock 
                            // B3:B0 SSPM2:SSPM0=0110 slave mode.
// --- timer interrupts--- 
  INTCON.T0IF = 1;          // reset TMR0 int flag
  INTCON.T0IE = 0;          // 1=enable TMR0 interrupt	

  PIE1.SSPIE = 1;           // enable i2c interrupt
  PIR1.SSPIF = 0;           // reset i2c interrupt flag
 
//  T1CON = 0x00;           // init TMR1, internal ck, prescaler div=1 

  i2c_data[0] = 0;          // clear address locations
  i2c_data[1] = 0;
  i2c_data[2] = 0;
  i2c_data[3] = 0;
  i2c_data[4] = 0;
  i2c_data[5] = 0;
  i2c_data[6] = 0;
  i2c_data[7] = 0;
  i2c_data[8] = 0;
  i2c_data[9] = 0;
}
