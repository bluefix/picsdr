




PWM Led fade out with Pic 16f628 

--------------------------------------------------------------------------------
 


Source code: 

;=======pwm.ASM=================================15/11/06==
;     standard crystal 4.0MHz XT
;------------------------------------------------------------
;     configure programmer
	LIST P=16F628;f=inhx8m
	#include "P16F628.INC"  ; Include header file
	__CONFIG	_PWRTE_ON  & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _BODEN_ON & _LVP_OFF & _CP_OFF & _MCLRE_OFF
; http://sandiding.tripod.com/Bertys.html
;------------------------------------------------------------
	cblock 0x20	; Beginn General Purpose-Register
;-------------------------- counters	
	count1
	count2
	count3
;--------------------------
	endc
;--------------------------
#DEFINE pwmu	PORTB,3
;--- Reset --------------------------------------------------
	org	h'00'
	goto	init		; reset -> init
;--- Interrupt ----------------------------------------------
	org	h'04'
;--------------------------
init	clrf	PORTA
	clrf	PORTB
	movlw	0x07		; Turn comparators off and enable pins for I/O 
	movwf	CMCON	
	bcf	STATUS,RP1
	call	usi	; setari porturi
	call	pause
	movlw	0xFF
	movwf	PORTB
	call	pause
	call	set_timer

;-------------------------- asteapta puls de 1ms
uu	
	call	pause
	movlw	0x02
	movwf	CCPR1L
	call	pause
	movlw	0x10
	movwf	CCPR1L
	call	pause
	movlw	0x40
	movwf	CCPR1L
	call	pause
	movlw	0x80
	movwf	CCPR1L
	call	pause
	movlw	0xFF
	movwf	CCPR1L
	call	pause
	movlw	0x80
	movwf	CCPR1L
	call	pause
	movlw	0x40
	movwf	CCPR1L
	call	pause
	movlw	0x10
	movwf	CCPR1L
	goto	uu

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set_timer
	clrf	T2CON
	clrf	TMR2
	clrf	INTCON
	bsf	STATUS,RP0
	clrf	PIE1
	bcf	STATUS,RP0
	clrf	PIR1
	bsf	STATUS,RP0
	movlw	0xFF
	movwf	PR2 ; compare with 255
	bcf	STATUS,RP0
	movlw	0x02
	movwf	CCPR1L
	movlw	0x03
	movwf	T2CON ; prescaler 1:16 and postscaler 1:1
	movlw	0x3C
	movwf	CCP1CON
	bsf	T2CON,TMR2ON
	return

;************************************************************************
;       Subrutine de intarziere                                         *
;************************************************************************
pause	movlw	0x02 ;	
	movwf	count3
d3	movlw	0x3F
	movwf	count1
d1	movlw	0xFA	  
	movwf	count2
d2	decfsz	count2,F	
	goto	d2		
	decfsz	count1,F	
	goto	d1		
	decfsz	count3,F    
	goto	d3          
	retlw	0x00
;============================================================
usi	bsf	STATUS,RP0	; Bank 1
	movlw	0xFF ; all input
	movwf	TRISA
	movlw	0x00
	movwf	TRISB ; all output
	bcf	STATUS,RP0	; Bank 0
	return
;============================================================
	end
;============================================================


--------------------------------------------------------------------------------
 Back to my home page 
Last updated October, 2006 

© Copyright 2006 Bergthaller Iulian-Alexandru

  Search:  The Web  Tripod 
 Report Abuse      « Previous | Top 100 | Next »   
    
Select Rating (10) 
 share: del.icio.us | digg | reddit | furl | facebook  


Site Sponsors
    