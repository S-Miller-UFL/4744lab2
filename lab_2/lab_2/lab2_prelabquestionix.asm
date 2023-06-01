;Lab 2, prelab question ix
;Name: Steven Miller
;Class #: 11318
;PI Name: Anthony Stross
;Description: Implements software delay using timer with prescalar
;value of 2
;***************INCLUDES*************************************
.include "ATxmega128a1udef.inc"
;***************END OF INCLUDES******************************

;*********************************EQUATES********************************
.EQU input = 0b00000000
.EQU output = 0b11111111
;.EQU div2 = 0b00000010
.EQU prescalar = 2
.EQU sysclk = 2000000
.EQU desiredperiod = .04 ;40ms
.EQU reciprocol = 1/.04 ;idk how to spell reciprocol
.EQU offset = 760 ;correcting for imprecision
;*******************************END OF EQUATES*******************************

;*********************************DEFS********************************

;*******************************END OF DEFS*******************************

;***********MAIN PROGRAM*******************************
.CSEG
.org 0x0100
MAIN:

;initialize port c for output
ldi r16, output
sts PORTC_DIR, r16

;initialize count register
ldi r16,0
sts TCC0_CNT, r16
sts TCC0_CNT+1,r16

;***********************NOTES***********************
;if we want to achieve a period of 40 ms with a prescalar of 8
;and a frequency of 2mhz, that equates to:
;ticks = (2000000cycles/second)/(2cycles/tick)*.04seconds = 40000 ticks
;ticks = (systemclock/prescalar) / (1/desiredperiod)
;it also may be a good idea to add a number that corrects
;for any imprecision 
;***********************END OF NOTES*****************

;initialize period register
ldi r16,low(((sysclk/prescalar)/reciprocol)+offset)
sts TCC0_PER, r16
ldi r16,high(((sysclk/prescalar)/reciprocol)+offset)
sts TCC0_PER+1,r16

;initialize clksel
ldi r16, TC_CLKSEL_DIV2_gc
sts TCC0_CTRLA,r16

;toggle output port
loop:
	lds r17,TCC0_INTFLAGS
	;check ov flag
	andi r17,0b00000001
	cpi r17,1
	;branch if we have overflow
	breq toggleoutput
	;else
	rjmp loop
	;if we have an overflow
	toggleoutput:
		;toggle outputs
		ldi r17,output
		sts PORTC_OUTTGL, r17
		;clear ov flag
		ldi r17, 0b00000001
		sts TCC0_INTFLAGS,r17
rjmp loop
end:
rjmp end

;***********END MAIN PROGRAM*******************************
