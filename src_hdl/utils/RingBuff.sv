///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	RingBuff
///////////////////////////////////////////////////////////////////////////////////////////////////

module RingBuff
#(
	parameter int NUM_ENTRY		= 16,
	parameter int WIDTH_ENTRY	= $clog2(NUM_ENTRY),
	parameter type TYPE			= logic[31:0]
)(
	input						clock,
	input						reset,
	input						I_We,				//Write-Enable
	input						I_Re,				//Read-Enable
	input	TYPE				I_Data,				//Input Data
	output	TYPE				O_Data,				//Output Data
	output						O_Full,				//Flag: Full
	output						O_Empty,			//Flag: Empty
    output  [WIDTH_ENTRY:0]		O_Num				//Remained Number of Entries
);


	TYPE	Data				[NUM_ENTRY-1:0];

	logic	[WIDTH_ENTRY-1:0]	WPtr;
	logic	[WIDTH_ENTRY-1:0]	RPtr;


	assign O_Data				= ( I_Re ) ? Data[ RPtr ] : '0;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Data[ i ]	<= '0;
			end
		end
		else if ( I_We ) begin
			Data[ WPtr ]	<= I_Data;
		end
	end


	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY					)
	) RingBuffCTRL
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				I_We						),
		.I_Re(				I_Re						),
		.O_WAddr(			WPtr						),
		.O_RAddr(			RPtr						),
		.O_Full(			O_Full						),
		.O_Empty(			O_Empty						),
		.O_Num(				O_Num						)
	);

endmodule