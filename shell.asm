shell:
	mov rsi,.prmpt
	call sprint
	mov rdi,buffer
	call input

	cmp byte[buffer],'('
	je .dlisp

	mov rsi,cmdstrings
	mov rdi,buffer
.loop
	call compare
	jc .docmd
	add rsi,16
	cmp rsi,endcmds
	jge .done
	jmp .loop
.dlisp
	mov rsi,buffer
	call rundlisp
	jmp .done
.docmd
	mov rax,[rsi + 8]
	call schedule
	call yield
.done
	mov rax,shell
	call schedule
	ret
	.prmpt db '?>',0
	
dumpcmd:
	mov rsi,.prmpt
	mov rdi,buffer
	call getinput

	mov rsi,buffer
	mov rdi,.voidchr
	call compare
	jc .void
	
	mov rsi,buffer
	call toint
	mov rsi,rax

	xor rcx,rcx
.loop
	push rsi
	push rcx
	call dump
	pop rcx
	pop rsi
	add rsi,8
	inc rcx
	cmp rcx,16
	jle .loop
	jmp .done
.void
	mov rsi,void
	xor rcx,rcx
	jmp .loop
.done
ret
	.prmpt db 'adress?>',0
	.voidchr db 'void',0

helpcmd:
	mov rsi,.hlp0
	call sprint
ret
	.hlp0 db 'help - this',13,'regs - dump registers',13,'dump - ram dump',13,'dlisp - INVOKE THE LISP!',13,0

dlispcmd:
	mov rdi,buffer
	mov rsi,.prmpt
	call getinput
	mov rsi,buffer
	call rundlisp
	ret
	.prmpt db 'DLISP>',0

cmdstrings:
clear:
	db 'clear',0,0,0
	dq clearscreen
help:
	db 'help',0,0,0,0
	dq helpcmd
dlisp:
	db 'dlisp',0,0,0
	dq dlispcmd
regs:
	db 'regs',0,0,0,0
	dq getregs
readchar:
	db 'read',0,0,0,0
	dq readcmd
flistchar:
	db 'flist',0,0,0
	dq list_files
dumpchar:
	db 'dump',0,0,0,0
	dq dumpcmd
endcmds: db '****'
