.align 4
.section .text
.globl _start

_start:
	lw x5, SIX
	beq x0, x5, done

loop:
	add x1, x1, 1
	bne x5, x1, loop
	add x2, x2, 1
	add x2, x2, 1

done:
	beq x0, x0, done
	




SIX:		.word 0x00000006
