.model tiny

.code
org 100h

init:
    ; set the address of the es segment to work with it
    mov ax, cs 
    mov es, ax

    ; set the value of the register si to correctly read the value of the argument (file name)
    mov si, 82h
    lea di, file_name 
    cld

copy_file_name:
    ; read the argument byte by byte and write it into memory using movsb
    movsb
    mov al, byte [si]
    cmp al, ' '
    je open_file
    cmp al, 0
    je open_file
    jmp copy_file_name

open_file:
    ; just opening the file
    xor ax, ax
    lea dx, file_name
    mov ah, 03dh
    int 21h
    

read_file:
    ; call read file function 3fh, put the contents of the file into memory (code)
    mov bx, ax
    mov ah, 03fh
    mov cx, [max_size]
    mov dx, offset code
    int 21h

exit:
    ; exit instructions
    mov ax, 4C00h
    int 21h

.data
; initialized data
max_size dw 10000d

.data?
; uninitialized data
file_name db 256d dup(?)
code db 10000d dup(?)

end init
