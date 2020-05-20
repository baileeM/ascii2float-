;  Bailee Miller
;  CS 218, Assignment #6
;  Provided Template

;  Write a simple assembly language program to convert an
;  unsigned floating point ASCII string into an floating point value


; **********************************************************************************
;  Macro, "ascii2float", to convert an unsigned floating point ASCII
;  string into an floating point value.  The macro reads the ASCII
;  string (byte-size, with leading blanks, sign, value, possible exponent,
;  NULL terminated) and converts to a doubleword sized float
;  (IEEE 32-bit floating point format).
;  Note, assumes valid/correct data.  As such, no error checking is performed.

;  Example:  given the ASCII string: "        +23.25", NULL
;    (8 spaces, '22', followed by '.', followed by '25',
;    followed by NULL, for a total of STR_LENGTH bytes) which is converted
;    to base-10 floating point value is 23.25.

; -----
;  Arguments
;	%1 -> string address (reg)
;	%2 -> integer number (destination address)


%macro	ascii2float	2

	;clear out every register to be used within the macro 
	mov rdx, 0
	cvtsi2ss xmm0, rdx
	cvtsi2ss xmm1, rdx
	cvtsi2ss xmm2, rdx
	cvtsi2ss xmm3, rdx
	mov rax, 0
	mov rsi, 0
	mov r9, 0
	mov r9, 1			;sign value	(default value in case there is no sign characer in string)
	mov r10, 0			;fraction digit count
	mov r11, 0			;whole number value
	mov r12, 0			
	mov r12, 1			;10^fraction digit count (default value of 1 to avoid dividing by zero) 
	mov r13, 0			;fraction value
	mov r14, 0			;temporary register

	%%WhiteSpace:
			cmp byte[%1 + rsi], ' '
			jne %%Negative
			inc rsi
			jmp %%WhiteSpace

	%%Mainloop:
		%%Negative:
			cmp byte[%1 + rsi], '-'
			jne %%Positive
			mov r9, -1
			inc rsi
			mov r11, 0
			jmp %%Digit 

		%%Positive: 
			cmp byte[%1 + rsi], '+'
			jne %%Def
			mov r9, 1
			inc rsi 
			mov r11, 0
			jmp %%Digit 

		%%Def:
			mov r9, 1
			jmp %%Digit 

		%%Digit: 
			mov rax, 0
			mov r10, 0
			cmp byte[%1 + rsi], '.'
			je %%Fraction
			cmp byte[%1 + rsi], NULL
			je %%End 

			mov al, byte[%1 + rsi]
			sub al, '0'
			mov r10, rax
			mov rax, 0
			mov rax, r11
			mov rbx, 0
			mov ebx, 10
			mul ebx 
			mov rbx, 0
			mov r11, rax
			mov rax, 0
			add r10, r11
			mov r11, r10

			inc rsi 
			jmp %%Digit

		%%Fraction:
			inc rsi
			mov rax, 0
			mov r12, 0 
			cmp byte[%1 + rsi], NULL
			je %%FractionDigit 

			add r10, 1
			mov al, byte[%1 + rsi]
			sub al, '0'
			mov r12, rax
			mov rax, 0
			mov rax, r13
			mov rbx, 0
			mov ebx, 10
			mul ebx
			mov ebx, 0
			mov r13, rax
			mov rax, 0
			add r12, r13
			mov r13, r12	
			jmp %%Fraction 

			%%FractionDigit:
				mov rsi, 0
				mov rax, 0
				mov r12, 10
				%%Calculate:
					inc rsi
					cmp rsi, r10
					jge %%End

					mov rax, r12
					mov rbx, 0
					mov ebx, 10
					mul ebx
					mov ebx, 0
					mov r12, rax	
					jmp %%Calculate 			

		%%End:
			cvtsi2ss xmm0, r11d			;whole number 
			cvtsi2ss xmm1, r13d			;fraction
			cvtsi2ss xmm2, r12d			;10^fraction digit count 

			divss xmm1, xmm2			;fraction / 10^fraction digit count
			addss xmm0,xmm1				;add number

			cvtsi2ss xmm3, r9d 			;sign number
			mulss xmm0, xmm3			;multiply by sign number

			movss dword[%2], xmm0	;store number in variable

	;once again clear out all registers to avoid carrying
	;values in registers for next macro loop
	mov rdx, 0
	mov rax, 0
	mov rsi, 0
	mov r9, 0
	mov r10, 0			
	mov r11, 0			
	mov r12, 0
	mov r13, 0			
	mov r14, 0			
	mov r15, 0
	cvtsi2ss xmm0, rdx
	cvtsi2ss xmm1, rdx
	cvtsi2ss xmm2, rdx
	cvtsi2ss xmm3, rdx

%endmacro ascii2float

; --------------------------------------------------------------
;  Simple macro to display a string to the console.
;	Call:	printString  <stringAddr>

;	Arguments:
;		%1 -> <stringAddr>, string address

;  Count characters (excluding NULL).
;  Display string starting at address <stringAddr>

%macro	printString	1
	push	rax					; save altered registers
	push	rdi					; not required, but
	push	rsi					; does not hurt.  :-)
	push	rdx
	push	rcx

	mov	rdx, 0
	mov	rdi, %1
%%countLoop:
	cmp	byte [rdi], NULL
	je	%%countLoopDone
	inc	rdi
	inc	rdx
	jmp	%%countLoop
%%countLoopDone:

	mov	rax, SYS_write				; system call for write (SYS_write)
	mov	rdi, STDOUT				; standard output
	mov	rsi, %1					; address of the string
	syscall						; call the kernel

	pop	rcx					; restore registers to original values
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
%endmacro


; *****************************************************************
;  Data Declarations

section	.data

; -----
;  Define standard constants.

TRUE		equ	1
FALSE		equ	0

EXIT_SUCCESS	equ	0			; successful operation
NOSUCCESS	equ	1			; unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
SYS_close	equ	3			; system call code for file close
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

LF		equ	10
SPACE		equ	" "
NULL		equ	0
ESC		equ	27
ten			db	10
tenD 		dd	10
signValue	db 	1

; -----
;  Variables and constants.

STR_LENGTH	equ	15			; digits in string, including NULL

newLine		db	LF, NULL

; -----
;  Misc. string definitions.

hdr1		db	"--------------------------------------------"
		db	LF, "CS 218 - Assignment #6", LF
		db	"Real Number Conversions", LF 
		db	LF, LF, NULL

hdr2		db	LF, "----------------------"
		db	LF, "List Values:"
		db	LF, LF, NULL

firstNum	db	"Initial String:   ", NULL
fltFmt1		db	"Converted Number: %14.6f", LF, NULL
fltFmt2		db	"Number (3*n + 1): %14.6f", LF, NULL
fltSumFmt	db	LF, "List Sum: %f", LF, NULL

lstSum		db	LF, "List Sum:"
		db	LF, NULL

; -----
;  Misc. data definitions (if any).

weight		dd	10
fltOne		dd	1.0
fltThree	dd	3.0

; -----
;  Assignment #6 Provided Data:

fltStr0		db	"        +9.625", NULL
fltNum0		dd	0.0
fltAns		dd	0.0


qStrArr1	db	"        +12.25", NULL, "         -3.75", NULL
		db	"        14.625", NULL, "       -22.125", NULL
		db	"        +5.875", NULL, "            32", NULL
		db	"          -13.", NULL
len1		dd	7
sum1		dd	0.0


qStrArr2	db	"           1.5", NULL, "         +2.75", NULL
		db	"          -3.0", NULL, "         4.125", NULL
		db	"       +10.625", NULL, "       -11.875", NULL
		db	"        12.125", NULL, "        -13.25", NULL
		db	"         +14.0", NULL, "          -205", NULL
		db	"        +21.75", NULL, "         +22.5", NULL
		db	"         23.75", NULL, "        24.125", NULL
		db	"        30.875", NULL, "         +31.0", NULL
len2		dd	16
sum2		dd	0.0


qStrArr3	db	"       +3.2122", NULL, "       +2.2431", NULL
		db	"       -0133.4", NULL, "        2.2050", NULL
		db	"      -4130.11", NULL, "       +1442.1", NULL
		db	"      +22432.0", NULL, "        +1.101", NULL
		db	"        1120.1", NULL, "       -1000.0", NULL
		db	"            .4", NULL, "          22.0", NULL
		db	"          -431", NULL, "         +4003", NULL
		db	"       +1334.1", NULL, "     +1.432125", NULL
		db	"       +2323.6", NULL, "       -1.3340", NULL
		db	"        4124.4", NULL, "       +1111.1", NULL
		db	"       +12.425", NULL, "       11332.5", NULL
		db	"       -1241.0", NULL, "     +14234.75", NULL
		db	"       +2.1125", NULL, "       -4312.5", NULL
		db	"        -420.5", NULL, "       +2.3325", NULL
		db	"       +2.2115", NULL, "       +3132.5", NULL
		db	"        +132.0", NULL, "       21344.1", NULL
		db	"        -1.324", NULL, "        +3.343", NULL
		db	"       -2.4212", NULL, "       -142.31", NULL
		db	"         3.341", NULL, "       +1.3312", NULL
		db	"          -312", NULL, "           404", NULL
		db	"      -12344.0", NULL, "       2.23450", NULL
		db	"           3.0", NULL, "            -2", NULL
		db	"       -3141.2", NULL, "      +2.22125", NULL
		db	"       +1.1245", NULL, "       -1013.4", NULL
		db	"       +3.2175", NULL, "        -4.421", NULL
		db	"         2.344", NULL, "         244.0", NULL
		db	"       11212.5", NULL, "     0.1144275", NULL
		db	"      2.012125", NULL, "      +0.12275", NULL
		db	"        -313.5", NULL, "         +1023", NULL
		db	"    +0.1132175", NULL, "      -21000.0", NULL
len3		dd	60
sum3		dd	0.0


; **********************************************************************************
;  Uninitialized data
;	Note, these variables/arrays are declared and allocated, but no
;	initial values are provided.

section	.bss

num0String	resb	STR_LENGTH
tempString	resb	STR_LENGTH
tempNum		resd	1


; **********************************************************************************

extern printf

section	.text
global	main
main:
	push	rbp
	mov	rbp, rsp

; **********************************************************************************
;  Main program
;	initial conversion (no macro)
;	display headers
;	calls the macro on various data items
;	display results to screen (via provided macro's)

;  Note, since the print does NOT perform an error checking,
;  	if the conversions do not work correctly,
;	the print will not work!

; **********************************************************************************
;  Prints some cute headers...

	printString	hdr1
	printString	firstNum
	printString	fltStr0
	printString	newLine

; -----
;  STEP #1
;	Convert ASCII string into a float
;	DO NOT USE MACRO HERE!!

	;clear out all registers before use
	mov rax, 0			
	mov rsi, 0
	mov r9, 0
	mov r9, 1			;sign value (default value +1)
	mov r10, 0			;fraction digit count
	mov r11, 0			;whole number value
	mov r12, 0
	mov r12, 1			;10^fraction digit count (default value +1)
	mov r13, 0			;fraction value
	mov r14, 0			;temporary register

	WhiteSpace:
			cmp byte[fltStr0 + rsi], ' '		;iterates through all white space before first character
			jne Negative						
			inc rsi
			jmp WhiteSpace						;keep looping through white space

	Negative:
		cmp byte[fltStr0 + rsi], '-'			;compare first character to '-'
		jne Positive
		mov r9, -1								;store -1 as our sign value
		inc rsi
		mov r11, 0
		jmp Digit 

	Positive: 
		cmp byte[fltStr0 + rsi], '+'			;compare first character to '+'
		jne Def
		mov r9, 1								;store +1 as our sign value
		inc rsi 
		mov r11, 0
		jmp Digit 

	Def:
		mov r9, 1			;default case for if there is no sign character
		jmp Digit 

		Digit: 
			mov rax, 0					;assembles our whole number value and stoes in r11
			mov r10, 0
			cmp byte[fltStr0 + rsi], '.'
			je Fraction
			cmp byte[fltStr0 + rsi], NULL
			je End 

			mov al, byte[fltStr0 + rsi]
			sub al, '0'
			mov r10, rax
			mov rax, 0
			mov rax, r11
			mul dword[tenD]
			mov r11, rax
			mov rax, 0
			add r10, r11
			mov r11, r10

			inc rsi 
			jmp Digit

		Fraction:
			inc rsi						;assembles our fraction value and stores in r13
			mov rax, 0
			mov r12, 0 
			cmp byte[fltStr0 + rsi], NULL
			je FractionDigit 

			add r10, 1
			mov al, byte[fltStr0 + rsi]
			sub al, '0'
			mov r12, rax
			mov rax, 0
			mov rax, r13
			mul dword[tenD]
			mov r13, rax
			mov rax, 0
			add r12, r13
			mov r13, r12	
			jmp Fraction 

			FractionDigit:
				mov rsi, 0				;calculates number of digits in our fraction (stored in r12)
				mov rax, 0
				mov r12, 10
				Calculate:
					inc rsi
					cmp rsi, r10
					jge End

					mov rax, r12
					mul dword[tenD]
					mov r12, rax	
					jmp Calculate 			

	End:
		cvtsi2ss xmm0, r11d			;whole number 
		cvtsi2ss xmm1, r13d			;fraction
		cvtsi2ss xmm2, r12d			;10^fraction digit count 

		divss xmm1, xmm2			;fraction / 10^fraction digit count
		addss xmm0,xmm1				;add number

		cvtsi2ss xmm3, r9d 			;sign number
		mulss xmm0, xmm3			;multiply by sign number

		movss dword[fltNum0], xmm0	;store number in variable
; -----
;  Perform (3.0 * fltNum0 + 3.0) operation.

	movss	xmm0, dword [fltNum0]
	mulss	xmm0, dword [fltThree]			; * 3.0
	addss	xmm0, dword [fltOne]			; + 1.0
	movss	dword [fltAns], xmm0

; -----
;  Display results.

	cvtss2sd	xmm0, dword [fltNum0]
	mov	rdi, fltFmt1
	mov	rax, 1
	call	printf

	cvtss2sd	xmm0, dword [fltAns]
	mov	rdi, fltFmt2
	mov	rax, 1
	call	printf

; **********************************************************************************
;  Next, repeatedly call the macro on each value in an array.

; ==================================================
;  Data Set #1 (short list)

	printString	hdr2

	mov	ecx, [len1]			; length
	mov	rsi, 0				; starting index of list
	mov	rdi, qStrArr1			; address of string

cvtLoop1:
	push	rcx
	push	rdi

	ascii2float	rdi, tempNum

	cvtss2sd	xmm0, dword [tempNum]
	mov	rdi, fltFmt1
	mov	rax, 1
	call	printf

	movss	xmm0, dword [tempNum]
	movss	xmm1, dword [sum1]
	addss	xmm1, xmm0
	movss	dword [sum1], xmm1

	pop	rdi
	add	rdi, STR_LENGTH

	pop	rcx
	dec	rcx				; check length
	cmp	rcx, 0
	ja	cvtLoop1

	cvtss2sd	xmm0, dword [sum1]
	mov	rdi, fltSumFmt
	mov	rax, 1
	call	printf

	printString	newLine

; ==================================================
;  Data Set #2 (long list)

	printString	hdr2

	mov	ecx, [len2]			; length
	mov	rsi, 0				; starting index of list
	mov	rdi, qStrArr2			; address of string

cvtLoop2:
	push	rcx
	push	rdi

	ascii2float	rdi, tempNum

	cvtss2sd	xmm0, dword [tempNum]
	mov	rdi, fltFmt1
	mov	rax, 1
	call	printf

	movss	xmm0, dword [tempNum]
	movss	xmm1, dword [sum2]
	addss	xmm1, xmm0
	movss	dword [sum2], xmm1

	pop	rdi
	add	rdi, STR_LENGTH

	pop	rcx
	dec	rcx				; check length
	cmp	rcx, 0
	ja	cvtLoop2

	cvtss2sd	xmm0, dword [sum2]
	mov	rdi, fltSumFmt
	mov	rax, 1
	call	printf

	printString	newLine

; ==================================================
;  Data Set #3 (longest list)

	printString	hdr2

	mov	ecx, [len3]			; length
	mov	rsi, 0				; starting index of list
	mov	rdi, qStrArr3			; address of string

cvtLoop3:
	push	rcx
	push	rdi

	ascii2float	rdi, tempNum

	cvtss2sd	xmm0, dword [tempNum]
	mov	rdi, fltFmt1
	mov	rax, 1
	call	printf

	movss	xmm0, dword [tempNum]
	movss	xmm1, dword [sum3]
	addss	xmm1, xmm0
	movss	dword [sum3], xmm1

	pop	rdi
	add	rdi, STR_LENGTH

	pop	rcx
	dec	rcx				; check length
	cmp	rcx, 0
	ja	cvtLoop3

	cvtss2sd	xmm0, dword [sum3]
	mov	rdi, fltSumFmt
	mov	rax, 1
	call	printf

	printString	newLine

; **********************************************************************************
;  Done, terminate program.

last:
	mov	rax, SYS_exit		; The system call for exit (sys_exit)
	mov	rdi, EXIT_SUCCESS
	syscall

