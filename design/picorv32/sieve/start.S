	.section .text
	.global start
	.global main

start:
	li sp,0x10000
	jal ra,main
	ebreak
