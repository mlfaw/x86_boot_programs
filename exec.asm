
; Executes typed in hexadecimal when ENTER is pressed.
; No error checking for input is used...
; example input: b8 24 0e bb 07 00 cd 10 f4

; nasm exec.asm
; qemu-system-i386w -drive format=raw,file=exec

bits 16

start:
    mov ax, 0x0200
    mov es, ax ; es:0 = 0x2000 now since segment:Address = segment*0x10+address
    xor si, si ; our offset

keyboard_loop:
    xor ax, ax ; ah = 0 (KEYBOARD - BLOCKING GET STROKE)
    int 0x16

    ; Check if ENTER
    cmp ah, 0x1C
    je execute_code

    ; Print character in AL
    mov ah, 0x0e
    int 0x10

    call character_to_hexadecimal
    shl al, 4
    mov bp, ax ; store digit in bp

    ; Get next digit
    xor ax, ax
    int 0x16

    ; Print character in AL
    mov ah, 0x0E
    int 0x10

    ; Store byte in memory
    call character_to_hexadecimal
    or ax, bp
    mov BYTE [es:si], al
    inc si

    ; Print two space characters
    mov ax, 0x0e20
    int 0x10
    int 0x10

    jmp keyboard_loop

; Here, we convert the character in al to a digit.
character_to_hexadecimal:
    cmp al, '9'
    jle character_is_number
    sub al, 'a'-10
    ret
character_is_number:
    sub al, '0'
    ret

execute_code:
    jmp 0:0x2000


times 510-($-$$) db 0
db 0x55
db 0xAA
