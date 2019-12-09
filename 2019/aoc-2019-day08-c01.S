# https://adventofcode.com/2019/day/8
#
# Images are sent as a series of digits that each represent the color of a single pixel. The digits fill each row of the image left-to-right, then move downward to the next row, filling rows top-to-bottom until every pixel of the image is filled.
#
# Each image actually consists of a series of identically-sized layers that are filled in this way. So, the first digit corresponds to the top-left pixel of the first layer, the second digit corresponds to the pixel to the right of that on the same layer, and so on until the last digit, which corresponds to the bottom-right pixel of the last layer.
#
# For example, given an image 3 pixels wide and 2 pixels tall, the image data 123456789012 corresponds to the following image layers:
#
# Layer 1: 123
#          456
#
# Layer 2: 789
#          012
#
# The image you received is 25 pixels wide and 6 pixels tall.
#
# To make sure the image wasn't corrupted during transmission, the Elves would like you to find the layer that contains the fewest 0 digits. On that layer, what is the number of 1 digits multiplied by the number of 2 digits?

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_1, '1'
.equ CHAR_2, '2'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_NEWLINE, '\n'

.equ IMAGE_WIDTH, 25
.equ IMAGE_HEIGHT, 6
.equ LAYERS_SIZE, IMAGE_WIDTH * IMAGE_HEIGHT

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

row_layers:
    mov     $0, %rax
    mov     $0, %rbx
    mov     $0, %rcx
    mov     $0, %r9
.row_layers_loop:
    cmp     $LAYERS_SIZE, %r9
    je      .row_layers_wrap_up
    movzb   (%rdi, %r9), %r10
    cmp     $CHAR_0, %r10
    jne     .row_layers_char_1
    inc     %rax
    jmp     .row_layers_next
.row_layers_char_1:
    cmp     $CHAR_1, %r10
    jne     .row_layers_char_2
    inc     %rbx
    jmp     .row_layers_next
.row_layers_char_2:
    cmp     $CHAR_2, %r10
    jne     .row_layers_next
    inc     %rcx
    jmp     .row_layers_next
.row_layers_next:
    inc     %r9
    jmp     .row_layers_loop
.row_layers_wrap_up:
    ret

challenge:
    push    %rbp
    mov     %rsp, %rbp
    sub     $32, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movq    $0xEFFFFFFFFFFFFFFF, %rax
    movq    %rax, 8(%rsp) # number of 0 for the layer that has the fewer number of 0
    movq    $0, 16(%rsp) # number of 1 for the layer that has the fewer number of 0
    movq    $0, 24(%rsp) # number of 2 for the layer that has the fewer number of 0
.challenge_layer_new:
    # check eof
    movq    (%rsp), %rdi
    movzb   (%rdi), %rax
    cmp     $CHAR_EOF, %rax
    je      .challenge_wrap_up
    # process layer
    call    row_layers
    cmp     %rax, 8(%rsp)
    jnae    .challenge_layer_next
    mov     %rax, 8(%rsp)
    mov     %rbx, 16(%rsp)
    mov     %rcx, 24(%rsp)
.challenge_layer_next:
    addq    $LAYERS_SIZE, (%rsp)
    jmp     .challenge_layer_new
.challenge_wrap_up:
    movq    16(%rsp), %rax
    movq    24(%rsp), %rbx
    mul     %rbx
    mov     %rax, %rdi
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
