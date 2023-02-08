void main();

#define UART_RX_FIFO    0x00
#define UART_TX_FIFO    0x04
#define UART_STAT       0x08

#define UART_RX_FIFO_VALID_DATA (1 << 0)
#define UART_RX_FIFO_FULL       (1 << 1)
#define UART_TX_FIFO_EMPTY      (1 << 2)
#define UART_TX_FIFO_FULL       (1 << 3)

volatile unsigned int *uart = (void *)0x10000000;

void putc(char c) {
    while (uart[UART_STAT/4] & UART_TX_FIFO_FULL);
    uart[UART_TX_FIFO/4] = c;
}

char getc() {
    while (!(uart[UART_STAT/4] & UART_RX_FIFO_VALID_DATA));
    return uart[UART_RX_FIFO/4];
}

#define N 128

char buffer[N];

void main() {
    while (1) {
        char *wp = buffer;
        char c;
        while (1) {
            c = getc();
            *wp++ = c;
            if (c == '\n')
                break;
        }
        char *rp = buffer;
        while (1) {
            c = *rp++;
            putc(c);
            if (rp == wp)
                break;
        }
    }
}
