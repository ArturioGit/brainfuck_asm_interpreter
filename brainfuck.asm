.model tiny


; constatnts 
MAX_SIZE EQU 10000

.data?
; uninitialized data
filename db 256d dup(?)
code db MAX_SIZE dup(?)
cells dw MAX_SIZE dup(?)

.data
nested_loops_value dw 0

.code
org 100h

init:
    ; set the address of the es segment to work with it
    mov ax, cs 
    mov es, ax

    ; set all bytes we will use to zero
    lea di, filename
    xor ax, ax
    mov cx, 30256
    cld
    rep stosb
    mov ax, cs 

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
    cmp al, '['
    je start_loop
    ret

    increment_value:
        inc word ptr [di]
        ret

    decrement_value:
        dec word ptr [di]
        ret

    increment_pointer:
        add di, 2
        ret

    decrement_pointer:
        sub di, 2
        ret

    print_value:
        mov ah, 40h ; to write in file (handle)
        mov bx, 1 ; stdout
        mov cx, 1 ; number of bytes to write
        mov dx, di ; copy pointer on current cell
        int 21h
        ret

    get_value:
        mov ah, 03fh ; to read from file
        mov bx, 0 ; stdin
        mov cx, 1 ; number of bytes to read
        mov dx, di ; copy pointer on current cell
        int 21h
        ret

    start_loop:
        cmp byte ptr [di], 0 ; if the cell = 0 at the beginning of the loop, it will not start
        jne exit_interpret_command_proc

        ; in case cell = 0, we have to skip all loop commands
        mov [nested_loops_value], 1; loop nested value to find the corresponding end of the loop

        ; In the cycle, we look for the corresponding ']', when we find it, we finish
        ; the interpretation of the command '[', we have changed the pointer si. 
        ; And we will continue itrepretation from a new place

        find_inner_brackets:
            cmp nested_loops_value, 0
            je exit_interpret_command_proc 
            lodsb
            cmp al, '['
            je inc_nested_value
            cmp al, ']' 
            je dec_nested_value

            jmp find_inner_brackets

            ; I am writing a comment, because it is definitely possible to optimize here

            inc_nested_value:
                inc nested_loops_value
                jmp find_inner_brackets
            
            dec_nested_value:
                dec nested_loops_value
                jmp find_inner_brackets
            
    exit_interpret_command_proc:
        ret    

interpret_command ENDP 


end init

; --------------------------------------------------------
; My loops work based on this algorithm in Java          
;
;               case '[':
;                   if (tape[pointer] == 0) {
;                        loop = 1;
;                        while (loop > 0) {
;                            i++;
;                            char c = code.charAt(i);
;                            if (c == '[') loop++;
;                            else if (c == ']') loop--;
;                        }
;                    }
;                    break;
;
;                case ']':
;                    if (tape[pointer] != 0) {
;                        loop = 1;
;                        while (loop > 0) {
;                            i--;
;                            char c = code.charAt(i);
;                            if (c == '[') loop--;
;                            else if (c == ']') loop++;
;                        }
;                    }
;                    break;
;
; --------------------------------------------------------