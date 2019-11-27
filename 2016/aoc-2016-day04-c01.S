# https://adventofcode.com/2016/day/4
#
# Each room consists of an encrypted name (lowercase letters separated by dashes) followed by a dash, a sector ID, and a checksum in square brackets.
#
# A room is real (not a decoy) if the checksum is the five most common letters in the encrypted name, in order, with ties broken by alphabetization. For example:
#
#     aaaaa-bbb-z-y-x-123[abxyz] is a real room because the most common letters are a (5), b (3), and then a tie between x, y, and z, which are listed alphabetically.
#     a-b-c-d-e-f-g-h-987[abcde] is a real room because although the letters are all tied (1 of each), the first five are listed alphabetically.
#     not-a-real-room-404[oarel] is a real room.
#     totally-real-room-200[decoy] is not.
#
# Of the real rooms from the list above, the sum of their sector IDs is 1514.
#
# What is the sum of the sector IDs of the real rooms?

.equ SYS_WRITE, 4
.equ STDOUT, 1
.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_A, 'a'
.equ CHAR_Z, 'z'
.equ CHAR_DASH, '-'
.equ CHAR_NEWLINE, '\n'
.equ CHAR_SPACE, ' '
.equ CHAR_BRACKET_OPEN, '['
.equ CHAR_BRACKET_CLOSE, ']'
.equ CHECKSUM_LENGTH, 5

.bss
.lcomm num, 12 # buffer to hold number to print, 'write' syscall refuse a data stack pointer
.lcomm debug_buffer, 4096 # buffer to hold number to print, 'write' syscall refuse a data stack pointer

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

sector_id_scan:
    push    %rdi
    call    number_read_u
    pop     %rdi
    movq    %rax, 48(%rdi)
    ret

checksum_compute:
    lea     16(%rdi), %r10 # char to check pointer
    lea     56(%rdi), %r11 # checksum to write pointer
    mov     $-1, %rbx # char index
.checksum_compute_char_candidate:
    inc     %rbx
    cmp     $26, %rbx
    je      .checksum_compute_wrap_up
    mov     $-1, %rcx # checksum pos index
.checksum_compute_pos_try:
    inc     %rcx
    cmp     $5, %rcx
    je      .checksum_compute_char_candidate
    cmpb    $0, (%r11, %rcx)
    je      .checksum_compute_pos
    # retrieve current checksum char count
    movzb    (%r11, %rcx), %rax
    movzb   -1(%r10, %rax), %rax
    #
    cmpb    %al, (%r10, %rbx)
    jg      .checksum_compute_pos
    jmp     .checksum_compute_pos_try
.checksum_compute_pos:
    mov     $4, %r12
.checksum_compute_pos_set_shift_loop:
    cmp     %r12, %rcx
    je      .checksum_compute_pos_set
    movzb   -1(%r11, %r12), %rax
    mov     %al, (%r11, %r12)
    dec     %r12
    jmp     .checksum_compute_pos_set_shift_loop
.checksum_compute_pos_set:
    movb    %bl, (%r11, %rcx)
    incb    (%r11, %rcx)
    jmp     .checksum_compute_char_candidate
.checksum_compute_wrap_up:
    mov     $0, %rax
.checksum_compute_charify_loop:
    decb    (%r11, %rax)
    addb    $CHAR_A, (%r11, %rax)
    inc     %rax
    cmp     $5, %rax
    jne     .checksum_compute_charify_loop
    ret

checksum_verify:
    mov     $-1, %rax
    movq    (%rdi), %r10
    cmpb    $CHAR_BRACKET_OPEN, (%r10)
    jne     .checksum_verify_error
    inc     %r10
    lea     56(%rdi), %r11
    mov     $0, %r12
.checksum_verify_char_check:
    movzb   (%r10), %rbx
    cmpb    %bl, (%r11)
    jne     .checksum_verify_wrap_up
    incq    %r10
    incq    %r11
    incq    %r12
    cmp     $CHECKSUM_LENGTH, %r12
    jne     .checksum_verify_char_check
    cmpb    $CHAR_BRACKET_CLOSE, (%r10)
    jne     .checksum_verify_error
    mov     $0, %rax
.checksum_verify_wrap_up:
    addq    $2, (%rdi)
    addq    $CHECKSUM_LENGTH, (%rdi)
    ret
.checksum_verify_error:
    mov     $4, %rdi
    call    exit_unset
    ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $64, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movq    $0, 8(%rsp) # sum of the sector ids
.challenge_room_new:
    movq    $0, 16(%rsp) # a - h
    movq    $0, 24(%rsp) # i - p
    movq    $0, 32(%rsp) # q - x
    movq    $0, 40(%rsp) # y - z + 2b of padding
    movq    $0, 48(%rsp) # sector id read
    movq    $0, 56(%rsp) # computed checksum + 3b of padding
.challenge_line_new:
    # check eof
    mov     (%rsp), %rax
    movzb   (%rax), %rax
    cmp     $0, %rax
    je      .challenge_wrap_up
    # check new line
    cmp     $CHAR_NEWLINE, %rax
    je      .challenge_line_consume_new_line
.challenge_char_new:
    mov     (%rsp), %rax
    movzb   (%rax), %rax
    cmp     $0, %rax
    # check dash
    cmp     $CHAR_DASH, %rax
    je      .challenge_consume_char
    # check char
    cmp     $CHAR_A, %rax
    jl      .challenge_encrypted_name_end
    cmp     $CHAR_Z, %rax
    jg      .challenge_encrypted_name_end
    # increase char count
    sub     $CHAR_A, %rax
    incb    16(%rsp, %rax)
    incq    (%rsp) # consume char
    jmp     .challenge_char_new
.challenge_encrypted_name_end:
    # not a dash nor a char to count
    movq    %rsp, %rdi
    call    sector_id_scan
    movq    %rsp, %rdi
    call    checksum_compute
    movq    %rsp, %rdi
    call    checksum_verify
    cmp     $0, %rax
    jne     .challenge_room_new
    movq    48(%rsp), %rax
    add     %rax, 8(%rsp)
    jmp     .challenge_room_new
.challenge_consume_char:
    incq    (%rsp)
    jmp     .challenge_char_new
.challenge_line_consume_new_line:
    incq    (%rsp)
    jmp     .challenge_line_new
.challenge_wrap_up:
    movq    8(%rsp), %rdi
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
