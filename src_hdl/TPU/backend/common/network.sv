module Network
	import pkg_tpu::*;
#(
	parameter int NUM_LANES		= 16,
	parameter int WIDTH_LANES	= $clog2(NUM_LANES);
)(
	input	[NUM_LANES+2-1:0]	I_Config_Path,					//Path Selects
	input	[2:0]				I_Bypass_Path,					//Path Selects
	input	[2:0]				I_WB_Path1,						//Path Selects
	input	[2:0]				I_WB_Path2,						//Path Selects
	input	hop_data_t			I_Path_Hop,						//From Multi-Hop Length Path
	input	data_t				I_Scalar_Data,					//From Scalar Unit
	input	index_t				I_WB_Index1,					//From ALU
	input	index_t				I_WB_Index2,					//From ALU
	input	data_t				I_WB_Data1,						//From ALU
	input	data_t				I_WB_Data2,						//From ALU
	input	data_t				I_Src_Data1,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data2,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data3,					//From RegFile after Rotation Path
	output	data_t				O_Src_Data1,					//To Exec Unit
	output	data_t				O_Src_Data2,					//To Exec Unit
	output	data_t				O_Src_Data3,					//To Exec Unit
	output	data_t				O_Src_Data4,					//To Exec Unit
	output	index_t				O_WB_Index1,					//To RegFile
	output	index_t				O_WB_Index2,					//To RegFile
	output	data_t				O_WB_Data1,						//To RegFile
	output	data_t				O_WB_Data2,						//To RegFile
	output	address_t			O_Address,						//To Load/Store Unit
	output	address_t			O_Stride,						//To Load/Store Unit
	output	address_t			O_Length						//To Load/Store Unit
);


	logic	[WIDTH_LANES-1:0]	Sel_Path;
	logic						Sel_Data2;
	logic						Sel_Data3;
	logic						Sel_Bypass1;
	logic						Sel_Bypass2;
	logic						Sel_Bypass3;
	logic						Sel_Scalar1;
	logic						Sel_Scalar2;
	logic						Sel_Scalar3;
	data_t						Path_Data;

	logic						Sel_Addr_Data1;
	logic						Sel_Addr_Data2;
	logic						Sel_Addr_Data3;
	logic						Sel_Stride_Data1;
	logic						Sel_Stride_Data2;
	logic						Sel_Stride_Data3;
	logic						Sel_Length_Data1;
	logic						Sel_Length_Data2;
	logic						Sel_Length_Data3;

	logic						Sel_WB_Data11;
	logic						Sel_WB_Data12;
	logic						Sel_WB_Data13;
	logic						Sel_WB_Data21;
	logic						Sel_WB_Data22;
	logic						Sel_WB_Data23;
	logic						Sel_WB_Bypass11;
	logic						Sel_WB_Bypass12;
	logic						Sel_WB_Bypass21;
	logic						Sel_WB_Bypass22;
	logic						Sel_Path_Odd1;
	logic						Sel_Path_Odd2;
	logic						Sel_Path_Even1;
	logic						Sel_Path_Even2;


	assign Sel_Data2			= I_Config_Path[0];
	assign Sel_Data3			= I_Config_Path[1];
	assign Sel_Path				= I_Config_Path[WIDTH_LANES+2-1:2];


	assign Sel_Bypass11			= I_Bypass_Path == 4'h0;
	assign Sel_Bypass12			= I_Bypass_Path == 4'h1;
	assign Sel_Bypass13			= I_Bypass_Path == 4'h2;

	assign Sel_Bypass21			= I_Bypass_Path == 4'h4;
	assign Sel_Bypass22			= I_Bypass_Path == 4'h5;
	assign Sel_Bypass23			= I_Bypass_Path == 4'h6;


	assign Sel_Addr_Data1		= ( I_Bypass_Path == 4'h8 ) | ( I_Bypass_Path == 4'hc );
	assign Sel_Addr_Data2		= ( I_Bypass_Path == 4'h9 ) | ( I_Bypass_Path == 4'hd );
	assign Sel_Addr_Data3		= ( I_Bypass_Path == 4'ha ) | ( I_Bypass_Path == 4'he );

	assign Sel_Stride_Data1		= ( I_Bypass_Path == 4'hb ) | ( I_Bypass_Path == 4'he );
	assign Sel_Stride_Data2		= ( I_Bypass_Path == 4'h8 ) | ( I_Bypass_Path == 4'hf );
	assign Sel_Stride_Data3		= ( I_Bypass_Path == 4'h9 ) | ( I_Bypass_Path == 4'hc );

	assign Sel_Length_Data1		= ( I_Bypass_Path == 4'ha ) | ( I_Bypass_Path == 4'hf );
	assign Sel_Length_Data2		= ( I_Bypass_Path == 4'hb ) | ( I_Bypass_Path == 4'he );
	assign Sel_Length_Data3		= ( I_Bypass_Path == 4'h8 ) | ( I_Bypass_Path == 4'hd );


	assign Sel_WB_Data11		= I_WB_Path1 == 3'h1;
	assign Sel_WB_Data12		= I_WB_Path1 == 3'h2;
	assign Sel_WB_Data13		= I_WB_Path1 == 3'h3;
	assign Sel_WB_Bypass11		= I_WB_Path1 == 3'h4;
	assign Sel_WB_Bypass12		= I_WB_Path1 == 3'h5;
	assign Sel_Path_Odd1		= I_WB_Path1 == 3'h6;
	assign Sel_Path_Even1		= I_WB_Path1 == 3'h7;

	assign Sel_WB_Data21		= I_WB_Path2 == 3'h1;
	assign Sel_WB_Data22		= I_WB_Path2 == 3'h2;
	assign Sel_WB_Data23		= I_WB_Path2 == 3'h3;
	assign Sel_WB_Bypass21		= I_WB_Path2 == 3'h4;
	assign Sel_WB_Bypass22		= I_WB_Path2 == 3'h5;
	assign Sel_Path_Odd2		= I_WB_Path2 == 3'h6;
	assign Sel_Path_Even2		= I_WB_Path2 == 3'h7;


	//ToDo
	assign Sel_WB_Index1_Idx1	=;
	assign Sel_WB_Index1_Idx2	=;
	assign Sel_WB_Index2_Idx1	=;
	assign Sel_WB_Index2_Idx2	=;


	assign Path_Data			=I_Path_Hop[ Sel_Path ];


	assign O_Src_Data1			= ( Sel_Bypass11 ) ?		I_WB_Data1 :
									( Sel_Bypass21 ) ?		I_WB_Data2 :
									( Sel_Scalar1 ) ?		I_Scalar_Data :
															I_Src_Data1;

	assign O_Src_Data2			= ( Sel_Data2 ) ? 			I_Src_Data2 :
									( Sel_Bypass12 ) ?		I_WB_Data1 :
									( Sel_Bypass22 ) ?		I_WB_Data2 :
									( Sel_Scalar2 ) ?		I_Scalar_Data :
															Path_Data;

	assign O_Src_Data3			= ( Sel_Data3 ) ? 			I_Src_Data3 :
									( Sel_Bypass13 ) ?		I_WB_Data1 :
									( Sel_Bypass23 ) ?		I_WB_Data2 :
									( Sel_Scalar3 ) ?		I_Scalar_Data :
															Path_Data;


	assign O_WB_Index1			= ( Sel_WB_Index1_Idx1 ) ?	I_WB_Index1 :
									( Sel_WB_Index1_Idx2 ) ?I_WB_Index2 :
															0;

	assign O_WB_Index2			= ( Sel_WB_Index2_Idx2 ) ?	I_WB_Index2 :
									( Sel_WB_Index2_Idx1 ) ?I_WB_Index1 :
															0;


	assign O_WB_Data1			= ( Sel_WB_Data11 ) ?		I_Src_Data1 :
									( Sel_WB_Data12 ) ?		I_Src_Data2 :
									( Sel_WB_Data13 ) ?		I_Src_Data3 :
									( Sel_WB_Bypass11 ) ?	I_WB_Data1 :
									( Sel_WB_Bypass12 ) ?	I_WB_Data2 :
									( Sel_Path_Odd1 ) ?		I_Odd_Path :
									( Sel_Path_Even1 ) ?	I_Even_Path :
															0;

	assign O_WB_Data2			= ( Sel_WB_Data23 ) ?		I_Src_Data3 :
									( Sel_WB_Data22 ) ?		I_Src_Data2 :
									( Sel_WB_Data21 ) ?		I_Src_Data1 :
									( Sel_WB_Bypass21 ) ?	I_WB_Data1 :
									( Sel_WB_Bypass22 ) ?	I_WB_Data2 :
									( Sel_Path_Odd2 ) ?		I_Odd_Path :
									( Sel_Path_Even2 ) ?	I_Even_Path :
															0;


	assign O_Address			= ( Sel_Addr_Data1 ) ?		I_Src_Data1 :
									( Sel_Addr_Data2 ) ?	I_Src_Data2 :
									( Sel_Addr_Data3 ) ?	I_Src_Data3 :
															0;

	assign O_Stride				= ( Sel_Stride_Data1 ) ?	I_Src_Data1 :
									( Sel_Stride_Data2 ) ?	I_Src_Data2 :
									( Sel_Stride_Data3 ) ?	I_Src_Data3 :
															0;

	assign O_Length				= ( Sel_Length_Data1 ) ?	I_Src_Data1 :
									( Sel_Length_Data2 ) ?	I_Src_Data2 :
									( Sel_Length_Data3 ) ?	I_Src_Data3 :
															0;

endmodule