emrpage dq 0
emradrs dq 0

initemr:
	call malocbig
	mov [emrpage],rbx
	mov [emradrs],rax
	mov rsi,rax
	mov rdi,rsi
	add rdi,1024
	xor rax,rax
	mov bl,1
.loop
	call getrnd16
	div bl
	add dl,'0'
	mov al,dl
	call cprint
	add rsi,1
	cmp rsi,rdi
	jge .done
	inc rsi
	jmp .loop
.done
ret

stepemr:
	
ret