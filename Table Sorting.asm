.model small
.stack 100h

.data
    max_rows        equ 50
    max_cols        equ 10
    max_strlen      equ 8
    column_names    db max_cols * max_strlen dup(0)
    column_types    db max_cols dup(0)
    table_data      db max_rows * max_cols * max_strlen dup(0)
    row_count       db 0
    col_count       db 0
    temp_buffer     db max_strlen dup(0)
    temp_num        dw 0
    sort_column     db 0
    msg_welcome     db 'student data management system', 13, 10, '$'
    msg_cols        db 'enter number of columns (1-10): $'
    msg_col_name    db 'enter column name: $'
    msg_col_type    db 'enter column type (s for string, n for numeric): $'
    msg_rows        db 'enter number of rows (1-50): $'
    msg_enter_data  db 'enter data for row $'
    msg_column      db ', column $'
    msg_colon       db ': $'
    msg_display     db 13, 10, 'current table:', 13, 10, '$'
    msg_sort_col    db 'enter column number to sort by (1-$'
    msg_sort_end    db '): $'
    msg_sorted      db 13, 10, 'sorted table:', 13, 10, '$'
    msg_newline     db 13, 10, '$'
    msg_space       db ' $'
    msg_tab         db 9, '$'
    msg_error       db 'error: invalid input!', 13, 10, '$'

.code
main proc
    mov ax, @data
    mov ds, ax
    lea dx, msg_welcome
    mov ah, 09h
    int 21h
    call get_column_count
    call get_column_definitions
    call get_row_count
    call get_table_data
    lea dx, msg_display
    mov ah, 09h
    int 21h
    call display_table
    call get_sort_column
    call sort_table
    lea dx, msg_sorted
    mov ah, 09h
    int 21h
    call display_table
    mov ah, 4ch
    int 21h
main endp

get_column_count proc
    lea dx, msg_cols
    mov ah, 09h
    int 21h
    call get_number
    cmp al, 1
    jl invalid_col_count
    cmp al, max_cols
    jg invalid_col_count
    mov col_count, al
    ret
invalid_col_count:
    lea dx, msg_error
    mov ah, 09h
    int 21h
    jmp get_column_count
get_column_count endp

get_column_definitions proc
    mov bl, 0
col_def_loop:
    mov al, col_count
    cmp bl, al
    jae col_def_done
    lea dx, msg_col_name
    mov ah, 09h
    int 21h
    mov al, bl
    mov ah, 0
    mov cl, max_strlen
    mul cl
    lea si, column_names
    add si, ax
    call get_string
get_col_type:
    lea dx, msg_col_type
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    mov dl, al
    push dx
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    pop dx
    lea si, column_types
    mov ah, 0
    mov al, bl
    add si, ax
    mov al, dl
    cmp al, 's'
    je store_string_type
    cmp al, 'n'
    je store_numeric_type
    lea dx, msg_error
    mov ah, 09h
    int 21h
    jmp get_col_type
store_string_type:
    mov byte ptr [si], 0
    jmp next_col
store_numeric_type:
    mov byte ptr [si], 1
next_col:
    inc bl
    jmp col_def_loop
col_def_done:
    ret
get_column_definitions endp

get_row_count proc
    lea dx, msg_rows
    mov ah, 09h
    int 21h
    call get_number
    cmp al, 1
    jl invalid_row_count
    cmp al, max_rows
    jg invalid_row_count
    mov row_count, al
    ret
invalid_row_count:
    lea dx, msg_error
    mov ah, 09h
    int 21h
    jmp get_row_count
get_row_count endp

get_table_data proc
    mov bl, 0
row_loop:
    mov al, row_count
    cmp bl, al
    jge data_done
    mov bh, 0
col_loop:
    mov al, col_count
    cmp bh, al
    jge next_row
    lea dx, msg_enter_data
    mov ah, 09h
    int 21h
    push bx
    mov al, bl
    inc al
    call print_number
    pop bx
    lea dx, msg_column
    mov ah, 09h
    int 21h
    push bx
    mov al, bh
    inc al
    call print_number
    pop bx
    lea dx, msg_colon
    mov ah, 09h
    int 21h
    mov al, bl
    mov ah, 0
    mov cl, col_count
    mul cl
    add al, bh
    mov ah, 0
    mov cl, max_strlen
    mul cl
    lea si, table_data
    add si, ax
    lea di, column_types
    mov al, bh
    mov ah, 0
    add di, ax
    mov al, [di]
    cmp al, 0
    je get_string_data
    call get_string
    jmp store_data
get_string_data:
    call get_string
store_data:
    inc bh
    jmp col_loop
next_row:
    inc bl
    jmp row_loop
data_done:
    ret
get_table_data endp

display_table proc
    mov bl, 0
header_loop:
    mov al, col_count
    cmp bl, al
    jae header_done
    mov al, bl
    mov ah, 0
    mov cl, max_strlen
    mul cl
    lea si, column_names
    add si, ax
    call print_string
    lea dx, msg_tab
    mov ah, 09h
    int 21h
    inc bl
    jmp header_loop
header_done:
    lea dx, msg_newline
    mov ah, 09h
    int 21h
    mov bl, 0
data_row_loop:
    mov al, row_count
    cmp bl, al
    jge display_done
    mov bh, 0
data_col_loop:
    mov al, col_count
    cmp bh, al
    jge next_data_row
    mov al, bl
    mov ah, 0
    mov cl, col_count
    mul cl
    add al, bh
    mov ah, 0
    mov cl, max_strlen
    mul cl
    lea si, table_data
    add si, ax
    call print_string
    lea dx, msg_tab
    mov ah, 09h
    int 21h
    inc bh
    jmp data_col_loop
next_data_row:
    lea dx, msg_newline
    mov ah, 09h
    int 21h
    inc bl
    jmp data_row_loop
display_done:
    ret
display_table endp

get_sort_column proc
    lea dx, msg_sort_col
    mov ah, 09h
    int 21h
    mov al, col_count
    call print_number
    lea dx, msg_sort_end
    mov ah, 09h
    int 21h
    call get_number
    cmp al, 1
    jl invalid_sort_col
    mov ah, 0
    mov bl, col_count
    cmp al, bl
    jg invalid_sort_col
    dec al
    mov sort_column, al
    ret
invalid_sort_col:
    lea dx, msg_error
    mov ah, 09h
    int 21h
    jmp get_sort_column
get_sort_column endp

sort_table proc
    mov bl, 0
outer_loop:
    mov al, row_count
    dec al
    cmp bl, al
    jge sort_done
    mov bh, 0
inner_loop:
    mov al, row_count
    sub al, bl
    dec al
    cmp bh, al
    jge next_outer
    push bx
    call compare_rows
    pop bx
    cmp al, 1
    jne no_swap
    push bx
    call swap_rows
    pop bx
no_swap:
    inc bh
    jmp inner_loop
next_outer:
    inc bl
    jmp outer_loop
sort_done:
    ret
sort_table endp

compare_rows proc
    mov al, bh
    mov ah, 0
    mov cl, col_count
    mul cl
    add al, sort_column
    mov ah, 0
    mov cl, max_strlen
    mul cl
    lea si, table_data
    add si, ax
    mov al, bh
    inc al
    mov ah, 0
    mov cl, col_count
    mul cl
    add al, sort_column
    mov ah, 0
    mov cl, max_strlen
    mul cl
    lea di, table_data
    add di, ax
    push si
    push di
    lea si, column_types
    mov al, sort_column
    mov ah, 0
    add si, ax
    mov al, [si]
    pop di
    pop si
    cmp al, 0
    je string_compare
    push si
    push di
    call string_to_number
    mov cx, ax
    mov si, di
    call string_to_number
    mov dx, ax
    pop di
    pop si
    cmp cx, dx
    jl need_swap
    jmp no_swap_needed
string_compare:
    call strcmp
    cmp al, 1
    je need_swap
    jmp no_swap_needed
need_swap:
    mov al, 1
    ret
no_swap_needed:
    mov al, 0
    ret
compare_rows endp

swap_rows proc
    mov cl, 0
swap_col_loop:
    mov al, col_count
    cmp cl, al
    jge swap_done
    mov al, bh
    mov ah, 0
    mov dl, col_count
    mul dl
    add al, cl
    mov ah, 0
    mov dl, max_strlen
    mul dl
    lea si, table_data
    add si, ax
    mov al, bh
    inc al
    mov ah, 0
    mov dl, col_count
    mul dl
    add al, cl
    mov ah, 0
    mov dl, max_strlen
    mul dl
    lea di, table_data
    add di, ax
    mov ch, max_strlen
swap_byte_loop:
    mov al, [si]
    mov ah, [di]
    mov [si], ah
    mov [di], al
    inc si
    inc di
    dec ch
    jnz swap_byte_loop
    inc cl
    jmp swap_col_loop
swap_done:
    ret
swap_rows endp

get_number proc
    mov bl, 0
get_digit_loop:
    mov ah, 01h
    int 21h
    cmp al, 13
    je input_done
    sub al, '0'
    cmp al, 9
    ja get_digit_loop
    mov ah, 0
    mov cl, al
    mov al, bl
    mov ah, 0
    mov dl, 10
    mul dl
    add al, cl
    mov bl, al
    jmp get_digit_loop
input_done:
    mov al, bl
    push ax
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    pop ax
    ret
get_number endp

get_character proc
    mov ah, 01h
    int 21h
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    ret
get_character endp

get_string proc
    push si
    mov cx, 0
get_char_loop:
    cmp cx, max_strlen - 1
    jge string_done
    mov ah, 01h
    int 21h
    cmp al, 13
    je string_done
    mov [si], al
    inc si
    inc cx
    jmp get_char_loop
string_done:
    mov byte ptr [si], 0
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    pop si
    ret
get_string endp

print_string proc
    push si
print_char_loop:
    mov al, [si]
    cmp al, 0
    je print_string_done
    mov dl, al
    mov ah, 02h
    int 21h
    inc si
    jmp print_char_loop
print_string_done:
    pop si
    ret
print_string endp

print_number proc
    mov ah, 0
    mov bl, 10
    div bl
    cmp al, 0
    je print_units
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
print_units:
    add ah, '0'
    mov dl, ah
    mov ah, 02h
    int 21h
    ret
print_number endp

print_number_debug proc
    push ax
    push bx
    push cx
    push dx
    mov cx, 0
    mov bx, 10
convert_loop:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne convert_loop
print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    dec cx
    jnz print_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number_debug endp

number_to_string proc
    mov ah, 0
    mov bl, 10
    div bl
    cmp al, 0
    je single_digit_str
    add al, '0'
    mov [si], al
    inc si
    add ah, '0'
    mov [si], ah
    inc si
    jmp null_term
single_digit_str:
    add ah, '0'
    mov [si], ah
    inc si
null_term:
    mov byte ptr [si], 0
    ret
number_to_string endp

string_to_number proc
    push si
    push bx
    push cx
    mov ax, 0
str_to_num_loop:
    mov bl, [si]
    cmp bl, 0
    je str_to_num_done
    cmp bl, ' '
    je str_to_num_done
    cmp bl, 9
    je str_to_num_done
    cmp bl, '0'
    jl str_to_num_done
    cmp bl, '9'
    jg str_to_num_done
    sub bl, '0'
    mov bh, 0
    mov cx, 10
    mul cx
    add ax, bx
    inc si
    jmp str_to_num_loop
str_to_num_done:
    pop cx
    pop bx
    pop si
    ret
string_to_number endp

strcmp proc
    push si
    push di
strcmp_loop:
    mov al, [si]
    mov ah, [di]
    cmp al, 0
    je first_end
    cmp ah, 0
    je second_end
    cmp al, ah
    jl first_less
    jg first_greater
    inc si
    inc di
    jmp strcmp_loop
first_end:
    cmp ah, 0
    je strings_equal
    jmp first_less
second_end:
    jmp first_greater
first_greater:
    mov al, 1
    jmp strcmp_done
first_less:
strings_equal:
    mov al, 0
strcmp_done:
    pop di
    pop si
    ret
strcmp endp

end main
