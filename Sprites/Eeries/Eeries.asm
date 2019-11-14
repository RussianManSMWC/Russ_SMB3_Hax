ObjectGroup00_InitJumpTable:
    .word EerieInit 				; Eerie
    .word EerieWaveInit 			; Wave Eerie
    .word EerieInit 				; Giant Eerie
    .word EerieWaveInit				; Wave Giant Eerie
	
ObjectGroup00_NormalJumpTable:
    .word EerieMain 				;eeries, big and small, wave and straight
    .word EerieMain
    .word EerieMain
    .word EerieMain 
	
ObjectGroup00_CollideJumpTable:
    .word ObjHit_DoNothing  		; \eeries
    .word ObjHit_DoNothing  		; |
    .word ObjHit_DoNothing  		; |
    .word ObjHit_DoNothing  		; /
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH16  ; eeries
    .byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH16  ;
    .byte OA1_PAL1 | OA1_HEIGHT32 | OA1_WIDTH32  ;
    .byte OA1_PAL1 | OA1_HEIGHT32 | OA1_WIDTH32  ;
	
ObjectGroup00_Attributes2:
    .byte OA2_TDOGRP1   			; eeries (if you didn't figure it out already)
    .byte OA2_TDOGRP1   			;
    .byte OA2_TDOGRP1   			;
    .byte OA2_TDOGRP1   			;
	
ObjectGroup00_Attributes3:
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE
    .byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE

Object_AttrFlags:
    .byte OAT_BOUNDBOX01 | OAT_FIREIMMUNITY | OAT_HITNOTKILL    ; eerie
    .byte OAT_BOUNDBOX01 | OAT_FIREIMMUNITY | OAT_HITNOTKILL    ; eerie wave
    .byte OAT_BOUNDBOX06 | OAT_FIREIMMUNITY | OAT_HITNOTKILL    ; giant eerie
    .byte OAT_BOUNDBOX06 | OAT_FIREIMMUNITY | OAT_HITNOTKILL    ; giant eerie wave
	
ObjectGroup00_PatTableSel:
    .byte OPTS_SETPT5 | 15 			; custom graphic
    .byte OPTS_SETPT5 | 15 			;
    .byte OPTS_SETPT5 | 15 			;
    .byte OPTS_SETPT5 | 15 			;
	
ObjectGroup00_PatternSets:
ObjPEerie:
	.byte $81,$83,$A1,$A3			;only used by small eeries, giant eerie uses it's own table not set in the pattern set (set giant eerie's pattern set to whatever)

Sprite_GiantEerie = $11				;what sprite number are giant eeries (should be right after small eeries
	
EerieXSpd:
db $10,$F0

EerieYSpd:
db $18,$E8

EerieWaveInit:
INC Sprite_Misc_Table1,x			;flag indicating this is a wave eerie

EerieInit:
JSR Init_FacePlayer					;

LDA EerieXSpd,y						;set initial speed
STA Sprite_X_Speed,x				;
RTS

EerieMain:
JSR SubOffScreen

LDA Player_HaltGame					;only graphics if freeze flag is set
BNE @GFX							;

JSR Player_HitEnemy					;collide with player
	
LDA #$07							;every X frames, animate
JSR CommonAnimate					;

JSR Object_ApplyXVel				;update X-pos

LDA Sprite_Misc_Table1,x			;check if it is wavy
BEQ @GFX							;don't move vertically if not

LDY Sprite_Misc_Table2,x			;vertical direction
LDA Sprite_Y_Speed,x				;
CLC									;accelerate
ADC CommonAcceleration,y			;
STA Sprite_Y_Speed,x				;
CMP EerieYSpd,y						;
BNE @YSpd							;

LDA Sprite_Misc_Table2,x			;change (vertical) direction when hit max speed
EOR #$01							;
STA Sprite_Misc_Table2,x			;

@YSpd
JSR Object_ApplyYVel_NoLimit		;update pos and stuff

@GFX
LDA Level_ObjectID,x				;
CMP #Sprite_GiantEerie				;giant sprites should appear after small and should be next to each other 
BCS GiantEerieGFX					;draw big huge massive gfx
JMP Object_ShakeAndDraw				;or not

GiantEerieTiles:
db $A5,$A7,$A9,$AB,$85,$87,$89,$8B
db $AD,$AF,$B1,$B3,$8D,$8F,$91,$93

GiantEerieGFX:
LDA #<GiantEerieTiles
PHA
LDA #>GiantEerieTiles
PHA
;protip: if 32x32 graphic routine is right after this (or any 32x32 sprite really), JMP is unecessary.
JMP General32x32GFXRoutine
