;; vim: set filetype=z80:

INCLUDE "hardware.inc"

SECTION "VBlank", ROM0[$40]
        call OnVBlank
        reti

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
        and LCDCF_ON
        or LCDCF_BGON
        ld [rLCDC], a

        call ScreenOff

        ; Clear VRAM
        ld hl, _VRAM
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

        ld a, [Palette]
        ld [rBGP], a

        ; Turn screen on
        call ScreenOn

        ; Enable VBlank interrupt
        ld a, IEF_VBLANK
        ld [rIE], a
        ei

MainLoop:
        jr MainLoop

OnVBlank:
        push af
        ld a, [rSCX]
        inc a
        ld [rSCX],a
        pop af
        ret

ScreenOn:
        push af
        ld a, [rLCDC]
        or LCDCF_ON
        ld [rLCDC], a
        pop af
        ret

ScreenOff:
        push af
        ld a, [rLCDC]
        bit 7, a
        jr z, .end

.waitForVBlank:
        ld a, [rSTAT]
        and (STATF_OAM | STATF_VB)
        cp STATF_VB
        jr nz, .waitForVBlank

        ld a, [rLCDC]
        res 7, a
        ld [rLCDC], a
.end:
        pop af
        ret

SECTION "Graphics", ROM0

Palette:
        DB %11100100

TileGraphics:
INCBIN "tile.2bpp"
TileGraphicsEnd:
