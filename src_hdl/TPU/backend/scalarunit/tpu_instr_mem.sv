///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	InstrMem
///////////////////////////////////////////////////////////////////////////////////////////////////

module InstrMem
	import pkg_mpu::*;
	import pkg_tpu::*;
	import pkg_tpu::instr_t;
(
	input						clock,
	input						reset,
	input						I_Req_St,				//Request Storing
	input						O_Ack_St,				//Ack for Storing
	input	instr_t				I_St_Instr,				//Storing Instruction
	input						I_Req_Ld,				//Request Loading
	input	t_address_t			I_Ld_Address,			//Load Address
	input	t_address_t			I_St_Address,			//Store Address
	output	instr_t				O_Ld_Instr				//Loaded Instruction
);


	logic						is_Storing;
	logic						is_Storing_D1;

	instr_t						R_Instr;

	instr_t						InstrMem	[IMEM_SIZE-1:0];


	assign O_Ld_Instr 			= R_Instr;
	assign O_Ack_St				= ~is_Storing & is_Storing_D1;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			is_Storing	<= 1'b0;
		end
		else begin
			is_Storing	<= I_Req_St;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			is_Storing_D1	<= 1'b0;
		end
		else begin
			is_Storing_D1	<= is_Storing;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Instr			<= 0;
		end
		else if ( I_Req_Ld ) begin
			R_Instr			<= InstrMem[ I_Ld_Address ];
		end
	end

	always_ff @( posedge clock ) begin
		if ( I_Req_St ) begin
			InstrMem[ I_St_Address ]	<= I_St_Instr;
		end
	end

endmodule