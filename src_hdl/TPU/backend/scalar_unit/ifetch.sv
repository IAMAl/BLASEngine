///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	IFetch
///////////////////////////////////////////////////////////////////////////////////////////////////

module IFetch
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Req,					//Enable to Work
	input						I_Empty,				//Flag: State in Empty for Instr Memory
	input						I_Term,					//Flag: Termination
	input	instr_t				I_Instr,				//Instruction
	output						O_Req,					//Request to Next Stage
	output	instruction_t		O_Instr,				//Instruction
	output						O_Re_Instr				//Read-Enabloe for Instr Memory
);


	logic						We_Instr;

	logic						R_Req;
	logic						R_Req_D1;
	logic						R_Empty;
	logic						R_Term;

	instruction_t				R_Instr;
	logic						Req;


	// Capture Instruction
	assign We_Instr				= Req & I_Instr.v;

	// Send Instruction to Next Stage
	assign O_Req				= R_Req_D1;
	assign O_Instr				= R_Instr;

	// Reqd-Enable to Instruction Buffer
	assign O_Re_Instr			= ~R_Empty;

	// Delayed to Retime
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req_D1		<= 1'b0;
		end
		else begin
			R_Req_D1		<= ~R_Empty;
		end
	end

	// Capturing Request
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req			<= 1'b0;
		end
		else begin
			R_Req			<= I_Req;
		end
	end

	// Capturing State of Insgtruction Memory
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Empty			<= 1'b0;
		end
		else begin
			R_Empty			<= I_Empty;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Term			<= 1'b0;
		end
		else begin
			R_Term			<= I_Term;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req				<= 1'b0;
		end
		else if ( R_Term ) begin
			Req				<= 1'b0;
		end
		else if ( R_Req & ~R_Empty ) begin
			Req				<= 1'b1;
		end
	end

	// Instruction Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Instr			<= '0;
		end
		else if ( We_Instr ) begin
			R_Instr			<= I_Instr.instr;
		end
	end

endmodule
