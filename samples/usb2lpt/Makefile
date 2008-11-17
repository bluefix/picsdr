
DEVICE = atmega8
#DEVICE = atmega48
AVRDUDE = avrdude -c pony-stk200 -P lpt1 -p $(DEVICE) -E noreset

COMPILE = avr-gcc -Wall -Os -Iusbdrv -I. -mmcu=$(DEVICE)

OBJECTS = usbdrv/usbdrv.o usbdrv/usbdrvasm.o usbdrv/oddebug.o usb2lpt5.o

# Implizite Regeln und symbolische Ziele:
all:	usb2lpt5.hex

disasm:	usb2lpt5.lst

.c.o:
	$(COMPILE) -c $< -o $@

.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" erforderlich, falls unter Windows die Endung .S
# wegen irgendetwas ein Kleinbuchstabe wurde

.c.s:
	$(COMPILE) -S $< -o $@

flash:	all
	$(AVRDUDE) -U flash:w:usb2lpt5.hex:i


# ATmega8 fuses:
# Fuse high byte:
# 0xc9 = 1 0 0 0   1 0 0 1 <-- BOOTRST (boot reset vector at 0x0000)
#        ^ ^ ^ ^   ^ ^ ^------ BOOTSZ0
#        | | | |   | +-------- BOOTSZ1
#        | | | |   +---------- EESAVE (don't preserve EEPROM over chip erase)
#        | | | +-------------- CKOPT (full output swing)
#        | | +---------------- SPIEN (allow serial programming)
#        | +------------------ WDTON (Watchdog immer EIN)
#        +-------------------- RSTDISBL (reset pin is enabled)
# Fuse low byte:
# 0x9f = 1 0 1 0   1 1 1 0
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL 3..0
#        | |  +--------------- SUT 1..0 (minimale Hochlaufzeit: 12 ms)
#        | +------------------ BODEN (BrownOut Detector enabled)
#        +-------------------- BODLEVEL (2.7V)

# ATmega48 fuses:
# Fuse high byte:
# 0xDD = 1 1 0 1   1 1 0 1
#        ^ ^ ^ ^   ^ ^-^-^---- BODLEVEL	(2.7V)
#        | | | |   +---------- EESAVE	(don't preserve EEPROM over chip erase)
#        | | | +-------------- WDTON	(Watchdog Timer Always On)
#        | | +---------------- SPIEN	(Enable Serial Programming)
#        | +------------------ DWEN	(debugWIRE Enable)
#        +-------------------- RSTDISBL	(External Reset Disable)
# Fuse low byte:
# 0xEF = 1 1 1 0   1 1 1 1
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL
#        | |  +--------------- SUT	(Quartz crystal - 6 ms startup)
#        | +------------------ CKOUT	(no output)
#        +-------------------- CKDIV8	(no division)
ifeq ($(DEVICE),atmega8)
 HFUSE = 0x89
 LFUSE = 0xAE
else
 HFUSE = 0xDD
 LFUSE = 0xEF
endif
 
fuse:
	$(AVRDUDE) -U hfuse:w:$(HFUSE):m -U lfuse:w:$(LFUSE):m

clean:
	rm -f usb2lpt5.hex usb2lpt5.lst usb2lpt5.bin *.o usbdrv/*.o

# Dateien:
usb2lpt5.bin:	$(OBJECTS)
	$(COMPILE) -o usb2lpt5.bin $(OBJECTS)

usb2lpt5.hex:	usb2lpt5.bin
	rm -f usb2lpt5.hex
	avr-objcopy -j .text -j .data -O ihex usb2lpt5.bin usb2lpt5.hex

usb2lpt5.lst:	usb2lpt5.bin
	avr-objdump -d usb2lpt5.bin > usb2lpt5.lst
