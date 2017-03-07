;
; FlappyBird.asm
;
; Created: 07/02/2017 10:00:19
;

; Author : Quang Nguyen, Chris Page
; Institution : Imperial College Lodon
;
.DEVICE ATmega128
.include "m128def.inc"	
;
		.ORG	$0

		jmp Init		    ; 
		nop reti			; External 0 interrupt  Vector 
		nop reti			; External 1 interrupt  Vector 
		nop reti			; External 2 interrupt  Vector 
		nop reti			; External 3 interrupt  Vector 
		jmp Button			; External 4 interrupt  Vector 
		nop reti			; External 5 interrupt  Vector 
		nop reti			; External 6 interrupt  Vector 
		nop reti			; External 7 interrupt  Vector 
		nop reti			; Timer 2 Compare Vector 
		nop reti			; Timer 2 Overflow Vector 
		nop reti			; Timer 1 Capture  Vector 
		jmp GameInter 		; Timer 1 CompareA  Vector 
		nop reti			; Timer 1 CompareB  Vector 
		nop reti			; Timer 1 Overflow  Vector 
		jmp MusicInter		; Timer 0 Compare  Vector 
		nop reti			; Timer 0 Overflow interrupt  Vector 
		nop reti			; SPI  Vector 
		nop reti			; UART Receive  Vector 
		nop reti			; UDR Empty  Vector 
		nop reti			; UART Transmit  Vector 
		nop reti			; ADC Conversion Complete Vector 
		nop reti			; EEPROM Ready Vector 
		nop reti			; Analog Comparator  Vector 

.org		$0080			; start address well above interrupt table



;*********************************************************
;***************                         *****************
;***************     VARIABLE SETUP      *****************
;***************                         *****************
;*********************************************************

;************** Non-Immediate Registers ******************
		.def CurrentLevel	= r3	; Level Position Indicator
		.def ClockCounter	= r5	; Number of Game Interrupts occured
		.def TimeCounter	= r6	; Number of Music Timer Interrupts occured
		.def TimePointer	= r7	; Music Time Position Indicator 
		.def CurrentTime	= r8	; Curent Music Time
	
		.def BirdPosition	= r9	; Bird Position
		.def BirdSpeed		= r10	; Bird Speed
	
		.def NumPositionx	= r11	; Number Position X-Coordinate
		.def NumPositiony	= r12	; Number Position Y-Coordinate
		
;****************** Immediate Registers ****************** 
		.def TempReg		= r16	; Temporary Register 1
		.def TempReg2		= r17	; Temporary Register 2
	
		.def TempRightX3	= r18	; Tube Right Bound/Line Start X-Coordinate	
		.def TempLeftY4		= r19	; Tube Left Bound/Line Start Y-Coordinate	
		.def TempTopLength5	= r20	; Tube Top Bound/Line Length	
		.def TempBottom6	= r21	; Tube Bottom Bound
		
		.def InterruptState = r23	; Game Timer Interrupt
		.def Crash			= r24	; Crash State
		.def ButtonState	= r25	; Button State
		
;************************** SRAM   ***********************
		.equ Tubex1			= $0200	; Tube 1 Position X-Coordinate
		.equ Tubey1			= $0201	; Tube 1 Position Y-Coordinate
		.equ Tubex2			= $0202	; Tube 2 Position X-Coordinate
		.equ Tubey2			= $0203	; Tube 2 Position Y-Coordinate
	
		.equ Score			= $0204	; Current Score 
		.equ NotePointer	= $0205	; Music Note Position Indicator 

;************************* EEPROM ************************
		.equ HighScore		= $0200	; High Score

	rjmp Init 						; Jump over Database and Intertupt to Initialisation



;*********************************************************
;***************                         *****************
;***************         DATABASE        *****************
;***************                         *****************
;*********************************************************

;********************* Level Design **********************
	LevelDesign:
		.db $6C,$98,$C4,$5A,$86,$B2,$49,$75,$A1,$CD,$63,$8F,$BB,$51,$7D,$AA,$D6,$6C
	MusicNotes:
		.dw $0BD6,$0000,$0BD6,$0000,$0BD6,$0000,$0F51,$0000,$0BD6,$0000,$0A25,$0000,$148F,$0000,$0F51,$0000,$148F,$0000,$1869,$0000,$11C1,$0000,$1046,$0000,$115C,$0000,$122B,$0000,$148F,$0000,$0BD6,$0000,$0A47,$0000,$0915,$0000,$0B29,$0000,$0A47,$0000,$0BD6,$0000,$0F06,$0000,$0D78,$0000,$1046,$0000,$0F51,$0000,$148F,$0000,$1869,$0000,$11C1,$0000,$1046,$0000,$115C,$0000,$122B,$0000,$148F,$0000,$0BD6,$0000,$0A47,$0000,$0915,$0000,$0B29,$0000,$0A47,$0000,$0BD6,$0000,$0F06,$0000,$0D78,$0000,$1046,$0000,$0F9F,$0000,$0A47,$0000,$0AD9,$0000,$0B7D,$0000,$0C99,$0000,$0C04,$0000,$148F,$0000,$122B,$0000,$0F9F,$0000,$122B,$0000,$0F9F,$0000,$0DB4,$0000,$0F9F,$0000,$0A47,$0000,$0AD9,$0000,$0B7D,$0000,$0C99,$0000,$0C04,$0000,$07A8,$0000,$07A8,$0000,$07A8,$0000,$148F,$0000,$0F9F,$0000,$0A47,$0000,$0AD9,$0000,$0B7D,$0000,$0C99,$0000,$0C04,$0000,$148F,$0000,$122B,$0000,$0F9F,$0000,$122B,$0000,$0F9F,$0000,$0DB4,$0000,$0D5A,$0000,$0E34,$0000,$0F9F,$0000,$148F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0A47,$0000,$0AD9,$0000,$0B7D,$0000,$0C99,$0000,$0C04,$0000,$148F,$0000,$122B,$0000,$0F9F,$0000,$122B,$0000,$0F9F,$0000,$0DB4,$0000,$0F9F,$0000,$0A47,$0000,$0AD9,$0000,$0B7D,$0000,$0C99,$0000,$0C04,$0000,$07A8,$0000,$07A8,$0000,$07A8,$0000,$148F,$0000,$0F9F,$0000,$0A47,$0000,$0AD9,$0000,$0B7D,$0000,$0C99,$0000,$0C04,$0000,$148F,$0000,$122B,$0000,$0F9F,$0000,$122B,$0000,$0F9F,$0000,$0DB4,$0000,$0D78,$0000,$0E34,$0000,$0F9F,$0000,$148F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0D78,$0000,$0BD6,$0000,$0F9F,$0000,$122B,$0000,$148F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0D78,$0000,$0BD6,$0000,$08FA,$0000,$0A47,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0F9F,$0000,$0D78,$0000,$0BD6,$0000,$0F9F,$0000,$122B,$0000,$148F,$0000,$0BD6,$0000,$0BD6,$0000,$0BD6,$0000,$0F51,$0000,$0BD6,$0000,$0A25,$0000,$148F
	NoteTimes:
		.db $18, $25, $18, $18, $4A, $18, $18, $18, $18, $4A, $18, $89, $18, $8F, $18, $70, $18, $63, $18, $7C, $18, $4A, $13, $52, $18, $25, $18, $4A, $18, $31, $13, $31, $C, $25, $18, $4A, $13, $25, $0C, $57, $13, $4A, $13, $25, $13, $25, $13, $7C, $18, $70, $18, $63, $18, $7C, $18, $4A, $13, $52, $18, $25, $18, $4A, $18, $31, $13, $31, $0C, $25, $18, $4A, $13, $25, $0C, $57, $13, $4A, $13, $25, $13, $25, $13, $7C, $18, $4A, $18, $18, $18, $25, $18, $25, $25, $4A, $25, $4A, $18, $25, $18, $25, $18, $4A, $18, $25, $18, $18, $18, $36, $18, $4A, $18, $18, $18, $25, $18, $25, $25, $4A, $31, $4A, $13, $4A, $13, $25, $13, $4A, $18, $4A, $18, $4A, $18, $18, $18, $25, $18, $25, $25, $4A, $25, $4A, $18, $25, $18, $25, $18, $4A, $18, $25, $18, $18, $18, $68, $18, $70, $18, $68, $18, $59, $18, $4A, $18, $4A, $18, $25, $18, $4A, $18, $4A, $18, $18, $18, $25, $18, $25, $25, $4A, $25, $4A, $18, $25, $18, $25, $18, $4A, $18, $25, $18, $18, $18, $36, $18, $4A, $18, $18, $18, $25, $18, $25, $25, $4A, $31, $4A, $13, $4A, $13, $C, $13, $4A, $18, $4A, $18, $4A, $18, $18, $18, $25, $18, $25, $25, $4A, $25, $4A, $18, $25, $18, $25, $18, $4A, $18, $25, $18, $18, $18, $68, $18, $70, $18, $68, $18, $59, $18, $4A, $18, $4A, $18, $25, $18, $4A, $0E, $25, $13, $4A, $0E, $57, $13, $25, $13, $57, $13, $25, $13, $4A, $13, $25, $13, $95, $0E, $25, $13, $4A, $0E, $57, $13, $25, $13, $25, $13, $89, $13, $51, $13, $95, $0E, $25, $13, $4A, $0E, $57, $13, $25, $13, $57, $13, $25, $13, $4A, $13, $25, $13, $95, $18, $25, $18, $4A, $18, $4A, $18, $18, $18, $4A, $18, $89, $18, $8F



;*********************************************************
;***************                         *****************
;***************    INTERRUPT ROUTINES   *****************
;***************                         *****************
;*********************************************************

;**************** Game Timer Interrupts ******************
GameInter:		
		in r4,SREG				; save SREG
		ldi InterruptState, $FF	; indicate Game Timer Interrupt has been triggered
		out SREG,r4				; restore SREG	
		reti					; return

;*************** External Button Interrupts **************
Button:	
		in r4,SREG				; save SREG
		ldi ButtonState, $FF	; indicate Button External Interrupt has been triggered
		out SREG,r4				; restore SREG	
		reti					; return

;*************** External Button Interrupts **************
MusicInter:
		in r4,SREG				; save SREG
		inc TimeCounter			; indicate Music Timer Interrupt has been triggered
		out SREG,r4				; restore SREG	
		reti					; return	



;*********************************************************
;***************                         *****************
;***************     INITIALISATION      *****************
;***************                         *****************
;*********************************************************

Init:                
;***************** Stack Pointer Setup ******************* 
		ldi r16, $0F			; Stack Pointer Setup 
		out SPH,r16				; Stack Pointer High Byte 
		ldi r16, $FF			; Stack Pointer Setup 
		out SPL,r16				; Stack Pointer Low Byte 
   
;******************** RAMPZ Setup ************************ 
		ldi  r16, $00			; 1 = EPLM acts on upper 64K
		out RAMPZ, r16			; 0 = EPLM acts on lower 64K

;**************** Comparator Setup Code ******************  
		ldi r16,$80				; Comparator Disabled, Input Capture Disabled 
		out ACSR, r16			; Comparator Settings   

;****************** TIMER0 Setup Code *******************  
		ldi r16,$0D				; CTC Mode
		out TCCR0, r16			; Timer - PRESCALE TCK0 BY 256
								; clear timer on OCR0 match
		ldi r16,$90				; load OCR0 with n=125
		out OCR0,r16			; The counter will go every n*256*125 nsec

;****************** TIMER1A Setup Code *******************  
		ldi r16,$00				; Normal Operation
		out TCCR1A, r16			; 
		ldi r16,$0F				; CTC Mode, Prescale 1024
		out TCCR1B, r16			;
		ldi r16,$00				; High byte of OCR1A
		out OCR1AH,r16			; 
		ldi r16,$80				; Low byte of OCR1A
		out OCR1AL,r16			;

;****************** TIMER3A Setup Code *******************  
		ldi r16,$41				; Normal Operation
		sts TCCR3A, r16			; 
		ldi r16,$11				; PWM Mode
		sts TCCR3B, r16			;
		ldi r16,$00				; High byte of OCR3A
		sts OCR3AH,r16			;
		ldi r16,$00				; Low byte of OCR3A
		sts OCR3AL,r16			;	
   	
;******************* PORTB Setup Code ********************
		ldi r16, $FF			; OUTPUT (BLANKING INPUT)
		out DDRB , r16			; Port B Direction Register
		ldi r16, $FF			; 
		out PORTB, r16			; 

;******************* PORTC Setup Code ********************
		ldi r16, $FF			; OUTPUT (X-AXIS)
		out DDRC , r16			; Port C Direction Register
		ldi r16, $FF			; 
		out PORTC, r16			; 
   
;******************* PORTD Setup Code ********************
		ldi r16, $FF			; Port D OUTPUT (Y-AXIS)
		out DDRD, r16			; Port D Direction Register
		ldi r16, $FF			; 
		out PORTD, r16			;
		
;******************* PORTE Setup Code ********************
		ldi r16, $0F			; 0-3 INPUT (USER INPUT), 4-7 OUTPUT (SPEAKER)
		out DDRE, r16			; Port E Direction Register
		ldi r16, $FF			; Port E Pull-up Register
		out PORTE, r16			;

;************** EXTERNAL INTERRUPT 4 Setup Code **********  
		ldi r16, $10			; Enable INT4
		out EIMSK, r16			; 
		ldi r16, $02			; Trigger Interrupt on falling edge	
		out EICRB, r16			;

 	sei							; Enable All Interrupts



;*********************************************************
;***************                         *****************
;***************     MAIN PROGRAMME      *****************
;***************                         *****************
;*********************************************************

;**************** Level Initialisation *******************
		ldi TempReg, $01				; Reset Level Position Indicator upon booting
		mov CurrentLevel, TempReg		;

;******************* Standby Screen **********************
Main:			
		rcall Ground					; Display Ground
		ldi TempReg, $7F				; reset Bird Position
		mov BirdPosition, TempReg 		;
		rcall Bird						; Display Bird
		rcall HighScoreOut				; Display High Score
		rcall ScoreOut         			; Display Current Score
		rcall FlappyOut  				; Display 'FLAPPY BIRD'
		sbis PINE, 4					; If Button is pressed, initialise Game
		rjmp GameInit					;
	
		ldi TempReg2, LOW(HighScore)	; Load EEPROM Address of High Score
		ldi TempRightX3, High(HighScore); 
		rcall EEPROM_read				; Read High Score from EEPROM
		lds TempReg2, Score 			; Compare Current Score with High Score
		cp TempReg2, TempReg 			;
		ldi TempReg, $00 				; Reset Current Score to 0
		sts Score, TempReg 				;
		brlo Main 						; If Current Score is lower, continue Standby Screen
		mov TempReg, TempReg2			; If Current Score is higher, load new High Score
		ldi TempReg2, LOW(HighScore)	; Load EEPROM Address of High Score
		ldi TempRightX3, High(HighScore);
		rcall EEPROM_write				; Write new High Score to EEPROM
		rjmp Main						; When done, continue Standby Screen

;*************** Game Initialisation *********************
GameInit: 
	
		ldi TempReg, $00				; 
		sts Tubex1, TempReg				; Reset Tubes1 X-Coordinates to zero
		sts Tubex2, TempReg				; Reset Tubes1 X-Coordinates to zero
		
		ldi TempReg, $7F				; 
		sts Tubey1, TempReg				; Reset Tubes 1 Height to centre
		sts Tubey2, TempReg				; Reset Tubes 2 Height to centre
		mov BirdPosition, TempReg		; Reset Bird Position to centre
	
		ldi TempReg, $00				; 
		mov BirdSpeed, TempReg			; Reset Bird Speed to zero
		mov InterruptState, TempReg		; Reset Game Interrupt State to None
		mov Crash, TempReg				; Reset Crash State to None
		mov ClockCounter, TempReg  		; Reset Game Interrupt Counter to zero
		mov CurrentTime, TempReg 		; Reset Current Music Time to zero
		ldi XH,HIGH(NotePointer)		; Load NotePointer SRAM Position
		ldi XL,LOW(NotePointer) 		;
		st X, TempReg 					; Reset Music Note Position to zero
		mov TimeCounter, TempReg        ; Reset Music Interrupt Counter to zero
		mov TimePointer, TempReg 		; Reset Music Time Position to zero

		ldi r16, $12					; Enable Game Timer and Music Timer Interrupts
		out TIMSK, r16					;

;******************* GamePlay *****************************
Gameplay:  		
		rcall Ground					; Display Ground	
		rcall Bird						; Display Bird		
		rcall Tube						; Display Tube		
		rcall ScoreOut					; Display Score	
		rcall HighScoreOut				; Display High Score
		cpi InterruptState, $FF			; Check for Game Timer Interrupt	
		breq Move						; If Game Interrupt happened, Move

FlyDone:
		LDI ZH, HIGH(2*NoteTimes)		; Load NoteTimes table
		LDI ZL, LOW(2*NoteTimes)		;
		ldi TempReg, $00				;
		add ZL, TimePointer 			; Move Z-Pointer to Current Music Time Position
		adc ZH, TempReg 				;
		lpm CurrentTime, Z 				; Extract Current Music Time 
		cp TimeCounter, CurrentTime 	; Compare Music Interrupt Counter with Music Time
		brlo NoteDone 					; If Counter is lower, do note change Music Note
		rcall NoteChange 				; If Counter matches, change Musics Note

NoteDone:
		cpi Crash, $FF					; 	
		breq Crashed					; If bird was crashed, go to crash animation
		rjmp GamePlay					; If bird was not crashed, continue gameplay	

;******************* Crash Animation ***********************
Crashed:
		ldi TempReg, $0F 				;
		cp BirdPosition, TempReg 		; Check whether bird hits ceiling
		ldi TempReg, $FA 				; 
		mov BirdSpeed, TempReg 			; If bird does not hit ceiling, add upward speed
		brsh TopCheckDone 				;
		ldi TempReg, $0F 				; 
		mov BirdPosition, TempReg 		; If bird hit ceiling, stop bird at ceiling
		ldi TempReg, $00				; If bird hit ceiling, reset Bird Speed to zero
		mov BirdSpeed, TempReg 			; 
		
TopCheckDone:		
		ldi TempReg, $00 				;
		mov ClockCounter, TempReg 		; Disable Music
		sts	OCR3AH,TempReg 				;
		sts OCR3AL,TempReg	 			;


CrashScreen:
		rcall Ground					; Display Ground	
		rcall Bird						; Display Bird		
		rcall Tube						; Display Tube		
		rcall ScoreOut					; Display Score	
		rcall HighScoreOut				; Display High Score
		cpi InterruptState, $FF			; Check for Game Timer Interrupt			
		breq CrashMove 					; If Game Interrupt happened, CrashMove

CrashMoveDone:
		ldi TempReg, $30				;
		cp TempReg, ClockCounter 		; Compare ClockCounter with $30
		breq CrashDone 					; If Clock Counter reaches $30, stop crash animation 
		rjmp CrashScreen 				; If Clock Counter lower than $30, continue crash animation

CrashMove:
		ldi InterruptState, $00			; Reset Timer Interrupt State
		inc ClockCounter 				; Increase Clock Counter
		ldi TempReg, $01 				; 
		add BirdSpeed, TempReg			; Update Bird Speed
		add BirdPosition, BirdSpeed 	; Update Bird Position
		ldi TempReg, $E0 				;
		cp BirdPosition, TempReg		; Check whether bird hits Ground
		brlo CrashTopCheck 				; If bird higher than Ground, check whether bird hits ceiling
		mov BirdPosition, TempReg 		; If bird hits Ground, stop bird at Ground
		ldi TempReg, $00 				;
		mov BirdSpeed, TempReg 			; If bird hits Ground, reset Bird Speed to zero
		rjmp CrashMoveDone 				; Continue crash sequence

CrashTopCheck:
		ldi TempReg, $0F 				;
		cp BirdPosition, TempReg 		; Check whether bird hits ceiling
		brsh CrashMoveDone 				; If bird does not hit ceiling, continue crash sequence
		mov BirdPosition, TempReg 		; If bird hit ceiling, stop bird at ceiling
		ldi TempReg, $00				;
		mov BirdSpeed, TempReg 			; If bird hit ceiling, reset Bird Speed to zero
		rjmp CrashMoveDone 				; Continue crash sequence
		 

CrashDone:
		ldi r16, $00					; Disable Game Timer and Music Timer Interrupts
		out TIMSK, r16		 			;
	 	rjmp Main 						; Go to Standby Screen



;*********************************************************
;***************                         *****************
;***************      GAME PHYSICS       *****************
;***************                         *****************
;*********************************************************	
		
;****************** Movement Physics *********************
Move: 	
		inc ClockCounter 				; Increase number of Game Interrupts Occured
		lds TempReg, Tubex1				; 
		cpi TempReg, $00 				; Check whether Tube1 X-Coordinate is at zero
		brne move1 						; If Tube1 is already moving, go to move1
		ldi TempReg, $01 				; 
		cp ClockCounter, TempReg 		; If Tube1 is not already moving, move it after 1 Game Interrupt
		brne movedone 					;
		ldi TempReg, $2B 				; Shift Tube1 X-Coordinate to $2B

move1:
		inc TempReg 					; Move Tube1 horizontally by 1
		cpi TempReg, $FF 				; 
		brne move1done 					; If Tube1 does not reach the end of the screen, go to move1done
		
		LDI ZH, HIGH(2*LevelDesign) 	; Load LevelDesign table
		LDI ZL, LOW(2*LevelDesign)	 	;
		ldi TempReg, $00 				;
		add ZL, CurrentLevel 			; Move Z-Pointer to Current LevelDesign Position
		adc ZH, TempReg 				;
		lpm  							; Extract Current LevelDesign Height
		inc CurrentLevel 				; Increase Current LevelDesign Pointer
		ldi TempReg, $11 				; 
		cp CurrentLevel, TempReg 		; If Current LevelDesign Pointer reaches the end of the sequence,
		ldi TempReg, $01 				; reset it back to 1
		brne modify1b		 			; 
		mov CurrentLevel, TempReg 		; 
modify1b:		
		sts Tubey1, R0 					; Change the height of Tube1
		ldi TempReg, $2C 				; Reset X-Coordinate of Tube1 to right of the screen

move1done:
		sts Tubex1, TempReg 		 	; Change X-Coordinate of Tube1
		
		lds TempReg, Tubex2 			;
		cpi TempReg, $00 				; Check whether Tube2 X-Coordinate is at zero
		brne move2 						; If Tube2 is already moving, go to move2
		ldi TempReg, $6F 				;
		cp ClockCounter, TempReg 		; If Tube2 is not already moving, move it after 111 Game Interrupts
		brne movedone 					;
		ldi TempReg, $2B 				; Shift Tube2 X-Coordinate to $2B

move2:		
		inc TempReg 					; Move Tube1 horizontally by 1
		cpi TempReg, $FF 				;
		brne move2done 					; If Tube1 does not reach the end of the screen, go to move2done
		
		LDI ZH, HIGH(2*LevelDesign) 	; Load LevelDesign table
		LDI ZL, LOW(2*LevelDesign) 		;
		ldi TempReg, $00 				; 
		add ZL, CurrentLevel 			; Move Z-Pointer to Current LevelDesign Position
		adc ZH, TempReg 				;
		lpm  							; Extract Current LevelDesign Height
		inc CurrentLevel 				; Increase Current LevelDesign Pointer
		ldi TempReg, $11 				;
		cp CurrentLevel, TempReg 		; If Current LevelDesign Pointer reaches the end of the sequence,
		ldi TempReg, $01 				; reset it back to 1
		brne modify2b 					;
		mov CurrentLevel, TempReg 		;
modify2b:	
		sts Tubey2, R0 					; Change the height of Tube2
		ldi TempReg, $2C 				; Reset X-Coordinate of Tube2 to right of the screen

move2done:
		sts Tubex2, TempReg 			; Change X-Coordinate of Tube1

movedone:	
		ldi TempReg, $7B 				;
		lds TempReg2, Tubex1 			; 
		cp TempReg2, TempReg 			; 
		breq incscore 					; If bird has moved across the Tube1, increase the score
		lds TempReg2, Tubex2 			;
		cp TempReg2, TempReg 			;
		breq incscore 					; If bird has moved across the Tube2, increase the score

incscoredone:
		ldi InterruptState, $00 		; Reset InterruptState to None
		cpi ButtonState, $FF 			; Check whether the button has been pressed
		breq Flap						; If Pressed, got to Flap
Flapdone:	
		ldi TempReg, $01
		add BirdSpeed, TempReg		 	; Update Bird Speed
		add BirdPosition, BirdSpeed 	; Update Bird Position
		
		ldi TempReg, $E0 				;
		cp BirdPosition, TempReg		; 
		brsh HitGround					; If bird has hit the Ground, go to HitGround
		
		ldi TempReg, $0F 				;
		cp BirdPosition, TempReg 		; 
		brlo BirdCrash 					; If bird has hit the ceiling, go to BirdCrash

checktube1:
		ldi TempReg, $7B 				;
		lds TempReg2, Tubex1 			; 
		cp TempReg2, TempReg 			; Check if bird has reached Tube1
		brlo checktube2 				; If bird has not reached Tube1, go to checktube2
		ldi TempReg, $AF 				;
		cp TempReg2, TempReg 			; Check if bird is still within reach of Tube1
		brsh checktube2 				; If bird has gone beyond reach of Tube1, go to checktube2
		lds TempReg2, Tubey1 			;
		cp BirdPosition, TempReg2 		; 
		brsh BirdCrash 					; If bird has hit Tube1 bottom opening, go to BirdCrash
		mov TempReg, TempReg2 			;
		subi TempReg, $39 				; 
		cp BirdPosition, TempReg 		;
		brlo BirdCrash  				; If bird has hit Tube1 top opening, go to BirdCrash

checktube2:
		ldi TempReg, $7B 				;
		lds TempReg2, Tubex2 			;
		cp TempReg2, TempReg 			; Check if bird has reached Tube2
		brlo checktubedone 				; If bird has not reached Tube2, go to checktubedone
		ldi TempReg, $AF 				;
		cp TempReg2, TempReg 			; Check if bird is still within reach of Tube2
		brsh checktubedone 				; If bird has gone beyond reach of Tube2, go to checktubedone
		lds TempReg2, Tubey2 			;
		cp BirdPosition, TempReg2 		; If bird has hit Tube2 bottom opening, go to BirdCrash
		brsh BirdCrash 					;
		mov TempReg, TempReg2 			;
		subi TempReg, $39 				; 
		cp BirdPosition, TempReg 		;
		brlo BirdCrash  				; If bird has hit Tube2 top opening, go to BirdCrash

checktubedone:
		rjmp FlyDone 					; When all tubes have been checked, go to FlyDone

HitGround:
		ldi TempReg, $E0 				;
		mov BirdPosition, TempReg 		; If bird has hit Ground, it remains on Ground
		ldi Crash, $FF 					; Crash State changed to True
		rjmp FlyDone 					; Go to FlyDone

BirdCrash:
		ldi Crash, $FF 					; Crash State changed to True
		rjmp FlyDone 					; Go to FlyDone

;********************* User Input ***********************
Flap:	
		ldi ButtonState, $00 			; Reset Button State to None
		ldi TempReg, $F9
		mov BirdSpeed, TempReg 			; Add vertival upward speed to bird
		rjmp Flapdone 					; Go to Flap Done


incscore:
		lds TempReg, Score 				;
		inc TempReg 					; Increase Score
		sts Score, TempReg 				; Save to SRAM
		rjmp incscoredone 				;

;******************* Music Output ***********************
NoteChange:			
		ldi TempReg, $00 				;
		mov TimeCounter, TempReg 		;
		LDI ZH, HIGH(2*MusicNotes) 		; Load MusicNotes table
		LDI ZL, LOW(2*MusicNotes) 		;
		ldi XH,HIGH(NotePointer)  		; Load Low Byte of NotePointer SRAM Position to X
		ldi XL,LOW(NotePointer) 		;
		ld TempReg, X 					; Extract Low Byte of NotePointer to TempReg
		add ZL, TempReg 				; Add Low Byte of NotePointer to Z-Pointer
		ldi XH,HIGH(2*NotePointer)  	; Load High Byte of NotePointer SRAM Position to X
		ldi XL,LOW(2*NotePointer) 		;
		ld TempReg, X 					; Extract High Byte of NotePointer to TempReg
		adc ZH, TempReg 				; Add with carry Low Byte of NotePointer to Z-Pointer
		lpm TempReg, Z+	 				; Extract Musics Note Low Byte
		lpm TempReg2, Z 				; Extract Musics Note High Byte
		sts	OCR3AH,TempReg2 			; Change PWM period High Byte
		sts OCR3AL,TempReg	 			; Change PWM period Low Byte
		inc TimePointer 				; Increase TimePointer

		ldi XH,HIGH(NotePointer)  		; 
		ldi XL,LOW(NotePointer)			;
		ld TempReg, X 					;
		ldi TempReg2, $02 				;
		add TempReg, TempReg2 			; Increase NotePointer by 2 
		st X, TempReg 					;
		ldi XH,HIGH(2*NotePointer) 		; 
		ldi XL,LOW(2*NotePointer) 		;
		ld TempReg, X 					;
		ldi TempReg2, $00 				;
		adc TempReg, TempReg2 			;
		st X, TempReg 					; Store Note Pointer to its SRAM Position
		ldi TempReg2, $01 				; If NotePointer reaches 340, 
		cpse TempReg, TempReg2 			;
		ret 							;
		ldi XH,HIGH(NotePointer) 		; 
		ldi XL,LOW(NotePointer) 		;
		ld TempReg, X 					;
		ldi TempReg2, $54 				;
		cpse TempReg, TempReg2 			;
		ret 							;
		ldi TempReg, $00 				; Reset NotePointer to 0
		st X, TempReg 					;
		ldi XH,HIGH(2*NotePointer) 		; 
		ldi XL,LOW(2*NotePointer) 		;
		ldi TempReg, $00 				;
		st X, TempReg 					;
		clr TimePointer 				;
		ret



;*********************************************************
;***************                         *****************
;***************        ANIMATION        *****************
;***************                         *****************
;*********************************************************

;******************** Display Score **********************
ScoreOut:
		ldi TempReg, $05				;
		mov NumPositiony, TempReg 		;
		ldi TempReg, $0C 				;
		mov NumPositionx, TempReg 		;
		rcall EOut 						; Display 'E'
			
		ldi TempReg, $18 				;
		mov NumPositionx, TempReg 		;
		rcall ROut 						; Display 'R'
	 	
		ldi TempReg, $24				;
		mov NumPositionx, TempReg 		;
		rcall OOut 						; Display 'O'
				
		ldi TempReg, $30				;
		mov NumPositionx, TempReg 		;
		rcall COut 						; Display 'C'

		ldi TempReg, $3C 				;
		mov NumPositionx, TempReg 		;
		rcall SOut 						; Display 'S'

		lds TempReg, Score 				;
		rcall hex2dec 					; Convert Score from Hex to Decimal

		cbi PortB, 2					; Enable Brightness
		ldi TempLeftY4, $15 			;
		mov NumPositionx, TempLeftY4 	;
		ldi TempLeftY4, $20 			;
		mov NumPositiony, TempLeftY4 	;
		rcall DigitOut 					; Display the Lower Digit
 
		ldi TempLeftY4, $2A 			;
		mov NumPositionx, TempLeftY4 	;
		mov TempReg, TempBottom6 		;
		rcall DigitOut 					; Display the Higher Digit
		ret 							;


;*************** Display High Score **********************
HighScoreOut:		
		ldi TempReg, $80 				;
		mov NumPositiony, TempReg 		;
		ldi TempReg, $16 				;
		mov NumPositionx, TempReg 		;
		rcall HOut 						; Display 'H'
	
		ldi TempReg, $22 				;
		mov NumPositionx, TempReg 		;
		rcall GOut 						; Display 'G'
				
		ldi TempReg, $2E 				;
		mov NumPositionx, TempReg 		;
		rcall IOut 						; Display 'I'

		ldi TempReg, $3A 				;
		mov NumPositionx, TempReg 		;
		rcall HOut 						; Display 'H'

		ldi TempReg, $98 				;
		mov NumPositiony, TempReg 		;
		ldi TempReg, $0C 				;
		mov NumPositionx, TempReg 		;
		rcall EOut 						; Display 'E'
			
		ldi TempReg, $18 				;
		mov NumPositionx, TempReg 	 	;
		rcall ROut 						; Display 'R'
	
		ldi TempReg, $24 				;
		mov NumPositionx, TempReg 		;
		rcall OOut 						; Display 'O'
				
		ldi TempReg, $30 				;
		mov NumPositionx, TempReg 		;
		rcall COut 						; Display 'C'

		ldi TempReg, $3C 				;
		mov NumPositionx, TempReg 		;
		rcall SOut 						; Display 'S'

		ldi TempReg2, LOW(HighScore) 	; Load High Score EEPROM Address
		ldi TempRightX3, High(HighScore);
		rcall EEPROM_read 				; Read High Score from EEPROM
		rcall hex2dec 					; Convert High Score from Hex to Decimal

		cbi PortB, 2					; Enable Brightness
		ldi TempLeftY4, $15  			;
		mov NumPositionx, TempLeftY4 	;
		ldi TempLeftY4, $B0 			;
		mov NumPositiony, TempLeftY4 	;
		rcall DigitOut 					; Display Lower Digit

		ldi TempLeftY4, $2A  			;
		mov NumPositionx, TempLeftY4 	;
		mov TempReg, TempBottom6 		;
		rcall DigitOut					; Display Higher Digit
		ret 							;

;********************* Display Tube **********************
Tube:
		ldi TempReg, $24 				;
		lds TempRightX3, Tubex1 		; Extract Tube1 X-Coordinates
		lds TempLeftY4, Tubex1 			; 
		add TempLeftY4, TempReg		 	; Calculate Tube1 Left

		cpi TempLeftY4, $50				; 
		brlo compare1					; If TubeLeft exceeds the right of display area, go to compare1
		rjmp notcompare1 				; If TubeLeft does not exceed the right of display area, go to notcompare1

compare1:
		cpi TempRightX3, $50 			; 
		brlo tube2 						; If TubeRight does not exceed the left of display area, go to tube2
		ldi TempLeftY4, $FF 			; If TubeRight exceed the left of display area, set TubeLeft to left display boundary

notcompare1:
		cpi TempRightX3, $50			; 
		brsh tube1out					; If TubeRight does exceed the right of display area, go to tube1out
		ldi TempRightX3, $50 			; If TubeRight exceed the right of display area, set TubeRight to right display boundary

tube1out:
		lds TempTopLength5, Tubey1		; Extract Tube1 Height
		ldi TempBottom6, $E0 			; Calculate Bottom Tube1 Height
		rcall TubeOut 					; Display Bottom Tube1
		
		ldi TempTopLength5, $00 		;
		lds TempBottom6, Tubey1			; 
		subi TempBottom6, $48 			; Calculate Top Tube1 Height
		rcall TubeOut 					; Display Top Tube1

tube2:
		ldi TempReg, $24 				;
		lds TempRightX3, Tubex2 		; Extract Tube2 X-Coordinates
		lds TempLeftY4, Tubex2 			;
		add TempLeftY4, TempReg 		; Calculate Tube2 Left

		cpi TempLeftY4, $50				; 
		brlo compare2					; If TubeLeft exceeds the right of display area, go to compare2
		rjmp notcompare2 				; If TubeLeft does not exceed the right of display area, go to notcompare2

compare2:
		cpi TempRightX3, $50 			;
		brlo tubedone 					; If TubeRight does not exceed the left of display area, go to tubedone
		ldi TempLeftY4, $FF 			; If TubeRight exceed the left of display area, set TubeLeft to left display boundary


notcompare2:
		cpi TempRightX3, $50			; 
		brsh tube2out					; If TubeRight does exceed the right of display area, go to tube2out
		ldi TempRightX3, $50 			; If TubeRight exceed the right of display area, set TubeRight to right display boundary

tube2out:
		lds TempTopLength5, Tubey2		; Extract Tube2 Height
		ldi TempBottom6, $E0 			; Calculate Bottom Tube2 Height
		rcall TubeOut 					; Display Bottom Tube1
		
		ldi TempTopLength5, $00 		;
		lds TempBottom6, Tubey2			; 
		subi TempBottom6, $48			; Calculate Top Tube1 Height
		rcall TubeOut 					; Display Top Tube2

tubedone:
		ret

;*************** Convert Hex to Decimal ******************
hex2dec:
		ldi TempReg2, $00
		ldi TempBottom6, $00
		ldi TempReg2, -1 + '0'
_bib3:  
		inc     TempReg2
        subi    TempReg, low(100)
        sbci    TempBottom6, high(100)
        brcc    _bib3

        ldi     TempBottom6, 10 + '0'
_bib4:  
		dec     TempBottom6
        subi    TempReg, -10
        brcs    _bib4

        subi    TempReg, -'0'
		ret

;*************** Display 'Flappy Bird' *******************
FlappyOut:
		ldi TempReg, $10 				;
		mov NumPositiony, TempReg 		;
		ldi TempReg, $C9 				;
		mov NumPositionx, TempReg 		;
		rcall FOut 						; Display 'F'
			
		ldi TempReg, $B4 				;
		mov NumPositionx, TempReg 		;
		rcall LOut 						; Display 'L'
	
		ldi TempReg, $9F 				;
		mov NumPositionx, TempReg 		;
		rcall AOut						; Display 'A'
				
		ldi TempReg, $8A 				;
		mov NumPositionx, TempReg 		;
		rcall POut 						; Display 'P'
 					
		ldi TempReg, $75 				;
		mov NumPositionx, TempReg 		;
		rcall POut 						; Display 'P'

		ldi TempReg, $60 				;
		mov NumPositionx, TempReg 		;
		rcall YOut 						; Display 'Y'

		ldi TempReg, $40 				;
		mov NumPositiony, TempReg 		;
		ldi TempReg, $B4 	 			;
		mov NumPositionx, TempReg 		;
		rcall BOut 						; Display 'B'
			
		ldi TempReg, $9F 				;
		mov NumPositionx, TempReg 		;
		rcall BigIOut 					; Display 'I'
	 	
		ldi TempReg, $8A 				;
		mov NumPositionx, TempReg 		;
		rcall BigROut					; Display 'R'
				
		ldi TempReg, $75 				;
		mov NumPositionx, TempReg 		;
		rcall DOut 						; Display 'D'

		ret 							;

;********************* Display Digit **********************
DigitOut:		
		lsl TempReg
		lsl TempReg
		lsl TempReg
		lsl TempReg		 
		cpi TempReg, $00
		brne NotZero
		rcall ZeroOut
		ret
NotZero:
		cpi TempReg, $10
		brne NotOne
		rcall OneOut
		ret
NotOne:
		cpi TempReg, $20
		brne NotTwo
		rcall TwoOut
		ret
NotTwo:
		cpi TempReg, $30
		brne NotThree
		rcall ThreeOut
		ret
NotThree:
		cpi TempReg, $40
		brne NotFour
		rcall FourOut
		ret
NotFour:
		cpi TempReg, $50
		brne NotFive
		rcall FiveOut
		ret
NotFive:
		cpi TempReg, $60
		brne NotSix
		rcall SixOut
		ret
NotSix:
		cpi TempReg, $70
		brne NotSeven
		rcall SevenOut
		ret
NotSeven:
		cpi TempReg, $80
		brne NotEight
		rcall EightOut
		ret
NotEight:
		cpi TempReg, $90
		brne NotNine
		rcall NineOut
NotNine:
		ret

;********************* Display Tube ***********************
TubeOut:		
		cp TempRightX3, TempLeftY4
		brsh tubedone
		
		mov TempReg, TempRightX3

		out PORTD, TempTopLength5
		out PORTC, TempReg
		
		cbi PortB, 2					; Enable Brightness
		rcall BigDel

Top:	
		inc TempReg
		out PORTD, TempTopLength5
		out PORTC, TempReg
		
		cp TempReg, TempLeftY4
		brne Top 

		mov TempReg, TempTopLength5	

Left:	
		inc TempReg
		out PORTD, TempReg
		cp TempReg, TempBottom6
		brne Left

		mov TempReg, TempLeftY4

Bottom: 
		dec TempReg
		out PORTC, TempReg
		cp TempReg, TempRightX3
		brne Bottom

		mov TempReg, TempBottom6

Right:  
		dec TempReg
		out PORTD, TempReg
		
		cp TempReg, TempTopLength5
		brne Right

		sbi PortB, 2					; Disable Brightness
		rcall BigDel
		ret    


;******************* Display Ground ***********************
Ground:
		ldi TempRightX3, $50
		ldi TempLeftY4, $FF
		ldi TempTopLength5, $E0
		ldi TempBottom6, $FF
		rcall TubeOut

		ldi TempRightX3, $50
		ldi TempLeftY4,	 $FF
		ldi TempTopLength5, $00
		ldi TempBottom6, $E0
		rcall TubeOut

		ret

;********************* Display Bird ***********************
Bird:
		ldi TempRightX3, $9F
		ldi TempLeftY4, $AF
		mov TempTopLength5, BirdPosition 
		mov TempBottom6, TempTopLength5 
		subi TempTopLength5, $0F
		rcall TubeOut
		ret

;**************** Display Horizontal Line *****************
HorizontalOut:
		mov TempReg2, TempRightX3
		add TempReg2, TempTopLength5
		mov TempReg, TempRightX3
		out PORTC, TempReg		
		out PORTD, TempLeftY4		
		cbi PortB, 2					; Enable Brightness
		rcall BigDel


HorizontalAgain:
		inc TempReg
		out PORTC, TempReg		
		cp TempReg, TempReg2
		brne HorizontalAgain
		sbi PortB, 2					; Disable Brightness
		rcall BigDel
		ret

;**************** Display Vertical Line ******************
VerticalOut:
		mov TempReg2, TempLeftY4
		add TempReg2, TempTopLength5
		mov TempReg, TempLeftY4
		out PORTC, TempRightX3		
		out PORTD, TempReg		
		cbi PortB, 2					; Enable Brightness
		rcall BigDel


VerticalAgain:
		inc TempReg
		out PORTD, TempReg		
		cp  TempReg, TempReg2
		brne VerticalAgain
		sbi PortB, 2					; Disable Brightness
		rcall BigDel
		ret

;**************** Display Number 1 ***********************
OneOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;**************** Display Number 2 ***********************
TwoOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $0B
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ldi TempReg, $0D
		add TempLeftY4, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $13
		add TempLeftY4, TempReg
		rcall HorizontalOut
		ldi TempReg, $13
		sub TempLeftY4, TempReg
		mov TempRightX3, NumPositionx
		ldi TempReg, $10
		add TempRightX3, TempReg
		rcall VerticalOut
		ret

;**************** Display Number 3 ***********************
ThreeOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut		
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ldi TempReg, $0D
		add TempLeftY4, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $13
		add TempLeftY4, TempReg
		rcall HorizontalOut
		ret

;**************** Display Number 4 ***********************
FourOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut		
		
		ldi TempReg, $0D
		add TempLeftY4, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut

		ldi TempReg, $0D
		sub TempLeftY4, TempReg
		ldi TempReg, $10
		add TempRightX3, TempReg
		ldi TempReg, $0D
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ret

;**************** Display Number 5 ***********************
FiveOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $0D
		add TempLeftY4, TempReg
		rcall HorizontalOut
		ldi TempReg, $13
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		ldi TempReg, $0D
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ldi TempReg, $0D 
		add TempLeftY4, TempReg
		mov TempRightX3, NumPositionx
		ldi TempReg, $13
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;**************** Display Number 6 ***********************
SixOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $0D
		add TempLeftY4, TempReg
		rcall HorizontalOut
		ldi TempReg, $13
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ldi TempReg, $0D 
		add TempLeftY4, TempReg
		mov TempRightX3, NumPositionx
		ldi TempReg, $13
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;**************** Display Number 7 ***********************
SevenOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ret

;**************** Display Number 8 ***********************
EightOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $0D
		add TempLeftY4, TempReg
		rcall HorizontalOut
		ldi TempReg, $13
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		mov TempRightX3, NumPositionx
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;**************** Display Number 9 ***********************
NineOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut		
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $0D
		add TempLeftY4, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut

		ldi TempReg, $0D
		sub TempLeftY4, TempReg
		ldi TempReg, $10
		add TempRightX3, TempReg
		ldi TempReg, $0D
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ret

;**************** Display Number 0 ***********************
ZeroOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $20
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		mov TempRightX3, NumPositionx
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Small Letter H **********************
HOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony		
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut		
		ldi TempReg, $08
		add TempRightX3, TempReg
		rcall VerticalOut	
		ldi TempReg, $08
		add TempLeftY4, TempReg
		mov TempTopLength5, TempReg
		mov TempRightX3, NumPositionx
		rcall HorizontalOut		
		ret

;************ Display Small Letter I **********************
IOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $04
		add TempRightX3, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Small Letter G **********************
GOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		add TempRightX3, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		
		mov TempRightX3, NumPositionx
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		mov TempLeftY4, NumPositiony
		add TempLeftY4, TempReg
		rcall VerticalOut
		ldi TempReg, $04
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ret

;************ Display Small Letter S **********************
SOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $08
		add TempLeftY4, TempReg
		rcall HorizontalOut
		ldi TempReg, $08
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08 
		add TempRightX3, TempReg
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ldi TempReg, $08
		add TempLeftY4, TempReg
		mov TempRightX3, NumPositionx
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Small Letter C **********************
COut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		add TempRightX3, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ret

;************ Display Small Letter O **********************
OOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		add TempRightX3, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ret

;************ Display Small Letter R **********************
ROut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $03
		add TempRightX3, TempReg
		ldi TempReg, $05	
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $08	
		mov TempTopLength5, TempReg
		rcall VerticalOut
	
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		add TempLeftY4, TempReg
		rcall VerticalOut	
		rcall HorizontalOut

		ldi TempReg, $08
		add TempRightX3, TempReg
		sub TempLeftY4, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Small Letter E **********************
EOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall HorizontalOut		
			
		ldi TempReg, $08
		add TempLeftY4, TempReg
		ldi TempReg, $08
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $08
		add TempLeftY4, TempReg
		rcall HorizontalOut

		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		add TempRightX3, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut

		ret

;************ Display Large Letter F **********************
FOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut		
		
			
		ldi TempReg, $10
		add TempLeftY4, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut


		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Large Letter L **********************
LOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg	
		ldi TempReg, $20
		add TempLeftY4, TempReg
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut

		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Large Letter A **********************
AOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut	
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		mov TempRightX3, NumPositionx
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Large Letter P **********************
POut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		rcall VerticalOut
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ret

;************ Display Large Letter Y **********************
YOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		rcall VerticalOut	
		
		ldi TempReg, $08 
		sub TempRightX3, TempReg
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall VerticalOut
		ret

;************ Display Large Letter B **********************
BOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut	
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall HorizontalOut	
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10 
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		mov TempRightX3, NumPositionx
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Large Letter I **********************
BigIOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $08
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Large Letter R **********************
BigROut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $06
		add TempRightX3, TempReg
		ldi TempReg, $0A	
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $10	
		mov TempTopLength5, TempReg
		rcall VerticalOut
	
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		add TempLeftY4, TempReg
		rcall VerticalOut	
		rcall HorizontalOut

		ldi TempReg, $10
		add TempRightX3, TempReg
		sub TempLeftY4, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ret

;************ Display Large Letter D **********************
DOut:
		mov TempRightX3, NumPositionx
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		rcall HorizontalOut
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut
		ldi TempReg, $10
		mov TempTopLength5, TempReg
		ldi TempReg, $20
		add TempLeftY4, TempReg
		rcall HorizontalOut		
		
		mov TempLeftY4, NumPositiony
		ldi TempReg, $10
		add TempRightX3, TempReg
		ldi TempReg, $20
		mov TempTopLength5, TempReg
		rcall VerticalOut	
		ret



;*********************************************************
;***************                         *****************
;***************     EEPROM COMMANDS     *****************
;***************                         *****************
;*********************************************************

;******************** EEPROM Write ***********************
EEPROM_write:
	
		sbic EECR,EEWE 					; Wait for completion of previous write
		rjmp EEPROM_write 				;
		out EEARH, TempRightX3 			; Set up address (TempRightX3:TempReg2) in address register
		out EEARL, TempReg2 			;
		out EEDR,TempReg 				; Write data (TempReg) to data register
		sbi EECR,EEMWE 					; Write logical one to EEMWE
		sbi EECR,EEWE 					; Start eeprom write by setting EEWE
		ret 							;

;******************** EEPROM Read ***********************
EEPROM_read:
		sbic EECR,EEWE 					; Wait for completion of previous write
		rjmp EEPROM_read 				;
		out EEARH, TempRightX3 			; Set up address (TempRightX3:TempReg2) in address register
		out EEARL, TempReg2 			;
		sbi EECR,EERE 					; Start eeprom read by writing EERE
		in TempReg,EEDR 				; Read data from data register
		ret 							;



;*********************************************************
;***************                         *****************
;***************          DELAY          *****************
;***************                         *****************
;*********************************************************
	
BigDEL:
        ldi ZH, HIGH(10)
        ldi ZL, LOW (10)
CountBigDel:
        sbiw ZL, 1
        brne CountBigDel
        ret  
