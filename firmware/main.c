#include <stdint.h>
#include <stdbool.h>


#define BLOCK_INT_SIZE 16
#define BLOCK_CHAR_SIZE 64

#define DIGEST_INT_SIZE 8
#define DIGEST_CHAR_SIZE 32

void main()
{	
	//unsigned char block[BLOCK_CHAR_SIZE];
	//unsigned char digest[DIGEST_CHAR_SIZE];

	unsigned int zero = 0;
	unsigned int word = 23;
	unsigned int position = 0;
	unsigned int digest;

	/* crypto.sha256_lw */
	/* asm volatile (".insn r opcode, funct3, funct7, rd, rs1, rs2"); */
	asm volatile (".insn r 0x0B, 0x0, 0x0, %0, %1, %2" : "=r" (zero) : "r" (word), "r" (position)); 

	/* crypto.sha256_init */
	/* asm volatile (".insn r opcode, funct3, funct7, rd, rs1, rs2"); */
	asm volatile (".insn r 0x0B, 0x1, 0x0, %0, %1, %2" : "=r" (zero) : "r" (zero), "r" (zero)); 

	/* crypto.sha256_next */
	/* asm volatile (".insn r opcode, funct3, funct7, rd, rs1, rs2"); */
	asm volatile (".insn r 0x0B, 0x2, 0x0, %0, %1, %2" : "=r" (zero) : "r" (zero), "r" (zero)); 

	/* crypto.sha256_digest */
	/* asm volatile (".insn r opcode, funct3, funct7, rd, rs1, rs2"); */
	asm volatile (".insn r 0x0B, 0x3, 0x0, %0, %1, %2" : "=r" (digest) : "r" (zero), "r" (position)); 

	/* crypto.sha256_reset */
	/* asm volatile (".insn r opcode, funct3, funct7, rd, rs1, rs2"); */
	asm volatile (".insn r 0x0B, 0x4, 0x0, %0, %1, %2" : "=r" (zero) : "r" (zero), "r" (zero)); 
}
