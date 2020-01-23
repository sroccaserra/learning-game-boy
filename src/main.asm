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
.include "nintendo_logo.i"

.INCLUDE "gb_hardware.i"

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
@clearVRam:
        ld (hl), a
        inc hl
        bit 5, h
        jp z, @clearVRam

        ; Test tile
        ld hl, $9000
        ld e, %00001111 ; registers d and e represent the following row of pixels:
        ld d, %00110011 ;     00 01 01 10 10 11 11
        ld b, 8         ; 8 rows
@loadTile:
        ld (hl), d
        inc l
        ld (hl), e
        inc l
        rlc e
        rlc d
        dec b
        jp nz, @loadTile

        ; Set palettes
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

@waitForVBlank:
        ld a, (LY)
        cp 145
        jr nz, @waitForVBlank

        ld a, (LCDC)
        res 7, a
        ld (LCDC), a
        +: pop af
        ret
.ends
