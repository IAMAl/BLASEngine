module HazardCheck (
	input						clock,
	input						reset,
	input						I_Ack,
	input						I_Commit,
	input	[$clog2(NUM_ENTRY_SCALAR)-1:0]	I_CommitNo,
	input						I_Req,
	input	id_t				I_ThreadID_Scalar,
	output						O_Req,
	output	id_t				O_ThreadID_Scalar,
	output	[$clog2(NUM_ENTRY_SCALAR)-1:0]	O_IssueNo,
);

	logic	[NUM_ENTRY_SCALAR-1:0]	Valid;
	logic	[NUM_ENTRY_SCALAR-1:0]	Commit;

	logic							R_Req;
	logic							R_Req_Issue;
	logic	[NUM_ENTRY_SCALAR-1:0]	R_Issue_No;
	pcu_tab_hazard_t				ThreadID [NUM_ENTRY_SCALAR-1:0];


	//// Issue Sequence
	assign O_Req					= R_Req_Issue;
	assign O_ThreadID_Scalar		= ThreadID[ Issue_No ].ID;
	assign O_IssueNo				= R_Issue_No;

	// Check Issable or Not
	assign Issueable				= &is_Matched;

	// Generate Mask Flags
	always_comb begin
		for ( int=0; i<NUM_ENTRY_SCALAR; ++i ) begin
			assign Mask[ i ]		=  ThreadID[ i ].Src;
		end
	end

	// One Set takes Seriese of Entries
	// Ring-Buffer Controller
	// Issue__No:	Pointer for Read
	// WNo:			Pointer for Write
	always_comb begin
		for ( int i=0; i<NUM_ENTRY_SCALAR; ++i ) begin
			assign is_Matched[ i ]	= ~( ( Valid[ i ] & ThreadID[ i ].Commit & ( ThreadID[ i ].Src_ID == ThreadID[ Issue_No ].ID ) & ( i != Issue_No ) ) ^ Mask[ i ] );
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
				ThreadID[ WNo ].Src_ID	<= I_ThreadID_Scalar;
				ThreadID[ WNo ].Commmit	<= 1'b0;
			end
			else if ( I_Req & ~R_Req ) begin
				Valid[ WNo ]			<= 1'b1;
				ThreadID[ WNo ].ID		<= I_ThreadID_Scalar;
				ThreadID[ WNo ].Src		<= 1'b0;
				ThreadID[ WNo ].Src_ID	<= 0;
				ThreadID[ WNo ].Commmit	<= 1'b0;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	// Write-Enable		: I_Req & ~Full;
	// Read-Enable		: Issueable & ~Empty

endmodule