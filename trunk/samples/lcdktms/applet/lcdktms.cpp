#include <LiquidCrystalKtms.h>

/*uint8_t  nsck=2,    //3
si=3,  //4
cd=4,  //5
nreset=5,  //6
nbusy=6,   //7
ncs=7; //8
*/
#include "WProgram.h"
void setup();
void loop();
LiquidCrystalKtms lcd(2,3,4,5,6,7);
   char msg1[13] ={0};
   char msg2[] ="012345678901";
void setup()                    // run once, when the sketch starts
{
}





void loop()                     // run over and over again
{

  // lcd.home();delay(100);
  //lcd.clear();delay(100);
  ltoa( 123456, msg1, 10);
  
  digitalWrite(7, 0); //delay(1);
  lcd.print( msg1);
  digitalWrite(7, 1);
  
  delay(1000);
  
  
  //lcd.clear();delay(100);
  //lcd.home();delay(100);
  
  digitalWrite(7, 0);//delay(1);
  lcd.print( msg2);
  digitalWrite(7, 1);

  delay(1000);
}


int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

