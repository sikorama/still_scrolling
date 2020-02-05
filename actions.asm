
ACTION_NEXT_PATTERN2:
.cnt:	ld a,3
		inc a
		and 3
		ld (ACTION_NEXT_PATTERN2.cnt+1),a		
		ret nz
		call action_next_bjcol	
		
ACTION_NEXT_PATTERN:
.cnt:
	ld a,0
	inc a
	and 3
	ld (ACTION_NEXT_PATTERN.cnt+1),a
	ld b,a
	ld a,7
	jr z, ACTION_SHOW_PAT12
	dec b
	jr z, ACTION_SHOW_PAT21
	ld a,5 
	dec b
	jr nz, ACTION_NEXT_PATTERN.n3
	call ACTION_SHOW_PAT11	
	ld a, 2
	jr  ACTION_SHOW_PAT22
.n3:
	call ACTION_SHOW_PAT22
	ld a, 2
	jr  ACTION_SHOW_PAT11
			
ACTION_SHOW_PATTERN1:
		ld a,6
		ld (bloc_config), a	
		ld a,1

ACTION_SHOW_PAT11:
		ld HL,MOTIF1_SCREEN_HW_OFFSET1
		ld DE,MOTIF1_SCREEN_HW_OFFSET2
		jP SET_BLOCS


ACTION_SHOW_PATTERN_BLOC4
		ld a,1<<3

ACTION_SHOW_PAT22:
		ld HL,MOTIF2_SCREEN_HW_OFFSET1
		ld DE,MOTIF2_SCREEN_HW_OFFSET2
		jP SET_BLOCS
		
ACTION_SHOW_PAT12:
		ld HL,MOTIF1_SCREEN_HW_OFFSET2
		ld DE,MOTIF2_SCREEN_HW_OFFSET1
		jp SET_BLOCS
		
ACTION_SHOW_PAT21:
		ld HL,MOTIF2_SCREEN_HW_OFFSET2
		ld DE,MOTIF1_SCREEN_HW_OFFSET1
				
; A Contient le masque pour les affectations
; TODO: Remplacer IX par HL et faire des increments?
SET_BLOCS:
		rra
		jr nc,SET_BLOCS.next1
		ld (IX+4),D
		ld (IX+6),E		
		ld (IX+0),H
		ld (IX+2),L
.next1:
		rra
		jr nc,SET_BLOCS.next2
		ld (IX+8+4),D
		ld (IX+8+6),E	
		ld (IX+8+0),H
		ld (IX+8+2),L
.next2:
		rra
		jr nc,SET_BLOCS.next3
		ld (IX+16+4),D
		ld (IX+16+6),E		
		ld (IX+16+0),H
		ld (IX+16+2),L		
.next3:
		rra
		ret nc
		ld (IX+24+4),D
		ld (IX+24+6),E		
		ld (IX+24+0),H
		ld (IX+24+2),L		
		ret	

SET_PATTERN_SCRAMBLE:
	ld a,4
	ld (scramble_cnt),a
	ld hl,split_pattern1		

split_pattern_fill:
	push HL
	ld BC,split_raster_3cycles1-split_raster_3cycles0
	ld de,split_raster_3cycles0
	call spfill
	ld a,(HL) ; TODO: coller directement dans le code
	ld (delay_italique),a
	pop HL
	
	ld BC,split_crtc_3cycles1-split_crtc_3cycles0
	ld de,split_crtc_3cycles0

spfill:
repeat (NUM_SPLIT_LINES-1)
	LDI
	LDI	
	ex de,hl
	add hl,bc
	ex de,hl
	inc c ; Compensation de la décrementation des  2 LDI.
	inc c ; comme bc <256, ca passe
rend
	LDI
	LDI
ret


		


; Faire scroller damier ou non		
ACTION_DAMIER_SCROLL:
	ld hl, #080
	ld (vel_col_cycle+1), hl
	ACTION_END	
if 0
ACTION_DAMIER_STATIQUE:
	ld hl, #100
	ld (vel_col_cycle+1), hl
	ACTION_END
endif

; Motif en damier ou en damier décallé	
ACTION_SET_DAMIER
	ld a, 7
	ld (dam1+1),a
	ACTION_END	
ACTION_SET_COLUMN
	ld a, 10
	ld (dam1+1),a
	ACTION_END	

; La palette du split raster passe en noir aléatoirement
if 0
ERASE_PAL:
	ld a,1
	ld (en_er+1),a
	ACTION_END	

ERASE_FULL_PAL:
	ld a,63
	ld (full_er+1),a
	ACTION_END	
endif
	
; Preset avec le split en haut et le hw en bas
; Background noir
ACTION_PRESET_HS:
		ld a,1<<2
		ld (bloc_config), a		
		ACTION_END	

; on fait passer le scroll4 en bas, et on en profite
; pour lancer les nouvelles couleurs: 
; scroll raster 1 color
; text gris et blanc
ACTION_SET_FIRST1_12:
	ld HL,screen_bloc1 +12
	ld (FIRSTHW+1),HL
ACTION_SET_RED_PURPLE_DAMIER:
		ld HL, (GA_RED <<8)| GA_PURPLE
		ld (DamierColors+1), HL	
;		ACTION_END

ACTION_HWSCROLL_BLOC4: 		
		ld a,1<<3
		ld (bloc_config), a		
		; Remonte la fin du scroll split raster
		ld a, 128+56
		ld (split_last_line+1),a
		ACTION_END
		
ACTION_3SCROLLS: 		; 3 Scrolls
		ld a,7
		ld (bloc_config), a
		ACTION_END		
if 0
ACTION_4SCROLLS: 		; 4 Scrolls
		ld a,15
		ld (bloc_config), a
		ACTION_END

ACTION_NO_SCROLL:
		xor a
		ld (bloc_config), a
;		jr SET_ALL_BLACKS		
endif		

SET_ALL_BLACKS:
		ld HL,BLACK_SCREEN_HW_OFFSET
		or A		
SET_ALLBLOCS:
		ld E,L
		ld D,H
SET_ALLBLOCS2:
		;ld IX, screen_Bloc1
		ld a, 1 | 2 | 4
		JP SET_BLOCS	

		
SET_JUMP_VEL1:
	ld a,1
	ld (JUMP_VEL+1), a
	ACTION_END
SET_JUMP_VEL2:
	ld a,2
	ld (JUMP_VEL+1), a
ACTION_NOTRAM:
	
	xor a
	ld (TRAM1+1),a
	ld (TRAM2+1),a	
	ACTION_END

if 0	
ACTION_TOGGLE_HSWIDTH:
	ld a,(LETWIDTH+1)
	xor 2
	ld (LETWIDTH+1),a
	ACTION_END
endif
	
;ACTION_SET_TITLE:
;	ld HL,MOIRE1_SCREEN_HW_OFFSET
;	ld (FIRSTHW+1),HL
;	ACTION_END

ACTION_TOGGLE_AUTO_PATTERN:
	 ld a,(th_nxtpat+1)
	 xor (#C ^ #40)
	 ld (th_nxtpat+1),a
	 ;ld (autopal+1),a
	 		; couleur unie pour le split raster
		; et changement auto des couleurs au rebond		
		ld HL,split_raster_out0.incl
		ld BC,split_raster_out1.incl-split_raster_out0.incl
		ld a,NUM_SPLIT_LINES-1
ataplp	ld (hl), 0
		add hl,bc
		dec a
		jp nz, ataplp
		ld (hl), 0
		
		;jp ACTION_SET_BJ_PAL1

	 ACTION_END	
	
ACTION_TOGGLE_AUTO_ITALIQUE:
		ld hl,split_auto_ital
		ld a,(hl)
		cpl
		ld (hl),a	
		ACTION_END

action_toggle_autofgbg:
	ld a,(AUTO_TOGGLE+1)
	;cpl
	xor 1
	ld (AUTO_TOGGLE+1),a	

	ACTION_END

ACTION_HWSCROLL_INV:
		ld a,(invscr)
		xor #A9
		ld (invscr),a
		ACTION_END		
		
; démarre le rebond
ACTION_REBOND_FG:
		; rebond activé
		xor a
		ld (split_config+1),a
		ACTION_END  ; On ne devrait pas avoir a mettre le violet ici

; ne devrait pas etre necessaire
if 0
ACTION_VIOLET_PAL:		
		ld HL,VIOLET_PAL
		ld (splitRASTERPAL+1),HL
		ACTION_END
endif

ACTION_WHITE_PAL:		
		ld HL,WHITE_PAL
		ld (splitRASTERPAL+1),HL
		ACTION_END


		
; Arrete le rebond
ACTION_STOP_REBOND:		
		ld a,2
		ld (split_config+1),a
		ACTION_END
		
ACTION_SET_DAMIER_PAL:
;		ld HL, (GA_WHITE <<8)| GA_BLUE_SKY
;		ld (DamierColors+1), HL		
		;ACTION_SET_BJ_PAL01:
		;ld a, GA_BLACK
		;ld (bgcolor+1),a
		;ld (col00+1),a
		;ld (col15+1),a
		
		ld HL, (#58 <<8)| #5D
		ld (DamierColors+1), HL	
		
		ld HL,BJRASTCOL02
		ld (splitRASTERPAL+1),HL
;		jP ACTION_SET_BJ_PAL
		ACTION_END

; Palettes Barjack:  Damier          		     SCROLL	
; a vérifier :)
; Bleu    10 15 17	 GA_BLUE/GA_BLUE_BRIGHT      GA_BLUE_SKY
; Violet  18 1d 0d   GA_MAGENTA/GA_MAUVE         GA_MAGENTA_BRIGHT
; Rouge   1c 0c 0e 	 GA_RED/GA_RED_BRIGHT 	     GA_ORANGE
; Orange  0d 07 0e   GA_MAGENTA_BRIGHT/GA_PINK   GA_YELLOW
; Vert    00 16 12   GA_GREY/GA_GREEN			 GA_GREEN_BRIGHT

;Puis Damier 
	

ACTION_SET_RED_MAGENTA2:
		ld HL, (GA_MAGENTA <<8)| GA_MAGENTA_BRIGHT
		ld (DamierColors+1), HL	
ACTION_END

ACTION_SET_RED_BLUE_CYAN:
		ld HL, (GA_BLUE <<8)| GA_CYAN
		ld (DamierColors+1), HL	
ACTION_END


		
ACTION_SET_BJ_PAL03:
		ld HL,BJRASTCOL03
		ld (splitRASTERPAL+1),HL		
		ACTION_END
		
ACTION_SET_BJ_PAL1:
		ld HL,BJRASTCOL1
		ld (splitRASTERPAL+1),HL
SET_BLUE_DAMIER:
		ld HL, (GA_BLUE <<8)| GA_BLUE_BRIGHT
		ld (DamierColors+1), HL	
ACTION_END
		
ACTION_SET_BJ_PAL2:
		ld HL, (GA_MAGENTA <<8)| GA_MAUVE
		ld (DamierColors+1), HL	
		ld HL,BJRASTCOL2
		ld (splitRASTERPAL+1),HL
		ACTION_END
		
ACTION_SET_BJ_PAL3:
		ld HL, (GA_RED <<8)| GA_RED_BRIGHT
		ld (DamierColors+1), HL		
		ld HL,BJRASTCOL3
		ld (splitRASTERPAL+1),HL
		ACTION_END
		
ACTION_SET_BJ_PAL4:
		ld HL, (GA_MAGENTA_BRIGHT <<8)| GA_PINK
		ld (DamierColors+1), HL	
		ld HL,BJRASTCOL4
		ld (splitRASTERPAL+1),HL
		ACTION_END
		
ACTION_SET_BJ_PAL5:
		ld HL,BJRASTCOL5
		ld (splitRASTERPAL+1),HL
SET_GREEN_DAMIER:
		ld HL, (#5e <<8)| GA_GREEN
		ld (DamierColors+1), HL		
		ACTION_END
		
action_next_bjcol:		
		; auto pal
		ld a,0
		add ACTION_SET_BJ_PAL2-ACTION_SET_BJ_PAL1
		cp 5*(ACTION_SET_BJ_PAL2-ACTION_SET_BJ_PAL1)
		jr nz,action_next_bjcol.no5
		xor a
.no5:		
		ld (action_next_bjcol+1),a
		
		ld c,a
		ld b,0
		ld HL,ACTION_SET_BJ_PAL1
		add hl,bc
		jp (HL)

SET_YELLOW_SCROLL:		
		ld a,48
		ld (flash_cnt.add+1),a
		ACTION_END
		
		
ACTION_TOGGLE_FLASH:
		ld a,(flash_cnt.toggle)
		xor #6f
		ld (flash_cnt.toggle),a
		ACTION_END
		
; Resynchronise les scrolls
ACTION_SYNC_SCROLLS:
if TEST_PLUS==0
	ld hl,(SPL_TXT_INDEX)
	;inc hl
	ld (TXT1),HL
endif
	ACTION_END

; Hard scroll => des espaces a l'infini	
ACTION_SPACE_SCROLL:	
	ld hl,space
	ld (TXT1),HL
	ACTION_END


; NON UTILISé
if 0
; Changement motif remplissage scroll
ACTION_SET_TABMODE0_2PXI1
	ld a, floor(TABMODE0_2PXI/256)
	jr SET_TABMODE0	
ACTION_SET_TABMODE0_2PX
	ld a, floor(TABMODE0_2PX/256)
SET_TABMODE0:
	ld (CUR_TABMODE0+1),a
	ACTION_END
endif

if 0	
ACTION_RESETCNT:
		; Remet les compteurs d'action a 0
		
if ABSDATE==1
		LD hl,0
		LD (frameCntAction+1),HL
else
		LD a,1
		LD (frameCntAction+1),a
endif
		LD hl,action_table
		LD (action_table_ptr),hl
		ACTION_END
endif

if 0
set_split_dec_size:				
	ld a,(split_size_height+1)
	dec a
	ret z

set_split_inc_size:				
	ld a,(split_size_height+1)
	inc a
	cp 16
	jr nz,set_split_size
	ACTION_END

set_split_stdsize:				
	ld a ,16
set_split_size:
	ld (split_size_height+1),a
	ACTION_END
endif

	
; PRESET CLAVIER pour l'ajustement horizontal du scroll
if DISABLE_KB==0

; Decalage horizontal global

; ACTION_KEYUP	
	; ld hl,(decallage_scrolls+1)
	; inc hl
	; ld (decallage_scrolls+1),hl	
	; ACTION_END	
; ACTION_KEYDOWN
	; ld hl,(decallage_scrolls+1)
	; dec hl
	; ld (decallage_scrolls+1),hl	
	; ACTION_END

; Gauche droite: ajuste 
ACTION_KEYRIGHT
	ld a,(ajuste_plus+1)
	inc a 
	jr set_ajuste_plus	
ACTION_KEYLEFT
	ld a,(ajuste_plus+1)
	dec a 
set_ajuste_plus:
	and 15
	ld (ajuste_plus+1),a	
	inc a
if TEST_PLUS==1	
	; Changer le texte du scroll de facon a avoir la valeur affichée (-7...+7)
	cp 11
	jp M,NUMVAL
	add 'A'-'0'-10
NUMVAL:		
	add '0'-32
	ld (space),a	
endif
	ACTION_END
endif


