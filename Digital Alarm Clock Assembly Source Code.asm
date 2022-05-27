;****************************************************************************************************
;This software is provided in an “AS IS” condition,NO WARRANTIES in any form apply to this software.
; picmicrolab.com 8.2.2014
;***************************************************************************************************
;PIC16F876A Based Digital Alarm Clock  RB0 - Alarm, RB1 - Time,RB3 - Min,RB4 - Hours, RB5 - Buzzer,

LIST P=PIC16F876A 
include <P16f876A.inc> 

__CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC  & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

;-----------------------------------------------------------------------------------------------------
OnesMin EQU 0X30 ;1's minutes
TensMin EQU 0X31 ;10's minutes
OnesHour EQU 0X32  ;1's hours
TensHour EQU 0X33 ;10's hours
;-----------------------------------------------------------------------------------------------------
OnesMinAlarm EQU 0X60 ;1's minutes
TensMinAlarm EQU 0X61 ;10's minutes
OnesHourAlarm EQU 0X62  ;1's hours
TensHourAlarm EQU 0X63 ;10's hours
;----------------------------------------------------------------------------------------------------

org 0x00 
reset:
goto start
org 0x04 
goto		IntSRV
org		0x10
start: 	bcf STATUS, RP0 
	   	bcf STATUS, RP1 

		clrf PORTA
	
		bsf STATUS, RP0 
		movlw	0x06
		movwf	ADCON1; all A,E digital

		movlw   0xff		; RB7-RB0 of PORTB are inputs
		movwf   TRISB
		bcf     OPTION_REG,0x07 ; RBPU is ON -->Pull UP on PORTB is enabled
		
		movlw 0x00
		movwf TRISA 
		clrf TRISC 
		bcf STATUS, RP0
		bsf PORTC,0X00


        clrf            T1CON                                 
        movlw           0xD8
        movwf           TMR1H             
        movlw			0xF0
		movwf			TMR1L
        clrf            INTCON          
        bsf             STATUS,RP0
        clrf            PIE1            
        bcf  			STATUS,RP0
        clrf            PIR1            
        movlw           0x20            
        movwf           T1CON          
        bsf				INTCON,PEIE	
		;bsf				INTCON,GIE 

		bcf				INTCON,GIE 
  
		bsf				STATUS,RP0 
		bsf				PIE1,TMR1IE	
        bcf				STATUS,RP0


		bsf   		T1CON,TMR1ON
		bcf		STATUS, RP0		;Bank 0	
;--------------------------Default Time Settings-----------------------
movlw 0x00
movwf	OnesMin
movlw 0x00
movwf	TensMin
movlw 0x00
movwf	OnesHour
movlw 0x00
movwf	TensHour
;-------------------------Default Alarm Settings-------------
movlw 0x03
movwf	OnesMinAlarm
movlw 0x02
movwf	TensMinAlarm
movlw 0x01
movwf	OnesHourAlarm
movlw 0x00
movwf	TensHourAlarm
;------------------------------------------------------------



bsf				INTCON,GIE ;Enable GIE for 1s count

looop:

;------------------------------------------------------------------------

btfss PORTB,0x00 ;RB0 - AlarmAdj Input OFF
call ShowCountAlarm

btfsc PORTB,0x00 ;RB0 - AlarmAdj Input ON
call ShowCount

call CompareAlarmTime

goto	looop
;-----------------------------------------------------------------------
	
delay:					
		movlw		0x0f		
		movwf		0x51
CONT1:	movlw		0x0f		
		movwf		0x52
CONT2:	decfsz		0x52,f
		goto		CONT2
		decfsz		0x51,f
		goto		CONT1
		return	
;-----------------------------------

IntSRV:	
	bcf   		T1CON,TMR1ON
	bcf         PIR1,TMR1IF
	
	movlw       0xD8
	movwf		TMR1H
	movlw		0xF0
	movwf		TMR1L
;----------------------------------------

call AdjMin
call AdjHours

call AdjMinAlarm
call AdjHoursAlarm
;----------------------------------------
	incf		0x35


	movlw 		0x7D ;7d
	subwf 		0x35,w
	btfss 		STATUS,Z
	goto next
	
;------------------------------------------------
	clrf 0x35	;1Hz Output - Seconds counter
	incf 0x36 ; Minutes counter
;---------------------------------------------------------------------------
	movlw 0x3C 
	subwf 0x36,w
	btfss STATUS,Z
	goto next
	clrf 0x36
;---------------------------------------------------------------------------
	incf OnesMin ;increase 1's minutes	
	movlw 0x0A
	subwf OnesMin,w
	btfss STATUS,Z
	goto next
	clrf OnesMin
	incf TensMin ;increase 10's minutes	
	movlw 0x06
	subwf TensMin,w
	btfss STATUS,Z
	goto next
	clrf TensMin
	incf OnesHour ;increase 1's hours
	call Check24H
	movlw 0x0A
	subwf OnesHour,w
	btfss STATUS,Z
	goto next
	clrf OnesHour
	incf TensHour ;increase 10's hours
	call Check24H
	
next:
	bsf   		T1CON,TMR1ON
	retfie
;-------------------Check24H--------------------
Check24H:
	movf TensHour,w
	movlw 0x02
	subwf TensHour,w
	btfss STATUS,Z
	return
	movf OnesHour,w
	movlw 0x04
	subwf OnesHour,w
	btfss STATUS,Z
	return
	clrf OnesHour
	clrf TensHour
return
;----------------------------------------------
;-------------------Check24HAlarm-------------
Check24HAlarm:
	movf TensHourAlarm,w
	movlw 0x02
	subwf TensHourAlarm,w
	btfss STATUS,Z
	return
	movf OnesHourAlarm,w
	movlw 0x04
	subwf OnesHourAlarm,w
	btfss STATUS,Z
	return
	clrf OnesHourAlarm
	clrf TensHourAlarm
return

;-------------------------------------------------
AdjMin:
	btfsc PORTB,0x01 ;RB1 - TimeAdj Input
	return

	btfsc PORTB,0x03 ;RB3 - MinAdj Input
	return
	clrf 0x35
	clrf 0x36

	incf 0x37
	movlw 0x40
	subwf 0x37,w
	btfss STATUS,Z
	return
	clrf 0x37

	incf OnesMin ;increase 1's minutes	
	movlw 0x0A
	subwf OnesMin,w
	btfss STATUS,Z
	return
	clrf OnesMin
	incf TensMin ;increase 10's minutes	
	movlw 0x06
	subwf TensMin,w
	btfss STATUS,Z
	return
	clrf TensMin

return
;--------------------------------
AdjHours:
	btfsc PORTB,0x01 ;RB1 - TimeAdj Input
	return

	call Check24H
	btfsc PORTB,0x04 ;RB2 - HourAdj Input
	return
	clrf 0x35
	clrf 0x36
;-------------------------------
	incf 0x37
	movlw 0x40
	subwf 0x37,w
	btfss STATUS,Z
	return
	clrf 0x37
;-------------------------------
	incf OnesHour ;increase 1's hours	
	movlw 0x0A
	subwf OnesHour,w
	btfss STATUS,Z
	return
	clrf OnesHour
	incf TensHour ;increase 10's hours	
	movlw 0x06
	subwf TensHour,w
	btfss STATUS,Z
	return
	clrf TensHour
	
return
;-------------------------------------------------
AdjMinAlarm:
	btfsc PORTB,0x00 ;RB0 - AlarmAdj Input
	return

	btfsc PORTB,0x03 ;RB3 - MinAdj Input
	return
	;clrf 0x35
	;clrf 0x36

	incf 0x37
	movlw 0x40
	subwf 0x37,w
	btfss STATUS,Z
	return
	clrf 0x37

	incf OnesMinAlarm ;increase 1's minutes	
	movlw 0x0A
	subwf OnesMinAlarm,w
	btfss STATUS,Z
	return
	clrf OnesMinAlarm
	incf TensMinAlarm ;increase 10's minutes	
	movlw 0x06
	subwf TensMinAlarm,w
	btfss STATUS,Z
	return
	clrf TensMinAlarm

return
;--------------------------------
AdjHoursAlarm:
	btfsc PORTB,0x00 ;RB1 - TimeAdj Input
	return

	call Check24HAlarm
	btfsc PORTB,0x04 ;RB2 - HourAdj Input
	return
	clrf 0x35
	clrf 0x36
;-------------------------------
	incf 0x37
	movlw 0x40
	subwf 0x37,w
	btfss STATUS,Z
	return
	clrf 0x37
;-------------------------------
	incf OnesHourAlarm ;increase 1's hours	
	movlw 0x0A
	subwf OnesHourAlarm,w
	btfss STATUS,Z
	return
	clrf OnesHourAlarm
	incf TensHourAlarm ;increase 10's hours	
	movlw 0x06
	subwf TensHourAlarm,w
	btfss STATUS,Z
	return
	clrf TensHourAlarm
	
return
;--------------------------------------------

ConvertBCDto7Segment:
movf 0x40,w
sublw 0x01
btfss STATUS,Z ; 1
goto Digit2
movlw	0xf9
movwf	0x40
;------------------------------------
Digit2:
movf 0x40,w
sublw 0x02
btfss STATUS,Z ; 2
goto Digit3
movlw	0xA4
movwf	0x40
;---------------------------
Digit3:
movf 0x40,w
sublw 0x03
btfss STATUS,Z ; 3
goto Digit4
movlw	0xb0
movwf	0x40

;---------------------------
Digit4:
movf 0x40,w
sublw 0x04
btfss STATUS,Z ; 4
goto Digit5
movlw	0x99
movwf	0x40
;---------------------------
Digit5:
movf 0x40,w
sublw 0x05
btfss STATUS,Z ; 5
goto Digit6
movlw	0x92
movwf	0x40
;---------------------------
Digit6:
movf 0x40,w
sublw 0x06
btfss STATUS,Z ; 6
goto Digit7
movlw	0x82
movwf	0x40
;---------------------------
Digit7:
movf 0x40,w
sublw 0x07
btfss STATUS,Z ; 7
goto Digit8
movlw	0xf8
movwf	0x40
;----------------------------
Digit8:
movf 0x40,w
sublw 0x08
btfss STATUS,Z ; 8
goto Digit9
movlw	0x80
movwf	0x40
;---------------------------
Digit9:
movf 0x40,w
sublw 0x09
btfss STATUS,Z ; 9
goto Digit0
movlw	0x90
movwf	0x40
;---------------------------
Digit0:
movf 0x40,w
btfss STATUS,Z ; 0
;goto DigitA
return
movlw	0xc0
movwf	0x40
return
;---------------------------

;----------------------------------------------------
ShowCount:
movf	OnesMin,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTA,0X00
call	delay
movlw	0x0f
movwf	PORTA


movf	TensMin,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTC,0x07
bcf		PORTA,0X01 ;Decimal Point
call	delay
movlw	0x0f
movwf	PORTA

movf	OnesHour,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTC,0x07;Decimal Point
bcf		PORTA,0X02
call	delay
movlw	0x0f
movwf	PORTA

movf	TensHour,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTA,0X03
call	delay
movlw	0x0f
movwf	PORTA

return
;-------------------------------------------------------------
;----------------------------------------------------
ShowCountAlarm:
movf	OnesMinAlarm,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTA,0X00
call	delay
movlw	0x0f
movwf	PORTA


movf	TensMinAlarm,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTC,0x07
bcf		PORTA,0X01 ;Decimal Point
call	delay
movlw	0x0f
movwf	PORTA

movf	OnesHourAlarm,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTC,0x07;Decimal Point
bcf		PORTA,0X02
call	delay
movlw	0x0f
movwf	PORTA

movf	TensHourAlarm,w
movwf	0x40
call ConvertBCDto7Segment
movf 0x40,w
movwf   PORTC
bcf		PORTA,0X03
call	delay
movlw	0x0f
movwf	PORTA

return


;-------------------------------------------------------------
delayL:	
		movlw		0x0A		
		movwf		0x53				
CONT3L:	movlw		0xff		
		movwf		0x51
CONT1L:	movlw		0xff		
		movwf		0x52
CONT2L:	decfsz		0x52,f
		goto		CONT2L
		decfsz		0x51,f
		goto		CONT1L
		;incf		0x35
		decfsz		0x53,f	
		goto		CONT3L
		return			

;-----------------------------------------------------------------------
CompareAlarmTime:
;If Time = Alarm RA5 = 1 and Buz Switvh ON --> Sound ON
movf    OnesMinAlarm,w
subwf   OnesMin,w
btfss 	STATUS,Z
return
movf    TensMinAlarm,w
subwf   TensMin,w
btfss 	STATUS,Z
return
movf    OnesHourAlarm,w
subwf   OnesHour,w
btfss 	STATUS,Z
return
movf    TensHourAlarm,w
subwf   TensHour,w
btfss 	STATUS,Z
return

bsf		PORTA,0X05
return
;------------------------------------------------------------------------
end