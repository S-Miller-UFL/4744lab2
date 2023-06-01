;Lab 2, prelab question x
;Name: Steven Miller
;Class #: 11318
;PI Name: Anthony Stross
;Description: counts how many minutes have elapsed since start of program
;***************INCLUDES*************************************
.include "ATxmega128a1udef.inc"
;***************END OF INCLUDES******************************

;*********************************EQUATES********************************
.EQU prescalar = 64
.EQU sysclk = 2000000
.EQU desiredperiod = 1 ;1000ms
.EQU reciprocal = 1/1 ;idk how to spell reciprocal
.EQU offset = 590 ;correcting for imprecision
;*******************************END OF EQUATES*******************************

;*********************************DEFS********************************
.DEF second_r18 = r18
.DEF minute_r19 = r19
.DEF one_r20 = r20
;*******************************END OF DEFS*******************************

;***********MAIN PROGRAM*******************************
.CSEG
.org 0x0100
MAIN:

;initialize registers
ldi second_r18,60
ldi minute_r19,0
ldi one_r20,1

;initialize count register
ldi r16,0
sts TCC0_CNT, r16
sts TCC0_CNT+1,r16

;***********************NOTES***********************
;if we want to achieve a period of 40 ms with a prescalar of 8
;and a frequency of 2mhz, that equates to:
;ticks = (2000000cycles/second)/(64cycles/tick)*1seconds = 31250 ticks
;ticks = (systemclock/prescalar) / (1/desiredperiod)
;it also may be a good idea to add a number that corrects
;for any imprecision 
;***********************END OF NOTES*****************

;initialize period register
ldi r16,low(((sysclk/prescalar)/reciprocal)+offset)
sts TCC0_PER, r16
ldi r16,high(((sysclk/prescalar)/reciprocal)+offset)
sts TCC0_PER+1,r16

;initialize clksel
ldi r16, TC_CLKSEL_DIV64_gc
sts TCC0_CTRLA,r16

loop:
	lds r17,TCC0_INTFLAGS
	;check ov flag
	andi r17,0b00000001
	cpi r17,1
	;branch if we have overflow
	breq decrementsecond
	;else
	rjmp loop
	decrementsecond:
		;decrement "second" register
		dec second_r18
		;clear ov flag
		ldi r17, 0b00000001
		sts TCC0_INTFLAGS,r17
		;see if we hit a minute
		cpi second_r18, 0
		brne loop
		add minute_r19,one_r20
rjmp loop
end:
rjmp end

;***********END MAIN PROGRAM*******************************

