IRQ: {
	Setup: {
		sei
		
		lda #$7f	//Disable CIA IRQ's to prevent crash because 
		sta $dc0d
		sta $dd0d

		lda $d01a
		ora #%00000001	
		sta $d01a

		lda #<MainIRQ    
		ldx #>MainIRQ
		sta IRQ_LSB   //$fff1 --> LO_BYTE of the JMP $BEEF 
		stx IRQ_MSB	// $fff2  --> HI_BYTE of the JMP $BEEF


		lda #<IRQ_Indirect //$fff0
		sta $fffe
		lda #>IRQ_Indirect
		sta $ffff
		// wenn also der IRQ ausgelöst wird, dann wird immer nach $fff0 gesprungen. Dort wartet ein JMP $BEEF Befehl

		lda #60  //Rasterzeile 60
		sta $d012
		
		lda $d011
		and #%01111111
		sta $d011	

		asl $d019
		cli
		rts
	}


	MainIRQ: {		
		:StoreState()

			ldx #$07 //gelb
			stx VIC.BACKGROUND_COLOR

			lda #<SecondIRQ    
			ldx #>SecondIRQ
			sta IRQ_LSB   // $fff1 --> selfmod code (JMP $BEEF) at $fff0
			stx IRQ_MSB	// $fff2 --> selfmod code (JMP $BEEF) at $fff0

			lda #120
			sta $d012
			
			lda $d011
			and #%11111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState();
		rti
	}


	SecondIRQ: {
		:StoreState()
			//Reset Values set by IRQ	
			lda #LIGHT_BLUE
			sta VIC.BACKGROUND_COLOR
			
			lda #<MainIRQ    
			ldx #>MainIRQ
			sta IRQ_LSB   // 0314
			stx IRQ_MSB	// 0315

			lda #60  //Rasterline 60
			sta $d012
			
			lda $d011
			and #%01111111
			sta $d011	

			asl $d019 //Acknowledging the interrupt
		:RestoreState()
		rti
	}

}