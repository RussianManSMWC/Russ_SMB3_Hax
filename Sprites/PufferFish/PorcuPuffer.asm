;A porcu puffer from Super Mario World

ObjectGroup00_InitJumpTable:
	.word ObjInit_DoNothing				;vertical init

ObjectGroup00_NormalJumpTable:
	.word PorcuMain
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
	.byte OA1_PAL3 | OA1_HEIGHT32 | OA1_WIDTH32	;vertical

ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP5 | OA2_GNDPLAYERMOD

ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE

ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15

ObjectGroup00_KillAction:
    	.byte KILLACT_STANDARD

Object_AttrFlags:
	.byte OAT_BOUNDBOX06

;ObjPPorcu:
;doesnt matter

PorcuTiles:
db $AF,$AD,$AB,$A9,$8F,$8D,$8B,$89
db $87,$85,$AB,$A9,$8F,$8D,$8B,$89

PorcuMaxXSpd:
db $10,-$10

PorcuMain:
LDA #<PorcuTiles
LDY #>PorcuTiles
JSR General32x32GFX

JSR SubOffScreen

LDA Player_HaltGame
BNE @Re

JSR Player_HitEnemy

;face the player always
JSR Level_ObjCalcXDiffs
LDA CommonSprFlip,y
STA Objects_FlipBits,x

LDA Counter_1
AND #$04
LSR
LSR
STA Objects_Frame,x

LDA Counter_1
AND #$03
BNE @SkipXAccel

LDA Objects_XVel,x
CMP PorcuMaxXSpd,y
BEQ @SkipXAccel
CLC
ADC CommonAcceleration,y
STA Objects_XVel,x

@SkipXAccel
LDA Objects_XVel,x
PHA
LDA Level_ScrollDiffH				;i think???
ASL
ASL
ASL
ASL
CLC
ADC Objects_XVel,x
STA Objects_XVel,x

JSR Object_ApplyXVel
PLA
STA Objects_XVel,x

LDA #$30
STA ObjSplash_DisTimer,x			;NEVER show splashes!

JSR Object_WorldDetectN1

LDY #$04
LDA Objects_InWater,X
BEQ @NotInWater
LDY #$FC

@NotInWater
STY Objects_YVel,x

JSR Object_ApplyYVel_NoLimit

@Re
RTS