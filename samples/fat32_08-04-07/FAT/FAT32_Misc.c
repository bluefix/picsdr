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
#include "FAT32_Misc.h"

//-----------------------------------------------------------------------------
// FATMisc_ClearLFN: Clear long file name cache
//-----------------------------------------------------------------------------
void FATMisc_ClearLFN(BOOL wipeTable)
{
	int i;
	FAT32_LFN.no_of_strings = 0;

	// Zero out buffer also
	if (wipeTable)
		for (i=0;i<MAX_LONGFILENAME_ENTRIES;i++)
			memset(FAT32_LFN.String[i], 0x00, 13);
}
//-----------------------------------------------------------------------------
// FATMisc_cacheLFN - Function extracts long file name text from sector 
//                       at a specific offset
//-----------------------------------------------------------------------------
void FATMisc_CacheLFN(BYTE *entryBuffer)
{
	BYTE LFNIndex, i;
	LFNIndex = entryBuffer[0] & 0x0F;

	if (FAT32_LFN.no_of_strings==0) 
		FAT32_LFN.no_of_strings = LFNIndex;

	FAT32_LFN.String[LFNIndex-1][0] = entryBuffer[1];
	FAT32_LFN.String[LFNIndex-1][1] = entryBuffer[3];
	FAT32_LFN.String[LFNIndex-1][2] = entryBuffer[5];
	FAT32_LFN.String[LFNIndex-1][3] = entryBuffer[7];
	FAT32_LFN.String[LFNIndex-1][4] = entryBuffer[9];
	FAT32_LFN.String[LFNIndex-1][5] = entryBuffer[0x0E];
	FAT32_LFN.String[LFNIndex-1][6] = entryBuffer[0x10];
	FAT32_LFN.String[LFNIndex-1][7] = entryBuffer[0x12];
	FAT32_LFN.String[LFNIndex-1][8] = entryBuffer[0x14];
	FAT32_LFN.String[LFNIndex-1][9] = entryBuffer[0x16];
	FAT32_LFN.String[LFNIndex-1][10] = entryBuffer[0x18];		 		  		  	 		 
	FAT32_LFN.String[LFNIndex-1][11] = entryBuffer[0x1C];
	FAT32_LFN.String[LFNIndex-1][12] = entryBuffer[0x1E];

	for (i=0; i<13; i++)
		if (FAT32_LFN.String[LFNIndex-1][i]==0xFF) 
			FAT32_LFN.String[LFNIndex-1][i] = 0x20; // Replace with spaces
} 
//-----------------------------------------------------------------------------
// FATMisc_GetLFNCache: Get a copy of the long filename to into a string buffer
//-----------------------------------------------------------------------------
void FATMisc_GetLFNCache(BYTE *strOut)
{
	int i,index;
	int lfncount = 0;

	// Copy LFN from LFN Cache into a string
	for (index=0;index<FAT32_LFN.no_of_strings;index++)
		for (i=0; i<13; i++)
			strOut[lfncount++] = FAT32_LFN.String[index][i];

	// Null terminate string
	strOut[lfncount]='\0';
}
//-----------------------------------------------------------------------------
// FATMisc_If_LFN_TextOnly: If LFN text entry found
//-----------------------------------------------------------------------------
int FATMisc_If_LFN_TextOnly(FAT32_ShortEntry *entry)
{
	if ((entry->Attr&0x0F)==FILE_ATTR_LFN_TEXT) 
		return 1;
	else 
		return 0;
}
//-----------------------------------------------------------------------------
// FATMisc_If_LFN_Invalid: If SFN found not relating to LFN
//-----------------------------------------------------------------------------
int FATMisc_If_LFN_Invalid(FAT32_ShortEntry *entry)
{
	if ((entry->Name[0]==FILE_HEADER_BLANK)||(entry->Name[0]==FILE_HEADER_DELETED)||(entry->Attr==FILE_ATTR_VOLUME_ID)||(entry->Attr&FILE_ATTR_SYSHID)) 
		return 1;
	else 
		return 0;
}
//-----------------------------------------------------------------------------
// FATMisc_If_LFN_Exists: If LFN exists and correlation SFN found
//-----------------------------------------------------------------------------
int FATMisc_If_LFN_Exists(FAT32_ShortEntry *entry)
{
	if ((entry->Attr!=FILE_ATTR_LFN_TEXT) && (entry->Name[0]!=FILE_HEADER_BLANK) && (entry->Name[0]!=FILE_HEADER_DELETED) && (entry->Attr!=FILE_ATTR_VOLUME_ID) && (!(entry->Attr&FILE_ATTR_SYSHID)) && (FAT32_LFN.no_of_strings))
		return 1;
	else 
		return 0;
}
//-----------------------------------------------------------------------------
// FATMisc_If_noLFN_SFN_Only: If SFN only exists
//-----------------------------------------------------------------------------
int FATMisc_If_noLFN_SFN_Only(FAT32_ShortEntry *entry)
{
	if ((entry->Attr!=FILE_ATTR_LFN_TEXT) && (entry->Name[0]!=FILE_HEADER_BLANK) && (entry->Name[0]!=FILE_HEADER_DELETED) && (entry->Attr!=FILE_ATTR_VOLUME_ID) && (!(entry->Attr&FILE_ATTR_SYSHID)))
		return 1;
	else 
		return 0;
}
//-----------------------------------------------------------------------------
// FATMisc_If_dir_entry: Returns 1 if a directory
//-----------------------------------------------------------------------------
int FATMisc_If_dir_entry(FAT32_ShortEntry *entry)
{
	if (entry->Attr&FILE_TYPE_DIR) 
		return 1;
	else 
		return 0;
}
//-----------------------------------------------------------------------------
// FATMisc_If_file_entry: Returns 1 is a file entry
//-----------------------------------------------------------------------------
int FATMisc_If_file_entry(FAT32_ShortEntry *entry)
{
	if (entry->Attr&FILE_TYPE_FILE) 
		return 1;
	else 
		return 0;
}
//-----------------------------------------------------------------------------
// FATMisc_LFN_to_entry_count:
//-----------------------------------------------------------------------------
int FATMisc_LFN_to_entry_count(char *filename)
{
	// 13 characters entries
	int length = (int)strlen(filename);
	int entriesRequired = length / 13;

	// Remainder
	if ((length % 13)!=0)
		entriesRequired++;

	return entriesRequired;
}
//-----------------------------------------------------------------------------
// FATMisc_LFN_to_lfn_entry:
//-----------------------------------------------------------------------------
void FATMisc_LFN_to_lfn_entry(char *filename, BYTE *buffer, int entry, BYTE sfnChk)
{
	int i;
	int nameIndexes[] = {1,3,5,7,9,0x0E,0x10,0x12,0x14,0x16,0x18,0x1C,0x1E};

	// 13 characters entries
	int length = (int)strlen(filename);
	int entriesRequired = FATMisc_LFN_to_entry_count(filename);

	// Filename offset
	int start = entry * 13;

	// Initialise to zeros
	memset(buffer, 0x00, 32);

	// LFN entry number
	buffer[0] = (BYTE)(((entriesRequired-1)==entry)?(0x40|(entry+1)):(entry+1));

	// LFN flag
	buffer[11] = 0x0F;

	// Checksum of short filename
	buffer[13] = sfnChk;

	// Copy to buffer
	for (i=0;i<13;i++)
	{
		if ( (start+i) < length )
			buffer[nameIndexes[i]] = filename[start+i];
		else if ( (start+i) == length )
			buffer[nameIndexes[i]] = 0x00;
		else
		{
			buffer[nameIndexes[i]] = 0xFF;
			buffer[nameIndexes[i]+1] = 0xFF;
		}
	}


}
//-----------------------------------------------------------------------------
// FATMisc_Create_sfn_entry: Create the short filename directory entry
//-----------------------------------------------------------------------------
#ifdef INCLUDE_WRITE_SUPPORT
void FATMisc_Create_sfn_entry(char *shortfilename, UINT32 size, UINT32 startCluster, FAT32_ShortEntry *entry)
{
	int i;

	// Copy short filename
	for (i=0;i<11;i++)
		entry->Name[i] = shortfilename[i];

	// Unless we have a RTC we might as well set these to 1980
	entry->CrtTimeTenth = 0x00;
	entry->CrtTime[1] = entry->CrtTime[0] = 0x00;
	entry->CrtDate[1] = 0x00;
	entry->CrtDate[0] = 0x20;
	entry->LstAccDate[1] = 0x00;
	entry->LstAccDate[0] = 0x20;
	entry->WrtTime[1] = entry->WrtTime[0] = 0x00;
	entry->WrtDate[1] = 0x00;
	entry->WrtDate[0] = 0x20;	

	entry->Attr = FILE_TYPE_FILE;
	entry->NTRes = 0x00;

	entry->FstClusHI = (UINT16)((startCluster>>16) & 0xFFFF);
	entry->FstClusLO = (UINT16)((startCluster>>0) & 0xFFFF);
	entry->FileSize = size;
}
#endif
//-----------------------------------------------------------------------------
// FATMisc_CreateSFN: Create a padded SFN 
//-----------------------------------------------------------------------------
#ifdef INCLUDE_WRITE_SUPPORT
BOOL FATMisc_CreateSFN(char *sfn_output, char *filename)
{
	int i;
	int dotPos = -1;
	char ext[3];
	int pos;
	int len = (int)strlen(filename);

	// Invalid to start with .
	if (filename[0]=='.')
		return FALSE;

	memset(sfn_output, ' ', 11);
	memset(ext, ' ', 3);

	// Find dot seperator
	for (i = 0; i< len; i++)
	{
		if (filename[i]=='.')
			dotPos = i;
	}

	// Extract extensions
	if (dotPos!=-1)
	{
		// Copy first three chars of extension
		for (i = (dotPos+1); i < (dotPos+1+3); i++)
			if (i<len)
				ext[i-(dotPos+1)] = filename[i];

		// Shorten the length to the dot position
		len = dotPos;
	}

	// Add filename part
	pos = 0; 
	for (i=0;i<len;i++)
	{
		if ( (filename[i]!=' ') && (filename[i]!='.') )
			sfn_output[pos++] = (char)toupper(filename[i]);
		
		// Fill upto 8 characters
		if (pos==8)
			break;
	}

	// Add extension part
	for (i=8;i<11;i++)
		sfn_output[i] = (char)toupper(ext[i-8]);

	return TRUE;
}
#endif
//-----------------------------------------------------------------------------
// FATMisc_GenerateTail:
// sfn_input = Input short filename, spaced format & in upper case
// sfn_output = Output short filename with tail
//-----------------------------------------------------------------------------
#ifdef INCLUDE_WRITE_SUPPORT
BOOL FATMisc_GenerateTail(char *sfn_output, char *sfn_input, UINT32 tailNum)
{
	int tail_chars;
	char tail_str[8];

	if (tailNum > 99999)
		return FALSE;

	// Convert to number
	memset(tail_str, 0x00, sizeof(tail_str)); 
	tail_str[0] = '~';
	itoa(tailNum, tail_str+1, 10);
	
	// Copy in base filename
    memcpy(sfn_output, sfn_input, 11);
	   
	// Overwrite with tail
	tail_chars = (int)strlen(tail_str);
	memcpy(sfn_output+(8-tail_chars), tail_str, tail_chars);

	return TRUE;
}
#endif
