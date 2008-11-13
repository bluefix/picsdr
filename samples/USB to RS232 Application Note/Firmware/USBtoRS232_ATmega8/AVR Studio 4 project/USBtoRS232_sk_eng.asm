;***************************************************************************
;* U S B   S T A C K   F O R   T H E   A V R   F A M I L Y
;*
;* File Name            :"USBtoRS232.asm"
;* Title                :AVR309:USB to UART protocol converter
;* Date                 :01.02.2004
;* Version              :2.8
;* Target MCU           :ATmega8
;* AUTHOR		:Ing. Igor Cesko
;* 			 Slovakia
;* 			 cesko@internet.sk
;* 			 http://www.cesko.host.sk
;*
;* DESCRIPTION:
;*  USB protocol implementation into MCU with noUSB interface:
;*  Device:
;*  Universal USB interface (3x8-bit I/O port + RS232 serial line + EEPROM)
;*  + added RS232 FIFO buffer
;*
;* The timing is adapted for 12 MHz crystal
;*
;*
;* to add your own functions - see section: TEMPLATE OF YOUR FUNCTION
;*
;* to customize device to your company you must change VendorUSB ID (VID)
;* to VID assigned to your company (for more information see www.usb.org)
;*
;***************************************************************************
.include "m8def.inc"
;comment for AT90S2313
.equ	UCR			=UCSRB
.equ	UBRR			=UBRRL
.equ	EEAR			=EEARL
.equ	USR			=UCSRA
.equ	E2END			=127
.equ	RAMEND128		=96+127

.equ	inputport		=PINB
.equ	outputport		=PORTB
.equ	USBdirection		=DDRB
.equ	DATAplus		=1		;signal D+ na PB1	;ENG;signal D+ on PB1
.equ	DATAminus		=0		;signal D- na PB0 - treba dat na tento pin pull-up 1.5kOhm	;ENG;signal D- on PB0 - give on this pin pull-up 1.5kOhm
.equ	USBpinmask		=0b11111100	;mask low 2 bits (D+,D-) on PB	;ENG;mask low 2 bit (D+,D-) on PB
.equ	USBpinmaskDplus		=~(1<<DATAplus)	;mask D+ bit on PB	;ENG;mask D+ bit on PB
.equ	USBpinmaskDminus	=~(1<<DATAminus);mask D- bit on PB	;ENG;mask D- bit on PB

.equ	TSOPPort		=PINB
.equ	TSOPpullupPort		=PORTB
.equ	TSOPPin			=2		;signal OUT z IR senzora TSOP1738 na PB2	;ENG;signal OUT from IR sensor TSOP1738 on PB2

;.equ	LEDPortLSB		=PORTD		;pripojenie LED diod LSB	;ENG;connecting LED diode LSB
;.equ	LEDPinLSB		=PIND		;pripojenie LED diod LSB (vstup)	;ENG;connecting LED diode LSB (input)
;.equ	LEDdirectionLSB		=DDRD		;vstup/vystup LED LSB	;ENG;input/output LED LSB
;.equ	LEDPortMSB		=PORTB		;pripojenie LED diod MSB	;ENG;connecting LED diode MSB
;.equ	LEDPinMSB		=PINB		;pripojenie LED diod MSB  (vstup)	;ENG;connecting LED diode MSB  (input)
;.equ	LEDdirectionMSB		=DDRB		;vstup/vystup LED MSB	;ENG;input/output LED MSB
;.equ	LEDlsb0			=3		;LED0 na pin PD3	;ENG;LED0 on pin PD3
;.equ	LEDlsb1			=5		;LED1 na pin PD5	;ENG;LED1 on pin PD5
;.equ	LEDlsb2			=6		;LED2 na pin PD6	;ENG;LED2 on pin PD6
;.equ	LEDmsb3			=3		;LED3 na pin PB3	;ENG;LED3 on pin PB3
;.equ	LEDmsb4			=4		;LED4 na pin PB4	;ENG;LED4 on pin PB4
;.equ	LEDmsb5			=5		;LED5 na pin PB5	;ENG;LED5 on pin PB5
;.equ	LEDmsb6			=6		;LED6 na pin PB6	;ENG;LED6 on pin PB6
;.equ	LEDmsb7			=7		;LED7 na pin PB7	;ENG;LED7 on pin PB7

.equ	SOPbyte			=0b10000000	;Start of Packet byte	;ENG;Start of Packet byte
.equ	DATA0PID		=0b11000011	;PID pre DATA0 pole	;ENG;PID for DATA0 field
.equ	DATA1PID		=0b01001011	;PID pre DATA1 pole	;ENG;PID for DATA1 field
.equ	OUTPID			=0b11100001	;PID pre OUT pole	;ENG;PID for OUT field
.equ	INPID			=0b01101001	;PID pre IN pole	;ENG;PID for IN field
.equ	SOFPID			=0b10100101	;PID pre SOF pole	;ENG;PID for SOF field
.equ	SETUPPID		=0b00101101	;PID pre SETUP pole	;ENG;PID for SETUP field
.equ	ACKPID			=0b11010010	;PID pre ACK pole	;ENG;PID for ACK field
.equ	NAKPID			=0b01011010	;PID pre NAK pole	;ENG;PID for NAK field
.equ	STALLPID		=0b00011110	;PID pre STALL pole	;ENG;PID for STALL field
.equ	PREPID			=0b00111100	;PID pre PRE pole	;ENG;PID for FOR field

.equ	nSOPbyte		=0b00000001	;Start of Packet byte - opacne poradie	;ENG;Start of Packet byte - reverse order
.equ	nDATA0PID		=0b11000011	;PID pre DATA0 pole - opacne poradie	;ENG;PID for DATA0 field - reverse order
.equ	nDATA1PID		=0b11010010	;PID pre DATA1 pole - opacne poradie	;ENG;PID for DATA1 field - reverse order
.equ	nOUTPID			=0b10000111	;PID pre OUT pole - opacne poradie	;ENG;PID for OUT field - reverse order
.equ	nINPID			=0b10010110	;PID pre IN pole - opacne poradie	;ENG;PID for IN field - reverse order
.equ	nSOFPID			=0b10100101	;PID pre SOF pole - opacne poradie	;ENG;PID for SOF field - reverse order
.equ	nSETUPPID		=0b10110100	;PID pre SETUP pole - opacne poradie	;ENG;PID for SETUP field - reverse order
.equ	nACKPID			=0b01001011	;PID pre ACK pole - opacne poradie	;ENG;PID for ACK field - reverse order
.equ	nNAKPID			=0b01011010	;PID pre NAK pole - opacne poradie	;ENG;PID for NAK field - reverse order
.equ	nSTALLPID		=0b01111000	;PID pre STALL pole - opacne poradie	;ENG;PID for STALL field - reverse order
.equ	nPREPID			=0b00111100	;PID pre PRE pole - opacne poradie	;ENG;PID for FOR field - reverse order

.equ	nNRZITokenPID		=~0b10000000	;PID maska pre Token paket (IN,OUT,SOF,SETUP) - opacne poradie NRZI	;ENG;PID mask for Token packet (IN,OUT,SOF,SETUP) - reverse order NRZI
.equ	nNRZISOPbyte		=~0b10101011	;Start of Packet byte - opacne poradie NRZI	;ENG;Start of Packet byte - reverse order NRZI
.equ	nNRZIDATA0PID		=~0b11010111	;PID pre DATA0 pole - opacne poradie NRZI	;ENG;PID for DATA0 field - reverse order NRZI
.equ	nNRZIDATA1PID		=~0b11001001	;PID pre DATA1 pole - opacne poradie NRZI	;ENG;PID for DATA1 field - reverse order NRZI
.equ	nNRZIOUTPID		=~0b10101111	;PID pre OUT pole - opacne poradie NRZI	;ENG;PID for OUT field - reverse order NRZI
.equ	nNRZIINPID		=~0b10110001	;PID pre IN pole - opacne poradie NRZI	;ENG;PID for IN field - reverse order NRZI
.equ	nNRZISOFPID		=~0b10010011	;PID pre SOF pole - opacne poradie NRZI	;ENG;PID for SOF field - reverse order NRZI
.equ	nNRZISETUPPID		=~0b10001101	;PID pre SETUP pole - opacne poradie NRZI	;ENG;PID for SETUP field - reverse order NRZI
.equ	nNRZIACKPID		=~0b00100111	;PID pre ACK pole - opacne poradie NRZI	;ENG;PID for ACK field - reverse order NRZI
.equ	nNRZINAKPID		=~0b00111001	;PID pre NAK pole - opacne poradie NRZI	;ENG;PID for NAK field - reverse order NRZI
.equ	nNRZISTALLPID		=~0b00000111	;PID pre STALL pole - opacne poradie NRZI	;ENG;PID for STALL field - reverse order NRZI
.equ	nNRZIPREPID		=~0b01111101	;PID pre PRE pole - opacne poradie NRZI	;ENG;PID for FOR field - reverse order NRZI
.equ	nNRZIADDR0		=~0b01010101	;Adresa = 0 - opacne poradie NRZI	;ENG;Address = 0 - reverse order NRZI

						;stavove byty - State	;ENG;status bytes - State
.equ	BaseState		=0		;
.equ	SetupState		=1		;
.equ	InState			=2		;
.equ	OutState		=3		;
.equ	SOFState		=4		;
.equ	DataState		=5		;
.equ	AddressChangeState	=6		;

						;Flagy pozadovanej akcie	;ENG;Flags of action
.equ	DoNone					=0
.equ	DoReceiveOutData			=1
.equ	DoReceiveSetupData			=2
.equ	DoPrepareOutContinuousBuffer		=3
.equ	DoReadySendAnswer			=4


.equ	CRC5poly		=0b00101		;CRC5 polynom	;ENG;CRC5 polynomial
.equ	CRC5zvysok		=0b01100		;CRC5 zvysok po uspesnom CRC5	;ENG;CRC5 remainder after successful CRC5
.equ	CRC16poly		=0b1000000000000101	;CRC16 polynom	;ENG;CRC16 polynomial
.equ	CRC16zvysok		=0b1000000000001101	;CRC16 zvysok po uspesnom CRC16	;ENG;CRC16 remainder after successful CRC16

.equ	MAXUSBBYTES		=14			;maximum bytes in USB input message	;ENG;maximum bytes in USB input message
.equ	NumberOfFirstBits	=10			;kolko prvych bitov moze byt dlhsich	;ENG;how many first bits allowed be longer
.equ	NoFirstBitsTimerOffset	=256-12800*12/1024	;Timeout 12.8ms (12800us) na ukoncenie prijmu po uvodnych bitoch (12Mhz:clock, 1024:timer predivider, 256:timer overflow value)	;ENG;Timeout 12.8ms (12800us) to terminate after firsts bits
.equ	InitBaudRate		=12000000/16/57600-1	;nastavit vysielaciu rychlost UART-u na 57600 (pre 12MHz=12000000Hz)	;ENG;UART on 57600 (for 12MHz=12000000Hz)

.equ	InputBufferBegin	=RAMEND128-127				;zaciatok prijimacieho shift buffera	;ENG;compare of receiving shift buffer
.equ	InputShiftBufferBegin	=InputBufferBegin+MAXUSBBYTES		;zaciatok prijimacieho buffera	;ENG;compare of receiving buffera

.equ	MyInAddressSRAM		=InputShiftBufferBegin+MAXUSBBYTES
.equ	MyOutAddressSRAM	=MyInAddressSRAM+1

.equ	OutputBufferBegin	=RAMEND128-MAXUSBBYTES-2	;zaciatok vysielacieho buffera	;ENG;compare of transmitting buffer
.equ	AckBufferBegin		=OutputBufferBegin-3	;zaciatok vysielacieho buffera Ack	;ENG;compare of transmitting buffer Ack
.equ	NakBufferBegin		=AckBufferBegin-3	;zaciatok vysielacieho buffera Nak	;ENG;compare of transmitting buffer Nak
.equ	ConfigByte		=NakBufferBegin-1	;0=unconfigured state	;ENG;0=unconfigured state
.equ	AnswerArray		=ConfigByte-8		;8 byte answer array	;ENG;8 byte answer array
.equ	StackBegin		=AnswerArray-1		;spodok zasobnika (stack je velky cca 68 bytov)	;ENG;low reservoir (stack is big cca 68 byte)

.equ	MAXRS232LENGTH		=RAMEND-RAMEND128-10	;maximalna dlzka RS232 kodu	;ENG;maximum length RS232 code
.equ	RS232BufferBegin	=RAMEND128+1		;zaciatok buffera pre RS232 prijem	;ENG;compare of buffer for RS232 - receiving
.equ	RS232BufferEnd		=RS232BufferBegin+MAXRS232LENGTH
.equ	RS232ReadPosPtr		=RS232BufferBegin+0
.equ	RS232WritePosPtr	=RS232BufferBegin+2
.equ	RS232LengthPosPtr	=RS232BufferBegin+4
.equ	RS232Reserved		=RS232BufferBegin+6
.equ	RS232FIFOBegin		=RS232BufferBegin+8



.def	RS232BufferFull		=R1		;priznak plneho RS232 buffera	;ENG;flag of full RS232 buffer
.def	backupbitcount		=R2		;zaloha bitcount registra v INT0 preruseni	;ENG;backup bitcount register in INT0 disconnected
.def	RAMread			=R3		;ci sa ma citat zo SRAM-ky	;ENG;if reading from SRAM
.def	backupSREGTimer		=R4		;zaloha Flag registra v Timer interrupte	;ENG;backup Flag register in Timer interrupt
.def	backupSREG		=R5		;zaloha Flag registra v INT0 preruseni	;ENG;backup Flag register in INT0 interrupt
.def	ACC			=R6		;accumulator	;ENG;accumulator
.def	lastBitstufNumber	=R7		;pozicia bitstuffingu	;ENG;position in bitstuffing
.def	OutBitStuffNumber	=R8		;kolko bitov sa ma este odvysielat z posledneho bytu - bitstuffing	;ENG;how many bits to send last byte - bitstuffing
.def	BitStuffInOut		=R9		;ci sa ma vkladat alebo mazat bitstuffing	;ENG;if insertion or deleting of bitstuffing
.def	TotalBytesToSend	=R10		;kolko sa ma poslat bytov	;ENG;how many bytes to send
.def	TransmitPart		=R11		;poradove cislo vysielacej casti	;ENG;order number of transmitting part
.def	InputBufferLength	=R12		;dlzka pripravena vo vstupnom USB bufferi	;ENG;length prepared in input USB buffer
.def	OutputBufferLength	=R13		;dlzka odpovede pripravena v USB bufferi	;ENG;length answers prepared in USB buffer
.def	MyOutAddress		=R14		;moja USB adresa (Out Packet)	;ENG;my USB address (Out Packet) for update
.def	MyInAddress		=R15		;moja USB adresa (In/SetupPacket)	;ENG;my USB address (In/SetupPacket)


.def	ActionFlag		=R16		;co sa ma urobit v hlavnej slucke programu	;ENG;what to do in main program loop
.def	temp3			=R17		;temporary register	;ENG;temporary register
.def	temp2			=R18		;temporary register	;ENG;temporary register
.def	temp1			=R19		;temporary register	;ENG;temporary register
.def	temp0			=R20		;temporary register	;ENG;temporary register
.def	bitcount		=R21		;counter of bits in byte	;ENG;counter of bits in byte
.def	ByteCount		=R22		;pocitadlo maximalneho poctu prijatych bajtov	;ENG;counter of maximum number of received bytes
.def	inputbuf		=R23		;prijimaci register	;ENG;receiver register
.def	shiftbuf		=R24		;posuvny prijimaci register	;ENG;shift receiving register
.def	State			=R25		;byte stavu stavoveho stroja	;ENG;state byte of status of state machine
.def	RS232BufptrX		=R26		;XL register - pointer do buffera prijatych IR kodov	;ENG;XL register - pointer to buffer of received IR codes
.def	RS232BufptrXH		=R27
.def	USBBufptrY		=R28		;YL register - pointer do USB buffera input/output	;ENG;YL register - pointer to USB buffer input/output
.def	ROMBufptrZ		=R30		;ZL register - pointer do buffera ROM dat	;ENG;ZL register - pointer to buffer of ROM data


;poziadavky na deskriptory	;ENG;requirements on descriptors
.equ	GET_STATUS		=0
.equ	CLEAR_FEATURE		=1
.equ	SET_FEATURE		=3
.equ	SET_ADDRESS		=5
.equ	GET_DESCRIPTOR		=6
.equ	SET_DESCRIPTOR		=7
.equ	GET_CONFIGURATION	=8
.equ	SET_CONFIGURATION	=9
.equ	GET_INTERFACE		=10
.equ	SET_INTERFACE		=11
.equ	SYNCH_FRAME		=12

;typy deskriptorov	;ENG;descriptor types
.equ	DEVICE			=1
.equ	CONFIGURATION		=2
.equ	STRING			=3
.equ	INTERFACE		=4
.equ	ENDPOINT		=5

;databits	;ENG;databits
.equ	DataBits5		=0
.equ	DataBits6		=1
.equ	DataBits7		=2
.equ	DataBits8		=3

;parity	;ENG;parity
.equ	ParityNone		=0
.equ	ParityOdd		=1
.equ	ParityEven		=2
.equ	ParityMark		=3
.equ	ParitySpace		=4

;stopbits	;ENG;stopbits
.equ	StopBit1		=0
.equ	StopBit2		=1

;user function start number
.equ	USER_FNC_NUMBER		=100


;------------------------------------------------------------------------------------------
;********************************************************************
;* Interrupt table	;ENG;* Interrupt table
;********************************************************************
.cseg
;------------------------------------------------------------------------------------------
.org 0						;po resete	;ENG;after reset
		rjmp	reset
;------------------------------------------------------------------------------------------
.org INT0addr					;externe prerusenie INT0	;ENG;external interrupt INT0
		rjmp	INT0handler
;------------------------------------------------------------------------------------------
.org URXCaddr					;prijem zo seriovej linky	;ENG;receiving from serial line
		push	temp0
		cbi	UCR,RXCIE			;zakazat interrupt od prijimania UART	;ENG;disable interrupt from UART receiving
		sei					;povol interrupty na obsluhu USB	;ENG;enable interrupts to service USB
		in	temp0,UDR			;nacitaj do temp0 prijate data z UART-u	;ENG;put to temp0 received data from UART
		in	backupSREGTimer,SREG		;zaloha SREG	;ENG;backup SREG
		push	temp2
		push	temp3
		lds	temp2,RS232LengthPosPtr
		lds	temp3,RS232LengthPosPtr+1		;zisti dlzku buffera RS232 kodu 	;ENG;determine length of RS232 code buffer
		cpi	temp3,HIGH(RS232BufferEnd-RS232FIFOBegin-1)	;ci by mal pretiect buffer	;ENG;if the buffer would overflow
		brlo	FIFOBufferNoOverflow			;ak nepretecie, tak zapis do FIFO	;ENG;if not overflow then write to FIFO
		brne	NoIncRS232BufferFull			;ak by mal pretiect, tak zabran prepisaniu	;ENG;if buffer would overflow, then prevent of overwriting
								;inak (pri rovnosti) este porovnaj Lo byty	;ENG;otherwise (if equall) still compare Lo bytes
		cpi	temp2,LOW(RS232BufferEnd-RS232FIFOBegin-1)	;ak by mal pretiect buffer (Lo byte)	;ENG;if buffer would overflow (Lo byte)
		brcc	NoIncRS232BufferFull			;tak zabran prepisaniu	;ENG;then prevent of overwriting
FIFOBufferNoOverflow:
		push	RS232BufptrX
		push	RS232BufptrXH
		lds	RS232BufptrX,RS232WritePosPtr		;nastavenie sa na zaciatok buffera zapisu RS232 kodu	;ENG;set position to begin of buffer write RS232 code
		lds	RS232BufptrXH,RS232WritePosPtr+1	;nastavenie sa na zaciatok buffera zapisu RS232 kodu	;ENG;set position to begin of buffer write RS232 code

		st	X+,temp0				;a uloz ho do buffera	;ENG;and save it to buffer
		cpi	RS232BufptrXH,HIGH(RS232BufferEnd+1)	;ak sa nedosiahol maximum RS232 buffera	;ENG;if not reached maximum of RS232 buffer
		brlo	NoUARTBufferOverflow			;tak pokracuj	;ENG;then continue
		brne	UARTBufferOverflow			;skontroluj aj LSB	;ENG;check althen LSB
 		cpi	RS232BufptrX,LOW(RS232BufferEnd+1)	;ak sa nedosiahol maximum RS232 buffera	;ENG;if not reached maximum of RS232 buffer
		brlo	NoUARTBufferOverflow			;tak pokracuj	;ENG;then continue
 UARTBufferOverflow:
		ldi	RS232BufptrX,LOW(RS232FIFOBegin)	;inak sa nastav na zaciatok buffera	;ENG;otherwise set position to buffer begin
		ldi	RS232BufptrXH,HIGH(RS232FIFOBegin)	;inak sa nastav na zaciatok buffera	;ENG;otherwise set position to buffer begin
 NoUARTBufferOverflow:
		sts	RS232WritePosPtr,RS232BufptrX		;ulozenie noveho offsetu buffera zapisu RS232 kodu	;ENG;save new offset of buffer write RS232 code
		sts	RS232WritePosPtr+1,RS232BufptrXH	;ulozenie noveho offsetu buffera zapisu RS232 kodu	;ENG;save new offset of buffer write RS232 code
		ldi	temp0,1					;zvys dlzku RS232 buffera	;ENG;increment length of RS232 buffer
		add	temp2,temp0
		ldi	temp0,0
		adc	temp3,temp0
		sts	RS232LengthPosPtr,temp2			;uloz dlzku buffera RS232 kodu	;ENG;save length of buffer RS232 code
		sts	RS232LengthPosPtr+1,temp3		;uloz dlzku buffera RS232 kodu	;ENG;save length of buffer RS232 code
		pop	RS232BufptrXH
		pop	RS232BufptrX
 NoIncRS232BufferFull:
 		pop	temp3
 		pop	temp2
		pop	temp0
		out	SREG,backupSREGTimer		;obnova SREG	;ENG;restore SREG
		cli					;zakazat interrupt kvoli zacykleniu	;ENG;disable interrupt because to prevent reentrant interrupt call
		sbi	UCR,RXCIE			;povolit interrupt od prijimania UART	;ENG;enable interrupt from receiving of UART
		reti
;------------------------------------------------------------------------------------------
;********************************************************************
;* Init program	;ENG;* Init program
;********************************************************************
;------------------------------------------------------------------------------------------
reset:			;inicializacia procesora a premennych na spravne hodnoty	;ENG;initialization of processor and variables to right values
		ldi	temp0,StackBegin	;inicializacia stacku	;ENG;initialization of stack
		out	SPL,temp0

		clr	XH				;RS232 pointer	;ENG;RS232 pointer
		clr	YH				;USB pointer	;ENG;USB pointer
		clr	ZH				;ROM pointer	;ENG;ROM pointer
		ldi	temp0,LOW(RS232FIFOBegin)	;nastav na zaciatok buffera Low	;ENG;set Low to begin of buffer
		sts	RS232ReadPosPtr,temp0		;znuluj ukazovatel citania	;ENG;zero index of reading
		sts	RS232WritePosPtr,temp0		;znuluj ukazovatel zapisu	;ENG;zero index of writing
		ldi	temp0,HIGH(RS232FIFOBegin)	;nastav na zaciatok buffera High	;ENG;set High to begin of buffer
		sts	RS232ReadPosPtr+1,temp0		;znuluj ukazovatel citania	;ENG;zero index of reading
		sts	RS232WritePosPtr+1,temp0	;znuluj ukazovatel zapisu	;ENG;zero index of writing
		sts	RS232LengthPosPtr,YH		;znuluj ukazovatel dlzky	;ENG;zero index of length
		sts	RS232LengthPosPtr+1,YH		;znuluj ukazovatel dlzky	;ENG;zero index of length
		clr	RS232BufferFull


		rcall	InitACKBufffer		;inicializacia ACK buffera	;ENG;initialization of ACK buffer
		rcall	InitNAKBufffer		;inicializacia NAK buffera	;ENG;initialization of NAK buffer

		rcall	USBReset		;inicializacia USB adresy	;ENG;initialization of USB addresses

		ldi	temp0,0b00111100	;nahodit pull-up na PORTB	;ENG;set pull-up on PORTB
		out	PORTB,temp0
		ldi	temp0,0b11111111	;nahodit pull-up na PORTC	;ENG;set pull-up on PORTC
		out	PORTC,temp0
		ldi	temp0,0b11111011	;nahodit pull-up na PORTD	;ENG;set pull-up on PORTD
		out	PORTD,temp0

		clr	temp0			;
		out	UBRRH,temp0		;nastavit vysielaciu rychlost UART-u High	;ENG;set UART speed High
		out	EEARH,temp0		;znulovat EEPROM ukazovatel	;ENG;zero EEPROM index

		ldi	temp0,1<<U2X		;nastavit mod X2 na UART-e	;ENG;set mode X2 on UART
		out	USR,temp0
		ldi	temp0,InitBaudRate	;nastavit vysielaciu rychlost UART-u	;ENG;set UART speed
		out	UBRR,temp0
		sbi	UCR,TXEN		;povolit vysielanie UART-u	;ENG;enable transmiting of UART
		sbi	UCR,RXEN		;povolit prijimanie UART-u	;ENG;enable receiving of UART
		sbi	UCR,RXCIE		;povolit interrupt od prijimania UART	;ENG;enable interrupt from receiving of UART

		ldi	temp0,0x0F		;INT0 - reagovanie na nabeznu hranu	;ENG;INT0 - respond to leading edge
		out	MCUCR,temp0		;
		ldi	temp0,1<<INT0		;povolit externy interrupt INT0	;ENG;enable external interrupt INT0
		out	GIMSK,temp0
;------------------------------------------------------------------------------------------
;********************************************************************
;* Main program	;ENG;* Main program
;********************************************************************
		sei					;povolit interrupty globalne	;ENG;enable interrupts globally
Main:
		sbis	inputport,DATAminus	;cakanie az sa zmeni D- na 0	;ENG;waiting till change D- to 0
		rjmp	CheckUSBReset		;a skontroluj, ci to nie je USB reset	;ENG;and check, if isn't USB reset

		cpi	ActionFlag,DoReceiveSetupData
		breq	ProcReceiveSetupData
		cpi	ActionFlag,DoPrepareOutContinuousBuffer
		breq	ProcPrepareOutContinuousBuffer
		rjmp	Main

CheckUSBReset:
		ldi	temp0,255		;pocitadlo trvania reset-u (podla normy je to cca 10ms - tu je to cca 100us)	;ENG;counter duration of reset (according to specification is that cca 10ms - here is cca 100us)
WaitForUSBReset:
		sbic	inputport,DATAminus	;cakanie az sa zmeni D+ na 0	;ENG;waiting till change D+ to 0
		rjmp	Main
		dec	temp0
		brne	WaitForUSBReset
		rcall	USBReset
		rjmp	Main

ProcPrepareOutContinuousBuffer:
		rcall	PrepareOutContinuousBuffer	;priprav pokracovanie odpovede do buffera	;ENG;prepare next sequence of answer to buffer
		ldi	ActionFlag,DoReadySendAnswer
		rjmp	Main
ProcReceiveSetupData:
		ldi	USBBufptrY,InputBufferBegin	;pointer na zaciatok prijimacieho buffera	;ENG;pointer to begin of receiving buffer
		mov	ByteCount,InputBufferLength	;dlzka vstupneho buffera	;ENG;length of input buffer
		rcall	DecodeNRZI		;prevod kodovania NRZI na bity	;ENG;transfer NRZI coding to bits
		rcall	MirrorInBufferBytes	;prehodit poradie bitov v bajtoch	;ENG;invert bits order in bytes
		rcall	BitStuff		;odstranenie bit stuffing	;ENG;removal of bitstuffing
		;rcall	CheckCRCIn		;kontrola CRC	;ENG;rcall	CheckCRCIn		;check CRC
		rcall	PrepareUSBOutAnswer	;pripravenie odpovede do vysielacieho buffera	;ENG;prepare answers to transmitting buffer
		ldi	ActionFlag,DoReadySendAnswer
		rjmp	Main
;********************************************************************
;* Main program END	;ENG;* Main program END
;********************************************************************
;------------------------------------------------------------------------------------------
;********************************************************************
;* Interrupt0 interrupt handler	;ENG;* Interrupt0 interrupt handler
;********************************************************************
INT0Handler:					;prerusenie INT0	;ENG;interrupt INT0
		in	backupSREG,SREG
		push	temp0
		push	temp1

		ldi	temp0,3			;pocitadlo trvania log0	;ENG;counter of duration log0
		ldi	temp1,2			;pocitadlo trvania log1	;ENG;counter of duration log1
		;cakanie na zaciatok paketu	;ENG;waiting for begin packet
CheckchangeMinus:
		sbis	inputport,DATAminus	;cakanie az sa zmeni D- na 1	;ENG;waiting till change D- to 1
		rjmp	CheckchangeMinus
CheckchangePlus:
		sbis	inputport,DATAplus	;cakanie az sa zmeni D+ na 1	;ENG;waiting till change D+ to 1
		rjmp	CheckchangePlus
DetectSOPEnd:
		sbis	inputport,DATAplus
		rjmp	Increment0		;D+ =0	;ENG;D+ =0
Increment1:
		ldi	temp0,3			;pocitadlo trvania log0	;ENG;counter of duration log0
		dec	temp1			;kolko cyklov trvala log1	;ENG;how many cycles takes log1
		nop
		breq	USBBeginPacket		;ak je to koniec SOP - prijimaj paket	;ENG;if this is end of SOP - receive packet
		rjmp	DetectSOPEnd
Increment0:
		ldi	temp1,2			;pocitadlo trvania log1	;ENG;counter of duration log1
		dec	temp0			;kolko cyklov trvala log0	;ENG;how many cycles take log0
		nop
		brne	DetectSOPEnd		;ak nenastal SOF - pokracuj	;ENG;if there isn't SOF - continue
		rjmp	EndInt0HandlerPOP2
EndInt0Handler:
		pop	ACC
		pop	RS232BufptrX
		pop	temp3
		pop	temp2
EndInt0HandlerPOP:
		pop	USBBufptrY
		pop	ByteCount
		mov	bitcount,backupbitcount	;obnova bitcount registra	;ENG;restore bitcount register
EndInt0HandlerPOP2:
		pop	temp1
		pop	temp0
		out	SREG,backupSREG
		ldi	shiftbuf,1<<INTF0	;znulovat flag interruptu INTF0	;ENG;zero interruptu flag INTF0
		out	GIFR,shiftbuf
		reti				;inak skonci (bol iba SOF - kazdu milisekundu)	;ENG;otherwise finish (was only SOF - every millisecond)

USBBeginPacket:
		mov	backupbitcount,bitcount	;zaloha bitcount registra	;ENG;backup bitcount register
		in	shiftbuf,inputport	;ak ano nacitaj ho ako nulty bit priamo do shift registra	;ENG;if yes load it as zero bit directly to shift register
USBloopBegin:
		push	ByteCount		;dalsia zaloha registrov (setrenie casu)	;ENG;additional backup of registers (save of time)
		push	USBBufptrY
		ldi	bitcount,6		;inicializacia pocitadla bitov v bajte	;ENG;initialization of bits counter in byte
		ldi	ByteCount,MAXUSBBYTES	;inicializacia max poctu prijatych bajtov v pakete	;ENG;initialization of max number of received bytes in packet
		ldi	USBBufptrY,InputShiftBufferBegin	;nastav vstupny buffera	;ENG;set the input buffer
USBloop1_6:
		in	inputbuf,inputport
		cbr	inputbuf,USBpinmask	;odmaskovat spodne 2 bity	;ENG;unmask low 2 bits
		breq	USBloopEnd		;ak su nulove - koniec USB packetu	;ENG;if they are zeros - end of USB packet
		ror	inputbuf		;presun Data+ do shift registra	;ENG;transfer Data+ to shift register
		rol	shiftbuf
		dec	bitcount		;zmensi pocitadlo bitov	;ENG;decrement bits counter
		brne	USBloop1_6		;ak nie je nulove - opakuj naplnanie shift registra	;ENG;if it isn't zero - repeat filling of shift register
		nop				;inak bude nutne skopirovat shift register bo buffera	;ENG;otherwise is necessary copy shift register to buffer
USBloop7:
		in	inputbuf,inputport
		cbr	inputbuf,USBpinmask	;odmaskovat spodne 2 bity	;ENG;unmask low 2 bits
		breq	USBloopEnd		;ak su nulove - koniec USB packetu	;ENG;if they are zeros - end of USB packet
		ror	inputbuf		;presun Data+ do shift registra	;ENG;transfer Data+ to shift register
		rol	shiftbuf
		ldi	bitcount,7		;inicializacia pocitadla bitov v bajte	;ENG;initialization of bits counter in byte
		st	Y+,shiftbuf		;skopiruj shift register bo buffera a zvys pointer do buffera	;ENG;copy shift register into buffer and increment pointer to buffer
USBloop0:					;a zacni prijimat dalsi bajt	;ENG;and start receiving next byte
		in	shiftbuf,inputport	;nulty bit priamo do shift registra	;ENG;zero bit directly to shift register
		cbr	shiftbuf,USBpinmask	;odmaskovat spodne 2 bity	;ENG;unmask low 2 bits
		breq	USBloopEnd		;ak su nulove - koniec USB packetu	;ENG;if they are zeros - end of USB packet
		dec	bitcount		;zmensi pocitadlo bitov	;ENG;decrement bits counter
		nop				;
		dec	ByteCount		;ak sa nedosiahol maximum buffera	;ENG;if not reached maximum buffer
		brne	USBloop1_6		;tak prijimaj dalej	;ENG;then receive next

		rjmp	EndInt0HandlerPOP	;inak opakuj od zaciatku	;ENG;otherwise repeat back from begin

USBloopEnd:
		cpi	USBBufptrY,InputShiftBufferBegin+3	;ak sa neprijali aspon 3 byte	;ENG;if at least 3 byte not received
		brcs	EndInt0HandlerPOP	;tak skonci	;ENG;then finish
		lds	temp0,InputShiftBufferBegin+0	;identifikator paketu do temp0	;ENG;identifier of packet to temp0
		lds	temp1,InputShiftBufferBegin+1	;adresa do temp1	;ENG;address to temp1
		brne	TestDataPacket		;ak je dlzka ina ako 3 - tak to moze byt iba DataPaket	;ENG;if is length different from 3 - then this can be only DataPaket
TestIOPacket:
;		cp	temp1,MyAddress		;ak to nie je urcene (adresa) pre mna	;ENG;if this isn't assigned (address) for me
;		brne	TestDataPacket		;tak to moze byt este Data Packet	;ENG;then this can be still DataPacket
TestSetupPacket:;test na SETUP paket	;ENG;test to SETUP packet
		cpi	temp0,nNRZISETUPPID
		brne	TestOutPacket		;ak nie je Setup PID - dekoduj iny paket	;ENG;if this isn't Setup PID - decode other packet
		cp	temp1,MyInAddress	;ak to nie je urcene (adresa) pre mna	;ENG;if this isn't assigned (address) for me
		brne	TestDataPacket		;tak to moze byt este Data Packet	;ENG;then this can be still DataPacket
		ldi	State,SetupState
		rjmp	EndInt0HandlerPOP	;ak je Setup PID - prijimaj nasledny Data paket	;ENG;if this is Setup PID - receive consecutive Data packet
TestOutPacket:	;test na OUT paket	;ENG;test for OUT packet
		cpi	temp0,nNRZIOUTPID
		brne	TestInPacket		;ak nie je Out PID - dekoduj iny paket	;ENG;if this isn't Out PID - decode other packet
		cp	temp1,MyOutAddress	;ak to nie je urcene (adresa) pre mna	;ENG;if this isn't assigned (address) for me
		brne	TestDataPacket		;tak to moze byt este Data Packet	;ENG;then this can be still DataPacket
		ldi	State,OutState
		rjmp	EndInt0HandlerPOP	;ak je Out PID - prijimaj nasledny Data paket	;ENG;if this is Out PID - receive consecutive Data packet
TestInPacket:	;test na IN paket	;ENG;test on IN packet
		cpi	temp0,nNRZIINPID
		brne	TestDataPacket		;ak nie je In PID - dekoduj iny paket	;ENG;if this isn't In PID - decode other packet
		cp	temp1,MyInAddress	;ak to nie je urcene (adresa) pre mna	;ENG;if this isn't assigned (address) for me
		breq	AnswerToInRequest
TestDataPacket:	;test na DATA0 a DATA1 paket	;ENG;test for DATA0 and DATA1 packet
		cpi	temp0,nNRZIDATA0PID
		breq	Data0Packet		;ak nie je Data0 PID - dekoduj iny paket	;ENG;if this isn't Data0 PID - decode other packet
		cpi	temp0,nNRZIDATA1PID
		brne	NoMyPacked		;ak nie je Data1 PID - dekoduj iny paket	;ENG;if this isn't Data1 PID - decode other packet
Data0Packet:
		cpi	State,SetupState	;ak bol stav Setup	;ENG;if was state Setup
		breq	ReceiveSetupData	;prijmi ho	;ENG;receive it
		cpi	State,OutState		;ak bol stav Out	;ENG;if was state Out
		breq	ReceiveOutData		;prijmi ho	;ENG;receive it
NoMyPacked:
		ldi	State,BaseState		;znuluj stav	;ENG;zero state
		rjmp	EndInt0HandlerPOP	;a prijimaj nasledny Data paket	;ENG;and receive consecutive Data packet

AnswerToInRequest:
		push	temp2			;zazalohuj dalsie registre a pokracuj	;ENG;backup next registers and continue
		push	temp3
		push	RS232BufptrX
		push	ACC
		cpi	ActionFlag,DoReadySendAnswer	;ak nie je pripravena odpoved	;ENG;if isn't prepared answer
		brne	NoReadySend		;tak posli NAK	;ENG;then send NAK
		rcall	SendPreparedUSBAnswer	;poslanie odpovede naspat	;ENG;transmitting answer back
		cpi	State,AddressChangeState ;ak je stav AddressChange	;ENG;if state is AddressChange
		breq	SetMyNewUSBAddress	;tak treba zmenit USB adresu	;ENG;then is necessary to change USB address
		ldi	State,InState
		ldi	ActionFlag,DoPrepareOutContinuousBuffer
		rjmp	EndInt0Handler		;a opakuj - cakaj na dalsiu odozvu z USB	;ENG;and repeat - wait for next response from USB
ReceiveSetupData:
		push	temp2			;zazalohuj dalsie registre a pokracuj	;ENG;backup next registers and continue
		push	temp3
		push	RS232BufptrX
		push	ACC
		rcall	SendACK			;akceptovanie Setup Data paketu	;ENG;accept Setup Data packet
		rcall	FinishReceiving		;ukonci prijem	;ENG;finish receiving
		ldi	ActionFlag,DoReceiveSetupData
		rjmp	EndInt0Handler
ReceiveOutData:
		push	temp2			;zazalohuj dalsie registre a pokracuj	;ENG;backup next registers and continue
		push	temp3
		push	RS232BufptrX
		push	ACC
		cpi	ActionFlag,DoReceiveSetupData	;ak sa prave spracovava prikaz Setup	;ENG;if is currently in process command Setup
		breq	NoReadySend		;tak posli NAK	;ENG;then send NAK
		rcall	SendACK			;akceptovanie Out paketu	;ENG;accept Out packet
		clr	ActionFlag
		rjmp	EndInt0Handler
NoReadySend:
		rcall	SendNAK			;este nie som pripraveny s odpovedou	;ENG;still I am not ready to answer
		rjmp	EndInt0Handler		;a opakuj - cakaj na dalsiu odozvu z USB	;ENG;and repeat - wait for next response from USB
;------------------------------------------------------------------------------------------
SetMyNewUSBAddress:		;nastavi novu USB adresu v NRZI kodovani	;ENG;set new USB address in NRZI coded
		lds	MyInAddress,MyInAddressSRAM
		lds	MyOutAddress,MyOutAddressSRAM
		rjmp	EndInt0Handler
;------------------------------------------------------------------------------------------
FinishReceiving:		;korekcne akcie na ukoncenie prijmu	;ENG;corrective actions for receive termination
		cpi	bitcount,7		;prenes do buffera aj posledny necely byte	;ENG;transfer to buffer also last not completed byte
		breq	NoRemainingBits		;ak boli vsetky byty prenesene, tak neprenasaj nic	;ENG;if were all bytes transfered, then nothing transfer
		inc	bitcount
ShiftRemainingBits:
		rol	shiftbuf		;posun ostavajuce necele bity na spravnu poziciu	;ENG;shift remaining not completed bits on right position
		dec	bitcount
		brne	ShiftRemainingBits
		st	Y+,shiftbuf		;a skopiruj shift register bo buffera - necely byte	;ENG;and copy shift register bo buffer - not completed byte
NoRemainingBits:
		mov	ByteCount,USBBufptrY
		subi	ByteCount,InputShiftBufferBegin-1	;v ByteCount je pocet prijatych byte (vratane necelych byte)	;ENG;in ByteCount is number of received bytes (including not completed bytes)

		mov	InputBufferLength,ByteCount		;a uchovat pre pouzitie v hlavnom programe	;ENG;and save for use in main program
		ldi	USBBufptrY,InputShiftBufferBegin	;pointer na zaciatok prijimacieho shift buffera	;ENG;pointer to begin of receiving shift buffer
		ldi	RS232BufptrX,InputBufferBegin+1		;data buffer (vynechat SOP)	;ENG;data buffer (leave out SOP)
		push	XH					;uschova RS232BufptrX Hi ukazovatela	;ENG;save RS232BufptrX Hi index
		clr	XH
MoveDataBuffer:
		ld	temp0,Y+
		st	X+,temp0
		dec	ByteCount
		brne	MoveDataBuffer

		pop	XH					;obnova RS232BufptrX Hi ukazovatela	;ENG;restore RS232BufptrX Hi index
		ldi	ByteCount,nNRZISOPbyte
		sts	InputBufferBegin,ByteCount		;ako keby sa prijal SOP - nekopiruje sa zo shift buffera	;ENG;like received SOP - it is not copied from shift buffer
		ret
;------------------------------------------------------------------------------------------
;********************************************************************
;* Other procedures	;ENG;* Other procedures
;********************************************************************
;------------------------------------------------------------------------------------------
USBReset:		;inicializacia USB stavoveho stroja	;ENG;initialization of USB state engine
		ldi	temp0,nNRZIADDR0	;inicializacia USB adresy	;ENG;initialization of USB address
		mov	MyOutAddress,temp0
		mov	MyInAddress,temp0
		clr	State			;inicializacia stavoveho stroja	;ENG;initialization of state engine
		clr	BitStuffInOut
		clr	OutBitStuffNumber
		clr	ActionFlag
		clr	RAMread			;bude sa vycitavat z ROM-ky	;ENG;will be reading from ROM
		sts	ConfigByte,RAMread	;nenakonfiguravany stav	;ENG;unconfigured state
		ret
;------------------------------------------------------------------------------------------
SendPreparedUSBAnswer:	;poslanie kodovanim NRZI OUT buffera s dlzkou OutputBufferLength do USB	;ENG;transmitting by NRZI coding OUT buffer with length OutputBufferLength to USB
		mov	ByteCount,OutputBufferLength		;dlzka odpovede	;ENG;length of answer
SendUSBAnswer:	;poslanie kodovanim NRZI OUT buffera do USB	;ENG;transmitting by NRZI coding OUT buffer to USB
		ldi	USBBufptrY,OutputBufferBegin		;pointer na zaciatok vysielacieho buffera	;ENG;pointer to begin of transmitting buffer
SendUSBBuffer:	;poslanie kodovanim NRZI dany buffer do USB	;ENG;transmitting by NRZI coding given buffer to USB
		ldi	temp1,0			;zvysovanie pointera (pomocna premenna)	;ENG;incrementing pointer (temporary variable)
		mov	temp3,ByteCount		;pocitadlo bytov: temp3 = ByteCount	;ENG;byte counter: temp3 = ByteCount
		ldi	temp2,0b00000011	;maska na xorovanie	;ENG;mask for xoring
		ld	inputbuf,Y+		;nacitanie prveho bytu do inputbuf a zvys pointer do buffera	;ENG;load first byte to inputbuf and increment pointer to buffer
						;USB ako vystup:	;ENG;USB as output:
		cbi	outputport,DATAplus	;zhodenie DATAplus : kludovy stav portu USB	;ENG;down DATAPLUS : idle state of USB port
		sbi	outputport,DATAminus	;nahodenie DATAminus : kludovy stav portu USB	;ENG;set DATAMINUS : idle state of USB port
		sbi	USBdirection,DATAplus	;DATAplus ako vystupny	;ENG;DATAPLUS as output
		sbi	USBdirection,DATAminus	;DATAminus ako vystupny	;ENG;DATAMINUS as output

		in	temp0,outputport	;kludovy stav portu USB do temp0	;ENG;idle state of USB port to temp0
SendUSBAnswerLoop:
		ldi	bitcount,7		;pocitadlo bitov	;ENG;bits counter
SendUSBAnswerByteLoop:
		nop				;oneskorenie kvoli casovaniu	;ENG;delay because timing
		ror	inputbuf		;do carry vysielany bit (v smere naskor LSB a potom MSB)	;ENG;to carry transmiting bit (in direction first LSB then MSB)
		brcs	NoXORSend		;ak je jedna - nemen stav na USB	;ENG;if that it is one - don't change USB state
		eor	temp0,temp2		;inak sa bude stav menit	;ENG;otherwise state will be changed
NoXORSend:
		out	outputport,temp0	;vysli von na USB	;ENG;send out to USB
		dec	bitcount		;zmensi pocitadlo bitov - podla carry flagu	;ENG;decrement bits counter - according to carry flag
		brne	SendUSBAnswerByteLoop	;ak pocitadlo bitov nie je nulove - opakuj vysielanie s dalsim bitom	;ENG;if bits counter isn't zero - repeat transmiting with next bit
		sbrs	inputbuf,0		;ak je vysielany bit jedna - nemen stav na USB	;ENG;if is transmiting bit one - don't change USB state
		eor	temp0,temp2		;inak sa bude stav menit	;ENG;otherwise state will be changed
NoXORSendLSB:
		dec	temp3			;zniz pocitadlo bytov	;ENG;decrement bytes counter
		ld	inputbuf,Y+		;nacitanie dalsieho bytu a zvys pointer do buffera	;ENG;load next byte and increment pointer to buffer
		out	outputport,temp0	;vysli von na USB	;ENG;transmit to USB
		brne	SendUSBAnswerLoop	;opakuj pre cely buffer (pokial temp3=0)	;ENG;repeat for all buffer (till temp3=0)

		mov	bitcount,OutBitStuffNumber	;pocitadlo bitov pre bitstuff	;ENG;bits counter for bitstuff
		cpi	bitcount,0		;ak nie je potrebny bitstuff	;ENG;if not be needed bitstuff
		breq	ZeroBitStuf
SendUSBAnswerBitstuffLoop:
		ror	inputbuf		;do carry vysielany bit (v smere naskor LSB a potom MSB)	;ENG;to carry transmiting bit (in direction first LSB then MSB)
		brcs	NoXORBitstuffSend	;ak je jedna - nemen stav na USB	;ENG;if is one - don't change state on USB
		eor	temp0,temp2		;inak sa bude stav menit	;ENG;otherwise state will be changed
NoXORBitstuffSend:
		out	outputport,temp0	;vysli von na USB	;ENG;transmit to USB
		nop				;oneskorenie kvoli casovaniu	;ENG;delay because of timing
		dec	bitcount		;zmensi pocitadlo bitov - podla carry flagu	;ENG;decrement bits counter - according to carry flag
		brne	SendUSBAnswerBitstuffLoop	;ak pocitadlo bitov nie je nulove - opakuj vysielanie s dalsim bitom	;ENG;if bits counter isn't zero - repeat transmiting with next bit
		ld	inputbuf,Y		;oneskorenie 2 cykly	;ENG;delay 2 cycle
ZeroBitStuf:
		nop				;oneskorenie 1 cyklus	;ENG;delay 1 cycle
		cbr	temp0,3
		out	outputport,temp0	;vysli EOP na USB	;ENG;transmit EOP on USB

		ldi	bitcount,5		;pocitadlo oneskorenia: EOP ma trvat 2 bity (16 cyklov pri 12MHz)	;ENG;delay counter: EOP shouls exists 2 bits (16 cycle at 12MHz)
SendUSBWaitEOP:
		dec	bitcount
		brne	SendUSBWaitEOP

		sbi	outputport,DATAminus	;nahodenie DATAminus : kludovy stav na port USB	;ENG;set DATAMINUS : idle state on USB port
		sbi	outputport,DATAminus	;oneskorenie 2 cykly: Idle ma trvat 1 bit (8 cyklov pri 12MHz)	;ENG;delay 2 cycle: Idle should exists 1 bit (8 cycle at 12MHz)
		cbi	USBdirection,DATAplus	;DATAplus ako vstupny	;ENG;DATAPLUS as input
		cbi	USBdirection,DATAminus	;DATAminus ako vstupny	;ENG;DATAMINUS as input
		cbi	outputport,DATAminus	;zhodenie DATAminus : treti stav na port USB	;ENG;reset DATAMINUS : the third state on USB port
		ret
;------------------------------------------------------------------------------------------
ToggleDATAPID:
		lds	temp0,OutputBufferBegin+1	;nahraj posledne PID	;ENG;load last PID
		cpi	temp0,DATA1PID			;ak bolo posledne DATA1PID byte	;ENG;if last was DATA1PID byte
		ldi	temp0,DATA0PID
		breq	SendData0PID			;tak posli nulovu odpoved s DATA0PID	;ENG;then send zero answer with DATA0PID
		ldi	temp0,DATA1PID			;inak posli nulovu odpoved s DATA1PID	;ENG;otherwise send zero answer with DATA1PID
SendData0PID:
		sts	OutputBufferBegin+1,temp0	;DATA0PID byte	;ENG;DATA0PID byte
		ret
;------------------------------------------------------------------------------------------
ComposeZeroDATA1PIDAnswer:
		ldi	temp0,DATA0PID			;DATA0 PID - v skutocnosti sa stoggluje na DATA1PID v nahrati deskriptora	;ENG;DATA0 PID - in the next will be toggled to DATA1PID in load descriptor
		sts	OutputBufferBegin+1,temp0	;nahraj do vyst buffera	;ENG;load to output buffer
ComposeZeroAnswer:
		ldi	temp0,SOPbyte
		sts	OutputBufferBegin+0,temp0	;SOP byte	;ENG;SOP byte
		rcall	ToggleDATAPID			;zmen DATAPID	;ENG;change DATAPID
		ldi	temp0,0x00
		sts	OutputBufferBegin+2,temp0	;CRC byte	;ENG;CRC byte
		sts	OutputBufferBegin+3,temp0	;CRC byte	;ENG;CRC byte
		ldi	ByteCount,2+2			;dlzka vystupneho buffera (SOP a PID + CRC16)	;ENG;length of output buffer (SOP and PID + CRC16)
		ret
;------------------------------------------------------------------------------------------
InitACKBufffer:
		ldi	temp0,SOPbyte
		sts	ACKBufferBegin+0,temp0		;SOP byte	;ENG;SOP byte
		ldi	temp0,ACKPID
		sts	ACKBufferBegin+1,temp0		;ACKPID byte	;ENG;ACKPID byte
		ret
;------------------------------------------------------------------------------------------
SendACK:
		push	USBBufptrY
		push	bitcount
		push	OutBitStuffNumber
		ldi	USBBufptrY,ACKBufferBegin	;pointer na zaciatok ACK buffera	;ENG;pointer to begin of ACK buffer
		ldi	ByteCount,2			;pocet vyslanych bytov (iba SOP a ACKPID)	;ENG;number of transmit bytes (only SOP and ACKPID)
		clr	OutBitStuffNumber
		rcall	SendUSBBuffer
		pop	OutBitStuffNumber
		pop	bitcount
		pop	USBBufptrY
		ret
;------------------------------------------------------------------------------------------
InitNAKBufffer:
		ldi	temp0,SOPbyte
		sts	NAKBufferBegin+0,temp0		;SOP byte	;ENG;SOP byte
		ldi	temp0,NAKPID
		sts	NAKBufferBegin+1,temp0		;NAKPID byte	;ENG;NAKPID byte
		ret
;------------------------------------------------------------------------------------------
SendNAK:
		push	OutBitStuffNumber
		ldi	USBBufptrY,NAKBufferBegin	;pointer na zaciatok ACK buffera	;ENG;pointer to begin of ACK buffer
		ldi	ByteCount,2			;pocet vyslanych bytov (iba SOP a NAKPID)	;ENG;number of transmited bytes (only SOP and NAKPID)
		clr	OutBitStuffNumber
		rcall	SendUSBBuffer
		pop	OutBitStuffNumber
		ret
;------------------------------------------------------------------------------------------
ComposeSTALL:
		ldi	temp0,SOPbyte
		sts	OutputBufferBegin+0,temp0	;SOP byte	;ENG;SOP byte
		ldi	temp0,STALLPID
		sts	OutputBufferBegin+1,temp0	;STALLPID byte	;ENG;STALLPID byte
		ldi	ByteCount,2			;dlzka vystupneho buffera (SOP a PID)	;ENG;length of output buffer (SOP and PID)
		ret
;------------------------------------------------------------------------------------------
DecodeNRZI:	;enkodovanie buffera z NRZI kodu do binarneho	;ENG;encoding of buffer from NRZI code to binary
		push	USBBufptrY		;zalohuj pointer do buffera	;ENG;back up pointer to buffer
		push	ByteCount		;zalohuj dlzku buffera	;ENG;back up length of buffer
		add	ByteCount,USBBufptrY	;koniec buffera do ByteCount	;ENG;end of buffer to ByteCount
		ser	temp0			;na zabezpecenie jednotkoveho carry (v nasledujucej rotacii)	;ENG;to ensure unit carry (in the next rotation)
NRZIloop:
		ror	temp0			;naplnenie carry z predchadzajuceho byte	;ENG;filling carry from previous byte
		ld	temp0,Y			;nahraj prijaty byte z buffera	;ENG;load received byte from buffer
		mov	temp2,temp0		;posunuty register o jeden bit vpravo a XOR na funkciu NRZI dekodovania	;ENG;shifted register to one bit to the right and XOR for function of NRZI decoding
		ror	temp2			;carry do najvyssieho bitu a sucasne posuv	;ENG;carry to most significant digit bit and shift
		eor	temp2,temp0		;samotne dekodovanie NRZI	;ENG;NRZI decoding
		com	temp2			;negovanie	;ENG;negate
		st	Y+,temp2		;ulozenie spat ako dekodovany byte a zvys pointer do buffera	;ENG;save back as decoded byte and increment pointer to buffer
		cp	USBBufptrY,ByteCount	;ak este neboli vsetky	;ENG;if not all bytes
		brne	NRZIloop		;tak opakuj	;ENG;then repeat
		pop	ByteCount		;obnov dlzku buffera	;ENG;restore buffer length
		pop	USBBufptrY		;obnov pointer do buffera	;ENG;restore pointer to buffer
		ret				;inak skonci	;ENG;otherwise finish
;------------------------------------------------------------------------------------------
BitStuff:	;odstranenie bit-stuffingu v buffri	;ENG;removal of bitstuffing in buffer
		clr	temp3			;pocitadlo vynechanych bitov	;ENG;counter of omitted bits
		clr	lastBitstufNumber	;0xFF do lastBitstufNumber	;ENG;0xFF to lastBitstufNumber
		dec	lastBitstufNumber
BitStuffRepeat:
		push	USBBufptrY		;zalohuj pointer do buffera	;ENG;back up pointer to buffer
		push	ByteCount		;zalohuj dlzku buffera	;ENG;back up buffer length
		mov	temp1,temp3		;pocitadlo vsetkych bitov	;ENG;counter of all bits
		ldi	temp0,8			;spocitat vsetky bity v bufferi	;ENG;sum all bits in buffer
SumAllBits:
		add	temp1,temp0
		dec	ByteCount
		brne	SumAllBits
		ldi	temp2,6			;inicializuj pocitadlo jednotiek	;ENG;initialize counter of ones
		pop	ByteCount		;obnov dlzku buffera	;ENG;restore buffer length
		push	ByteCount		;zalohuj dlzku buffera	;ENG;back up buffer length
		add	ByteCount,USBBufptrY	;koniec buffera do ByteCount	;ENG;end of buffer to ByteCount
		inc	ByteCount		;a pre istotu ho zvys o 2 (kvoli posuvaniu)	;ENG;and for safety increment it with 2 (because of shifting)
		inc	ByteCount
BitStuffLoop:
		ld	temp0,Y			;nahraj prijaty byte z buffera	;ENG;load received byte from buffer
		ldi	bitcount,8		;pocitadlo bitov v byte	;ENG;bits counter in byte
BitStuffByteLoop:
		ror	temp0			;naplnenie carry z LSB	;ENG;filling carry from LSB
		brcs	IncrementBitstuff	;ak LSB=0	;ENG;if that LSB=0
		ldi	temp2,7			;inicializuj pocitadlo jednotiek +1 (ak bola nula)	;ENG;initialize counter of ones +1 (if was zero)
IncrementBitstuff:
		dec	temp2			;zniz pocitadlo jednotiek (predpoklad jednotkoveho bitu)	;ENG;decrement counter of ones (assumption of one bit)
		brne	DontShiftBuffer		;ak este nebolo 6 jednotiek za sebou - neposun buffer	;ENG;if there was not 6 ones together - don't shift buffer
		cp	temp1,lastBitstufNumber	;
		ldi	temp2,6			;inicializuj pocitadlo jednotiek (ak by sa nerobil bitstuffing tak sa musi zacat odznova)	;ENG;initialize counter of ones (if no bitstuffing will be made then must be started again)
		brcc	DontShiftBuffer		;ak sa tu uz robil bitstuffing - neposun buffer	;ENG;if already was made bitstuffing - don't shift buffer

		dec	temp1	;
		mov	lastBitstufNumber,temp1	;zapamataj si poslednu poziciu bitstuffingu	;ENG;remember last position of bitstuffing
		cpi	bitcount,1		;aby sa ukazovalo na 7 bit (ktory sa ma vymazat alebo kde sa ma vlozit nula)	;ENG;for pointing to 7-th bit (which must be deleted or where to insert zero)
		brne	NoBitcountCorrect
		ldi	bitcount,9	;
		inc	USBBufptrY		;zvys pointer do buffera	ENG;increment pointer to buffer
NoBitcountCorrect:
		dec	bitcount
		bst	BitStuffInOut,0
		brts	CorrectOutBuffer	;ak je Out buffer - zvys dlzku buffera	;ENG;if this is Out buffer - increment buffer length
		rcall	ShiftDeleteBuffer	;posun In buffer	;ENG;shift In buffer
		dec	temp3			;zniz pocitadlo vynechani	;ENG;decrement counter of omission
		rjmp	CorrectBufferEnd
CorrectOutBuffer:
		rcall	ShiftInsertBuffer	;posun Out buffer	;ENG;shift Out buffer
		inc	temp3			;zvys pocitadlo vynechani	;ENG;increment counter of omission
CorrectBufferEnd:
		pop	ByteCount		;obnov dlzku buffera	;ENG;restore buffer length
		pop	USBBufptrY		;obnov pointer do buffera	;ENG;restore pointer to buffer
		rjmp	BitStuffRepeat		;a restartni od zaciatku	;ENG;and restart from begin
DontShiftBuffer:
		dec	temp1			;ak uz boli vsetky bity	;ENG;if already were all bits
		breq	EndBitStuff		;ukonci cyklus	;ENG;finish cycle
		dec	bitcount		;zniz pocitadlo bitov v byte	;ENG;decrement bits counter in byte
		brne	BitStuffByteLoop	;ak este neboli vsetky bity v byte - chod na dalsi bit	;ENG;if not yet been all bits in byte - go to next bit
						;inak nahraj dalsi byte	;ENG;otherwise load next byte
		inc	USBBufptrY		;zvys pointer do buffera	;ENG;increment pointer to buffer
		rjmp	BitStuffLoop		;a opakuj	;ENG;and repeat
EndBitStuff:
		pop	ByteCount		;obnov dlzku buffera	;ENG;restore buffer length
		pop	USBBufptrY		;obnov pointer do buffera	;ENG;restore pointer to buffer
		bst	BitStuffInOut,0
		brts	IncrementLength		;ak je Out buffer - zvys dlzku Out buffera	;ENG;if this is Out buffer - increment length of Out buffer
DecrementLength:				;ak je In buffer - zniz dlzku In buffera	;ENG;if this is In buffer - decrement length of In buffer
		cpi	temp3,0			;bolo aspon jedno znizenie	;ENG;was at least one decrement
		breq	NoChangeByteCount	;ak nie - nemen dlzku buffera	;ENG;if no - don't change buffer length
		dec	ByteCount		;ak je In buffer - zniz dlzku buffera	;ENG;if this is In buffer - decrement buffer length
		subi	temp3,256-8		;ak nebolo viac ako 8 bitov naviac	;ENG;if there wasn't above 8 bits over
		brcc	NoChangeByteCount	;tak skonci	;ENG;then finish
		dec	ByteCount		;inak este zniz dlzku buffera	;ENG;otherwise next decrement buffer length
		ret				;a skonci	;ENG;and finish
IncrementLength:
		mov	OutBitStuffNumber,temp3	;zapamataj si pocet bitov naviac	;ENG;remember number of bits over
		subi	temp3,8			;ak nebolo viac ako 8 bitov naviac	;ENG;if there wasn't above 8 bits over
		brcs	NoChangeByteCount	;tak skonci	;ENG;then finish
		inc	ByteCount		;inak zvys dlzku buffera	;ENG;otherwise increment buffer length
		mov	OutBitStuffNumber,temp3	;a zapamataj si pocet bitov naviac (znizene o 8)	;ENG;and remember number of bits over (decremented by 8)
NoChangeByteCount:
		ret				;skonci	;ENG;finish
;------------------------------------------------------------------------------------------
ShiftInsertBuffer:	;posuv buffer o jeden bit vpravo od konca az po poziciu: byte-USBBufptrY a bit-bitcount	;ENG;shift buffer by one bit to right from end till to position: byte-USBBufptrY and bit-bitcount
		mov	temp0,bitcount		;vypocet: bitcount= 9-bitcount	;ENG;calculation: bitcount= 9-bitcount
		ldi	bitcount,9
		sub	bitcount,temp0		;do bitcount poloha bitu, ktory treba nulovat	;ENG;to bitcount bit position, which is necessary to clear

		ld	temp1,Y			;nahraj byte ktory este treba posunut od pozicie bitcount	;ENG;load byte which still must be shifted from position bitcount
		rol	temp1			;a posun vlavo cez Carry (prenos z vyssieho byte a LSB do Carry)	;ENG;and shift to the left through Carry (transmission from higher byte and LSB to Carry)
		ser	temp2			;FF do masky - temp2	;ENG;FF to mask - temp2
HalfInsertPosuvMask:
		lsl	temp2			;nula do dalsieho spodneho bitu masky	;ENG;zero to the next low bit of mask
		dec	bitcount		;az pokial sa nedosiahne hranica posuvania v byte	;ENG;till not reached boundary of shifting in byte
		brne	HalfInsertPosuvMask

		and	temp1,temp2		;odmaskuj aby zostali iba vrchne posunute bity v temp1	;ENG;unmask that remains only high shifted bits in temp1
		com	temp2			;invertuj masku	;ENG;invert mask
		lsr	temp2			;posun masku vpravo - na vlozenie nuloveho bitu	;ENG;shift mask to the right - for insertion of zero bit
		ld	temp0,Y			;nahraj byte ktory este treba posunut od pozicie bitcount do temp0	;ENG;load byte which must be shifted from position bitcount to temp0
		and	temp0,temp2		;odmaskuj aby zostali iba spodne neposunute bity v temp0	;ENG;unmask to remains only low non-shifted bits in temp0
		or	temp1,temp0		;a zluc posunutu a neposunutu cast	;ENG;and put together shifted and nonshifted part

		ld	temp0,Y			;nahraj byte ktory este treba posunut od pozicie bitcount	;ENG;load byte which must be shifted from position bitcount
		rol	temp0			;a posun ho vlavo cez Carry (aby sa nastavilo spravne Carry pre dalsie prenosy)	;ENG;and shift it to the left through Carry (to set right Carry for further carry)
		st	Y+,temp1		;a nahraj spat upraveny byte	;ENG;and load back modified byte
ShiftInsertBufferLoop:
		cpse	USBBufptrY,ByteCount	;ak nie su vsetky cele byty	;ENG;if are not all entire bytes
		rjmp	NoEndShiftInsertBuffer	;tak pokracuj	;ENG;then continue
		ret				;inak skonci	;ENG;otherwise finish
NoEndShiftInsertBuffer:
		ld	temp1,Y			;nahraj byte	;ENG;load byte
		rol	temp1			;a posun vlavo cez Carry (prenos z nizsieho byte a LSB do Carry)	;ENG;and shift to the left through Carry (carry from low byte and LSB to Carry)
		st	Y+,temp1		;a nahraj spat	;ENG;and store back
		rjmp	ShiftInsertBufferLoop	;a pokracuj	;ENG;and continue
;------------------------------------------------------------------------------------------
ShiftDeleteBuffer:	;posuv buffera o jeden bit vlavo od konca az po poziciu: byte-USBBufptrY a bit-bitcount	;ENG;shift buffer one bit to the left from end to position: byte-USBBufptrY and bit-bitcount
		mov	temp0,bitcount		;vypocet: bitcount= 9-bitcount	;ENG;calculation: bitcount= 9-bitcount
		ldi	bitcount,9
		sub	bitcount,temp0		;do bitcount poloha bitu, ktory este treba posunut	;ENG;to bitcount bit position, which must be shifted
		mov	temp0,USBBufptrY	;uschovanie pointera do buffera	;ENG;backup pointera to buffer
		inc	temp0			;pozicia celych bytov do temp0	;ENG;position of completed bytes to temp0
		mov	USBBufptrY,ByteCount	;maximalna pozicia do pointera	;ENG;maximum position to pointer
ShiftDeleteBufferLoop:
		ld	temp1,-Y		;zniz buffer a nahraj byte	;ENG;decrement buffer and load byte
		ror	temp1			;a posun vpravo cez Carry (prenos z vyssieho byte a LSB do Carry)	;ENG;and right shift through Carry (carry from higher byte and LSB to Carry)
		st	Y,temp1			;a nahraj spat	;ENG;and store back
		cpse	USBBufptrY,temp0	;ak nie su vsetky cele byty	;ENG;if there are not all entire bytes
		rjmp	ShiftDeleteBufferLoop	;tak pokracuj	;ENG;then continue

		ld	temp1,-Y		;zniz buffer a nahraj byte ktory este treba posunut od pozicie bitcount	;ENG;decrement buffer and load byte which must be shifted from position bitcount
		ror	temp1			;a posun vpravo cez Carry (prenos z vyssieho byte a LSB do Carry)	;ENG;and right shift through Carry (carry from higher byte and LSB to Carry)
		ser	temp2			;FF do masky - temp2	;ENG;FF to mask - temp2
HalfDeletePosuvMask:
		dec	bitcount		;az pokial sa nedosiahne hranica posuvania v byte	;ENG;till not reached boundary of shifting in byte
		breq	DoneMask
		lsl	temp2			;nula do dalsieho spodneho bitu masky	;ENG;zero to the next low bit of mask
		rjmp	HalfDeletePosuvMask
DoneMask:
		and	temp1,temp2		;odmaskuj aby zostali iba vrchne posunute bity v temp1	;ENG;unmask to remain only high shifted bits in temp1
		com	temp2			;invertuj masku	;ENG;invert mask
		ld	temp0,Y			;nahraj byte ktory este treba posunut od pozicie bitcount do temp0	;ENG;load byte which must be shifted from position bitcount to temp0
		and	temp0,temp2		;odmaskuj aby zostali iba spodne neposunute bity v temp0	;ENG;unmask to remain only low nonshifted bits in temp0
		or	temp1,temp0		;a zluc posunutu a neposunutu cast	;ENG;and put together shifted and nonshifted part
		st	Y,temp1			;a nahraj spat	;ENG;and store back
		ret				;a skonci	;ENG;and finish
;------------------------------------------------------------------------------------------
MirrorInBufferBytes:
		push	USBBufptrY
		push	ByteCount
		ldi	USBBufptrY,InputBufferBegin
		rcall	MirrorBufferBytes
		pop	ByteCount
		pop	USBBufptrY
		ret
;------------------------------------------------------------------------------------------
MirrorBufferBytes:
		add	ByteCount,USBBufptrY	;ByteCount ukazuje na koniec spravy	;ENG;ByteCount shows to the end of message
MirrorBufferloop:
		ld	temp0,Y			;nahraj prijaty byte z buffera	;ENG;load received byte from buffer
		ldi	temp1,8			;pocitadlo bitov	;ENG;bits counter
MirrorBufferByteLoop:
		ror	temp0			;do carry dalsi najnizsi bit	;ENG;to carry next least bit
		rol	temp2			;z carry dalsi bit na obratene poradie	;ENG;from carry next bit to reverse order
		dec	temp1			;bol uz cely byte	;ENG;was already entire byte
		brne	MirrorBufferByteLoop	;ak nie tak opakuj dalsi najnizsi bit	;ENG;if no then repeat next least bit
		st	Y+,temp2		;ulozenie spat ako obrateny byte  a zvys pointer do buffera	;ENG;save back as reversed byte  and increment pointer to buffer
		cp	USBBufptrY,ByteCount	;ak este neboli vsetky	;ENG;if not yet been all
		brne	MirrorBufferloop	;tak opakuj	;ENG;then repeat
		ret				;inak skonci	;ENG;otherwise finish
;------------------------------------------------------------------------------------------
;CheckCRCIn:	;ENG;CheckCRCIn:
;		push	USBBufptrY	;ENG;		kiss	USBBUFPTRY
;		push	ByteCount	;ENG;		kiss	ByteCount
;		ldi	USBBufptrY,InputBuffercompare	;ENG;		ldi	USBBUFPTRY,InputBuffercompare
;		rcall	CheckCRC	;ENG;		rcall	CheckCRC
;		pop	ByteCount	;ENG;		pope	ByteCount
;		pop	USBBufptrY	;ENG;		pope	USBBUFPTRY
;		ret	;ENG;		lip
;------------------------------------------------------------------------------------------
AddCRCOut:
		push	USBBufptrY
		push	ByteCount
		ldi	USBBufptrY,OutputBufferBegin
		rcall	CheckCRC
		com	temp0			;negacia CRC	;ENG;negation of CRC
		com	temp1
		st	Y+,temp1		;ulozenie CRC na koniec buffera (najskor MSB)	;ENG;save CRC to the end of buffer (at first MSB)
		st	Y,temp0			;ulozenie CRC na koniec buffera (potom LSB)	;ENG;save CRC to the end of buffer (then LSB)
		dec	USBBufptrY		;pointer na poziciu CRC	;ENG;pointer to CRC position
		ldi	ByteCount,2		;otocit 2 byty CRC	;ENG;reverse bits order in 2 bytes CRC
		rcall	MirrorBufferBytes	;opacne poradie bitov CRC (pri vysielani CRC sa posiela naskor MSB)	;ENG;reverse bits order in CRC (transmiting CRC - MSB first)
		pop	ByteCount
		pop	USBBufptrY
		ret
;------------------------------------------------------------------------------------------
CheckCRC:	;vstup: USBBufptrY = zaciatok spravy	,ByteCount = dlzka spravy	;ENG;input: USBBufptrY = begin of message	,ByteCount = length of message
		add	ByteCount,USBBufptrY	;ByteCount ukazuje na koniec spravy	;ENG;ByteCount points to the end of message
		inc	USBBufptrY		;nastav pointer na zaciatok spravy - vynechat SOP	;ENG;set the pointer to message start - omit SOP
		ld	temp0,Y+		;nahraj PID do temp0	;ENG;load PID to temp0
						;a nastav pointer na zaciatok spravy - vynechat aj PID	;ENG;and set the pointer to start of message - omit also PID
		cpi	temp0,DATA0PID		;ci je DATA0 pole	;ENG;if is DATA0 field
		breq	ComputeDATACRC		;pocitaj CRC16	;ENG;compute CRC16
		cpi	temp0,DATA1PID		;ci je DATA1 pole	;ENG;if is DATA1 field
		brne	CRC16End		;ak nie tak skonci 	;ENG;if no then finish
ComputeDATACRC:
		ser	temp0			;inicializacia zvysku LSB na 0xff	;ENG;initialization of remaider LSB to 0xff
		ser	temp1			;inicializacia zvysku MSB na 0xff			;ENG;initialization of remaider MSB to 0xff
CRC16Loop:
		ld	temp2,Y+		;nahraj spravu do temp2 a zvys pointer do buffera	;ENG;load message to temp2 and increment pointer to buffer
		ldi	temp3,8			;pocitadlo bitov v byte - temp3	;ENG;bits counter in byte - temp3
CRC16LoopByte:
		bst	temp1,7			;do T uloz MSB zvysku (zvysok je iba 16 bitovy - 8 bit vyssieho byte)	;ENG;to T save MSB of remainder (remainder is only 16 bits - 8 bit of higher byte)
		bld	bitcount,0		;do bitcount LSB uloz T - MSB zvysku	;ENG;to bitcount LSB save T - of MSB remainder
		eor	bitcount,temp2		;XOR bitu spravy a bitu zvysku - v LSB bitcount	;ENG;XOR of bit message and bit remainder - in LSB bitcount
		rol	temp0			;posun zvysok dolava - nizsi byte (dva byty - cez carry)	;ENG;shift remainder to the left - low byte (two bytes - through carry)
		rol	temp1			;posun zvysok dolava - vyssi byte (dva byty - cez carry)	;ENG;shift remainder to the left - high byte (two bytes - through carry)
		cbr	temp0,1			;znuluj LSB zvysku	;ENG;znuluj LSB remains
		lsr	temp2			;posun spravu doprava	;ENG;shift message to right
		ror	bitcount		;vysledok XOR-u bitov z LSB do carry	;ENG;result of XOR bits from LSB to carry
		brcc	CRC16NoXOR		;ak je XOR bitu spravy a MSB zvysku = 0 , tak nerob XOR	;ENG;if is XOR bitmessage and MSB of remainder = 0 , then no XOR
		ldi	bitcount,CRC16poly>>8	;do bitcount CRC polynom - vrchny byte	;ENG;to bitcount CRC polynomial - high byte
		eor	temp1,bitcount		;a urob XOR zo zvyskom a CRC polynomom - vrchny byte	;ENG;and make XOR from remains and CRC polynomial - high byte
		ldi	bitcount,CRC16poly	;do bitcount CRC polynom - spodny byte	;ENG;to bitcount CRC polynomial - low byte
		eor	temp0,bitcount		;a urob XOR zo zvyskom a CRC polynomom - spodny byte	;ENG;and make XOR of remainder and CRC polynomial - low byte
CRC16NoXOR:
		dec	temp3			;boli uz vsetky bity v byte	;ENG;were already all bits in byte
		brne	CRC16LoopByte		;ak nie, tak chod na dalsi bit	;ENG;unless, then go to next bit
		cp	USBBufptrY,ByteCount	;bol uz koniec spravy	;ENG;was already end-of-message
		brne	CRC16Loop		;ak nie tak opakuj	;ENG;unless then repeat
CRC16End:
		ret				;inak skonci (v temp0 a temp1 je vysledok)	;ENG;otherwise finish (in temp0 and temp1 is result)
;------------------------------------------------------------------------------------------
LoadDescriptorFromROM:
		lpm				;nahraj z pozicie ROM pointera do R0	;ENG;load from ROM position pointer to R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer	;ENG;R0 save to buffer and increment buffer
		adiw	ZH:ZL,1			;zvys ukazovatel do ROM	;ENG;increment index to ROM
		dec	ByteCount		;pokial nie su vsetky byty	;ENG;till are not all bytes
		brne	LoadDescriptorFromROM	;tak nahravaj dalej	;ENG;then load next
		rjmp	EndFromRAMROM		;inak skonci	;ENG;otherwise finish
;------------------------------------------------------------------------------------------
LoadDescriptorFromROMZeroInsert:
		lpm				;nahraj z pozicie ROM pointerra do R0	;ENG;load from ROM position pointer to R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer	;ENG;R0 save to buffer and increment buffer

		bst	RAMread,3		;ak je 3 bit jednotkovy - nebude sa vkladat nula	;ENG;if bit 3 is one - don't insert zero
		brtc	InsertingZero		;inak sa bude vkladat nula	;ENG;otherwise zero will be inserted
		adiw	ZH:ZL,1			;zvys ukazovatel do ROM	;ENG;increment index to ROM
		lpm				;nahraj z pozicie ROM pointerra do R0	;ENG;load from ROM position pointer to R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer	;ENG;R0 save to buffer and increment buffer
		clt				;a znuluj	;ENG;and clear
		bld	RAMread,3		;treti bit v RAMread - aby sa v dalsom vkladali nuly	;ENG;the third bit in RAMread - for to the next zero insertion will be made
		rjmp	InsertingZeroEnd	;a pokracuj	;ENG;and continue
InsertingZero:
		clr	R0			;na vkladanie nul	;ENG;for insertion of zero
		st	Y+,R0			;nulu uloz do buffera a zvys buffer	;ENG;zero save to buffer and increment buffer
InsertingZeroEnd:
		adiw	ZH:ZL,1			;zvys ukazovatel do ROM	;ENG;increment index to ROM
		subi	ByteCount,2		;pokial nie su vsetky byty	;ENG;till are not all bytes
		brne	LoadDescriptorFromROMZeroInsert	;tak nahravaj dalej	;ENG;then load next
		rjmp	EndFromRAMROM		;inak skonci	;ENG;otherwise finish
;------------------------------------------------------------------------------------------
LoadDescriptorFromSRAM:
		ld	R0,Z			;nahraj z pozicie RAM pointerra do R0	;ENG;load from position RAM pointer to R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer	;ENG;R0 save to buffer and increment buffer
		adiw	ZH:ZL,1			;zvys ukazovatel do RAM	;ENG;increment index to RAM
		dec	ByteCount		;pokial nie su vsetky byty	;ENG;till are not all bytes
		brne	LoadDescriptorFromSRAM	;tak nahravaj dalej	;ENG;then load next
		rjmp	EndFromRAMROM		;inak skonci	;ENG;otherwise finish
;------------------------------------------------------------------------------------------
LoadDescriptorFromEEPROM:
		out	EEARL,ZL		;nastav adresu EEPROM Lo	;ENG;set the address EEPROM Lo
		out	EEARH,ZH		;nastav adresu EEPROM Hi	;ENG;set the address EEPROM Hi
		sbi	EECR,EERE		;vycitaj EEPROM do registra EEDR	;ENG;read EEPROM to register EEDR
		in	R0,EEDR			;nahraj z EEDR do R0	;ENG;load from EEDR to R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer	;ENG;R0 save to buffer and increment buffer
		adiw	ZH:ZL,1			;zvys ukazovatel do EEPROM	;ENG;increment index to EEPROM
		dec	ByteCount		;pokial nie su vsetky byty	;ENG;till are not all bytes
		brne	LoadDescriptorFromEEPROM;tak nahravaj dalej	;ENG;then load next
		rjmp	EndFromRAMROM		;inak skonci	;ENG;otherwise finish
;------------------------------------------------------------------------------------------
LoadXXXDescriptor:
		ldi	temp0,SOPbyte			;SOP byte	;ENG;SOP byte
		sts	OutputBufferBegin,temp0		;na zaciatok vysielacieho buffera dat SOP	;ENG;to begin of tramsmiting buffer store SOP
		ldi	ByteCount,8			;8 bytov nahrat	;ENG;8 byte store
		ldi	USBBufptrY,OutputBufferBegin+2	;do vysielacieho buffera	;ENG;to transmitting buffer

		and	RAMread,RAMread			;ci sa bude citat z RAM alebo ROM-ky alebo EEPROM-ky	;ENG;if will be reading from RAM or ROM or EEPROM
		brne	FromRAMorEEPROM			;0=ROM,1=RAM,2=EEPROM,4=ROM s vkladanim nuly	;ENG;0=ROM,1=RAM,2=EEPROM,4=ROM with zero insertion (string)
FromROM:
		rjmp	LoadDescriptorFromROM		;nahrat descriptor z ROM-ky	;ENG;load descriptor from ROM
FromRAMorEEPROM:
		sbrc	RAMread,2			;ak RAMread=4	;ENG;if RAMREAD=4
		rjmp	LoadDescriptorFromROMZeroInsert	;citaj z ROM s vkladanim nuly	;ENG;read from ROM with zero insertion
		sbrc	RAMread,0			;ak RAMread=1	;ENG;if RAMREAD=1
		rjmp	LoadDescriptorFromSRAM		;nahraj data zo SRAM-ky	;ENG;load data from SRAM
		rjmp	LoadDescriptorFromEEPROM	;inak citaj z EEPROM	;ENG;otherwise read from EEPROM
EndFromRAMROM:
		sbrc	RAMread,7			;ak je najvyssi bit v premennej RAMread=1	;ENG;if is most significant bit in variable RAMread=1
		clr	RAMread				;znuluj RAMread	;ENG;clear RAMread
		rcall	ToggleDATAPID			;zmenit DATAPID	;ENG;change DATAPID
		ldi	USBBufptrY,OutputBufferBegin+1	;do vysielacieho buffera - pozicia DATA PID	;ENG;to transmitting buffer - position of DATA PID
		ret
;------------------------------------------------------------------------------------------
PrepareUSBOutAnswer:	;pripravenie odpovede do buffera	;ENG;prepare answer to buffer
		rcall	PrepareUSBAnswer		;pripravenie odpovede do buffera	;ENG;prepare answer to buffer
MakeOutBitStuff:
		inc	BitStuffInOut			;vysielaci buffer - vkladanie bitstuff bitov	;ENG;transmitting buffer - insertion of bitstuff bits
		ldi	USBBufptrY,OutputBufferBegin	;do vysielacieho buffera	;ENG;to transmitting buffer
		rcall	BitStuff
		mov	OutputBufferLength,ByteCount	;dlzku odpovede zapamatat pre vysielanie	;ENG;length of answer store for transmiting
		clr	BitStuffInOut			;prijimaci buffer - mazanie bitstuff bitov	;ENG;receiving buffer - deletion of bitstuff bits
		ret
;------------------------------------------------------------------------------------------
PrepareUSBAnswer:	;pripravenie odpovede do buffera	;ENG;prepare answer to buffer
		clr	RAMread				;nulu do RAMread premennej - cita sa z ROM-ky	;ENG;zero to RAMread variable - reading from ROM
		lds	temp0,InputBufferBegin+2	;bmRequestType do temp0	;ENG;bmRequestType to temp0
		lds	temp1,InputBufferBegin+3	;bRequest do temp1	;ENG;bRequest to temp1
		cbr	temp0,0b10011111		;ak je 5 a 6 bit nulovy	;ENG;if is 5 and 6 bit zero
		brne	VendorRequest			;tak to nie je  Vendor Request	;ENG;then this isn't  Vendor Request
		rjmp	StandardRequest			;ale je to standardny request	;ENG;but this is standard Request
;--------------------------
VendorRequest:
		clr	ZH				;pre citanie z RAM alebo EEPROM	;ENG;for reading from RAM or EEPROM

		cpi	temp1,1				;
		brne	NoDoSetInfraBufferEmpty		;
		rjmp	DoSetInfraBufferEmpty		;restartne infra prijimanie (ak bolo zastavene citanim z RAM-ky)	;ENG;restart infra receiving (if it was stopped by reading from RAM)
NoDoSetInfraBufferEmpty:
		cpi	temp1,2				;
		brne	NoDoGetInfraCode
		rjmp	DoGetInfraCode			;vysle prijaty infra kod (ak je v bufferi)	;ENG;transmit received infra code (if it is in buffer)
NoDoGetInfraCode:
		cpi	temp1,3				;
		brne	NoDoSetDataPortDirection
		rjmp	DoSetDataPortDirection		;nastavi smer toku datovych bitov	;ENG;set flow direction of datal bits
NoDoSetDataPortDirection:
		cpi	temp1,4				;
		brne	NoDoGetDataPortDirection
		rjmp	DoGetDataPortDirection		;zisti smer toku datovych bitov	;ENG;detect of flow direction of data bits
NoDoGetDataPortDirection:
		cpi	temp1,5				;
		brne	NoDoSetOutDataPort
		rjmp	DoSetOutDataPort		;nastavi datove bity (ak su vstupne, tak ich pull-up)	;ENG;set data bits (if they are inputs, then pull-ups)
NoDoSetOutDataPort:
		cpi	temp1,6				;
		brne	NoDoGetOutDataPort
		rjmp	DoGetOutDataPort		;zisti nastavenie datovych out bitov (ak su vstupne, tak ich pull-up)	;ENG;detect settings of data out bits (if they are input, then pull-ups)
NoDoGetOutDataPort:
		cpi	temp1,7				;
		brne	NoDoGetInDataPort
		rjmp	DoGetInDataPort			;vrati hodnotu datoveho vstupneho portu	;ENG;return value of input data port
NoDoGetInDataPort:
		cpi	temp1,8				;
		brne	NoDoEEPROMRead
		rjmp	DoEEPROMRead			;vrati obsah EEPROM od urcitej adresy	;ENG;return contents of EEPROM from given address
NoDoEEPROMRead:
		cpi	temp1,9				;
		brne	NoDoEEPROMWrite
		rjmp	DoEEPROMWrite			;zapise EEPROM na urcitu adresu urcite data	;ENG;write to EEPROM to given address given data
NoDoEEPROMWrite:
		cpi	temp1,10			;
		brne	NoDoRS232Send
		rjmp	DoRS232Send			;vysle byte na seriovy linku	;ENG;transmit byte to serial line
NoDoRS232Send:
		cpi	temp1,11			;
		brne	NoDoRS232Read
		rjmp	DoRS232Read			;vrati prijaty byte zo seriovej linky (ak sa nejaky prijal)	;ENG;returns received byte from serial line
NoDoRS232Read:
		cpi	temp1,12			;
		brne	NoDoSetRS232Baud
		rjmp	DoSetRS232Baud			;nastavi prenosovu rychlost seriovej linky	;ENG;set line speed of of serial line
NoDoSetRS232Baud:
		cpi	temp1,13			;
		brne	NoDoGetRS232Baud
		rjmp	DoGetRS232Baud			;vrati prenosovu rychlost seriovej linky	;ENG;return line speed of serial line
NoDoGetRS232Baud:
		cpi	temp1,14			;
		brne	NoDoGetRS232Buffer
		rjmp	DoGetRS232Buffer		;vrati prenosovu rychlost seriovej linky	;ENG;return line speed of serial line
NoDoGetRS232Buffer:
		cpi	temp1,15			;
		brne	NoDoSetRS232DataBits
		rjmp	DoSetRS232DataBits		;nastavi prenosovu rychlost seriovej linky	;ENG;set line speed of serial line
NoDoSetRS232DataBits:
		cpi	temp1,16			;
		brne	NoDoGetRS232DataBits
		rjmp	DoGetRS232DataBits		;vrati prenosovu rychlost seriovej linky	;ENG;return line speed of serial line
NoDoGetRS232DataBits:
		cpi	temp1,17			;
		brne	NoDoSetRS232Parity
		rjmp	DoSetRS232Parity		;nastavi prenosovu rychlost seriovej linky	;ENG;set line speed of serial line
NoDoSetRS232Parity:
		cpi	temp1,18			;
		brne	NoDoGetRS232Parity
		rjmp	DoGetRS232Parity		;vrati prenosovu rychlost seriovej linky	;ENG;return line speed of serial line
NoDoGetRS232Parity:
		cpi	temp1,19			;
		brne	NoDoSetRS232StopBits
		rjmp	DoSetRS232StopBits		;nastavi prenosovu rychlost seriovej linky	;ENG;set line speed of serial line
NoDoSetRS232StopBits:
		cpi	temp1,20			;
		brne	NoDoGetRS232StopBits
		rjmp	DoGetRS232StopBits		;vrati prenosovu rychlost seriovej linky	;ENG;return line speed of serial line
NoDoGetRS232StopBits:

		cpi	temp1,USER_FNC_NUMBER+0		;
		brne	NoDoUserFunction0
		rjmp	DoUserFunction0			;vykona uzivatelsku rutinu0	;ENG;execute of user function0
NoDoUserFunction0:
		cpi	temp1,USER_FNC_NUMBER+1		;
		brne	NoDoUserFunction1
		rjmp	DoUserFunction1			;vykona uzivatelsku rutinu1	;ENG;execute of user function1
NoDoUserFunction1:
		cpi	temp1,USER_FNC_NUMBER+2		;
		brne	NoDoUserFunction2
		rjmp	DoUserFunction2			;vykona uzivatelsku rutinu2	;ENG;execute of user function1
NoDoUserFunction2:

		rjmp	ZeroDATA1Answer			;ak to bolo nieco nezname, tak priprav nulovu odpoved	;ENG;if that it was something unknown, then prepare zero answer


;----------------------------- USER FUNCTIONS --------------------------------------

;------------------------------TEMPLATE OF YOUR FUNCTION----------------------------
;------------------ BEGIN: This is template how to write own function --------------

;free of use are registers:
	;temp0,temp1,temp2,temp3,ACC,ZH,ZL
	;registers are destroyed after execution (use push/pop to save content)

;at the end of routine you must correctly set registers:
	;RAMread - 0=reading from ROM, 1=reading from RAM, 2=reading from EEPROM
	;temp0 - number of transmitted data bytes
	;ZH,ZL - pointer to buffer of transmitted data (pointer to ROM/RAM/EEPROM)

;to transmit data (preparing data to buffer) :
	;to transmit data you must jump to "ComposeEndXXXDescriptor"
	;to transmit one zero byte you can jump to "OneZeroAnswer"  (commonly used as confirmation of correct processing)
	;to transmit two zero byte you can jump to "TwoZeroAnswer"  (commonly used as confirmation of error in processing)
	;for small size (up to 8 bytes) ansver use buffer AnswerArray (see function DoGetOutDataPort:)

DoUserFunctionX:
DoUserFunction0:  ;send byte(s) of RAM starting at position given by first parameter in function
		lds	temp0,InputBufferBegin+4	;first parameter Lo into temp0
		lds	temp1,InputBufferBegin+5	;first  parameter Hi into temp1
		;lds	temp2,InputBufferBegin+6	;second parameter Lo into temp2
		;lds	temp3,InputBufferBegin+7	;second parameter Hi into temp3
		;lds	ACC,InputBufferBegin+8		;number of requested bytes from USB host (computer) into ACC

		;Here add your own code:
		;-------------------------------------------------------------------
		nop					;example of code - nothing to do
		nop
		nop
		nop
		nop
		;-------------------------------------------------------------------

		mov	ZL,temp0			;will be sending value of RAM - from address stored in temp0 (first parameter Lo of function)
		mov	ZH,temp1			;will be sending value of RAM - from address stored in temp1 (first parameter Hi of function)
		inc	RAMread				;RAMread=1 - reading from RAM
		ldi	temp0,255			;send max number of bytes - 255 bytes are maximum
		rjmp	ComposeEndXXXDescriptor		;a prepare data
DoUserFunction1:
		rjmp	OneZeroAnswer			;only confirm receiving by one zero byte answer
DoUserFunction2:
		rjmp	TwoZeroAnswer			;only confirm receiving by two zero bytes answer
;------------------ END: This is template how to write own function ----------------


;----------------------------- USER FUNCTIONS --------------------------------------
;--------------------------
DoSetInfraBufferEmpty:
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;--------------------------
DoGetInfraCode:
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;--------------------------
DoSetDataPortDirection:
		lds	temp1,InputBufferBegin+7	;stvrty parameter - bitova maska ktore porty menit	;ENG;fourth parameter - bit mask - which port(s) to change

		lds	temp0,InputBufferBegin+4	;prvy parameter - smer datovych bitov DDRB	;ENG;first parameter - direction of data bits DDRB
		andi	temp0,0b00111100		;zamaskovat nepouzite piny	;ENG;mask unused pins
		sbrc	temp1,0				;ak je bit0 nulovy - nemen port	;ENG;if bit0 is zero - don't change port state
		out	DDRB,temp0			;a update smeru datoveho portu	;ENG;and update direction of data port

		lds	temp0,InputBufferBegin+5	;druhy parameter - smer datovych bitov DDRC	;ENG;second parameter - direction of data bits DDRC
		sbrc	temp1,1				;ak je bit1 nulovy - nemen port	;ENG;if bit1 is zero - don't change port state
		out	DDRC,temp0			;a update smeru datoveho portu	;ENG;and update direction of data port

		lds	temp0,InputBufferBegin+6	;treti parameter - smer datovych bitov DDRD	;ENG;third parameter - direction of data bits DDRD
		andi	temp0,0b11111000		;zamaskovat nepouzite piny	;ENG;mask unused pins
		ori	temp0,0b00000010		;zamaskovat nepouzite piny	;ENG;mask unused pins
		sbrc	temp1,2				;ak je bit2 nulovy - nemen port	;ENG;if bit2 is zero - don't change port state
		out	DDRD,temp0			;a update smeru datoveho portu	;ENG;and update direction of data port

		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;--------------------------
DoGetDataPortDirection:
		in	temp0,DDRB			;nacitaj stav smeru DDRB	;ENG;read direction of DDRB
		sts	AnswerArray,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		in	temp0,DDRC			;nacitaj stav smeru DDRC	;ENG;read direction of DDRC
		sts	AnswerArray+1,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		in	temp0,DDRD			;nacitaj stav smeru DDRD	;ENG;read direction of DDRD
		sts	AnswerArray+2,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		ldi	ZL,AnswerArray			;posiela sa hodnota z AnswerArray	;ENG;sending is value from AnswerArray
		ldi	temp0,0x81			;RAMread=1 - cita sa z RAM-ky	;ENG;RAMREAD=1 - reading from RAM
		mov	RAMread,temp0			;(najvyssi bit na 1 - aby sa hned premenna RAMread znulovala)	;ENG;(highest bit set to 1 - to zero RAMread immediatelly)
		ldi	temp0,3				;posielaju sa tri byty	;ENG;sending are three bytes
		rjmp	ComposeEndXXXDescriptor		;a priprav data	;ENG;and prepare data
;--------------------------
DoSetOutDataPort:
		lds	temp1,InputBufferBegin+7	;stvrty parameter - bitova maska ktore porty menit	;ENG;fourth parameter - bit mask - which port(s) to change

		lds	temp0,InputBufferBegin+4	;prvy parameter - hodnota datovych bitov PORTB	;ENG;first parameter - value of data bits PORTB
		andi	temp0,0b00111100		;zamaskovat nepouzite piny	;ENG;mask unused pins
		sbrc	temp1,0				;ak je bit0 nulovy - nemen port	;ENG;if bit0 is zero - don't change port state
		out	PORTB,temp0			;a update datoveho portu	;ENG;and update data port

		lds	temp0,InputBufferBegin+5	;druhy parameter - hodnota datovych bitov PORTC	;ENG;second parameter - value of data bits PORTC
		sbrc	temp1,1				;ak je bit1 nulovy - nemen port	;ENG;if bit1 is zero - don't change port state
		out	PORTC,temp0			;a update datoveho portu	;ENG;and update data port

		lds	temp0,InputBufferBegin+6	;treti parameter - hodnota datovych bitov PORTD	;ENG;third parameter - value of data bits PORTD
		andi	temp0,0b11111000		;zamaskovat nepouzite piny	;ENG;mask unused pins
		ori	temp0,0b00000011		;zamaskovat nepouzite piny	;ENG;mask unused pins
		sbrc	temp1,2				;ak je bit2 nulovy - nemen port	;ENG;if bit2 is zero - don't change port state
		out	PORTD,temp0			;a update datoveho portu	;ENG;and update data port

		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;--------------------------
DoGetOutDataPort:
		in	temp0,PORTB			;nacitaj stav PORTB	;ENG;read PORTB
		sts	AnswerArray,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		in	temp0,PORTC			;nacitaj stav PORTC	;ENG;read PORTC
		sts	AnswerArray+1,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		in	temp0,PORTD			;nacitaj stav PORTD	;ENG;read PORTD
		sts	AnswerArray+2,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		ldi	ZL,AnswerArray			;posiela sa hodnota z AnswerArray	;ENG;sending is value from AnswerArray
		ldi	temp0,0x81			;RAMread=1 - cita sa z RAM-ky	;ENG;RAMREAD=1 - reading from RAM
		mov	RAMread,temp0			;(najvyssi bit na 1 - aby sa hned premenna RAMread znulovala)	;ENG;(highest bit set to 1 - to zero RAMread immediatelly)
		ldi	temp0,3				;posielaju sa tri byty	;ENG;sending are three bytes
		rjmp	ComposeEndXXXDescriptor		;a priprav data	;ENG;and prepare data
;--------------------------
DoGetInDataPort:
		in	temp0,PINB			;nacitaj stav PINB	;ENG;read PINB
		sts	AnswerArray,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		in	temp0,PINC			;nacitaj stav PINC	;ENG;read PINC
		sts	AnswerArray+1,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		in	temp0,PIND			;nacitaj stav PIND	;ENG;read PIND
		sts	AnswerArray+2,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		ldi	ZL,AnswerArray			;posiela sa hodnota z AnswerArray	;ENG;sending is value from AnswerArray
		ldi	temp0,0x81			;RAMread=1 - cita sa z RAM-ky	;ENG;RAMREAD=1 - reading from RAM
		mov	RAMread,temp0			;(najvyssi bit na 1 - aby sa hned premenna RAMread znulovala)	;ENG;(highest bit set to 1 - to zero RAMread immediatelly)
		ldi	temp0,3				;posielaju sa tri byty	;ENG;sending are three bytes
		rjmp	ComposeEndXXXDescriptor		;a priprav data	;ENG;and prepare data
;------------------------------------------------------------------------------------------
 DoGetIn:
		ldi	ZL,0				;posiela sa hodnota v R0	;ENG;sending value in R0
		ldi	temp0,0x81			;RAMread=1 - cita sa z RAM-ky	;ENG;RAMread=1 - reading from RAM
		mov	RAMread,temp0			;(najvyssi bit na 1 - aby sa hned premenna RAMread znulovala)	;ENG;(highest bit set to 1 - to zero RAMread immediatelly)
		ldi	temp0,1				;posli iba jeden byte	;ENG;send only single byte
		rjmp	ComposeEndXXXDescriptor		;a priprav data	;ENG;and prepare data
;------------------------------------------------------------------------------------------
DoEEPROMRead:
		lds	ZL,InputBufferBegin+4		;prvy parameter - offset v EEPROM-ke	;ENG;first parameter - offset in EEPROM
		lds	ZH,InputBufferBegin+5
		ldi	temp0,2
		mov	RAMread,temp0			;RAMread=2 - cita sa z EEPROM-ky	;ENG;RAMREAD=2 - reading from EEPROM
		ldi	temp0,E2END+1			;pocet mojich bytovych odpovedi do temp0 - cela dlzka EEPROM	;ENG;number my byte answers to temp0 - entire length of EEPROM
		rjmp	ComposeEndXXXDescriptor		;inak priprav data	;ENG;otherwise prepare data
;--------------------------
DoEEPROMWrite:
		lds	ZL,InputBufferBegin+4		;prvy parameter - offset v EEPROM-ke (adresa)	;ENG;first parameter - offset in EEPROM (address)
		lds	ZH,InputBufferBegin+5
		lds	R0,InputBufferBegin+6		;druhy parameter - data, ktore sa maju zapisat do EEPROM-ky (data)	;ENG;second parameter - data to store to EEPROM (data)
		out	EEAR,ZL				;nastav adresu EEPROM	;ENG;set the address of EEPROM
		out	EEARH,ZH
		out	EEDR,R0				;nastav data do EEPROM	;ENG;set the data to EEPROM
		cli					;zakaz prerusenie	;ENG;disable interrupt
		sbi	EECR,EEMWE			;nastav master write enable	;ENG;set the master write enable
		sei					;povol prerusenie (este sa vykona nasledujuca instrukcia)	;ENG;enable interrupt (next instruction is performed)
		sbi	EECR,EEWE			;samotny zapis	;ENG;write
 WaitForEEPROMReady:
		sbic	EECR,EEWE			;pockaj si na koniec zapisu	;ENG;wait to the end of write
		rjmp	WaitForEEPROMReady		;v slucke (max cca 4ms) (kvoli naslednemu citaniu/zapisu)	;ENG;in loop (max cca 4ms) (because of possible next reading/writing)
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;--------------------------
DoRS232Send:
		lds	temp0,InputBufferBegin+4	;prvy parameter - hodnota vysielana na RS232	;ENG;first parameter - value transmitted to RS232
		out	UDR,temp0			;vysli data na UART	;ENG;transmit data to UART
 WaitForRS232Send:
		sbis	UCR,TXEN			;ak nie je povoleny UART vysielac	;ENG;if disabled UART transmitter
		rjmp	OneZeroAnswer			;tak skonci - ochrana kvoli zacykleniu v AT90S2323/2343	;ENG;then finish - protection because loop lock in AT90S2323/2343
		sbis	USR,TXC				;pockat na dovysielanie bytu	;ENG;wait for transmition finish
		rjmp	WaitForRS232Send
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;--------------------------
DoRS232Read:
		rjmp	TwoZeroAnswer			;iba potvrd prijem dvoma nulami	;ENG;only acknowledge reception with two zero
;--------------------------
DoSetRS232Baud:
		lds	temp0,InputBufferBegin+4	;prvy parameter - hodnota baudrate na RS232	;ENG;first parameter - value of baudrate of RS232
		lds	temp1,InputBufferBegin+6	;druhy parameter - hodnota baudrate na RS232 - high byte	;ENG;second parameter - baudrate of RS232 - high byte
		cbr	temp1,1<<URSEL			;zapisovat sa bude baudrate high byte (nie UCSRC)	;ENG;writing will be baudrate high byte (no UCSRC)
		out	UBRRH,temp1			;nastav rychlost UART-u high byte	;ENG;set the speed of UART high byte
		out	UBRR,temp0			;nastav rychlost UART-u low byte	;ENG;set the speed of UART low byte
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;--------------------------
DoGetRS232Baud:
		in	temp0,UBRR			;vrat rychlost UART-u Lo	;ENG;return speed of UART Lo
		sts	AnswerArray,temp0
		in	temp0,UBRRH			;vrat rychlost UART-u Hi	;ENG;return speed of UART Hi
		sts	AnswerArray+1,temp0		;do pola AnswerArray	;ENG;to array AnswerArray
		ldi	ZL,AnswerArray			;posiela sa hodnota z AnswerArray	;ENG;sending is value from AnswerArray
		ldi	temp0,0x81			;RAMread=1 - cita sa z RAM-ky	;ENG;RAMREAD=1 - reading from RAM
		mov	RAMread,temp0			;(najvyssi bit na 1 - aby sa hned premenna RAMread znulovala)	;ENG;(highest bit set to 1 - to zero RAMread immediatelly)
		ldi	temp0,2				;posielaju sa dva byty	;ENG;sending are two bytes
		rjmp	ComposeEndXXXDescriptor		;a priprav data	;ENG;and prepare data
;--------------------------
DoGetRS232Buffer:
		cbi	UCR,RXCIE			;zakazat interrupt od prijimania UART	;ENG;disable interrupt from UART receiving
		nop
		lds	temp0,RS232LengthPosPtr
		lds	temp1,RS232LengthPosPtr+1	;zisti dlzku buffera RS232 kodu 	;ENG;obtain buffer length of RS232 code
		sbi	UCR,RXCIE			;povolit interrupt od prijimania UART	;ENG;enable interrupt from UART receiving

		cpi	temp0,0				;ak nie je RS232 Buffer prazdny	;ENG;if this isn't RS232 Buffer empty
		brne	SomeRS232Send			;tak ho posli	;ENG;then send it
		cpi	temp1,0				;ak nie je RS232 Buffer prazdny	;ENG;if this isn't RS232 Buffer empty
		brne	SomeRS232Send			;tak ho posli	;ENG;then send it
		rjmp	OneZeroAnswer			;inak nic neposli a potvrd prijem jednou nulou	;ENG;otherwise nothing send and acknowledge reception with single zero
 SomeRS232Send:
		lds	ACC,InputBufferBegin+8		;pocet pozadovanych bytov do ACC	;ENG;number of requiring bytes to ACC
		ldi	temp2,2				;pocet moznych dodanych bajtov (plus word dlzky buffera)	;ENG;number of possible bytes (plus word of buffer length)
		add	temp0,temp2
		ldi	temp2,0
		adc	temp1,temp2
		cpi	temp1,0				;ak je MSB>0	;ENG;if is MSB>0
		brne	AsRequiredGetRS232Buffer	;vysli tolko kolko sa ziada	;ENG;transmit as many as requested
		cp	ACC,temp0			;ak sa neziada viac ako mozem dodat	;ENG;if no requested more that I can send
		brcc	NoShortGetRS232Buffer		;vysli tolko kolko sa ziada	;ENG;transmit as many as requested
 AsRequiredGetRS232Buffer:
		mov	temp0,ACC
		ldi	temp1,0
 NoShortGetRS232Buffer:
		subi	temp0,2				;uber word dlzky	;ENG;substract word length
		sbci	temp1,0
		lds	temp2,RS232ReadPosPtr		;zisti ukazovatel citania buffera RS232 kodu	;ENG;obtain index of reading of buffer of RS232 code
		lds	temp3,RS232ReadPosPtr+1
		add	temp2,temp0			;zisti kde je koniec	;ENG;obtain where is end
		adc	temp3,temp1
		cpi	temp3,HIGH(RS232BufferEnd+1)	;ci by mal pretiect	;ENG;if it would overflow
		brlo	ReadNoOverflow			;
		brne	ReadOverflow			;ak ano - skoc na pretecenie	;ENG;if yes - skip to overflow

		cpi	temp2,LOW(RS232BufferEnd+1)	;inak porovnaj LSB	;ENG;otherwise compare LSB
		brlo	ReadNoOverflow			;a urob to iste	;ENG;and do the same
 ReadOverflow:
		subi	temp2,LOW(RS232BufferEnd+1)	;vypocitaj kolko sa neprenesie	;ENG;caculate how many not transfered
		sbci	temp3,HIGH(RS232BufferEnd+1)	;vypocitaj kolko sa neprenesie	;ENG;caculate how many not transfered
		sub	temp0,temp2			;a o to skrat dlzku citania	;ENG;and with this short length of reading
		sbc	temp1,temp3			;a o to skrat dlzku citania	;ENG;and with this short length of reading
		ldi	temp2,LOW(RS232FIFOBegin)	;a zacni od nuly	;ENG;and start from zero
		ldi	temp3,HIGH(RS232FIFOBegin)	;a zacni od nuly	;ENG;and start from zero
 ReadNoOverflow:
		lds	ZL,RS232ReadPosPtr		;zisti ukazovatel citania buffera RS232 kodu	;ENG;obtain index of reading of buffer of RS232 code
		lds	ZH,RS232ReadPosPtr+1		;zisti ukazovatel citania buffera RS232 kodu	;ENG;obtain index of reading of buffer of RS232 code

		sts	RS232ReadPosPtr,temp2		;zapis novy ukazovatel citania buffera RS232 kodu	;ENG;write new index of reading of buffer of RS232 code
		sts	RS232ReadPosPtr+1,temp3		;zapis novy ukazovatel citania buffera RS232 kodu	;ENG;write new index of reading of buffer of RS232 code
		sbiw	ZL,2				;priestor pre udaj dlzky - prenasa sa ako prvy word	;ENG;space for length data - transmitted as first word

		cbi	UCR,RXCIE			;zakazat interrupt od prijimania UART	;ENG;disable interrupt from UART receiving
		inc	RAMread				;RAMread=1 - cita sa z RAM-ky	;ENG;RAMread=1 reading from RAM
		lds	temp2,RS232LengthPosPtr
		lds	temp3,RS232LengthPosPtr+1	;zisti dlzku buffera RS232 kodu 	;ENG;obtain buffer length of RS232 code
		sub	temp2,temp0			;zniz dlzku buffera	;ENG;decrement buffer length
		sbc	temp3,temp1
		sts	RS232LengthPosPtr,temp2		;zapis novu dlzku buffera RS232 kodu 	;ENG;write new buffer length of RS232 code
		sts	RS232LengthPosPtr+1,temp3
		sbi	UCR,RXCIE			;povolit interrupt od prijimania UART	;ENG;enable interrupt from UART receiving

		st	Z+,temp2			;a uloz skutocnu dlzku do paketu	;ENG;and save real length to packet
		st	Z,temp3				;a uloz skutocnu dlzku do paketu	;ENG;and save real length to packet
		sbiw	ZL,1				;a nastav sa na zaciatok	;ENG;and set to begin
		inc	temp0				;a o tento jeden word zvys pocet prenasanych bajtov (dlzka buffer)	;ENG;and about this word increment number of transmited bytes (buffer length)
		inc	temp0
		rjmp	ComposeEndXXXDescriptor		;a priprav data	;ENG;and prepare data
;------------------------------------------------------------------------------------------
DoSetRS232DataBits:
		lds	temp0,InputBufferBegin+4	;prvy parameter - data bits 0=5db, 1=6db, 2=7db, 3=8db	;ENG;first parameter - data bits 0=5db, 1=6db, 2=7db, 3=8db
		cpi	temp0,DataBits8			;ak sa ma nastavit 8-bitova komunikacia	;ENG;if to set 8-bits communication
		breq	Databits8or9Set			;tak nemen 8/9 bitovu komunikaciu	;ENG;then don't change 8/9 bit communication
		in	temp1,UCSRB			;inak nacitaj UCSRB	;ENG;otherwise load UCSRB
		cbr	temp1,(1<<UCSZ2)		;vymaz 9-bitovu komunikaciu	;ENG;clear 9-bit communication
		out	UCSRB,temp1			;a zapis spat	;ENG;and write back
 Databits8or9Set:
		rcall	RS232DataBitsLocal
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
 RS232DataBitsLocal:
 		rcall	GetUCSRCtotemp1
		bst	temp0,0				;nastav UCSZ0	;ENG;set the UCSZ0
		bld	temp1,UCSZ0
		bst	temp0,1				;nastav UCSZ1	;ENG;set the UCSZ1
		bld	temp1,UCSZ1
		rcall	Settemp1toUCSRC
		ret
 GetUCSRCtotemp1:
		cli					;zisti UCSRC	;ENG;obtain UCSRC
		in	temp1,UBRRH
		in	temp1,UCSRC			;do temp1	;ENG;to temp1
		sei
		nop					;aby sa mohlo vykonat prerusenie pred ret istrukciou (ret trva dlho)	;ENG;for to enable possible interrupt waiting before ret instruction (ret has long duration)
 		ret
 Settemp1toUCSRC:
		sbr	temp1,(1<<URSEL)		;bude sa zapisovat do UCSRC	;ENG;will be writing to UCSRC
		out	UCSRC,temp1			;a zapis spat do registra s novymi UCSZ0 a UCSZ1	;ENG;and write back to register with new UCSZ0 and UCSZ1
		ret
;------------------------------------------------------------------------------------------
DoGetRS232DataBits:
		rcall	GetUCSRCtotemp1
		clr	temp0				;znuluj odpoved	;ENG;clear answer
		bst	temp1,UCSZ0			;zisti UCSZ0	;ENG;obtain UCSZ0
		bld	temp0,0				;a uloz do bitu 0	;ENG;and save to bit 0
		bst	temp1,UCSZ1			;zisti UCSZ1	;ENG;obtain UCSZ1
		bld	temp0,1				;a uloz do bitu 1	;ENG;and save to bit 1
		mov	R0,temp0			;vrat pocet databitov v R0	;ENG;return number of databits in R0
		rjmp	DoGetIn				;a ukonci 	;ENG;and finish
;------------------------------------------------------------------------------------------
DoSetRS232Parity:
		lds	temp0,InputBufferBegin+4	;prvy parameter - parity: 0=none, 1=odd, 2=even, 3=mark, 4=space	;ENG;first parameter - parity: 0=none, 1=odd, 2=even, 3=mark, 4=space
		cpi	temp0,3
		brcc	StableParity
		rcall	GetUCSRCtotemp1
		cbr	temp1,(1<<UPM1)|(1<<UPM0)	;znuluj paritne bity	;ENG;clear parity bits
		cpi	temp0,ParityNone		;ci ma byt none	;ENG;if none
		breq	SetParityOut
		sbr	temp1,(1<<UPM1)
		cpi	temp0,ParityEven		;ci ma byt even	;ENG;if even
		breq	SetParityOut
		sbr	temp1,(1<<UPM0)
		cpi	temp0,ParityOdd			;ci ma byt odd	;ENG;if odd
		brne	ParityErrorAnswer
 SetParityOut:
		rcall	Settemp1toUCSRC
		in	temp1,UCSRB			;nacitaj UCSRB	;ENG;load UCSRB
		cbr	temp1,(1<<UCSZ2)		;ak je 9-bitova komunikacia tak ju zmen na menej ako 9 bitovu	;ENG;if is 9-bits communication then change it under 9 bits
		out	UCSRB,temp1			;a zapis spat	;ENG;and write back
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
 StableParity:
		in	temp1,UCSRB			;zmen vysielany paritny bit TXB8	;ENG;change transmiting parity bit TXB8
		bst	temp0,0				;nacitaj najnizsi bit	;ENG;load lowest bit
		bld	temp1,TXB8			;a uloz ho na miesto TXB8	;ENG;and save to its place TXB8
		sbr	temp1,(1<<UCSZ2)		;nastav UCSZ2 bit - 9 bitova komunikacia	;ENG;set the UCSZ2 bit - 9 bits communication
		out	UCSRB,temp1			;upravene TXB8 a UCSZ2 zapisat do UCSRB	;ENG;changed TXB8 and UCSZ2 write to UCSRB

		ldi	temp0,3				;nastav 9-databit	;ENG;set the 9-databit
		rcall	RS232DataBitsLocal		;a sucasne vrat v temp1 obsah UCSRC	;ENG;and return in temp1 contents UCSRC
		cbr	temp1,(1<<UPM1)|(1<<UPM0)	;zakaz paritu	;ENG;disable parity
		rcall	Settemp1toUCSRC
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
 ParityErrorAnswer:
		rjmp	TwoZeroAnswer			;potvrd prijem dvoma nulami	;ENG;acknowledge reception with two zero
;------------------------------------------------------------------------------------------
DoGetRS232Parity:
		in	temp1,UCSRB			;nacitaj UCSRB	;ENG;load UCSRB
		sbrc	temp1,UCSZ2			;ak je 9-bitova komunikacia	;ENG;if is 9-bits communication
		rjmp	ParityIsStable			;tak je parita space alebo mark	;ENG;then parity is space or mark

		rcall	GetUCSRCtotemp1
		cbr	temp1,~((1<<UPM0)|(1<<UPM1))	;a nechaj nenulove iba paritne bity	;ENG;and let nonzero only parity bits

		cpi	temp1,(1<<UPM0)|(1<<UPM1)	;ak su obidva nastavene	;ENG;if are both set
		ldi	temp0,ParityOdd			;je to odd parita	;ENG;this is odd parity
		breq	RetGetParity			;a skonci	;ENG;and finish
		cpi	temp1,(1<<UPM1)			;ak je nastaveny UPM1	;ENG;if is UPM1 set
		ldi	temp0,ParityEven		;je to even parita	;ENG;this is even parity
		breq	RetGetParity			;a skonci	;ENG;and finish
		ldi	temp0,ParityNone		;inak je to none parita	;ENG;otherwise is that none parity
		rjmp	RetGetParity			;a skonci	;ENG;and finish
 ParityIsStable:
		bst	temp1,TXB8			;zisti ake je 9.-ty bit	;ENG;obtain what is 9-th bit
		ldi	temp0,ParityMark		;priprav si mark odpoved	;ENG;prepare mark answer
		brts	RetGetParity			;ak je 1 potom vrat mark	;ENG;if is 1 then return mark
		ldi	temp0,ParitySpace		;inak vrat space	;ENG;otherwise return space
 RetGetParity:
 		mov	R0,temp0			;odpoved daj z temp0 do R0	;ENG;answer move from temp0 to R0
		rjmp	DoGetIn				;a ukonci 	;ENG;and finish
;------------------------------------------------------------------------------------------
DoSetRS232StopBits:
		lds	temp0,InputBufferBegin+4	;prvy parameter - stop bits 0=1stopbit 1=2stopbits	;ENG;first parameter - stop bit 0=1stopbit 1=2stopbits
		rcall	GetUCSRCtotemp1
		bst	temp0,0				;a najnizsi bit z parametra	;ENG;and lowest bit from parameter
		bld	temp1,USBS			;uloz ako stopbit	;ENG;save as stopbit
		rcall	Settemp1toUCSRC
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou	;ENG;acknowledge reception with single zero
;------------------------------------------------------------------------------------------
DoGetRS232StopBits:
		rcall	GetUCSRCtotemp1
		clr	R0				;znuluj odpoved	;ENG;clear answer
		bst	temp1,USBS			;a bit USBS	;ENG;and bit USBS
		bld	R0,0				;zapis do odpovede	;ENG;write to answer
		rjmp	DoGetIn				;a ukonci 	;ENG;and finish
;------------------------------------------------------------------------------------------
;----------------------------- END USER FUNCTIONS ------------------------------------- END USER FUNCTIONS ------------------------------

OneZeroAnswer:		;posle jednu nulu	;ENG;send single zero
		ldi	temp0,1				;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
		rjmp	ComposeGET_STATUS2
;----------------------------- STANDARD USB REQUESTS ---------------------------------- STANDARD USB REQUESTS ------------------------------
StandardRequest:
		cpi	temp1,GET_STATUS		;
		breq	ComposeGET_STATUS		;

		cpi	temp1,CLEAR_FEATURE		;
		breq	ComposeCLEAR_FEATURE		;

		cpi	temp1,SET_FEATURE		;
		breq	ComposeSET_FEATURE		;

		cpi	temp1,SET_ADDRESS		;ak sa ma nastavit adresa	;ENG;if to set address
		breq	ComposeSET_ADDRESS		;nastav adresu	;ENG;set the address

		cpi	temp1,GET_DESCRIPTOR		;ak sa ziada descriptor	;ENG;if requested descriptor
		breq	ComposeGET_DESCRIPTOR		;vygeneruj ho	;ENG;generate it

		cpi	temp1,SET_DESCRIPTOR		;
		breq	ComposeSET_DESCRIPTOR		;

		cpi	temp1,GET_CONFIGURATION		;
		breq	ComposeGET_CONFIGURATION	;

		cpi	temp1,SET_CONFIGURATION		;
		breq	ComposeSET_CONFIGURATION	;

		cpi	temp1,GET_INTERFACE		;
		breq	ComposeGET_INTERFACE		;

		cpi	temp1,SET_INTERFACE		;
		breq	ComposeSET_INTERFACE		;

		cpi	temp1,SYNCH_FRAME		;
		breq	ComposeSYNCH_FRAME		;
							;ak sa nenasla znama poziadavka	;ENG;if not found known request
		rjmp	ZeroDATA1Answer			;ak to bolo nieco nezname, tak priprav nulovu odpoved	;ENG;if that was something unknown, then prepare zero answer

ComposeSET_ADDRESS:
		lds	temp1,InputBufferBegin+4	;nova adresa do temp1;	;ENG;new address to temp1
		rcall	SetMyNewUSBAddresses		;a pocitaj kodovanu (NRZI a bitstuffing) adresu	;ENG;and compute NRZI and bitstuffing coded adresses
		ldi	State,AddressChangeState	;nastav stav zmeny adresy	;ENG;set state for Address changing
		rjmp	ZeroDATA1Answer			;posli nulovu odpoved	;ENG;send zero answer

ComposeSET_CONFIGURATION:
		lds	temp0,InputBufferBegin+4	;cislo konfiguracie do premennej ConfigByte	;ENG;number of configuration to variable ConfigByte
		sts	ConfigByte,temp0		;
ComposeCLEAR_FEATURE:
ComposeSET_FEATURE:
ComposeSET_INTERFACE:
ZeroStringAnswer:
		rjmp	ZeroDATA1Answer			;posli nulovu odpoved	;ENG;send zero answer
ComposeGET_STATUS:
TwoZeroAnswer:
		ldi	temp0,2				;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
ComposeGET_STATUS2:
		ldi	ZH, high(StatusAnswer<<1)	;ROMpointer na odpoved	;ENG;ROMpointer to  answer
		ldi	ZL,  low(StatusAnswer<<1)
		rjmp	ComposeEndXXXDescriptor		;a dokonci	;ENG;and complete
ComposeGET_CONFIGURATION:
		lds	temp0,ConfigByte
		and	temp0,temp0			;ak som nenakonfigurovany	;ENG;if I am unconfigured
		breq	OneZeroAnswer			;tak posli jednu nulu - inak posli moju konfiguraciu	;ENG;then send single zero - otherwise send my configuration
		ldi	temp0,1				;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
		ldi	ZH, high(ConfigAnswerMinus1<<1)	;ROMpointer na odpoved	;ENG;ROMpointer to  answer
		ldi	ZL,  low(ConfigAnswerMinus1<<1)+1
		rjmp	ComposeEndXXXDescriptor		;a dokonci	;ENG;and complete
ComposeGET_INTERFACE:
		ldi	ZH, high(InterfaceAnswer<<1)	;ROMpointer na odpoved	;ENG;ROMpointer to answer
		ldi	ZL,  low(InterfaceAnswer<<1)
		ldi	temp0,1				;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci	;ENG;and complete
ComposeSYNCH_FRAME:
ComposeSET_DESCRIPTOR:
		rcall	ComposeSTALL
		ret
ComposeGET_DESCRIPTOR:
		lds	temp1,InputBufferBegin+5	;DescriptorType do temp1	;ENG;DescriptorType to temp1
		cpi	temp1,DEVICE			;DeviceDescriptor	;ENG;DeviceDescriptor
		breq	ComposeDeviceDescriptor		;
		cpi	temp1,CONFIGURATION		;ConfigurationDescriptor	;ENG;ConfigurationDescriptor
		breq	ComposeConfigDescriptor		;
		cpi	temp1,STRING			;StringDeviceDescriptor	;ENG;StringDeviceDescriptor
		breq	ComposeStringDescriptor		;
		ret
ComposeDeviceDescriptor:
		ldi	ZH, high(DeviceDescriptor<<1)	;ROMpointer na descriptor	;ENG;ROMpointer to descriptor
		ldi	ZL,  low(DeviceDescriptor<<1)
		ldi	temp0,0x12			;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci	;ENG;and complete
ComposeConfigDescriptor:
		ldi	ZH, high(ConfigDescriptor<<1)	;ROMpointer na descriptor	;ENG;ROMpointer to descriptor
		ldi	ZL,  low(ConfigDescriptor<<1)
		ldi	temp0,9+9+7			;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
ComposeEndXXXDescriptor:
		lds	TotalBytesToSend,InputBufferBegin+8	;pocet pozadovanych bytov do TotalBytesToSend	;ENG;number of requested bytes to TotalBytesToSend
		cp	TotalBytesToSend,temp0			;ak sa neziada viac ako mozem dodat	;ENG;if not requested more than I can send
		brcs	HostConfigLength		;vysli tolko kolko sa ziada	;ENG;transmit the requested number
		mov	TotalBytesToSend,temp0		;inak posli pocet mojich odpovedi	;ENG;otherwise send number of my answers
HostConfigLength:
		mov	temp0,TotalBytesToSend		;
		clr	TransmitPart			;nuluj pocet 8 bytovych odpovedi	;ENG;zero the number of 8 bytes answers
		andi	temp0,0b00000111		;ak je dlzka delitelna 8-mimi	;ENG;if is length divisible by 8
		breq	Length8Multiply			;tak nezapocitaj jednu necelu odpoved (pod 8 bytov)	;ENG;then not count one answer (under 8 byte)
		inc	TransmitPart			;inak ju zapocitaj	;ENG;otherwise count it
Length8Multiply:
		mov	temp0,TotalBytesToSend		;
		lsr	temp0				;dlzka 8 bytovych odpovedi sa dosiahne	;ENG;length of 8 bytes answers will reach
		lsr	temp0				;delenie celociselne 8-mimi	;ENG;integer division by 8
		lsr	temp0
		add	TransmitPart,temp0		;a pripocitanim k poslednej necelej 8-mici do premennej TransmitPart	;ENG;and by addition to last non entire 8-bytes to variable TransmitPart
		ldi	temp0,DATA0PID			;DATA0 PID - v skutocnosti sa stoggluje na DATA1PID v nahrati deskriptora	;ENG;DATA0 PID - in the next will be toggled to DATA1PID in load descriptor
		sts	OutputBufferBegin+1,temp0	;nahraj do vyst buffera	;ENG;store to output buffer
		rjmp	ComposeNextAnswerPart
ComposeStringDescriptor:
		ldi	temp1,4+8			;ak RAMread=4(vkladaj nuly z ROM-koveho citania) + 8(za prvy byte nevkldadaj nulu)	;ENG;if RAMread=4(insert zeros from ROM reading) + 8(behind first byte no load zero)
		mov	RAMread,temp1
		lds	temp1,InputBufferBegin+4	;DescriptorIndex do temp1	;ENG;DescriptorIndex to temp1
		cpi	temp1,0				;LANGID String	;ENG;LANGID String
		breq	ComposeLangIDString		;
		cpi	temp1,2				;DevNameString	;ENG;DevNameString
		breq	ComposeDevNameString		;
		brcc	ZeroStringAnswer		;ak je DescriptorIndex vyssi nez 2 - posli nulovu odpoved	;ENG;if is DescriptorIndex higher than 2 - send zero answer
							;inak to bude VendorString	;ENG;otherwise is VendorString
ComposeVendorString:
		ldi	ZH, high(VendorStringDescriptor<<1)	;ROMpointer na descriptor	;ENG;ROMpointer to descriptor
		ldi	ZL,  low(VendorStringDescriptor<<1)
		ldi	temp0,(VendorStringDescriptorEnd-VendorStringDescriptor)*4-2	;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci	;ENG;and complete
ComposeDevNameString:
		ldi	ZH, high(DevNameStringDescriptor<<1)	;ROMpointer na descriptor	;ENG;ROMpointer to descriptor
		ldi	ZL,  low(DevNameStringDescriptor<<1)
		ldi	temp0,(DevNameStringDescriptorEnd-DevNameStringDescriptor)*4-2	;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci	;ENG;and complete
ComposeLangIDString:
		clr	RAMread
		ldi	ZH, high(LangIDStringDescriptor<<1)	;ROMpointer na descriptor	;ENG;ROMpointer to descriptor
		ldi	ZL,  low(LangIDStringDescriptor<<1)
		ldi	temp0,(LangIDStringDescriptorEnd-LangIDStringDescriptor)*2;pocet mojich bytovych odpovedi do temp0	;ENG;number of my bytes answers to temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci	;ENG;and complete
;------------------------------------------------------------------------------------------
ZeroDATA1Answer:
		rcall	ComposeZeroDATA1PIDAnswer
		ret
;------------------------------------------------------------------------------------------
SetMyNewUSBAddresses:		;nastavi nove USB adresy v NRZI kodovani	;ENG;set new USB addresses in NRZI coded
		mov	temp2,temp1		;address to temp2 and temp1 and temp3
 		mov	temp3,temp1		;
		cpi	temp1,0b01111111	;ENG;if address contains less than 6 ones
		brne	NewAddressNo6ones	;ENG;then don't add bitstuffing
		ldi	temp1,0b10111111	;ENG;else insert one zero - bitstuffing
 NewAddressNo6ones:
		andi	temp3,0b00000111	;ENG;mask 3 low bits of Address
		cpi	temp3,0b00000111	;ENG;and if 3 low bits of Address is no all ones
		brne	NewAddressNo3ones	;ENG;then no change address
						;ENG;else insert zero after 3-rd bit (bitstuffing)
		sec				;set carry
		rol	temp2			;ENG;rotate left
		andi	temp2,0b11110111	;ENG;and inserted zero after 3-rd bit
 NewAddressNo3ones:
		sts	MyOutAddressSRAM,temp2	;ENG;store new non-coded address Out (temp2)
						;ENG;and now perform NRZI coding
		rcall	NRZIforAddress		;ENG;NRZI for AddressIn (in temp1)
		sts	MyInAddressSRAM,ACC	;ENG;store NRZI coded AddressIn

		lds	temp1,MyOutAddressSRAM	;ENG;load non-coded address Out (in temp1)
		rcall	NRZIforAddress		;ENG;NRZI for AddressOut
		sts	MyOutAddressSRAM,ACC	;ENG;store NRZI coded AddressOut

		ret				;ENG;and return
;------------------------------------------------------------------------------------------
NRZIforAddress:
		clr	ACC			;vychodzi stav odpovede - mojej nNRZI USB adresy	;ENG;original answer state - of my nNRZI USB address
		ldi	temp2,0b00000001	;maska na xorovanie	;ENG;mask for xoring
		ldi	temp3,8			;pocitadlo bitov	;ENG;bits counter
SetMyNewUSBAddressesLoop:
		mov	temp0,ACC		;zapamatat si koncovu odpoved	;ENG;remember final answer
		ror	temp1			;do carry vysielany bit LSB (v smere naskor LSB a potom MSB)	;ENG;to carry transmitting bit LSB (in direction firstly LSB then MSB)
		brcs	NoXORBits		;ak je jedna - nemen stav	;ENG;if one - don't change state
		eor	temp0,temp2		;inak sa bude stav menit podla posledneho bitu odpovede	;ENG;otherwise state will be changed according to last bit of answer
NoXORBits:
		ror	temp0			;posledny bit zmenenej odpovede do carry	;ENG;last bit of changed answer to carry
		rol	ACC			;a z carry do koncovej odpovede na miesto LSB (a sucasne prehodenie LSB a MSB poradia)	;ENG;and from carry to final answer to the LSB place (and reverse LSB and MSB order)
		dec	temp3			;zmensi pocitadlo bitov	;ENG;decrement bits counter
		brne	SetMyNewUSBAddressesLoop	;ak pocitadlo bitov nie je nulove opakuj vysielanie s dalsim bitom	;ENG;if bits counter isn't zero repeat transmitting with next bit
		ret
;------------------------------------------------------------------------------------------
;-------------------------- END DATA ENCRYPTION USB REQUESTS ------------------------------

PrepareOutContinuousBuffer:
		rcall	PrepareContinuousBuffer
		rcall	MakeOutBitStuff
		ret
;------------------------------------------------------------------------------------------
PrepareContinuousBuffer:
		mov	temp0,TransmitPart
		cpi	temp0,1
		brne	NextAnswerInBuffer		;ak uz je buffer prazdny	;ENG;if buffer empty
		rcall	ComposeZeroAnswer		;priprav nulovu odpoved	;ENG;prepare zero answer
		ret
NextAnswerInBuffer:
		dec	TransmitPart			;znizit celkovu dlzku odpovede	;ENG;decrement general length of answer
ComposeNextAnswerPart:
		mov	temp1,TotalBytesToSend	;zniz pocet bytov na vyslanie 	;ENG;decrement number of bytes to transmit
		subi	temp1,8			;ci je este treba poslat viac ako 8 bytov	;ENG;is is necessary to send more as 8 byte
		ldi	temp3,8			;ak ano - posli iba 8 bytov	;ENG;if yes - send only 8 byte
		brcc	Nad8Bytov
		mov	temp3,TotalBytesToSend	;inak posli iba dany pocet bytov	;ENG;otherwise send only given number of bytes
		clr	TransmitPart
		inc	TransmitPart		;a bude to posledna odpoved	;ENG;and this will be last answer
Nad8Bytov:
		mov	TotalBytesToSend,temp1	;znizeny pocet bytov do TotalBytesToSend	;ENG;decremented number of bytes to TotalBytesToSend
		rcall	LoadXXXDescriptor
		ldi	ByteCount,2		;dlzka vystupneho buffera (iba SOP a PID)	;ENG;length of output buffer (only SOP and PID)
		add	ByteCount,temp3		;+ pocet bytov	;ENG;+ number of bytes
		rcall	AddCRCOut		;pridanie CRC do buffera	;ENG;addition of CRC to buffer
		inc	ByteCount		;dlzka vystupneho buffera + CRC16	;ENG;length of output buffer + CRC16
		inc	ByteCount
		ret				;skonci	;ENG;finish
;------------------------------------------------------------------------------------------
.equ	USBversion		=0x0101		;pre aku verziu USB je to (1.01)	;ENG;for what version USB is that (1.01)
.equ	VendorUSBID		=0x03EB		;identifikator dodavatela (Atmel=0x03EB)	;ENG; vendor identifier (Atmel=0x03EB)
.equ	DeviceUSBID		=0x21FF		;identifikator vyrobku (USB to RS232 converter ATmega8=0x21FF)	;ENG;product identifier (USB to RS232 converter ATmega8=0x21FF)
.equ	DeviceVersion		=0x0003		;cislo verzie vyrobku (verzia=0.03)	;ENG;version number of product (version=0.03)
						;(0.01=AT90S2313 Infra buffer)	;ENG;(0.01=AT90S2313 Infra buffer)
						;(0.02=AT90S2313 RS232 buffer 32bytes)	;ENG;(0.02=AT90S2313 RS232 buffer 32bytes)
						;(0.03=ATmega8 RS232 buffer 800bytes)	;ENG;(0.03=ATmega8 RS232 buffer 800bytes)
.equ	MaxUSBCurrent		=50		;prudovy odber z USB (50mA) - rezerva na MAX232	;ENG;current consumption from USB (50mA) - together with MAX232
;------------------------------------------------------------------------------------------
DeviceDescriptor:
		.db	0x12,0x01		;0 byte - velkost deskriptora v bytoch	;ENG;0 byte - size of descriptor in byte
						;1 byte - typ deskriptora: Deskriptor zariadenia	;ENG;1 byte - descriptor type: Device descriptor
		.dw	USBversion		;2,3 byte - verzia USB LSB (1.00)	;ENG;2,3 byte - version USB LSB (1.00)
		.db	0x00,0x00		;4 byte - trieda zariadenia	;ENG;4 byte - device class
						;5 byte - podtrieda zariadenia	;ENG;5 byte - subclass
		.db	0x00,0x08		;6 byte - kod protokolu	;ENG;6 byte - protocol code
						;7 byte - velkost FIFO v bytoch	;ENG;7 byte - FIFO size in bytes
		.dw	VendorUSBID		;8,9 byte - identifikator dodavatela (Cypress=0x04B4)	;ENG;8,9 byte - vendor identifier (Cypress=0x04B4)
		.dw	DeviceUSBID		;10,11 byte - identifikator vyrobku (teplomer=0x0002)	;ENG;10,11 byte - product identifier (teplomer=0x0002)
		.dw	DeviceVersion		;12,13 byte - cislo verzie vyrobku (verzia=0.01)	;ENG;12,13 byte - product version number (verzia=0.01)
		.db	0x01,0x02		;14 byte - index stringu "vyrobca"	;ENG;14 byte - index of string "vendor"
						;15 byte - index stringu "vyrobok"	;ENG;15 byte - index of string "product"
		.db	0x00,0x01		;16 byte - index stringu "seriove cislo"	;ENG;16 byte - index of string "serial number"
						;17 byte - pocet moznych konfiguracii	;ENG;17 byte - number of possible configurations
DeviceDescriptorEnd:
;------------------------------------------------------------------------------------------
ConfigDescriptor:
		.db	0x9,0x02		;dlzka,typ deskriptoru	;ENG;length, descriptor type
ConfigDescriptorLength:
		.dw	9+9+7			;celkova dlzka vsetkych deskriptorov	;ENG;entire length of all descriptors
	ConfigAnswerMinus1:			;pre poslanie cisla congiguration number (pozor je  treba este pricitat 1)	;ENG;for sending the number - congiguration number (attention - addition of 1 required)
		.db	1,1			;numInterfaces,congiguration number	;ENG;numInterfaces, congiguration number
		.db	0,0x80			;popisny index stringu, atributy;bus powered	;ENG;string index, attributes; bus powered
		.db	MaxUSBCurrent/2,0x09	;prudovy odber, interface descriptor length	;ENG;current consumption, interface descriptor length
		.db	0x04,0			;interface descriptor; cislo interface	;ENG;interface descriptor; number of interface
	InterfaceAnswer:			;pre poslanie cisla alternativneho interface	;ENG;for sending number of alternatively interface
		.db	0,1			;alternativne nastavenie interface; pocet koncovych bodov okrem EP0	;ENG;alternatively interface; number of endpoints except EP0
	StatusAnswer:				;2 nulove odpovede (na usetrenie miestom)	;ENG;2 zero answers (saving ROM place)
		.db	0,0			;trieda rozhrania; podtrieda rozhrania	;ENG;interface class; interface subclass
		.db	0,0			;kod protokolu; index popisneho stringu	;ENG;protocol code; string index
		.db	0x07,0x5		;dlzka,typ deskriptoru - endpoint	;ENG;length, descriptor type - endpoint
		.db	0x81,0			;endpoint address; transfer type	;ENG;endpoint address; transfer type
		.dw	0x08			;max packet size	;ENG;max packet size
		.db	10,0			;polling interval [ms]; dummy byte (pre vyplnenie)	;ENG;polling interval [ms]; dummy byte (for filling)
ConfigDescriptorEnd:
;------------------------------------------------------------------------------------------
LangIDStringDescriptor:
		.db	(LangIDStringDescriptorEnd-LangIDStringDescriptor)*2,3	;dlzka, typ: string deskriptor	;ENG;length, type: string descriptor
		.dw	0x0409			;English	;ENG;English
LangIDStringDescriptorEnd:
;------------------------------------------------------------------------------------------
VendorStringDescriptor:
		.db	(VendorStringDescriptorEnd-VendorStringDescriptor)*4-2,3	;dlzka, typ: string deskriptor	;ENG;length, type: string descriptor
CopyRight:
		.db	"Ing. Igor Cesko http://www.cesko.host.sk"
CopyRightEnd:
VendorStringDescriptorEnd:
;------------------------------------------------------------------------------------------
DevNameStringDescriptor:
		.db	(DevNameStringDescriptorEnd-DevNameStringDescriptor)*4-2,3;dlzka, typ: string deskriptor	;ENG;length, type: string descriptor
		.db	"AVR309: USB to UART protocol converter"
DevNameStringDescriptorEnd:
;------------------------------------------------------------------------------------------
;********************************************************************
;* End of Program	;ENG;* End of program
;********************************************************************
;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
;********************************************************************
;* End of file	;ENG;* End of file
;********************************************************************
