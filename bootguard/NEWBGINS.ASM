code	segment
	assume	cs:code,ds:code
	org	100h

EAttr	equ	28
Attr	equ	31
InvAttr	equ	113

Pavel	proc	near
start:
	mov	ah,3
	mov	dh,0
	int	10h
	mov	cs:CurPos,dx
	mov	cs:CurSiz,cx

	mov	ah,1
	mov	cx,2000h
	int	10h

	call	_Title
	jc	Yes
quit:
	mov	ah,1
	mov	cx,cs:CurSiz
	int	10h

	mov	ah,2
	mov	bh,0
	mov	dx,cs:CurPos
	int	10h

	mov	ax,4C00h
	int	21h

CurPos	dw	0
CurSiz	dw	0

Yes:
	call	Get13
	mov	cs:i13o,ax
	mov	cs:i13s,dx
	cmp	ax,dx
	jne	okk
	cmp	ax,0
	jne	okk
	jmp	err_1		; Если вектор не определен.
okk:
	push	cs
	pop	ds
	push	cs
	pop	es

	mov	bx,offset Body + 1AEh	; Смещение CALL far C800:0256
	mov	es:[bx],ax	;     смещение
	mov	es:[bx+2],dx	;     сегмент

; Сохранить старый Boot
	mov	ax,0201h
	mov	bx,offset Buffer
	mov	cx,1
	mov	dx,0180h
	call	i13
	jnc	no_error_1
	jmp	error

no_error_1:
	call	CheckAlreadyInstalled
	jne	no_error_2
	jmp	AlreadyInstalled

no_error_2:
	mov	ax,0301h
	mov	bx,offset Buffer
	mov	cx,011
	mov	dx,80h
	call	i13
;	jc	error

; Сохранить MBR
	mov	ax,0201h
	mov	bx,offset Buffer
	mov	cx,1
	mov	dx,80h
	call	i13
	jc	error

	mov	ax,0301h
	mov	bx,offset Buffer
	mov	cx,010
	mov	dx,80h
	call	i13
;	jc	error


; Записать новый Boot
	
	mov	ax,0201h
	mov	bx,offset buffer
	call	i13
	jc	error

	mov	si,offset buffer + 2	; Отступ от JMP
	mov	di,offset Body + 2
	mov	cx,60

	cld
	rep	movsb

	mov	ax,0301h		; Записать
	mov	bx,offset Body
	mov	cx,1
	mov	dx,0180h
	call	i13
;	jc	error

	mov	ax,0301h
	mov	bx,offset Body
	mov	cx,9
	mov	dx,80h
	call	i13
;	jc	error


	mov	si,offset E0
	mov	dx,0A01h
	mov	bl,Attr
	call	_Type
	jmp	quit
err_1:
	mov	si,offset E1
	mov	dx,0A01h
	mov	bl,EAttr
	call	_Type	
	jmp	Err_E
error:
	mov	si,offset E2
	mov	dx,0A01h
	mov	bl,EAttr
	call	_Type
Err_E:
	mov	si,offset EE
	mov	dx,0B01h
	mov	bl,EAttr
	call	_Type
	jmp	quit

AlreadyInstalled:
	mov	si,offset E3
	mov	dx,0A01h
	mov	bl,EAttr
	call	_Type
	mov	si,offset E4
	mov	dx,0B01h
	mov	bl,EAttr
	call	_Type
	jmp	quit

i13	proc	near
	mov	bp,5
	push	ax
Try:
	pop	ax
	push	ax
	call	Abs13h
	jnc	i13Complete

	xor	ax,ax
	call	Abs13h

	dec	bp
	jnz	Try
	stc
i13Complete:
	pop	ax
	ret
i13	endp

Abs13h	proc	near
	pushf
	db	9ah
i13o	dw	256h
i13s	dw	0c800h
	ret
Abs13h	endp

CheckAlreadyInstalled	proc	near
	cld
	mov	si,offset Buffer + 62
	mov	di,offset Body + 62
	mov	cx,450
	rep	cmpsb
	ret
CheckAlreadyInstalled	endp

Ttl	db	'╔═════════════════════════════════════════════════════════════════════════════╗',13,10
	db	'║ Boot Guard  version 2.0                              (C) Shiryaev P.A. 1993 ║',13,10
	db	'╟─────────────────────────────────────────────────────────────────────────────╢',13,10
	db	'║   AMY Boot Guard ▄ - это специальная антивирусная программа, предохраняющая ║',13,10
	db	'║    ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀   жесткий диск ("винчестер") от заражения boot-вирусами. ║',13,10
	db	'║                      Программа замещает собой  типовую  загрузочную  запись ║',13,10
	db	'║ (Boot сектор). При заражении компьютера boot-вирусом (Stoned, Asuca и др.), ║',13,10
	db	'║ программа восстановит MBR и Boot,  используя абсолютный доступ к BIOS,  что ║',13,10
	db	'║ обеспечивает 100% гарантию уничтожения вируса.                              ║',13,10
	db	'║                                                                             ║',13,10
	db	'║        Инсталлировать Boot Guard ?                                          ║',13,10
	db	'║                                                                             ║',13,10
	db	'╚═════════════════════════════════════════════════════════════════════════════╝',0
E0	db	 '        Boot Guard успешно инсталлирован.  Всего Вам доброго !              ',0
E2	db	 'Ошибка установки Boot Guard !  Вероятно, неверно определен абсолютный вектор',0
EE	db	 '                 Удалите резидентов и попробуйте еще раз.                   ',0
E1	db	 '             Ошибка определения абсолютного вектора Int 13h !               ',0
E3	db	 '            Boot Guard уже инсталлирован на Вашем компьютере !              ',0
E4	db	 '                Установка не требуется. Всего Вам доброго !                 ',0
String_1	db	16,' Yes ',17,0
String_2	db	16,' No ',17,0

pavel	endp

_Title	proc	near

	push	cs
	pop	ds

	mov	si,offset Ttl
	mov	bx,Attr	; BH: page, BL: Attr
	xor	dx,dx
        call	_Type

WaitKey:
	mov	dx,0A2Ch

	mov	bl,Attr
	cmp	cs:YesNo,0
	je	No_1
	mov	bl,InvAttr
No_1:
	mov	si,offset String_1
	call	_Type

	mov	dx,0A35h

	mov	bl,Attr
	cmp	cs:YesNo,0
	jne	No_2
	mov	bl,InvAttr
No_2:
	mov	si,offset String_2
	call	_Type

ReadKey:
	mov	ah,0
	int	16h

	cmp	ax,4B00h
	je	Change
	cmp	ax,4D00h
	je	Change
	cmp	ax,011Bh
	je	Escape
	cmp	ax,1C0Dh
	je	kEnter
	jmp	ReadKey
Change:
	xor	cs:YesNo,1
	jmp	WaitKey
Escape:
	clc
	ret
kEnter:
	cmp	cs:YesNo,0
	je	Escape
	stc
	ret
_Title	endp

_Type   proc    near		; BH - video page
				; BL - attribute
				; DX - cursor
                                ; DS:SI - ASCIIZ string
	xor	bh,bh
	mov	ax,0500h
	int	10h	
Loc_1:
	mov	ah,2
	push	bx
	int	10h
	pop	bx

	lodsb
        cmp	al,0
        jz	_All

	cmp	al,13
	jnz	Not_13
	xor	dl,dl
	jmp	Loc_1
Not_13:
	cmp	al,10
	jnz	Not_10
	inc	dh
	jmp	Loc_1
Not_10:
	mov	cx,1
	mov	ah,9
	int	10h
	inc	dl
	jmp	Loc_1
_All:
	ret
_Type	endp

YesNo	db	0

Body:

include Body.inc

Buffer	db	0

include Get13.inc

code	ends
	end	start
