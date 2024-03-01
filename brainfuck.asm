.model tiny


; constatnts 
MAX_SIZE EQU 10000

.data?
; uninitialized data
filename db 256d dup(?)
code db MAX_SIZE dup(?)

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

exit:
    ; exit instructions
    mov ax, 4C00h
    int 21h

end init
