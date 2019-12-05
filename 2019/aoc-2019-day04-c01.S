# https://adventofcode.com/2019/day/4
#
# However, they do remember a few key facts about the password:
#
#   - It is a six-digit number.
#   - The value is within the range given in your puzzle input.
#   - Two adjacent digits are the same (like 22 in 122345).
#   - Going from left to right, the digits never decrease; they only ever increase or stay the same (like 111123 or 135679).
#
# Other than the range rule, the following are true:
#
#   - 111111 meets these criteria (double 11, never decreases).
#   - 223450 does not meet these criteria (decreasing pair of digits 50).
#   - 123789 does not meet these criteria (no double).
#
# How many different passwords within the range given in your puzzle input meet these criteria?


.equ ERROR_NUMBER_READ, 1
.equ ERROR_PASSWORD, 2

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_NEWLINE, '\n'

.equ PASSWORD_LENGTH, 6

.bss
.lcomm num, 12 # buffer to hold number to print, 'write' syscall refuse a data stack pointer

.text

exit_ec:
    mov     %rdi, %rbx
    movl    $1, %eax
    int     $0x80

exit_error:
    mov     $-1, %rdi
    call    exit_ec

helper_cpy:
    mov $0, %rax
.helper_cpy_loop:
    cmp     %rax, %rdx
    je      .helper_cpy_wrap_up
    movzb   (%rdi, %rax), %rbx
    mov     %bl, (%rsi, %rax)
    inc     %rax
    jmp     .helper_cpy_loop
.helper_cpy_wrap_up:
    ret

string_len:
    mov     $0, %rax
.string_len_loop:
    cmpb    $0, (%rdi)
    je      .string_len_end
    incq    %rax
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
    mov     $SYS_STDOUT, %rbx
    mov     %rdi, %rcx
    int     $0x80
    ret

number_print_u32:
    mov     $num, %r9 # buffer pointer
    movq    %rdi, %r10 # value to divide
    mov     $100000000, %r11 # divisor
    mov     $9, %r12 # loop 9 times
.number_print_u32_loop:
    mov     %r10, %rax
    mov     %r11, %rcx
    mov     $0, %rdx
    div     %rcx
    mov     %rdx, %r10
    add     $CHAR_0, %rax
    movb    %al, (%r9) # set digit
    inc     %r9
    # remove one 0 from divisor
    mov     %r11, %rax
    mov     $10, %rcx
    mov     $0, %rdx
    div     %rcx
    mov     %rax, %r11
    dec     %r12
    jne     .number_print_u32_loop
    movb    $CHAR_NEWLINE, (%r9)
    # print buffer
    mov     $num, %rdi
    call    stdout
    ret

password_check:
    movq    $0, %rax
    movzb   (%rdi), %r10
    movq    $1, %rcx
    cmp     $CHAR_0, %r10
    jl      .password_error
    cmp     $CHAR_9, %r10
    jg      .password_error
.password_loop:
    movzb   (%rdi, %rcx), %r11
    cmp     $CHAR_0, %r11
    jl      .password_error
    cmp     $CHAR_9, %r11
    jg      .password_error
    cmp     %r10, %r11
    jl      .password_ko
    jne     .password_char_next
    mov     $1, %rax
.password_char_next:
    inc     %rcx
    cmp     $PASSWORD_LENGTH, %rcx
    je      .password_wrap_up
    mov     %r11, %r10
    jmp     .password_loop
.password_ko:
    movq    $0, %rax
.password_wrap_up:
    ret
.password_error:
    movq    $ERROR_PASSWORD, %rdi
    call    exit_ec

password_end_check:
    mov     $1, %rax
    mov     $0, %rbx
.password_end_check_loop:
    movzb   (%rdi, %rbx), %rcx
    cmpb    %cl, (%rsi, %rbx)
    jne     .password_end_check_wrap_up
    inc     %rbx
    cmp     $PASSWORD_LENGTH, %rbx
    jne    .password_end_check_loop
.password_end_check_ok:
    mov     $0, %rax
.password_end_check_wrap_up:
    ret

password_init:
    push    %rdi
    lea     24(%rdi), %rsi
    mov     $PASSWORD_LENGTH, %rdx
    mov     (%rdi), %rdi
    call    helper_cpy
    pop     %rdi
    lea     16(%rdi), %rsi
    mov     $PASSWORD_LENGTH, %rdx
    mov     (%rdi), %rdi
    addq    $PASSWORD_LENGTH, %rdi
    addq    $1, %rdi
    call    helper_cpy
    ret

password_next:
    mov     $PASSWORD_LENGTH, %rax
    dec     %rax
.password_next_loop:
    incb    (%rdi, %rax)
    cmpb    $CHAR_9, (%rdi, %rax)
    jng     .password_next_wrap_up
    movb    $CHAR_0, (%rdi, %rax)
    dec     %rax
    jmp     .password_next_loop
.password_next_wrap_up:
    ret

challenge:
    push    %rbp
    mov     %rsp, %rbp
    sub     $32, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movq    $0, 8(%rsp) # password count
    movq    $0, 16(%rsp) # last password pointer
    movq    $0, 24(%rsp) # current password buffer + '\0' + 1 byte of padding
    mov     %rsp, %rdi
    call    password_init
.challenge_password_new:
    lea     24(%rsp), %rdi
    call    password_check
    addq    %rax, 8(%rsp)
    lea     24(%rsp), %rdi
    lea     16(%rsp), %rsi
    call    password_end_check
    cmp     $0, %rax
    je      .challenge_wrap_up
    lea     24(%rsp), %rdi
    call    password_next
    jmp     .challenge_password_new
.challenge_wrap_up:
    movq    8(%rsp), %rdi
    call    number_print_u32
    mov     %rbp, %rsp
    pop     %rbp
    ret

.global _start
_start:
    cmp     $2, (%rsp)
    jne     exit_error
    mov     16(%rsp), %rdi
    call    challenge
    mov     $0, %rdi
    call    exit_ec
