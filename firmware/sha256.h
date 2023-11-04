#ifndef _SHA256_H
#define _SHA256_H

#define DIGEST_INT_SIZE 8
#define DIGEST_CHAR_SIZE 32
#define DIGEST_STRING_SIZE 64

#define BLOCK_INT_SIZE 16
#define BLOCK_CHAR_SIZE 64
#define FINAL_BLOCK_CHAR_SIZE 56
#define BLOCK_STRING_SIZE 128

#define DBL_INT_ADD(a,b,c) if (a > 0xffffffff - (c)) ++b; a += c;

typedef struct {
	unsigned char data[64];
	unsigned int datalen;
	unsigned int block;
	unsigned int bitlen[2];
	unsigned int state[8];
} SHA256_CTX;


void sha256(char* data, unsigned int data_size, char* digest_string);

#endif // _SHA256_H

