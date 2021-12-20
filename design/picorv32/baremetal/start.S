	.section .text
	.global start
	.global main

start:
	jal ra,main
	ebreak
