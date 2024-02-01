ObjectGroup00_InitJumpTable:
	.word MontyMole_Init
	
ObjectGroup00_NormalJumpTable:
	.word MontyMole
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL3 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_NOSHELLORSQUASH | OA2_TDOGRP1
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_JUSTDRAW
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01
	
ObjPMontyMole:
db $8D,$8F
db $81,$83
db $85,$87
db $89,$8B

;Sprite_Misc_Table2 - chasing or not
;Sprite_Misc_Table5 - pointer

;GFX:
;Frame 0 - mole hill
;frame 1 - mole out
;frame 2 - mole 1
;frame 3 - mole 2

MontyMole_ChasingXSpd:
.byte $18,-$18

MontyMole_HillTime = $68

MontyMole_JumpOutYSpd = $B0

MontyMole_HopYSpd = $E0

MontyMole_HopeTime = $50

MontyMole_HoppingXSpd:
db $10,-$10

MontyMole:
JSR Object_DeleteOffScreen

LDA Sprite_Misc_Table5,x
JSR DynJump

;check proximity

dw MontyMole_WaitForPlayer
dw MontyMole_Hill
dw MontyMole_JumpOut
dw MontyMole_IsOut

MontyMole_WaitForPlayer:
	;JSR Object_AnySprOffscreen			;offscreen check i forgor
	;BNE @Return

	JSR Object_DetermineHorzVis

	LDA Objects_SprHVis,X
	BNE @Return

    JSR Level_ObjCalcXDiffs

    LDA Temp_Var16					;check if close enough
    CLC
    ADC #$60
    CMP #$C0
    BCS @Return
	
	INC Sprite_Misc_Table5,x
	
	LDA #MontyMole_HillTime
	STA Sprite_Misc_Timer1,x

@Return
	;don't need to draw the sprite, hopefully (cuz it's invisible rn)
	RTS
	
MontyMole_Hill:
	;probably don't need freeze flag check because it depends on misc timer (which only decreases if it;s false)
	LDA Sprite_Misc_Timer1,x
	BNE @Animate
	
	INC Sprite_Misc_Table5,x
	
	LDA #MontyMole_JumpOutYSpd
	STA Sprite_Y_Speed,x
	
	JSR Init_FacePlayer
	
	JSR SpawnBrickPieces
	
	LDX SlotIndexBackup         ; X = object slot index
	LDA Sound_QLevel2
    ORA #SND_LEVELCRUMBLE
    STA Sound_QLevel2
	
	;LDA #$02
	;STA Objects_Frame,X
	INC Objects_Frame,X						;frame 1
	BNE @GFX
	
@Animate
	LDA Counter_1
	LSR
	LSR
	LSR
	LSR
	AND #$01
	TAY
	LDA CommonSprFlip,y
	STA Objects_FlipBits,X
	
	JSR Object_FlipFace
	
@GFX
	JMP Object_ShakeAndDraw
	
MontyMole_JumpOut:
	LDA Player_HaltGame
	BNE @GFX
	
	JSR Player_HitEnemy				;remember which one to use...
	
	JSR Object_Move
	
	LDA Objects_DetStat,X			;
	AND #$04						;
	BEQ @GFX
	
	JSR Object_HitGround
	
	INC Sprite_Misc_Table5,x
	
	INC Objects_Frame,X					;frame 2

@GFX
	JMP Object_ShakeAndDraw
	
MontyMole_IsOut:
	LDA Player_HaltGame
	BNE @GFX
	
	LDA Sprite_Misc_Table2,x
	BNE @Hopping
	
;it's chasing then...

	JSR SubHorzPos					;face player
	
	LDA CommonSprFlip,y				;
	STA Objects_FlipBits,X			;
	
	LDA RandomN,X
	LSR
	BCC @ActNormal
	
	LDA Sprite_X_Speed,X				;set speed
	CMP MontyMole_ChasingXSpd,y				;cap speed
	BEQ @ActNormal					;
	CLC						;add acceleration to speed
	ADC CommonAcceleration,y			;
	STA Sprite_X_Speed,X				;store speed
	JMP @ActNormal

@Hopping
	LDA Sprite_Misc_Timer1,x
	BNE @ActNormal
	
	LDA #MontyMole_HopeTime
	STA Sprite_Misc_Timer1,x
	
	LDA #MontyMole_HopYSpd
	STA Sprite_Y_Speed,x
	
	LDY #$00
	LDA Objects_FlipBits,X
	;AND #$40					;don't need AND probably
	BNE @Speed
	
	INY
	
@Speed
	LDA MontyMole_HoppingXSpd,y
	STA Sprite_X_Speed,x

@ActNormal
	LDA Counter_1
	AND #$07
	BNE @NoFrame
	
	LDA Objects_Frame,X
	EOR #$01						;either 4 or 3 (because we set it to be 3 beforehand, those bits would reset)
	STA Objects_Frame,X

@NoFrame
	JSR Player_HitEnemy

	JSR Object_Move
	
	LDA Objects_DetStat,X			;
	AND #$04						;
	BEQ @NoGround
	
	JSR Object_HitGround
	
@NoGround
	LDA Objects_DetStat,X			;
	AND #$03
	BEQ @GFX
	
	JSR Object_FlipFace				;this doesn't matter for chasing one
	
	LDA Sprite_X_Speed,x			;this doesn't matter for hopping one (maybe can optimize...)
	JSR Negate
	STA Sprite_X_Speed,x


@GFX
	JMP Object_ShakeAndDraw

MontyMole_Init:
JSR Init_FacePlayer

	LDA Sprite_X_Position,x
	AND #$10
	STA Sprite_Misc_Table2,x
	RTS

MontyMole_BrickPieceYOffset:  .byte -$04, -$04, $04, $04
MontyMole_BrickPieceYHiOffset:    .byte  $FF,  $FF, $00, $00

MontyMole_BrickPieceXOffset:  .byte 00, 08, 00, $08

MontyMole_YSpd:  .byte $C0, $C0, $D0, $D0
MontyMole_XSpd:  .byte $F8, $08, $F8, $08

    ; Generates a segment of the busted brick (or microgoomba in the case of the Piledriver)
SpawnBrickPieces:
	LDA #$03
	STA Temp_Var16

@Loop
    LDY #$07     ; Y = 7 (wider expanse of special object slots)

    JSR SpecialObj_FindEmptyAbortY   ; Find an empty special object slot or don't come back here...

    ; Temp_Var1 = Ice Block's Y
    LDA Objects_Y,X
    STA Temp_Var1

    ; Temp_Var3 = Ice Block's Y Hi
    LDA Objects_YHi,X
    STA Temp_Var3

    ; Temp_Var2 = Ice Block's X
    LDA Objects_X,X
    STA Temp_Var2

    ; X = Temp_Var16 (input value for Ice Block)
    LDX Temp_Var16
	
	; X Lo = Temp_Var2
    LDA Temp_Var2
	CLC
	ADC MontyMole_BrickPieceXOffset,x
    STA SpecialObj_XLo,Y
	BCS @NoPiece							;check if offscreen

    ; Add Y offset by input
    LDA Temp_Var1
    CLC
    ADC MontyMole_BrickPieceYOffset,x
    STA SpecialObj_YLo,Y
	
    LDA Temp_Var3
    ADC MontyMole_BrickPieceYHiOffset,x
    STA SpecialObj_YHi,Y

    ; Set Ice Block Y Velocity by input
    LDA MontyMole_YSpd,X
    STA SpecialObj_YVel,Y

    ; Set Ice Block X Velocity by input
    LDA MontyMole_XSpd,X
    STA SpecialObj_XVel,Y

    LDA #SOBJ_BRICKDEBRIS    ; Busting brick, input value 4 only
    STA SpecialObj_ID,Y  ; Set appropriate ID

    LDA #$ff
    STA SpecialObj_Data,Y

    LDA #$00
    STA SpecialObj_Timer,Y
	
@NoPiece	
	LDX SlotIndexBackup
	
	DEC Temp_Var16     ; Temp_Var16--
    BPL @Loop
	RTS