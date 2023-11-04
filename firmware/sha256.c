#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "sha256.h"

void char_to_hex_string(char ch, char *hex_string) {
    static const char hex_digits[] = "0123456789abcdef";
    hex_string[0] = hex_digits[(ch >> 4) & 0xF];
    hex_string[1] = hex_digits[ch & 0xF];
    hex_string[2] = '\0';
}


/* asm volatile (".insn r opcode, funct3, funct7, rd, rs1, rs2"); */
void sha256_transform(SHA256_CTX *ctx, unsigned char data[])
{
	unsigned int block[BLOCK_INT_SIZE];
	unsigned int block_word;
	unsigned int digest_word;

	int zero = 0;

	for (int i = 0; i < 16; i++) {
        block[i] = 0;
        for (int j = 0; j < 4; j++) {
            block[i] <<= 8;
            block[i] |= data[i * 4 + j];
        }
    }

	/* crypto.sha256_reset */
	asm volatile (".insn r 0x0B, 0x4, 0x0, %0, %1, %2" 
				  : "=r" (zero) : "r" (zero), "r" (zero)); 

	/* load word */
	for (int i=0; i < BLOCK_INT_SIZE; i++) {
		block_word = block[i];
		/* crypto.sha256_lw */
		asm volatile (".insn r 0x0B, 0x0, 0x0, %0, %1, %2" 
					  : "=r" (zero) : "r" (block_word), "r" (i)); 
	}

	if (ctx->block == 1) {
		/* crypto.sha256_init */
		asm volatile (".insn r 0x0B, 0x1, 0x0, %0, %1, %2" 
					  : "=r" (zero) : "r" (zero), "r" (zero)); 
	} else {
		/* crypto.sha256_next */
		asm volatile (".insn r 0x0B, 0x2, 0x0, %0, %1, %2" 
					  : "=r" (zero) : "r" (zero), "r" (zero)); 
	}

	/* digest */
	for (int i=0; i < DIGEST_INT_SIZE; i++) {
		/* crypto.sha256_digest */
		asm volatile (".insn r 0x0B, 0x3, 0x0, %0, %1, %2" 
					  : "=r" (digest_word) : "r" (zero), "r" (i)); 
		
		ctx->state[i] = digest_word;
	}
}


void sha256_init(SHA256_CTX *ctx)
{
	ctx->datalen = 0;
	ctx->block = 0;
	ctx->bitlen[0] = 0;
	ctx->bitlen[1] = 0;
	ctx->state[0] = 0;
	ctx->state[1] = 0;
	ctx->state[2] = 0;
	ctx->state[3] = 0;
	ctx->state[4] = 0;
	ctx->state[5] = 0;
	ctx->state[6] = 0;
	ctx->state[7] = 0;
}


void sha256_update(SHA256_CTX *ctx, unsigned char data[], unsigned int len)
{
	for (int i = 0; i < len; ++i) {
		ctx->data[ctx->datalen] = data[i];
		ctx->datalen++;

		if (ctx->datalen == BLOCK_CHAR_SIZE) {
			ctx->block++;

			sha256_transform(ctx, ctx->data);

			DBL_INT_ADD(ctx->bitlen[0], ctx->bitlen[1], 512);
			ctx->datalen = 0;
		}
	}
}

void sha256_final(SHA256_CTX *ctx, unsigned char digest[])
{
	int i = ctx->datalen;

	if (ctx->datalen < FINAL_BLOCK_CHAR_SIZE) {
		
		/* block padding */
		ctx->data[i++] = 0x80;	
		while (i < FINAL_BLOCK_CHAR_SIZE) {
			ctx->data[i++] = 0x00;
		}
	
	} else {
		
		/* block padding */
		ctx->data[i++] = 0x80;
		while (i < BLOCK_CHAR_SIZE) {
			ctx->data[i++] = 0x00;
		}

		ctx->block++;

		sha256_transform(ctx, ctx->data);

		/* new block */
		//memset(ctx->data, 0, FINAL_BLOCK_CHAR_SIZE);
		for(int j=0; j<FINAL_BLOCK_CHAR_SIZE; j++) {
			ctx->data[j] = 0;
		}
	}

	DBL_INT_ADD(ctx->bitlen[0], ctx->bitlen[1], ctx->datalen * 8);
	ctx->data[63] = ctx->bitlen[0];
	ctx->data[62] = ctx->bitlen[0] >> 8;
	ctx->data[61] = ctx->bitlen[0] >> 16;
	ctx->data[60] = ctx->bitlen[0] >> 24;
	ctx->data[59] = ctx->bitlen[1];
	ctx->data[58] = ctx->bitlen[1] >> 8;
	ctx->data[57] = ctx->bitlen[1] >> 16;
	ctx->data[56] = ctx->bitlen[1] >> 24;

	ctx->block++;

	sha256_transform(ctx, ctx->data);

	for (i = 0; i < 4; ++i) {
		digest[i]      = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
		digest[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
		digest[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
		digest[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
		digest[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
		digest[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
		digest[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
		digest[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
	}
}

void sha256(char* data, unsigned int data_size, char* digest_string) { 
    
    SHA256_CTX ctx;
	unsigned char digest[DIGEST_CHAR_SIZE];
    char string[3];
	
	sha256_init(&ctx);
	sha256_update(&ctx, data, data_size);
	sha256_final(&ctx, digest);

	for (int i = 0; i < DIGEST_CHAR_SIZE; i++) {
		char_to_hex_string(digest[i], string);

        digest_string[i*2] = string[0];
		digest_string[i*2+1] = string[1];
	}
	digest_string[DIGEST_STRING_SIZE] = '\0';
}