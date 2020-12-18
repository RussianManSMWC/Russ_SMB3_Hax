ObjectGroup00_InitJumpTable:
	.word KaboombaInit
	
ObjectGroup00_NormalJumpTable:
	.word Kaboomba
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing

	;initial palette doesn't matter, as it's tied to initial X-pos
ObjectGroup00_Attributes:
    .byte OA1_PAL2 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP0
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01 | OAT_FIREIMMUNITY | OAT_HITNOTKILL

ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5|15
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_JUSTDRAW

ObjPKaboomba:
db $93,$95
db $97,$99
db $9B,$9D
db $B3,$B5
db $B7,$B9
db $93,$95

TimePerShootFrame = $09
InitialSpawnTime = $60

SpawnedSprite = $6C
SpawnedSprite_YSpd = $E0
SpawnedSprite_State = OBJSTATE_KICKED

SpawnedShellXSpd:
db $E8,$18

ShellXDisp:
db $F0+4,$10-4

ShellXDispHi:
db $FF,$00

ShellYDisp = $F0+4

Kaboomba:
JSR Object_DeleteOffScreen

LDA Sprite_Misc_Table1,x
BEQ @WalkNorm

;Shoot
JSR DoShootin
LDA #$00
BEQ @StoreSpd
;most of this is copy-pasted from shyguy i made

@WalkNorm
;LDA #$08     ; A = $08
;JSR CommonAnimate

;check frame counter and animate

LDA Counter_1
AND #$07
BNE @NoFrame

LDA Objects_Frame,X
EOR #$01
STA Objects_Frame,X

@NoFrame
LDA #$08
LDY Objects_FlipBits,X
BNE @StoreSpd  ; If flipped, jump to PRG004_B275

LDA #-$08    ; A = -$08

@StoreSpd
STA Sprite_X_Speed,x

JSR Object_ApplyYVel
JSR Object_ApplyXVel
JSR Object_WorldDetect4

LDA Objects_DetStat,X
AND #$03
BEQ @NoWallz  			; If troopa has not hit a wall, jump to PRG004_B283

JSR Object_FlipFace

@NoWallz
LDA Objects_DetStat,X
AND #$04
BNE @HitGround				; If troopa has hit ground, jump to PRG004_B29B

LDA Sprite_Y_Speed,x
;CMP #ShyGuyGravity
;BEQ @Stop
CLC
ADC #OBJECT_FALLRATE		;CommonAcceleration
STA Sprite_Y_Speed,x
JMP @Stop

@HitGround
LDA #$00
STA Sprite_Y_Speed,x

JSR Object_HitGround

@Stop
JSR Object_HitTest
BCC @NoHit

JSR SubVertPos
LDA Temp_Var16
CMP #$E8
BPL @Hurt

LDA Player_YVel
BMI @NoHit

LDA Objects_Y,X
SEC
SBC #28
STA Player_Y

LDA Objects_YHi,X
SBC #$00
STA Player_YHi

LDY #$00
STY Player_InAir
STY Player_YVel

LDA Player_SpriteX
CMP #16
BLT idk;@STOPRIGHTTHERECRIMINALSCUM

LDA Object_VelCarry
BPL @NoDEY  ; If platform X velocity carried, jump to PRG005_AFB8

DEY      ; Y = $FF (16-bit sign extension)

@NoDEY
CLC
ADC Player_X        ; Add carry value to Player X
STA Player_X        ; Update Player X

TYA      ; Sign extension -> 'A'
ADC Player_XHi      ; Apply carry
STA Player_XHi      ; Update Player X Hi
JMP @STOPRIGHTTHERECRIMINALSCUM						;sadly

@Hurt
JSR Player_GetHurt

@NoHit
@STOPRIGHTTHERECRIMINALSCUM
idk:
LDA Sprite_Misc_Table1,x
BNE @Draw

LDA Sprite_Misc_Timer1,x
BNE @Draw

INC Sprite_Misc_Table1,x

LDA #TimePerShootFrame		;set timer again
STA Sprite_Misc_Timer1,x	

LDA #$02
STA Objects_Frame,X

@Draw
JMP Object_ShakeAndDraw

DoShootin:
LDA Sprite_Misc_Timer1,x		;check if between frames timer is up
BNE ReKaboomba				;if not, return

LDA #TimePerShootFrame		;set timer again
STA Sprite_Misc_Timer1,x			;

INC Objects_Frame,X			;next frame
LDA Objects_Frame,X		;
CMP #$04			;check for specific frame
BNE @NoShoot			;if not the right one, don't shoot

JSR SpawnAProjectile		;spawn a projectile

@NoShoot
INC Sprite_Misc_Table1,x			;next state (frame)
LDA Sprite_Misc_Table1,x			;
CMP #$05			;
BNE ReKaboomba				;if it isn't yet time to end shooting animation, return

LDA #$00
STA Objects_Frame,X			;reset frame
STA Sprite_Misc_Table1,x			;and state

KaboombaSetTimer:
LDA #InitialSpawnTime			;\(re-)initialize timer
STA Sprite_Misc_Timer1,x			;|

ReKaboomba:
RTS

KaboombaInit:
JSR Init_FacePlayer
JMP KaboombaSetTimer

SpawnAProjectile:
LDY #$04

@Loop
;CPY SlotIndexBackup
;BEQ @Next

LDA Objects_State,y
BEQ @Spawned

@Next
DEY
BPL @Loop
RTS

@Spawned
TYA
TAX
JSR Level_PrepareNewObject
LDX SlotIndexBackup

LDA #SpawnedSprite_State
STA Objects_State,y

LDA #$ff								;this is specifically for the shell, can change or remove
STA Objects_Timer3,y

LDA Objects_FlipBits,X
STA Objects_FlipBits,y
STY $00

LDY #$00
AND #$40
BEQ @NoChange

INY

@NoChange
STY $01

LDA SpawnedShellXSpd,y
LDY $00
STA Sprite_X_Speed,y

LDA #SpawnedSprite_YSpd
STA Sprite_Y_Speed,y

LDY $01
LDA ShellXDisp,y
STA $02

LDA ShellXDispHi,y
STA $03

LDY $00
LDA Objects_X,x
CLC
ADC $02
STA Objects_X,y

LDA Objects_XHi,x
ADC $03
STA Objects_XHi,y

LDA Objects_Y,x
CLC
ADC #ShellYDisp
STA Objects_Y,y

LDA Objects_YHi,x
ADC #$FF
STA Objects_YHi,y

LDA #SpawnedSprite
STA Level_ObjectID,y

LDA Objects_SprAttr,X						;to-do: define?
STA Objects_SprAttr,y

;spawn smoke

JSR SpecialObj_FindEmptyAbort

LDA #SOBJ_POOF
STA SpecialObj_ID,y

    ; SpecialObj_Data = $1F
LDA #$1f
STA SpecialObj_Data,y

LDA Objects_X,x
CLC
ADC $02
STA SpecialObj_XLo,y

;LDA Objects_XHi,x
;ADC $03
;STA Objects_XHi,y

LDA Objects_Y,x
CLC
ADC #ShellYDisp
STA SpecialObj_YLo,y

LDA Objects_YHi,x
ADC #$FF
STA SpecialObj_YHi,y

LDA Sound_QLevel1
ORA #$08
STA Sound_QLevel1
RTS