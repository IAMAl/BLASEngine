///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Counter
///////////////////////////////////////////////////////////////////////////////////////////////////

module Counter #(
	parameter int	WIDHT_COUNT	= 64;
)(
	input						clock,
	input						reset,
	input						I_Clr,					//Clear Counter
	input						I_En,					//Enable to Count
	output	[WIDHT_COUNT-1:0]	O_CountVal				//Count Value
);


	logic	[WIDHT_COUNT-1:0]	R_CountVal;


	assign O_CountVal			= R_CountVal;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_CountVal		<= 0;
		end
		else ( I_Clr ) begin
			R_CountVal		<= 0;
		end
		else if ( I_En ) begin
			R_CountVal		<= O_CountVal + 1'b1;
		end
	end

endmodule
