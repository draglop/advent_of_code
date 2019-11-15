# https://adventofcode.com/2016/day/1
#
#The Document indicates that you should start at the given coordinates (where you just landed) and face North. Then, follow the provided sequence: either turn left (L) or right (R) 90 degrees, then walk forward the given number of blocks, ending at a new intersection.
#
#For example:
#
#    Following R2, L3 leaves you 2 blocks East and 3 blocks North, or 5 blocks away.
#    R2, R2, R2 leaves you 2 blocks due South of your starting position, which is 2 blocks away.
#    R5, L5, R5, R3 leaves you 12 blocks away.

# gcc -O0 -no-pie

.equ SYS_WRITE, 4
.equ STDOUT, 1
.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_L, 'L'
.equ CHAR_R, 'R'
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

string_number_len:
    mov     $0, %rax
.string_number_len_loop:
    cmpb    $CHAR_0, (%rdi)
    jl      .string_number_len_end
    cmpb    $CHAR_9, (%rdi)
    jg      .string_number_len_end
    incq    %rax
    incq    %rdi
    jmp     .string_number_len_loop
.string_number_len_end:
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

number_absolute_u32:
    movl    (%rdi), %eax
    cmpl    $0x00, %eax
    jge     .number_absolute_u32_end
    neg     %eax
    movl    %eax, (%rdi)
.number_absolute_u32_end:
    ret

number_print_u32:
    mov     $num, %r9 # buffer pointer
    movq    %rdi, %r10 # value to divide
    mov     $100000000, %r11 # dividend
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
    # remove one 0 from dividend
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

number_read_u32:
    push    %rdi
    mov     (%rdi), %rdi
    call    string_number_len
    pop     %rdi
    cmp     $0, %rax
    jle     .number_read_u32_exit
    mov     (%rdi), %r9 # pointer to number
    add     %rax, %r9
    dec     %r9
    mov     $0, %r10 # accumulator
    mov     $1, %r11 # multiplicator
    mov     %rax, %rcx
.number_read_u32_loop:
    movzb   (%r9), %rax
    sub     $CHAR_0, %rax
    mul     %r11
    add     %rax, %r10
    mov     $10, %rax
    mul     %r11
    mov     %rax, %r11
    add     $1, (%rdi)
    dec     %r9
    loop    .number_read_u32_loop
    mov     %r10, %rax
.number_read_u32_exit:
    ret

advance:
    push    %rdi
    call    number_read_u32
    pop     %rdi
    movl    8(%rdi), %ecx
    cmp     $0, %ecx
    je      .advance_n
    cmp     $1, %ecx
    je      .advance_e
    cmp     $2, %ecx
    je     .advance_s
    cmp     $3, %ecx
    je     .advance_w
    jmp     .advance_error
.advance_n:
    addl    %eax, 16(%rdi)
    jmp     .advance_wrap_up
.advance_e:
    addl    %eax, 12(%rdi)
    jmp     .advance_wrap_up
.advance_s:
    subl    %eax, 16(%rdi)
    jmp     .advance_wrap_up
.advance_w:
    subl    %eax, 12(%rdi)
    jmp     .advance_wrap_up
.advance_wrap_up:
    movl    %eax, %edi
    ret
.advance_error:
    mov     $2, %rdi
    call    exit_unset

direction_update:
    mov     (%rdi), %rax
    movzb   (%rax), %rcx
.direction_update_test_r:
    cmp     $CHAR_R, %rcx
    jne     .direction_update_test_l
    mov     $1, %eax
    jmp     .direction_update_value
.direction_update_test_l:
    cmp     $CHAR_L, %rcx
    jne     .direction_update_error
    mov     $-1, %eax
.direction_update_value:
    add     8(%rdi), %eax
    cmp     $4, %eax
    je      .direction_update_force_0
    cmp     $-1, %eax
    je      .direction_update_force_3
    jmp     .direction_update_update_pointed
.direction_update_force_0:
    mov     $0, %eax
    jmp     .direction_update_update_pointed
.direction_update_force_3:
    mov     $3, %eax
    jmp     .direction_update_update_pointed
.direction_update_update_pointed:
    movl    %eax, 8(%rdi)
    incq    (%rdi)
    ret
.direction_update_error:
    mov     $3, %rdi
    call    exit_unset

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $20, %rsp
    mov     %rdi, -20(%rbp) # buffer pointer
    movl    $0, -12(%rbp) # direction: 0 = N, 1 = E, 2 = S, 3 = W
    movl    $0, -8(%rbp) # x
    movl    $0, -4(%rbp) # y
.challenge_loop:
    lea     -20(%rbp), %rdi
    call    direction_update
    lea     -20(%rbp), %rdi
    call    advance
    # check eof
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $0x00, %rdi
    je      .challenge_wrap_up
    # check comma
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $CHAR_COMMA, %rdi
    jne     .challenge_loop
    incq    -20(%rbp) # consume comma
    # check eof
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $0x00, %rdi
    je      .challenge_wrap_up
    # check space
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $CHAR_SPACE, %rdi
    jne     .challenge_loop
    incq    -20(%rbp) # consume space
    # check eof
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $0x00, %rdi
    je      .challenge_wrap_up
    jmp     .challenge_loop
.challenge_wrap_up:
    lea     -8(%rbp), %rdi
    call    number_absolute_u32
    lea     -4(%rbp), %rdi
    call    number_absolute_u32
    movl   -8(%rbp), %edi
    movl   -4(%rbp), %eax
    addl    %eax, %edi
    call    number_print_u32
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
