.label SCREEN_RAM = $c000
.label SPRITE_POINTERS = SCREEN_RAM + $3f8



#import "zeropage.asm"

BasicUpstart2(Entry)

#import "../libs/tables.asm" 
#import "../libs/vic.asm"
#import "../libs/macros.asm"

#import "utils/irq.asm"


* = * "Main"
Entry:
		lda #$00 //black
		sta VIC.BACKGROUND_COLOR
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

		ldx #25
		jsr FillScreen
		
		//----------------------------------------
		// Initialize sprites
		//----------------------------------------
		lda #$10
		sta SCREEN_RAM + $03f8 + $00
		lda #$11
		sta SCREEN_RAM + $03f8 + $01
		lda #$12
		sta SCREEN_RAM + $03f8 + $02
		sta SCREEN_RAM + $03f8 + $03
		sta SCREEN_RAM + $03f8 + $04
		sta SCREEN_RAM + $03f8 + $05
		sta SCREEN_RAM + $03f8 + $06
		sta SCREEN_RAM + $03f8 + $07

		lda #$06
		sta $d027
		sta $d028
		sta $d029
		sta $d02a
		sta $d02b
		sta $d02c
		sta $d02d
		sta $d02e

		
		//sprite all singlecolor
		lda #$00
		sta $d01c


		//Car left
		lda #32
		sta $d000		//Sprite1 X
		lda #162
		sta $d001		//Sprite1 Y
		
		//Car right
		lda #50		
		sta $d002		//Sprite2 X
				
		lda #200
		sta $d003		//Sprite2 Y

		//frog nest
		lda #32		
		sta $d004		//Sprite3 X
		lda #62		
		sta $d006		//Sprite4 X
		lda #92		
		sta $d008		//Sprite5 X
		lda #122		
		sta $d00a		//Sprite5 X
		lda #152		
		sta $d00c		//Sprite5 X
		lda #182		
		sta $d00e		//Sprite5 X
						
		lda #25
		sta $d005		//Sprite2 Y
		sta $d007		//Sprite2 Y
		sta $d009		//Sprite2 Y
		sta $d00b		//Sprite2 Y
		sta $d00d		//Sprite2 Y
		sta $d00f		//Sprite2 Y


		lda #%00000010
		sta $d010

		//enable only the car sprites
		lda #%00000011
		sta $d015
		
		cli			//enable interrupts
		


	//Inf loop
	!Loop:
		nop


		lda UpdateMapFlagSplit1
		beq !noshiftsplit1+
			dec UpdateMapFlagSplit1
			ldx MapPositionSplit1
			cpx #89						//MapPosition 89? (map ends here, because right side is 89 + 39= 128)
			bne !+
				ldx #$d9 				//negative value -39 (in ShiftSplit1 + 39 = 0), map start from 0 again
				stx MapPositionSplit1
			!:
			//---------------------------
			// SHIFT MAP of the Split 1
			//---------------------------
			jsr ShiftSplit1
	
	
	!noshiftsplit1:
		lda UpdateMapFlagSplit2
		beq !noshiftsplit2+				//if UpdateMapFlag is set --> shift the map
			dec UpdateMapFlagSplit2		//reset UpdateMapFlag
			ldx MapPositionSplit2
			cpx #129
			bne !+
				lda #$01
				sta MapPositionSplit2
			!:
			//---------------------------
			// SHIFT MAP of the Split 2
			//---------------------------
			jsr ShiftSplit2

	!noshiftsplit2:
	
		jmp !Loop- 
	

FillScreen: {
	.label ZPMapPointer = VECTOR1
	.label ZPScreenPointer = VECTOR2
	.label ZPColorPointer = VECTOR3
	
	stx TEMP1	//amount of rows (25)
		
	!loop:
		
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
		//for debugging
		lda #$07			//border color to yellow
		sta $d020
			
		txa			//X-Register = Mapposition 0,1,2,3,....88 
		clc
		adc #39		//Akku = 39,40, 41, 42 ,43,....127, 0
		tax			//back to X-Register
		
		.for(var i=0; i< 3; i++) {					//Row 0 - 3
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

		lda #$00			//border color to black
		sta $d020

		rts
}

//shifts to the right
ShiftSplit2: {
		//for debugging
		lda #$05			//border color to green
		sta $d020

		lda #128
		sec 
		sbc MapPositionSplit2
		tax						//X-Register = Mapposition 1 ...127 		1-->127; 2-->126  (X = 128 - X); 128 -->0; !!!!!129 -->
		


		.for(var i=5; i< 9; i++) {					//Row 5 - 8
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
		lda #$00			//border color to black
		sta $d020

		rts
}


SplitStartRows:
	.byte $01, $04



XScrollSplit1:
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


* = $c400 "Sprites"
	.import binary "..//assets/sprites/sprites.bin"

* = $8000 "CharMap"
CHAR_MAP:
	.import binary "../assets/maps/map.bin"
COLOR_MAP:
	.import binary "../assets/maps/cols.bin"	

* = $f000 "Charset"
	CHAR_SET:
		.import binary "../assets/maps/charset.bin" 

//This fixes the ghost byte issue on screen shake
//By forcing all IRQs to run indirectly from the last 
//page ensuring the ghost byte is always $FF
* = $fff0 "IRQ Indirect vector"
IRQ_Indirect:
	.label IRQ_LSB = $fff1
	.label IRQ_MSB = $fff2
	jmp $BEEF


