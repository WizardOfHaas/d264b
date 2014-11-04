	db 'vm.asm',0

	vmstab dq 0,0
	nextvm dq 0,0	

	testcode dq 0,0,'@'
	
initvm:				;Spin up MVMs
	mov rsi,.msg
	call sprint
	
	call malocbig
	mov [vmstab],rax

	call newvm
	xor rax,rax
	mov rsi,testcode
	call runvm
	
	mov rsi,.ok
	call sprint
	ret
	.msg db 'Initializing MVM subsystem...',13,0
	.ok db '[ok]',13,0

newvm:				;Create new VM
	mov rsi,.msg
	call sprint
	mov rax,[nextvm]
	call iprint
	
	call malocbig		;Get 2 pages for VM and put in vmstab
	mov rdi,[nextvm]
	mov [vmstab + rdi],rax
	call malocbig
	mov [vmstab + rdi + 4], rax	

	mov rax,2
	add [nextvm],rax	;Set nextvm to point to empty space in vmstab
	mov rsi,.on
	call sprint
	ret
	.msg db 'VM ',0
	.on db ' online',13,0

runvm:				;rax - vm ID, rsi, code
	mov rbx,[vmstab + rax]	;get the address for the VM state and tape pages
	mov [.vmstate],rbx
	mov rbx,[vmstab + rax + 4]
	mov [.vmtape],rbx
	mov [.vmcode],rsi
	
	mov rdi,[.sp]		;grab ip and sp from stored state
	mov rsi,[.ip]
	
	.loop

	cmp byte[rsi + .vmcode],'@'	;let loop until the end (@) for now
	je .break
	
	call vmop

	inc rsi			;next op!
	
	jmp .loop
	
	.break

	mov [.ip],rsi		;now save the state and clean up
	mov [.sp],rdi
	
	ret
	.vmstate dq 0,0
	.vmtape dq 0,0
	.vmcode dq 0,0
	.ip dq 0,0
	.sp dq 0,0

vmop:
	
	ret