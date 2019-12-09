# https://adventofcode.com/2019/day/5
#
# The Thermal Environment Supervision Terminal (TEST) starts by running a diagnostic program (your puzzle input). The TEST diagnostic program will run on your existing Intcode computer after a few modifications:
#
# First, you'll need to add two new instructions:
#
#   - Opcode 3 takes a single integer as input and saves it to the address given by its only parameter. For example, the instruction 3,50 would take an input value and store it at address 50.
#   - Opcode 4 outputs the value of its only parameter. For example, the instruction 4,50 would output the value at address 50.
#
# Programs that use these instructions will come with documentation that explains what should be connected to the input and output. The program 3,0,4,0,99 outputs whatever it gets as input, then halts.
#
# Second, you'll need to add support for parameter modes:
#
# Each parameter of an instruction is handled based on its parameter mode. Right now, your ship computer already understands parameter mode 0, position mode, which causes the parameter to be interpreted as a position - if the parameter is 50, its value is the value stored at address 50 in memory. Until now, all parameters have been in position mode.
#
# Now, your ship computer will also need to handle parameters in mode 1, immediate mode. In immediate mode, a parameter is interpreted as a value - if the parameter is 50, its value is simply 50.
#
# Parameter modes are stored in the same value as the instruction's opcode. The opcode is a two-digit number based only on the ones and tens digit of the value, that is, the opcode is the rightmost two digits of the first value in an instruction. Parameter modes are single digits, one per parameter, read right-to-left from the opcode: the first parameter's mode is in the hundreds digit, the second parameter's mode is in the thousands digit, the third parameter's mode is in the ten-thousands digit, and so on. Any missing modes are 0.
#
# For example, consider the program 1002,4,3,4,33.
#
# The first instruction, 1002,4,3,4, is a multiply instruction - the rightmost two digits of the first value, 02, indicate opcode 2, multiplication. Then, going right to left, the parameter modes are 0 (hundreds digit), 1 (thousands digit), and 0 (ten-thousands digit, not present and therefore zero):
#
# ABCDE
#  1002
#
# DE - two-digit opcode,      02 == opcode 2
#  C - mode of 1st parameter,  0 == position mode
#  B - mode of 2nd parameter,  1 == immediate mode
#  A - mode of 3rd parameter,  0 == position mode,
#                                   omitted due to being a leading zero
#
# This instruction multiplies its first two parameters. The first parameter, 4 in position mode, works like it did before - its value is the value stored at address 4 (33). The second parameter, 3 in immediate mode, simply has value 3. The result of this operation, 33 * 3 = 99, is written according to the third parameter, 4 in position mode, which also works like it did before - 99 is written to address 4.
#
# Parameters that an instruction writes to will never be in immediate mode.
#
# Finally, some notes:
#
#   - It is important to remember that the instruction pointer should increase by the number of values in the instruction after the instruction finishes. Because of the new instructions, this amount is no longer always 4.
#   - Integers can be negative: 1101,100,-1,4,0 is a valid program (find 100 + -1, store the result in position 4).
#
# The TEST diagnostic program will start by requesting from the user the ID of the system to test by running an input instruction - provide it 1, the ID for the ship's air conditioner unit.
#
# It will then perform a series of diagnostic tests confirming that various parts of the Intcode computer, like parameter modes, function correctly. For each test, it will run an output instruction indicating how far the result of the test was from the expected value, where 0 means the test was successful. Non-zero outputs mean that a function is not working correctly; check the instructions that were run before the output instruction to see which one failed.
#
# Finally, the program will output a diagnostic code and immediately halt. This final output isn't an error; an output followed immediately by a halt means the program finished. If all outputs were zero except the diagnostic code, the diagnostic program ran successfully.
#
# After providing 1 to the only input instruction and passing all the tests, what diagnostic code does the program produce?

.equ ERROR_CHALLENGE, 1
.equ ERROR_NUMBER_READ, 2
.equ ERROR_PROGRAM_RUN, 3
.equ ERROR_DESTINATION_MODE, 4
.equ ERROR_OPERAND_MODE, 5

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_NEWLINE, '\n'
.equ CHAR_MINUS, '-'

.equ INTEGER_SEPARATOR, ','
.equ MODE_POSITION, 0
.equ MODE_IMMEDIATE, 1
.equ OPCODE_ADD, 1
.equ OPCODE_MUL, 2
.equ OPCODE_IN, 3
.equ OPCODE_PRINT, 4
.equ OPCODE_END, 99
.equ PROGRAM_INPUT, 1

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

number_read_s:
    mov     $0, %rax # accumulator
    mov     $0, %r10 # number of digit read
    mov     $10, %r11 # digit multiplicator
    mov     $0, %r12 # negative flag
    cmpb    $CHAR_MINUS, (%rdi)
    je      .number_read_s_negative_flag
.number_read_s_loop:
    movzb   (%rdi), %rbx
    cmpb    $CHAR_0, %bl
    jl      .number_read_s_wrap_up
    cmpb    $CHAR_9, %bl
    jg      .number_read_s_wrap_up
    mul     %r11 # shift previous number by one digit: x10
    sub     $CHAR_0, %bl
    add     %rbx, %rax
    inc     %r10
    incq    %rdi
    jmp     .number_read_s_loop
.number_read_s_negative_flag:
    mov     $1, %r12
    incq    %rdi
    jmp     .number_read_s_loop
.number_read_s_wrap_up:
    cmp     $0, %r10
    je      .number_read_s_error
    cmp     $0, %r12
    je      .number_read_s_end
    neg     %rax
.number_read_s_end:
    ret
.number_read_s_error:
    mov     $ERROR_NUMBER_READ, %rdi
    call    exit_ec
    ret

operand_resolve:
    cmp     $MODE_IMMEDIATE, %rdx
    jne     .operand_resolve_position
    mov     %rsi, %rax
    jmp     .operand_resolve_wrap_up
.operand_resolve_position:
    cmp     $MODE_POSITION, %rdx
    jne     .operand_resolve_error
    mov     $4, %rax
    mul     %rsi
    neg     %rax
    movl    -4(%rdi, %rax), %eax
.operand_resolve_wrap_up:
    ret
.operand_resolve_error:
    mov     $ERROR_OPERAND_MODE, %rdi
    call    exit_ec

program_instruction_codes:
    push    %rbp
    mov     %rsp, %rbp
    mov     $0, %rdx
    mov     %rdi, %rax
    mov     $100, %rbx
    div     %rbx
    mov     %rdx, %r9 # opcode
    mov     $0, %rdx
    div     %rbx
    mov     %rax, %r12 # destination address mode
    mov     %rdx, %rax
    mov     $10, %rbx
    mov     $0, %rdx
    div     %rbx
    mov     %rax, %r10 # second operand address mode
    mov     %rdx, %r11 # first operant address mode
    mov     %r9, %rax
    mov     %r12, %rbx
    mov     %r10, %rdx
    mov     %r11, %rcx
    pop     %rbp
    ret

program_run_destination_mode_error:
    mov     $ERROR_DESTINATION_MODE, %rdi
    call    exit_ec

program_run:
    push    %rbp
    mov     %rsp, %rbp
    sub     $24, %rsp
    mov     %rdi, (%rsp) # program instruction base
    movq    $0, 8(%rsp) # program instruction offset
    mov     %rsi, 16(%rsp) # single program input value
.program_run_loop:
    mov     (%rsp), %r9 # program instruction base
    mov     8(%rsp), %r10 # program instruction offset
    movl    -4(%r9, %r10), %edi
    call    program_instruction_codes
    cmp     $MODE_POSITION, %rbx
    jne     program_run_destination_mode_error
    cmp     $OPCODE_END, %rax
    je      .program_run_wrap_up
    cmp     $OPCODE_ADD, %rax
    je      .program_run_add
    cmp     $OPCODE_MUL, %rax
    je      .program_run_mul
    cmp     $OPCODE_PRINT, %rax
    je      .program_run_print
    cmp     $OPCODE_IN, %rax
    je      .program_run_input
    jmp     .program_run_error
.program_run_mul:
    mov     (%rsp), %r9 # program instruction base
    mov     8(%rsp), %r10 # program instruction offset
    push    %rdx
    # first operand
    mov     %r9, %rdi
    movl    -8(%r9, %r10), %esi
    mov     %rcx, %rdx
    call    operand_resolve
    # second operand
    pop     %rdx
    push    %rax # save first operand
    mov     %r9, %rdi
    movl    -12(%r9, %r10), %esi
    call    operand_resolve
    # mul
    pop     %rbx
    mul     %rbx
    # write destination
    movl    -16(%r9, %r10), %edi
    mov     %rax, %rsi
    mov     $16, %rcx
    jmp     .program_run_destination
.program_run_add:
    mov     (%rsp), %r9 # program instruction base
    mov     8(%rsp), %r10 # program instruction offset
    push    %rdx
    # first operand
    mov     %r9, %rdi
    movl    -8(%r9, %r10), %esi
    mov     %rcx, %rdx
    call    operand_resolve
    # second operand
    pop     %rdx
    push    %rax # save first operand
    mov     %r9, %rdi
    movl    -12(%r9, %r10), %esi
    call    operand_resolve
    # add
    pop     %rsi
    add     %rax, %rsi
    # write destination
    movl    -16(%r9, %r10), %edi
    mov     $16, %rcx
    jmp     .program_run_destination
.program_run_print:
    mov     (%rsp), %r9 # program instruction base
    mov     8(%rsp), %r10 # program instruction offset
    # first operand
    mov     %r9, %rdi
    movl    -8(%r9, %r10), %esi
    mov     %rcx, %rdx
    call    operand_resolve
    mov     %rax, %rdi
    call    number_print_u32
    mov     $8, %rdi
    jmp     .program_run_advance
.program_run_input:
    mov     (%rsp), %r9 # program instruction base
    mov     8(%rsp), %r10 # program instruction offset
    # write destination
    movl    -8(%r9, %r10), %edi
    mov     16(%rsp), %rsi
    mov     $8, %rcx
    jmp     .program_run_destination
.program_run_destination:
    mov     $4, %rax
    mul     %rdi
    neg     %rax
    movl    %esi, -4(%r9, %rax)
    # advance
    mov     %rcx, %rdi
    jmp     .program_run_advance
.program_run_advance:
    sub     %rdi, 8(%rsp)
    jmp     .program_run_loop
.program_run_wrap_up:
    mov     %rbp, %rsp
    pop     %rbp
    ret
.program_run_error:
    movq    $ERROR_PROGRAM_RUN, %rdi
    call    exit_ec

stack_integers_s32:
    push    $0 # rsp offset used
.stack_integers_s32_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .stack_integers_wrap_up
    cmpb    $INTEGER_SEPARATOR, (%rdi)
    je      .stack_integers_char_consume
    call    number_read_s # overwrite %rsp-8
    lea     -12(%rsp), %rcx
    mov     (%rsp), %rbx
    sub     %rbx, %rcx
    movl    %eax, (%rcx)
    add     $4, (%rsp)
    jmp     .stack_integers_s32_loop
.stack_integers_char_consume:
    incq    %rdi
    jmp     .stack_integers_s32_loop
.stack_integers_wrap_up:
    pop     %rax
    ret

challenge:
    push    %rbp
    mov     %rsp, %rbp
    sub     $8, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    call    stack_integers_s32 # hoping that it fits
    sub     $24, %rsp # space to integers (ret values, push ...)
    sub     %rax, %rsp
    mov     %rsp, %rdi
    add     %rax, %rdi
    mov     $PROGRAM_INPUT, %rsi
    call    program_run
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
