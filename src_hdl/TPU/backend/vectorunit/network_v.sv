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
	input						I_Req,
	input	[12:0]				I_Sel_Path,						//Path Selects
	input	data_t				I_Scalar_Data,					//Data from Scalar Unit
	input						I_Sel_ALU_Src1,					//Source Select
	input						I_Sel_ALU_Src2,					//Source Select
	input						I_Sel_ALU_Src3,					//Source Select
	input	lane_t				I_Lane_Data_Src1,				//Lane Data
	input	lane_t				I_Lane_Data_Src2,				//Lane Data
	input	lane_t				I_Lane_Data_Src3,				//Lane Data
	input	data_t				I_Src_Data1,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data2,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data3,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data4,					//From RegFile after Rotation Path
	input	inex_t				I_Src_Idx1,						//Index from RegFile
	input	inex_t				I_Src_Idx2,						//Index from RegFile
	input	inex_t				I_Src_Idx3,						//Index from RegFile
	input	inex_t				I_Src_Idx4,						//Index from RegFile
	input	index_t				I_WB_DstIdx,					//Index from ALU
	input	data_t				I_WB_Data,						//Data from ALU
	output	data_t				O_Src_Data1,					//To Exec Unit
	output	data_t				O_Src_Data2,					//To Exec Unit
	output	data_t				O_Src_Data3,					//To Exec Unit
	output	data_t				O_Lane_Data_Src1,				//Lane Data
	output	data_t				O_Lane_Data_Src2,				//Lane Data
	output	data_t				O_Lane_Data_Src3				//Lane Data
);


	logic						Req;
	logic	[4:0]				Sel_Path;

	logic	[1:0]				Sel_Scalar;
	logic						Sel_Scalar_Src1;
	logic						Sel_Scalar_Src2;
	logic						Sel_Scalar_Src3;

	logic	[1:0]				Sel_Path_Src1;
	logic	[1:0]				Sel_Path_Src2;
	logic	[1:0]				Sel_Path_Src3;

	data_t						Src_Data1;
	data_t						Src_Data2;
	data_t						Src_Data3;

	index_t						Src_Index1;
	index_t						Src_Index2;
	index_t						Src_Index3;

	logic						Sel_Src1_Data1;
	logic						Sel_Src1_Data2;
	logic						Sel_Src1_Data3;
	logic						Sel_Src1_Data4;

	logic						Sel_Src2_Data1;
	logic						Sel_Src2_Data2;
	logic						Sel_Src2_Data3;
	logic						Sel_Src2_Data4;

	logic						Sel_Src3_Data1;
	logic						Sel_Src3_Data2;
	logic						Sel_Src3_Data3;
	logic						Sel_Src3_Data4;

	logic						Sel_WB_Data1;
	logic						Sel_WB_Data2;
	logic						Sel_WB_Data3;

	data_t						Path_Src_Data1;
	data_t						Path_Src_Data2;
	data_t						Path_Src_Data3;


	assign Req					= I_Req;

	assign Sel_Path_Src1		= I_Sel_Path[1:0];
	assign Sel_Path_Src2		= I_Sel_Path[3:2];
	assign Sel_Path_Src3		= I_Sel_Path[5:4];

	assign Sel_Scalar			= I_Sel_Path[7:6];

	assign Sel_Path				= I_Sel_Path[12:8];

	assign Sel_Scalar_Src1		= Req & I_Sel_ALU_Src1 & ( Sel_Scalar == 2'h1 );
	assign Sel_Scalar_Src2		= Req & I_Sel_ALU_Src2 & ( Sel_Scalar == 2'h2 );
	assign Sel_Scalar_Src3		= Req & I_Sel_ALU_Src3 & ( Sel_Scalar == 2'h3 );

	assign Sel_Src1_Data1		= Req & I_Sel_ALU_Src1 & ( Sel_Path_Src1 == 2'h0 );
	assign Sel_Src1_Data2		= Req & I_Sel_ALU_Src1 & ( Sel_Path_Src1 == 2'h1 );
	assign Sel_Src1_Data3		= Req & I_Sel_ALU_Src1 & ( Sel_Path_Src1 == 2'h2 );
	assign Sel_Src1_Data4		= Req & I_Sel_ALU_Src1 & ( Sel_Path_Src1 == 2'h3 );

	assign Sel_Src2_Data1		= Req & I_Sel_ALU_Src2 & ( Sel_Path_Src2 == 2'h0 );
	assign Sel_Src2_Data2		= Req & I_Sel_ALU_Src2 & ( Sel_Path_Src2 == 2'h1 );
	assign Sel_Src2_Data3		= Req & I_Sel_ALU_Src2 & ( Sel_Path_Src2 == 2'h2 );
	assign Sel_Src2_Data4		= Req & I_Sel_ALU_Src2 & ( Sel_Path_Src2 == 2'h3 );

	assign Sel_Src3_Data1		= Req & I_Sel_ALU_Src3 & ( Sel_Path_Src3 == 2'h0 );
	assign Sel_Src3_Data2		= Req & I_Sel_ALU_Src3 & ( Sel_Path_Src3 == 2'h1 );
	assign Sel_Src3_Data3		= Req & I_Sel_ALU_Src3 & ( Sel_Path_Src3 == 2'h2 );
	assign Sel_Src3_Data4		= Req & I_Sel_ALU_Src3 & ( Sel_Path_Src3 == 2'h3 );


	assign Src_Index1			= ( Sel_Src1_Data1 ) ?		I_Src_Idx1 ;
									( Sel_Src1_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src1_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src1_Data4 ) ?	I_Src_Idx4 ;
															'0;

	assign Src_Index2			= ( Sel_Src2_Data1 ) ?		I_Src_Idx1 ;
									( Sel_Src2_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src2_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src2_Data4 ) ?	I_Src_Idx4 ;
															'0;

	assign Src_Index3			= ( Sel_Src3_Data1 ) ?		I_Src_Idx1 ;
									( Sel_Src3_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src3_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src3_Data4 ) ?	I_Src_Idx4 ;
															'0;


	assign Sel_WB_Data1			= Req & I_Sel_ALU_Src1 & ( Src_Index1 == I_WB_DstIdx );
	assign Sel_WB_Data2			= Req & I_Sel_ALU_Src2 & ( Src_Index2 == I_WB_DstIdx );
	assign Sel_WB_Data3			= Req & I_Sel_ALU_Src3 & ( Src_Index3 == I_WB_DstIdx );


	assign Src_Data1			= ( Sel_Src1_Data1 ) ?		I_Src_Data1 ;
									( Sel_Src1_Data2 ) ?	I_Src_Data2 ;
									( Sel_Src1_Data3 ) ?	I_Src_Data3 ;
									( Sel_Src1_Data4 ) ?	I_Src_Data4 ;
															'0;

	assign Src_Data2			= ( Sel_Src2_Data1 ) ?		I_Src_Data1 ;
									( Sel_Src2_Data2 ) ?	I_Src_Data2 ;
									( Sel_Src2_Data3 ) ?	I_Src_Data3 ;
									( Sel_Src2_Data4 ) ?	I_Src_Data4 ;
															'0;

	assign Src_Data3			= ( Sel_Src3_Data1 ) ?		I_Src_Data1 ;
									( Sel_Src3_Data2 ) ?	I_Src_Data2 ;
									( Sel_Src3_Data3 ) ?	I_Src_Data3 ;
									( Sel_Src3_Data4 ) ?	I_Src_Data4 ;
															'0;


	assign O_Src_Data1			= ( Sel_Scalar_Src1 ) ?		I_Scalar_Data :
									( Sel_WB_Data ) ?		I_WB_Data :
									( I_Sel_ALU_Src1 ) ?	Path_Src_Data1 :
															'0;

	assign O_Src_Data2			= ( Sel_Scalar_Src2 ) ?		I_Scalar_Data :
									( Sel_WB_Data2 ) ?		I_WB_Data :
									( I_Sel_ALU_Src2 ) ?	Path_Src_Data2 :
															'0;

	assign O_Src_Data3			= ( Sel_Scalar_Src3 ) ?		I_Scalar_Data :
									( Sel_WB_Data3 ) ?		I_WB_Data :
									( I_Sel_ALU_Src3 ) ?	Path_Src_Data3 :
															'0;


	PathSel #(
		.LANE_ID(			LANE_ID				)
	) PathSel
	(
		.I_Req(				Req					),
		.I_Sel_Path(		Sel_Path			),
		.I_Lane_Data_Src1(	I_Lane_Data_Src1	),
		.I_Lane_Data_Src2(	I_Lane_Data_Src2	),
		.I_Lane_Data_Src3(	I_Lane_Data_Src3	),
		.I_Src_Data1(		Src_Data1			),
		.I_Src_Data2(		Src_Data2			),
		.I_Src_Data3(		Src_Data3			),
		.O_Src_Data1(		Path_Src_Data1		),
		.O_Src_Data2(		Path_Src_Data2		),
		.O_Src_Data3(		Path_Src_Data3		),
		.O_Lane_Data_Src1(	O_Lane_Data_Src1	),
		.O_Lane_Data_Src2(	O_Lane_Data_Src2	),
		.O_Lane_Data_Src3(	O_Lane_Data_Src3	)
	);

endmodule