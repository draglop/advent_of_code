# https://adventofcode.com/2019/day/8#part2
#
# Now you're ready to decode the image. The image is rendered by stacking the layers and aligning the pixels with the same positions in each layer. The digits indicate the color of the corresponding pixel: 0 is black, 1 is white, and 2 is transparent.
#
# The layers are rendered with the first layer in front and the last layer in back. So, if a given position has a transparent pixel in the first and second layers, a black pixel in the third layer, and a white pixel in the fourth layer, the final image would have a black pixel at that position.
#
# For example, given an image 2 pixels wide and 2 pixels tall, the image data 0222112222120000 corresponds to the following image layers:
#
# Layer 1: 02
#          22
#
# Layer 2: 11
#          22
#
# Layer 3: 22
#          12
#
# Layer 4: 00
#          00
#
# Then, the full image can be found by determining the top visible pixel in each position:
#
#   - The top-left pixel is black because the top layer is 0.
#   - The top-right pixel is white because the top layer is 2 (transparent), but the second layer is 1.
#   - The bottom-left pixel is white because the top two layers are 2, but the third layer is 1.
#   - The bottom-right pixel is black because the only visible pixel in that position is 0 (from layer 4).
#
# So, the final image looks like this:
#
# 01
# 10
#
# What message is produced after decoding your image?

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_1, '1'
.equ CHAR_2, '2'
.equ CHAR_EOF, 0
.equ CHAR_NEWLINE, '\n'
.equ CHAR_CR, '\r'

.equ IMAGE_WIDTH, 25
.equ IMAGE_HEIGHT, 6
.equ LAYERS_SIZE, IMAGE_WIDTH * IMAGE_HEIGHT
.equ PIXEL_BLACK_OUTPUT, '#'
.equ PIXEL_WHITE_OUTPUT, ' '

.bss
.lcomm layer_buffer, LAYERS_SIZE
.lcomm line_buffer, IMAGE_WIDTH + 3 # line buffer

.text

exit_ec:
    mov     %rdi, %rbx
    movl    $1, %eax
    int     $0x80

exit_error:
    mov     $-1, %rdi
    call    exit_ec

helper_cpy:
    mov $0, %rax
.helper_cpy_loop:
    cmp     %rax, %rdx
    je      .helper_cpy_wrap_up
    movzb   (%rdi, %rax), %rbx
    mov     %bl, (%rsi, %rax)
    inc     %rax
    jmp     .helper_cpy_loop
.helper_cpy_wrap_up:
    ret

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

layer_append:
    mov     $layer_buffer, %rax
    mov     $0, %rbx
.layer_append_loop:
    cmp     $LAYERS_SIZE, %rbx
    je      .layer_append_wrap_up
    movb    (%rax, %rbx), %cl
    cmpb    $CHAR_2, %cl
    jne     .layer_append_next
    movb    (%rdi, %rbx), %cl
    movb    %cl, (%rax, %rbx)
.layer_append_next:
    inc     %rbx
    jmp     .layer_append_loop
.layer_append_wrap_up:
    ret

message_format:
    mov     $layer_buffer, %rdi
    mov     $0, %rax
.message_format_loop:
    cmp     $LAYERS_SIZE, %rax
    je      .message_format_wrap_up
    movzb   (%rdi, %rax), %rdx
    cmp     $CHAR_0, %rdx
    movb    $PIXEL_WHITE_OUTPUT, (%rdi, %rax)
    jne     .message_format_char_1
    jmp     .message_format_char_next
.message_format_char_1:
    movb    $PIXEL_BLACK_OUTPUT, (%rdi, %rax)
.message_format_char_next:
    inc     %rax
    jmp     .message_format_loop
.message_format_wrap_up:
    ret

message_print:
    push    %rbp
    mov     %rsp, %rbp
    sub     $8, %rsp
    movq    $0, (%rsp)
    call    message_format
    mov     $line_buffer, %rax
    add     $IMAGE_WIDTH, %rax
    movb    $CHAR_NEWLINE, (%rax)
    movb    $CHAR_EOF, 1(%rax)
.message_print_line_loop:
    mov     $layer_buffer, %rdi
    addq    (%rsp), %rdi
    cmpb    $CHAR_EOF, (%rdi)
    je      .message_print_wrap_up
    mov     $line_buffer, %rsi
    mov     $IMAGE_WIDTH, %rdx
    call    helper_cpy
    mov     $line_buffer, %rdi
    call    stdout
    addq    $IMAGE_WIDTH, (%rsp)
    jmp     .message_print_line_loop
.message_print_wrap_up:
    mov     %rbp, %rsp
    pop     %rbp
    ret

challenge:
    push    %rbp
    mov     %rsp, %rbp
    sub     $32, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movq    (%rsp), %rdi
    movq    $layer_buffer, %rsi
    movq    $LAYERS_SIZE, %rdx
    call    helper_cpy
    addq    $LAYERS_SIZE, (%rsp)
.challenge_layer_new:
    # check eof
    movq    (%rsp), %rdi
    movzb   (%rdi), %rax
    cmp     $CHAR_EOF, %rax
    je      .challenge_wrap_up
    # process layer
    call    layer_append
    addq    $LAYERS_SIZE, (%rsp)
    jmp     .challenge_layer_new
.challenge_wrap_up:
    call    message_print
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
