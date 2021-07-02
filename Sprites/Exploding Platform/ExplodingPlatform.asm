ObjectGroup00_InitJumpTable:
	.word ExplodingPlatform_Init
	
ObjectGroup00_NormalJumpTable:
	.word ExplodingPlatform
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDART
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01
	
ObjPExplodingPlat:
db $91,$93
db $95,$97
db $99,$9B
db $9D,$9F
db $B1,$B3				;1 unpressed
db $B5,$B7				;4 unpressed

ExplodingPlatform_TickTime = $30

ExplodingPlatform_Init:
LDY #$04
LDA Sprite_X_Position,x							;odd or even position determines initial number
AND #$10
BEQ @AAA
INY

@AAA
TYA
STA Objects_Frame,X
RTS

ExplodingPlatform:
JSR SubOffScreen

JSR Object_ShakeAndDraw

LDA Player_HaltGame
BEQ @Continue

@Continue
LDA Sprite_Misc_Table2,x						;check pressed flag
BEQ @NotExploding

LDA Sprite_Misc_Timer1,x
BNE @NotExploding

LDA Objects_Frame,X								;if it was at 1
BEQ @Disappear									;"explode"

LDA Sound_QLevel1								;tick sound
ORA #SND_LEVELBLIP
STA Sound_QLevel1

DEC Objects_Frame,X								;next frame

LDA #ExplodingPlatform_TickTime
STA Sprite_Misc_Timer1,x
BNE @NotExploding

@Disappear
JSR Object_PoofDie

LDA Sound_QLevel1
ORA #SND_LEVELBABOOM
STA Sound_QLevel1

@NotExploding
;copy-pasted from bank 2, and slightly modified to match graphics

    JSR Object_HitTest   ; Test if Player is touching object
    BCC @NotOnPlat     ; If not, jump to PRG002_BAEE (RTS)

    ; Test if Player is standing on top of platform

    LDA Player_SpriteY
    CLC
    ADC #20
    CMP Objects_SpriteY,X
    BCS @NotOnPlat  ; If Player's bottom is beneath object's top, jump to PRG002_BABE

    LDA Player_YVel
    BMI @NotOnPlat  ; If Player is moving upward, jump to PRG002_BABD

    LDA Objects_Y,X
    SEC
    SBC #28
    STA Player_Y
	
    LDA Objects_YHi,X
    SBC #$00
    STA Player_YHi

    ; Flag Player as NOT mid-air
    LDY #$00
    STY Player_InAir

    LDA Object_VelCarry
    BPL @Carry

    DEY      ; Y = -1 (provides a sort of carry if Player's X Velocity caused one)

@Carry
    ; Add to Player_X, with carry
    CLC
    ADC Player_X
    STA Player_X
    TYA
    ADC Player_XHi
    STA Player_XHi
	
	LDA Sprite_Misc_Table2,x				;is platform already going to explode?
	BNE @NotOnPlat							;if so, don't care
	
;set platform to explode
	
	LDA #ExplodingPlatform_TickTime			;set timer
	STA Sprite_Misc_Timer1,x
	
	INC Sprite_Misc_Table2,x				;press it
	
	LDY #$00								;set pressed frame from unpressed. this is for 1
	LDA Objects_Frame,X
	CMP #$04
	BEQ @Yes
	
	LDY #$03								;this is for 4
	
@Yes
	TYA
	STA Objects_Frame,X						;set correct pressed frame

@NotOnPlat	
RTS