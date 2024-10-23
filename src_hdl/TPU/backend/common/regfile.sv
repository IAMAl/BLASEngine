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

module RegFile
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Req,					//Request from Index Stage
	input						I_We,					//Flag: Write=Enable
	input	dst_t				I_Index_Dst,			//Write Index for Destination
	input	data_t				I_Data,					//Write-Back Data
	input	idx_t				I_Index_Src1,			//Read Index for Source-1
	input	idx_t				I_Index_Src2,			//Read Index for Source-2
	output	data_t				O_Data_Src1,			//Data of Source-1
	output	data_t				O_Data_Src2				//Data of Source-2
);


	logic						Re1;
	logic						Re2;
	data_t						Data_Src1;
	data_t						Data_Src2;

	data_t						R_Data_Src1;
	data_t						R_Data_Src2;


	assign Re1					= I_Req & I_Index_Src1.v & ( I_Index_Src1.src_sel.no == 2'h1 );
	assign Re2					= I_Req & I_Index_Src2.v & ( I_Index_Src2.src_sel.no == 2'h1 );

	assign O_Data_Src1			= Data_Src1;

	assign O_Data_Src2			= Data_Src2;


	BareRegFile RegFile (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				I_We					),
		.I_Re1(				Re1						),
		.I_Re2(				Re2						),
		.I_Index_Dst(		I_Index_Dst				),
		.I_Data(			I_Data					),
		.I_Index_Src1(		I_Index_Src1			),
		.I_Index_Src2(		I_Index_Src2			),
		.O_Data_Src1(		Data_Src1				),
		.O_Data_Src2(		Data_Src2				)
	);

endmodule