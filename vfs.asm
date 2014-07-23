	db 'vfs.asm'

	vfsadrs dq 0
	vfspage dq 0

	diskbuf dq 0
	fatbuf dq 0
	
	fat_start dw 0

	fat_root_ents db 0,0
	fat_size db 0,0
	fat_reserved db 0,0
	fat_root_start dw 0,0
	fat_data_start dw 0,0
	fats db 0,0	
	
initvfs:
	mov rsi,.msg
	call sprint

	call malocbig
	mov [fatbuf],rax
	
	call malocbig		;First.... lets get the MBR data and grab info for the first partition.....
	mov [diskbuf],rax
	mov rdi,rax
	xor rax,rax
	call readsector

	mov rdi,[diskbuf]
	mov eax,[rdi + 0x01C6]
	mov [fat_start],eax

	mov rdi,[diskbuf]
	call readsector

	xor rax,rax
	mov rdi,[diskbuf]
	mov ax,[rdi + 0x11]
	mov [fat_root_ents],ax
	mov ax,[rdi + 0x16]
	mov [fat_size],ax
	mov al,[rdi + 0x10]
	mov [fats],al
	mov ax,[rdi + 0x0E]
	mov [fat_reserved],ax
	
	xor rax,rax		;Not calcing root entry location right
	xor rbx,rbx
	mov ax,[fat_size]
	shl ax,1
	add ax,[fat_reserved]
	add ax,[fat_start]	
	mov [fat_root_start],eax

	
	mov bx,[fat_root_ents]
	shr ebx,4
	add ebx,eax
	mov [fat_data_start],ebx
	
	mov rdi,[fatbuf]
	call readsector

	mov rsi,.ok
	call sprint
	
	ret
	.msg db 'Initializing VFS...',0
	.ok db '[ok]',13,0
	
; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2009 Return Infinity -- see LICENSE.TXT
;
; Hard Drive Functions
; =============================================================================
; NOTE:	These functions use LBA28. Maximum visible drive size is 128GiB
;	LBA48 would be needed to access sectors over 128GiB (up to 128PiB)


; -----------------------------------------------------------------------------
; readsector -- Read from a sector on the hard drive
; IN:	RAX = sector to read
;	RDI = memory location to store sector (512 Bytes)
; OUT:	RAX = next sector
;	RDI = RDI + 512
;	All other registers preserved
readsector:
	push rdx
	push rcx
	push rax

	push rax		; Save RAX since we are about to overwrite it
	mov dx, 0x01F2		; Sector count Port 7:0
	mov al, 1		; Read one sector, a value of 0 here would read 256 sectors
	out dx, al
	pop rax			; Restore RAX which is our sector number
	inc dx			; 0x01F3 - LBA Low Port 7:0
	out dx, al
	inc dx			; 0x01F4 - LBA Mid Port 15:8
	shr rax, 8
	out dx, al
	inc dx			; 0x01F5 - LBA High Port 23:16
	shr rax, 8
	out dx, al
	inc dx			; 0x01F6 - Device Port. Bit 6 set for LBA mode, Bit 4 for device (0 = master, 1 = slave), Bits 3-0 for LBA "Extra High" (27:24)
	shr rax, 8
	and al, 00001111b 	; Clear bits 4-7 just to be safe
	or al, 01000000b	; Turn bit 6 on since we want to use LBA addressing, leave device at 0 (master)
	out dx, al
	inc dx			; 0x01F7 - Command Port
	mov al, 0x20		; Read sector(s). 0x24 if LBA48
	out dx, al

readsector_wait:		; VERIFY THIS
	in al, dx
	test al, 8		; This means the sector buffer requires servicing.
	jz readsector_wait	; Don't continue until the sector buffer is ready.
	mov rcx, 256		; One sector is 512 bytes but we are reading 2 bytes at a time
	mov dx, 0x01F0		; Data port - data comes in and out of here.
	rep insw		; Read data to the address starting at RDI

	pop rax
	add rax, 1		; Point to the next sector
	pop rcx
	pop rdx
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; writesector -- Write to a sector on the hard drive
; IN:	RAX = sector to write
;	RSI = memory location of data to write (512 Bytes)
; OUT:	RAX = next sector
;	RSI = RSI + 512
;	All other registers preserved
writesector:
	push rdx
	push rcx
	push rax

	push rax		; Save RAX since we are about to overwrite it
	mov dx, 0x01F2		; Sector count Port 7:0
	mov al, 1		; Write one sector, a value of 0 here will write 256 sectors
	out dx, al
	pop rax			; Restore RAX which is our sector number
	inc dx			; 0x01F3 - LBA Low Port 7:0
	out dx, al
	inc dx			; 0x01F4 - LBA Mid Port 15:8
	shr rax, 8
	out dx, al
	inc dx			; 0x01F5 - LBA High Port 23:16
	shr rax, 8
	out dx, al
	inc dx			; 0x01F6 - Device Port. Bit 6 set for LBA mode, Bit 4 for device (0 = master, 1 = slave), Bits 3-0 for LBA "Extra High" (27:24)
	shr rax, 8
	and al, 00001111b 	; Clear bits 4-7 just to be safe
	or al, 01000000b	; Turn bit 6 on since we want to use LBA addressing, leave device at 0 (master)
	out dx, al
	inc dx			; 0x01F7 - Command Port
	mov al, 0x30		; Write sector(s). 0x34 if LBA48
	out dx, al

writesector_wait:		; VERIFY THIS
	in al, dx
	test al, 8		; This means the sector buffer requires servicing.
	jz writesector_wait	; Don't continue until the sector buffer is ready.
	mov rcx, 256		; One sector is 512 bytes but we are writing 2 bytes at a time
	mov dx, 0x01F0		; Data port - data comes in and out of here.
	rep outsw		; Write data from the address starting at RSI

	pop rax
	add rax, 1		; Point to the next sector
	pop rcx
	pop rdx
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; readsectors -- Read sectors on the hard drive
; IN:	RAX = starting sector to read
;	RCX = number of sectors to read (1 - 256)
;	RDI = memory location to store sectors
; OUT:	RAX = RAX + number of sectors that were read
;	RCX = number of sectors that were read (0 on error)
;	RDI = RDI + (number of sectors * 512)
;	All other registers preserved
readsectors:
	push rdx
	push rcx
	push rax

	push rcx		; Save RCX for use in the read loop
	cmp rcx, 256
	jg readsectors_fail	; Over 256? Fail!
	jne readsectors_skip	; Not 256? No need to modify CL
	mov cl, 0		; 0 translates to 256
readsectors_skip:

	push rax		; Save RAX since we are about to overwrite it
	mov dx, 0x01F2		; Sector count Port 7:0
	mov al, cl		; Read CL sectors
	out dx, al
	pop rax			; Restore RAX which is our sector number
	inc dx			; 0x01F3 - LBA Low Port 7:0
	out dx, al
	inc dx			; 0x01F4 - LBA Mid Port 15:8
	shr rax, 8
	out dx, al
	inc dx			; 0x01F5 - LBA High Port 23:16
	shr rax, 8
	out dx, al
	inc dx			; 0x01F6 - Device Port. Bit 6 set for LBA mode, Bit 4 for device (0 = master, 1 = slave), Bits 3-0 for LBA "Extra High" (27:24)
	shr rax, 8
	and al, 00001111b 	; Clear bits 4-7 just to be safe
	or al, 01000000b	; Turn bit 6 on since we want to use LBA addressing, leave device at 0 (master)
	out dx, al
	inc dx			; 0x01F7 - Command Port
	mov al, 0x20		; Read sector(s). 0x24 if LBA48
	out dx, al

readsectors_wait:		; VERIFY THIS
	in al, dx
	test al, 8		; This means the sector buffer requires servicing.
	jz readsectors_wait	; Don't continue until the sector buffer is ready.
	pop rcx
	shl rcx, 8		; Multiply RCX by 256 to get the amount of words that will be read
	mov dx, 0x01F0		; Data port - data comes in and out of here.
	rep insw		; Read data to the address starting at RDI

	pop rax
	add rax, rcx
	pop rcx
	pop rdx
ret

readsectors_fail:
	pop rcx
	pop rax
	pop rcx
	pop rdx
	xor rcx, rcx		; Set RCX to 0 since nothing was read
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
