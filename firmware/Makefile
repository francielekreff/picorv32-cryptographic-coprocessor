CROSS=riscv32-unknown-elf-

firmware: main.elf
	$(CROSS)objcopy -O binary main.elf main.bin
	python3 progmem.py

main.elf: main.lds start.s main.c
	$(CROSS)gcc $(CFLAGS) -march=rv32im -mabi=ilp32 -Wl,--build-id=none,-Bstatic,-T,main.lds,-Map,main.map,--strip-debug -ffreestanding -nostdlib \
	-o main.elf start.s main.c

main.lds: sections.lds
	$(CROSS)cpp -P -o $@ $^

clean:
	rm -f main.elf
	rm -f main.lds
	rm -f main.map
	rm -f main.bin
	rm -f progmem.v
