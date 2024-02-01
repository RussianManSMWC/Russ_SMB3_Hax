;LET THERE BE FIREWORKS
;Moves at different speeds and is launched at different times based on its x-position

ObjectGroup00_InitJumpTable:
	.word FireworksInit

ObjectGroup00_NormalJumpTable:
	.word Fireworks
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
	.byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH8
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP0
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15

ObjectGroup00_KillAction:
    	.byte KILLACT_STANDARD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX00 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL

ObjPFirework:
db $85,$87

Fireworks_InitSpeeds:
db $E2,$E6,$E4,$E0

Fireworks_InitTimers:
db $60,$10,$A0,$FF

FireworksInit:
;depend on x-pos...
;also timer

	LDA Sprite_X_Position,x
	AND #$30
	LSR
	LSR
	LSR
	LSR
	TAY
	LDA Fireworks_InitSpeeds,y
	STA Sprite_Y_Speed,x
	
	LDA Fireworks_InitTimers,y
	STA Sprite_Misc_Timer1,x
RTS

Fireworks:
JSR SubOffScreen

;LDA Objects_Timer2,x
;BNE @DoShow

;LDA Counter_1
;AND #$03
;BNE @NoGFX

@DoShow
;JSR Object_ShakeAndDraw
    JSR Object_AnySprOffscreen
    BNE @NoGFX  ; If any of Hotfoot's sprites are off-screen, jump to PRG002_A888 (RTS)

    JSR Object_CalcSpriteXY_NoHi    ; Calculate Hotfoot's sprites
    LDY ObjGroupRel_Idx     ; Y = Object's group relative index
    LDA ObjectGroup_PatternStarts,Y ; Get Hotfoot's starting pattern index
    CLC
    ADC Objects_Frame,X     ; Offset by frame
    TAY             ; -> 'Y'
    LDA ObjectGroup_PatternSets,Y   ; Get appropriate sprite pattern for this frame

    ; Store pattern into sprite RAM
    LDY Object_SprRAM,X
    STA Sprite_RAM+$01,Y

    ; Store Y coordinate
    LDA Objects_SpriteY,X
    STA Sprite_RAM+$00,Y

    ; Store attributes
    LDA Objects_SprAttr,X
    ORA Objects_FlipBits,X
    STA Sprite_RAM+$02,Y

    ; Store X coordinate
    LDA Objects_SpriteX,X
	CLC
	ADC #$04
    STA Sprite_RAM+$03,Y

;LDA Counter_1
;AND #$03
;BNE @NoGFX

LDA Objects_Frame,x
EOR #$01
STA Objects_Frame,x

;LDA #$02
;STA Objects_Timer2,x

@NoGFX
LDA Sprite_Misc_Timer1,x
BNE @Return

JSR Object_ApplyYVel

INC Sprite_Misc_Table1,x
LDA Sprite_Misc_Table1,x
AND #$03
BNE @KeepAccel

INC Sprite_Y_Speed,x

@KeepAccel
LDA Sprite_Y_Speed,x
CMP #$FC
BNE @Return

;turn into explosion...
LDA #$55
STA Level_ObjectID,X

    LDA #$00
    STA Objects_Var3,X

    ; Set internal state to 2
    LDA #$02
    STA Objects_Var5,X

    ; Reset timer to $28 (length of explosion)
    LDA #$28
    STA Objects_Timer,X

    ; Ba-boom
    LDA Sound_QLevel1
    ORA #SND_LEVELBABOOM
    STA Sound_QLevel1

    ; Since Bob-omb is exploding, he no longer needs to enforce his pattern bank
    INC Objects_DisPatChng,X
	
    LDA #$10
    STA RotatingColor_Cnt

@Return
RTS