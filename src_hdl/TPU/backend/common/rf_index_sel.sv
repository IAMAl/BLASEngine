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

module RF_Index_Sel
	import pkg_tpu::*;
(
	input						I_Odd1,
	input						I_Odd2,
	input						I_Odd3,
	input	idx_t				I_Index_Src1,			//Read Index for Source-1
	input	idx_t				I_Index_Src2,			//Read Index for Source-2
	input	idx_t				I_Index_Src3,			//Read Index for Source-3
	output	idx_t				O_Index_Src1,			//Read Index for Source-1
	output	idx_t				O_Index_Src2,			//Read Index for Source-2
	output	idx_t				O_Index_Src3,			//Read Index for Source-3
	output	idx_t				O_Index_Src4			//Read Index for Source-4
);

	logic	[2:0]				Sel;


	assign Sel				= { I_Odd1, I_Odd2, I_Odd3 };

	always_comb begin
		case ( Sel )
			3'h0: begin
				assign O_Index_Src1	= I_Index_Src1;
				assign O_Index_Src2	= I_Index_Src2;
				assign O_Index_Src3	= '0;
				assign O_Index_Src4	= '0;
			end
			3'h1: begin
				assign O_Index_Src1	= I_Index_Src1;
				assign O_Index_Src2	= I_Index_Src2;
				assign O_Index_Src3	= I_Index_Src3;
				assign O_Index_Src4	= '0;
			end
			3'h2: begin
				assign O_Index_Src1	= I_Index_Src1;
				assign O_Index_Src2	= I_Index_Src3;
				assign O_Index_Src3	= I_Index_Src2;
				assign O_Index_Src4	= '0;
			end
			3'h3: begin
				assign O_Index_Src1	= I_Index_Src1;
				assign O_Index_Src2	= '0;
				assign O_Index_Src3	= I_Index_Src2;
				assign O_Index_Src4	= I_Index_Src3;
			end
			3'h4: begin
				assign O_Index_Src1	= I_Index_Src3;
				assign O_Index_Src2	= I_Index_Src2;
				assign O_Index_Src3	= I_Index_Src1;
				assign O_Index_Src4	= '0;
			end
			3'h5: begin
				assign O_Index_Src1	= '0;
				assign O_Index_Src2	= I_Index_Src2;
				assign O_Index_Src3	= I_Index_Src1;
				assign O_Index_Src4	= I_Index_Src3;
			end
			3'h6: begin
				assign O_Index_Src1	= '0;
				assign O_Index_Src2	= I_Index_Src3;
				assign O_Index_Src3	= I_Index_Src1;
				assign O_Index_Src4	= I_Index_Src2;
			end
			3'h7: begin
				assign O_Index_Src1	= '0;
				assign O_Index_Src2	= '0;
				assign O_Index_Src3	= I_Index_Src1;
				assign O_Index_Src4	= I_Index_Src2;
			end
		endcase
	end

endmodule