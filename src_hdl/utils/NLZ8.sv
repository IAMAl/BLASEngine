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
	output						O_Valid				//Flag: Validation
);


	always_comb begin
		case ( I_Data )
			8'b???????1: begin
				O_Num = 3'h0;
			end
			8'b??????10: begin
				O_Num = 3'h1;
			end
			8'b?????100: begin
				O_Num = 3'h2;
			end
			8'b????1000: begin
				O_Num = 3'h3;
			end
			8'b???10000: begin
				O_Num = 3'h4;
			end
			8'b??100000: begin
				O_Num = 3'h5;
			end
			8'b?1000000: begin
				O_Num = 3'h6;
			end
			8'b10000000: begin
				O_Num = 3'h7;
			end
			default: begin
				O_Num = 3'h0;
			end
		endcase
	end

	assign O_Valid	= I_Data != 8'h0;

endmodule