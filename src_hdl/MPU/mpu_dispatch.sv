///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Dispatch_MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module Dispatch_MPU
	import pkg_tpu::instr_t;
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Issue,			//Request from Previous Stage
	input	id_t				I_ThreadID,				//Scalar Thread-ID from Hazard Check Unit
	output						O_Req_Lookup,			//Request to MapMan Unit
	output	id_t				O_ThreadID,				//Scalar Thread-ID to Commit Unit
	input						I_Ack_LookUp,			//Ack from MapMan Unit
	input	lookup_t			I_ThreadInfo,			//Instr Memory Info from MapMan Unit
	output						O_Ld,					//Load Instruction
	output	mpu_address_t		O_Address,				//Loading Address
	input	instr_t				I_Instr,				//Loaded Instruction
	output						O_Req,					//Issue Request
	output	instr_t				O_Instr,				//Send Loaded Instructions to TPUs
	output	mpu_issue_no_t		O_IssueNo,				//Issue No
	input	mpu_issue_no_t		I_IssueNo,				//Issue No
	output						O_Send_Thread,			//Status
	output						O_End_Send				//Flag End of Sending
);


	// Status
	logic						Loading;
	logic						End_Load;

	// Loading Information
	mpu_address_t				Length;
	logic						Set_Address;
	mpu_address_t				Base_Addr;

	// FSM for Dispatch Control
	fsm_dispatch_t				FSM_Dispatch;

	//Instruction
	instr_t						R_Instr;

	// Thread-ID
	id_t						R_ThreadID;

	// Issue-No
	mpu_issue_no_t				R_IssueNo;

	// Store Information
	mpu_address_t				R_Length;
	mpu_address_t				R_Address;

	// Thread Program Length
	//	In terms of Number of Instructions
	logic	[WIDTH_THREAD_LEN-1:0]	R_TLength;

	// Load Ack
	logic						R_Ld;
	logic						R_LdD1;


	assign O_Req				= FSM_Dispatch >= FSM_DPC_SEND_THREADID;


	// Set when Ack has come
	//	Ack comes from MapMan having Base Address and Length used for loading
	assign Set_Address			= I_Ack_LookUp;
	assign Loading				= FSM_Dispatch == FSM_DPC_SEND_INSTRS;

	// Check Loading is ended
	assign End_Load				= R_Length == 0;

	// Requset to MapMan with Thread-ID
	assign O_Req_Lookup			= FSM_Dispatch == FSM_DPC_GETINFO;
	assign O_ThreadID			= R_ThreadID;

	// Information from MapMan
	assign Length				= I_ThreadInfo.length;
	assign Base_Addr			= I_ThreadInfo.address;

	// Load Request
	assign O_Ld					= Loading;

	// Load Address
	assign O_Address			= R_Address;

	// Send Thread (Instructions) to TPU
	assign O_Instr.v			= R_Instr.v & R_LdD1;
	assign O_Instr.instr		= R_Instr.instr;
	assign O_Send_Thread		=   FSM_Dispatch == FSM_DPC_SEND_INSTRS;
	assign O_End_Send			= ( FSM_Dispatch == FSM_DPC_SEND_INSTRS ) & End_Load;

	assign O_IssueNo			= R_IssueNo;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld			<= 1'b0;
			R_LdD1			<= 1'b0;
			R_Instr			<= 0;
		end
		else begin
			R_Ld			<= Loading;
			R_LdD1			<= (  FSM_Dispatch == FSM_DPC_SEND_THREADID ) |
								( FSM_Dispatch == FSM_DPC_SEND_ISSUENO ) |
								( FSM_Dispatch == FSM_DPC_SEND_ILENGTH ) |
								R_Ld;
			R_Instr			<= (  FSM_Dispatch == FSM_DPC_SEND_THREADID ) ?	R_ThreadID :
								( FSM_Dispatch == FSM_DPC_SEND_ISSUENO ) ?	R_IssueNo :
								( FSM_Dispatch == FSM_DPC_SEND_ILENGTH ) ?	R_TLength :
								( I_Instr.v ) ?								I_Instr :
																			'0;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ThreadID		<= 0;
			R_IssueNo		<= 0;
		end
		else if ( I_Req_Issue ) begin
			R_ThreadID		<= I_ThreadID;
			R_IssueNo		<= I_IssueNo;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length		<= 0;
		end
		else if ( Loading ) begin
			R_Length		<= R_Length - 1'b1;
		end
		else if ( Set_Address ) begin
			R_Length		<= Length;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_TLength		<= 0;
		end
		else if ( Set_Address ) begin
			R_TLength		<= Length;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Address		<= 0;
		end
		else if ( Loading ) begin
			R_Address		<= R_Address + 1'b1;
		end
		else if ( Set_Address ) begin
			R_Address		<= Base_Addr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Dispatch	<= FSM_DPC_INIT;
		end
		else case ( FSM_Dispatch )
			FSM_DPC_INIT: begin
				if ( I_Req_Issue ) begin
					FSM_Dispatch	<= FSM_DPC_GETINFO;
				end
				else begin
					FSM_Dispatch	<= FSM_DPC_INIT;
				end
			end
			FSM_DPC_GETINFO: begin
				if ( I_Ack_LookUp ) begin
					FSM_Dispatch	<= FSM_DPC_SEND_THREADID;
				end
				else begin
					FSM_Dispatch	<= FSM_DPC_GETINFO;
				end
			end
			FSM_DPC_SEND_THREADID: begin
				FSM_Dispatch	<= FSM_DPC_SEND_ISSUENO;
			end
			FSM_DPC_SEND_ISSUENO: begin
				FSM_Dispatch	<= FSM_DPC_SEND_ILENGTH;
			end
			FSM_DPC_SEND_ILENGTH: begin
				FSM_Dispatch	<= FSM_DPC_SEND_INSTRS;
			end
			FSM_DPC_SEND_INSTRS: begin
				if ( End_Load ) begin
					FSM_Dispatch	<= FSM_DPC_INIT;
				end
				else begin
					FSM_Dispatch	<= FSM_DPC_SEND_INSTRS;
				end
			end
			default: begin
				FSM_Dispatch	<= FSM_DPC_INIT;
			end
		endcase
	end

endmodule