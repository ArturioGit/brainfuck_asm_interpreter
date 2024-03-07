.model tiny


; constatnts 
MAX_SIZE EQU 10000
TAIL_LENGTH EQU 80h

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
    mov cl, [ds:TAIL_LENGTH]
    mov ch, 0
    dec cl
    lea di, filename 

copy_filename:
    ; read the argument byte by byte and write it into memory using movsb
    rep movsb
    

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
    mov cx, 1

interpret_loop PROC
    lodsb ; increment si each iteration and put value of ds:si into al. si is code pointer
    cmp al, 0
    je exit
    call interpret_command 
    jmp interpret_loop

    exit:
        ret

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
    cmp al, ']'
    je end_loop
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
        mov dx, di ; copy pointer on current cell
        int 21h
        ret

    get_value:
        mov ah, 03fh           ; DOS function to read from file or stdin
        mov bx, 0              ; Handle for stdin
        lea dx, [di]           ; Pointer to the current cell
        int 21h                ; Call DOS interrupt
        
        cmp byte ptr [di], 0Dh  ; Check for carriage return (CR)
        jne end_get_value
        mov byte ptr [di], 0FFFFh

        end_get_value:
            ret

    start_loop:
        cmp byte ptr [di], 0 ; if the cell = 0 at the beginning of the loop, it will not start
        jne exit_interpret_command_proc

        ; in case cell = 0, we have to skip all loop commands
        inc [nested_loops_value] ; loop nested value to find the corresponding end of the loop

        ; In the cycle, we look for the corresponding ']', when we find it, we finish
        ; the interpretation of the command '[', we have changed the pointer si. 
        ; And we will continue itrepretation from a new place

        find_end_bracket:
            cmp nested_loops_value, 0
            je exit_interpret_command_proc 
            lodsb
            cmp al, '['
            je inc_nested_value_start_loop
            cmp al, ']' 
            jne find_end_bracket
            
            dec nested_loops_value
            jmp find_end_bracket

            inc_nested_value_start_loop:
                inc nested_loops_value
                jmp find_end_bracket
            

    end_loop:
        cmp byte ptr [di], 0 ; if the cell = 0 at the beginning of the loop, it will not start
        je exit_interpret_command_proc

        inc [nested_loops_value] ; the same

        ; _ ] _ _
        ;     | - pointer si was here
        sub si, 2  
        ; _ ] _ _
        ; | - pointer si was here

        std   

        ; In the cycle, we look for the corresponding '[', when we find it, we finish
        ; the interpretation of the command ']', we have changed the pointer si. 
        ; And we will continue itrepretation from a new place    

        find_start_bracket:
            cmp nested_loops_value, 0
            je set_cld
            lodsb
            cmp al, ']'
            je inc_nested_value_end_loop
            cmp al, '[' 
            jne find_start_bracket

            dec nested_loops_value
            jmp find_start_bracket
        
            inc_nested_value_end_loop:
                inc nested_loops_value
                jmp find_start_bracket
            

    set_cld:
        ; _ _ [ _ 
        ;     | - pointer was here
        inc si
        ; _ _ [ _ 
        ;       | - pointer is here now
        cld
 
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