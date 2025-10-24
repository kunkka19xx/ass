section    .data; Data segment
userMsg    db 'Please enter a number: '; Ask the user to enter a number
lenUserMsg equ $-userMsg; The length of the message
dispMsg    db 'You have entered: '
lenDispMsg equ $-dispMsg

section .bss; Uninitialized data
num     resb 5

section .text; Code Segment
global  _start

_start:                ;User prompt
mov rax, 1
mov rdi, 1
mov rsi, userMsg
mov rdx, lenUserMsg
syscall

;Read and store the user input
mov   rax, 0
mov   rdi, 0
mov   rsi, num
mov   rdx, 5; 5 bytes (numeric, 1 for sign) of that information
syscall

;Output the message 'The entered number is: '
mov     rax, 1
mov     rdi, 1
mov     rsi, dispMsg
mov     rdx, lenDispMsg
syscall

;Output the number entered
mov     rax, 1
mov     rdi, 1
mov     rsi, num
mov     rdx, 5
syscall

	;   Exit code
	mov rax, 60
	mov rdi, 0
	syscall
