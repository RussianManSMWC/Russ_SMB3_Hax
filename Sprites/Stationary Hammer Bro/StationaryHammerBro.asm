;Super Mario World Hammer Bro But It's Stationary

ObjectGroup00_InitJumpTable:
	.word ObjInit_DoNothing
	
ObjectGroup00_NormalJumpTable:
	.word SMWHammerBroStationary
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    	.byte OA1_PAL3 | OA1_HEIGHT32 | OA1_WIDTH32
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP5 | OA2_NOSHELLORSQUASH
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_KillAction:
    	.byte KILLACT_NORMALSTATE

Object_AttrFlags:
	.byte OAT_BOUNDBOX11
	
ObjPGFX:
;DoesntMatter

;code here

SMWBro_ThrowTime = $30

SMWBro_YSpd = -$30

SMWBroTiles:
db $97,$95,$93,$91,$9F,$9D,$9B,$71

SMWHammerBro_HammerXDisp:
db -$08,$18

SMWHammerBro_HammerXVel:
db -$0A, $0A

SMWHammerBroStationary:
JSR SubOffScreen

LDA #$00							;fixes glitchy gfx when dead
STA Objects_Frame,X					;

LDA #<SMWBroTiles
LDY #>SMWBroTiles
JSR General32x32GFX					;display aesthetics

LDA Player_HaltGame
BNE @Re

LDA Objects_State,X
CMP #OBJSTATE_NORMAL
BNE @Dead						;doesnt do jack when dead

LDA Objects_Y,X
PHA
CLC
ADC #$10						;offset position so its hitbox is at its body
STA Objects_Y,X

LDA Objects_YHi,x
PHA
ADC #$00
STA Objects_YHi,x

LDA Objects_SpriteY,x
PHA
CLC
ADC #$10
STA Objects_SpriteY,x

JSR Player_HitEnemy
;JSR Object_WorldDetectN1					;doesnt quite work (doesnt work for both tiles underneath + glitchy gfx when dead)
;JSR Object_HandleBumpUnderneath

PLA
STA Objects_SpriteY,x
PLA
STA Objects_YHi,x
PLA
STA Objects_Y,X

;throw hammers and flip.
LDA Objects_Timer,x
BNE @Re

LDA Objects_FlipBits,x						;flip horizontally
EOR #$40
STA Objects_FlipBits,x

LDA #SMWBro_ThrowTime
STA Objects_Timer,x

LDA Sprite_Misc_Table1,x					;flipped facing (so that the hammer spawns correctly)
EOR #$01
STA Sprite_Misc_Table1,x

;spawn hammers

    LDA Objects_SprHVis,X
    BNE @Re  ; If any sprite is horizontally off-screen, jump to PRG004_A61B (RTS)

    LDY #$05     ; Y = 5
@Loop
    LDA SpecialObj_ID,Y
    BEQ @Run  ; If this Special Object slot is empty, jump to PRG004_A5F6

    DEY      ; Y--
    BPL @Loop  ; While Y >= 0, loop!
@Re
    RTS      ; Return

@Dead
;JSR Object_ApplyYVel
JMP Object_Move

@Run
    STY Temp_Var1       ; Temp_Var1 = Special Object slot index
	
    ; Set Hammer X/Y at Hammer Bro's position
	LDY Sprite_Misc_Table1,x
    LDA Objects_X,X
	CLC
	ADC SMWHammerBro_HammerXDisp,y
	PHA
    
	LDA SMWHammerBro_HammerXVel,Y   ; Hammer towards Player X Vel
    LDY Temp_Var1       ; Y = Special Object slot index
    STA SpecialObj_XVel,Y    ; Set X Velocity
	
	PLA
	STA SpecialObj_XLo,Y
	
    LDA Objects_Y,X
	CLC
	ADC #$08
    STA SpecialObj_YLo,Y
	
    LDA Objects_YHi,X
    STA SpecialObj_YHi,Y

    ; Hammer Y velocity = -$30
    LDA #SMWBro_YSpd
    STA SpecialObj_YVel,Y

    LDA #SOBJ_HAMMER ; Hammer Bro hammer
	STA SpecialObj_ID,Y
RTS