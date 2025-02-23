///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	PathSel
///////////////////////////////////////////////////////////////////////////////////////////////////

module PathSel
	import pkg_tpu::*;
#(
	parameter int LANE_ID		= 0
)(
	input						I_Req,							//Request to Work
	input	[4:0]				I_Sel_Path,						//Path Selects
	input	[4:0]				I_Sel_Path_WB,					//Path Selects
	input	data_t				I_Scalar_Data,					//Scalar Data
	input	lane_t				I_Lane_Data_Src1,				//Data from Lanes
	input	lane_t				I_Lane_Data_Src2,				//Data from Lanes
	input	lane_t				I_Lane_Data_Src3,				//Data from Lanes
	input	lane_t				I_Lane_Data_WB,					//Data from Lanes
	input	data_t				I_Src_Data1,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data2,					//From RegFile after Rotation Path
	input	data_t				I_Src_Data3,					//From RegFile after Rotation Path
	output	data_t				O_Src_Data1,					//To Exec Unit
	output	data_t				O_Src_Data2,					//To Exec Unit
	output	data_t				O_Src_Data3,					//To Exec Unit
	input	data_t				I_WB_Data,						//Write-Back Data from Exec Unit
	output	data_t				O_WB_Data,						//Write-Back Data To RF Unit
	output	data_t				O_Lane_Data_Src1,				//Data to Lanes
	output	data_t				O_Lane_Data_Src2,				//Data to Lanes
	output	data_t				O_Lane_Data_Src3,				//Data to Lanes
	output	data_t				O_Lane_Data_WB					//Data to Lanes
);


	logic	[3:0]				Sel_Path_Lane;
	logic	[3:0]				Sel_Path_WB_Lane;
	logic	[1:0]				Sel_Path_Src;
	logic	[1:0]				Sel_Path_WB;
	logic						Sel_Path;
	logic						Sel_WB_Path;


	data_t						Lane_Data1;
	data_t						Lane_Data2;
	data_t						Lane_Data3;
	data_t						Src_Data1;
	data_t						Src_Data2;
	data_t						Src_Data3;
	data_t						WB_Data;

	data_t						Lane_WB_Data;


	assign Sel_Path_Lane		= I_Sel_Path[3:0] + LANE_ID;
	assign Sel_Path_Src			= I_Sel_Path[1:0];
	assign Sel_Path				= I_Sel_Path[4];

	assign Sel_Path_WB_Lane		= I_Sel_Path_WB[3:0] + LANE_ID;
	assign Sel_Path_WB			= I_Sel_Path_WB[1:0];
	assign Sel_WB_Path			= I_Sel_Path_WB[4];

	assign Lane_Data1			= I_Lane_Data_Src1[ Sel_Path_Lane ];
	assign Src_Data1			= (   Sel_Path_Src == 2'h3 ) ?	I_Src_Data3 :
									( Sel_Path_Src == 2'h2 ) ?	I_Src_Data2 :
									( Sel_Path_Src == 2'h1 ) ?	I_Src_Data1 :
																I_Scalar_Data;

	assign Lane_Data2			= I_Lane_Data_Src2[ Sel_Path_Lane ];
	assign Src_Data2			= (   Sel_Path_Src == 2'h3 ) ?	I_Src_Data3 :
									( Sel_Path_Src == 2'h2 ) ?	I_Src_Data2 :
									( Sel_Path_Src == 2'h1 ) ?	I_Src_Data1 :
																I_Scalar_Data;

	assign Lane_Data3			= I_Lane_Data_Src3[ Sel_Path_Lane ];
	assign Src_Data3			= (   Sel_Path_Src == 2'h3 ) ?	I_Src_Data3 :
									( Sel_Path_Src == 2'h2 ) ?	I_Src_Data2 :
									( Sel_Path_Src == 2'h1 ) ?	I_Src_Data1 :
																I_Scalar_Data;

	assign Lane_WB_Data			= I_Lane_Data_WB[ Sel_Path_WB_Lane ];
	assign WB_Data				= (   Sel_Path_WB == 2'h3 ) ?	I_Src_Data3 :
									( Sel_Path_WB == 2'h2 ) ?	I_Src_Data2 :
									( Sel_Path_WB == 2'h1 ) ?	I_Src_Data1 :
																I_WB_Data;


	assign O_Src_Data1			= ( Sel_Path ) ?	Lane_Data1 :	Src_Data1;
	assign O_Src_Data2			= ( Sel_Path ) ?	Lane_Data2 :	Src_Data2;
	assign O_Src_Data3			= ( Sel_Path ) ?	Lane_Data3 :	Src_Data3;
	assign O_WB_Data			= ( Sel_WB_Path ) ?	Lane_WB_Data :	WB_Data;

	assign O_Lane_Data_Src1		= ( I_Req )	?		I_Src_Data1 : '0;
	assign O_Lane_Data_Src2		= ( I_Req )	?		I_Src_Data2 : '0;
	assign O_Lane_Data_Src3		= ( I_Req )	?		I_Src_Data3 : '0;
	assign O_Lane_Data_WB		= I_WB_Data;

endmodule