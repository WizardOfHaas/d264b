initmm:
	mov rsi,.msg
	call sprint

	mov rsi,void
	mov rdi,void + 2048
	xor ax,ax
	call fillmem
	
	mov rsi,.ok
	call sprint
ret
	.msg db 'Initializing Memory Manager...',0
	.ok db '[ok]',13,0

fillmem:	;rsi - start,rdi - end,al - value
.loop
	cmp rsi,rdi
	jge .done
	inc rsi
	mov byte[rsi],al
	jmp .loop
.done
ret

malocbig:		;Out - rAX,start of 1kb page,rBX,page id
	push rsi
	mov rsi,void
	xor rbx,rbx
.loop
	cmp rsi,void + 2048
	jg .done
	cmp byte[rsi + rbx],0
	je .found
	add bx,1
	jmp .loop
.found
	mov byte[rsi + rbx],1
	mov rax,1024
	mul rbx
	add rax,void
.done
	push rax
	mov rsi,rax
	mov rdi,rax
	add rdi,1024
	mov al,0
	call fillmem
	pop rax
	pop rsi
ret

freebig:	;rax - page id
	add rax,void
	mov byte[rax],0
ret

movemem:	;rsi - source, rdi - dest, rax - size
	push rax
	push rdi
	push rsi
	xor rbx,rbx
.loop
	cmp rbx,rax
	jge .done
	mov cl,byte[rsi]
	mov byte[rdi],cl
	inc rsi
	inc rdi
	inc rbx
	jmp .loop
.done
	pop rsi
	pop rdi
	pop rax
ret

copystring:	;rsi - source, sdi - dest
	push rsi
	push rdi
.loop
	mov al,byte[rsi]
	mov byte[rdi],al
	cmp al,0
	je .done
	inc rsi
	inc rdi
	jmp .loop
.done
	pop rdi
	pop rsi
ret

dump:		;rsi - address
	push rsi
	push rdi
	push rax
	push rbx
	
	push rsi
	mov rax,rsi
	call iprint
	mov al,':'
	call cprint
	pop rsi

	xor rbx,rbx	
.loop
	cmp rbx,16
	jge .next
	push rbx
	push rsi

	xor rax,rax
	mov al,byte[rsi]
	call iprint	
	mov al,' '
	call cprint

	pop rsi
	pop rbx
	inc rsi
	inc rbx
	jmp .loop
.next
	mov al,'|'
	call cprint
	xor rbx,rbx
	sub rsi,16
.cloop
	cmp rbx,16
	jge .done
	push rbx
	push rsi

	xor rax,rax
	mov al,byte[rsi]
	call cprint	

	pop rsi
	pop rbx
	inc rsi
	inc rbx
	jmp .cloop
.done
	call newline

	pop rbx
	pop rax
	pop rdi
	pop rsi
ret
