;Lab 2, Section 3
;Name: Steven Miller
;Class #: 11318
;PI Name: Anthony Stross
;Description: Implements software delay using timer
;***************INCLUDES*************************************
.include "ATxmega128a1udef.inc"
;***************END OF INCLUDES******************************

;*********************************EQUATES********************************
.EQU input = 0b00000000
.EQU output = 0b11111111
.EQU div2 = 0b00000010
;*******************************END OF EQUATES*******************************

;*********************************DEFS********************************

;*******************************END OF DEFS*******************************

;***********MAIN PROGRAM*******************************
.CSEG
.org 0x0100
MAIN:
ldi r16, 0x10
ldi r17, div2
;to achieve atleast a 40ms count, we need a displacement
;of atleast 1.23
;will round to 2 because we cant represent floats in assembly
;initialize clock
sts TCC0_PER, r16
sts TCC0_CTRLA,r17
;loop
LOOP:
RJMP LOOP
;***********END MAIN PROGRAM*******************************
