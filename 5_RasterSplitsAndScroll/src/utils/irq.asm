IRQ: {



	Setup: {
		sei
		
		lda #$7f	//Disable CIA IRQ's to prevent crash because 
		sta $dc0d
		sta $dd0d

		lda $d01a		//Enable Raster-Interrupt
		ora #%00000001	
		sta $d01a

		lda #<EnterButtomBorderIRQ    
		ldx #>EnterButtomBorderIRQ
		sta IRQ_LSB   //$fff1 --> LO_BYTE of the JMP $BEEF 
		stx IRQ_MSB	// $fff2  --> HI_BYTE of the JMP $BEEF


		lda #<IRQ_Indirect //$fff0
		sta $fffe
		lda #>IRQ_Indirect
		sta $ffff
		// wenn also der IRQ ausgelöst wird, dann wird immer nach $fff0 gesprungen. Dort wartet ein JMP $BEEF Befehl

		lda #RASTERLINE_250
		sta $d012
		
		lda $d011
		and #$7f
		sta $d011	


		asl $d019
		//cli
		rts
	}

	//info: raster is out of the 'character screen' (40x25)
	//here we can shift character, change colors, .... (Attention: finish before Rasterline 51)
	EnterButtomBorderIRQ: {
			sta ModA + 1
			stx ModX + 1
			sty ModY + 1

			lda $d011
			and #%11110111					//schalte in 24-Zeilenmodus
			sta $d011

			lda #$06
			sta $d020
			
			lda #$0a
			sta VIC.EXTENDED_BG_COLOR_1
			lda #$09
			sta VIC.EXTENDED_BG_COLOR_2

			
			//inc MapPosition				//only for testing, if pixel scroll is not active
			
			lda UpdateMapFlagSplit1
			beq !noshiftsplit1+
				dec UpdateMapFlagSplit1
				ldx MapPositionSplit1
				cpx #89						//MapPosition 89?
				bne !+
					ldx #$d9 				//negative value -39 (in ShiftSplit1 + 39 = 0), map start from 0 again
					stx MapPositionSplit1
		!:
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
				jsr ShiftSplit2


		!noshiftsplit2:
			lda #<Split1IRQ    
			ldx #>Split1IRQ
			sta IRQ_LSB   					// $fff1 --> selfmod code (JMP $BEEF) at $fff0
			stx IRQ_MSB						// $fff2 --> selfmod code (JMP $BEEF) at $fff0

			lda #SPLIT_1_RASTERLINE
			sta $d012

			lda #$01
			sta $d020

			//warte bis Raster > 255
			lda #$ff
			lda $d011
			bpl *-3

			lda $d011
			ora #%00001000
			and #$7f
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


	Split1IRQ: {		
			sta ModA + 1
			stx ModX + 1
			sty ModY + 1

			//background color to light blue
			lda #$03
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
		
			lda XScroll			//starts with 7,6.... (scrolls to the left side)
			ora #%00010000
			sta $d016
			dec XScroll
			bne !+
				//now $d016 X-scroll is 0
				//X-Scroll-Offset is now 0
				inc MapPositionSplit1
				inc UpdateMapFlagSplit1
				//for next time
				lda #7
				sta XScroll
		
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



	Split2IRQ: {
		:StoreState()
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
			
			lda $d011
			and #$7f
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState()
		rti
	}


	Split3IRQ: {
		:StoreState()
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
			sta IRQ_LSB   // 0314
			stx IRQ_MSB	// 0315

			lda #RASTERLINE_250  
			sta $d012
			
			lda $d011
			and #$7f
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState()
		rti
	}


}