; this macro prints a char in AL and advances
; the current cursor position:
PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM                  


     
;include 'emu8086.inc'

        org  100h           ; set location counter to 100h        
        
        
        

jmp start


; define variables:

msg0 db "Vom desena graficul unei functii de grdul 2 de forma x^2+ax+c",0Dh,0Ah
     db "Va rog inserati valorile parametrilor",0Dh,0Ah,'$'
msg01 db 0Dh,0Ah, 0Dh,0Ah, 'a=: $'

msg02 db "b=  : $"

msg03 db "c=  : $"

; first and second number:
num1 dw ?
num2 dw ?
num3 dw ?

start:
mov dx, offset msg0
mov ah, 9
int 21h


lea dx, msg01
mov ah, 09h    ; output string at ds:dx
int 21h  


; get the multi-digit signed number
; from the keyboard, and store
; the result in cx register:

call scan_num

; store first number:
mov num1, cx 



; new line:
putc 0Dh
putc 0Ah







; output of a string at ds:dx
lea dx, msg02
mov ah, 09h
int 21h  


; get the multi-digit signed number
; from the keyboard, and store
; the result in cx register:

call scan_num


; store second number:
mov num2, cx 



         
 ; new line:
putc 0Dh
putc 0Ah


    ; output of a string at ds:dx
lea dx, msg03
mov ah, 09h
int 21h  


; get the multi-digit signed number
; from the keyboard, and store
; the result in cx register:

call scan_num


; store second number:
mov num3, cx 

    

        jmp  CodeStart

DataStart:

numX    dw   -60            ; min x value
numXmax dw   +60            ; max x value
xIncr   dw   4             ; display every 4th pixel
numY    dw   ?              ; numY = f(numX)
color   db   ?              ; color to use for display


; Plot a quadratic equation along with axes
CodeStart:

        mov  al, 13h        ; set video mode 320x200, 256 colors
        mov  ah, 0
        int  10h

        call Xaxis          ; draw x-axis
        call Yaxis          ; draw y-axis
        
; for (ax = numX; ax <= numXmax; ax += 5)
        mov  color, 52      ; set color for the curve
Lup:      
        mov  ax, numX       ; get x
        call Fcn            ; calculate f(x)
        mov  NumY, ax       ; save y = f(x)
        
        mov  ax, numX
        mov  bx, numY
        call Plot           ; plot (x,y)

        mov  ax, numX
        add  ax, xIncr      ; run x in steps of xIncr
        mov  numX, ax
        cmp  ax, numXmax
        jle  Lup            ; loop until done

        call Legend         ; draw legend
       
        ret                 ; return to caller


;========================================================== 
; Plots a pixel at (x,y); assumes that (x,y) are in (AX,BX)
; Uses AX (AH and AL), CX, DX
Plot    PROC
        mov  cx, ax
        add  cx, 160        ; translate for x origin
        mov  dx, bx
        neg  dx             ; invert for normal positive y "up"
        add  dx, 100        ; translate for y origin
        mov  al, color      ; set color
        mov  ah, 0ch        ; subfunction for drawing a pixel
        int  10h

        ret                 ; return to caller
Plot ENDP


;==========================================================
; Display x-axis
Xaxis   PROC
        mov  ax, xMax       ; set min/max for axis 
        neg  ax
        mov  x, ax
        mov  color, 40      ; set axis color

Xlup:   
        mov  ax, x
        mov  bx, 0
        call Plot
        add  x, 8           ; display every 8th pixel
        mov  ax, x
        cmp  ax, xMax
        jle  Xlup 

        ret                 ; return to caller
Xaxis   ENDP

x       dw   ?
xMax    dw   80             ; min/max x-axis coordinate


;==========================================================
; Display y-axis
Yaxis   PROC
        mov  ax, yMax       ; set min/max for axis
        neg  ax
        mov  y, ax
        mov  color, 40      ; set axis color
YLup:
        mov  ax, 0
        mov  bx, y
        call Plot
        add  y, 8           ; display every 8th pixel
        mov  ax, y
        cmp  ax, yMax
        jle  Ylup
 
        ret                 ; return to caller
Yaxis   ENDP

y       dw   ?
yMax    dw   72             ; min/max y-axis coordinate


;==========================================================
; y = f(x) = x^2 / 32 - 50  x is in AX; result in AX 

Fcn     PROC
        mov  dx, 0          ; prepare for multiplication
        mov  bx, ax
        imul bx             ; AX now contains x^2
        sar  ax, 5          ; AX now contains x^2/32
        imul num1
        mov  cx,ax
        mov  ax, bx
        imul num2
        add ax ,cx
        add  ax, num3         ; AX now contains x^2/32 - 50

        ret                 ; return to caller
Fcn     ENDP


;==========================================================
; Display the legend
; See www.emu8086.com/assembly_language_tutorial_assembler_reference/
;     for details on all the 8086 interrupts and color attributes
Legend  PROC
    	mov  al, 1
    	mov  bh, 0
    	mov  bl, 0011_1011b ; color attributes
    	mov  cx, msg1end - offset msg1 ; calculate message size 
    	mov  dl, 8          ; column
    	mov  dh, 23         ; row
    	push cs
    	pop  es
    	mov  bp, offset msg1
    	mov  ah, 13h        ; subfunction for display a string
    	int  10h
    	jmp  msg1end
msg1    db   " y = f(x) = (x^2)*(1/32)*("
msg1end:  
        mov ax, num1
        call print_num
        
        putc ')'
        putc '+'
        putc '('
        
        mov ax, num2 
        call print_num
        putc ')'
        putc '*'
        putc 'x'
        putc  '+'   
        putc  '('  
        mov ax,num3
        call print_num
        putc ')'
        ret
Legend  ENDP 




SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP

  


; this procedure prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

        PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP



; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0   ; set flag.

        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
        PUTC    AL


        MOV     AX, DX  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
        PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP



ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.







GET_STRING      PROC    NEAR
PUSH    AX
PUSH    CX
PUSH    DI
PUSH    DX

MOV     CX, 0                   ; char counter.

CMP     DX, 1                   ; buffer too small?
JBE     empty_buffer            ;

DEC     DX                      ; reserve space for last zero.


;============================
; Eternal loop to get
; and processes key presses:

wait_for_key:

MOV     AH, 0                   ; get pressed key.
INT     16h

CMP     AL, 0Dh                  ; 'RETURN' pressed?
JZ      exit_GET_STRING


CMP     AL, 8                   ; 'BACKSPACE' pressed?
JNE     add_to_buffer
JCXZ    wait_for_key            ; nothing to remove!
DEC     CX
DEC     DI
PUTC    8                       ; backspace.
PUTC    ' '                     ; clear position.
PUTC    8                       ; backspace again.
JMP     wait_for_key

add_to_buffer:

        CMP     CX, DX          ; buffer is full?
        JAE     wait_for_key    ; if so wait for 'BACKSPACE' or 'RETURN'...

        MOV     [DI], AL
        INC     DI
        INC     CX
        
        ; print the key:
        MOV     AH, 0Eh
        INT     10h

JMP     wait_for_key
;============================

exit_GET_STRING:

; terminate by null:
MOV     [DI], 0

empty_buffer:

POP     DX
POP     DI
POP     CX
POP     AX
RET
GET_STRING      ENDP



