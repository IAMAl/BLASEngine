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
	input						I_Req_St,				//Store Request
	input						I_Req,					//Request from Network Stage
	input						I_Stall,				//Force Stalling
	input						I_Sel_CondValid,		//Selector for CondValid-1/2
	input						I_CondValid1,			//Condition Valid
	input						I_CondValid2,			//Condition Valid
	input						I_Jump,					//Jump Instruction
	input						I_Branch,				//Branch Instruction
	input	issue_no_t			I_Timing_MY,			//Count Value for This Instruction
	input	issue_no_t			I_Timing_WB,			//Count Value for Write-Back Instr
	input	state_t				I_State,				//Status Register
	input						I_Cond,					//Flag: Condition
	input	address_t			I_Src,					//Source Value
	output						O_IFetch,				//Instruction Fetch
	output	address_t			O_Address,				//Address (Program COunter)
	output						O_StallReq				//Stall Request
);


	logic						Cond_Valid;
	logic						Valid;
	logic						Taken;
	logic						Update;
	address_t					Address;
	logic						StallReq;
	logic						Req;
	logic						Ready;

	logic						R_Req;
	logic						R_Cond;
	logic						R_CondValid;

	logic						R_St;

	address_t					R_Address;


	assign Req					= ~I_Stall & I_Req;


	// Validation of Arriving Condition Signal
	//	I_Cond have Status Values
	//	CondValid signal validates timing
	assign Cond_Valid			= ( I_Sel_CondValid ) ? I_CondValid2 : I_CondValid1;


	// Conditional Branch Instruction should be
	//	next instruction of evaluation (ex. compare instruction)
	//	The I_Timing_xx holds unique value generated at
	//	issueing the instruction.
	//	The I_Timing_WB is the evaluation instruction
	//	The I_Timing_MY is the branch (this) instruction
	//	This module works as execution unit, entering after network stage
	assign Valid				= ( I_Timing_MY == ( I_Timing_WB + 1'b1 ) );
	assign Ready				= Valid & I_Branch;


	// Branch Evaluation
	assign Taken				= Ready & I_Cond;//I_State[ I_Cond ];


	// Updating Address
	assign Update				= ( Req & ( ~I_Branch | Ready ) ) | R_St;
	assign Address				= ( I_Req_St & ~R_St ) ?	0:
									( Taken ) ?				R_Address + I_Src :
															R_Address + 1'b1;


	// Stall Request to Wait for ValidCond
	assign StallReq				= R_Req & ~R_Cond;


	// Send Instruction Fetch Request
	assign O_IFetch				= R_Req;


	// Program Address
	assign O_Address			= R_Address;


	// Stall Request
	assign O_StallReq			= StallReq;


	// Capture Request
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req			<= 1'b0;
		end
		else begin
			R_Req			<= Req;
		end
	end

	// Capture Store Request
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St			<= 1'b0;
		end
		else if ( I_Req ) begin
			R_St			<= 1'b0;
		end
		else if ( I_Req_St ) begin
			R_St			<= 1'b1;
		end
	end

	// Retime to Make Stall-Sinal
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Cond			<= 1'b1;
		end
		else begin
			R_Cond			<= ~R_CondValid & I_Req;
		end
	end

	// Validation of Branch
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_CondValid		<= 1'b0;
		end
		else if ( StallReq ) begin
			R_CondValid		<= 1'b0;
		end
		else if ( Cond_Valid ) begin
			R_CondValid		<= 1'b1;
		end
	end

	// Program Address
	always_ff @( posedge clock ) begin
		if ( reset) begin
			R_Address		<= '0;
		end
		else if ( I_Req_St & ~R_St ) begin
			R_Address		<= '0;
		end
		else if ( Req & I_Jump ) begin
			R_Address		<= I_Src;
		end
		else if ( Update ) begin
			R_Address		<= Address;
		end
	end

endmodule