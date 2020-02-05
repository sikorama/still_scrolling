
DATA_START: EQU #8000
ENTRY_POINT: EQU #9000

; 0: mode normal
; 1: utilise le code dans le header
PRODMODE: EQU 0

ORG #4000

if PRODMODE==0
		include "header.asm"
else
		GET_FONT EQU 0
		
		 ld hl,(#be7d) 
		 ld bc,#12A
		 add hl,bc
		 ld (getfont+1), hl
		 ld bc, 20
		 add hl,bc
		 ld (literal+1),hl
endif	

START:		
		; Desactive ITs et Sauvegarde des registres Mirroir		
if PRODMODE == 0				
		ld a,(#a000)
		;ld (dupa00+1),a
		cp #55
		push af
		call nz,CHECK_CRTC ; Si crtc 1 ou 2 on quitte			
		;call GET_FONT	
		; recup fonte systeme (avec des appels systeme, donc fait avant la decompressoin
		GET_CARACT_TAB #A06B,63
		; desactivation ITs
		DI						
		DISABLE_INT38
		
		ld bc,#7f00
		out (c),c
		ld a,GA_BLACK
		out (c),a		
		
else
		getfont:		call GET_FONT
endif	
		LD 		IX,CRUNCH_DATA
		LD  	DE,DATA_START
		; décompression
		call shrinkler_decrunch

		; On verifie si c'est un CPC +
		; sauf si on a a pas testé les CRTC 1 et 2		
;dupa00:	ld a,0
		;cp #55
		pop af
		jr z,go
		
		; On lit #Be00, si 'est différent de 255 on 
		LD      b,#BE
		IN      A,(C)
		inc A		
		jr Z, go
		; on a un CPC+
		
		ld bc,#BC8d
		ld a,3
		out (c),a
		inc b		
		out (c),c
		inc a
		ld (#9504),a ; adresse du label AJUSTE_PLUS, on met 4
		
		; GO!
go:
		JP	ENTRY_POINT

CRUNCH_DATA:
		INCBIN "crunched.bin"

READ "Shrinkler_Z80_v8__(Madram)__recall_209.asm"
