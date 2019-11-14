ObjectGroup00_InitJumpTable:
	.word Init_Return
	
ObjectGroup00_NormalJumpTable:
	.word Crazy_Chomp
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
	.byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1

ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE

Object_AttrFlags:
    .byte OAT_BOUNDBOX01 | OAT_FIREIMMUNITY | OAT_HITNOTKILL
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | $0A				;same as normal chain chomp (duh)
	
ObjectGroup00_PatternSets:
ObjPChainChomp:
	.byte $91, $93, $9D, $9F

CrazyChomp_BounceSpd = $E0
CrazyChomp_HighBounceSpd = $C0

CrazyChomp_HighBounceRate = 3
	
CrazyChompXSpd:
.byte $10,$F0
	
CrazyChomp_BounceSpd = $D0
CrazyChomp_HighBounceSpd = $B0

CrazyChomp_HighBounceRate = 3
	
CrazyChompXSpd:
.byte $16,-$16
	
Crazy_Chomp:
    JSR SubOffScreen   					;Handle off-screen situation
	
	LDA Player_HaltGame					;
	BNE @Re
	
	JSR Player_HitEnemy					;collide with player
	JSR Object_Move						;move
	
	LDA Objects_DetStat,X				;
	STA $00								;save for future use
	AND #$04							;if hit ground, bounce
	BEQ @NoGroundHit					;
	
    JSR SubHorzPos						;face player on ground hit
	LDA CommonSprFlip,y					;
	STA Objects_FlipBits,X				;
	
	LDA CrazyChompXSpd,y				;
	STA Sprite_X_Speed,X				;
	
	LDA Sprite_Misc_Table1,x			;jump high when bounce counter is at set value
	CMP #CrazyChomp_HighBounceRate		;
	BNE @Default						;
	
	LDA #$00							;reset bounce counter
	STA Sprite_Misc_Table1,x			;
	
	LDA #CrazyChomp_HighBounceSpd		;
	BNE @StoreSpd						;
	
@Default
	INC Sprite_Misc_Table1,x			;increase bounce counter

	LDA #CrazyChomp_BounceSpd			;normal speed
	
@StoreSpd
	STA Sprite_Y_Speed,x				;
	
@NoGroundHit
	LDA $00								;
	AND #$03							;
	BEQ @NoWallHit						;hit wall, invert spd
	
	;JSR PRG001_A9B1					;can use this routine if in bank 1 (and Object_InteractWithWorld wasn't removed)
	
	JSR Object_AboutFace
    ;JSR Object_FlipFace				;now that i think of it AboutFace already flips sprite, no?
	
@NoWallHit
	LDA $00								;if hit ceiling, reset speed
	AND #$08							;
	BEQ @NoCeilingHit					;
	
	LDA #$00							;
	STA Sprite_Y_Speed,x				;
	
@NoCeilingHit

	LDA #$10							;animate every 16 frames
	JSR CommonAnimate					;
	
@Re
	JMP Object_ShakeAndDraw				;and draw
	
Init_Return:
	RTS