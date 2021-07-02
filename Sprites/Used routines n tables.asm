;Sprite flip. honestly should've been in a fixed bank (and other common sprite tables TBH)
CommonSprFlip:
.byte SPR_HFLIP, $00

;common accleration (duh)
CommonAcceleration:
db $01, -$01

;X-positions for 32x32 graphic routine
Common32x32TilePos:
db $00,$08,$10,$18,$10,$08,$00

;32x32 sprite graphic routine
;there was no such routine for common use so i had to code it myself.
;it's a little buggy (sometimes sprite tiles seem to wrap, even though i thought that was fixed) and flicker (uses other sprite tiles. maybe Object_GetRandNearUnusedSpr could've been helpful here but IDK)
;i had to code it with a bit of trial and error but nonetheless i'm satisfyed that it functions. feel free to propose different solution.
;INPUT:
;Pushed A 1 - Table location to grab sprite tiles from, low byte
;Pushed A 2 - Table location to grap sprite tiles from, high byte

General32x32GFXRoutine:
LDA Objects_Frame,X
ASL
ASL
ASL
STA Temp_Var9

JSR Object_ShakeAndCalcSprite

PLA
STA Temp_Var7
PLA
STA Temp_Var6

LDA #$00
LDX Temp_Var3
BNE @NoFlip

LSR Temp_Var8
LSR Temp_Var8
LSR Temp_Var8
LSR Temp_Var8

LDA #$03

@NoFlip
STA Temp_Var11
STA Temp_Var12

LDA Temp_Var8					; save horz visibility
STA Temp_Var15     				; Horizontal visibility -> Temp_Var15

LDX #$07     ; X = 6

@drawloop
CPX #$03
BNE @NoAddition

LSR Temp_Var5					;check low row

LDA Temp_Var8					;back to leftmost sprite
STA Temp_Var15					;

LDA Temp_Var1					;low row
CLC
ADC #$10
STA Temp_Var1					;yeah, low row

;LDA Temp_Var2					;actual X-position
;STA Temp_Var10

LDA Temp_Var12
STA Temp_Var11

@NoAddition
LDA Temp_Var3
BEQ @ShiftOther

ASL Temp_Var15
BCS @OffscreenHorz				;why bother if it's offscreen vertically
BCC @Do

@ShiftOther
LSR Temp_Var15
BCS @OffscreenHorz

@Do
LDA Temp_Var5
STA Temp_Var14

LDA Temp_Var1
LSR Temp_Var14
BCS @OffscreenVert

STA Sprite_RAM+$00,Y

@OffscreenHorz
@OffscreenVert
STY Temp_Var16
TXA
CLC
ADC Temp_Var9
TAY
;LDA GiantEerieTiles,y
LDA (Temp_Var6),y
LDY Temp_Var16
STA Sprite_RAM+$01,y

;LDA #SPR_PAL1
LDA Temp_Var4
ORA Temp_Var3					;flip sprite
STA Sprite_RAM+$02,y

LDA Temp_Var2
LDY Temp_Var11
CLC
ADC Common32x32TilePos,y
LDY Temp_Var16
STA Sprite_RAM+$03,y

INC Temp_Var11

;JSR Object_GetRandNearUnusedSpr

INY
INY
INY
INY

DEX
BPL @drawloop

LDX SlotIndexBackup
RTS

;Common 2-frame animation routine
;Input A - how many frames it takes to change frame animate

CommonAnimate:
STA Temp_Var1
LDA Sprite_Misc_Timer1,x
BNE @Meh

LDA Objects_Frame,X
EOR #$01
STA Objects_Frame,X
	
LDA Temp_Var1
STA Sprite_Misc_Timer1,x

@Meh
RTS

;standart routine to make sprite face player on init (also can be used to set speed afterwards)
Init_FacePlayer:
JSR SubHorzPos
;TYA								;why did I put TYA here???
LDA CommonSprFlip,y
STA Objects_FlipBits,X
RTS