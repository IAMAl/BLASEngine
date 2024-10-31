///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Network_V
///////////////////////////////////////////////////////////////////////////////////////////////////

module Network_V
	import pkg_tpu::*;
#(
	parameter int NUM_LANES		= 16,
	parameter int WIDTH_LANES	= $clog2(NUM_LANES),
	parameter int LANE_ID		= 0
)(
	input						clock,
	input						reset,
	input						I_Stall,
	input	pipe_net_t			I_Command,				//Command
	input						I_Req,					//Request from Reg-Read
	input	[6:0]				I_Sel_Path,				//Path Selects
	input	[4:0]				I_Sel_Path_WB,			//Path Selects
	input	data_t				I_Scalar_Data,			//Data from Scalar Unit
	input	lane_t				I_Lane_Data_Src1,		//Lane Data
	input	lane_t				I_Lane_Data_Src2,		//Lane Data
	input	lane_t				I_Lane_Data_Src3,		//Lane Data
	input	lane_t				I_Lane_Data_WB,			//Lane Data
	input	dst_t				I_WB_Index,				//Write-Back Index
	input	data_t				I_WB_Data,				//Write-Back Data
	output	data_t				O_WB_Data,				//To RF Unit
	output	data_t				O_Src_Data1,			//To Exec Unit
	output	data_t				O_Src_Data2,			//To Exec Unit
	output	data_t				O_Src_Data3,			//To Exec Unit
	output	data_t				O_Lane_Data_Src1,		//Lane Data
	output	data_t				O_Lane_Data_Src2,		//Lane Data
	output	data_t				O_Lane_Data_Src3,		//Lane Data
	output	data_t				O_Lane_Data_WB,			//Lane Data
	output						O_Buff_Full
);


	logic						Req;
	logic	[4:0]				Sel_Path;

	logic	[1:0]				Sel_Scalar;
	logic						Sel_Scalar_Src1;
	logic						Sel_Scalar_Src2;
	logic						Sel_Scalar_Src3;

	idx_t						Src_Index1;
	idx_t						Src_Index2;
	idx_t						Src_Index3;

	data_t						Src_Data1;
	data_t						Src_Data2;
	data_t						Src_Data3;

	data_t						Path_Src_Data1;
	data_t						Path_Src_Data2;
	data_t						Path_Src_Data3;

	index_t						Slice_Len;


	assign Req					= I_Command.v;

	assign Sel_Scalar			= I_Sel_Path[1:0];

	assign Sel_Path				= I_Sel_Path[6:2];

	assign Sel_Scalar_Src1		= Req & I_Command.command.instr.src1.v & ( Sel_Scalar == 2'h1 );
	assign Sel_Scalar_Src2		= Req & I_Command.command.instr.src2.v & ( Sel_Scalar == 2'h2 );
	assign Sel_Scalar_Src3		= Req & I_Command.command.instr.src3.v & ( Sel_Scalar == 2'h3 );


	assign Src_Index1			= I_Command.command.instr.src1;
	assign Src_Index2			= I_Command.command.instr.src2;
	assign Src_Index3			= I_Command.command.instr.src3;

	assign Src_Data1			= I_Command.data1;
	assign Src_Data2			= I_Command.data2;
	assign Src_Data3			= I_Command.data3;

	assign Slice_Len			= I_Command.command.instr.slice_len;


	PathSel #(
		.LANE_ID(			LANE_ID					)
	) PathSel
	(
		.I_Req(				Req						),
		.I_Sel_Path(		Sel_Path				),
		.I_Sel_Path_WB(		I_Sel_Path_WB			),
		.I_Scalar_Data(		I_Scalar_Data			),
		.I_Lane_Data_Src1(	I_Lane_Data_Src1		),
		.I_Lane_Data_Src2(	I_Lane_Data_Src2		),
		.I_Lane_Data_Src3(	I_Lane_Data_Src3		),
		.I_Lane_Data_WB(	I_Lane_Data_WB			),
		.I_Src_Data1(		Src_Data1				),
		.I_Src_Data2(		Src_Data2				),
		.I_Src_Data3(		Src_Data3				),
		.I_WB_Data(			I_WB_Data				),
		.O_Src_Data1(		Path_Src_Data1			),
		.O_Src_Data2(		Path_Src_Data2			),
		.O_Src_Data3(		Path_Src_Data3			),
		.O_WB_Data(			O_WB_Data				),
		.O_Lane_Data_Src1(	O_Lane_Data_Src1		),
		.O_Lane_Data_Src2(	O_Lane_Data_Src2		),
		.O_Lane_Data_Src3(	O_Lane_Data_Src3		),
		.O_Lane_Data_WB(	O_Lane_Data_WB			)
	);


	BypassBuff #(
		.BUFF_SIZE(			BYPASS_BUFF_SIZE		)
	) BypassBuff
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_WB_Index(		I_WB_Index				),
		.I_WB_Data(			I_WB_Data				),
		.I_Slice_Len(		Slice_Len				),
		.I_Idx1(			Src_Index1				),
		.I_Idx2(			Src_Index2				),
		.I_Idx3(			Src_Index3				),
		.I_Src1(			Path_Src_Data1			),
		.I_Src2(			Path_Src_Data2			),
		.I_Src3(			Path_Src_Data3			),
		.O_Src1(			O_Src_Data1				),
		.O_Src2(			O_Src_Data2				),
		.O_Src3(			O_Src_Data3				),
		.O_Full(			O_Buff_Full				)
	);

endmodule