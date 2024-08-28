///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Des
///////////////////////////////////////////////////////////////////////////////////////////////////

module Des
#(
	parameter int WIDTH_INPUT		= 8,
	parameter int WIDTH_OUTPUT		= 32,
)(
	input							clock,
	input							reset
	input							I_Req,							//Request
	input	[WIDTH_INPUT-1:0]		I_Data,							//Serial Source
	output							O_Valid,						//Valid Output
	output	[WIDTH_OUTPUT-1:0]		O_Data							//De-serialized Data
);

	localparam int	ROUND_VAL		= (WIDTH_INPUT+1)/2;
	localparam int	COUNT_VAL		= (WIDTH_OUTPUT+ROUND_VAL)/WIDTH_INPUT;
	localparam int	WIDTH_COUNT		= $clog2(COUNT_VAL);



	logic	[WIDTH_OUTPUT-1:0]		Shift_Data;

	logic							Valid;

	logic	[WIDTH_COUNT-1:0]		Count;

	logic	[WIDTH_OUTPUT-1:0]		Data;


	assign Valid				= Count == COUNT_VAL;

	assign O_Valud				= Valid;
	assign O_Data				= ( Valid ) ? Data : '0;

	assign Shift_Data			= I_Data << ( WODTH_INPUT << Count );


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Data			<= 0;
		end
		else if ( Valid ) begin
			Data			<= 0;
		end
		else if ( I_Req ) begin
			Data			<= Data | Shift_Data;
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