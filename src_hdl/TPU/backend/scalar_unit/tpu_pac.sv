///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	PACUnit
///////////////////////////////////////////////////////////////////////////////////////////////////

module PACUnit
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Ld,				//Request of Fetching
	input						I_End_Ld,				//End of Fetching
	input						I_Stall,				//Force Stalling
	input						I_Valid,				//Condition Valid
	input						I_Jump,					//Jump Instruction
	input						I_Branch,				//Branch Instruction
	input	state_t				I_State,				//Status Register
	input	cond_t				I_Cond,					//Flag: Condition
	input	i_address_t			I_Src,					//Source Value
	output						O_Re,					//Instruction Fetch
	output	i_address_t			O_Address				//Address (Program COunter)
);

	logic						Jump;
	logic						Taken;
	logic						Update;
	i_address_t					Address;
	logic						Req;

	i_address_t					R_Address;


	assign Req				= I_Req_Ld;

	// Branch Evaluation
	assign Taken			= I_Valid & I_Branch & I_State[ I_Cond ] & ~I_Stall;

	// Jump
	assign Jump				= I_Valid & I_Jump & ~I_Stall;

	// Updating Address
	assign Update			= Req;
	assign Address			= ( Jump ) ?		R_Address + I_Src :
								( Taken ) ?		R_Address + I_Src :
								( ~I_Stall ) ?	R_Address + 1'b1 :
												R_Address;

	// Send Instruction Fetch Request
	assign O_Re				= Req;

	// Program Address
	assign O_Address		= R_Address;


	always_ff @( posedge clock ) begin
		if ( reset) begin
			R_Address		<= '0;
		end
		else if ( I_End_Ld ) begin
			R_Address		<= '0;
		end
		else if ( Update ) begin
			R_Address		<= Address;
		end
	end

endmodule
