section .data
msg     db 'hello bro'
msgLen  equ $-msg

nl db 10

section .bss
buffer  resb 32

section .text

global _start

_start:
	mov rax, 1
	mov rsi, msg
	mov rdx, msgLen
	syscall

	mov rax, 39; getpid
	syscall

	mov rbx, rax

	mov rdi, buffer + 31
	mov byte [rdi], 0

.convert_loop:
	dec  rdi
	xor  rdx, rdx
	mov  rax, rbx
	mov  rcx, 10
	div  rcx
	add  dl, '0'
	mov  [rdi], dl
	mov  rbx, rax
	test rax, rax
	jnz  .convert_loop

	mov rax, 1
	mov rdi, 1
	syscall

	mov rax, 60
	xor rdi, rdi
	syscall
