///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	RF_Index_Sel
///////////////////////////////////////////////////////////////////////////////////////////////////

module RF_Index_Sel
	import pkg_tpu::*;
(
	input						I_Odd1,					//Flag of Odd for Srource-1
	input						I_Odd2,					//Flag of Odd for Srource-2
	input						I_Odd3,					//Flag of Odd for Srource-3
	input	idx_t				I_Index_Src1,			//Read Index for Source-1
	input	idx_t				I_Index_Src2,			//Read Index for Source-2
	input	idx_t				I_Index_Src3,			//Read Index for Source-3
	output	idx_t				O_Index_Src1,			//Read Index for Source-1
	output	idx_t				O_Index_Src2,			//Read Index for Source-2
	output	idx_t				O_Index_Src3,			//Read Index for Source-3
	output	idx_t				O_Index_Src4			//Read Index for Source-4
);


	logic	[2:0]				Sel;


	assign Sel				= { I_Odd3, I_Odd2, I_Odd1 };

	always_comb begin
		case ( Sel )
			3'h0: begin
				O_Index_Src1	= I_Index_Src1;
				O_Index_Src2	= I_Index_Src2;
				O_Index_Src3	= '0;
				O_Index_Src4	= '0;
			end
			3'h1: begin
				O_Index_Src1	= I_Index_Src1;
				O_Index_Src2	= I_Index_Src2;
				O_Index_Src3	= I_Index_Src3;
				O_Index_Src4	= '0;
			end
			3'h2: begin
				O_Index_Src1	= I_Index_Src1;
				O_Index_Src2	= I_Index_Src3;
				O_Index_Src3	= I_Index_Src2;
				O_Index_Src4	= '0;
			end
			3'h3: begin
				O_Index_Src1	= I_Index_Src1;
				O_Index_Src2	= '0;
				O_Index_Src3	= I_Index_Src2;
				O_Index_Src4	= I_Index_Src3;
			end
			3'h4: begin
				O_Index_Src1	= I_Index_Src3;
				O_Index_Src2	= I_Index_Src2;
				O_Index_Src3	= I_Index_Src1;
				O_Index_Src4	= '0;
			end
			3'h5: begin
				O_Index_Src1	= '0;
				O_Index_Src2	= I_Index_Src2;
				O_Index_Src3	= I_Index_Src1;
				O_Index_Src4	= I_Index_Src3;
			end
			3'h6: begin
				O_Index_Src1	= '0;
				O_Index_Src2	= I_Index_Src3;
				O_Index_Src3	= I_Index_Src1;
				O_Index_Src4	= I_Index_Src2;
			end
			3'h7: begin
				O_Index_Src1	= '0;
				O_Index_Src2	= '0;
				O_Index_Src3	= I_Index_Src1;
				O_Index_Src4	= I_Index_Src2;
			end
		endcase
	end

endmodule