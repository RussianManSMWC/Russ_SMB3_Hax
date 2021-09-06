ObjectGroup00_InitJumpTable:
	.word ObjInit_DoNothing
	
ObjectGroup00_NormalJumpTable:
	.word CloudGenerator
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP2
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | $0B
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDART
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX00 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL 
	
ObjCloudGen:
db $9F,$9F

;Objects_Var10 - cloud present
;Objects_Var11 - cloud timer

CloudGen_CloudDuration = $9F
CloudGen_WhenToBlink = $40			;when start blinking

CloudGenerator:
LDA Player_HaltGame
BNE @Re

LDA Objects_Var10,x
BNE @CloudOn

LDA Objects_Var12,x
BEQ @CanGen

LDA Player_InAir
BNE @Re

LDA #$00
STA Objects_Var12,x

RTS

@CanGen
;cloud isn't on screen, allow one to spawn.
LDA Pad_Input
AND #PAD_UP
BEQ @Re
STA Objects_Var10,x					;spawned cloud

;set under the player

LDA Player_Y
CLC
ADC #$20
STA Objects_Y,x

LDA Player_YHi
ADC #$00
STA Objects_YHi,x

LDA Player_X
STA Objects_X,x

LDA Player_XHi
STA Objects_XHi,x

LDA #CloudGen_CloudDuration
STA Objects_Timer2,x					;used for anything???
STA Objects_Var12,x

;spawn poof of smoke

    JSR Object_DetermineVertVis ; Set flags based on which sprites of this object are vertically visible
    JSR Object_DetermineHorzVis
;JSR @DontShowButExist

@Smoke
	LDA #SND_LEVELPOOF
	STA Sound_QLevel1
;JSR SpecialObj_FindEmptyAbort
LDY #$07
JSR SpecialObj_FindEmptyAbortY

LDA #SOBJ_POOF
STA SpecialObj_ID,Y

LDA #$1f
STA SpecialObj_Data,Y

    LDA Objects_X,X
    STA SpecialObj_XLo,Y
    LDA Objects_Y,X
    STA SpecialObj_YLo,Y
    LDA Objects_YHi,X
    STA SpecialObj_YHi,Y

@Re
RTS

@CloudOn
;LDA Objects_State,X
;PHA
JSR SubOffScreen

LDA Objects_State,X
BNE @Alive

;stay alive but remove the cloud

STA Objects_Var10,x
STA Objects_Timer2,x

;PLA 
;STA Objects_State,X
LDA #OBJSTATE_NORMAL
STA Objects_State,X
RTS
;do I need to worry about Level_ObjectsSpawned,Y?

@Alive
;PLA


;solid for the player (copy-pasted from exploding platforms I made, can turn into subroutine if you want...)

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

    ;LDA Object_VelCarry
    ;BPL @Carry
;LDA #$00
    ;DEY      ; Y = -1 (provides a sort of carry if Player's X Velocity caused one)

;@Carry
    ; Add to Player_X, with carry
;    CLC
;    ADC Player_X
;    STA Player_X
;    TYA
;    ADC Player_XHi
;    STA Player_XHi

@NotOnPlat
LDA Objects_Timer2,x
BEQ @NoCloud
CMP #CloudGen_CloudDuration-$1F				;don't show when puff of smoke is displaying
BCS @DontShowButExist
CMP #CloudGen_WhenToBlink
BCS @NoBlink

LDA Counter_1
AND #$03
BNE @DontShowButExist

@Show
@NoBlink
JMP Object_ShakeAndDrawMirrored

@NoCloud
STA Objects_Var10,x
JMP @Smoke

@DontShowButExist
JSR Object_ShakeAndCalcSprite				;fixes clipping issue (the sprite is there but invisible)
LDX SlotIndexBackup
RTS