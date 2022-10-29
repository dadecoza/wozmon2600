    PROCESSOR 6502
    INCLUDE "vcs.h"
    include  "macro.h"
    ORG $F080
    LDY #0
next
    LDA message,y
    jsr $f902
    INY
    CPY #15
    bne next
    rts
message
    BYTE #$0D + #$80
    BYTE #$0A + #$80
    BYTE #"H" + #$80
    BYTE #"E" + #$80
    BYTE #"L" + #$80
    BYTE #"L" + #$80
    BYTE #"O" + #$80
    BYTE #" " + #$80
    BYTE #"W" + #$80
    BYTE #"O" + #$80
    BYTE #"R" + #$80
    BYTE #"L" + #$80
    BYTE #"D" + #$80
    BYTE #$0A + #$80
    BYTE #$0D + #$80