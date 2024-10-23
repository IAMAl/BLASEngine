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
				O_Num = 0;
			end
			8'b??????10: begin
				O_Num = 1;
			end
			8'b?????100: begin
				O_Num = 2;
			end
			8'b????1000: begin
				O_Num = 3;
			end
			8'b???10000: begin
				O_Num = 4;
			end
			8'b??100000: begin
				O_Num = 5;
			end
			8'b?1000000: begin
				O_Num = 6;
			end
			8'b10000000: begin
				O_Num = 7;
			end
		endcase
	end

	assign O_Valid	= O_Num != 3'h0;

endmodule