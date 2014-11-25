	db 'vm.asm',0

	vmstab dq 0,0
	nextvm dq 0,0	

testcode:
	db 0, 1, 0,0,0,0, 4, 0,0,0,1 ,0, 0,0,0,0
	db 0, 2, 0,0,0,0, 4, 0,0,0,1 ,0, 0,0,0,0
	db '@'
	
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
	.msg db 13,'Initializing MVM subsystem...',13,0
	.ok db '[ok]',13,13,0

newvm:				;Create new VM
	mov rsi,.msg
	call sprint
	mov rax,[nextvm]
	call iprint
	
	call malocbig		;Get 2 pages for VM and put in vmstab
	mov rdi,[nextvm]
	mov r10,[vmstab]
	mov [r10 + rdi],rax
	push rdi
	call malocbig
	pop rdi
	mov [r10 + rdi + 4], rax	

	mov rax,2
	add [nextvm],rax	;Set nextvm to point to empty space in vmstab
	mov rsi,.on
	call sprint
	ret
	.msg db 'VM ',0
	.on db ' [online]',13,0

runvm:				;rax - vm ID, rsi, code
	mov rbx,[vmstab + rax]	;get the address for the VM state and tape pages
	mov [.vmstate],rbx
	mov rbx,[vmstab + rax + 4]
	mov [.vmtape],rbx
	mov [.vmcode],rsi
	
	mov rdi,[.sp]		;grab ip and sp from stored state
	mov rsi,[.ip]
	mov r10,[.jp]
	mov r11,[.vmcode]
	mov r12,[.vmtape]
	
	.loop
	
	cmp byte[rsi + r11],'@'	;let loop until the end (@) for now
	je .break
	
	call vmop	
	
	add rsi,16			;next op!	
	
	jmp .loop
	
	.break

	mov [.ip],rsi		;now save the state and clean up
	mov [.sp],rdi
	mov [.jp],r10
	
	ret
	.vmstate dq 0,0
	.vmtape dq 0,0
	.vmcode dq 0,0
	.ip dq 0,0
	.sp dq 0,0
	.jp dq 0,0

vmop:
	xor rbx,rbx
	mov bl,byte[rsi + r11]
	xor rcx,rcx
	
	.loop
	cmp byte[rcx + optab],'*'
	je .err
	cmp bl,byte[rcx + optab]
	je .runop
	add rcx,5
	jmp .loop
		
	.runop
	call [optab + rcx + 1]
	jmp .done
	
	.err
	.done
	ret
	
optab:				;Table of opcodes and their handlers
	db 0
	dq movop
	db '*****'

	;; Opcode case parser tables
r_casetab:			;Read case parsers
	db 0
	dq r_sp0p
	db 1
	dq r_sp1p
	db 2
	dq r_ipp
	db 3
	dq r_jsp
	db 4
	dq r_nump

	db 5
	dq r_sp0n
	db 6
	dq r_sp1n
	db 7
	dq r_ipn
	db 8
	dq r_jsn
	db 9
	dq r_numn
	db '*****'

	;; Opcode Handlers
movop:
	push rsi
	add rsi,1
	call r_case
	call getregs
	pop rsi
	ret

	;; Case Parsers
	;; returns:
	;; rax: address or num(only on case 9)
	;; bl: flag (A for address N for num E for ERROR!!!)
r_case:			;rsi - ip for opcode case and (if) arg, returns eax with the output
	mov bl,byte[rsi + r11]
	xor rcx,rcx
	
	.loop
	cmp byte[rcx + r_casetab],'*'
	je .err
	cmp bl,byte[rcx + r_casetab]
	je .docase
	add rcx,9
	jmp .loop

	.docase
	mov bl,'A'
	xor rax,rax
	call [rcx + r_casetab + 1]
	jmp .done
	
	.err
	mov bl,'E'
	.done
	ret
	
r_sp0p:
	mov eax,[rdi + r12]
	ret
r_sp1p:
	ret
r_ipp:
	mov eax,[rsi + r11]
	ret
r_jsp:
	mov eax,[r10 + r12]
	ret
r_nump:
	push rcx
	mov ecx,[rsi + r11 + 1]
	mov eax,[ecx]
	pop rcx
	ret

r_sp0n:
	mov eax,edi
	ret
r_sp1n:
	ret
r_ipn:
	mov eax,esi
	ret
r_jsn:
	mov eax,r10		;TODO: make this assemble
	ret
r_numn:
	mov eax,[rsi + r11]
	mov bl,'N'
	ret