emrpage dq 0
emradrs dq 0

initemr:
	call malocbig
	mov [emrpage],rbx
	mov [emradrs],rax
	
	xor rax,rax
	mov rsi,[emradrs]
	mov rdi,rsi
	add rdi,1024
	call fillmem

	mov rsi,[emradrs]
	mov byte[rsi + 5],1
	mov byte[rsi +  21],1

	call dumpemr
.done
ret

dumpemr:
	mov rsi,[emradrs]
	xor rbx,rbx
	xor rcx,rcx
.loop
	mov al,byte[rsi]
	add al,'0'
	push rbx
	push rcx
	call cprint
	pop rcx
	pop rbx
	inc rsi
	cmp rbx,15
	jge .next
	inc rbx
	jmp .loop
.next
	call newline
	cmp rcx,15
	jge .done
	xor rbx,rbx
	inc rcx
	jmp .loop
.done
ret

stepemr:
	xor rax,rax
	mov rsi,[emradrs]
ret

getneighbors:		;rax - cell id, rdi - pointer to neighbor list
	cmp rax,80
	jl .row0
	add rax,[emradrs]
	mov bl,byte[rax - 17]
	mov byte[.buff],bl
	mov bl,byte[rax - 16]
	mov byte[.buff + 1],bl
	mov bl,byte[rax - 15]
	mov byte[.buff + 2],bl
	jmp .next
.row0
	add rax,[emradrs]
	mov byte[.buff],0
	mov byte[.buff + 1],0
	mov byte[.buff + 2],0
.next
	mov bl,byte[rax - 1]
	mov byte[.buff + 3],bl
	mov bl,byte[rax + 1]
	cmp rax,240
	jg .lastrow
	mov byte[.buff + 4],bl
	mov bl,byte[rax + 15]
	mov byte[.buff + 5],bl
	mov bl, byte[rax + 16]
	mov byte[.buff + 6],bl
	mov bl,byte[rax + 17]
	mov byte[.buff + 7],bl
	jmp .done
.lastrow
	
.done
	mov rdi,.buff
ret
	.buff times 8 db 0