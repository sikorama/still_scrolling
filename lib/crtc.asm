; Tout ce qui a trait au CRTC


; Registres CRTC
;cf http://irios.free.fr/crtc_6845.htm#cal6845
;http://www.6502.org/users/andre/hwinfo/crtc/index.html

CRTC_PORT1   EQU #BC00
CRTC_PORT2   EQU #BD00
CRTC_PORT1_H EQU #BC	; Port Reg Select
CRTC_PORT2_H EQU #BD    ; Port Set Value


CRTC_REG_HCHAR 		EQU #00 ; Temps total (-1) pour une ligne horizontale 0-255, 63 (64us)
CRTC_REG_HLEN 		EQU #01 ; Nombre de caractere affiches par ligne 0-255, 40. Doit etre inferieur ou egal a HCHAR
CRTC_REG_HPOS 		EQU #02 ; Positon Horizontale,  R1<R2<=R0
CRTC_REG_HSYNC 		EQU #03 ; Longueur de Synchronisation 0-15 Exprimé en multiple du nombre de périodes d'horloge nécessaires à l'affichage d'un caractère
                       
CRTC_REG_VLINE 		EQU #04 ; Nombre de lignes texte -1  0-127 (38)
CRTC_REG_VSYNC   	EQU #05 ; Synchro Verticale 0-31 (0) en scanline , s'ajoute a R4 pour la synchro V
CRTC_REG_VCHAR		EQU #06 ; Nombre de caracteres affiches en vertical 0-127 (25)
CRTC_REG_VPOS   	EQU #07 ; Position Verticale (30) , il définit le nombre de lignes de trames à balayer avant d'activer le signal "VSYNC"
CRTC_REG_INTERL		EQU #08 ; 0-3

CRTC_REG_SCANNING 	EQU #09 ; Nombre de lignes par caractere (-1) 0-31 (7 ou 8)
CRTC_REG_BLINK      EQU #0A ; Clignotement du curseur

CRTC_REG_VRAMHI 	EQU #0C  ; Offset video ram : première adresse de la RAM d'écran affiché après un "vertical blanking"
CRTC_REG_VRAMLO 	EQU #0D


MACRO CRTC_SET_REG REG,VAL
	LD      BC,CRTC_PORT1 | {REG}
	OUT     (C),C 
	inc 	B
	LD 		C,{VAL}
	OUT     (C),C
MEND


;Mode Standard
; 80 x 25 (40, 25, 46,32)
;Modes Full screen courants: 
; 96 * 21 (48, 21, 50) Manque 32 octets pour passer a 2048
; 92 * 22 (46, 22, 49) Manque 24 octets pour passer a 2048
; Modes speciaux
; 64  * 32
; 32  * 64
; 128 * 16
; 16 * 128
MACRO SETSCREEN linelen,numline,left,top

	; Largeur de ligne 
	CRTC_SET_REG CRTC_REG_HLEN,{linelen} 	
	; Posiiton horizontale: 50 tout a gauche
	CRTC_SET_REG CRTC_REG_HPOS, {left}	
	; Synchro / Position Verticale
	CRTC_SET_REG CRTC_REG_VPOS,	{top}
	
	; Nomnbre de lignes texte (25 par defaut)
	CRTC_SET_REG CRTC_REG_VCHAR,{numline}	
	;CRTC_SET_REG CRTC_REG_VLINE,{numline}
MEND

MACRO SET_VRAM_OFFSET_HL	
	LD      BC,#BC00 | CRTC_REG_VRAMHI	
	OUT     (C),C 		
	inc 	B
	OUT     (C),H
	
	dec 	B	
	inc 	C		; VRAMLO
	OUT     (C),C 
	inc 	B	
	OUT     (C),L
MEND

MACRO CRTC_RESET
	SETSCREEN 40,25,46,32
	CRTC_SET_REG CRTC_REG_VLINE,38
	;CRTC_SET_REG CRTC_REG_HSYNC,1426
	ld HL,#3000
	SET_VRAM_OFFSET_HL	
MEND
