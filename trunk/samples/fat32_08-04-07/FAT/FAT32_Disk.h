#include "..\define.h"
#include "FAT32_opts.h"

#ifndef __FAT32_DISK_H__
#define __FAT32_DISK_H__

BOOL FAT32_InitDrive();
BOOL FAT_ReadSector(UINT32 sector, BYTE *buffer);
BOOL FAT_WriteSector(UINT32 sector, BYTE *buffer);

#endif