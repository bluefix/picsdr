

                                    CDC-2313


    This is the Readme file to firmware-only CDC driver for Atmel AVR
    microcontrollers. For more information please visit
    http://www.recursion.jp/avrcdc/


SUMMARY
=======
    The AVR-CDC performs the CDC (Communication Device Class) connection over
    low-speed USB. It provides the virtual RS-232C interface without installing
    dedicated driver. The AVR-CDC is originally developed by Osamu Tamura.
    Akira Kitazawa has significantly contributed to improve this software. 


SPECIFICATION
=============
    AVR-CDC (ATtiny2313 version)
        Speed:    9600bps Fixed (rebuild to use 1200-19200bps)
        Datasize: 8
        Parity:   none
        Stopbit:  1

    Some characters may be corrupted in continuous full-duplex transaction.

    Although the CDC is supported by Windows 2000/XP/Vista, Mac OS 9.1/X,
    and Linux 2.4, CDC on low-speed USB is not allowed by the USB standard.
    Use AVR-CDC at your own risk.


USAGE
=====
    [Windows XP/2000]
    When you connect with a USB port first, a "Driver Setup Dialog" appears.
    Specify the folder in which "avrcdc.inf" exists, without searching
    automatically. Although it is warned that the driver is not certified,
    confirm it. It only loads Windows' built-in "usbser.sys". Then, the
    virtual COM port appears.
 
    [Windows Vista]
    Specify the folder in which "lowbulk.inf" exists. It loads both
    "usbser.sys" and "lowbulk.sys".

    [Mac OS X]
    You'll see the device /dev/cu.usbmodem***.

    [Linux]
    The device will be /dev/ttyACM*.
    Linux 2.6 does not accept low-speed CDC without patching the kernel.

DEVELOPMENT
===========
    Build your circuit and write firmware (cdc2313.hex) into it.
    C1:104 means 0.1uF, R3:1K5 means 1.5K ohms.
    You can select other clocks and baudrates. Modify values in
    "Configuration options" or in Makefile, and rebuild the codes.

    3.6V Vcc may not be enough for the higher clock (15-20MHz) operation.
    Consider using Zener diodes to drop the line voltage.
    See http://avrusb.wikidot.com/hardware for details.

    If the connection is unstable, try other USB-Hub or PC.

    This driver has been developed on AVR Studio 4.14 and WinAVR 20080610.
    The code size is about 2KB, and 81bytes RAM is required.

    Fuse bits
                     ext  H-L
        ATtiny2313    FF DD-FF

    * Detach the ISP programmer before restarting the device.


USING AVR-CDC FOR FREE
======================
    The AVR-CDC is published under an Open Source compliant license.
    See the file "License.txt" for details.

    You may use this driver in a form as it is. However, if you want to
    distribute a system with your vendor name, modify these files and recompile
    them;
        1. Vendor String in usbconfig.h
        2. COMPANY and MFGNAME strings in avrcdc.inf/lowbulk.inf 



    Osamu Tamura @ Recursion Co., Ltd.
    http://www.recursion.jp/avrcdc/
    3 October 2007
    27 January 2008
    25 August 2008

