	dlisptest db "(eq (+ 1 1) (+ 1 0))",0

	dlisppage dq 0
	dlispadrs dq 0
	dlisptemp dq 0

	listchar db 'cons',0
	setfchar db 'setf',0
	carchar db 'car',0
	cdrchar db 'cdr',0
	evalchar db 'eval',0
	eqchar db 'eq',0
	
rundlisp:			;rsi - string to interpret
	call validatedlisp
	cmp rax,0
	jne .err
	
	call malocbig
	mov [dlisppage],rbx
	mov [dlispadrs],rax
	mov qword[dlisptemp],rax
	call malocbig
	call malocbig

	call tokenify
	mov [.temp],rsi
	
	mov rsi,[.temp]
	call getstatement

	call eval

	cmp ax,'Ss'
	jne .int
	mov rsi,rdi
	call sprint
	jmp .outdone
	
	.int
	cmp ax,'Ll'
	je .list
	call iprint
	jmp .outdone

	.list
	mov rsi,rdi
	call listprint
	
	.outdone
	call newline
	
	mov rax,[dlisppage]
	call freebig
	add rax,1
	call freebig
	add rax,1
	call freebig
	jmp .done
.err
	mov rsi,.errmsg
	call sprint
.done
	ret
	.temp dq 0
	.errmsg db 'You done fucke up!',13,0

eval:				;rsi - tokonified dlisp to eval
	push rsi
	cmp byte[rsi],'0'
	jge .char
	cmp byte[rsi],'('
	je .parse
	cmp byte[rsi],"'"
	je .alist
	
	cmp byte[rsi],'+'
	je .sum
	cmp byte[rsi],'-'
	je .dif
	cmp byte[rsi],'*'
	je .mul
	cmp byte[rsi],'/'
	je .div

	cmp byte[rsi],"'"
	je .str
	
	jmp .done
.parse
	call getstatement
	call eval
	jmp .done

.alist
	call getlist
	mov rdi,rsi
	jmp .done
	
.str
	mov ax,'Ss'
	mov rdi,rsi
	add rdi,2
	jmp .done
	
.char
	cmp byte[rsi],'9'
	jle .num

	mov rdi,listchar
	call compare
	je .list

	mov rdi,setfchar
	call compare
	je .setf

	mov rdi,carchar
	call compare
	je .car

	mov rdi,cdrchar
	call compare
	je .cdr
	
	mov rdi,evalchar
	call compare
	je .evalcmd

	mov rdi, eqchar
	call compare
	je .eq
	
	jmp .done
	
.num
	call toint
	jmp .done

.eq	
	add rsi,3	
	call eq
	jmp .done
	
.evalcmd
	add rsi,5
	call dump		;This is for testing
	call eval
	jmp .done
	
.setf
	
	jmp .done

.car
	add rsi,4
	call eval
	mov rsi,rdi

	mov rdi,[dlisptemp]
	push rdi
	call copystring
	
	call strlength
	add [dlisptemp],rax
	add rdi,rax
	mov byte[rdi + 1],254
	mov rax,2
	add [dlisptemp],rax
	
	pop rdi
	mov ax,'Ll'
	jmp .done

.cdr
	add rsi,4
	call eval
	mov rsi,rdi

	call counttokens
	cmp rax,1
	je .cdr1

	call strlength
	add rsi,rax
	add rsi,1
	mov rdi,rsi
	
	mov ax,'Ll'
	jmp .done
.cdr1
	push rsi
	call strlength
	add rsi,rax
	mov byte[rsi + 1],254
	pop rdi
	
	mov ax,'Ll'
	jmp .done
	
.list
	add rsi,5
	call eval

	mov ax,'Ll'
	jmp .done
	
.sum
	add rsi,2
	call eval
	mov rbx,rax
	
	.sumloop
	cmp byte[rsi],254
	je .sumdone
	cmp byte[rsi],'('
	je .sumstatement

	call strlength
	add rsi,rax
	inc rsi
	.sumstatedone

	cmp byte[rsi],254
	je .sumdone

	push rbx
	call eval
	pop rbx
	add rbx,rax
	jmp .sumloop
.sumdone
	mov rax,rbx
	jmp .done
.sumstatement
	push rax
	call statementlength
	add rsi,rax
	add rsi,2
	pop rax
	jmp .sumstatedone
	
.mul
	add rsi,2
	call eval
	mov rbx,rax
	push rbx
	
	cmp byte[rsi],'('
	je .mulstatement
	
	call dlstrlength
	add rsi,rax
	inc rsi
	.mulstatedone
	
	call eval
	pop rbx
	mul rbx
	jmp .done
.mulstatement
	push rax
	call statementlength
	add rsi,rax
	add rsi,2
	pop rax
	jmp .mulstatedone

.div
	add rsi,2
	call eval
	mov rbx,rax
	push rbx
	
	cmp byte[rsi],'('
	je .divstatement
	
	call dlstrlength
	add rsi,rax
	inc rsi
	.divstatedone
	
	call eval
	pop rbx
	xchg rax,rbx
	div rbx
	jmp .done
.divstatement
	push rax
	call statementlength
	add rsi,rax
	add rsi,2
	pop rax
	jmp .divstatedone
	
.dif
	add rsi,2
	call eval
	mov rbx,rax
	push rbx
	
	cmp byte[rsi],'('
	je .difstatement
	
	call dlstrlength
	add rsi,rax
	inc rsi
	.difstatedone
	
	call eval
	pop rbx
	sub rbx,rax
	mov rax,rbx
	jmp .done
.difstatement
	push rax
	call statementlength
	add rsi,rax
	add rsi,2
	pop rax
	jmp .difstatedone
	
.done
	pop rsi

	push rax
	push rbx
	push rsi
	call sprint
	pop rsi
	pop rbx
	pop rax
	call getregs
	
	ret

eq:				;rsi - input (this is for the interpreter, don't call it yourself)
	call counttokens
	cmp rax,2
	je .nums
	.nvm

	call getargs
	
	call eval
	push rdi
	
	mov bl,254
	call indexof
	add rsi,rax
	inc rsi	
	call eval
	pop rsi	

	cmp ax,'Ss'
	cmp ax,'Ll'
	
	
	jmp .cmp
.nums
	cmp byte[rsi],57
	jg .nvm
	call strlength
	mov rdi,rsi
	add rdi,rax
	add rdi,1

	call compare
	jc .t
	jmp .nil	
.cmp	
	call tkcompare
	jc .t
.nil
	mov rdi,.nilchar
  	jmp .done
.t
	mov rdi,.tchar
.done
	mov rax,'Ss'
	ret
	
	.tchar db 'T',0,254
	.nilchar db 'Nil',0,254
	
tkcompare:			;Compare - but for token strings!
	push rdi
	push rsi
	push rax
	push rbx
.loop
	mov al,byte[rsi]
	mov ah,byte[rdi]
	cmp al,ah
	jne .no
	cmp al,254
	je .eq
	inc rdi
	inc rsi
	jmp .loop
.no
	clc
	jmp .done
.eq
	stc
.done
	pop rbx
	pop rax
	pop rsi
	pop rdi
	ret
	
getargs:				;rsi - token string to sperate into argument list
	;; ' a ' b ( + 1 1 ) => ' a/' b/( + 1 1)
	;; rax -> number of args
	push rsi
	xor rbx,rbx
.loop
	mov al,byte[rsi]

	cmp al,254
	je .done
	cmp al,"'"
	je .quote
	cmp al,'('
	je .stmt
	
	inc rsi
	
	jmp .loop
.stmt
	call pstmlen
	add rsi,rax
	inc rsi
	mov rdi,rsi
	inc rdi
	inc rax

	
	call memcpy
	mov byte[rsi - 1],0
	mov byte[rsi],254
	
	inc rsi
	jmp .loop
.quote
	mov al,byte[rsi + 2]
	cmp al,'('
	je .bigquote
	
	add rsi,2
	call strlength		
	add rsi,rax

	mov rdi,rsi
	add rdi,2
	mov bl,254
	call indexof
	inc rax
	inc rsi
	
	call memcpy
	mov byte[rsi],254

	inc rsi
	jmp .loop
.bigquote
	add rsi,2
	call pstmlen
	
	add rsi,rax
	inc rsi
	mov rdi,rsi
		
	mov bl,254
	call indexof
	inc rax
	inc rdi
	
	call memcpy

	mov byte[rsi],254
	inc rsi
	jmp .loop
.split
	mov byte[rsi],254
	inc rsi
	inc rbx
	jmp .loop
.done
	mov rax,rbx
	pop rsi
	ret
	
getlist:			;rsi - token string to get list from, list
	;; '(a b) 'c '(1 2 3) => (a b c 1 2 3)
	call malocbig
	mov rdi,rax
	push rax
.loop
	cmp byte[rsi],254
	je .done
	
	cmp byte[rsi],"'"
	je .quote

	cmp byte[rsi],'('
	je .eval
	
	jmp .loop
.quote
	push rsi
	cmp byte[rsi + 2],'('
	je .bigquote

	add rsi,2
	call copystring
	
	call strlength
	add rdi,rax
	add rdi,1
	mov byte[rdi],0

	pop rsi
	add rsi,rax
	add rsi,3
	jmp .loop
.bigquote
	add rsi,2
	call getstatement
	call copystatement

	pop rsi
	call statementlength
	add rsi,rax
	add rsi,2
	jmp .loop
.eval
	call eval
	call copystatement

	call statementlength
	add rsi,rax
	add rdi,rax
	add rdi,2
	call dump
	add rsi,2		;When returns has a buffer miss, fix that shit!
	jmp .loop
.done
	mov byte[rdi],254
	pop rsi
	ret
	
getstatement:			;rsi - tokonified source to get statement from, statement
	;; (+ 1 1) => ( + 1 1 ) => + 1 1
	;; ^String    ^Token       ^Statement!
	push rdi
.loop0
	cmp byte[rsi],'('
	je .next
	cmp byte[rsi],254
	je .err
	
	inc rsi
	jmp .loop0
.next
	xor rax,rax
	mov rbx,1
	add rsi,2
	mov r8,rsi
.loop1
	cmp byte[rsi],')'
	je .done
	cmp byte[rsi],'('
	je .complex
	cmp byte[rsi],254
	je .err

	inc rsi
	inc rax
	jmp .loop1
.complex
	inc rsi
	inc rbx
	inc rax
	jmp .loop1
.more
	inc rax
	inc rsi
	jmp .loop1
.err
	mov rsi,0
	ret
.done
	dec rbx
	cmp rbx,0
	jne .more
	
	mov rsi,r8
	mov rdi,[dlisptemp]
	call movemem
	mov rsi,[dlisptemp]
	mov byte[rsi + rax],254
	add rax,3
	add [dlisptemp], rax
	pop rdi
	ret

tokenify:			;rsi - string to tokenify
	cmp qword[.page],0
	je .nofree
	mov rax,[.page]
	call freebig
	
	.nofree
	mov al,' '
	call strsplit

	call malocbig
	mov [.page],rax
	mov [.adrs],rax
	mov rdi,rax
.loop
	cmp byte[rsi],254
	je .done
	
	cmp byte[rsi],'('
	je .addtok
	cmp byte[rsi],')'
	je .addtok
	cmp byte[rsi],'+'
	je .addtok
	cmp byte[rsi],'-'
	je .addtok
	cmp byte[rsi],'*'
	je .addtok
	cmp byte[rsi],'/'
	je .addtok
	cmp byte[rsi],"'"
	je .addtok
	cmp byte[rsi],' '
	je .addtok

	cmp byte[rsi],'0'
	jge .addstr

	inc rsi
	
	jmp .loop
.addtok
	mov al,byte[rsi]
	mov byte[rdi],al
	inc rdi
	mov byte[rdi],0

	inc rdi
	inc rsi
	jmp .loop
.addstr
	call copystring
	call dlstrlength
	add rsi,rax
	add rdi,rax
	mov byte[rdi],0
	
	inc rdi
	jmp .loop
.done
	mov byte[rdi],254
	mov rsi,[.adrs]
	ret
	.page dq 0
	.adrs dq 0
	
strsplit:			;rsi - string to split, al - delimiter
	push rsi
.loop
	mov ah,byte[rsi]

	cmp ah,al
	je .split
	cmp ah,0
	je .done

	inc rsi
	jmp .loop
.split
	mov byte[rsi],0
	inc rsi
	jmp .loop
.done
	mov byte[rsi],254
	pop rsi
	ret

dlstrlength:			;rsi - string to count length of
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],0
	je .done
	cmp byte[rsi],254
	je .done
	cmp byte[rsi],'0'
	jl .done

	inc rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret


strlength:			;rsi - string to count length of
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],0
	je .done

	inc rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret

indexof:			;rsi - string to count length of, bl - char
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],bl
	je .done

	inc rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret
	
statementlength:			;rsi - string to count length of
	;; I BLAME THIS FOR RUINING THE RECURSION ON CONS!!
	;;  MUST FIX!!!
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],')'
	je .done
	cmp byte[rsi],254
	je .done

	inc rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret

	
pstmlen:				;rsi - string, rax, length of statement
	push rsi
	xor rax,rax
	xor rbx,rbx
.loop
	cmp byte[rsi],'('
	je .open
	cmp byte[rsi],')'
	je .close

	cmp byte[rsi],254
	je .end
	cmp rax,0
	je .end
	
	inc rsi
	inc rbx
	jmp .loop
.open
	inc rax
	inc rbx
	inc rsi
	jmp .loop
.close
	dec rax
	inc rbx
	inc rsi
	jmp .loop

.end
	clc
	cmp rax,0
	je .done
	stc
.done
	mov rax,rbx
	pop rsi
	ret
	
counttokens:				;rsi - count tokens here
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],254
	je .done
	cmp byte[rsi],0
	je .count
	
	inc rsi
	jmp .loop
.count
	inc rsi
	inc rax
	jmp .loop
.done
	pop rsi

	ret
	
validatedlisp:				;rsi - string to validate
	push rsi
	xor rax,rax
.loop
	cmp byte[rsi],'('
	je .open
	cmp byte[rsi],')'
	je .close

	cmp byte[rsi],0
	je .done
	
	inc rsi
	jmp .loop
.open
	inc rax
	inc rsi
	jmp .loop
.close
	dec rax
	inc rsi
	jmp .loop
.done
	pop rsi
	ret

copystatement:	        	;rsi - source, sdi - dest
	push rax
.loop
	mov al,byte[rsi]
	cmp al,254
	je .done
	mov byte[rdi],al
	inc rsi
	inc rdi
	jmp .loop
.done
	mov byte[rdi + 1],254
	pop rax
	ret	

listprint:
	push rsi
.loop
	mov al,[rsi]
	cmp al,254
	je .done
	inc rsi
	cmp al,13
	je .nl
	push rsi
	call cprint
	pop rsi
	jmp .loop
.nl
	call newline
	jmp .loop
.done
	pop rsi
	ret
