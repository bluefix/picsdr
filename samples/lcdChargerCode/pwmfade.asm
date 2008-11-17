;andy fade some lights


	list P=16f628a
#include <p16f628a.inc>
	__config _INTOSC_OSC_NOCLKOUT & _BODEN_OFF & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _DATA_CP_OFF & _CP_OFF 
	ERRORLEVEL -302
	
	cblock		20h
	BH,BL,wait,del_clk1,del_clk2,run,runn
	endc
	
	bsf	STATUS,RP0		;bank 1
	movlw	0x00
	movwf	TRISB		;make all PORTB outputs
	movlw	0xff
	movwf	TRISA		;make all PORTA inputs
	bcf	STATUS,RP0
	
	movlw	0x07		;turn off comparitors
	movwf	CMCON
	

	
start
	movlw	0x44			;adjustment for speed of fade
	movwf	runn
	btfss	PORTA,0			;call to see if low, if low make fade slower
	call	slower
	btfss	PORTA,1			;call to see if low, if low make fade faster

	call	faster	
	call	firstt
	call	secondd
	call	thirdd
	call	fourthh
	call	fifthh
	call	sixthh
	call	seventhh
	call	eighthh
	call	ninthh
	call	tenthh
	call	ninthh
	call	eighthh
	call	seventhh
	call	sixthh
	call	fifthh
	call	fourthh
	call	thirdd
	call	secondd
	goto	start

firstt
	movf	runn,0
	movwf	run
first
	movlw	0xff
	movwf	PORTB		;turn on leds
	movlw	0x01		;set on time of duty cycle
	movwf	BH
loop
	decfsz	BH,1		;count down the on time
	goto	loop
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x01		;set off time of duty cycle
	movwf	BH
loop2
	incfsz	BH,1		;count up to the off time
	goto	loop2
	decfsz	run,1	;run the PWM for a moment
	goto	first
	return
	
secondd
	movf	runn,0
	movwf	run	
second
	movlw	0xff
	movwf	PORTB		;turn on leds
	movlw	0x03		;set on time of duty cycle
	movwf	BH
loopa
	decfsz	BH,1		;count down the on time
	goto	loopa
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x03		;set off time of duty cycle
	movwf	BH
loop2a
	incfsz	BH,1		;count up to the off time
	goto	loop2a
	decfsz	run,1	;run the PWM for a moment
	goto	second
	return


thirdd
	movf	runn,0
	movwf	run
third
	movlw	0xff
	movwf	PORTB		;turn on leds
	movlw	0x05		;set on time of duty cycle
	movwf	BH
loopb
	decfsz	BH,1		;count down the on time
	goto	loopb
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x05		;set off time of duty cycle
	movwf	BH
loop2b
	incfsz	BH,1		;count up to the off time
	goto	loop2b
	decfsz	run,1	;run the PWM for a moment
	goto	third
	return


fourthh
	movf	runn,0
	movwf	run
fourth
	movlw	0xff
	movwf	PORTB		;turn on leds
	movlw	0x07		;set on time of duty cycle
	movwf	BH
loopc
	decfsz	BH,1		;count down the on time
	goto	loopc
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x07		;set off time of duty cycle
	movwf	BH
loop2c
	incfsz	BH,1		;count up to the off time
	goto	loop2c
	decfsz	run,1	;run the PWM for a moment
	goto	fourth
	return

	
fifthh
	movf	runn,0
	movwf	run
fifth
	movlw	0xff
	movwf	PORTB		;turn on leds		
	movlw	0x09		;set on time of duty cycle
	movwf	BH

loopd
	decfsz	BH,1		;count down the on time
	goto	loopd
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x09		;set off time of duty cycle
	movwf	BH
loop2d
	incfsz	BH,1		;count up to the off time
	goto	loop2d
	decfsz	run,1	;run the PWM for a moment
	goto	fifth
	return


sixthh
	movf	runn,0
	movwf	run
sixth
	movlw	0xff
	movwf	PORTB		;turn on leds
	movlw	0x11		;set on time of duty cycle
	movwf	BH

loope
	decfsz	BH,1		;count down the on time
	goto	loope
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x11		;set off time of duty cycle
	movwf	BH
loop2e
	incfsz	BH,1		;count up to the off time
	goto	loop2e
	decfsz	run,1		;run the PWM for a moment
	goto	sixth
	return
	
	
seventhh
	movf	runn,0
	movwf	run
seventh
	movlw	0xff
	movwf	PORTB
	movlw	0x17		;set on time of duty cycle
	movwf	BH
loopf
	decfsz	BH,1		;count down the on time
	goto	loopf
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x17		;set off time of duty cycle
	movwf	BH
loop2f
	incfsz	BH,1		;count up to the off time
	goto	loop2f
	decfsz	run,1	;run the PWM for a moment
	goto	seventh
	return
	

eighthh
	movf	runn,0
	movwf	run
eighth
	movlw	0xff
	movwf	PORTB
	movlw	0x25		;set on time of duty cycle
	movwf	BH
loopg
	decfsz	BH,1		;count down the on time
	goto	loopg
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x25		;set off time of duty cycle
	movwf	BH
loop2g
	incfsz	BH,1		;count up to the off time
	goto	loop2g
	decfsz	run,1	;run the PWM for a moment
	goto	eighth	
	return
	
	
ninthh
	movf	runn,0
	movwf	run
ninth
	movlw	0xff
	movwf	PORTB
	movlw	0x35		;set on time of duty cycle
	movwf	BH
looph
	decfsz	BH,1		;count down the on time
	goto	looph
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x35		;set off time of duty cycle
	movwf	BH
loop2h
	incfsz	BH,1		;count up to the off time
	goto	loop2h
	decfsz	run,1	;run the PWM for a moment
	goto	ninth	
	return
	
	
tenthh
	movf	runn,0
	movwf	run
tenth
	movlw	0xff
	movwf	PORTB
	movlw	0x50		;set on time of duty cycle
	movwf	BH
loopi
	decfsz	BH,1		;count down the on time
	goto	loopi
	movlw	0x00		;turn leds off
	movwf	PORTB
	movlw	0x50		;set off time of duty cycle
	movwf	BH
loop2i
	incfsz	BH,1		;count up to the off time
	goto	loop2i
	decfsz	run,1	;run the PWM for a moment
	goto	tenth
	return
	
slower
	movlw	0x88		;puts higher value in speed adjustment
	movwf	runn
	return
faster
	movlw	0x11		;puts lower value in speed adjustment
	movwf	runn
	return
	
	endAttached Thumbnails
    
__________________
jeremy 