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
    DB 0
ENDR

; MAIN CODE
;

SECTION "Game code", ROM0
Start:
        ; Usual setup
        di
        ld sp, $FFFE

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
        halt
        nop
        jr MainLoop

OnVBlank:
        push af

        call ReadJoypadState

        ; Scroll in joypad direction
        ld hl, rSCX
        ld b, [hl]
        ld hl, rSCY
        ld c, [hl]
        ld a, [JoypadState]
.ifRight:
        bit PADB_RIGHT, a
        jr nz, .ifLeft
        inc b
.ifLeft:
        bit PADB_LEFT, a
        jr nz, .ifUp
        dec b
.ifUp:
        bit PADB_UP, a
        jr nz, .ifDown
        dec c
.ifDown:
        bit PADB_DOWN, a
        jr nz, .updateScroll
        inc c
.updateScroll:
        ld hl, rSCX
        ld [hl], b
        ld hl, rSCY
        ld [hl], c

        pop af
        ret

ReadJoypadState:
        ; read directions
        ld a, P1F_5
        ldh [rP1], a
        ld a, [rP1]
        ld a, [rP1]
        cpl             ; direction down -> bit set
        and a, $0f      ; keep lower four bytes
        swap a          ; move them to higher four bytes
        ld b, a
        ; read buttons
        ld a, P1F_4
        ldh [rP1], a
        REPT 6
        ld a, [rP1]
        ENDR
        cpl
        and a, $0f
        or a, b
        ld [JoypadState], a
        ld a, [JoypadState]
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
        ld a, [rLY]
        cp 145
        jr nz, .waitForVBlank

        ld a, [rLCDC]
        res 7, a
        ld [rLCDC], a
.end:
        pop af
        ret

SECTION "Vars", WRAM0[_RAM]

JoypadState:
        DB

SECTION "Graphics", ROM0

Palette:
        DB %11100100

TileGraphics:
        INCBIN "tile.2bpp"
TileGraphicsEnd:
