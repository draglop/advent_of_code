# https://adventofcode.com/2016/day/2
#
#     1
#   2 3 4
# 5 6 7 8 9
#   A B C
#     D
#
# You still start at "5" and stop when you're at an edge, but given the same instructions as above, the outcome is very different:
#
#     You start at "5" and don't move at all (up and left are both edges), ending at 5.
#     Continuing from "5", you move right twice and down three times (through "6", "7", "B", "D", "D"), ending at D.
#     Then, from "D", you move five more times (through "D", "B", "C", "C", "B"), ending at B.
#     Finally, after five more moves, you end at 3.
#
# So, given the actual keypad layout, the code would be 5DB3.

# gcc -O0 -no-pie -Wall

.equ SYS_WRITE, 4
.equ STDOUT, 1
.equ CHAR_0, '0'
.equ CHAR_A, 'A'
.equ CHAR_D, 'D'
.equ CHAR_L, 'L'
.equ CHAR_R, 'R'
.equ CHAR_U, 'U'
.equ CHAR_COMMA, ','
.equ CHAR_NEWLINE, '\n'
.equ CHAR_SPACE, ' '

.equ DISTANCE_MAX, 2

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

number_absolute_u64:
    mov     %rdi, %rax
    cmp     $0, %rax
    jge     .number_absolute_u64_end
    neg     %rax
.number_absolute_u64_end:
    ret

distance:
    push    %rsi
    call    number_absolute_u64
    pop     %rdi
    push    %rax
    call    number_absolute_u64
    pop     %rdi
    add     %rdi, %rax
    ret

button_consume:
    mov     (%rdi), %rax
    movzb   (%rax), %rax # button
    movsbq  16(%rdi), %rbx # bufer x
    movsbq  17(%rdi), %rcx # buffer y
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
    add     $-1, %rcx
    jmp     .button_consume_distance_check
.button_consume_l:
    add     $-1, %rbx
    jmp     .button_consume_distance_check
.button_consume_r:
    add     $1, %rbx
    jmp     .button_consume_distance_check
.button_consume_u:
    add     $1, %rcx
    jmp     .button_consume_distance_check
.button_consume_distance_check:
    push    %rdi
    push    %rbx
    push    %rcx
    mov     %rbx, %rdi
    mov     %rcx, %rsi
    call    distance
    pop     %rcx
    pop     %rbx
    pop     %rdi
    cmp     $DISTANCE_MAX, %rax
    jg      .button_consume_wrap_up
    # distance is OK, commit x and y
    movb    %bl, 16(%rdi)
    movb    %cl, 17(%rdi)
.button_consume_wrap_up:
    incq    (%rdi)
    ret
.button_consume_error:
    mov     $1, %rdi
    call    exit_unset
    ret

digit_write:
    # y influence
    movsbq  17(%rdi), %rbx
    cmp     $0, %rbx
    jl      .digit_write_y_negative
    jg      .digit_write_y_positive
    jmp     .digit_write_y_influence
.digit_write_y_negative:
    sub     $1, %rbx
    jmp     .digit_write_y_influence
.digit_write_y_positive:
    add     $1, %rbx
    jmp     .digit_write_y_influence
.digit_write_y_influence:
    mov     $2, %rax
    mul     %rbx
    neg     %rax
    add     $7, %rax
    # x influence
    movsbq  16(%rdi), %rbx
    add     %rbx, %rax
    cmp     $9, %rax
    jg      .digit_write_char
.digit_write_digit:
    add     $CHAR_0, %rax
    jmp     .digit_write_wrap_up
.digit_write_char:
    sub     $10, %rax
    add     $CHAR_A, %rax
.digit_write_wrap_up:
    mov     8(%rdi), %rbx
    movb    %al, (%rbx)
    incq    8(%rdi)
    ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $18, %rsp
    movq    %rdi, -18(%rbp) # buffer to read pointer
    movq    $num, -10(%rbp) # buffer to write pointer
    movb    $-2, -2(%rbp) # x
    movb    $0, -1(%rbp) # y
.challenge_loop:
    # check eof
    mov     -18(%rbp), %rax
    movzb   (%rax), %rax
    cmp     $0x00, %rax
    je      .challenge_wrap_up
    # check new digit
    cmp     $CHAR_NEWLINE, %rax
    jne     .challenge_button_consume
    incq    (%rsp) # consume new line
    mov     %rsp, %rdi
    call    digit_write
    jmp     .challenge_loop
.challenge_button_consume:
    mov     %rsp, %rdi
    call    button_consume
    # check eof to write last digit id buffer doesn't end by '\n'
    mov     -18(%rbp), %rax
    movzb   (%rax), %rax
    cmp     $0x00, %rax
    jne     .challenge_loop
    call    digit_write
.challenge_wrap_up:
    movb    $CHAR_NEWLINE, 8(%rsp)
    incq    8(%rsp)
    movb    $0, 8(%rsp)
    mov     $num, %rdi
    call    stdout
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
