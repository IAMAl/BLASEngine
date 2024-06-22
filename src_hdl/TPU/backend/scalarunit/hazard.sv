module Hazard_Detect
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Issue,					//Request from Previous Stage
	input	iw_t				I_Index_Entry,					//Set of Indeces
	input						I_Slice,						//Flaag: Index-Sllicing
	input						I_Req_Commit,					//Request to Commit
	input	[WIDTH_BUFF-1:0]	I_Commit_No,					//Commit (Issued) No.
	output						O_Req_Issue,					//Request to Next Stage
	output						O_Issue_No,						//Issue(Dispatch) No
	output						O_RAR_Hzard						//RAR-Hazard
);


	localparam WIDTH_BUFF		= $clog2(DEPTH_BUFF);

	logic						We;
	logic						Re;
	logic						Full,
	logic						Empty;
	logic	[WIDTH_BUFF-1:0]	WNo;
	logic	[WIDTH_BUFF-1:0]	RNo;

	logic						v_Issue;
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


	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_dst_i_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_dst_i_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_dst_i_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_dst_i_src3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src1_i_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src1_i_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src1_i_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src1_i_src3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src2_i_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src2_i_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src2_i_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src2_i_src3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src3_i_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src3_i_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src3_i_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_i_src3_i_src3;

	logic						R_Req;
	logic						R_Issue_No;
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

	iw_t						TabHazard [NUM_ENTRY_HAZARD-1:0];


	assign O_Req_Issue			= R_Req;
	assign O_Issue_No			= R_Issue_No;
	assign O_RAR_Hzard			= R_RAR_Hzard;


	//// Hazard Detections
	assign RAW_Hazard_Src1		= |is_Matched_i_src1_i_dst;
	assign RAW_Hazard_Src2		= |is_Matched_i_src2_i_dst;
	assign RAW_Hazard_Src3		= |is_Matched_i_src3_i_dst;

	assign WAR_Hazard_Src1		= |is_Matched_i_dst_i_src1;
	assign WAR_Hazard_Src2		= |is_Matched_i_dst_i_src2;
	assign WAR_Hazard_Src3		= |is_Matched_i_dst_i_src3;

	assign WAW_Hazard			= |is_Matched_i_dst_i_dst;

	assign RAR_Hazard_Src1		= ( |is_Matched_i_src1_i_src1 ) | ( |is_Matched_i_src1_i_src2 ) | ( |is_Matched_i_src1_i_src3 );
	assign RAR_Hazard_Src2		= ( |is_Matched_i_src2_i_src1 ) | ( |is_Matched_i_src2_i_src2 ) | ( |is_Matched_i_src2_i_src3 );
	assign RAR_Hazard_Src3		= ( |is_Matched_i_src3_i_src1 ) | ( |is_Matched_i_src3_i_src2 ) | ( |is_Matched_i_src3_i_src3 );

	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			assign is_Matched_i_dst_i_dst[ i ]		= TabHazard[ i ].v_dst  & I_Index_Entry.v_dst  & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_dst );
			assign is_Matched_i_dst_i_src1[ i ]		= TabHazard[ i ].v_src1 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_dst );
			assign is_Matched_i_dst_i_src2[ i ]		= TabHazard[ i ].v_src2 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_dst );
			assign is_Matched_i_dst_i_src3[ i ]		= TabHazard[ i ].v_src3 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_dst );

			assign is_Matched_i_src1_i_dst[ i ]		= TabHazard[ i ].v_Dst  & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_src1 );
			assign is_Matched_i_src1_i_src1[ i ]	= TabHazard[ i ].v_src1 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_src1 );
			assign is_Matched_i_src1_i_src2[ i ]	= TabHazard[ i ].v_src2 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_src1 );
			assign is_Matched_i_src1_i_src3[ i ]	= TabHazard[ i ].v_src3 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_src1 );

			assign is_Matched_i_src2_i_dst[ i ]		= TabHazard[ i ].v_Dst  & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_src2 );
			assign is_Matched_i_src2_i_src1[ i ]	= TabHazard[ i ].v_src1 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_src2 );
			assign is_Matched_i_src2_i_src2[ i ]	= TabHazard[ i ].v_src2 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_src2 );
			assign is_Matched_i_src2_i_src3[ i ]	= TabHazard[ i ].v_src3 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_src2 );

			assign is_Matched_i_src3_i_dst[ i ]		= TabHazard[ i ].v_Dst  & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_src3 );
			assign is_Matched_i_src3_i_src1[ i ]	= TabHazard[ i ].v_src1 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_src3 );
			assign is_Matched_i_src3_i_src2[ i ]	= TabHazard[ i ].v_src2 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_src3 );
			assign is_Matched_i_src3_i_src3[ i ]	= TabHazard[ i ].v_src3 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_src3 );
		end
	end

	assign RAR_Hazard			= I_Slice & ( RAR_Hazard_Src1 | RAR_Hazard_Src2 | RAR_Hazard_Src3 );


	//// Issueable Detection
	assign v_Issue				= I_Req_Issue & ~( RAW_Hazard_Src1 | RAW_Hazard_Src2 | RAW_Hazard_Src3 | WAR_Hazard_Src1 | WAR_Hazard_Src2 | WAR_Hazard_Src3 | WAW_Hazard );


	//// Buffer Control
	assign We				= I_Req_Issue & ~Full;
	assign Re				= Valud_Issue & ~Empty;


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
			R_Req				<= v_Issue;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Issue_No			<= '0;
		end
		else begin
			R_Issue_No			<= WNo;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			TabHazard			<= '0;
		end
		else if ( I_Req_Commit | I_Req_Issue ) begin
			if ( I_Req_Commit ) begin
				TabHazard[ I_Commit_No ].v_Dst	<= 1'b0;
				TabHazard[ I_Commit_No ].v_src1	<= 1'b0;
				TabHazard[ I_Commit_No ].v_src2	<= 1'b0;
				TabHazard[ I_Commit_No ].v_src3	<= 1'b0;
			end

			if ( I_Req_Issue ) begin
				TabHazard[ WNo ] <= I_Index_Entry;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_BUFF					)
	) RingBuffCTRL
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.O_WAddr(			WNo							),
		.O_RAddr(			RNo							),
		.O_Full(			Full						),
		.O_Empty(			Empty						),
		.O_Num(											)
	);

endmodule