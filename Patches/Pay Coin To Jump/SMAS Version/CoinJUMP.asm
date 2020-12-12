org $23CAC2
autoclean JML SPENDCOIN
Continue:

freecode

SPENDCOIN:
STA $00
BEQ .NoJump

LDX #$00
LDA $0726
BEQ .Mario

LDX #$23

.Mario
LDA $1DA2,x			;coin counter
BEQ .PreNoJump

DEC $1DA2,x
JML Continue

.PreNoJump
LDA #$2A
STA $1203			;sound effect (wrong!)

.NoJump
JML $23CB2A