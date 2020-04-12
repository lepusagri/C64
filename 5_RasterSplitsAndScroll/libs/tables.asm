TABLES: {
	TileScreenLocations2x2:
		.byte 0,1,40,41		//Table to speed up tile to screen location conversion
	ScreenRowLSB:
		.fill 25, <[$c000 + i * 40]
	ScreenRowMSB:
		.fill 25, >[$c000 + i * 40]
	
	ColorRowLSB:
		.fill 25, <[$d800 + i * 40]
	ColorRowMSB:
		.fill 25, >[$d800 + i * 40]
	

	/*BufferLSB:
		.fill 25, <[MAPLOADER.BUFFER + i * 40]
	BufferMSB:
		.fill 25, >[MAPLOADER.BUFFER + i * 40]
	*/
	
	PowerOfTwo:
		.byte 1,2,4,8,16,32,64,128
	InvPowerOfTwo:
		.byte 255-1, 255-2, 255-4, 255-8, 255-16, 255-32, 255-64, 255-128

	Plus:
		.fill 256, i

		

}



