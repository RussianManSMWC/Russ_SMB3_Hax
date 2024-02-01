ObjectGroup00_InitJumpTable:
	.word SwooperInit
	
ObjectGroup00_NormalJumpTable:
	.word Swooper
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL2 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1 | OA2_NOSHELLORSQUASH
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_JUSTDRAW
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01
	
ObjPSwooper:
db $8D,$8F
db $81,$83
db $85,$87
db $89,$8B

Swooper_Max_X_Speed:		db $10,$F0
Swooper_Max_Y_Speed:		db $04,$FC
Swooper_X_Acceleration:		db $01,$FF
Swooper_Y_Acceleration:		db $01,$FF

Swooper_InitYSpeed = $20

SwooperInit:
JMP Init_FacePlayer

Swooper:
JSR Object_DeleteOffScreen
JSR Object_ShakeAndDraw

LDA Player_HaltGame
BNE @Re

JSR Player_HitEnemy					;interact with player
JSR Object_ApplyYVel
JSR Object_ApplyXVel

LDY Sprite_Misc_Table2,x			;"pointer"
DEY
BEQ @MovingDown						;1 - moves down
DEY
BEQ @MovingHorz						;2 - moves horizontally (with slight sine movement)

;0 - wait for the player
JSR Object_AnySprOffscreen
BNE @Re  ; If any sprite is off-screen, jump to PRG004_A6A6 (RTS)

JSR Level_ObjCalcXDiffs

LDA Temp_Var16				;\ if Mario more than 0x50 pixels (5 16x16 tiles) from sprite,
CLC				; |
ADC #$50			; |
CMP #$A0			; |
BCS @Re		;/ return

INC Sprite_Misc_Table2,x

LDA #Swooper_InitYSpeed
STA Sprite_Y_Speed,x

LDA Sound_QLevel2
ORA #SND_BOOMERANG				;maybe???????
STA Sound_QLevel2

@Re
RTS

@MovingHorz
LDA Counter_1
LSR
BCS @MaybeMove

LDA Sprite_Misc_Table5,x
AND #$01
TAY
LDA Sprite_Y_Speed,x
CLC
ADC Swooper_Y_Acceleration,y
STA Sprite_Y_Speed,x
CMP Swooper_Max_Y_Speed,y
BNE @MaybeMove

INC Sprite_Misc_Table5,x

@MaybeMove
LDA Counter_1
AND #$03
BNE @Animate
BEQ @Movement

@MovingDown
LDA Counter_1
AND #$03
;BNE @NoYSpeedShenanigan
BNE @Animate

DEC Sprite_Y_Speed,x
BNE @NoYSpeedShenanigan

INC Sprite_Misc_Table2,x

@NoYSpeedShenanigan
@Movement
LDY #$00
LDA Objects_FlipBits,x
BNE @NoFlip
INY

@NoFlip
LDA Sprite_X_Speed,x
CMP Swooper_Max_X_Speed,y
BEQ @Animate
CLC
ADC Swooper_X_Acceleration,y
STA Sprite_X_Speed,x

@Animate
LDA Counter_1
AND #$04
LSR
LSR
CLC
ADC #$01
STA Objects_Frame,X
RTS