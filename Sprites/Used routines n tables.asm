;Sprite flip. honestly should've been in a fixed bank (and other common sprite tables TBH)
CommonSprFlip:
.byte SPR_HFLIP, $00

;common accleration (duh)
CommonAcceleration:
db $01, -$01

;OLD 32x32 Graphics routine!!!
;this is still used by a few sprites, I'll make them use the new one. The new one is way below.
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

;standard routine to make sprite face player on init (also can be used to set speed afterwards)
Init_FacePlayer:
JSR SubHorzPos
;TYA								;why did I put TYA here???
LDA CommonSprFlip,y
STA Objects_FlipBits,X
RTS

;A NEW 32x32 GFX Routine

;32x32 sprite graphic routine (improvedTM)
;input A as sprite tile table high byte
;input Y as sprite tile table low byte
;sprite tile table is ordered like so (assuming not horizontally flipped, flip is handled automatically):
;first 4 bytes are bottom tiles from left to right, last 4 bytes are top tiles from left to right

;output TEMP_SpriteTileSlot is starting sprite tile slot for the first 6 sprite tiles
;output TEMP_SpriteTileSlotInLoop is the starting sprite tile slot for the remaining 2 sprite tiles (two rightmost/leftmost depending on facing)

TEMP_XFlipBit = Temp_Var3
TEMP_SpriteTileSlotInLoop = Temp_Var9
TEMP_SpriteTileSlot = Temp_Var10
TEMP_VerticalVis = Temp_Var12
TEMP_HorizontalVis = Temp_Var13
TEMP_SpriteTileSlot = Temp_Var14
TEMP_TileTablePointer = Temp_Var15		;2 bytes

General32x32GFX:
STA TEMP_TileTablePointer			;save sprite tile image pointer
STY TEMP_TileTablePointer+1			;

LDA Objects_Frame,X
ASL
ASL
ASL						;*8 to get a proper frame
;STA TEMP_TileTableOffset			;tile offset
CLC
ADC TEMP_TileTablePointer
STA TEMP_TileTablePointer

LDA TEMP_TileTablePointer+1
ADC #$00
STA TEMP_TileTablePointer+1

JSR Object_ShakeAndCalcSprite
STY TEMP_SpriteTileSlot				;save the sprite tile slot

LDA Temp_Var8					;
STA TEMP_HorizontalVis				;horizontal visibility

LDA TEMP_XFlipBit				;reorder sprite tiles is the sprite is horizontally flipped
BEQ @NoFlippedX

LDX #$00
BEQ @Loop

@NoFlippedX
LDX #$03

@Loop
STY TEMP_SpriteTileSlotInLoop
ASL TEMP_HorizontalVis						;if horizontally offscreen (both tpo and bottom are at the same pos)
BCS @Next							;skip this pair

LDA Temp_Var5							;restore vertical visibility
STA TEMP_VerticalVis						;

LDA Temp_Var1
LSR TEMP_VerticalVis
BCS @TopOffscreen						;if the top tile is vertically offscreen, try drawing a bottom one
STA Sprite_RAM+$00,Y						;set upper sprite Y

TXA
CLC
ADC #$04							;top sprite tile
TAY
LDA (TEMP_TileTablePointer),y
LDY TEMP_SpriteTileSlotInLoop
STA Sprite_RAM+$01,Y

@TopOffscreen
LDA Temp_Var1
LSR TEMP_VerticalVis
BCS @Next  							;if the bottom one is vertically off-screen, don't draw

ADC #$10
STA Sprite_RAM+$04,Y

TXA
TAY
LDA (TEMP_TileTablePointer),y
LDY TEMP_SpriteTileSlotInLoop
STA Sprite_RAM+$05,Y

LDA Temp_Var4
ORA TEMP_XFlipBit
STA Sprite_RAM+$02,Y						;properties (palette and flip and stuff)
STA Sprite_RAM+$06,Y						;whatever, lets set for both even if one of them is offscreen (less space that way)

LDA Temp_Var2
STA Sprite_RAM+$03,Y
STA Sprite_RAM+$07,Y						;x-pos

@Next
LDA Temp_Var2
CLC
ADC #$08
STA Temp_Var2							;+8 for the next pair

TYA
CLC
ADC #$08							;next couple of slots
TAY

LDA TEMP_XFlipBit						;draw in a different order if the image is horizontally flipped
BNE @DifferentCountdown

DEX
BEQ @RandStuff
BPL @Loop
BMI @End

@DifferentCountdown
INX
CPX #$03
BEQ @RandStuff
CPX #$04
BNE @Loop

@End
LDX SlotIndexBackup
RTS

@RandStuff
JSR Object_GetRandNearUnusedSpr					;need to grab a couple more random sprite tile slots to finish the image
;STY TEMP_SpriteTileSlotInLoop
JMP @Loop