Get13	proc	far
	xor	ax,ax
	mov	ds,ax

	mov	ax,ds:[4h]	; ������� ����� 01
	mov	cs:o1,ax
	mov	ax,ds:[6h]
	mov	cs:s1,ax

	pushf			; ������ �
	pop	ax
	and	ah,0FEh
	push	ax
	popf

	cli			; ��⠭����� ����� 01
	mov	ax,offset New01
	mov	ds:[4h],ax
	mov	ax,cs
	mov	ds:[6h],ax
	sti

	pushf			; ��⠭����� �
	pop	ax
	or	ah,1
	push	ax
	popf
	
	xor	ax,ax
	mov	dx,80h
	int	13h

	cmp	cs:s13,0	; �� ��襫...
	jne	OK1
	cmp	cs:o13,0
	jne	OK1

	mov	ax,0201h
	mov	bx,offset ENND
	mov	cx,1
	mov	dx,80h
	push	cs
	pop	es
	int	13h
OK1:
	cli
	mov	cs:OKAY,1	; ��⮬���᪮� �⪫�祭��
	pushf			; ������ �
	pop	ax
	and	ah,0FEh
	push	ax
	popf

	cli			; ����⠭����� ����� 01
	xor	ax,ax
	mov	ds,ax
	mov	ax,cs:o1
	mov	ds:[4h],ax
	mov	ax,cs:s1
	mov	ds:[6h],ax

	push	cs
	pop	ds

	mov	dx,cs:s13
	mov	ax,cs:o13

	ret

s13	dw	0
o13	dw	0
o1	dw	0
s1	dw	0

oax	dw	'SP'
ods	dw	'39'
osi	dw	0

OKAY	db	0

New01:
	mov	cs:oax,ax
	mov	cs:ods,ds
	mov	cs:osi,si

	pop	si
	pop	ds

	pop	ax		; ���� T=1
	or	ah,1
	push	ax

	mov	ax,ds		; ROM ?
	cmp	ax,0BFFFh
	jb	NotROM

	push	si

	shr	si,1
	shr	si,1
	shr	si,1
	shr	si,1

	add	si,ax
	pop	si
	jc	NotROM

	mov	cs:s13,ax	; �����...
	mov	cs:o13,si
Release:
	pop	ax		; ���� T=0
	and	ah,0FEh
	push	ax
	mov	cs:OKAY,0

NotROM:	
	cmp	cs:OKAY,1
	je	Release

	push	ds	; ���� ᫥���饩 �������
	push	si

	mov	ax,ds:[si]
	cmp	al,0CDh
	je	Interrupt

All:
	mov	si,cs:osi
	mov	ds,cs:ods
	mov	ax,cs:oax
	iret

db	'PS93'

Interrupt:
	pop	si		; �������� ������� INT 13h
	add	si,2		; ����� �㦭� �� �ய�����
	push	si		; �⮡� �� ��横������.

	mov	al,ah
	xor	ah,ah
	shl	ax,1
	shl	ax,1
	mov	si,ax

	pushf			; ���࠭�� 䫠�� � T=1
	pop	ax
	or	ah,1
	push	ax

	xor	ax,ax		; ����� ���뢠���
	mov	ds,ax
	mov	ax,ds:[si+2]
	push	ax		; �������
	mov	ax,ds:[si]
	push	ax		; ���饭��
	jmp	All

ENND	db	'PAVEL Soft (C) 1993',0
Get13	endp
