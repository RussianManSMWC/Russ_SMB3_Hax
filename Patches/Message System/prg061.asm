BaseMessageLocationH = $2B00
BaseMessageLocationV = $2700

;FREERAM
MessageBoxTask = $069F			;message box code pointer
CurrentMessage = $06A0			;current message index

DoMessageBoxShiz:
;LDA MessageBoxTask
DEY								;start from $01
TYA
JSR DynJump

.dw UploadMessage				;
.dw Wait						;wait for A button
.dw RestorationProject			;restore status bar

;LDX #$00        ; X = 0
;LDY Graphics_BufCnt ; Y = Graphics_BufCnt
;BEQ @Delay     ; If graphics buffer is empty, jump to PRG026_B466

    ; Graphics buffer has content... skips delay functionality:
;STX StatusBar_UpdFl ; StatusBar_UpdFl = 0
;BEQ @Buffer     ; Jump to PRG026_B47A

;@Delay
;INC StatusBar_UpdFl ; StatusBar_UpdFl++
;LDA StatusBar_UpdFl ; A = StatusBar_UpdFl
;AND #$01        ; going for a toggle
;BNE @Buffer     ; If set, jump to PRG026_B47A

;    LDA #$00
;    STA StatusBar_UpdFl ; StatusBar_UpdFl = 0
	
;    LDA #$06        ;
;    STA Graphics_Queue ; Set Graphics_Queue = 6 (6?? Does it matter?)
	

;RTS

UploadMessage:
;@Buffer
LDA #<BorderOnly_DoStatusBarV			;load table location for vertical level
LDX #>BorderOnly_DoStatusBarV			;

LDY Level_7Vertical						;check vertical level
BNE @Yes								;

LDA #<BorderOnly_DoStatusBar			;
LDX #>BorderOnly_DoStatusBar			;

@Yes
STA $00									;
STX $01									;

LDY #$00								;

@Loop
LDA ($00),y								;
STA Graphics_Buffer,y					;
INY										;
CPY #36									;upload 36 bytes of status bar tilemap suitable for messages
BNE @Loop								;

LDA CurrentMessage						;and a message next
ASL										;
TAX										;
LDA MessagePointer,x					;
STA $00									;

LDA MessagePointer+1,x					;
STA $01									;

TYA										;
TAX										;
LDY #$00								;
@MoreLoopin
LDA ($00),y								;
STA Graphics_Buffer,x					;
BEQ @Exit								;
INY										;
INX										;
BNE @MoreLoopin

@Exit
INC MessageBoxTask
INC CurrentMessage						;next time select is pressed new message displayed (used with test codde from PRG030

LDA #$00								;
STA Graphics_BufCnt						;just in case

;TXA
;CLC
;ADC Graphics_BufCnt
;STA Graphics_BufCnt

Wait:
RTS

;LDA #$30
;JMP VideoUdpateAndReturn				;upload message

;set up border expansion and clear status bar to fit in our messages
macro StatusBarMessage _1
    DBYT _1 + $14
    .byte 10|VU_REPEAT, $A1		;continuation of upper row
	
;row 1
    DBYT _1 + $22
    .byte VU_REPEAT | 28, $FE	;empty space row 1
	
;row 2

    DBYT _1 + $42
    .byte VU_REPEAT | 28, $FE	;empty space row 1

;row 3 (extra)
	
	DBYT _1 + $61
    .byte $01, $A6
	
    DBYT _1 + $62
    .byte VU_REPEAT | 28, $FE	;empty space row 1
	
	DBYT _1 + $7E				;
    .byte $01, $A7
	
 ;bottom
 
     DBYT _1 + $81
    .byte $01, $A8     ; lower left corner

    DBYT _1 + $82
    .byte VU_REPEAT | 28, $A4  ; Bar across the bottom

    DBYT _1 + $9E				;upper right corner
    .byte $01, $A5
.endm

    ; Typical status bar (vertical level)
BorderOnly_DoStatusBarV:
    StatusBarMessage $2700

    ; Typical status bar (non-vertical level)
BorderOnly_DoStatusBar:
    StatusBarMessage $2B00
	
;message pointers
MessagePointer:
dw TEST1
dw TEST2

;Note: DOES NOT AUTOMATICALLY OFFSET VRAM POSITION! If you want it to display in vertical level set VRAM location accordingly ($2700 vertical and $2B00 horizontal)
;First Row starts at BaseMessageLocation+22, Second Row is BaseMessageLocation+42 and third row is BaseMessageLocation+42. It doesn't have to be exactly at the beginning of the row, can be anywhere in the message field)
;First byte is amount of characters and properties. Adding VU_REPEAT will repeat a character X times.
;Example:
;db $03|VU_REPEAT,$B0
;will repeat tile B0 3 times.
;Amount of characters on a single line should not exceed 28 or the rest will go out of bounds (or past $XXXX+1E). you don't like graphical glitches, do you?
;Space tile is $FE
;$00 will end writing, even if it's a part of the string, so... don't use $00 as a part of string, k?

TEST1:
DBYT BaseMessageLocationH+$22
;here's first row.
db 23			;15 (actually more, too lazy to count) characters
;   T   h   i   s       i   s       a       t   e   s   t       m   e   s   s   a   g   e  .
db $C3,$D7,$D8,$CC,$FE,$D8,$CC,$FE,$D0,$FE,$CD,$D4,$CC,$CD,$FE,$DC,$D4,$CC,$CC,$D0,$D6,$D4,$E9
DBYT BaseMessageLocationH+$42
db 12
;   H   e   l   l   o       w   o   r   l   d   !
db $B7,$D4,$DB,$DB,$DE,$FE,$81,$DE,$CB,$DB,$D3,$EA
db $00

;:AAAA:
TEST2:
DBYT BaseMessageLocationH+$22
db 28|VU_REPEAT
db $B0
DBYT BaseMessageLocationH+$42
db 28|VU_REPEAT
db $B0
DBYT BaseMessageLocationH+$62
db 28|VU_REPEAT
db $B0
db $00

;Code and data for status bar restoration
macro StatusBarRestore _1
    DBYT _1 + $14
    db 8
	db $A2,$A0,$A1,$A1,$A3,$A1,$A1,$A3	;continuation of upper row

    DBYT _1 + $22
    db 28
	db $70, $71, $72, $73, $FE, $FE, $EF, $EF, $EF, $EF, $EF, $EF, $3C    ; |WORLD  >>>>>>[P] $  | |  | |  | |  | |
    db $3D, $FE, $EC, $F0, $F0, $A7, $A6, $FE, $FE, $AA, $FE, $FE, $AA,$FE,$FE
	
	DBYT _1 + $42
    ; Discrepency --------v  (Pattern is ... $FE, $FE ... in PRG030 status bar)  Unimportant; inserts <M> which is replaced anyway
    db 28
	db $FE, $FE, $FB, $FE, $F3, $FE, $F0, $F0, $F0, $F0, $F0, $F0, $F0    ; [M/L]x  000000 c000| etc.
    db $FE, $ED, $F4, $F0, $F0, $A7, $A6, $FE, $FE, $AA, $FE, $FE, $AA,$FE,$FE

	DBYT _1 + $61
	db 1
	db $A8
	
	DBYT _1 + $62
	db 18|VU_REPEAT
	db $A4
	
    DBYT _1 + $74
    db 11
	db $A5,$A8,$A4,$A4,$A9,$A4,$A4,$A9,$A4,$A4,$A5
	
	DBYT _1 + $81
	db 30|VU_REPEAT
	db $FC
	
	db $00
	;99 bytes total/107
endm

RestoreVerticalBorder:
StatusBarRestore $2700

RestoreBorder:
StatusBarRestore $2B00

;restore old status bar layout.
RestorationProject:
LDA #<RestoreVerticalBorder
LDX #>RestoreVerticalBorder

LDY Level_7Vertical
BNE @Yes

LDA #<RestoreBorder
LDX #>RestoreBorder

@Yes
STA $00
STX $01

LDY #$00

@Loop
LDA ($00),y
STA Graphics_Buffer,y
BEQ @Exit
INY
BNE @Loop

@Exit
STA MessageBoxTask					;return to normal gameplay

LDA Player_Current					;restore mario/luigi icon
ASL A           					;
TAX         						;
LDA MarioLuigiSymbols,x
STA Graphics_Buffer+$2D
LDA MarioLuigiSymbols+1,x
STA Graphics_Buffer+$2E

;restore world number

LDX World_Num
INX         						; X = World_Num+1
TXA         						; A = X
ORA #$f0        					; Mark it up as a tile
STA Graphics_Buffer+$12

;Restore cards

LDA Player_Current
BEQ @PlayerMario  					; If player = 0 (Mario), jump to definitely not PRG031_FCC6

LDA #Inventory_Cards2 - Inventory_Cards

@PlayerMario
STA $01

LDY #$00

@LoopShiz
STY $00

LDY $01
LDX Inventory_Cards,Y

LDY $00
LDA CardUL,x							;this time tables' are in bank 31/63, no copy-paste now
STA $0323,y
;STA Graphics_Buffer+??,y

LDA CardUR,x
STA $0323+1,y
;STA Graphics_Buffer+??,y

LDA CardLL,x
STA $0342,y
;STA Graphics_Buffer+??,y

LDA CardLR,x
STA $0342+1,y
;STA Graphics_Buffer+??,y

INC $01

INY
INY
INY
CPY #$09
BCC @LoopShiz
RTS

MarioLuigiSymbols:
db $74, $75
db $76, $77
