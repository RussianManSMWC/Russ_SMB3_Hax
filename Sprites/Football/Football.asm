ObjectGroup00_InitJumpTable:
	.word ObjInit_DoNothing
	
ObjectGroup00_NormalJumpTable:
	.word Football_Main
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL3 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1 | OA2_NOSHELLORSQUASH
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01

ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5|15
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_JUSTDRAW

ObjPFootball:
 .byte $87, $89

BounceHeights:
db $A0,$D0,$C0,$D0

FootballXSpeed:
    ;.byte $00, -$02,  $02,  $00,  $00,  $80,  $80,  $00 ; $00-$07
    ;.byte $00,  $80,  $00,  $80, -$01, -$01,  $01,  $01 ; $08-$0F
	
		db $00, -$10, $10, $00, $00, $00, $00, $00
		db $00, $00, $00, $00, -$0A, -$0A, $0A, $0A			;looks about right...

;Football from SMW
Football_Main:
;JSR SubOffScreen
JSR Object_DeleteOffScreen

JSR Player_HitEnemy

JSR Object_Move

LDA Objects_DetStat,X			;
AND #$03						;
BEQ @NoWallHit					;

JSR Object_AboutFace			;also affects flip, iirc football shouldn't do that. but idk

@NoWallHit
LDA Objects_DetStat,X			;
AND #$04						;
BEQ @NoFloorHit					;

;yes random!
LDA RandomN,X					;
AND #$03						;
TAY								;
LDA BounceHeights,y				;
STA Objects_YVel,x				;

;LDY Objects_Var1,x
;LDA BounceHeights,y
;STA Objects_YVel,x

LDY Level_Tile_Slope			;x-speed depending on slope
LDA FootballXSpeed,y			;
BEQ @NotSpeed					;
STA Objects_XVel,x				;

@NotSpeed
LDA Objects_FlipBits,X
EOR #SPR_HFLIP
STA Objects_FlipBits,X

;INC Objects_Var1,x

;LDA Objects_Var1,x
;CMP #$03
;BNE @NoFloorHit

;LDA #$00
;STA Objects_Var1,x

@NoFloorHit
LDA Objects_DetStat,X			;ceiling?
AND #$08						;
BEQ @Re							;

LDA #$00						;no y-speed
STA Objects_YVel,x				;

@Re
JMP Object_ShakeAndDraw			;