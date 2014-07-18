	db 'task.asm'
	
	taskadrs dq 0
	que times 512 db 0
	curtask dq 0
	
inittask:
	mov rsi,.msg
	call sprint

	call malocbig
	add rax,5
	mov [taskadrs],rax
	mov [curtask],rax
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
	.msg db 'Initializing Task Manager...',0
	.ok db '[ok]',13,0

OLDschedule:	;rax - adrs to schedule, rax - pid
	mov rdi,[taskadrs]
	mov rsi,rdi
	add rsi,1024
.loop
	cmp rdi,rsi
	jge .full
	cmp qword[rdi],0
	je .sched
	add rdi,8
	jmp .loop
.sched
	mov [rdi],rax
	mov rax,rdi
	sub rax,[taskadrs]
	mov [curtask],rax
	jmp .done
.full
	mov rax,-1
.done
	ret

pushtask:			;Lets try using a stack for a task que
	mov r10,rsp
	mov r11,rbp

	mov rbp,[taskadrs]
	mov rsp,[curtask]
	push rax

	mov [curtask],rsp
	
	mov rsp,r10
	mov rbp,r11
	ret

poptask:
	mov r10,rsp
	mov r11,rbp

	mov rbp,[taskadrs]
	mov rsp,[curtask]
	pop rax

	mov [curtask],rsp
	
	mov rsp,r10
	mov rbp,r11
	ret

schedule:
	call pushtask
	ret

yield:
	call poptask
	call rax
	ret
	
OLDyield:
	;; Calc address of current current task
	mov rbx,[taskadrs]
	add rbx,[curtask]
	mov rax,[rbx]
	push rax
	
	;; Set up task for after this one
	;; FIX THIS SHIT!!!
	mov rdi,[taskadrs]
	add rdi,1024
.loop
	cmp rbx,rdi
	jge .end
	add rbx,4

	push rdi
	push rbx
	mov rax,rbx
	sub rax,[taskadrs]
	call iprint
	call newline
	pop rbx
	pop rdi
	
	cmp qword[rbx],0
	jne .next
	jmp .loop
.next

	sub rbx,[taskadrs]
	mov [curtask],rbx
	jmp .done
.end
	mov rbx,[taskadrs]
	jmp .loop
.done	
	;; Run it, motherfucker!
	pop rax
	call rax	
ret
