#include "print.h"

#define UART_RX_FIFO    0x00
#define UART_TX_FIFO    0x04
#define UART_STAT       0x08

#define UART_RX_FIFO_VALID_DATA (1 << 0)
#define UART_RX_FIFO_FULL       (1 << 1)
#define UART_TX_FIFO_EMPTY      (1 << 2)
#define UART_TX_FIFO_FULL       (1 << 3)

volatile unsigned int *uart = (void *)0x60000000;

void putc(char c) {
    while (uart[UART_STAT/4] & UART_TX_FIFO_FULL);
    uart[UART_TX_FIFO/4] = c;
}

char getc() {
    while (!(uart[UART_STAT/4] & UART_RX_FIFO_VALID_DATA));
    return uart[UART_RX_FIFO/4];
}

void print(const char *s) {
    char c;
    while ((c = *s++) != '\0')
        putc(c);
}

void printu(unsigned int n) {
    char stack[10], *p = stack;
    do {
        *p++ = '0' + n % 10;
        n /= 10;
    } while (n != 0);
    while (p != stack)
        putc(*--p);
}
