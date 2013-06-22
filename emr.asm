emrpage dq 0
emradrs dq 0
ruletab dq 0

initemr:
	call malocbig
	mov [emrpage],rbx
	mov [emradrs],rax

	xor rax,rax
	mov rsi,[emradrs]
	mov rdi,rsi
	add rdi,1024
	call fillmem

	mov rax,.tab
	mov [ruletab],rax

	mov rsi,[emradrs]
	mov byte[rsi],0
	mov byte[rsi + 21],1
	mov byte[rsi + 22],1
	mov byte[rsi + 37],1

	call dumpemr
.loop
	call getkey
	call getkey
	call stepemr
	jmp .loop
.done
ret
	.tab db 0,1,1,1,0,0,0,0,0,0

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
	call malocbig
	mov [.page],rbx
	mov [.adrs],rax

	mov rax,1024
	mov rdi,[.adrs]
	mov rsi,[emradrs]
	call movemem

	xor rdx,rdx
.loop
	mov rax,rdx
	push rdx
	call sumneighbors
	pop rdx

	mov rdi,[emradrs]
	add rdi,rdx
	mov rsi,[ruletab]
	add rsi,rbx
	mov cl,byte[rsi]
	mov byte[rdi],cl
	

	cmp rdx,256
	jge .done
	inc rdx
	jmp .loop
.done
	mov rax,1024
	mov rsi,[.adrs]
	mov rdi,[emradrs]
	call movemem

	call dumpemr
	mov rax,[.page]
	call freebig
ret
	.tmp times 32 db 0
	.page dq 0
	.adrs dq 0

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