IRQ: {

	XScroll:
		.byte $07
		


	Setup: {
		sei
		
		lda #$7f	//Disable CIA IRQ's to prevent crash because 
		sta $dc0d
		sta $dd0d

		lda $d01a		//Enable Raster-Interrupt
		ora #%00000001	
		sta $d01a

		lda #<Split1IRQ    
		ldx #>Split1IRQ
		sta IRQ_LSB   //$fff1 --> LO_BYTE of the JMP $BEEF 
		stx IRQ_MSB	// $fff2  --> HI_BYTE of the JMP $BEEF


		lda #<IRQ_Indirect //$fff0
		sta $fffe
		lda #>IRQ_Indirect
		sta $ffff
		// wenn also der IRQ ausgelöst wird, dann wird immer nach $fff0 gesprungen. Dort wartet ein JMP $BEEF Befehl

		lda #SPLIT_1_RASTERLINE  
		sta $d012
		
		lda $d011
		and #$7f
		sta $d011	

		asl $d019
		cli
		rts
	}


	Split1IRQ: {		
		:StoreState()

			//ldx #$0c //grey
			//stx VIC.BACKGROUND_COLOR

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
			

			lda XScroll
			//and #%11101111
			ora #%00011000
			sta $d016
			dec XScroll
			bne !+

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

			asl $d019 //Acknowledging the interrupt
	
		:RestoreState();
		rti
	}


	XScrollSplit2:
		.byte $00

	Split2IRQ: {
		:StoreState()
			//Reset Values set by IRQ	
			lda #$00
			sta VIC.BACKGROUND_COLOR
			
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
			//Reset Values set by IRQ	
			lda #$00
			sta VIC.BACKGROUND_COLOR
			
			lda #%00011000
			sta $d016
			
			lda #<Split1IRQ    
			ldx #>Split1IRQ
			sta IRQ_LSB   // 0314
			stx IRQ_MSB	// 0315

			lda #SPLIT_1_RASTERLINE  
			sta $d012
			
			lda $d011
			and #%01111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState()
		rti
	}


}