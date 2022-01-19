ObjectGroup00_InitJumpTable:
	.word Pakatto_Init
	
ObjectGroup00_NormalJumpTable:
	.word Pakatto
	
ObjectGroup00_CollideJumpTable:
	.word Pakatto_Interaction
	
ObjectGroup00_Attributes:
    .byte OA1_PAL1 | OA1_HEIGHT32 | OA1_WIDTH24
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP2 | OA2_STOMPDONTCARE
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_TAILATKIMMUNE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | 15
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDART
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX13 | OAT_WEAPONIMMUNITY | OAT_FIREIMMUNITY | OAT_HITNOTKILL
	
ObjPPakatto:
db $81,$83,$85,$A1,$A3,$A5
db $81,$83,$85,$A7,$A9,$A5
db $8B,$8D,$8F,$AB,$AD,$AF

;facing depending on x-pos
Pakatto_Init:
LDA Sprite_X_Position,x
AND #$10
ASL										;10X2 = 20
ASL										;20X2 = 40
STA Objects_FlipBits,x
RTS

Pakatto_IdleTime = $50					;how long before opening then shooting
Pakatto_OpeningTime = $04				;for how long does it display opening frame
Pakatto_ClosingTime = $40				;how long does it stay open
Pakatto_ShootingTime = $20				;when to shoot when open

Pakatto_FireballXOffset:
db $00,$10

Pakatto_FireballXSpd:
db -$10,$10

Pakatto_FireballYOffset = $0D

Pakatto_TilesetOffset:
db $00, $06,$0C

Pakatto:
JSR SubOffScreen

;big bertha method
;INC Objects_Frame,X
JSR Object_ShakeAndCalcSprite
STY Temp_Var9


;LDX SlotIndexBackup
;    LDA Objects_Frame,X
;    DEC Objects_Frame,X  ; Big Bertha's frame--
;    ASL A
;    ASL A           ; Multiply by 4
;    CLC
;    ADC Temp_Var6       ; Add to starting tile
;    STA Temp_Var6       ; Set as starting tile
;    TAX      ; Starting tile -> 'X'

LDX SlotIndexBackup
LDA Objects_Frame,x
TAX
LDY ObjGroupRel_Idx
LDA Pakatto_TilesetOffset,x
CLC
ADC ObjectGroup_PatternStarts,Y
STA Temp_Var6
TAX

LDY Temp_Var9

    ;LDX SlotIndexBackup         ; X = object slot index

    JSR Object_Draw24x16Sprite ; Draw upper half of Big Bertha




    ; Sprite_RAM offset += 12 (3 sprites ahead)
    TYA
    CLC
    ADC #$0c
    TAY

    LDX Temp_Var6   ; X = starting tile

    INX
    INX
    INX

    ; Sprite Y += 16 (lower half of Big Bertha)
    LDA #16
    CLC
    ADC Temp_Var1
    STA Temp_Var1
    JSR Object_Draw24x16Sprite ; Draw lower half of Pakatto

    LDX SlotIndexBackup         ; X = object slot index
	
	;GFX over!
	
	LDA Player_HaltGame
	BNE @Re

;Interaction!!!
JSR Object_HitTestRespond

LDA Sprite_Misc_Table1,x
JSR DynJump
dw @Wait
dw @Opening
dw @Shooting

@Re
RTS

@Wait
LDA Sprite_Misc_Timer2,x
BNE @Re

LDA #Pakatto_OpeningTime

@SetTime
STA Sprite_Misc_Timer2,x

INC Objects_Frame,x
;INC Objects_Frame,x

INC Sprite_Misc_Table1,x
RTS

@Opening
LDA Sprite_Misc_Timer2,x
BNE @Re

LDA #Pakatto_ClosingTime
BNE @SetTime

@BecomeNormal
STA Objects_Frame,x
STA Sprite_Misc_Table1,x

LDA #Pakatto_IdleTime
STA Sprite_Misc_Timer2,x
RTS

@Shooting
LDA Sprite_Misc_Timer2,x
BEQ @BecomeNormal
CMP #Pakatto_ShootingTime
BNE @Re

;shoot a fireball!

LDY #$00
LDA Objects_FlipBits,x
AND #$40
BEQ @NOO
INY

@NOO
LDA Pakatto_FireballXOffset,y		;set fireball position based on facing.
STA $00							;

LDA Pakatto_FireballXSpd,y			;and speed
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
ADC #Pakatto_FireballYOffset
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
RTS

Pakatto_Interaction:
    LDA Objects_Y,X     ; Get object's Y
    SEC
    SBC #$10       ; Subtract Temp_Var2 (height above object considered "stompable" range)
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