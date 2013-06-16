shell:
	mov rsi,.prmpt
	call sprint
	mov rdi,buffer
	call input

	mov rsi,cmdstrings
	mov rdi,buffer
.loop
	call compare
	jc .docmd
	add rsi,16
	cmp rsi,endcmds
	jge .done
	push rsi
	push rdi
	call getregs
	pop rdi
	pop rsi
	jmp .loop
.docmd
	mov rax,[rsi + 8]
	call rax
.done
ret
	.prmpt db '?>',0

helpcmd:
	mov rsi,.hlp0
	call sprint
ret
	.hlp0 db 'help - this',0

cmdstrings:
help:
	db 'help',0,0,0,0
	dq helpcmd
endcmds: db '****'