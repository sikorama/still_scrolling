; A la suite du code

; on  ajoute un décalage avant (et donc une compensation?)
; pour chaque pattern, pour que l'inclinaison se fasse par rapport au
; centre de la lettre
split_pattern0: ; Droite
	db #86,#00,#86,#00,#86,#00,#86,#00
	db #86,#00,#86,#00,#86,#00
	if NUM_SPLIT_LINES== 8 
		db #86,#00
	endif	
	db 4
split_pattern1: ; Scramble
	db #86,#00,#86,#86,#00,#00,#86,#86
	db #00,#00,#86,#86,#00,#00
	if NUM_SPLIT_LINES== 8 
		db #86,#86
	endif
	db 4
split_pattern2: ; InclinL1
	db #86,#00,#86,#00,#00,#00,#86,#00
	db #00,#00,#86,#00,#00,#00
	if NUM_SPLIT_LINES== 8 
		db #86,#00
	endif
	db 3
split_pattern3: ; InclinL2
	db #86,#00,#00,#00,#00,#00,#00,#00
	db #00,#00,#00,#00,#00,#00
	if NUM_SPLIT_LINES== 8 
		db #00,#00
	endif
	db 2

if 0
split_pattern4: ; InclinL2
	db #86,#00,#00,#00,#00,#00,#00,#00
	db #00,#00,#86,#00,#00,#00
	if NUM_SPLIT_LINES== 8 
		db #00,#00
	endif
	db 2
endif

	
if 0
split_pattern4: ; inclinR2
	db #86,#00,#86,#86,#86,#86,#86,#86
	db #86,#86,#86,#86,#86,#86
	if NUM_SPLIT_LINES== 8 
		db #86,#86
	endif
	db 8
endif

TXT_MASK    db #80
	
end_data1 

ALIGN 256
; Table de 42 octets
; Doit etre aligné sur 256 octets pour le hard scroll
; 2*14 octets...
tabmode0:

; colonnes de 2 pixels => vitesse couleur +1/trame
tabmode0_2px:
repeat 3
v=15
repeat 14
	DBPIXM0 v,v
	v=v-1
rend	
rend


; Palette pour le split scroll
split_colorindex dw BJRASTCOL01
; Scroll HW
HWSCROLL_OFFSET  dw      0 ,(LINEWIDTH/2)*8

cycle_col_cnt dw #E00  ; Compteur pour le cyclage de couleur 8.8
; Configuration des 4 écrans: scroll ou non
bloc_config: db 0
vscroll_cnt db 0
scroll_hwoffset dw 0 ; Adresse mémoire vidéo pour afficher le scroll hard

; Timer principal pour rythmer les animations:
; de 0 a 3 (b0b1), pour décaler de 1 a 4 nops
SUBSCROLL db 0
; Pour le rebond on utilise ce compteur, pour pouvoir changer
; la vitesse de rebond.
; On pourra le resynchroniser avec szubscroll si besoin
REBOND_CNT db 0
; Comme on calcul le symmetrique, autant le stocker
REBOND_VAL db 0
; Pour l'effet de scramble, un compteur pour retablir les valeurs normale
SCRAMBLE_CNT db 0
volumes db 0

; Split Scroll
; Configuration : TODO: a regrouper sur moins d'octets si c'est interessant: le code peut etre plus long..)
; ou a mettre si possible dans le code
split_mode: 		db 0 ; b0: raster(0) ou crtc (1)
toggle_split_mode 	db 0 ; Flag pour alterner entre les 2 modes de split (au bon moment)
split_auto_ital: 	db 0


delay_italique: 	db 4 ; Delai additionnel pour le mode "italique"


SPL_TXT_INDEX    dw TEXTE1


action_table_ptr: dw action_table

if 0
ALIGN 256	
tabmode0_2pxi:
;colonnes de 2 pixels, décallés de 1
repeat 4
v=14
repeat 13
	DBPIXM0 (v-1),v
	v=v-1
rend	
	DBPIXM0 14,v
rend
endif


; Rebond 
sintable:	
sin2table: ;  48 octets+1
	repeat SINTABSIZE/2+1, angle
		;db 69-(cos(180*(angle-1)/SINTABSIZE))*68
		db 78-(cos(180*(angle-1)/SINTABSIZE))*77
	rend
	


		  
if ABSDATE==0

MACRO DEF_ACTION cur,addr	
	db ({cur}-prev) &255
	dw {addr}
	prev = {cur}
mend

else

MACRO DEF_ACTION cur,addr	
	dw {cur}
	dw {addr}	
mend

endif

action_table:		
	
if ABSDATE==0
	dw ACTION_PRESET_HS
	prev=1	
else	
	DEF_ACTION #0001, ACTION_PRESET_HS
endif	

if TEST_PLUS==0
	
	DEF_ACTION #0100, SET_JUMP_VEL1		; FILL
	
	DEF_ACTION #0190, ACTION_HWSCROLL_INV	; Barre
	DEF_ACTION #0200, SET_JUMP_VEL1		; FILL
	DEF_ACTION #0300, ACTION_SET_DAMIER_PAL
	DEF_ACTION #0400, SET_JUMP_VEL1		; FILL
	DEF_ACTION #043F, SET_ALL_BLACKS	
	DEF_ACTION #0440, ACTION_SYNC_SCROLLS		
	DEF_ACTION #0441, ACTION_WHITE_PAL	
else
	DEF_ACTION #0002, SET_ALL_BLACKS	
	DEF_ACTION #0003, ACTION_WHITE_PAL	
	DEF_ACTION #0004, action_toggle_autofgbg					
	DEF_ACTION #0005, ACTION_REBOND_FG							
repeat 32
	DEF_ACTION #0100, ACTION_WHITE_PAL	
rend	

endif
	
	; On commence a rebondir
	DEF_ACTION #0480, ACTION_REBOND_FG							; Debut du rythme, 5 eme pattern
	DEF_ACTION #0481, action_toggle_autofgbg					; Rebond et auto fgbg= ON
	DEF_ACTION #0580, SET_JUMP_VEL1		; FILL
	DEF_ACTION #0680, SET_JUMP_VEL1		; FILL
	DEF_ACTION #0780, ACTION_DAMIER_SCROLL	
	
	DEF_ACTION #0880, SET_JUMP_VEL1		; FILL
	DEF_ACTION #0980, SET_JUMP_VEL1		; FILL
	
	; 1er break
	DEF_ACTION #09EC, ACTION_SPACE_SCROLL	; Scroll = espaces	
	DEF_ACTION #09EE, ACTION_HWSCROLL_INV 	; Doit etre sur une adresse paire
	
	
	DEF_ACTION #0A60,action_toggle_autofgbg	; FG only: a faire au bon moment)	
	
	DEF_ACTION #0A7F,ACTION_3SCROLLS		; 3 scrolls 
	
	
	DEF_ACTION #0A80,SET_BLUE_DAMIER
	
	DEF_ACTION #0A90, ACTION_SHOW_PATTERN_BLOC4	; En bas
	
	DEF_ACTION #0b90, ACTION_SET_COLUMN		;  damier 'décalé'
	DEF_ACTION #0bB0, ACTION_HWSCROLL_INV	
	


	DEF_ACTION #0C00, SET_JUMP_VEL1			; FILL
	
	DEF_ACTION #0C40, ACTION_SYNC_SCROLLS	; 'AST'
	
	
	DEF_ACTION #0C70,ACTION_SET_BJ_PAL03
	DEF_ACTION #0CE0, ACTION_SPACE_SCROLL	; Scroll = espaces	
	
	DEF_ACTION #0d00, SET_JUMP_VEL1			; FILL	
	
	
	DEF_ACTION #0D80, ACTION_TOGGLE_FLASH
	DEF_ACTION #0e00, SET_JUMP_VEL1			; FILL
	
	DEF_ACTION #0EC8, ACTION_SET_DAMIER 
	
	DEF_ACTION #0F00, ACTION_TOGGLE_AUTO_ITALIQUE 				 			
	
	DEF_ACTION #1000, SET_JUMP_VEL1     ; FILL
	DEF_ACTION #1100, SET_JUMP_VEL1		; FILL
	DEF_ACTION #1200, ACTION_SHOW_PATTERN1
	
	DEF_ACTION #1300, SET_JUMP_VEL1		; FILL
	
	DEF_ACTION #13FF, ACTION_TOGGLE_AUTO_ITALIQUE
	
	DEF_ACTION #1468, ACTION_HWSCROLL_INV		; Greetings
	DEF_ACTION #1470, ACTION_NOTRAM
	DEF_ACTION #14D0, ACTION_SYNC_SCROLLS	
	DEF_ACTION #14E0, ACTION_PRESET_HS
	DEF_ACTION #14E1, SET_ALL_BLACKS
	DEF_ACTION #14FE, SET_GREEN_DAMIER
	DEF_ACTION #14FF, SET_YELLOW_SCROLL
	
	DEF_ACTION #1500, SET_JUMP_VEL2			; Rebond plus rapide,doit etre sur une commande paire	
	DEF_ACTION #1501, ACTION_TOGGLE_AUTO_ITALIQUE ; MADE
	DEF_ACTION #1502,action_toggle_autofgbg	
	
	DEF_ACTION #1600, SET_JUMP_VEL2			; FILL
	
	DEF_ACTION #1690, SET_JUMP_VEL2			; FILL	
	DEF_ACTION #1790,action_toggle_autofgbg	

	DEF_ACTION #17fd, ACTION_TOGGLE_AUTO_ITALIQUE
	
	
	DEF_ACTION #17ff, ACTION_SET_FIRST1_12 ; ,ACTION_HWSCROLL_BLOC4
	DEF_ACTION #1800,ACTION_NEXT_PATTERN

	DEF_ACTION #1860,ACTION_NEXT_PATTERN
	DEF_ACTION #1861,ACTION_SET_RED_MAGENTA2

	DEF_ACTION #18C0,ACTION_NEXT_PATTERN
	DEF_ACTION #18c1,ACTION_SET_RED_BLUE_CYAN

	DEF_ACTION #1920,ACTION_NEXT_PATTERN
	DEF_ACTION #1821,ACTION_SET_RED_MAGENTA2

	
	DEF_ACTION #1980,ACTION_NEXT_PATTERN
	DEF_ACTION #1881,ACTION_SET_RED_PURPLE_DAMIER
	
	DEF_ACTION #19E0,ACTION_NEXT_PATTERN
	DEF_ACTION #19E1,ACTION_SET_RED_MAGENTA2
	
	
	DEF_ACTION #1A40,ACTION_NEXT_PATTERN
	DEF_ACTION #1A41,ACTION_SET_RED_BLUE_CYAN
	
	
	DEF_ACTION #1Af0,ACTION_TOGGLE_FLASH
	DEF_ACTION #1B00,ACTION_TOGGLE_AUTO_PATTERN
;	DEF_ACTION #1bC0,ACTION_HWSCROLL_INV ; on n'inverse plus, car on a un changement de palette
	
	DEF_ACTION #1C00, SET_JUMP_VEL2			; FILL
	DEF_ACTION #1D00, SET_JUMP_VEL2			; FILL
	
	; Fin
	DEF_ACTION #1E00, SET_JUMP_VEL2			; FILL	
	DEF_ACTION #1F00, SET_ALL_BLACKS			
	DEF_ACTION #1F80, 0 ; RESET!
	
END_ACTION_TABLE:
	print "ACTION TABLE=",END_ACTION_TABLE-ACTION_TABLE

if DISABLE_KB==0

; Clavier
if (PROD==0)
	INHIBKB db 0
endif
kbstate ds 10
	
endif


charset 32,32+63,1

; A regler en fonction de la largeur d'ecran
; LINEWIDTH == 120 => +1 #40
TXT1    dw space
;last: db "IF YOU'RE STILL SCROLLING... THEN YOU'RE STILL ALIVE!"

TEXTE1  
		db " YET ANOTHER CPC PRODUCTION IN 2018   "
TITLE:	db "'STILL SCROLLING'   A 4KB INTRO BY STEPH/MUSIC2EYE "
		db "   SPECIAL THANKS TO   AST   "
		db " BARJACK ROUDOUDOU TARGHAN OFFSET DEVILMARKUS FLYNN LONE"
		db "  GREETINGS  "
		db " MADE LONGSHOT EPSILON CMP KRIS SID TRONIC PLISSKEN MADRAM TOTO GOLEM13 BDCIRON DRILL   "
		db "      "
space:
if TEST_PLUS==0		
  db " ",0
else
  db "7",0
endif

print "TEXT=",space - TEXTE1
		
	; 512 (#200) octets a placer ou on veut
	; Il faut 1 octet avec 0 avant
	; les caracteres a la fin sont interessants aussi, non?
CARAC_TAB: 
CARAC_TAB_ROM: 

ORG Music_Address  
	INCbin "../resources/mus8000.bin"
MUSIC_END:

org #8800-4-4

macro SCRBLOC hi,lo
		  db {hi}, CRTC_REG_VRAMLO,{lo},8 ; 8 => Pour le SPLIT CRTC
mend

macro SCRBLOCA addr
	SCRBLOC floor({addr}/256), {addr}&255	
mend

; Doit etre aligné sur 256 (-4...)


		SCRBLOCA BLACK_SCREEN_HW_OFFSET

scr_bloc: 						; *** crtc1: 6 au lieu de 8, 12 fois
screen_bloc1:	  
		  repeat 6
		  SCRBLOCA MOIRE2_SCREEN_HW_OFFSET			; Bloc 1a
		  rend		 
		  SCRBLOCA BLACK_SCREEN_HW_OFFSET			; Bloc 
		  SCRBLOCA BLACK_SCREEN_HW_OFFSET			; Bloc 
		  
		  SCRBLOCA BLACK_SCREEN_HW_OFFSET			; 
		  SCRBLOCA BLACK_SCREEN_HW_OFFSET			; 
		  ; Une en plus
		  SCRBLOCA BLACK_SCREEN_HW_OFFSET			; 
		  ;SCRBLOCA BLACK_SCREEN_HW_OFFSET			; 
		  
Player_Address:
	read "../extra/ArkosTrackerPlayer_CPC_MSX.asm"	
PLAYER_END:
;CE: A contient le num de registre
;CS: A contient la valeur lue
PSGREADREGA:
	 ld DE,#4000	; Peut etre fait 1 fois avant
	 LD BC,#F782    
     OUT (C),C
     LD B,#F4     ; Selectionne le
     OUT (C),A    ; Registre
	 
     LD BC,#F6C0  ;Paf
     OUT (C),C     
     OUT (C),E	  ; F6 <=0
	 
     LD BC,#F792    ; OUTI?
     OUT (C),C     
	 dec B
     OUT (C),D	  ; F7<=40
     LD B,#F4     ; 
     IN A,(C)     ; Lecture F4

	; Desactiver? => on ne pourrait le faire 1 fois , quand on a tout lu
	 LD BC,#F782 
     OUT (C),C
     dec B
     OUT (C),E ; F6<=0 
	 ret



; Autres blocs
ORG #8f00 ;#A100
; Palette Split raster
; =>Doit etre aligné sur 256
COLOR_SPLIT_RAST:
COLOR_SPLIT_CRTC:

flash_pal2:	; Bleu ciel/blanc 
BJRASTCOL03:
	ds 22,#53			; optim: décaller le compteur de 22 comme ca on a 44 fois la meme valeur consécutive
	ds 22,#53
	db #5b
WHITE_PAL:
	db GA_WHITE,GA_WHITE,#5b

flash_pal: ; Blanc/jaune
	ds 22,#4a
	ds 22,#4a	
	db #43,#4B,#4B,#43

BJRASTCOL01: db GA_BLUE
VIOLET_PAL: 
BJRASTCOL02: db #5C ; Marron (03)
BJRASTCOL1: db GA_BLUE_SKY
BJRASTCOL2: db GA_MAGENTA_BRIGHT
BJRASTCOL3: db GA_ORANGE
BJRASTCOL4: db GA_YELLOW
BJRASTCOL5: db GA_GREEN_BRIGHT

;SAVE "STILL.BIN",#9000,CARAC_TAB-#8000,DSK,"STILL.DSK" 