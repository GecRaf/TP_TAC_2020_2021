;------------------------------------------------------------------------
;	Base para TRABALHO PRATICO - TECNOLOGIAS e ARQUITECTURAS de COMPUTADORES
;   
;	ANO LECTIVO 2020/2021
;--------------------------------------------------------------
; Demostra��o da navega��o do Ecran com um avatar
;
;		arrow keys to move 
;		press ESC to exit
;
;------------------------------------------------------------------------
; MACROS
;------------------------------------------------------------------------
;MACRO GOTO_XY
; COLOCA O CURSOR NA POSIÇÃO POSX,POSY
;	POSX -> COLUNA
;	POSY -> LINHA
; 	REGISTOS USADOS
;		AH, BH, DL,DH (DX)
;------------------------------------------------------------------------
GOTO_XY		MACRO	POSX,POSY
			MOV	AH,02H
			MOV	BH,0
			MOV	DL,POSX
			MOV	DH,POSY
			INT	10H
ENDM
;--------------------------------------------------------------
; MOSTRA - Faz o display de uma string terminada em $
;---------------------------------------------------------------------------
MOSTRA MACRO STR 
MOV AH,09H
LEA DX,STR 
INT 21H
ENDM
; FIM DAS MACROS

.8086
.model small
.stack 2048

PILHA	SEGMENT PARA STACK 'STACK'
		db 2048 dup(?)
PILHA	ENDS

dseg	segment para public 'data'


		STR12	 		db 		"            "	; String para 12 digitos
		NUMERO			db		"                    $" 	; String destinada a guardar o número lido
		NUM_SP			db		"                    $" 	; PAra apagar zona de ecran
		DDMMAAAA 		db		"            "
		
		Horas			dw		0				; Vai guardar a HORA actual
		Minutos			dw		0				; Vai guardar os minutos actuais
		Segundos		dw		0				; Vai guardar os segundos actuais
		Segundos_jogo	dw		0				; Vai guardar os segundos de jogo
		centenas		dw		0				; Centenas de segundos
		Old_seg			dw		0				; Guarda os �ltimos segundos que foram lidos
		Tempo_init		dw		0				; Guarda O Tempo de inicio do jogo
		Tempo_j			dw		0				; Guarda O Tempo que decorre o  jogo
		Tempo_limite	dw		100				; tempo m�ximo de Jogo
		String_TJmax	db		"    /100$"
		Str_tempoJogo	db		"            "  ; stirng para tempo de jogo decorrido

		String_num 		db 		"  0 $"
        String_nome1  	db	    "TAC $"
		String_nome2  	db	    "ISEC $"
		String_nome3  	db	    "COIMBRA $"
		String_nome4  	db	    "ASSEMBLY $"	
		String_nome5  	db	    "COMPUTADORES $"
		Construir_nome1	db	    "    $"
		Construir_nome2	db	    "     $"
		Construir_nome3	db	    "        $"
		Construir_nome4	db	    "         $"
		Construir_nome5	db	    "             $"
		Dim_nome1		dw		4	; Comprimento do Nome
		Dim_nome2		dw		5
		Dim_nome3		dw		8
		Dim_nome4		dw		9
		Dim_nome5		dw		13
		indice_nome		dw		0	; indice que aponta para Construir_nome
		
		Fim_Ganhou		db	    " Ganhou! $"	
		Fim_Perdeu		db	    " Perdeu! $"	

        Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
        Fich         	db      'labi5.TXT',0
		Fich2         	db      'labi2.TXT',0
		Fich3         	db      'labi3.TXT',0
		Fich4         	db      'labi4.TXT',0
		Fich5         	db      'labi5.TXT',0
		Menu 			DB		'menu2.TXT',0
		MenuNiveis 		DB		'menuNiveis.TXT',0
		About   		db      "I am some text about the program!$" ; Teste ao menu, remover mais tarde
        HandleFich      dw      0
        car_fich        db      ?
		HandleMenu      dw      0
		car_Menu        db      ?

		string			db	"Teste pr�tico de T.I",0
		Car				db	32	; Guarda um caracter do Ecran 
		Cor				db	7	; Guarda os atributos de cor do caracter
		POSy			db	3	; a linha pode ir de [1 .. 25]
		POSx			db	3	; POSx pode ir [1..80]	
		POSya			db	3	; Posi��o anterior de y
		POSxa			db	3	; Posi��o anterior de x
		NUMDIG			db	0	; controla o numero de digitos do numero lido
		MAXDIG			db	4	; Constante que define o numero MAXIMO de digitos a ser aceite
dseg	ends

cseg	segment para public 'code'
assume		cs:cseg, ds:dseg

;********************************************************************************
;********************************************************************************
; HORAS  - LE Hora DO SISTEMA E COLOCA em tres variaveis (Horas, Minutos, Segundos)
; CH - Horas, CL - Minutos, DH - Segundos
;********************************************************************************	

Ler_TEMPO PROC	
 
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
	
		PUSHF
		
		mov AH, 2CH             ; Buscar a hORAS
		int 21H                 
		
		xor AX,AX
		mov AL, DH              ; segundos para al
		mov Segundos, AX		; guarda segundos na variavel correspondente
		
		xor AX,AX
		mov AL, CL              ; Minutos para al
		mov Minutos, AX         ; guarda MINUTOS na variavel correspondente
		
		xor AX,AX
		mov AL, CH              ; Horas para al
		mov Horas,AX			; guarda HORAS na variavel correspondente
 
		POPF
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
Ler_TEMPO   ENDP 

;********************************************************************************
;********************************************************************************	
;-------------------------------------------------------------------
; HOJE - LE DATA DO SISTEMA E COLOCA NUMA STRING NA FORMA DD/MM/AAAA
; CX - ANO, DH - MES, DL - DIA
;-------------------------------------------------------------------
HOJE PROC	

		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		PUSH SI
		PUSHF
		
		MOV AH, 2AH             ; Buscar a data
		INT 21H                 
		PUSH CX                 ; Ano-> PILHA
		XOR CX,CX              	; limpa CX
		MOV CL, DH              ; Mes para CL
		PUSH CX                 ; Mes-> PILHA
		MOV CL, DL				; Dia para CL
		PUSH CX                 ; Dia -> PILHA
		XOR DH,DH                    
		XOR	SI,SI
; DIA ------------------ 
; DX=DX/AX --- RESTO DX   
		XOR DX,DX               ; Limpa DX
		POP AX                  ; Tira dia da pilha
		MOV CX, 0               ; CX = 0 
		MOV BX, 10              ; Divisor
		MOV	CX,2
DD_DIV:                         
		DIV BX                  ; Divide por 10
		PUSH DX                 ; Resto para pilha
		MOV DX, 0               ; Limpa resto
		loop dd_div
		MOV	CX,2
DD_RESTO:
		POP DX                  ; Resto da divisao
		ADD DL, 30h             ; ADD 30h (2) to DL
		MOV DDMMAAAA[SI],DL
		INC	SI
		LOOP DD_RESTO            
		MOV DL, '/'             ; Separador
		MOV DDMMAAAA[SI],DL
		INC SI
; MES -------------------
; DX=DX/AX --- RESTO DX
		MOV DX, 0               ; Limpar DX
		POP AX                  ; Tira mes da pilha
		XOR CX,CX               
		MOV BX, 10				; Divisor
		MOV CX,2
MM_DIV:                         
		DIV BX                  ; Divisao or 10
		PUSH DX                 ; Resto para pilha
		MOV DX, 0               ; Limpa resto
		LOOP MM_DIV
		MOV CX,2 
MM_RESTO:
		POP DX                  ; Resto
		ADD DL, 30h             ; SOMA 30h
		MOV DDMMAAAA[SI],DL
		INC SI		
		LOOP MM_RESTO
		
		MOV DL, '/'             ; Character to display goes in DL
		MOV DDMMAAAA[SI],DL
		INC SI
 
;  ANO ----------------------
		MOV DX, 0               
		POP AX                  ; mes para AX
		MOV CX, 0               ; 
		MOV BX, 10              ; 
 AA_DIV:                         
		DIV BX                   
		PUSH DX                 ; Guarda resto
		ADD CX, 1               ; Soma 1 contador
		MOV DX, 0               ; Limpa resto
		CMP AX, 0               ; Compara quotient com zero
		JNE AA_DIV              ; Se nao zero
AA_RESTO:
		POP DX                  
		ADD DL, 30h             ; ADD 30h (2) to DL
		MOV DDMMAAAA[SI],DL
		INC SI
		LOOP AA_RESTO
		POPF
		POP SI
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
HOJE   ENDP 


;********************************************************************************
;********************************************************************************
;ROTINA PARA APAGAR ECRAN

APAGA_ECRAN	PROC
		PUSH BX
		PUSH AX
		PUSH CX
		PUSH SI
		XOR	BX,BX
		MOV	CX,24*80
		mov bx,160
		MOV SI,BX
APAGA:	
		MOV	AL,' '
		MOV	BYTE PTR ES:[BX],AL
		MOV	BYTE PTR ES:[BX+1],7
		INC	BX
		INC BX
		INC SI
		LOOP	APAGA
		POP SI
		POP CX
		POP AX
		POP BX
		RET
APAGA_ECRAN	ENDP

;********************************************************************************
;********************************************************************************
; LEITURA DE UMA TECLA DO TECLADO 
; LE UMA TECLA	E DEVOLVE VALOR EM AH E AL
; SE ah=0 É UMA TECLA NORMAL
; SE ah=1 É UMA TECLA EXTENDIDA
; AL DEVOLVE O CÓDIGO DA TECLA PREMIDA
LE_TECLA	PROC
sem_tecla:
		call Trata_Horas
		MOV	AH,0BH
		INT 21h
		cmp AL,0
		je	sem_tecla
		
	
		
		MOV	AH,08H
		INT	21H
		MOV	AH,0
		CMP	AL,0
		JNE	SAI_TECLA
		MOV	AH, 08H
		INT	21H
		MOV	AH,1
SAI_TECLA:	
		RET
LE_TECLA	ENDP




;********************************************************************************
;********************************************************************************
; Imprime o tempo e a data no monitor

Trata_Horas PROC

		PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX		

		call 	Ler_TEMPO				; Horas MINUTOS e segundos do Sistema
		
		mov		AX, Segundos
		cmp		AX, Old_seg			; Verifica se os segundos mudaram desde a ultima leitura
		je		fim_horas			; Se a hora não mudou desde a última leitura sai.
		mov		Old_seg, AX			; Se segundos são diferentes actualiza informação do tempo 
		
		mov 	ax,Horas
		mov		bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		mov 	STR12[0],al			; 
		mov 	STR12[1],ah
		mov 	STR12[2],'h'		
		mov 	STR12[3],'$'
		goto_xy 2,0
		MOSTRA STR12 		
        
		mov 	ax,Minutos
		mov 	bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		mov 	STR12[0],al			; 
		mov 	STR12[1],ah
		mov 	STR12[2],'m'		
		mov 	STR12[3],'$'
		goto_xy	6,0
		MOSTRA	STR12 		
		
		mov 	ax,Segundos
		mov 	bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		mov 	STR12[0],al			; 
		mov 	STR12[1],ah
		mov 	STR12[2],'s'		
		mov 	STR12[3],'$'
		goto_xy	10,0
		MOSTRA	STR12 		
        
		goto_xy	57,0
		

		inc 	Segundos_jogo
		mov		ax, Segundos_jogo
		mov 	bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		mov		STR12[0], al
		mov		STR12[1], ah
		mov 	STR12[2],'s'		
		mov 	STR12[3],'$'

		MOSTRA	STR12
		cmp		Segundos_jogo, 100
		;MOSTRA 	STR12 ; Arranja maneira de mostrar os 100 segundos. Ele chega ao 99 e salta
						; como ele depois não mostra mais a string não dá print ao nr 100
						; ve se da para resolver
		je		PERDEU

		;mul		

	;centenas_f:
	;	inc		centenas
	;	mov		ax, centenas
	;	mov		STR12[0], al
	;	mov		STR12[1], 0
	;	mov 	STR12[2], 0		
	;	mov 	STR12[3],'s'
	;	mov 	STR12[3],'$'
	;	goto_xy	57,0
	;	MOSTRA	STR12 	
	
	
	
fim_horas:		
		goto_xy	POSx,POSy			; Volta a colocar o cursor onde estava antes de actualizar as horas
		
		POPF
		POP DX		
		POP CX
		POP BX
		POP AX
		RET		

PERDEU:
			goto_xy 25, 21
			MOSTRA Fim_Perdeu
			mov	Segundos_jogo, 0
			jmp fim

fim: 
		mov		ah, 4ch ; Não é bem assim que quero acabar, tenho de ver uma maneira melhor
		int		21h

Trata_Horas ENDP


;########################################################################

teclanum  proc
		mov	ax, dseg
		mov	ds,ax
		mov	ax,0B800h
		mov	es,ax		; es é ponteiro para mem video

NOVON:	
		mov		NUMDIG, 0			; inícia leitura de novo número
		mov		cx, 20
		xor		BX,BX
LIMPA_N: 	
		mov		NUMERO[bx], ' '	
		inc		bx
		loop 	LIMPA_N
		
		mov		al, 20
		mov		POSx,al
		mov		al, 10
		mov		POSy,al				; (POSx,POSy) é posição do cursor
		goto_xy	POSx,POSy
		MOSTRA	NUM_SP	

CICLO:	goto_xy	POSx,POSy
	
		call 	LE_TECLA		; lê uma nova tecla
		cmp		ah,1			; verifica se é tecla extendida
		je		ESTEND
		cmp 	AL,27			; caso seja tecla ESCAPE sai do programa
		je		FIM
		cmp 	AL,13			; Pressionando ENTER vai para OKNUM
		je		OKNUM		
		cmp 	AL,8			; Teste BACK SPACE <- (apagar digito)
		jne		NOBACK
		mov		bl,NUMDIG		; Se Pressionou BACK SPACE 
		cmp		bl,0			; Verifica se não tem digitos no numero
		je		NOBACK			; se não tem digitos continua então não apaga e salta para NOBACK

		dec		NUMDIG			; Retira um digito (BACK SPACE)
		dec		POSx			; Retira um digito	

		xor		bx,bx
		mov		bl, NUMDIG
		mov		NUMERO[bx],' '	; Retira um digito		
		goto_xy	POSx,POSy
		mov		ah,02h			; imprime SPACE na possicão do cursor
		mov		dl,32			; que equivale a colocar SPACE 
		int		21H

NOBACK:	
		cmp		AL,30h			; se for menor que tecla do ZERO
		jb		CICLO
		cmp		AL,39h			; ou se for maior que tecla do NOVE 
		ja		CICLO			; é rejeitado e vai buscar nova tecla 
		
		mov		bl,MAXDIG		; se atigido numero máximo de digitos ?	
		cmp		bl,NUMDIG	
		jbe		CICLO			; não aceita mais digitos
		xor		Bx, Bx			; caso contrario coloca digito na matriz NUMERO
		mov		bl, NUMDIG
		mov		NUMERO[bx], al		
		mov		ah,02h			; imprime digito 
		mov		dl,al			; na possicão do cursor
		int		21H

		inc		POSx			; avança o cursor e
		inc		NUMDIG			; incrementa o numero de digitos

ESTEND:	jmp	CICLO			; Tecla extendida não é tratada neste programa 

OKNUM:	goto_xy	20,16
		MOSTRA	NUM_SP			
		goto_xy	20,16		
		xor		bx,bx
		mov		bl, NUMDIG
		inc 	bl
		mov		NUMERO[bx], '$'			
		MOSTRA	NUMERO 
		jmp		NOVON		; Vai ler novo numero

fim:	ret

teclanum ENDP

;########################################################################
;goto_xy	macro		POSx,POSy
;		mov		ah,02h
;		mov		bh,0		; numero da p�gina
;		mov		dl,POSx
;		mov		dh,POSy
;		int		10h
;endm

;########################################################################
; MOSTRA - Faz o display de uma string terminada em $

;MOSTRA MACRO STR 
;	mov AH,09H
;	lea DX,STR 
;	int 21H
;ENDM

; FIM DAS MACROS



;ROTINA PARA APAGAR ECRAN

;apaga_ecran	proc
;			mov		ax,0B800h
;			mov		es,ax
;			xor		bx,bx
;			mov		cx,25*80
;		
;apaga:		mov		byte ptr es:[bx],' '
;			mov		byte ptr es:[bx+1],7
;			inc		bx
;			inc 	bx
;			loop	apaga
;			ret
;apaga_ecran	endp

;########################################################################
; IMP_MENU

IMP_MENU	PROC
ShowMenu:
		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,Menu
        int     21h
        jc      erro_abrir
        mov     HandleFich,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleFich
        mov     cx,1
        lea     dx,car_fich
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_fich
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai_f

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai_f:	
		jmp getnum

getnum:        
    mov     ah, 1 
    int     21h        
    
    cmp     al, '1' 
    jl      ShowMenu   
    cmp     al, '3'
    jg      ShowMenu 
        
    cmp     al, "1"
    je      Jogo
    cmp     al, "2"
    je      ShowAbout
    cmp     al, "3"
    jmp     Quit
;    cmp     al, "4"
;    jmp     CodeForMenu4
;    etc...
        
Quit: 
   mov   ah,4ch
   int   21h   

Showabout:       
    lea     dx, About  
    mov     ah, 09h 
    int     21h    
    jmp     ShowMenu
    
Jogo:
	call	apaga_ecran

fim: 
			ret
		
IMP_MENU	endp

;########################################################################
; IMP_FICH

IMP_FICH	PROC

		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,Fich
        int     21h
        jc      erro_abrir
        mov     HandleFich,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleFich
        mov     cx,1
        lea     dx,car_fich
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_fich
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai_f

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai_f:	
		RET
		
IMP_FICH	endp		

;########################################################################
; LE UMA TECLA	

;LE_TECLA	PROC
		
;		mov		ah,08h
;		int		21h
;		mov		ah,0
;		cmp		al,0
;		jne		SAI_TECLA
;		mov		ah, 08h
;		int		21h
;		mov		ah,1
;SAI_TECLA:	RET
;LE_TECLA	endp



;########################################################################
; Avatar

AVATAR	PROC
			mov		ax,0B800h
			mov		es,ax

			goto_xy	POSx,POSy		; Vai para nova possi��o
			mov 	ah, 08h			; Guarda o Caracter que est� na posi��o do Cursor
			mov		bh,0			; numero da p�gina
			int		10h			
			mov		Car, al			; Guarda o Caracter que est� na posi��o do Cursor
			mov		Cor, ah			; Guarda a cor que est� na posi��o do Cursor

			goto_xy 9,20
			MOSTRA	String_nome1	
			goto_xy 9,21
			MOSTRA	Construir_nome1
					
CICLO:	
			goto_xy	POSxa,POSya		; Vai para a posi��o anterior do cursor
			mov		ah, 02h
			mov		dl, Car			; Repoe Caracter guardado 
			int		21H
			goto_xy	POSx,POSy		; Vai para nova possi��o
			mov 	ah, 08h
			mov		bh,0			; numero da p�gina
			int		10h		
			mov		Car, al			; Guarda o Caracter que est� na posi��o do Cursor
			mov		Cor, ah			; Guarda a cor que est� na posi��o do Cursor
		
			goto_xy	78,0							
			mov		ah, 02h			; Mostra o caractr que estava na posi��o do AVATAR
			mov		dl, Car			; IMPRIME caracter da posi��o no canto
			int		21H

			

			goto_xy 57,0
			MOSTRA	String_TJmax

			goto_xy	POSx,POSy
			cmp		al, String_nome1[si]
			jne		IMPRIME
			mov  	al, String_nome1[si]
			mov		Construir_nome1[si], al
			inc 	si
			xor 	di,di
			repete:
			mov		al, String_nome1[di]
			cmp     al, '$'
			je     	GANHOU ;acertou
			cmp		Construir_nome1[di], al
			goto_xy 9,21
			MOSTRA	Construir_nome1
			goto_xy	POSx,POSy
			jne 	IMPRIME ;diferentes
			inc 	di
			jmp     repete
			;goto_xy	POSx,POSy		; Vai para posi��o do cursor
			

IMPRIME:	
			mov		ah, 02h
			mov		dl, 190			; Coloca AVATAR
			int		21H	
			goto_xy	POSx,POSy	; Vai para posi��o do cursor
		
			mov		al, POSx	; Guarda a posi��o do cursor
			mov		POSxa, al
			mov		al, POSy	; Guarda a posi��o do cursor
			mov 	POSya, al


		
LER_SETA:	call 	LE_TECLA
			cmp		ah, 1
			je		ESTEND
			cmp 	al, 27	; ESCAPE
			je		Main
			jmp		LER_SETA
		
ESTEND:		cmp 	al,48h
			jne		BAIXO
			dec		POSy		;Cima
			goto_xy    POSx,POSy      
            mov     ah, 08h
            mov     bh,0        
            int     10h  
			cmp		al,177
			je 		INC_Y
			jmp		CICLO

BAIXO:		cmp		al,50h
			jne		ESQUERDA
			inc 	POSy		;Baixo
			goto_xy    POSx,POSy      
            mov     ah, 08h
            mov     bh,0        
            int     10h  
			cmp		al,177
			je 		DEC_Y
			jmp		CICLO

ESQUERDA:
			cmp		al,4Bh
			jne		DIREITA
			dec		POSx		;Esquerda
			goto_xy    POSx,POSy      
            mov     ah, 08h
            mov     bh,0        
            int     10h  
			cmp		al,177
			je 		INC_X
			jmp		CICLO

DIREITA:
			cmp		al,4Dh
			jne		LER_SETA
			inc		POSx		;Direita
			goto_xy    POSx,POSy      
            mov     ah, 08h
            mov     bh,0        
            int     10h  
			cmp		al,177
			je 		DEC_X
			jmp		CICLO

INC_Y:
			inc POSy
        	goto_xy	POSx,POSy		; Para o cursor ficar sempre em baixo do avatar
			mov 	ah, 08h
			mov		bh,0			
			int		10h	
			jmp 	LER_SETA

INC_X:
			inc POSx
        	goto_xy	POSx,POSy		; Para o cursor ficar sempre em baixo do avatar
			mov 	ah, 08h
			mov		bh,0			
			int		10h	
			jmp 	LER_SETA

DEC_Y:
			dec POSy
        	goto_xy	POSx,POSy		; Para o cursor ficar sempre em baixo do avatar
			mov 	ah, 08h
			mov		bh,0			
			int		10h	
			jmp 	LER_SETA

DEC_X:
			dec POSx
        	goto_xy	POSx,POSy		; Para o cursor ficar sempre em baixo do avatar
			mov 	ah, 08h
			mov		bh,0			
			int		10h	
			jmp 	LER_SETA

GANHOU:
			;call apaga_ecran
			goto_xy 25, 21
			MOSTRA Fim_Ganhou
			jmp fim
			;jmp fim

fim:				
			ret
AVATAR		endp

;########################################################################
; Mostra menu após dar ESCAPE
;########################################################################
MOSTRA_MENU PROC
			call 	apaga_ecran
			jmp		IMP_MENU
MOSTRA_MENU endp
;########################################################################
Main  proc
		mov			ax, dseg
		mov			ds,ax
		
		xor 		si,si

		mov			ax,0B800h
		mov			es,ax
		
		call		apaga_ecran
		call		IMP_MENU
		goto_xy		0,0
		call		IMP_FICH
		call 		AVATAR
		goto_xy		0,22
		
		mov			ah,4CH
		INT			21H
Main	endp
Cseg	ends
end	Main
		
