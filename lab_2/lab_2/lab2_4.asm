;******************************************************************************
;  File name: lab2_4.asm
;  Author: Christopher Crary
;  Last Modified By: Steven Miller
;  Last Modified On: 31 May 2023
;  Purpose: To allow LED animations to be created with the OOTB uPAD,OOTB SLB, and OOTB MB.
;******************************************************************************

;*******INCLUDES*************************************
.include "ATxmega128a1udef.inc"
;*******END OF INCLUDES******************************

;*******DEFINED SYMBOLS******************************
.equ ANIMATION_START_ADDR	=	0x2000
.equ ANIMATION_SIZE			=	0x1fff
.EQU sramend = 0x3fff
.EQU allones = 0b11111111
.EQU allzeroes = 0b00000000
.EQU s2bit = 3
.EQU s1bit = 2
.EQU sysclk = 2000000
.EQU reciprocal =1/.01
.EQU offset = 0
.EQU prescalar = 8
;*******END OF DEFINED SYMBOLS***********************

;*******MEMORY CONSTANTS*****************************
; data memory allocation
.dseg
.org ANIMATION_START_ADDR
ANIMATION:
.byte ANIMATION_SIZE
;*******END OF MEMORY CONSTANTS**********************

;*******MAIN PROGRAM*********************************
.cseg
.org 0x0000
	rjmp MAIN

.CSEG
.org 0x0100
MAIN:
; initialize the stack pointer
	ldi r16, low(sramend)
	sts CPU_SPL,r16
	ldi r16, high(sramend)
	sts CPU_SPH,r16
; initialize relevant I/O modules (switches and LEDs)
	rcall IO_INIT

; initialize (but do not start) the relevant timer/counter module(s)
	rcall TC_INIT

; Initialize the X and Y indices to point to the beginning of the 
; animation table. (Although one pointer could be used to both
; store frames and playback the current animation, it is simpler
; to utilize a separate index for each of these operations.)
; Note: recognize that the animation table is in DATA memory
	ldi XL, low(ANIMATION_START_ADDR)
	ldi XH, high(ANIMATION_START_ADDR)
	ldi YL, low(ANIMATION_START_ADDR)
	ldi YH, high(ANIMATION_START_ADDR)

; begin main program loop 
	
; "EDIT" mode
EDIT:
	
; Check if it is intended that "PLAY" mode be started, i.e.,
; determine if the relevant switch has been pressed.
	lds r16, PORTF_IN
; If it is determined that relevant switch was pressed, 
; go to "PLAY" mode.
	sbrc r16, s2bit
	rjmp play

; Otherwise, if the "PLAY" mode switch was not pressed,
; update display LEDs with the voltage values from relevant DIP switches
; and check if it is intended that a frame be stored in the animation
; (determine if this relevant switch has been pressed).
	lds r16, PORTA_IN
	sts PORTC_OUT, r16

; If the "STORE_FRAME" switch was not pressed,
; branch back to "EDIT".
	lds r16, PORTA_IN
	sbrs r16, s1bit
	rjmp edit

; Otherwise, if it was determined that relevant switch was pressed,
; perform debouncing process, e.g., start relevant timer/counter
; and wait for it to overflow. (Write to CTRLA and loop until
; the OVFIF flag within INTFLAGS is set.)
	
	;initialize CTRLA
	ldi r16, TC_CLKSEL_DIV8_gc
	sts TCC0_CTRLA,r16
	;load period register
	ldi r16,low(((sysclk/prescalar)/reciprocal)+offset)
	sts TCC0_PER, r16
	ldi r16,high(((sysclk/prescalar)/reciprocal)+offset)
	sts TCC0_PER+1,r16

	;debouncing
	debounceloop:
		lds r17,TCC0_INTFLAGS
		;check ov flag
		;branch if we have overflow
		sbrs  r17,0
		rjmp debounceloop

; After relevant timer/counter has overflowed (i.e., after
; the relevant debounce period), disable this timer/counter,
; clear the relevant timer/counter OVFIF flag,
; and then read switch value again to verify that it was
; actually pressed. If so, perform intended functionality, and
; otherwise, do not; however, in both cases, wait for switch to
; be released before jumping back to "EDIT".
	;disable TC
	ldi r17, 0b00000000
	sts TCC0_CTRLA,r17
	;clear ov flag
	ldi r17, 0b00000001
	sts TCC0_INTFLAGS,r17

	;red switch again
	lds r16, PORTA_IN
	sbrs r16, s1bit
	rjmp edit

; Wait for the "STORE FRAME" switch to be released
; before jumping to "EDIT".
STORE_FRAME_SWITCH_RELEASE_WAIT_LOOP:
	
	
; "PLAY" mode
PLAY:

; Reload the relevant index to the first memory location
; within the animation table to play animation from first frame.


PLAY_LOOP:

; Check if it is intended that "EDIT" mode be started
; i.e., check if the relevant switch has been pressed.`


; If it is determined that relevant switch was pressed, 
; go to "EDIT" mode.


; Otherwise, if the "EDIT" mode switch was not pressed,
; determine if index used to load frames has the same
; address as the index used to store frames, i.e., if the end
; of the animation has been reached during playback.
; (Placing this check here will allow animations of all sizes,
; including zero, to playback properly.)
; To efficiently determine if these index values are equal,
; a combination of the "CP" and "CPC" instructions is recommended.


; If index values are equal, branch back to "PLAY" to
; restart the animation.


; Otherwise, load animation frame from table, 
; display this "frame" on the relevant LEDs,
; start relevant timer/counter,
; wait until this timer/counter overflows (to more or less
; achieve the "frame rate"), and then after the overflow,
; stop the timer/counter,
; clear the relevant OVFIF flag,
; and then jump back to "PLAY_LOOP".


; end of program (never reached)
DONE: 
	rjmp DONE
;*******END OF MAIN PROGRAM *************************

;*******SUBROUTINES**********************************

;****************************************************
; Name: IO_INIT 
; Purpose: To initialize the relevant input/output modules, as pertains to the
;		   application.
; Input(s): N/A
; Output: N/A
;****************************************************
IO_INIT:
; protect relevant registers

; initialize the relevant I/O
	;set port C as output
	ldi r16, allones
	sts PORTC_DIRSET,r16
	;set port A as input
	ldi r16, allones
	sts PORTA_DIRCLR,r16
	;set port F as input
	ldi r16, allones
	sts PORTF_DIRCLR,r16
; recover relevant registers
	
; return from subroutine
	ret
;****************************************************
; Name: TC_INIT 
; Purpose: To initialize the relevant timer/counter modules, as pertains to
;		   application.
; Input(s): N/A
; Output: N/A
;****************************************************
TC_INIT:
; protect relevant registers

; initialize the relevant TC modules
	ldi r16, allzeroes
	sts TCC0_CNT, r16
	sts TCC0_CNT+1,r16
	sts TCC0_PER, r16
	sts TCC0_PER+1, r16
; recover relevant registers
	
; return from subroutine
	ret

;*******END OF SUBROUTINES***************************