<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<!-- saved from url=(0076)http://www.sfr-fresh.com/linux/misc/gpsd-2.37.tar.gz:a/gpsd-2.37/sirfflash.c -->
<HTML lang=en><HEAD><TITLE>SfR Fresh: [gpsd-2.37.tar.gz] Member sirfflash.c (gpsd-2.37/sirfflash.c)</TITLE>
<META http-equiv=content-type content="text/html; charset=ISO-8859-1"><LINK 
href="sirfflash_files/highlight.css" type=text/css rel=stylesheet>
<META content="MSHTML 6.00.2900.3243" name=GENERATOR></HEAD>
<BODY class=hl>
<H2><IMG alt="" src="sirfflash_files/forest1.gif"> "<A 
href="http://www.sfr-fresh.com/fresh/softarch.html">SfR Fresh</A>" - the SfR 
Freeware/Shareware Archive <IMG alt="" src="sirfflash_files/forest2.gif"></H2>
<H3>Member "gpsd-2.37/sirfflash.c" of archive <A 
href="http://www.sfr-fresh.com/linux/misc/gpsd-2.37.tar.gz/">gpsd-2.37.tar.gz</A>:</H3>
<HR>
<FONT size=-1>As a special service "SfR Fresh" has tried to format the requested 
source page into HTML format using (guessed) C and C++ source code syntax 
highlighting with prefixed line numbers. Alternatively you can here <A 
href="http://www.sfr-fresh.com/linux/misc/gpsd-2.37.tar.gz:t/gpsd-2.37/sirfflash.c">view</A> 
or <A 
href="http://www.sfr-fresh.com/linux/misc/gpsd-2.37.tar.gz:b/gpsd-2.37/sirfflash.c">download</A> 
the uninterpreted source code file. That can be also achieved for any archive 
member file by clicking within an archive contents listing on the first 
character of the file(path) respectively on the according byte size field. 
</FONT>
<HR>
<PRE class=hl><SPAN class="hl line">    1 </SPAN><SPAN class="hl com">/* $Id: sirfflash.c 4420 2007-10-12 13:44:49Z ckuethe $ */</SPAN>
<SPAN class="hl line">    2 </SPAN><SPAN class="hl com">/*</SPAN>
<SPAN class="hl line">    3 </SPAN><SPAN class="hl com"> * Copyright (c) 2005-2007 Chris Kuethe &lt;chris.kuethe@gmail.com&gt;</SPAN>
<SPAN class="hl line">    4 </SPAN><SPAN class="hl com"> * Copyright (c) 2005-2007 Eric S. Raymond &lt;esr@thyrsus.com&gt;</SPAN>
<SPAN class="hl line">    5 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">    6 </SPAN><SPAN class="hl com"> * Permission to use, copy, modify, and distribute this software for any</SPAN>
<SPAN class="hl line">    7 </SPAN><SPAN class="hl com"> * purpose with or without fee is hereby granted, provided that the above</SPAN>
<SPAN class="hl line">    8 </SPAN><SPAN class="hl com"> * copyright notice and this permission notice appear in all copies.</SPAN>
<SPAN class="hl line">    9 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">   10 </SPAN><SPAN class="hl com"> * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES</SPAN>
<SPAN class="hl line">   11 </SPAN><SPAN class="hl com"> * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF</SPAN>
<SPAN class="hl line">   12 </SPAN><SPAN class="hl com"> * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR</SPAN>
<SPAN class="hl line">   13 </SPAN><SPAN class="hl com"> * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES</SPAN>
<SPAN class="hl line">   14 </SPAN><SPAN class="hl com"> * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN</SPAN>
<SPAN class="hl line">   15 </SPAN><SPAN class="hl com"> * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF</SPAN>
<SPAN class="hl line">   16 </SPAN><SPAN class="hl com"> * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.</SPAN>
<SPAN class="hl line">   17 </SPAN><SPAN class="hl com"> */</SPAN>
<SPAN class="hl line">   18 </SPAN><SPAN class="hl com">/*</SPAN>
<SPAN class="hl line">   19 </SPAN><SPAN class="hl com"> * This is the SiRF-dependent part of the gpsflash program.</SPAN>
<SPAN class="hl line">   20 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">   21 </SPAN><SPAN class="hl com"> * If we ever compose our own S-records, dlgsp2.bin looks for this header</SPAN>
<SPAN class="hl line">   22 </SPAN><SPAN class="hl com"> * unsigned char hdr[] = "S00600004844521B\r\n";</SPAN>
<SPAN class="hl line">   23 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">   24 </SPAN><SPAN class="hl com"> * Here's what Carl Carter at SiRF told us when he sent us informattion</SPAN>
<SPAN class="hl line">   25 </SPAN><SPAN class="hl com"> * on how to build one of these:</SPAN>
<SPAN class="hl line">   26 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">   27 </SPAN><SPAN class="hl com"> * --------------------------------------------------------------------------</SPAN>
<SPAN class="hl line">   28 </SPAN><SPAN class="hl com"> * Regarding programming the flash, I will attach 2 things for you -- a</SPAN>
<SPAN class="hl line">   29 </SPAN><SPAN class="hl com"> * program called SiRFProg, the source for an older flash programming</SPAN>
<SPAN class="hl line">   30 </SPAN><SPAN class="hl com"> * utility, and a description of the ROM operation.  Note that while the</SPAN>
<SPAN class="hl line">   31 </SPAN><SPAN class="hl com"> * ROM description document is for SiRFstarIII, the interface applies to</SPAN>
<SPAN class="hl line">   32 </SPAN><SPAN class="hl com"> * SiRFstarII systems like you are using.  Here is a little guide to how</SPAN>
<SPAN class="hl line">   33 </SPAN><SPAN class="hl com"> * things work:</SPAN>
<SPAN class="hl line">   34 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">   35 </SPAN><SPAN class="hl com"> * 1.  The receiver is put into "internal boot" mode -- this means that it</SPAN>
<SPAN class="hl line">   36 </SPAN><SPAN class="hl com"> * is running off the code contained in the internal ROM rather than the</SPAN>
<SPAN class="hl line">   37 </SPAN><SPAN class="hl com"> * external flash.  You do this by either putting a pull-up resistor on</SPAN>
<SPAN class="hl line">   38 </SPAN><SPAN class="hl com"> * data line 0 and cycling power or by giving a message ID 148.</SPAN>
<SPAN class="hl line">   39 </SPAN><SPAN class="hl com"> * 2.  The internal ROM provides a very primitive boot loader that permits</SPAN>
<SPAN class="hl line">   40 </SPAN><SPAN class="hl com"> * you to load a program into RAM and then switch to it.</SPAN>
<SPAN class="hl line">   41 </SPAN><SPAN class="hl com"> * 3.  The program in RAM is used to handle the erasing and programming</SPAN>
<SPAN class="hl line">   42 </SPAN><SPAN class="hl com"> * chores, so theoretically you could create any program of your own</SPAN>
<SPAN class="hl line">   43 </SPAN><SPAN class="hl com"> * choosing to handle things.  SiRFProg gives you an example of how to do</SPAN>
<SPAN class="hl line">   44 </SPAN><SPAN class="hl com"> * it using Motorola S record files as the programming source.  The program</SPAN>
<SPAN class="hl line">   45 </SPAN><SPAN class="hl com"> * that resides on the programming host handles sending down the RAM</SPAN>
<SPAN class="hl line">   46 </SPAN><SPAN class="hl com"> * program, then communicating with it to transfer the data to program.</SPAN>
<SPAN class="hl line">   47 </SPAN><SPAN class="hl com"> * 4.  Once the programming is complete, you transfer to it by switching to</SPAN>
<SPAN class="hl line">   48 </SPAN><SPAN class="hl com"> * "external boot" mode -- generally this requires a pull-down resistor on</SPAN>
<SPAN class="hl line">   49 </SPAN><SPAN class="hl com"> * data line 0 and either a power cycle or toggling the reset line low then</SPAN>
<SPAN class="hl line">   50 </SPAN><SPAN class="hl com"> * back high.  There is no command that does this.</SPAN>
<SPAN class="hl line">   51 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">   52 </SPAN><SPAN class="hl com"> * Our standard utility operates much faster than SiRFProg by using a</SPAN>
<SPAN class="hl line">   53 </SPAN><SPAN class="hl com"> * couple tricks.  One, it transfers a binary image rather than S records</SPAN>
<SPAN class="hl line">   54 </SPAN><SPAN class="hl com"> * (which are ASCII and about 3x the size of the image).  Two, it</SPAN>
<SPAN class="hl line">   55 </SPAN><SPAN class="hl com"> * compresses the binary image using some standard compression algorithm.</SPAN>
<SPAN class="hl line">   56 </SPAN><SPAN class="hl com"> * Three, when transferring the file we boost the port baud rate.  Normally</SPAN>
<SPAN class="hl line">   57 </SPAN><SPAN class="hl com"> * we use 115200 baud as that is all the drivers in most receivers handle.</SPAN>
<SPAN class="hl line">   58 </SPAN><SPAN class="hl com"> * But when supported, we can boost up to 900 kbaud.  Programming at 38400</SPAN>
<SPAN class="hl line">   59 </SPAN><SPAN class="hl com"> * takes a couple minutes.  At 115200 it takes usually under 30 seconds.</SPAN>
<SPAN class="hl line">   60 </SPAN><SPAN class="hl com"> * At 900 k it takes about 6 seconds.</SPAN>
<SPAN class="hl line">   61 </SPAN><SPAN class="hl com"> * --------------------------------------------------------------------------</SPAN>
<SPAN class="hl line">   62 </SPAN><SPAN class="hl com"> *</SPAN>
<SPAN class="hl line">   63 </SPAN><SPAN class="hl com"> * Copyright (c) 2005 Chris Kuethe &lt;chris.kuethe@gmail.com&gt;</SPAN>
<SPAN class="hl line">   64 </SPAN><SPAN class="hl com"> */</SPAN>
<SPAN class="hl line">   65 </SPAN>
<SPAN class="hl line">   66 </SPAN><SPAN class="hl dir">#include &lt;sys/types.h&gt;</SPAN>
<SPAN class="hl line">   67 </SPAN><SPAN class="hl dir">#include</SPAN> <SPAN class="hl dstr">"gpsd_config.h"</SPAN><SPAN class="hl dir"></SPAN>
<SPAN class="hl line">   68 </SPAN><SPAN class="hl dir">#include</SPAN> <SPAN class="hl dstr">"gpsd.h"</SPAN><SPAN class="hl dir"></SPAN>
<SPAN class="hl line">   69 </SPAN><SPAN class="hl dir">#include</SPAN> <SPAN class="hl dstr">"gpsflash.h"</SPAN><SPAN class="hl dir"></SPAN>
<SPAN class="hl line">   70 </SPAN>
<SPAN class="hl line">   71 </SPAN><SPAN class="hl dir">#if defined(SIRF_ENABLE) &amp;&amp; defined(BINARY_ENABLE)</SPAN>
<SPAN class="hl line">   72 </SPAN>
<SPAN class="hl line">   73 </SPAN><SPAN class="hl com">/* From the SiRF protocol manual... may as well be consistent */</SPAN>
<SPAN class="hl line">   74 </SPAN><SPAN class="hl dir">#define PROTO_SIRF 0</SPAN>
<SPAN class="hl line">   75 </SPAN><SPAN class="hl dir">#define PROTO_NMEA 1</SPAN>
<SPAN class="hl line">   76 </SPAN>
<SPAN class="hl line">   77 </SPAN><SPAN class="hl dir">#define BOOST_38400 0</SPAN>
<SPAN class="hl line">   78 </SPAN><SPAN class="hl dir">#define BOOST_57600 1</SPAN>
<SPAN class="hl line">   79 </SPAN><SPAN class="hl dir">#define BOOST_115200 2</SPAN>
<SPAN class="hl line">   80 </SPAN>
<SPAN class="hl line">   81 </SPAN><SPAN class="hl kwb">static int</SPAN>
<SPAN class="hl line">   82 </SPAN><SPAN class="hl kwd">sirfSendUpdateCmd</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> pfd<SPAN class="hl sym">){</SPAN>
<SPAN class="hl line">   83 </SPAN>	<SPAN class="hl kwb">bool</SPAN> status<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">   84 </SPAN>	<SPAN class="hl com">/*@ +charint @*/</SPAN>
<SPAN class="hl line">   85 </SPAN>	<SPAN class="hl kwb">static unsigned char</SPAN> msg<SPAN class="hl sym">[] =	{</SPAN>
<SPAN class="hl line">   86 </SPAN>	    			<SPAN class="hl num">0xa0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0xa2</SPAN><SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* header */</SPAN>
<SPAN class="hl line">   87 </SPAN>				<SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0x01</SPAN><SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* message length */</SPAN>
<SPAN class="hl line">   88 </SPAN>				<SPAN class="hl num">0x94</SPAN><SPAN class="hl sym">,</SPAN>		<SPAN class="hl com">/* 0x94: firmware update */</SPAN>
<SPAN class="hl line">   89 </SPAN>				<SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* checksum */</SPAN>
<SPAN class="hl line">   90 </SPAN>				<SPAN class="hl num">0xb0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0xb3</SPAN><SPAN class="hl sym">};</SPAN>	<SPAN class="hl com">/* trailer */</SPAN>
<SPAN class="hl line">   91 </SPAN>	<SPAN class="hl com">/*@ -charint @*/</SPAN>
<SPAN class="hl line">   92 </SPAN>	status <SPAN class="hl sym">=</SPAN> <SPAN class="hl kwd">sirf_write</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> msg<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">   93 </SPAN>	<SPAN class="hl com">/* wait a moment for the receiver to switch to boot rom */</SPAN>
<SPAN class="hl line">   94 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">sleep</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl num">2</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">   95 </SPAN>	<SPAN class="hl kwa">return</SPAN> status ? <SPAN class="hl num">0</SPAN> <SPAN class="hl sym">: -</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">   96 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">   97 </SPAN>
<SPAN class="hl line">   98 </SPAN><SPAN class="hl kwb">static int</SPAN>
<SPAN class="hl line">   99 </SPAN><SPAN class="hl kwd">sirfSendLoader</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> pfd<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">struct</SPAN> termios <SPAN class="hl sym">*</SPAN>term<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">char</SPAN> <SPAN class="hl sym">*</SPAN>loader<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">size_t</SPAN> ls<SPAN class="hl sym">){</SPAN>
<SPAN class="hl line">  100 </SPAN>	<SPAN class="hl kwb">unsigned int</SPAN> x<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  101 </SPAN>	<SPAN class="hl kwb">int</SPAN> r<SPAN class="hl sym">,</SPAN> speed <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">38400</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  102 </SPAN>	<SPAN class="hl com">/*@i@*/</SPAN><SPAN class="hl kwb">unsigned char</SPAN> boost<SPAN class="hl sym">[] = {</SPAN><SPAN class="hl str">'S'</SPAN><SPAN class="hl sym">,</SPAN> BOOST_38400<SPAN class="hl sym">};</SPAN>
<SPAN class="hl line">  103 </SPAN>	<SPAN class="hl kwb">unsigned char</SPAN> <SPAN class="hl sym">*</SPAN>msg<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  104 </SPAN>
<SPAN class="hl line">  105 </SPAN>	<SPAN class="hl kwa">if</SPAN><SPAN class="hl sym">((</SPAN>msg <SPAN class="hl sym">=</SPAN> <SPAN class="hl kwd">malloc</SPAN><SPAN class="hl sym">(</SPAN>ls<SPAN class="hl sym">+</SPAN><SPAN class="hl num">10</SPAN><SPAN class="hl sym">)) ==</SPAN> NULL<SPAN class="hl sym">){</SPAN>
<SPAN class="hl line">  106 </SPAN>		<SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">-</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">;</SPAN> <SPAN class="hl com">/* oops. bail out */</SPAN>
<SPAN class="hl line">  107 </SPAN>	<SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  108 </SPAN>
<SPAN class="hl line">  109 </SPAN>	<SPAN class="hl com">/*@ +charint @*/</SPAN>
<SPAN class="hl line">  110 </SPAN><SPAN class="hl dir">#ifdef B115200</SPAN>
<SPAN class="hl line">  111 </SPAN>	speed <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">115200</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  112 </SPAN>	boost<SPAN class="hl sym">[</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">] =</SPAN> BOOST_115200<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  113 </SPAN><SPAN class="hl dir">#else</SPAN>
<SPAN class="hl line">  114 </SPAN><SPAN class="hl dir">#ifdef B57600</SPAN>
<SPAN class="hl line">  115 </SPAN>	speed <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">57600</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  116 </SPAN>	boost<SPAN class="hl sym">[</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">] =</SPAN> BOOST_57600<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  117 </SPAN><SPAN class="hl dir">#endif</SPAN>
<SPAN class="hl line">  118 </SPAN><SPAN class="hl dir">#endif</SPAN>
<SPAN class="hl line">  119 </SPAN>	<SPAN class="hl com">/*@ -charint @*/</SPAN>
<SPAN class="hl line">  120 </SPAN>
<SPAN class="hl line">  121 </SPAN>	x <SPAN class="hl sym">= (</SPAN><SPAN class="hl kwb">unsigned</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">htonl</SPAN><SPAN class="hl sym">(</SPAN>ls<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  122 </SPAN>	msg<SPAN class="hl sym">[</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">] =</SPAN> <SPAN class="hl str">'S'</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  123 </SPAN>	msg<SPAN class="hl sym">[</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">] = (</SPAN><SPAN class="hl kwb">unsigned char</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  124 </SPAN>	<SPAN class="hl kwd">memcpy</SPAN><SPAN class="hl sym">(</SPAN>msg<SPAN class="hl sym">+</SPAN><SPAN class="hl num">2</SPAN><SPAN class="hl sym">, &amp;</SPAN>x<SPAN class="hl sym">,</SPAN> <SPAN class="hl num">4</SPAN><SPAN class="hl sym">);</SPAN> <SPAN class="hl com">/* length */</SPAN>
<SPAN class="hl line">  125 </SPAN>	<SPAN class="hl kwd">memcpy</SPAN><SPAN class="hl sym">(</SPAN>msg<SPAN class="hl sym">+</SPAN><SPAN class="hl num">6</SPAN><SPAN class="hl sym">,</SPAN> loader<SPAN class="hl sym">,</SPAN> ls<SPAN class="hl sym">);</SPAN> <SPAN class="hl com">/* loader */</SPAN>
<SPAN class="hl line">  126 </SPAN>	<SPAN class="hl kwd">memset</SPAN><SPAN class="hl sym">(</SPAN>msg<SPAN class="hl sym">+</SPAN><SPAN class="hl num">6</SPAN><SPAN class="hl sym">+</SPAN>ls<SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">4</SPAN><SPAN class="hl sym">);</SPAN> <SPAN class="hl com">/* reset vector */</SPAN>
<SPAN class="hl line">  127 </SPAN>
<SPAN class="hl line">  128 </SPAN>	<SPAN class="hl com">/* send the command to jack up the speed */</SPAN>
<SPAN class="hl line">  129 </SPAN>	<SPAN class="hl kwa">if</SPAN><SPAN class="hl sym">((</SPAN>r <SPAN class="hl sym">= (</SPAN><SPAN class="hl kwb">int</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">write</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> boost<SPAN class="hl sym">,</SPAN> <SPAN class="hl num">2</SPAN><SPAN class="hl sym">)) !=</SPAN> <SPAN class="hl num">2</SPAN><SPAN class="hl sym">) {</SPAN>
<SPAN class="hl line">  130 </SPAN>		<SPAN class="hl kwd">free</SPAN><SPAN class="hl sym">(</SPAN>msg<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  131 </SPAN>		<SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">-</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">;</SPAN> <SPAN class="hl com">/* oops. bail out */</SPAN>
<SPAN class="hl line">  132 </SPAN>	<SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  133 </SPAN>
<SPAN class="hl line">  134 </SPAN>	<SPAN class="hl com">/* wait for the serial speed change to take effect */</SPAN>
<SPAN class="hl line">  135 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">tcdrain</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  136 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">usleep</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl num">1000</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  137 </SPAN>
<SPAN class="hl line">  138 </SPAN>	<SPAN class="hl com">/* now set up the serial port at this higher speed */</SPAN>
<SPAN class="hl line">  139 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">serialSpeed</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> term<SPAN class="hl sym">,</SPAN> speed<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  140 </SPAN>
<SPAN class="hl line">  141 </SPAN>	<SPAN class="hl com">/* ship the actual data */</SPAN>
<SPAN class="hl line">  142 </SPAN>	r <SPAN class="hl sym">=</SPAN> <SPAN class="hl kwd">binary_send</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">, (</SPAN><SPAN class="hl kwb">char</SPAN> <SPAN class="hl sym">*)</SPAN>msg<SPAN class="hl sym">,</SPAN> ls<SPAN class="hl sym">+</SPAN><SPAN class="hl num">10</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  143 </SPAN>	<SPAN class="hl kwd">free</SPAN><SPAN class="hl sym">(</SPAN>msg<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  144 </SPAN>	<SPAN class="hl kwa">return</SPAN> r<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  145 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  146 </SPAN>
<SPAN class="hl line">  147 </SPAN><SPAN class="hl kwb">static int</SPAN>
<SPAN class="hl line">  148 </SPAN><SPAN class="hl kwd">sirfSetProto</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> pfd<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">struct</SPAN> termios <SPAN class="hl sym">*</SPAN>term<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">unsigned int</SPAN> speed<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">unsigned int</SPAN> proto<SPAN class="hl sym">){</SPAN>
<SPAN class="hl line">  149 </SPAN>	<SPAN class="hl kwb">int</SPAN> i<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  150 </SPAN>	<SPAN class="hl kwb">int</SPAN> spd<SPAN class="hl sym">[</SPAN><SPAN class="hl num">8</SPAN><SPAN class="hl sym">] = {</SPAN><SPAN class="hl num">115200</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">57600</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">38400</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">28800</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">19200</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">14400</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">9600</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">4800</SPAN><SPAN class="hl sym">};</SPAN>
<SPAN class="hl line">  151 </SPAN>	<SPAN class="hl com">/*@ +charint @*/</SPAN>
<SPAN class="hl line">  152 </SPAN>	<SPAN class="hl kwb">static unsigned char</SPAN> sirf<SPAN class="hl sym">[] =	{</SPAN>
<SPAN class="hl line">  153 </SPAN>				<SPAN class="hl num">0xa0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0xa2</SPAN><SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* header */</SPAN>
<SPAN class="hl line">  154 </SPAN>				<SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0x31</SPAN><SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* message length */</SPAN>
<SPAN class="hl line">  155 </SPAN>				<SPAN class="hl num">0xa5</SPAN><SPAN class="hl sym">,</SPAN>		<SPAN class="hl com">/* message 0xa5: UART config */</SPAN>
<SPAN class="hl line">  156 </SPAN>				<SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">8</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl com">/* port 0 */</SPAN>
<SPAN class="hl line">  157 </SPAN>				<SPAN class="hl num">0xff</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl com">/* port 1 */</SPAN>
<SPAN class="hl line">  158 </SPAN>				<SPAN class="hl num">0xff</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl com">/* port 2 */</SPAN>
<SPAN class="hl line">  159 </SPAN>				<SPAN class="hl num">0xff</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl com">/* port 3 */</SPAN>
<SPAN class="hl line">  160 </SPAN>				<SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* checksum */</SPAN>
<SPAN class="hl line">  161 </SPAN>				<SPAN class="hl num">0xb0</SPAN><SPAN class="hl sym">,</SPAN><SPAN class="hl num">0xb3</SPAN><SPAN class="hl sym">};</SPAN>	<SPAN class="hl com">/* trailer */</SPAN>
<SPAN class="hl line">  162 </SPAN>	<SPAN class="hl com">/*@ -charint @*/</SPAN>
<SPAN class="hl line">  163 </SPAN>
<SPAN class="hl line">  164 </SPAN>	<SPAN class="hl kwa">if</SPAN> <SPAN class="hl sym">(</SPAN><SPAN class="hl kwd">serialConfig</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> term<SPAN class="hl sym">,</SPAN> <SPAN class="hl num">38400</SPAN><SPAN class="hl sym">) == -</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  165 </SPAN>		<SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">-</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  166 </SPAN>
<SPAN class="hl line">  167 </SPAN>	sirf<SPAN class="hl sym">[</SPAN><SPAN class="hl num">7</SPAN><SPAN class="hl sym">] =</SPAN> sirf<SPAN class="hl sym">[</SPAN><SPAN class="hl num">6</SPAN><SPAN class="hl sym">] = (</SPAN><SPAN class="hl kwb">unsigned char</SPAN><SPAN class="hl sym">)</SPAN>proto<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  168 </SPAN>	<SPAN class="hl com">/*@i@*/</SPAN>i <SPAN class="hl sym">=</SPAN> <SPAN class="hl kwd">htonl</SPAN><SPAN class="hl sym">(</SPAN>speed<SPAN class="hl sym">);</SPAN> <SPAN class="hl com">/* borrow "i" to put speed into proper byte order */</SPAN>
<SPAN class="hl line">  169 </SPAN>	<SPAN class="hl com">/*@i@*/</SPAN><SPAN class="hl kwd">bcopy</SPAN><SPAN class="hl sym">(&amp;</SPAN>i<SPAN class="hl sym">,</SPAN> sirf<SPAN class="hl sym">+</SPAN><SPAN class="hl num">8</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">4</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  170 </SPAN>
<SPAN class="hl line">  171 </SPAN>	<SPAN class="hl com">/* send at whatever baud we're currently using */</SPAN>
<SPAN class="hl line">  172 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">sirf_write</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> sirf<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  173 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">nmea_send</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> <SPAN class="hl str">"$PSRF100,%u,%u,8,1,0"</SPAN><SPAN class="hl sym">,</SPAN> speed<SPAN class="hl sym">,</SPAN> proto<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  174 </SPAN>
<SPAN class="hl line">  175 </SPAN>	<SPAN class="hl com">/* now spam the receiver with the config messages */</SPAN>
<SPAN class="hl line">  176 </SPAN>	<SPAN class="hl kwa">for</SPAN><SPAN class="hl sym">(</SPAN>i <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">;</SPAN> i <SPAN class="hl sym">&lt; (</SPAN><SPAN class="hl kwb">int</SPAN><SPAN class="hl sym">)(</SPAN><SPAN class="hl kwa">sizeof</SPAN><SPAN class="hl sym">(</SPAN>spd<SPAN class="hl sym">)/</SPAN><SPAN class="hl kwa">sizeof</SPAN><SPAN class="hl sym">(</SPAN>spd<SPAN class="hl sym">[</SPAN><SPAN class="hl num">0</SPAN><SPAN class="hl sym">]));</SPAN> i<SPAN class="hl sym">++) {</SPAN>
<SPAN class="hl line">  177 </SPAN>		<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">serialSpeed</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> term<SPAN class="hl sym">,</SPAN> spd<SPAN class="hl sym">[</SPAN>i<SPAN class="hl sym">]);</SPAN>
<SPAN class="hl line">  178 </SPAN>		<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">sirf_write</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> sirf<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  179 </SPAN>		<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">nmea_send</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> <SPAN class="hl str">"$PSRF100,%u,%u,8,1,0"</SPAN><SPAN class="hl sym">,</SPAN> speed<SPAN class="hl sym">,</SPAN> proto<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  180 </SPAN>		<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">tcdrain</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  181 </SPAN>		<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">usleep</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl num">100000</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  182 </SPAN>	<SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  183 </SPAN>
<SPAN class="hl line">  184 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">serialSpeed</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> term<SPAN class="hl sym">, (</SPAN><SPAN class="hl kwb">int</SPAN><SPAN class="hl sym">)</SPAN>speed<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  185 </SPAN>	<SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">void</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">tcflush</SPAN><SPAN class="hl sym">(</SPAN>pfd<SPAN class="hl sym">,</SPAN> TCIOFLUSH<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  186 </SPAN>
<SPAN class="hl line">  187 </SPAN>	<SPAN class="hl kwa">return</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  188 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  189 </SPAN>
<SPAN class="hl line">  190 </SPAN><SPAN class="hl com">/*@ -nullstate @*/</SPAN>
<SPAN class="hl line">  191 </SPAN><SPAN class="hl kwb">static int</SPAN> <SPAN class="hl kwd">sirfProbe</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> fd<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">char</SPAN> <SPAN class="hl sym">**</SPAN>version<SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  192 </SPAN><SPAN class="hl com">/* try to elicit a return packet with the firmware version in it */</SPAN>
<SPAN class="hl line">  193 </SPAN><SPAN class="hl sym">{</SPAN>
<SPAN class="hl line">  194 </SPAN>    <SPAN class="hl com">/*@ +charint @*/</SPAN>
<SPAN class="hl line">  195 </SPAN>    <SPAN class="hl kwb">static unsigned char</SPAN> versionprobe<SPAN class="hl sym">[] = {</SPAN>
<SPAN class="hl line">  196 </SPAN>				    <SPAN class="hl num">0xa0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0xa2</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0x02</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  197 </SPAN>				    <SPAN class="hl num">0x84</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  198 </SPAN>				    <SPAN class="hl num">0x00</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0x84</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0xb0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0xb3</SPAN><SPAN class="hl sym">};</SPAN>
<SPAN class="hl line">  199 </SPAN>    <SPAN class="hl com">/*@ -charint @*/</SPAN>
<SPAN class="hl line">  200 </SPAN>    <SPAN class="hl kwb">char</SPAN> buf<SPAN class="hl sym">[</SPAN>MAX_PACKET_LENGTH<SPAN class="hl sym">];</SPAN>
<SPAN class="hl line">  201 </SPAN>    ssize_t status<SPAN class="hl sym">,</SPAN> want<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  202 </SPAN>
<SPAN class="hl line">  203 </SPAN>    <SPAN class="hl kwd">gpsd_report</SPAN><SPAN class="hl sym">(</SPAN>LOG_PROG<SPAN class="hl sym">,</SPAN> <SPAN class="hl str">"probing with %s</SPAN><SPAN class="hl esc">\n</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  204 </SPAN>		<SPAN class="hl kwd">gpsd_hexdump</SPAN><SPAN class="hl sym">(</SPAN>versionprobe<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwa">sizeof</SPAN><SPAN class="hl sym">(</SPAN>versionprobe<SPAN class="hl sym">)));</SPAN>
<SPAN class="hl line">  205 </SPAN>    <SPAN class="hl kwa">if</SPAN> <SPAN class="hl sym">((</SPAN>status <SPAN class="hl sym">=</SPAN> <SPAN class="hl kwd">write</SPAN><SPAN class="hl sym">(</SPAN>fd<SPAN class="hl sym">,</SPAN> versionprobe<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwa">sizeof</SPAN><SPAN class="hl sym">(</SPAN>versionprobe<SPAN class="hl sym">))) !=</SPAN> <SPAN class="hl num">10</SPAN><SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  206 </SPAN>	<SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">-</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  207 </SPAN>    <SPAN class="hl com">/*</SPAN>
<SPAN class="hl line">  208 </SPAN><SPAN class="hl com">     * Older SiRF chips had a 21-character version message.  Newer</SPAN>
<SPAN class="hl line">  209 </SPAN><SPAN class="hl com">     * ones (GSW 2.3.2 or later) have an 81-character version message.</SPAN>
<SPAN class="hl line">  210 </SPAN><SPAN class="hl com">     * Accept either.</SPAN>
<SPAN class="hl line">  211 </SPAN><SPAN class="hl com">     */</SPAN>
<SPAN class="hl line">  212 </SPAN>    want <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  213 </SPAN>    <SPAN class="hl kwa">if</SPAN> <SPAN class="hl sym">(</SPAN><SPAN class="hl kwd">expect</SPAN><SPAN class="hl sym">(</SPAN>fd<SPAN class="hl sym">,</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl esc">\xa0\xa2\x00\x15\x06</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">5</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">1</SPAN><SPAN class="hl sym">))</SPAN>
<SPAN class="hl line">  214 </SPAN>	want <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">21</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  215 </SPAN>    <SPAN class="hl kwa">else if</SPAN> <SPAN class="hl sym">(</SPAN><SPAN class="hl kwd">expect</SPAN><SPAN class="hl sym">(</SPAN>fd<SPAN class="hl sym">,</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl esc">\xa0\xa2\x00\x51\x06</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">5</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl num">1</SPAN><SPAN class="hl sym">))</SPAN>
<SPAN class="hl line">  216 </SPAN>	want <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">81</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  217 </SPAN>
<SPAN class="hl line">  218 </SPAN>    <SPAN class="hl kwa">if</SPAN> <SPAN class="hl sym">(</SPAN>want<SPAN class="hl sym">) {</SPAN>
<SPAN class="hl line">  219 </SPAN>	ssize_t len<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  220 </SPAN>	<SPAN class="hl kwd">memset</SPAN><SPAN class="hl sym">(</SPAN>buf<SPAN class="hl sym">,</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">,</SPAN> <SPAN class="hl kwa">sizeof</SPAN><SPAN class="hl sym">(</SPAN>buf<SPAN class="hl sym">));</SPAN>
<SPAN class="hl line">  221 </SPAN>	<SPAN class="hl kwa">for</SPAN> <SPAN class="hl sym">(</SPAN>len <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">;</SPAN> len <SPAN class="hl sym">&lt;</SPAN> want<SPAN class="hl sym">;</SPAN> len <SPAN class="hl sym">+=</SPAN> status<SPAN class="hl sym">) {</SPAN>
<SPAN class="hl line">  222 </SPAN>	    status <SPAN class="hl sym">=</SPAN> <SPAN class="hl kwd">read</SPAN><SPAN class="hl sym">(</SPAN>fd<SPAN class="hl sym">,</SPAN> buf<SPAN class="hl sym">+</SPAN>len<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwa">sizeof</SPAN><SPAN class="hl sym">(</SPAN>buf<SPAN class="hl sym">));</SPAN>
<SPAN class="hl line">  223 </SPAN>	    <SPAN class="hl kwa">if</SPAN> <SPAN class="hl sym">(</SPAN>status <SPAN class="hl sym">== -</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  224 </SPAN>		<SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">-</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  225 </SPAN>	<SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  226 </SPAN>	<SPAN class="hl kwd">gpsd_report</SPAN><SPAN class="hl sym">(</SPAN>LOG_PROG<SPAN class="hl sym">,</SPAN> <SPAN class="hl str">"%d bytes = %s</SPAN><SPAN class="hl esc">\n</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl sym">,</SPAN> len<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwd">gpsd_hexdump</SPAN><SPAN class="hl sym">(</SPAN>buf<SPAN class="hl sym">, (</SPAN><SPAN class="hl kwb">size_t</SPAN><SPAN class="hl sym">)</SPAN>len<SPAN class="hl sym">));</SPAN>
<SPAN class="hl line">  227 </SPAN>	<SPAN class="hl sym">*</SPAN>version <SPAN class="hl sym">=</SPAN> <SPAN class="hl kwd">strdup</SPAN><SPAN class="hl sym">(</SPAN>buf<SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  228 </SPAN>	<SPAN class="hl kwa">return</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  229 </SPAN>    <SPAN class="hl sym">}</SPAN> <SPAN class="hl kwa">else</SPAN> <SPAN class="hl sym">{</SPAN>
<SPAN class="hl line">  230 </SPAN>	<SPAN class="hl sym">*</SPAN>version <SPAN class="hl sym">=</SPAN> NULL<SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  231 </SPAN>	<SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">-</SPAN><SPAN class="hl num">1</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  232 </SPAN>    <SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  233 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  234 </SPAN><SPAN class="hl com">/*@ +nullstate @*/</SPAN>
<SPAN class="hl line">  235 </SPAN>
<SPAN class="hl line">  236 </SPAN><SPAN class="hl kwb">static int</SPAN> <SPAN class="hl kwd">sirfPortSetup</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> fd<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">struct</SPAN> termios <SPAN class="hl sym">*</SPAN>term<SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  237 </SPAN><SPAN class="hl sym">{</SPAN>
<SPAN class="hl line">  238 </SPAN>    <SPAN class="hl com">/* the firware upload defaults to 38k4, so let's go there */</SPAN>
<SPAN class="hl line">  239 </SPAN>    <SPAN class="hl kwa">return</SPAN> <SPAN class="hl kwd">sirfSetProto</SPAN><SPAN class="hl sym">(</SPAN>fd<SPAN class="hl sym">,</SPAN> term<SPAN class="hl sym">,</SPAN> PROTO_SIRF<SPAN class="hl sym">,</SPAN> <SPAN class="hl num">38400</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  240 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  241 </SPAN>
<SPAN class="hl line">  242 </SPAN><SPAN class="hl kwb">static int</SPAN> <SPAN class="hl kwd">sirfVersionCheck</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> fd UNUSED<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">const char</SPAN> <SPAN class="hl sym">*</SPAN>version UNUSED<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  243 </SPAN>			    <SPAN class="hl kwb">const char</SPAN> <SPAN class="hl sym">*</SPAN>loader UNUSED<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">size_t</SPAN> ls UNUSED<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  244 </SPAN>			    <SPAN class="hl kwb">const char</SPAN> <SPAN class="hl sym">*</SPAN>firmware UNUSED<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">size_t</SPAN> fs UNUSED<SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  245 </SPAN><SPAN class="hl sym">{</SPAN>
<SPAN class="hl line">  246 </SPAN>    <SPAN class="hl com">/*</SPAN>
<SPAN class="hl line">  247 </SPAN><SPAN class="hl com">     * This implies that any SiRF loader and firmware image is good for</SPAN>
<SPAN class="hl line">  248 </SPAN><SPAN class="hl com">     * any SiRF chip.  We really want to do more checking here...</SPAN>
<SPAN class="hl line">  249 </SPAN><SPAN class="hl com">     */</SPAN>
<SPAN class="hl line">  250 </SPAN>    <SPAN class="hl kwa">return</SPAN> <SPAN class="hl num">0</SPAN><SPAN class="hl sym">;</SPAN>
<SPAN class="hl line">  251 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  252 </SPAN>
<SPAN class="hl line">  253 </SPAN><SPAN class="hl kwb">static int</SPAN> <SPAN class="hl kwd">wait2seconds</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> fd UNUSED<SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  254 </SPAN><SPAN class="hl sym">{</SPAN>
<SPAN class="hl line">  255 </SPAN>    <SPAN class="hl com">/* again we wait, this time for our uploaded code to start running */</SPAN>
<SPAN class="hl line">  256 </SPAN>    <SPAN class="hl kwd">gpsd_report</SPAN><SPAN class="hl sym">(</SPAN>LOG_PROG<SPAN class="hl sym">,</SPAN> <SPAN class="hl str">"waiting 2 seconds...</SPAN><SPAN class="hl esc">\n</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  257 </SPAN>    <SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">sleep</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl num">2</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  258 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  259 </SPAN>
<SPAN class="hl line">  260 </SPAN><SPAN class="hl kwb">static int</SPAN> <SPAN class="hl kwd">wait5seconds</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> fd UNUSED<SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  261 </SPAN><SPAN class="hl sym">{</SPAN>
<SPAN class="hl line">  262 </SPAN>    <SPAN class="hl com">/* wait for firmware upload to settle in */</SPAN>
<SPAN class="hl line">  263 </SPAN>    <SPAN class="hl kwd">gpsd_report</SPAN><SPAN class="hl sym">(</SPAN>LOG_PROG<SPAN class="hl sym">,</SPAN> <SPAN class="hl str">"waiting 5 seconds...</SPAN><SPAN class="hl esc">\n</SPAN><SPAN class="hl str">"</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  264 </SPAN>    <SPAN class="hl kwa">return</SPAN> <SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN><SPAN class="hl sym">)</SPAN><SPAN class="hl kwd">sleep</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl num">5</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  265 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  266 </SPAN>
<SPAN class="hl line">  267 </SPAN><SPAN class="hl kwb">static int</SPAN> <SPAN class="hl kwd">sirfPortWrapup</SPAN><SPAN class="hl sym">(</SPAN><SPAN class="hl kwb">int</SPAN> fd<SPAN class="hl sym">,</SPAN> <SPAN class="hl kwb">struct</SPAN> termios <SPAN class="hl sym">*</SPAN>term<SPAN class="hl sym">)</SPAN>
<SPAN class="hl line">  268 </SPAN><SPAN class="hl sym">{</SPAN>
<SPAN class="hl line">  269 </SPAN>    <SPAN class="hl com">/* waitaminnit, and drop back to NMEA@4800 for luser apps */</SPAN>
<SPAN class="hl line">  270 </SPAN>    <SPAN class="hl kwa">return</SPAN> <SPAN class="hl kwd">sirfSetProto</SPAN><SPAN class="hl sym">(</SPAN>fd<SPAN class="hl sym">,</SPAN> term<SPAN class="hl sym">,</SPAN> PROTO_NMEA<SPAN class="hl sym">,</SPAN> <SPAN class="hl num">4800</SPAN><SPAN class="hl sym">);</SPAN>
<SPAN class="hl line">  271 </SPAN><SPAN class="hl sym">}</SPAN>
<SPAN class="hl line">  272 </SPAN>
<SPAN class="hl line">  273 </SPAN><SPAN class="hl kwb">struct</SPAN> flashloader_t sirf_type <SPAN class="hl sym">= {</SPAN>
<SPAN class="hl line">  274 </SPAN>    <SPAN class="hl sym">.</SPAN>name <SPAN class="hl sym">=</SPAN> <SPAN class="hl str">"SiRF binary"</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  275 </SPAN>
<SPAN class="hl line">  276 </SPAN>    <SPAN class="hl com">/* name of default flashloader */</SPAN>
<SPAN class="hl line">  277 </SPAN>    <SPAN class="hl sym">.</SPAN>flashloader <SPAN class="hl sym">=</SPAN> <SPAN class="hl str">"dlgsp2.bin"</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  278 </SPAN>    <SPAN class="hl com">/*</SPAN>
<SPAN class="hl line">  279 </SPAN><SPAN class="hl com">     * I can't imagine a GPS firmware less than 256KB / 2Mbit. The</SPAN>
<SPAN class="hl line">  280 </SPAN><SPAN class="hl com">     * latest build that I have (2.3.2) is 296KB. So 256KB is probably</SPAN>
<SPAN class="hl line">  281 </SPAN><SPAN class="hl com">     * low enough to allow really old firmwares to load.</SPAN>
<SPAN class="hl line">  282 </SPAN><SPAN class="hl com">     *</SPAN>
<SPAN class="hl line">  283 </SPAN><SPAN class="hl com">     * As far as I know, USB receivers have 512KB / 4Mbit of</SPAN>
<SPAN class="hl line">  284 </SPAN><SPAN class="hl com">     * flash. Application note APNT00016 (Alternate Flash Programming</SPAN>
<SPAN class="hl line">  285 </SPAN><SPAN class="hl com">     * Algorithms) says that the S2AR reference design supports 4, 8</SPAN>
<SPAN class="hl line">  286 </SPAN><SPAN class="hl com">     * or 16 Mbit flash memories, but with current firmwares not even</SPAN>
<SPAN class="hl line">  287 </SPAN><SPAN class="hl com">     * using 60% of a 4Mbit flash on a commercial receiver, I'm not</SPAN>
<SPAN class="hl line">  288 </SPAN><SPAN class="hl com">     * going to stress over loading huge images. The define below is</SPAN>
<SPAN class="hl line">  289 </SPAN><SPAN class="hl com">     * 524288 bytes, but that blows up nearly 3 times as S-records.</SPAN>
<SPAN class="hl line">  290 </SPAN><SPAN class="hl com">     * 928K srec -&gt; 296K binary</SPAN>
<SPAN class="hl line">  291 </SPAN><SPAN class="hl com">     */</SPAN>
<SPAN class="hl line">  292 </SPAN>    <SPAN class="hl sym">.</SPAN>min_firmware_size <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">262144</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  293 </SPAN>    <SPAN class="hl sym">.</SPAN>max_firmware_size <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">1572864</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  294 </SPAN>
<SPAN class="hl line">  295 </SPAN>    <SPAN class="hl com">/* a reasonable loader is probably 15K - 20K */</SPAN>
<SPAN class="hl line">  296 </SPAN>    <SPAN class="hl sym">.</SPAN>min_loader_size <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">15440</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  297 </SPAN>    <SPAN class="hl sym">.</SPAN>max_loader_size <SPAN class="hl sym">=</SPAN> <SPAN class="hl num">20480</SPAN><SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  298 </SPAN>
<SPAN class="hl line">  299 </SPAN>    <SPAN class="hl com">/* the command methods */</SPAN>
<SPAN class="hl line">  300 </SPAN>    <SPAN class="hl sym">.</SPAN>probe <SPAN class="hl sym">=</SPAN> sirfProbe<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  301 </SPAN>    <SPAN class="hl sym">.</SPAN>port_setup <SPAN class="hl sym">=</SPAN> sirfPortSetup<SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* before signal blocking */</SPAN>
<SPAN class="hl line">  302 </SPAN>    <SPAN class="hl sym">.</SPAN>version_check <SPAN class="hl sym">=</SPAN> sirfVersionCheck<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  303 </SPAN>    <SPAN class="hl sym">.</SPAN>stage1_command <SPAN class="hl sym">=</SPAN> sirfSendUpdateCmd<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  304 </SPAN>    <SPAN class="hl sym">.</SPAN>loader_send  <SPAN class="hl sym">=</SPAN> sirfSendLoader<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  305 </SPAN>    <SPAN class="hl sym">.</SPAN>stage2_command <SPAN class="hl sym">=</SPAN> wait2seconds<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  306 </SPAN>    <SPAN class="hl sym">.</SPAN>firmware_send  <SPAN class="hl sym">=</SPAN> srecord_send<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  307 </SPAN>    <SPAN class="hl sym">.</SPAN>stage3_command <SPAN class="hl sym">=</SPAN> wait5seconds<SPAN class="hl sym">,</SPAN>
<SPAN class="hl line">  308 </SPAN>    <SPAN class="hl sym">.</SPAN>port_wrapup <SPAN class="hl sym">=</SPAN> sirfPortWrapup<SPAN class="hl sym">,</SPAN>	<SPAN class="hl com">/* after signals unblock */</SPAN>
<SPAN class="hl line">  309 </SPAN><SPAN class="hl sym">};</SPAN>
<SPAN class="hl line">  310 </SPAN><SPAN class="hl dir">#endif</SPAN> <SPAN class="hl com">/* defined(SIRF_ENABLE) &amp;&amp; defined(BINARY_ENABLE) */</SPAN><SPAN class="hl dir"></SPAN>
</PRE><!--HTML generated by highlight, http://www.andre-simon.de/--></BODY></HTML>
