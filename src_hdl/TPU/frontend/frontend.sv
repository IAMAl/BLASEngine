///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	FrontEnd
///////////////////////////////////////////////////////////////////////////////////////////////////

module FrontEnd
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_En_Exe,				//Enable Execution
	input						I_Full,					//Flag: State in Full in Buffer
	input						I_Term,					//Flag: Termination from Scalar Unit
	input						I_Nack,					//Nack from Back-End
	input						I_Req,					//Request to Work
	input	mpu_issue_no_t		I_IssueNo				//Issue No at MPU, used for Exec
	input	instr_t				I_Instr,				//Instruction
	output						O_We,					//Write-Enable for Buffer
	output	id_t				O_ThreadID,				//ThreadID to Buffer
	output	instr_t				O_Instr,				//Instruction to Buffer
	output						O_Term,					//Flag: Termination
	output	mpu_issue_no_t		O_IssueNo,				//Issue No at MPU, used for Commit
	output						O_Nack					//Nack to Allocator
);


	logic						is_FSM_TPU_SCALAR;
	logic						is_FSM_TPU_SIMT;
	logic						is_FSM_TPU_INSTR;
	logic						is_FSM_TPU_RUN;

	logic						Set_We;


	logic						R_Req;
	logic						R_En_Exe;
	logic						R_Full;
	logic						R_Term;
	logic						R_We;
	logic						R_Nack;

	fsm_pe_frontend_t			R_FSM_TPU_FRONTEND;

	mpu_issue_no_t				R_IssueNo;
	instr_t						R_Instr;
	id_t						R_ThreadID;


	// FSM State Flag
	assign is_FSM_TPU_SCALAR	= R_FSM_TPU_FRONTEND == FSM_TPU_SCALAR;
	assign is_FSM_TPU_SIMT		= R_FSM_TPU_FRONTEND == FSM_TPU_SIMT;
	assign is_FSM_TPU_INSTR		= R_FSM_TPU_FRONTEND == FSM_TPU_INSTR;
	assign is_FSM_TPU_RUN		= R_FSM_TPU_FRONTEND >  FSM_TPU_FE_INIT;

	assign Set_We               = ~R_Full & (
										( R_IssueNo.v & R_Thread_SIMT.v & R_Req ) |
										( R_En_Exe & R_Req )
									);

	assign O_We					= R_We;
	assign O_Instr				= R_Instr;
	assign O_IssueNo			= R_IssueNo;
	assign O_ThreadID			= R_ThreadID;
	assign O_Nack				= R_Full | R_Nack;
	assign O_Term				= is_FSM_TPU_RUN & ~R_Req;


	always_ff @ ( posedge clock ) begin
		if ( reset ) begin
			R_Instr				<= '0;
		end
		else if ( R_Req ) begin
			R_Instr				<= I_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ThreadID			<= '0;
		end
		else if ( R_Term ) begin
			R_ThreadID			<= '0;
		end
		else if ( R_Instr.v & is_FSM_TPU_SIMT ) begin
			R_ThreadID			<= R_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_IssueNo			<= '0;
		end
		else if ( R_Term ) begin
			R_IssueNo			<= '0;
		end
		else if ( R_Instr.v & is_FSM_TPU_SCALAR ) begin
			R_IssueNo			<= R_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_We				<= 1'b0;
		end
		else if ( ~R_Req ) begin
			R_We				<= 1'b0;
		end
		else if ( Set_We ) begin
			R_We				<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_En_Exe			<= 1'b0;
		end
		else begin
			R_En_Exe			<= I_En_Exe;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req				<= 1'b0;
		end
		else begin
			R_Req				<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Term				<= 1'b0;
		end
		else begin
			R_Term				<= I_Term;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Full				<= 1'b0;
		end
		else begin
			R_Full				<= I_Full;
		end
	end

	always_ff @( posedge clock ) begin
		if ( rset ) begin
			R_Nack				<= 1'b0;
		end
		else begin
			R_Nack				<= I_Nack;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_FSM_TPU_FrontEnd	<= FSM_TPU_FE_INIT;
		end
		else case ( R_FSM_TPU_FrontEnd )
			FSM_TPU_FE_INIT: begin
				if ( R_Req ) begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_SCALAR;
				end
				else begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_FE_INIT;
				end
			end
			FSM_TPU_SCALAR: begin
				if ( R_Req & R_Instr.v ) begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_SIMT;
				end
				else begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_SCALAR;
				end
			end
			FSM_TPU_SIMT: begin
				if ( R_Req & R_Instr.v ) begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_INSTR;
				end
				else begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_SIMT;
				end
			end
			FSM_TPU_INSTR: begin
				if ( R_Term & R_Instr.v ) begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_INSTR;
				end
				else begin
					R_FSM_TPU_FrontEnd	<= FSM_TPU_SIMT;
				end
			end
			default: begin
				R_FSM_TPU_FrontEnd	<= FSM_TPU_FE_INIT;
			end
		endcase
	end

endmodule