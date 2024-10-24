///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Logic_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module Shift_Unit
	import pkg_tpu::*;
#(
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						I_En,					//Enable to Execute
	input   data_t				I_Data1,				//Source Operand
	input   data_t				I_Data2,				//Source Operand
	input	TYPE				I_Token,				//Command
	output  					O_Valid,				//Output Valid
	output  data_t				O_Data,					//Output Data
	output	TYPE				O_Token					//Command
);


	localparam	LOG_WIDTHD			= $clog2(WIDTH_DATA)-1;

	reg	[WIDTH_DATA-1:0]			ResultData;


	assign O_Valid					= I_En;
	assign O_Data					= ( I_En ) ? ResultData : '0;
	assign O_Token					= ( I_En ) ? I_Token	: '0;


	always_comb begin
		case ( I_Token.op.OpCode )
			2'b00: ResultData	= I_Data1 <<  I_Data2[LOG_WIDTHD:0];
			2'b01: ResultData	= I_Data1 <<< I_Data2[LOG_WIDTHD:0];
			2'b10: ResultData	= I_Data1 >>  I_Data2[LOG_WIDTHD:0];
			2'b11: ResultData	= I_Data1 >>> I_Data2[LOG_WIDTHD:0];
		endcase
	end

endmodule