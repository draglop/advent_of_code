# https://adventofcode.com/2019/day/1
#
# Fuel required to launch a given module is based on its mass. Specifically, to find the fuel required for a module, take its mass, divide by three, round down, and subtract 2.
#
# For example:
#
#     For a mass of 12, divide by 3 and round down to get 4, then subtract 2 to get 2.
#     For a mass of 14, dividing by 3 and rounding down still yields 4, so the fuel required is also 2.
#     For a mass of 1969, the fuel required is 654.
#     For a mass of 100756, the fuel required is 33583.
#
# The Fuel Counter-Upper needs to know the total fuel requirement. To find it, individually calculate the fuel needed for the mass of each module (your puzzle input), then add together all the fuel values.
#
# What is the sum of the fuel requirements for all of the modules on your spacecraft?


.equ ERROR_CHALLENGE, 1
.equ ERROR_NUMBER_READ, 2

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_NEWLINE, '\n'

.equ FUEL_DIVISOR, 3
.equ FUEL_SUBSTRACT, 2

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

number_read_u:
    mov     $0, %rax # accumulator
    mov     $0, %r10 # number of digit read
    mov     $10, %r12 # digit multiplicator
.number_read_u_loop:
    mov     (%rdi), %rbx
    movzb   (%rbx), %rbx
    cmpb    $CHAR_0, %bl
    jl      .number_read_u_wrap_up
    cmpb    $CHAR_9, %bl
    jg      .number_read_u_wrap_up
    mul     %r12 # shift previous number by one digit: x10
    sub     $CHAR_0, %bl
    add     %rbx, %rax
    inc     %r10
    incq    (%rdi)
    jmp     .number_read_u_loop
.number_read_u_wrap_up:
    cmp     $0, %r10
    je      .number_read_u_error
    ret
.number_read_u_error:
    mov     $ERROR_NUMBER_READ, %rdi
    call    exit_ec

challenge:
    push    %rbp
    mov     %rsp, %rbp
    sub     $16, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movq    $0, 8(%rsp) # fuel accumulator
.challenge_number_new:
    # check eof
    movq    (%rsp), %rax
    movzb   (%rax), %rax
    cmp     $CHAR_EOF, %rax
    je      .challenge_wrap_up
    # check new line
    cmp     $CHAR_NEWLINE, %rax
    je      .challenge_line_consume
    # process number`
    movq    %rsp, %rdi
    call    number_read_u
    movq    $FUEL_DIVISOR, %rcx
    div     %rcx
    sub     $FUEL_SUBSTRACT, %rax
    addq    %rax, 8(%rsp)
    jmp     .challenge_number_new
.challenge_line_consume:
    incq    (%rsp)
    jmp     .challenge_number_new
.challenge_wrap_up:
    movq    8(%rsp), %rdi
    call    number_print_u32
    mov     %rbp, %rsp
    pop     %rbp
    ret
.challenge_error:
    movq    $ERROR_CHALLENGE, %rdi
    call    exit_ec

.global _start
_start:
    cmp     $2, (%rsp)
    jne     exit_error
    mov     16(%rsp), %rdi
    call    challenge
    mov     $0, %rdi
    call    exit_ec
