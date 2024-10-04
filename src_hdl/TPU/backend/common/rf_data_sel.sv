///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	RegFile
///////////////////////////////////////////////////////////////////////////////////////////////////

module RF_Data_Sel
	import pkg_tpu::*;
(
	input						I_Odd1,					//Flag of Odd for Srource-1
	input						I_Odd2,					//Flag of Odd for Srource-2
	input						I_Odd3,					//Flag of Odd for Srource-3
	input	data_t				I_Data_Src1,			//Read Index for Source-1
	input	data_t				I_Data_Src2,			//Read Index for Source-2
	input	data_t				I_Data_Src3,			//Read Index for Source-3
	input	data_t				I_Data_Src4,			//Read Index for Source-4
	output	data_t				O_Data_Src1,			//Read Index for Source-1
	output	data_t				O_Data_Src2,			//Read Index for Source-2
	output	data_t				O_Data_Src3				//Read Index for Source-3
);


	logic	[2:0]				Sel;


	assign Sel				= { I_Odd1, I_Odd2, I_Odd3 };

	always_comb begin
		case ( Sel )
			3'h0: begin
				assign O_Data_Src1	= I_Data_Src1;
				assign O_Data_Src2	= I_Data_Src2;
				assign O_Data_Src3	= '0;
			end
			3'h1: begin
				assign O_Data_Src1	= I_Data_Src1;
				assign O_Data_Src2	= I_Data_Src2;
				assign O_Data_Src3	= I_Data_Src3;
			end
			3'h2: begin
				assign O_Data_Src1	= O_Data_Src1;
				assign O_Data_Src2	= O_Data_Src3;
				assign O_Data_Src3	= O_Data_Src2;
			end
			3'h3: begin
				assign O_Data_Src1	= I_Data_Src1;
				assign O_Data_Src2	= I_Data_Src3;
				assign O_Data_Src3	= I_Data_Src4;
			end
			3'h4: begin
				assign O_Data_Src1	= I_Data_Src3;
				assign O_Data_Src2	= I_Data_Src2;
				assign O_Data_Src3	= I_Data_Src1;
			end
			3'h5: begin
				assign O_Data_Src1	= I_Data_Src3;
				assign O_Data_Src2	= I_Data_Src2;
				assign O_Data_Src3	= I_Data_Src4;
			end
			3'h6: begin
				assign O_Data_Src1	= I_Data_Src3;
				assign O_Data_Src2	= I_Data_Src4;
				assign O_Data_Src3	= I_Data_Src2;
			end
			3'h7: begin
				assign O_Data_Src1	= I_Data_Src3;
				assign O_Data_Src2	= I_Data_Src4;
				assign O_Data_Src3	= '0;
			end
		endcase
	end

endmodule