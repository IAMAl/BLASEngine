module Commit(
	input						clock,
	input						reset,
	input									I_Req_Issue,
	input [$clocg(NUM_ENTRY_SCALAR)-1:0]	I_Issue_No,
	input									I_Req_Commit,
	input [$clocg(NUM_ENTRY_SCALAR)-1:0]	I_CommitNo,
	output									O_Req_Commit,
	output [$clocg(NUM_ENTRY_SCALAR)-1:0]	O_CommitNo
);

	pcu_tab_commit							IssueInfo	[NUM_ENTRY_SCALAR-1:0];
	logic	[$clog(NUM_ENTRY_SCALAR)-1:0]	R_Commit_No;
	logic									R_Commit;

	assign Commit			= Valid[ RNo ] & IssedInfo[ RNo ].Commit;

	assign O_Req_Commit		= R_Commit;
	assign O_CommitNo		= R_Commit_No;

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
			R_Commit_No		<= 1'b0;
		end
		else begin
			R_Commit_No		<= IssedInfo[ RNo ].IsseNo;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			IssueInfo			<= '0;
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
	// Write-Enable		: I_Req_Issue & ~Full;
	// Read-Enable		: Commit & ~Empty

endmodule