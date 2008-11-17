processor 16f628
	include "P16F628.inc"
	__config _HS_OSC & _WDT_OFF & _LVP_OFF

	cblock	0x20		;start of general purpose registers
	d1,d2,d3,count
	endc

	org		0x0000

init	clrf	count
	movlw	0x07			;turn comparators off
	movwf	CMCON
	bsf 	STATUS,RP0		;bank 1
	movlw	0x00			;all pins outputs
	movwf	TRISA
	movwf	TRISB
	movlw	0xff			;set period
	movwf	PR2
	bcf 	STATUS,RP0		;bank 0

main	movlw	0x80			;set duty cycle
	movwf	CCPR1L
	movlw	0x04			;set timer2 prescale and enable it
	movwf	T2CON
	movlw	0x0c			;set bottom 2 pwm bits and enable pwm
	movwf	CCP1CON
	call	delay

mloop	movf	count,w			;cycles msb 8 bits of pwm from 0 to 255
	movwf	CCPR1L			;over and over
	call	delay
	incfsz	count
	goto	mloop
reset	clrf	count
	goto	mloop	

delay	movlw	0x2d			;around 0.1 second or a bit less
	movwf	d1
	movlw	0xe7
	movwf	d2
	movlw	0x01
	movwf	d3
delay_0	decfsz	d1, f
	goto	dd2
	decfsz	d2, f
dd2	goto	dd3
	decfsz	d3, f
dd3	goto	delay_0
	return

	end