# https://adventofcode.com/2019/day/5#part2
#
# Instead, you'll need to use the TEST to extend the thermal radiators. Fortunately, the diagnostic program (your puzzle input) is already equipped for this. Unfortunately, your Intcode computer is not.
#
# Your computer is only missing a few opcodes:
#
#   - Opcode 5 is jump-if-true: if the first parameter is non-zero, it sets the instruction pointer to the value from the second parameter. Otherwise, it does nothing.
#   - Opcode 6 is jump-if-false: if the first parameter is zero, it sets the instruction pointer to the value from the second parameter. Otherwise, it does nothing.
#   - Opcode 7 is less than: if the first parameter is less than the second parameter, it stores 1 in the position given by the third parameter. Otherwise, it stores 0.
#   - Opcode 8 is equals: if the first parameter is equal to the second parameter, it stores 1 in the position given by the third parameter. Otherwise, it stores 0.
#
# Like all instructions, these instructions need to support parameter modes as described above.
#
# Normally, after an instruction is finished, the instruction pointer increases by the number of values in that instruction. However, if the instruction modifies the instruction pointer, that value is used and the instruction pointer is not automatically increased.
#
# For example, here are several programs that take one input, compare it to the value 8, and then produce one output:
#
#   - 3,9,8,9,10,9,4,9,99,-1,8 - Using position mode, consider whether the input is equal to 8; output 1 (if it is) or 0 (if it is not).
#   - 3,9,7,9,10,9,4,9,99,-1,8 - Using position mode, consider whether the input is less than 8; output 1 (if it is) or 0 (if it is not).
#   - 3,3,1108,-1,8,3,4,3,99 - Using immediate mode, consider whether the input is equal to 8; output 1 (if it is) or 0 (if it is not).
#   - 3,3,1107,-1,8,3,4,3,99 - Using immediate mode, consider whether the input is less than 8; output 1 (if it is) or 0 (if it is not).
#
# Here are some jump tests that take an input, then output 0 if the input was zero or 1 if the input was non-zero:
#
#   - 3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9 (using position mode)
#   - 3,3,1105,-1,9,1101,0,0,12,4,12,99,1 (using immediate mode)
#
# Here's a larger example:
#
# 3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
# 1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
# 999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99
#
# The above example program uses an input instruction to ask for a single number. The program will then output 999 if the input value is below 8, output 1000 if the input value is equal to 8, or output 1001 if the input value is greater than 8.
#
# This time, when the TEST diagnostic program runs its input instruction to get the ID of the system to test, provide it 5, the ID for the ship's thermal radiator controller. This diagnostic test suite only outputs one number, the diagnostic code.
#
# What is the diagnostic code for system ID 5?

.equ ERROR_CHALLENGE, 1
.equ ERROR_NUMBER_READ, 2
.equ ERROR_PROGRAM_RUN, 3
.equ ERROR_OPERAND_BOUND, 4
.equ ERROR_OPERAND_MODE, 5

.equ INTEGER_SIZE, 4
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
.equ OPCODE_JNZ, 5
.equ OPCODE_JZ, 6
.equ OPCODE_STORE_LESS, 7
.equ OPCODE_STORE_EQU, 8
.equ OPCODE_END, 99
.equ PROGRAM_DEFAULT_INPUT, 1

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

operand_resolve_offset:
    cmp     $MODE_IMMEDIATE, %rdi
    jne     .operand_resolve_offset_position_mode
    mov     %rdx, %r8
    jmp     .operand_resolve_offset_check
.operand_resolve_offset_position_mode:
    cmp     $MODE_POSITION, %rdi
    jne     .operand_resolve_offset_mode_error
    movl    (%rsi, %rdx), %eax
    neg     %rax
    mov     $INTEGER_SIZE, %rbx
    mul     %rbx
    mov     %rax, %r8
    jmp     .operand_resolve_offset_check
.operand_resolve_offset_check:
    mov     $INTEGER_SIZE, %rax
    neg     %rax
    mul     %rcx
    cmp     %rax, %r8
    jl      .operand_resolve_offset_bound_error
    mov     %r8, %rax
    ret
.operand_resolve_offset_bound_error:
    mov     $ERROR_OPERAND_BOUND, %rdi
    call    exit_ec
.operand_resolve_offset_mode_error:
    mov     $ERROR_OPERAND_MODE, %rdi
    call    exit_ec

program_instruction_codes:
    push    %rbp
    mov     %rsp, %rbp
    mov     $0, %rdx
    mov     %rdi, %rax
    mov     $100, %rbx
    div     %rbx
    mov     %rdx, %r8 # opcode
    mov     $0, %rdx
    div     %rbx
    mov     %rax, %r11 # destination address mode
    mov     %rdx, %rax
    mov     $10, %rbx
    mov     $0, %rdx
    div     %rbx
    mov     %rax, %r10 # second operand address mode
    mov     %rdx, %r9 # first operand address mode
    pop     %rbp
    ret

program_run:
    push    %rbp
    mov     %rsp, %rbp
    push    %rdx # program input value
    push    %rsi # program instructions count
    push    %rdi # program instructions base
    push    $0 # current instruction offset
.program_run_loop:
    mov     (%rsp), %rax
    mov     8(%rsp), %rbx # program instruction base
    movl    (%rbx, %rax), %edi
    call    program_instruction_codes
    subq    $INTEGER_SIZE, (%rsp) # consume command
    cmp     $OPCODE_END, %r8
    je      .program_run_wrap_up
    cmp     $OPCODE_ADD, %r8
    je      .program_run_add
    cmp     $OPCODE_MUL, %r8
    je      .program_run_mul
    cmp     $OPCODE_PRINT, %r8
    je      .program_run_print
    cmp     $OPCODE_IN, %r8
    je      .program_run_input
    cmp     $OPCODE_STORE_LESS, %r8
    je      .program_run_store_less
    cmp     $OPCODE_STORE_EQU, %r8
    je      .program_run_store_equ
    cmp     $OPCODE_JZ, %r8
    je      .program_run_jz
    cmp     $OPCODE_JNZ, %r8
    je      .program_run_jnz
    jmp     .program_run_error
.program_run_add:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    mov     8(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store first value
    # second operand
    mov     %r10, %rdi # operand mode
    mov     16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # instructions offset
    mov     24(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 8(%rsp) # consume command
    mov     16(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store second value
    # third operand
    mov     %r11, %rdi # operand mode
    mov     24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # instructions offset
    mov     32(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 16(%rsp) # consume command
    mov     %rax, %rbx
    # add
    pop     %rax
    pop     %rcx
    add     %rcx, %rax
    # write destination
    mov     8(%rsp), %rdx
    movl    %eax, (%rdx, %rbx)
    jmp     .program_run_loop
.program_run_input:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    # write destination
    mov     8(%rsp), %rdx
    mov     24(%rsp), %rbx
    movl    %ebx, (%rdx, %rax)
    jmp     .program_run_loop
.program_run_mul:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    mov     8(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store first value
    # second operand
    mov     %r10, %rdi # operand mode
    mov     16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # instructions offset
    mov     24(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 8(%rsp) # consume command
    mov     16(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store second value
    # third operand
    mov     %r11, %rdi # operand mode
    mov     24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # instructions offset
    mov     32(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 16(%rsp) # consume command
    mov     %rax, %rbx
    # mul
    pop     %rax
    pop     %rcx
    mul     %rcx
    # write destination
    mov     8(%rsp), %rdx
    movl    %eax, (%rdx, %rbx)
    jmp     .program_run_loop
.program_run_print:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    mov     8(%rsp), %rdx
    movl    (%rdx, %rax), %edi
    call    number_print_u32
    jmp     .program_run_loop
.program_run_store_equ:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    mov     8(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store first value
    # second operand
    mov     %r10, %rdi # operand mode
    mov     16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # instructions offset
    mov     24(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 8(%rsp) # consume command
    mov     16(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store second value
    # third operand
    mov     %r11, %rdi # operand mode
    mov     24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # instructions offset
    mov     32(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 16(%rsp) # consume command
    mov     %rax, %rbx
    # compare
    pop     %rax
    pop     %rcx
    cmp     %rcx, %rax
    je      .program_run_store_equ_1
    xor     %rax, %rax
    jmp     .program_run_store_equ_wrap_up
.program_run_store_equ_1:
    mov     $1, %rax
.program_run_store_equ_wrap_up:
    # write destination
    mov     8(%rsp), %rdx
    movl    %eax, (%rdx, %rbx)
    jmp     .program_run_loop
.program_run_store_less:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    mov     8(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store first value
    # second operand
    mov     %r10, %rdi # operand mode
    mov     16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # instructions offset
    mov     24(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 8(%rsp) # consume command
    mov     16(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store second value
    # third operand
    mov     %r11, %rdi # operand mode
    mov     24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # instructions offset
    mov     32(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 16(%rsp) # consume command
    mov     %rax, %rbx
    # compare
    pop     %rax
    pop     %rcx
    cmp     %rax, %rcx
    jl      .program_run_store_less_1
    xor     %rax, %rax
    jmp     .program_run_store_less_wrap_up
.program_run_store_less_1:
    mov     $1, %rax
.program_run_store_less_wrap_up:
    # write destination
    mov     8(%rsp), %rdx
    movl    %eax, (%rdx, %rbx)
    jmp     .program_run_loop
.program_run_jnz:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    mov     8(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store first value
    # second operand
    mov     %r10, %rdi # operand mode
    mov     16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # instructions offset
    mov     24(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 8(%rsp) # consume command
    # compare
    pop     %rbx
    cmp     $0, %rbx
    je      .program_run_loop
    mov     8(%rsp), %rdx # instructions base
    movl    (%rdx, %rax), %ebx
    mov     $INTEGER_SIZE, %rax
    neg     %rax
    mul     %rbx
    mov     %rax, (%rsp)
    jmp     .program_run_loop
.program_run_jz:
    # first operand
    mov     %r9, %rdi # operand mode
    mov     8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # instructions offset
    mov     16(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, (%rsp) # consume command
    mov     8(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    push    %rbx # store first value
    # second operand
    mov     %r10, %rdi # operand mode
    mov     16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # instructions offset
    mov     24(%rsp), %rcx # instructions count
    call    operand_resolve_offset
    sub     $INTEGER_SIZE, 8(%rsp) # consume command
    # compare
    pop     %rbx
    cmp     $0, %rbx
    jne     .program_run_loop
    mov     8(%rsp), %rdx # instructions base
    movl    (%rdx, %rax), %ebx
    mov     $INTEGER_SIZE, %rax
    neg     %rax
    mul     %rbx
    mov     %rax, (%rsp)
    jmp     .program_run_loop
.program_run_wrap_up:
    mov     %rbp, %rsp
    pop     %rbp
    ret
.program_run_error:
    movq    $ERROR_PROGRAM_RUN, %rdi
    call    exit_ec

stack_integers_s32:
    push    $0 # integers count
.stack_integers_s32_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .stack_integers_wrap_up
    cmpb    $INTEGER_SEPARATOR, (%rdi)
    je      .stack_integers_char_consume
    call    number_read_s # overwrite %rsp-8
    mov     %rax, %r8
    mov     (%rsp), %rax
    mov     $INTEGER_SIZE, %rcx
    mul     %rcx
    neg     %rax # stack growns downward
    sub     $12, %rax # -12 to not get stomp by stack integers call
    movl    %r8d, (%rsp, %rax)
    incq    (%rsp)
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
    push    %rsi # program input value
    call    stack_integers_s32 # hoping that it fits
    pop     %rsi
    sub     $36, %rsp # unused space to integers (ret values, push ...)
    mov     %rsp, %rdi # integers pointer
    mov     %rsi, %rcx # save program input
    mov     %rax, %rsi # integers count
    mov     $INTEGER_SIZE, %rbx
    mul     %rbx
    sub     %rax, %rsp
    mov     %rcx, %rdx
    call    program_run
    mov     %rbp, %rsp
    pop     %rbp
    ret
.challenge_error:
    movq    $ERROR_CHALLENGE, %rdi
    call    exit_ec

.global _start
_start:
    cmp     $1, (%rsp)
    jle     exit_error
    movq    $PROGRAM_DEFAULT_INPUT, %rsi
    cmp     $3, (%rsp)
    jg      exit_error
    jl      ._start_challenge # no input value, used default
    # input value provided, read it
    mov     24(%rsp), %rdi
    call    number_read_s
    movl    %eax, %esi
._start_challenge:
    mov     16(%rsp), %rdi
    call    challenge
    mov     $0, %rdi
    call    exit_ec
