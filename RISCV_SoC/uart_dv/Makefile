CROSS=riscv32-unknown-elf-
CFLAGS=

all : sim

sim: uart_tb.vvp uart_firmware.hex
	vvp -N $< +firmware=uart_firmware.hex

uart_tb.vvp: uart_tb.v ../pico_wrapper.v ../spimemio.v ../simpleuart.v ../picosoc.v ../picorv32.v ../spiflash.v
	iverilog -s uart_tb -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v` -DNO_ICE40_DEFAULT_ASSIGNMENTS

uart_firmware.elf: sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -mabi=ilp32 -march=rv32ic -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o uart_firmware.elf start.s firmware.c

uart_firmware.hex: uart_firmware.elf
	$(CROSS)objcopy -O verilog uart_firmware.elf uart_firmware.hex


# ---- Clean ----

clean:
	rm -f uart_tb.vvp uart_tb.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f uart_firmware.elf uart_firmware.hex uart_firmware.bin


.PHONY: spiflash_tb clean
.PHONY: icebprog icebprog_fw icebsim icebsynsim
