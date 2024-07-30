module Network
	import pkg_tpu::*;
#(
	parameter int NUM_LANES		= 16,
	parameter int WIDTH_LANES	= $clog2(NUM_LANES);
)(
	input						I_Req,
	input	[7:0]				I_Sel_Path,						//Path Selects
	input	data_t				I_Scalar_Data,					//Data from Scalar Unit
	input	[2:0]				I_Sel_ALU_Src1,					//Source Select
	input	[2:0]				I_Sel_ALU_Src2,					//Source Select
	input	[2:0]				I_Sel_ALU_Src3,					//Source Select
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
	input	index_t				I_WB_DstIdx1,					//Index from ALU
	input	index_t				I_WB_DstIdx2,					//Index from ALU
	input	data_t				I_WB_Data1,						//Data from ALU
	input	data_t				I_WB_Data2,						//Data from ALU
	output	data_t				O_Src_Data1,					//To Exec Unit
	output	data_t				O_Src_Data2,					//To Exec Unit
	output	data_t				O_Src_Data3,					//To Exec Unit
	output	data_t				O_Lane_Data_Src1,				//Lane Data
	output	data_t				O_Lane_Data_Src2,				//Lane Data
	output	data_t				O_Lane_Data_Src3,				//Lane Data
	output	address_t			O_Address,						//To Load/Store Unit
	output	address_t			O_Stride,						//To Load/Store Unit
	output	address_t			O_Length						//To Load/Store Unit
);


	logic						Req;
	logic	[4:0]				Sel_Path;

	logic	[1:0]				Sel_Scalar;
	logic						Sel_Scalar_Src1;
	logic						Sel_Scalar_Src2;
	logic						Sel_Scalar_Src3;

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

	logic						Sel_WB_Data11;
	logic						Sel_WB_Data12;
	logic						Sel_WB_Data21;
	logic						Sel_WB_Data22;
	logic						Sel_WB_Data31;
	logic						Sel_WB_Data32;

	data_t						Path_Src_Data1;
	data_t						Path_Src_Data2;
	data_t						Path_Src_Data3;


	assign Req					= I_Req;
	assign Sel_Path				= I_Sel_Path;

	assign Sel_Scalar			= I_Sel_Path[7:6];

	assign Sel_Scalar_Src1		= Req & I_Sel_ALU_Src1[2] & ( Sel_Scalar == 2'h1 );
	assign Sel_Scalar_Src2		= Req & I_Sel_ALU_Src2[2] & ( Sel_Scalar == 2'h2 );
	assign Sel_Scalar_Src3		= Req & I_Sel_ALU_Src3[2] & ( Sel_Scalar == 2'h3 );

	assign Sel_Src1_Data1		= Req & I_Sel_ALU_Src1[2] & ( Sel_Path_Src1 == 2'h0 );
	assign Sel_Src1_Data2		= Req & I_Sel_ALU_Src1[2] & ( Sel_Path_Src1 == 2'h1 );
	assign Sel_Src1_Data3		= Req & I_Sel_ALU_Src1[2] & ( Sel_Path_Src1 == 2'h2 );
	assign Sel_Src1_Data4		= Req & I_Sel_ALU_Src1[2] & ( Sel_Path_Src1 == 2'h3 );

	assign Sel_Src2_Data1		= Req & I_Sel_ALU_Src2[2] & ( Sel_Path_Src2 == 2'h0 );
	assign Sel_Src2_Data2		= Req & I_Sel_ALU_Src2[2] & ( Sel_Path_Src2 == 2'h1 );
	assign Sel_Src2_Data3		= Req & I_Sel_ALU_Src2[2] & ( Sel_Path_Src2 == 2'h2 );
	assign Sel_Src2_Data4		= Req & I_Sel_ALU_Src2[2] & ( Sel_Path_Src2 == 2'h3 );

	assign Sel_Src3_Data1		= Req & I_Sel_ALU_Src3[2] & ( Sel_Path_Src3 == 2'h0 );
	assign Sel_Src3_Data2		= Req & I_Sel_ALU_Src3[2] & ( Sel_Path_Src3 == 2'h1 );
	assign Sel_Src3_Data3		= Req & I_Sel_ALU_Src3[2] & ( Sel_Path_Src3 == 2'h2 );
	assign Sel_Src3_Data4		= Req & I_Sel_ALU_Src3[2] & ( Sel_Path_Src3 == 2'h3 );

	assign Sel_WB_Data11		= Req & I_Sel_ALU_Src1[2] & ( Src_Index1 == I_WB_DstIdx1 );
	assign Sel_WB_Data12		= Req & I_Sel_ALU_Src1[2] & ( Src_Index1 == I_WB_DstIdx2 );
	assign Sel_WB_Data21		= Req & I_Sel_ALU_Src2[2] & ( Src_Index2 == I_WB_DstIdx1 );
	assign Sel_WB_Data22		= Req & I_Sel_ALU_Src2[2] & ( Src_Index2 == I_WB_DstIdx2 );
	assign Sel_WB_Data31		= Req & I_Sel_ALU_Src3[2] & ( Src_Index3 == I_WB_DstIdx1 );
	assign Sel_WB_Data32		= Req & I_Sel_ALU_Src3[2] & ( Src_Index3 == I_WB_DstIdx2 );


	assign Src_Index1			= ( Sel_Src1_Data1 ) ?		I_Src_Idx1 ;
									( Sel_Src1_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src1_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src1_Data4 ) ?	I_Src_Idx4 ;
															0;

	assign Src_Index2			= ( Sel_Src2_Data1 ) ?		I_Src_Idx1 ;
									( Sel_Src2_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src2_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src2_Data4 ) ?	I_Src_Idx4 ;
															0;

	assign Src_Index3			= ( Sel_Src3_Data1 ) ?		I_Src_Idx1 ;
									( Sel_Src3_Data2 ) ?	I_Src_Idx2 ;
									( Sel_Src3_Data3 ) ?	I_Src_Idx3 ;
									( Sel_Src3_Data4 ) ?	I_Src_Idx4 ;
															0;

	assign Src_Data1			= ( Sel_Src1_Data1 ) ?		I_Src_Data1 ;
									( Sel_Src1_Data2 ) ?	I_Src_Data2 ;
									( Sel_Src1_Data3 ) ?	I_Src_Data3 ;
									( Sel_Src1_Data4 ) ?	I_Src_Data4 ;
															0;

	assign Src_Data2			= ( Sel_Src2_Data1 ) ?		I_Src_Data1 ;
									( Sel_Src2_Data2 ) ?	I_Src_Data2 ;
									( Sel_Src2_Data3 ) ?	I_Src_Data3 ;
									( Sel_Src2_Data4 ) ?	I_Src_Data4 ;
															0;

	assign Src_Data3			= ( Sel_Src3_Data1 ) ?		I_Src_Data1 ;
									( Sel_Src3_Data2 ) ?	I_Src_Data2 ;
									( Sel_Src3_Data3 ) ?	I_Src_Data3 ;
									( Sel_Src3_Data4 ) ?	I_Src_Data4 ;
															0;

	assign Sel_LdST				= Req & ~I_Sel_ALU_Src1 & ~I_Sel_ALU_Src2 & ~I_Sel_ALU_Src3;


	assign O_Src_Data1			= ( Sel_Scalar_Src1 ) ?		I_Scalar_Data :
									( Sel_WB_Data11 ) ?		I_WB_Data1 :
									( Sel_WB_Data12 ) ?		I_WB_Data2 :
									( I_Sel_ALU_Src1[2] )?	Path_Src_Data1 :
															'0;

	assign O_Src_Data2			= ( Sel_Scalar_Src2 ) ?		I_Scalar_Data :
									( Sel_WB_Data21 ) ?		I_WB_Data1 :
									( Sel_WB_Data22 ) ?		I_WB_Data2 :
									( I_Sel_ALU_Src2[2] )?	Path_Src_Data2 :
															'0;

	assign O_Src_Data3			= ( Sel_Scalar_Src3 ) ?		I_Scalar_Data :
									( Sel_WB_Data31 ) ?		I_WB_Data1 :
									( Sel_WB_Data32 ) ?		I_WB_Data2 :
									( I_Sel_ALU_Src3[2] )?	Path_Src_Data3 :
															'0;


	assign O_Address			= (   ( Sel_Path[1:0] == 2'h0 ) & Sel_LdST ) ?	I_Src_Data1 :
									( ( Sel_Path[1:0] == 2'h1 ) & Sel_LdST ) ?	I_Src_Data2 :
									( ( Sel_Path[1:0] == 2'h2 ) & Sel_LdST ) ?	I_Src_Data3 :
									( ( Sel_Path[1:0] == 2'h3 ) & Sel_LdST ) ?	I_Src_Data4 :
																				'0;

	assign O_Stride				= (   ( Sel_Path[1:0] == 2'h0 ) & Sel_LdST ) ?	I_Src_Data2 :
									( ( Sel_Path[1:0] == 2'h1 ) & Sel_LdST ) ?	I_Src_Data3 :
									( ( Sel_Path[1:0] == 2'h2 ) & Sel_LdST ) ?	I_Src_Data4 :
									( ( Sel_Path[1:0] == 2'h3 ) & Sel_LdST ) ?	I_Src_Data1 :
																				'0;

	assign O_Length				= (   ( Sel_Path[1:0] == 2'h0 ) & Sel_LdST ) ?	I_Src_Data3 :
									( ( Sel_Path[1:0] == 2'h1 ) & Sel_LdST ) ?	I_Src_Data4 :
									( ( Sel_Path[1:0] == 2'h2 ) & Sel_LdST ) ?	I_Src_Data1 :
									( ( Sel_Path[1:0] == 2'h3 ) & Sel_LdST ) ?	I_Src_Data2 :
																				'0;

	PathSel #(
		.LANE_ID(			LANE_ID)
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