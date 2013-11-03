	dlisppage dq 0
	dlispadrs dq 0
	dlisptemp dq 0

rundlisp:			;rsi - string to interpret
	call validatedlisp
	cmp rax,0
	jne .err
	
	call malocbig
	mov [dlisppage],rbx
	mov [dlispadrs],rax
	mov qword[dlisptemp],rax

	call tokenify
	mov [.temp],rsi
	
	mov rsi,[.temp]
	call getstatement

	call eval
	call iprint
	call newline
	
	mov rax,[dlisppage]
	call freebig
	jmp .done
.err
	mov rsi,.errmsg
	call sprint
.done
	ret
	.temp dq 0
	.errmsg db 'You done fucke up!',13,0

eval:				;rsi - tokonified dlisp to eval
	push rsi
	cmp byte[rsi],'0'
	jge .char
	cmp byte[rsi],'('
	je .parse
	
	cmp byte[rsi],'+'
	je .sum
	cmp byte[rsi],'-'
	je .dif
	
	jmp .done
.parse
	call getstatement
	call eval
	jmp .done
	
.char
	cmp byte[rsi],'9'
	jle .num
	jmp .done
	
.num
	call toint
	jmp .done
	
.sum
	add rsi,2
	call eval
	mov rbx,rax
	
	.sumloop
	cmp byte[rsi],254
	je .sumdone
	cmp byte[rsi],'('
	je .sumstatement

	call strlength
	add rsi,rax
	inc rsi
	.sumstatedone

	cmp byte[rsi],254
	je .sumdone

	push rbx
	call eval
	pop rbx
	add rbx,rax
	jmp .sumloop
.sumdone
	mov rax,rbx
	jmp .done
.sumstatement
	push rax
	call statementlength
	add rsi,rax
	add rsi,2
	pop rax
	jmp .sumstatedone
	
.dif
	add rsi,2
	call eval
	mov rbx,rax
	push rbx
	
	cmp byte[rsi],'('
	je .difstatement
	
	call dlstrlength
	add rsi,rax
	inc rsi
	.difstatedone
	
	call eval
	pop rbx
	sub rbx,rax
	mov rax,rbx
	jmp .done
.difstatement
	push rax
	call statementlength
	add rsi,rax
	add rsi,2
	pop rax
	jmp .difstatedone
.done
	pop rsi

	push rax
	push rbx
	push rsi
	mov al,byte[rsi]
	call cprint
	pop rsi
	pop rbx
	pop rax
	call getregs
	
	ret

getstatement:			;rsi - tokonified source to get statement from, statement
	;; (+ 1 1) => ( + 1 1 ) => + 1 1
	;; ^String    ^Token       ^Statement!
.loop0
	cmp byte[rsi],'('
	je .next
	cmp byte[rsi],254
	je .err
	
	inc rsi
	jmp .loop0
.next
	xor rax,rax
	mov rbx,1
	add rsi,2
	mov r8,rsi
.loop1
	cmp byte[rsi],')'
	je .done
	cmp byte[rsi],'('
	je .complex
	cmp byte[rsi],254
	je .err

	inc rsi
	inc rax
	jmp .loop1
.complex
	inc rsi
	inc rbx
	inc rax
	jmp .loop1
.more
	inc rax
	inc rsi
	jmp .loop1
.err
	mov rsi,0
	ret
.done
	dec rbx
	cmp rbx,0
	jne .more
	
	mov rsi,r8
	mov rdi,[dlisptemp]
	call movemem
	mov rsi,[dlisptemp]
	mov byte[rsi + rax],254
	add rax,3
	add [dlisptemp], rax
	ret

tokenify:			;rsi - string to tokenify
	cmp qword[.page],0
	je .nofree
	mov rax,[.page]
	call freebig
	
	.nofree
	mov al,' '
	call strsplit

	call malocbig
	mov [.page],rax
	mov [.adrs],rax
	mov rdi,rax
.loop
	cmp byte[rsi],254
	je .done
	
	cmp byte[rsi],'('
	je .addtok
	cmp byte[rsi],')'
	je .addtok
	cmp byte[rsi],'+'
	je .addtok
	cmp byte[rsi],'-'
	je .addtok
	cmp byte[rsi],'*'
	je .addtok
	cmp byte[rsi],'/'
	je .addtok

	cmp byte[rsi],'0'
	jge .addstr

	inc rsi
	
	jmp .loop
.addtok
	mov al,byte[rsi]
	mov byte[rdi],al
	inc rdi
	mov byte[rdi],0

	inc rdi
	inc rsi
	jmp .loop
.addstr
	call copystring
	call dlstrlength
	add rsi,rax
	add rdi,rax
	mov byte[rdi],0
	
	inc rdi
	jmp .loop
.done
	mov byte[rdi],254
	mov rsi,[.adrs]
	ret
	.page dq 0
	.adrs dq 0
	
strsplit:			;rsi - string to split, al - delimiter
	push rsi
.loop
	mov ah,byte[rsi]

	cmp ah,al
	je .split
	cmp ah,0
	je .done

	inc rsi
	jmp .loop
.split
	mov byte[rsi],0
	inc rsi
	jmp .loop
.done
	mov byte[rsi],254
	pop rsi
	ret

dlstrlength:			;rsi - string to count length of
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],0
	je .done
	cmp byte[rsi],254
	je .done
	cmp byte[rsi],'0'
	jl .done

	inc rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret


strlength:			;rsi - string to count length of
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],0
	je .done

	inc rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret

statementlength:			;rsi - string to count length of
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],')'
	je .done

	inc rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret

validatedlisp:				;rsi - string to validate
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],'('
	je .open
	cmp byte[rsi],')'
	je .close

	cmp byte[rsi],0
	je .done
	
	inc rsi
	jmp .loop
.open
	inc rax
	inc rsi
	jmp .loop
.close
	dec rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret

