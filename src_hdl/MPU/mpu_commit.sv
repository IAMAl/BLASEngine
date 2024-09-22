///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Commit_MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module Commit_MPU
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Issue,			//Request from Dispatch Unit
	input	mpu_issue_no_t		I_Issue_No,				//Issue No. from Dispatch Unit
	input						I_Req_Commit,			//Commit from Coomit-Agregator Unit
	input	mpu_issue_no_t		I_CommitNo,				//Commit No from Commit-Agregator Unit
	output						O_Req_Commit,			//Request to Next-Stage
	output	mpu_issue_no_t		O_Issue_No,				//Commit No to Next-Stage
	output						O_Full					//Flag: State in Full of Table
);


	logic	[NUM_ENTRY_HAZARD-1:0]	Valid;
	logic						Commit;

	// Commit Table Handling
	logic						We;
	logic						Re;
	mpu_issue_no_t				WNo;
	mpu_issue_no_t				RNo;
	logic						Full;
	logic						Empty;

	// Commit Table Matter
	mpu_tab_commit_t			IssueInfo	[NUM_ENTRY_HAZARD-1:0];
	mpu_issue_no_t				R_Issue_No;
	logic						R_Commit;


	// Check First Entry can be committed or not
	assign Commit				= Valid[ RNo ] & IssedInfo[ RNo ].Commit;

	// Commit Request
	assign O_Req_Commit			= R_Commit;
	assign O_Issue_No			= R_Issue_No;

	// Table Status
	assign O_Full				= Full;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Commit		<= 1'b0;
		end
		else begin
			R_Commit		<= Commit;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Issue_No		<= 1'b0;
		end
		else if ( Commit ) begin
			R_Issue_No		<= IssedInfo[ RNo ].IsseNo;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY_HAZARD; ++i  ) begin
				IssueInfo[ i ]		<= '0;
			end
		end
		else if ( I_Req_Issue | I_Req_Commit ) begin
			if ( I_Req_Commit ) begin
				IssueInfo[ I_CommitNo ].Commit	<= 1'b1;
			end

			if ( I_Req_Issue ) begin
				IssueInfo[ WNo ].Valid			<= 1'b1;
				IssueInfo[ WNo ].IssueNo		<= I_Issue_No;
				IssueInfo[ WNo ].Commit			<= 1'b0;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	assign We					= I_Req_Issue & ~Full;
	assign Re					= Commit & ~Empty;
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY_HAZARD		)
	) HazardTab_Ptr
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.I_Offset(			'0						),
		.O_WAddr(			WNo						),
		.O_RAddr(			RNo						),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(										)
	);

endmodule