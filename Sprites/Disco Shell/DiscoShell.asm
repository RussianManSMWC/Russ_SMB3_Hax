ObjectGroup00_InitJumpTable:
	.word DiscoShell_Init
	
ObjectGroup00_NormalJumpTable:
	.word DiscoShell
	
ObjectGroup00_CollideJumpTable:
	.word DiscoShell_Interaction
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT32 | OA1_WIDTH16					;size probably doesn't matter (16x16 regardless)
	
ObjectGroup00_Attributes2:
	.byte OA2_GNDPLAYERMOD | OA2_TDOGRP1
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE | OA3_DIESHELLED
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT6 | $4F
	
ObjectGroup00_KillAction:
    .byte KILLACT_JUSTDRAWMIRROR
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01 | OAT_BOUNCEOFFOTHERS | OAT_FIREIMMUNITY | OAT_HITNOTKILL
	
	;can probably be shorter, I just copy-pasted those from vanilla koopas
ObjPDisco:
.byte $CB, $C5, $C3, $C5, $FD, $FD, $FD, $FD, $FD, $FD, $D1, $D1, $D3, $D5

;for when it bumps into walls
DiscoShell_BumpSpeeds:
db -$20,$20

DiscoShell:

;cheat the system, draw a normal shell (drawing routine for thrown/kicked sprites)

LDA Level_ObjectID,x
PHA
LDA #OBJ_REDTROOPA
STA Level_ObjectID,x

;JSR PRG000_CCF7
;PLA
;STA Level_ObjectID,x
;JMP @Continue

@JustGFX
JSR PRG000_CD46						;dunno if more efficient than copy-pasting animation and calling 
PLA
STA Level_ObjectID,x
;RTS

LDA Player_HaltGame
BEQ DiscoShell_Continue

;turns out no init needed
DiscoShell_Init:
RTS

;I have X doubts about this working

DiscoShell_Continue:
;LDA Objects_State,x
;CMP #OBJSTATE_NORMAL				;in case it disappears offscree  (because we mess with status later on)
;BCC @Re							;(not the case anymore... maybe)

;INC Objects_Var5,X

;need some sorta timing

JSR SubHorzPos
TYA
STA Objects_Var4,x

LDA Sprite_X_Speed,x
LDY Objects_Var4,x
BNE @MoveLeft

CMP #$20
BPL @NoMore

INC Sprite_X_Speed,x
INC Sprite_X_Speed,x
JMP @NoMore

@MoveLeft
CMP #$E0
BMI @NoMore

DEC Sprite_X_Speed,x
DEC Sprite_X_Speed,x

;i'll leave like this for now...

@NoMore
;cycle through colors

LDA Counter_1
LSR
BCS @NoPal

LDA Objects_SprAttr,x				;change from pal 1 to pal 3 and back
AND #$03
CLC
ADC #$01
CMP #$04
BNE @NoOverFlow

LDA #$01							;no palette 0

@NoOverFlow
STA $00

LDA Objects_SprAttr,x
AND #$FC
ORA $00
STA Objects_SprAttr,x

;LDA Objects_SprAttr,x
;AND #$FC
;STA $00

;LDA Objects_SprAttr,x
;AND #$03
;CLC
;ADC #$01
;CMP #$04
;BNE @NoOverFlow

;LDA #$01

;@NoOverFlow
;ORA $00
;STA Objects_SprAttr,x				;whichever is more effective, too lazy to check

@NoPal

;COPY-PASTE FROM bank 0!
    TXA
    CLC
    ADC Counter_1
    LSR A
    BCC @NoSprToSprCollision  ; Semi-randomly jump to PRG000_CD46

    JSR ObjectToObject_HitTest
    BCC @NoSprToSprCollision  ; If object has not hit another object, jump to PRG000_CD46

    ; Play object-to-object collision sound
    LDA Sound_QPlayer
    ORA #SND_PLAYERKICK
    STA Sound_QPlayer

    ; Knock object in same general direction as the kicked shell object
    LDA Objects_XVel,X
    ASL A
    LDA #$10     ; A = $10
    BCC @A
    LDA #-$10    ; A = -$10
@A								;wouldve use + but it breaks sublabels
    STA Objects_XVel,Y

    LDA Objects_State,Y
    CMP #OBJSTATE_KICKED
    BNE @Ignorance  ; If the impacted object's state is not Kicked, jump to PRG000_CD36

    ; Another kicked object on the way... (slam and kill eachother)

    LDA Objects_KillTally,Y
    JSR Score_Get100PlusPts  ; Get the total score this OTHER kicked shell object earned
    JSR ObjectKill_SetShellKillVars  ; Kill our kicked object and set ShellKill variables

    ; Set X Velocity of our kicked object in the direction of the impacted object
    LDA Objects_XVel,Y
    ASL A
    LDA #$10
    BCS @AA
    LDA #-$10
@AA
    STA Objects_XVel,X

@Ignorance
    TYA
    TAX      ; X = the other object we just hit
    JSR ObjectKill_SetShellKillVars  ; Kill the impacted object and set ShellKill variables

    LDX SlotIndexBackup         ; X = object slot index (our kicked object)
    LDA Objects_KillTally,X
    INC Objects_KillTally,X     ; Increase our kicked object's kill tally...
    JSR Score_Get100PlusPtsY    ; Get points by the kill tally!  (Incidentally, Score_Get100PlusPts would work too)

@NoSprToSprCollision
JSR Object_HitTestRespond

;JSR Object_HandleBumpUnderneath				;turns out this makes player interact with the shell as normal. totally makes sense (NO!)
												;thankfully not needed, iirc SMW version can't be affected by bumping from underneath
JSR Object_Move

	LDA Objects_DetStat,X			;
	AND #$03						;
	BEQ @NoWall
	TAY
	LDA DiscoShell_BumpSpeeds-1,y
	STA Sprite_X_Speed,x

LDA Object_TileWall2
JSR Object_BumpBlocks				;thanks boom-boom for not using this routine

    LDA Sound_QPlayer
    ORA #SND_PLAYERBUMP
    STA Sound_QPlayer

@NoWall
	LDA Objects_DetStat,X			;
	AND #$04						;
	BEQ @Re
	
	JSR Object_HitGround

@Re
;Never wake up!
;LDA #$FF
;STA Objects_Timer4,X
RTS

DiscoShell_Interaction:
;JSR Object_HitTest
;BCC @NoHit

;more copy-paste job
    LDA Objects_Y,X     ; Get object's Y
    SEC
    SBC #$19       ; Subtract Temp_Var2 (height above object considered "stompable" range)
    ROL Temp_Var1       ; Stores the carry bit into Temp_Var1 bit 0
    CMP Player_Y

    PHP      ; Save CPU state (the comparison)

    LSR Temp_Var1      ; Restore the carry bit
    LDA Objects_YHi,X
    SBC #$00        ; Apply the carry bit to the Objects_YHi as needed for the height subtraction

    PLP      ; Restore CPU state (the comparison)

    SBC Player_YHi     ; Get the difference against the Player_YHi
    BMI @Hurt     ; If negative (Player_YHi > Objects_YHi, Player is lower), jump to PRG000_D20F (Object_HoldKickOrHurtPlayer)


    LDA #-$40
    STA Player_YVel

    ; Play squish sound
    LDA Sound_QPlayer
    ORA #SND_PLAYERSWIM
    STA Sound_QPlayer
	
	;no score, no stop, nothing. bounce as much as you want.

RTS

@Hurt
JMP Player_GetHurt