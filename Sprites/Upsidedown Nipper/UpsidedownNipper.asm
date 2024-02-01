;it's nipper but its upsidedown

ObjectGroup00_InitJumpTable:
	.word ObjInit_DoNothing
	
ObjectGroup00_NormalJumpTable:
	.word UpsidedownNipper
	
ObjectGroup00_CollideJumpTable:
	.word Player_GetHurt
	
ObjectGroup00_Attributes:
    .byte OA1_PAL2 | OA1_HEIGHT16 | OA1_WIDTH16
	
ObjectGroup00_Attributes2:
	.byte OA2_TDOGRP1
	
ObjectGroup00_Attributes3:
	.byte OA3_HALT_NORMALONLY | OA3_NOTSTOMPABLE
	
ObjectGroup00_PatTableSel:
	.byte OPTS_SETPT5 | $0A
	
ObjectGroup00_KillAction:
    .byte KILLACT_STANDARD
	
Object_AttrFlags:
	.byte OAT_BOUNDBOX01
	
ObjPNipper:
.byte $A1, $A3, $AD, $AF, $A5, $A7, $A9, $AB

UpsidedownNipper:
LDA Objects_FlipBits,X						;always flipped vertically
ORA #$80
STA Objects_FlipBits,X

JSR Object_DeleteOffScreen
JSR Object_ShakeAndDraw

LDA Player_HaltGame
BNE @Re

JSR Object_WorldDetectN1

LDA Objects_DetStat,X
AND #$08
BNE @OnCeiling

;apply custom gravity

JSR Object_ApplyYVel_NoLimit

LDA Objects_YVel,x
CLC
ADC #-OBJECT_FALLRATE
STA Objects_YVel,x
BPL @Interact
CMP #-OBJECT_MAXFALL
BCS @Interact

LDA #-OBJECT_MAXFALL
STA Objects_YVel,x
BNE @Interact

@OnCeiling
    LDA #$00
    STA Objects_YVel,X				;stick to ceiling

    LDA Counter_1
    LSR A
    LSR A
    AND #$02
    TAY      ; Y = 0 or 2

    JSR Object_CalcCoarseXDiff   ; Get X difference between Nipper and Player
    ;STA Temp_Var14      ; Store flip direction -> Temp_Var14
	STA Objects_FlipBits,X

    LDA Temp_Var15
    CLC
    ADC #$03
    CMP #$06
    BCS @NoJMP  ; If Player is horizontally too far away from Nipper, jump to PRG002_B1CD

    JSR Object_CalcCoarseYDiff
    LDA Temp_Var15
    BPL @NoJMP  ; If Player is above Nipper, don't jump

    INY      ; Y = 1 or 3

    ; Jump little Nipper!
    LDA #$30
    STA Objects_YVel,X

@NoJMP
TYA
STA Objects_Frame,X

@Interact
JSR Object_HitTestRespond				;hurt player

;LDA Temp_Var14
;STA Objects_FlipBits,X

@Re
RTS