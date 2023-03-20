#include "print.h"

#define N 128

char buffer[N];

void run_echo() {
    int i;
    for (i=0; i<10; i++) {
        print("Input: ");
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
