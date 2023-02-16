/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/

SECTIONS {
	. = 0x80000000;
	.text : {
		start*(.text);
		*(.text .text.*);
	}
	.data : {
		*(*);
	}
	end = .;
}
