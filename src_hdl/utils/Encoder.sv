///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Encoder
///////////////////////////////////////////////////////////////////////////////////////////////////

module Encoder
#(
	parameter int NUM_ENTRY			= 8
)(
	input	[NUM_ENTRY-1:0]			I_Data,							//Encode-Source
	output	[$clog2(NUM_ENTRY)-1:0]	O_Enc							//Encoded Value
);


	logic [NUM_ENTRY-1:0]			FlatData	[NUM_ENTRY-1:0];
	logic [$clog2(NUM_ENTRY)-1:0]	Enc			[NUM_ENTRY-1:0];
	logic [NUM_ENTRY-1:0]			ExchangeEnc [$clog2(NUM_ENTRY)-1:0];
	logic [$clog2(NUM_ENTRY)-1:0]	No;


	//// Generating Priority										////
	//	 always statemant can not handle dynamic range
	for ( genvar index = 0; index < NUM_ENTRY; ++index ) begin
		assign FlatData[ index ] = '0 | I_Data[ index:0 ];
	end


	//// Encoding width Priority									////
	//	 Most significant bit have priority
	for ( genvar index = 1; index < NUM_ENTRY; ++index ) begin
		assign Enc[ index ] = ( I_Data[ index ] & ( FlatData[ index-1 ] == 0 )) ? index : 0;
	end
	assign Enc[ 0 ] = 0;

	for ( genvar cross_index = 0; cross_index < $clog2(NUM_ENTRY); ++cross_index ) begin
		for ( genvar index = 0; index < NUM_ENTRY; ++index ) begin
			assign ExchangeEnc[ cross_index ][ index ] = Enc[ index ][ cross_index ];
		end
	end


	//// Encoding width Priority									////
	//	 Assumumtion: I_Data is one-hot code
	for ( genvar cross_index = 0; cross_index < $clog2(NUM_ENTRY); ++cross_index ) begin
			assign No[ cross_index ] = |ExchangeEnc[ cross_index ];
	end
	assign O_Enc	= No;

endmodule