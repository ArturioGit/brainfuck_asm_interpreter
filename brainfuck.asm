.model tiny
.code
org 100h

init:
    mov ax, cs 
    mov es, ax
    mov si, 82h
    lea di, file_name 
    cld

copy_to_buffer:
    movsb
    mov al, byte [si]
    cmp al, ' '
    je open_file
    cmp al, 0
    je open_file
    jmp copy_to_buffer

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
    xor ax, ax
    mov ah, 02h          ; Function code for displaying a character
    mov dl, [code]       ; Load the character from memory into DL
    int 21h 

    mov ax, 4C00h
    int 21h

.data
max_size dw 10000d

.data?
file_name db 256d dup(?)
code db 10000d dup(?)

end init
