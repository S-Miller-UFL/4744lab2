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
;*******************************END OF EQUATES*******************************

;*********************************DEFS********************************
;*******************************END OF DEFS*******************************

;***********MEMORY CONFIGURATION*************************

;***********END OF MEMORY CONFIGURATION***************
;***********MAIN PROGRAM*******************************
.CSEG
.org 0x0100
MAIN:
;set port directions
LDI R16, INPUT
STS PORTA_DIR , R16
LDI R16, OUTPUT
STS PORTC_DIR , R16

;loop for actual led and switch circuits
LOOP:
	;copy load value from switch registers into led registers
	LDS R16, PORTA_IN
	STS PORTC_OUT,R16
RJMP LOOP
;***********END MAIN PROGRAM*******************************
