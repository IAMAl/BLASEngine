///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	PipeReg_FE
///////////////////////////////////////////////////////////////////////////////////////////////////

module PipeReg_FE
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Stall,
	input	op_t				I_Op,
	output	op_t				O_Op
);


	op_t						R_Op;


	assign O_Op				= R_Op;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Op			<= '0;
		end
		else if ( ~I_Stall ) begin
			R_Op			<= I_Op;
		end
	end

endmodule