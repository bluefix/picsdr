' Program: GSED1330.BAS written using Bascom-AVR ver 1.11.6.2
' Basic program to interface with a graphic LCD
' which has a Seiko SED1330 controller. This program will set up
' the LCD and allow one to position and write text as well as load and display
' bitmap images.
' The Graphic routines to draw circles, squares, rectangles,straight lines
' and set/reset pixels will be availabe at the website for a small license fee.
'
'
'                            BETA CODE
'                   **** NOT FOR COMMERCIAL USE *****
'                       Ver. 0.0.5  July, 2001
'
'
'
' Project Reference: GS1330-8535
' MCU: Atmel AT90S8535
' Software: Bascom-AVR ver 1.11.6.2
' Atmel Programmer: STK500 development board set at 5.0v
'                   ISP and terminal output
'
' Initial Date: July 30, 2001
' Projected Completion Date: August 30, 2001
'
' Author: Ranjit Diol
'         rsdiol@compsys1.com
'         http://www.compsys1.com/workbench
'
'******************************************************************************
'   DISCLAIMER: This file is being released as non-commericial
'   software. It is being provided "AS IS", neither the author,
'   nor COMPSys shall be held liable for any damages caused
'   by its use.
'
'   This product is issued as public domain software,you may use or distribute
'   it freely for non-commercial use.You may use this code or portions thereof
'   in other applications as long as the author is given credit for
'   those portions used.
'
'******************************************************************************
'
'                      (c) COMPSys, 2001
'                     All Rights Reserved
'
'******************************************************************************
'
'
'                    P L E A S E   R E A D
'                    =====================
'IMPORTANT: You may need to change port and pin assignments
'           to match your design. All routines are in the 'gosub' format,
'           you can also,if you want,declare them as subs and functions.
'           you also find variables and constants that are never used and
'           may be removed.
'
'Brief:Hyundai 256x128 LCD using a SED1330F
'
'        LCD PINS                        MCU PINS
'           1 GND                         ----
'           2 GND                         ----
'           3 +5v                         ----
'           4 Vee -15v                    ----
'           5 /RES  Reset on low          Portb.0
'           6 /RD   Read on low           Portb.1
'           7 /WR   Write on low          Portb.5
'           8 /CS   Chip enable on low    Portb.4
'           9 CD    Low=Data Hi=Cmd       Portb.3
'           10-17   Data 8 bits           Portd.0 - Portd.7
'           18-20   No Connection
'
'
'==============================================================

$regfile = "8535def.dat"                                    'AT90S8535 mcu

'Setup ports and aliases
Ddrb = &B11111111
Portb = 255                                                 '255
Ddrd = &B11111111
Portd = 255                                                 '255

'LCD controls
Gl_rst Alias Portb.0                                        'LCD /Reset
Gl_rd Alias Portb.1                                         'LCD /RD
Gl_wr Alias Portb.5                                         'LCD /WR
Gl_cs Alias Portb.4                                         'LCD /CS
Gl_a0 Alias Portb.3                                         'LCD A0 (C/D)
Gl_dat Alias Portd                                          'LCD 8 bit data
Gl_tris Alias Ddrd                                          'LCD data redirection
Gl_inp Alias Pind                                           'LCD data input

Reset Gl_cs                                                 'Set chip select low



'Setup constants may be some that are not used

'=========================================================
'PLEASE REFER TO THE SED1330 SPEC SHEETS FROM SEIKO-EPSON
'FOR MORE DETAILS
'=========================================================

'Constants used
Const Sys_set = &H40
Const Sys_sleep = &H53
Const Sys_cgram_addr = &H5C
Const Sys_scroll = &H44
Const Sys_scroll_hdot = &H5A
Const Sys_scroll_rate = &H5A
Const Sys_cur_form = &H5D
Const Sys_cur_addr = &H46
Const Sys_cur_read = &H47
Const Sys_cur_dir_rt = &H4C
Const Sys_cur_dir_lt = &H4D
Const Sys_cur_dir_up = &H4E
Const Sys_cur_dir_dn = &H4F
Const Sys_over_lay = &H5B
Const Sys_mwrite = &H42
Const Sys_mread = &H43
Const Lcd_disp_on = &H59
Const Lcd_disp_off = &H58
Const Lcd_inverse = &HFF
Const Lcd_normal = &H00

'
'The LCD Initialization parameters are in the
'       data section at end of code
'   =======================================
'   CHANGE ACCORDING TO YOUR LCD DATA SHEET
'   =======================================
'
Const Lcd_cr = &H20                                         '32 Chars/bytes per line
Const Lcd_crm = Lcd_cr - 1                                  'Maximum x value perline
Const Lcd_grh = &H1000                                      'Graphic home position
Const Lcd_txh = &H0000                                      'Text home position
Const Lcd_lh = &H08                                         'Height of line (8x8 characters)
Const Lcd_ol = &B00000001                                   'Sys Overlay value used
Const Lcd_off = &B00010110                                  'Lcd off parameter used
Const Lcd_on = &B00010100                                   'LCD on parameter
Const Lcd_cur1 = &H04                                       'Cursor parameters
Const Lcd_cur2 = &H86
Const Lcd_lines = 16                                        'Number of text lines
Const Lcd_w = &H100                                         '256 pixels wide
Const Lcd_h = &H80                                          '128 pixels high
Const Ascii_spc = &H20                                      'ASCII space

'Memory location of beginning of lines
Const Lcd_l1 = Lcd_txh                                      'Line 1
Const Lcd_l2 = Lcd_cr * 1                                   'Line 2
Const Lcd_l3 = Lcd_cr * 3                                   'Line 3
Const Lcd_l4 = Lcd_cr * 4                                   'Line 4
Const Lcd_l5 = Lcd_cr * 5                                   'Line 5
Const Lcd_l6 = Lcd_cr * 6                                   'Line 6
Const Lcd_l7 = Lcd_cr * 7                                   'Line 7
Const Lcd_l8 = Lcd_cr * 8                                   'Line 8
Const Lcd_l9 = Lcd_cr * 9                                   'Line 9
Const Lcd_l10 = Lcd_cr * 10                                 'Line 10
Const Lcd_l11 = Lcd_cr * 11                                 'Line 11
Const Lcd_l12 = Lcd_cr * 12                                 'Line 12
Const Lcd_l13 = Lcd_cr * 13                                 'Line 13
Const Lcd_l14 = Lcd_cr * 14                                 'Line 14
Const Lcd_l15 = Lcd_cr * 15                                 'Line 15
Const Lcd_l16 = Lcd_cr * 16                                 'Line 16
Const Lcd_l17 = Lcd_cr * 17                                 'Line 17
Const Lcd_l18 = Lcd_cr * 18                                 'Line 18
Const Lcd_l19 = Lcd_cr * 19                                 'Line 19
Const Lcd_l20 = Lcd_cr * 20                                 'Line 20
Const Lcd_l21 = Lcd_cr * 21                                 'Line 21
Const Lcd_l22 = Lcd_cr * 22                                 'Line 22
Const Lcd_l23 = Lcd_cr * 23                                 'Line 23
Const Lcd_l24 = Lcd_cr * 24                                 'Line 24
Const Lcd_l25 = Lcd_cr * 25                                 'Line 25
Const Lcd_l26 = Lcd_cr * 26                                 'Line 26
Const Lcd_l27 = Lcd_cr * 27                                 'Line 27
Const Lcd_l28 = Lcd_cr * 28                                 'Line 28
Const Lcd_l29 = Lcd_cr * 29                                 'Line 29
Const Lcd_l30 = Lcd_cr * 30                                 'Line 30


'Define variable some may not be used in this application
'**********************************************************
'Please Note:
'YOU MAY FIND MANY UNUSED VARIABLES
'SINCE THIS IS AN ABBREVIATED VERSION OF A LARGER PROGRAM

Dim Gl_cmd As Byte
Dim Gl_byte As Byte
Dim Gl_cur As Byte
Dim Gl_i As Byte
Dim Gl_j As Byte
Dim Gl_k As Byte
Dim Gl_x As Byte
Dim Gl_y As Byte
Dim Gl_addr As Word
Dim Gl_w As Word
Dim Gl_read As Byte
Dim Gl_old As Byte
Dim Gl_addrlo As Word
Dim Gl_addrhi As Word
Dim Gl_bit As Byte
Dim Gl_rstflag As Byte
Dim Hex_nib As Byte
Dim In_array(32) As Byte
Dim Msg As String * 40
Dim Char As String * 1
Dim Dat_1 As Word
Dim Dat_2 As Word
Dim Dat As Word
Dim Tmp1 As Word
Dim Tmp2 As Word
Dim Eeaddr As Word

'Initialize
'Setup variables
Gl_j = 0
Gl_i = 0
Gl_k = 0
Gl_addr = 0
Gl_x = 0
Gl_y = 0
Gl_rstflag = 0

Reset Gl_rst                                                'rst low
Waitms 10
Set Gl_rst                                                  'rst high                                                  'Make sure reset is high


'Wait a bit and let things settle
Waitms 100


'Begin main loop
Main:

 'Initialize display
  Gosub Gl_init

Msg1:
  Gl_addr = Lcd_txh + 2                                     'Set cursor address
  Gl_cur = Sys_cur_dir_rt                                   'set cursor movement to right
  Msg = "AVR and SED1330 256x128 LCD"                       'Text to be display
  Gosub Gl_putmsg
 Wait 1
  Gl_addr = Lcd_l11 + 11
  Msg = "Ranjit Diol"
  Gosub Gl_putmsg

  Gl_addr = Lcd_l12 + 4
  Msg = "http://www.compsys1.com/"
  Gosub Gl_putmsg
Wait 1
   Gl_addr = Lcd_l13 + Lcd_grh
   Gosub Gl_setaddr
   Gl_byte = &HFF

   For Gl_i = 0 To 31
     Gosub Gl_putbyte
   Next Gl_i

  Gl_addr = Lcd_l14 + 6
  Msg = "Written in BascomAVR"
  Gosub Gl_putmsg

  Gl_addr = Lcd_l15 + 6
  Msg = "Using an AT90S8535"
  Gosub Gl_putmsg

  Wait 3
'Load image from eeprom
' **** MAKE SURE THAT YOU HAVE LOADED THE EEP or HEX IMAGE FILE (64x64 bitmap) *****

    Gl_byte = 0
    Eeaddr = 0                                              'EEprom initial address
    Gl_cur = Sys_cur_dir_rt                                 'Cursor movement right

 For Gl_addr = &H126C To &H1A4C Step Lcd_cr                 'Step by line &H20
 Gosub Gl_setaddr
       For Gl_i = 1 To 8
          Readeeprom Gl_byte , Eeaddr                       'Read the graphic byte
          Gosub Gl_putbyte                                  'Now place it
          Incr Eeaddr
       Next Gl_i
 Next Gl_addr

Fini:
Goto Fini

End


'********** Beginning of Data section ********************
'
'            SED1330F Controller Parameters
'LCD Initialization parameters are in the data section
'      =======================================
'      CHANGE ACCORDING TO YOUR LCD DATA SHEET
'       =======================================
'               256 x 128 Display
'==========================================================
'     P1     P2      P3    P4     P5     P6     P7     P8
Dat1:
Data &H30 , &H87 , &H07 , &H1F , &H52 , &H7F , &H20 , &H00
'     P1     P2     P3     P4     P5     P6
Dat2:
Data &H00 , &H00 , &H7F , &H00 , &H10 , &H7F

'==========================================================

'              OTHER RESOLUTIONS
'===============================================================
'These may or may not be correct for your LCD therefore it is
'important that you check your LCD specifications for the correct
'parameters!
'================================================================
'               192 x 128 Display
'==========================================================
'     P1     P2      P3    P4     P5     P6     P7     P8
'Dat1:
'Data &H30 , &H85 , &H07 , &H1F , &H7C , &H7F , &H20 , &H00

'     P1     P2     P3     P4     P5     P6
'Dat2:
'Data &H00 , &H00 , &H7F , &H00 , &H04 , &H7F

'==========================================================

'               240 x 64 Display
'==========================================================
'     P1     P2      P3    P4     P5     P6     P7     P8
'Dat1:
'Data &H30 , &H87 , &H07 , &H1D , &HF8 , &H3F , &H1D , &H00

'     P1     P2     P3     P4     P5     P6
'Dat2:
'Data &H00 , &H00 , &H3F , &H00 , &H04 , &H3F

'==========================================================

'               240 x 128 Display
'==========================================================
'     P1     P2      P3    P4     P5     P6     P7     P8
'Dat1:
'Data &H30 , &H87 , &H07 , &H1D , &H7F , &H7F , &H1E , &H00

'     P1     P2     P3     P4     P5     P6
'Dat2:
'Data &H00 , &H00 , &H3F , &H00 , &H04 , &H3F

'==========================================================

'               320 x 200 Display
'==========================================================
'     P1     P2      P3    P4     P5     P6     P7     P8
'Dat1:
'Data &H30 , &H87 , &H07 , &H27 , &H4F , &HC7 , &H28 , &H00

'     P1     P2     P3     P4     P5     P6
'Dat2:
'Data &H00 , &H00 , &HC7 , &H00 , &H08 , &HC7

'==========================================================

'               220 x 240 Display
'==========================================================
'     P1     P2      P3    P4     P5     P6     P7     P8
'Dat1:
'Data &H30 , &H87 , &H07 , &H27 , &H42 , &HEF , &H28 , &H00

'     P1     P2     P3     P4     P5     P6
'Dat2:
'Data &H00 , &H00 , &HEF , &H00 , &H08 , &HEF

'==========================================================


Sdat1:
Data "1" , "2" , "3" , "4" , "5" , "6" , "7" , "8" , "9" , "a" , "b" , "c" , "d" , "e" , "f"

'Data to display a 64x64 bitmap this will create an eep image
'This section can be removed once the eep file is generated
Imgdat:
$eeprom
Data &H00 , &H00 , &H00 , &H00 , &H04 , &H80 , &H00 , &H00 , &H00 , &H00 , &H00 , &H08 , &HC0 , &H60 , &H00 , &H00
Data &H00 , &H00 , &H00 , &H20 , &H5E , &HB0 , &H00 , &H00 , &H00 , &H00 , &H04 , &H34 , &H00 , &HEC , &H00 , &H00
Data &H00 , &H00 , &H00 , &HC4 , &H09 , &HBE , &H00 , &H00 , &H00 , &H00 , &H0C , &H01 , &HFF , &HFF , &H00 , &H00
Data &H00 , &H00 , &H1C , &H00 , &H7E , &HBF , &H80 , &H00 , &H00 , &H00 , &H28 , &H01 , &HE1 , &H97 , &H80 , &H00
Data &H00 , &H00 , &H7D , &H1E , &H84 , &HDF , &HC0 , &H00 , &H00 , &H01 , &H7E , &HFF , &H11 , &HEF , &HC0 , &H00
Data &H00 , &H01 , &HCA , &H7E , &H8F , &HEF , &HE0 , &H00 , &H00 , &H03 , &H29 , &H70 , &H38 , &HFF , &HF8 , &H00
Data &H00 , &H06 , &H10 , &H04 , &H40 , &H7D , &H08 , &H00 , &H00 , &H03 , &H83 , &HD0 , &H02 , &H78 , &H7C , &H00
Data &H00 , &H07 , &H21 , &H00 , &H9C , &HF7 , &H04 , &H00 , &H00 , &H07 , &H91 , &H00 , &H30 , &HF9 , &HBE , &H00
Data &H00 , &H07 , &H65 , &HBE , &HF8 , &HED , &HC6 , &H00 , &H00 , &H07 , &HB3 , &HFB , &HE8 , &HEF , &HFE , &H00
Data &H00 , &H07 , &HF8 , &HFF , &HF7 , &HE3 , &H0E , &H00 , &H00 , &H0F , &HF5 , &HE7 , &HE8 , &H01 , &HFE , &H00
Data &H00 , &H0F , &H72 , &H80 , &H00 , &H00 , &HFF , &H00 , &H00 , &H0F , &HF0 , &H80 , &H00 , &H00 , &H3E , &H00
Data &H00 , &H0F , &H60 , &H80 , &H00 , &H00 , &H7E , &H00 , &H00 , &H0E , &HE0 , &H00 , &H00 , &H00 , &H06 , &H00
Data &H00 , &H0E , &H20 , &H00 , &H00 , &H00 , &H16 , &H00 , &H00 , &H1C , &H00 , &H00 , &H00 , &H00 , &H0E , &H00
Data &H00 , &H1C , &H00 , &H00 , &H00 , &H00 , &H1E , &H00 , &H00 , &H1C , &H00 , &H00 , &H00 , &H00 , &H1E , &H00
Data &H00 , &H3C , &H00 , &H00 , &H00 , &H00 , &H1A , &H00 , &H00 , &H2C , &H00 , &H00 , &H00 , &H00 , &H06 , &H00
Data &H01 , &HAC , &H00 , &H00 , &H00 , &H00 , &H2E , &H00 , &H01 , &HCC , &H06 , &H70 , &H00 , &H00 , &H36 , &H00
Data &H02 , &HB8 , &H00 , &HF8 , &H00 , &H00 , &H1E , &H00 , &H01 , &H0C , &H01 , &H80 , &H00 , &HFE , &H0E , &H00
Data &H01 , &H2C , &H0F , &HFC , &H01 , &HF6 , &H1E , &H00 , &H00 , &H8C , &H1F , &H92 , &H03 , &H60 , &H0F , &H40
Data &H01 , &HB8 , &H03 , &HCA , &H07 , &HFC , &H1C , &H00 , &H00 , &H2C , &H01 , &HB8 , &H09 , &HAE , &H09 , &HC0
Data &H00 , &HEC , &H04 , &H00 , &H0B , &HC4 , &H16 , &H00 , &H00 , &H6C , &H00 , &H00 , &H10 , &H78 , &H14 , &H00
Data &H00 , &H4C , &H00 , &H00 , &H10 , &H80 , &H1E , &H40 , &H00 , &H1C , &H00 , &H00 , &H00 , &H70 , &H19 , &H80
Data &H00 , &H04 , &H00 , &H00 , &H00 , &H00 , &H1A , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H0F , &H00
Data &H00 , &H18 , &H00 , &H00 , &H00 , &H00 , &H3A , &H00 , &H00 , &H00 , &H00 , &H00 , &H20 , &H00 , &H22 , &H00
Data &H00 , &H00 , &H00 , &H0C , &H28 , &H00 , &H04 , &H00 , &H00 , &H04 , &H00 , &H43 , &HD0 , &H00 , &H48 , &H00
Data &H00 , &H00 , &H03 , &H80 , &H00 , &H00 , &H58 , &H00 , &H00 , &H02 , &H00 , &H00 , &H01 , &H00 , &H40 , &H00
Data &H00 , &H02 , &H01 , &HC0 , &H00 , &H80 , &H80 , &H00 , &H00 , &H00 , &H00 , &H7E , &H12 , &H80 , &H80 , &H00
Data &H00 , &H01 , &H00 , &H38 , &H5E , &H01 , &H00 , &H00 , &H00 , &H00 , &H80 , &H40 , &H30 , &H01 , &H00 , &H00
Data &H00 , &H00 , &HC0 , &H2F , &HE0 , &H02 , &H00 , &H00 , &H00 , &H00 , &H60 , &H10 , &H10 , &H04 , &H00 , &H00
Data &H00 , &H00 , &H10 , &H08 , &H20 , &H08 , &H00 , &H00 , &H00 , &H00 , &H08 , &H07 , &HC0 , &H10 , &H00 , &H00
Data &H00 , &H00 , &H04 , &H00 , &H00 , &H40 , &H00 , &H00 , &H00 , &H00 , &H02 , &H00 , &H01 , &H00 , &H00 , &H00
Data &H00 , &H00 , &H00 , &H80 , &H06 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H40 , &H08 , &H00 , &H00 , &H00
Data &H00 , &H00 , &H00 , &H30 , &H30 , &H00 , &H00 , &H00 , &H00 , &H00 , &H00 , &H03 , &H80 , &H00 , &H00 , &H00
$data
'End of eep data

'****** End of Data Section ************

'
'===== SUBROUTINES ============
'


Gl_init:                                                    'Setup LCD
 Gl_cmd = Sys_set
 Gosub Send_cmd

 For Gl_i = 0 To 7                                          'P1  P2  P3  P4  P5  P6  P7 P8
   Gl_byte = Lookup(gl_i , Dat1)
  Gosub Send_dat
 Next Gl_i

 'scroll
 Gl_cmd = Sys_scroll
 Gosub Send_cmd

 For Gl_i = 0 To 5
  Gl_byte = Lookup(gl_i , Dat2)
  Gosub Send_dat
 Next Gl_i
 'Hdot
 Gl_cmd = Sys_scroll_rate
 Gosub Send_cmd
 Gl_byte = &H0
 Gosub Send_dat

 'Overlay
 Gl_cmd = Sys_over_lay
 Gosub Send_cmd
 Gl_byte = Lcd_ol
 Gosub Send_dat

 'DISP OFF
 Gl_cmd = Lcd_disp_off
 Gosub Send_cmd
 Gl_byte = Lcd_off
 Gosub Send_dat

 'CSRW set cursor home
 Gl_cmd = Sys_cur_addr
 Gosub Send_cmd
 Gl_byte = Low(lcd_txh)                                     '&H0
 Gosub Send_dat
 Gl_byte = High(lcd_txh)                                    '&H0
 Gosub Send_dat
 Gl_cmd = Sys_cur_dir_rt
 Gosub Send_cmd
 Gl_byte = Sys_mwrite
 Gosub Send_dat
 Gl_byte = &H0
 Gosub Send_dat


 'CSR FORM
 Gl_cmd = Sys_cur_form
 Gosub Send_cmd
 Gl_byte = Lcd_cur1                                         '&H04
 Gosub Send_dat
 Gl_byte = Lcd_cur2                                         '&H86
 Gosub Send_dat

 'DISP ON
 Gl_cmd = Lcd_disp_on
 Gosub Send_cmd
 Gl_byte = Lcd_on                                           '&B00010100
 Gosub Send_dat

 'CSR DIR
 Gl_cmd = Sys_cur_dir_rt
 Gosub Send_cmd
  'Clear Graphic screen

 Gosub Gl_grfclr

 'Clear Text screen
 Gosub Gl_txtclr

Return


'Clear Graphic Screen
Gl_grfclr:
 Gl_cmd = Sys_cur_addr                                      'CSRW command
 Gosub Send_cmd
 Gl_byte = Low(lcd_grh)                                     '&H00
 Gosub Send_dat
 Gl_byte = High(lcd_grh)                                    '&H10
 Gosub Send_dat
 Gl_cmd = Sys_cur_dir_rt                                    'Cur movement right
 Gosub Send_cmd
 Gl_cmd = Sys_mwrite
 Gosub Send_cmd
 For Gl_i = 1 To Lcd_h                                      '128
    For Gl_j = 1 To Lcd_cr                                  'Char /line = 32
  Gl_byte = Lcd_normal
  Gosub Send_dat
    Next Gl_j
 Next Gl_i
Return

'Graphic home
Gl_grfhome:
 Gl_cmd = Sys_cur_addr                                      'CSRW command
 Gosub Send_cmd
 Gl_byte = Low(lcd_grh)                                     '&H00
 Gosub Send_dat
 Gl_byte = High(lcd_grh)                                    '&H10
 Gosub Send_dat
Return


'Clear Text screen
Gl_txtclr:
 Gl_cmd = Sys_cur_addr                                      'CSRW command
 Gosub Send_cmd
 Gl_byte = Low(lcd_txh)                                     '&H00
 Gosub Send_dat
 Gl_byte = High(lcd_txh)                                    '&H00
 Gosub Send_dat
 Gl_cmd = Sys_cur_dir_rt                                    'Cur movement right
 Gosub Send_cmd
 Gl_cmd = Sys_mwrite
 Gosub Send_cmd
 For Gl_i = 1 To Lcd_lines                                  '16
    For Gl_j = 1 To Lcd_cr                                  '32
  Gl_byte = Ascii_spc                                       '&H20 ASCII Space
  Gosub Send_dat
    Next Gl_j
 Next Gl_i

 Gl_cmd = Sys_cur_addr                                      'CSRW command
 Gosub Send_cmd
 Gl_byte = Low(lcd_txh)
 Gosub Send_dat
 Gl_byte = High(lcd_txh)
 Gosub Send_dat
Return

'Routine to set the address
'assumes address is in gl_addr and cursor movment in gl_cur
Gl_setaddr:
 'CSRW set cursor home
 Gl_cmd = Sys_cur_addr                                      'Address command
 Gosub Send_cmd
 Gl_byte = Low(gl_addr)                                     'Vram text memory starts at $0000 and graphics at $1000
 Gosub Send_dat
 Gl_byte = High(gl_addr)
 Gosub Send_dat
 Gl_cmd = Gl_cur                                            'Set cursor movement to left,right,up or down
 Gosub Send_cmd
Return

'Lookup hex string
Gl_find:
Hex_nib = Lookupstr(in_array(gl_i) , Sdat1)
Return

'Sending commands and data routines
Send_dat:
 Reset Gl_a0                                                'CD low
 Gl_dat = Gl_byte
 Goto Gl_strobe

Send_cmd:
 Set Gl_a0                                                  'CD high
 Gl_dat = Gl_cmd

Gl_strobe:
 Reset Gl_wr                                                'WR low
! nop
 Set Gl_wr                                                  'WR high
 Reset Gl_a0                                                'CMD low
Return

Read_lcd:                                                   'Returns gl_read
 Gl_cmd = Sys_mread
 Gosub Send_cmd
 Gl_tris = &B00000000                                       'Port input                                    'Make portd input

 Set Gl_a0                                                  'Set A0 high
 Reset Gl_rd                                                'RD low
 ! nop
 Gl_read = Gl_inp                                           'PIND                                         'Assign data
 Set Gl_rd                                                  'RD high
 Reset Gl_a0                                                'CD low high
 Gl_tris = &B11111111                                       'port output
Return


'Place a message on the display assumes msg has the text,and gl_addr has address
Gl_putmsg:

 'Set the address
 Gosub Gl_setaddr

 'MWRITE write mode
 Gl_cmd = Sys_mwrite
 Gosub Send_cmd

  'Display the text
  Gl_j = Len(msg)
  For Gl_i = 1 To Gl_j
      Char = Mid(msg , Gl_i , 1)
      Gl_byte = Char
      Gosub Send_dat
  Next Gl_x

Return

'Place a byte assumes cur direction, gl_byte and address has been set
Gl_putbyte:
  Gl_cmd = Sys_mwrite
  Gosub Send_cmd
  Gosub Send_dat
Return


'***************************************
'      E N D   O F   C O D E
'***************************************