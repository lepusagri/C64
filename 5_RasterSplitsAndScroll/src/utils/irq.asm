.label RASTERLINE_250 = 250
.label FIRST_SCREEN_RASTERLINE = 51
.label SPLIT_1_RASTERLINE = FIRST_SCREEN_RASTERLINE -1	//50
.label SPLIT_2_RASTERLINE = SPLIT_1_RASTERLINE + 5*8	//90
.label SPLIT_3_RASTERLINE = SPLIT_2_RASTERLINE + 5*8	//130
.label Split2StartRow = SplitStartRows +1

IRQ: {

	Setup: {
		sei
		
		lda #$7f	//Disable CIA IRQ's to prevent crash because 
		sta $dc0d
		sta $dd0d

		lda $d01a		//Enable Raster-Interrupt
		ora #%00000001	
		sta $d01a

		lda #<EnterTopBorderIRQ    
		ldx #>EnterTopBorderIRQ
		sta IRQ_LSB   //$fff1 --> LO_BYTE of the JMP $BEEF 
		stx IRQ_MSB	// $fff2  --> HI_BYTE of the JMP $BEEF


		lda #<IRQ_Indirect //$fff0
		sta $fffe
		lda #>IRQ_Indirect
		sta $ffff
		// wenn also der IRQ ausgelöst wird, dann wird immer nach $fff0 gesprungen. Dort wartet ein JMP $BEEF Befehl

		lda #0
		sta $d012
		
		lda $d011
		and #$7f
		sta $d011	


		asl $d019
		//cli
		rts
	}


	//Rater at 0: enable top border sprites
	EnterTopBorderIRQ: {		
			sta ModA + 1
			stx ModX + 1
			sty ModY + 1

			//enable all sprites
			lda #%11111111
			sta $d015
		
			
			lda $d011
			ora #%00001000	// 25 Zeilenmodus
			and #$7f
			sta $d011

					
			lda #<Split1IRQ    
			ldx #>Split1IRQ
			sta IRQ_LSB   // $fff1 --> selfmod code (JMP $BEEF) at $fff0
			stx IRQ_MSB	// $fff2 --> selfmod code (JMP $BEEF) at $fff0

			lda #SPLIT_1_RASTERLINE
			sta $d012
			
			
		ModA:
			lda #$00
		ModX:
			ldx #$00
		ModY:
			ldy #$00
			asl $d019
			rti
	}

	//Rater at 50 : scroll to left (1 line before screen)
	Split1IRQ: {		
			sta ModA + 1
			stx ModX + 1
			sty ModY + 1

			//disable the top border sprites (because of ghosting in buttom border)
			lda #%00000011
			sta $d015
		

			//background color to blue
			lda #$06//#$03
			sta $d021

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
		
			lda XScrollSplit1
			//starts with 7,6.... (scrolls to the left side)
			ora #%00010000
			sta $d016
			dec XScrollSplit1

			bne !+
				//now $d016 X-scroll is 0
				//X-Scroll-Offset is now 0
				inc MapPositionSplit1
				inc UpdateMapFlagSplit1
				//for next time
				lda #7
				sta XScrollSplit1
		
		!:
			lda #<Split2IRQ    
			ldx #>Split2IRQ
			sta IRQ_LSB   // $fff1 --> selfmod code (JMP $BEEF) at $fff0
			stx IRQ_MSB	// $fff2 --> selfmod code (JMP $BEEF) at $fff0

			lda #SPLIT_2_RASTERLINE
			sta $d012
			
			lda $d011
			and #%11111111
			sta $d011	

		ModA:
			lda #$00
		ModX:
			ldx #$00
		ModY:
			ldy #$00
			asl $d019
			rti
	}

	//Rater at 90: scroll to right (1 line before 6th char row)
	Split2IRQ: {
			sta ModA + 1
			stx ModX + 1
			sty ModY + 1
			
			lda XScrollSplit2
			ora #%00010000
			sta $d016
			
			inc XScrollSplit2
			
			cmp #%00010111	//X-Scroll max reached
			bne !+
				inc MapPositionSplit2
				inc UpdateMapFlagSplit2
				lda #$00
				sta XScrollSplit2
			
		!:
			lda #<Split3IRQ 
			ldx #>Split3IRQ
			sta IRQ_LSB   // 0314
			stx IRQ_MSB	// 0315

			lda #SPLIT_3_RASTERLINE 
			sta $d012
			
		ModA:
			lda #$00
		ModX:
			ldx #$00
		ModY:
			ldy #$00
			asl $d019
			rti
	}


	//Rater at 130: no scrolling (1 line before 11th char row)
	Split3IRQ: {
			sta ModA + 1
			stx ModX + 1
			sty ModY + 1
			
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
			
			
			lda #%00010000
			sta $d016
			
			//background color: black
			lda #$00
			sta $d021

			//multicolor1 : grey
			lda #$0c
			sta $d022

			//multicolor1 : grey
			lda #$0f
			sta $d023
			

			lda #<EnterButtomBorderIRQ 
			ldx #>EnterButtomBorderIRQ
			sta IRQ_LSB   
			stx IRQ_MSB	

			lda #RASTERLINE_250 
			sta $d012

		ModA:
			lda #$00
		ModX:
			ldx #$00
		ModY:
			ldy #$00
			asl $d019
			rti
	}


	//info: raster is outside of the 'character screen' (40x25)
	//here we can shift character, change colors, .... (Attention: finish before Rasterline 51)
	EnterButtomBorderIRQ: {
			sta ModA + 1
			stx ModX + 1
			sty ModY + 1

			lda $d011
			and #%11110111					//schalte in 24-Zeilenmodus
			sta $d011

			//sprite 1 -X:
			inc $d000		//255->0
			bne !+
				lda $d010
				eor #%00000001
				sta $d010
			!:

			dec $d002
			bne !+
				lda $d010
				eor #%00000010
				sta $d010
			!:


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
			



			lda #$0a
			sta VIC.EXTENDED_BG_COLOR_1
			lda #$09
			sta VIC.EXTENDED_BG_COLOR_2
			
			
			lda #<EnterTopBorderIRQ    
			ldx #>EnterTopBorderIRQ
			sta IRQ_LSB   					// $fff1 --> selfmod code (JMP $BEEF) at $fff0
			stx IRQ_MSB						// $fff2 --> selfmod code (JMP $BEEF) at $fff0

			lda #0
			sta $d012


		
		ModA:
			lda #$00
		ModX:
			ldx #$00
		ModY:
			ldy #$00
			asl $d019
	
			rti
	}



}