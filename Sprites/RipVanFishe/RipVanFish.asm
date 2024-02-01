;
ObjectGroup00_InitJumpTable:
	.word RipVanFish_Init
	
ObjectGroup00_NormalJumpTable:
	.word RipVanFish
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL3 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1 | OA2_NOSHELLORSQUASH
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_JUSTDRAW  | OA3_NOTSTOMPABLE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 31
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01
	
;pog fish, i mean rip van fish
ObjPRipVanFish:
db $B9,$BB
db $BD,$BF
db $99,$9B
db $9D,$9F

;Code and rest goes here

	;shared, feel free to separate them
	RipVanFish_MaxSpeedY:
	RipVanFish_MaxSpeedX:
	db $10,$F0

	 RipVanFish_Init:
	 LDA #$01
	 STA Objects_InWater,X
	 RTS

RipVanFish:
JSR SubOffScreen
JSR Object_ShakeAndDraw

;facing based on speed
LDA #$40
LDY Sprite_X_Speed,x
BPL @Set
LDA #$00

@Set
STA Objects_FlipBits,x

;LDA Player_HaltGame
;BEQ @Continue

JSR Player_HitEnemy

;there's supposed to be a star check, but i dont feel like implementing that rn

;LDA #$30
;STA ObjSplash_DisTimer,x			;NEVER show splashes! (doesnt work??? as in disables water interaction entirely, which is ???)

JSR Object_ApplyXVel
JSR Object_ApplyYVel
JSR Object_WorldDetectN1

INC Sprite_Misc_Table1,x					;animation frame counter

LDA Objects_DetStat,x
AND #$03
BEQ @NoWall

LDA #$00
STA Sprite_X_Speed,x

@NoWall
LDA Objects_DetStat,x
AND #$0C
BEQ @NoGrndCeiling
CMP #$04
BEQ @NotCeiling

LDA #$00
STA Sprite_Y_Speed,x
BEQ @NoGrndCeiling

@NotCeiling
JSR Object_HitGround

@NoGrndCeiling
LDA Objects_InWater,X
BNE @InWater

;when not in water....
LDA #$10
STA Sprite_Y_Speed,x

@InWater
LDA Objects_Var11,x
BNE @Chasing

;sleeping state
@Sleepy
LDA #$02									;when sleeping, sinks very slowly
STA Sprite_Y_Speed,x

LDA Counter_1
AND #$03
BNE @NoXSpeedMess

LDA Sprite_X_Speed,x
BEQ @NoXSpeedMess
BPL @DecXSpd

INC Sprite_X_Speed,x
JMP @NoXSpeedMess

@DecXSpd
DEC Sprite_X_Speed,x

@NoXSpeedMess
;LDA Objects_DetStat,x						;do we need any of this???
;AND #$04
;BEQ @NoGrnd

;LDA #$00
;STA Sprite_Y_Speed,x

;LDA Sprite_Y_Position,x
;AND #$F0
;STA Sprite_Y_Position,x

;JSR Object_HitGround						;alt?

@NoGrnd
;i'd include Zs but i;m lazy rn

;JSR RipVanFishSpawnZts				;dont spawn zts

	LDA Objects_SprHVis,X
	BNE @NoChase

JSR Level_ObjCalcXDiffs

LDA Temp_Var16
			ADC #$30			; | 
			CMP #$60			; |
			BCS @NoChase			;/ branch

JSR Level_ObjCalcYDiffs

LDA Temp_Var16
			ADC #$30			; |
			CMP #$60			; |
			BCS @NoChase			;/ branch
			
			INC Objects_Var11,x
			LDA #$FF			;\ Set timer for chasing Mario
			;STA !151C,x			;/
			;STA Objects_Timer,x
			STA Objects_Var10,x
			BNE @Chasing

@NoChase
;sleeping animation
LDY #$02
LDA Sprite_Misc_Table1,x
AND #$30
BNE @StoreFrame
INY

@StoreFrame
TYA
STA Objects_Frame,x
RTS

;WIP

@Chasing
LDA Counter_1
LSR
BCS @NoTimer

DEC Objects_Var10,x
BEQ @FallSleep

@NoTimer
LDA Counter_1
AND #$07
BNE @AnimateChase

;chase da player
JSR SubHorzPos
			LDA Sprite_X_Speed,x		;\ If horizontal max speed in direction towards Mario achieved,
			CMP RipVanFish_MaxSpeedX,y			; |
			BEQ @NoMoreAccel			;/ branch
			CLC				;\ Else, accelerate towards Mario
			ADC CommonAcceleration,y		; |
			STA Sprite_X_Speed,x		;/
			
@NoMoreAccel
JSR SubVertPos
			LDA Sprite_Y_Speed,x		;\ If horizontal max speed in direction towards Mario achieved,
			CMP RipVanFish_MaxSpeedY,y			; |
			BEQ @NoMoreAccelY			;/ branch
			CLC				;\ Else, accelerate towards Mario
			ADC CommonAcceleration,y		; |
			STA Sprite_Y_Speed,x	

@NoMoreAccelY	
			;NOT sleeping animation
			
			@AnimateChase
LDY #$00
LDA Sprite_Misc_Table1,x
AND #$04
BEQ @StoreFrame2
INY

@StoreFrame2
TYA
STA Objects_Frame,x
RTS

@FallSleep
DEC Objects_Var11,x
JMP @Sleepy