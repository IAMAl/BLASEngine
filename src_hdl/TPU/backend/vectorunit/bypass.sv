module Bypass (
	input	[4:0]				I_Config_Path,					//Path Selects
	input	data_t				I_Odd_Path,						//From Odd_Path
	input	data_t				I_Even_Path,					//From Even_Path
	input	data_t				I_Scalar_Data,					//From Scalar Unit
	input	data_t				I_Bypass_Data,					//From ALU
	input	data_t				I_Src_Data1,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data2,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data3,					//From RegFile after Rotation Path
	output	data_t				O_Src_Data1,					//To Exec Unit
	output	data_t				O_Src_Data2,					//To Exec Unit
	output	data_t				O_Src_Data3,					//To Exec Unit
	output	data_t				O_Src_Data4,					//To Exec Unit
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

	assign Sel_Path_Odd			= I_Config_Path[4];
	assign Sel_Data2			= I_Config_Path[5];
	assign Sel_Data3			= I_Config_Path[6];

	assign Sel_Bypass1			= I_Config_Path[3:2] == 2'h0;
	assign Sel_Bypass2			= I_Config_Path[3:2] == 2'h1;
	assign Sel_Bypass3			= I_Config_Path[3:2] == 2'h2;
	assign Sel_Bypass4			= I_Config_Path[3:2] == 2'h3;

	assign Sel_Bypass1			= I_Config_Path[1:0] == 2'h0;
	assign Sel_Bypass2			= I_Config_Path[1:0] == 2'h1;
	assign Sel_Bypass3			= I_Config_Path[1:0] == 2'h2;
	assign Sel_Bypass4			= I_Config_Path[1:0] == 2'h3;

	assign Path_Data			= ( Sel_Path_Odd ) ?	I_Odd_Path :
														I_Even_Path;

	assign O_Src_Data1			= ( Sel_Bypass1 ) ?		I_Bypass_data :
									( Sel_Scalar1 ) ?	I_Scalar_Data :
														I_Src_Data1;

	assign O_Src_Data1			= ( Sel_Data2 ) ? 		I_Src_Data2 :
									( Sel_Bypass2 ) ?	I_Bypass_data :
									( Sel_Scalar2 ) ?	I_Scalar_Data :
														Path_Data;

	assign O_Src_Data1			= ( Sel_Data3 ) ? 		I_Src_Data3 :
									( Sel_Bypass3 ) ?	I_Bypass_data :
									( Sel_Scalar3 ) ?	I_Scalar_Data :
														Path_Data;

	assign O_Src_Data4			= ( Sel_Bypass4 ) ?		I_Bypass_data :
									( Sel_Scalar4 ) ?	I_Scalar_Data :
														I_Src_Data3;

endmodule