///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Network_S
///////////////////////////////////////////////////////////////////////////////////////////////////

module Network_S
	import pkg_tpu::*;
#(
	parameter int NUM_LANES		= 16,
	parameter int WIDTH_LANES	= $clog2(NUM_LANES)
)(
	input						clock,
	input						reset,
	input						I_Stall,
	input						I_Req,					//Request from Reg-Read
	input	[1:0]				I_Sel_Path,				//Path Selects
	input	[1:0]				I_Sel_Path_WB,			//Path Selects
	input						I_Sel_ALU_Src1,			//Source Select
	input						I_Sel_ALU_Src2,			//Source Select
	input						I_Sel_ALU_Src3,			//Source Select
	input	data_t				I_Src_Data1,			//Data from RegFile
	input	data_t				I_Src_Data2,			//Data From RegFile
	input	data_t				I_Src_Data3,			//Data From RegFile
	input	index_t				I_Src_Idx1,				//Index from RegFile
	input	index_t				I_Src_Idx2,				//Index from RegFile
	input	index_t				I_Src_Idx3,				//Index from RegFile
	input	data_t				I_WB_Data,				//Data from ALU
	output	data_t				O_Src_Data1,			//To Exec Unit
	output	data_t				O_Src_Data2,			//To Exec Unit
	output	data_t				O_Src_Data3,			//To Exec Unit
	output						O_Buff_Full,			//Flag: Buffer is Full
	output	data_t				O_PAC_Src_Data			//Data to PAC Unit
);


	logic						Req;
	logic	[1:0]				Sel_Path;
	logic	[1:0]				Sel_Path_WB;

	index_t						Src_Index1;
	index_t						Src_Index2;
	index_t						Src_Index3;

	data_t						Src_Data1;
	data_t						Src_Data2;
	data_t						Src_Data3;


	assign Req					= I_Req;
	assign Sel_Path				= I_Sel_Path;
	assign Sel_Path_WB			= I_Sel_Path_WB;

	assign Src_Index1			= I_Src_Idx1;
	assign Src_Index2			= I_Src_Idx2;
	assign Src_Index3			= I_Src_Idx3;

	assign Src_Data1			= I_Src_Data1;
	assign Src_Data2			= I_Src_Data2;
	assign Src_Data3			= I_Src_Data3;

	assign O_PAC_Src_Data		=(    Sel_Path == 2'h1 ) ?		I_Src_Data1 :
									( Sel_Path == 2'h2 ) ?		I_Src_Data2 :
									( Sel_Path == 2'h3 ) ?		I_Src_Data3 :
																'0;

	assign O_WB_Data			= (   Sel_Path_WB == 2'h3 ) ?	I_Src_Data3 :
									( Sel_Path_WB == 2'h2 ) ?	I_Src_Data2 :
									( Sel_Path_WB == 2'h1 ) ?	I_Src_Data1 :
																I_WB_Data;


	BypassBuff #(
		.BUFF_SIZE(			BYPASS_BUFF_SIZE		)
	) BypassBuff
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_WB_Index(		I_WB_Index				),
		.I_WB_Data(			I_WB_Data				),
		.I_Idx1(			Src_Index1				),
		.I_Idx2(			Src_Index2				),
		.I_Idx3(			Src_Index3				),
		.I_Src1(			Src_Data1				),
		.I_Src2(			Src_Data2				),
		.I_Src3(			Src_Data3				),
		.O_Src1(			O_Src_Data1				),
		.O_Src2(			O_Src_Data2				),
		.O_Src3(			O_Src_Data3				),
		.O_Full(			O_Buff_Full				)
	);

endmodule