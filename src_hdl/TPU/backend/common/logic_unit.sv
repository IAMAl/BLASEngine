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

module Logic_Unit
	import pkg_tpu::*;
#(
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						I_En,					//Enable to Execute
	input   data_t				I_Data1,				//Source Operand
	input   data_t				I_Data2,				//Source Opernad
	input	TYPE				I_Token,				//Command
	output  data_t				O_Valid,				//Output Valid
	output  data_t				O_Data,					//Output Data
	output	TYPE				O_Token,				//Command
);

	reg	[WIDTH_DAYA-1:0]		ResultData;


	assign O_Valid				= I_En;
	assign O_Data				= ( I_En ) ? ResultData : '0;
	assign O_Token				= ( I_En ) ? I_Token	: '0;


	always_comn begin
		case ( I_Token.instr.op.OpCode )
			2'b00: assign ResultData	= ~I_Data1;
			2'b01: assign ResultData	= I_Data1 & I_Data2;
			2'b10: assign ResultData	= I_Data1 | I_Data2;
			2'b11: assign ResultData	= I_Data1 ^ I_Data2;
		endcase
	end

endmodule