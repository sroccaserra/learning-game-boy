;; vim: set filetype=z80:

INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

EntryPoint:
        nop
        jp Start

REPT $150 - $104
    db 0
ENDR

; MAIN CODE
;

SECTION "Game code", ROM0
Start:
        ; Usual setup
        di
        ld sp, $DFF0

        ; Set up LCDC
        ld a, [rLCDC]
        and %10000000
        or  %00000001
        ld [rLCDC], a

        call ScreenOff

        ; Clear VRAM
        ld hl, $8000
        xor a
.clearVRam:
        ld [hl], a
        inc hl
        bit 5, h
        jp z, .clearVRam

        ; Test tile
        ld hl, $9000
        ld de, TileGraphics
        ld bc, TileGraphicsEnd - TileGraphics
.loadTile:
        ld a, [de]
        ld [hli], a
        inc de
        dec bc
        ld a, b
        or c            ; Check if count is 0, since `dec bc` doesn't update flags
        jr nz, .loadTile

        ; Set palettes
        ld a, %00011011
        ld [rBGP], a

        ; Turn screen on
        call ScreenOn

        ; TODO!
GameLoop:
        jr GameLoop

        ; ScreenOn: Turns the screen on.
ScreenOn:
        push af
        ld a, [rLCDC]
        set 7, a
        ld [rLCDC], a
        pop af
        ret

        ; ScreenOff: Turns the screen off safely (waits for vblank).
ScreenOff:
        push af
        ld a, [rLCDC]
        bit 7, a
        jr z, .endVBlank

.waitForVBlank:
        ld a, [rLY]
        cp 145
        jr nz, .waitForVBlank

        ld a, [rLCDC]
        res 7, a
        ld [rLCDC], a
.endVBlank:
        pop af
        ret

SECTION "Graphics", ROM0
TileGraphics:
        DB %00110011,%00001111
        DB %01100110,%00011110
        DB %11001100,%00111100
        DB %10011001,%01111000
        DB %00110011,%11110000
        DB %01100110,%11100001
        DB %11001100,%11000011
        DB %10011001,%10000111
TileGraphicsEnd:
