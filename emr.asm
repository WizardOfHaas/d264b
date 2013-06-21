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
	mov byte[rsi],1
	mov byte[rsi + 5],1
	mov byte[rsi + 85],1

	call dumpemr
.done
ret

dumpemr:
	mov rsi,[emradrs]
	xor rbx,rbx
.loop
	mov al,byte[rsi]
	add al,'0'
	call cprint
	cmp rbx,1024
	jge .done
	inc rsi
	inc rbx
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
	mov bl,byte[rax - 81]
	mov byte[.buff],bl
	mov bl,byte[rax - 80]
	mov byte[.buff + 1],bl
	mov bl,byte[rax - 79]
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
	mov byte[.buff + 4],bl
	mov bl,byte[rax + 79]
	mov byte[.buff + 5],bl
	mov bl, byte[rax + 80]
	mov byte[.buff + 6],bl
	mov bl,byte[rax + 81]
	mov byte[.buff + 7],bl
	mov rdi,.buff
ret
	.buff times 8 db 0