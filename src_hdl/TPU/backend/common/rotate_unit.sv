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

module Rotate_Unit
	import pkg_tpu::*;
(
	input						I_En,
	input   opt_t 				I_Op,
	input   data_t				I_Data1,
	input   data_t				I_Data2,
	input   issue_no_t			I_Issue_No,
	output  data_t				O_Valid,
	output  data_t				O_Data,
	output  issue_no_t			O_Issue_No
);


localparam	LOG_WIDTHD			= $clog2(WIDTH_DATA)-1;

reg	[WIDTH_DAYA-1:0]			ResultData;


assign O_Valid					= I_En;
assign O_Data					= ( I_En ) ? ResultData : '0;
assign O_Issue_No				= ( I_En ) ? I_Issue_No : '0:


always_comn begin
	case ( I_Op.OpCode )
		2'b00: assign ResultData	= ( I_Data1 << I_Data2[LOG_WIDTHD:0] ) | ( I_Data1 >> ( LOG_WIDTHD -  I_Data2[LOG_WIDTHD:0] ) );
		2'b10: assign ResultData	= ( I_Data1 >> I_Data2[LOG_WIDTHD:0] ) | ( I_Data1 << ( LOG_WIDTHD -  I_Data2[LOG_WIDTHD:0] ) );
		default: assign ResultData	= '0;
	endcase
end

endmodule