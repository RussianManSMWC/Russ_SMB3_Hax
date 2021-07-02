;note - it uses routines and stuff from bank 4

ObjectGroup04_InitJumpTable:
	.word ObjInit_GroundTroop
	
ObjectGroup04_NormalJumpTable:
	.word Crazy_Spiny
	
ObjectGroup04_CollideJumpTable:
	.word $0000
	
ObjectGroup04_Attributes:
    .byte OA1_PAL3 | OA1_HEIGHT32 | OA1_WIDTH16
	
ObjectGroup04_Attributes2:
	.byte OA2_GNDPLAYERMOD | OA2_TDOGRP1
	
ObjectGroup04_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_DIESHELLED
	
ObjectGroup04_PatTableSel:
	.byte OPTS_SETPT5 | $0B
	
ObjectGroup04_KillAction:
    .byte KILLACT_JUSTDRAWMIRROR
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01 | OAT_BOUNCEOFFOTHERS
	
	;same as orig spiny
	
ObjPCrazySpiny:
.byte $81, $83, $85, $87, $89, $89, $89, $89, $89, $89, $89, $89, $8B, $8D

Crazy_Spiny:
LDA Objects_Var4,x
JSR DynJump

dw Spiny_NormalInQuotes
dw WaitALittle
dw ThrowItself

Spiny_NormalInQuotes:
LDA Level_ObjectID,x
PHA
LDA #$71
STA Level_ObjectID,x
JSR ObjNorm_GroundTroop						;run EVERYTHING that a normal spiny can do
PLA
STA Level_ObjectID,x

LDA Player_HaltGame
BNE @Re

;don't spin mid-air
LDA Objects_DetStat,X
AND #$04
BEQ @Re

JSR SubHorzPos

LDA Temp_Var16
CLC
ADC #$24
CMP #$50
BGE CrazySpiny_Return

TYA
STA Objects_Var5,x

INC Objects_Var4,x

;short timer

LDA #$30
STA Objects_Timer,x

LDA #$05								;hopefully spinning frame
STA Objects_Frame,x

@Re

CrazySpiny_Return:
RTS

;stay in place
;-still can be hit with tail and nlocks
;-when time is up turn into kicked shell
;-still turn other sprites away
WaitALittle:
JSR Object_DeleteOffScreen

LDA Player_HaltGame
BNE @Re

LDA Counter_1
AND #$07
BEQ @Re

LDA Objects_Frame,x
CMP #$06
BNE @OtherWay

DEC Objects_Frame,x
BNE @Normal

@OtherWay
INC Objects_Frame,x

@Normal
JSR Player_HitEnemy

JSR GroundTroop_BumpOffOthers
JSR Object_HandleBumpUnderneath

;DK how to handle block bump (from underneath or w/e), we'll see if it works..

LDA Objects_Timer,x
BNE @Re

INC Objects_Var4,x

@Re
LDA Objects_Frame,x
CMP #$06
BNE @DoubleRe

JMP Object_ShakeAndDraw
;LDY Object_SprRAM,X
;LDA Sprite_RAM+6,y					;
;EOR #$40
;STA Sprite_RAM+6,y

@DoubleRe
JMP Object_ShakeAndDrawMirrored

;animate

ThrowItself:
LDY Objects_Var5,x
LDA ObjectKickXVelMoving_Inverted,y
STA Objects_XVel,x

LDA #OBJSTATE_KICKED
STA Objects_State,x

LDA #$00
STA Objects_Var5,x					;please tell me neither kicked nor carried states use these two
STA Objects_Var4,x					;
RTS

ObjectKickXVelMoving_Inverted:
.byte $30, -$30