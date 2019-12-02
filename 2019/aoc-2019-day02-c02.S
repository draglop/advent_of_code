# https://adventofcode.com/2019/day/2
#
# Intcode programs are given as a list of integers; these values are used as the initial state for the computer's memory. When you run an Intcode program, make sure to start by initializing memory to the program's values. A position in memory is called an address (for example, the first value in memory is at "address 0").
#
# Opcodes (like 1, 2, or 99) mark the beginning of an instruction. The values used immediately after an opcode, if any, are called the instruction's parameters. For example, in the instruction 1,2,3,4, 1 is the opcode; 2, 3, and 4 are the parameters. The instruction 99 contains only an opcode and has no parameters.
#
# The address of the current instruction is called the instruction pointer; it starts at 0. After an instruction finishes, the instruction pointer increases by the number of values in the instruction; until you add more instructions to the computer, this is always 4 (1 opcode + 3 parameters) for the add and multiply instructions. (The halt instruction would increase the instruction pointer by 1, but it halts the program instead.)
#
# "With terminology out of the way, we're ready to proceed. To complete the gravity assist, you need to determine what pair of inputs produces the output 19690720."
#
# The inputs should still be provided to the program by replacing the values at addresses 1 and 2, just like before. In this program, the value placed in address 1 is called the noun, and the value placed in address 2 is called the verb. Each of the two input values will be between 0 and 99, inclusive.
#
# Once the program has halted, its output is available at address 0, also just like before. Each time you try a pair of inputs, make sure you first reset the computer's memory to the values in the program (your puzzle input) - in other words, don't reuse memory from a previous attempt.
#
# Find the input noun and verb that cause the program to produce the output 19690720. What is 100 * noun + verb? (For example, if noun=12 and verb=2, the answer would be 1202.)

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

.equ OUTPUT_TO_MATCH, 19690720

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
    movl    %ebx, -8(%rdi)
    movl    %ecx, -12(%rdi)
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
    sub     $16, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movl    $0, 8(%rsp) # noun
    movl    $0, 12(%rsp) # verb
.challenge_loop:
    movq    (%rsp), %rdi
    call    stack_integers_u32 # hoping that it fits
    movl    8(%rsp), %ebx
    movl    12(%rsp), %ecx
    mov     %rsp, %r9
    sub     $24, %rsp # space to integers (ret values, push ...)
    sub     %rax, %rsp
    mov     %rsp, %rdi
    add     %rax, %rdi
    mov     %rax, %rsi
    push    %r9
    call    program_run
    pop     %rsp
    cmp     $OUTPUT_TO_MATCH, %rax
    je      .challenge_wrap_up
    incl    8(%rsp)
    cmpl    $100, 8(%rsp)
    jne     .challenge_loop
    movl    $0, 8(%rsp)
    incl    12(%rsp)
    cmpl    $100, 12(%rsp)
    jne     .challenge_loop
    jmp     .challenge_error
.challenge_wrap_up:
    movl    8(%rsp), %eax
    mov     $100, %r9
    mul     %r9
    add     12(%rsp), %eax
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
