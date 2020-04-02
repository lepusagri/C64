.label SCREEN_RAM = $0400
.label COLOR_RAM = $d800

BasicUpstart2(Entry)

TextMap:
    .import binary "assets/starting/mymap.bin"

ColorRamp:
    .byte $01,$07,$0f,$0a,$0c,$04,$0b,$06,$0b,$04,$0c,$0a,$0f,$07

ColorIndex:
    .byte $00

Entry: {
        //set charset
        //bit7-4 %0001 * $0400 (1kByte)
        //bit3-1 $100 (4) * $0800 =$2000 (1 Zeichensatz 2kByte $800)
        lda #%00011000 
        sta $d018

        //set border and background to black
        lda #0
        sta $d020
        sta $d021

        lda #238
        jsr ClearScreen

        //draw Text
        ldx #0
    !:
        lda TextMap,x
        sta SCREEN_RAM + 12 * 40, x
        inx
        cpx #80
        bne !-

        //jmp *

    Loop:
        ldx ColorIndex
        inx
        cpx #14
        bne !+
        ldx #0
    !:
        stx ColorIndex

        ldy #0
    Innerloop:
        lda ColorRamp, x
        sta COLOR_RAM +12 * 40 + 8, y
        sta COLOR_RAM +13 * 40 + 8, y

        inx
        cpx #14
        bne !+
        ldx #0
    !:
        iny
        cpy #24
        bne Innerloop

        lda #$a0
    !:
        cmp $d012 
        bne !-

        jmp Loop


}


ClearScreen: {
        ldx #250
    !:
        dex
        sta SCREEN_RAM, x
        sta SCREEN_RAM + 250, x
        sta SCREEN_RAM + 500, x
        sta SCREEN_RAM + 750, x
        bne !-
        rts
}

* = $2000
.import binary "assets/starting/chars.bin"
