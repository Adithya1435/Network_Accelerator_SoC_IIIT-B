#include <stdint.h>
#include <stdbool.h>

/* UART */
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data   (*(volatile uint32_t*)0x02000008)


#define ACTION_BASE 0x03010000

#define ACTION_LO     (*(volatile uint32_t*)(ACTION_BASE + 0x00))
#define ACTION_HI     (*(volatile uint32_t*)(ACTION_BASE + 0x04))
#define ACTION_VALID  (*(volatile uint32_t*)(ACTION_BASE + 0x08))
#define PKT_START     (*(volatile uint32_t*)(ACTION_BASE + 0x0C))
#define ACTION_STATUS (*(volatile uint32_t*)(ACTION_BASE + 0x10))

void putchar(char c);
void print(const char *p);
void print_hex(uint32_t v);

void main(){

	reg_uart_clkdiv = 104;

	print("Inject action");

	ACTION_LO = 0xDEADBEEF;
	ACTION_HI = 0xCAFEBABE;
	PKT_START = 1;
	ACTION_VALID = 1;

	if (ACTION_STATUS)
		print(" Drain allowed");
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
