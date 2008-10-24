http://www.obdev.at/developers/articles/00003.html

Implementing USB 1.1 in Firmware
by Christian Starkjohann
This article describes the techniques we used to implement NRZI decoding and bitstuff decoding in realtime in our firmware-only USB driver for Atmel AVR microcontrollers. 
For more information about the USB driver click here... 
The Challenge
For a USB 1.1 compatible low-speed device, a bit stream of 1.5 Mbit/s must be decoded. For a processor clocked at 12 MHz, this means that we have 8 CPU cycles for each bit. Being a RISC processor, the AVR executes most instructions in a single clock cycle. This gives us roughly 8 instructions to do the following operations on each bit:

NRZI decoding. A "1" is encoded as no change of the data lines, a "0" as a change. NRZI decoding can therefore be done by a negative exclusive or operation between the current status and the previous one (8 cycles earlier). 
Bitstuff decoding. In order to preserve synchronization during long sequences of "1", a "0" (change of data lines) is inserted every 6 consecutive "1" bits. This "stuffed" bit must be removed during reception. 
End of Packet recognition. The end of a packet is notified by a "SE0" condition. This means that both data lines (which are normally the inverse of each other) are at logical "0" level for two bit times. 
In addition to these tasks, the received byte must be stored and a buffer overflow check performed every 8 data bits.

The Naive Approach
The straight forward solution for the bit-processing loop looked like this (registers, I/O ports and constants have been replaced with symbolic constants for better readability):

loop:
    in      x1, port        ; 1 read data from I/O port
    andi    x1, mask        ; 1 check for SE0
    breq    end_of_packet   ; 1 (1 cycle because branch not taken)
    eor     x2, x1          ; 1 NRZI decoding
    ror     x2              ; 1 assuming data bit in LSB -> carry
    ror     shift           ; 1 collect data bits
    mov     x2, x1          ; 1 store input for next cycle
    dec     cnt             ; 1 all 8 bits read?
    brne    loop            ; 2 loop 8 times
                            ; ------------------------------------
                            ; 10 cycles

The first figure in the comment is the number of CPU cycles the instruction takes. As you can clearly see, we have already exceeded the limit of 8 instructions. And we have not even attempted to do bitstuff decoding yet!

The obvious optimization is to unroll the loop. We can simply copy the code 8 times and save the loop construct. This saves us 3 cycles and we are back in the game with 7 cycles used so far. If we can find a way to do bit-unstuffing in 1 cycle, of course!

As a side-note: We have read the inverse of the data: Exor gives 1 if the data lines change and 0 of they don't. But it is easy to compensate for that any time later.

The naive approach to bitstuff decoding is a counter which is decremented each no-change bit and set to 6 when a change is detected. If the counter reaches 0, we must destroy the next bit. This procedure involves at least one branch for the decision change or no-change, one decrement instruction, one constant load and one branch if the counter reaches zero. It is very hard to craft code with conditional branches into a form where each branch takes the same number of cycles. And it is even harder to pack all these instructions into one cycle!

Breakthrough in Bitstuff Decoding
What we really need is a completely different algorithm for bitstuff decoding which uses as much as possible of the information already acquired. There's no use in computing the same result twice.

What we already have is the stream of bits read so far in the shift register. The last 6 bits received are certainly available there. Since we shift from MSB to LSB, we must find out whether the 6 most significant bits are all 0 (which means no-change; remember: we read the inverse bit stream). This can easily be done in a compare with the constant 4. The part for the first bit in an unrolled loop would now be:

rxbit0:
    in      x1, port        ; 1 read data from I/O port
    andi    x1, mask        ; 1 check for SE0
    breq    end_of_packet   ; 1 (1 cycle because branch not taken)
    eor     x2, x1          ; 1 NRZI decoding
    ror     x2              ; 1 assuming data bit in LSB -> carry
    ror     shift           ; 1 collect data bits
    cpi     shift, 4        ; 1 check for 6 consecutive 0 bits
    brlo    do_unstuff      ; 1 (branch not taken)
    mov     x2, x1          ; 1 store input for next cycle
                            ; ------------------------------------
                            ; 9 cycles

We are now at 9 cycles and have detected the bitstuffing. Almost done. We need to save another cycle and get some spare cycles for saving the data and checking for buffer overflow.

Since the loop is already unrolled, we can save the mov instruction. If we exchange the meaning of x1 and x2 every bit, we don't need to move data around. This saves one cycle and we can now read all the bits in time. When we further take into account that an End of Packet state is two bits long, we can save the SE0 check every second bit and win enough spare cycles to store the data and do loop control. Does this mean we are ready? Not quite! The code at do_unstuff is not yet written. But let us write down what we have so far:

rxbit0:
    in      x1, port        ; 1 read data from I/O port
    andi    x1, mask        ; 1 check for SE0
    breq    end_of_packet   ; 1 (1 cycle because branch not taken)
    eor     x2, x1          ; 1 NRZI decoding
    ror     x2              ; 1 assuming data bit in LSB -> carry
    ror     shift           ; 1 collect data bits
    cpi     shift, 4        ; 1 check for 6 consecutive 0 bits
    brlo    do_unstuff0     ; 1 (branch not taken)
rxbit1:
    in      x2, port        ; 1 read data from I/O port
    andi    x2, mask        ; 1 check for SE0
    breq    end_of_packet   ; 1 (1 cycle because branch not taken)
    eor     x1, x2          ; 1 NRZI decoding
    ror     x1              ; 1 assuming data bit in LSB -> carry
    ror     shift           ; 1 collect data bits
    cpi     shift, 4        ; 1 check for 6 consecutive 0 bits
    brlo    do_unstuff1     ; 1 (branch not taken)
                            ; ------------------------------------
                            ; 16 cycles

Removing the Stuffed Bit
Destroying one bit should be easy, at first glance. Just do a dummy-read and wait:

do_unstuff0:                ; 1 (1 extra cycle: branch was taken)
    in      x1, port        ; 1 read data from I/O port
    andi    x1, mask        ; 1 check for SE0
    breq    end_of_packet   ; 1 (1 cycle because branch not taken)
    nop                     ; 1
    nop                     ; 1
    rjmp    rxbit1          ; 2 (branch taken)
                            ; ------------------------------------
                            ; 8 cycles

For the first time we have 2 spare cycles! Now do the necessary copy/paste and replace SE0 checks where we need loop control and we are done. But wait! What happens if the stuffed bit is followed by a no-change bit? Our shift register contains the data we store and it would have 7 leading zeros. The next bit would therefore be destroyed, although a bit stuffing has only just occurred. A bug!

This time it's tough. We must prevent that there are more than 5 leading zeros in the shift register, but this register should contain the data we store. And we have no control over the data we have to store. We could duplicate the register and use the copy for bitstuff detection. But where are the spare cycles for taking care of the copy? And keeping redundant data can't be efficient, after all. What we need is another Good Idea.

If there is a solution, it must consist of modifying the shift register. This is the only way how the tightly packed code for reading bits can survive without modification. OK. So we have to set at least the MSB in shift during do_unstuff. But how should we reconstruct the received byte then?

The key to a solution is that we know what we modify. We set bits to "1" which are known to be "0". And we know where they will land because the loop is unrolled and the number of shift operations following until the data is stored is fixed. We simply collect the bits we have modified in a separate register and bring them back just before we store. Luckily we had two spare cycles in do_unstuff:

do_unstuff0:                ; 1 (1 extra cycle: branch was taken)
    in      x1, port        ; 1 read data from I/O port
    andi    x1, mask        ; 1 check for SE0
    breq    end_of_packet   ; 1 (1 cycle because branch not taken)
    ori     shift, 0xfc     ; 1 mask out 6 recently received bits
    andi    x3, 0xfe        ; 1 the bits we masked shifted right 7
    rjmp    rxbit1          ; 2 (branch taken)
                            ; ------------------------------------
                            ; 8 cycles

x3 must be pre-initialized to 0xff at the start of each byte and we must store the value shift & x3. These two operations replace another SE0 check. Now we are really done decoding the stream. And we have not a single spare cycle left!

The production code has to take care of some other minor problems, e.g. how to accumulate cycles from spared SE0 checks where we need them, which SE0 checks to spare without breaking standards compliance and so on. See the assembler module of the driver for more details.
 References
USB in a Nutshell by Craig Peackock 
--------------------------------------------------------------------------------
Universal Serial Bus Revision 1.1 Specification 
--------------------------------------------------------------------------------
AVR Instruction Set 
--------------------------------------------------------------------------------
Atmel's Application Note AVR309 (not yet online, preview available at www.cesko.host.sk).  
