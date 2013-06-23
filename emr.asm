emrpage dq 0
emradrs dq 0
ruletab dq gol

gol 	db 0,0,0,1,0,0,0,0,0
	db 0,0,1,1,0,0,0,0,0

lfod	db 0,0,1,0,0,0,0,0,0
	db 1,0,0,0,0,0,0,0,0

lwod 	db 0,0,0,1,0,0,0,0,0
	db 1,1,1,1,1,1,1,1,1

maze	db 0,0,0,1,0,0,0,0,0
	db 0,1,1,1,1,1,0,0,0


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
	mov byte[rsi],0
	mov byte[rsi + 22],1
	mov byte[rsi + 38],1
	mov byte[rsi + 54],1

	call dumpemr
.loop
	call getkey
	call getkey
	call stepemr
	jmp .loop
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
	add al,7
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
	add qword[.gen],1

	call malocbig
	mov [.page],rbx
	mov [.adrs],rax

	mov rax,1024
	mov rdi,[.adrs]
	mov rsi,[emradrs]
	call movemem

	xor rax,rax
.loop
	mov rdi,[emradrs]
	add rdi,rax
	cmp byte[rdi],0
	je .dead
.live
	call sumneighbors
	mov rsi,[ruletab]
	add rsi,rbx
	add rsi,9
	movzx rcx,byte[rsi]
	call getregs

	mov rdi,[.adrs]
	add rdi,rax
	mov cl,byte[rsi]
	mov byte[rdi],cl
	jmp .ok
.dead
	call sumneighbors
	mov rsi,[ruletab]
	add rsi,rbx

	mov rdi,[.adrs]
	add rdi,rax
	mov cl,byte[rsi]
	mov byte[rdi],cl
.ok
	cmp rax,256
	jge .done
	inc rax
	jmp .loop
.done
	mov rax,1024
	mov rsi,[.adrs]
	mov rdi,[emradrs]
	call movemem

	mov rax,[.page]
	call freebig

	call dumpemr
	mov rax,[.gen]
	call iprint
ret
	.tmp times 32 db 0
	.page dq 0
	.adrs dq 0
	.gen dq 0

sumneighbors:		;rax - cell id, rbx - sum of neighbors values
	push rax
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
	pop rax
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

	mov bl,byte[rax + 15]
	mov byte[.buff + 5],bl
	mov bl, byte[rax + 16]
	mov byte[.buff + 6],bl
	mov bl,byte[rax + 17]
	mov byte[.buff + 7],bl
	jmp .done
.done
	mov rdi,.buff
ret
	.buff times 8 db 0