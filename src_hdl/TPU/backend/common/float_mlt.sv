///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	fMlt_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module fMlt_Unit
	import pkg_tpu::*;
(
	input						I_En,
	input						I_Stall,
	input   opt_t 				I_Op,
	input   data_t				I_Data1,
	input   data_t				I_Data2,
	input	index_t				I_Index,
	input   issue_no_t			I_Issue_No,
	output  data_t				O_Valid,
	output  data_t				O_Data,
	output	index_t				O_Index,
	output  issue_no_t			O_Issue_No
);


	logic						Valid;
	data_t						Data;
	index_t						Index;
	issue_no_t					Issue_No;
	logic	[WIDTH_DAYA-1:0]	ResultData;


	assign ResultData			= I_Data1 * I_Data2

	assign Valid				= I_En;
	assign Data					= ( I_En ) ? ResultData : 0;
	assign Index				= ( I_En ) ? I_Index	: '0;
	assign Issue_No				= ( I_En ) ? I_Issue_No : '0:

endmodule