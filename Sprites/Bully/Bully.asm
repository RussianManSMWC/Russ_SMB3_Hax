ObjectGroup00_InitJumpTable:
	.word Bully_Init				;or Init_Return, doesn't matter
	
ObjectGroup00_NormalJumpTable:
	.word Bully
	
ObjectGroup00_CollideJumpTable:
	.word Bully_Interaction
	
ObjectGroup00_Attributes:
	.byte OA1_PAL2 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1 | OA2_GNDPLAYERMOD
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE

Object_AttrFlags:
    .byte OAT_BOUNDBOX01 | OAT_FIREIMMUNITY | OAT_HITNOTKILL
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 14				;can fit tiles for bully
	
ObjectGroup00_PatternSets:
ObjPBully:
	.byte $B9, $BB, $BD, $BF
	
BumpSpd:
db $30,-$30						;player's bump speed
	
BullyBumpSpd:
.byte -$1A,$1A						;bully's bump speed

BullyXSpeed:
.byte $20,-$20						;bully's max spd.

Bully:
	JSR SubOffScreen				;offscreen situation
	
	LDA Player_HaltGame				;don't do whatever
    	BNE @Re						;
	
	JSR Object_Move					;interact with objects
	
	LDA Objects_DetStat,X				;
	AND #$04					;
	BEQ @NoFloorHit					;
	
	JSR Object_HitGround				;stay on ground
	
;only chase when grounded

	JSR SubHorzPos					;face player
	
	LDA CommonSprFlip,y				;
	STA Objects_FlipBits,X				;
	
	LDA Sprite_X_Speed,X				;set speed
	CMP BullyXSpeed,y				;cap speed
	BEQ @NoFloorHit					;
	CLC						;add acceleration to speed
	ADC CommonAcceleration,y			;
	STA Sprite_X_Speed,X				;store speed

@NoFloorHit
	LDA Objects_DetStat,X				;if hit wall, invert speed and shiz
	AND #$03					;
	BEQ @NoWall					;
	
	LDA Sprite_X_Speed,X				;
	;EOR #$FF
	;TAY
	;INY
	;TYA
	JSR Negate					;yeah, this is a thing
	STA Sprite_X_Speed,X				;

	JSR Bully_PlayBumpSnd				;play bump sound when hit wall
	
@NoWall
	LDA #$07					;animate every 7? frames
	JSR CommonAnimate				;
	
@Meh
	JSR Object_HitTestRespond			;check collision with player
	
@Re
	JMP Object_ShakeAndDraw				;and draw ofc

Bully_Interaction:
JSR SubHorzPos						;from what side bump has occured

LDA BumpSpd,y						;set bump speed
STA Player_XVel						;for player

LDA #$1A						;set longer time for frame to change
STA Sprite_Misc_Timer2,x				;
STA Sprite_Misc_Timer1,x				;and don't interact with player again for set time

LDA #$01						;set frame
STA Objects_Frame,X					;

LDA BullyBumpSpd,y					;set bump speed
STA Sprite_X_Speed,X					;for bully

Bully_PlayBumpSnd:
LDA Sound_QPlayer					;play bump speed
ORA #SND_PLAYERBUMP					;
STA Sound_QPlayer					;
	
Bully_Init:
RTS
