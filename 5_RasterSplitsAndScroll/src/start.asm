.label SCREEN_RAM = $c000
.label SPRITE_POINTERS = SCREEN_RAM + $3f8
.label FIRST_SCREEN_RASTERLINE = 51
.label SPLIT_1_RASTERLINE = FIRST_SCREEN_RASTERLINE + 7
.label SPLIT_2_RASTERLINE = SPLIT_1_RASTERLINE + 4*8	//51 + 7 + 32
.label SPLIT_3_RASTERLINE = SPLIT_2_RASTERLINE + 4*8	


* = $f000 "Charset"
	CHAR_SET:
		.import binary "../assets/maps/charset.bin" 

#import "zeropage.asm"

BasicUpstart2(Entry)

#import "../libs/tables.asm" 
#import "../libs/vic.asm"
#import "../libs/macros.asm"

#import "utils/irq.asm"


//.var music = LoadSid("../assets/sound/cuteplatform.sid")
//* = $1000 "Music"
//	.fill music.size, music.getData(i)


Entry:
		lda #$00 //hellblau
		sta VIC.BACKGROUND_COLOR
		
		lda #$00 //white	
		sta VIC.BORDER_COLOR

		lda #$05
		sta VIC.EXTENDED_BG_COLOR_1
		lda #$00
		sta VIC.EXTENDED_BG_COLOR_2
	

		jsr IRQ.Setup

		//Bank out BASIC and Kernal ROM
		lda $01
		and #%11111000 
		ora #%00000101
		sta $01


		//Set VIC BANK 3
		// Bit #0 und #1 : %00 --> Bank 3 --> $C000 -$FFFF
		lda $dd00
		and #%11111100
		sta $dd00 

		//Set screen and character memory
		// Character memory %110: $3000 - $37FF in VIC Bank 3 --> $f000 - f7fff
		// Screen Memory %0000: $0000 - $03FF in VIC Bank 3 --> $c000 - $ffff
		lda #%00001100
		sta VIC.MEMORY_SETUP //$d018

FillScreen: {
		lda #<SCREEN_RAM
		sta ScrMod + 1 
		lda #>SCREEN_RAM
		sta ScrMod + 2
		
		lda #<VIC.COLOR_RAM
		sta ColMod + 1
		lda #>VIC.COLOR_RAM
		sta ColMod + 2

		ldy #$00
		ldx #$04
	
	!loop:
		lda #$01
	ScrMod:
		sta $BEEF, y
		lda #$02
	ColMod:
		sta $BEEF, y
		dey
		bne !loop-

		inc ScrMod +2
		inc ColMod +2
		dex
		bne !loop-

}


	
ChangeColorSplit1: {
	ldx #$04
!loop:
	
	lda TABLES.ColorRowLSB, x
	sta VECTOR1
	lda TABLES.ColorRowMSB, x
	sta VECTOR1 + 1 
	
	ldy #39
	!:
	lda #$05 //color green
	sta (VECTOR1),y
	dey
	bpl !-

	dex
	bne !loop-
}	


ChangeColorSplit2: {
	ldx #$08
!loop:
	
	lda TABLES.ColorRowLSB, x
	sta VECTOR1
	lda TABLES.ColorRowMSB, x
	sta VECTOR1 + 1 
	
	ldy #39
	!:
	lda #$06 //color blue
	sta (VECTOR1),y
	dey
	bpl !-

	dex
	cpx Split2StartRow
	bne !loop-
}	





	//Inf loop
	!Loop:
		nop
		jmp !Loop- 
	

SplitStartRows:
	.byte $01, $04

.label Split2StartRow = SplitStartRows +1




//This fixes the ghost byte issue on screen shake
//By forcing all IRQs to run indirectly from the last 
//page ensuring the ghost byte is always $FF
* = $fff0 "IRQ Indirect vector"
IRQ_Indirect:
	.label IRQ_LSB = $fff1
	.label IRQ_MSB = $fff2
	jmp $BEEF


