///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	fAdd_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module fAdd_Unit
	import pkg_tpu::*;
(
	input						I_En,
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


	logic						is_Sub;

	logic						Valid;
	data_t						Data;
	index_t						Index;
	issue_no_t					Issue_No;
	logic	[WIDTH_DAYA-1:0]	ResultData;


	assign is_Sub				= I_Op.OpCode[0];
	assign ResultData			= ( is_Sub ) ? I_Data1 - I_Data2 : I_Data1 + I_Data2;

	assign Valid				= I_En;
	assign Data					= ( I_En ) ? ResultData : 0;
	assign Index				= ( I_En ) ? I_Index	: '0;
	assign Issue_No				= ( I_En ) ? I_Issue_No : '0:

endmodule