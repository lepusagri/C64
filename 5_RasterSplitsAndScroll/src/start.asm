.label SCREEN_RAM = $c000
.label SPRITE_POINTERS = SCREEN_RAM + $3f8
.label RASTERLINE_250 = 250
.label FIRST_SCREEN_RASTERLINE = 51
.label SPLIT_1_RASTERLINE = FIRST_SCREEN_RASTERLINE -1
.label SPLIT_2_RASTERLINE = SPLIT_1_RASTERLINE + 5*8	
.label SPLIT_3_RASTERLINE = SPLIT_2_RASTERLINE + 5*8	
.label Split2StartRow = SplitStartRows +1


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
		
		lda #$00 //black	
		sta VIC.BORDER_COLOR

		lda #$0a
		sta VIC.EXTENDED_BG_COLOR_1
		lda #$09
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
		
		
		lda $d016
		and #%11110111	//switch to 38 column mode
		ora #%00010000	//turn multicolor on
		sta $d016

		lda #25
		sta TEMP1
		jsr FillScreen
		
		cli


	//Inf loop
	!Loop:
		nop
		jmp !Loop- 
	

FillScreen: {
	!loop:
		.label ZPMapPointer = VECTOR1
		.label ZPScreenPointer = VECTOR2
		.label ZPColorPointer = VECTOR3
		
		ldx TEMP1
		
		lda TABLES.MapRowLSB,x	
		sta ZPMapPointer + 0
		lda TABLES.MapRowMSB,x
		sta ZPMapPointer + 1
		
		lda TABLES.ScreenRowLSB, x
		sta ZPScreenPointer + 0
		lda TABLES.ScreenRowMSB, x
		sta ZPScreenPointer + 1

		lda TABLES.ColorRowLSB, x
		sta ZPColorPointer + 0
		lda TABLES.ColorRowMSB, x
		sta ZPColorPointer + 1


		ldy #39
	!:	
		lda (ZPMapPointer),y
		sta (ZPScreenPointer),y
		
		//color
		tax 					//char_id --> X-Reg.
		lda COLOR_MAP,x			//get the defined color of the char_id
		sta (ZPColorPointer),y	//set color

		dey
		bpl !-

		dec TEMP1
		bpl !loop- 

		rts

}

//shifts to the left
ShiftSplit1: {
		txa			//X-Register = Mapposition 0,1,2,3,....88 
		clc
		adc #39		//Akku = 39,40, 41, 42 ,43,....127, 0
		tax			//back to X-Register
		
		.for(var i=0; i< 5; i++) {					//Row 0 - 5
			.for(var j=0; j<38; j++) {
				lda SCREEN_RAM + (40 * i) + j + 1	//1-->0;....;38-->37
				sta SCREEN_RAM + (40 * i) + j + 0
				lda $d800 + (40 * i) + j + 1
				sta $d800 + (40 * i) + j + 0
			}
			//.break
			//get new column from the map
			lda CHAR_MAP + (128 * i), x			//Mapposition 1 --> $8040; 	
			sta SCREEN_RAM + (40 * i) + 38
			tay
			lda COLOR_MAP, y
			sta $d800 + (40 * i) + 38

		}
		rts
}

//shifts to the right
ShiftSplit2: {
		lda #128
		sec 
		sbc MapPositionSplit2
		tax						//X-Register = Mapposition 1 ...127 		1-->127; 2-->126  (X = 128 - X); 128 -->0; !!!!!129 -->
		


		.for(var i=5; i< 10; i++) {					//Row 5 - 10
			.for(var j=37; j>=0; j--) {
				
				lda SCREEN_RAM + (40 * i) + j + 0	//38-->39;....0-->1
				sta SCREEN_RAM + (40 * i) + j + 1
				
				lda $d800 + (40 * i) + j + 0
				sta $d800 + (40 * i) + j + 1
			}
			//.break
			//get new column from the map and store it in column 0
			lda CHAR_MAP + (128 * i), x 	
			sta SCREEN_RAM + (40 * i)
			tay
			lda COLOR_MAP, y
			sta $d800 + (40 * i)

		}
		rts
}


SplitStartRows:
	.byte $01, $04



XScroll:
	.byte $07
XScrollSplit2:
	.byte $00

MapPositionSplit1:
	.byte $00
UpdateMapFlagSplit1:
	.byte $00
MapPositionSplit2:
	.byte $00
UpdateMapFlagSplit2:
	.byte $00


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


