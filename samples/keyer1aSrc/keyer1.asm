;**********************************************************************
;                                                                     *
;   KEYER1.ASM  by W.Buescher (DL4YHF)                                *
;                                                                     *
;                                                                     *
;   ELBUG-firmware for PIC16F84                                       *
;                                                                     *
;     - power-saving operation at 50kHz, using SLEEP-Mode,            *
;       no need for ON/OFF-switch                                     *
;     - RECORD and PLAY of a message with max. 63 letters in EEPROM   *
;                                       and about 50 letters in RAM   *
;     - two function keys for "MSG1", "MSG2", combined="MODE"         *
;     - CW-speed-setting via POTI                                     *
;                                                                     *
;                                                                     *
;   Revision date:  03/2000                                           *
;   recent changes:                                                   *
;     07/1999:                                                        *
;         - changed the oscillator from "LP-crystal" to "RC"          *
;              because wake-up with 32kHz-crytal was too slow         *
;         - changed storage format of "pauses" from "bit" to "byte"   *
;              to allow different "pause times" between WORDs         *
;         - implemented a second "message memory" in RAM, which is    *
;           o.k. because RAM-contents don't get lost during           *
;           sleep mode (also applies to "configuration data").        *
;         - implemented two macro-codes (NNN) and (ANN) for a         *
;           "contest number generator"                                *
;     03/2000: Upward compatible with rev 07/1999.                    *
;         - implemented a "BEACON" mode which is quite the same as    *
;           the "LOOP" mode but it does not automatically "stop"      *
;           after 255 message replays. Also good for ARDF-TX.         *
;           Beacon mode may be activated with the command "C" (!).    *
;         - about 20 words of program memory left                     *
;           for "future extensions".                                  *
;         - used MPLab for Windows/16 3.99.23, processor V6.3205      *
;     07/2000: Changed from MPLab V3.99 to V5.11 and rebuilt the      *
;           project, just to find out that I still get 8 messages     *
;           from MPASM telling the "same old story":                  *
;            > Register in operand not in bank 0.                     *
;            > Ensure that bank bits are correct.                     *
;           The resulting hex file is still exactly 5999 bytes long.  *
;     07/2001: Started project KEYER2 which uses exactly the same     *
;           Hardware as KEYER1 but has a QRSS transmission mode       *
;           instead of the contest-number-generator.                  *
;     07/2002: Produced a variant of KEYER1 for the PIC16F628,        *
;           Project name "KEYER628" .                                 *
;                                                                     *
;**********************************************************************
;  Usage of this file:                                                *
;    - Compile with Microchip's MPLAB, using project file KEYER1.PJT  *
;    - program the generated .HEX-Files mit "PIP02" into a PIC16F84   *
;      using one of the many "extra simple PIC-Programmers".          *
;    - plug the PIC into an "ugly style construction" PC board        *
;      (maybe you will also find a PCB layout where you got this..)   *
;                                                                     *
;**********************************************************************
;                                                                     *
;  Author:                                                            *
;     Wolfgang Buescher, Teutoburger Strasse 6, 33415 Verl, Germany   *
;     Contact me via Packet Radio:  DL4YHF@DB0EAM.#HES.DEU.EU         *
;                         (or maybe DL4YHF@DB0BQ.#NRW.DEU.EU )        *
;             or via Internet:      DL4YHF@qsl.net,  DL4YHF@aol.com   *
;                                                                     *
;**********************************************************************
;                                                                     *
;  This program is "shareware" in its current version. You may use it *
;  freely for non-commercial purposes and for "low-profit" kits.      *
;  However, if you find this software useful,  a little donation to   *
;  encourage future projects will be appreciated but not expected ;-) *
;                                                                     *
; You will find the latest release of this software                   * 
;    and german and english manuals at DL4YHF's Homebrew Homepage:    *
;    www.qsl.net/dl4yhf/pic_key.html (follow the links !)             *
;                                                                     *
; Read the "Exclusion of warranty" before using this software...      *
;   (the author will not be liable for anything at all, as usual).    *
;                                                                     *
;                                                                     *
;**********************************************************************

 ; radix  dec
  list      p=16F84             ; list directive to define processor
  #include <p16F84.inc>         ; processor specific variable definitions


; '__CONFIG' directive is used to embed configuration data within .asm file.
; The lables following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.
 ;EX: __CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _LP_OSC
      __CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _RC_OSC
; See Notes on the clock oscillator below !
; Don't enable the watchdog... I don't "feed" it in this program !


;=======================================================================
; Hardware description and software considerations
;=======================================================================
;
; Clock Oscillator
; ----------------
;  The PIC16F84 WAS running in "low power mode" with 32.768kHz crystal.
;  Worked fine for the first tests, but:
;    In "low power 32kHz-crystal mode" wake-up took up to 5 seconds... 
;    thats why the keyer now uses the RC-oscillator.
;  In "RC-oscillator"-mode wake-up only needs some 100 Microseconds
;  which is ok for this purpose. In the prototype the oscillator was:
;  R=100kOhm,  Cext=450pF (!), the resulting clock frequency was
;  50kHz ... though the data sheet says something different.
;  You may change the clock oscillator if you don't like the pitch
;  of the sidetone. 
;  A PIC instruction takes 4 clock cyles, so 8192 instructions are executed
;  per second,  or one instruction needs 122 Microseconds.
;
; Poti
; ----
;  The speed-poti is connected to a capacitor, the PIC treats this
;  as a "programmed monoflop". The timer is used to measure the
;  capacitor charge time. The Poti has 47...100kOhm (connected from
;  PortB.0 to Vcc) and the Capacitor (connected to GND) is 220nF.
;
; Sidetone
; --------
;  Because the 500Hz-sidetone has to be genereated by the software,
;  the "audio output pin" has to be inverted every 8 instructions..
;  seems a tough job if other tasks have to be performed too.
;  (The timer has been occupied for other tasks..)
;
; Power Consumption
; -----------------
;  Though no longer running in "LP"-mode, the PIC itself only draws
;  about 50uA when operating and about 0.7uA when in standby-mode.
;  The software enters "standby-mode" if there is no action 
;  (no "replay" and no key pressed) for more than 0.x seconds.
;  The PIC will wake up  on any change at the  Port B inputs
;  (that's where the paddle and the function keys are connected). 
;  Additional power is only required for the sidetone output
;  (up to 300uA with low-impedance speakers) and to drive the
;  base of the "keying transistor".
;  Try a darlington or at least a transistor with a high current gain, 
;  and keep the base resistor as high as possible. 
;  My "switching purpose" FETs didn't work with 2.4 Volts at the gate!
;  
;

;=======================================================================
; Application Switches  (SWI_xx)
;=======================================================================
#define SWI_TEST_QRQ      0 ; 1: Test "REPLAY" with MPSIM, low delay
#define SWI_WARN_QRK      1 ; 1: Warn with a "humming" sidetone
                            ;    if the letter-gap is too short to decode

#define MAIN_CYCLE       14 ; for calculation of morse speed table entries:
        ; "number of cycles in the main loop when the clock freq was 32kHz"
        ; When using 32kHz clock and still 20 cycles main loop: MAIN_CYCLE=20
        ; When using 50kHz clock and still 20 cycles main loop: MAIN_CYCLE=13
;


;=======================================================================
; Port definitions  (IOP_xx)
;=======================================================================
; Some Port-assignments are compatible with the ingenious NorCal-Keyer "KC1"
;    by Wayne Burdick, Rev.B, 4-7-96. 
; The following definitions are Operands for BTFSS etc.

#define IOP_POTI1      PORTA, 0    ; only if poti is POLLED (NO IRQ!!)
#define IOP_KEY_OUTPUT PORTA, 1    ; modulation output:    1=HF on,  0=HF off
#define IOP_TX_CONTROL PORTA, 2    ; transmitter control:  1=TX,     0=RX
#define IOP_AUDIO_OUT  PORTA, 3    ; sidetone (piezo speaker, also "signals")
#define IOP_COUNTER    PORTA, 4    ; frequency counter only with 4 MHz XTAL

; Note: PORTB will have its internal pullups enabled.
;       (so there's no need to tie unused pins to GND or VCC.)
#define IOP_RESERVE1   PORTB, 0    ; "for future use" ....  ..
#define IOP_SIGNAL_LED PORTB, 2    ; "Signal"-LED instead of piezo speaker
#define IOP_HAND_KEY   PORTB, 3    ; from NORCALs keyer. not used yet.
#define IOP_DOT        PORTB, 4    ; the inputs of PORTB are used for wake-up    
#define IOP_DASH       PORTB, 5
#define IOP_KEY_MSG1   PORTB, 6    ; my "MESSAGE 1" is NORCALs "MSG"
#define IOP_KEY_MSG2   PORTB, 7    ; my "MESSAGE 2" is NORCALs "FREQ"

;=======================================================================
; other constants                  
;=======================================================================


  ; Storage format of "spaces", "control characters" and "transmittable CW letters"
  ; ---------------------------------------------------------------------------------
  ;  The most significant bits define the code type.  
  ;     Bit7: 1 = "this is SPACE (=pause) or CONTROL character", in this case: 
  ;        Bit6,Bit5 = control character type:
  ;        0x = SPACE (=pause,     bits5..0 contain the length in DOTS (max.63)
  ;        10 = extra long "dash", bits4..0 contain the length in DOTS (max.31)
  ;        11 = future reserve,    bits4..0 contain 31 possible codes
  ;     Bit7: 0 = "this is a transmittable character (not SPACE or CONTROL)".
  ;        Bits6..0 contain a maximum of 6 dashes or dots,
  ;             with leading 1="Startbit" before the "dash/dot-matrix",
  ;             dash/dot-matrix is in Bit0..max.Bit5: 
  ;                  0=dot 1=dash
  ;             Bit0 always contains the LAST TRANSMITTED dash/dot.
  ; See definitions below for some examples how CW letters are stored in memory.
#define CW_CHR_0     b'00111111'  ; "0" 
#define CW_CHR_1     b'00101111'  ; "1"
#define CW_CHR_2     b'00100111'  ; "2"
#define CW_CHR_3     b'00100011'  ; "3"
#define CW_CHR_4     b'00100001'  ; "4"
#define CW_CHR_5     b'00100000'  ; "5"
#define CW_CHR_6     b'00110000'  ; "6"
#define CW_CHR_7     b'00111000'  ; "7"
#define CW_CHR_8     b'00111100'  ; "8"
#define CW_CHR_9     b'00111110'  ; "9"

#define CW_CHR_A     b'00000101'  ; 'A'
#define CW_CHR_B     b'00011000'  ; 'B'
#define CW_CHR_C     b'00011010'  ; 'C'
#define CW_CHR_D     b'00001100'  ; 'D'
#define CW_CHR_E     b'00000010'  ; 'E'
#define CW_CHR_F     b'00010010'  ; 'F'
#define CW_CHR_G     b'00001110'  ; 'G'
#define CW_CHR_H     b'00010000'  ; 'H'
#define CW_CHR_I     b'00000100'  ; 'I'
#define CW_CHR_J     b'00010111'  ; 'J'
#define CW_CHR_K     b'00001101'  ; 'K'
#define CW_CHR_L     b'00010100'  ; 'L'
#define CW_CHR_M     b'00000111'  ; 'M'
#define CW_CHR_N     b'00000110'  ; 'N'
#define CW_CHR_O     b'00001111'  ; 'O'
#define CW_CHR_P     b'00010110'  ; 'P'
#define CW_CHR_Q     b'00011101'  ; 'Q'
#define CW_CHR_R     b'00001010'  ; 'R'
#define CW_CHR_S     b'00001000'  ; 'S'
#define CW_CHR_T     b'00000011'  ; 'T'
#define CW_CHR_U     b'00001001'  ; 'U'
#define CW_CHR_V     b'00010001'  ; 'V'
#define CW_CHR_W     b'00001011'  ; 'W'
#define CW_CHR_X     b'00011001'  ; 'X'
#define CW_CHR_Y     b'00011011'  ; 'Y'
#define CW_CHR_Z     b'00011100'  ; 'Z'

#define CW_CHR_SEPAR b'00110001'  ; '='  (-...-)  this is the "official" separator
#define CW_CHR_SEPA2 b'01100001'  ; '-'  (-....-) but this is also frequenty used
#define CW_CHR_POINT b'01010101'  ; '.'  (-.-.-.)
#define CW_CHR_SLASH b'00110010'  ; '/'  (-..-.)
#define CW_CHR_?     b'01001100'  ; '?'  (..--..)
#define CW_CHR_AR    b'00101010'  ; 'AR' (.-.-.)
#define CW_CHR_SK    b'01000101'  ; 'SK' (...-.-)
#define CW_CHR_KA    b'00110101'  ; 'KA' (-.-.-)
#define CW_CHR_KN    b'00110110'  ; 'KN' (-.--.)
#define CW_CHR_EOM   b'01011111'  ; 'EOM' (.-----) used for "partitions" of msg
#define CW_CHR_NNN   b'01101010'  ; 'NNN' (-.-.-.) replaced by serial number
#define CW_CHR_ANN   b'01011010'  ; 'ANN' (.--.-.) advance to next number
#define CW_CHR_SPACE b'10000000'  ; ' ' (pause length in "dots" will be added)


;***** VARIABLE DEFINITIONS ****************************************
; EEPROM memory
#define  EEPROM_ADR_CW_SPEED   0x3F  ; EEPROM location for "speed"
#define  EEPROM_ADR_MSG1_START 0x3E  ; Start of recorded message
                                     ; (Index runs DOWN to zero)

; RAM memory (general purpose registers, PIC16F84: 0x0C..0x4F)
w_temp        EQU     0x0C        ; variable used for context saving 
status_temp   EQU     0x0D        ; variable used for context saving

; Keyer Variables
KY_state      EQU     0x0E        ; keyer state
CW_timing     EQU     0x0F        ; duration of a "dot" (for keyer+generator etc)
CW_t_cnt      EQU     0x10        ; CW (keyer-) timer
KY_mem_index  EQU     0x11        ; Keyer memory index for record + replay
KY_flags      EQU     0x12        ; Keyer flags... etc
#define  ky_dot       0           ; flag "dot in memory"   for squeezing
#define  ky_dash      1           ; flag "dash in memory"  for squeezing
#define  ky_recording 2           ; flag "keyer is recording into eeprom"
#define  ky_playing   3           ; flag "keyer is playing back from eeprom"
#define  ky_message2  4           ; flag "using message number 2" (in RAM)
#define  ky_msg_full  5           ; flag "message buffer full" (during record)
#define  ky_beep_cpl  6           ; flag "MessageBeep complete"
#define  ky_wait_cmd  7           ; flag "Waiting for command"

KY_char_latch    EQU  0x13        ; Buffer for decoding the SENT character
KY_decoded_char  EQU  0x14        ; output of the CW decoder (ready chars)
KY_count_elements EQU 0x15        ; Counter for dashes+dots in a character
KY_dot_counter   EQU  0x16        ; counts number of "dot times" for long delays
PT_counter       EQU  0x17        ; Poti-Scaler (counts main loops)

NoActivityTimer  EQU  0x18        ; timer for "no activity" detection
            ; (in "WAIT"-mode for power-down, 
            ;  in "endless-loop-replay" used to limit the max. repeat number,
            ;  and as "timeout" after message-buttons are pressed.
            ; )
 

OP_flags         EQU  0x19        ; option flags (saved in EEPROM)..
#define  op_dot_memory_off 0      ; flag "dot memory disabled"
#define  op_list_mode      1      ; flag "list mode", macro expansion disabled
#define  op_quick_digits   2      ; flag "use quick digits" when sending number
#define  op_loop_mode      3      ; flag "endless loop mode" when playing (almost)
#define  op_beacon_mode    4      ; flag "beacon mode" (endless TX loop without timeout)
#define NR_flags OP_flags
#define  nr_digit1         5      ; digit1 of "three-digit-number" sent/rcvd
#define  nr_digit2         6      ; digit2 of "three-digit-number" sent/rcvd
#define  nr_digit3         7      ; digit3 of "three-digit-number" sent/rcvd

NR_hundreds      EQU  0x1A        ; three-digit-number (unpacked BCD)
NR_tens          EQU  0x1B
NR_ones          EQU  0x1C

Msg2_Start       EQU  0x1D        ; start of message Nr. 2 (volatile!!)
Msg2_End         EQU  0x4F        ; end  of  message Nr. 2
RAM_MSG2_LENGTH  EQU  (Msg2_End - Msg2_Start + 1)

;**********************************************************************
; Initial contents of DATA EEPROM:
   org (H'213E'-14-16-16-4-9)  
   ; Initialize EEPROM Data with a small partitioned Test Message 
   ; (this is "Message #1", reverse address order!)
   ; Will be overwritten as soon as the user records his own message.
	de 0 ; termination with null byte

        ; 5th part of message#1: 14 byte    "ur rst 599/<serial number>"
        de CW_CHR_NNN,CW_CHR_SLASH
        de CW_CHR_SPACE+5,CW_CHR_N, CW_CHR_N, CW_CHR_5
        de CW_CHR_SPACE+5,CW_CHR_T,CW_CHR_S,CW_CHR_R
        de CW_CHR_SPACE+5,CW_CHR_R,CW_CHR_U
        de CW_CHR_EOM
 
        ; 4th part of message#1: 16 byte    "test de  dl4yhf .-.-."
        de CW_CHR_AR       
        de CW_CHR_F, CW_CHR_H, CW_CHR_Y
        de CW_CHR_4, CW_CHR_L, CW_CHR_D
        de CW_CHR_SPACE+8,CW_CHR_E,CW_CHR_D,CW_CHR_SPACE+5
        de CW_CHR_T, CW_CHR_S, CW_CHR_E, CW_CHR_T
        de CW_CHR_EOM
        
        ; 3rd part of message#1: 16 byte    "de dl4yhf pse  k"
        de CW_CHR_K
        de CW_CHR_SPACE+10
        de CW_CHR_E, CW_CHR_S, CW_CHR_P
        de CW_CHR_SPACE+5
        de CW_CHR_F, CW_CHR_H, CW_CHR_Y
        de CW_CHR_4, CW_CHR_L, CW_CHR_D
        de CW_CHR_SPACE+5                  
        de CW_CHR_E, CW_CHR_D
        de CW_CHR_EOM

        ; 2nd part of message#1: 4 byte     "73 <advance serial number>"
        de CW_CHR_ANN
        de CW_CHR_3,CW_CHR_7
        de CW_CHR_EOM
  
        ; 1st part of message#1: 9 byte     "ur nr <number> <number>"
        de CW_CHR_NNN, CW_CHR_SPACE+8
        de CW_CHR_NNN, CW_CHR_SPACE+8
        de CW_CHR_R, CW_CHR_N, CW_CHR_SPACE+5
        de CW_CHR_R, CW_CHR_U
        

   org  (H'2100'+EEPROM_ADR_CW_SPEED)  ; Initialize EEPROM Data
        de D'100' ; (initial CW-timing)



;**********************************************************************
  ORG     0x000             ; processor reset vector
        goto    reset             ; go to beginning of program




  ; the remaining bytes in page0 are used for computed gotos 
  ; and lookup tables so we dont have to mess around 
  ; with the ugly "pclath"-Register. See Microchips AppNote556 !

;=======================================================================
; Converts a decimal-digit(w) to morse code(w)
;  - must be located in "page 0" because of "computed goto"
;=======================================================================
DigitToMorse:
         andlw   d'15'                 ; a "modulo ten" would be too complicated
         addwf   PCL,F                 ; add digit value to  Program Counter(low)
         retlw   CW_CHR_0
         retlw   CW_CHR_1
         retlw   CW_CHR_2
         retlw   CW_CHR_3
         retlw   CW_CHR_4
         retlw   CW_CHR_5
         retlw   CW_CHR_6
         retlw   CW_CHR_7
         retlw   CW_CHR_8
         retlw   CW_CHR_9
         retlw   CW_CHR_A  ; may be used for hexadecimal conversions one fine day
         retlw   CW_CHR_B
         retlw   CW_CHR_C
         retlw   CW_CHR_D
         retlw   CW_CHR_E
         retlw   CW_CHR_F
 ; end of function DigitToMorse(w) 

DigitToMorse_Quick:
         andlw   d'15'                 ; a "modulo ten" would be too complicated
         addwf   PCL,F                 ; add digit value to  Program Counter(low)
         retlw   CW_CHR_T  ; 0 -> "-"
         retlw   CW_CHR_A  ; 1 -> ".-"
         retlw   CW_CHR_U  ; 2 -> "..-"
         retlw   CW_CHR_V  ; 3 -> "...-"
         retlw   CW_CHR_4  
         retlw   CW_CHR_5  ; 5 , some prefer "e" instead of "5", but I dont---
         retlw   CW_CHR_6
         retlw   CW_CHR_7  ; 7 , sometimes "D" instead of "7"... not logical!
         retlw   CW_CHR_8  ; 8 , sometimes "B" instead of "8"
         retlw   CW_CHR_N  ; 9 is very common, so we used it here
         retlw   CW_CHR_?  ; this is stupid, but the only "safe" way..
         retlw   CW_CHR_?
         retlw   CW_CHR_?
         retlw   CW_CHR_?
         retlw   CW_CHR_?
         retlw   CW_CHR_?
 ; end of function DigitToMorse_Quick(w) 


;=======================================================================
; Main Loop   
;  The execution time of this loop must be CONSTANT
;  as long as the CW sidetone is generated.
;  This allows to use the "main loop" as a "timebase" 
;  without using the timer (the timer may be used for future things..)
;=======================================================================
main_loop:       ; Main loop while no CW sidetone has to be generated.
                 ; Here some "asynchronous" actions may be performed.
                 ; The average "main_loop" takes 4 cycles more
                 ; than the "main_loop_sync". 
                 ; The keyer state machine takes care of this !!!

;=======================================================================
; Check if its time to read the "quasi-analog/digital-converter"
;=======================================================================
        decfsz  PT_counter,F      ;01 divide main loop interval..
        goto    no_poti           ;02
        movlw   d'100'            ; number of intervals until next poti reading
        movwf   PT_counter        ; (d'100' = roughly 500ms using 32.768kHz xtal)
        call    ReadPoti          ; don't waste too much "page0" memory here
        movwf   CW_timing         ; save "return"-value as new CW-timing
no_poti:                          ;04 (if no poti reading is taken)

main_loop_sync:  ; main loop while CW sidetone "on"


;=======================================================================
; Check if any "message"-button is pressed
;=======================================================================
         btfss   IOP_KEY_MSG1     ; "Message1"-Button pressed ?
         goto    msg1_pressed
         btfss   IOP_KEY_MSG2     ; "Message2"-Button pressed ?
         goto    msg2_pressed
no_button:

        ; at the end of the "main loop": the "keyer state machine"..

;=======================================================================
; Keyer-Task
;=======================================================================
;
; States for the keyer state machine:
;  many actions in that do "logically" belong together are split
;  into squences of "substates"
;  to keep the execution time of the keyer task as short as possible.
;  Otherwise the generation of the sidetone would be impossible
;  with a 32kHz crystal.

; state sequence for WAITING and switching into SLEEP mode

#define KYS_PREPARE_WAIT      0  ; waiting for anything to happen...
#define KYS_WAITING           1  ; ... with "no-activity"-detection

; state sequence for sending a DOT :
#define KYS_SEND_DOT          2  ; sending a dot
#define KYS_WAIT_DOT_PAUSE    3  ; wait for pause after dot

; state sequence for sending a DASH:
#define KYS_SEND_DASH         4  ; sending a dash, 1st dot time
#define KYS_SEND_DASH2        5  ; sending a dash, 2nd dot time
#define KYS_SEND_DASH3        6  ; sending a dash, 3rd dot time
#define KYS_START_DASH_PAUSE  7  ; prepare next state..
#define KYS_WAIT_DASH_PAUSE   8  ; wait for pause after dash

; state sequence for waiting, detecting and recording characters and spaces
#define KYS_WAIT_LESS_1DOT    9  ; waiting for less than 1 dot times
#define KYS_WAIT_LESS_5DOTS   d'10' ; waiting for less than 5 dot times, phase 1
#define KYS_WAIT_LESS_5DOTS2  d'11' ; waiting for less than 5 dot times, phase 2
#define KYS_WAIT_LESS_5DOTS3  d'12' ; waiting for less than 5 dot times, phase 3
#define KYS_SPACE_WAIT_DOT    d'13' ; wait for one dot time 
#define KYS_SPACE_INCR_DOTS   d'14' ; counts up to n "space-dot-times"

; state sequence for Keyer-Replay 
#define KYS_PLAY_GET_NEXT_CHAR d'15' ; read next letter of stored message + analyze
#define KYS_PLAY_WAIT_SPACE    d'16' ; wait for a "space" time between WORDS
#define KYS_PLAY_WAIT_DASH     d'17' ; WAIT for end of DASH, 1st phase
#define KYS_PLAY_WAIT_DASH2    d'18' ;  "    "   "  "   "  , 2nd phase
#define KYS_PLAY_WAIT_DOT      d'19' ; WAIT for end of DOT or 3rd phase of DASH
#define KYS_PLAY_START_PAUSE1  d'20' ; switch to "one-dot-pause"    = WAIT_DOT+1
#define KYS_PLAY_WAIT_PAUSE1   d'21' ; WAIT for "one-dot-pause"
#define KYS_PLAY_WAIT_PAUSE2   d'22' ; WAIT for "two-dot-pause", 1st phase
#define KYS_PLAY_WAIT_PAUSE22  d'23' ; WAIT for "two-dot-pause", 2nd phase
#define KYS_PLAY_CHECK_END_MSG d'24' ; check if more letters follow = WAIT_PAUSE22+1

; "very special" states:
#define KYS_TUNE               d'25' ; "tuning" (continuous carrier)

KeyerTask: ;------- implementation of "elbug state machine" ----------------
        bcf     IOP_AUDIO_OUT        ;01 sidetone LOW        
        movf    KY_state, W          ;02 load current "machine state"
        ; the next instruction is a good place to set a breakpoint... "click it right!"
        addwf   PCL,F                ;03 add state to low byte of Program Counter
 
        ; default state, may prepare to start "power down"-timer
        goto  kyt_prepare_wait       ;05 load timer for "no activity"-timeout
        goto  kyt_waiting            ;05 waiting for more than 5 dots   

        ; state sequence for sending a DOT :
        goto  kyt_send_dot           ;05 sending a dot
        goto  kyt_wait_dot_pause     ;05 wait for pause after a dot

        ; state sequence for sending a DASH:
        goto  kyt_send_dash          ;05 sending a dash (1st dot time)
        goto  kyt_send_dash          ;05 sending a dash (2nd dot time)
        goto  kyt_send_dash          ;05 sending a dash (3rd dot time)
        goto  kyt_start_dash_pause   ;05    prepare next state..
        goto  kyt_wait_dash_pause    ;05 wait for pause after sending a dash

        ; state sequence for WAIT phases with no paddle closed
        ; (required for the CW TX decoder:)
        goto  kyt_wait_less_1dot     ;05 waiting for less than 1 dot time
        goto  kyt_wait_less_5dots    ;05 waiting for less than 5 dot times, phase 1
        goto  kyt_wait_less_5dots2   ;05 waiting for less than 5 dot times, phase 2
        goto  kyt_wait_less_5dots3   ;05 waiting for less than 5 dot times, phase 3
        goto  kyt_space_wait_dot     ;05 wait for one dot time 
        goto  kyt_space_incr_dots    ;05 count up to 15 "space-dot-times"

        ; state sequence for Keyer-Replay 
        goto  kyt_play_get_next_char ;05 read next char from message and analyze it
        goto  kyt_play_wait_space    ;05 wait until end of a "long pause" between WORDs
        goto  kyt_play_wait_elem     ;05 WAIT for end of played DASH,  1st phase
        goto  kyt_play_wait_elem     ;05 WAIT for end of played DASH,  2nd phase
        goto  kyt_play_wait_elem     ;05 WAIT for end of played DOT or 3rd phase of DASH
        goto  kyt_play_start_pause1  ;05 start "one-dot-pause" between dashes and dots
        goto  kyt_play_wait_pause1   ;05 WAIT for "one-dot-pause"
        goto  kyt_play_wait_pause2   ;05 WAIT for "two-dot-pause" between letters (add'l)
        goto  kyt_play_wait_pause2   ;05  "    "   "   "   , 2nd phase, same code
        goto  kyt_play_check_end_msg ;05 check if message over or more letters follow

        ; "very special" states:
        goto  kyt_tune               ;05 "tuning" (continuous carrier)


end_of_page0: ; THIS LABEL MUST STILL BE IN PAGE0, OTHERWISE COMPUTED GOTOs FAIL
#if (end_of_page0 > 0xFF)
 error "Shit. Computed jumps are outside of page0."
#endif

;============================================================================
; Implementation of the KEYER-states
;============================================================================
; The state-Labels are jumped to via "computed goto" from Page0.
;   "synchroneous" states require a constant main-loop-delay
;                 because of the sidetone-generation.
;   "asynchroneous" states can tolerate a little "jitter".
;                 They allow the main loop to perform other tasks.
; 

kyt_prepare_wait: ;----------------------------------------------------------
         movlw   1                     ; prepare detection of next letter..
         movwf   KY_char_latch         ; ..with "start bit" in position 0
         clrf    NoActivityTimer       ; reload "No Actvity"-Timer
         btfss   IOP_DASH              ; dash-paddle closed:
         goto    kyt_start_dash        ; start keying a "dash"
         btfss   IOP_DOT               ; dot-paddle closed:
         goto    kyt_start_dot         ; start keying a "dot"
         movlw   KYS_WAITING           ; next state = "WAITING"
         movwf   KY_state              ; store new state
         bcf     IOP_TX_CONTROL        ; Transmitter OFF,  Receiver ON.
          ; because there is no paddle touched, this is a good time
          ;   to check some error flags and generate warning signals if needed:
         call    WarningSignals
         goto    main_loop             ; end task, extremely "async"     


kyt_waiting:   ;======= main "waiting" state ==========================
        ; - waits for "anything" to happen.
        ; - enters sleep mode after long time of "No Activity".
        ; - tests both paddles and starts "dash" or "dot" if pressed.
        movlw   KYS_WAITING             ;07 default: remain "waiting"
        btfss   IOP_DASH                ;08 dash-paddle closed:
        goto    kyt_start_dash          ;09 start keying a "dash"
        btfss   IOP_DOT                 ;10 dot-paddle closed:
        goto    kyt_start_dot           ;11 start keying a "dot"
        movwf   KY_state                ;12 store new(?) state
        decfsz  NoActivityTimer,F       ;13 "Nothing happened" for a long time ?
        goto    main_loop               ;14 no: end task, asynchronous
        ; Enter SLEEP mode after a long time of no activity:
        call    PowerDown              ; supply current about 1uA
        goto    kyt_prepare_wait       ; resume normal operation.

kyt_start_dot: ; start sending a DOT
         bsf     IOP_TX_CONTROL        ; transmitter on, receiver off
         movf    CW_timing,w           ; load timer w. dot time
         movwf   CW_t_cnt              ;
         movlw   KYS_SEND_DOT          ; new state
         movwf   KY_state              ; 
         bsf     IOP_KEY_OUTPUT        ; carrier on (Dot)
main_loop_sync12:
         nop                           ;14 
         goto    main_loop_sync        ;15 end task, synchron

kyt_send_dot:  ;======== send dot (WAIT) =====================
         btfss   IOP_DASH              ;07 check DASH-contact
         bsf     KY_flags, ky_dash     ;08 .. save in "dash memory"
         bsf     IOP_AUDIO_OUT         ;09 sidetone HIGH (at t=09!)
         bsf     IOP_KEY_OUTPUT        ;10 carrier on (Dot)
         decfsz  CW_t_cnt,F            ;11 decrement, Timer still running?
         goto    main_loop_sync12      ;12 yes -> end task, synchron
         ;   else: "start pause after dot"...
	 bcf     IOP_KEY_OUTPUT        ; carrier off (TX remains "on")
         movlw   KYS_WAIT_DOT_PAUSE    ; load new state
         movwf   KY_state              ;  
         movf    CW_timing,w           ; set pause-time
         movwf   CW_t_cnt              ;  
         rlf     KY_char_latch,f       ; shift the SENT letter left
         bcf     KY_char_latch,7       ; never shift a "1" into MSB
         bcf     KY_char_latch,0       ; LSB=0 means "append DOT"
         ;  continue with "wait_dot_pause"...

kyt_wait_dot_pause: ;====== pause after dot  (WAIT) ========
         ; (register DASHES during this time !)
         bcf     IOP_KEY_OUTPUT        ;07 carrier off
         btfss   IOP_DASH              ;08 check "dash" contact
         bsf     KY_flags, ky_dash     ;09 store "dash" in memory
         decfsz  CW_t_cnt,F            ;10 decrement, Timer still running?
         goto    main_loop             ;11 yes -> end task, async
         ; else "waiting for the pause after dot" is over,
         ; check if there is a DASH in memory:
         ; if yes, start sending a dash;
         ; else wait until "end-of-letter" has been detected.
         bcf     KY_flags,ky_dot       ;   erase "dot" from memory
         btfsc   OP_flags,op_dot_memory_off ; for "old style keyer" :
         bcf     KY_flags,ky_dash      ;   erase "dash" from memory, too
         btfsc   KY_flags, ky_dash     ;   "dash" in memory ?
         goto    kyt_start_dash        ;   yes, "start dash"
         ; required for "squeezing" without dash/dot - memory ("old style"):
         btfss   IOP_DASH              ;   "dash" currently pressed ?
         goto    kyt_start_dash        ;   yes, "start dash"
         goto    kyt_prepare_wait_1dot ;   default: prepare to wait..

  ;
  ; sequence when keying a DASH:
  ;  
kyt_start_dash: ; start DASH
        bsf     IOP_TX_CONTROL          ; transmitter on, receiver off
        movf    CW_timing,w             ; load timer w. dash time
        movwf   CW_t_cnt                ; (for 1st 1/3 phase)
	movlw   KYS_SEND_DASH           ; new state "Send Dash"
        movwf   KY_state
        bsf     IOP_KEY_OUTPUT          ; carrier on (Dash)
        ; continue with "send_dash"...    

kyt_send_dash:  ;======== send DASH (WAIT, 3 phases) ==========
        ; and register DOTS in memory while waiting
        btfss   IOP_DOT                 ;07 check DOT-input
        bsf     KY_flags, ky_dot        ;08 save DOT in memory
        bsf     IOP_AUDIO_OUT           ;09 sidetone HIGH (at t=09!)
        decfsz  CW_t_cnt,F              ;10 decrement, Timer still running?
        goto    kyt_send_dash2          ;11 yes, stay in this state & phase.
        incf    KY_state,F              ;12 no, next state (or 1/3 dash time)
        movf    CW_timing,w             ;13 (kyt_send_dash has "3 phases"!)
        movwf   CW_t_cnt                ;14 start timer for next 1/3 dash 
        goto    main_loop_sync          ;15 end task, synchron
kyt_send_dash2:
        nop                             ;13 remain in "this" state.
        nop                             ;14
        goto    main_loop_sync          ;15 end task, synchron


kyt_start_dash_pause: ;---start pause after DASH (switching state)---
	bcf     IOP_KEY_OUTPUT          ;07 carrier off (after Dash) 
        movlw   KYS_WAIT_DASH_PAUSE     ;08 load new state
        movwf   KY_state                ;09
        movf    CW_timing,w             ;10 setzten "pause" time
        movwf   CW_t_cnt                ;11
        rlf     KY_char_latch,f         ;12 shift the SENT letter left
        bcf     KY_char_latch,7         ;13 never shift a "1" into MSB
        bsf     KY_char_latch,0         ;14 LSB=1 means "append DASH"
        goto    main_loop               ;15 end task, async

kyt_wait_dash_pause: ;====== pause after dash (WAIT) =======
        ; and register DOTS while waiting
        bcf     IOP_KEY_OUTPUT          ;07 carrier off
        btfss   IOP_DOT                 ;08 check "dot" contact
        bsf     KY_flags, ky_dot        ;09 store "dot" in memory
        decfsz  CW_t_cnt,F              ;10 dekrement, Timer still running?
        goto    main_loop               ;11 yes -> end task, async
        ; else "waiting for the pause after dash" is over,
        ; check if there is a DOT in memory:
        ; if yes, start sending a dot;
        ; else wait until "end-of-letter" has been detected.
        bcf     KY_flags,ky_dash        ;   erase "dash" from memory
        btfsc   OP_flags,op_dot_memory_off ; for "old style keyer":
        bcf     KY_flags,ky_dot         ;   erase "dot" from memory, too
        btfsc   KY_flags, ky_dot        ;   "dot" in memory ?
        goto    kyt_start_dot           ;   yes, "start dot"
        btfss   IOP_DOT                 ;   "dot" currently pressed ?
        goto    kyt_start_dot           ;   yes, "start dot"
                                        ;   else prepare to wait..
kyt_prepare_wait_1dot:  ; prepare waiting for 1 dot time 
        ; (if less than 2 dots "total" pause, the "current" letter continues)
        movf    CW_timing,w             ;   load timer with one dot time
	movwf   CW_t_cnt                ;   ... as "threshold" for new char.
        movlw   KYS_WAIT_LESS_1DOT      ;   next "WAITING" state
        movwf   KY_state                ;   store new state
        ; continue with "wait_less_1dot"


 ;
 ; states for WAIT phases with no paddle closed
 ; (required for the CW TX decoder, 
 ;  ONE dot-time pause has already passed)
 ;

kyt_wait_less_1dot:  ;====== WAIT for less than 1 dot time ================
        ; A new letter is detected after a TOTAL pause of 2 dot-times has expired.
        ; The old letter continues if time not expired and any paddle pressed.
        ; Note: one "dot-time" pause is already over 
        ;       since the end of last DASH or DOT!
         btfss   IOP_DASH              ;07 dash-paddle closed:
         goto    kyt_start_dash        ;08 start keying a "dash"
         btfss   IOP_DOT               ;09 dot-paddle closed:
         goto    kyt_start_dot         ;10 start keying a "dot"
         decfsz  CW_t_cnt,F            ;11 dekrement, Timer still running?
         goto    main_loop             ;12 yes -> end task, async
         ; else:  new char detected after 2 dots 
         ;        since the end of the last DOT or DASH.
         bcf     IOP_TX_CONTROL        ; Transmitter OFF,  Receiver ON.
         ; The decoded char is appended to the message memory,
         ; if "recording" is active.
         movlw   KYS_WAIT_LESS_5DOTS   ; next "WAITING" state
         movwf   KY_state              ; store new state
         movf    CW_timing,w           ; load timer w. 1 dot time
	 movwf   CW_t_cnt              ; will be used in "wait_less_5dots"
         movf    KY_char_latch,w       ; load decoded letter
         movwf   KY_decoded_char       ; ..into the decoder output "latch"
         btfsc   KY_flags,ky_wait_cmd  ; "waiting for command" ?
         goto    CommandDispatcher     ; yes, handle input char as "command"
         btfsc   KY_flags,ky_recording ; is "RECORDING" active ?
kyt_append: call AppendToMessage       ; save (w) in buffer[KY_mem_index--]
         call    WarningSignals        ; generate warnings signals (?)
         movlw   1                     ; prepare detection of next letter..
         movwf   KY_char_latch         ; ..with "start bit" in position 0
         goto    main_loop             ; no, all ok, end task

kyt_wait_less_5dots:   ;====== WAIT less than 5 dot times (1st phase) ======
        ; This "3 dot waiting state" is split into three phases
        ; to avoid the calculation of "3 times CW_timing".
        ; It is necessary to detect SPACES between WORDS.
        movlw   KYS_WAIT_LESS_5DOTS2    ;07 next WAITING phase
        btfss   IOP_DOT                 ;08 dot-paddle closed:
        goto    kyt_start_dot           ;09 no space, start keying a "dot"
        movwf   KY_state                ;10 store new(?) state
        goto    main_loop               ;11 end task, "async", timing ok.
        ; The exit to "main_loop" should be at t=11, 
        ; because exiting to "main_loop" takes 4 cycles more
        ;    than exiting to "main_loop_sync".

kyt_wait_less_5dots2:  ;====== WAIT less than 5 dot times (2nd phase) =======
        movlw   KYS_WAIT_LESS_5DOTS3    ;07 next WAITING phase
        btfss   IOP_DASH                ;08 dash-paddle closed:
        goto    kyt_start_dash          ;09 no space, start keying a "dash"
        movwf   KY_state                ;10 store new(?) state
        goto    main_loop               ;11 end task, async

kyt_wait_less_5dots3:  ;====== WAIT less than 5 dot times (3rd phase) =======
        movlw   KYS_WAIT_LESS_5DOTS     ;07 keep state, 1st phase
        movwf   KY_state                ;08 store new(?) state
        decfsz  CW_t_cnt,F              ;09 dekrement, Timer still running?
        goto    main_loop               ;10 yes, end task, async
        ;  5 dots over: measure length of WORD separation...
        ;  (in "dot times") and emit one of the 31 possible "space"
        ;  characters. 
        movlw   H'82'                   ; prepare "SPACE" code with 2 dots...
        movwf   KY_char_latch           ; because of replay-task !
        btfss   KY_flags,ky_recording   ; is "RECORDING" active ?
        goto    kyt_prepare_wait        ; no, don't count SPACE length
        movf    CW_timing,w             ; load timer with dot time..
	movwf   CW_t_cnt                ;   ... as "timebase" for next state
        movlw   D'60'                   ; set "maximum pause length"...
        movwf   KY_dot_counter          ;   ... measured in "dot-times"
        movlw   KYS_SPACE_WAIT_DOT      ; next state 
        movwf   KY_state                ;  
        ;  continue with "space_wait_dot"

kyt_space_wait_dot:    ;======= WAIT for one dot time ==================
        ; (inner loop for measuring the length of a pause between WORDs)
        ; Exit from this state if paddle touched
        ;                      or "dot timer" runs off.
        ; In both "Exit"-cases a "SPACE"-code is appended to the message
        btfss   IOP_DASH                ;07 dash-paddle closed:
        goto    kyt_space_save          ;08 end of pause, save!
        btfss   IOP_DOT                 ;09 dot-paddle closed:
        goto    kyt_space_save          ;10 end of pause, save!
        decfsz  CW_t_cnt,F              ;11 dekrement, Timer still running?
        goto    main_loop               ;12 still runs   -> keep state!
        incf    KY_state,F              ;13 dot time over-> SPACE_INCR_DOTS
        goto    main_loop               ;14 end task, async
        
kyt_space_incr_dots:   ;======= count "space-dot-times" ================
        ; (outer loop for measuring the length of a pause between WORDs)
        ; Exit from this loop, if the "maximum acceptable time" for
        ; a pause between WORDs is exceeded.
        movf    CW_timing,w             ;07 load timer with dot time..
	movwf   CW_t_cnt                ;08 ... for next "SPACE_WAIT_DOT".
        movlw   KYS_SPACE_WAIT_DOT      ;09 next state: "continue waiting"
        movwf   KY_state                ;10 
        incf    KY_char_latch,F         ;11 increment SPACE code (max. 60 counts)
        decfsz  KY_dot_counter,F        ;12 "maximum acceptable pause" exceeded?
        goto    main_loop               ;13 not exceeded -> "SPACE_WAIT_DOT"
        ; else: "maximum pause exceeded" -> 
kyt_space_save: ; append "SPACE" character to message 
        ; (the "space code" is appended to the the recorded message string,
        ;  if there is enough EEPROM memory left.)
        movlw   KYS_PREPARE_WAIT        ;14 next "WAITING" state
        movwf   KY_state                ;15 store new state
        movf    KY_char_latch,w         ;16 load "pause" code... 
        goto    kyt_append              ;17 ..and append to message buffer
;======= end of CW DECODER states ============================================



;======= states for Keyer-Replay  ============================================


kyt_play_get_next_char: ;-----------------------------------------------------
   ; Reads the next letter for REPLAY from the current message buffer,
   ;  and analyzes code:
   ; Check if its a "space" or "control character" (bit7=1)
   ;              or a "transmittable letter"      (bit7=0)
   ; Also check if the end of the message is reached   (code=0)
kyt_play_next2:
         call    ReadFromMessage       ; read byte(w) from message[KY_mem_index--]
         movwf   KY_char_latch         ; store in tx-"shift register"
         btfss   KY_char_latch,7       ; bit7  is space/control flag
         goto    kyt_play_normal_letter; bit7=0, start "normal" letter
         bcf     KY_char_latch,7       ; reset space/control flag
         btfss   KY_char_latch,6       ; bit6 of letter is control flag
         goto    kyt_play_pause        ; bit6=0, start "pause" time
         bcf     KY_char_latch,6       ; 6-bit-"control code" remains..
kyt_play_control_code:  ; analyze 6-bit "control" code (not implemented)
         goto    kyt_play_check_end_msg; continue with next letter

kyt_ns:  movwf   KY_state              ; set new state   
         goto    main_loop             ; end task, extremely "async"

kyt_play_pause:         ; analyze 6-bit "pause" code (variable length)
         bcf     IOP_TX_CONTROL        ; Transmitter OFF,  Receiver ON.
         movf    CW_timing,w           ; load timer w. dot time.. 
         movwf   CW_t_cnt              ; ..to prepare "PLAY_WAIT_SPACE"
         movf    KY_char_latch,w       ; load bits0..5 of pause code..
         movwf   KY_dot_counter        ; into "dot counter" for pause
         movlw   KYS_PLAY_WAIT_SPACE   ; next state
         goto    kyt_ns                ; set state, end task.
kyt_play_normal_letter: ; analyze 7-bit "letter" code (maybe zero-byte)
         bsf     IOP_TX_CONTROL        ; Transmitter ON,  Receiver OFF.

         ;-- Is the letter a zero-byte (end-of-string) ?
         movf   KY_char_latch,f        ; set "ZERO" flag if zero byte.
         btfsc  STATUS,Z               ; skip next instruction if NOT ZERO
         goto   kyt_play_chk_loop      ; no zero byte...

        ;--- no "control" but a "possibly transmittable" letter or "macro":
         btfsc  OP_flags,op_list_mode   ; in "list mode"...
         goto   kyt_play_init_char      ; ...no "special chars" are analyzed
        ;-- Is the letter an EOM-code (end-of-messagem, end partition) ?
         movlw  CW_CHR_EOM
         subwf  KY_char_latch,w      
         btfsc  STATUS,Z
         goto   kyt_play_chk_loop
        ;-- Is the letter a "play 3-digit-number" instruction ?
         movlw  CW_CHR_NNN
         subwf  KY_char_latch,w      
         btfsc  STATUS,Z
         goto   kyt_play_digit1
        ;-- Is the letter an "increment contest number"-command ?
         movlw  CW_CHR_ANN
         subwf  KY_char_latch,w      
         btfsc  STATUS,Z
         goto   kyt_play_inc_nnn
         goto   kyt_play_init_char         

kyt_play_next_loop:  ; at the end of a recorded message:
         btfss   KY_flags,ky_message2    ; playing loop from message #1 or #2 ?
         movlw   EEPROM_ADR_MSG1_START   ; #1: Startindex in message-EEPROM
         btfsc   KY_flags,ky_message2    ; else..
         movlw   RAM_MSG2_LENGTH-1       ; #2: Startindex in message-RAM
         movwf   KY_mem_index            ; this index will be DECREMENTED!
         goto    main_loop               ; end task, async.

kyt_play_chk_loop: ; check if "endless loop" is active;  if not, stop playing.
         btfss  OP_flags, op_loop_mode  ; Is "LOOP MODE" active ?
         goto   kyt_play_beacon         ; no, check "beacon mode", then stop.
         decfsz NoActivityTimer,F       ; limit the number of replay loops
         goto   kyt_play_next_loop      ; play again from start of 1st partition
kyt_play_beacon:   ; check if "BEACON MODE" is active ?
         btfss  OP_flags,op_beacon_mode ; Is "BEACON MODE" active ?
         goto   kyt_play_stop           ; no, stop playing.
         goto   kyt_play_next_loop      ; play again from start of 1st partition
kyt_play_stop:     ; stored message is over (end-of-string, end-of-message):
         bcf    KY_flags, ky_playing    ; reset "playing"-Flag
         goto   kyt_prepare_wait        ; enter "main waiting"-state

kyt_play_inc_nnn: ; increment the "contest number" (non-transmitting char!)
         call   IncrementNumber
         goto   kyt_play_check_end_msg  ; next state: get next char from buffer
kyt_play_digit1: ; prepare playing 1st digit of a 3-digit-number
         bsf    NR_flags,nr_digit1      ; "1st digit of three-digit-number"
         movf   NR_hundreds,w           ; load most significant digit
kyt_play_init_digit:
         btfss  OP_flags,op_quick_digits
         call   DigitToMorse            ; convert digit(w) to morse code(w)
         btfsc  OP_flags,op_quick_digits
         call   DigitToMorse_Quick      ; ... optionally use "quick" digits
         movwf  KY_char_latch           ; store in tx-"shift register"
                ; continue with "kyt_play_init_char"..
kyt_play_init_char:  
   ; prepare transmission of next letter (in KY_char_latch):
   ; shift left until "start bit" is in LSB
   ; and count the number of dots and dashes in the letter.
        movlw   6                       ; load number of dots+dashes
        movwf   KY_count_elements       ; ..into "element counter"
        btfsc   KY_char_latch,6         ; is it 6-element-char ?
	goto    kyt_play_init6          ; else..
	btfsc   KY_char_latch,5         ; is it 5-element-char ?
	goto    kyt_play_init5          ; else..
	btfsc   KY_char_latch,4         ; is it 4-element-char ?
	goto    kyt_play_init4          ; else..
	btfsc   KY_char_latch,3         ; is it 3-element-char ?
	goto    kyt_play_init3          ; else..
	btfsc   KY_char_latch,2         ; is it 2-element-char ?
	goto    kyt_play_init2          ; else must be 1-element-char
kyt_play_init1: ; only 1-element-char, shift bit 0 into bit 5
        decf    KY_count_elements,F
        rlf     KY_char_latch,F
kyt_play_init2: ; 2-element-char, shift bit 1 into bit 5
        decf    KY_count_elements,F
	rlf     KY_char_latch,F
kyt_play_init3: ; 3-element-char, shift bit 2 into bit 5
        decf    KY_count_elements,F
	rlf     KY_char_latch,F
kyt_play_init4: ; 4-element-char, shift bit 3 into bit 5
        decf    KY_count_elements,F
	rlf     KY_char_latch,F
kyt_play_init5: ; 5-element-char, shift bit 4 into bit 5
        decf    KY_count_elements,F
	rlf     KY_char_latch,F
kyt_play_init6: ; 6-element-char, dont shift, dont decrement
        ; continue with "kyt_play_next_elem"

kyt_play_next_elem:
        ; check if next element is a DASH or a DOT, 
        ; load timer with single or triple dot time.
        movf    CW_timing,w             ; time for a DOT...
	movwf   CW_t_cnt                ; will be tripled BY STATE MACHINE
	movlw   KYS_PLAY_WAIT_DOT       ; state for waiting a DOT
	btfsc   KY_char_latch,5         ; is next element DOT(0) or DASH(1) ?
	movlw   KYS_PLAY_WAIT_DASH      ;  it's  DASH..
        movwf   KY_state                ; set next state
        goto    main_loop               ; end task, async
   ; end of "PLAY_GET_NEXT_CHAR" (and label for "next element").



kyt_play_wait_space:  ;----- WAIT for "space" between WORDS ------------
        ; This state waits for a variable time (KY_dot_count)
        ; between two WORDs when playing a stored message.
        btfss   IOP_DASH                ;07 dash-paddle closed:
        goto    kyt_play_stop           ;08 stop replay
        btfss   IOP_DOT                 ;09 dot-paddle closed:
        goto    kyt_play_stop           ;10 stop replay
        decfsz  CW_t_cnt,F              ;11 next "dot-time" over ?
        goto    main_loop               ;12 no: keep "waiting", end task, async
        movf    CW_timing,w             ;13 yes: reload timer w. dot time..
	movwf   CW_t_cnt                ;14   .. for next "dot-time" loop
        decfsz  KY_dot_counter,F        ;15 Whole "pause" between WORDS over ?
        goto    main_loop               ;16   no, wait for next "dot-time"
        goto    kyt_play_check_end_msg  ;17   yes, continue with next letter
   ; end of keyer state "PLAY_WAIT_SPACE" (gap between WORDS)


kyt_play_wait_elem:   ;---- Wait for end of played DASH or DOT ----
        ; this "state" has been split into 3 "phases"
        ; to get a total "waiting" time of 3 dot lengths
        ; which is the "additional pause" between two WORDS.
        ; The corresponding states are:
	;   KYS_PLAY_WAIT_DASH, KYS_PLAY_WAIT_DASH2, KYS_PLAY_WAIT_DOT.
        ; By incrementing the state number, 
        ;  also KYS_PLAY_START_PAUSE1 will be entered "automatically".
        bsf     IOP_KEY_OUTPUT          ;07 carrier on
        nop                             ;08
        bsf     IOP_AUDIO_OUT           ;09 sidetone HIGH (at t=09!)
        decfsz  CW_t_cnt,F              ;10 decrement, Timer still running?
        goto    kyt_play_el_continue    ;11 yes, stay in this state.
        incf    KY_state,F              ;12 no, next state (or 1/3 dash time)
        movf    CW_timing,w             ;13 (this "state" has "3 phases"!)
        movwf   CW_t_cnt                ;14 start timer for next dot-time
        goto    main_loop_sync          ;15 end task, synchron
kyt_play_el_continue:
        nop                             ;13 remain in "this" state.
        nop                             ;14
        goto    main_loop_sync          ;15 end task, synchron

kyt_play_start_pause1: ;---- switching state to enter "pause" -----
        ; Starts "one-dot-pause" between dahes+dots in one letter.
        ; This state is entered after INCREMENTING KYS_PLAY_WAIT_DOT.
        bcf     IOP_KEY_OUTPUT          ; carrier off
	movf    CW_timing,w             ; pause_time := 1 dot
	movwf   CW_t_cnt
	movlw   KYS_PLAY_WAIT_PAUSE1    ; new state = "one dot pause"
	movwf   KY_state
	goto    main_loop               ; end task, async

kyt_play_wait_pause1:  ;----- WAIT for "one-dot-pause" ------------------
        ; WAITS for pause between "elements" (DASHES or DOTS) in a letter
        ; and checks if "playing" is cancelled by the paddle contacts.
        bcf     IOP_KEY_OUTPUT          ;07 carrier off
        btfss   IOP_DASH                ;08 dash-paddle closed:
        goto    kyt_play_stop           ;09 stop replay
        btfss   IOP_DOT                 ;10 dot-paddle closed:
        goto    kyt_play_stop           ;11 stop replay
        nop                             ;12
        decfsz  CW_t_cnt,F              ;13 dekrement, Timer still running?
        goto    main_loop_sync          ;14 end task, synchron
        ; pause between elements IN ONE letter is over:
        ;  check if more dashes or dots follow in this letter.
        decfsz  KY_count_elements,F     ; Is this the last "element" ?
        goto    kyt_play_ltr_continues  ; no, letter continues.
        ; no more dashes or dots in "this" letter:
        ; start an additional pause of TWO dots
        ; (this gives a total pause of THREE dots)
	movf    CW_timing,w             ; additional pause_time will be..
	movwf   CW_t_cnt                ;  ..doubled in next state
        movlw   KYS_PLAY_WAIT_PAUSE2    ; new state: wait 2 dot times
        goto    kyt_ns                  ; set new state, end task, async
kyt_play_ltr_continues:
        ; more dashes or dots in "this" letter left...
	rlf     KY_char_latch,F         ; shift letter one bit left
        goto    kyt_play_next_elem      ; play next element of letter
        
kyt_play_wait_pause2:  ;----- WAIT for "two-dot-pause" ------------------
        ; WAITS for additional pause between two letters.
        decfsz  CW_t_cnt,F              ;07 dekrement, Timer still running?
        goto    kyt_play_wait_continues ;08 yes, stay in this state+phase
        incf    KY_state,F              ;09 no, next state (or phase)
        movf    CW_timing,w             ;10 (this "state" has "2 phases"!)
        movwf   CW_t_cnt                ;11 start timer for next dot-time
        goto    main_loop               ;12 end task, async
kyt_play_wait_continues:
        btfss   IOP_DASH                ;10 dash-paddle closed:
        goto    kyt_play_stop           ;11 stop replay
        btfss   IOP_DOT                 ;12 dot-paddle closed:
        goto    kyt_play_stop           ;13 stop replay
        goto    main_loop               ;14 end task, async

kyt_play_check_end_msg: ;---- Check "End of played Message" ------------
   ; First check if transmission of a "three-digit-number" is still in progress.
   ; If so, send the "next" digit of this number.
   ; This state may be entered by incrementing "KY_state" above "WAIT_PAUSE22"
         btfss  NR_flags,nr_digit1      ; 1st digit of three-digit-number sent?
         goto   kyt_play_nd1
         bcf    NR_flags,nr_digit1      ; 1st digit done...
         bsf    NR_flags,nr_digit2      ; now sending 2nd digit.
         movf   NR_tens,w               ; load "tens"
         goto   kyt_play_init_digit     ; convert to morse code & transmit
kyt_play_nd1:
         btfss  NR_flags,nr_digit2      ; 2nd digit of three-digit-number sent?
         goto   kyt_play_nd2
         bcf    NR_flags,nr_digit2      ; 2nd digit done...
         movf   NR_ones,w               ; load "ones"
         goto   kyt_play_init_digit     ; convert to morse code & transmit
kyt_play_nd2:   ; else: no "number"-transmission in progress...
         ; Check if there are more letters to be sent.
         ; Maybe "ReadFromMessage" has cleared the "playing"-flag.
         btfss   KY_flags,ky_playing    ; "playing message" still active ?
         goto    kyt_play_chk_loop      ; no -> stop play if no "endless loop"
         movlw   KYS_PLAY_GET_NEXT_CHAR ; new state if playing still active
         goto    kyt_ns                 ; set state, end task, async

;------------- end of Keyer-replay-states ---------------------------


;------- "very special" Keyer-states  ======================================

kyt_tune:   ;======= "tuning" state ==========================
        ; - exit from this state by touching any paddle- or button- contact 
        ; - enters sleep mode after long time of "No Activity".
         bsf     IOP_TX_CONTROL        ;07 Transmitter ON,  Receiver OFF.
         btfss   IOP_DASH              ;08 dash-paddle closed:
         goto    kyt_tune_stop2        ;09 stop "tuning"
         bsf     IOP_AUDIO_OUT         ;10 sidetone HIGH
         btfss   IOP_DOT               ;11 dot-paddle closed:
         goto    kyt_tune_stop2        ;12 stop "tuning"
         btfss   IOP_KEY_MSG1          ;13 "Message1"-Button pressed ?
         goto    kyt_tune_stop2        ;14
         btfss   IOP_KEY_MSG2          ;15 "Message2"-Button pressed ?
         goto    kyt_tune_stop2        ;16
         bsf     IOP_KEY_OUTPUT        ;17 carrier on
         decfsz  CW_t_cnt,F            ;18 "inner loop"-time over ?
         goto    kyt_tu2               ;19 no, end task
         decfsz  NoActivityTimer,F     ;20 "outer loop"-time over ?
kyt_tu2: goto    main_loop_sync        ;21 no, end task
        ; Exit "tune"-loop after a long time of no activity:
kyt_tune_stop:
         bcf     IOP_KEY_OUTPUT        ; carrier off (Dot)
         goto    kyt_prepare_wait      ; resume normal operation.
kyt_tune_stop2:
         bcf     KY_flags,ky_wait_cmd  ; exit from "command"-mode
         goto    kyt_tune_stop

;======= End of "Keyer-Task" after abt 16 cycles (incl. jump back) =====



;=======================================================================
; Initialization after RESET or WAKEUP (?)
;=======================================================================
 ; ORG  0x100
reset:  ;----- Hardware initialization -----
        bcf     INTCON, GIE       ; disable all interrupts
        bcf     STATUS, RP1
        bsf     STATUS, RP0    ;! ; setting RP0 enables access to TRIS regs        
        bsf     IOP_POTI1      ;! ; Poti-Port as input saves power
        bcf     IOP_KEY_OUTPUT ;! ; output
        bcf     IOP_TX_CONTROL ;! ; output
        bcf     IOP_AUDIO_OUT  ;! ; output
        bcf     IOP_SIGNAL_LED ;! ; output
        bsf     IOP_COUNTER    ;! ; input
        bcf     OPTION_REG, NOT_RBPU ; enable PORTB pull-ups 
             ; option register is in bank1. i know. thanks for the warning.
        bsf     IOP_DOT        ;! ; input (with pullup)
        bsf     IOP_DASH       ;! ; input (with pullup)
        bsf     IOP_KEY_MSG2   ;! ; input (with pullup)
        bsf     IOP_KEY_MSG1   ;! ; input (with pullup)

        bcf     STATUS, RP0    ;! ; clearing RP0 enables access to PORTs
        bcf     IOP_KEY_OUTPUT    ; key output low
        bcf     IOP_TX_CONTROL    ; Transmitter off, receiver on
        bcf     IOP_AUDIO_OUT     ; audio sidetone low

        ;----- Software Initialization -----
        clrf    KY_state          ; KY_state := 0
        clrf    KY_flags          ; KY_flags := 0
        clrf    CW_t_cnt   
        movlw   (d'54000' / (d'060'*MAIN_CYCLE) )
        movwf   CW_timing         ; CW_timing := 60 letters per minute
                                  ; (default value if poti fails...)
        clrf    PT_counter
        incf    PT_counter,F
        clrf    OP_flags          ; set all option bits to "standard" (0)  
        clrf    NR_hundreds       ; set three-digit-number..
        clrf    NR_tens           ; ... to "ZERO"
        clrf    NR_ones           ;  ("unpacked" BCD format)

#if SWI_TEST_QRQ  ; Test with MPSIM ?
        movlw   3
        movwf   CW_timing       ; (QRQ for simulator)
#endif  ; SWI_TEST_..

        goto    main_loop         ;



;=======================================================================
; Actions if control buttons are pressed
;=======================================================================
        ; A short touch of a "message" button starts playing a message
        ;   (and may also terminate recording).
        ; A long touch of a "message" button starts recording a message
        ;   (this will be indicated by a signal letter "R").
        ; A combination of both buttons
        ;   may be used to enter a "configuration menu" 
        ;   in later versions of this firmware.
        ; Stop playing a message before it terminates "itself"
        ; is also possible by touching a paddle.
        ;
msg1_pressed:    ; Message #1 has just been pressed.
	bcf     IOP_KEY_OUTPUT          ; carrier off
        clrf    NoActivityTimer         ; reload "key-down"-Timer
        btfsc   KY_flags, ky_recording  ; recording active ?
        goto    msg_stop_recording      ; yes, stop recording & return
        bcf     KY_flags, ky_message2   ; else use "message 1" NOW..
                      ; ( if this flag had been cleared earlier, 
                      ;  the wrong "recorded" message could have been stopped)
msg1_wait_release1:
        call    Delay10                 ; min. 10*100us = 1ms per loop
        btfsc   IOP_KEY_MSG1            ; "message" key still pressed ?
        goto    msg1_play               ; no, only short press -> play !
        btfss   IOP_KEY_MSG2            ; check "combination" of buttons
        goto    msg1_then_2             ; msg1 pressed, then msg2
        decfsz  NoActivityTimer,F       ; "short" time over ?
        goto    msg1_wait_release1      ; no, still pressed -> wait
        ; now the message button has been pressed "quite long"
        movlw   b'11101110'             ; Beep "M" for "message record"
        call    MessageBeeps            ; ... means "Recording on"
        ; still have to wait until the button is released ?
msg1_wait_release2:
        btfsc   IOP_KEY_MSG1            ; "message" key released ?
        goto    msg1_record             ; released now -> start record.
        btfss   IOP_KEY_MSG2            ; check "combination" of buttons
        goto    msg1_then_2             ; msg1 pressed, then msg2
        call    PowerDown               ; not released ... save power!
        goto    msg1_wait_release2      ; check again if msg.button released
msg1_record:  ; now the message button is released,
              ; start recording of a message.
        movlw   EEPROM_ADR_MSG1_START   ; Start address in message EEPROM
        movwf   KY_mem_index            ; this index will be DECREMENTED!
msg_record_i: ; start recording, beginning at current index.
        bsf     KY_flags, ky_recording  ; set "recording" flag
        bcf     KY_flags, ky_playing    ; reset "playing" flag for safety
        goto    msg_release_both_buttons

msg1_play:     ; start playing recorded message #1
        movlw   EEPROM_ADR_MSG1_START   ; Start address in message EEPROM
msg_play:      
        movwf   KY_mem_index            ; this index will be DECREMENTED!
        movwf   KY_char_latch           ; temporary save start-index
        ; Check if the message is "partitioned".
        ; If yes, user may choose partition by multiple "button clicks".
        ;         With every "button clicks" the index is advanced
        ;         beyond the next "EOM"-character.
        ; If no,  we don't have to wait if the button is pressed
        ;         more times (saves time in contests and pileups)
        bsf     KY_flags, ky_playing    ; set "playing"-flag for "ReadFromMessage"
msg_play_skip_eom:
        call    ReadFromMessage         ; read Message[KY_mem_index--] ->w
        btfsc   STATUS,Z                ; skip next instruction if NOT ZERO
        goto    msg_play_no_partition   ; end-of-string, no EOM-code found!
        sublw   CW_CHR_EOM              ; check if character is EOM-code..
        btfsc   STATUS,Z                ; skip next instruction if NOT EQUAL
        goto    msg_play_partitioned    ; message is partitioned...
        btfsc   KY_flags, ky_playing    ; end of message reached ?
        goto    msg_play_skip_eom       ; no, continue until index==0
        ; else continue with "msg_play_no_partition".
msg_play_no_partition:
        ; no partition in the message buffer, 
        ; start playing the complete message without any further delay.               
        movf    KY_char_latch,w         ; restore 1st index of message
        movwf   KY_mem_index
        bsf     KY_flags, ky_playing    ; set "playing"-flag for "ReadFromMessage"
        goto    msg_play_i              ; play message from the start
msg_play_partitioned:
        ; start playing a "partitioned" message:
        ; first wait some time to see if there are more
        ; short "clicks" of the message button. 
        ; - if no more "button clicks": 
        ;   start message from the current messag-buffer-index !
        ; - for every "click" advance the message index to the next 
        ;    "EOM-code" (which is the "partition separator").
         movf    KY_char_latch,w       ; restore 1st index of message
         movwf   KY_mem_index
         bsf     KY_flags, ky_playing  ; set "playing"-flag for "ReadFromMessage"
msg_pp0: clrf    NoActivityTimer       ; reload "key-down"-Timer       
msg_pp1: call    Delay10               ; wait a little bit..
         btfss   IOP_KEY_MSG1      
         goto    msg_pp3               ; ...to see if more..
         btfss   IOP_KEY_MSG2          ; ... "button clicks" follow !
         goto    msg_pp3               ; 
         decfsz  NoActivityTimer,F     ; max. "wait"-time over ?
         goto    msg_pp1               ; no, not yet -> loop
         ; The message button has not been pressed for quite a long time.
         ; Start playing from the "current" position.
msg_pp2: goto   msg_play_i             ; start playing from current index        
msg_pp3: ; message button is pressed to "skip" message to next "EOM-code".
         call    ReadFromMessage       ; read Message[KY_mem_index--]
         btfsc   STATUS,Z              ; skip next instruction if NOT ZERO
         goto    msg_pp5               ; end-of-string, no EOM-code found!
         sublw   CW_CHR_EOM            ; check if character is EOM-code..
         btfsc   STATUS,Z              ; skip next instruction if NOT EQUAL
         goto    msg_pp5               ; message is partitioned...
         btfsc   KY_flags,ky_playing   ; end of message memory reached ?
         goto    msg_pp3               ; no, continue until end of memory
msg_pp5: ; "skipping EOM" finished. Now wait for release of message button.
         clrf    NoActivityTimer       ; reload "key-down"-Timer       
msg_pp6: call   Delay10                ; wait a little bit..
         decfsz  NoActivityTimer,F     ; max. "wait"-time over ?
         goto    msg_pp7               ; no : continue waiting
         goto    msg_record_i          ; yes: RECORD from current position
msg_pp7: btfss   IOP_KEY_MSG1      
         goto    msg_pp6               ; button still pressed, loop
         btfss   IOP_KEY_MSG2       
         goto    msg_pp6       
         ; message buttons have been released after a "short" time.
         ; check if more short "button clicks" follow.
         goto    msg_pp0

msg_play_i:    ;start playing recorded message at current index
        movlw   KYS_PLAY_GET_NEXT_CHAR
        movwf   KY_state                ; initialize keyer state
        bsf     KY_flags, ky_playing    ; set "playing"-flag
        clrf    NoActivityTimer         ; reload "No Activity"-Timer
               ; (used to limit "endless" play-loop to 255 times)
        goto    no_button               ; continue main loop

msg_stop_recording:  ; if any message button pressed while "recording":
        ; stop recording, wait until button is released 
        ; and return to main loop
        call    StopRecording           ; stop recording
        movlw   b'10101000'             ; Message-Beep "s"...
        call    MessageBeeps            ; ... means "recording Stopped"
        goto    msg_release_both_buttons

msg_release_btn_pdown:
        call    PowerDown       ; save a little bit of battery power
msg_release_both_buttons: 
        ; "normal" exit to ensure both buttons are released
        ;   before main loop continues
        ; + save power if someone puts a brick on any button..
        btfss   IOP_KEY_MSG1      
        goto    msg_release_btn_pdown   ; msg1 still pressed, wait...
        btfss   IOP_KEY_MSG2
        goto    msg_release_btn_pdown   ; msg2 still pressed, wait...
        movlw   KYS_PREPARE_WAIT        ; else "wait" in main loop
        movwf   KY_state                ; initialize keyer state
        clrf    NoActivityTimer         ; reload "No Activity"-Timer
        goto    no_button               ; continue main loop

msg1_then_2:     ; message1 and message2 - buttons combined:
msg2_then_1:     ;      Enter "command mode".
         bcf    NR_flags,nr_digit1      ; no "1st digit"
         bcf    NR_flags,nr_digit2      ; no "2nd digit"
         bcf    NR_flags,nr_digit2      ; no "3rd digit"
         btfsc  KY_flags,ky_wait_cmd    ; already "waiting for command" ?
         goto   msg_done_command        ;    yes -> leave command mode.
         bsf    KY_flags,ky_wait_cmd    ; set "waiting for command" - flag
         movlw  b'11101011'             ; Beep "C" for "Command"
         call   MessageBeeps
         movlw  b'10100000'
msg_br:  call   MessageBeeps
         goto   msg_release_both_buttons
msg_done_command:
         bcf    KY_flags,ky_wait_cmd    ; clear "waiting for command"-flag
         movlw  b'11101010'             ; Beep "D" for "Done"
         goto   msg_br


msg2_pressed:    ; Message #2 has just been pressed.
	bcf     IOP_KEY_OUTPUT          ; carrier off
        clrf    NoActivityTimer         ; reload "key-down"-Timer
        btfsc   KY_flags, ky_recording  ; recording active ?
        goto    msg_stop_recording      ; yes, stop recording & return
        bsf     KY_flags, ky_message2   ; else use "message 2" NOW
msg2_wait_release1:
        call    Delay10                 ; min. 10*100us = 1ms per loop
        btfsc   IOP_KEY_MSG2            ; "message" key still pressed ?
        goto    msg2_play               ; no, only short press -> play !
        btfss   IOP_KEY_MSG1            ; check "combination" of buttons
        goto    msg2_then_1             ; msg2 pressed, then msg1
        decfsz  NoActivityTimer,F       ; "short" time over ?
        goto    msg2_wait_release1      ; no, still pressed -> wait
        ; now the message button has been pressed "quite long"
        movlw   b'11101110'             ; Beep "M" for "message record"
        call    MessageBeeps            ; ... means "Recording on"
        ; still have to wait until the button is released ?
msg2_wait_release2:
        btfsc   IOP_KEY_MSG2            ; "message" key released ?
        goto    msg2_record             ; released now -> start record.
        btfss   IOP_KEY_MSG1            ; check "combination" of buttons
        goto    msg2_then_1             ; msg2 pressed, then msg1
        call    PowerDown               ; not released ... save power!
        goto    msg2_wait_release2      ; check again if msg.button released
msg2_record:  ; now the message button is released,
              ; start recording message2 (in RAM, not EEPROM).
        movlw   RAM_MSG2_LENGTH-1       ; Start INDEX in message RAM
        movwf   KY_mem_index            ; this index will be DECREMENTED!
        bsf     KY_flags, ky_recording  ; set "recording" flag
        bcf     KY_flags, ky_playing    ; reset "playing" flag for safety
        goto    msg_release_both_buttons

msg2_play:     ; start playing recorded message #2
        movlw   RAM_MSG2_LENGTH-1       ; Start address in message RAM
        goto    msg_play                ; initialize state machine & return

        

;=======================================================================
; Read the "quasi-analog/digital-converter" with poti & capacitor
;=======================================================================
       ; The Poti is sampled via "polling" on any port.
       ; The "conversion table" is included in the poti-read-routine !
ReadPoti:
        bcf     INTCON, GIE       ;01 disable IRQs while we are in register bank 1
                                  ; (and to prevent bad poti readings !)
        bcf     IOP_POTI1         ;02 clear Poti pin output latch to discharge
        bsf     STATUS, RP0    ;! ;03 set RP0 for TRIS access (;!)
        bcf     IOP_POTI1      ;! ;04 define PortB.0 as output -> begin discharge
          ; (typical discharge of 220nF from 2V to 0V takes about 100usec)
        nop                    ;! ;05 ensure capacitor gets completely discarged !
        bsf     IOP_POTI1      ;! ;06 define PortB.0(!!) as input -> start e-function
        bcf     STATUS, RP0    ;! ;07 clear RP0 for "normal" access
          ; after a certain time the state of the poti input 
          ; will toggle from '0' (which it should be now) to '1'.
        btfsc   IOP_POTI1         ;08 check if already charged
        retlw   (d'54000' / (d'360'*MAIN_CYCLE) )  ;09 index 0 only for Mario
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'340'*MAIN_CYCLE) )  ;11 index 1
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'320'*MAIN_CYCLE) )  ;13 index 2
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'300'*MAIN_CYCLE) )  ;15 index 3
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'280'*MAIN_CYCLE) )  ;17 index 4
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'260'*MAIN_CYCLE) )  ;19 index 5
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'240'*MAIN_CYCLE) )  ;21 index 6
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'230'*MAIN_CYCLE) )  ;23 index 7 
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'220'*MAIN_CYCLE) )  ;25 index 8
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'215'*MAIN_CYCLE) )  ;27 index 9  
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'210'*MAIN_CYCLE) )  ;29 index 10
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'205'*MAIN_CYCLE) )  ;31 index 11
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'200'*MAIN_CYCLE) )  ;33 index 12
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'195'*MAIN_CYCLE) )  ;35 index 13
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'190'*MAIN_CYCLE) )  ;37 index 14  
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'185'*MAIN_CYCLE) )  ;39 index 15
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'180'*MAIN_CYCLE) )  ;41 index 16
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'175'*MAIN_CYCLE) )  ;43 index 17
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'170'*MAIN_CYCLE) )  ;45 index 18
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'165'*MAIN_CYCLE) )  ;47 index 19
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'160'*MAIN_CYCLE) )  ;49 index 20
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'155'*MAIN_CYCLE) )  ;51 index 21
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'150'*MAIN_CYCLE) )  ;53 index 22
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'145'*MAIN_CYCLE) )  ;55 index 23
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'140'*MAIN_CYCLE) )  ;57 index 24
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'135'*MAIN_CYCLE) )  ;59 index 25
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'130'*MAIN_CYCLE) )  ;61 index 26
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'127'*MAIN_CYCLE) )  ;63 index 27
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'125'*MAIN_CYCLE) )  ;65 index 28 
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'122'*MAIN_CYCLE) )  ;67 index 29
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'120'*MAIN_CYCLE) )  ;69 index 30
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'117'*MAIN_CYCLE) )  ;71 index 31
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'115'*MAIN_CYCLE) )  ;73 index 32
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'112'*MAIN_CYCLE) )  ;75 index 33
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'110'*MAIN_CYCLE) )  ;77 index 34
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'107'*MAIN_CYCLE) )  ;79 index 35
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'105'*MAIN_CYCLE) )  ;81 index 36
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'102'*MAIN_CYCLE) )  ;83 index 37
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'100'*MAIN_CYCLE) )  ;85 index 38
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'097'*MAIN_CYCLE) )  ;87 index 39
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'095'*MAIN_CYCLE) )  ;89 index 40 
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'092'*MAIN_CYCLE) )  ;91 index 41
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'090'*MAIN_CYCLE) )  ;93 index 42
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'087'*MAIN_CYCLE) )  ;95 index 43
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'085'*MAIN_CYCLE) )  ;97 index 44
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'082'*MAIN_CYCLE) )  ;99 index 45
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'080'*MAIN_CYCLE) )  ;101 index 46
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'077'*MAIN_CYCLE) )  ;103 index 47
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'075'*MAIN_CYCLE) )  ;105 index 48
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'072'*MAIN_CYCLE) )  ;107 index 49
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'070'*MAIN_CYCLE) )  ;109 index 50
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'068'*MAIN_CYCLE) )  ;111 index 51  
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'065'*MAIN_CYCLE) )  ;113 index 52
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'062'*MAIN_CYCLE) )  ;115 index 53
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'060'*MAIN_CYCLE) )  ;117 index 54
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'058'*MAIN_CYCLE) )  ;119 index 55 
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'055'*MAIN_CYCLE) )  ;121 index 56
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'050'*MAIN_CYCLE) )  ;123 index 57
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'045'*MAIN_CYCLE) )  ;125 index 58
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'040'*MAIN_CYCLE) )  ;127 index 59
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'035'*MAIN_CYCLE) )  ;129 index 60
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'030'*MAIN_CYCLE) )  ;131 index 61
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'025'*MAIN_CYCLE) )  ;133 index 62
        btfsc   IOP_POTI1
        retlw   (d'54000' / (d'020'*MAIN_CYCLE) )  ;135 index 63
#if (SWI_TEST_QRQ) 
        retlw   (d'54000' / (d'360'*MAIN_CYCLE) )  ;137 index 64+
#else
        retlw   0xFF ; 137 index 64+ : slowest possible speed
#endif ; .. (!SWI_TEST_QRQ)
       ; Takes a maximum of 137 cycles, that's about 15ms w. 38kHz oscillator,
       ;  but much less time at high CW-speeds (where this delay would hurt..)
       ; Note that the interrupt is still disabled after returning !


;----- End of subroutine "ReadPoti" --------------------


;=======================================================================
; Save a single Byte in the PIC's Data-EEPROM.
;  Input parameters:
;    EEDATA   contains byte to be written
;    w        contains byte address (i.e. "index")
;
; Notes:
;   - This routine will wait for completion of "eeprom write ready"
;     **before** writing to EEPROM.
;     (improves performance during message recording, max. 10ms)
;  Side effects:
;    KY_char_latch  will be overwritten
;=======================================================================
#define  L_save_eep_timer KY_char_latch

SaveInEEPROM:
        ; write to EEPROM data memory as explained in PIC data sheet
        ; EEDATA and EEADR must have been set before calling this subroutine
        ; (optimized for the keyer-state-machine).
         movwf   EEADR                 ; write into EEPROM address register
         bcf     INTCON, GIE           ; disable INTs
         bsf     STATUS, RP0         ;!; Bank1 for "EECON" access
         bsf     EECON1, WREN        ;!; set WRite ENable
         movlw   055h                ;!;
         movwf   EECON2              ;!; write 55h
         movlw   0AAh                ;!;
         movwf   EECON2              ;!; write AAh
         bsf     EECON1, WR          ;!; set WR bit, begin write
         ; wait until write access to the EEPROM is complete
         clrf    L_save_eep_timer    ;!; preset "timeout"-counter
SaveEW:  btfss   EECON1, WR          ;!; WR is cleared after completion of write
         goto    SaveRdy             ;!; WR=0, "old" write access complete
         decfsz  L_save_eep_timer,F  ;!;
         goto    SaveEW              ;!; not ready,no timeout,continue waiting
SaveRdy: ; now the EEPROM is ready to accept "new" write data
         bcf     EECON1, WREN        ;!; disable further WRites
         bcf     STATUS, RP0         ;!; Bank0 for normal access
         bsf     INTCON, GIE           ; enable INTs
         return


;=======================================================================
; Read a single Byte from the PIC's Data-EEPROM.
;  Input parameters:
;     w  contains byte address
;
;  Result:
;     w  returns the read byte
;=======================================================================
ReadFromEEPROM:
        movwf   EEADR                   ;01 write into EEPROM address register
        bcf     INTCON, GIE             ;02 disable INTs
        bsf     STATUS, RP0             ;03 Bank1 for "EECON" access
        bsf     EECON1, RD              ;04 set "Read"-Flag for EEPROM
        bcf     STATUS, RP0             ;05 normal access to Bank0
        bsf     INTCON, GIE             ;06 re-enable interrupts
        movf    EEDATA, w               ;07 read byte from EEPROM latch
        return                          ;08+09 back to caller


;=======================================================================
; Stop recording a message
;    - finish last "PAUSE"-code 
;    - append ZERO byte if there is enough memory left
;                 in the "current" message buffer.
;  Input parameters:
;    KY_mem_index contains current index of recorded message string
;  Side effects:
;    KY_char_latch will be overwritten
;=======================================================================
StopRecording:
         btfss   KY_char_latch,7       ; "PAUSE-code" in progress ? 
         goto    StopR2                ;  no -> don't append pause-code
         movf    KY_char_latch,w       ;  yes-> append "current" pause:
         call    AppendToMessage       ;   message[KY_mem_index--] = w;
StopR2:  movlw   0                     ; data to be written = ZERO byte
         call    AppendToMessage       ;   message[KY_mem_index--] = w;
         bcf     KY_flags,ky_recording ; stop "RECORDING" now
         movlw   1                     ; prepare detection of next letter..
         movwf   KY_char_latch         ; ..with "start bit" in position 0
         return         


;=======================================================================
; Reads the "current" message byte
;  Input parameters:
;    KY_mem_index:         contains the message buffer INDEX to read from.
;    KY_flags.ky_message2: 0="use Message #1 (EEPROM)
;                          1="use Message #2 (RAM)
;  Output, changed variables:
;    w               :     returns the read byte
;    ZERO-flag       :     is set if the result is ZERO (end-of-string)
;    KY_mem_index    :     will be decremented (down to zero, not further)
;    KY_flags.ky_playing:  will be cleared if index ZERO reached
;=======================================================================
ReadFromMessage:
        movf    KY_mem_index,w          ; load current message-index
        btfsc   STATUS, Z               ; Is message-index already ZERO ?
        goto    ReadFM1                 ; index already zero-> dont decrement
        decfsz  KY_mem_index,F          ; decrement message-index
        goto    ReadFM2                 ; not zero
ReadFM1: ; end of message buffer reached, reset "playing" flag
        bcf     KY_flags, ky_playing
ReadFM2: ; note that <w> still contains the not-decremented index.
        btfss   KY_flags, ky_message2   ; "message1" or "message2" ?
        goto    ReadFromEEPROM          ; "message1" (EEPROM)
        ; else: "message2" (RAM) will be read with "indexed addressing"
        addlw   Msg2_Start              ; add base address of buffer
        movwf   FSR                     ; store in "data memory pointer"
        movf    INDF,w                  ; read data from  INDF = *(FSR)
        return                          ; that's all


;=======================================================================
; Append a Byte to the recorded message (only if recording is active),
; turn recording "off" if there's no "recording-memory" left.
;  Input parameters:
;    w            contains the byte to be appended
;    KY_mem_index contains current index of recorded message string
;    KY_flags.ky_message2: 0="use Message #1 (EEPROM)
;                          1="use Message #2 (RAM)
;  Output parameters, changed variables:
;    KY_mem_index will be decremented
;    KY_flags.ky_recording may be reset here if running out of memory 
;    KY_char_latch  will be overwritten with "1"
;    
;=======================================================================
AppendToMessage:
        btfss   KY_flags,ky_recording   ; "RECORDING" still active ?
        return                          ; no, no action allowed.
        movwf   EEDATA                  ; data to be written
        btfsc   KY_flags, ky_message2   ; is "message 2" used ?
        goto    Append_msg2             ; yes, message2 -> other part
        ; Append to "Message1" (that's the one in EEPROM)
        movf    KY_mem_index,w          ; load current "saving" address
        call    SaveInEEPROM            ; save <EEDATA> in <w>
App_di: decfsz  KY_mem_index,F          ; address for next recorded letter
        return                          ; enough memory, don't stop recording
        ; else: ran out of message memory, stop recording, set "full"-flag
        bcf     KY_flags,ky_recording   ; stop "RECORDING" now
        bsf     KY_flags,ky_msg_full    ; set "message buffer full" - flag
        return                          ; back to caller
Append_msg2     ; if "Message2" is used instead of "Message1".
        ; Message2 is stored in RAM, not in EEPROM.
        ; Add the base address of the RAM-Buffer to the index
        ; and use indexed addressing to write the byte into the buffer.
        movlw   Msg2_Start              ; Base address of RAM-Message
        addwf   KY_mem_index,w          ; ..plus "index"..
        movwf   FSR                     ; store in "data memory pointer"
        movf    EEDATA,w                ; get write data from temp.var
        movwf   INDF                    ; write to   INDF = *(FSR)
        goto    App_di                  ; continue with decrementing index


;=======================================================================
; Increment serial number (three-digit bcd)
;   NR_ones, NR_tens, NR_hundreds.
;=======================================================================
IncrementNumber:
         incf    NR_ones,F
         movlw   d'10'
         subwf   NR_ones,w      
         btfss   STATUS,Z
         return
         clrf    NR_ones
         incf    NR_tens,F
         movlw   d'10'
         subwf   NR_tens,w      
         btfss   STATUS,Z
         return
         clrf    NR_tens
         incf    NR_hundreds,F
         movlw   d'10'
         subwf   NR_hundreds,w      
         btfss   STATUS,Z
         return
         clrf    NR_hundreds
         return


;=======================================================================
; Switch to 'Power Down' state (using sleep instruction)
;=======================================================================
        ; This subroutine is called after a certain time of "no activity".
        ; Caller is the "keyer state machine".
        ; Returns to caller as soon as "something happens" on Port B.
PowerDown:
        ; prepare on-chip peripherals for SLEEP mode.
         bcf     IOP_KEY_OUTPUT        ; carrier off
         bcf     IOP_AUDIO_OUT         ; sidetone off
         bcf     IOP_TX_CONTROL        ; transmitter off, receiver on
         bcf     IOP_SIGNAL_LED        ; signal-LED off

        ; set "wakeup" interrupt source to "Change on Port B" only
         movlw b'00001000'     ; new INTCON value: only RB0 Interrupt
              ;  ||||||||
              ;  |||||||+--RBIF: RB Port Change Interrupt Flag 
              ;  ||||||+---INTF: External Interrupt Flag 
              ;  |||||+----T0IF: Timer0 Overflow Interrupt Flag 
              ;  ||||+-----RBIE: Port Change Interrupt Enable
              ;  |||+------INTE: INT Interrupt Enable
              ;  ||+-------T0IE: T0IF Interupt Enable
              ;  |+--------EEIE: EE Write Complete Interrupt Enable
              ;  +---------GIE:  Global Interrupt Enable
        movwf   INTCON
        sleep                          ; supply current less 1uA now..
        nop
        clrf    INTCON                 ; disable interrupt on "Port B change"
        call    ReadPoti       
        movwf   CW_timing              ; poti may have been changed during "sleep"
        return
;------ end of subroutine 'PowerDown' -----------------


;==========================================================================
; Short Delay Routines (n NOPs + call&return time)
;==========================================================================
Delay10:  nop
Delay9:   nop
Delay8:   nop
Delay7:   nop
Delay6:   nop
Delay5:   nop
Delay4:   nop
Delay3:   nop
Delay2:   nop
Delay1:   nop
          return
       


;==========================================================================
; Generates a "message beep sequence" for feedback after special key-inputs.
;  This "message" may be cancelled by any paddle contact...
;      it does *NOT* disturb normal keying operation !
;      (only audible if sidetone-output is used)
;  Input parameters:
;    w       contains an 8-bit message pattern, 
;              "1"-Bit = Signal on,   "0"-Bit = Signal off
;  Output parameters:
;    KY_flags.beep_cpl:  1="Beep completed"  0="Beep cancelled"
; 
;  Side effects:
;    destroys the contents of
;        - KY_char_latch
;        - KY_count_elements
;        - KY_dot_counter   
;
;==========================================================================
#define  L_timer KY_decoded_char

MessageBeeps:
         bcf     KY_flags,ky_beep_cpl  ; "Beep not completed"
         movwf   KY_char_latch         ; store pattern in "shift register"
         movlw   8                     ; number of "bits" in message pattern
         movwf   KY_count_elements      
MsgB_1:  movlw   d'040'                ; number of tone periods per signal element
         movwf   KY_dot_counter
         btfsc   KY_char_latch,7
         bsf     IOP_SIGNAL_LED        ; activate signal-LED if pattern bit "1" 
         btfss   KY_char_latch,7
         bcf     IOP_SIGNAL_LED
MsgB_2:  btfsc   KY_char_latch,7
         bsf     IOP_AUDIO_OUT         ; sidetone "high" if next pattern bit "1"
         call    Delay6
         bcf     IOP_AUDIO_OUT         ; sidetone "low"
         call    Delay1
         btfss   IOP_DOT
         goto    MsgB_3                ; "dot"-contact closed  -> cancel
         btfss   IOP_DASH
         goto    MsgB_3                ; "dash"-contact closed -> cancel
         decfsz  KY_dot_counter,F      ; more tone periods ?
         goto    MsgB_2                ; yes, next period
         rlf     KY_char_latch,F       ; shift signal pattern
         decfsz  KY_count_elements,F   ; more bits in pattern ?
         goto    MsgB_1                ; yes, next bit of pattern
         bsf     KY_flags,ky_beep_cpl  ; "Beep Completed"
MsgB_3:  bcf     IOP_SIGNAL_LED        ; signal-LED off
         movlw   1                     ; set "default" contents...
         movwf   KY_char_latch         ; ..with "start bit" in position 0
         return
;------ end of subroutine 'Message Beeps' -----------------



;==========================================================================
;  Generate warning signals if any warn/error-flags are pending
;==========================================================================
WarningSignals:
        ; Has message recording been stopped because memory is full ?
        btfss   KY_flags,ky_msg_full
        goto    warn_sig_nfull
        movlw   b'10101110'             ;   Message-Beep: "f"...
        call    MessageBeeps            ;   ... means "recording memory Full"
        movlw   b'10000000'
        call    MessageBeeps
        btfsc   KY_flags,ky_beep_cpl    ;   only if beep signal "completed":
        bcf     KY_flags,ky_msg_full    ;   reset warn flag
warn_sig_nfull:
        return


;=======================================================================
; Convert a morse-code-digit(KY_decoded_char) into a BCD value (w)
;  input parameters:       
;     KY_decoded_char: contains the morse code of a numeric digit (hopefully)
;  output parameters:
;     STATUS.DC:  0 = all ok,   1 = error occured (not a digit)
;     w        :  returns the decimal value if no error
;  Side effects:
;     destroys the contents of
;        - KY_char_latch
;=======================================================================
MorseToDigit:
  ;   - used by command handler if a number is entered in morse code.
  ;   - cannot be implemented via "table" because of low memory.
  ;   - instead we call the "inverse" function DigitToMorse to "find"
  ;     the binary value.
         movlw   d'10'                 ; load max. bcd value
         movwf   KY_char_latch         ; ..also as "loop counter"
MorseD1: decf    KY_char_latch,w       ; load (value-1) into w
         call    DigitToMorse          ; decimal-digit(w) to morse code(w)
         subwf   KY_decoded_char,w     ; found the number ?
         btfsc   STATUS,Z
         goto    MorseD3               ; yes, got the number !
         decfsz  KY_char_latch,F       ; no, test next BCD number
         goto    MorseD1
  ; Morse character not found in the "standard set"...
  ;   maybe it was a "quick digit" like "N" instead of "9":
         movlw   d'10'                 ; load max. bcd value
         movwf   KY_char_latch         ; ..also as "loop counter"
MorseD2: decf    KY_char_latch,w       ; load (value-1) into w
         call    DigitToMorse_Quick    ; decimal-digit(w) to morse code(w)
         subwf   KY_decoded_char,w     ; found the number ?
         btfsc   STATUS,Z
         goto    MorseD3               ; yes, got the number !
         decfsz  KY_char_latch,F       ; no, test next BCD number
         goto    MorseD2
  ; seems we're out of luck, number not found, digit cannot be decoded.
         bsf     STATUS,DC             ; error flag for "return value"
         retlw   0
MorseD3: ; found the number, return its value.
         decf    KY_char_latch,w       ; w := KY_char_latch-1
         bcf     STATUS,DC             ; no error
         return                        ; return with BCD value in w
 ; end of function MorseToDigit(w) 




;==========================================================================
;  Handle Command Code (KY_decoded_char)
;  - will be called by morse decoder after completion of a decoded letter,
;    if "command mode" is active.
;==========================================================================
CommandDispatcher:
         ; first check if we are just waiting for a numeric input (serial)
         btfss  NR_flags,nr_digit1      ; 1st digit of three-digit-number ?
         goto   cmd_di1
         call   MorseToDigit            ; convert entered code to BCD 
         btfsc  STATUS,DC               ; Conversion ok ?
         goto   cmd_nr_error            ; error, probably a "bad digit"
         bcf    NR_flags,nr_digit1      ; ok, 1st digit done...
         bsf    NR_flags,nr_digit2      ; now wait for 2nd digit
         movwf  NR_hundreds             ; set "hundreds" of serial
         goto   main_loop               ; don't say "roger" until number ready!
cmd_di1: btfss  NR_flags,nr_digit2      ; 2nd digit of three-digit-number sent?
         goto   cmd_di2
         call   MorseToDigit            ; convert entered code to BCD 
         btfsc  STATUS,DC               ; Conversion ok ?
         goto   cmd_nr_error            ; error, probably a "bad digit"
         bcf    NR_flags,nr_digit2      ; ok, 2nd digit done...
         bsf    NR_flags,nr_digit3      ; now wait for 3rd digit
         movwf  NR_tens                 ; set "tens" of serial
         goto   main_loop               ; don't say "roger" until number ready!
cmd_di2: btfss  NR_flags,nr_digit3      ; 3rd digit of three-digit-number sent?
         goto   cmd_di3
         call   MorseToDigit            ; convert entered code to BCD 
         btfsc  STATUS,DC               ; Conversion ok ?
         goto   cmd_nr_error            ; error, probably a "bad digit"
         bcf    NR_flags,nr_digit3      ; ok, 3rd digit done...
         movwf  NR_ones                 ; set "ones" of serial
         goto   cmd_ok                  ; now say "roger", number is "ready"!  
cmd_di3:
         ; else: no "number"-transmission in progress.
         ; Find out which "Keyer-Command" has been entered..
         movlw  CW_CHR_A               ; switch to "iambic mode A" ?
         subwf  KY_decoded_char,w      
         btfss  STATUS,Z
         goto   cmd_na
         bsf    OP_flags,op_dot_memory_off
         goto   cmd_ok
cmd_na:  movlw  CW_CHR_B               ; switch to "iambic mode B" ?
         subwf  KY_decoded_char,w      
         btfss  STATUS,Z
         goto   cmd_nb
         bcf    OP_flags,op_dot_memory_off
         goto   cmd_ok 
cmd_nb:  movlw  CW_CHR_C               ; Activate "beaCon" mode ?
         subwf  KY_decoded_char,w      ; (similar to "endless mode",
         btfss  STATUS,Z               ;  but no "255-loops-timeout)
         goto   cmd_nc
         bsf    OP_flags,op_beacon_mode ; turn BEACON mode on
         bcf    OP_flags,op_loop_mode   ; but turn LOOP mode off (!)
         goto   cmd_ok
cmd_nc:  movlw  CW_CHR_D               ; command entry "Done" ?
         subwf  KY_decoded_char,w      
         btfss  STATUS,Z
         goto   cmd_nd
         bcf    KY_flags,ky_wait_cmd   ; clear "waiting for command" - flag
         goto   cmd_ok 
cmd_nd:  movlw  CW_CHR_E               ; toggle "Endless loop mode" ?
         subwf  KY_decoded_char,w      ; (use it if your TRX has "QSK" 
         btfss  STATUS,Z               ;  ..or at least "SEMI-BK")
         goto   cmd_ne
         btfss  OP_flags,op_loop_mode  ; if "loop mode" is ON...
         goto   cmd_e2
         bcf    OP_flags,op_loop_mode   ; ...then turn LOOP mode OFF,
         bcf    OP_flags,op_beacon_mode ; ...also turn the BEACON off
         goto   cmd_ok 
cmd_e2:                                ; else: "E"-cmd, "loop mode" was off:
         bsf    OP_flags,op_loop_mode  ; ...turn LOOP mode on
         bcf    OP_flags,op_beacon_mode ; ..but turn the BEACON off
         goto   cmd_ok
cmd_ne:  movlw  CW_CHR_L               ; switch to "List mode" ?
         subwf  KY_decoded_char,w      ; (used to "list" message memory..
         btfss  STATUS,Z               ;  ..without expanding the macros)
         goto   cmd_nl
         bsf    OP_flags,op_list_mode  ; no more "macro expansion"
         goto   cmd_ok 
cmd_nl:  movlw  CW_CHR_M               ; switch to "Macro mode" ?
         subwf  KY_decoded_char,w      
         btfss  STATUS,Z
         goto   cmd_nm
         bcf    OP_flags,op_list_mode  ; terminate "list" = enable macro expansion
         goto   cmd_ok 
cmd_nm:  movlw  CW_CHR_N               ; enter three-digit "Number" ?
         subwf  KY_decoded_char,w      
         btfss  STATUS,Z
         goto   cmd_nn
         bsf    NR_flags,nr_digit1     ; set flag to receive 1st digit
         movlw   b'11101000'           
         call    MessageBeeps          ; signal "N", then..
         goto   cmd_ok                 ; signal "R"
cmd_nn:  movlw  CW_CHR_Q               ; activate "Quick digit mode" ?
         subwf  KY_decoded_char,w      
         btfss  STATUS,Z
         goto   cmd_nq
         bsf    OP_flags,op_quick_digits
         goto   cmd_ok 
cmd_nq:  movlw  CW_CHR_S               ; activate "Standard digit mode" ?
         subwf  KY_decoded_char,w      ; (also call it "Slow digit mode")
         btfss  STATUS,Z
         goto   cmd_ns
         bcf    OP_flags,op_quick_digits
         goto   cmd_ok 
cmd_ns:  movlw  CW_CHR_T               ; "Tune mode" (continuous carrier)?
         subwf  KY_decoded_char,w
         btfss  STATUS,Z
         goto   cmd_nt
         movlw  d'65'                  ; allow 65*256 loops of "tuning"
         movwf  NoActivityTimer        ; .. that's about 30 seconds
         movlw  KYS_TUNE
         movwf  KY_state
         goto   cmd_ok
cmd_nt: 

cmd_error:  ; command not recognized, signal questionmark
         movlw   b'10101110'           ; Message-Beep: "?"
         call    MessageBeeps
         movlw   b'11101010'
         goto    cmd_mb_quit           ; send signal(w), then quit
cmd_nr_error: ; "numeric error", signal "N?"
         movlw   b'11101000'
         call    MessageBeeps          ; signal "N"
         goto    cmd_error  

cmd_ok:  ; command recognized, signal "R" (roger) 
         ; and continue main loop.
         movlw   b'10111010'
cmd_mb_quit: ; send signal(w), then quit (to main_loop)
         call    MessageBeeps
         goto    main_loop


  END   ; directive 'end of program'

