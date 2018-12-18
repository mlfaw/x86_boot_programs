; Goal is/was a hex-editor though it's unfinished.
; You can type and backspace also works...

; nasm editor.asm
; then
; qemu-system-i386  -drive format=raw,file=editor
; or
; qemu-system-i386w -drive format=raw,file=editor

; 01234567890123456789012345678901234567890123456789012345678901234567890123456789
; 00 00|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00
; 00 10|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00
; 00 20|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00
; 00 30|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00
; 00 40|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00
; 00 50|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00
; 00 60|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00
; 00 70|  00 00 00 00   00 00 00 00    00 00 00 00   00 00 00 00

bits 16
org 0x7C00

; Our file is stored from 0x500 to 0x7BFF...
; This gives us 30463~ bytes to use which we'll round down to 30000
MAX_FILE_SIZE equ 30000
FILE_LOCATION equ 0x500

; BIOS scan codes:
SC_ENTER equ 0x1C
SC_BACKSPACE equ 0x0E
; Scan words...
SW_CTRL_S equ 0x1F13

start:
    ; Let's save this for later...
    mov BYTE [DiskNumber], dl
    call reset_screen

    ; We'll use es to address the text-graphics memory
    mov ax, 0xB800
    mov es, ax

    ; And ds to address our file's memory
    mov ax, FILE_LOCATION
    mov ds, ax

keyboard_loop:
    xor ax, ax ; AH=0 (KEYBOARD - GET KEYSTROKE)
    int 0x16 ; block until keystroke
    ; AH = BIOS scan code
    ; AL = ASCII character

    ; Scan-code handling
    cmp ah, SC_ENTER
    je keyboard_loop
    cmp ah, SC_BACKSPACE
    je backspace_handler

    ; skip zeroes
    test al, al
    jz keyboard_loop

    ; Write ASCII to memory:
    mov ah, 7 ; color
    mov bx, [VidMemOffset]
    mov WORD [es:bx], ax
    add bx, 2 ; select next character in memory
    mov [VidMemOffset], bx
    
    mov al, 1 ; al=1 to increase
    call cursor_change_handler
    jmp keyboard_loop


backspace_handler:
    mov bx, [VidMemOffset]
    test bx, bx
    jz keyboard_loop
    sub bx, 2
    mov [VidMemOffset], bx
    mov ax, 0x0720
    mov WORD [es:bx], ax
    
    xor al, al ; al=0 to decrease
    call cursor_change_handler
    jmp keyboard_loop


; clobbers registers
cursor_change_handler:
    cmp al, 1
    mov ax, [CursorOffset]
    je cursor_change_handler_inc
    call decrease_cursor
    jmp cursor_change_handler_exit
cursor_change_handler_inc:
    call increase_cursor
cursor_change_handler_exit:
    mov dx, ax
    mov [CursorOffset], ax
    mov ah, 2
    mov bh, 0
    int 0x10
    ret


; clobbers registers
increase_cursor:
    cmp al, 79
    je increase_cursor_ah
    inc al
    ret
increase_cursor_ah:
    cmp ah, 24
    je increase_cursor_hlt
    mov al, 0
    inc ah
    ret
increase_cursor_hlt:
    ret


; clobbers registers
decrease_cursor:
    test al, al
    jz decrease_cursor_ah
    dec al
    ret
decrease_cursor_ah:
    test ah, ah
    jz decrease_cursor_hlt
    mov al, 79
    dec ah
    ret
decrease_cursor_hlt:
    ret


reset_screen:
    mov ah, 2 ; VIDEO - SET CURSOR POSITION
    mov bh, 0 ; page number
    xor dx, dx ; row=0, column=0
    int 0x10
    ; FALL THROUGH to clear_screen
clear_screen:
    mov ax, 0x0600 ; ah=0x06 (scroll window up), al=0 (clear entire window)
    mov bh, 7 ; light-gray foreground w/ black background
    xor cx, cx ; row, column of windows upper left corner
    mov dx, 0x184F ; row=24, column=79
    int 0x10
    ret


DiskNumber db 0
VidMemOffset dw 0
CursorOffset dw 0

; Bootloader things:
times 510-($-$$) db 0
dw 0xAA55

;times (64 * 1024)-($-$$) db ' ' ; fill with spaces...
