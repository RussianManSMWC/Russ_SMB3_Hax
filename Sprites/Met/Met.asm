ObjectGroup00_InitJumpTable:
	.word MetInit
	
ObjectGroup00_NormalJumpTable:
	.word MetMain
	
ObjectGroup00_CollideJumpTable:
	.word Player_GetHurt
	
ObjectGroup00_Attributes:
	.byte OA1_PAL3 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_KillAction:
    .byte KILLACT_JUSTDRAW16X16
	
ObjectGroup00_Attributes2:
	.byte OA2_NOSHELLORSQUASH | OA2_TDOGRP1
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01 | OAT_FIREIMMUNITY

ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_Attributes3:	
	.byte OA3_HALT_NORMALONLY

ObjPMet:
db $89,$8B				;walk 1/stand still
db $A5,$A7				;walk 2
db $85,$87				;hide
	
MetShootTimer = $30		;how long it takes to start walking, fireball is in between
MetWhenShoot = $18		;when spawn fireball
MetWalkTimer = $50		;how long it walks

Met_DelayTime = $1F		;how long it takes after walking to check proximity again

Met_FireballXOffset:
db $00,$08

Met_FireballXSpd:
db -$10,$10

Met_FireballYOffset = $04

Met_XSpd:
db -$10,$10
	
MetMain:
JSR SubOffScreen				;offscreen begone
JSR Object_ShakeAndDraw			;shake and draw, as you can see (what is this, milkshake?)

LDA Player_HaltGame				;don't do whatever
BNE Met_Return					;

JSR Player_HitEnemy				;collide with player (always)

JSR Object_Move					;move (always have at least Y-speed (gravity))

LDA Objects_DetStat,X			;
AND #$04						;
BEQ @NoFloorHit					;
	
JSR Object_HitGround			;stay grounded

@NoFloorHit
LDA Objects_Var5,x				;hmm, what to do...
JSR DynJump						;

dw Wait							;wait for the player?
dw WaitNShoot					;shoot fireball and wait a little?
dw Walk							;walk? so many options, man!

Wait:
;check proximity
LDA Objects_Timer,x
BNE @Return

JSR SubHorzPos					;check which side the player's on
LDA $0F							;
CLC								;
ADC #$50						;
CMP #$A0						;
BCS @Return						;

LDA #MetShootTimer				;set wait timer
STA Objects_Timer,x				;

LDA #$00						;show up, coward!
STA Objects_Frame,X				;

INC Objects_Var5,x				;next state

@Return
Met_Return:
RTS								;

WaitNShoot:
LDA Objects_Timer,x				;next phase when 0
BEQ @NextPhase					;
CMP #MetWhenShoot				;shoot at a certain point
BNE @Return						;

@ShootFire
;spawn a fireball

JSR Met_GetHorzDir				;horizontal direction

LDA Met_FireballXOffset,y		;set fireball position based on facing.
STA $00							;

LDA Met_FireballXSpd,y			;and speed
STA $01							;

;i think i copy-pasted this from venus or something.
LDY #$03     						; Y = 3
JSR SpecialObj_FindEmptyAbortY   	; Find an empty slot from special object slot 0 to 3 or don't come back!

    ; Set X offset
LDA Objects_X,X
CLC
ADC $00
STA SpecialObj_XLo,Y

    ; Set Y offset
LDA Objects_Y,X
CLC
ADC #Met_FireballYOffset
STA SpecialObj_YLo,Y

LDA Objects_YHi,X
ADC #$00
STA SpecialObj_YHi,Y

    ; Piranha fireball
    LDA #SOBJ_PIRANHAFIREBALL
    STA SpecialObj_ID,Y
	
	LDA $01
	STA SpecialObj_XVel,Y
	
LDA #$00				;no why-speed
STA SpecialObj_YVel,Y
	
	;sound effect ofc
	
LDA Sound_QPlayer
ORA #SND_PLAYERFIRE
STA Sound_QPlayer	
	
@Return
RTS

@NextPhase
INC Objects_Var5,x			;next state

LDA #MetWalkTimer			;how long to walk
STA Objects_Timer,x			;

JSR Met_GetHorzDir			;get facing

LDA Met_XSpd,y				;walk towards the player
STA Objects_XVel,X			;
RTS							;

Walk:
LDA Level_NoStopCnt			;change walking frame every few frames
AND #$0F					;
BNE @NoChange				;

;LDA #$10
;JSR CommonAnimate

LDA Objects_Frame,X
EOR #$01
STA Objects_Frame,X

@NoChange
LDA Objects_DetStat,X		;wall? face away!
AND #$03
BEQ @NoWall
	
JSR Object_AboutFace

@NoWall
LDA Objects_Timer,x
BNE @Return

LDA #$00
STA Objects_Var5,x					;reset state
STA Objects_XVel,X					;No X-spd

LDA #Met_DelayTime
STA Objects_Timer,x
BNE MetInit							;Met_DelayTime != 0
;JMP MetInit						;face player and set frame again

@Return
RTS

MetInit:
;LDA #MetShootTimer
;STA Objects_Timer,x
LDA #$02							;show as stationary
STA Objects_Frame,x					;

JMP Init_FacePlayer					;assuming Init_FacePlayer is far, can use BNE if not

Met_GetHorzDir:
LDY #$00
LDA Objects_FlipBits,x
AND #$40
BEQ @NOO
INY

@NOO
RTS
