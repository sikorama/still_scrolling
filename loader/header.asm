include "../lib/toolbox.asm"

TEST034 EQU 0

CHECK_CRTC:				; Si A000==#55, on ne fait pas le test CRTC
	
; Test si CRTC 1 ou 2
if TEST034==1

TestLongueurVBL
		print "Test VBL"
        ld b,#f5        ; Boucle d'attente de la VBL
SyncTLV1
        in a,(c)
        rra
        jr nc,synctlv1
NoSyncTLV1
        in a,(c)        ; Pre-Synchronisation
        rra             ; Attente de la fin de la VBL
        jr c,nosynctlv1
SyncTLV2
        in a,(c)        ; Deuxième boucle d'attente
        rra             ; de la VBL
        jr nc,synctlv2
 
        ld hl,140       ; Boucle d'attente de
WaitTLV dec hl          ; 983 micro-secondes
        ld a,h
        or l
        jr nz,waittlv
        in a,(c)        ; Test de la VBL
        rra             ; Si elle est encore en cours
        ret NC			; type 0,3,4 = On ne fait rien, c'est sensé marcher
else

TestBFxx
		print "Test BFXX"
        ld bc,#bc0c     ; On sélectionne le reg12
        out (c),c
        ld b,#bf        ; On lit sa valeur
        in a,(c)
        ld c,a          ; si les bits 6 ou 7 sont
        and #3f         ; non nuls alors on a un
        cp c            ; problème
        ret nz			; emulateur alien => on ne fait rien
        ld a,c
        or a            ; si la valeur est non nulle
        ret nz 		   ; alors on a un type 0,3,4
        ld bc,#bc0d
        out (c),c       ; On sélectionne le reg13
        ld b,#bf
        in a,(c)        ; On lit sa valeur
        or a            ; Si la valeur est non nulle
        ret nz			; alors on a un type 0,3,4     
endif		
		rst 0
						
GET_FONT:	
		; recup fonte systeme (avec des appels systeme, donc fait avant la decompressoin
;		GET_CARACT_TAB #A050,63
		; desactivation ITs
;		DI						
;		DISABLE_INT38
		if 0
		
ANIMATION:
			PUSH 	AF
			PUSH 	BC		
; 13 octets			
if 1
			ld b,#7f
			ld a,GA_SELECT_BORDER
			out (c),a			
			ld a,H
			add a
			and #4
			or #50
			out (c),a
endif			

; 23 octets pour faire disparaitre progressivement
if 1
                PUSH 	HL
                PUSH DE
                LD 	 D,0
                LD   B,20			 
dest:		 LD 	HL,#c000
lp:			
                LD 	(HL),D
                
                LD 	E,C
                ADD HL,DE
                SET 6,H
                SET 7,H			 
                djnz lp
                ld 	(dest+1),hl			 
	
		POP DE		
		POP HL
endif
		POP BC 
		POP AF
	ret
	
	endif
	