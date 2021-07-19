ObjectGroup00_InitJumpTable:
	.word JetPack_Init
	
ObjectGroup00_NormalJumpTable:
	.word JetPack
	
ObjectGroup00_CollideJumpTable:
	.word ObjHit_DoNothing
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT32 | OA1_WIDTH8					;only palette matters
	
ObjectGroup00_Attributes2:
	.byte OA2_NOSHELLORSQUASH | OA2_TDOGRP1
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDART
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX00 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL 
	
;ObjP:
;this doesnt' matter at all, can be anything

JetPack_Tile = $AD

JetPack_FuelDecayTime = $10

JetPack_NumberTiles:
db $B5,$B3,$B1,$AF

JetPack_MaxFuel = $03					;this value means 0, which means no more fuel. if you wish to add more, don't forget JetPack_NumberTiles

JetPack:
LDY #$02+8
LDA Player_FlipBits
STA Objects_FlipBits,x					;flip sprite with player
AND #$40
BEQ @Diff
LDY #-$02								;and also x-disposition related to the player

@Diff
TYA
STA Temp_Var1
CLC
ADC Player_X
STA Objects_X,x

LDY #$00
LDA Temp_Var1
BPL @Shiz
DEY
@Shiz
TYA
ADC Player_XHi
STA Objects_XHi,x

;get the player's size
LDA Player_Y
STA Objects_Y,x

LDA Player_YHi
STA Objects_YHi,x

LDA Player_Suit
BEQ @Draw

LDA Player_IsDucking
BNE @Draw								;fits fine when ducking

LDA Player_Statue						;don't displace anyway if in statue mode
BNE @Draw

;displace if big
LDA Objects_Y,x
SEC
SBC #$08
STA Objects_Y,x

LDA Objects_YHi,x
SBC #$00
STA Objects_YHi,x

@Draw
;unfortunately my jetpack is of non-standart size - 8x32.
    JSR Object_ShakeAndCalcSprite

    LDA Temp_Var8  ; Testing bit 7 of horizontal sprite visibility
    BMI @NotVisi ; If bit 7 is set (this sprite is horizontally off-screen), jump to PRG000_D68E

    LDA Temp_Var4			;kinda w/e tbh
	STA Sprite_RAM+$02,Y     ; Store into both sprite's attributes (don't care for horizontal flip for number
    ORA Temp_Var3       ; Joins base attributes to H-flip flag
    STA Sprite_RAM+$06,Y     ; Store into both sprite's attributes

    LDA Temp_Var5  ; Check sprite vertical visibility
    LSR A       ; Shift right (checking lowest bit)
	STA Temp_Var5
    BCS @TryAnother ; If this bit is set, this sprite piece is invisible, jump to PRG000_D6C6 (RTS)

    LDA Temp_Var1  ; Get sprite Y
    STA Sprite_RAM+$00,Y     ; Otherwise, OK to set sprite Y
	
	LDA Temp_Var2      ; Get sprite X
    STA Sprite_RAM+$03,Y
	
	;set the sprite tile later
	
@TryAnother
    ;LDA Temp_Var1  ; Get sprite Y
	;CLC
	;ADC #$10
	;STA Temp_Var1
	
	LDA Temp_Var5
	LSR
	BCS @NotVisi
	
	LDA Temp_Var1
	CLC
	ADC #$10
	STA Sprite_RAM+$04,Y

	LDA Temp_Var2      ; Get sprite X
    STA Sprite_RAM+$07,Y
	
	LDA #JetPack_Tile
	STA Sprite_RAM+$05,Y

@NotVisi
LDX SlotIndexBackup
STY Temp_Var1
LDY Objects_Var11,x							;fuel state
LDA JetPack_NumberTiles,y
LDY Temp_Var1
STA Sprite_RAM+$01,Y

LDA Player_HaltGame
BNE @Re

;check for air and stuff

LDA Objects_Var10,x						;flag for jetpack activation
BNE @CanKeep

LDA Player_InAir						;player in air?
BEQ @Re

LDA Player_YVel							;must hit downard speed first to activate
BMI @Re

INC Objects_Var10,x						;now can activate jetpack

@SetTime
LDA #JetPack_FuelDecayTime
STA Objects_Var12,x						;manual timer
RTS

@CanKeep
LDA Player_InAir						;must be airborn to use jetpack
BEQ @NoMore								;bad news - doesn't work with solid platform sprites. most likely slot related. (to-do: add a check for if player's on platform? more copy-pasta work)

LDA Objects_Var11,x						;ran out of fuel = return
CMP #JetPack_MaxFuel
BEQ @Re

LDA Pad_Holding							;holding A?
BPL @Re									;if not, return

;spawn smoke plz
LDA Counter_1							;spawn smoke every few frames if the player's holding the button
AND #$0F
BNE @NoSmoke

JSR JetPack_SpawnSmoke

@NoSmoke
LDA Objects_Var12,x						;timer zero?
BNE @Count								;if not, keep counting

INC Objects_Var11,x						;next fuel value
JSR @SetTime							;slightly less space and thats about it
;LDA #JetPack_FuelDecayTime
;STA Objects_Var12,x	
BNE @NoCount

@Count
DEC Objects_Var12,x						;timer--

@NoCount
LDA Player_HitCeiling					;prevent player from clipping through blocks (like activated ?-blocks)
BNE @KeepZero

LDA Player_YVel
BPL @DoDifferent
CMP #$C0								;max upward speed
BCC @Set

@Do
LDA Player_YVel
SEC
SBC #$05								;acceleration (kinda beats natural gravity?)
STA Player_YVel

@Re
RTS

@NoMore
STA Objects_Var10,x
STA Objects_Var11,x						;reset back to 3
RTS

@Set
LDA #$C0								;always stay at max
STA Player_YVel							;
RTS

@DoDifferent
Lda #$EA
STA Player_YVel
;LDA Player_YVel
;SEC
;SBC #$1A							;man, is downward speed heavy!
;STA Player_YVel
RTS

@KeepZero
LDA #$20							;give player enough downward speed to cancel next Y-speed setting (since it becomes positive it'll change to @DoDifferent value)
STA Player_YVel

JetPack_Init:
RTS

JetPack_SpawnSmoke:
JSR SpecialObj_FindEmptyAbort

    LDA Objects_X,X
    CLC
    ADC #$F8+4
    STA SpecialObj_XLo,Y

    LDA Objects_Y,X
    CLC
    ADC #$20
    STA SpecialObj_YLo,Y
	
    LDA Objects_YHi,X
    ADC #$00
    STA SpecialObj_YHi,Y

LDA #SOBJ_POOF
STA SpecialObj_ID,Y

    LDA #$1f
    STA SpecialObj_Data,Y
	RTS