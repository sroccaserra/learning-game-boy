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

DmaCode:
        ld a, $c1
        ld [rDMA], a
        ld a, 40
.loop:                  ; wait 160 cycles/microseconds
        dec a
        jr nz, .loop
        ret
DmaCodeEnd:

Start:
        ; Usual setup
        di
        ld sp, $FFFE

        ; Set up LCDC
        ld a, [rLCDC]
        and LCDCF_ON
        or LCDCF_BGON
        or LCDCF_OBJON
        ld [rLCDC], a

        call ScreenOff

        ; Clear VRAM
        ld hl, _VRAM
        xor a
.clearVRam:
        ld [hl+], a
        bit 5, h
        jp z, .clearVRam

        ; Load DMA routine in High RAM
        ld bc, DmaCode
        ld hl, DmaRoutine
        REPT DmaCodeEnd - DmaCode
        ld a, [bc]
        inc bc
        ld [hl+], a
        ENDR

        ; Load tile in VRAM
        ld hl, $9000
        ld de, TileGraphics
        ld bc, TileGraphicsEnd - TileGraphics
.loadTile:
        ld a, [de]
        ld [hl+], a
        inc de
        dec bc
        ld a, b
        or c            ; Check if count is 0, since `dec bc` doesn't update flags
        jr nz, .loadTile

        ld a, [BgPalette]
        ld [rBGP], a

        ; Load sprite in VRAM
        ld hl, $8000
        ld bc, Sprite
        REPT 16
        ld a, [bc]
        ld [hl+], a
        inc bc
        ENDR
        ld a, [SpritePalette]
        ld [rOBP0], a

        ; Clear OamBuffer
        ld hl, OamBuffer
        ld b, 40*4
        xor a
.clearOamBuffer:
        ld [hl+], a
        dec b
        jr nz, .clearOamBuffer

        ; Init player state
        ld a, 34
        ld [PlayerX], a
        ld [PlayerY], a

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
        ld hl, PlayerX
        ld b, [hl]
        ld hl, PlayerY
        ld c, [hl]
        ld a, [JoypadState]
.ifRight:
        bit PADB_RIGHT, a
        jr z, .ifLeft
        inc b
.ifLeft:
        bit PADB_LEFT, a
        jr z, .ifUp
        dec b
.ifUp:
        bit PADB_UP, a
        jr z, .ifDown
        dec c
.ifDown:
        bit PADB_DOWN, a
        jr z, .updateScroll
        inc c
.updateScroll:
        ld hl, PlayerX
        ld [hl], b
        ld hl, PlayerY
        ld [hl], c

        ; load sprite attributes
        ld hl, OamBuffer
        ld a, [PlayerY]
        ld [hl+], a     ; y-coord
        ld a, [PlayerX]
        ld [hl+], a     ; x-coord
        ld a, 0         ; tile index
        ld [hl+], a
        ld a, %00000000 ; attributes, including palette, which are all zero
        ld [hl+], a

        call DmaRoutine

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

PlayerX:
        DB
PlayerY:
        DB

SECTION "OAM Buffer", WRAM0[$C100]

OamBuffer:
        DS 4*40         ; 40 sprites data

SECTION "High Ram", HRAM

DmaRoutine:
        DS DmaCodeEnd - DmaCode

SECTION "Graphics", ROM0

BgPalette:
        DB %11100100

TileGraphics:
        INCBIN "tile.2bpp"
TileGraphicsEnd:

SpritePalette:
        DB %11100100

Sprite:
        DW `02222220
        DW `21111113
        DW `21333313
        DW `21311213
        DW `21311213
        DW `21322213
        DW `21111113
        DW `03333330
