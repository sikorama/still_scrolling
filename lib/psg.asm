; Liste des Registres du PSG
; http://quasar.cpcscene.net/doku.php?id=assem:psg


PSG_PERIOD_AL 	 EQU 0
PSG_PERIOD_AH 	 EQU 1
PSG_PERIOD_BL 	 EQU 2
PSG_PERIOD_BH 	 EQU 3
PSG_PERIOD_CL 	 EQU 4
PSG_PERIOD_CH 	 EQU 5
PSG_NOISE 		 EQU 6 ; 0-31
PSG_CTRL 		 EQU 7
PSG_VOLA 		 EQU 8
PSG_VOLB 		 EQU 9
PSG_VOLC 		 EQU 10
PSG_ENV_PERIODEL EQU 11
PSG_ENV_PERIODEH EQU 12
PSG_ENV_SHAPE    EQU 13


PSG_CTRL_BIT_ENA	  EQU 0 ; Si a 0, on a du son
PSG_CTRL_BIT_ENB	  EQU 1
PSG_CTRL_BIT_ENC	  EQU 2
PSG_CTRL_BIT_NOISEA	  EQU 3 ; Si a 0, on a du noise
PSG_CTRL_BIT_NOISEB	  EQU 4
PSG_CTRL_BIT_NOISEC	  EQU 5
PSG_CTRL_BIT_SELAUDIO EQU 6 ; Pour selectionner le clavier/L'audio

PSG_CTRL_MUTE_A EQU (1<<PSG_CTRL_BIT_ENA)
PSG_CTRL_MUTE_B EQU (1<<PSG_CTRL_BIT_ENB)
PSG_CTRL_MUTE_C EQU (1<<PSG_CTRL_BIT_ENC)

PSG_CTRL_MUTE_NOISE_A EQU (1<<PSG_CTRL_BIT_NOISEA)
PSG_CTRL_MUTE_NOISE_B EQU (1<<PSG_CTRL_BIT_NOISEB)
PSG_CTRL_MUTE_NOISE_C EQU (1<<PSG_CTRL_BIT_NOISEC)

PSG_CTRL_SEL_AUDIO EQU (1<<PSG_CTRL_BIT_SELAUDIO)

; Controle du pitch des notes pour A,B,C
; Codé sur 12 bits
; Periode = 62500/Freq 
MACRO PSG_Periode freq
dw 62500/{freq}
MEND

MACRO PSG_FREQTABLE freqbase
	f={freqbase}
	REPEAT 12,cnt
		f=f*1.059463
		PSG_Periode f		
		print {freqbase},cnt,f,62500/f
	REND
MEND

MACRO PSG_NOTE freqbase,noterel
	f={freqbase}
	REPEAT {noterel},cnt
		f=f*1.059463
	REND
	PSG_Periode f
	print {freqbase},f,62500/f
MEND

; Routine de lecture de registre du  psg  (par madram)
; Recuperer reg 8,9,10 pour les volumes
;
MACRO PSGREADREG_A
	 LD BC,#F782
     OUT (C),C
     LD B,#F4     ; Selectionne le
     OUT (C),A    ; Registre
     LD BC,#F6C0  ;Paf!
     OUT (C),C
     XOR A
     OUT (C),A
     LD BC,#F792
     OUT (C),C
     LD BC,#F640
     OUT (C),C
     LD B,#F4     ; Ici on vient lire
     IN A,(C)     ; sa valeur
     LD BC,#F782
     OUT (C),C
     LD BC,#F600
     OUT (C),C
MEND


; CE: E contient le numéro de registre à écrire
;     A contient la valeur
; CS: B,C,D modifiés

macro PSG_SET_REG
	ld   D,0
	ld   B,#f4
	out  (C),E
	ld   BC,#f6c0
	out  (C),C	
	out  (C),D
	ld   B,#f4
	out  (C),A
	ld   BC,#f680
	out  (C),C	
	out  (C),D
mend


; PSG_440hz = #08E
