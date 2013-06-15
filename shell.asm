shell:
	mov rsi,.prmpt
	call sprint
	mov rdi,buffer
	call input

	mov rsi,cmdstrings
	mov rdi,buffer
.loop		;;;;;;;AROUND HERE! ITS FUCKED UP!!!
	call compare
	jc .docmd
	add rsi,16
	cmp rdi,endcmds
	jge .done
	jmp .loop
.docmd
	mov rax,[rsi + 8]
	call getregs
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
endcmds: