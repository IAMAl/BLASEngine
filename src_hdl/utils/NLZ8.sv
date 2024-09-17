///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	NLZ8
///////////////////////////////////////////////////////////////////////////////////////////////////

module NLZ8
(
	input	[8-1:0]				I_Data,				//Data
	output	reg [2:0]			O_Num,				//Number
	output	logic				O_Valid				//Flag: Validation
);

	always_comb begin
		case ( I_Data )
		8'b???????1: assign O_Num = 0;
		8'b??????10: assign O_Num = 1;
		8'b?????100: assign O_Num = 2;
		8'b????1000: assign O_Num = 3;
		8'b???10000: assign O_Num = 4;
		8'b??100000: assign O_Num = 5;
		8'b?1000000: assign O_Num = 6;
		8'b10000000: assign O_Num = 7;
		endcase
	end

	assign O_Valid	= O_Num != 3'h0;

endmodule