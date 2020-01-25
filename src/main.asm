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
        ld de, tile_graphics
        ld bc, tile_graphics_end - tile_graphics
@loadTile:
        ld a, (de)
        ld (hli), a
        inc de
        dec bc
        ld a, b
        or c            ; Check if count is 0, since `dec bc` doesn't update flags
        jr nz, @loadTile

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

.section "Graphics"

tile_graphics:
        .db %00110011,%00001111
        .db %01100110,%00011110
        .db %11001100,%00111100
        .db %10011001,%01111000
        .db %00110011,%11110000
        .db %01100110,%11100001
        .db %11001100,%11000011
        .db %10011001,%10000111
tile_graphics_end:

.ends
