;; vim: set filetype=z80:

.memorymap
        slotsize $4000
        slot 0 $0000
        slot 1 $4000
        defaultslot 0
.endme

.rombankmap
        bankstotal 2
        banksize $4000
        banks 2
.endro

.gbheader
        name "GB TEMPLATE"
        cartridgetype $00
        ramsize $00
.endgb
.nintendologo

;
; HARDWARE DEFINES
;
.define LCDC $FF40
.define STAT $FF41
.define SCY  $FF42
.define SCX  $FF43
.define LY   $FF44
.define LYC  $FF45

.define BGP  $FF47
.define OBP0 $FF48
.define OBP1 $FF49

;
; JUMP VECTORS
;

.bank 0 slot 0
.org $0100
.section "Vec_Jump" size 4 force
        nop
        jp start
.ends

;
; MAIN CODE
;

.section "Code1x"
start:
        ; Usual setup
        di
        ld sp, $DFF0

        ; Set up LCDC
        ld a, (LCDC)
        and %10000000
        or  %00000001
        ld (LCDC), a

        ; Turn screen off
        call screen_off

        ; Clear VRAM
        ld hl, $8000
        xor a
        -:
                ld (hl), a
                inc hl
                bit 5, h
                jp z, -

        ; Test tile
        ld hl, $9000
        ld de, %0000111100110011
        ld b, 8
        -:
                ld (hl), e
                inc l
                ld (hl), d
                inc l
                rlc e
                rlc d
                dec b
                jp nz, -

        ; Set palettes
        ;ld a, %11100100
        ld a, %00011011
        ld (BGP), a

        ; Turn screen on
        call screen_on

        ; TODO!
        -: jr -

        ; screen_on: Turns the screen on.
        ;
        ; Input: -
        ; Output: -
        ; Clobbers: -
screen_on:
        push af
        ld a, (LCDC)
        set 7, a
        ld (LCDC), a
        +: pop af
        ret

        ; screen_off: Turns the screen off safely (waits for vblank).
        ;
        ; Input: -
        ; Output: -
        ; Clobbers: -
screen_off:
        push af
        ld a, (LCDC)
        bit 7, a
        jr z, +

        ; Wait for vblank
        -:
                ld a, (LY)
                cp 145
                jr nz, -

        ld a, (LCDC)
        res 7, a
        ld (LCDC), a
        +: pop af
        ret
.ends

