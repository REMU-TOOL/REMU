	.section .text
	.global start
	.global main

start:
	li sp,0x90000000
	jal ra,main
	ebreak
