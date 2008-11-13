;***************************************************************************
;* U S B   S T A C K   F O R   T H E   A V R   F A M I L Y
;*
;* File Name            :"USB90S2313.asm"
;* Title                :AVR309:USB to UART protocol converter (simple - small FIFO)
;* Date                 :26.01.2004
;* Version              :2.2
;* Target MCU           :AT90S2313-10
;* AUTHOR		:Ing. Igor Cesko
;* 			 Slovakia
;* 			 cesko@internet.sk
;* 			 http://www.cesko.host.sk
;*
;* DESCRIPTION:
;*  USB protocol implementation into MCU with noUSB interface:
;*  Device:
;*  Universal USB interface (8-bit I/O port + RS232 serial line + EEPROM)
;*  + added RS232 FIFO buffer
;*
;* The timing is adapted for 12 MHz crystal (overclocked MCU !!!)
;*
;*
;* to add your own functions - see section: TEMPLATE OF YOUR FUNCTION
;*
;* to customize device to your company you must change VendorUSB ID (VID)
;* to VID assigned to your company (for more information see www.usb.org)
;*
;***************************************************************************
.include "2313def.inc"

.equ	inputport		=PINB
.equ	outputport		=PORTB
.equ	USBdirection		=DDRB
.equ	DATAplus		=1		;signal D+ na PB1
.equ	DATAminus		=0		;signal D- na PB0 - treba dat na tento pin pull-up 1.5kOhm
.equ	USBpinmask		=0b11111100	;mask low 2 bits (D+,D-) on PB
.equ	USBpinmaskDplus		=~(1<<DATAplus)	;mask D+ bit on PB
.equ	USBpinmaskDminus	=~(1<<DATAminus);mask D- bit on PB

.equ	TSOPPort		=PINB
.equ	TSOPpullupPort		=PORTB
.equ	TSOPPin			=2		;signal OUT z IR senzora TSOP1738 na PB2

.equ	LEDPortLSB		=PORTD		;pripojenie LED diod LSB
.equ	LEDPinLSB		=PIND		;pripojenie LED diod LSB (vstup)
.equ	LEDdirectionLSB		=DDRD		;vstup/vystup LED LSB
.equ	LEDPortMSB		=PORTB		;pripojenie LED diod MSB
.equ	LEDPinMSB		=PINB		;pripojenie LED diod MSB  (vstup)
.equ	LEDdirectionMSB		=DDRB		;vstup/vystup LED MSB
.equ	LEDlsb0			=3		;LED0 na pin PD3
.equ	LEDlsb1			=5		;LED1 na pin PD5
.equ	LEDlsb2			=6		;LED2 na pin PD6
.equ	LEDmsb3			=3		;LED3 na pin PB3
.equ	LEDmsb4			=4		;LED4 na pin PB4
.equ	LEDmsb5			=5		;LED5 na pin PB5
.equ	LEDmsb6			=6		;LED6 na pin PB6
.equ	LEDmsb7			=7		;LED7 na pin PB7

.equ	SOPbyte			=0b10000000	;Start of Packet byte
.equ	DATA0PID		=0b11000011	;PID pre DATA0 pole
.equ	DATA1PID		=0b01001011	;PID pre DATA1 pole
.equ	OUTPID			=0b11100001	;PID pre OUT pole
.equ	INPID			=0b01101001	;PID pre IN pole
.equ	SOFPID			=0b10100101	;PID pre SOF pole
.equ	SETUPPID		=0b00101101	;PID pre SETUP pole
.equ	ACKPID			=0b11010010	;PID pre ACK pole
.equ	NAKPID			=0b01011010	;PID pre NAK pole
.equ	STALLPID		=0b00011110	;PID pre STALL pole
.equ	PREPID			=0b00111100	;PID pre PRE pole

.equ	nSOPbyte		=0b00000001	;Start of Packet byte - opacne poradie
.equ	nDATA0PID		=0b11000011	;PID pre DATA0 pole - opacne poradie
.equ	nDATA1PID		=0b11010010	;PID pre DATA1 pole - opacne poradie
.equ	nOUTPID			=0b10000111	;PID pre OUT pole - opacne poradie
.equ	nINPID			=0b10010110	;PID pre IN pole - opacne poradie
.equ	nSOFPID			=0b10100101	;PID pre SOF pole - opacne poradie
.equ	nSETUPPID		=0b10110100	;PID pre SETUP pole - opacne poradie
.equ	nACKPID			=0b01001011	;PID pre ACK pole - opacne poradie
.equ	nNAKPID			=0b01011010	;PID pre NAK pole - opacne poradie
.equ	nSTALLPID		=0b01111000	;PID pre STALL pole - opacne poradie
.equ	nPREPID			=0b00111100	;PID pre PRE pole - opacne poradie

.equ	nNRZITokenPID		=~0b10000000	;PID maska pre Token paket (IN,OUT,SOF,SETUP) - opacne poradie NRZI
.equ	nNRZISOPbyte		=~0b10101011	;Start of Packet byte - opacne poradie NRZI
.equ	nNRZIDATA0PID		=~0b11010111	;PID pre DATA0 pole - opacne poradie NRZI
.equ	nNRZIDATA1PID		=~0b11001001	;PID pre DATA1 pole - opacne poradie NRZI
.equ	nNRZIOUTPID		=~0b10101111	;PID pre OUT pole - opacne poradie NRZI
.equ	nNRZIINPID		=~0b10110001	;PID pre IN pole - opacne poradie NRZI
.equ	nNRZISOFPID		=~0b10010011	;PID pre SOF pole - opacne poradie NRZI
.equ	nNRZISETUPPID		=~0b10001101	;PID pre SETUP pole - opacne poradie NRZI
.equ	nNRZIACKPID		=~0b00100111	;PID pre ACK pole - opacne poradie NRZI
.equ	nNRZINAKPID		=~0b00111001	;PID pre NAK pole - opacne poradie NRZI
.equ	nNRZISTALLPID		=~0b00000111	;PID pre STALL pole - opacne poradie NRZI
.equ	nNRZIPREPID		=~0b01111101	;PID pre PRE pole - opacne poradie NRZI
.equ	nNRZIADDR0		=~0b01010101	;Adresa = 0 - opacne poradie NRZI

						;stavove byty - State
.equ	BaseState		=0		;
.equ	SetupState		=1		;
.equ	InState			=2		;
.equ	OutState		=3		;
.equ	SOFState		=4		;
.equ	DataState		=5		;
.equ	AddressChangeState	=6		;

						;Flagy pozadovanej akcie
.equ	DoNone					=0
.equ	DoReceiveOutData			=1
.equ	DoReceiveSetupData			=2
.equ	DoPrepareOutContinuousBuffer		=3
.equ	DoReadySendAnswer			=4


.equ	CRC5poly		=0b00101		;CRC5 polynom
.equ	CRC5zvysok		=0b01100		;CRC5 zvysok po uspesnpm CRC5
.equ	CRC16poly		=0b1000000000000101	;CRC16 polynom
.equ	CRC16zvysok		=0b1000000000001101	;CRC16 zvysok po uspesnom CRC16

.equ	MAXUSBBYTES		=14			;maximum bytes in USB input message
.equ	MAXRS232LENGTH		=36			;maximalna dlzka RS232 kodu (pocet jednotiek a nul spolu) (pozor: MAXRS232LENGTH musi byt parne cislo !!!)
.equ	NumberOfFirstBits	=10			;kolko prvych bitov moze byt dlhsich
.equ	NoFirstBitsTimerOffset	=256-12800*12/1024	;Timeout 12.8ms (12800us) na ukoncenie prijmu po uvodnych bitoch (12Mhz:clock, 1024:timer predivider, 256:timer overflow value)
.equ	InitBaudRate		=12000000/16/57600-1	;nastavit vysielaciu rychlost UART-u na 57600 (pre 12MHz=12000000Hz)

.equ	InputBufferBegin	=RAMEND-127				;zaciatok prijimacieho shift buffera
.equ	InputShiftBufferBegin	=InputBufferBegin+MAXUSBBYTES		;zaciatok prijimacieho buffera
.equ	RS232BufferBegin	=InputShiftBufferBegin+MAXUSBBYTES	;zaciatok buffera pre RS232 prijem

.equ	MyInAddressSRAM		=RS232BufferBegin+MAXRS232LENGTH+1
.equ	MyOutAddressSRAM	=MyInAddressSRAM+1

.equ	OutputBufferBegin	=RAMEND-MAXUSBBYTES-2	;zaciatok vysielacieho buffera
.equ	AckBufferBegin		=OutputBufferBegin-3	;zaciatok vysielacieho buffera Ack
.equ	NakBufferBegin		=AckBufferBegin-3	;zaciatok vysielacieho buffera Nak

.equ	StackBegin		=NakBufferBegin-1	;spodok zasobnika

.def	ConfigByte		=R1		;0=unconfigured state
.def	backupbitcount		=R2		;zaloha bitcount registra v INT0 preruseni
.def	RAMread			=R3		;ci sa ma citat zo SRAM-ky
.def	backupSREGTimer		=R4		;zaloha Flag registra v Timer interrupte
.def	backupSREG		=R5		;zaloha Flag registra v INT0 preruseni
.def	ACC			=R6		;accumulator
.def	lastBitstufNumber	=R7		;pozicia bitstuffingu
.def	OutBitStuffNumber	=R8		;kolko bitov sa ma este odvysielat z posledneho bytu - bitstuffing
.def	BitStuffInOut		=R9		;ci sa ma vkladat alebo mazat bitstuffing
.def	TotalBytesToSend	=R10		;kolko sa ma poslat bytov
.def	TransmitPart		=R11		;poradove cislo vysielacej casti
.def	InputBufferLength	=R12		;dlzka pripravena vo vstupnom USB bufferi
.def	OutputBufferLength	=R13		;dlzka odpovede pripravena v USB bufferi
.def	MyOutAddress		=R14		;moja USB adresa na update
.def	MyInAddress		=R15		;moja USB adresa


.def	ActionFlag		=R16		;co sa ma urobit v hlavnej slucke programu
.def	temp3			=R17		;temporary register
.def	temp2			=R18		;temporary register
.def	temp1			=R19		;temporary register
.def	temp0			=R20		;temporary register
.def	bitcount		=R21		;counter of bits in byte
.def	ByteCount		=R22		;pocitadlo maximalneho poctu prijatych bajtov
.def	inputbuf		=R23		;prijimaci register
.def	shiftbuf		=R24		;posuvny prijimaci register
.def	State			=R25		;byte stavu stavoveho stroja
.def	RS232BufptrX		=R26		;XL register - pointer do buffera prijatych IR kodov
.def	RS232BufferFull		=R27		;XH register - priznak plneho RS232 Buffera
.def	USBBufptrY		=R28		;YL register - pointer do USB buffera input/output
.def	ROMBufptrZ		=R30		;ZL register - pointer do buffera ROM dat

;poziadavky na deskriptory
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

;typy deskriptorov
.equ	DEVICE			=1
.equ	CONFIGURATION		=2
.equ	STRING			=3
.equ	INTERFACE		=4
.equ	ENDPOINT		=5

.equ	USER_FNC_NUMBER		=100


;------------------------------------------------------------------------------------------
;********************************************************************
;* Interrupt table
;********************************************************************
.cseg
;------------------------------------------------------------------------------------------
.org 0						;po resete
		rjmp	reset
;------------------------------------------------------------------------------------------
.org INT0addr					;externe prerusenie INT0
		rjmp	INT0handler
;------------------------------------------------------------------------------------------
.org URXCaddr					;prijem zo seriovej linky
		push	temp0
		in	temp0,UDR			;nacitaj do temp0 prijate data z UART-u
		sei					;povol interrupty na obsluhu USB
		in	backupSREGTimer,SREG		;zaloha SREG
		cbi	UCR,RXCIE			;zakazat interrupt od prijimania UART
		cpi	RS232BufferFull,MAXRS232LENGTH-4
		brcc	NoIncRS232BufferFull
		push	RS232BufptrX
		lds	RS232BufptrX,RS232BufferBegin+2	;nastavenie sa na zaciatok buffera zapisu RS232 kodu : 3.byte hlavicky (dlzka kodu + citanie + zapis + rezerva)
		st	X+,temp0			;a uloz ho do buffera
		cpi	RS232BufptrX,RS232BufferBegin+MAXRS232LENGTH+1	;ak sa nedosiahol maximum RS232 buffera
		brne	NoUARTBufferOverflow		;tak pokracuj
		ldi	RS232BufptrX,RS232BufferBegin+4	;inak sa nastav na zaciatok buffera
 NoUARTBufferOverflow:
		sts	RS232BufferBegin+2,RS232BufptrX	;ulozenie noveho offsetu buffera zapisu RS232 kodu : 3.byte hlavicky (dlzka kodu + citanie + zapis + rezerva)
		inc	RS232BufferFull			;zvys dlzku RS232 Buffera
		pop	RS232BufptrX
 NoIncRS232BufferFull:
		pop	temp0
		out	SREG,backupSREGTimer		;obnova SREG
		cli					;zakazat interrupt kvoli zacykleniu
		sbi	UCR,RXCIE			;povolit interrupt od prijimania UART
		reti
;------------------------------------------------------------------------------------------
;********************************************************************
;* Init program
;********************************************************************
;------------------------------------------------------------------------------------------
reset:			;inicializacia procesora a premennych na spravne hodnoty
		ldi	temp0,StackBegin	;inicializacia stacku
		out	SPL,temp0

		clr	XH			;RS232 pointer
		clr	YH			;USB pointer
		clr	ZH			;ROM pointer
		sts	RS232BufferBegin+0,YH	;znuluj dlzky RS232 kodu v bufferi
		ldi	temp0,RS232BufferBegin+4
		sts	RS232BufferBegin+1,temp0;znuluj ukazovatel citania
		sts	RS232BufferBegin+2,temp0;znuluj ukazovatel zapisu
		clr	RS232BufferFull

		rcall	InitACKBufffer		;inicializacia ACK buffera
		rcall	InitNAKBufffer		;inicializacia NAK buffera

		rcall	USBReset		;inicializacia USB adresy

		sbi	TSOPpullupPort,TSOPpin	;nahodit pull-up na TSOP vstupe

		ldi	temp0,(1<<LEDlsb0)+(1<<LEDlsb1)+(1<<LEDlsb2)
		out	LEDPortLSB,temp0	;nahodit pull-up na vsetkych LED vstupoch LSB
		ldi	temp0,(1<<LEDmsb3)+(1<<LEDmsb4)+(1<<LEDmsb5)+(1<<LEDmsb6)+(1<<LEDmsb7)
		out	LEDPortMSB,temp0	;nahodit pull-up na vsetkych LED vstupoch MSB

		sbi	PORTD,0			;nahodit pull-up na RxD vstupe
		ldi	temp0,InitBaudRate	;nastavitvysielaciu rychlost UART-u
		out	UBRR,temp0
		sbi	UCR,TXEN		;povolit vysielanie UART-u
		sbi	UCR,RXEN		;povolit prijimanie UART-u
		sbi	UCR,RXCIE		;povolit interrupt od prijimania UART

		ldi	temp0,0x0F		;INT0 - reagovanie na nabeznu hranu
		out	MCUCR,temp0		;
		ldi	temp0,1<<INT0		;povolit externy interrupt INT0
		out	GIMSK,temp0
;------------------------------------------------------------------------------------------
;********************************************************************
;* Main program
;********************************************************************
		sei					;povolit interrupty globalne
Main:
		sbis	inputport,DATAminus	;cakanie az sa zmeni D- na 0
		rjmp	CheckUSBReset		;a skontroluj, ci to nie je USB reset

		cpi	ActionFlag,DoReceiveSetupData
		breq	ProcReceiveSetupData
		cpi	ActionFlag,DoPrepareOutContinuousBuffer
		breq	ProcPrepareOutContinuousBuffer
		rjmp	Main

CheckUSBReset:
		ldi	temp0,255		;pocitadlo trvania reset-u (podla normy je to cca 10ms - tu je to cca 100us)
WaitForUSBReset:
		sbic	inputport,DATAminus	;cakanie az sa zmeni D+ na 0
		rjmp	Main
		dec	temp0
		brne	WaitForUSBReset
		rcall	USBReset
		rjmp	Main

ProcPrepareOutContinuousBuffer:
		rcall	PrepareOutContinuousBuffer	;priprav pokracovanie odpovede do buffera
		ldi	ActionFlag,DoReadySendAnswer
		rjmp	Main
ProcReceiveSetupData:
		ldi	USBBufptrY,InputBufferBegin	;pointer na zaciatok prijimacieho buffera
		mov	ByteCount,InputBufferLength	;dlzka vstupneho buffera
		rcall	DecodeNRZI		;prevod kodovania NRZI na bity
		rcall	MirrorInBufferBytes	;prehodit poradie bitov v bajtoch
		rcall	BitStuff		;odstranenie bit stuffing
		;rcall	CheckCRCIn		;kontrola CRC
		rcall	PrepareUSBOutAnswer	;pripravenie odpovede do vysielacieho buffera
		ldi	ActionFlag,DoReadySendAnswer
		rjmp	Main
;********************************************************************
;* Main program END
;********************************************************************
;------------------------------------------------------------------------------------------
;********************************************************************
;* Interrupt0 interrupt handler
;********************************************************************
INT0Handler:					;prerusenie INT0
		in	backupSREG,SREG
		push	temp0
		push	temp1

		ldi	temp0,3			;pocitadlo trvania log0
		ldi	temp1,2			;pocitadlo trvania log1
		;cakanie na zaciatok paketu
CheckchangeMinus:
		sbis	inputport,DATAminus	;cakanie az sa zmeni D- na 1
		rjmp	CheckchangeMinus
CheckchangePlus:
		sbis	inputport,DATAplus	;cakanie az sa zmeni D+ na 1
		rjmp	CheckchangePlus
DetectSOPEnd:
		sbis	inputport,DATAplus
		rjmp	Increment0		;D+ =0
Increment1:
		ldi	temp0,3			;pocitadlo trvania log0
		dec	temp1			;kolko cyklov trvala log1
		nop
		breq	USBBeginPacket		;ak je to koniec SOP - prijimaj paket
		rjmp	DetectSOPEnd
Increment0:
		ldi	temp1,2			;pocitadlo trvania log1
		dec	temp0			;kolko cyklov trvala log0
		nop
		brne	DetectSOPEnd		;ak nenastal SOF - pokracuj
		rjmp	EndInt0HandlerPOP2
EndInt0Handler:
		pop	ACC
		pop	RS232BufptrX
		pop	temp3
		pop	temp2
EndInt0HandlerPOP:
		pop	USBBufptrY
		pop	ByteCount
		mov	bitcount,backupbitcount	;obnova bitcount registra
EndInt0HandlerPOP2:
		pop	temp1
		pop	temp0
		out	SREG,backupSREG
		ldi	shiftbuf,1<<INTF0	;znulovat flag interruptu INTF0
		out	GIFR,shiftbuf
		reti				;inak skonci (bol iba SOF - kazdu milisekundu)

USBBeginPacket:
		mov	backupbitcount,bitcount	;zaloha bitcount registra
		in	shiftbuf,inputport	;ak ano nacitaj ho ako nulty bit priamo do shift registra
USBloopBegin:
		push	ByteCount		;dalsia zaloha registrov (setrenie casu)
		push	USBBufptrY
		ldi	bitcount,6		;inicializacia pocitadla bitov v bajte
		ldi	ByteCount,MAXUSBBYTES	;inicializacia max poctu prijatych bajtov v pakete
		ldi	USBBufptrY,InputShiftBufferBegin	;nastav vstupny buffer
USBloop1_6:
		in	inputbuf,inputport
		cbr	inputbuf,USBpinmask	;odmaskovat spodne 2 bity
		breq	USBloopEnd		;ak su nulove - koniec USB packetu
		ror	inputbuf		;presun Data+ do shift registra
		rol	shiftbuf
		dec	bitcount		;zmensi pocitadlo bitov
		brne	USBloop1_6		;ak nie je nulove - opakuj naplnanie shift registra
		nop				;inak bude nutne skopirovat shift register bo buffera
USBloop7:
		in	inputbuf,inputport
		cbr	inputbuf,USBpinmask	;odmaskovat spodne 2 bity
		breq	USBloopEnd		;ak su nulove - koniec USB packetu
		ror	inputbuf		;presun Data+ do shift registra
		rol	shiftbuf
		ldi	bitcount,7		;inicializacia pocitadla bitov v bajte
		st	Y+,shiftbuf		;skopiruj shift register bo buffera a zvys pointer do buffera
USBloop0:					;a zacni prijimat dalsi bajt
		in	shiftbuf,inputport	;nulty bit priamo do shift registra
		cbr	shiftbuf,USBpinmask	;odmaskovat spodne 2 bity
		breq	USBloopEnd		;ak su nulove - koniec USB packetu
		dec	bitcount		;zmensi pocitadlo bitov
		nop				;
		dec	ByteCount		;ak sa nedosiahol maximum buffera
		brne	USBloop1_6		;tak prijimaj dalej

		rjmp	EndInt0HandlerPOP	;inak opakuj od zaciatku

USBloopEnd:
		cpi	USBBufptrY,InputShiftBufferBegin+3	;ak sa neprijali aspon 3 byte
		brcs	EndInt0HandlerPOP	;tak skonci
		lds	temp0,InputShiftBufferBegin+0	;identifikator paketu do temp0
		lds	temp1,InputShiftBufferBegin+1	;adresa do temp1
		brne	TestDataPacket		;ak je dlzka ina ako 3 - tak to moze byt iba DataPaket
TestIOPacket:
;		cp	temp1,MyInAddress	;ak to nie je urcene (adresa) pre mna
;		brne	TestDataPacket		;tak to moze byt este Data Packet
TestSetupPacket:;test na SETUP paket
		cpi	temp0,nNRZISETUPPID
		brne	TestOutPacket		;ak nie je Setup PID - dekoduj iny paket
		cp	temp1,MyInAddress	;ak to nie je urcene (adresa) pre mna	;ENG;if this isn't assigned (address) for me
		brne	TestDataPacket		;tak to moze byt este Data Packet	;ENG;then this can be still DataPacket
		ldi	State,SetupState
		rjmp	EndInt0HandlerPOP	;ak je Setup PID - prijimaj nasledny Data paket
TestOutPacket:	;test na OUT paket
		cpi	temp0,nNRZIOUTPID
		brne	TestInPacket		;ak nie je Out PID - dekoduj iny paket
		cp	temp1,MyOutAddress	;ak to nie je urcene (adresa) pre mna	;ENG;if this isn't assigned (address) for me
		brne	TestDataPacket		;tak to moze byt este Data Packet	;ENG;then this can be still DataPacket
		ldi	State,OutState
		rjmp	EndInt0HandlerPOP	;ak je Out PID - prijimaj nasledny Data paket
TestInPacket:	;test na IN paket
		cpi	temp0,nNRZIINPID
		brne	TestDataPacket		;ak nie je In PID - dekoduj iny paket
		cp	temp1,MyInAddress	;ak to nie je urcene (adresa) pre mna	;ENG;if this isn't assigned (address) for me
		breq	AnswerToInRequest	;tak to moze byt este Data Packet	;ENG;then this can be still DataPacket
TestDataPacket:	;test na DATA0 a DATA1 paket
		cpi	temp0,nNRZIDATA0PID
		breq	Data0Packet		;ak nie je Data0 PID - dekoduj iny paket
		cpi	temp0,nNRZIDATA1PID
		brne	NoMyPacked		;ak nie je Data1 PID - dekoduj iny paket
Data0Packet:
		cpi	State,SetupState	;ak bol stav Setup
		breq	ReceiveSetupData	;prijmi ho
		cpi	State,OutState		;ak bol stav Out
		breq	ReceiveOutData		;prijmi ho
NoMyPacked:
		ldi	State,BaseState		;znuluj stav
		rjmp	EndInt0HandlerPOP	;a prijimaj nasledny Data paket

AnswerToInRequest:
		push	temp2			;zazalohuj dalsie registre a pokracuj
		push	temp3
		push	RS232BufptrX
		push	ACC
		cpi	ActionFlag,DoReadySendAnswer	;ak nie je pripravena odpoved
		brne	NoReadySend		;tak posli NAK
		rcall	SendPreparedUSBAnswer	;poslanie odpovede naspat
		cpi	State,AddressChangeState;ak je stav AddressChange
		breq	SetMyNewUSBAddress	;tak treba zmenit USB adresu
		ldi	State,InState
		ldi	ActionFlag,DoPrepareOutContinuousBuffer
		rjmp	EndInt0Handler		;a opakuj - cakaj na dalsiu odozvu z USB
ReceiveSetupData:
		push	temp2			;zazalohuj dalsie registre a pokracuj
		push	temp3
		push	RS232BufptrX
		push	ACC
		rcall	SendACK			;akceptovanie Setup Data paketu
		rcall	FinishReceiving		;ukonci prijem
		ldi	ActionFlag,DoReceiveSetupData
		rjmp	EndInt0Handler
ReceiveOutData:
		push	temp2			;zazalohuj dalsie registre a pokracuj
		push	temp3
		push	RS232BufptrX
		push	ACC
		cpi	ActionFlag,DoReceiveSetupData	;ak sa prave spracovava prikaz Setup
		breq	NoReadySend		;tak posli NAK
		rcall	SendACK			;akceptovanie Out paketu
		clr	ActionFlag
		rjmp	EndInt0Handler
NoReadySend:
		rcall	SendNAK			;este nie som pripraveny s odpovedou
		rjmp	EndInt0Handler		;a opakuj - cakaj na dalsiu odozvu z USB
;------------------------------------------------------------------------------------------
SetMyNewUSBAddress:		;nastavi novu USB adresu v NRZI kodovani
		lds	MyInAddress,MyInAddressSRAM
		lds	MyOutAddress,MyOutAddressSRAM
		rjmp	EndInt0Handler
;------------------------------------------------------------------------------------------
FinishReceiving:		;korekcne akcie na ukoncenie prijmu
		cpi	bitcount,7		;prenes do buffera aj posledny necely byte
		breq	NoRemainingBits		;ak boli vsetky byty prenesene, tak neprenasaj nic
		inc	bitcount
ShiftRemainingBits:
		rol	shiftbuf		;posun ostavajuce necele bity na spravnu poziciu
		dec	bitcount
		brne	ShiftRemainingBits
		st	Y+,shiftbuf		;a skopiruj shift register bo buffera - necely byte
NoRemainingBits:
		mov	ByteCount,USBBufptrY
		subi	ByteCount,InputShiftBufferBegin-1	;v ByteCount je pocet prijatych byte (vratane necelych byte)

		mov	InputBufferLength,ByteCount		;a uchovat pre pouzitie v hlavnom programe
		ldi	USBBufptrY,InputShiftBufferBegin	;pointer na zaciatok prijimacieho shift buffera
		ldi	RS232BufptrX,InputBufferBegin+1		;data buffer (vynechat SOP)
MoveDataBuffer:
		ld	temp0,Y+
		st	X+,temp0
		dec	ByteCount
		brne	MoveDataBuffer

		ldi	ByteCount,nNRZISOPbyte
		sts	InputBufferBegin,ByteCount		;ako keby sa prijal SOP - nekopiruje sa zo shift buffera
		ret
;------------------------------------------------------------------------------------------
;********************************************************************
;* Other procedures
;********************************************************************
;------------------------------------------------------------------------------------------
USBReset:		;inicializacia USB stavoveho stroja
		ldi	temp0,nNRZIADDR0	;inicializacia USB adresy
		mov	MyOutAddress,temp0
		mov	MyInAddress,temp0
		clr	State			;inicializacia stavoveho stroja
		clr	BitStuffInOut
		clr	OutBitStuffNumber
		clr	ActionFlag
		clr	RAMread			;bude sa vycitavat z ROM-ky
		clr	ConfigByte		;nenakonfiguravany stav
		ret
;------------------------------------------------------------------------------------------
SendPreparedUSBAnswer:	;poslanie kodovanim NRZI OUT buffer s dlzkou OutputBufferLength do USB
		mov	ByteCount,OutputBufferLength		;dlzka odpovede
SendUSBAnswer:	;poslanie kodovanim NRZI OUT buffer do USB
		ldi	USBBufptrY,OutputBufferBegin		;pointer na zaciatok vysielacieho buffera
SendUSBBuffer:	;poslanie kodovanim NRZI dany buffer do USB
		ldi	temp1,0			;zvysovanie pointra (pomocna premenna)
		mov	temp3,ByteCount		;pocitadlo bytov: temp3 = ByteCount
		ldi	temp2,0b00000011	;maska na xorovanie
		ld	inputbuf,Y+		;nacitanie prveho bytu do inputbuf a zvys pointer do buffera
						;USB ako vystup:
		cbi	outputport,DATAplus	;zhodenie DATAplus : kludovy stav portu USB
		sbi	outputport,DATAminus	;nahodenie DATAminus : kludovy stav portu USB
		sbi	USBdirection,DATAplus	;DATAplus ako vystupny
		sbi	USBdirection,DATAminus	;DATAminus ako vystupny

		in	temp0,outputport	;kludovy stav portu USB do temp0
SendUSBAnswerLoop:
		ldi	bitcount,7		;pocitadlo bitov
SendUSBAnswerByteLoop:
		nop				;oneskorenie kvoli casovaniu
		ror	inputbuf		;do carry vysielany bit (v smere naskor LSB a potom MSB)
		brcs	NoXORSend		;ak je jedna - nemen stav na USB
		eor	temp0,temp2		;inak sa bude stav menit
NoXORSend:
		out	outputport,temp0	;vysli von na USB
		dec	bitcount		;zmensi pocitadlo bitov - podla carry flagu
		brne	SendUSBAnswerByteLoop	;ak pocitadlo bitov nie je nulove - opakuj vysielanie s dalsim bitom
		sbrs	inputbuf,0		;ak je vysielany bit jedna - nemen stav na USB
		eor	temp0,temp2		;inak sa bude stav menit
NoXORSendLSB:
		dec	temp3			;zniz pocitadlo bytov
		ld	inputbuf,Y+		;nacitanie dalsieho bytu a zvys pointer do buffera
		out	outputport,temp0	;vysli von na USB
		brne	SendUSBAnswerLoop	;opakuj pre cely buffer (pokial temp3=0)

		mov	bitcount,OutBitStuffNumber	;pocitadlo bitov pre bitstuff
		cpi	bitcount,0		;ak nie je potrebny bitstuff
		breq	ZeroBitStuf
SendUSBAnswerBitstuffLoop:
		ror	inputbuf		;do carry vysielany bit (v smere naskor LSB a potom MSB)
		brcs	NoXORBitstuffSend	;ak je jedna - nemen stav na USB
		eor	temp0,temp2		;inak sa bude stav menit
NoXORBitstuffSend:
		out	outputport,temp0	;vysli von na USB
		nop				;oneskorenie kvoli casovaniu
		dec	bitcount		;zmensi pocitadlo bitov - podla carry flagu
		brne	SendUSBAnswerBitstuffLoop	;ak pocitadlo bitov nie je nulove - opakuj vysielanie s dalsim bitom
		ld	inputbuf,Y		;oneskorenie 2 cykly
ZeroBitStuf:
		nop				;oneskorenie 1 cyklus
		cbr	temp0,3
		out	outputport,temp0	;vysli EOP na USB

		ldi	bitcount,5		;pocitadlo oneskorenia: EOP ma trvat 2 bity (16 cyklov pri 12MHz)
SendUSBWaitEOP:
		dec	bitcount
		brne	SendUSBWaitEOP

		sbi	outputport,DATAminus	;nahodenie DATAminus : kludovy stav na port USB
		sbi	outputport,DATAminus	;oneskorenie 2 cykly: Idle ma trvat 1 bit (8 cyklov pri 12MHz)
		cbi	USBdirection,DATAplus	;DATAplus ako vstupny
		cbi	USBdirection,DATAminus	;DATAminus ako vstupny
		cbi	outputport,DATAminus	;zhodenie DATAminus : treti stav na port USB
		ret
;------------------------------------------------------------------------------------------
ToggleDATAPID:
		lds	temp0,OutputBufferBegin+1	;nahraj posledne PID
		cpi	temp0,DATA1PID			;ak bolo posledne DATA1PID byte
		ldi	temp0,DATA0PID
		breq	SendData0PID			;tak posli nulovu odpoved s DATA0PID
		ldi	temp0,DATA1PID			;inak posli nulovu odpoved s DATA1PID
SendData0PID:
		sts	OutputBufferBegin+1,temp0	;DATA0PID byte
		ret
;------------------------------------------------------------------------------------------
ComposeZeroDATA1PIDAnswer:
		ldi	temp0,DATA0PID			;DATA0 PID - v skutocnosti sa stoggluje na DATA1PID v nahrati deskriptora
		sts	OutputBufferBegin+1,temp0	;nahraj do vyst buffera
ComposeZeroAnswer:
		ldi	temp0,SOPbyte
		sts	OutputBufferBegin+0,temp0	;SOP byte
		rcall	ToggleDATAPID			;zmen DATAPID
		ldi	temp0,0x00
		sts	OutputBufferBegin+2,temp0	;CRC byte
		sts	OutputBufferBegin+3,temp0	;CRC byte
		ldi	ByteCount,2+2			;dlzka vystupneho buffera (SOP a PID + CRC16)
		ret
;------------------------------------------------------------------------------------------
InitACKBufffer:
		ldi	temp0,SOPbyte
		sts	ACKBufferBegin+0,temp0		;SOP byte
		ldi	temp0,ACKPID
		sts	ACKBufferBegin+1,temp0		;ACKPID byte
		ret
;------------------------------------------------------------------------------------------
SendACK:
		push	USBBufptrY
		push	bitcount
		push	OutBitStuffNumber
		ldi	USBBufptrY,ACKBufferBegin	;pointer na zaciatok ACK buffera
		ldi	ByteCount,2			;pocet vyslanych bytov (iba SOP a ACKPID)
		clr	OutBitStuffNumber
		rcall	SendUSBBuffer
		pop	OutBitStuffNumber
		pop	bitcount
		pop	USBBufptrY
		ret
;------------------------------------------------------------------------------------------
InitNAKBufffer:
		ldi	temp0,SOPbyte
		sts	NAKBufferBegin+0,temp0		;SOP byte
		ldi	temp0,NAKPID
		sts	NAKBufferBegin+1,temp0		;NAKPID byte
		ret
;------------------------------------------------------------------------------------------
SendNAK:
		push	OutBitStuffNumber
		ldi	USBBufptrY,NAKBufferBegin	;pointer na zaciatok ACK buffera
		ldi	ByteCount,2			;pocet vyslanych bytov (iba SOP a NAKPID)
		clr	OutBitStuffNumber
		rcall	SendUSBBuffer
		pop	OutBitStuffNumber
		ret
;------------------------------------------------------------------------------------------
ComposeSTALL:
		ldi	temp0,SOPbyte
		sts	OutputBufferBegin+0,temp0	;SOP byte
		ldi	temp0,STALLPID
		sts	OutputBufferBegin+1,temp0	;STALLPID byte
		ldi	ByteCount,2			;dlzka vystupneho buffera (SOP a PID)
		ret
;------------------------------------------------------------------------------------------
DecodeNRZI:	;enkodovanie buffera z NRZI kodu do binarneho
		push	USBBufptrY		;zalohuj pointer do buffera
		push	ByteCount		;zalohuj dlzku buffera
		add	ByteCount,USBBufptrY	;koniec buffera do ByteCount
		ser	temp0			;na zabezpecenie jednotkoveho carry (v nasledujucej rotacii)
NRZIloop:
		ror	temp0			;naplnenie carry z predchadzajuceho byte
		ld	temp0,Y			;nahraj prijaty byte z buffera
		mov	temp2,temp0		;posunuty register o jeden bit vpravo a XOR na funkciu NRZI dekodovania
		ror	temp2			;carry do najvyssieho bitu a sucasne posuv
		eor	temp2,temp0		;samotne dekodovanie NRZI
		com	temp2			;negovanie
		st	Y+,temp2		;ulozenie spat ako dekodovany byte a zvys pointer do buffera
		cp	USBBufptrY,ByteCount	;ak este neboli vsetky
		brne	NRZIloop		;tak opakuj
		pop	ByteCount		;obnov dlzku buffera
		pop	USBBufptrY		;obnov pointer do buffera
		ret				;inak skonci
;------------------------------------------------------------------------------------------
BitStuff:	;odstranenie bit-stuffingu v buffri
		clr	temp3			;pocitadlo vynechanych bitov
		clr	lastBitstufNumber	;0xFF do lastBitstufNumber
		dec	lastBitstufNumber
BitStuffRepeat:
		push	USBBufptrY		;zalohuj pointer do buffera
		push	ByteCount		;zalohuj dlzku buffera
		mov	temp1,temp3		;pocitadlo vsetkych bitov
		ldi	temp0,8			;spocitat vsetky bity v bufferi
SumAllBits:
		add	temp1,temp0
		dec	ByteCount
		brne	SumAllBits
		ldi	temp2,6			;inicializuj pocitadlo jednotiek
		pop	ByteCount		;obnov dlzku buffera
		push	ByteCount		;zalohuj dlzku buffera
		add	ByteCount,USBBufptrY	;koniec buffera do ByteCount
		inc	ByteCount		;a pre istotu ho zvys o 2 (kvoli posuvaniu)
		inc	ByteCount
BitStuffLoop:
		ld	temp0,Y			;nahraj prijaty byte z buffera
		ldi	bitcount,8		;pocitadlo bitov v byte
BitStuffByteLoop:
		ror	temp0			;naplnenie carry z LSB
		brcs	IncrementBitstuff	;ak LSB=0
		ldi	temp2,7			;inicializuj pocitadlo jednotiek +1 (ak bola nula)
IncrementBitstuff:
		dec	temp2			;zniz pocitadlo jednotiek (predpoklad jednotkoveho bitu)
		brne	DontShiftBuffer		;ak este nebolo 6 jednotiek za sebou - neposun buffer
		cp	temp1,lastBitstufNumber	;
		ldi	temp2,6			;inicializuj pocitadlo jednotiek (ak by sa nerobil bitstuffing tak sa musi zacat odznova)
		brcc	DontShiftBuffer		;ak sa tu uz robil bitstuffing - neposun buffer

		dec	temp1
		mov	lastBitstufNumber,temp1	;zapamataj si poslednu poziciu bitstuffingu
		cpi	bitcount,1		;aby sa ukazovalo na 7 bit (ktory sa ma vymazat alebo kde sa ma vlozit nula)
		brne	NoBitcountCorrect
		ldi	bitcount,9
		inc	USBBufptrY		;zvys pointer do buffera
NoBitcountCorrect:
		dec	bitcount
		bst	BitStuffInOut,0
		brts	CorrectOutBuffer	;ak je Out buffer - zvys dlzku buffera
		rcall	ShiftDeleteBuffer	;posun In buffer
		dec	temp3			;zniz pocitadlo vynechani
		rjmp	CorrectBufferEnd
CorrectOutBuffer:
		rcall	ShiftInsertBuffer	;posun Out buffer
		inc	temp3			;zvys pocitadlo vynechani
CorrectBufferEnd:
		pop	ByteCount		;obnov dlzku buffera
		pop	USBBufptrY		;obnov pointer do buffera
		rjmp	BitStuffRepeat		;a restartni od zaciatku
DontShiftBuffer:
		dec	temp1			;ak uz boli vsetky bity
		breq	EndBitStuff		;ukonci cyklus
		dec	bitcount		;zniz pocitadlo bitov v byte
		brne	BitStuffByteLoop	;ak este neboli vsetky bity v byte - chod na dalsi bit
						;inak nahraj dalsi byte
		inc	USBBufptrY		;zvys pointer do buffera
		rjmp	BitStuffLoop		;a opakuj
EndBitStuff:
		pop	ByteCount		;obnov dlzku buffera
		pop	USBBufptrY		;obnov pointer do buffera
		bst	BitStuffInOut,0
		brts	IncrementLength		;ak je Out buffer - zvys dlzku Out buffera
DecrementLength:				;ak je In buffer - zniz dlzku In buffera
		cpi	temp3,0			;bolo aspon jedno znizenie
		breq	NoChangeByteCount	;ak nie - nemen dlzku buffera
		dec	ByteCount		;ak je In buffer - zniz dlzku buffera
		subi	temp3,256-8		;ak nebolo viac ako 8 bitov naviac
		brcc	NoChangeByteCount	;tak skonci
		dec	ByteCount		;inak este zniz dlzku buffera
		ret				;a skonci
IncrementLength:
		mov	OutBitStuffNumber,temp3	;zapamataj si pocet bitov naviac
		subi	temp3,8			;ak nebolo viac ako 8 bitov naviac
		brcs	NoChangeByteCount	;tak skonci
		inc	ByteCount		;inak zvys dlzku buffera
		mov	OutBitStuffNumber,temp3	;a zapamataj si pocet bitov naviac (znizene o 8)
NoChangeByteCount:
		ret				;skonci
;------------------------------------------------------------------------------------------
ShiftInsertBuffer:	;posuv buffera o jeden bit vpravo od konca az po poziciu: byte-USBBufptrY a bit-bitcount
		mov	temp0,bitcount		;vypocet: bitcount= 9-bitcount
		ldi	bitcount,9
		sub	bitcount,temp0		;do bitcount poloha bitu, ktory treba nulovat

		ld	temp1,Y			;nahraj byte ktory este treba posunut od pozicie bitcount
		rol	temp1			;a posun vlavo cez Carry (prenos z vyssieho byte a LSB do Carry)
		ser	temp2			;FF do masky - temp2
HalfInsertPosuvMask:
		lsl	temp2			;nula do dalsieho spodneho bitu masky
		dec	bitcount		;az pokial sa nedosiahne hranica posuvania v byte
		brne	HalfInsertPosuvMask

		and	temp1,temp2		;odmaskuj aby zostali iba vrchne posunute bity v temp1
		com	temp2			;invertuj masku
		lsr	temp2			;posun masku vpravo - na vlozenie nuloveho bitu
		ld	temp0,Y			;nahraj byte ktory este treba posunut od pozicie bitcount do temp0
		and	temp0,temp2		;odmaskuj aby zostali iba spodne neposunute bity v temp0
		or	temp1,temp0		;a zluc posunutu a neposunutu cast

		ld	temp0,Y			;nahraj byte ktory este treba posunut od pozicie bitcount
		rol	temp0			;a posun ho vlavo cez Carry (aby sa nastavilo spravne Carry pre dalsie prenosy)
		st	Y+,temp1		;a nahraj spat upraveny byte
ShiftInsertBufferLoop:
		cpse	USBBufptrY,ByteCount	;ak nie su vsetky cele byty
		rjmp	NoEndShiftInsertBuffer	;tak pokracuj
		ret				;inak skonci
NoEndShiftInsertBuffer:
		ld	temp1,Y			;nahraj byte
		rol	temp1			;a posun vlavo cez Carry (prenos z nizsieho byte a LSB do Carry)
		st	Y+,temp1		;a nahraj spat
		rjmp	ShiftInsertBufferLoop	;a pokracuj
;------------------------------------------------------------------------------------------
ShiftDeleteBuffer:	;posuv buffera o jeden bit vlavo od konca az po poziciu: byte-USBBufptrY a bit-bitcount
		mov	temp0,bitcount		;vypocet: bitcount= 9-bitcount
		ldi	bitcount,9
		sub	bitcount,temp0		;do bitcount poloha bitu, ktory este treba posunut
		mov	temp0,USBBufptrY	;uschovanie pointera do buffera
		inc	temp0			;pozicia celych bytov do temp0
		mov	USBBufptrY,ByteCount	;maximalna pozicia do pointra
ShiftDeleteBufferLoop:
		ld	temp1,-Y		;zniz buffer a nahraj byte
		ror	temp1			;a posun vpravo cez Carry (prenos z vyssieho byte a LSB do Carry)
		st	Y,temp1			;a nahraj spat
		cpse	USBBufptrY,temp0	;ak nie su vsetky cele byty
		rjmp	ShiftDeleteBufferLoop	;tak pokracuj

		ld	temp1,-Y		;zniz buffer a nahraj byte ktory este treba posunut od pozicie bitcount
		ror	temp1			;a posun vpravo cez Carry (prenos z vyssieho byte a LSB do Carry)
		ser	temp2			;FF do masky - temp2
HalfDeletePosuvMask:
		dec	bitcount		;az pokial sa nedosiahne hranica posuvania v byte
		breq	DoneMask
		lsl	temp2			;nula do dalsieho spodneho bitu masky
		rjmp	HalfDeletePosuvMask
DoneMask:
		and	temp1,temp2		;odmaskuj aby zostali iba vrchne posunute bity v temp1
		com	temp2			;invertuj masku
		ld	temp0,Y			;nahraj byte ktory este treba posunut od pozicie bitcount do temp0
		and	temp0,temp2		;odmaskuj aby zostali iba spodne neposunute bity v temp0
		or	temp1,temp0		;a zluc posunutu a neposunutu cast
		st	Y,temp1			;a nahraj spat
		ret				;a skonci
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
		add	ByteCount,USBBufptrY	;ByteCount ukazuje na koniec spravy
MirrorBufferloop:
		ld	temp0,Y			;nahraj prijaty byte z buffera
		ldi	temp1,8			;pocitadlo bitov
MirrorBufferByteLoop:
		ror	temp0			;do carry dalsi najnizsi bit
		rol	temp2			;z carry dalsi bit na obratene poradie
		dec	temp1			;bol uz cely byte
		brne	MirrorBufferByteLoop	;ak nie tak opakuj dalsi najnizsi bit
		st	Y+,temp2		;ulozenie spat ako obrateny byte  a zvys pointer do buffera
		cp	USBBufptrY,ByteCount	;ak este neboli vsetky
		brne	MirrorBufferloop	;tak opakuj
		ret				;inak skonci
;------------------------------------------------------------------------------------------
;CheckCRCIn:
;		push	USBBufptrY
;		push	ByteCount
;		ldi	USBBufptrY,InputBufferBegin
;		rcall	CheckCRC
;		pop	ByteCount
;		pop	USBBufptrY
;		ret
;------------------------------------------------------------------------------------------
AddCRCOut:
		push	USBBufptrY
		push	ByteCount
		ldi	USBBufptrY,OutputBufferBegin
		rcall	CheckCRC
		com	temp0			;negacia CRC
		com	temp1
		st	Y+,temp1		;ulozenie CRC na koniec buffera (najskor MSB)
		st	Y,temp0			;ulozenie CRC na koniec buffera (potom LSB)
		dec	USBBufptrY		;pointer na poziciu CRC
		ldi	ByteCount,2		;otocit 2 byty CRC
		rcall	MirrorBufferBytes	;opacne poradie bitov CRC (pri vysielani CRC sa posiela naskor MSB)
		pop	ByteCount
		pop	USBBufptrY
		ret
;------------------------------------------------------------------------------------------
CheckCRC:	;vstup: USBBufptrY = zaciatok spravy	,ByteCount = dlzka spravy
		add	ByteCount,USBBufptrY	;ByteCount ukazuje na koniec spravy
		inc	USBBufptrY		;nastav pointer na zaciatok spravy - vynechat SOP
		ld	temp0,Y+		;nahraj PID do temp0
						;a nastav pointer na zaciatok spravy - vynechat aj PID
		cpi	temp0,DATA0PID		;ci je DATA0 pole
		breq	ComputeDATACRC		;pocitaj CRC16
		cpi	temp0,DATA1PID		;ci je DATA1 pole
		brne	CRC16End		;ak nie tak skonci
ComputeDATACRC:
		ser	temp0			;inicializacia zvysku LSB na 0xff
		ser	temp1			;inicializacia zvysku MSB na 0xff
CRC16Loop:
		ld	temp2,Y+		;nahraj spravu do temp2 a zvys pointer do buffera
		ldi	temp3,8			;pocitadlo bitov v byte - temp3
CRC16LoopByte:
		bst	temp1,7			;do T uloz MSB zvysku (zvysok je iba 16 bitovy - 8 bit vyssieho byte)
		bld	bitcount,0		;do bitcount LSB uloz T - MSB zvysku
		eor	bitcount,temp2		;XOR bitu spravy a bitu zvysku - v LSB bitcount
		rol	temp0			;posun zvysok dolava - nizsi byte (dva byty - cez carry)
		rol	temp1			;posun zvysok dolava - vyssi byte (dva byty - cez carry)
		cbr	temp0,1			;znuluj LSB zvysku
		lsr	temp2			;posun spravu doprava
		ror	bitcount		;vysledok XOR-u bitov z LSB do carry
		brcc	CRC16NoXOR		;ak je XOR bitu spravy a MSB zvysku = 0 , tak nerob XOR
		ldi	bitcount,CRC16poly>>8	;do bitcount CRC polynom - vrchny byte
		eor	temp1,bitcount		;a urob XOR zo zvyskom a CRC polynomom - vrchny byte
		ldi	bitcount,CRC16poly	;do bitcount CRC polynom - spodny byte
		eor	temp0,bitcount		;a urob XOR zo zvyskom a CRC polynomom - spodny byte
CRC16NoXOR:
		dec	temp3			;boli uz vsetky bity v byte
		brne	CRC16LoopByte		;ak nie, tak chod na dalsi bit
		cp	USBBufptrY,ByteCount	;bol uz koniec spravy
		brne	CRC16Loop		;ak nie tak opakuj
CRC16End:
		ret				;inak skonci (v temp0 a temp1 je vysledok)
;------------------------------------------------------------------------------------------
LoadDescriptorFromROM:
		lpm				;nahraj z pozicie ROM pointra do R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer
		adiw	ZH:ZL,1			;zvys ukazovatel do ROM
		dec	ByteCount		;pokial nie su vsetky byty
		brne	LoadDescriptorFromROM	;tak nahravaj dalej
		rjmp	EndFromRAMROM		;inak skonci
;------------------------------------------------------------------------------------------
LoadDescriptorFromROMZeroInsert:
		lpm				;nahraj z pozicie ROM pointra do R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer

		bst	RAMread,3		;ak je 3 bit jednotkovy - nebude sa vkladat nula
		brtc	InsertingZero		;inak sa bude vkladat nula
		adiw	ZH:ZL,1			;zvys ukazovatel do ROM
		lpm				;nahraj z pozicie ROM pointra do R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer
		clt				;a znuluj
		bld	RAMread,3		;treti bit v RAMread - aby sa v dalsom vkladali nuly
		rjmp	InsertingZeroEnd	;a pokracuj
InsertingZero:
		clr	R0			;na vkladanie nul
		st	Y+,R0			;nulu uloz do buffera a zvys buffer
InsertingZeroEnd:
		adiw	ZH:ZL,1			;zvys ukazovatel do ROM
		subi	ByteCount,2		;pokial nie su vsetky byty
		brne	LoadDescriptorFromROMZeroInsert	;tak nahravaj dalej
		rjmp	EndFromRAMROM		;inak skonci
;------------------------------------------------------------------------------------------
LoadDescriptorFromSRAM:
		ld	R0,Z			;nahraj z pozicie RAM pointra do R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer
		inc	ZL			;zvys ukazovatel do RAM
		dec	ByteCount		;pokial nie su vsetky byty
		brne	LoadDescriptorFromSRAM	;tak nahravaj dalej
		rjmp	EndFromRAMROM		;inak skonci
;------------------------------------------------------------------------------------------
LoadDescriptorFromEEPROM:
		out	EEAR,ZL			;nastav adresu EEPROM
		sbi	EECR,EERE		;vycitaj EEPROM do registra EEDR
		in	R0,EEDR			;nahraj z EEDR do R0
		st	Y+,R0			;R0 uloz do buffera a zvys buffer
		inc	ZL			;zvys ukazovatel do RAM
		dec	ByteCount		;pokial nie su vsetky byty
		brne	LoadDescriptorFromEEPROM;tak nahravaj dalej
		rjmp	EndFromRAMROM		;inak skonci
;------------------------------------------------------------------------------------------
LoadXXXDescriptor:
		ldi	temp0,SOPbyte			;SOP byte
		sts	OutputBufferBegin,temp0		;na zaciatok vysielacieho buffera dat SOP
		ldi	ByteCount,8			;8 bytov nahrat
		ldi	USBBufptrY,OutputBufferBegin+2	;do vysielacieho buffera

		and	RAMread,RAMread			;ci sa bude citat z RAM alebo ROM-ky alebo EEPROM-ky
		brne	FromRAMorEEPROM			;0=ROM,1=RAM,2=EEPROM,4=ROM s vkladanim nuly
FromROM:
		rjmp	LoadDescriptorFromROM		;nahrat descriptor z ROM-ky
FromRAMorEEPROM:
		sbrc	RAMread,2			;ak RAMread=4
		rjmp	LoadDescriptorFromROMZeroInsert	;citaj z ROM s vkladanim nuly
		sbrc	RAMread,0			;ak RAMread=1
		rjmp	LoadDescriptorFromSRAM		;nahraj data zo SRAM-ky
		rjmp	LoadDescriptorFromEEPROM	;inak citaj z EEPROM
EndFromRAMROM:
		sbrc	RAMread,7			;ak je najvyssi bit v premennej RAMread=1
		clr	RAMread				;znuluj RAMread
		rcall	ToggleDATAPID			;zmenit DATAPID
		ldi	USBBufptrY,OutputBufferBegin+1	;do vysielacieho buffera - pozicia DATA PID
		ret
;------------------------------------------------------------------------------------------
PrepareUSBOutAnswer:	;pripravenie odpovede do buffera
		rcall	PrepareUSBAnswer		;pripravenie odpovede do buffera
MakeOutBitStuff:
		inc	BitStuffInOut			;vysielaci buffer - vkladanie bitstuff bitov
		ldi	USBBufptrY,OutputBufferBegin	;do vysielacieho buffera
		rcall	BitStuff
		mov	OutputBufferLength,ByteCount	;dlzku odpovede zapamatat pre vysielanie
		clr	BitStuffInOut			;prijimaci buffer - mazanie bitstuff bitov
		ret
;------------------------------------------------------------------------------------------
PrepareUSBAnswer:	;pripravenie odpovede do buffera
		clr	RAMread				;nulu do RAMread premennej - cita sa z ROM-ky
		lds	temp0,InputBufferBegin+2	;bmRequestType do temp0
		lds	temp1,InputBufferBegin+3	;bRequest do temp1
		cbr	temp0,0b10011111		;ak je 5 a 6 bit nulovy
		brne	VendorRequest			;tak to nie je  Vendor Request
		rjmp	StandardRequest			;ale je to standardny request
;--------------------------
DoSetInfraBufferEmpty:
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou
;--------------------------
DoSetRS232Baud:
		lds	temp0,InputBufferBegin+4	;prvy parameter - hodnota baudrate na RS232
		out	UBRR,temp0			;nastav rychlost UART-u
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou
;--------------------------
DoGetRS232Baud:
		in	R0,UBRR				;vrat rychlost UART-u v R0
		rjmp	DoGetIn				;a ukonci
;--------------------------
DoRS232Send:
		lds	temp0,InputBufferBegin+4	;prvy parameter - hodnota vysielana na RS232
		out	UDR,temp0			;vysli data na UART
WaitForRS232Send:
		sbis	UCR,TXEN			;ak nie je povoleny UART vysielac
		rjmp	OneZeroAnswer			;tak skonci - ochrana kvoli zacykleniu v AT90S2323/2343
		sbis	USR,TXC				;pockat na dovysielanie bytu
		rjmp	WaitForRS232Send
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou
;--------------------------
DoRS232Read:
		rjmp	TwoZeroAnswer			;iba potvrd prijem dvoma nulami
;--------------------------
VendorRequest:
		clr	ZH				;pre citanie z RAM alebo EEPROM

		cpi	temp1,1				;
		breq	DoSetInfraBufferEmpty		;restartne infra prijimanie (ak bolo zastavene citanim z RAM-ky)

		cpi	temp1,2				;
		breq	DoGetInfraCode			;vysle prijaty infra kod (ak je v bufferi)

		cpi	temp1,3				;
		breq	DoSetDataPortDirection		;nastavi smer toku datovych bitov
		cpi	temp1,4				;
		breq	DoGetDataPortDirection		;zisti smer toku datovych bitov

		cpi	temp1,5				;
		breq	DoSetOutDataPort		;nastavi datove bity (ak su vstupne, tak ich pull-up)
		cpi	temp1,6				;
		breq	DoGetOutDataPort		;zisti nastavenie datovych out bitov (ak su vstupne, tak ich pull-up)

		cpi	temp1,7				;
		breq	DoGetInDataPort			;vrati hodnotu datoveho vstupneho portu

		cpi	temp1,8				;
		breq	DoEEPROMRead			;vrati obsah EEPROM od urcitej adresy
		cpi	temp1,9				;
		breq	DoEEPROMWrite			;zapise EEPROM na urcitu adresu urcite data

		cpi	temp1,10			;
		breq	DoRS232Send			;vysle byte na seriovy linku
		cpi	temp1,11			;
		breq	DoRS232Read			;vrati prijaty byte zo seriovej linky (ak sa nejaky prijal)

		cpi	temp1,12			;
		breq	DoSetRS232Baud			;nastavi prenosovu rychlost seriovej linky
		cpi	temp1,13			;
		breq	DoGetRS232Baud			;vrati prenosovu rychlost seriovej linky
		cpi	temp1,14			;
		breq	DoGetRS232Buffer		;vrati RS232 buffer

		cpi	temp1,USER_FNC_NUMBER+0		;
		breq	DoUserFunction0			;vykona uzivatelsku rutinu0
		cpi	temp1,USER_FNC_NUMBER+1		;
		breq	DoUserFunction1			;vykona uzivatelsku rutinu1
		cpi	temp1,USER_FNC_NUMBER+2		;
		breq	DoUserFunction2			;vykona uzivatelsku rutinu2

		rjmp	ZeroDATA1Answer			;ak to bolo nieco nezname, tak priprav nulovu odpoved

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

DoUserFunctionX:
DoUserFunction0:  ;send byte(s) of RAM starting at position given by first parameter in function
		lds	temp0,InputBufferBegin+4	;prvy  parameter Lo do temp0
		;lds	temp1,InputBufferBegin+5	;prvy  parameter Hi do temp1
		;lds	temp2,InputBufferBegin+6	;druhy parameter Lo do temp2
		;lds	temp3,InputBufferBegin+7	;druhy parameter Hi do temp3
		;lds	ACC,InputBufferBegin+8		;pocet pozadovanych bytov do ACC

		;Tu si pridajte vlastny kod:
		;-------------------------------------------------------------------
		nop					;priklad na kod - nic nerobi
		nop
		nop
		nop
		nop
		;-------------------------------------------------------------------

		mov	ZL,temp0			;bude sa posielat hodnota RAM adresy ulozena v temp0 (prvy parameter funkcie)
		inc	RAMread				;RAMread=1 - cita sa z RAM-ky
		ldi	temp0,RAMEND+1			;posli max pocet byte - celu RAM
		rjmp	ComposeEndXXXDescriptor		;a priprav data
DoUserFunction1:
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou
DoUserFunction2:
		rjmp	TwoZeroAnswer			;potvrd prijem dvoma nulami
;------------------ END: This is template how to write own function ----------------

;----------------------------- USER FUNCTIONS --------------------------------------

DoGetInfraCode:
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou

DoEEPROMRead:
		lds	ZL,InputBufferBegin+4		;prvy parameter - offset v EEPROM-ke
		ldi	temp0,2
		mov	RAMread,temp0			;RAMread=2 - cita sa z EEPROM-ky
		ldi	temp0,E2END+1			;pocet mojich bytovych odpovedi do temp0 - cela dlzka EEPROM
		rjmp	ComposeEndXXXDescriptor		;inak priprav data
DoEEPROMWrite:
		lds	ZL,InputBufferBegin+4		;prvy parameter - offset v EEPROM-ke (adresa)
		lds	R0,InputBufferBegin+6		;druhy parameter - data, ktore sa maju zapisat do EEPROM-ky (data)
		rjmp	EEPROMWrite			;zapis do EEPROM a aj ukonci prikaz
DoSetDataPortDirection:
		lds	ACC,InputBufferBegin+4		;prvy parameter - smer datovych bitov
		rcall	SetDataPortDirection
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou
DoGetDataPortDirection:
		rcall	GetDataPortDirection
		rjmp	DoGetIn

DoSetOutDataPort:
		lds	ACC,InputBufferBegin+4		;prvy parameter - hodnota datovych bitov
		rcall	SetOutDataPort
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou
DoGetOutDataPort:
		rcall	GetOutDataPort
		rjmp	DoGetIn

DoGetInDataPort:
		rcall	GetInDataPort
 DoGetIn:
		ldi	ZL,0				;posiela sa hodnota v R0
		ldi	temp0,0x81			;RAMread=1 - cita sa z RAM-ky
		mov	RAMread,temp0			;(najvyssi bit na 1 - aby sa hned premenna RAMread znulovala)
		ldi	temp0,1				;posli iba jeden byte
		rjmp	ComposeEndXXXDescriptor		;a priprav data

DoGetRS232Buffer:
		mov	temp0,RS232BufferFull		;zisti dlzku buffera RS232 kodu
		cpi	temp0,0				;ak je RS232 Buffer prazdny
		breq	OneZeroAnswer			;tak nic neposli a potvrd prijem jednou nulou

		lds	ACC,InputBufferBegin+8		;pocet pozadovanych bytov do ACC
		inc	temp0				;pocet moznych dodanych bajtov (plus byte dlzky buffera)
		cp	ACC,temp0			;ak sa neziada viac ako mozem dodat
		brcc	NoShortGetRS232Buffer		;vysli tolko kolko sa ziada
		mov	temp0,ACC
NoShortGetRS232Buffer:
		dec	temp0				;uber byte dlzky
		lds	temp1,RS232BufferBegin+1	;zisti ukazovatel citania buffera RS232 kodu : 2.byte hlavicky (dlzka kodu + citanie + zapis + rezerva)
		add	temp1,temp0			;zisti kde je koniec
		cpi	temp1,RS232BufferBegin+MAXRS232LENGTH+1	;ak by mal pretiect
		brcs	ReadNoOverflow
		subi	temp1,RS232BufferBegin+MAXRS232LENGTH+1	;vypocitaj kolko sa neprenesie
		sub	temp0,temp1			;a o to skrat dlzku citania
		ldi	temp1,RS232BufferBegin+4	;a zacni od nuly
ReadNoOverflow:
		lds	ZL,RS232BufferBegin+1		;zisti ukazovatel citania buffera RS232 kodu : 2.byte hlavicky (dlzka kodu + citanie + zapis + rezerva)
		sts	RS232BufferBegin+1,temp1	;zapis novy ukazovatel citania buffera RS232 kodu : 2.byte hlavicky (dlzka kodu + citanie + zapis + rezerva)
		dec	ZL				;priestor pre udaj dlky - prenasa sa ako prvy bajt

		sub	RS232BufferFull,temp0		;zniz dlzku buffera
		st	Z,RS232BufferFull		;a uloz skutocnu dlzku do paketu
		inc	temp0				;a o tento jeden bajt zvys pocet prenasanych bajtov (dlzka buffera)
		inc	RAMread				;RAMread=1 - cita sa z RAM-ky
		rjmp	ComposeEndXXXDescriptor		;a priprav data
;----------------------------- END USER FUNCTIONS ----------------------------------

OneZeroAnswer:		;posle jednu nulu
		ldi	temp0,1				;pocet mojich bytovych odpovedi do temp0
		rjmp	ComposeGET_STATUS2

StandardRequest:
		cpi	temp1,GET_STATUS		;
		breq	ComposeGET_STATUS		;

		cpi	temp1,CLEAR_FEATURE		;
		breq	ComposeCLEAR_FEATURE		;

		cpi	temp1,SET_FEATURE		;
		breq	ComposeSET_FEATURE		;

		cpi	temp1,SET_ADDRESS		;ak sa ma nastavit adresa
		breq	ComposeSET_ADDRESS		;nastav adresu

		cpi	temp1,GET_DESCRIPTOR		;ak sa ziada descriptor
		breq	ComposeGET_DESCRIPTOR		;vygeneruj ho

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
							;ak sa nenasla znama poziadavka
		rjmp	ZeroDATA1Answer			;ak to bolo nieco nezname, tak priprav nulovu odpoved

ComposeSET_ADDRESS:
		lds	temp1,InputBufferBegin+4	;nova adresa do temp1
		rcall	SetMyNewUSBAddresses		;ENG;and compute NRZI and bitstuffing coded adresses
		ldi	State,AddressChangeState	;nastav stav pre zmenu adresy
		rjmp	ZeroDATA1Answer			;posli nulovu odpoved

ComposeSET_CONFIGURATION:
		lds	ConfigByte,InputBufferBegin+4	;cislo konfiguracie do premennej ConfigByte
ComposeCLEAR_FEATURE:
ComposeSET_FEATURE:
ComposeSET_INTERFACE:
ZeroStringAnswer:
		rjmp	ZeroDATA1Answer			;posli nulovu odpoved
ComposeGET_STATUS:
TwoZeroAnswer:
		ldi	temp0,2				;pocet mojich bytovych odpovedi do temp0
ComposeGET_STATUS2:
		ldi	ZH, high(StatusAnswer<<1)	;ROMpointer na odpoved
		ldi	ZL,  low(StatusAnswer<<1)
		rjmp	ComposeEndXXXDescriptor		;a dokonci
ComposeGET_CONFIGURATION:
		and	ConfigByte,ConfigByte		;ak som nenakonfigurovany
		breq	OneZeroAnswer			;tak posli jednu nulu - inak posli moju konfiguraciu
		ldi	temp0,1				;pocet mojich bytovych odpovedi do temp0
		ldi	ZH, high(ConfigAnswerMinus1<<1)	;ROMpointer na odpoved
		ldi	ZL,  low(ConfigAnswerMinus1<<1)+1
		rjmp	ComposeEndXXXDescriptor		;a dokonci
ComposeGET_INTERFACE:
		ldi	ZH, high(InterfaceAnswer<<1)	;ROMpointer na odpoved
		ldi	ZL,  low(InterfaceAnswer<<1)
		ldi	temp0,1				;pocet mojich bytovych odpovedi do temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci
ComposeSYNCH_FRAME:
ComposeSET_DESCRIPTOR:
		rcall	ComposeSTALL
		ret
ComposeGET_DESCRIPTOR:
		lds	temp1,InputBufferBegin+5	;DescriptorType do temp1
		cpi	temp1,DEVICE			;DeviceDescriptor
		breq	ComposeDeviceDescriptor		;
		cpi	temp1,CONFIGURATION		;ConfigurationDescriptor
		breq	ComposeConfigDescriptor		;
		cpi	temp1,STRING			;StringDeviceDescriptor
		breq	ComposeStringDescriptor		;
		ret
ComposeDeviceDescriptor:
		ldi	ZH, high(DeviceDescriptor<<1)	;ROMpointer na descriptor
		ldi	ZL,  low(DeviceDescriptor<<1)
		ldi	temp0,0x12			;pocet mojich bytovych odpovedi do temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci
ComposeConfigDescriptor:
		ldi	ZH, high(ConfigDescriptor<<1)	;ROMpointer na descriptor
		ldi	ZL,  low(ConfigDescriptor<<1)
		ldi	temp0,9+9+7			;pocet mojich bytovych odpovedi do temp0
ComposeEndXXXDescriptor:
		lds	TotalBytesToSend,InputBufferBegin+8	;pocet pozadovanych bytov do TotalBytesToSend
		cp	TotalBytesToSend,temp0			;ak sa neziada viac ako mozem dodat
		brcs	HostConfigLength		;vysli tolko kolko sa ziada
		mov	TotalBytesToSend,temp0		;inak posli pocet mojich odpovedi
HostConfigLength:
		mov	temp0,TotalBytesToSend		;
		clr	TransmitPart			;nuluj pocet 8 bytovych odpovedi
		andi	temp0,0b00000111		;ak je dlzka delitelna 8-mimi
		breq	Length8Multiply			;tak nezapocitaj jednu necelu odpoved (pod 8 bytov)
		inc	TransmitPart			;inak ju zapocitaj
Length8Multiply:
		mov	temp0,TotalBytesToSend		;
		lsr	temp0				;dlzka 8 bytovych odpovedi sa dosiahne
		lsr	temp0				;delenie celociselne 8-mimi
		lsr	temp0
		add	TransmitPart,temp0		;a pripocitanim k poslednej necelej 8-mici do premennej TransmitPart
		ldi	temp0,DATA0PID			;DATA0 PID - v skutocnosti sa stoggluje na DATA1PID v nahrati deskriptora
		sts	OutputBufferBegin+1,temp0	;nahraj do vyst buffera
		rjmp	ComposeNextAnswerPart
ComposeStringDescriptor:
		ldi	temp1,4+8			;ak RAMread=4(vkladaj nuly z ROM-koveho citania) + 8(za prvy byte nevkldadaj nulu)
		mov	RAMread,temp1
		lds	temp1,InputBufferBegin+4	;DescriptorIndex do temp1
		cpi	temp1,0				;LANGID String
		breq	ComposeLangIDString		;
		cpi	temp1,2				;DevNameString
		breq	ComposeDevNameString		;
		brcc	ZeroStringAnswer		;ak je DescriptorIndex vyssi nez 2 - posli nulovu odpoved
							;inak to bude VendorString
ComposeVendorString:
		ldi	ZH, high(VendorStringDescriptor<<1)	;ROMpointer na descriptor
		ldi	ZL,  low(VendorStringDescriptor<<1)
		ldi	temp0,(VendorStringDescriptorEnd-VendorStringDescriptor)*4-2	;pocet mojich bytovych odpovedi do temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci
ComposeDevNameString:
		ldi	ZH, high(DevNameStringDescriptor<<1)	;ROMpointer na descriptor
		ldi	ZL,  low(DevNameStringDescriptor<<1)
		ldi	temp0,(DevNameStringDescriptorEnd-DevNameStringDescriptor)*4-2	;pocet mojich bytovych odpovedi do temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci
ComposeLangIDString:
		clr	RAMread
		ldi	ZH, high(LangIDStringDescriptor<<1)	;ROMpointer na descriptor
		ldi	ZL,  low(LangIDStringDescriptor<<1)
		ldi	temp0,(LangIDStringDescriptorEnd-LangIDStringDescriptor)*2;pocet mojich bytovych odpovedi do temp0
		rjmp	ComposeEndXXXDescriptor		;a dokonci
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
;------------------------------------------------------------------------------------------
PrepareOutContinuousBuffer:
		rcall	PrepareContinuousBuffer
		rcall	MakeOutBitStuff
		ret
;------------------------------------------------------------------------------------------
PrepareContinuousBuffer:
		mov	temp0,TransmitPart
		cpi	temp0,1
		brne	NextAnswerInBuffer		;ak uz je buffer prazdny
		rcall	ComposeZeroAnswer		;priprav nulovu odpoved
		ret
NextAnswerInBuffer:
		dec	TransmitPart			;znizit celkovu dlzku odpovede
ComposeNextAnswerPart:
		mov	temp1,TotalBytesToSend	;zniz pocet bytov na vyslanie
		subi	temp1,8			;ci je este treba poslat viac ako 8 bytov
		ldi	temp3,8			;ak ano - posli iba 8 bytov
		brcc	Nad8Bytov
		mov	temp3,TotalBytesToSend	;inak posli iba dany pocet bytov
		clr	TransmitPart
		inc	TransmitPart		;a bude to posledna odpoved
Nad8Bytov:
		mov	TotalBytesToSend,temp1	;znizeny pocet bytov do TotalBytesToSend
		rcall	LoadXXXDescriptor
		ldi	ByteCount,2		;dlzka vystupneho buffera (iba SOP a PID)
		add	ByteCount,temp3		;+ pocet bytov
		rcall	AddCRCOut		;pridanie CRC do buffera
		inc	ByteCount		;dlzka vystupneho buffera + CRC16
		inc	ByteCount
		ret				;skonci
;------------------------------------------------------------------------------------------
.equ	USBversion		=0x0101		;pre aku verziu USB je to (1.01)
.equ	VendorUSBID		=0x03EB		;identifikator dodavatela (Atmel=0x03EB)
.equ	DeviceUSBID		=0x21FE		;identifikator vyrobku (USB to RS232 converter AT90S2313=0x21FE)
.equ	DeviceVersion		=0x0002		;cislo verzie vyrobku (verzia=0.02)
.equ	MaxUSBCurrent		=46		;prudovy odber z USB (46mA)
;------------------------------------------------------------------------------------------
DeviceDescriptor:
		.db	0x12,0x01		;0 byte - velkost deskriptora v bytoch
						;1 byte - typ deskriptora: Deskriptor zariadenia
		.dw	USBversion		;2,3 byte - verzia USB LSB (1.00)
		.db	0x00,0x00		;4 byte - trieda zariadenia
						;5 byte - podtrieda zariadenia
		.db	0x00,0x08		;6 byte - kod protokolu
						;7 byte - velkost FIFO v bytoch
		.dw	VendorUSBID		;8,9 byte - identifikator dodavatela (Cypress=0x04B4)
		.dw	DeviceUSBID		;10,11 byte - identifikator vyrobku (teplomer=0x0002)
		.dw	DeviceVersion		;12,13 byte - cislo verzie vyrobku (verzia=0.01)
		.db	0x01,0x02		;14 byte - index stringu "vyrobca"
						;15 byte - index stringu "vyrobok"
		.db	0x00,0x01		;16 byte - index stringu "seriove cislo"
						;17 byte - pocet moznych konfiguracii
DeviceDescriptorEnd:
;------------------------------------------------------------------------------------------
ConfigDescriptor:
		.db	0x9,0x02		;dlzka,typ deskriptoru
ConfigDescriptorLength:
		.dw	9+9+7			;celkova dlzka vsetkych deskriptorov
	ConfigAnswerMinus1:			;pre poslanie cisla congiguration number (pozor je  treba este pricitat 1)
		.db	1,1			;numInterfaces,congiguration number
		.db	0,0x80			;popisny index stringu, atributy;bus powered
		.db	MaxUSBCurrent/2,0x09	;prudovy odber, interface descriptor length
		.db	0x04,0			;interface descriptor; cislo interface
	InterfaceAnswer:			;pre poslanie cisla alternativneho interface
		.db	0,1			;alternativne nastavenie interface; pocet koncovych bodov okrem EP0
	StatusAnswer:				;2 nulove odpovede (na usetrenie miestom)
		.db	0,0			;trieda rozhrania; podtrieda rozhrania
		.db	0,0			;kod protokolu; index popisneho stringu
		.db	0x07,0x5		;dlzka,typ deskriptoru - endpoint
		.db	0x81,0			;endpoint address; transfer type
		.dw	0x08			;max packet size
		.db	10,0			;polling interval [ms]; dummy byte (pre vyplnenie)
ConfigDescriptorEnd:
;------------------------------------------------------------------------------------------
LangIDStringDescriptor:
		.db	(LangIDStringDescriptorEnd-LangIDStringDescriptor)*2,3	;dlzka, typ: string deskriptor
		.dw	0x0409			;English
LangIDStringDescriptorEnd:
;------------------------------------------------------------------------------------------
VendorStringDescriptor:
		.db	(VendorStringDescriptorEnd-VendorStringDescriptor)*4-2,3	;dlzka, typ: string deskriptor
CopyRight:
		.db	"Ing. Igor Cesko"
CopyRightEnd:
VendorStringDescriptorEnd:
;------------------------------------------------------------------------------------------
DevNameStringDescriptor:
		.db	(DevNameStringDescriptorEnd-DevNameStringDescriptor)*4-2,3;dlzka, typ: string deskriptor
		.db	"AVR309:USB to UART protocol converter (simple)"
DevNameStringDescriptorEnd:
;------------------------------------------------------------------------------------------
MaskPortData:
		bst	ACC,0
		bld	temp0,LEDlsb0
		bst	ACC,1
		bld	temp0,LEDlsb1
		bst	ACC,2
		bld	temp0,LEDlsb2
		bst	ACC,3
		bld	temp1,LEDmsb3
		bst	ACC,4
		bld	temp1,LEDmsb4
		bst	ACC,5
		bld	temp1,LEDmsb5
		bst	ACC,6
		bld	temp1,LEDmsb6
		bst	ACC,7
		bld	temp1,LEDmsb7
		ret
;------------------------------------------------------------------------------------------
SetDataPortDirection:
		in	temp0,LEDdirectionLSB		;nacitaj aktualny stav LSB do temp0 (aby sa nezmenili ostatne smery bitov)
		in	temp1,LEDdirectionMSB		;nacitaj aktualny stav MSB do temp1 (aby sa nezmenili ostatne smery bitov)
		rcall	MaskPortData
		out	LEDdirectionLSB,temp0		;a update smeru LSB datoveho portu
		out	LEDdirectionMSB,temp1		;a update smeru MSB datoveho portu
		ret
;------------------------------------------------------------------------------------------
SetOutDataPort:
		in	temp0,LEDPortLSB		;nacitaj aktualny stav LSB do temp0 (aby sa nezmenili ostatne bity)
		in	temp1,LEDPortMSB		;nacitaj aktualny stav MSB do temp1 (aby sa nezmenili ostatne bity)
		rcall	MaskPortData
		out	LEDPortLSB,temp0		;a update LSB datoveho portu
		out	LEDPortMSB,temp1		;a update MSB datoveho portu
		ret
;------------------------------------------------------------------------------------------
GetInDataPort:
		in	temp0,LEDPinMSB			;nacitaj aktualny stav MSB do temp0
		in	temp1,LEDPinLSB			;nacitaj aktualny stav LSB do temp1
MoveLEDin:
		bst	temp1,LEDlsb0			;a daj bity LSB na spravne pozicie (z temp1 do temp0)
		bld	temp0,0				;(bity MSB su na spravnom mieste)
		bst	temp1,LEDlsb1
		bld	temp0,1
		bst	temp1,LEDlsb2
		bld	temp0,2
		mov	R0,temp0			;a vysledok uloz do R0
		ret
;------------------------------------------------------------------------------------------
GetOutDataPort:
		in	temp0,LEDPortMSB		;nacitaj aktualny stav MSB do temp0
		in	temp1,LEDPortLSB		;nacitaj aktualny stav LSB do temp1
		rjmp	MoveLEDin
;------------------------------------------------------------------------------------------
GetDataPortDirection:
		in	temp0,LEDdirectionMSB		;nacitaj aktualny stav MSB do temp0
		in	temp1,LEDdirectionLSB		;nacitaj aktualny stav LSB do temp1
		rjmp	MoveLEDin
;------------------------------------------------------------------------------------------
EEPROMWrite:
		out	EEAR,ZL				;nastav adresu EEPROM
		out	EEDR,R0				;nastav data do EEPROM
		cli					;zakaz prerusenie
		sbi	EECR,EEMWE			;nastav master write enable
		sei					;povol prerusenie (este sa vykona nasledujuca instrukcia)
		sbi	EECR,EEWE			;samotny zapis
WaitForEEPROMReady:
		sbic	EECR,EEWE			;pockaj si na koniec zapisu
		rjmp	WaitForEEPROMReady		;v slucke (max cca 4ms) (kvoli naslednemu citaniu/zapisu)
		rjmp	OneZeroAnswer			;potvrd prijem jednou nulou
;------------------------------------------------------------------------------------------
;********************************************************************
;* End of Program
;********************************************************************
;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
;********************************************************************
;* End of file
;********************************************************************
