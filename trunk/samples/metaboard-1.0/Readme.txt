What is Metaboard?
==================

Metaboard is a USB based prototyping board for Atmel's AVR microcontrollers.
It was designed to meet the following criteria:

 - Low complexity and thus extremely low price.
 - Single sided PCB so that the board can be manufactured at home. If
   professionally manufactured, a single sided board is still cheaper.
 - No SMD components. Easy to assembler at home.
 - (Mostly) compatible with Arduino (www.arduino.cc) in board dimension
   and connector layout. Can also be programmed by Arduino's development
   environment via USB.
 - No upfront investment for development environment or programmer hardware.
 - Breadboard area on board.
 - Completely Open Source.

Metaboard meets these criteria in conjunction with the boot loader
USBaspLoader which emulates USBasp (an ISP programmer for AVRs which is
supported by avrdude).


What Resources are Available for Metaboard?
===========================================

Metaboard can either be used with the free GCC tool chain or with Arduino's
free Integrated Development Environment. Arduino offers a set of example
projects, documentation and a user community which is especially helpful
for the beginner. Since Metaboard is not entirely equivalent to the Arduino
board, not all example projects can be used out of the box. We plan to offer
example projects made especially for Metaboard.

The GCC toolchain can be dowloaded from:
 - Windows: http://winavr.sourceforge.net/
 - Mac OS X: http://www.obdev.at/avrmacpack/
 - Linux and other Unixes: See
   http://www.nongnu.org/avr-libc/user-manual/install_tools.html

Example projects based on GCC can be found at http://www.obdev.at/avrusb/.
Since these examples have not been developed for Metaboard, they must be modified with Metaboard's pin assignments and clock rate.

All resources related to Arduino can be found at http://www.arduino.cc/.

Metaboard can be downloaded from http://metalab.at/wiki/Metaboard.
USBaspLoader is available at http://www.obdev.at/avrusb/usbasploader.html.


Why Another Board, Why Not Use Arduino?
=======================================

The main reason is the price. A prototyping board must be as cheap as
possible, otherwise it's too valuable to be used for quick and dirty
experiments. You can get two Metaboards for the price of one Arduino
Diecimila. Another good reason is the direct USB implementation. You can
implement any type of device: Keyboards, Mice, Joysticks etc. with Metaboard.
No special drivers for the FTDI chip are needed.


Other "Why / Why Not" Questions
===============================

 - Why not add an ISP connector? The ISP connector is only used once to flash
   the boot loader into the chip. Since this can be done in an external
   programming socket and the chips can be delivered pre-programmed, we
   rather save valuable board space in favor of the breadboard area. If you
   absolutely need an ISP connector, solder it to the breadboard area.
 - Why not run the AVR on 3.3 V? The AVR's maximum clock rate for 3.3 V is
   ca. 10 MHz. Since we want 16 Mhz, we must use 5 V.
 - Why use a jumper to activate the boot loader? The jumper is the easiest
   and most reliable solution, and it's neutral when not in boot-loader
   mode. Yes, there exist more elegant solutions such as toggling boot loader
   mode after each manual reset and having a status LED to indicate boot
   loader mode, but the LED adds a load to the pin which is not neutral
   during normal operation.


---
(C) 2008 by Christian Starkjohann.
