ObjectGroup00_InitJumpTable:
	.word GrinderInit
	
ObjectGroup00_NormalJumpTable:
	.word Grinder
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT32 | OA1_WIDTH32
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP5 | OA2_GNDPLAYERMOD | OA2_STOMPDONTCARE
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE | OA3_NOTSTOMPABLE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX11 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL

;doesn't matter	
;ObjPGrinder:

GrinderTiles:
db $95,$97,$97,$95,$95,$97,$97,$95
db $99,$9B,$9B,$99,$99,$9B,$9B,$99

Grinder_XSpeed = $18

GrinderInit:
;JSR Init_FacePlayer
JSR SubHorzPos
LDA #Grinder_XSpeed
DEY
BMI @Store

LDA #-Grinder_XSpeed

@Store
STA Sprite_X_Speed,x
RTS

Grinder:
JSR SubOffScreen

LDA #<GrinderTiles
LDY #>GrinderTiles
JSR General32x32GFX

;fix up the props afterwards (apply flips and priority)
LDY TEMP_SpriteTileSlotInLoop
LDA Sprite_RAM+2,y				;apply horizontal flip to the top right
ORA #$40
STA Sprite_RAM+2,y

LDA Sprite_RAM+6,y
ORA #$C0+$20					;bottom right is also flipped both horizontally and vertically (and priority)
STA Sprite_RAM+6,y

LDY TEMP_SpriteTileSlot
LDA Sprite_RAM+(4*4)+2,y			;second to last top tile is also flipped
ORA #$40
STA Sprite_RAM+(4*4)+2,y

LDA Sprite_RAM+(4*5)+2,y			;second to last bottom tile is also flipped
ORA #$C0+$20
STA Sprite_RAM+(4*5)+2,y

;apply vertical flip + BG priority to the last two bottom tiles
LDA Sprite_RAM+(4*1)+2,y
ORA #$80+$20
STA Sprite_RAM+(4*1)+2,y
STA Sprite_RAM+(4*3)+2,y

;GFX done, actual code
LDA Player_HaltGame
BNE @Re

;animate

LDA Counter_1					;animate and make noise every few frames
AND #$03
BNE @NoGFX

LDA Objects_Frame,x				;animate
EOR #$01					;
STA Objects_Frame,x				;

LDA Sound_QLevel2
ORA #SND_BOOMERANG				;I want to point out how surprisingly well this sound fits
STA Sound_QLevel2

@NoGFX
JSR Object_Move					;interact with objects
	
LDA Objects_DetStat,X				;
AND #$04					;
BEQ @NoFloorHit					;
	
JSR Object_HitGround				;stay on ground
	
@NoFloorHit
LDA Objects_DetStat,X				;if hit wall, invert speed and shiz
AND #$03					;
BEQ @NoWall					;
	
LDA Objects_XVel,X				; only speed, don't really care about flips
JSR Negate
STA Objects_XVel,X
	
@NoWall
JSR Player_HitEnemy				;interact witht the player

@Re
RTS