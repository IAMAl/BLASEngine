module Bypass (
	input	[3:0]				I_Config_Path,					//Path Selects
	input	[2:0]				I_Bypass_Path,					//Path Selects
	input	[2:0]				I_WB_Path1,						//Path Selects
	input	[2:0]				I_WB_Path2,						//Path Selects
	input	data_t				I_Odd_Path,						//From Odd_Path
	input	data_t				I_Even_Path,					//From Even_Path
	input	data_t				I_Scalar_Data,					//From Scalar Unit
	input	data_t				I_Bypass_Data1,					//From ALU
	input	data_t				I_Bypass_Data2,					//From ALU
	input	data_t				I_Src_Data1,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data2,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data3,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data4,					//From RegFile after Rotation Path
	output	data_t				O_Src_Data1,					//To Exec Unit
	output	data_t				O_Src_Data2,					//To Exec Unit
	output	data_t				O_Src_Data3,					//To Exec Unit
	output	data_t				O_Src_Data4,					//To Exec Unit
	output	data_t				O_WB_Data1,						//To RegFile
	output	data_t				O_WB_Data2,						//To RegFile
	output	address_t			O_Address,						//To Load/Store Unit
	output	address_t			O_Stride,						//To Load/Store Unit
	output	address_t			O_Length						//To Load/Store Unit
);

	logic						Sel_Path_Odd;
	logic						Sel_Data2;
	logic						Sel_Data3;
	logic						Sel_Bypass1;
	logic						Sel_Bypass2;
	logic						Sel_Bypass3;
	logic						Sel_Bypass4;
	logic						Sel_Scalar1;
	logic						Sel_Scalar2;
	logic						Sel_Scalar3;
	logic						Sel_Scalar4;
	data_t						Path_Data;

	assign Sel_Data2			= I_Config_Path[0];
	assign Sel_Data3			= I_Config_Path[1];
	assign Sel_Path_Odd			= I_Config_Path[2];


	assign Sel_Bypass11			= I_Bypass_Path == 4'h0;
	assign Sel_Bypass12			= I_Bypass_Path == 4'h1;
	assign Sel_Bypass13			= I_Bypass_Path == 4'h2;
	assign Sel_Bypass14			= I_Bypass_Path == 4'h3;

	assign Sel_Bypass21			= I_Bypass_Path == 4'h4;
	assign Sel_Bypass22			= I_Bypass_Path == 4'h5;
	assign Sel_Bypass23			= I_Bypass_Path == 4'h6;
	assign Sel_Bypass24			= I_Bypass_Path == 4'h7;


	assign Sel_Addr_Data1		= ( I_Bypass_Path == 4'h8 ) | ( I_Bypass_Path == 4'hc );
	assign Sel_Addr_Data2		= ( I_Bypass_Path == 4'h9 ) | ( I_Bypass_Path == 4'hd );
	assign Sel_Addr_Data3		= ( I_Bypass_Path == 4'ha ) | ( I_Bypass_Path == 4'he );
	assign Sel_Addr_Data4		= ( I_Bypass_Path == 4'hb ) | ( I_Bypass_Path == 4'hf );

	assign Sel_Stride_Data1		= ( I_Bypass_Path == 4'hb ) | ( I_Bypass_Path == 4'he );
	assign Sel_Stride_Data2		= ( I_Bypass_Path == 4'h8 ) | ( I_Bypass_Path == 4'hf );
	assign Sel_Stride_Data3		= ( I_Bypass_Path == 4'h9 ) | ( I_Bypass_Path == 4'hc );
	assign Sel_Stride_Data4		= ( I_Bypass_Path == 4'ha ) | ( I_Bypass_Path == 4'hd );

	assign Sel_Length_Data1		= ( I_Bypass_Path == 4'ha ) | ( I_Bypass_Path == 4'hf );
	assign Sel_Length_Data2		= ( I_Bypass_Path == 4'hb ) | ( I_Bypass_Path == 4'he );
	assign Sel_Length_Data3		= ( I_Bypass_Path == 4'h8 ) | ( I_Bypass_Path == 4'hd );
	assign Sel_Length_Data4		= ( I_Bypass_Path == 4'h9 ) | ( I_Bypass_Path == 4'hc );


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


	assign Path_Data			= ( Sel_Path_Odd ) ?	I_Odd_Path :
														I_Even_Path;


	assign O_Src_Data1			= ( Sel_Bypass11 ) ?	I_Bypass_data1 :
									( Sel_Bypass21 ) ?	I_Bypass_data2 :
									( Sel_Scalar1 ) ?	I_Scalar_Data :
														I_Src_Data1;

	assign O_Src_Data2			= ( Sel_Data2 ) ? 		I_Src_Data2 :
									( Sel_Bypass12 ) ?	I_Bypass_data1 :
									( Sel_Bypass22 ) ?	I_Bypass_data2 :
									( Sel_Scalar2 ) ?	I_Scalar_Data :
														Path_Data;

	assign O_Src_Data3			= ( Sel_Data3 ) ? 		I_Src_Data3 :
									( Sel_Bypass13 ) ?	I_Bypass_data1 :
									( Sel_Bypass23 ) ?	I_Bypass_data2 :
									( Sel_Scalar3 ) ?	I_Scalar_Data :
														Path_Data;

	assign O_Src_Data4			= ( Sel_Bypass14 ) ?	I_Bypass_data1 :
									( Sel_Bypass24 ) ?	I_Bypass_data2 :
									( Sel_Scalar4 ) ?	I_Scalar_Data :
														I_Src_Data4;


	assign O_WB_Data1			= ( Sel_WB_Data11 ) ?		I_Src_Data1 :
									( Sel_WB_Data12 ) ?		I_Src_Data2 :
									( Sel_WB_Data13 ) ?		I_Src_Data3 :
									( Sel_WB_Bypass11 ) ?	I_Bypass_data1 :
									( Sel_WB_Bypass12 ) ?	I_Bypass_data2 :
									( Sel_Path_Odd1 ) ?		I_Odd_Path :
									( Sel_Path_Even1 ) ?	I_Even_Path :
															0;

	assign O_WB_Data2			= ( Sel_WB_Data23 ) ?		I_Src_Data3 :
									( Sel_WB_Data22 ) ?		I_Src_Data2 :
									( Sel_WB_Data21 ) ?		I_Src_Data1 :
									( Sel_WB_Bypass21 ) ?	I_Bypass_data1 :
									( Sel_WB_Bypass22 ) ?	I_Bypass_data2 :
									( Sel_Path_Odd2 ) ?		I_Odd_Path :
									( Sel_Path_Even2 ) ?	I_Even_Path :
															0;


	assign O_Address			= ( Sel_Addr_Data1 ) ?		I_Src_Data1 :
									( Sel_Addr_Data2 ) ?	I_Src_Data2 :
									( Sel_Addr_Data3 ) ?	I_Src_Data3 :
									( Sel_Addr_Data4 ) ?	I_Src_Data4 :
															0;
	assign O_Stride				= ( Sel_Stride_Data1 ) ?	I_Src_Data1 :
									( Sel_Stride_Data2 ) ?	I_Src_Data2 :
									( Sel_Stride_Data3 ) ?	I_Src_Data3 :
									( Sel_Stride_Data4 ) ?	I_Src_Data4 :
															0;

	assign O_Length				= ( Sel_Length_Data1 ) ?	I_Src_Data1 :
									( Sel_Length_Data2 ) ?	I_Src_Data2 :
									( Sel_Length_Data3 ) ?	I_Src_Data3 :
									( Sel_Length_Data4 ) ?	I_Src_Data4 :
															0;

endmodule