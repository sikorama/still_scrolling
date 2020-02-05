
; 0: Test VBL
; 1: Test Reg12/13
TEST034 EQU 0

; http://quasar.cpcscene.net/doku.php?id=coding:test_crtc

; Il faudrait tester le CRTC4 aussi, car il faudrait le patcher aussi
; Pour le CRTC2 par contre...

TestCRTC:

if PATCH_MODE==2
	print "Pas de Patch CRTC"	
else

if PATCH_MODE==0

; Test si CRTC 1 ou 2
if TEST034==2

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
endif

; Autres test possible
if TEST034==1
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
		
		; Sinon on a un type 1,2... si c'est 1 on devrait pouvoir patcher
		; Si c'est 2, on doit désactiver les split CRTC, rester en raster
		; Ou quitter...        		


		
; Test CRTC 1
; Test basé sur la détection du balayage des lignes hors border
; Permet d'identifier le type 1
; Bug connu rarissime: si reg6=0 ou reg6>reg4+1 alors le test est faussé !


TestBorder:
	print "Test Border"
	ld b,#f5
NoSyncTDB1
	in a,(c)		; On attend un peu pour etre
	rra				; sur d'etre sortis de la VBL
	jr c,nosynctdb1	; en cours du test précédent
SyncTDB1
	in a,(c)	; On attend le début d'une
	rra			; nouvelle VBL
	jr nc,synctdb1

NoSyncTDB2
	in a,(c)	; On attend la fin de la VBL
	rra
	jr c,nosynctdb2

	ld ix,0		; On met @ zéro les compteurs
	ld hl,0		; de changement de valeur (IX),
	ld d,l		; de ligne hors VBL (HL) et
	ld e,d		; de ligne hors border (DE)
	ld b,#be
	in a,(c)
	and 32
	ld c,a
SyncTDB2
	inc de		; On attend la VBL suivante
	ld b,#be	; en mettant @ jour les divers
	in a,(c)	; compteurs
	and 32
	jr nz,border
	inc hl		; Ligne de paper !
	jr noborder
Border	ds 4
NoBorder
	cp c
	jr z,nochange
	inc ix		; Transition paper/border !
	jr change
NoChange
	ds 5
Change	ld c,a
	ds 27
	ld b,#f5
	in a,(c)
	rra
	jr nc,synctdb2	; On boucle en attendant la VBL

	db #dd:	ld a,l 	; Si on n'a pas eu juste deux transitions alors ce n'est
	cp 2		;
	ret nz	; pas un type 1 
endif
	
	; Type 1: on patche le code split CRTC
	; => il faudrait tester si c'est pas un type2
	; auquel cas, on arrete (ou on fait que du split raster)
	
	
patch_crtc1:
			        ; c = Numero du registre
	ld bc,#0B06		; b = 11 entrées dans la table
	ld de,4		; Pas 
	ld HL,scr_bloc+3
patch_tab:
	ld (hl),c
	add hl,de
	djnz patch_tab	
	; 2 octets pour les valeur a envoyer au reg
	;ld a,e ; e=4
	
	ld a,#7f 
	ld (CRTC_PATCH2+1),a
	xor a
	ld (CRTC_PATCH1+1),a

	; Valeur a rétablir?
	ret
	
endif

	
	
	
	