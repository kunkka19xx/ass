	BITS 64

	section .text
	global  _start

_start:
	mov rax, 1; sys_write
	mov rdi, 1; stdout
	mov rsi, msg
	mov rdx, msglen
	syscall

	mov rax, 60; sys_exit
	xor rdi, rdi; status 0
	syscall

	section .data
	msg    db 'hello', 10; 10 = newline
	msglen equ $ - msg
