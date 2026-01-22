CROSS=riscv32-unknown-elf-
CFLAGS=

all : sim

sim: action_tb.vvp action_firmware.hex
	vvp -N $< +firmware=action_firmware.hex

action_tb.vvp: action_tb.v ../pico_wrapper.v ../spimemio.v ../simpleuart.v ../picosoc.v ../picorv32.v ../spiflash.v ../tcam_mmio.v ../tcam_ctrl_pipe.v ../action_drain_ctrl_upper.v ../action_mmio.v
	iverilog -s action_tb -o $@ $^

action_firmware.elf: sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -mabi=ilp32 -march=rv32ic -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o action_firmware.elf start.s firmware.c

action_firmware.hex: action_firmware.elf
	$(CROSS)objcopy -O verilog action_firmware.elf action_firmware.hex


clean:
	rm -f action_tb.vvp action_tb.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f action_firmware.elf action_firmware.hex action_firmware.bin
