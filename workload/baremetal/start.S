	.section .text
	.global start
	.global main

start:
	li sp, STACK_TOP
	jal ra, main
	ebreak
