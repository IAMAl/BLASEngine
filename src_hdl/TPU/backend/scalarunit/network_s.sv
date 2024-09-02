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
	parameter int WIDTH_LANES	= $clog2(NUM_LANES);
)(
	input						I_Stall,
	input						I_Req,
	input	[5:0]				I_Sel_Path,				//Path Selects
	input						I_Sel_ALU_Src1,			//Source Select
	input						I_Sel_ALU_Src2,			//Source Select
	input						I_Sel_ALU_Src3,			//Source Select
	input	data_t				I_Src_Data1,			//Data from RegFile
	input	data_t				I_Src_Data2,			//Data From RegFile
	input	data_t				I_Src_Data3,			//Data From RegFile
	input	data_t				I_Src_Data4,			//Data From RegFile
	input	index_t				I_Src_Idx1,				//Index from RegFile
	input	index_t				I_Src_Idx2,				//Index from RegFile
	input	index_t				I_Src_Idx3,				//Index from RegFile
	input	index_t				I_Src_Idx4,				//Index from RegFile
	input	index_t				I_WB_DstIdx,			//Index from ALU
	input	data_t				I_WB_Data,				//Data from ALU
	output	data_t				O_Src_Data1,			//To Exec Unit
	output	data_t				O_Src_Data2,			//To Exec Unit
	output	data_t				O_Src_Data3,			//To Exec Unit
	output						O_Buff_Full,			//Flag: Buffer is Full
	output	data_t				O_PAC_Src_Data			//Data to PAC Unit
);


	logic						Req;
	logic	[1:0]				Sel_Path;

	logic	[1:0]				Sel_Path_Src1;
	logic	[1:0]				Sel_Path_Src2;
	logic	[1:0]				Sel_Path_Src3;

	index_t						Src_Index1;
	index_t						Src_Index2;
	index_t						Src_Index3;

	data_t						Src_Data1;
	data_t						Src_Data2;
	data_t						Src_Data3;

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


	assign Req					= I_Req;
	assign Sel_Path				= I_Sel_Path;

	assign Sel_Path_Src1		= I_Sel_Path[1:0];
	assign Sel_Path_Src2		= I_Sel_Path[3:2];
	assign Sel_Path_Src3		= I_Sel_Path[5:4];

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


	assign Src_Index1			= (   Sel_Src1_Data1 ) ?	I_Src_Idx1 ;
									( Sel_Src1_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src1_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src1_Data4 ) ?	I_Src_Idx4 ;
															'0;

	assign Src_Index2			= (   Sel_Src2_Data1 ) ?	I_Src_Idx1 ;
									( Sel_Src2_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src2_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src2_Data4 ) ?	I_Src_Idx4 ;
															'0;

	assign Src_Index3			= (   Sel_Src3_Data1 ) ?	I_Src_Idx1 ;
									( Sel_Src3_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src3_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src3_Data4 ) ?	I_Src_Idx4 ;
															'0;


	assign Src_Data1			= (   Sel_Src1_Data1 ) ?	I_Src_Data1 :
									( Sel_Src1_Data2 ) ?	I_Src_Data2 :
									( Sel_Src1_Data3 ) ?	I_Src_Data3 :
									( Sel_Src1_Data4 ) ?	I_Src_Data4 :
															'0;

	assign Src_Data2			= (   Sel_Src2_Data1 ) ?	I_Src_Data1 :
									( Sel_Src2_Data2 ) ?	I_Src_Data2 :
									( Sel_Src2_Data3 ) ?	I_Src_Data3 :
									( Sel_Src2_Data4 ) ?	I_Src_Data4 :
															'0;
	assign Src_Data3			= (   Sel_Src3_Data1 ) ?	I_Src_Data1 :
									( Sel_Src3_Data2 ) ?	I_Src_Data2 :
									( Sel_Src3_Data3 ) ?	I_Src_Data3 :
									( Sel_Src3_Data4 ) ?	I_Src_Data4 :
															'0;


	assign O_PAC_Src_Data		= (   Sel_Path[1:0] == 2'h0 ) ?	I_Src_Data1 :
									( Sel_Path[1:0] == 2'h1 ) ?	I_Src_Data2 :
									( Sel_Path[1:0] == 2'h2 ) ?	I_Src_Data3 :
									( Sel_Path[1:0] == 2'h3 ) ?	I_Src_Data4 :
																'0;


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