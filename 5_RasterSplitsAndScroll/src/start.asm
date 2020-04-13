.label SCREEN_RAM = $c000
.label SPRITE_POINTERS = SCREEN_RAM + $3f8
.label FIRST_SCREEN_RASTERLINE = 51
.label SPLIT_1_RASTERLINE = FIRST_SCREEN_RASTERLINE -1
.label SPLIT_2_RASTERLINE = SPLIT_1_RASTERLINE + 5*8	
.label SPLIT_3_RASTERLINE = SPLIT_2_RASTERLINE + 5*8	


* = $f000 "Charset"
	CHAR_SET:
		.import binary "../assets/maps/charset.bin" 

#import "zeropage.asm"

BasicUpstart2(Entry)

#import "../libs/tables.asm" 
#import "../libs/vic.asm"
#import "../libs/macros.asm"

#import "utils/irq.asm"


* = * "Main"
Entry:
		lda #$03 //hellblau
		sta VIC.BACKGROUND_COLOR
		
		lda #$01 //white	
		sta VIC.BORDER_COLOR

		lda #$0a
		sta VIC.EXTENDED_BG_COLOR_1
		lda #$0b
		sta VIC.EXTENDED_BG_COLOR_2
	

		jsr IRQ.Setup

		/*sei
		
		lda #$7f	//Disable CIA IRQ's to prevent crash because 
		sta $dc0d
		sta $dd0d
		*/

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
		
		//cli

		lda $d016
		ora #%00011000
		sta $d016


		ldx #10 //row

FillScreen: {
	!loop:
		lda TABLES.MapRowLSB,x	
		sta VECTOR1 + 0
		lda TABLES.MapRowMSB,x
		sta VECTOR1 + 1

		
		lda TABLES.ScreenRowLSB, x
		sta VECTOR2 + 0
		lda TABLES.ScreenRowMSB, x
		sta VECTOR2 + 1

		ldy #39
	!:	
		lda (VECTOR1),y
		sta (VECTOR2),y
		dey
		bpl !-

		dex
		bpl !loop- 

}



	//Inf loop
	!Loop:
		nop
		jmp !Loop- 
	

SplitStartRows:
	.byte $01, $04

.label Split2StartRow = SplitStartRows +1




* = $8000 "CharMap"
CHAR_MAP:
	.import binary "../assets/maps/map.bin"
COLOR_MAP:
	.import binary "../assets/maps/cols.bin"	


//This fixes the ghost byte issue on screen shake
//By forcing all IRQs to run indirectly from the last 
//page ensuring the ghost byte is always $FF
* = $fff0 "IRQ Indirect vector"
IRQ_Indirect:
	.label IRQ_LSB = $fff1
	.label IRQ_MSB = $fff2
	jmp $BEEF


