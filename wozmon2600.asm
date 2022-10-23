;-------------------------------------------------------------------------
;
;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak 1976
;
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;   Atari 2600 Port
;
;   1200,n,8,1 TTL output.
;   
;   View from back of Atari 2600
;     TX
;     | +- RX
;     | | 
;     o o o o o                        o o o o o
;      o o o o                          o o o o 
;          |
;          GND
;
;   TX -> PA0
;   RX -> PA1
;
;   
;   Cart Memory map
;   F000-F3FF RAM Read
;   F400-F7FF RAM Write
;   F800-FFFF ROM
;
;   Useful links ...
;   *  https://forums.atariage.com/topic/165365-using-port-a-as-output/
;   *  http://www.brielcomputers.com/phpBB3/viewtopic.php?f=9&t=197
;   *  https://www.sbprojects.net/projects/apple1/wozmon.php
;   *  https://dasm-assembler.github.io/
;-------------------------------------------------------------------------
    PROCESSOR 6502
    INCLUDE "vcs.h"
    INCLUDE "macro.h"
    ;ORG $F000
    ;.byte #$ff  ;reserve first 2048 bytes for ram
    ORG $F800

;-------------------------------------------------------------------------
;  Memory declaration
;-------------------------------------------------------------------------

XAML      = $80             ; Last "opened" location Low
XAMH      = $81             ; Last "opened" location High
STL       = $82             ; Store address Low
STH       = $83             ; Store address High
L         = $84             ; Hex value parsing Low
H         = $85             ; Hex value parsing High
YSAV      = $86             ; Used to see if hex value is given
MODE      = $87             ; $00=XAM, $7F=STOR, $AE=BLOCK XAM
BYTEIN    = $88             ; Variable to store byte for console input
TEMP      = $89 
IN        = $F000           ; RAM Read
WN        = $F400           ; RAM Write

;-------------------------------------------------------------------------
;  Constants
;-------------------------------------------------------------------------

BS       = $88             ; Backspace key, arrow left key
CR       = $8D             ; Carriage Return
LF       = $8A
ESC      = $9B             ; ESC key
PROMPT   = $DC             ; "\" Prompt character

;-------------------------------------------------------------------------
;  Let's get started
;
;  Remark the RESET routine is only to be entered by asserting the RESET
;  line of the system. This ensures that the data direction registers
;  are selected.
;-------------------------------------------------------------------------
RESET           CLEAN_START
                CLD
                CLI
                LDA #1
                STA SWACNT
                STA SWCHA               ; Keep the line high for UART
                LDA #$9B
;-------------------------------------------------------------------------
; The GETLINE process
;-------------------------------------------------------------------------

NOTCR           CMP     #BS             ; Backspace key?
                BEQ     BACKSPACE       ; Yes
                CMP     #ESC            ; ESC?
                BEQ     ESCAPE          ; Yes
                INY                     ; Advance text index
                BPL     NEXTCHAR        ; Auto ESC if line longer than 127
ESCAPE          LDA     #PROMPT         ; Print prompt character
                JSR     ECHO            ; Output it.
GETLINE         LDA     #CR             ; Send CR
                JSR     ECHO
                LDY     #$01            ; Start a new input line
BACKSPACE       DEY                     ; Backup text index
                BMI     GETLINE         ; Oops, line's empty, reinitialize
NEXTCHAR        JSR     GETCH           ; Read character from keyboard
                CMP     #$60            ; *Is it Lower case
                BMI     CONVERT         ; *Nope, just convert it
                AND     #$5F            ; *If lower case, convert to Upper case
CONVERT         ORA     #$80            ; *Convert it to "ASCII Keyboard" Input
                STA     WN,Y            ; Add to text buffer.
                JSR     ECHO            ; Display character.
                CMP     #CR             ; CR?
                BNE     NOTCR           ; No.
                LDY     #$FF            ; Reset text index.
                LDA     #$00            ; For XAM mode.
                TAX                     ; 0->X.
SETSTOR         ASL                     ; Leaves $7B if setting STOR mode
SETMODE         STA     MODE            ; Set mode flags
BLSKIP          INY                     ; Advance text index
NEXTITEM        LDA     IN,Y            ; Get character
                CMP     #CR
                BEQ     GETLINE         ; We're done if it's CR!
                CMP     #$AE            ; "."
                BCC     BLSKIP          ; Ignore everything below "."!
                BEQ     SETMODE         ; Set BLOCK XAM mode ("." = $AE)
                CMP     #$BA            ; ":"
                BEQ     SETSTOR         ; Set STOR mode! $BA will become $7B
                CMP     #$D2            ; "R"
                BEQ     RUN             ; Run the program! Forget the rest
                STX     L               ; Clear input value (X=0)
                STX     H
                STY     YSAV            ; Save Y for comparison
NEXTHEX         LDA     IN,Y            ; Get character for hex test
                EOR     #$B0            ; Map digits to 0-9
                CMP     #$0A            ; Is it a decimal digit?
                BCC     DIG             ; Yes!
                ADC     #$88            ; Map letter "A"-"F" to $FA-FF
                CMP     #$FA            ; Hex letter?
                BCC     NOTHEX          ; No! Character not hex
DIG             ASL
                ASL                     ; Hex digit to MSD of A
                ASL
                ASL
                LDX     #$04            ; Shift count
HEXSHIFT        ASL                     ; Hex digit left, MSB to carry
                ROL     L               ; Rotate into LSD
                ROL     H               ; Rotate into MSD's
                DEX                     ; Done 4 shifts?
                BNE     HEXSHIFT        ; No, loop
                INY                     ; Advance text index
                BNE     NEXTHEX         ; Always taken
NOTHEX          CPY     YSAV            ; Was at least 1 hex digit given?
                BNE     NOESCAPE        ; * Branch out of range, had to improvise...
                JMP     ESCAPE          ; Yes, generate ESC sequence.
RUN             JSR     ACTRUN          ; * JSR to the Address we want to run.
                JMP     RESET           ; * When returned for the program, reset EWOZ.
ACTRUN          JMP     (XAML)          ; Run at current XAM index.
NOESCAPE        BIT     MODE            ; Test MODE byte
                BVC     NOTSTOR         ; B6=0 is STOR, 1 is XAM or BLOCK XAM
                LDA     L               ; LSD's of hex data
                STA     (STL,X)         ; Store current 'store index'(X=0)
                INC     STL             ; Increment store index.
                BNE     NEXTITEM        ; No carry!
                INC     STH             ; Add carry to 'store index' high
TONEXTITEM      JMP     NEXTITEM        ; Get next command item.
NOTSTOR         BMI     XAMNEXT         ; B7=0 for XAM, 1 for BLOCK XAM.
                LDX     #$02            ; Byte count.
SETADR          LDA     L-1,X           ; Copy hex data to
                STA     STL-1,X         ; 'store index'
                STA     XAML-1,X        ; and to 'XAM index'
                DEX                     ; Next of 2 bytes
                BNE     SETADR          ; Loop unless X = 0
NXTPRNT         BNE     PRDATA          ; NE means no address to print
                LDA     #CR             ; Print CR first
                JSR     ECHO
                LDA     XAMH            ; Output high-order byte of address
                JSR     PRBYTE
                LDA     XAML            ; Output low-order byte of address
                JSR     PRBYTE
                LDA     #$BA            ; Print colon
                JSR     ECHO
PRDATA          LDA     #$A0            ; Print space
                JSR     ECHO
                LDA     (XAML,X)        ; Get data from address (X=0)
                JSR     PRBYTE          ; Output it in hex format
XAMNEXT         STX     MODE            ; 0 -> MODE (XAM mode).
                LDA     XAML            ; See if there's more to print
                CMP     L
                LDA     XAMH
                SBC     H
                BCS     TONEXTITEM      ; Not less! No more data to output
                INC     XAML            ; Increment 'examine index'
                BNE     MOD8CHK         ; No carry!
                INC     XAMH
MOD8CHK         LDA     XAML            ; If address MOD 8 = 0 start new line
                AND     #$0F
                BPL     NXTPRNT         ; Always taken.
;-------------------------------------------------------------------------
;  Subroutine to print a byte in A in hex form (destructive)
;-------------------------------------------------------------------------
PRBYTE          PHA                     ; Save A for LSD
                LSR
                LSR
                LSR                     ; MSD to LSD position
                LSR
                JSR     PRHEX           ; Output hex digit
                PLA                     ; Restore A
;-------------------------------------------------------------------------
;  Subroutine to print a hexadecimal digit
;-------------------------------------------------------------------------
PRHEX           AND     #$0F            ; Mask LSD for hex print
                ORA     #$B0            ; Add "0"
                CMP     #$BA            ; Is it a decimal digit?
                BCC     ECHO            ; Yes! output it
                ADC     #$06            ; Add offset for letter A-F
;-------------------------------------------------------------------------
;  Subroutine to print a character to the terminal
;-------------------------------------------------------------------------
ECHO            STA TEMP                ; Save Registers
                PHA
                TXA
                PHA
                TYA
                PHA
                LDA TEMP                     
                AND #$7F                ; *Change to "standard ASCII"
                LDX #0                  ; Start Bit
                STX SWCHA               ; Load bit into port
                LDX #16                 ; Seems to be more or less right for 1200baud
                STX TIM64T              ; Set timer
STARTBIT        LDX INTIM               ; Check time
                BNE STARTBIT            ; Are we done waiting?
                DEX                     ; Waste cycles to bring it even closer to 1200baud
                DEX                     ; Waste cycles to bring it even closer to 1200baud
                LDY #7                  ; We will count down from 7 to 0 for all bits in the byte
SHIFTBIT        STA SWCHA               ; Write bit to SWCHA
                ROR                     ; Rotate out next Bit
                LDX #16                 ; Seems to be more or less right for 1200baud 
                STX TIM64T              ; Set timer
TXWAIT          LDX INTIM               ; Check time
                BNE TXWAIT              ; Are we done waiting?
                DEY                     ; Decrement y
                BPL SHIFTBIT            ; Do we still have bits left?
                LDX #1                  ; Stop Bit
                STX SWCHA               ; Write the stop bit
                LDX #16                 ; Seems to be more or less right for 1200baud 
                STX TIM64T              ; Set timer
STOPBIT         LDX INTIM               ; Check time
                BNE STOPBIT             ; Are we done waiting?
                PLA                     ; Restore Registers
                TAY
                PLA
                TAX
                PLA
                RTS                     ; Return
;-------------------------------------------------------------------------
;  Subroutine to read a character from the terminal
;-------------------------------------------------------------------------
GETCH           TXA
                PHA                     ; Push X register on stack
                CLC                     ; Clear carry
                LDA #$FF
                STA BYTEIN              ; Clear BYTEIN              
RXLOW           LDA SWCHA               ; Check if RX line is low indicating start bit
                LSR                     ; Shift bits right to get to the RX bit
                LSR                     ; Shift bits right to get to the RX bit
                BCS RXLOW               ; Check if RX line is low, if not we wait
                DEX                     ; Waste cycles to bring it even closer to 1200baud
                LDX #7                  ; We will count down from 7 to 0 for all bits in the byte
READBIT         LDA #16                 ; Seems to be more or less right for 1200baud 
                STA TIM64T              ; Set timer
RXWAIT          LDA INTIM               ; Check time
                BNE RXWAIT              ; Are we done waiting?
                LDA SWCHA               ; Read SWCHA
                LSR                     ; Shift bits right to get to the RX bit
                LSR                     ; Shift bits right to get to the RX bit
                ROR BYTEIN              ; Rotate right for next bit
                DEX                     ; Decrement X
                BPL READBIT             ; Loop until 8 bits read
                LDA #16                 ; Seems to be more or less right for 1200baud
                STA TIM64T              ; Set timer
RXSTOPBIT       LDA INTIM               ; Check time
                BNE RXSTOPBIT           ; Wait for Stop bit time
                PLA                     ; Restore X
                TAX
                LDA BYTEIN              ; Load received byte into accumalator
                RTS                     ; Return
;-------------------------------------------------------------------------
;  Vector area
;-------------------------------------------------------------------------
    ORG $FFFA        ;     TOP

    .WORD RESET      ;     NMI
    .WORD RESET      ;     RESET
    .WORD RESET      ;     IRQ

    END