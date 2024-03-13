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
    mov bx, cs 
    mov es, bx
    ; set all bytes we will use to zero
    lea di, filename
    xor ax, ax
    mov cx, 30256
    cld
    rep stosb

copy_filename:
    ; set the value of the register si to correctly read the value of the argument (file name)
    mov si, 82h
    mov cl, [ds:TAIL_LENGTH]
    mov ch, 0
    dec cl
    lea di, filename 
    ; read the argument byte by byte and write it into memory using movsb
    rep movsb
    
open_file:
    ; just opening the file
    mov ds, bx
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

interpret_loop:
    lodsb ; increment si each iteration and put value of ds:si into al. si is code pointer
    cmp al, 0
    jne interpret_command 
    exit:
        ret

interpret_command:
    increment_value:
        cmp al, '+'
        jne decrement_value
            inc word ptr [di]
            
    decrement_value:
        cmp al, '-'
        jne increment_pointer
            dec word ptr [di]

    increment_pointer:
        cmp al, '>'
        jne decrement_pointer
            add di, 2  

    decrement_pointer:
        cmp al, '<'
        jne start_loop
            sub di, 2

    start_loop:
        cmp al, '['
        jne end_loop
            push si
            cmp byte ptr [di], 0 ; if the cell = 0 at the beginning of the loop, it will not start
            je inc_nested_value_start_loop
            
            jmp interpret_loop

            ; in case cell = 0, we have to skip all loop commands
            ; In the cycle, we look for the corresponding ']', when we find it, we finish
            ; the interpretation of the command '[', we have changed the pointer si. 
            ; And we will continue itrepretation from a new place

            find_end_bracket:
                cmp nested_loops_value, 0
                je end_loop
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
        cmp al, ']'
        jne print_value
            cmp byte ptr [di], 0 ; if the cell = 0 at the end of the loop, it will not start again
            je end_loop_di_0
            pop si
            push si
            jmp print_value
            end_loop_di_0:
                add sp, 2

    print_value:
        cmp al, '.'
        jne check_input_command
            mov ah, 02h 
            cmp byte ptr [di], 0Ah
            jne continue_print_value
                mov dl, 0Dh
                int 21h
            continue_print_value:
                mov dl, byte ptr [di]
                int 21h
                jmp interpret_loop

    check_input_command:
        cmp al, ','
        jne end_get_value

    get_value:
        mov ah, 03fh ; DOS function to read from file or stdin
        xor bx, bx ; Handle for stdin
        mov dx, di ; Pointer to the current cell
        int 21h ; Call DOS interrupt
            
        or ax, ax  
        jnz check_for_ODh
        mov word ptr [di], 0FFFFh

        check_for_ODh:
            cmp byte ptr [di], 0dh
            je get_value

        end_get_value:
            jmp interpret_loop
    
end init