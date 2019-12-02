# https://adventofcode.com/2019/day/2
#
# An Intcode program is a list of integers separated by commas (like 1,0,0,3,99). To run one, start by looking at the first integer (called position 0). Here, you will find an opcode - either 1, 2, or 99. The opcode indicates what to do; for example, 99 means that the program is finished and should immediately halt. Encountering an unknown opcode means something went wrong.
#
# Opcode 1 adds together numbers read from two positions and stores the result in a third position. The three integers immediately after the opcode tell you these three positions - the first two indicate the positions from which you should read the input values, and the third indicates the position at which the output should be stored.
#
# For example, if your Intcode computer encounters 1,10,20,30, it should read the values at positions 10 and 20, add those values, and then overwrite the value at position 30 with their sum.
#
# Opcode 2 works exactly like opcode 1, except it multiplies the two inputs instead of adding them. Again, the three integers after the opcode indicate where the inputs and outputs are, not their values.
#
# Once you're done processing an opcode, move to the next one by stepping forward 4 positions.
#
# For example, suppose you have the following program:
#
# 1,9,10,3,2,3,11,0,99,30,40,50
#
# For the purposes of illustration, here is the same program split into multiple lines:
#
# 1,9,10,3,
# 2,3,11,0,
# 99,
# 30,40,50
#
# The first four integers, 1,9,10,3, are at positions 0, 1, 2, and 3. Together, they represent the first opcode (1, addition), the positions of the two inputs (9 and 10), and the position of the output (3). To handle this opcode, you first need to get the values at the input positions: position 9 contains 30, and position 10 contains 40. Add these numbers together to get 70. Then, store this value at the output position; here, the output position (3) is at position 3, so it overwrites itself. Afterward, the program looks like this:
#
# 1,9,10,70,
# 2,3,11,0,
# 99,
# 30,40,50
#
# Step forward 4 positions to reach the next opcode, 2. This opcode works just like the previous, but it multiplies instead of adding. The inputs are at positions 3 and 11; these positions contain 70 and 50 respectively. Multiplying these produces 3500; this is stored at position 0:
#
# 3500,9,10,70,
# 2,3,11,0,
# 99,
# 30,40,50
#
# Stepping forward 4 more positions arrives at opcode 99, halting the program.
#
# Here are the initial and final states of a few more small programs:
#
#     1,0,0,0,99 becomes 2,0,0,0,99 (1 + 1 = 2).
#     2,3,0,3,99 becomes 2,3,0,6,99 (3 * 2 = 6).
#     2,4,4,5,99,0 becomes 2,4,4,5,99,9801 (99 * 99 = 9801).
#     1,1,1,4,99,5,6,0,99 becomes 30,1,1,4,2,5,6,0,99.
#
# Once you have a working computer, the first step is to restore the gravity assist program (your puzzle input) to the "1202 program alarm" state it had just before the last computer caught fire. To do this, before running the program, replace position 1 with the value 12 and replace position 2 with the value 2. What value is left at position 0 after the program halts?

.equ ERROR_CHALLENGE, 1
.equ ERROR_NUMBER_READ, 2
.equ ERROR_PROGRAM_RUN, 3

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_NEWLINE, '\n'

.equ INTEGER_SEPARATOR, ','
.equ OPCODE_ADD, 1
.equ OPCODE_MUL, 2
.equ OPCODE_END, 99

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
    movzb   (%rdi), %rbx
    cmpb    $CHAR_0, %bl
    jl      .number_read_u_wrap_up
    cmpb    $CHAR_9, %bl
    jg      .number_read_u_wrap_up
    mul     %r12 # shift previous number by one digit: x10
    sub     $CHAR_0, %bl
    add     %rbx, %rax
    inc     %r10
    incq    %rdi
    jmp     .number_read_u_loop
.number_read_u_wrap_up:
    cmp     $0, %r10
    je      .number_read_u_error
    ret
.number_read_u_error:
    mov     $ERROR_NUMBER_READ, %rdi
    call    exit_ec
    ret

stack_integers_u32:
    push    $0 # rsp offset used
.stack_integers_u32_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .stack_integers_wrap_up
    cmpb    $INTEGER_SEPARATOR, (%rdi)
    je      .stack_integers_char_consume
    call    number_read_u # overwrite %rsp-8
    lea    -12(%rsp), %rcx
    mov     (%rsp), %rbx
    sub     %rbx, %rcx
    movl    %eax, (%rcx)
    add     $4, (%rsp)
    jmp     .stack_integers_u32_loop
.stack_integers_char_consume:
    incq    %rdi
    jmp     .stack_integers_u32_loop
.stack_integers_wrap_up:
    pop     %rax
    ret

program_run:
    cmpl    $OPCODE_END, -4(%rdi)
    je      .program_run_wrap_up
    movl    $12, -8(%rdi)
    movl    $2, -12(%rdi)
    mov     $0, %r9 # integer offset
    mov     $4, %r10 # position multiplicator
.program_run_loop:
    cmpl    $OPCODE_END, -4(%rdi, %r9)
    je      .program_run_wrap_up
    # first operand
    movl    -8(%rdi, %r9), %eax
    mul     %r10
    neg     %rax
    movl    -4(%rdi, %rax), %ebx
    # second operand
    movl    -12(%rdi, %r9), %eax
    mul     %r10
    neg     %rax
    movl    -4(%rdi, %rax), %ecx
    # destination
    movl    -16(%rdi, %r9), %eax
    mul     %r10
    neg     %rax
    mov     %rax, %r11
    cmpl    $OPCODE_ADD, -4(%rdi, %r9)
    je      .program_run_add
    cmpl    $OPCODE_MUL, -4(%rdi, %r9)
    je      .program_run_mul
    jmp     .program_run_error
.program_run_add:
    add     %ebx, %ecx
    movl    %ecx, -4(%rdi, %r11)
    jmp     .program_run_advance
.program_run_mul:
    movl    %ebx, %eax
    mul     %ecx
    movl    %eax, -4(%rdi, %r11)
    jmp     .program_run_advance
.program_run_advance:
    sub     $16, %r9
    jmp     .program_run_loop
.program_run_wrap_up:
    movl    -4(%rdi), %eax
    ret
.program_run_error:
    movq    $ERROR_PROGRAM_RUN, %rdi
    call    exit_ec

challenge:
    push    %rbp
    mov     %rsp, %rbp
    sub     $8, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    call    stack_integers_u32 # hoping that it fits
    sub     $24, %rsp # space to integers (ret values, push ...)
    sub     %rax, %rsp
.debug:
    mov     %rsp, %rdi
    add     %rax, %rdi
    mov     %rax, %rsi
    call    program_run
    mov     %rax, %rdi
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
