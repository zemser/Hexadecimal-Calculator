;macros:
    %macro initalize_num 0   
        xor eax,eax   ;go through all 81 bytes of [num] and put 0 in them
        mov eax,81  
        %%begin_initalize_num_loop:
        cmp eax,0     
        je %%finish_num_initalize
        dec eax
        mov byte [num+eax],0
        jmp %%begin_initalize_num_loop
        %%finish_num_initalize:
    %endmacro

    %macro convert_ascii_to_dec 1
        mov bl,0x3A
        xor ecx,ecx
        mov cl,%1       
        mov dl,cl
        sub dl,bl       ;check if the byte is smaller than 10
        jl %%is_num
        mov bl,0x5B
        mov dl,cl
        sub dl,bl
        jl %%is_capital
            sub cl,87   ;convert to decimal 10-15
            jmp %%end1
        %%is_capital:
            sub cl,55   ;convert to decimal 10-15
            jmp %%end1
        %%is_num:
            sub cl,48   ;convert to decimal 
        %%end1:
    %endmacro

    %macro convert_dec_to_ascii 1
        mov ecx,%1
        mov dl,cl
        sub dl,10
        jl %%was_num
            add cl,55
            jmp %%end2
        %%was_num:
            add cl,48
        %%end2:
    %endmacro

    %macro free_list 2
        mov ebx,%1      ;link to the head of the list
        mov ecx,%2      ;list to the tail of the list(default 0)
        mov [last_link_to_free],ecx
        cmp ebx,[last_link_to_free]
        je %%one_link
        %%free_loop:
            cmp ebx,[last_link_to_free]
            je %%finish
            mov edx,ebx     ;save in edx the link to free
            inc ebx         ;point ebx to the next link
            mov ebx,[ebx]
            mov [link_to_free],ebx  ;save the next link in link_to_free
            push edx
            call free
            add esp,4
            mov ebx,[link_to_free]      ;restore the next link to ebx
            jmp %%free_loop

        %%one_link:
            push ebx
            call free
            add esp ,4
        %%finish:
    %endmacro


    %macro print_debug  1
        mov eax,%1   ;eax hold pointer to the start of the list
        mov [ptempStruct],eax  ;move the pointer to the list to ptempStruct
        %%print_debug_loop:cmp dword [ptempStruct],0
        je %%end_print_debug
        xor edx,edx
        mov ebx,[ptempStruct]
        mov byte dl,[ebx]  ;the hexa to print
        convert_ascii_to_dec dl
        push ecx        
        push format_hexa_no_line
        call printf 
        add esp,8
        mov eax,[ptempStruct]      ;mov to eax the pointer
        inc eax                     
        mov eax,[eax]               ;put in eax the next pointer
        mov [ptempStruct],eax       ;save the next pointer in ptempStruct
        jmp %%print_debug_loop
        %%end_print_debug:
            push format_newLine
            call printf  ;print \n
            add esp,4

    %endmacro


    %macro funcPrep 0
        push ebp        ;setup stack frame
        mov ebp, esp
    %endmacro

     %macro funcAfter 0		
        mov esp, ebp	
        pop ebp
        ret
    %endmacro

section	.data	
    format_string: db "%s", 10, 0	; format string
    format_string_n0_newLine: db "%s", 0	; format string
    format_hexa: db "%X",10, 0	; format hexa
    format_hexa_no_line: db "%X", 0	; format hexa with no new line
    format_int: db "%d", 0	; format string
    format_newLine: db "",10,0
    msg1: db 'Calc: ',0
    err1: db 'Error: Operand Stack Overflow',10,0
    err2: db 'Error: Insufficient Number of Arguments on Stack',10,0
    err3: db 'wrong Y value',10,0
    lenerr1: equ 30  ;$-err1
    lenerr2: equ 49   ;$-err2
    lenerr3: equ 14  ;$-err3
    len1: equ  6  ;$-msg1   
    sr: db "sr"
    deb: db "-d"
    funcounter: dd 0
    stackCounter: dd 0
    stack_size equ 5
    stackOperand: times stack_size DD 0  ;the opernd stack
    handlepCounter: dd 0
    struct: times 40 db 0
    carryflag: db 0 
    
    
    SYS_READ equ 3  
    STDIN     equ 0
    

section .bss   
    debug:resd 1
    num: resb 81     ;the input from the user
    phandleNum: resd 1 
    bytesRecived: resd 1
    count_leading_zeros: resd 1
    pStruct: resd 1   ;pointer to the struct
    ptempStruct: resd 1  ;temp pointer to the struct
    pfirst: resd 1
    phandle: resb 1
    reservePointerinP: resd 1
    link_to_free: resd 1        ;for freeing marco
    last_link_to_free: resd 1   ;for freeing marco
    ;for plus function
    first_link: resd 1
    second_link: resd 1
    tmp_first_link: resd 1
    tmp_second_link: resd 1
    first_num: resd 1
    second_num: resd 1
    plusic: resd 1
    ;for n fucntion
    n_counter: resd 1
    retval: resd 1
    remainder: resd 1
    ;for x*y^2 fucntion
    power: resd 1  ;for y
    power_carry_flag: resd 1
    ;for the x*y^(-2)
    reversed_list: resd 1  ;for the pointer to the reversed list
    tmp_reversed_link: resd 1
    





section .text
    align 16
     global main 
     extern printf 
     extern fprintf 
     extern fflush
     extern malloc 
     extern calloc 
     extern free 
     ;extern gets 
     extern fgets 

main:  
    funcPrep
    pushad
    mov eax,[ebp+8]     ;the first argument- argc
    mov dword [debug],0     ;initialize debug flag
    cmp eax,1    ;check if argc is 1- no debug argument was given
    je no_debug
    mov dword ebx,[ebp+12]  ;the second argument - argv
    mov ecx, [ebx+4]
    cmp word [ecx],"-d"
    jne no_debug
    found_debug: ;in case we got "-d"
        mov dword [debug],1
    
    no_debug:

    call myCalc

    push eax
    push format_hexa
    call printf
    add esp,8

    popad
    funcAfter

count_1s:
        funcPrep
        sub esp,4 ;for the returned value
        pushad	  ;preserve ebx-c calling convention
        
        xor eax,eax
        mov al,[ebp+8]     ; in al is the hexa (we want to count its the 1's)
        xor ebx,ebx  ;we want to use ebx to count the 1's
        shl al,4   ; we want only the 4 lsb bits
        xor esi,esi
        count_1s_loop: cmp esi,4
        je ones_end
        shl al,1
        jnc no_c
        inc ebx
        no_c:
        inc esi
        jmp count_1s_loop
        ones_end: 
      
        mov [retval],ebx   ;transfer returned value
        popad
        mov eax,[retval]  ;put returned value in eax
        funcAfter

list_to_y:
        funcPrep
        sub esp,4 ;for the returned value
        pushad	  ;preserve ebx-c calling convention

        xor eax,eax
        mov dword [power],eax       ;initalize the power
        mov dword [n_counter],eax    ;initalize the counter
        mov eax,[ebp+8]     ; in eax is the pointer to the start of the link
        list_to_y_loop: cmp byte [n_counter],2     ;check if y is more than 2 links, if so the num is greater than 200 -jump to err_h
            je err_h
            xor edx,edx
            mov byte dl,[eax]      ;save the num in the pointer in eax 
            convert_ascii_to_dec dl
            mov dl,cl  
            cmp byte[n_counter],0
            jne second_iter
            mov dword [power],edx
            jmp y_loop
            second_iter:
                shl dl,4      ;multiply the second hexa(that is converted to dec) by 16
                add dl,[power] ;add it to the first hexa
                mov [power],dl
            y_loop:
                inc eax
                mov eax,[eax]
                inc byte [n_counter]    ;update counte
                cmp dword eax,0     ;check if we got to the last link 
                je no_err
                jmp list_to_y_loop
                
                
        err_h:
            mov dword [power],0xC9    ;move to power the hex value of 201
        no_err:
        popad
        mov dword eax,[power]  ;put returned value in eax
        funcAfter

reverse_list:
        funcPrep
        sub esp,4 ;for the returned value
        pushad	  ;preserve ebx-c calling convention
        xor eax,eax
        mov dword [n_counter],eax    ;initalize the counter of the list size
        mov eax,[ebp+8]     ; in eax is the pointer to the start of the link
        ;go through the orignal list and count how many items + push the nums on the stack
        push_loop:
            cmp eax,0   ;check if we got to the end of the list
            je pop_proc
            xor edx,edx
            mov byte dl,[eax]  ;put in edx the num in the curr link
            push edx 
            inc byte [n_counter]   ;increase the counter of nums we pushed on stack
            inc eax
            mov eax,[eax]
            jmp push_loop

        pop_proc:
            mov eax,1   ;argument 2 for calloc
            mov ebx,5    ;argument 1 for calloc
            push eax
            push ebx
            call calloc
            add esp,8
            mov [tmp_first_link],eax        ;save the first link of the new list
            jmp first_pop
            pop_loop:
                cmp byte [n_counter],0          ;check if we poped all the numbers
                je reverse_list_end
                mov eax,1   ;argument 2 for calloc
                mov ebx,5    ;argument 1 for calloc
                push eax
                push ebx
                call calloc
                add esp,8
                mov ebx,[tmp_reversed_link]  ;now ebx has the prev pointer
                mov [ebx],eax           ;point the prev pointer to the new link
            first_pop:
                xor ebx,ebx
                pop ebx                 ;get the next number from the stack
                mov [eax],ebx           ;put the number in the link
                inc eax
                mov [tmp_reversed_link],eax   ;save pointer to the next link
                dec byte [n_counter]
                jmp pop_loop


        reverse_list_end:
            popad
            mov dword eax,[tmp_first_link]  ;put returned value in eax
            funcAfter


 myCalc:
    funcPrep
    pushad
    
    loop:
    initalize_num 
    mov eax,4            ; 'write' system call
    mov ebx,1            ; file descriptor 1 = screen
    mov ecx,msg1        ; string to write
    mov edx,6     ; length of string to write
    int 0x80              ; call the kernel
    
    mov eax, SYS_READ ;get input from user
    mov ebx, STDIN
    mov ecx, num
    mov edx, 81
    int 0x80
    x:mov [bytesRecived],eax   ;how many bytes were recieved from input
    dec byte [bytesRecived]  ;dec for the enter
    jmp checkInput
    
    end:     ;jumps after recieving q 
    cmp byte [stackCounter],0
    je Finito
    dec byte [stackCounter]
    mov eax,[stackCounter]
    mov dword ebx,[stackOperand+4*eax]  ;in ebx is the pointer to the first link
    mov [link_to_free],ebx
    xor esi,esi             ;to create the link "0"
    free_list [link_to_free],esi
    jmp end
    Finito:
        popad
        mov eax,[funcounter]
        funcAfter

handle_oprend:
    jmp err_insufficient

;****************************************************************************************************************************************
handle_num:
    ;reading the first num
    continue_handle_num: 
    mov eax,1   ;argument 2 for calloc
    mov ebx,5    ;argument 1 for calloc
    push eax
    push ebx
    call calloc
    add esp,8
    mov dword [pfirst], eax  ;save the pointer to the first link in pfirst
    mov ecx,[pfirst]
    mov [ptempStruct],ecx   ;copy to ptemp the pointer to the first link
    dec byte [bytesRecived] 
    mov esi,[bytesRecived]  ;move the  esi to point for how many numbers we have left
    mov  dl,[num+esi]
    mov ebx,[ptempStruct]
    mov [ebx],dl            ;put in the first byte of the struct - the number 
    
    ;count leading zeros
    xor esi,esi  
    leading_zeros:cmp byte [num+esi],48
    jne before_read_num
    inc byte [count_leading_zeros]
    inc esi
    jmp leading_zeros
    
    before_read_num:
        mov eax,[bytesRecived]
        sub eax,[count_leading_zeros]
        jl numover; for case the input was only zeros
        mov [count_leading_zeros],eax  ;[count_leading_zeros] holds the sub between how many bytes in total and the sum of the leading zeros

    read_num:
    cmp byte [count_leading_zeros],0   ;loop for reading the rest of the numbers 
    je numover  ;maybe jump to loop instead
    mov eax,1   ;argument 2 for calloc
    mov ebx,5    ;argument 1 for calloc
    push eax
    push ebx
    call calloc
    add esp,8
    mov dword [pStruct], eax   ;store the address of calloc in the pointerq
    mov ecx,[ptempStruct]  ;put in ecx the pointer to the previous struct
    inc ecx            ;increase the pointer by one to point the the 4 last bytes in the struct
    mov [ecx],eax        ;put in the address of the prev pointer the address of the new calloc
    dec byte [bytesRecived] 
    dec byte [count_leading_zeros]       
    mov esi,[bytesRecived]  ;move the  esi to point for how many numbers we have left
    mov dl,[num+esi]     ; move the next num to dl

    mov ebx,[pStruct]   ;move the pointer to the curr struct to ebx
    mov [ebx],dl        ;move the num to the first byte in the cur struct

    mov ecx,[pStruct]    
    mov [ptempStruct],ecx   ;save the pstruct in temp struct
    jmp read_num

    numover: 
    mov edx,[stackCounter]
    mov ebx, [pfirst]
    mov dword [stackOperand+4*edx],ebx
    inc byte [stackCounter]
    mov dword [count_leading_zeros],0

    ; check debug mode 
    cmp byte [debug],1          
    jne loop     
    push ebx
    call reverse_list
    add esp,4
    d:mov [pfirst],eax  ;now pfirst has the pointer to the reversed list
    print_debug [pfirst]   ;print for debug
    xor esi,esi
    dd:free_list [pfirst],esi ;free the reversed list
    jmp loop

;****************************************************************************
handle_p:
    inc byte[funcounter]   ;increase the functions counter
    mov dword [handlepCounter],0    ;initialize handlepCounter(number of pushed numbers) to 0
    cmp byte [stackCounter],0
    je err_insufficient
    dec byte [stackCounter]
    mov eax,[stackCounter]
    mov dword ebx,[stackOperand+4*eax]  ;in ebx is the pointer to the struct
    mov [link_to_free],ebx    ;save first link (for free marco in p_end)
    p_loop:
    cmp dword ebx,0
    je p_end
    mov edx,[ebx]  ;put in edx the number that is pointed by ebx
    push edx   ;push the number
    inc byte [handlepCounter]  ;update the stack counter of nums we pushed
    inc ebx
    mov ebx,[ebx]
    jmp p_loop

    p_end:
        xor esi,esi             ;to create the link "0"
        free_list [link_to_free],esi
        mov esi,0
        p2_loop:cmp byte [handlepCounter],1  ;check if we poped all the numbers we put
            je p_finish
            pop ebx
            mov [phandleNum],bl    ;put the next byte to print in [phandleNum]
            push phandleNum
            call printf
            add esp,4
            dec byte [handlepCounter]
            jmp p2_loop

    p_finish: ;print the number
        pop ebx
        mov [phandleNum],bl  ;put the next byte to print in [phandleNum]
        push phandleNum
        push format_string
        call printf
        add esp, 8
        jmp loop
     
;**************************************************************************
handle_plus:
    inc byte[funcounter]   ;increase the functions counter
    ;save pointers to 2 top numbers and remove from the stack
    mov eax,[stackCounter]
    mov ebx,2
    sub eax,ebx
    jl err_insufficient     ;jump if there are less than 2 numbers in the stack
    dec byte [stackCounter]
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax]
    mov [first_link],ebx         
    mov [tmp_first_link],ebx     ;save so we can free the first link in the end
    xor edx,edx
    mov dword [stackOperand+4*eax],edx ;put zeros in the stack where we removed the number
    dec byte [stackCounter]
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax]
    mov [second_link],ebx         
    mov [tmp_second_link],ebx            ;save so we can free the first link in the end
    mov dword [stackOperand+4*eax],edx  ;put zeros in the stack where we removed the number

    mov byte [carryflag],0           ;initialize carry flag to 0
    ;create the new link of the sum
    mov eax,1   ;argument 2 for calloc
    mov ebx,5    ;argument 1 for calloc
    push eax
    push ebx
    call calloc
    add esp,8
    mov dword [pStruct], eax    ;first link of the sum-to be put in the stack operand
    mov ebx,[stackCounter]
    mov dword [stackOperand+4*ebx],eax          ;save the first link of the sum in the stack
    inc byte [stackCounter]                     ;set stackCounter
    jmp no_malloc

    ;start sum action:
    sum_loop:
        mov eax,1   ;argument 2 for calloc
        mov ebx,5    ;argument 1 for calloc
        push eax
        push ebx
        call calloc
        add esp,8
        mov dword [pStruct], eax 
        mov ebx,[ptempStruct]  ;point the prev link pointer to the new calloc
        inc ebx
        mov [ebx],eax

        no_malloc: 
        mov edx,[first_link]        ;move the num in the link to first_num
        mov cl,[edx]
        mov [plusic],cl
        convert_ascii_to_dec [plusic]
        mov [first_num],cl   
        ;get next link (of first number)
        mov ecx,[first_link]
        inc ecx
        mov ecx,[ecx]
        mov [first_link],ecx
        
        mov edx,[second_link]        ;move the num in the link to second_num
        mov cl,[edx]
        mov [plusic],cl
        convert_ascii_to_dec [plusic]
        mov [second_num],cl
        ;get next link (of second number)
        mov ecx,[second_link]
        inc ecx
        mov ecx,[ecx]
        mov [second_link],ecx

        ;now we have the converted decimal numberes in first_num and second_num
        mov edx,[first_num]
        mov ecx,[second_num]
        add ecx,edx           ;now cl holds the sum
        cmp byte [carryflag],1  ;check if we there is a carry and we need to increase cl 
        jne continue_sum
        inc ecx
        continue_sum:
            mov eax,ecx           ;for the next carry check
            sub eax,16         ;if less than 0 there is no carry,else there is a carry (al holds the number we want to put in the cur link (without the carry))
            jl no_carry
            ;handle with carry
            convert_dec_to_ascii eax
            mov ebx,[pStruct]
            mov [ebx],ecx                ;the marco puts the converted value in cl aka the number
            mov edx,[pStruct]
            mov [ptempStruct],edx
            mov byte [carryflag],1
            jmp check_end_of_numbers

        no_carry:
            convert_dec_to_ascii ecx
            mov eax,[pStruct]
            mov [eax],ecx        ;the marco puts the converted value in cl aka the number
            mov edx,[pStruct]
            mov [ptempStruct],edx
            mov byte [carryflag],0

        check_end_of_numbers:
            ;check if the first number is finished,if so connect the rest of the second number to the sum
            cmp dword [first_link],0
            jne check_end_of_second

            cmp dword[second_link],0    ;check if the second number is also finished
            jne end_of_first
            ;free both lists
            xor esi,esi
            free_list [tmp_first_link],esi
            xor esi,esi
            free_list [tmp_second_link],esi

            cmp byte [carryflag],0      ;check if there is a carry, if so make a new link and put 1 in it, than finish
            je before_go_back_to_loop_check_debug
            mov eax,1   ;argument 2 for calloc
            mov ebx,5    ;argument 1 for calloc
            push eax
            push ebx
            call calloc
            add esp,8
            mov dword [pStruct], eax 
            mov ebx,[ptempStruct]  ;point the prev link pointer to the new calloc
            inc ebx
            mov [ebx],eax
            mov byte [eax],49       ;put 1 in the last link
            mov byte [carryflag],0
            jmp before_go_back_to_loop_check_debug

            end_of_first:
            xor esi,esi
            free_list [tmp_first_link],esi   ;free the first list-it ended before the second list
            free_list [tmp_second_link],[second_link]  ;free the second list from the start until the link we add to the sum list

            mov edx,[ptempStruct]
            inc edx
            mov eax,[second_link]    
            mov [edx],eax           ;now the address of the pointer in ptempStruct points to the rest of the second_link
            cmp byte [carryflag],0 
            jne handle_single_num_carry        ;in case there is a carry and the first list is finished, go through the rest of the second list and add the carry        
            jmp before_go_back_to_loop_check_debug                 ;the sum of the two numbers is in the stack

            ;check if the second number is finished,if so connect the rest of the first number to the sum
            check_end_of_second:
                cmp dword [second_link],0
                jne sum_loop
                xor esi,esi
                free_list [tmp_second_link],esi   ;free the second list-it ended before the first list
                free_list [tmp_first_link],[first_link]  ;free the first list from the start until the link we add to the sum list
                
                mov edx,[ptempStruct]
                inc edx
                mov eax,[first_link]    
                mov [edx],eax           ;now the address of the pointer in ptwmpStruct points to the rest of the first_link
                cmp byte [carryflag],0 
                jne handle_single_num_carry        ;in case there is a carry and the first list is finished, go through the rest of the second list and add the carry        
                jmp before_go_back_to_loop_check_debug                ;the sum of the two numbers is in the stack

        handle_single_num_carry:
            mov [ptempStruct],eax  ;pointer to the remainder of the longer list
            mov byte cl,[eax]
            mov byte [plusic],cl
            convert_ascii_to_dec [plusic]
            cmp cl,15     ;the marco puts the converted value in cl aka the number
            jne handle_no_carry
            ;handle carry
            mov eax, [ptempStruct]
            mov byte [eax],48     ;put zero in the curr  link (15+1=10)
            inc eax
            cmp dword [eax],0     ;check if the curr link is the last link
            jne handle_not_last_link
            mov eax,1   ;argument 2 for calloc
            mov ebx,5    ;argument 1 for calloc
            push eax
            push ebx
            call calloc
            add esp,8
            mov ebx,[ptempStruct]  ;point the prev link pointer to the new calloc
            inc ebx
            mov [ebx],eax   ;point the prev link to point to the the new link
            mov byte [eax],49   ;put in the last link 1 but calloc does it anyway???
            mov byte [carryflag],0
            jmp before_go_back_to_loop_check_debug
            handle_not_last_link:
                 mov eax,[eax]
                 jmp handle_single_num_carry   ;go to the next link to add the carry

            handle_no_carry:
                inc cl          ; add the carry from the previous sum
                convert_dec_to_ascii ecx
                mov eax, [ptempStruct]
                mov [eax],cl
                mov byte [carryflag],0
                jmp before_go_back_to_loop_check_debug

            before_go_back_to_loop_check_debug:
                cmp byte [debug],1          ; check debug mode 
                jne loop
                mov eax,[stackCounter]
                mov dword ebx,[stackOperand+4*eax-4]
                push ebx
                call reverse_list
                add esp,4
                mov [pfirst],eax  ;now pfirst has the pointer to the reversed list
                print_debug [pfirst]   ;print for debug
                xor esi,esi
                free_list [pfirst],esi ;free the reversed list
                jmp loop

;**************************************************************************
handle_dup:
    inc byte[funcounter]   ;increase the functions counter
    mov eax,[stackCounter]
    mov ebx,1 ;check if there is at least 1 item in the stackOperand
    sub eax,ebx
    jl err_insufficient
    mov eax,[stackCounter] ;check if there is a free place in the stack
    mov ebx,4
    sub ebx,eax
    jl err_overflow
    
    dec byte [stackCounter]     ;decrease stackcounter- to get the item on top of the stack
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax]  ;ebx holds the pointer to first link on top of the stack
    inc byte [stackCounter]  ;for the dec we did before

    ;copy the list and add the copy to the stack
    mov [first_link],ebx
    mov eax,1   ;argument 2 for calloc
    mov ebx,5    ;argument 1 for calloc
    push eax
    push ebx
    call calloc
    add esp,8
    mov dword [second_link], eax   ;store the address of calloc in the [second_link]
    mov dword [tmp_second_link], eax    ;save the first pointer to the list for later to push on the stack
    jmp first_handle_dup_iter
    dup_loop:
        cmp dword [first_link],0
        je handle_dup_end
        mov eax,1   ;argument 2 for calloc
        mov ebx,5    ;argument 1 for calloc
        push eax
        push ebx
        call calloc
        add esp,8
        mov dword [second_link], eax   ;store the address of calloc in [second_link] 
        mov ebx,[ptempStruct]    ;now in eax-the last pointer of the duplicated list
        mov [ebx], eax   ;connect the last pointer of the duplicated list to the new link from the calloc
        
        first_handle_dup_iter:
        mov ebx,[first_link]   ;put in ebx the pointer to the orignal list
        xor edx,edx
        mov edx,[ebx]   ;edx has the num that is in the cur link in the orignal list
        mov [eax],edx
        inc eax   ;increase eax-now it points to the pointer of the link
        mov [ptempStruct],eax  
        inc ebx 
        mov ebx,[ebx]  ;now ebx has the pointer to the next link
        mov [first_link],ebx
        jmp dup_loop
    handle_dup_end:
        mov eax,[stackCounter]
        mov ebx,[tmp_second_link]
        mov dword [stackOperand+4*eax],ebx  ;put the pointer to the first link in the list on the stack
        inc byte [stackCounter]  ;for the list we added (of the duplicated list)
        
        ; check debug mode 
        cmp byte [debug],1          
        jne loop
        mov eax,[stackCounter]
        mov dword ebx,[stackOperand+4*eax-4]
        push ebx
        call reverse_list
        add esp,4
        mov [pfirst],eax  ;now pfirst has the pointer to the reversed list
        print_debug [pfirst]   ;print for debug
        xor esi,esi
        free_list [pfirst],esi ;free the reversed list
        jmp loop

;**************************************************************************
handle_n:
    inc byte[funcounter]   ;increase the functions counter
    mov eax,[stackCounter]
    mov ebx,1
    sub eax,ebx
    jl err_insufficient     ;jump if there are less than 1 number in the stack
    dec byte [stackCounter] ;**********************************************************************************rmemember to inc back
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax]
    mov [first_link],ebx         
    mov [tmp_first_link],ebx     ;save so we can free the first link in the end
    xor edx,edx 
    mov [n_counter],edx      ;initalize the n_counter 
    mov dword [stackOperand+4*eax],edx ;put zeros in the stack where we removed the number
    
    n_loop: 
        mov eax,[first_link]        ;put in ecx the pointer to the link
        mov eax,[eax]               ;put the number from the link in eax
        mov [retval],eax
        convert_ascii_to_dec [retval]
        push ecx
        call count_1s
        add esp,4
        add eax,[n_counter]         ; add to the counter the returned value
        mov [n_counter],eax         ;update the counter
        mov eax,[first_link]        ;put in ecx the pointer to the link
        inc eax
        mov eax,[eax]               ;put the next pointer in eax
        mov [first_link],eax
        cmp dword [first_link],0
        jne n_loop
        xor eax,eax
        free_list [tmp_first_link],eax      ;free the list of the number we poped
        
        mov eax,1   ;argument 2 for calloc
        mov ebx,5    ;argument 1 for calloc
        push eax
        push ebx
        call calloc
        add esp,8
        mov dword [first_link], eax   ;first link points to the first link of the new list
        mov edx,[stackCounter]
        mov dword [stackOperand+4*edx],eax  ;put in the stackoperand the pointer to the first link of the new list
        inc byte [stackCounter]             ;increase stack counter
        jmp first_iter

    n2_loop:
        mov eax,1   ;argument 2 for calloc
        mov ebx,5    ;argument 1 for calloc
        push eax
        push ebx
        call calloc
        add esp,8
        mov dword [first_link], eax   ;first link points to the first link of the new list
        mov ebx,[second_link]           ;put in ebx the pointer that is in the prev link
        mov [ebx],eax                   ;point the pointer in ebx to the new link

        first_iter:
            mov eax,[n_counter] ;the num we divide
            mov ecx,0x10        ;put in ecx the divisor  
            cdq
            DIV ecx
            mov [n_counter],eax        ;update the num after we devided 
            mov ebx,[first_link]
            convert_dec_to_ascii edx    ;convert the remainder (after div the remainder is saved in edx) to ascii
            mov [ebx],ecx                   ;put in the link the remainder 
            inc ebx
            mov [second_link],ebx
            cmp eax,0            ;check if we finished to divide
            je n_debug
            jmp n2_loop

    ; check debug mode 
    n_debug:
        cmp byte [debug],1          
        jne loop
        mov eax,[stackCounter]
        mov dword ebx,[stackOperand+4*eax-4]
        push ebx
        call reverse_list
        add esp,4
        mov [pfirst],eax  ;now pfirst has the pointer to the reversed list
        print_debug [pfirst]   ;print for debug
        xor esi,esi
        free_list [pfirst],esi ;free the reversed list
        jmp loop

;**************************************************************************
handle_positive_power:
    inc byte[funcounter]   ;increase the functions counter
    mov eax,[stackCounter]
    mov ebx,2
    sub eax,ebx
    jl err_insufficient     ;jump if there are less than 2 numbers in the stack
    dec byte [stackCounter]
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax]
    mov [first_link],ebx         
    mov [tmp_first_link],ebx     ;save so we can free the first link in the end
    dec byte [stackCounter]
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax]
    mov [second_link],ebx         
    
    mov eax,[second_link]  ;eax now is the pointer to first link (list of y)
    push eax
    call list_to_y
    add esp,4

    mov dword [power],eax     ;now y is in [power]
    mov ebx,200
    sub ebx,eax
    jl wrong_num
    xor esi,esi
    free_list [second_link],esi         ;free y
    handle_positive_power_loop:
        cmp dword [power],0           ;check how many "shifts" we did
        je handle_positive_power_end
        xor ebx,ebx
        mov [power_carry_flag],ebx
        mov byte [carryflag],0
        iner_power_loop:
            cmp dword [first_link],0      ;check we didn't get to the end of the list
            je next_power
            mov eax,[first_link]
            mov ecx,ebx                     ;put 0 in ecx
            mov edx,[eax]                    ;save the num in edx(for the convertion)
            convert_ascii_to_dec dl
            mov bl,cl
            sub cl,0x8      ;ecx holds the converted(to decimal) value
            jl no_p_carry
            mov byte [carryflag],1         ;in case there is a carry(add it to the next op)
            jmp shift_power
            no_p_carry: 
                mov byte [carryflag],0
            shift_power: 
                shl bl,1                    ;multiplay by 2
                cmp byte [carryflag],1
                jne no_module
                sub bl,16                   ;if there is a carry after the shl we need to sub 16 for the convert
                no_module:
                cmp dword [power_carry_flag],0      ;check if there is a carry from the prev op
                je no_p_carry2
                inc byte bl    ;if there was carry from prev op, add it here to the shifted num
            no_p_carry2:
                ;update the value of the num in the link
                convert_dec_to_ascii ebx  ;the converted num is stored in ecx
                mov eax,[first_link]    ;put in eax the pointer to the curr link
                mov byte [eax],cl   ;put the shifted num back in the link (instead of the prev num)

                xor ebx,ebx
                mov byte bl,[carryflag]         ;move carryflag to power_carry_flag for the next op
                mov [power_carry_flag],ebx  ;power_carry_flag is now the carry for the next op
                ;update first link to the next one
                mov eax,[first_link]
                mov [ptempStruct],eax   ;save the the cur link before we move in [first_link] the next link (its for the new calloc in next_power)
                inc eax
                mov eax,[eax]
                mov [first_link],eax
                jmp iner_power_loop

        next_power:
            dec byte [power]
            mov edx,[tmp_first_link]    ;set first_link to the beginning of the list
            mov [first_link],edx
            cmp dword [power_carry_flag],0
            je handle_positive_power_loop
            ;in case we need to add a new link with 1
            mov eax,1   ;argument 2 for calloc
            mov ebx,5    ;argument 1 for calloc
            push eax
            push ebx
            call calloc
            add esp,8
            mov ebx,[ptempStruct]  ;put the pointer to the last link in ebx
            inc ebx  
            mov [ebx],eax   ;point the last link in the list to the new link from calloc
            mov byte [eax],49
            jmp handle_positive_power_loop

    handle_positive_power_end:
        mov ebx,[tmp_first_link]
        mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
        mov [stackOperand+4*eax],ebx
        inc byte [stackCounter]
        jmp plus_debug
    wrong_num:
        inc byte [stackCounter]  ;for the two dec we did in the start
        inc byte [stackCounter]
        jmp err_wrong_value

    ; check debug mode 
    plus_debug:
        cmp byte [debug],1          
        jne loop
        mov eax,[stackCounter]
        mov dword ebx,[stackOperand+4*eax-4]
        push ebx
        call reverse_list
        add esp,4
        mov [pfirst],eax  ;now pfirst has the pointer to the reversed list
        print_debug [pfirst]   ;print for debug
        xor esi,esi
        free_list [pfirst],esi ;free the reversed list
        jmp loop
;**************************************************************************
handle_negative_power:
    inc byte[funcounter]   ;increase the functions counter
    mov eax,[stackCounter]
    mov ebx,2
    sub eax,ebx
    jl err_insufficient     ;jump if there are less than 2 numbers in the stack
    dec byte [stackCounter]
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax]
    mov [first_link],ebx      ;get pointer to X    
    mov [tmp_first_link],ebx     ;save so we can free the first link in the end
    dec byte [stackCounter]
    mov eax,[stackCounter]      ;update the changes to the stackCounter into eax
    mov ebx,[stackOperand+4*eax] ;get pointer to Y
    mov [second_link],ebx         

    mov eax,[second_link]  ;eax now is the pointer to first link (list of y)
    push eax
    call list_to_y
    add esp,4
    mov dword [power],eax     ;now y is in [power]
    mov ebx,200
    sub ebx,eax
    jl wrong_num
    xor esi,esi
    free_list [second_link],esi         ;free y

   
    mov dword ebx,[first_link]
    push ebx   ;in ebx is the pointer to the start of the list
    call reverse_list
    add esp,4
    mov [pStruct],eax   ;pStruct hold the pointer to the newly created reversed list
    mov [ptempStruct],eax  ;save the pointer to the new list (for later to put on the stack)
    xor esi,esi
    free_list [first_link],esi          ;free X
    handle_negative_power_loop:     
        cmp dword [power],0     ;check how many "shifts" we did
        je handle_negative_power_end
        mov byte [carryflag],0
        iner_neg_power_loop:
            cmp dword [pStruct],0   ;check we didn't get to the end of the list
            je next_neg_power
            mov eax,[pStruct]
            mov edx,[eax]                   ;save the num in edx(for the convertion)
            convert_ascii_to_dec dl         ;now cl holds the converted number from the link 
            xor ebx,ebx
            shl byte [carryflag],4          ;multiplay by 16(if it was 0 remains 0)
            add cl,[carryflag]              ;add the carry flag to the number
            shr cl,1                        ;divide the number by 2
            adc bl,0                        ; put the carry from the shr in bl
            mov [carryflag],bl              ;save the carry flag
            ;change the number in the link
            mov eax,[pStruct]
            convert_dec_to_ascii  ecx
            mov byte [eax],cl
            inc eax                         
            mov eax,[eax]       
            mov [pStruct],eax                ;put the next link in pStruct
            jmp iner_neg_power_loop

            next_neg_power:
                dec byte [power]
                mov edx,[ptempStruct]    ;put in edx the pointer to the beginning of the list
                mov[pStruct],edx        ;[pStruct] points to the start of the list
                xor eax,eax
                mov byte al,[edx]            ;put in eax the num in the first link of the list
                cmp eax,48              ;if the num in first link is now 0- lose the link (and save the next link in ptempStruct)
                jne no_lose
                inc edx
                mov edx,[edx]  ;edx-has the pointer to the next link
                cmp dword edx,0;check if the next pointer isn't 0
                je handle_negative_power_end ; in this case we have one link and there is 0 inside it
                mov [ptempStruct],edx ;put in ptempStruct the new pointer to the start of the list (previously second link)
                mov dword ecx,[pStruct]
                push ecx
                call free  ;free the first link of the list
                add esp,4
                mov eax,[ptempStruct]  ;mov the new pointer of the head of the list to eax
                mov [pStruct],eax       ;update pstruct to point to the new head of the list
                no_lose: ;jump here if the num in the head of the list isnt 0 
                
                jmp handle_negative_power_loop

    handle_negative_power_end:
        mov dword ebx,[ptempStruct]
        push ebx   ;in ebx is the pointer to the start of the reversed and divided list
        call reverse_list
        add esp,4
        mov [pStruct],eax   ;now pstruct has pointer to the final and new divided list
        xor esi,esi
        free_list [ptempStruct],esi  ;free the reveres divied list that we created
        mov ebx,[pStruct]
        mov eax,[stackCounter]      
        mov [stackOperand+4*eax],ebx   
        inc byte [stackCounter]
        jmp neg_debug 
        
    ; check debug mode 
    neg_debug:
        cmp byte [debug],1          
        jne loop
        mov eax,[stackCounter]
        mov dword ebx,[stackOperand+4*eax-4]
        push ebx
        call reverse_list
        add esp,4
        mov [pfirst],eax  ;now pfirst has the pointer to the reversed list
        print_debug [pfirst]   ;print for debug
        xor esi,esi
        free_list [pfirst],esi ;free the reversed list
        jmp loop

;**************************************************************************
checkInput:
    cmp byte [num],113  ;if recived 'q' jump to end
    je end
    cmp byte [num],43  ; check for +
    je handle_plus
    cmp byte [num],112   ; check for 'p'
    je handle_p 
    cmp byte [num],100  ;check for 'd'
    je handle_dup
    cmp byte [num],94   ;check for ^
    je handle_positive_power
    cmp byte [num],118   ;check for 'v'
    je handle_negative_power
    cmp byte [num],110   ;check for n
    je handle_n
    mov bx,[num]  ;check for 'sr'
    mov cx,[sr]
    cmp word bx,cx
    je handle_oprend
    cmp byte [stackCounter],5
    jne handle_num
    jmp err_overflow 
        
    jmp loop

err_overflow:
    mov eax,4
    mov ebx,1
    mov ecx,err1
    mov edx, lenerr1
    int 0x80
    jmp loop

err_insufficient:
    mov eax,4
    mov ebx,1
    mov ecx,err2
    mov edx, lenerr2
    int 0x80
    jmp loop

err_wrong_value:
    mov eax,4
    mov ebx,1
    mov ecx,err3
    mov edx,lenerr3
    int 0x80
    jmp loop



   
  

        
