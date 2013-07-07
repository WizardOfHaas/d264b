taskadrs dq 0
que times 512 db 0

inittask:
	mov rsi,.msg
	call sprint

	call malocbig
	mov [taskadrs],rax
	mov rsi,rax
	mov rdi,rax
	add rdi,1024
	xor al,al
	call fillmem
	call malocbig
	call malocbig
	call malocbig
	call malocbig

	mov rsi,.ok
	call sprint
ret
	.msg db 'Inisializing Task Manager...',0
	.ok db '[ok]',13,0

schedule:	;rax - adrs to schedule, rax - pid
	mov rdi,[taskadrs]
	mov rsi,rdi
	add rsi,1024
.loop
	cmp rdi,rsi
	jge .full
	cmp qword[rdi],0
	je .sched
	add rdi,1
	jmp .loop
.sched
	mov [rdi],rax
	mov rax,rdi
	sub rax,[taskadrs]
	jmp .done
.full
	mov rax,-1
.done
ret

yield:
	mov rsi,[taskadrs]
	mov rax,[rsi]
	mov rbx,shell
	call getregs
ret