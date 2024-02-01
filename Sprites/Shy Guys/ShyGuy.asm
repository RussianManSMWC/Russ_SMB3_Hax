ObjectGroup00_InitJumpTable:
    .word ShyGuy_Init 					; shy guys
    .word Init_FacePlayer 				;
    .word ShyGuy_Init 					;
    .word Init_FacePlayer 				;
	
ObjectGroup00_NormalJumpTable:
    .word ShyGuy_Main 					;Shyboi (no ledge fall)
    .word ShyGuy_Main					;Shyboi (fall off ledges)
    .word ShyGuy_Main					;Shyboi giga (no ledge fall)
    .word ShyGuy_Main 					;Shyboi giga (fall)
	
ObjectGroup00_CollideJumpTable:
    .word ObjHit_DoNothing  			; \shy guys
    .word ObjHit_DoNothing  			; |
    .word ObjHit_DoNothing  			; |
    .word ObjHit_DoNothing  			; /
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH16  ; shy guys
    .byte OA1_PAL2 | OA1_HEIGHT16 | OA1_WIDTH16  ; 
    .byte OA1_PAL1 | OA1_HEIGHT32 | OA1_WIDTH32  ;
    .byte OA1_PAL2 | OA1_HEIGHT32 | OA1_WIDTH32  ;
	
ObjectGroup00_Attributes2:
    .byte OA2_TDOGRP1 | OA2_GNDPLAYERMOD	; shy guys (DUH)
    .byte OA2_TDOGRP1 | OA2_GNDPLAYERMOD 	;
    .byte OA2_TDOGRP6 | OA2_GNDPLAYERMOD 	;
    .byte OA2_TDOGRP6 | OA2_GNDPLAYERMOD 	;
	
ObjectGroup00_Attributes3:
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE	; i hate repeating myself, but... yeah, they're still shy guys
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE	;
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE	;
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE	;

Object_AttrFlags:
    .byte OAT_BOUNDBOX01 | OAT_BOUNCEOFFOTHERS  	;
    .byte OAT_BOUNDBOX01 | OAT_BOUNCEOFFOTHERS 		;
    .byte OAT_BOUNDBOX06 | OAT_BOUNCEOFFOTHERS 		;
    .byte OAT_BOUNDBOX06 | OAT_BOUNCEOFFOTHERS		;

ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
    .byte KILLACT_STANDARD
    .byte KILLACT_STANDARD
    .byte KILLACT_STANDARD
	
ObjectGroup00_PatTableSel:
    .byte OPTS_SETPT5 | 15 							; custom graphic
    .byte OPTS_SETPT5 | 15 							;
    .byte OPTS_SETPT5 | 15 							;
    .byte OPTS_SETPT5 | 15 							;
	
ObjectGroup00_PatternSets:
ObjPShyGuy:
	.byte $B5,$B7,$95,$97			;only used by small shy guys, giant shy guy uses it's own table not set in the pattern set

Sprite_GiantShyGuyNoLedge = $15				;what sprite number are giant shy guy (should be right after small shy guys)

ShyGuy_Init:
INC Sprite_Misc_Table1,x			;flag indicating this is a ledge-staying shy guy
JMP Init_FacePlayer					;

ShyGuy_Main:
JSR SubOffScreen

LDA Player_HaltGame					;freeze flag = return
BEQ @Run							;
JMP @STOPRIGHTTHERECRIMINALSCUM		;too far for branch

@Run
LDA #$07							;
JSR CommonAnimate					;

LDA #$08     						; A = $08

LDY Objects_FlipBits,X
BNE @StoreSpd  						; If flipped, jump to PRG004_B275

LDA #-$08    						; A = -$08

@StoreSpd
STA Sprite_X_Speed,x

;JSR Object_Move  					; Do standard movement (except it doesn't work)

JSR Object_ApplyYVel				; workaround for top solidity
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
;CMP #ShyGuyGravity
;BEQ @Stop
CLC									;
ADC #OBJECT_FALLRATE				;gravity
STA Sprite_Y_Speed,x				;

@Stop
LDA Sprite_Misc_Table1,x			;code from generic troop, specifically red koopa
BEQ @NoFloorAllign

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
JSR Object_HitTest					;
BCC @NoHit							;

JSR SubVertPos						;
LDA Temp_Var16						;not on top = hurt
CMP #$E8							;
BPL @Hurt							;

LDA Player_YVel						;if player's moving up (jumped), don't stay on top
BMI @NoHit							;

LDA Objects_Y,X						;do stay on top
SEC									;
SBC #28								;
STA Player_Y						;

LDA Objects_YHi,X					;
SBC #$00							;
STA Player_YHi						;

LDY #$00							;not in air
STY Player_InAir					;
STY Player_YVel						;reset speed

LDA Player_SpriteX					;check collision with boundary
CMP #16								;so it doesn't push inside and kill
BLT @STOPRIGHTTHERECRIMINALSCUM		;

LDA Object_VelCarry
BPL @NoDEY  						; If platform X velocity carried, jump to PRG005_AFB8

DEY      							; Y = $FF (16-bit sign extension)

@NoDEY
CLC									;
ADC Player_X        				; Add carry value to Player X
STA Player_X        				; Update Player X

TYA      							; Sign extension -> 'A'
ADC Player_XHi      				; Apply carry
STA Player_XHi      				; Update Player X Hi
JMP @STOPRIGHTTHERECRIMINALSCUM		; sadly

@Hurt
JSR Player_GetHurt					;ouch

@NoHit
@STOPRIGHTTHERECRIMINALSCUM
LDA Level_ObjectID,x				;
CMP #Sprite_GiantShyGuyNoLedge		;giant sprites should appear after small and should be next to each other 
BCS @Giant							;
JMP Object_ShakeAndDraw				;

@Giant
LDA #<GiantShyGuyTiles				;
PHA									;

LDA #>GiantShyGuyTiles				;
PHA									;
JMP General32x32					;beep

GiantShyGuyTiles:
db $AD,$AF,$B1,$B3,$8D,$8F,$91,$93
db $B9,$BB,$BD,$BF,$99,$9B,$9D,$9F
