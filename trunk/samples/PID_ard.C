http://growdown.blogspot.com/2007/11/pid-code-for-arduino.html

skip to main | skip to sidebar growdown 
My efforts towards good work

Thursday, November 29, 2007
PID code for Arduino
 
Here is my PID code for Arduino or other microcontroller.  
It is unfinished and untested in this exact state, 
but it used to work on a PIC, so it cant be that broken, right?  
Once I get a chance to get it uploaded to my espresso machine and tested IRL,
 I'll publish it on the arduino wiki. If you use this and especially if you change it, 
 please drop a quick comment. (license at bottom) thanks!


float iState = 0;
float lastTemp = 0;
#define PGAIN_ADR 0
#define IGAIN_ADR 4
#define DGAIN_ADR 8
#define WINDUP_GUARD_GAIN 10float loadfloat(int address) 
{  
// must be written  
// this function return the float from EEPROM storage.   
// This is used for the P,I, and D_GAIN settings.  
// These are three values that need to be tuned after   
// the machine up and running to make the PID loop   
// work right.
}
float UpdatePID(float targetTemp, float curTemp)
{  
// these can be cut out if memory is an issue,   
// but they make it more readable  
float pTerm, iTerm, dTerm;   
float error;  
float windupGaurd;  
// determine how badly we are doing  
error = targetTemp - curTemp;  
// the pTerm is the view from now, the pgain judges   
// how much we care about error we are this instant.  
pTerm = loadfloat(PGAIN_ADR) * error;  
// iState keeps changing over time; it's   
// overall "performance" over time, or accumulated error  
iState += error;  
// to prevent the iTerm getting huge despite lots of   
//  error, we use a "windup guard"   
// (this happens when the machine is first turned on and 
// it cant help be cold despite its best efforts)  
// not necessary. this makes windup guard values   
// relative to the current iGain  
windupGaurd = WINDUP_GUARD_GAIN / loadfloat(IGAIN_ADR);    
if (iState > windupGaurd)     
iState = windupGaurd;  
else if (iState < -windupGaurd)     
iState = -windupGaurd;  
iTerm = loadfloat(IGAIN_ADR) * iState;  
// the dTerm, the difference between the temperature now  
//  and our last reading, indicated the "speed,"   
// how quickly the temp is changing. (aka. Differential)  
dTerm = (loadfloat(DGAIN_ADR)* (curTemp - lastTemp));  
// now that we've use lastTemp, put the current temp in  
// our pocket until for the next round  lastTemp = curTemp;  
// here comes the juicy magic feedback bit  

return pTerm + iTerm - dTerm;
} 





http://www.blog.nashlincoln.com/espresso/gaggia-espresso-pid-arduino-mod



Nash Lincoln
Gaggia Espresso PID Arduino ModNovember 25, 2007 at 8:49 pm · Filed under Espresso, Mods 

Modding the Gaggia Espresso:
Adding a PID temperature controller and computer interface.

This really isn’t about aesthetics, but I’ll probably clean up the install a bit.
Goal
The goal of this project is to create a computer interface for my Gaggia Espresso machine replacing the factory thermal switches with a PID controller and the “steam” and “pump” toggle switches with a LCD/button menu system.

Motivation
After seeing the various instructions and kits geared toward modding a home espresso machine with a PID, and their costs and features compared to something like the PID PIC MOD, I decided I would start from scratch and build my own PID. Then I could easily extend it to control the rest of the espresso machine, such as adding a timer to monitor or control the shot time and adding temperature presets.

Hardware
Parts list:

1x Arduino Decimillia 
1x 25A zero-cross SSR (for pump, could be much smaller, > 5A) 
1x 40A zero-cross SSR (for heating element, could be 25A) 
1x AD595 thermocouple conditioner/interface IC 
1x Type-K thermocouple (could use type T or possibly other) 
1x 16×2 character LCD with HD44780 parallel interface 
3x SPST normally-open momentary push-button switch 
10AWG stranded wire for 125V wiring (12AWG is probably good enough) 
22AWG solid wire for 5V wiring 
Power supply for Arduino 
Various resistors, capacitors, quick-disconnect connectors for 10AWG wire, etc. 
I’m using an Arduino Decimillia micro-controller which utilizes the AVR AtMega168. The hookup of the components is pretty straight-forward; The LCD uses 6 digital IO pins - 4 for a 4 bit parallel data bus, one for Register Select and one for Operation (data read/write) enable signal. The SSRs take one digital IO pin each. The AD595 takes one 10 bit AD converter pin. The three buttons share one external interrupt pin and use two digital IO pins to indicate which button has been pressed; with this scheme, one interrupt can be used with 2^n buttons taking only n+1 pins. Various resistors, capacitors and other components are used, but the details are rather tedious and boring.

Software
The software was written in the Arduino Programming Language, which is based on Processing and is similar to C++ with a few java-like syntactical niceties thrown in.

The main loop is executed at about 100Hz. During each iteration of the loop the AD595 is read and summed 100 times and after 100 iterations the average is taken and the current temp is updated. I started by oversampling 100x but found that that resulted in poor accuracy and provided many more readings than I was using. After some experimentation I found that oversampling 10,000 times gave great accuracy (about +/- 0.1 deg. Farenheit) and didn’t introduce any negative side effects due to excessive smoothing of the temperature curve. Also, since the PID period is one second, oversampling 10,000 times, giving me one reading per second, is just enough for the PID to have an updated reading at each iteration.

The PID algorithm is based off of this article: PID without a PHD. One of the bigger problems I had was tuning the PID, as seems to be the case for many people. What gave me such a hard time was all the instructions on the internet about how to tune a PID. Most say to start with Ki and Kd set to 0 and adjust Kp first. They go on to say that Ki can then be set to remove any static offset from the setpoint. Kd is said to be tricky to set and unnecessary for most applications.

After having trouble with that tuning technique and observing the system in operation a bit I realized that those instuctions wouldn’t work for me. The problem with relying on Kp to correct most of the error is that you have to be below the setpoint before any correction occurs (unless you add a constant positive error term to each reading). Because the system takes a few seconds to respond, the temp dips pretty low before it starts to reverse. Likewise, as the temp is climbing towards the setpoint, proportional error correction is applied right up until hitting the setpoint, at which point too much heat has been added and the temp overshoots the setpoint considerably. Adding ANY Ki just makes things worse. It dawned on me that the system was responding way too late, so the PID needed to anticipate the future state of the system in order to be effective. The future temp depends on two things, the current temp and the rate of change of temp. After observing that the temp would climb about 15 deg. after shutting off the boiler at maximum rate of change and doing some simple math to figure out what some reasonable values for Kd and Kp should be, I came up with settings which hold the temp to within +/- 1 deg. farenheit of the setpoint, and not more than 4 or 5 deg. of over/undershoot when turning on or recovering from steam mode. Intra-shot stability is also quite good usually dipping no more than a couple of deg. farenhiet and ending back at setpoint by the end of a 30 sec. 1.75 - 2 oz. shot. This is with Kd set to an aggressive 5x Kp and Ki set to 0. I believe this can be improved with further tuning of the PID parameters.

Because the boiler is either off or on, I use a PWM (pulse width modulation) technique to control the boiler. I treat the PID output as a percentage and keep the boiler on for that percent of a second, updating every second. Anything < 0% is treated as 0% and anything > 100% is treated as 100%. I round the output to the tens so that I limit the minimum on-off cycle time of the boiler to 0.1 seconds. This is for several reasons; anything faster is really unnecessary, it wears the SSR less and it limits the amount of EM interference caused by switching 1300 watts on and off that quickly.

Results
The machine works great! I get better stability and control than I was expecting, and it came together pretty quickly with no major problems. Additionally, I still need to finish fine-tuning the PID parameters to maximize stability.

As for the Espresso, that is a whole other subject that I will dedicate a whole post to, but for now I will say that I’m getting some great results with my local San Francisco favorites — Blue Bottle Espresso Temescal, Blue Bottle Roman Espresso and Coffee to the People’s Beatnik Espresso. I’ll be picking up some Blue Bottle Hayes Valley Espresso and some Blue Bottle Retrofit Espresso shortly.

What I have left to do:
Fine-tune the PID parameters 
Improve the accuracy of the temperature reading by using an equation to adjust for the slight non-linearity of the AD595 
Fix the sometimes flaky button circuit 
Save settings to EEPROM instead of reverting to defaults upon power cycle. 
Add persistent settings profiles that can be chosen via the setup menu. 
Calibrate the temp circuit 
Correlate the boiler temp to group head temp or add secondary thermometer to group head 
Show average error in +/- deg. F/C 
??? 
The program is still pretty beta, with some features requiring cleaning up and others needing to be implemented. When it’s a bit more finished I will post the GPL’d source code, if there is any interest.

If you thought this was interesting, check out the PID PIC MOD. It’s a surprisingly similar project with a Rancilio Sylvia and gave me some high-level ideas for my project.
Nash Lincoln

Permalink 

8 Comments » 
ArsGeek » Blog Archive » Super Geek Modified Gaggia Espresso Machine said,
December 2, 2007 @ 8:58 am 

[...] Nash Lincoln Modified a Gaggia Expresso Machine adding an LCD with buttons and programming an OS for the machine. It can keep the coffee a specific temperature and can even store different brew temperatures for your various favorite beans.read more | digg story Click the icon, share the link: These icons link to social bookmarking sites where readers can share and discover new web pages. [...]

links for 2007-12-05 « Mandarine said,
December 4, 2007 @ 10:22 pm 

[...] » Gaggia Espresso PID Arduino Mod The goal of this project is to create a computer interface for my Gaggia Espresso machine replacing the factory thermal switches with a PID controller and the “steam” and “pump” toggle switches with a LCD/button menu system. (tags: diy electronics cafe embedded) [...]

??????? ????????-????? at coffee*sponge: ??? ? ???? said,
December 5, 2007 @ 4:13 am 

[...] ?????? ??? ??????? ????????-?????? Gaggia Espresso ??? ?????????? ?? ??? ?????? ????? ??? ?????????. The goal of this project is to create a computer interface for my Gaggia Espresso machine replacing the factory thermal switches with a PID controller and the “steam” and “pump” toggle switches with a LCD/button menu system. [...]

hoeken said,
December 19, 2007 @ 11:01 am 

Hey,

I cant find your email, so hopefully this comment reaches you. Anyway, I’m very interested in looking at your code.

I’m part of the RepRap project, and we’re building an open source 3D printer. anyway, i’m experimenting with using a thermocouple + the AD595 chip, same as you. I’m also using an arduino, so when i found this article i was very happy.

Anyway, here’s what i need PID for. the way our print process works is that we have a plastic extruder (which is basically a fancy, computer controlled glue gun). this extruder has a heater and a thermocouple on it. I’m hoping to either use (or learn from) your PID code to create a rock solid temperature controller that can handle the heating.

please contact me at hoeken@rrrf.org

cheers!

expresso coffee beans said,
March 27, 2008 @ 1:03 pm 

expresso coffee beans…

Sebastian Rametta is the name, coffee is the game….

John said,
April 14, 2008 @ 7:46 am 

John…

Just wanted to drop a note to let you know what a great site you have. It is a great resource and a great place to drop by….

awdriven said,
May 20, 2008 @ 8:49 am 

I’m really interested in seeing your code as well. I’m working on a bbq smoker control that needs a PID routine to proportionally control a draft fan.

espresso coffee said,
May 27, 2008 @ 7:32 pm 

espresso coffee…

Maggie Hall…

RSS feed for comments on this post · TrackBack URI 

Leave a Comment
You must be logged in to post a comment.
Pages
Resume 
Archives
January 2008 
December 2007 
November 2007 
September 2007 
March 2007 
January 2007 
Categories
Computational Linguistics 
Espresso 
iPod 
Mods 
Uncategorized 
Meta
Register 
Log in 
Entries RSS 
Comments RSS 
WordPress 
  
Design by Beccary and Weblogs.us · XHTML · CSS 




http://growdown.blogspot.com/2006/11/custom-silvia-pid-mod.html


skip to main | skip to sidebar growdown 
My efforts towards good work

Sunday, November 26, 2006
Rancilio Silvia "PID PIC NES" mod
 


I have long admired the pioneering work of Rancilio Silvia owners in modding their espresso machines. Here, I present my Silvia given a PIC 16F876 microcontroller brain, a 20 character VFD display, nintendo controller, three zero-crossing solid state relays, IC thermometer, laser cut acrylic top, cold cathode ground effects and shot light. This project has stretched out for quite some time, and will likely continue on as I pick away at it some more. But for now, the bulk of the first wave of coolness is complete. First, a silly demo video, followed by a list of features and discussion.

 
PID
A microchip PIC16F876 gets temperature readings from a boiler-top mounted National LM34 Temperature Sensor. These temperature readings are processed using the PID control loop which I learned about in detail from the excellent article PID with out a PhD. A thrift store modder's favorite NES controller can set the PID gains, espresso and steam setpoints, temperature calibration values, and heater control PWM period. I wrote the NES code by reading a fantastic spec available from the iGamePlay project. The NES gamepad's popularity is well deserved as is a tough little controller with enough buttons to be useful, yet still very simple. For example, the select button switches between the main mode and setup mode, and the arrow buttons allow you to choose and alter variable values. It works out pretty cleanly. The main display currently shows a) the current temperature, b) the heater power setting (0 - 100 percent, which translates to a PWM heat amount), c) a timer showing how long the machine has been heating up, and d) a timer that alternates between a shot timer, and a timer showing how long the machine has been temperature stable and ready (remaining within 0.5 degrees of the set point).

One of the most interesting challenges so far has actually been tuning the PID loop. Currently though, after it settles, the machine appears to be indefinitely stable (I've seen it stable for over 2 hours before shutting off the machine) to about 0.1 degrees of the set point temperature. Interestingly, stability improved substantially after I finally closed the machine back up (after easily a year of being in terminal state of "operational dissassembly") and insulated the boiler from room drafts etc.


Shot Timer
One of the big motivations to go the distance and give the PIC total machine control was to enable a shot timer. When the top switch is thrown, it starts counting the seconds. It was basically a lot of work to make the machine act like it always does, but just so the PIC knows about it. The front panel switches are all "virtual" just pulling pins on the microcontroller which in turn throws the relays. One cool side effect of this is that starting a shot no longer makes a click sound on my stereo speakers. I think this is because the zero-crossing relays remove the spark-gap that occurs with a normal 120 switch (that's just a guess, but something changed because the grinder switch still sends out an electric 'pop' . . . for now).

A closeup of the VFD display showing a slightly outdated version of the interface.

Remote Control
Once I had the PIC sitting between the switches and the relays, and I had a NES controller setup to change PID values, my inner (or is that outer?) nerd forced me to add a useless "remote control" feature that replicates the front panel switches with the A, B, and start buttons on the gamepad. Eventually, I would like to put a solenoid on the steam wand valve so that I can call for water and steam completely with buttons and switches, and get rid of the squeeky knob (btw, does anyone know how to lubricate the steam valve with something more edible than WD-40?).

Bling
A combination 5v/12v power supply left the door open for some code cathode lights to sit on the 12v rail. While there is some utility in adding light under the brew head, this is mostly just silliness-- especially my "ground effects." A laser cut clear acrylic top allows for the VFD display to be viewable without undermining the sleek boxy shape of the Silvia. 

While there are still quite a few wires swimming around under the top, the overall number has been reduced, and it makes for a fairly clean appearance from above. I removed both top-mounted thermostats, and the switches have only 2 wires each instead of 4 going to each switch. Sadly, the little switch lights don't work. Though perhaps its possible to get them back?

Plumbing
I also drilled and plumbed a drain from the bottom of the drip tray. The plumbing technique was the great idea of a clever hardware store employee who showed me to the lamp parts section. The key ingredients are a threaded tube and low profile gnurled nut. A tube feeds a growler under the table and greatly reduces the number of spills from an overflowing drip tray. I am the kind of person who forgets to fill the water tank and empty the drip tray., so I really like this mod. I used to have the intake plumbed out to a remote water tank as well. It was great to be able to see the water level (a feature I hope to add for the internal tank), but ultimately it doesn't look as clean and the internal reservoir gives a little preheat to the water as well (Has anyone tried preheating their water out there, perhaps with a fish tank heater?). Heres two pics of the drain plumbing. 

A view down into the tray. I've since trimmed the top off the tube coming into the tray.

Underneath the drip tray, taking advantage of a factory access hole in the bottom of the machine.


Some Guts

I had originally planned to make space for the power supply and electronics by remoting the water tank, but everything ended up fitting. The electonics was luckily simple enough that I could just solder it all on a perf-board instead of needing a real circuit board (which would still be cool, especially if one were to make more of these...)

 Screw terminals on both ends of the perf-board work great as the interface to the rest of the machine. Plus, it's fun to wire stuff up solder-free with just a crimper and some terminals.

Well, if you made it this far, thanks for reading. I'll keep my eye on the comments section here if there are any questions. 
Posted by Tim Hirzel at 11:10 PM   
36 comments: 
Anonymous said... 
Hi Tim - you've made a really, really nice job there. Well Done! I'd love to see more construction details since this looks like a great mod to do.

5:40 AM  
Alexander said... 
btw, does anyone know how to lubricate the steam valve with something more edible than WD-40?

You can use any food-grade oil, such as canola, safflower, peanut (unless you have an allergy) or whatever floats your boat. Simply put it onto the end of a q-tip and swab it where it needs to go.

12:00 PM  
Anonymous said... 
You can use food-grade oil, as alexander said. A longer-lasting, but more expensive solution would be the food-grade grease Chris Coffee and other online merchant sell.

1:23 PM  
Robin said... 
Wow! I'll take a double, please.
Have the Rancilio Silvia people seen this yet?
Do you get a special drink if you do the special secret NES code? (Was it down-down-up-down-left-right-left-right?)
Amazing.

4:41 PM  
Adrian said... 
Fantastic job mate!

10:43 PM  
erik said... 
A good food-grade lubricant is super lube. I have run the mistake of using wd-40 (actually someone else did it before I could stop them) 
and it is a horrid mess on food appliances. It not only tastes awful but penetrates many metal surfaces so it is really hard to get out. 
Don't do it.

BTW, the mod is fantastic. All you need now is a tcp/ip stack, an ethernet port and a webserver.

1:29 PM  
dan b said... 
very cool, i just started planning a pic pid myself the past couple weeks, so i'm psyched to find this. couple 
thoughts: how accurate do you think the lm34 is? everyone now seems to be sold on tapping the boiler and using 
type t tc's for speed and accuracy. 

also, seems like you could add preinfusion pretty easily by opening the solenoid and delaying the pump. yesno?

4:20 PM  
Tim Hirzel said... 
Thanks everyone for reading about my mod. Thanks for the lubrication tips as well! erik, you are right on about 
running a little web server in there with saved performance data and a web interface for tuning. one of the 
rabbit semiconductor board would be great for that.

dan b. I am far from an expert on temperature sensing. In fact, I picked this device because it gives you temp 
readings in the easily digestible 0.1 volts / degree. I had a moment about whether I should be using a thermocouple , 
but my friend casey (who is much better than I am this kind of stuff) said it was pretty much gonna be the same thing. 
While drilling the boiler makes a little sense for speed (though, once the thermostats are gone, are people using those 
tapped holes instead?) the whole system in inherently slow. Seems like splitting hairs for temp sensing. When you 
pull 
a shot, its gonna take a few minutes to get settled back with the stock heating element. Whats the hurry? ;) 
Also, I am taking thousands of measurements and averaging them, which I think de-noises the sensor quite a bit. 

preinfusion? I gotta google that, but it sounds cool. If it takes what you describe, then yeah, 
it would be no problem.

oh yeah, in terms of drawings and stuff. I'll have to see if I have anything useful. I really stumbled my 
way through this (it really did take years to complete), and broke a bunch of stuff on the way. One thing 
that was really helpful, the drawings and schematics here: http://www.espressotec.com/ummanual.asp#rancilioparts

i studied that schematic with a beer for countless evenings to figure it out, but it was vital.

10:34 PM  
Anonymous said... 
Now we just need a Yoshi Suger Cube maker...

www.dozingo.com

2:43 PM  
Nick said... 
This post has been removed by the author. 
10:13 PM  
Nick said... 
Bad ass dude. Mad props.

10:15 PM  
yiqin said... 
this is a really great mod.

3:46 AM  
Old Timey Dave said... 
This kick ass for sure... I'd love to post a link to it on our blog. Let me know.

12:00 PM  
Tim Hirzel said... 
feel free to post anything: pics or a link to my boring video! :)
thanks all,
tim

11:17 PM  
Fritz said... 
Very, very nice - have you fixed the drip tray into the chassis? 

I want to do the drain mod and I've been tossing around fixing the tray in there to simplify the draining etc.

Have you got any pictures with the tube trimmed down?

6:45 AM  
Mitch Gurowitz said... 
Wow, I can only begin to imagine what you could do with a wireless Wii controller! 

And to think that I thought a PID was ambitious!

11:35 PM  
Jared C. said... 
Very nice work!!! I'm extremely impressed. You have done something here like no one else has done before you. I guarantee there will be some interest (and jealousy) in you project.

I posted a link to here from www.coffeegeek.com, because this project very much deserves some visibility and credit from those folks there.

Keep up the good work! I expect to see Rocky integrated into your system soon! ;-)

3:10 AM  
Anonymous said... 
This post has been removed by a blog administrator. 
10:42 PM  
Olman Feelyus said... 
You are mad, truly mad. You must have been thrown out of the academy in Prague.

9:42 PM  
Anonymous said... 
props to that

www.the-ultimate-solution.net

Get Rich Quick Home Business Scams

11:26 AM  
DW said... 
Tim, I have some questions about how to use my PID. 

Can you drop me an email?

Dougwamble at g mail

Much appreciated if you have a moment...

10:07 PM  
Anonymous said... 
wath a beautiful idea! 
but which kind of coffe you use? here in Italy I can find some of best and optimal quality, but them in America? it is possible to find them?

btw, nice work! ^_^

=nil=

2:12 AM  
Sysadmn said... 
FWIW, WD-40 is not a lubricant. It's designed for Water Displacement, and it's more like a lacquer. As it ages, it gets really gummy. 
http://www.google.com/search?q=wd-40+gummy+lubricant&sourceid=navclient-ff&ie=UTF-8&rlz=1B3GGGL_en___US215

9:24 AM  
Anonymous said... 
Hi Tim,

I like your site very much. You may be interested in my PIC18F4523-controlled Rancilio Silvia that shares some of the features 
you implemented: http://silviatune.googlepages.com/index.html

-pn

3:18 PM  
resort in the philippines said... 
This post has been removed by a blog administrator. 
5:05 PM  
? said... 
This post has been removed by a blog administrator. 
8:36 PM  
? said... 
This post has been removed by a blog administrator. 
8:37 PM  
? said... 
This post has been removed by a blog administrator. 
8:37 PM  
? said... 
This post has been removed by a blog administrator. 
8:37 PM  
? said... 
This post has been removed by a blog administrator. 
8:38 PM  
? said... 
This post has been removed by a blog administrator. 
8:38 PM  
? said... 
This post has been removed by a blog administrator. 
8:39 PM  
? said... 
This post has been removed by a blog administrator. 
8:39 PM  
? said... 
This post has been removed by a blog administrator. 
9:45 PM  
Will Custom Machining said... 
Very creative custom machininig work, its art and funcitonal =), have a good one and keep up the creative work, i'll be back to view more pics of any future projects.

Will

6:37 PM  
Anonymous said... 
Hey, I just stumbled upon this while looking for NES projects, but thought you might like to know this would be perfect for the Hungry Scientist contest being held on Instructables.com right now. This is the link if you're interested: http://www.instructables.com/contest/hungryscientist/

3:09 PM  
Post a Comment 

Links to this post
  Death By Link - August Part I  
- If I could get my hands on a Super Genintari, I would name my first born child after it. It plays Atari 2600, NES, Sega Genesis, and SNES games. - Build your own USB NES controller... with a 2gb memory stick full of games on it. ... 
Posted byBigKilla at3:42 PM 
  Gaggia Espresso PID Arduino Mod  
Goal. The goal of this project is to create a computer interface for my Gaggia Espresso machine replacing the factory thermal switches with a PID controller and the “steam” and “pump” toggle switches with a LCD/button menu system. ... 
Posted bynashira_lincoln at9:49 PM 
  Me identifico con este tipo!!!  
Miren lo que encontre en la red!!!! Trabajo Inspirador!!! Rancilio Silvia “PID PIC NES” mod 1000+ puntos Geek!!! 
Posted byxenomuta at11:48 PM 
  Silvia PIC controlled PID looped Espresso Machine  
Filed under: misc hacks. Last night I rebuilt my ECM Giotto with a new boiler. I've seen PID controlled machines before, but today I stumbled across this modded Rancillo Silvia. [Tim] replaced the internal brain with a PIC controller, ... 
Posted byWill O'Brien at6:28 PM 
  Dale una nueva vida a tu clásica Nintendo  
Con el paso de los años, he comenzado a preguntarme si podría encontrar otro uso para mi vieja amiga la NES. Odio tenerla escondida en el fondo del armario, llena de polvo y de arañas, cuando ella podría ser reutilizada para un ... 
Posted byFalfon at2:31 PM 
  10 ideas para reciclar tu antigua NES  
Tú, si, tú, tú tenías la NES. Y Hora, ¿donde está tu vieja consola? Aquella cajita con la que derrotaste a Galon en el Zelda, con la que llegaste a los últimos niveles del Super Mario, con la que te erigiste campeón de tu casa del ... 
Posted byEl Staff at3:51 AM 
  Breathe new life into your classic NES console  
Filed under: fix-it, household hacks, recreation, weekend projects, audio and video, computers and internet, geek it yourself, electronics. Whenever I think of my original Nintendo Entertainment System (NES), I get a warm, ... 
Posted byDan Chilton at8:00 AM 
  Rancilio Sylvia: Two months of great coffee  
The new machine is fabulous. It took a few days to start getting the hang of consistently good shots, but those first few cups made me realize what great espresso was really all about. My first thoughts were, literally, “Oh my God, ... 
Posted byJoe at12:35 AM 
  [La semaine spéciale NES] : La machine à Expresso NES  
Voici une machine à expresso controlée par une manette de NES. A quoi cela sert-il ? Absolument à rien !! Juste le plaisir d'obtenir son café après avoir pressé le bouton d'une manette de console. La personne a aussi fait quelques ... 
Posted bynoreply@blog.playersrepublic.fr (Arnaud BONNET) at3:55 PM 
  Rancilio Silvia "PID PIC NES" mod  
NES Controllers can control many things, newly included is this NES Controlled Expresso maker http://growdown.blogspot.com/2006/11/custom-silvia-pid-mod.html. 
Posted byMark Aka knoppy44 at1:02 AM 
  ??????????????????????????(??)  
?????????DIY??????? ?????????????????????????????????????????????????…? ??????????????????????????????????????????????? ... 
Posted by at6:00 AM 
  NESilvia  
Speaking of home machines... I don't know what it is that the old skool Nintendo controller does on this Rancilio Silvia... but I like it. :-D. 
Posted byNick at10:11 PM 
  NES gamepad controls espresso machine  
Filed under: Culture, Hacks. There's nothing like reminiscing about the go-go '80s, the decade that gave us the NES and the cocaine craze that would eventually be displaced by the "less addictive" espresso fad. (Just go with us. ... 
Posted bywebmaster at5:55 PM 
  NES gamepad-controlled espresso machine  
Filed under: Misc. Gadgets, Household. We've touted the benefits of espresso machine modding in the past, but Tim Herzel has taken the dark art to even geekier caffeine-fueled heights with his latest contraption, an espresso machine ... 
Posted byDonald Melanson at2:03 PM 
  DIY HACK - NES Controlled Espresso Machine  
http://zedomax.com/image/200612/espresso.jpg. Here’sa cool NES controlled espresso machinery! …a PIC 16F876 microcontroller brain, a 20 character VFD display, nintendo controller, three zero-crossing solid state relays, IC thermometer, ... 
Posted bymax at6:55 PM 
  vacation, continued  
Still on vacation. I’ma motivated type person, so it’s tough for me to just hang out around the house. Though I’m realizing that to dedicate these few days playing with my kids and taking care of Meg are both much needed and well worth ... 
Posted byken at9:39 AM 
  Coffee-Modding Wakes Up  
We’re all about modding your stuff here at the CG, from computer cases to cell phone unlock codes and everything in between. But sometimes something comes across our desks that make us take notice and wonder, “wha? ... 
Posted byMatt Hickey at3:13 PM 
  NES Controlled Espresso Machine  
If you like video games, this NES Espresso Machine allows you to wake up with caffeine and a game controller in your hand. “I have long admired the pioneering work of Rancilio Silvia owners in modding their espresso machines. ... 
Posted byAlan Parekh at6:32 AM 
Create a Link 

Newer Post Older Post Home 
Subscribe to: Post Comments (Atom) Blog Archive
? 2008 (8) 
? July (2) 
Half Bot, All Boat. 
iphone apps that look cool 
? May (1) 
Improvements to Arduino Wii Nunchuck connection 
? April (2) 
PID Tuning Application for Arduino Silvia Mod 
Arduino and Silvia: Two Italians, One Tangled Affa... 
? March (2) 
Rancilio Silvia Top CAD Files 
Non contact Voltage Presence Measuring for Applian... 
? February (1) 
Narcoa? But I hardly even know'er! 
? 2007 (5) 
? November (2) 
Magically Vectorious 
PID code for Arduino 
? October (3) 
Inside Quonset Nation 
Fort Quonset 
I heart Arduino 
? 2006 (3) 
? November (1) 
Rancilio Silvia "PID PIC NES" mod 
? January (2) 
Ipod as Field Guide 
Ipod Nano Wristwatch Hack 
? 2005 (8) 
? December (5) 
Sub Zero Montana 
The Christmas Stroll 
Upside Down Hanging Christmas Tree 
Icicalus Maximus 
A Cold Night In Bozeman 
? October (3) 
Halloween Goodness 
"Artificial" Tree 
Starlit Shelving 
 About Me
Tim Hirzel 
View my complete profile 
  




http://web.mit.edu/6.111/www/s2004/PROJECTS/2/game.htm





 << INTRODUCTION >>


<< OVERVIEW >>


<< AUDIO >>


<< GAMEPLAY >>


<< VIDEO >>


<< IMPROVEMENTS >>


<< ZBT RAMS >>


<< TIPS AND TRICKS >>


<< NES INPUT FSM >>


<< TOOLS >>


 Input / Game Logic 

There are two obvious tasks in this section of the iGamePlay project. 
The input component must interface with users, 
ensuring that each player has a direct say in the flow and variation of any single game. 
The game logic component must preserve and update the continually varying game state, 
driving information about crucial game objects to the video output unit. 

User Input 

For the iGamePlay project, we decided to use two Nintendo Emulation System (NES) 
controllers as input devices. The gamer generation has extended familiarity with this device, 
and its use is straightforward. Beyond that, the system interface for NES controllers is rather simple. 
Unlike analog controllers and joysticks, the NES joy pad only has buttons. At any time, each button is 
either idle (off) or depressed (on). The only task that the user input module must perform is to 
sample all eight NES buttons at some frequency. 





  

Figure 6. Physical Interface to NES Controller 
The physical interface to the NES controller is a simple one. Only five wires connect each NES pad 
to the iGamePlay kit. There are four controller inputs (power, ground, latch and pulse) and 
one controller output (data). Since there is only one data line, buttons states must be transferred 
serially. An input finite state machine within the project handles all controller communications, 
according to the input protocol shown in Figure 7. A latch signal from the input FSM initiates a 
transaction sixty times every second. Latch is held high for twelve microseconds, after which the 
first data value (“A”) is guaranteed to be valid. After reading the value, the input sends seven 
six-microsecond pulses out on the pulse wire. After each one, it reads a new button value from the 
data line, which the controller will drive there in the order “B,” “Select,” “Start,” “Up,” “Down,” 
“Left,” and “Right.” See Appendix D for Verilog code that implements this communication protocol. 


Figure 7. Nintendo Emulation System Input Protocol 
A major concern with any asynchronous user input to a digital system is registering and steadying user 
data. In this case, the user presses keypad buttons that may bounce after the first touch until they 
finally settle. To prevent asynchronous data from ruining the careful timing of the digital system, 
the inputs are first registered on the system clock. In some scenarios, it is helpful to also build a 
button delay, to ensure that a user meant to perform the chosen action. For example, when the user 
chooses a menu option, the system waits for 100 ms of valid user data to ensure that any button press 
is intentional. However, such “debouncing” of user input is not always beneficial: when a user wants 
to shoot a missile, it is important that the action is completed immediately. Because demand for button 
debouncing varies even across different uses of the same keys, debouncing is performed locally as 
needed, and not dealt with in or around the input FSM. 

Game Logic 

Beat 

The game logic portion of the iGamePlay project is the section of code that is the least 
native to a hardware implementation. The game logic component is a large finite state machine 
built on several other game object FSMs. The interactions between the modules are often complex 
and tedious in hardware (i.e. collision detection), and as a result take up a lot of FPGA realty.
 Figure 8 shows an overview of the game logic component. 


Figure 8. Game Logic Overview 
The minor FSMs for players, missiles and enemies are all primarily movement oriented. They control 
the positions of game objects in response to user input in the case of the players, a beat signal 
in the case of the enemies, and a target’s position in the case of the missiles. However, such movements
 are predicated on the “liveness” of objects. Hardware restrictions do not allow the allocation of many 
 missile or enemy structures, and as a result the viable number of missiles and enemies were experimentally 
 capped at sixteen. At no one time will all enemies and missiles be active. Instead, the game logic cycles 
 through idle (expired or collided) missiles, keeping track of the current missile and enemy indices, and 
 reactivating them as new game objects with the spawn signal and a set of initial coordinates. When it is 
 time for the game objects to disappear again (whether via expiration or collision), missiles and enemies 
 are given an active reset signal. 


The operations that require knowledge about more than one game object all take place in the main game loop. 
The most visually prominent and also most difficult multi-object actions are collisions, which can lead 
to any of the following outcomes: player bounce, player death, enemy splitting, enemy death, and missile 
death. The reason why collisions are so tricky is that each collision requires several large comparators 
to check for proximity, and the total number of collision checks is in the hundreds. To solve this problem, 
the iGamePlay system uses a single collider module that checks proximity of its inputs. The system examines 
collision candidates in sequence, an inefficiency that is made possible by the high system clock speed. At 
a clock frequency of 27 MHz, and a movement rate of one tick per 100 milliseconds, the system has many 
thousands of clock cycles to check collisions between movements. 


Figure 9. Game Loop Finite State Machine 
While the focus of the game logic is mainly on game play and game content, the main loop also performs 
several functions that gamers might take for granted in games. See Figure 9 for a diagram showing the 
transitions of the game loop FSM. The system deals with game play aspects in the PLAY loop: collisions 
(as described above), player death and victory, and missile firing. Beyond this, the system keeps 
track of levels, changing the level in the transition from PLAY back to SETUP. With each higher level, 
missiles and enemies speed up, presenting a larger challenge to the player, whose own speed remains unchanged.
SETUP is a good place to provide level information to the video system, though project time constraints
 forced us to bypass this feature. The system also implements a Mario-style menu interface, allowing the user 
 to switch a selector between editing game mode and starting a match. Finally, the WIN state provides an 
 opportunity to present game results to the video system, which could output whether player one, player two,
  or the enemy won the match. Due to project time constraints, this implementation did not contain such a 
  summary screen, instead skipping through to the RESET state. 
    
http://web.mit.edu/6.111/www/s2004/PROJECTS/2/game.htm