
/*********************************************************************
*                                                                    *
*                       Software License Agreement                   *
*                                                                    *
*   The software supplied herewith by Microchip Technology           *
*   Incorporated (the "Company") for its PICmicro® Microcontroller   *
*   is intended and supplied to you, the Company’s customer, for use *
*   solely and exclusively on Microchip PICmicro Microcontroller     *
*   products. The software is owned by the Company and/or its        *
*   supplier, and is protected under applicable copyright laws. All  *
*   rights are reserved. Any use in violation of the foregoing       *
*   restrictions may subject the user to criminal sanctions under    *
*   applicable laws, as well as to civil liability for the breach of *
*   the terms and conditions of this license.                        *
*                                                                    *
*   THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION.  NO           *
*   WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING,    *
*   BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND    *
*   FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE     *
*   COMPANY SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL,  *
*   INCIDENTAL OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.  *
*                                                                    *
*********************************************************************/


/*********************************************************************
*                                                                    *
*           I2C Master and Slave Network using the PICmicro          * 
*                                                                    *
**********************************************************************
*                                                                    *
*   Filename:       i2c_comm.c                                       *
*   Date:           06/09/2000                                       *
*   Revision:       1.00                                             *
*                                                                    *
*   Tools:          MPLAB 5.00.00                                    *
*                   Hi-Tech PIC C Compiler V7.85                     *
*                                                                    *
*   Author:         Richard L. Fischer                               *
*   Company:        Microchip Technology Incorporated                *
*                                                                    *
**********************************************************************
*                                                                    *
*   Files required:                                                  *
*                                                                    *
*                   pic.h         (Hi-Tech file)                     *
*                   delay.h       (Hi-Tech file)                     *
*                   i2c_comm.h                                       *
*                                                                    *
**********************************************************************
*                                                                    *
*   Notes: The routines within this file are for communicating       *
*          with the I2C Slave device(s).                             *
*                                                                    *
*********************************************************************/

	#include <pic.h>                     // processor if/def file
	#include "i2c_comm.h"
	#include "c:\ht-pic\samples\delay.h"


#define LIMIT  0x80



/*******************************************************************
  MAIN PROGRAM BEGINS HERE
********************************************************************/
void Service_I2CSlave( void )
{
//------------------------------------------------------------------------
//   Will execute these statements once per each round of slave reads. 
//------------------------------------------------------------------------
	if ( !sflag.event.read_start )       // execute once per entire rounds of slave reads
	{
	  sflag.event.read_start = 1;        // set reads start flag
	  index = 0x00;
	  slave_count = 0x00;                // reset running slave counter
	  address_hold = SlaveAddress[slave_count];// initialize address hold buffer (1st slave)
	  Write2Slave_Ptr = &WriteStatBuf2Slave[0];//(bytecount, functional, checksum)
	  read_count = OperChannelsPerSlave + 1; // set byte read count (bytes + 1/2checksum)
	  ReadFSlave_Ptr = &ReadStatBufFromSlave[0]; // set up pointer for data read from Slave
	  I2CState_Ptr = &ReadFSlaveI2CStates[0];    // initialize I2C state pointer
	}


//------------------------------------------------------------------------
//  Will execute these statements if last I2C bus state was a WRITE
//------------------------------------------------------------------------
	if ( sflag.event.write_state )       // test if previous I2C state was a write
	{
	  if ( ACKSTAT )                     // was NOT ACK received?                   
	  {
	    PEN = 1; 	                     // generate bus stop condition
	    eflag.i2c.ack_error = 1;         // set acknowledge error flag
	  }
	  sflag.event.write_state = 0;       // reset write state flag
	}


//------------------------------------------------------------------------
//  Will execute these statements if a bus collision or an acknowledge error
//------------------------------------------------------------------------
	if ( eflag.i2c.bus_coll_error || eflag.i2c.ack_error  )           
	{
	  sflag.event.read_loop = 0;         // reset read loop flag for any error
	  sflag.event.next_i2cslave = 1;     // set flag indicating next slave

	  temp.error = error_mask << slave_count; // compose error status word

	  if ( eflag.i2c.bus_coll_error )    // test for bus collision error
	  {
		eflag.i2c.bus_coll_error = 0;    // reset bus collision error flag
		bus.error_word |= temp.error;    // compose bus error status word
		SSPIF = 1;                       // set false interrupt to restart comm
	  }
	  if ( eflag.i2c.ack_error )         // test for acknowledge error
	  {
		eflag.i2c.ack_error = 0;         // reset acknowledge error flag
		comm.error_word |= temp.error;   // compose communication error status word
	  }
	}

	else                                 // else no error for this slave
	{
	  temp.error = error_mask << slave_count; // compose error status word
	  bus.error_word &= ~temp.error;     // reset bus error bit for this slave
	  comm.error_word &= ~temp.error;    // reset comm error bit for this slave
	}


//------------------------------------------------------------------------
//  Will execute these statements for each new slave device after the first 
//------------------------------------------------------------------------
	if ( sflag.event.next_i2cslave )     // if next slave is being requested
	{
	  ComposeBuffer();                   // compose buffer for sending to PC
	  sflag.event.next_i2cslave = 0;     // reset next slave status flag	 

	  if ( sflag.event.usart_tx )        // test if USART TX still in progress
	  {
		slave_count ++;                  // increment slave counter
		SSPIE = 0;                       // disable SSP based interrupt
		if ( !sflag.event.usart_tx )     // test if interrupt occurred while here
		{
		  SSPIE = 1;                     // re-enable SSP based interrupt
		}
	  }

	  address_hold = SlaveAddress[slave_count]; // obtain slave address (repeat or next)
	  read_count = OperChannelsPerSlave + 1; // set byte read count (bytes, 1/2checksum)
	  ReadFSlave_Ptr = &ReadStatBufFromSlave[0]; // set up pointer for data read from Slave
 	  I2CState_Ptr = &ReadFSlaveI2CStates[0];    // re-initialize I2C state pointer
	}


//---------------------------------------------------------------------
//  Test if all slaves have been communicated with or continue with next bus state
//---------------------------------------------------------------------
	if ( slave_count < OperNumberI2CSlaves ) // test if all slaves have not been accessed
	{
	  sflag.event.i2c = 0;               // reset I2C state event flag
	  I2CBusState();                     // execute next I2C state
	}	

	else                                 // else
	{
	 	sflag.event.reads_done = 1;      // set flag indicating all slaves are read
	}
}


//------------------------------------------------------------------------
//  Will execute this switch/case evaluation for next I2C bus state
//------------------------------------------------------------------------
void I2CBusState ( void )
{
	i2cstate = *I2CState_Ptr++;          // retrieve next I2C state
	
	switch ( i2cstate )                  // evaluate which I2C state to execute
	{
		case ( READ ):                   // test for I2C read
		  RCEN = 1;                      // initiate i2C read state
		break;

		case ( WRITE_DATA ):             // test for I2C write (DATA)
 		  SSPBUF = *Write2Slave_Ptr++;   // initiate I2C write state
		  sflag.event.write_state = 1;   // set flag indicating write event in action
		break;

		case ( WRITE_ADDRESS1 ):         // test for I2C address (R/W=1)
		  SSPBUF = address_hold + 1;     // initiate I2C address write state 
		  sflag.event.write_state = 1;   // set flag indicating write event in action
		break;

		case ( START ):                  // test for I2C start state
		  SEN = 1;                       // initiate I2C bus start state		
		break;

		case ( WRITE_ADDRESS0 ):         // test for I2C address (R/W=0)
		  SSPBUF = address_hold;         // initiate I2C address write state
		  sflag.event.write_state = 1;   // set flag indicating write event in action
		break;

		case ( SEND_ACK ):               // test for send acknowledge state
		  *ReadFSlave_Ptr++ = SSPBUF;    // save off byte
		  if ( read_count > 0)           // test if still in read loop
		  {
			read_count -= 1;             // reduce read count
			I2CState_Ptr -= 2;           // update state pointer
		  }
		  ACKDT = 0;                     // set acknowledge data state (true)
		  ACKEN = 1;                     // initiate acknowledge state
		break;

		case ( SEND_NACK ):              // test if sending NOT acknowledge state
		  *ReadFSlave_Ptr = SSPBUF;      // save off byte
		  ACKDT = 1;                     // set acknowledge data state (false)
		  ACKEN = 1;                     // initiate acknowledge sequence
		break;

		case ( STOP ):                   // test for stop state
		  PEN = 1;                       // initiate I2C bus stop state 
		  sflag.event.next_i2cslave = 1; // set flag indicating next slave
		  sflag.event.writes_done = 1;   // reset flag, write is done
		break;	

		case ( RESTART ):                // test for restart state
		  RSEN = 1;                      // initiate I2C bus restart state
		break;     

		default:                         // 
		break;
	}
}


//------------------------------------------------------------------------
//  Compose Buffer to transmit to PC and Slave I2C (slave I2C if overlimit)
//------------------------------------------------------------------------
void ComposeBuffer( void )
{	  
	if ( ( ReadStatBufFromSlave[0] & 0x80 )  ||  ( eflag.i2c.slave_override ) )
	{
	  checksum.word = Calc_Checksum( &ReadStatBufFromSlave[0], 4 );
	  temp.hold.lobyte = ReadStatBufFromSlave[4];
	  temp.hold.hibyte = ReadStatBufFromSlave[5];

	  if ( ( ( checksum.word + temp.checksum ) == 0 )  ||  ( eflag.i2c.slave_override ) )
	  {
		ReadStatBufFromSlave[6] = bus.error.hibyte;  //
		ReadStatBufFromSlave[7] = bus.error.lobyte;  //
		ReadStatBufFromSlave[8] = comm.error.hibyte; //
		ReadStatBufFromSlave[9] = comm.error.lobyte; //

		if ( eflag.i2c.slave_override )   // test if comm failed with Slave
		{ 
		  ReadStatBufFromSlave[5] = 0x00; // null out voltage data  		  
		  ReadStatBufFromSlave[4] = 0x00; // null out rpm data  
		  ReadStatBufFromSlave[3] = 0x00; // null out temperature data
		}
		else                              // else comm with Slave OK
		{
		  ReadStatBufFromSlave[5] = ReadStatBufFromSlave[3]; // voltage data  		  
		  ReadStatBufFromSlave[4] = ReadStatBufFromSlave[2]; // rpm data  
		  ReadStatBufFromSlave[3] = ReadStatBufFromSlave[1]; // temperature data 
		}

		ReadStatBufFromSlave[2] = ( slave_count + 1 ); // slave ID
		ReadStatBufFromSlave[1] = 0x55;  // start sync character 2  
		ReadStatBufFromSlave[0] = 0xAA;  // start sync character 1  

		sflag.event.usart_tx = 1;        // set flag indicating USART TX in progress
		TXIE = 1;                        // enable USART TX interrupts

		if ( comm.error_word & 0x0FFF )  // test if any slave is on the bus
		{
		  if ( (ReadStatBufFromSlave[5] >= LIMIT)  &&  ( !eflag.i2c.slave_override ) )
          {                                         
			WriteData2Slave[3] = 0x01;   // out of limits indicator to slave
			Write_I2CSlave();            // write "error" code to slave
		  }
		  else if ( (ReadStatBufFromSlave[5] < LIMIT)  &&  ( !eflag.i2c.slave_override ) )
  		  {
			WriteData2Slave[3] = 0x00;   // in limits indicator to slave
			Write_I2CSlave();	         // write "valid" code to slave 
		  }
		}

		eflag.i2c.slave_override = 0;   // reset slave override flag
		read_retry = 0x00;               // reset retry count
		eflag.i2c.retry_attempt = 0;     // reset retry communication flag
	  }
	  else
	  {
		eflag.i2c.retry_attempt = 1;     // set retry communications flag 
	  }	
	}
	else
	{
	  eflag.i2c.retry_attempt = 1;       // set retry communications flag 
	}

	if ( eflag.i2c.retry_attempt )       // test if there was a retry request
	{
	  read_retry ++;                     // update retry counter               
	  if ( read_retry > MaxSlaveRetry -1 )// test if all retries have been attempted
	  {
		eflag.i2c.slave_override = 1;    // set flag to process next packet no matter what
	  } 
	  if ( slave_count == 0 )            // test for first slave
	  {
		Write2Slave_Ptr = &WriteStatBuf2Slave[0]; // reinitialize pointer
	  }
	  else                               // else slave 1 -> X
	  {
		Write2Slave_Ptr = &WriteStatBuf2Slave[slave_count * 3]; // reinitialize pointer
	  }
	}
}


//------------------------------------------------------------------------
//  Will execute these statements when requiring to write to a Slave I2C device
//------------------------------------------------------------------------
void Write_I2CSlave( void )
{
	unsigned char temp_ptr;              // define auto variable
	sflag.event.writes_done = 0;         // ensure flag is reset
	temp_ptr = Write2Slave_Ptr;          // save off current write pointer
	I2CState_Ptr = Write2SlaveStates;    // initialize I2C state pointer for writes
	ReadFSlave_Ptr = &ReadStatBufFromSlave[0];

	WriteData2Slave[0] = address_hold;   // obtain slave address
	WriteData2Slave[1] = 0x01;           // byte number request
	WriteData2Slave[2] = 0x00;           // functional offset
	checksum.word = Calc_Checksum( &WriteData2Slave[0], 4 );
	checksum.word = ~checksum.word + 1;
	WriteData2Slave[4] = (unsigned char)checksum.word; // save off checksum to array

	Write2Slave_Ptr = &WriteData2Slave[1];// initialize pointer

	do 
	{
	  DelayUs( 400 );                    // delay between events
	  sflag.event.i2c = 0;               // reset I2C state event flag
	  I2CBusState();                     // execute next I2C state
	  while ( !sflag.event.i2c );        // wait here until event completes

	  if ( sflag.event.write_state )     // test if previous I2C state was a write
	  {
		if ( ACKSTAT )                   // was NOT ACK received?                   
		{
		  PEN = 1; 	                     // generate bus stop condition
		  sflag.event.writes_done = 1;   // set write done flag do to error
		}
		sflag.event.write_state = 0;     // reset write state flag
	  }
	} while( !sflag.event.writes_done ); // stay in loop until error or done

	PORTB ^= 0b00000100;                 // ***** test purposes only *****	
	Write2Slave_Ptr = temp_ptr ;         // restore pointer contents
}



//------------------------------------------------------------------------
//  Generic checksum calculation routine
//------------------------------------------------------------------------
unsigned int Calc_Checksum( unsigned char *ptr, unsigned char length )
{
	unsigned int checksum;               // define auto type variable
	checksum = 0x0000;                   // reset checksum word

	while ( length )                     // while data string length != 0
	{
	  checksum += *ptr++;                // generate checksum
	  length --;                         // decrement data string length
	}
	return ( checksum );                 // return additive checksum
}
