//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//					        FAT32 File IO Library
//								    V2.0
// 	  							 Rob Riglar
//						    Copyright 2003 - 2007
//
//   					  Email: rob@robriglar.com
//
//-----------------------------------------------------------------------------
//
// This file is part of FAT32 File IO Library.
//
// FAT32 File IO Library is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// FAT32 File IO Library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with FAT32 File IO Library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
#include "define.h"
#include "FAT\FAT32_Base.h"
#include "FAT\FAT32_Access.h"
#include "FAT\FAT32_Filelib.h"

int GetRandom(int max) { return rand() % (max + 1); }

//-----------------------------------------------------------------
// Main: Test bench file to create 5 files with psuedo random 
// sequences in of varying lengths - read them back and complete
// then remove them.
//-----------------------------------------------------------------
void main()
{
	int i,j,x;

	FL_FILE * files[5];
	FL_FILE *readFile;
	char filenames[5][260];
	BYTE fileData[5][10000];
	BYTE readBuffer[10000];
	int fileLengths[5];

	srand(time(NULL));
    
	// Initialise
	FAT32_InitDrive();

	// Initialise FAT parameters
	if (!FAT32_InitFAT())
	{
		printf("\r\nFailed: Could not load FAT details!");
		return;
	}

	// Generate 5 random files
	memset(filenames, 0x00, 260*5);
	for (j=0;j<5;j++)
	{
		// Length 
		fileLengths[j] = GetRandom(9999);
		
		// Data 
		for (x=0;x<fileLengths[j];x++)
			fileData[j][x] = (BYTE)GetRandom(255);

		// Names
		sprintf(filenames[j], "X:\\Auto Generated Filename Number %d", j+1);
	}

	// Create some files
	for (j=0;j<5;j++)
	{
		printf("Creating File: %s [%d bytes]\n", filenames[j], fileLengths[j]);

		// Create File
		files[j] = fl_fopen(filenames[j], "w");
		if (files[j]!=NULL)
		{
			if (fl_fwrite(fileData[j], 1, fileLengths[j], files[j])!=fileLengths[j])
				printf("ERROR: File Write Block Failed File %s Length %d\n", filenames[j], fileLengths[j]);
		}
		else
			printf("ERROR: Error Creating File %s\n", filenames[j]);

		fl_fclose(files[j]);

		// Verify File
		readFile = fl_fopen(filenames[j], "r");
		if (readFile!=NULL)
		{
			BOOL failed = FALSE;

			printf("File %s Read Check [%d bytes]\n", filenames[j], fileLengths[j]);

			if (fl_fread(readFile, readBuffer, fileLengths[j])!=fileLengths[j])
				printf("ERROR: File %s Read Length Error %d\n", filenames[j], fileLengths[j]);

			for (i=0;i<fileLengths[j];i++)
				if ( fileData[j][i] != (BYTE)readBuffer[i] )
					failed = TRUE;

			if (failed)
				printf("ERROR: File %s Data Verify Failed\n", filenames[j]);
		}
		fl_fclose(readFile);

		// Delete File
		if (fl_remove(filenames[j])<0)
			printf("ERROR: Delete File %s Failed\n", filenames[j]);
	}

	fl_shutdown();

	printf("\r\nCompleted\r\n");

	// List directory
	ListDirectory(FAT32_GetRootCluster());
}