///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	HazardCheck_TPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module HazardCheck_TPU
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Issue,			//Request from Previous Stage
	input						I_Req,					//Request to Work ToDo
	input	instr_t				I_Instr,				//Instruction
	input						I_Req_Commit,			//Request to Commit
	input	[WIDTH_BUFF-1:0]	I_Commit_No,			//Commit (Issued) No.
	output						O_Req_Issue,			//Request to Next Stage
	output	command_t			O_Instr,				//Issue(Dispatch) Instruction
	output						O_RAR_Hazard,			//RAR-Hazard
	output						O_RAW_Hazard,			//RAW-Hazard
	output						O_WAR_Hazard,			//WAR-Hazard
	output						O_WAW_Hazard,			//WAW-Hazard
	output	issue_no_t			O_Rd_Ptr				//Read Pointer to Commit Unit
);


	localparam int WIDTH_BUFF	= $clog2(DEPTH_BUFF);
	localparam int WIDTH_ENTRY	= $clog2(NUM_ENTRY_HAZARD);


	iw_t						Index_Entry;

	index_s_t					Index_Dst;
	index_s_t					Index_Src1;
	index_s_t					Index_Src2;
	index_s_t					Index_Src3;

	logic						We;
	logic						Re;
	logic						Full;
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


	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_dst_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_dst_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_dst_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_dst_src3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src1_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src1_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src1_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src1_src3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src2_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src2_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src2_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src2_src3;

	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src3_dst;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src3_src1;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src3_src2;
	logic [NUM_ENTRY_HAZARD-1:0]	is_Matched_src3_src3;


	logic						R_Req;
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


	//// Storing to Table
	logic						Set_Index;

	logic						R_Valid_Dst;
	logic						R_Valid_Src1;
	logic						R_Valid_Src2;
	logic						R_Valid_Src3;

	index_s_t					R_Index_Dst;
	index_s_t					R_Index_Src1;
	index_s_t					R_Index_Src2;
	index_s_t					R_Index_Src3;

	iw_t						R_Indeces;

	logic						We_Valid_Dst;
	logic						We_Valid_Src1;
	logic						We_Valid_Src2;
	logic						We_Valid_Src3;


	logic						is_Vec;
	logic						Sel_Unit;
	logic						Valid_Dst;
	logic						Valid_Src1;
	logic						Valid_Src2;
	logic						Valid_Src3;
	index_t						Index_Dst;
	index_t						Index_Src1;
	index_t						Index_Src2;
	index_t						Index_Src3;
	logic						Slice1;
	logic						Slice2;
	logic						Slice3;


	assign Sel_Unit				= I_Instr.op.Sel_Unit;
	assign Valid_Dst			= I_Instr.dst.v;
	assign Valid_Src1			= I_Instr.src1.v;
	assign Valid_Src2			= I_Instr.src2.v;
	assign Valid_Src3			= I_Instr.src3.v;
	assign Index_Dst			= I_Instr.dst.idx;
	assign Index_Src1			= I_Instr.src1.idx;
	assign Index_Src2			= I_Instr.src2.idx;
	assign Index_Src3			= I_Instr.src3.idx;
	assign Slice1				= I_Instr.src1.slice;
	assign Slice2				= I_Instr.src2.slice;
	assign Slice3				= I_Instr.src3.slice;


	assign O_Req_Issue			= R_Req;
	assign O_Instr.instr		= TabHazard[ RNo ].instr;
	assign O_Instr.issue_no		= RNo;

	assign O_RAR_Hazard			= R_RAR_Hazard;
	assign O_RAW_Hazard			= R_RAW_Hazard;
	assign O_WAR_Hazard			= R_WAR_Hazard;
	assign O_WAW_Hazard			= R_WAW_Hazard;


	//// Referenced at Commit Select Unit
	assign O_Rd_Ptr				= RNo;


	//// Forming Indeces for Mixing Scalar and Vector Units
	assign Index_Dst			= { is_Vec, Index_Dst };
	assign Index_Src1			= { is_Vec, Index_Src1 };
	assign Index_Src2			= { is_Vec, Index_Src2 };
	assign Index_Src3			= { is_Vec, Index_Src3 };


	//// Storing to Table
	assign Set_Index			= We_Valid_Dst | We_Valid_Src1 | We_Valid_Src1 | We_Valid_Src2 | We_Valid_Src3;
	assign Index_Entry			= R_Indeces;


	//// Hazard Detections
	assign RAW_Hazard_Src1		= |is_Matched_src1_dst;
	assign RAW_Hazard_Src2		= |is_Matched_src2_dst;
	assign RAW_Hazard_Src3		= |is_Matched_src3_dst;

	assign WAR_Hazard_Src1		= |is_Matched_dst_src1;
	assign WAR_Hazard_Src2		= |is_Matched_dst_src2;
	assign WAR_Hazard_Src3		= |is_Matched_dst_src3;

	assign WAW_Hazard			= |is_Matched_dst_dst;

	assign RAR_Hazard_Src1		= ( |is_Matched_src1_src1 ) | ( |is_Matched_src1_src2 ) | ( |is_Matched_src1_src3 );
	assign RAR_Hazard_Src2		= ( |is_Matched_src2_src1 ) | ( |is_Matched_src2_src2 ) | ( |is_Matched_src2_src3 );
	assign RAR_Hazard_Src3		= ( |is_Matched_src3_src1 ) | ( |is_Matched_src3_src2 ) | ( |is_Matched_src3_src3 );

	always_comb begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			assign is_Matched_dst_dst[ i ]		= TabHazard[ i ].dst.v  & Valid_Dst  & ( TabHazard[ i ].dst.idx  == Index_Dst );
			assign is_Matched_dst_src1[ i ]		= TabHazard[ i ].src1.v & Valid_Src1 & ( TabHazard[ i ].src1.idx == Index_Dst );
			assign is_Matched_dst_src2[ i ]		= TabHazard[ i ].src2.v & Valid_Src2 & ( TabHazard[ i ].src2.idx == Index_Dst );
			assign is_Matched_dst_src3[ i ]		= TabHazard[ i ].src3.v & Valid_Src3 & ( TabHazard[ i ].src3.idx == Index_Dst );

			assign is_Matched_src1_dst[ i ]		= TabHazard[ i ].dst.v  & Valid_Src1 & ( TabHazard[ i ].dst.idx  == Index_Src1 );
			assign is_Matched_src1_src1[ i ]	= TabHazard[ i ].src1.v & Valid_Src1 & ( TabHazard[ i ].src1.idx == Index_Src1 ) & ( TabHazard[ i ].slice_len != 0 );
			assign is_Matched_src1_src2[ i ]	= TabHazard[ i ].src2.v & Valid_Src1 & ( TabHazard[ i ].src2.idx == Index_Src1 ) & ( TabHazard[ i ].slice_len != 0 );
			assign is_Matched_src1_src3[ i ]	= TabHazard[ i ].src3.v & Valid_Src1 & ( TabHazard[ i ].src3.idx == Index_Src1 ) & ( TabHazard[ i ].slice_len != 0 );

			assign is_Matched_src2_dst[ i ]		= TabHazard[ i ].dst.v  & Valid_Src2 & ( TabHazard[ i ].dst.idx  == Index_Src2 );
			assign is_Matched_src2_src1[ i ]	= TabHazard[ i ].src1.v & Valid_Src2 & ( TabHazard[ i ].src1.idx == Index_Src2 ) & ( TabHazard[ i ].slice_len != 0 );
			assign is_Matched_src2_src2[ i ]	= TabHazard[ i ].src2.v & Valid_Src2 & ( TabHazard[ i ].src2.idx == Index_Src2 ) & ( TabHazard[ i ].slice_len != 0 );
			assign is_Matched_src2_src3[ i ]	= TabHazard[ i ].src3.v & Valid_Src2 & ( TabHazard[ i ].src3.idx == Index_Src2 ) & ( TabHazard[ i ].slice_len != 0 );

			assign is_Matched_src3_dst[ i ]		= TabHazard[ i ].dst.v  & Valid_Src3 & ( TabHazard[ i ].dst.idx  == Index_Src3 );
			assign is_Matched_src3_src1[ i ]	= TabHazard[ i ].src1.v & Valid_Src3 & ( TabHazard[ i ].src1.idx == Index_Src3 ) & ( TabHazard[ i ].slice_len != 0 );
			assign is_Matched_src3_src2[ i ]	= TabHazard[ i ].src2.v & Valid_Src3 & ( TabHazard[ i ].src2.idx == Index_Src3 ) & ( TabHazard[ i ].slice_len != 0 );
			assign is_Matched_src3_src3[ i ]	= TabHazard[ i ].src3.v & Valid_Src3 & ( TabHazard[ i ].src3.idx == Index_Src3 ) & ( TabHazard[ i ].slice_len != 0 );
		end
	end

	assign RAR_Hazard			= ( Slice1 & RAR_Hazard_Src1 ) | ( Slice2 & RAR_Hazard_Src2 ) | ( Slice3 & RAR_Hazard_Src3 );


	//// Issueable Detection
	assign v_Issue				= Req_Issue & ~( RAW_Hazard_Src1 | RAW_Hazard_Src2 | RAW_Hazard_Src3 | WAR_Hazard_Src1 | WAR_Hazard_Src2 | WAR_Hazard_Src3 | WAW_Hazard );


	//// Buffer Control
	assign We					= Req_Issue & ~Full;
	assign Re					= Valud_Issue & ~Empty;


	//// Storing to Table
	//	 Taking Care of Stall
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Dst	<= 1'b0;
		end
		else begin
			We_Valid_Dst	<= Valid_Dst;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src1	<= 1'b0;
		end
		else begin
			We_Valid_Src1	<= Valid_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src2	<= 1'b0;
		end
		else begin
			We_Valid_Src2	<= Valid_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src3	<= 1'b0;
		end
		else begin
			We_Valid_Src3	<= Valid_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Dst		<= '0;
		end
		else begin
			R_Index_Dst		<= Index_Dst;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Src1	<= '0;
		end
		else begin
			R_Index_Src1	<= Index_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Src2	<= '0;
		end
		else begin
			R_Index_Src2	<= Index_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reest ) begin
			R_Index_Src3	<= '0;
		end
		else begin
			R_Index_Src3	<= Index_Src3;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Indeces		<= '0;
		end
		else if ( Set_Index ) begin
			if ( R_Valid_Dst ) begin
				R_Indeces.v_dst		<= 1'b1;
				R_Indeces.i_dst		<= R_Index_Dst;
			end
			else begin
				R_Indeces.v_dst		<= 1'b0;
			end

			if ( R_Valid_Src1 ) begin
				R_Indeces.v_src1	<= 1'b1;
				R_Indeces.i_src1	<= R_Index_Src1;
			end
			else begin
				R_Indeces.v_src1	<= 1'b0;
			end

			if ( R_Valid_Src2 ) begin
				R_Indeces.v_src2	<= 1'b1;
				R_Indeces.i_src2	<= R_Index_Src2;
			end
			else begin
				R_Indeces.v_src2	<= 1'b0;
			end

			if ( R_Valid_Src3 ) begin
				R_Indeces.v_src3	<= 1'b1;
				R_Indeces.i_src3	<= R_Index_Src3;
			end
			else begin
				R_Indeces.v_src3	<= 1'b0;
			end
		end
	end


	//// Hazard Detections
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
			TabHazard			<= '0;
		end
		else if ( I_Req_Commit | I_Req_Issue ) begin
			if ( I_Req_Commit ) begin
				TabHazard[ I_Commit_No ].instr.dst.v	<= 1'b0;
				TabHazard[ I_Commit_No ].instr.src1.v	<= 1'b0;
				TabHazard[ I_Commit_No ].instr.src2.v	<= 1'b0;
				TabHazard[ I_Commit_No ].instr.src3.v	<= 1'b0;
			end

			if ( We ) begin
				TabHazard[ WNo ] <= I_Instr;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_BUFF				)
	) RingBuffCTRL
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.O_WAddr(			WNo						),
		.O_RAddr(			RNo						),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(										)
	);

endmodule