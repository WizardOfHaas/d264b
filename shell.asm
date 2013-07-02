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
	jmp .loop
.docmd
	mov rax,[rsi + 8]
	call rax
.done
ret
	.prmpt db '?>',0

dumpcmd:
	mov rsi,.prmpt
	mov rdi,buffer
	call getinput
	mov rsi,buffer
	call toint
	mov rsi,rax
	call dump
ret
	.prmpt db 'adress?>',0

helpcmd:
	mov rsi,.hlp0
	call sprint
ret
	.hlp0 db 'help - this',13,'regs - dump registers',13,'dump - ram dump',13,0

cmdstrings:
help:
	db 'help',0,0,0,0
	dq helpcmd
regs:
	db 'regs',0,0,0,0
	dq getregs
dumpchar:
	db 'dump',0,0,0,0
	dq dumpcmd
emrchar
	db 'emr',0,0,0,0,0
	dq startemr
endcmds: db '****'