.label SCREEN_RAM = $c000
.label SPRITE_POINTERS = SCREEN_RAM + $3f8


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
		lda #$0e //hellblau
		sta VIC.BACKGROUND_COLOR
		
		lda #$01 //white	
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
		lda $dd00
		and #%11111100
		sta $dd00 

		//Set screen and character memory
		lda #%00001100
		sta VIC.MEMORY_SETUP


	//Inf loop
	!Loop:
		nop

		jmp !Loop- 
	




//This fixes the ghost byte issue on screen shake
//By forcing all IRQs to run indirectly from the last 
//page ensuring the ghost byte is always $FF
* = $fff0 "IRQ Indirect vector"
IRQ_Indirect:
	.label IRQ_LSB = $fff1
	.label IRQ_MSB = $fff2
	jmp $BEEF


