void main();

void printc(char c) {
    *((volatile char *)0x10000000) = c;
}

void print(const char *s) {
    char c;
    while ((c = *s++) != '\0')
        printc(c);
}

void printu(unsigned int n) {
    char stack[10], *p = stack;
    do {
        *p++ = '0' + n % 10;
        n /= 10;
    } while (n != 0);
    while (p != stack)
        printc(*--p);
}

static inline unsigned int getbit(unsigned int *table, unsigned int i) {
    return (table[i >> 5] >> (i & 31)) & 1;
}

static inline void clearbit(unsigned int *table, unsigned int i) {
    table[i >> 5] &= ~(1ul << (i & 31));
}

void sieve(unsigned int *primes, unsigned int n) {
    unsigned int i, j;
    for (i = 0; i < n / 32; i++)
        primes[i] = 0xffffffff;
    for (i = 2; i * i <= n; i++)
        if (getbit(primes, i))
            for (j = i + i; j < n; j += i)
                clearbit(primes, j);
}

#define N 128

unsigned int primetable[N/32];

void main() {
    unsigned int i;
    print("Sieve benchmark\n");
    sieve(primetable, N);
    print("Primes:\n");
    for (i = 2; i < N; i++) {
        if (getbit(primetable, i)) {
            printu(i);
            printc('\n');
        }
    }
}
