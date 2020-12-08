ObjectGroup00_InitJumpTable:
	.word ReflectingFireballInit
	
ObjectGroup00_NormalJumpTable:
	.word ReflectingFireball
	
ObjectGroup00_CollideJumpTable:
	.word Player_GetHurt
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_KillAction:
    .byte KILLACT_JUSTDRAW16X16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01

ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5|15
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE 

ObjPReflectFireball:
db $BB,$BD

ReflectFire_InitialYSpd = $F0

ReflectFire_InitialXSpd:
db $10,-$10

ReflectingFireballInit:
JSR Init_FacePlayer

LDA ReflectFire_InitialXSpd,y
STA Sprite_X_Speed,x

LDA #ReflectFire_InitialYSpd
STA Sprite_Y_Speed,x
RTS

ReflectingFireball:
;LDY #$00
;LDA Objects_FlipBits,x
;AND #$80
;BEQ @YSpd
;INY

;@XSpd
;LDA ReflectFire_YSpd,y
;STA Sprite_Y_Speed,x

;LDY #$00
;LDA Objects_FlipBits,x
;AND #$40
;BEQ @XSpd
;INY

;@XSpd
;LDA ReflectFire_XSpd,y
;STA Sprite_X_Speed,x

LDA Player_HaltGame					;
BNE @NoFlipHorz						;
	
JSR Player_HitEnemy

JSR Object_ApplyXVel				;move about
JSR Object_ApplyYVel				;
JSR Object_WorldDetect4				;

;change color every other frame
LDA Counter_1
AND #$07
BNE @NoFrame

LDA Objects_SprAttr,x				;change from pal 1 to pal 3 and back
EOR #$02
STA Objects_SprAttr,x

@NoFrame
LDA Sprite_Blocked_Status,x			;reflect
AND #$0C
BEQ @NoFlipVert

LDA Objects_FlipBits,x				;vertically
EOR #$80
STA Objects_FlipBits,x

LDA Sprite_Y_Speed,x
JSR Negate
STA Sprite_Y_Speed,x

@NoFlipVert
LDA Sprite_Blocked_Status,x
AND #$03
BEQ @NoFlipHorz

JSR Object_AboutFace				;horizontally

@NoFlipHorz
JMP Object_ShakeAndDraw