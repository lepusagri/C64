.label IRQ_RASTERLINE = $28


BasicUpstart2(Entry)

Entry:
        sei

        //disable CIA interrupts
        lda #$7f
        sta $dc0d
        sta $dd0d

        //enable raster interrupts
        lda #$01
        sta $d01a

        //set IRQ
        lda #<IRQ
        ldx #>IRQ
        sta $fffe
        stx $ffff

        //set the line
        lda $d011
        and #$7f
        sta $d011
        
        lda #IRQ_RASTERLINE
        sta $d012

        //bank out kernel and basic
        lda #$35
        sta $01

        //ack interrupt
        asl $d019
        cli

    !Loop:
        nop 
        nop
        nop
        bit $00
        jmp !Loop-

IRQ:
        pha
        txa
        pha
        tya
        pha

        lda #<StableIRQ
        ldx #>StableIRQ
        sta $fffe
        stx $ffff
        inc $d012
        asl $d019

        tsx
        cli

        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        
       

StableIRQ:
        // 7-8 cycles + jitter
        txs             //2

        //9 cycles
        ldx #$08        //X *5 + 1 /////
    !:
        dex
        bne !-          //////////////
        bit $00

        //53 cycles
        
        lda $d012
        cmp $d012
        //61 cycles
        beq !+
    !:    

        //64 cycles
        inc $d020
        dec $d020


        asl $d019

        //set IRQ
        lda #<IRQ
        ldx #>IRQ
        sta $fffe
        stx $ffff

        lda #IRQ_RASTERLINE
        sta $d012


        pla
        tay
        pla
        tax 
        pla

        rti