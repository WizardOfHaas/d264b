USE64
[ORG 0x0000000000100000]

start:
	call clearscreen

	mov rsi,splash
	call sprint
	call getregs

	mov eax,0
	cpuid
	mov [vinfo],ebx
	mov [vinfo + 4],edx
	mov [vinfo + 8],ecx
	mov rsi,vinfo
	call sprint
	call newline

	call initmm

	call initemr
end:
	call shell
jmp end

db 'For Jamie'
buffer times 256 db 0
vinfo times 16 db 0
splash db 'd264b - Built with Dreckig OS Technology',13,'copyright 2013-2015 Sean Haas',13,0
xpos db 0
ypos db 0

%include 'memc.asm'
%include 'emr.asm'
%include 'shell.asm'

clearscreen:
	xor ax,ax
	mov rsi,0xB8000
	mov rdi,0xB8800
	call fillmem
.done
	mov byte[xpos],0
	mov byte[ypos],0
ret

sprint:
.loop
	mov al,[rsi]
	cmp al,0
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
ret

inccurs:
	mov ah,byte[xpos]
	mov al,byte[ypos]
	
	cmp al,24
	jg .scroll

	cmp ah,80
	jge .incy
	add byte[xpos],1
	jmp .done
.scroll
	call scrollup
	sub byte[ypos],1
	jmp .done
.incy
	mov byte[xpos],0
	cmp byte[ypos],24
	jg .scroll
	add byte[ypos],1
.done
ret

scrollup:
	mov rax,4000
	mov rsi,0xB80A0
	mov rdi,0xB8000
	call movemem
ret

cprint:
	push rdi
	mov ah,0x02
	mov ecx,eax
	movzx eax,byte[ypos]
	mov edx,160
	mul edx
	movzx ebx,byte[xpos]
	shl ebx,1

	mov edi,0xB8000
	add edi,eax
	add edi,ebx

	mov eax,ecx
	mov word[ds:edi],ax
	call inccurs
.done
	pop rdi
ret

getregs:
	mov r8,rax
	mov r9,rbx
	mov r10,rcx
	mov r11,rdx
	mov r12,rsi
	mov r13,rdi
	mov word[.reg + 2],'ax'
	mov rsi,.reg
	call sprint
	mov rax,r8
	call iprint
	mov byte[.reg + 2],'b'
	mov rsi,.reg
	call sprint
	mov rax,r9
	call iprint
	mov byte[.reg + 2],'c'
	mov rsi,.reg
	call sprint
	mov rax,r10
	call iprint
	mov byte[.reg + 2],'d'
	mov rsi,.reg
	call sprint
	mov rax,r11
	call iprint
	mov word[.reg + 2],'si'
	mov rsi,.reg
	call sprint
	mov rax,r12
	call iprint
	mov byte[.reg + 2],'d'
	mov rsi,.reg
	call sprint
	mov rax,r13
	call iprint
	call newline
ret
	.reg db ' rax:',0

iprint:		;rax - int to print
	call itoa
	call sprint
ret

itoa:		;IN - rax - int, OUT - rsi, string
	mov rdi,.tmp
	call tostring
	mov rsi,.tmp
ret
	.tmp times 32 db 0

tostring:		;RAX - int, RDI - string out
	push rdx
	push rcx
	push rbx
	push rax

	mov rbx, 10					; base of the decimal system
	xor ecx, ecx					; number of digits generated
.os_int_to_string_next_divide
	xor edx, edx					; RAX extended to (RDX,RAX)
	div rbx						; divide by the number-base
	push rdx					; save remainder on the stack
	inc rcx						; and count this remainder
	cmp rax, 0					; was the quotient zero?
	jne .os_int_to_string_next_divide		; no, do another division

.os_int_to_string_next_digit
	pop rax						; else pop recent remainder
	add al, '0'					; and convert to a numeral
	stosb						; store to memory-buffer
	loop .os_int_to_string_next_digit		; again for other remainders
	xor al, al
	stosb						; Store the null terminator at the end of the string

	pop rax
	pop rbx
	pop rcx
	pop rdx
ret

toint:		;RSI - string, RAX - int out!
	push rsi
	push rdx
	push rcx
	push rbx

	xor eax, eax			; initialize accumulator
	mov rbx, 10			; decimal-system's radix
.os_string_to_int_next_digit:
	mov cl, [rsi]			; fetch next character
	cmp cl, '0'			; char preceeds '0'?
	jb .os_string_to_int_invalid	; yes, not a numeral
	cmp cl, '9'			; char follows '9'?
	ja .os_string_to_int_invalid	; yes, not a numeral
	mul rbx				; ten times prior sum
	and rcx, 0x0F			; convert char to int
	add rax, rcx			; add to prior total
	inc rsi				; advance source index
	jmp .os_string_to_int_next_digit	; and check another char
	
.os_string_to_int_invalid:
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	ret

newline:
	mov byte[xpos],0
	add byte[ypos],1
ret

getkey:		;OUT - al, key pressed
	xor rax,rax
	in al,0x64
	test al,01b
	jz getkey
	in al,0x60

	cmp al,0x2A
	je .shifton
	cmp al,0x36
	je .shifton
	cmp al,0xAA
	je .shiftoff
	cmp al,0xB6
	je .shiftoff

	or al,al
	jz getkey
	jmp .keydown
.shifton
	mov byte[.shift],1
	jmp getkey
.shiftoff
	mov byte[.shift],0
	jmp getkey
.keydown
	cmp byte[.shift],1
	je .shifted
	mov rbx,keylayoutlower
	jmp .shiftless
.shifted
	mov rbx,keylayoutupper
.shiftless
	add rbx,rax
	mov bl,[rbx]
	mov [key],bl
	mov al,[key]
	jmp .done
.done
ret
	.shift db 0

input:		;rdi - string to typietype into
.loop
	call getkey
	cmp al,0
	je .loop
	cmp al,0x1C
	je .done
	cmp al,0x0E
	je .back
	mov byte[rdi],al
	call cprint
	add rdi,1
	jmp .loop
.back
	dec rdi
	dec byte[xpos]
	jmp .loop
.done
	mov byte[rdi],0
	call newline
ret

getinput:
	push rdi
	call sprint
	pop rdi
	call input
ret

compare:	;Compares string in rsi to rdi. stc if equal
	push rdi
	push rsi
	push rax
.loop
	mov al,byte[rsi]
	mov ah,byte[rdi]
	cmp al,ah
	jne .no
	cmp al,0
	je .equal
	inc rdi
	inc rsi
	jmp .loop
.no
	clc
	jmp .done
.equal
	stc
.done
	pop rax
	pop rsi
	pop rdi
ret

getrnd:			;OUT - rax, rnd number
	xor rax,rax
	call getrnd16
	shl rax,16
	call getrnd16
	shl rax,16
	call getrnd16
	call iprint
	call newline
ret

getrnd16:
	cli			;OUT - ax, random number
	mov al,00000000b
	out 0x43,al
	in al,0x40	
	mov ah,al
	in al,40h
	xor al,ah
	sti
ret

key db 0
keylayoutlower:
	db 0x00, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0x0e, 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0x1c, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',';', 0, '`', 0, 0, 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' ', 0
keylayoutupper:
	db 0x00, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0x0e, 0, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 0x1c, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', 0, '~', 0, 0, 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' ', 0
	;;  0e = backspace
	;;  1c = enter
	
void: