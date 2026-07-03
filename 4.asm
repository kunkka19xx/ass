	BITS 64

	section .text
	global  _start

_start:
	;   write name
	mov rax, 1; sys_write
	mov rdi, 1; stdout
	mov rsi, name
	mov rdx, 8
	syscall

	;   overwrite name
	mov qword [name], 'Nuha Ali'

	;   write new name
	mov rax, 1
	mov rdi, 1
	mov rsi, name
	mov rdx, 8
	syscall

	;   exit
	mov rax, 60; sys_exit
	xor rdi, rdi
	syscall

	section .data
	name    db 'Zara Ali '
