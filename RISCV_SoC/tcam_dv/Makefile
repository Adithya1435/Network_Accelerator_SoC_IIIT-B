CROSS=riscv32-unknown-elf-
CFLAGS=

all : sim

sim: tcam_tb.vvp tcam_firmware.hex
	vvp -N $< +firmware=tcam_firmware.hex

tcam_tb.vvp: tcam_tb.v ../pico_wrapper.v ../spimemio.v ../simpleuart.v ../picosoc.v ../picorv32.v ../spiflash.v ../tcam_mmio.v ../tcam_ctrl_pipe.v ../action_drain_ctrl_upper.v ../action_mmio.v
	iverilog -s tcam_tb -o $@ $^

tcam_firmware.elf: sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -mabi=ilp32 -march=rv32ic -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o tcam_firmware.elf start.s firmware.c

tcam_firmware.hex: tcam_firmware.elf
	$(CROSS)objcopy -O verilog tcam_firmware.elf tcam_firmware.hex

clean:
	rm -f tcam_tb.vvp tcam_tb.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f tcam_firmware.elf tcam_firmware.hex tcam_firmware.bin
