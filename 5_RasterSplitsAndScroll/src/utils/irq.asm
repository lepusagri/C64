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


	EnterButtomBorderIRQ: {
		sta ModA + 1
		stx ModX + 1
		sty ModY + 1

		//nur zum Testen (wenn ohne pixel scroll)
		//inc MapPosition
			
		
		lda UpdateMapFlag
		beq !noshift+
		dec UpdateMapFlag
		ldx MapPosition
		cpx #89
		bne !+
			//MapPosition 89
			ldx #$d9
			stx MapPosition
		!:
		jsr ShiftSplit1
	
	!noshift:		
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


	Split1IRQ: {		
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
			
			lda XScroll			//starts with 7,6.... (scrolls to the left side)
			//and #%11111111
			ora #%00011000
			sta $d016
			.break
			dec XScroll
			bne !+
				//now $d016 X-scroll is 0
				//X-Scroll-Offset is now 0
				inc MapPosition
				inc UpdateMapFlag
				//for next time
				lda #7
				sta XScroll
			
			!:
			lda #<EnterButtomBorderIRQ    
			ldx #>EnterButtomBorderIRQ
			sta IRQ_LSB   // $fff1 --> selfmod code (JMP $BEEF) at $fff0
			stx IRQ_MSB	// $fff2 --> selfmod code (JMP $BEEF) at $fff0

			lda #RASTERLINE_250
			sta $d012
			
			lda $d011
			and #%11111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
	
		:RestoreState();
		rti
	}


	XScrollSplit2:
		.byte $00

	Split2IRQ: {
		:StoreState()
			.break
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
			//and #%00000111
			ora #%00011000
			sta $d016
			inc XScrollSplit2


			lda #<Split3IRQ    
			ldx #>Split3IRQ
			sta IRQ_LSB   // 0314
			stx IRQ_MSB	// 0315

			lda #SPLIT_3_RASTERLINE  
			sta $d012
			
			lda $d011
			and #%01111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState()
		rti
	}


	Split3IRQ: {
		:StoreState()
			.break
			lda #%00011000
			sta $d016
			
			lda #<EnterButtomBorderIRQ 
			ldx #>EnterButtomBorderIRQ
			sta IRQ_LSB   // 0314
			stx IRQ_MSB	// 0315

			lda #RASTERLINE_250  
			sta $d012
			
			lda $d011
			and #%01111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState()
		rti
	}


}