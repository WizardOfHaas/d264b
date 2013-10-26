rundlisp:			;rsi - string to interpret
	call tokenify
	mov [.temp],rsi
	push rsi
	call dump
	pop rsi
	add rsi,16
	call dump

	call newline
	mov rsi,[.temp]
	call getstatement
	push rsi
	call dump
	pop rsi

	call eval
	call getregs
	ret
	.temp dq 0

eval:				;rsi - tokonified dlisp to eval
	cmp byte[rsi],'+'
	je .sum
	cmp byte[rsi],'-'
	je .dif
	
	jmp .done
.sum
	mov rax,[rsi + 2]
	mov rbx,[rsi + 4]

	add rax,rbx
	jmp .done
.dif
	.done
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
	mov rdi,.temp
	call movemem
	mov rsi,.temp
	mov byte[rsi + rax],254
	ret
	.temp times 64 db 0

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
