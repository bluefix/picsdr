'Bitmap image 64x64 pixels
'Written in BASCOMAVR 1.11.62
'
'This will load the internal eeprom with 512 bytes of a bitmap
'You may then use AVR Studio to read and save the code as a hex file
'which can also be used to load the eeprom, after a application has been loaded.
'
'July 30, 2001
'Ranjit Diol
'Http://www.compsys1.com/workbench
'rsdiol@compsys1.com

'This file is provided "as is" and may be freely distributed


$regfile = "8535def.dat"                                    'AT90S8535 mcu

Dim I As Word
Dim Dat As Byte

Restore Img

For I = 0 To 511
    Read Dat
    Writeeeprom Dat , I
Next I

End


Img:
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
