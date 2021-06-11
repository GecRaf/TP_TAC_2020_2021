;********************************************************************************	
;	TRABALHO PRATICO - TECNOLOGIAS e ARQUITECTURAS de COMPUTADORES
;   
;	ANO LECTIVO 2020/2021
;********************************************************************************	
; 	Realizado por:
;
;	Rafael Couto		2019142454	a2019142454@isec.pt
;	Rodrigo Ferreira	2019138331	a2019138331@isec.pt
;
;********************************************************************************	
; MACROS
;********************************************************************************	
;MACRO GOTO_XY 
; COLOCA O CURSOR NA POSIÇÃO POSX,POSY
;	POSX -> COLUNA
;	POSY -> LINHA
; 	REGISTOS USADOS
;		AH, BH, DL,DH (DX)
;********************************************************************************	
GOTO_XY		MACRO	POSX,POSY
			MOV	AH,02H
			MOV	BH,0
			MOV	DL,POSX
			MOV	DH,POSY
			INT	10H
ENDM
;********************************************************************************	
; MOSTRA - Faz o display de uma string terminada em $
;********************************************************************************	
MOSTRA MACRO STR 
MOV AH,09H
LEA DX,STR 
INT 21H
ENDM
;********************************************************************************	
; FIM DAS MACROS
;********************************************************************************	

.8086
.model small
.stack 2048

PILHA	SEGMENT PARA STACK 'STACK'
		db 2048 dup(?)
PILHA	ENDS

dseg	segment para public 'data'


		STR12	 		db 		"            "	; String para 12 digitos
		NUMERO			db		"                    $" 	; String destinada a guardar o número lido
		NUM_SP			db		"                    $" 	; Para apagar zona de ecran
		
		Horas			dw		0				; Vai guardar a HORA actual
		Minutos			dw		0				; Vai guardar os minutos actuais
		Segundos		dw		0				; Vai guardar os segundos actuais
		Segundos_jogo	dw		0				; Vai guardar os segundos de jogo
		Old_seg			dw		0				; Guarda os �ltimos segundos que foram lidos
		Tempo_init		dw		0				; Guarda O Tempo de inicio do jogo
		Tempo_j			dw		0				; Guarda O Tempo que decorre o  jogo
		Tempo_limite	dw		100				; Tempo m�ximo de Jogo
		String_TJmax	db		"    /100$"
		Str_tempoJogo	db		"            "  ; String para tempo de jogo decorrido
		String_tempo	db		"   s $"
		EstadoJogo		db		0				; Guarda o estado do jogo

		String_num 		db 		"  0 $"
		String_nome		db		20 dup(' '),'$'
        String_nome1  	db	    "TAC $"
		String_nome2  	db	    "ISEC $"
		String_nome3  	db	    "COIMBRA $"
		String_nome4  	db	    "ASSEMBLY $"	
		String_nome5  	db	    "COMPUTADORES $"
		Construir_nome	db	    20 dup(' '),'$'
		indice_nome		dw		0	; indice que aponta para Construir_nome
		
		Fim_Ganhou		db	    " Ganhou! $"	
		Fim_Perdeu		db	    " Perdeu! $"
		Voltar_Menu		db		" Para voltar ao menu pressione a tecla ESC... $"	

        Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
        Fich         	db      'labi1.TXT',0
		Menu 			DB		'Menu.TXT',0
		Niveis 			DB		'Menu2.TXT',0
		Top10   		db      'top10.TXT',0
        HandleFich      dw      0
        car_fich        db      ?
		HandleMenu      dw      0
		car_Menu        db      ?
		HandleNiveis    dw      0
		car_Niveis      db      ?
		HandleTOP10    	dw      0
		car_TOP10      	db      ?

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
; HORAS  - LE Hora DO SISTEMA E COLOCA em tres variaveis (Horas, Minutos, Segundos)
; 	CH - Horas, CL - Minutos, DH - Segundos
;	Faz contagem de tempo de jogo para saber quando e que o jogador perdeu por 
;	limite de tempo excedido.
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
;ROTINA PARA APAGAR ECRAN
;********************************************************************************	

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
; LEITURA DE UMA TECLA DO TECLADO 
; LE UMA TECLA	E DEVOLVE VALOR EM AH E AL
; SE ah=0 É UMA TECLA NORMAL
; SE ah=1 É UMA TECLA EXTENDIDA
; AL DEVOLVE O CÓDIGO DA TECLA PREMIDA
;********************************************************************************	
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
; Imprime o tempo e a data no monitor
;********************************************************************************	

Trata_Horas PROC

		PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		PUSH BP

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
		mov 	STR12[0],'0'
		mov 	STR12[1],'0'
		mov 	STR12[2],'0'
		mov 	STR12[3],'s'
		mov 	STR12[4],'$'
		mov		ax, Segundos_jogo
		mov		bp, 2
	
	divisao_temp:
		mov 	bl, 10   
		div 	bl
		add		ah,	30h				; Caracter Correspondente às unidades
		mov		String_tempo[bp], ah
		mov		ah, 0		
		dec		bp
		cmp		al, 0
		jne 	divisao_temp	

		MOSTRA	String_tempo
		cmp		Segundos_jogo, 100
		je		ESTADO
	
fim_horas:		
		goto_xy	POSx,POSy			; Volta a colocar o cursor onde estava antes de actualizar as horas
		
		POPF
		POP DX		
		POP CX
		POP BX
		POP AX
		POP BP
		RET

Trata_Horas ENDP

;********************************************************************************	

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

;********************************************************************************	
; IMP_MENU
;	Imprime ficheiro .txt relativo ao menu
;	Aguarda introducao de opcao do menu
;********************************************************************************	

IMP_MENU	PROC

		goto_xy		0,0
		call 		apaga_ecran
		mov			ax,0B800h
		mov			es,ax

ShowMenu:
		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,Menu
        int     21h
        jc      erro_abrir
        mov     HandleMenu,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleMenu
        mov     cx,1
        lea     dx,car_Menu
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_Menu
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleMenu
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
    je      MostraTOP10
    cmp     al, "3"
    jmp     Quit
        
Quit: 
   mov   ah,4ch
   int   21h   

MostraTOP10:
	jmp		IMP_TOP10
    
Jogo:
	jmp		IMP_NIVEIS

fim: 
	ret
		
IMP_MENU	endp

;********************************************************************************	
; IMP_TOP10
;	Imprime ficheiro .txt relativo ao top10
;	Aguarda ate o utilizador decidir retomar ao menu
;********************************************************************************	

IMP_TOP10	PROC
		goto_xy		0,0
		call 		apaga_ecran
		mov			ax,0B800h
		mov			es,ax

ShowTOP10:
		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,Top10
        int     21h
        jc      erro_abrir
        mov     HandleTOP10,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleTOP10
        mov     cx,1
        lea     dx,car_TOP10
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_TOP10
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleTOP10
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
    
    cmp     al, '6' 
    jl      ShowTOP10   
    cmp     al, '6'
    jg      ShowTOP10 
        
    cmp     al, "6"
    je      IMP_MENU

fim: 
			ret
		
IMP_TOP10	endp

;********************************************************************************	
; IMP_NIVEIS
;	Imprime ficheiro .txt relativo ao menu de niveis
;	Aguarda que o utilizador selecione o menu ou retome ao menu principal
;	Selecao do nivel de jogo carrega palavra a completar para a string_nome
;	e modifica ficheiro de jogo a carregar consoante a escolha do nivel
;********************************************************************************	

IMP_NIVEIS	PROC

		goto_xy		0,0
		call 		apaga_ecran
		mov			ax,0B800h
		mov			es,ax

ShowNiveis:
		;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,Niveis
        int     21h
        jc      erro_abrir
        mov     HandleNiveis,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_f

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleNiveis
        mov     cx,1
        lea     dx,car_Niveis
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_Niveis
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleNiveis
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
    jl      ShowNiveis   
    cmp     al, '6'
    jg      ShowNiveis
        
    cmp     al, "1"
    je      LVL1
    cmp     al, "2"
    je      LVL2
    cmp     al, "3"
    je     	LVL3
	cmp     al, "4"
    je     	LVL4
	cmp     al, "5"
    je     	LVL5
	cmp     al, "6"
    je     Volta_Menu
        
Volta_Menu: 
   jmp		IMP_MENU
LVL1:
	call 	LIMPA_VAR
	mov		Segundos_jogo, 0
	mov		Fich[4], '1'
	xor 	di,di
	repete1:
			mov		al, String_nome1[di]
			cmp     al, '$'
			je     	final1
			mov		String_nome[di], al
			inc 	di
			jmp     repete1
	final1: 
	jmp		IMP_FICH
LVL2:
	call 	LIMPA_VAR
	mov		Segundos_jogo, 0
	mov 	Fich[4], '2'
	xor 	di,di
	repete2:
			mov		al, String_nome2[di]
			cmp     al, '$'
			je     	final2
			mov		String_nome[di], al
			inc 	di
			jmp     repete2
	final2:
	jmp		IMP_FICH
LVL3:
	call 	LIMPA_VAR
	mov		Segundos_jogo, 0
	mov 	Fich[4], '3'
	xor 	di,di
	repete3:
			mov		al, String_nome3[di]
			cmp     al, '$'
			je     	final3
			mov		String_nome[di], al
			inc 	di
			jmp     repete3
	final3:
	jmp		IMP_FICH
LVL4:
	call 	LIMPA_VAR
	mov		Segundos_jogo, 0
	mov 	Fich[4], '4'
	xor 	di,di
	repete4:
			mov		al, String_nome4[di]
			cmp     al, '$'
			je     	final4
			mov		String_nome[di], al
			inc 	di
			jmp     repete4
	final4:
	jmp		IMP_FICH
LVL5:
	call 	LIMPA_VAR
	mov		Segundos_jogo, 0
	mov 	Fich[4], '5'
	xor 	di,di
	repete5:
			mov		al, String_nome5[di]
			cmp     al, '$'
			je     	final5
			mov		String_nome[di], al
			inc 	di
			jmp     repete5
	final5:
	jmp		IMP_FICH

fim: 
			ret
		
IMP_NIVEIS	endp

;********************************************************************************	
; IMP_FICH
;	Imprime ficheiro .txt relativo ao labirinto
;	Apos selecao de nivel no IMP_NIVEIS, carrega o nivel escolhido e imprime 
;	ficheiro designado para o nivel
;********************************************************************************	

IMP_FICH	PROC
		call 		apaga_ecran
		mov			ax,0B800h
		mov			es,ax
		mov 		Segundos_jogo, 0

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

;********************************************************************************	
; Avatar
;	Processo que trata de toda a funcionalidade do Avatar, desde movimentacao
;	a copia e colagem do avatar nas sucessivas movimentacoes.
;	Permite recuar ao menu principal pressionando a tecla "ESC".
;	Faz verificacao de igualdade entre a string_nome e construir_nome
;	 e salta para a funcao ESTADO para verificar se ganhou ou perdeu.
;********************************************************************************	

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
			MOSTRA	String_nome	
			goto_xy 9,21
			MOSTRA	Construir_nome
					
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

			

			goto_xy 58,0
			MOSTRA	String_TJmax

			goto_xy	POSx,POSy
			cmp		al, String_nome[si]
			jne		IMPRIME
			mov  	al, String_nome[si]
			mov		Construir_nome[si], al
			inc 	si
			xor 	di,di
		repete:
			mov		al, String_nome[di]
			cmp     al, '$'
			je     	ESTADO ;acertou
			cmp		Construir_nome[di], al
			goto_xy 9,21
			MOSTRA	Construir_nome
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

fim:				
			ret
AVATAR		endp

;********************************************************************************	
; LIMPA_VAR
;	Processo que limpa Construir_Nome na selecao de cada nivel de modo a que 
;	nao fique registado o que foi jogado no nivel 1 quando avancar para o
;	nivel 2, por exemplo.
;********************************************************************************	

LIMPA_VAR PROC
	push 	si 
	xor 	si,si
	ciclo:
		cmp Construir_nome[si], '$'
		je 	fora
		mov Construir_nome[si], ' '
		inc si
		jmp ciclo
	fora:
		pop si
		ret
LIMPA_VAR ENDP

;********************************************************************************
; LEITURA DE UMA TECLA DO TECLADO 
; LE UMA TECLA	E DEVOLVE VALOR EM AH E AL
; SE ah=0 É UMA TECLA NORMAL
; SE ah=1 É UMA TECLA EXTENDIDA
; AL DEVOLVE O CÓDIGO DA TECLA PREMIDA
;********************************************************************************	

LE_SPACE	PROC
sem_tecla:
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
LE_SPACE	ENDP

;********************************************************************************
; ESTADO
;	Processo que avalia se o jogador perdeu ou ganhou consante reunidas certas
;	condicoes como tempo limite excedido ou string_nome igual a construir_nome
;	Permite voltar ao menu principal pressionando a tecla "ESC".
;********************************************************************************	

ESTADO PROC
	cmp		Segundos_jogo, 100
	je		PERDEU
	inc 	EstadoJogo
	cmp		EstadoJogo, 1
	je 		GANHOU

	PERDEU:
			goto_xy 	25, 20
			MOSTRA 		Fim_Perdeu
			goto_xy		25, 21
			MOSTRA		Voltar_Menu
			mov			Segundos_jogo, 0
			jmp			LE_ESPACO
	GANHOU:
			goto_xy 	25, 20
			MOSTRA 		Fim_Ganhou
			goto_xy		25, 21
			MOSTRA		Voltar_Menu
			mov			Segundos_jogo, 0
			jmp			LE_ESPACO

	fim:
			mov			ah,4CH
			INT			21H

	LE_ESPACO:
			call	LE_SPACE
			cmp		ah, 1
			je		LE_ESPACO
			cmp 	al, 27	; ESC
			je		IMP_MENU

ESTADO ENDP

;********************************************************************************	
;	MAIN
;********************************************************************************	
Main  proc
		mov			ax, dseg
		mov			ds,ax

		xor			si,si

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
		
