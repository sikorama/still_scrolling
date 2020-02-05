; STILL SCROLLING in 2018
; Stéphane Sikora, Mai-Aout 2018 

; Credits supplémentaires:
; Roudoudou: RASM
; Roudoudou, Madram ++: Routine décruncher
; Targhan/Arkos : Arkos Tracker
; Offset: routine détection CRTC  (http://quasar.cpcscene.net/doku.php?id=coding:test_crtc)
; AST: Tests & tricks

; Idées supplémentaire
; Flash bleu: l'enlever ou le rallonger d'une ou deux trames
; Palettes générées, ce qui permet d'avoir plusieurs version, dont une version random
; A la fin mettre toutes les encres a 0 (et temporiser 1 s seconde?)
;\=/

; CRTCs 0 3 4 uniquement
; Mais attention sur CRTC3 (et 4?) : on a un décallage dans l'interpretation des commandes au CRTC et le R3 n'est pas ajusté de la meme facon

DEBUG EQU 0
; PROD>0 On ne quitte qu'avec un reset (
; PROD 2 on ne coupe pas les ITs au début, ca été fait par le loader
PROD EQU 1
print 'PROD =' , PROD

DISABLE_KB EQU PROD

ABSDATE EQU 0

TEST_PLUS EQU 0 ; Permet d'avoir le texte qui correspond a la valeur d'ajustement pour le PLUS (debug)

; A VIRER
ENABLE_SPLIT_PALETTE EQU 0

; Pour debug CRTC1 (obsolete)
; A VIRER
;CRTC_REDUCTION EQU 0 ;Pour tester la reduction du scroll CRTC pour CRTC1
;NO_CHANGE_R12 EQU 0 

; Detection CRTC
; 0 = Auto
; 1 = Force Patch
; 2 = Disable Detection & Patch
PATCH_MODE EQU 2

	LINEWIDTH EQU 100 ; 100 - 120
	SINTABSIZE EQU 96 ; Le compteur principal (subscroll) va de 0 a SINTABSIZE-1
	SC1_H EQU 3
	SC2_H EQU 3 ; Les petits ecrans font 4*8 lignes
	SC4_H EQU 10
	NUM_SPLIT_LINES EQU 7 
	;Player_Address		equ #8800 
	Music_Address		equ #8000
	ENABLE_MUSIC EQU 1

	; Adresses HW
	BLACK_SCREEN_HW_OFFSET  EQU 50

	; Bloc de 4*8 lignes dispo 
	MOIRE1_SCREEN_HW_OFFSET  EQU 50+8*LINEWIDTH/2
	
	
	MOTIF1_SCREEN_HW_OFFSET1  EQU #1000
	MOTIF1_SCREEN_HW_OFFSET2  EQU MOTIF1_SCREEN_HW_OFFSET1+(4*LINEWIDTH/2)
	
	MOTIF2_SCREEN_HW_OFFSET1  EQU #1000+(8*LINEWIDTH/2)
	MOTIF2_SCREEN_HW_OFFSET2  EQU MOTIF2_SCREEN_HW_OFFSET1+(4*LINEWIDTH/2)
	
	MOIRE2_SCREEN_HW_OFFSET   EQU #1000+16*LINEWIDTH/2
	
	; Adresses memoire
	BLACK_SCREEN_MEM_OFFSET  EQU 100 	
	MOIRE1_SCREEN_MEM_OFFSET  EQU 100+8*LINEWIDTH
		
	MOTIF1_SCREEN_MEM_OFFSET1  EQU #4000 
	MOTIF1_SCREEN_MEM_OFFSET2  EQU MOTIF1_SCREEN_MEM_OFFSET1+4*LINEWIDTH
	
	MOTIF2_SCREEN_MEM_OFFSET1 EQU #4000+8*LINEWIDTH
	MOTIF2_SCREEN_MEM_OFFSET2  EQU MOTIF2_SCREEN_MEM_OFFSET1+4*LINEWIDTH

	MOIRE2_SCREEN_MEM_OFFSET   EQU #4000+16*LINEWIDTH
		
	
	include "./lib/toolbox.asm"

	macro MY_DEBUG_BORDER col
		if PROD==0
		DEBUG_BORDER {col}
		endif
	mend
	
	
ORG     #9000

macro CHECK_LINE_VRAM LDAI
if {LDAI}==1
	ld a,i
endif
	ld h,floor((scr_bloc+4)/256)
	rra
	rra 
	rra 
	and #1C						; arrondi sur 4 (0xc) 
	ld l,a	
	
	ld a, #0c
	ld c, #be

	out (0),a
	ld b, c
	outi
	outi
	ld b, c
	outi						

MEND

    ; Largeur de ligne 
	CRTC_SET_REG CRTC_REG_HLEN,LINEWIDTH/2
	; Position horizontale: 50 tout a gauche
	CRTC_SET_REG CRTC_REG_HPOS, 50-DEBUG
	
	; => Eviter d'utiliser un appel systeme, on le fait au niveau du 
	; loader
	if PROD<2	
		GET_CARACT_TAB CARAC_TAB_ROM,63
		SETMODE 0
	endif
	
	if ENABLE_MUSIC>0
	LD de,Music_Address
	call Player_Address
	endif

	DI
	
if PATCH_MODE!=2
	call TestCRTC ; => a passer en macro?
endif

	if PROD==0		
		DISABLE_INT (inter+1)
		; sauvegarde des registres mirroir
		PUSH_MIRROR_REGS
	else
		if PROD==1
			DISABLE_INT38
		endif
	endif

	ld HL,#C000
	ld DE,#C001
	ld BC,#4000-1
	ld (hl),#00
	LDIR
	
	; On remplit de 0 la banque #4000-7fff et de #C0 la banque #100-3fff
	ld HL,BLACK_SCREEN_MEM_OFFSET
	ld DE,BLACK_SCREEN_MEM_OFFSET+1
	ld BC,#4000-BLACK_SCREEN_MEM_OFFSET
	ld (hl),#00
	ldir	
	ld HL,MOTIF1_SCREEN_MEM_OFFSET1
	ld DE,MOTIF1_SCREEN_MEM_OFFSET1+1
	ld BC,#4000-1
	ld (hl),#C0
	LDIR
	
	
; Remplissage de l'écran avec un motif
; Utilisation audacieuse de la pile pour faire le motif symmetrique
macro fill_screen:
	ld hl,MOTIF1_SCREEN_MEM_OFFSET1
	ld a, 8*8+1
fslp0:
	ex af,af'
	ld a,LINEWIDTH
fsstartp:
	ld de, #400 ; #900
	push hl
fslp1:
	push af
		push hl
		ld hl,tabmode0_2px
		ld a,d
		cp 14
		jP M, no0
		sub 14
		ld d,a
no0:
		; inversion palette
		ld c,a
		ld a,13
		sub c		
		ld c,a		
		ld b,0
		add hl,bc
		ld a,(hl)
		pop hl

		ex de,hl
fsincrement:	
		ld bc,#07f ; #80
		add hl,bc
		ex de,hl		
fsmoire:
		and #55
		ld (hl),a		
		inc hl

	pop af
	dec a
	jr nz, fslp1
	
	ld hl,(fsincrement+1)
	inc HL
	inc HL
	ld (fsincrement+1),hl

	ld hl,(fsstartp+1)
	ld de,2*LINEWIDTH/2
	sbc hl,de
	ld (fsstartp+1),HL
	
	pop hl
	push hl ; audacieux :)
	call NXT_LINE

	ld a,(fsmoire+1)
	cpl 
	ld (fsmoire+1),a
	
	ex af,af'
	dec a
	jr nz, fslp0
	
	; Ensuite on depile 	
	ld a,64
	ld de,MOTIF2_SCREEN_MEM_OFFSET1
lpmirror:	
	pop hl
	push de	
	ld bc,LINEWIDTH
	ldir
	pop hl
	ex af,af'
	call nxt_line	
	ex af,af'
	ex de,hl
	dec a
	jr nz, lpmirror
	pop HL
mend	
	fill_screen
	
;	call fill_screen ; Macro a la place?

if 0
	ld de,MOIRE1_SCREEN_MEM_OFFSET+2*LINEWIDTH+16+4
	ld hl, TITLE+1
	ld b,15
lpprm0:
	ld a,(hl)
	inc hl
	push de
	push bc
	push hl
	call print_carac_m0
	pop hl
	pop bc
	pop de

	inc de
	inc de
	inc de
	inc de

	djnz lpprm0
	endif
	
	EI

LOOP

FirstScreen:	

	WAITSYNC
	; Cyclage de couleur pour animation		
	LD  A,(cycle_col_cnt+1)
damierColors:
	ld HL, (GA_BLUE <<8)| GA_BLUE
	call setDamPal
		
		; Couleur 1
		ld c,GA_SELECT_COL |1
		out (c),c
col15:	ld a, GA_BLACK
		out (c),a

		dec c
col00:  ld a, GA_BLACK
		out (c),c
		out (c),a
		
		MY_DEBUG_BORDER GA_GREEN
		ld 		BC,GA_PORT | GA_SET_MODE|0
		OUT     (C),C
	
;	 
FIRSTHW:	 	
		ld HL,screen_bloc1 -4
		ld e,(HL)
		inc HL
		inc HL
		ld l,(HL)				
		ld h,e
		SET_VRAM_OFFSET_HL
	
	; ================================================================

splitRASTERPAL:
	LD      HL,BJRASTCOL01
	LD      (split_colorindex),HL

	; flash Palette du scroll
flash_cnt:
	ld a,22		; commencer a 22 comme ca on compresse mieux la palette
	inc a
	cp SINTABSIZE/2
	jr nz,flash_cnt.noloop 
	xor a
.noloop:	
	ld (flash_cnt+1),a
.add:
	add 0
.toggle:
	nop
	;ld l,a

	LD  (split_colorindex),HL
	
	; Palette du split scroll en fonction la position 	
if ENABLE_SPLIT_PALETTE==1	
palreb:
	ld a,1
	or a
	jr z,nopalrebond
	
 	ld a,(REBOND_VAL)
	srl a
decalcol:
	 LD H,COLOR_SPLIT_RAST/256
	 ld l,a	
	 LD (split_colorindex),HL
nopalrebond:
endif

	; Recupere les touches clavier.. peut etre reduit a une seule ligne
	; en prod, car seule la barre espace est gérée
if DISABLE_KB==0
	;DI	
	GETKBSTATE kbstate	
endif
	EI
	
	if 1
set_split_size:	
	ld b,0
	ld a,(REBOND_CNT)
	cp 40	
	jp M,set_split_size.enhaut
	
	ld a,(REBOND_VAL)	
	cp 32
	jp M,set_split_size.enhaut
	cp #44
	jp P,set_split_size.enhaut
	ld b,1
.enhaut:
	
	ld a,(REBOND_CNT)		
	and 7
	; si 0 on reconfigure le split
	jr nz, set_split_size.height
	
	ld a,(split_mode)							
	or a
	ld a,SPLIT_DEFAULT_HEIGHT
	jr z, set_split_size.raster

	add b
	add b	
	ld hl, split_crtc_size0+1	
	ld de, split_crtc_size1 - split_crtc_size0			
	jr set_split_size.setValues
	
.raster:	

	sub b
	ld hl, split_raster_size0+1	
	ld de, split_raster_size1 - split_raster_size0
	
.setValues:
	ld (set_split_size.cursizeptr+1),hl
	ld (set_split_size.curdeltaptr+1),de
	ld (set_split_size.height+1),a	
	jr set_split_size.end
	
.height:
	 ld a,SPLIT_DEFAULT_HEIGHT	
	 
.curSIZEPTR:
	ld hl,split_raster_size0+1	
.curDELTAPTR:
	ld de,split_raster_size1 - split_raster_size0
	ld (hl),a
	add hl,de
	ld (set_split_size.cursizeptr+1),hl
	;inc a
	;ld (set_split_size.height+1),a
.end	
endif

	; On attend le début de la zone visible (4 lignes texte = 4*8 lignes)
	; moins le code precedent, Pour ca on gere le scroll hard
	CALL SCROLL
	;CALL SPLIT_SCROLL

	MY_DEBUG_BORDER COL_RED_BRIGHT

	; Overflow du du reg7
	CRTC_SET_REG CRTC_REG_VPOS   ,#7f
	; Taille du premier écran
	CRTC_SET_REG CRTC_REG_VLINE  ,SC1_H
	CRTC_SET_REG CRTC_REG_VCHAR  ,(SC1_H+1)

	 ld HL,(scroll_hwoffset)
	 ld D,H
	 ld E,L
	 ld BC,4*LINEWIDTH/2
	 add HL,BC
	 ex HL,DE	
	 
	 ; On pourrait aussi décaller par bloc de 4
		ld a,(bloc_config)
	; on pourrait zapper le bloc 1, il est affecté juste apres,
	; => ecrire directement dans le code
	ld IX ,screen_bloc1
		
	call SET_BLOCS
		
		; Premier écran de 8 lignes, on le fait avant que ne commence le bloc raster
		; TODO a optimiser
	
		ld a,(screen_bloc1)
		ld h,a
		ld a,(screen_bloc1+2)
		ld l,a
		SET_VRAM_OFFSET_HL
		
		; -------------------------------
		; Calcul de la Position verticale du split scroll

		; 0 = Saut
		; 2 = immobile
		; 1 = terminer le saut 		
		; ... autres valeurs 
		
split_config:	ld a,1	; config == 0 => Saut activé
		or a
		jr z,jump

		; sinon si le bit 0 est a 0, (ex 00000010)  on ne bouge pas
		bit 0,a
		jr z, end_jump

		; sinon (xxxxxxx1) , on termine le saut pour aller en 0
		ld a,(REBOND_CNT)		
		or a
		jr nz, jump
		ld a,2
		ld (split_config+1),a
		jr end_jump
jump:								; mode 'jump'
		ld a,(REBOND_CNT)			 
		; Verife si >SINTABSIZE/2, et dans ce cas remplace par SINTABSIZE-a
.sinth:	
		cp SINTABSIZE/2		
		JP M,jump.sinsym
		ld c,a
		ld a,SINTABSIZE
		sub c		
.sinsym:
		ld c,a	
		ld b,0
sstable: ld hl,sintable			; ****** Table sinus pour le split scroll (sintable ou sin2table)
		add hl,bc
		ld a,(hl)
		ld (REBOND_VAL),a
		; ici ajouter un décallage  supplémentaire 
		; add 0
		ld (tempo2+1),a				; poke		
end_jump:

		; Moire 2: on ne la genere qu'au début, apres ce n'est plus nécessaire	
		ld HL,#7f00 ; 128,0
		CALL FILL_RAND		
		ld HL,#3f14 ; 64,20		
		CALL FILL_RAND
		ld HL,#1f24 ; 32,36		
		CALL FILL_RAND
		ld HL,#0f2C ; 16,44		
		CALL FILL_RAND
		ld HL,#0730 ; 8,48				
		CALL FILL_RAND
	
		

	; ================================================================
		HALT
		; ================================================================
	
		DEBUG_BORDER GA_RED
		CRTC_SET_REG CRTC_REG_VLINE  ,SC2_H
		CRTC_SET_REG CRTC_REG_VCHAR  ,(SC2_H+1)
		
		di
		ds 28+27
		
tempo2:
		LD A,1				; ******* Nombre de ligne avant le split-scroll

		ld d,a
		xor a
		ld i,a
		
if DEBUG==0
		ds 7
else		
		LD 	    BC,GA_PORT | GA_SELECT_COLOR
		OUT     (C),C
		ds 3
endif
		
lpw000:
		CHECK_LINE_VRAM 0
		ld a,i
		inc a
		ld i,a
		ds 2
		
if DEBUG==0
		ds 19
else		
		;split raster pour le debug
		and 31
		or GA_SET_COL		
		ld b,GA_PORT_H	
		OUT     (C),A
		ld a, GA_BLACK
		OUT     (C),a		
		ld a,i
endif
		DEC d
		jr nz, lpw000
					
; ------------- SPLIT - SCROLL -----------------------
		ld a,(subscroll)
		ld b,a
		ld  a,(delay_italique)		
		add b
decall:						; a optimiser pour reduire la taille une fois que c'est bien callé
		add 12
		ld (nopc4+1),a
nopc4	jr nopc4
		ds 32

		ld a,(split_mode)							; split_mode= 0> Raster 1>CRTC
		or a		
		jp z, effect_split_raster
		
; Split CRTC
effect_split_crtc:
		LD 	    BC,GA_PORT | GA_SELECT_BORDER
		OUT     (C),C

		ld h, COLOR_SPLIT_CRTC/256 		; Poids fort de la palette

		ds 5

		; Le reg 8 ou 6 sera selectionné  plus loin
		;LD      BC,CRTC_PORT1 | 8			; CRTC 0: reg 8: 0 / 48
		;OUT     (C),C

		; on peut inverser les couleurs en inversant les valeurs
		; il faut inverser ld e, et le d, (et pas les valeurs)
		; a l'aide un xor bien senti (xor ("ld e", "ld d"))
		; CRTC 1 et 4: on met 0 pour dessiner et>0 (ici 8) pour ne pas dessiner
		; autre CRTCs: on met 48 pour dessiner et 0 pour ne pas dessiner
CRTC_PATCH1:
		ld e,48
CRTC_PATCH2:
		ld d,0

		include "split.asm"
		ld a,i
		split_crtc_line 0
		split_crtc_line 1
		split_crtc_line 2
		split_crtc_line 3
		split_crtc_line 4
		split_crtc_line 5
		split_crtc_line 6
if NUM_SPLIT_LINES==8
		split_crtc_line 7
endif
		JP effect_end

; -------------- Même chose,  mode RASTER
effect_split_raster:	

					LD 	    BC,GA_PORT | GA_SELECT_COL | 0
					OUT     (C),C

					ld e,GA_WHITE ; ?? inutile a priori
bgcolor:
					ld d,GA_BLACK
					ld h, COLOR_SPLIT_RAST/256 			; Poids fort de la palette

ajuste_plus:		jr def_ajuste 					; Sert pour tester l'ajustement horizontal sur un +
					ds 6
def_ajuste:
					ds 14-2
					ld a,i
					split_raster_line 0
					split_raster_line 1
					split_raster_line 2
					split_raster_line 3
					split_raster_line 4
					split_raster_line 5
					split_raster_line 6
if NUM_SPLIT_LINES==8
					split_raster_line 7
endif
			jP effect_end
			
			include "actions.asm"

effect_end:

if PROD==0
; TODO: Compensation du décalage pour le scroll? est ce utile?
; entre split et crtc, il y a plus de décallage
; par contre pour le debug c'est plus cool
; ou alors il faut utiliser pour faire des rasters dans le scroll
		ld a,(subscroll)
		;and 3
		xor 3
		ld (nopc5+1),a
nopc5:	jr nopc5
		ds 4
endif

; Attente pour atteindre un nombre de ligne précis depuis le debut
; du split scroll
; on sait que i a forcémentune valeur minimale , qui correspond a la taill
tempo3:
	LD 	    BC,GA_PORT | GA_SELECT_COLOR
	OUT     (C),C
	ld a,i
lpw3:
		CHECK_LINE_VRAM 0
		; split raster pour le debug
		ld a,i
		inc a
		ld i,a
        ds 2
if DEBUG==0
			ds 18		
else
			ld c,a
			and 31
			or GA_SET_COL
			ld b,GA_PORT_H
			ld a, GA_BLACK

			OUT     (C),a
			; ld a, GA_BLACK
			nop 
			nop
			OUT     (C),a
			ld a,c
endif	

split_last_line:
		cp 128+80       ;	 a partir du moment ou on colle le scroll en bas on va passer en gris et blanc, un peu plus tot 
		jp M, lpw3

		; A faire une fois qu'on est a mis le scroll en bas
		cp 128+70
		jp P, nogrey
		ld HL,GA_GREY<<8|GA_WHITE
		ld a,(colcnt+1)
		call setDamPal
nogrey:	
		EI
		
		MY_DEBUG_BORDER GA_ORANGE

		CRTC_SET_REG CRTC_REG_VLINE  ,SC4_H
		CRTC_SET_REG CRTC_REG_VCHAR  ,(SC4_H+1)
		CRTC_SET_REG CRTC_REG_VPOS   ,(SC4_H-1)

		;CALL SCROLL
		CALL SPLIT_SCROLL

		MY_DEBUG_BORDER GA_RED

if ENABLE_MUSIC>0
		ei
		call Player_Address + 3
		di

		; on retablit ix, comme ca pour toutes les actions
		; ix pointe sur les blocs adresse memoire
		ld IX ,screen_bloc1

		MY_DEBUG_BORDER GA_ORANGE
	
	    ; prend pas mal de temps:
		; optimisable / peut etre pas necessaire d'avoir toutes les tracks
		; a chaque trame... 		
		; calcul de la variation de la somme		
		ld a,8 
		call PSGREADREGA
		and #F					; pourquoi ne pas integrer le and dans le call????
		ld h,a
		
		ld a,9
		call PSGREADREGA
		and #F
		ld l,a
		
		ld a,10 
		call PSGREADREGA
		and #F
		ld c,a
		add h
		add l		
		ld (volumes),a
		ld a,c
th_nxtpat:
		cp #40
		call P, ACTION_NEXT_PATTERN2
		
		
endif

		MY_DEBUG_BORDER GA_BLACK
if 0
		
		; Effacer la palette
en_er:	ld a,0
		or a
		jr z,no_erase_pal
		
		ld a,r
		and 63
full_er:add 0
		ld l,a
		ld h,COLOR_SPLIT_CRTC/256
		ld a,GA_BLACK
		ld (hl),a
		
no_erase_pal:		
endif

		; Fait avancer le compteur pour le rebond
		ld HL,REBOND_CNT
		LD A,(HL)
JUMP_VEL:	add a,1						; Vitesse variable 0 1 2 4 8...
		cp SINTABSIZE
		jP M,rnomax
		xor a
rnomax:	ld (HL),a
		
		; Couleur de remplissage du hard scroll
colcnt:		ld a,0
		inc a
		cp 14
		jr nz,nomod14

		xor A
nomod14: ld (colcnt+1),a	
		
		; Cyclage de couleur: passe a la couleur suivante.		
		LD      hl,(cycle_col_cnt);
		; Vitesse de changement de couleur
vel_col_cycle:
		ld 		bc, #0100		; #80 pour avancer moins vite et faire un scroll relatif
		; Ajouter la valeur du sinus ?
		add   	hl,bc
		ld 		a,h
		
		cp 		14
		JP 		M,inccol1
		
		
		xor 	A
inccol1:
		ld 		h,a
		LD      (cycle_col_cnt),hl

		; Actions specifiques en fonction de la position dans le rebond
		
		; -- Auto toggle fg/bg? (en haut)
CHECK_TOGGLE:

		ld a,(REBOND_CNT)
		or a				; est on en 0?
		jr nz,no_toggle
AUTO_TOGGLE:			; peut s'optimiser en xor a:or a:jr z/nz
		ld a,0
		or a
		jr z, no_toggle
		inc a
		ld (toggle_split_mode),a
no_toggle:
		; -- scramble?
		ld a,(SCRAMBLE_CNT)
		or a
		jr z, no_scramble
		
		dec a
		ld (SCRAMBLE_CNT),a
		jr z, SET_PATTERN_STD
		
no_scramble:
		; -- auto italique? si non => check scramble
		ld a,(split_auto_ital)
		or a
		jr z,check_scramble
	
		ld a,(REBOND_CNT)
		;inclinaison en fonction du temps: a regler
		cp 4
		jp M, SET_PATTERN_STD				
		
		cp SINTABSIZE/4-4
		jp M, SET_PATTERN_ITAL1
		
		cp SINTABSIZE/2
		jp M, SET_PATTERN_ITAL2
		
		cp SINTABSIZE/2+8
		jp M, SET_PATTERN_ITAL1
;		jr SET_PATTERN_STD				

SET_PATTERN_STD:
	ld hl,split_pattern0
	call split_pattern_fill
	jr check_action_table
	
SET_PATTERN_ITAL1:
	ld hl,split_pattern2
	call split_pattern_fill
	jr check_action_table

check_scramble:		

if TEST_PLUS==0	
	
; Si Volume>seuil, SCRAMBLE!

	ld a,(volumes)
	cp #1C
	call P,SET_PATTERN_SCRAMBLE		
endif

	jr check_action_table
	
SET_PATTERN_ITAL2:
	ld hl,split_pattern3
	call split_pattern_fill
		
check_action_table:
	; action associée a la trame	
	LD hl,(action_table_ptr)
		
		
	
	
if ABSDATE==1
frameCntAction:	LD DE,0
	inc DE
	LD (frameCntAction+1),DE
	ld a,e
	cpi
	jr nz, skip_special_frame
	ld a,d
	cpi 
	jr nz, skip_special_frame
	; On execute l'action et on passe au pointeur suivant
else
frameCntAction:	LD a,1
	dec a
	ld (frameCntAction+1),a
	jr nz, skip_special_frame
	
endif
	
	;LD hl,(action_table_ptr)
	LD e,(hl)
	INC hl
	LD d,(hl)
	INC hl
	
if ABSDATE==0
	ld a,(hl)
	inc HL	
	ld (frameCntAction+1),a
endif
	
	LD (action_table_ptr),hl
	ex de,hl
	ld DE,END_ACTIONS
	push DE	
	jp (HL)

skip_special_frame:


if PROD==0
if DISABLE_KB==0
	LD A,(INHIBKB)
	OR A
	JR Z,check
	DEC a
	ld (INHIBKB),a
	JR check_exit_key
check:
	CHECK_ACTION_KEYS
	OR A
	JR Z,check_exit_key
	LD A,8
	ld (INHIBKB),a
ENDIF

else

END_ACTIONS:

endif

check_exit_key:
if DISABLE_KB==0
		; Touche espace pour quitter
		LD 	a,(kbstate+5)
		bit 7,a		
		JP  nz,LOOP
else
		JP  LOOP
endif


exit:
	; Faire un arret propre? audio + effacement
	
if PROD==0
		POP_MIRROR_REGS
inter   LD      HL,0
        LD      (#38),HL
		CRTC_RESET
		CALL    #bca7
        RET
else
if DISABLE_KB==0
		rst 0	
endif
		
endif

		; ==============================================================

		include "hscroll2.asm"

SPLIT_SCROLL:		
		LD A,(subscroll)
		inc a
		and 3
		ld (subscroll),a		

	ret nz
	if 0
		jp z, toggle_split		

		; on ne fait rien 3 fois sur 4
		; on pourrait afficher un caractere par exemple
		
		ld HL, MOIRE1_SCREEN_MEM_OFFSET+2*LINEWIDTH
			
		ld a,(volumes)
		;add a
		add a
		ld b,a
cdest:	ld a,0
		cp b
		jr z,eqa
		jp p,infa				
supa:		
		inc a
		jr eqa
infa:				
		dec a
eqa:		
		ld (cdest+1),a
		
		ld b,0
		ld c,a
		add hl,bc
		
tm2:	
	ld DE,tabmode0_2px
	cpl	
	sla a
	sla a
	and 15
	ld e,a
	
	push hl
	ld BC,LINEWIDTH
	exx
	ld b,8

lp88
	exx
	;inc e	
	inc e	
	ld a,(de)
@xorr:	and #FF

	push HL
	add HL,BC
	ld (hl),a
	pop HL
	inc e	
	ld a,(de)
	
	AND (HL)		
	ld (hl),a	
	;and (hl)

	inc HL
	;cpl
	;ld (hl),a
	dec HL
	ld a,h
	add 8
	ld h,a
	
	ld a,(@xorr+1)
	;cpl
	ld (@xorr+1),a
	exx
	djnz lp88
	

pop hl

; ld bc,LINEWIDTH
; add hl,bc
; ld BC,#800
; xor a
; repeat 8
	;;ld a,(de)
	; ld (hl),a
	; add HL,BC
; rend
	
ret
	
		endif
		
		
		
	; Applique le changment de mode FG/BG si requis
toggle_split:
	LD A,(toggle_split_mode)
	or a
	JR Z,skip_split_toggle
	xOR A
	ld (toggle_split_mode),a
	; Changement de mode
	LD A,(split_mode)
	xor 1
	ld (split_mode),a
	OR A
	JR Z,rasmode

	; ------------ SPLIT CRTC	
	;LD      HL,COLOR_SPLIT_CRTC
	;LD      (split_colorindex),HL
	ld HL,SPLIT_CRTC_OUT0+1
	ld (split_start1+1+3),HL
	ld HL,SPLIT_CRTC_OUT0+1+24  				; Patch 
	ld (split_start2+1),HL

	ld HL,SPLIT_CRTC_OUT1-SPLIT_CRTC_OUT0-24-1
	ld (split_delta1b+1),HL
	ld HL,SPLIT_CRTC_OUT1-SPLIT_CRTC_OUT0
	ld (split_delta2+1),HL
	
	JR skip_split_toggle
	
rasmode:
;	ld HL,SPLIT_RASTER_OUT0+1+2
;	ld (split_start1+1),HL
	ld HL,SPLIT_RASTER_OUT0+1
	ld (split_start1+1+3),HL

	ld HL,SPLIT_RASTER_OUT0+1+24
	ld (split_start2+1),HL

	ld HL,SPLIT_RASTER_OUT1-SPLIT_RASTER_OUT0-24-1
	ld (split_delta1b+1),HL
	ld HL,SPLIT_RASTER_OUT1-SPLIT_RASTER_OUT0
	ld (split_delta2+1),HL

skip_split_toggle:

		; Decalage des outs
		; Le code gere les changements de mode
		ld a,NUM_SPLIT_LINES
split_start1:
		ld HL,SPLIT_RASTER_OUT0+1+2
		LD DE,SPLIT_RASTER_OUT0+1
lpdecal:
repeat 12
		ldi
		inc HL
		inc de
rend
		ldi
		; Passage au bloc suivant
split_delta1:
		ld BC, SPLIT_RASTER_OUT1-SPLIT_RASTER_OUT0-24-1
		ADD HL,bc
split_delta1b:
		ld BC, SPLIT_RASTER_OUT1-SPLIT_RASTER_OUT0-24-1
		EX DE,HL
		ADD HL,bc
		EX DE,HL		
		dec a
		jr nz, lpdecal		

		;out c,c => ED49
		;out c,d => ED51
		;out c,e => ED59

        LD      HL,(SPL_TXT_INDEX)
        
		; code commun avec le hard scroll => call?
		LD      L,(HL)        
        LD      H,0
        ADD     HL,HL  ; *8
        ADD     HL,HL
        ADD     HL,HL
        ; Ajout de l'offset de la table des caractères
		; décalé de 256 pour zapper les 32 premiers octets
		LD      BC,CARAC_TAB-8
        ADD     HL,BC       

		
		EX      DE,HL		
		
		; Optimisation: si la fonte était stockee en colonnes
		; on n'aurait qu'un octet a lire a chaque fois
		; Test a l'aide du masque
		LD      A,(TXT_MASK)
        LD      C,A

split_start2:
		ld HL,SPLIT_RASTER_OUT0+1+24   ; Se patche pour le CRTC1? 

        LD      B,NUM_SPLIT_LINES
SPL_SCR1
		PUSH    BC
		
		LD 		A,(DE)
		AND 	C

		JR 		Z,SPL_SCR3
		LD 		A,#59
		JR SPL_scr4
SPL_SCR3:
		LD		A,#51
SPL_SCR4:
		LD      (HL),A

split_delta2:
		LD 		BC, SPLIT_RASTER_OUT1-SPLIT_RASTER_OUT0
		ADD 	HL,BC
        INC     DE
		
        POP     BC
        DJNZ    SPL_SCR1

		; Si on a eu une transition crtc<->raster
		; on force les source pour les copies
		LD A,(split_mode)
		or a
		JR Z,rasmode2
		ld HL,SPLIT_CRTC_OUT0+1+2
		ld (split_start1+1),HL
		ld HL,SPLIT_CRTC_OUT1-SPLIT_CRTC_OUT0-24-1
		ld (split_delta1+1),HL

		JR nextmask
rasmode2:
		ld HL,SPLIT_RASTER_OUT0+1+2
		ld (split_start1+1),HL
		ld HL,SPLIT_RASTER_OUT1-SPLIT_RASTER_OUT0-24-1
		ld (split_delta1+1),HL

nextmask:
		; prepare le masque pour le prochain coup
		; et passe au caractere suivant si necessaire
        LD      A,(TXT_MASK)
        rra
        JR      NC,SPL_SCR6
        LD      HL,(SPL_TXT_INDEX)
        INC     HL
        LD      A,(HL)
		cp 1
		ld a,#08
		jr z,SPL_SCR5
		ld a,#80       
SPL_SCR5
		LD      (SPL_TXT_INDEX),HL
        ;LD      A,#80
SPL_SCR6
		LD      (TXT_MASK),A
        RET

include "crtc_patch.asm"

NXT_LINE : NEXTLINE LINEWIDTH

; Remplissage 'random' et progressif
; moire 2
datar: db 0
FILL_RAND:
	ld a,(datar)
	ld c,a	
	ld a,R	
	add c
	ld (datar),a
	ld b,a
	and #38			
	ld D,A
	ld A,R	
	add b		
rng: and H
off: add L		; ici offset
	ld E,A
	ld A,b
	and 3
	ld (FRJR+1),A
	LD BC, LINEWIDTH	
	ld HL,MOIRE2_SCREEN_MEM_OFFSET
FRJR: jr FRJR+2
	add HL,BC
	add HL,BC
	add HL,BC
	add HL,DE	
	xor A
	ld (HL),A
	ret
	

	 ; Simple print en mode 2, sans gerer de debordement	
; DE: Destination
; A = carac
if 0
print_carac_m2:
	ld L,A
	ld H,0
	add HL,HL
	add HL,HL
	add HL,HL
	ld BC, CARAC_TAB-8
	add HL,BC
	ld BC,#800-1
repeat 7
	LDI
	inc C
	ex de,hl
	add HL,BC
	ex de,hl
rend
	LDI
	RET
endif

if 0
; A: caractere
; DE: destination
print_carac_m0:
	ld L,A
	ld H,0
	add HL,HL
	add HL,HL
	add HL,HL
	ld BC, CARAC_TAB-8
	add HL,BC

	ex de,hl	
	exx
	ld b,8
lp7:
	exx
	ld a,(DE)
	ld b,a
repeat 4
	xor a
	rl b	
	jr nc,@nomask1
	or #AA
@nomask1:
	rl b
	jr nc,@nomask2
	or #55
@nomask2:
	ld (HL),a		
	inc HL
rend
	ld BC,#800-4
	add HL,BC
	inc DE
	exx
	djnz  lp7
	exx	
	RET
	
endif


; CE: A correspond a l'index (0-13)
;     HL contient les 2 couleurs
setDamPal:	
	ld b,GA_PORT_H
	ld d,a
	ld a, GA_SELECT_COL | 15
	sub d

ld c,7
lpdam1:
	out (c),a
	out (c),l
	inc a
	cp (GA_SELECT_COL | 16)
	jr nz, lpdam1.notl
	ld a,GA_SELECT_COL |2
.notl:
	dec c
	jr nz, lpdam1

ld c,7
lpdam2:
	out (c),a
	out (c),h
	inc a
	cp (GA_SELECT_COL | 16)
	jr nz, lpdam2.notl
	ld a,GA_SELECT_COL | 2
.notl:
	dec c
	jr nz, lpdam2
	ret
	
	
include "data.asm"