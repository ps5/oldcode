code	segment
	assume	cs:code,ds:code,es:code
	org	0

NewSeg	equ	60h
;NewSeg	equ	cs	; For TD

BGcxLOC	equ	09h
BGdxLOC	equ	80h

Boot	proc	far
start:
	jmp	BootCode
;	jmp	Begin	; For TD
	db	90h
	db	'MSDOS5.0'
	db	0,2,4,1,0,2
	db	0,2,0,0,0F8h,0F9h
	db	0,11h,0,0Fh,0,11h
	db	0,0,0,7,0E4h,3
	db	0,80h,0,29h,0A0h,28h
	db	3Ah,1Bh
	db	'MS-DOS_5   FAT16   '

BootCode:
	mov	si,7C00h
	cli
	xor	ax,ax
	mov	ss,ax
	mov     sp,si
	sti
	mov	ds,ax

	mov	ax,NewSeg
	mov	es,ax
	xor	di,di
	mov	ax,offset Begin
	push	es
	push	ax
	mov	cx,100h
	cld
	rep	movsw
	db	0CBh		; Переход на 60:xxx - Begin

MemorySize	dw	280h	; 640 Kb

Begin:
	mov	bx,word ptr ds:[0413h]	; ds=ss=0 / cs=es=NewSeg
	push	cs
	pop	ds
	mov	si,offset _CopyRight
	call	OutLine

	; *** Проверить память ***
	mov	si,offset _TestMemory
	call	OutScreen

	cmp	bx,word ptr ds:[offset MemorySize]
	jne	MemoryNotOK
	call	TypeOK
	jmp	CheckMBR

MemoryNotOK:
	call	TypeChanged

	; *** Проверить MBR ***
CheckMBR:
	call	Overlay

	mov	si,offset _TestMBR
	mov	dx,80h
	call	ReadToBuf
	mov	si,512
	call	Compare
	jnc	CheckBoot

MBRNotOK:
	mov	bp,512
	call	Complex
	jne	CheckBoot

	mov	dx,80h
	call	WriteFromBuf
	jmp	Reboot

	; *** Проверить Boot ***
CheckBoot:
	mov	si,offset _TestBoot
	mov	dx,0180h
	call	ReadToBuf
	xor	si,si			; Сравнить с собой
	call	Compare
	jnc	CheckComplete

BootNotOK:
	mov	bp,1024
	call	Complex
	jne	CheckComplete

	mov	dx,0180h
	xor	bp,bp
	call	WriteFromBuf
Reboot:
	db	0EAh
	dw	00000h
	dw	0FFFFh
CheckComplete:
	mov	dx,BGdxLOC
	mov	cx,BGcxLOC+2		; Boot Sector
	xor	bx,bx
	mov	es,bx
	push	es
	mov	bx,7C00h
	push	bx
	mov	ax,0201h
	call	Abs13h
	db	0CBh		; Far Ret to begin of Boot - 0:7C00h

Boot	endp

Complex	proc	near
	call	AskRestore
	je	ComplexComplete
	call	AskSetNew	; Запрос: Запомнить новое ?
	jne	ComplexComplete

	mov	di,bp
	call	MoveSave
	cmp	di,bp
ComplexComplete:
	ret
Complex	endp

MoveSave	proc	near
	cld
	mov	si,1536
	mov	cx,100h
	rep	movsw
	call	SaveNewer
	ret
MoveSave	endp

Compare	proc	near
	mov	cx,200h
	mov	di,1536
	rep	cmpsb
	je	CompareOK
	call	TypeChanged
	stc
	db	0C3h
CompareOK:
	call	TypeOK
	clc
	ret
Compare	endp

ReadToBuf	proc	near
	call	OutScreen
	mov	ax,0201h
	mov	bx,1536
	jmp	inWriteFromBuf
ReadToBuf	endp

WriteFromBuf	proc	near
	mov	ax,0301h
	mov	bx,bp
inWriteFromBuf:
	mov	cx,1
	call	Abs13h
	ret
WriteFromBuf	endp

SaveNewer	proc	near
	mov	cx,BGcxLOC
	mov	dx,BGdxLOC
	mov	ax,0303h
	xor	bx,bx
	call	Abs13h
	ret
SaveNewer	endp

Overlay	proc	near
	mov	cx,BGcxLOC+1
	mov	dx,BGdxLOC
	mov	ax,0202h
	mov	bx,512
	call	Abs13h
	ret
Overlay	endp

AskRestore	proc	near
	mov	si,offset _Restore
AskContinue:
	call	OutScreen
GetKey:
	xor	ax,ax
	int	16h
	push	ax
	call	Int10h
	mov	si,offset _CR
	call	OutScreen
	pop	ax
	cmp	al,'y'
	je	AskRestoreComplete
	cmp	al,'Y'
AskRestoreComplete:
	ret
AskRestore	endp

AskSetNew	proc	near
	mov	si,offset _SetNew
	jmp	AskContinue
AskSetNew	endp

TypeChanged	proc	near
	mov	si,offset _Changed
	jmp	inTypeOK
TypeChanged	endp

TypeOK	proc	near
	mov	si,offset _OK
inTypeOK:
	call	OutLine
	ret
TypeOk	endp

OutLine	proc	near
	call	OutScreen
	mov	si,offset _CR
	call	OutScreen
	ret
OutLine	endp

OutScreen	proc	near
	cld
	lodsb
OutNext:
	call	Int10h
	lodsb
	cmp	al,0
	jne	OutNext
	ret
OutScreen	endp

Int10h	proc	near
	push	bx
	mov	ah,0Eh
	mov	bx,7
	int	10h
	pop	bx
	ret
Int10h	endp

Abs13h	proc	near
	push	bp
	mov	bp,5
	push	ax
TryAbs13h:
	pop	ax
	push	ax
	call	BIOS13h
	jnc	Abs13hComplete
	xor	ax,ax
	call	BIOS13h
	dec	bp
	jnz	TryAbs13h
	stc
Abs13hComplete:
	pop	ax
	pop	bp
	ret
Abs13h	endp

BIOS13h	proc	near
	pushf
	db	9Ah
o13	dw	0ABB5h
s13	dw	0F000h
	ret
BIOS13h	endp

_CopyRight	db	'Boot Guard  v2.0',0
_TestMemory	db	'MemSize: ',0
_TestMBR	db	'MBR: ',0
_TestBoot	db	'Boot: ',0

_OK		db	'Ok',0
_Changed	db	'CHANGED',7,0
_CR		db	0Dh,0Ah,0

_Restore	db	'Restore ?',0
_SetNew		db	'Save new?',0

Sign		dw	0AA55h

code		ends

		end	start
