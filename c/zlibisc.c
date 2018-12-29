#define ZF_DLL

// Ugly Windows hack
#ifndef ulong
   typedef unsigned long ulong;
#endif

#include "string.h"
#include "stdio.h"
#include "stdlib.h"
#include "zlib.h"
#include <cdzf.h>



int Compress(char* istream, CACHE_EXSTRP retval)
{
	ulong srcLen = strlen(istream)+1;      // +1 for the trailing `\0`
	ulong destLen = compressBound(srcLen); // this is how you should estimate size 
										 // needed for the buffer
	char* ostream = malloc(destLen);
	int res = compress(ostream, &destLen, istream, srcLen);
	CACHEEXSTRKILL(retval);
	if (!CACHEEXSTRNEW(retval,destLen)) {return ZF_FAILURE;}
	memcpy(retval->str.ch,ostream,destLen);   // copy to retval->str.ch
	return ZF_SUCCESS;
}

void DumpHex(const void* data, size_t size) {
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
	for (i = 0; i < size; ++i) {
		printf("%02X ", ((unsigned char*)data)[i]);
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
			} else if (i+1 == size) {
				ascii[(i+1) % 16] = '\0';
				if ((i+1) % 16 <= 8) {
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
				}
				printf("|  %s \n", ascii);
			}
		}
	}
}

int main()
{
  const char *istream = "123";
  ulong srcLen = strlen(istream)+1;      // +1 for the trailing `\0`
  ulong destLen = compressBound(srcLen); // this is how you should estimate size 
                                         // needed for the buffer
  char* ostream = malloc(destLen);
  int res = compress(ostream, &destLen, istream, srcLen); 
  // destLen is now the size of actuall buffer needed for compression
  // you don't want to uncompress whole buffer later, just the used part
  if(res == Z_BUF_ERROR){
    printf("Buffer was too small!\n");
    return 1;
  }
  if(res ==  Z_MEM_ERROR){
    printf("Not enough memory for compression!\n");
    return 2;
  }
  
  DumpHex(ostream, destLen);
  //printf("%s", ostream);

  const char *i2stream = ostream;
  char* o2stream = malloc(srcLen);
  ulong destLen2 = destLen; //destLen is the actual size of the compressed buffer
  int des = uncompress(o2stream, &srcLen, i2stream, destLen2);
  ///printf("%s\n", o2stream);
  return 0;
}


ZFBEGIN
	ZFENTRY("Compress","cJ",Compress)
ZFEND