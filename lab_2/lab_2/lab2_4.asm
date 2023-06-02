;******************************************************************************
;  File name: lab2_4.asm
;  Author: Christopher Crary
;  Last Modified By: Steven Miller
;  Last Modified On: 1 june 2023
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
.EQU debouncereciprocal =1/.01
.EQU animationreciprocal = 1/.2
.EQU offset = 0
.EQU prescalar = 1024
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
	sbrs r16, s2bit
	rjmp play

; Otherwise, if the "PLAY" mode switch was not pressed,
; update display LEDs with the voltage values from relevant DIP switches
; and check if it is intended that a frame be stored in the animation
; (determine if this relevant switch has been pressed).
	lds r16, PORTA_IN
	sts PORTC_OUT, r16

; If the "STORE_FRAME" switch was not pressed,
; branch back to "EDIT".
	lds r17, PORTF_IN
	sbrc r17, s1bit
	rjmp edit

; Otherwise, if it was determined that relevant switch was pressed,
; perform debouncing process, e.g., start relevant timer/counter
; and wait for it to overflow. (Write to CTRLA and loop until
; the OVFIF flag within INTFLAGS is set.)
	
	;load period register
	ldi r16,low(((sysclk/prescalar)/debouncereciprocal)+offset)
	sts TCC0_PER, r16
	ldi r16,high(((sysclk/prescalar)/debouncereciprocal)+offset)
	sts TCC0_PER+1,r16
	ldi r16,TC_CLKSEL_DIV1024_gc
	sts TCC0_CTRLA,r16

	;debouncing
	debounceloop:
		lds r17,TCC0_INTFLAGS
		;check ov flag
		;branch if we have overflow
		sbrs  r17,TC0_OVFIF_bp
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
	;clear period register
	ldi r17, 0b00000000
	sts TCC0_PER,r17
	sts TCC0_PER+1,r17

; Wait for the "STORE FRAME" switch to be released
; before jumping to "EDIT".
STORE_FRAME_SWITCH_RELEASE_WAIT_LOOP:
	;read switch again
	lds r17, PORTF_IN
	sbrs r17, s1bit
	rjmp store_frame_switch_release_wait_loop
	storeframe:
		;store port A registers in X
		lds r16, PORTA_IN
		st x+, r16
		rjmp edit
	
	
	
; "PLAY" mode
PLAY:

; Reload the relevant index to the first memory location
; within the animation table to play animation from first frame.
	ldi YL,low(animation_start_addr)
	ldi YH,high(animation_start_addr)
	ld r20, y
	sts PORTC_OUT,r20

PLAY_LOOP:

; Check if it is intended that "EDIT" mode be started
; i.e., check if the relevant switch has been pressed.`
	lds r17, PORTF_IN
; If it is determined that relevant switch was pressed, 
; go to "EDIT" mode.
	sbrs r17, s1bit
	rjmp edit
; Otherwise, if the "EDIT" mode switch was not pressed,
; determine if index used to load frames has the same
; address as the index used to store frames, i.e., if the end
; of the animation has been reached during playback.
; (Placing this check here will allow animations of all sizes,
; including zero, to playback properly.)
; To efficiently determine if these index values are equal,
; a combination of the "CP" and "CPC" instructions is recommended.
	ld r20, y
	comparexylower:
		;compare lower bytes of x and y
		mov r16,xl
		mov r17, yl
		cp r16,r17
		breq comparexyhigher
		rjmp fivecyclecounter
		comparexyhigher:
			;compare higher bytes of x and y
			mov r16,xh
			mov r17, yh
			cp r16,r17
			breq play
			rjmp fivecyclecounter


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

fivecyclecounter:
	;load period register
	ldi r16,low(((sysclk/prescalar)/animationreciprocal)+offset)
	sts TCC0_PER, r16
	ldi r16,high(((sysclk/prescalar)/animationreciprocal)+offset)
	sts TCC0_PER+1,r16
	;initialize CLKSEL
	ldi r16,TC_CLKSEL_DIV1024_gc
	sts TCC0_CTRLA,r16
	ldi r16,0
	;initialize count
	sts TCC0_CNT, r16
	sts TCC0_CNT+1,r16
	loadanimationframe:
		;load animation frames
		sts PORTC_OUT,r20
		lds r17,TCC0_INTFLAGS
		;check ov flag
		;branch if we have overflow
		sbrs  r17,TC0_OVFIF_bp
		rjmp loadanimationframe
		;clear OVF
		ldi r17, 0b00000001
		sts TCC0_INTFLAGS,r17
		adiw y,1
		rjmp play_loop
	
		
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
	push r16
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
	pop r16
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
	push r16
; initialize the relevant TC modules
	ldi r16, allzeroes
	sts TCC0_CNT, r16
	sts TCC0_CNT+1,r16
	sts TCC0_PER, r16
	sts TCC0_PER+1, r16
	;initialize CTRLB
	ldi r16, allzeroes
	sts TCC0_CTRLB,r16
	;clear OVF
	ldi r17, 0b00000001
	sts TCC0_INTFLAGS,r17
; recover relevant registers
	pop r16
; return from subroutine
	ret

;*******END OF SUBROUTINES***************************