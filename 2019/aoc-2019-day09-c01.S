# https://adventofcode.com/2019/day/9
#
#You've just said goodbye to the rebooted rover and left Mars when you receive a faint distress signal coming from the asteroid belt. It must be the Ceres monitoring station!
#
#In order to lock on to the signal, you'll need to boost your sensors. The Elves send up the latest BOOST program - Basic Operation Of System Test.
#
#While BOOST (your puzzle input) is capable of boosting your sensors, for tenuous safety reasons, it refuses to do so until the computer it runs on passes some checks to demonstrate it is a complete Intcode computer.
#
#Your existing Intcode computer is missing one key feature: it needs support for parameters in relative mode.
#
#Parameters in mode 2, relative mode, behave very similarly to parameters in position mode: the parameter is interpreted as a position. Like position mode, parameters in relative mode can be read from or written to.
#
#The important difference is that relative mode parameters don't count from address 0. Instead, they count from a value called the relative base. The relative base starts at 0.
#
#The address a relative mode parameter refers to is itself plus the current relative base. When the relative base is 0, relative mode parameters and position mode parameters with the same value refer to the same address.
#
#For example, given a relative base of 50, a relative mode parameter of -7 refers to memory address 50 + -7 = 43.
#
#The relative base is modified with the relative base offset instruction:
#
# -  Opcode 9 adjusts the relative base by the value of its only parameter. The relative base increases (or decreases, if the value is negative) by the value of the parameter.
#
#For example, if the relative base is 2000, then after the instruction 109,19, the relative base would be 2019. If the next instruction were 204,-34, then the value at address 1985 would be output.
#
#Your Intcode computer will also need a few other capabilities:
#
# -  The computer's available memory should be much larger than the initial program. Memory beyond the initial program starts with the value 0 and can be read or written like any other memory. (It is invalid to try to access memory at a negative address, though.)
# -  The computer should have support for large numbers. Some instructions near the beginning of the BOOST program will verify this capability.
#
#Here are some example programs that use these features:
#
# -  109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99 takes no input and produces a copy of itself as output.
# -  1102,34915192,34915192,7,4,7,99,0 should output a 16-digit number.
# -  104,1125899906842624,99 should output the large number in the middle.
#
#The BOOST program will ask for a single input; run it in test mode by providing it the value 1. It will perform a series of checks on each opcode, output any opcodes (and the associated parameter modes) that seem to be functioning incorrectly, and finally output a BOOST keycode.
#
#Once your Intcode computer is fully functional, the BOOST program should report no malfunctioning opcodes when run in test mode; it should only output a single value, the BOOST keycode. What BOOST keycode does it produce?

.equ ERROR_UNDEFINED, -1
.equ ERROR_CHALLENGE, 1
.equ ERROR_NUMBER_READ, 2
.equ ERROR_PROGRAM_RUN, 3
.equ ERROR_PROGRAM_RUN_DESTINATION, 4
.equ ERROR_DESTINATION_MODE, 5
.equ ERROR_OPERAND_BOUND, 6
.equ ERROR_OPERAND_MODE, 7

.equ INTEGER_SIZE, 8
.equ NEG_INTEGER_SIZE, -8
.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_NEWLINE, '\n'
.equ CHAR_MINUS, '-'

.equ INTEGER_SEPARATOR, ','
.equ MODE_ABSOLUTE, 0
.equ MODE_IMMEDIATE, 1
.equ MODE_RELATIVE, 2
.equ OPCODE_ADD, 1
.equ OPCODE_MUL, 2
.equ OPCODE_IN, 3
.equ OPCODE_PRINT, 4
.equ OPCODE_JNZ, 5
.equ OPCODE_JZ, 6
.equ OPCODE_STORE_LESS, 7
.equ OPCODE_STORE_EQU, 8
.equ OPCODE_BASE, 9
.equ OPCODE_END, 99
.equ PROGRAM_ARRAY_MIN_SIZE, 3000
.equ PROGRAM_DEFAULT_INPUT, 1

.bss
.lcomm num, 18 # buffer to hold number to print, 'write' syscall refuse a data stack pointer

.text

exit_ec:
    mov     %rdi, %rbx
    movq    $1, %rax
    int     $0x80

exit_error:
    mov     $ERROR_UNDEFINED, %rdi
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

number_print_u64:
    movq    $num, %r9 # buffer pointer
    movb    $CHAR_0, (%r9)
    cmp     $0, %rdi
    jge     .number_print_s64_unsigned
    movb    $CHAR_MINUS, (%r9) # set digit
    neg     %rdi
.number_print_s64_unsigned:
    inc     %r9
    movq    %rdi, %r10 # value to divide
    movq    $1000000000000000, %r11 # divisor
    movq    $16, %r12 # loop 9 times
.number_print_u64_loop:
    movq    %r10, %rax
    movq    %r11, %rcx
    movq    $0, %rdx
    div     %rcx
    movq    %rdx, %r10
    add     $CHAR_0, %rax
    movb    %al, (%r9) # set digit
    inc     %r9
    # remove one 0 from divisor
    movq    %r11, %rax
    movq    $10, %rcx
    movq    $0, %rdx
    div     %rcx
    movq    %rax, %r11
    dec     %r12
    jne     .number_print_u64_loop
    movb    $CHAR_NEWLINE, (%r9)
    # print buffer
    movq    $num, %rdi
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

program_operand_resolve_index:
    #rdi: operand mode
    #rsi: integers array base
    #rdx: current instruction index
    #rcx: integers array size
    #rbx: relative mode base offset
    cmp     $MODE_IMMEDIATE, %rdi
    je     .program_operand_resolve_index_immediate
    cmp     $MODE_ABSOLUTE, %rdi
    je     .program_operand_resolve_index_absolute
    cmp     $MODE_RELATIVE, %rdi
    je     .program_operand_resolve_index_relative
    jmp    .program_operand_resolve_index_mode_error
.program_operand_resolve_index_absolute:
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %rdx
    mov     (%rsi, %rax), %r8
    jmp     .program_operand_resolve_index_check
.program_operand_resolve_index_immediate:
    mov     %rdx, %r8
    jmp     .program_operand_resolve_index_check
.program_operand_resolve_index_relative:
    # todo: should check that value is in bound
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %rdx
    mov     (%rsi, %rax), %r8
    add     %rbx, %r8
    jmp     .program_operand_resolve_index_check
.program_operand_resolve_index_check:
    cmp     %rcx, %r8
    jge     .program_operand_resolve_index_bound_error
    mov     %r8, %rax
    ret
.program_operand_resolve_index_bound_error:
    mov     $ERROR_OPERAND_BOUND, %rdi
    call    exit_ec
.program_operand_resolve_index_mode_error:
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
    push    $0   # single program relative base value
    push    %rsi # program instructions count
    push    %rdi # program instructions base
    push    $0 # current instruction offset
.program_run_loop:
    mov     (%rsp), %rax
    mov     $NEG_INTEGER_SIZE, %rbx
    mul     %rbx
    mov     8(%rsp), %rbx # program instruction base
    movq    (%rbx, %rax), %rdi
    call    program_instruction_codes
    incq    (%rsp) # consume command
    # r9:  operation code
    # r10: first operand address mode
    # r11: second operand address mode
    # r12: third operand address mode
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
    cmp     $OPCODE_BASE, %r8
    je      .program_run_base
    jmp     .program_run_error
.program_run_add:
   # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    push    %rax
    # second operand
    mov     %r10, %rdi # operand mode
    movq    16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # current instruction index
    mov     24(%rsp), %rcx # instructions count
    movq    32(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    8(%rsp) # consume command
    push    %rax
    # third operand
    mov     %r11, %rdi # operand mode
    movq    24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # current instruction index
    mov     32(%rsp), %rcx # instructions count
    movq    40(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    16(%rsp) # consume command
    mov     %rax, %r10
    pop     %r9
    pop     %r8
    # add
    movq    8(%rsp), %rsi # instructions base
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r8
    movq    (%rsi, %rax), %r8
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r9
    movq    (%rsi, %rax), %rax
    add     %r8, %rax
    # write destination
    mov     %rax, %rdi # value
    movq    8(%rsp), %rsi # instructions base
    mov     %r10, %rdx # destination index
    jmp     .program_run_write_destination
.program_run_base:
   # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    mov     %rax, %r8
    movq    8(%rsp), %rsi # instructions base
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r8
    movq    (%rsi, %rax), %r8
    add     %r8, 24(%rsp)
    jmp     .program_run_loop
.program_run_input:
    # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    #
    movq    $NEG_INTEGER_SIZE, %rdx
    mul     %rdx
    movq    32(%rsp), %rbx # program input
    movq    %rbx, (%rsi, %rax)
    jmp     .program_run_loop
.program_run_mul:
    # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    push    %rax
    # second operand
    mov     %r10, %rdi # operand mode
    movq    16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # current instruction index
    mov     24(%rsp), %rcx # instructions count
    movq    32(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    8(%rsp) # consume command
    push    %rax
    # third operand
    mov     %r11, %rdi # operand mode
    movq    24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # current instruction index
    mov     32(%rsp), %rcx # instructions count
    movq    40(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    16(%rsp) # consume command
    mov     %rax, %r10
    pop     %r9
    pop     %r8
    #
    movq    8(%rsp), %rsi # instructions base
    movq    $NEG_INTEGER_SIZE, %rax
    mul     %r8
    movq    (%rsi, %rax), %r8
    movq    $NEG_INTEGER_SIZE, %rax
    mul     %r9
    movq    (%rsi, %rax), %rax
    mul     %r8
    # write destination
    mov     %rax, %rdi # value
    movq    8(%rsp), %rsi # instructions base
    mov     %r10, %rdx # destination index
    jmp     .program_run_write_destination
.program_run_print:
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    mov     $NEG_INTEGER_SIZE, %rdx
    mul     %rdx
    movq    (%rsi, %rax), %rdi
    call    number_print_u64
    jmp     .program_run_advance
.program_run_store_equ:
    # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    push    %rax
    # second operand
    mov     %r10, %rdi # operand mode
    movq    16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # current instruction index
    mov     24(%rsp), %rcx # instructions count
    movq    32(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    8(%rsp) # consume command
    push    %rax
    # third operand
    mov     %r11, %rdi # operand mode
    movq    24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # current instruction index
    mov     32(%rsp), %rcx # instructions count
    movq    40(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    16(%rsp) # consume command
    mov     %rax, %r10
    pop     %r9
    pop     %r8
    # compare
    movq    8(%rsp), %rsi # instructions base
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r8
    movq    (%rsi, %rax), %r8
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r9
    movq    (%rsi, %rax), %r9
    cmp     %r8, %r9
    je      .program_run_store_equ_1
    xor     %rdi, %rdi
    jmp     .program_run_store_equ_wrap_up
.program_run_store_equ_1:
    mov     $1, %rdi
.program_run_store_equ_wrap_up:
    # write destination
    movq    8(%rsp), %rsi # instructions base
    mov     %r10, %rdx # destination index
    jmp     .program_run_write_destination
.program_run_store_less:
    # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    push    %rax
    # second operand
    mov     %r10, %rdi # operand mode
    movq    16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # current instruction index
    mov     24(%rsp), %rcx # instructions count
    movq    32(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    8(%rsp) # consume command
    push    %rax
    # third operand
    mov     %r11, %rdi # operand mode
    movq    24(%rsp), %rsi # instructions base
    movq    16(%rsp), %rdx # current instruction index
    mov     32(%rsp), %rcx # instructions count
    movq    40(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    16(%rsp) # consume command
    mov     %rax, %r10
    pop     %r9
    pop     %r8
    # compare
    movq    8(%rsp), %rsi # instructions base
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r8
    movq    (%rsi, %rax), %r8
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r9
    movq    (%rsi, %rax), %r9
    cmp     %r9, %r8
    jl      .program_run_store_less_1
    xor     %rdi, %rdi
    jmp     .program_run_store_less_wrap_up
.program_run_store_less_1:
    mov     $1, %rdi
.program_run_store_less_wrap_up:
    # write destination
    movq    8(%rsp), %rsi # instructions base
    mov     %r10, %rdx # destination index
    jmp     .program_run_write_destination
.program_run_jnz:
    # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    push    %rax
    # second operand
    mov     %r10, %rdi # operand mode
    movq    16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # current instruction index
    mov     24(%rsp), %rcx # instructions count
    movq    32(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    8(%rsp) # consume command
    mov     %rax, %r9
    pop     %r8
    # compare
    movq    8(%rsp), %rsi # instructions base
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r8
    movq    (%rsi, %rax), %r8
    cmp     $0, %r8
    je      .program_run_loop
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r9
    movq    (%rsi, %rax), %r9
    movq    %r9, (%rsp)
    jmp     .program_run_loop
.program_run_jz:
    # first operand
    mov     %r9, %rdi # operand mode
    movq    8(%rsp), %rsi # instructions base
    movq    (%rsp), %rdx # current instruction index
    mov     16(%rsp), %rcx # instructions count
    movq    24(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    (%rsp) # consume command
    push    %rax
    # second operand
    mov     %r10, %rdi # operand mode
    movq    16(%rsp), %rsi # instructions base
    movq    8(%rsp), %rdx # current instruction index
    mov     24(%rsp), %rcx # instructions count
    movq    32(%rsp), %rbx # current relative base value
    call    program_operand_resolve_index
    incq    8(%rsp) # consume command
    mov     %rax, %r9
    pop     %r8
    # compare
    movq    8(%rsp), %rsi # instructions base
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r8
    movq    (%rsi, %rax), %r8
    cmp     $0, %r8
    jne     .program_run_loop
    mov     $NEG_INTEGER_SIZE, %rax
    mul     %r9
    movq    (%rsi, %rax), %r9
    movq    %r9, (%rsp)
    jmp     .program_run_loop
.program_run_write_destination:
    movq    $NEG_INTEGER_SIZE, %rax
    mul     %rdx
    movq    %rdi, (%rsi, %rax)
    jmp     .program_run_loop
.program_run_advance:
    #sub     %rdi, 8(%rsp)
    jmp     .program_run_loop
.program_run_wrap_up:
    mov     %rbp, %rsp
    pop     %rbp
    ret
.program_run_error:
    movq    $ERROR_PROGRAM_RUN, %rdi
    call    exit_ec
.program_run_destination_error:
    movq    $ERROR_PROGRAM_RUN_DESTINATION, %rdi
    call    exit_ec

program_operand_resolve_offset:
    ret

stack_s64:
    push    $-2 # neg index count -2, -2 to not get by number_read_s 'ret'
.stack_s64_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .stack_s64_wrap_up
    cmpb    $INTEGER_SEPARATOR, (%rdi)
    je      .stack_s64_char_consume
    call    number_read_s # must not use/touch the stack
    mov     %rax, %r8 # save extracted number
    mov     (%rsp), %rax
    mov     $INTEGER_SIZE, %rbx
    mul     %rbx
    movq    %r8, (%rsp,%rax)
    decq    (%rsp)
    jmp     .stack_s64_loop
.stack_s64_char_consume:
    incq    %rdi
    jmp     .stack_s64_loop
.stack_s64_wrap_up:
    pop     %rax
    add     $2, %rax # remove the 1 from the start
    neg     %rax # -> index count
    ret

program_challenge:
    push    %rbp
    mov     %rsp, %rbp
    push    %rsi # program input value
    call    stack_s64 # hoping that it fits
    pop     %r8
    sub     $40, %rsp # offset integers (ret values, push ...)
    mov     %rsp, %rdi # pointer to integers
    mov     %rax, %rsi # integers count
    # move rsp to end of integers list
    movq    $INTEGER_SIZE, %r9
    mul     %r9 # rax already has the integers count
    sub     %rax, %rsp
    # program requirement reserve more space and format the integers to 0more integer and format
    mov     $PROGRAM_ARRAY_MIN_SIZE, %r10
    sub     %rsi, %r10
    cmp     $0, %r10
    jle     .program_challenge_run
    # format
    xor     %rcx, %rcx
.program_challenge_format_one:
    movq    $INTEGER_SIZE, %rax
    neg     %rax
    mul     %rcx
    movq    $0, (%rsp, %rax)
    inc     %rcx
    cmp     %r10, %rcx
    jle     .program_challenge_format_one
    mov     $INTEGER_SIZE, %rax
    mul     %r10
    sub     %rax, %rsp
    mov     %rcx, %rsi
.program_challenge_run:
    mov     %r8, %rdx
    call    program_run
    mov     %rbp, %rsp
    pop     %rbp
    ret
.program_challenge_error:
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
    mov     %rax, %rsi
._start_challenge:
    mov     16(%rsp), %rdi
    call    program_challenge
    mov     $0, %rdi
    call    exit_ec
