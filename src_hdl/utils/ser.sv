///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Ser
///////////////////////////////////////////////////////////////////////////////////////////////////

module Ser
#(
	parameter int WIDTH_INPUT	= 32,
	parameter int WIDTH_OUTPUT	= 8,
)(
	input						clock,
	input						reset
	input						I_Req,				//Request
	input	[WIDTH_INPUT-1:0]	I_Data,				//Serial Source
	output						O_Valid,			//Valid Output
	output	[WIDTH_OUTPUT-1:0]	O_Data				//De-sirialized Data
);

	localparam int	ROUND_VAL	= (WIDTH_OUTPUT+1)/2;
	localparam int	COUNT_VAL	= (WIDTH_INPUT+ROUND_VAL)/WIDTH_OUTPUT;
	localparam int	WIDTH_COUNT	= $clog2(COUNT_VAL);


	logic	[WIDTH_COUNT-1:0]	Count;

	logic	[WIDTH_OUTPUT-1:0]	Data;


	assign Valid				= Count == COUNT_VAL;

	assign O_Valud				= Valid;
	assign O_Data				= ( Valid ) ? Data : '0;

	assign Index				= Count;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Data			<= 0;
		end
		else if ( Valid ) begin
			Data			<= 0;
		end
		else if ( I_Req ) begin
			Data[WIDTH_OUTPUT*(count+1)-1:WIDTH_OUTPUT*count]	<= I_Data;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Count			<= 0;
		end
		else if ( Valid ) begin
			Count			<= 0;
		end
		else if ( I_Req ) begin
			Count			<= Count + 1'b1;
		end
	end

endmodule