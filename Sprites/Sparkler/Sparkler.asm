ObjectGroup00_InitJumpTable:
	.word Init_FacePlayer
	
ObjectGroup00_NormalJumpTable:
	.word Sparkler
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL3 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1 | OA2_STOMPDONTCARE
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15

ObjectGroup00_KillAction:
    .byte KILLACT_JUSTDRAW16X16
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX00 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL 
	
ObjPSparkler:
db $B1,$B3
db $B5,$B7

Sparkly_XSpeed = $20

Sparkler:
JSR SubOffScreen
LDA Player_HaltGame					;freeze flag = return
BNE @Re							;

LDA #Sparkly_XSpeed     						; A = $08

LDY Objects_FlipBits,X
BNE @StoreSpd  						; If flipped, jump to PRG004_B275

LDA #-Sparkly_XSpeed    						; A = -$08

@StoreSpd
STA Sprite_X_Speed,x

;maybe I can just use Object_Move but i'm lazy to test
JSR Object_ApplyYVel				;
JSR Object_ApplyXVel				;
JSR Object_WorldDetect4				;

LDA Objects_DetStat,X				;
AND #$03							;
BEQ @NoWallz  						; change dir on wall hit

JSR Object_FlipFace

@NoWallz
LDA Objects_DetStat,X				;
AND #$04							;
BNE @HitGround						;stay grounded

LDA Sprite_Y_Speed,x				;
CLC									;
ADC #OBJECT_FALLRATE				;gravity
STA Sprite_Y_Speed,x				;

@Stop
LDA Objects_Var4,X
BNE @NoFloorAllign  				; if was grounded, don't allign

JSR Object_AboutFace				; Turn around

; Applies X velocity twice to undo his previous step that would have put him over
JSR Object_ApplyXVel
JSR Object_ApplyXVel

INC Objects_Var4,X					;increase flag
BNE @Allign							;

@HitGround
LDA #$00							;
STA Objects_Var4,X					;

LDA #$00
STA Sprite_Y_Speed,x				;reset speed when grounded

@Allign
JSR Object_HitGround				;

@NoFloorAllign 

;JSR Object_HitTest					;
;BCC @NoHit							;

LDA Counter_1
AND #$07
BNE @NoAnim

LDA Objects_Frame,x
EOR #$01
STA Objects_Frame,x

@NoAnim
;hurt the player when colliding
JSR Player_HitEnemy

@Re
JMP Object_ShakeAndDraw