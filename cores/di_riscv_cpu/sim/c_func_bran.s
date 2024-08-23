	.file	"c_func_bran.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	add
	.type	add, @function
add:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	sw	a1,-24(s0)
	lw	a4,-20(s0)
	lw	a5,-24(s0)
	add	a5,a4,a5
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	add, .-add
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	li	a5,1
	sw	a5,-20(s0)
	li	a5,2
	sw	a5,-24(s0)
	lw	a1,-24(s0)
	lw	a0,-20(s0)
	call	add
	sw	a0,-28(s0)
	lw	a5,-28(s0)
	blez	a5,.L4
	li	a5,1
	sw	a5,-32(s0)
.L4:
	lw	a5,-28(s0)
	blez	a5,.L5
	li	a5,2
	sw	a5,-32(s0)
.L5:
	lw	a4,-28(s0)
	li	a5,3
	bgt	a4,a5,.L6
	li	a5,3
	sw	a5,-36(s0)
.L6:
	lw	a4,-28(s0)
	li	a5,3
	bgt	a4,a5,.L7
	li	a5,4
	sw	a5,-36(s0)
.L7:
	li	a5,0
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.ident	"GCC: () 9.3.0"
