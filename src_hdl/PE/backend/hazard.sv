module Hazard (
	input						clock,
	input						reset,
	input						I_Req_Issue,					//Request from Previous Stage
	input	iw_t				I_Index_Entry,					//Set of Indeces
	input						I_Slice,						//Flaag: Index-Sllicing
	output						O_Req_Issue,					//Request to Next Stage
	output						O_No_Issue,
	output						O_RAR_Hzard						//RAR-Hazard
);

	logic						Valid_Issue;
	logic						RAR_Hazard;
	logic						RAW_Hazard_Src1;
	logic						RAW_Hazard_Src2;
	logic						RAW_Hazard_Src3;
	logic						WAR_Hazard_Src1;
	logic						WAR_Hazard_Src2;
	logic						WAR_Hazard_Src3;
	logic						RAR_Hazard_Src1;
	logic						RAR_Hazard_Src2;
	logic						RAR_Hazard_Src3;


	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_DstID_DstID;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_DstID_SrcID1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_DstID_SrcID2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_DstID_SrcID3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID1_DstID;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID1_SrcID1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID1_SrcID2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID1_SrcID3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID2_DstID;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID2_SrcID1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID2_SrcID2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID2_SrcID3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID3_DstID;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID3_SrcID1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID3_SrcID2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_SrcID3_SrcID3;

	logic						R_Req;
	logic						R_No_Issue;
	logic						R_RAR_Hazard;
	logic						R_WAW_Hazard;
	logic						R_RAW_Hazard_Src1;
	logic						R_RAW_Hazard_Src2;
	logic						R_RAW_Hazard_Src3;
	logic						R_WAR_Hazard_Src1;
	logic						R_WAR_Hazard_Src2;
	logic						R_WAR_Hazard_Src3;
	logic						R_RAR_Hazard_Src1;
	logic						R_RAR_Hazard_Src2;
	logic						R_RAR_Hazard_Src3;

	tab_hazard_t				TabHazard [NUM_ENTRY_HAZARD-1:0];


	assign O_Req_Issue			= R_Req;
	assign O_No_Issue			= R_No_Issue;
	assign O_RAR_Hzard			= R_RAR_Hzard;

	assign RAW_Hazard_Src1		= |is_Matched_SrcID1_DstID;
	assign RAW_Hazard_Src2		= |is_Matched_SrcID2_DstID;
	assign RAW_Hazard_Src3		= |is_Matched_SrcID3_DstID;

	assign WAR_Hazard_Src1		= |is_Matched_DstID_SrcID1;
	assign WAR_Hazard_Src2		= |is_Matched_DstID_SrcID2;
	assign WAR_Hazard_Src3		= |is_Matched_DstID_SrcID3;

	assign WAW_Hazard			= |is_Matched_DstID_DstID;

	assign RAR_Hazard_Src1		= ( |is_Matched_SrcID1_SrcID1 ) | ( |is_Matched_SrcID1_SrcID2 ) | ( |is_Matched_SrcID1_SrcID3 );
	assign RAR_Hazard_Src2		= ( |is_Matched_SrcID2_SrcID1 ) | ( |is_Matched_SrcID2_SrcID2 ) | ( |is_Matched_SrcID2_SrcID3 );
	assign RAR_Hazard_Src3		= ( |is_Matched_SrcID3_SrcID1 ) | ( |is_Matched_SrcID3_SrcID2 ) | ( |is_Matched_SrcID3_SrcID3 );

	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			assign is_Matched_DstID_DstID[ i ]	= TabHazard[ i ].Valid_Dst  & I_Index_Entry.v_dst  & ( TabHazard[ i ].DstID  == I_Index_Entry.i_dst );
			assign is_Matched_DstID_SrcID1[ i ]	= TabHazard[ i ].Valid_Src1 & I_Index_Entry.v_src1 & ( TabHazard[ i ].SrcID1 == I_Index_Entry.i_dst );
			assign is_Matched_DstID_SrcID2[ i ]	= TabHazard[ i ].Valid_Src2 & I_Index_Entry.v_src2 & ( TabHazard[ i ].SrcID2 == I_Index_Entry.i_dst );
			assign is_Matched_DstID_SrcID3[ i ]	= TabHazard[ i ].Valid_Src3 & I_Index_Entry.v_src3 & ( TabHazard[ i ].SrcID3 == I_Index_Entry.i_dst );

			assign is_Matched_SrcID1_DstID[ i ]	= TabHazard[ i ].Valid_Dst  & I_Index_Entry.v_src1 & ( TabHazard[ i ].DstID  == I_Index_Entry.i_src1 );
			assign is_Matched_SrcID1_SrcID1[ i ]= TabHazard[ i ].Valid_Src1 & I_Index_Entry.v_src1 & ( TabHazard[ i ].SrcID1 == I_Index_Entry.i_src1 );
			assign is_Matched_SrcID1_SrcID2[ i ]= TabHazard[ i ].Valid_Src2 & I_Index_Entry.v_src1 & ( TabHazard[ i ].SrcID2 == I_Index_Entry.i_src1 );
			assign is_Matched_SrcID1_SrcID3[ i ]= TabHazard[ i ].Valid_Src3 & I_Index_Entry.v_src1 & ( TabHazard[ i ].SrcID3 == I_Index_Entry.i_src1 );

			assign is_Matched_SrcID2_DstID[ i ]	= TabHazard[ i ].Valid_Dst  & I_Index_Entry.v_src2 & ( TabHazard[ i ].DstID  == I_Index_Entry.i_src2 );
			assign is_Matched_SrcID2_SrcID1[ i ]= TabHazard[ i ].Valid_Src1 & I_Index_Entry.v_src2 & ( TabHazard[ i ].SrcID1 == I_Index_Entry.i_src2 );
			assign is_Matched_SrcID2_SrcID2[ i ]= TabHazard[ i ].Valid_Src2 & I_Index_Entry.v_src2 & ( TabHazard[ i ].SrcID2 == I_Index_Entry.i_src2 );
			assign is_Matched_SrcID2_SrcID3[ i ]= TabHazard[ i ].Valid_Src3 & I_Index_Entry.v_src2 & ( TabHazard[ i ].SrcID3 == I_Index_Entry.i_src2 );

			assign is_Matched_SrcID3_DstID[ i ]	= TabHazard[ i ].Valid_Dst  & I_Index_Entry.v_src3 & ( TabHazard[ i ].DstID  == I_Index_Entry.i_src3 );
			assign is_Matched_SrcID3_SrcID1[ i ]= TabHazard[ i ].Valid_Src1 & I_Index_Entry.v_src3 & ( TabHazard[ i ].SrcID1 == I_Index_Entry.i_src3 );
			assign is_Matched_SrcID3_SrcID2[ i ]= TabHazard[ i ].Valid_Src2 & I_Index_Entry.v_src3 & ( TabHazard[ i ].SrcID2 == I_Index_Entry.i_src3 );
			assign is_Matched_SrcID3_SrcID3[ i ]= TabHazard[ i ].Valid_Src3 & I_Index_Entry.v_src3 & ( TabHazard[ i ].SrcID3 == I_Index_Entry.i_src3 );
		end
	end

	assign Valid_Issue			= I_Req_Issue & ~( RAW_Hazard_Src1 | RAW_Hazard_Src2 | RAW_Hazard_Src3 | WAR_Hazard_Src1 | WAR_Hazard_Src2 | WAR_Hazard_Src3 | WAW_Hazard );
	assign RAR_Hazard			= I_Slice & ( RAR_Hazard_Src1 | RAR_Hazard_Src2 | RAR_Hazard_Src3 );

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAW_Hazard_Src1	<= 1'b0;
		end
		else begin
			R_RAW_Hazard_Src1	<= RAW_Hazard_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAW_Hazard_Src2	<= 1'b0;
		end
		else begin
			R_RAW_Hazard_Src2	<= RAW_Hazard_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAW_Hazard_Src3	<= 1'b0;
		end
		else begin
			R_RAW_Hazard_Src3	<= RAW_Hazard_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_WAR_Hazard_Src1	<= 1'b0;
		end
		else begin
			R_WAR_Hazard_Src1	<= WAR_Hazard_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_WAR_Hazard_Src2	<= 1'b0;
		end
		else begin
			R_WAR_Hazard_Src2	<= WAR_Hazard_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_WAR_Hazard_Src3	<= 1'b0;
		end
		else begin
			R_WAR_Hazard_Src3	<= WAR_Hazard_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_WAW_Hazard		<= 1'b0;
		end
		else begin
			R_WAW_Hazard		<= WAW_Hazard;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAR_Hazard_Src1	<= 1'b0;
		end
		else begin
			R_RAR_Hazard_Src1	<= RAR_Hazard_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAR_Hazard_Src2	<= 1'b0;
		end
		else begin
			R_RAR_Hazard_Src2	<= RAR_Hazard_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAR_Hazard_Src3	<= 1'b0;
		end
		else begin
			R_RAR_Hazard_Src3	<= RAR_Hazard_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAR_Hazard_Src3	<= 1'b0;
		end
		else begin
			R_RAR_Hazard_Src3	<= RAR_Hazard_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_RAR_Hazard		<= 1'b0;
		end
		else begin
			R_RAR_Hazard		<= RAR_Hazard;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req				<= 1'b0;
		end
		else begin
			R_Req				<= Valid_Issue;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_No_Issue			<= '0;
		end
		else begin
			R_No_Issue			<= WNo;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			TabHazard			<= '0;
		end
		else if ( I_Req_Commit | I_Req_Issue ) begin
			if ( I_Req_Commit ) begin
				TabHazard[ I_Commit_No ].Valid_Dst	<= 1'b0;
				TabHazard[ I_Commit_No ].Valid_Src1	<= 1'b0;
				TabHazard[ I_Commit_No ].Valid_Src2	<= 1'b0;
				TabHazard[ I_Commit_No ].Valid_Src3	<= 1'b0;
			end

			if ( I_Req_Issue ) begin
				TabHazard[ WNo ] <= I_Index_Entry;
			end
		end
	end

	//// Module: Ring-Buffer Controller
	// Write-Enable		: I_Req_Issue & ~Full;
	// Read-Enable		: Valid_Issue & ~Empty

endmodule