CROSS=riscv32-unknown-elf-

# Ajust the help text
help:
	@echo ""
	@echo "Compiling main code:"
	@echo "  make main.lds"
	@echo "  make main.elf"
	@echo ""
	@echo "Verilog progmem file:"
	@echo "  make progmem.v"
	@echo ""
	@echo "Debug files:"
	@echo "  make main.hex"
	@echo "  make objdump.txt"
	@echo ""


main.lds: sections.lds
	$(CROSS)cpp -P -o $@ $^


main.elf: main.lds start.s main.c
	$(CROSS)gcc $(CFLAGS) -march=rv32im -mabi=ilp32 -Wl,--build-id=none,-Bstatic,-T,main.lds,-Map,main.map,--strip-debug -fno-builtin-memset -nostdlib -ffreestanding \
	-o main.elf start.s main.c sha256.c


main.hex: main.elf
	$(CROSS)objcopy -O binary main.elf main.bin
	python3 ../scripts/makehex.py main.bin 4096 > main.hex


progmem.v: main.elf
	$(CROSS)objcopy -O binary main.elf main.bin
	python3 ../scripts/progmem.py


objdump.txt: main.elf
	$(CROSS)objdump -d main.elf >> objdump.txt


clean:
	rm -f main.elf
	rm -f main.lds
	rm -f main.map
	rm -f main.bin
	rm -f main.hex
	rm -f progmem.v
	rm -f objdump.txt