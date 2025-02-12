; Archivo: Proyecto 1
; Dispositivo: PIC16F887
; Autor: Jos� Santizo 
; Compilador: pic-as (v2.32), MPLAB X v5.50
    
; Programa: Reloj digital
; Hardware: Displays de 7 segmentos, LEDs y pushbuttons
    
; Creado: 14 de septiembre, 2021
; �ltima modificaci�n: 15 de septiembre, 2021
    
PROCESSOR 16F887
#include <xc.inc>
    
;configuration word 1
 CONFIG FOSC=INTRC_NOCLKOUT // Oscilador interno sin salidas
 CONFIG WDTE=OFF            // WDT desabilitado (reinicio repetitiv del PIC)
 CONFIG PWRTE=ON            // PWRTE habilitado (espera de 72 ms al iniciar)
 CONFIG MCLRE=ON           // El pin de MCLR se utiliza como prendido o apagado
 CONFIG CP=OFF              // Sin protecci?n de c?digo
 CONFIG CPD=OFF		    // Sin protecci?n de datos 
 
 CONFIG BOREN=OFF	    // Sin reinicio cuando el voltaje de alimentaci?n baja de 4V
 CONFIG IESO=OFF	    // Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    // Cambio de reloj externo a interno en caso de fallo
 CONFIG LVP=OFF		    // Programaci?n en bajo voltaje permitido
 
;configuration word 2
 CONFIG WRT=OFF		    // Protecci?n de autoescritura por el programa desactivada
 CONFIG BOR4V=BOR40V	    // Reinicio abajo de 4v, (BOR21V = 2.1V)
 
;-----------------------------------------
;		 MACROS
;-----------------------------------------  
 REINICIAR_TMR1 MACRO
    MOVLW	12		;TIMER1 HIGH = 248
    MOVWF	TMR1H
    MOVLW	42		
    MOVWF	TMR1L
    BCF		TMR1IF
    ENDM
 
 REINICIAR_TMR0 MACRO
    BANKSEL	PORTD
    MOVLW	100		; Timer 0 reinicia cada 5 ms
    MOVWF	TMR0		; Mover este valor al timer 0
    BCF		T0IF		; Limpiar la bandera del Timer 0
    ENDM 
    
 REINICIAR_TMR2 MACRO
    BANKSEL	PORTA
    BCF		TMR2IF
    ENDM
    
 WDIV1 MACRO	DIVISOR,COCIENTE,RESIDUO    ; Macro de divisor
    MOVWF	CONTEO	    ; El dividendo se encuentra en W, pasar w a conteo
    CLRF	CONTEO1  ; Limpiar la variable que est? sobre w
	
    INCF	CONTEO1    ; Aumentar conteo + 1
    MOVLW	DIVISOR	    ; Pasar la litera del divisor a w
	
    SUBWF	CONTEO, F    ; Restar de w conteo, y guardarlo en conteo
    BTFSC	STATUS,0    ; Si carry 0, decrementar conteo+1
    GOTO	$-4
	
    DECF	CONTEO1, W
    MOVWF	COCIENTE
	
    MOVLW	DIVISOR
    ADDWF	CONTEO,W
    MOVWF	RESIDUO
  endm
 
;Variables a utilizar
 PSECT udata_bank0	; common memory
    STATUS_MODO:	    DS 1
    OLD_STATUS_MODO:	    DS 1
    STATUS_SEL:		    DS 1
    OLD_STATUS_SEL:	    DS 1
    STATUS_SET:		    DS 1
    OLD_STATUS_SET:	    DS 1
    UNO:		    DS 1
    DIEZ:		    DS 1
    CIEN:		    DS 1
    MIL:		    DS 1
    DISP_SELECTOR:	    DS 1
    UNI:		    DS 1
    DECE:		    DS 1
    CEN:		    DS 1
    MILE:		    DS 1
    UNI_TEMP:		    DS 1
    DECE_TEMP:		    DS 1
    CEN_TEMP:		    DS 1
    MILE_TEMP:		    DS 1
    UNI1:		    DS 1
    DECE1:		    DS 1
    CEN1:		    DS 1
    MILE1:		    DS 1
    UNI_TEMP1:		    DS 1
    DECE_TEMP1:		    DS 1
    CEN_TEMP1:		    DS 1
    MILE_TEMP1:		    DS 1
    SEGUNDOS:		    DS 1
    MINUTOS:		    DS 1
    HORAS:		    DS 1
    DIAS:		    DS 1
    MESES:		    DS 1
    LIMITE_DIAS:	    DS 1
    CONTEO:		    DS 1
    CONTEO1:		    DS 1
    LUCES:		    DS 1
    AND1:		    DS 1
    AND2:		    DS 1
    AND3:		    DS 1
    AND4:		    DS 1
    STATUS_SEL_TEMP:	    DS 1
    STATUS_MODO_TEMP:	    DS 1
    COM_STATUS_SEL_TEMP:    DS 1
    COM_STATUS_MODO_TEMP:   DS 1
    CONT:		    DS 2
    CONT1:		    DS 1
  
 PSECT udata_shr	; common memory
    W_TEMP:		    DS 1	; 1 byte
    STATUS_TEMP:	    DS 1	; 1 byte
    
    
 PSECT resVect, class=CODE, abs, delta=2
 ;------------vector reset-----------------
 ORG 00h		; posici?n 0000h para el reset
 resetVec:
    PAGESEL MAIN
    goto MAIN

 PSECT intVect, class=CODE, abs, delta=2
 ;------------vector interrupciones-----------------
 ORG 04h			    ; posici?n 0000h para interrupciones
 
 PUSH:
    MOVWF	W_TEMP
    SWAPF	STATUS, W
    MOVWF	STATUS_TEMP
 
 ISR:
    BTFSC	T0IF
    CALL	INT_TMR0
    
    BTFSC	TMR2IF
    CALL	CONTADORES_HORA
    
    BTFSC	TMR1IF
    CALL	LUCES_HORA
 POP:
    SWAPF	STATUS_TEMP, W
    MOVWF	STATUS
    SWAPF	W_TEMP, F
    SWAPF	W_TEMP, W
    RETFIE
   
 ;------------Sub rutinas de interrupci?n--------------
 LUCES_HORA:
    REINICIAR_TMR1
    BTFSC	STATUS_MODO, 0
    CALL	INTERMITENCIA
    RETURN
    
 INTERMITENCIA:
    INCF	LUCES
    MOVF	LUCES, W
    ANDLW	00000001B
    MOVWF	PORTE
    RETURN
 
 CONTADORES_HORA:
    REINICIAR_TMR2
    INCF	CONT
    MOVF	CONT, W
    SUBLW	200
    BTFSS	STATUS, 2
    GOTO	RETURN_T2
    CLRF	CONT
    
    BTFSS	STATUS_SET, 0
    INCF	SEGUNDOS
    
    MOVF	SEGUNDOS, W
    SUBLW	60
    BTFSC	STATUS, 2
    CALL	INC_MINUTOS
    
    MOVF	MINUTOS, W
    SUBLW	60
    BTFSC	STATUS, 2
    CALL	INC_HORAS
    
    MOVF	HORAS, W
    SUBLW	24
    BTFSC	STATUS, 2
    CALL	INC_DIAS
    
    MOVF	MESES, W
    CALL	TABLA_FECHA
    MOVWF	LIMITE_DIAS
    
    MOVF	DIAS, W
    SUBWF	LIMITE_DIAS, W
    BTFSC	STATUS, 2
    CALL	INC_MES
    
    MOVF	MESES, W
    SUBLW	13
    BTFSC	STATUS, 2
    CALL	REINICIO
    
    RETURN
    
 RETURN_T2:
    RETURN

 INC_MINUTOS:
    INCF	MINUTOS
    CLRF	SEGUNDOS
    RETURN
    
 INC_HORAS:
    INCF	HORAS
    CLRF	MINUTOS
    RETURN
    
 INC_DIAS:
    INCF	DIAS
    CLRF	HORAS
    RETURN
    
 INC_MES:
    INCF	MESES
    MOVLW	1
    MOVWF	DIAS
    RETURN   
 
 REINICIO:
    MOVLW	1
    MOVWF	MESES
    RETURN
    
 INT_TMR0:
    REINICIAR_TMR0	
    
    ; SE SELECCIONA EL DISPLAY AL QUE SE DESEA ESCRIBIR
    MOVF	DISP_SELECTOR, W
    MOVWF	PORTD
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE UNIDADES (0001)
    MOVF	DISP_SELECTOR, W
    SUBLW	1			;Chequear si DISP_SELECTOR = 0001
    BTFSC	STATUS, 2
    CALL	DISPLAY_UNI		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE DECENAS (0010)
    MOVF	DISP_SELECTOR, W
    SUBLW	2			;Chequear si DISP_SELECTOR = 0010
    BTFSC	STATUS, 2
    CALL	DISPLAY_DECE		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE CENTENAS (0100)
    MOVF	DISP_SELECTOR, W
    SUBLW	4			;Chequear si DISP_SELECTOR = 0100
    BTFSC	STATUS, 2
    CALL	DISPLAY_CEN
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE MILESIMAS (1000)
    MOVF	DISP_SELECTOR, W
    SUBLW	8			;Chequear si DISP_SELECTOR = 1000
    BTFSC	STATUS, 2
    CALL	DISPLAY_MIL
    
    ;MOVER EL 1 EN DISP_SELECTOR 1 POSICI?N A LA IZQUIERDA
    BCF		STATUS, 0		;Se limpia el bit de carry
    RLF		DISP_SELECTOR, 1	;1 en DISP_SELECTOR se corre una posici?n a al izquierda
    
    ;REINICIAR DISP_SELECTOR SI EL VALOR SUPER? EL N?MERO DE DISPLAYS
    MOVF	DISP_SELECTOR, W
    SUBLW	16
    BTFSC	STATUS, 2
    CALL	RESET_DISP_SELECTOR
    
    RETURN
    
 DISPLAY_UNI:
    MOVF	UNO, W			;W = UN0
    MOVWF	PORTA			;PORTC = W
    RETURN
    
 DISPLAY_DECE:
    MOVF	DIEZ, W			;W = DIEZ
    MOVWF	PORTA			;PORTC = W
    RETURN
    
 DISPLAY_CEN:
    MOVF	CIEN, W
    MOVWF	PORTA
    RETURN
    
 DISPLAY_MIL:
    MOVF	MIL, W
    MOVWF	PORTA
    RETURN

 RESET_DISP_SELECTOR:
    CLRF	DISP_SELECTOR
    INCF	DISP_SELECTOR, 1
    RETURN
    
  
 ;------------Posici?n del c?digo---------------------
 PSECT CODE, DELTA=2, ABS
 ORG 100H		;Posici?n para el codigo
 
 ;-------------Tabla n?meros--------------------------
 TABLA_FECHA:
    CLRF	PCLATH
    BSF		PCLATH, 0   ;PCLATH = 01    PCL = 02
    ANDLW	0x0f
    ADDWF	PCL	    ;PC = PCLATH + PCL + W
    
    ;Verificar el l?mite de d?as dependiendo de cada mes
    RETLW	0	    ;MES INICIAL 0
    RETLW	32	    ;ENERO
    RETLW	29	    ;FEBRERO
    RETLW	32	    ;MARZO
    RETLW	31	    ;ABRIL
    RETLW	32	    ;MAYO
    RETLW	31	    ;JUNIO
    RETLW	32	    ;JULIO
    RETLW	32	    ;AGOSTO
    RETLW	31	    ;SEPTIEMBRE
    RETLW	32	    ;OCTUBRE
    RETLW	31	    ;NOVIEMBRE
    RETLW	32	    ;DICIEMBRE
 
 TABLA:
    CLRF	PCLATH
    BSF		PCLATH, 0   ;PCLATH = 01    PCL = 02
    ANDLW	0x0f
    ADDWF	PCL	    ;PC = PCLATH + PCL + W
    RETLW	00111111B   ;0
    RETLW	00000110B   ;1
    RETLW	01011011B   ;2
    RETLW	01001111B   ;3
    RETLW	01100110B   ;4
    RETLW	01101101B   ;5
    RETLW	01111101B   ;6
    RETLW	00000111B   ;7
    RETLW	01111111B   ;8
    RETLW	01101111B   ;9
    RETLW	01110111B   ;A
    RETLW	01111100B   ;B
    RETLW	00111001B   ;C
    RETLW	01011110B   ;D
    RETLW	01111001B   ;E
    RETLW	01110001B   ;F
    
 ;-----------Configuraci?n----------------
 MAIN:
    BSF		STATUS_MODO, 0		    ;CONFIGURAR EL STATUS MODO EN 1
    BCF		STATUS_SET, 0		    ;CONFIGURAR EL STATUS SET EN 1
    BCF		STATUS_SEL, 0
    CALL	RESET_DISP_SELECTOR	    ;REINICIAR EL DISPLAYS_SELECTOR
    CALL	CONFIG_IO
    CALL	CONFIG_RELOJ		    ;Configuraci?n del oscilador
    CALL	CONFIG_TMR0		    ;Configuraci?n del Timer 0
    CALL	CONFIG_INT_ENABLE	    ;Configuraci?n de interrupciones
    CALL	CONFIG_TMR2
    CALL	CONFIG_TMR1
    BANKSEL	PORTA
    BANKSEL	PORTD
    
 ;---------Loop principal----------------
 LOOP:
    CALL	LIMITES_MINUTOS_HORAS
    CALL	LIMITES_MESES_DIAS
    
    BTFSC	PORTB, 0
    CALL	ANTIREBOTE_MODO
    
    CALL	CHECK_MODO
    
    BTFSC	PORTB, 1
    CALL	ANTIREBOTE_SET
    
    BTFSC	STATUS_SET, 0
    CALL	ANTIREBOTE_SEL
    
    
    GOTO	LOOP
 
 ;---------------SUBRUTINAS------------------ 
 ;-----------------------------------------
 ;	 L?GICA DE CONTADORES DE HORA
 ;----------------------------------------- 
 LIMITES_MINUTOS_HORAS:
    MOVF	MINUTOS, W
    WDIV1	10,DECE,UNI
    
    MOVF	HORAS, W
    WDIV1	10,MILE,CEN
    
    MOVF	UNI, W
    CALL	TABLA
    MOVWF	UNI_TEMP
    
    MOVF	DECE, W
    CALL	TABLA
    MOVWF	DECE_TEMP
    
    MOVF	CEN, W
    CALL	TABLA
    MOVWF	CEN_TEMP
    
    MOVF	MILE, W
    CALL	TABLA
    MOVWF	MILE_TEMP
    RETURN
    
 ;-----------------------------------------
 ;	 L?GICA DE CONTADORES DE FECHA
 ;----------------------------------------- 
 LIMITES_MESES_DIAS:
    MOVF	DIAS, W
    WDIV1	10,DECE1,UNI1
    
    MOVF	MESES, W
    WDIV1	10,MILE1,CEN1
    
    MOVF	UNI1, W
    CALL	TABLA
    MOVWF	UNI_TEMP1
    
    MOVF	DECE1, W
    CALL	TABLA
    MOVWF	DECE_TEMP1
    
    MOVF	CEN1, W
    CALL	TABLA
    MOVWF	CEN_TEMP1
    
    MOVF	MILE1, W
    CALL	TABLA
    MOVWF	MILE_TEMP1
    RETURN  
 
 ;-----------------------------------------
 ;	       STATUS DE SET
 ;----------------------------------------- 
 ANTIREBOTE_SET:
    BTFSC	PORTB, 1
    GOTO	$-1
    CALL	FLIP_FLOP_SET
    RETURN
 
 FLIP_FLOP_SET:
    MOVF	STATUS_SET, W
    MOVWF	OLD_STATUS_SET
    
    BTFSC	OLD_STATUS_SET, 0
    CALL	LIMPIAR_CONT_UNI
    
    BTFSS	OLD_STATUS_SET, 0
    CALL	RESUME
    
    RETURN
    
 LIMPIAR_CONT_UNI:
    BCF		STATUS_SET, 0
    CLRF	SEGUNDOS
    BCF		PORTC, 0
    RETURN
    
 RESUME:
    BSF		STATUS_SET, 0
    BSF		PORTC, 0
    RETURN
    
 ;-----------------------------------------
 ;	    STATUS DE SELECCI�N
 ;----------------------------------------- 
 ANTIREBOTE_SEL:
    BTFSC	PORTB, 2
    CALL	FLIP_FLOP_SEL
    
    CALL	AND_VERIFICACION1
    CALL	AND_VERIFICACION2
    CALL	AND_VERIFICACION3
    CALL	AND_VERIFICACION4
    RETURN
 
 FLIP_FLOP_SEL:
    BTFSC	PORTB, 2
    GOTO	$-1
    MOVF	STATUS_SEL, W
    MOVWF	OLD_STATUS_SEL
    
    BTFSC	OLD_STATUS_SEL, 0
    CALL	HORAS_DIAS
    
    BTFSS	OLD_STATUS_SEL, 0
    CALL	MINUTOS_MES
    
    RETURN  
    
 MINUTOS_MES:
    BSF		STATUS_SEL, 0
    BCF		PORTC, 4
    BSF		PORTC, 5
    RETURN
    
 HORAS_DIAS:
    BCF		STATUS_SEL, 0
    BCF		PORTC, 5
    BSF		PORTC, 4
    RETURN
    
 AND_VERIFICACION1:
    MOVF	STATUS_SEL, W
    MOVWF	STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W
    MOVWF	STATUS_MODO_TEMP
    
    COMF	STATUS_SEL_TEMP, W
    ANDWF	STATUS_MODO_TEMP, W
    MOVWF	AND1
    BTFSC	AND1, 0
    CALL	ANTIREBOTE_INTERNO3
    RETURN
    
 AND_VERIFICACION2:
    MOVF	STATUS_SEL, W
    MOVWF	STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W
    MOVWF	STATUS_MODO_TEMP
    
    COMF	STATUS_MODO_TEMP, W
    ANDWF	STATUS_SEL_TEMP, W
    MOVWF	AND2
    BTFSC	AND2, 0
    CALL	ANTIREBOTE_INTERNO4
    RETURN
    
 AND_VERIFICACION3:
    MOVF	STATUS_SEL, W
    MOVWF	STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W
    MOVWF	STATUS_MODO_TEMP
    
    MOVF	STATUS_MODO_TEMP
    ANDWF	STATUS_SEL_TEMP, W
    MOVWF	AND3
    BTFSC	AND3, 0
    CALL	ANTIREBOTE_INTERNO1
    RETURN
    
 AND_VERIFICACION4:
    MOVF	STATUS_SEL, W
    MOVWF	STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W
    MOVWF	STATUS_MODO_TEMP
    
    COMF	STATUS_SEL_TEMP, W
    MOVWF	COM_STATUS_SEL_TEMP
    COMF	STATUS_MODO_TEMP, W
    ANDWF	COM_STATUS_SEL_TEMP, W
    MOVWF	AND4
    BTFSC	AND4, 0
    CALL	ANTIREBOTE_INTERNO2
    RETURN
    
 ANTIREBOTE_INTERNO1:
    BTFSC	PORTB, 3
    CALL	INCRE_MINUTOS
    
    BTFSC	PORTB, 4
    CALL	DECRE_MINUTOS
    RETURN
    
 INCRE_MINUTOS:
    BTFSC	PORTB, 3
    GOTO	$-1
    INCF	MINUTOS
    RETURN
    
 DECRE_MINUTOS:
    BTFSC	PORTB, 4
    GOTO	$-1
    DECF	MINUTOS
    
    MOVF	MINUTOS, W
    SUBLW	-1
    BTFSC	STATUS, 2
    CALL	REINICIO3
    RETURN
    
 REINICIO3:
    MOVLW	59
    MOVWF	MINUTOS
    RETURN
    
 ANTIREBOTE_INTERNO2:
    BTFSC	PORTB, 3
    CALL	INCRE_DIAS
    
    BTFSC	PORTB, 4
    CALL	DECRE_DIAS
    RETURN
    
 INCRE_DIAS:
    BTFSC	PORTB, 3
    GOTO	$-1
    INCF	DIAS
    RETURN
    
 DECRE_DIAS:
    BTFSC	PORTB, 4
    GOTO	$-1
    DECF	DIAS
    
    MOVF	DIAS, W
    SUBLW	-1
    BTFSC	STATUS, 2
    CALL	REINICIO2
    RETURN
    
 REINICIO2:
    MOVF	LIMITE_DIAS
    MOVWF	DIAS
    RETURN
    
 ANTIREBOTE_INTERNO3:
    BTFSC	PORTB, 3
    CALL	INCRE_HORAS
    
    BTFSC	PORTB, 4
    CALL	DECRE_HORAS
    RETURN
    
 INCRE_HORAS:
    BTFSC	PORTB, 3
    GOTO	$-1
    INCF	HORAS
    RETURN
    
 DECRE_HORAS:
    BTFSC	PORTB, 4
    GOTO	$-1
    DECF	HORAS
    
    MOVF	HORAS, W
    SUBLW	-1
    BTFSC	STATUS, 2
    CALL	REINICIO1
    RETURN
    
 REINICIO1:
    MOVLW	23
    MOVWF	HORAS
    RETURN
    
 ANTIREBOTE_INTERNO4:
    BTFSC	PORTB, 3
    CALL	INCRE_MESES
    
    BTFSC	PORTB, 4
    CALL	DECRE_MESES
    RETURN
    
 INCRE_MESES:
    BTFSC	PORTB, 3
    GOTO	$-1
    INCF	MESES
    RETURN
    
 DECRE_MESES:
    BTFSC	PORTB, 4
    GOTO	$-1
    DECF	MESES
    
    MOVF	MESES, W
    SUBLW	-1
    BTFSC	STATUS, 2
    CALL	REINICIO4
    RETURN
    
 REINICIO4:
    MOVLW	12
    MOVWF	MESES
    RETURN
    
 ;-----------------------------------------
 ;	       STATUS DE MODO
 ;----------------------------------------- 
 ANTIREBOTE_MODO:
    BTFSC	PORTB, 0
    GOTO	$-1
    CALL	FLIP_FLOP_GENERAL
    RETURN
 
 FLIP_FLOP_GENERAL:
    MOVF	STATUS_MODO, W
    MOVWF	OLD_STATUS_MODO
    
    BTFSC	OLD_STATUS_MODO, 0
    BCF		STATUS_MODO, 0
    
    BTFSS	OLD_STATUS_MODO, 0
    BSF		STATUS_MODO, 0
    
    RETURN
    
 ;-----------------------------------------
 ;	       CHECK MODO
 ;----------------------------------------- 
 CHECK_MODO:
    BTFSC	STATUS_MODO, 0
    CALL	HORA_DISPLAYS
    
    BTFSS	STATUS_MODO, 0
    CALL	FECHA_DISPLAYS
    RETURN
       
 HORA_DISPLAYS:
    MOVF	UNI_TEMP, W
    MOVWF	UNO
    
    MOVF	DECE_TEMP, W
    MOVWF	DIEZ
    
    MOVF	CEN_TEMP, W
    MOVWF	CIEN
    
    MOVF	MILE_TEMP, W
    MOVWF	MIL
    
    RETURN
    
 FECHA_DISPLAYS:
    MOVF	UNI_TEMP1, W
    MOVWF	CIEN
    
    MOVF	DECE_TEMP1, W
    MOVWF	MIL
    
    MOVF	CEN_TEMP1, W
    MOVWF	UNO
    
    MOVF	MILE_TEMP1, W
    MOVWF	DIEZ
    
    BSF		PORTE, 0
    
    RETURN
 ;-----------------------------------------
 ;      CONFIGURACIONES GENERALES
 ;----------------------------------------- 
 CONFIG_TMR2:
    BANKSEL	PORTA
    BCF		TOUTPS3
    BCF		TOUTPS2
    BCF		TOUTPS1
    BSF		TOUTPS0		    ;POSTCALER = 0001 = 1:2
    
    BSF		TMR2ON
    
    BSF		T2CKPS1
    BCF		T2CKPS0		    ;PRESCALER = 1:16
    BANKSEL	TRISB
    MOVLW	156
    MOVWF	PR2
    CLRF	TMR2
    REINICIAR_TMR2
    RETURN

 CONFIG_TMR1:
    BANKSEL	PORTC
    BCF		TMR1GE		    ;SIEMPRE CONTANDO
    BSF		T1CKPS1		    ;CONFIGURACI�N DE PRESCALER
    BSF		T1CKPS0		    ;PRESCALER DE 1:8 - CADA 1 Hz
    BCF		T1OSCEN		    ;LOW POWER OSCILATOR OFF
    BCF		TMR1CS
    BSF		TMR1ON		    ;ENCENDER EL TMR1
    
    ;CARGAR LOS VALORES INICIALES
    REINICIAR_TMR1
    RETURN   
 
 CONFIG_INT_ENABLE:
    BANKSEL	TRISA
    BSF		TMR2IE		    ;INTERRUPCI?N TMR2
    BSF		TMR1IE		    ;INTERRUPCI�N TMR1
    
    BANKSEL	PORTA
    BSF		T0IE		    ;HABILITAR TMR0
    BCF		T0IF		    ;BANDERA DE TMR0
    
    BCF		TMR1IF		    ;BANDERA DE TMR1
    BCF		TMR2IF		    ;BANDERA DE TMR2
    
    BSF		PEIE		    ;INTERRUPCIONES PERIF?RICAS
    BSF		GIE		    ;INTERRUPCIONES GLOBALES
    RETURN

    
 CONFIG_TMR0:
    BANKSEL	TRISA
    BCF		T0CS		    ;Reloj interno
    BCF		PSA		    ;PRESCALER
    BSF		PS2 
    BSF		PS1
    BCF		PS0		    ;Prescaler = 110 = 1:128
    BANKSEL	PORTA
    REINICIAR_TMR0
    RETURN
 
 CONFIG_IO:
    BANKSEL	ANSEL
    CLRF	ANSEL		    ;Pines digitales
    CLRF	ANSELH
    
    BANKSEL	TRISA
    CLRF	TRISA		    ;Port A como salida
    CLRF	TRISD		    ;PORT D COMO SALIDA
    CLRF	TRISC
    CLRF	TRISE
    
    BSF		TRISB, 0	    ;PORT B COMO ENTRADA
    BSF		TRISB, 1
    BSF		TRISB, 2
    BSF		TRISB, 3
    BSF		TRISB, 4
    
    BANKSEL	PORTA
    CLRF	PORTA
    CLRF	PORTD
    CLRF	PORTC
    CLRF	PORTE
    RETURN
    
 CONFIG_RELOJ:
    BANKSEL	OSCCON
    BSF		IRCF2		    ;IRCF = 110 = 4MHz
    BSF		IRCF1
    BCF		IRCF0
    BSF		SCS		    ;Reloj interno
    RETURN
    
    
END


