.label SCREEN_RAM = $0400
.label START_4_ZEILE = SCREEN_RAM + (40 * 3)
.label IRQline = 200
.label ZP_0 = $0A

TABLE:



BasicUpstart2(Entry)

Entry:
    lda #$00
    //sta $d020
    sta $d021

    lda #147                           //Code zum Bildschirmlöschen
    jsr $ffd2                          //zur Textausgabe springen (löscht den BS)

    // IRQ setup
    sei
    lda #$35        // Bank out kernal and basic
    sta $01

    lda #$7f        // Disable CIA IRQ's
    sta $dc0d
    sta $dd0d

    lda #<IRQ   // Install RASTER IRQ
    ldx #>IRQ   // into Hardware
    sta $fffe       // Interrupt Vector
    stx $ffff

    lda #$01        // Enable RASTER IRQs
    sta $d01a
    
    lda #IRQline    // IRQ raster line
    sta $d012
    
    lda $d011   // clear IRQ raster line bit 8
    and #$7f
    sta $d011

    asl $d019  // Ack any previous raster interrupt
    bit $dc0d  // reading the interrupt control registers
    bit $dd0d  // clears them

    ldy #[scrolltextend - scrolltext -1]
    sty currenttextpos

    //ack interrupt
    asl $d019
    cli

!loop:
    nop
    nop
    jmp !loop-


IRQ:
    pha
    txa
    pha
    tya
    pha
   
    inc scrollpos                      //Offset um 1 erhöhen
    lda #%00000111                     //wir brauchen nur die unteren drei BITs
    and scrollpos                      //also ausmaskieren
    sta scrollpos                      //und speichern

    bne !end+ 
    jsr Scrollchars                     //wenn der X-Offset wieder 0 werden soll, dann muss zuvor 

   
 !end:   
    lda $d016                          //Register 22 in den Akku
    and #%11111000                     //Bits für den Offset vom linken Rand löschen
    ora scrollpos                      //neuen Offset setzen
    sta $d016                          //und zurück ins VIC-II-Register schreiben
 
    asl $d019

    pla                                
    tay
    pla
    tax
    pla
    rti




Scrollchars:
    ldy currenttextpos
    lda scrolltext, y
    sta START_4_ZEILE 
    
    dey
    cpy #0
    bne !+

    ldy #[scrolltextend - scrolltext -1]
    sty currenttextpos
    
    !:
    sty currenttextpos
    
    ldx #39
    !loop:
    lda [START_4_ZEILE-1], x 
    sta [START_4_ZEILE], x
    dex
    bpl !loop- 
    
    rts

 



scrolltext:
    .text "mein name ist thomas hasenecker    "
scrolltextend:

currenttextpos:
    .byte 0

scrollpos:
 .byte 0                            //aktuelle Scrollposition