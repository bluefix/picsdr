#include "..\define.h"
#include "FAT32_Definitions.h"
#include "FAT32_opts.h"

#ifndef __FAT32_WRITE_H__
#define __FAT32_WRITE_H__

//-----------------------------------------------------------------------------
//  Globals
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Prototypes
//-----------------------------------------------------------------------------
BOOL FAT32_AddFileEntry(UINT32 dirCluster, char *filename, char *shortfilename, UINT32 startCluster, UINT32 size);
BOOL FAT32_AddFreeSpaceToChain(UINT32 *startCluster);
BOOL FAT32_AllocateFreeSpace(BOOL newFile, UINT32 *startCluster, UINT32 size);

#endif
