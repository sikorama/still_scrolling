; Macro pour generer un bloc de split raster
SPLIT_DEFAULT_HEIGHT EQU 16

macro split_raster_line numb
					exx
					CHECK_LINE_VRAM 0
					exx
split_raster_3cycles{numb}:
					add a,(HL)		; 2 cycles : nop nop
					nop				; 3 cycles: add a,(hl) nop
									; 4 cycles: add a,(hl) add a,(hl)
									
					ld HL,(split_colorindex)									
split_raster_size{numb}:
					ld c,SPLIT_DEFAULT_HEIGHT	; Taille+1
					ld a,i
					add c
					ld i,a
					dec c
					ds 4
				
					
@splitrasterl:			
					; Change la couleur
					ld e,(hl)									
					ds 1
split_raster_out{numb}:
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D					
					OUT (C),D
					OUT (C),D
					
.incl:				;inc l	; passe a la couleur suivante => peut etre zappé pour le final
					nop
					
					DEC c
					JR NZ,@splitrasterl
					
					OUT (C),D
					nop
					nop
					ld a,i 	; Pas utile, on ne change pas A (3 cycles)
					
mend


; Macro pour generer un bloc de split crtc
; D et E contiennent les valeurs a envoyer au reg 8 (6) pour dessiner
macro split_crtc_line numb
					CHECK_LINE_VRAM 0
					outi			; Rétablit le reg8 	(reg6 sur crtc1)
					inc b 			; b = #BD

split_crtc_3cycles{numb}:
					add a,(HL)		; 2 cycles : nop nop (0 0)
					nop				; 3 cycles: add a,(hl) nop 86 0
									; 4 cycles: add a,(hl) add a,(hl)									 
					
					
split_crtc_size{numb}:									
					ld c,SPLIT_DEFAULT_HEIGHT		; Taille+1
					exx
					
					; On a pas besoin de remettre H a chaque fois
					; Il faut le faire pointer sur le bon bloc de 256 octets
					;ld HL,COLOR2+{numb}*2	; 3 cycles, mais on n'a plus de décalage en fonction de la position...
					;ld a,(split_colorindex)
					;ld l,a
					
					ld hL,(split_colorindex)		 ; 5 cycles!!!
					ld e,(hl)						 ; si e ne change jamais...
					;ld B,GA_PORT_H	
					exx
					
					ld a,i
					add c
					ld i,a
					dec c
				
					
					
					;nop

@splitcrtcl:
					exx
					; Change la couleur du border et passe a la couleur suivante					
					;outi
					;inc B					
					ld b, GA_PORT_H
					out (c),e
					
					exx
					
split_crtc_out{numb}:
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					OUT (C),D
					
					OUT (C),D
					OUT (C),D
					OUT (C),D
				
				
					DEC C
					JR NZ,@splitcrtcl				
					
					OUT (C),D
					nop
					;ld a,i
mend
