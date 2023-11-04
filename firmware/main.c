#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "sha256.h"

#define reg_leds (*(volatile uint32_t*)0x03000000)

void main()
{	
	char data[] = "Hello, World!";
    char digest_string[DIGEST_STRING_SIZE];   

	sha256(data, 13, digest_string);
}