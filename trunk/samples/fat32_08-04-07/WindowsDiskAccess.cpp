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
#include "..\define.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Windows.h>

// Warning: If you get the wrong physical drive ID you could erase your main hard disk!!

#ifdef SOURCE_WINDOWS_PHYSICAL_DRIVE

// File Functions
static __int64 DiskFileSeek(HANDLE hf, __int64 distance, DWORD MoveMethod);

//---------------------------------------------------------------------
// ReadSector: Read disk sector (512 bytes) in Windows
//---------------------------------------------------------------------
extern "C" BOOL ReadDiskSector(int drive, DWORD startinglogicalsector, int numberofsectors, BYTE *buffer)
{
	HANDLE hDevice; 
	DWORD bytesread;
    
	// Creating a handle to drive a: using CreateFile () function ..
	char _devicename[] = "\\\\.\\PhysicalDrive0";
	_devicename[17] += drive;
	hDevice = CreateFile(_devicename,  // drive to open
						GENERIC_READ,     // access type
						FILE_SHARE_READ | // share mode
						FILE_SHARE_WRITE, 
						NULL,             // default security attributes
						OPEN_EXISTING,    // disposition
						0,                // file attributes
						NULL);            // do not copy file attributes

 
    if (hDevice == INVALID_HANDLE_VALUE) 
        return FALSE;

	DiskFileSeek(hDevice, (startinglogicalsector),FILE_BEGIN);

	if (!ReadFile (hDevice, buffer, 512*numberofsectors, &bytesread, NULL) )
		 return FALSE;

	CloseHandle(hDevice); 
	return TRUE;
}
//---------------------------------------------------------------------
// WriteDiskSector: Write disk sector (512 bytes) in Windows
//---------------------------------------------------------------------
extern "C" BOOL WriteDiskSector(int drive, DWORD startinglogicalsector, int numberofsectors, BYTE *buffer)
{
	HANDLE hDevice; 
	DWORD byteswritten;
    
	// Creating a handle to drive a: using CreateFile () function ..
	char _devicename[] = "\\\\.\\PhysicalDrive0";
	_devicename[17] += drive;
	hDevice = CreateFile(_devicename,  // drive to open
						GENERIC_READ|GENERIC_WRITE,     // access type
						FILE_SHARE_READ | // share mode
						FILE_SHARE_WRITE, 
						NULL,             // default security attributes
						OPEN_EXISTING,    // disposition
						0,                // file attributes
						NULL);            // do not copy file attributes

 
    if (hDevice == INVALID_HANDLE_VALUE) 
        return FALSE;

	DiskFileSeek(hDevice, (startinglogicalsector),FILE_BEGIN);

	if (!WriteFile (hDevice, buffer, 512*numberofsectors, &byteswritten, NULL) )
		 return FALSE;

	CloseHandle(hDevice); 
	return TRUE;
}
//---------------------------------------------------------------------
// DiskFileSeek: Allow seeking through large files (a disk opened as a
// file).
//---------------------------------------------------------------------
static __int64 DiskFileSeek(HANDLE hf,__int64 distance, DWORD MoveMethod)
{
	__int64 seekDistance=0;
	seekDistance = distance*512;
	LARGE_INTEGER li;
	li.QuadPart = seekDistance;
	li.LowPart = SetFilePointer (hf, li.LowPart, &li.HighPart, MoveMethod);
	return li.QuadPart;
}

#endif
