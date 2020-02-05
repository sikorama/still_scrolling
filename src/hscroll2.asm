; Hard Scroll Mode 0, qui utilise 2 'ecrans' pour avoir une precision
; a l'octet (pas au pixel, il faudrait 2 ecrans en plus)
; V2

HS_NBBLOCS  EQU 8

SCROLL:
		LD 		A,(subscroll)				
		and 1 						
		jr z,flip1
		
		ld HL,HWSCROLL_OFFSET
		ld DE,LINEWIDTH-2-2
		jr flip
flip1:
		ld HL,HWSCROLL_OFFSET+2				; 2eme écran: plus bas
		ld DE,LINEWIDTH-1-2					; et decalé de 1 octet
flip:
			ld (scr_adr1+1),HL
			ld (scr_adr2+1),HL
			ld (scr_adr4+1),DE

		;Compteur pour calculer l'offset hardware #0 - #01FF
scr_adr1
        LD      HL,(HWSCROLL_OFFSET) 
        INC     HL 
        RES     2,H 
scr_adr2
        LD      (HWSCROLL_OFFSET),HL 
		push HL
		;on ajoute #30 (pour #C0)	
        LD      A,H
        OR      #30		
		ld (scroll_hwoffset+1),a
		ld a,l
		ld (scroll_hwoffset),a

        LD      HL,(TXT1) 
        LD      L,(HL) 	       
        LD      H,0 
       
 	    ADD     HL,HL  ; *8
        ADD     HL,HL 
        ADD     HL,HL         		
		LD      BC,CARAC_TAB-1-8 ; on decale de 1 caracter et 1 octet
        ADD     HL,BC 
        
		EX      DE,HL 
        
scr_adr3
		pop HL
		;LD      HL,(HWSCROLL_OFFSET) 		
        ADD     HL,HL 		
        SET     7,H
        SET     6,H 
scr_adr4
        LD      BC,LINEWIDTH
        ADD     HL,BC 
        RES     3,H 
        
TXT2:	LD      A,#08					; Decallage fin des 2 scrolls
        LD      C,A 
	
        LD      B,HS_NBBLOCS
SCR1    PUSH    BC 
        PUSH    DE 
		
        ; Ici on peut faire un effet de 'damier'
		ld a,B
decalaa:	inc  a		; On decale de 1 pour bien aligner)
					; on peut s'amuser a  xor #3d (nop/dec a)
		and 2		; Frequence
		jr z,dam1
		xor a
		jr dam3
dam1:
		ld a,7
dam3:
		ld (damadd+1),a	
		
		LD      A,(DE)
		AND 	C	
		; Pour inverser FG/BG on remplace nop par xor c		
invscr:	  nop 
        

        ld d,a

CUR_TABMODE0:
		ld b,	floor(tabmode0/256) 		; pas nécessaire de le calculer a chaque fois?
		LD      a,(colcnt+1)
		and 254
damadd:	add 0
		ld 		c,a
		ld 		a,(bc)				
		ld 		e,a	
		inc bc
		
		ld a,(bc)		
		ld c,a
		  
		ld a,d
		or a	
		JR      Z,SCR4
		
		; Forcement 8-1, le calcul de la ligne suivant est optimisé		
		LD      B,8-1
SCR3    LD      (HL),E         
		INC     hl 	   ; attention à rester dans la mémoire écran         			
		LD      (HL),C
		DEC HL
		LD      a,h 	; Calcul ligne suivante
        ADD     8 
        LD      h,a 		
        djnz SCR3		
		
		; Il faut proteger celui ci car il risque de deborder
		LD      (HL),E 
        PUSH HL
		INC     hl 	   
		set 6,h
		set 7,h		
		LD      (HL),C
		POP HL
		
		;LD      a,h 	; debut Calcul ligne suivante
        ;ADD     8 
        ;LD      h,a 		
		jr SCR_NXTBLOC
		
SCR4  
		LD  B,4-1
TRAM1:
		ld  e,#80 ; Tramage, alternace #80 et #40
TRAM2:
		ld  C,#40 
SCR4L    
		LD      (HL),e        
		INC     HL 	   
		LD      (HL),e        
		DEC 	HL

		LD      a,h 	; Calcul ligne suivante
        ADD     8 
        LD      h,a 

		LD      (HL),c 
        INC     HL 	   
		LD      (HL),c        
		DEC 	HL

		LD      a,h 	; Calcul ligne suivante
        ADD     8 
        LD      h,a 

        djnz SCR4L

		LD      (HL),e ; LDI pour aller plus vite?        
		INC     HL 	   
		LD      (HL),e        
		DEC 	HL

		LD      a,h 	; Calcul ligne suivante
        ADD     8 
        LD      h,a 

		; Il faut proteger celui ci car il risque de deborder
		LD      (HL),c 
		push HL
        INC     HL 	   
		set 	6,h      ; Pour  rester dans la mémoire écran		
		set 	7,h		
		LD      (HL),c        
		;DEC 	HL
		POP HL

		;LD      a,h 	; Calcul ligne suivante
        ;ADD     8 
        ;LD      h,a 
		
SCR_NXTBLOC
        LD      a,h   ;
        SUB     #38		; comme on n'a pas fait le dernier, +8, on fait #40-8
        LD      h,a 
        LD      a,l 
        ADD     a,LINEWIDTH
        LD      l,a 
        jr  nc , nxt
        INC     h 
        RES     3,H 
nxt:		
        POP     DE 
        INC     DE 
		
        POP     BC 
        DJNZ    SCR1 
		
		ld a,(subscroll)
		inc a
LETWIDTH and 3		; and 1 pour avoir une largeur standard. and 3 pour avoir qqche de plus allongé
		ret nz	
		
		; Colonne suivante
		LD      A,(TXT2+1)
		RRA 
		JR      NC,SCR6 
		
		; Passage a la lettre suivante	
		; gérer caractère spéciaux : ESPACE == DEMI CARACTERE
        LD      HL,(TXT1) 
        INC     HL 
        
		LD      A,(HL) 
		or a
		JR Z,RESETMASK
		LD      (TXT1),HL 
		cp 1
		LD A,#08 
		jr z,SCR6				

RESETMASK:
        LD      A,#80 
SCR6    LD      (TXT2+1),A 
SCROLL_END:
        RET 
		
		
		