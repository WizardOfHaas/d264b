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
	mov byte[rsi + 20],1
	mov byte[rsi + 22],1

	call dumpemr
	call getkey
	call stepemr
.done
ret

dumpemr:
	mov byte[xpos],0
	mov byte[ypos],5
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
	xor rdx,rdx
.loop
	mov rax,rdx
	push rdx
	call sumneighbors
	pop rdx
	cmp rbx,3
	je .live
	cmp rbx,1
	jle .die
	.allok
	cmp rdx,256
	jge .done
	inc rdx
	jmp .loop
.live
	mov rdi,[emradrs]
	add rdi,rdx
	mov byte[rdi],1
	jmp .allok
.die
	mov rdi,[emradrs]
	add rdi,rdx
	mov byte[rdi],0
	jmp .allok
.done
	call dumpemr
ret
	.tmp times 32 db 0

sumneighbors:		;rax - cell id, rbx - sum of neighbors values
	call getneighbors
	xor rbx,rbx
	movzx rcx,byte[rdi]
	add rbx,rcx
	movzx rcx,byte[rdi + 1]
	add rbx,rcx
	movzx rcx,byte[rdi + 2]
	add rbx,rcx
	movzx rcx,byte[rdi + 3]
	add rbx,rcx
	movzx rcx,byte[rdi + 4]
	add rbx,rcx
	movzx rcx,byte[rdi + 5]
	add rbx,rcx
	movzx rcx,byte[rdi + 6]
	add rbx,rcx
	movzx rcx,byte[rdi + 7]
	add rbx,rcx
ret

getneighbors:		;rax - cell id, rdi - pointer to neighbor list
	cmp rax,16
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
	mov byte[.buff + 4],bl
	cmp rax,240
	jg .lastrow
	mov bl,byte[rax + 15]
	mov byte[.buff + 5],bl
	mov bl, byte[rax + 16]
	mov byte[.buff + 6],bl
	mov bl,byte[rax + 17]
	mov byte[.buff + 7],bl
	jmp .done
.lastrow
	mov byte[.buff + 5],0
	mov byte[.buff + 6],0
	mov byte[.buff + 7],0
.done
	mov rdi,.buff
ret
	.buff times 8 db 0