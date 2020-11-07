ObjectGroup00_InitJumpTable:
	.word ObjInit_DoNothing
	
ObjectGroup00_NormalJumpTable:
	.word Thwimp
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL2 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1 | OA2_GNDPLAYERMOD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01 | OAT_FIREIMMUNITY

ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | $12
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE

ObjPThwimp:
db $B7,$B7

Thwimp_MaxFallSpeed = $40
Thwimp_JumpSpeed = $A0

Thwimp_WaitTime = $40

Thwimp_XSpeed:
db $10,$F0

;Thwimp from SMW
Thwimp:
	JSR Object_ShakeAndDrawMirrored
	JSR SubOffScreen

	LDA Player_HaltGame				;
    BNE @Re							;
	
	JSR Player_HitEnemy
	
	;apply diff gravity when grounded
	
	JSR Object_ApplyYVel
	JSR Object_ApplyXVel
	JSR Object_WorldDetect4;N1	;JSR Object_WorldDetect4
	
	LDA Sprite_Blocked_Status,x
	AND #$0C
	BEQ @Gravity
	LDY #$10
	AND #$08
	BNE @AlmostStore
	
	LDA #$00							;otherwise it's grounded, reset y-speed and x-speed
	STA Sprite_X_Speed,x
	STA Sprite_Y_Speed,x
	
	;LDA Sprite_Y_Position,x
	;SEC
	;SBC #$01
	;STA Sprite_Y_Position,x
	
	;LDA Sprite_Y_PositionHi,x
	;SBC #$00
	;STA Sprite_Y_PositionHi,x
	
	;JSR Object_HitGround				;right? (answer - no! doesn't work)

	LDY Sprite_Misc_Timer1,x
	BEQ @RestoreTimer
	DEY
	BNE @Re
	
	INC Sprite_Misc_Table1,x
	LDA Sprite_Misc_Table1,x
	AND #$01
	TAY
	LDA Thwimp_XSpeed,y
	STA Sprite_X_Speed,x
	
	LDA #Thwimp_JumpSpeed
	BNE @Store
	RTS
	
@AlmostStore	
	TYA
	BNE @Store
	
@Gravity	
	LDA Sprite_Y_Speed,x
	BMI @LessGravity
	CMP #Thwimp_MaxFallSpeed
	BCS @Store
	ADC #$05
	
@LessGravity
	CLC
	ADC #$03

@Store
	STA Sprite_Y_Speed,x
	
@Re
	RTS
	
@RestoreTimer	
	LDA #Thwimp_WaitTime
	STA Sprite_Misc_Timer1,x

	LDA Sound_QPlayer
	ORA #SND_PLAYERBUMP
	STA Sound_QPlayer
	RTS