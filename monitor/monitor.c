#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <alloca.h>
#include <errno.h>

#include "control.h"
#include "physmap.h"

#define SHELL_BUFSIZE 256

int parse_num(const char *str, unsigned long *result) {
	unsigned long res = 0, newres;
	unsigned int radix = 10, len = strlen(str);
	unsigned char c;

	if (len > 2 && str[0] == '0' && str[1] == 'x') {
		str += 2;
		radix = 16;
	}

	while (c = *str++) {
		if (c >= '0' && c <= '9')
			c -= '0';
		else if (radix == 16) {
			if (c >= 'A' && c <= 'F')
				c -= 'A' - 10;
			else if (c >= 'a' && c <= 'f')
				c -= 'a' - 10;
			else
				return 1;
		}
		else
			return 1;

		newres = res * radix + c;
		if (newres < res)
			return 2;

		res = newres;
	}

	*result = res;
	return 0;
}

char *tokenize(char *next, int dry_run) {
    int in_quote = 0, prev_backslash = 0, leading_spaces = 1, trailing_spaces = 0;
    char *read = next, *write = next;
    if (*next == '\0' || *next == '\n') {
        return NULL;
    }
    for (;;) {
        char c = *read++;
        if (c == '\0' || c == '\n') {
            if (!dry_run) *write++ = '\0';
            read--;
            break;
        }
        if (c == ' ') {
            if (leading_spaces || trailing_spaces)
                continue;
            if (in_quote || prev_backslash) {
                if (!dry_run) *write++ = c;
                prev_backslash = 0;
                continue;
            }
            if (!dry_run) *write++ = '\0';
            trailing_spaces = 1;
            continue;
        }
        leading_spaces = 0;
        if (trailing_spaces) {
            read--;
            break;
        }
        switch (c) {
            case '\\':
                if (prev_backslash) {
                    if (!dry_run) *write++ = c;
                    prev_backslash = 0;
                }
                else {
                    prev_backslash = 1;
                }
                break;
            case '"':
                if (prev_backslash) {
                    if (!dry_run) *write++ = c;
                    prev_backslash = 0;
                }
                else {
                    in_quote = !in_quote;
                }
                break;
            default:
                if (!dry_run) *write++ = c;
                break;
        }
    }
    return read;
}

void show_help() {
    printf(
        "Available commands:\n"
        "    help\n"
        "        Show this message.\n"
        "    state\n"
        "        Print emulator state (running/stopped).\n"
        "    trig\n"
        "        Print activated trigger list (S=step trigger).\n"
        "    cycle [<new_cycle>]\n"
        "        Set cycle count to <new_cycle> if specified. Otherwise print current cycle count.\n"
        "    reset <duration>\n"
        "        Perform initial reset sequence where reset is held for <duration> cycles.\n"
        "        Note this command also resets cycle count.\n"
        "    run [<duration>]\n"
        "        Continue emulation execution. Run for <duration> cycles and stop if specified.\n"
        "    stop\n"
        "        Pause emulation execution.\n"
        "    step\n"
        "        Synonym for \"run 1\".\n"
        "    loadb\n"
        "        load checkpoint from STDIN. Checkpoint size is printed in decimal before data transfer.\n"
        "    saveb\n"
        "        save checkpoint to STDOUT. Checkpoint size is printed in decimal before data transfer.\n"
        "\n"
    );
}

void trig() {
    int i;
    uint32_t trig_stat = emu_trig_stat();
    if (emu_is_step_trig())
        printf("S ");
    for (i = 0; i < 32; i++)
        if (trig_stat & (1 << i))
            printf("%d ", i);
    printf("\n");
}

void loadb() {
    void *data = malloc(emu_checkpoint_size);
    printf("%d\n", emu_checkpoint_size);
    fread(data, 1, emu_checkpoint_size, stdin);
    emu_load_checkpoint_binary(data);
    free(data);
}

void saveb() {
    void *data = malloc(emu_checkpoint_size);
    printf("%d\n", emu_checkpoint_size);
    emu_save_checkpoint_binary(data);
    fwrite(data, 1, emu_checkpoint_size, stdout);
    free(data);
}

void run_command(int argc, char **argv) {
    if (argc == 0 || !strcmp(argv[0], "help")) {
        show_help();
    }
    else if (!strcmp(argv[0], "state")) {
        printf("%s\n", emu_is_running() ? "running" : "stopped");
    }
    else if (!strcmp(argv[0], "trig")) {
        trig();
    }
    else if (!strcmp(argv[0], "cycle")) {
        if (argc >= 2) {
            unsigned long cycle;
            if (parse_num(argv[1], &cycle)) {
                printf("invalid argument\n");
            }
            emu_write_cycle(cycle);
            printf("ok\n");
        }
        else {
            printf("%lu\n", emu_read_cycle());
        }
    }
    else if (!strcmp(argv[0], "reset")) {
        unsigned long duration;
        if (argc < 2 || parse_num(argv[1], &duration)) {
            printf("invalid argument\n");
        }
        emu_init_reset((uint32_t)duration);
        printf("ok\n");
    }
    else if (!strcmp(argv[0], "run")) {
        if (argc >= 2) {
            unsigned long duration;
            if (parse_num(argv[1], &duration)) {
                printf("invalid argument\n");
            }
            emu_step_for(duration);
            printf("ok\n");
        }
        else {
            emu_halt(0);
            printf("ok\n");
        }
    }
    else if (!strcmp(argv[0], "stop")) {
        emu_halt(1);
        printf("ok\n");
    }
    else if (!strcmp(argv[0], "step")) {
        emu_step_for(1);
        printf("ok\n");
    }
    else if (!strcmp(argv[0], "loadb")) {
        loadb();
        printf("ok\n");
    }
    else if (!strcmp(argv[0], "saveb")) {
        saveb();
        printf("ok\n");
    }
    else {
        printf("unrecognized command\n");
    }
}

void shell() {
    char buf[SHELL_BUFSIZE];
    while ((fprintf(stderr, "> "), fgets(buf, SHELL_BUFSIZE, stdin))) {
        int argc = 0;
        char **argv, *token, *next;
        next = buf;
        while (next = tokenize(next, 1)) {
            argc++;
        }
        argv = alloca(argc * sizeof(char *));
        argc = 0;
        token = next = buf;
        while (next = tokenize(next, 0)) {
            argv[argc++] = token;
            token = next;
        }
        if (strlen(argv[argc-1]) == 0) argc--;
        run_command(argc, argv);
    }
}

int main() {
    int res;

    setvbuf(stdout, NULL, _IOLBF, 0);

    res = init_map();
    if (res)
        return res;

    emu_ctrl_init();

    shell();

    fini_map();
    return 0;
}
