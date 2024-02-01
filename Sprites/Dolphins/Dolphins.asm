;Vertical and horizontal dolphins from SMW

ObjectGroup00_InitJumpTable:
	.word DolphinVert_Init				;vertical init
	.word ObjInit_DoNothing				;horizontal init (no init really)

ObjectGroup00_NormalJumpTable:
	.word DolphinVert
	.word DolphinHorz
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
	.byte OA1_PAL3 | OA1_HEIGHT32 | OA1_WIDTH16	;vertical
	.byte OA1_PAL3 | OA1_HEIGHT16 | OA1_WIDTH40	;horizontal
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP2 | OA2_GNDPLAYERMOD		;v
	.byte OA2_TDOGRP5 | OA2_GNDPLAYERMOD		;h
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	.byte OPTS_SETPT5 | 15

ObjectGroup00_KillAction:
    	.byte KILLACT_STANDARD
	.byte KILLACT_STANDARD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL
	.byte OAT_BOUNDBOX13 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL

;OAT_BOUNDBOX02 | OAT_WEAPONIMMUNITY | OAT_HITNOTKILL Vert???
;OAT_BOUNDBOX08 | OAT_WEAPONIMMUNITY | OAT_HITNOTKILL Horz

ObjPVertDolph:
db $A1,$A3,$A5,$A7

ObjPHorzDolph:
db $91,$93,$95,$97,$81				;last tile is tail
db $B1,$B3,$B5,$B7,$83

DolphinHorz_XAccel:
db -$01,$01

DolphinHorz_MaxXSpd:
db -$08,$08

DolphinVert_Init:
INC Objects_Var12,x
RTS

DolphinVert:
;this one is simply 16x32 that flips.
JSR Object_Draw16x32Sprite
JMP Dolphin_Shared

DolphinHorz:
JSR DolphinHorzGFX

Dolphin_Shared:
JSR SubOffScreen

LDA Player_HaltGame
BEQ @Continue
RTS

@Continue
LDA Objects_Var12,x
BEQ @HorzAnim

LDY #$00
LDA Counter_1
AND #$04
BEQ @StoreFlip
;LSR
;LSR
;BCC @StoreFlip
;LDY #$01
INY
BNE @StoreFlip

@HorzAnim
LDA Counter_1
AND #$08
LSR
LSR
LSR
;BNE @NoFlip

;LDA Objects_Var10,x
;EOR #$01
STA Objects_Var10,x

@NoFlip
LDA Objects_Var11,x
AND #$01
TAY

@StoreFlip
LDA CommonSprFlip,y
STA Objects_FlipBits,x
;LSR
;BCC @NO

;LDA Objects_FlipBits,x
;EOR #$40
;STA Objects_FlipBits,x

@NO
JSR Object_ApplyYVel_NoLimit
JSR Object_ApplyXVel
    ; Apply Y velocity

LDA Sprite_Y_Speed,x	; sprite Y speed
BMI @MovingUp	; if the sprite is moving down...
CMP #$3F		; and its Y speed has not reached 3F...
BCS @MaxYSpeed	;
@MovingUp	;
INC Sprite_Y_Speed,x	; increment its Y speed
@MaxYSpeed	;

TXA		; sprite index -> A
EOR Counter_1	;
LSR		; every other frame depending on the sprite index...
BCC @NoObjInteract	; don't interact with objects

JSR Object_WorldDetectN1

@NoObjInteract
LDA Sprite_Y_Speed,x
BMI @PlayerInt

LDA Objects_InWater,X
BEQ @PlayerInt

LDA Sprite_Y_Speed,x	;
SEC		;
SBC #$08		; diminish the sprite Y speed by 8
STA Sprite_Y_Speed,x
BPL @NoSpeedZero

LDA #$00
STA Sprite_Y_Speed,x

@NoSpeedZero
LDA Objects_Var12,x
BNE @JustJump

;LDY #$02
;BNE @NotASNormal

@Normal
LDA Objects_Var11,x
AND #$01
TAY

@NotASNormal
LDA Sprite_X_Speed,x
CLC
ADC DolphinHorz_XAccel,y
STA Sprite_X_Speed,x
CMP DolphinHorz_MaxXSpd,y
BNE @PlayerInt

@JustJump
INC Objects_Var11,x

LDA #$C0
STA Sprite_Y_Speed,x

@PlayerInt
    JSR Object_HitTest   ; Test if Player is touching object
    BCC @NotOnPlat     ; If not, jump to PRG002_BAEE (RTS)

    ; Test if Player is standing on top of platform

	;LDA #$00
	;STA Object_VelCarry				;no vel carry!!! (so the player doesnt slide off)

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
	STY Player_YVel

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

     
@NotOnPlat
RTS

;similar to LogPlat_Draw
DolphinHorzGFX:
LDA Objects_FlipBits,x
STA Temp_Var16

;I ain't using Objects_Frame because i think it'd be a bit complicated to calculate gfx stuff. instead just use some other misc table
LDA Objects_Var10,x
PHA
JSR Object_ShakeAndCalcSprite
PLA
BEQ @FirstFrame

;INX
;INX
;INX
;INX
;INX

TXA									;i think less cpu cycles? same space
CLC
ADC #$05
TAX

@FirstFrame
STX Temp_Var15

;need to figure out what to draw first depending on flipping, 16x16 portion or 24x16 one

    LDA Counter_1
    LSR A
    PHP      ; Save CPU state (most importantly the carry flag)
    BCC @SIKE  ; Every other tick, jump to PRG002_B5BD

    ; Y += (11 + C = 12) -- Every other tick, offset Sprite_RAM
    TYA
    ADC #$0B
    TAY

@SIKE
LDA Temp_Var16
BEQ @DrawNorm

;flipped
INX
INX
INX

@DrawNorm
JSR Object_Draw16x16Sprite

LDA Temp_Var7   ; Get Sprite_RAM offset (as determined by Object_ShakeAndCalcSprite)
PLP      ; Restore CPU state
BCS @Convert  ; Every other opposite tick, jump to PRG002_B5C7

TYA
ADC #$08

@Convert
TAY

INX							;drew first two tiles
INX

LDA #16
CLC
ADC Temp_Var2
STA Temp_Var2

    ; Alters horizontal visibility ??
ASL Temp_Var8
ASL Temp_Var8

@DrawPlz
LDA Temp_Var16
BEQ @DrawNormTwo

LDX Temp_Var15

@DrawNormTwo
JSR Object_Draw24x16Sprite   ; Draw wide sprite

    LDX SlotIndexBackup         ; X = object slot index
RTS