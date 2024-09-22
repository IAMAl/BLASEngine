///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	iMlt_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module iMlt_Unit
	import pkg_tpu::*;
#(
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						I_En,
	input   data_t				I_Data1,
	input   data_t				I_Data2,
	input	TYPE				I_Token,
	input   issue_no_t			I_Issue_No,
	output  data_t				O_Valid,
	output  data_t				O_Data,
	output	TYPE				O_Token
);


	logic						is_Signed;
	logic						is_Sign;

	logic	[WIDTH_DATA-1:0]	Src_Data1;
	logic	[WIDTH_DATA-1:0]	Src_Data2;

	logic	[WIDTH_DAYA-1:0]	ResultData;


	assign is_Signed			= |I_Token.instr.op.OpCode;
	assign is_Sign				= I_Data1[WIDTH_DATA-1] ^ I_Data2[WIDTH_DATA-1];


	assign Src_Data1			= ( is_Signed & I_Data1[WIDTH_DATA-1] ) ? ~I_Data1 + 1'b1 : I_Data1;
	assign Src_Data2			= ( is_Signed & I_Data2[WIDTH_DATA-1] ) ? ~I_Data2 + 1'b1 : I_Data2;

	assign ResultData			= Src_Data1 * Src_Data2;

	assign O_Valid				= I_En;
	assign O_Data				= ( I_En ) ? (
									( is_Signed & is_Sign ) ?  ~ResultData + 1'b1 :
																ResultData
									) :
									0;
	assign O_Token				= ( I_En ) ? I_Token	: '0;

endmodule