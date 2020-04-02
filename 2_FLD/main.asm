
.label FIXEDLINES  = 3                     //Feste Zeichenzeilen
.label STARTLINE   = 48+FIXEDLINES*8       //Start immer ganze Textzeile, wg. Bad Line
.label SKIPLINES   = 45                    //Größe der Lücke in Pixelzeilen

BasicUpstart2(Entry)

linesToSkip:
 .byte SKIPLINES

Entry: {
       //lda #$ff                           //Füllmuster für die „undefinierten“ Bereiche
       // sta $3fff
        lda #$01
        sta $0450
        lda #$02
        sta $0451
        lda #$03
        sta $0452
        
        
        sei                                //Interrupts sperren

    !loop: 
        lda #SKIPLINES                     //Anzahl der zu überspringenden
        sta linesToSkip                    //Zeilen merken

    !nextScreen:
        jsr waitForNewFrame                //Auf erste Rasterzeile warten

        lda #%00011011                     //Standardwerte für $D011
        sta $d011                          //setzen

        lda #STARTLINE                     //Warten, bis die gewünschte Rasterzeile (72 = %0100 1000) erreicht ist.
        cmp $d012
        bne *-3

        ldx linesToSkip                    //X-Reg: 45..44..43 Anzahl der zu überspringenden Rasterzeilen ins X-Reg. holen
        beq !loop-                          //falls 0 -> alles zurück auf Anfang

    !nextRasterLine:
        ldy $d012                          //auf nächste Rasterzeile warten 
        !:
        cpy $d012
        beq !-
                                           //$D012 Startwert (dez73):  %01001 |001|  --> 010 --> 011 --> 100 --> 101 --> 110 --> 111 --> 000 
        
        ldy $d012
        iny
        tya
        and #%00000111
        ora #%00011000
        sta $d011
               
        /* 
        clc                                //Y-Scroll-Position um eins erhöhen
        lda $d011                          //$D011: %00011                    |011|  --> 100 --> 101 --> 110 --> 111 --> 000 --> 001 --> 010 
        adc #1
        and #%00000111
        ora #%00011000                     
        sta $d011                          //$D011: %00011                    |100|  --> 101 --> 110 --> 111 --> 000 --> 001 --> 010                               
        */



        dex                                //Anzahl der Leerzeilen minus 1  (45,44,43)
        bne !nextRasterLine-               //falls nicht 0, $d011 weiter verändern


        dec linesToSkip                    //Anzahl der Leerzeilen für nächsten Durchlauf verringern --> damit man eine kleiner werdende Lücke sieht ("Animation") 

        jmp !nextScreen-                   //Und wieder auf den nächsten Bildaufbau warten


}


waitForNewFrame: {
    lda $d011                      
    bpl *-3                            //solange $d011 positiv ist, warten...
    lda $d011                      
    bmi *-3                            //solange $d011 negativ ist, warten...
    rts                                //jetzt wurde das höchste BIT in $d011 gelöscht -> ein neuer Bildschirmaufbau beginnt.
}


