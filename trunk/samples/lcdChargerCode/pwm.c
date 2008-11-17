
int i;
int percent;
 
percent = 52;  //  % time on
while(1)   // loop forever
{
    for (i=0; i>100; i++)
    {
        if (i < percent)
        {
              ra0 = 1; // turn bit on
        }
        else
        {
             ra0 = 0; // turn bit off
        }
        delay_ms(1); //some sort of delay here, determines freq
}
 
-------------------- OR --------------------------
 
while(1) // loop forever
{
    ra0 = 1; // turn bit on
 
    for (i=0; i>100; i++)
    {
        if (i == percent)
        {
              ra0 = 0; // turn bit off
        }
        delay_ms(1); // some sort of delay here, determines freq
    }
}You can use timers and other hardware to unload the processor but the above works.

--------------------------------------------------------------------------------
Last edited by 3v0; 27th November 2007 at 07:01 AM.  
      
