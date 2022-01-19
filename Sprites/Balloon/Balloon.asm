ObjectGroup00_InitJumpTable:
	.word Balloon_Init
	
ObjectGroup00_NormalJumpTable:
	.word Balloon_Main
	
ObjectGroup00_CollideJumpTable:
	.word Baloon_Interaction

	;initial palette doesn't matter, as it's tied to initial X-pos
ObjectGroup00_Attributes:
    .byte OA1_PAL2 | OA1_HEIGHT32 | OA1_WIDTH16
	
ObjectGroup00_KillAction:
    .byte KILLACT_JUSTDRAW16X32
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1 | OA2_NOSHELLORSQUASH
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX02 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL

ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5|15
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE | OA3_TAILATKIMMUNE

ObjPBalloon:
.byte $91,$93,$87,$89
.byte $95,$97,$87,$89
 
.byte $99,$9B,$87,$89
.byte $9D,$9F,$87,$89

Balloon_ColorTable:
db $01,$02,$03,$02

Balloon_LatchYSpd = $F0				;y-speed for when player's on the balloon

Balloon_Init:
LDA Objects_X,x						;palette depednds on initial X-pos
LSR
LSR
LSR
LSR
AND #$03
TAY
LDA Objects_SprAttr,x
AND #$FF-3							;save all bits but bit 0 and 1 (palettes)
ORA Balloon_ColorTable,y
STA Objects_SprAttr,x
RTS

;Objects_Var1 - balloon's state
;Objects_Var5 - rope flip
Balloon_Main:
JSR Object_Draw16x32Sprite			;draw da balloon

LDA Objects_Var5,x				;check if the rope is supposed to be flipped
BEQ @NoFlip

;small rope flipping
LDY Object_SprRAM,X					;don't flip entire 16x32 sprite, only rope
LDA Sprite_RAM+10,y					;
EOR #$40
STA Sprite_RAM+10,y
STA Sprite_RAM+14,y

LDA Sprite_RAM+11,y
CLC
ADC #$08
STA Sprite_RAM+11,y

LDA Sprite_RAM+15,y
SEC
SBC #$08
STA Sprite_RAM+15,y

@NoFlip
JSR Object_DeleteOffScreen

LDA Player_HaltGame
BNE Baloon_Return					;forgot the most essential

LDA Counter_1						;flip the rope every few frames
AND #$07
BNE @NoFlipChange

LDA Objects_Var5,x
EOR #$01
STA Objects_Var5,x

@NoFlipChange
LDA Objects_Var1,x
JSR DynJump

.dw Baloon_WaitPlayer
.dw Baloon_CarryPlayer
.dw Baloon_Away

Baloon_WaitPlayer:
JSR Object_HitTestRespond

LDA Counter_1
AND #$3F
BNE Baloon_Return

Baloon_ChangeFrame:
LDA Objects_Frame,x
EOR #$01
STA Objects_Frame,x

Baloon_Return:
RTS

Balloon_ShiftXPosLo:
db $01,$FF

Balloon_ShiftXPosHi:
db $00,$FF

Baloon_Interaction:
LDA #$02
STA Objects_Frame,x

INC Objects_Var1,x

;Give Speed!

LDA #Balloon_LatchYSpd
STA Objects_YVel,x

;place player at sprite's position (and zero speed)
Baloon_PlacePlayerAtIt:
;do every pixel, maybe this will prevent graphical glitches
LDA Objects_X,x
CMP Player_X
BEQ @CheckHi

@Shift
;move one pixel
JSR SubHorzPos
TYA
LDA Objects_X,x
CLC
ADC Balloon_ShiftXPosLo,y
STA Player_X

LDA Objects_XHi,x
ADC Balloon_ShiftXPosHi,y
STA Player_XHi
JMP @Others

@CheckHi
LDA Objects_XHi,x
CMP Player_XHi
BNE @Shift

@Keep
LDA Objects_X,x
STA Player_X

LDA Objects_XHi,x
STA Player_XHi

@Others
LDY #$10-7
LDA Player_Suit
BEQ @Small
LDY #$18-7

@Small
TYA
CLC
ADC Objects_Y,x
STA Player_Y

;may not work too well in vertical levels, maybe? (had to fix horizontal screen garbage when placing player at sprite's x-pos, maybe need same fix for vert, but IDK)
LDA Objects_YHi,x
ADC #$00
STA Player_YHi

LDY #$01							;
STY Player_FlyTime					;trick the game so it can scroll vertically always (if locked scroll)
DEY									;
STY Player_XVel						;no X-speed (to-do: make player able to move freely horizontally?) 

LDY #$F8							;enough upward speed to check for ceiling
STY Player_YVel						;
RTS									;
;interact w/ player

;if interact success, carry da player
Baloon_CarryPlayer:
LDA Counter_1
AND #$0F
BNE @NoFrame

JSR Baloon_ChangeFrame

@NoFrame
LDA Controller1Press				;check for A button
AND #PAD_A
BEQ @NOOO							;well

;player jump action
LDA #$C8							;Y-speed
STA Player_YVel

LDA #SND_PLAYERJUMP
ORA Sound_QPlayer
STA Sound_QPlayer

@GetOff
INC Objects_Var1,x

;random X-speed. idk
LDA Random_Pool+3
AND #$07
ASL
STA $00
AND #$01
BEQ @StoreSpeed

LDA $00
JSR Negate
JMP @TrulyStore

@StoreSpeed
LDA $00

@TrulyStore
STA Objects_XVel,x
RTS

@NOOO
LDA Player_HitCeiling				;hitting the ceiling?
BNE @GetOff							;get off the balloon

JSR Baloon_PlacePlayerAtIt			;place player at the balloon's pos
JMP Object_ApplyYVel				;move vertically

Baloon_Away:
LDA Objects_YVel,x					;if it somehow hits max upward speed, don't overflow
CMP #$80
BEQ @NoMorePlz

DEC Objects_YVel,x					;accelerate up constantly

@NoMorePlz
JSR Object_ApplyXVel
JMP Object_ApplyYVel