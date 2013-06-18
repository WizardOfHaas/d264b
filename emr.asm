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
.done
ret

stepemr:
	
ret