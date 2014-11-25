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

casetab:			;Opcode cases and thier handlers
	db 0
	dq sp0p
	db 1
	dq sp1p
	db 2
	dq ipp
	db 3
	dq jsp
	db 4
	dq nump

	db 5
	dq sp0n
	db 6
	dq sp1n
	db 7
	dq ipn
	db 8
	dq jsn
	db 9
	dq numn
	db '*****'

	;; Opcode Handlers
movop:
	push rsi
	add rsi,1
	call getcase
	call getregs
	pop rsi
	ret

	;; Case Parsers
	;; returns:
	;; rax: address or num(only on case 9)
	;; bl: flag (A for address N for num E for ERROR!!!)
getcase:			;rsi - ip for opcode case and #
	mov bl,byte[rsi + r11]
	xor rcx,rcx
	
	.loop
	cmp byte[rcx + casetab],'*'
	je .err
	cmp bl,byte[rcx + casetab]
	je .docase
	add rcx,9
	jmp .loop

	.docase
	mov bl,'A'
	call [rcx + casetab + 1]
	jmp .done
	
	.err
	mov bl,'E'
	.done
	ret
	
sp0p:
	ret
sp1p:
	ret
ipp:
	ret
jsp:
	ret
nump:
	ret

sp0n:
	ret
sp1n:
	ret
ipn:
	ret
jsn:
	ret
numn:
	mov bl,'N'
	ret