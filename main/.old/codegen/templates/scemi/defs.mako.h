#ifndef DEFS_H_
#define DEFS_H_
#include <stdint.h>
#define SCEMI 1

#define W_VALID 1
#define W_IS_TAIL 1
#define W_DEST_ADDR 4
#define W_VC 2
#define W_DATA 32
#define W_MASK 6
#define DATA_WIDTH 32
#define FLITDATA_SIZE 32
#define FLIT_SIZE (FLITDATA_SIZE+2+W_VC+W_DEST_ADDR)

#endif
