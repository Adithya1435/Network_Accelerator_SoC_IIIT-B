#include <stdint.h>
#include <stdbool.h>

#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data   (*(volatile uint32_t*)0x02000008)

#define TCAM_KEY0      (*(volatile uint32_t*)(TCAM_BASE + 0x00))
#define TCAM_KEY1      (*(volatile uint32_t*)(TCAM_BASE + 0x04))
#define TCAM_KEY2      (*(volatile uint32_t*)(TCAM_BASE + 0x08))
#define TCAM_KEY3      (*(volatile uint32_t*)(TCAM_BASE + 0x0C))
#define TCAM_KEY_VALID (*(volatile uint32_t*)(TCAM_BASE + 0x10))

#define TCAM_HIT       (*(volatile uint32_t*)(TCAM_BASE + 0x14))
#define TCAM_INDEX     (*(volatile uint32_t*)(TCAM_BASE + 0x18))

#define TCAM_WR_ADDR   (*(volatile uint32_t*)(TCAM_BASE + 0x20))
#define TCAM_WR_ISMASK (*(volatile uint32_t*)(TCAM_BASE + 0x24))
#define TCAM_WR_D0     (*(volatile uint32_t*)(TCAM_BASE + 0x28))
#define TCAM_WR_D1     (*(volatile uint32_t*)(TCAM_BASE + 0x2C))
#define TCAM_WR_D2     (*(volatile uint32_t*)(TCAM_BASE + 0x30))
#define TCAM_WR_D3     (*(volatile uint32_t*)(TCAM_BASE + 0x34))
#define TCAM_WR_EN     (*(volatile uint32_t*)(TCAM_BASE + 0x38))

#define TCAM_BASE 0x03000000

void putchar(char c);
void print(const char *p);
void print_hex(uint32_t v);


void main()
{
	reg_uart_clkdiv = 104;
	print("TCAM test start ");

	/* Program entry 0:
	 * match key == 0x11223344_55667788_99AABBCC_DDEEFF00
	 */
	TCAM_WR_ADDR   = 0;
	TCAM_WR_ISMASK = 0;

	TCAM_WR_D0 = 0xDDEEFF00;
	TCAM_WR_D1 = 0x99AABBCC;
	TCAM_WR_D2 = 0x55667788;
	TCAM_WR_D3 = 0x11223344;
	TCAM_WR_EN = 1;


	TCAM_WR_ISMASK = 1;
	TCAM_WR_D0 = 0x00000000;
	TCAM_WR_D1 = 0x00000000;
	TCAM_WR_D2 = 0x00000000;
	TCAM_WR_D3 = 0x00000000;
	TCAM_WR_EN = 1;

	print("Rule programmed ");


	TCAM_KEY0 = 0xDDEEFF00;
	TCAM_KEY1 = 0x99AABBCC;
	TCAM_KEY2 = 0x55667788;
	TCAM_KEY3 = 0x11223344;
	TCAM_KEY_VALID = 1;


	if (TCAM_HIT) {
		print("TCAM HIT index=");
		print_hex(TCAM_INDEX);
		print(" ");
	} else {
		print("TCAM MISS");
	}

	while (1);
}

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v)
{
	for (int i = 28; i >= 0; i -= 4) {
		int d = (v >> i) & 0xF;
		putchar(d < 10 ? '0' + d : 'A' + d - 10);
	}
}
