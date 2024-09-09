///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	HazardCheck_MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module HazardCheck_MPU
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Commit,			//Commit Signal from Commit Unit
	input	tpu_row_clm_t		I_Issued_No,			//Commit No. from Commit Unit
	input						I_Req,					//Request from Previous Stage
	input	id_t				I_ThreadID_S,			//Scalar Thread-ID
	output						O_Req_Issue,			//Request to Next Stage
	output	id_t				O_ThreadID_S,			//Scalar Thread-ID to Commit Unit
	output	tpu_row_clm_t		O_IssueNo,				//Issue No to Commit Unit
);


	localparam WIDTH_ENTRY		= $clog2(NUM_ENTRY_HAZARD);

	logic	[NUM_ENTRY_HAZARD-1:0]	Mask;
	logic	[NUM_ENTRY_HAZARD-1:0]	Retire;

	tpu_row_clm_t				Issue_No;

	// Table Handling
	logic						We;
	logic						Re;
	logic						Full;
	logic						Empty;

	logic	[NUM_ENTRY_HAZARD-1:0]	Valid;
	logic	[NUM_ENTRY_HAZARD-1:0]	Commit;
	logic	[WIDTH_ENTRY-1:0]	Offset;

	logic						R_Req;
	logic						R_Req_Issue;
	tpu_row_clm_t				R_Issue_No;
	mpu_tab_hazard_t			ThreadID		[NUM_ENTRY_HAZARD-1:0];


	//// Issue Sequence
	assign O_Req_Issue			= R_Req_Issue;
	assign O_ThreadID_S			= ThreadID[ Issue_No ].ID;
	assign O_IssueNo			= R_Issue_No;

	// Check Issuable or Not
	assign Issueable			= &is_Matched;

	// Generate Mask Flags
	always_comb begin
		for ( int=0; i<NUM_ENTRY_HAZARD; ++i ) begin
			assign Mask[ i ]		= ThreadID[ i ].Src;
		end
	end

	// Generate Retire Flags
	always_comb begin
		for ( int=0; i<NUM_ENTRY_HAZARD; ++i ) begin
			assign Retire[ i ]		= Valid[ i ] & ThreadID[ i ].Commit & ( i != Issue_No );
		end
	end

	// One Set takes Seriese of Entries
	// Ring-Buffer Controller
	// Issue_No:	Pointer for Read
	// WNo:			Pointer for Write
	always_comb begin
		for ( int i=0; i<NUM_ENTRY_HAZARD; ++i ) begin
			assign is_Matched[ i ]	=  ~( ( Retire[ i ] & ( ThreadID[ i ].Src_ID == ThreadID[ Issue_No ].ID ) ) ^ Mask[ i ] );
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req			<= 1'b0;
		end
		else begin
			R_Req			<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req_Issue		<= 1'b0;
		end
		else begin
			R_Req_Issue		<= Issueable;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Issue_No		<= 0;
		end
		else if ( Issueable ) begin
			R_Issue_No		<= Issue_No;
		end
	end


	//// Hazard Check Table
	// Valid[]			: Validation Flag for The Entry
	// ThreadID[].ID	: Scalar Thread-IID of This
	// ThreadID[].Src	: Source ID Indication Flag
	// ThreadID[].Src_ID: Source Scalar Thread-ID for This
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			ThreadID		<= '0;
		end
		else if ( I_Req_Commit | I_Req ) begin
			if ( Issueable ) begin
				for ( i=0: i<NUMENTRY_STH; ++i ) begin
					valid[ i ]				<= Valid[ i ] ^ ThreadID[ i ].Commit;
				end
			end

			if ( I_Rq_Commit ) begin
				ThreadID[ I_Issued_No ].Commmit	<= 1'b1;
			end

			if ( I_Req & R_Req ) begin
				Valid[ WNo ]			<= 1'b1;

				ThreadID[ WNo ].Src		<= 1'b1;
				ThreadID[ WNo ].Src_ID	<= I_ThreadID_S;
				ThreadID[ WNo ].Commmit	<= 1'b0;
				ThreadID[ WNo ].Count	<= ThreadID[ WNo - 1'b1 ].Count + 1'b1
			end
			else if ( I_Req & ~R_Req ) begin
				Valid[ WNo ]			<= 1'b1;

				ThreadID[ WNo ].ID		<= I_ThreadID_S;
				ThreadID[ WNo ].Src		<= 1'b0;
				ThreadID[ WNo ].Src_ID	<= 0;
				ThreadID[ WNo ].Commmit	<= 1'b0;
				ThreadID[ WNo ].Count	<= 1;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	assign We					= I_Req & ~Full;
	assign Re					= Issueable & ~Empty;
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY_HAZARD		)
	) HazardTab_Ptr
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.I_Offset(			Offset					),
		.O_WAddr(			WNo						),
		.O_RAddr(			Issue_No				),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(										)
	);

endmodule