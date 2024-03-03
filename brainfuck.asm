.model tiny


; constatnts 
MAX_SIZE EQU 10000

.data?
; uninitialized data
filename db 256d dup(?)
code db MAX_SIZE dup(?)
cells db MAX_SIZE dup(?)

.data
nested_loops_value dw 0

.code
org 100h

init:
    ; set the address of the es segment to work with it
    mov ax, cs 
    mov es, ax

    ; set the value of the register si to correctly read the value of the argument (file name)
    mov si, 82h
    lea di, filename 
    cld

copy_filename:
    ; read the argument byte by byte and write it into memory using movsb
    movsb
    mov dl, byte [si]
    cmp dl, ' '
    je open_file
    cmp dl, 0
    je open_file
    jmp copy_filename

open_file:
    ; just opening the file
    mov ds, ax
    xor ax, ax
    lea dx, filename
    mov ah, 03dh
    int 21h
    

read_file:
    ; call read file function 3fh, put the contents of the file into memory (code)
    mov bx, ax
    mov ah, 03fh
    mov cx, MAX_SIZE
    mov dx, offset code
    int 21h

close_file:
    ; just closing file
    mov ah, 3Eh
    int 21h

loop_preparation:
    lea si, code 
    lea di, cells

interpret_loop PROC
    lodsb ; increment si each iteration and put value of ds:si into al. si is code pointer
    call interpret_command 
    cmp al, 0 ; condition to exit
    jne interpret_loop

    exit:
        ; exit instructions
        mov ax, 4C00h
        int 21h

interpret_loop ENDP

interpret_command PROC
    cmp al, '+'
    je increment_value
    cmp al, '-'
    je decrement_value
    cmp al, '>'
    je increment_pointer
    cmp al, '<'
    je decrement_pointer
    cmp al, '.'
    je print_value
    cmp al, ','
    je get_value
    ret

    increment_value:
        inc byte ptr [di]
        ret
    decrement_value:
        dec byte ptr [di]
        ret
    increment_pointer:
        inc di
        ret
    decrement_pointer:
        dec di
        ret
    print_value:
        mov ah, 2
        mov dl, [di]
        int 21h
        ret
    get_value:
        mov ah, 1
        int 21h
        mov [di], al
        ret

interpret_command ENDP 


end init
