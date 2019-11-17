# https://adventofcode.com/2016/day/2
#
# The document goes on to explain that each button to be pressed can be found by starting on the previous button and moving to adjacent buttons on the keypad: U moves up, D moves down, L moves left, and R moves right. Each line of instructions corresponds to one button, starting at the previous button (or, for the first line, the "5" button); press whatever button you're on at the end of each line. If a move doesn't lead to a button, ignore it.
#
# You can't hold it much longer, so you decide to figure out the code as you walk to the bathroom. You picture a keypad like this:
#
# 1 2 3
# 4 5 6
# 7 8 9
#
# Suppose your instructions are:
#
# ULL
# RRDDD
# LURDL
# UUUUD
#
#     You start at "5" and move up (to "2"), left (to "1"), and left (you can't, and stay on "1"), so the first button is 1.
#     Starting from the previous button ("1"), you move right twice (to "3") and then down three times (stopping at "9" after two moves and ignoring the third), ending up with 9.
#     Continuing from "9", you move left, up, right, down, and left, ending with 8.
#     Finally, you move up four times (stopping at "2"), then down once, ending with 5.
#
# So, in this example, the bathroom code is 1985.

# gcc -O0 -no-pie -Wall

.equ SYS_WRITE, 4
.equ STDOUT, 1
.equ CHAR_0, '0'
.equ CHAR_D, 'D'
.equ CHAR_L, 'L'
.equ CHAR_R, 'R'
.equ CHAR_U, 'U'
.equ CHAR_COMMA, ','
.equ CHAR_NEWLINE, '\n'
.equ CHAR_SPACE, ' '

.bss
.lcomm num, 12 # buffer to hold number to print, 'write' syscall refuse a data stack pointer

.text

exit_error:
    mov     $-1, %rdi
    call    exit_unset

exit_unset:
    mov     %rdi, %rbx
    movl    $1, %eax
    int     $0x80

string_len:
    mov     $0, %rax
.string_len_loop:
    cmpb    $0, (%rdi)
    je      .string_len_end
    inc     %rax
    incq    %rdi
    jmp     .string_len_loop
.string_len_end:
    ret

stdout:
    push    %rdi
    call    string_len
    pop     %rdi
    mov     %rax, %rdx # length to write
    mov     $SYS_WRITE, %rax
    mov     $STDOUT, %rbx
    mov     %rdi, %rcx
    int     $0x80
    ret

button_consume:
	mov		(%rdi),	%rax
	movzb	(%rax), %rax
    cmpb    $CHAR_D, %al
    je      .button_consume_d
    cmpb    $CHAR_L, %al
    je      .button_consume_l
    cmpb    $CHAR_R, %al
    je      .button_consume_r
    cmpb    $CHAR_U, %al
    je      .button_consume_u
    jmp     .button_consume_error
.button_consume_d:
    cmpb    $1, 17(%rdi)
    je      .button_consume_wrap_up
    addb    $1, 17(%rdi)
    jmp     .button_consume_wrap_up
.button_consume_l:
    cmpb    $-1, 16(%rdi)
    je      .button_consume_wrap_up
    subb    $1, 16(%rdi)
    jmp     .button_consume_wrap_up
.button_consume_r:
    cmpb    $1, 16(%rdi)
    je      .button_consume_wrap_up
    addb    $1, 16(%rdi)
    jmp     .button_consume_wrap_up
.button_consume_u:
    cmpb    $-1, 17(%rdi)
    je      .button_consume_wrap_up
    subb    $1, 17(%rdi)
    jmp     .button_consume_wrap_up
.button_consume_wrap_up:
	incq	(%rdi)
    ret
.button_consume_error:
    mov     $1, %rdi
    call    exit_unset
    ret

digit_write:
	movzb	17(%rdi), %rbx
	inc		%rbx
	mov		$3, %rax
	mul		%rbx
	movzb	16(%rdi), %rbx
	addb 	$2, %bl
	add		%rbx, %rax
	add		$CHAR_0, %rax
    mov     8(%rdi), %rbx
	movb	%al, (%rbx)
	incq	8(%rdi)
	ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $18, %rsp
    movq    %rdi, -18(%rbp) # buffer to read pointer
    movq    $num, -10(%rbp) # buffer to write pointer
    movb    $0, -2(%rbp) # x
    movb    $0, -1(%rbp) # y
.challenge_loop:
	# check eof
    mov     -18(%rbp), %rax
    movzb   (%rax), %rax
    cmp     $0x00, %rax
    je      .challenge_wrap_up
	# check new digit
    cmp     $CHAR_NEWLINE, %rax
	jne		.challenge_button_consume
    incq    (%rsp) # consume new line
	mov		%rsp, %rdi
	call	digit_write
	jmp		.challenge_loop
.challenge_button_consume:
    mov     %rsp, %rdi
	call	button_consume
    # check eof to write last digit id buffer doesn't end by '\n'
    mov     -18(%rbp), %rax
    movzb   (%rax), %rax
    cmp     $0x00, %rax
	jne		.challenge_loop
    call    digit_write
.challenge_wrap_up:
	movb	$CHAR_NEWLINE, 8(%rsp)
	incq	8(%rsp)
	movb	$0, 8(%rsp)
	mov 	$num, %rdi
	call	stdout
    mov     %rbp, %rsp
    pop     %rbp
    ret

.global main
main:
    cmp     $2, %rdi
    jne     exit_error
    mov     8(%rsi), %rdi
    call    challenge
    mov     $0, %rax # success
    ret
