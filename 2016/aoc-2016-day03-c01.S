# https://adventofcode.com/2016/day/3
#
# The design document gives the side lengths of each triangle it describes, but... 5 10 25? Some of these aren't triangles. You can't help but mark the impossible ones.
#
# In a valid triangle, the sum of any two sides must be larger than the remaining side. For example, the "triangle" given above is impossible, because 5 + 10 is not larger than 25.

# gcc -O0 -no-pie -Wall

.equ SYS_WRITE, 4
.equ STDOUT, 1
.equ CHAR_0, '0'
.equ CHAR_9, '9'
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

number_read_u:
    mov     $0, %rax # accumulator
    mov     $0, %r10 # number of digit read
    mov     $10, %r12 # multiplicator
.number_read_u_loop:
    mov     (%rdi), %rbx
    movzb   (%rbx), %rbx
    cmpb    $CHAR_0, %bl
    jl      .number_read_u_wrap_up
    cmpb    $CHAR_9, %bl
    jg      .number_read_u_wrap_up
    # shift previous number by one digit: x10
    mul     %r12
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
    mov     $1, %rdi
    call    exit_unset
    ret

spaces_consume:
.spaces_consume_loop:
    mov     (%rdi), %rax
    movzb   (%rax), %rax
    cmp     $CHAR_SPACE, %rax
    jne     .spaces_consume_wrap_up
    incq    (%rdi)
    jmp     .spaces_consume_loop
.spaces_consume_wrap_up:
    ret

triangle_check:
    # set max value to r10 and other two to r11 and r12
    cmp     %rdi, %rsi
    jg      .triangle_check_cmp1_rsi_bigger
    mov     %rdi, %r10
    mov     %rsi, %r11
    jmp     .triangle_check_cmp1_done
.triangle_check_cmp1_rsi_bigger:
    mov     %rsi, %r10
    mov     %rdi, %r11
.triangle_check_cmp1_done:
    cmp     %r10, %rdx
    jg      .triangle_check_cmp2_rdx_bigger
    mov     %rdx, %r12
    jmp     .triangle_check_fit_check
.triangle_check_cmp2_rdx_bigger:
    mov     %r10, %r12
    mov     %rdx, %r10
    # check that larger side is inferior to the sum of the other two
.triangle_check_fit_check:
    add     %r11, %r12
    cmp     %r10, %r12
    jg      .triangle_check_fit_ok
.triangle_check_fit_ko:
    mov     $0, %rax
    jmp     .triangle_check_wrap_up
.triangle_check_fit_ok:
    mov     $1, %rax
    jmp     .triangle_check_wrap_up
.triangle_check_wrap_up:
    ret

triangle:
    push    %rdi
    call    spaces_consume
    mov     (%rsp), %rdi
    call    number_read_u
    push    %rax
    mov     8(%rsp), %rdi
    call    spaces_consume
    mov     8(%rsp), %rdi
    call    number_read_u
    push    %rax
    mov     16(%rsp), %rdi
    call    spaces_consume
    mov     16(%rsp), %rdi
    call    number_read_u
    mov     %rax, %rdi
    pop     %rsi
    pop     %rdx
    call    triangle_check
    pop     %rdi
    cmp     $0, %rax
    je      .triangle_wrap_up
    incl    8(%rdi)
.triangle_wrap_up:
    ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $12, %rsp
    movq    %rdi, -12(%rbp) # buffer to read pointer
    movl    $0, -4(%rbp) # triangle count
.challenge_loop:
    # check eof
    mov     -12(%rbp), %rax
    movzb   (%rax), %rax
    cmp     $0x00, %rax
    je      .challenge_wrap_up
    # consume spaces
    mov     %rsp, %rdi
    call    spaces_consume
    # consume new line
    mov     -12(%rbp), %rax
    movzb   (%rax), %rax
    cmp     $CHAR_NEWLINE, %rax
    je      .challenge_consume_separator
    mov     %rsp, %rdi
    call    triangle
    jmp     .challenge_loop
.challenge_consume_separator:
    incq    -12(%rbp)
    jmp     .challenge_loop
.challenge_wrap_up:
    movl    -4(%rbp), %edi
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
