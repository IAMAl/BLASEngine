module HazardCheck #(
	import pkg_mpu::*;
)(
	input							clock,
	input							reset,
	input							I_Ack,						//Ack from Dispatch Unit
	input							I_Commit,					//Commit Signal from Commit Unit
	input	[WIDTH_ENTRY_STH-1:0]	I_CommitNo,					//Commit No. from Commit Unit
	input							I_Req,						//Request from Previous Stage
	input	id_t					I_ThreadID_S,				//Scalar Thread-ID
	output							O_Req,						//Request to Next Stage
	output	id_t					O_ThreadID_S,				//Scalar Thread-ID to Commit Unit
	output	[WIDTH_ENTRY_STH-1:0]	O_IssueNo,					//Issue No to Commit Unit
);


	logic	[NUM_ENTRY_STH-1:0]		Valid;
	logic	[NUM_ENTRY_STH-1:0]		Commit;

	logic							R_Req;
	logic							R_Req_Issue;
	logic	[NUM_ENTRY_STH-1:0]		R_Issue_No;
	mpu_tab_hazard_t				ThreadID		[NUM_ENTRY_STH-1:0];


	//// Issue Sequence
	assign O_Req					= R_Req_Issue;
	assign O_ThreadID_S				= ThreadID[ Issue_No ].ID;
	assign O_IssueNo				= R_Issue_No;

	// Check Issable or Not
	assign Issueable				= &is_Matched;

	// Generate Mask Flags
	always_comb begin
		for ( int=0; i<NUM_ENTRY_STH; ++i ) begin
			assign Mask[ i ]		=  ThreadID[ i ].Src;
		end
	end

	// One Set takes Seriese of Entries
	// Ring-Buffer Controller
	// Issue__No:	Pointer for Read
	// WNo:			Pointer for Write
	always_comb begin
		for ( int i=0; i<NUM_ENTRY_STH; ++i ) begin
			assign is_Matched[ i ]	= ~( ( Valid[ i ] & ~ThreadID[ i ].Commit & ( ThreadID[ i ].Src_ID == ThreadID[ Issue_No ].ID ) & ( i != Issue_No ) ) ^ Mask[ i ] );
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
		else if ( I_Ack ) begin
			R_Req_Issue		<= 1'b0;
		end
		else if ( Issueable ) begin
			R_Req_Issue		<= 1'b1;
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
	// ThreadID[].ID	: Scalar Thread=ID of This
	// ThreadID[].Src	: Source ID Indication Flag
	// ThreadID[].Src_ID: Source Scalar Thread=ID for This
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			ThreadID		<= '0;
		end
		else if ( I_Commit | I_Req ) begin
			if ( I_Commit ) begin
				ThreadID[ I_CommitNo ].Commmit	<= 1'b1;
			end

			if ( I_Req & R_Req ) begin
				Valid[ WNo ]			<= 1'b1;
				ThreadID[ WNo ].Src		<= 1'b1;
				ThreadID[ WNo ].Src_ID	<= I_ThreadID_S;
				ThreadID[ WNo ].Commmit	<= 1'b0;
			end
			else if ( I_Req & ~R_Req ) begin
				Valid[ WNo ]			<= 1'b1;
				ThreadID[ WNo ].ID		<= I_ThreadID_S;
				ThreadID[ WNo ].Src		<= 1'b0;
				ThreadID[ WNo ].Src_ID	<= 0;
				ThreadID[ WNo ].Commmit	<= 1'b0;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	assign Full				= Num == (NUM_ENTRY_STH-1);
	assign We				= I_Req & ~Full;
	assign Re				= Issueable & ~Empty;
	RingBuffCTRL #(
		.NUM_ENTRY(		NUM_ENTRY_STH		)
	) HazardTab_Ptr
	(
		.clock(			clock				),
		.reset(			reset				),
		.I_We(			We					),
		.I_Re(			Re					),
		.O_WAddr(		WNo					),
		.O_RAddr(		Issue_No			),
		.O_Full(							),
		.O_Empty(		Empty				),
		.O_Num(			Num					)
	);

endmodule