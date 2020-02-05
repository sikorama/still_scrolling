;TODO : corriger les noms des couleurs

; NOmbre de lignes total([Reg4+ 1 ] x [Reg9+ 1])+ Reg5
; Valeur par defaut: ([38+ 1 ]x[7 + 1 ])+0) = 312
ifndef TOOBLOX_ASM
TOOBLOX_ASM EQU 1

INCLUDE "crtc.asm"
INCLUDE "gatearray.asm"

;INCLUDE "2Dengine.asm"
INCLUDE "psg.asm"
INCLUDE "keys.asm"


; Registres PPI8255

PPI_PortA 	EQU #F400 ; RW
PPI_PortB 	EQU #F500 ; Read Only
PPI_PortC 	EQU #F600 ; Write Only
PPI_CTRL 	EQU #F700 ; Registre de controle. Write Only

PPI_PortA_H EQU hi(PPI_PORTA)
PPI_PortB_H EQU hi(PPI_PORTB)
PPI_PortC_H EQU hi(PPI_PORTC)
PPI_CTRL_H 	EQU hi(PPI_CTRL)




; Test de remplissage décran 
; Ex DEST=SCREEN, FW=80,FH=25
MACRO FILLSCREEN DEST,FW,FH	
	LD HL,{DEST}
	LD A,8
@LP0	
		LD C,1
		LD D,{FH}
@LP1
			LD E,{FW}
@LP2
			LD (HL),C
			INC HL
			DEC E			
			JR nz,@LP2
	
		INC C
		DEC D		
		JR nz,@LP1

	LD DE, #800-{FW}*{FH}  
	ADD HL,DE 	
		
	DEC A		
	JR nz,@LP0
MEND

; Efface partiellement l'écran avec des points aléatoires
MACRO CLEARSCREEN numpix
	LD HL,SCREEN
	LD DE,{numpix}
	LD B,0
@lp:	
	LD (HL),B
	LD A,R	
	LD C,A
	ADD HL,BC
	LD A,H	
	OR #C0
	LD H,A	
	DEC DE
	LD A,D
	OR E	
	JR nz,@lp	
MEND

MACRO GET_CARACT_TAB DEST,NUMCARAC
	XOR A
	CALL #BBA5 ; Recupere l'adresse de la fonte
	CALL #B906  ; recupere l'état de la rom inferieures
	inc h 	   ; On passe les  32 (256=32*8) premiers caracteres
	LD DE,{DEST}
	LD BC,8*{NUMCARAC}
	LDIR
	CALL #B90C ; restaure la rom inferieure 
MEND

MACRO FILLSCREEN1 DEST,FW,FH	
	LD HL,{DEST}				
	LD A,8
@lp0	
	PUSH af			
		LD a,{FH}
@lp1
		PUSH af	
			LD a,{FW}
@lp2
			LD (HL),l
			INC HL
			DEC a			
			JR nz,@lp2
	
		POP af
		
		DEC a		
		JR nz,@lp1

;	LD de, 2048-{FW}*{FH}  
;	ADD HL,de 	
		
	POP af
	DEC a		
	JR nz,@lp0
MEND


MACRO FILLSCREEN3 DEST,FW,FH	
	LD HL,{DEST}				
	LD A,8
	LD D, #FF
	
	
@lp0	
	PUSH af			
		LD B,{FH}
@lp1		
		LD C,{FW}
@lp2
		LD A,C
		srl A
		XOR B
		AND 8
		
		JR z,@nextpix			
		LD (HL),D
@nextpix
		INC HL
		DEC C			
		JR nz,@lp2

		; 
		DEC B		
		JR nz,@lp1

;	LD de, 2048-{FW}*{FH}  
;	ADD HL,de 	
		
	POP af
	DEC a		
	JR nz,@lp0
MEND

MACRO FILLSCREEN4 DEST,FW,FH	
	LD HL,{DEST}				
	LD a,8
	LD D, #0F
		
@lp0	
	PUSH af			
		LD B,{FH}
@lp1		
		LD C,{FW}
@lp2
		LD A,C
		AND 8
		
		JR z,@nextpix			
		LD (HL),D
@nextpix
		INC HL
		DEC C			
		JR nz,@lp2

		; 
		DEC B		
		JR nz,@lp1

;	LD de, 2048-{FW}*{FH}  
;	ADD HL,de 	
		
	POP af
	DEC a		
	JR nz,@lp0
MEND



;genere une fonction nextline en fonction de la largeur de l.ecran
;CS: modifie AF, durée variable
;Devrait pouvoir etre optimisée (sans test)
MACRO NEXTLINE LW
        LD      a,h  ; h+=#800
        ADD     a,8 
        LD      h,a 
        AND     #38 
        RET     nz 	; <- RET si on n edéborde pas
        LD      a,h 
        SUB     #40 
        LD      h,a 
        LD      a,l 
        ADD     a,{LW}
        LD      l,a 
        RET     nc  ; <- RET
        INC     h 
        RES     3,H 
		ret			; <- RET
		
MEND

BIOS_SETMODE EQU #BC0E

MACRO SETMODE mode
; mode graphique 1 
	LD a,{mode}
	CALL BIOS_SETMODE
MEND

BIOS_WAIT_KEY		EQU #BB06
BIOS_WAIT_BLANK 	EQU #BD19
BIOS_RESET_AUDIO 	EQU #BCA7
BIOS_PLOT 			EQU #BBEA ; DE=X, HL=Y
BIOS_DRAW 			EQU #BBF6

SCREEN 		 		EQU #C000	

; CLAVIER

; CS: A contient le caractere tapé
MACRO WAITKEY
	CALL BIOS_WAITKEY 	
MEND

; Récupere l'etat de toutes les 'lignes' de clavier (8 touches par ligne)
; DEST est un pointeur vers 10 octets disponibles
; Recupere l'état des touches du clavier et joystick
; DEST,0,10 pour toutes les lignes
MACRO GETKBSTATE0 DEST,FIRST,NUM
	
	; TOUCHES DU CLAVIER
	LD      BC,PPI_PORTA |#0E 	; Selection registre 14 du PSG
	OUT     (C),C 
	LD      BC,PPI_PORTC |#C0  
	OUT     (C),C 		
	XOR     A 
	OUT     (C),A 	
	LD      BC,PPI_CTRL |#92 
	LD 		HL,{DEST}+{FIRST}	; On ajoute FIRST pour ne pas changer les routines clavier
	OUT     (C),C 		
	LD 		C,#40+{FIRST}
	LD 		D,{NUM}
@KBGETLINE
	LD      B,PPI_PORTC_H  	   ; Selectionne ligne de clavier
	OUT     (C),C 
	LD      B,PPI_PORTA_H 
	IN      A,(C) 
	LD 		(HL),A
	INC 	HL		
	INC 	C				   ; Ligne suivante
	DEC 	D			  	   ; On s'arrete a 10
	JR 		NZ, @KBGETLINE	
	;On desactive
	LD      BC,PPI_CTRL |#82 
	OUT     (C),C 
	LD      BC,PPI_PORTC
	OUT     (C),C 		
MEND

MACRO GETKBSTATE DEST
	GETKBSTATE0 {DEST},0,10
MEND



; --- interruptions

; Synchro ecran
MACRO WAITSYNC 
		LD      b,PPI_PortB_H
@SYNC   IN      A,(C) 
        RRA 
        JR      NC,@SYNC 
MEND

; Attente de 16*nbl cycles, 4 correspond donc a une ligne
MACRO TEMPO nbl
	LD a,{nbl}
@waitl
	ds 12
	dec a
	jr nz, @waitl
MEND
		

MACRO STORE_INT38 addr
	LD      HL,(#38) 
	LD      ({addr}),HL 
MEND		

MACRO DISABLE_INT38
	LD      HL,#c9fb	; EI + RET
	LD      (#38),HL 
MEND		


; Desactive les interruptions
MACRO DISABLE_INT addr
	DI 
	STORE_INT38	{addr}
	DISABLE_INT38
MEND

MACRO PUSH_MIRROR_REGS
	di
	exx
	push hl
	push bc
	push de
	exx
	ex AF,AF'
	PUSH AF
	ex AF,AF'
	ei
MEND

MACRO POP_MIRROR_REGS
	di
	ex AF,AF'
	POP AF
	ex AF,AF'	
	exx
	pop de
	pop bc
	pop hl
	exx
	ei
MEND



; Table des pixels pour le mode 0
MACRO PIXM0 COL2,COL1
	({COL1}&8)/8 | (({COL1}&4)*4) | (({COL1}&2)*2) | (({COL1}&1)*64) | (({COL2}&8)/4) | (({COL2}&4)*8) | (({COL2}&2)*4) | (({COL2}&1)*128)
MEND

MACRO DBPIXM0 COL2,COL1
	db ({COL1}&8)/8 | (({COL1}&4)*4) | (({COL1}&2)*2) | (({COL1}&1)*64) | (({COL2}&8)/4) | (({COL2}&4)*8) | (({COL2}&2)*4) | (({COL2}&1)*128)
MEND

endif
