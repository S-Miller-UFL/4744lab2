;Lab 2, Section 2
;Name: Steven Miller
;Class #: 11318
;PI Name: Anthony Stross
;Description: Implements software delays
;***************INCLUDES*************************************
.include "ATxmega128a1udef.inc"
;***************END OF INCLUDES******************************

;*********************************EQUATES********************************
.EQU sramend = 0x3fff ;top of stack
.EQU srambegin = 0x2000 ;bottom of stack
.EQU input = 0b00000000
.EQU output = 0b11111111
;*******************************END OF EQUATES*******************************

;*********************************DEFS********************************
.DEF ms_r16 = r16
.DEF us_r17 = r17
.DEF zero_r18 = r18
.DEF one_r19 = r19
.DEF four_r20 = r20
.DEF multiple_r21 = r21
;*******************************END OF DEFS*******************************

;***********MAIN PROGRAM*******************************
.CSEG
.org 0x0100
MAIN:
;initialize stack pointer
ldi r16, low(sramend)
out CPU_SPL, r16
ldi r16, high(sramend)
out CPU_SPH, r16
;set port directions
LDI R22, output
STS PORTC_DIR , R22
;initialize registers
ldi zero_r18,0
ldi one_r19,1
ldi four_r20,4
;loop to call subroutine
LOOP:
	ldi multiple_r21,1
	rcall delay_x_10ms
	STS PORTC_OUTTGL,R22
RJMP LOOP
;***********END MAIN PROGRAM*******************************

;*********************SUBROUTINES**************************************
; Subroutine Name: delay_10ms
; performs a series of instructions for 10ms
; Inputs: none
; Ouputs: none
; Affected: r16, r17,r19,r20
delay_10ms:
	ldi ms_r16,0
	ldi us_r17,0
	tenms:
		ldi four_r20, 0
			;1ms
			onekus:
				ldi us_r17,0
					;250us
					faus:
						add us_r17,one_r19
						cpi us_r17,253
					brne faus
				add four_r20,one_r19
				cpi four_r20,2	
			;branch if 1ms
			brne onekus
		add ms_r16,one_r19
		;branch if 10 ms	
		cpi ms_r16,10
	brne tenms						
ret
; Subroutine Name: delay_x_10ms
; delays a select multiple of 10ms
; Inputs: r21
; Ouputs: none
; Affected: r16,r17,r19,r20,r21
delay_x_10ms:
push r21
	loopx:
		cpi multiple_r21,0
		breq exit
		call delay_10ms
		dec multiple_r21
	rjmp loopx
exit:
pop r21
ret