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
#(
	parameter int WIDTH_BUFF	= $clog2(NUM_ENTRY_HAZARD)
)(
	input						clock,
	input						reset,
	input						I_Req,							//Request to Work
	input						I_Slice,						//Slicing is used
	input						I_Req_Issue,					//Request from Previous Stage
	input						I_is_Vec,						//Request is for Vector Unit
	input	instruction_t		I_Instr,						//Fetched Instruction
	input						I_Commit_Req,					//Request to Commit
	input	[WIDTH_BUFF-1:0]	I_Commit_No,					//Commit (Issued) No.
	output						O_Req_Issue,					//Request to Next Stage
	output						O_Instr,						//Issue Instruction
	output						O_RAR_Hazard,					//RAR-Hazard
	output						O_RAW_Hazard,					//RAW-Hazard
	output						O_WAR_Hazard,					//WAR-Hazard
	output						O_WAW_Hazard,					//WAW-Hazard
	output	issue_no_t			O_Rd_Ptr						//Read Pointer to Commit Unit
);


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

	index_s_t					R_Index_Dst;
	index_s_t					R_Index_Src1;
	index_s_t					R_Index_Src2;
	index_s_t					R_Index_Src3;

	iw_t						R_Indeces;

	logic						We_Valid_Dst;
	logic						We_Valid_Src1;
	logic						We_Valid_Src2;
	logic						We_Valid_Src3;


	assign O_Req_Issue			= R_Req;

	assign O_Instr				= TabHazard[ RNo ].instr;

	assign O_RAR_Hazard			= R_RAR_Hazard;
	assign O_RAW_Hazard			= R_RAW_Hazard_Src1 | R_RAW_Hazard_Src2 | R_RAW_Hazard_Src3;
	assign O_WAR_Hazard			= R_WAR_Hazard_Src1 | R_WAR_Hazard_Src2 | R_WAR_Hazard_Src3;
	assign O_WAW_Hazard			= R_WAW_Hazard;


	//// Referenced at Commit Select Unit
	assign O_Rd_Ptr				= RNo;


	//// Forming Indeces for Mixing Scalar and Vector Units
	assign Index_Dst			= { I_is_Vec, I_Instr.dst.no,  I_Instr.dst.idx };
	assign Index_Src1			= { I_is_Vec, I_Instr.src1.no, I_Instr.src1.idx };
	assign Index_Src2			= { I_is_Vec, I_Instr.src1.no, I_Instr.src2.idx };
	assign Index_Src3			= { I_is_Vec, I_Instr.src1.no, I_Instr.src3.idx };


	//// Storing to Table
	assign Set_Index			= We_Valid_Dst | We_Valid_Src1 | We_Valid_Src1 | We_Valid_Src2 | We_Valid_Src3;
	assign Index_Entry			= R_Indeces;


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
		for ( int i=0; i<NUM_ENTRY_HAZARD; ++i ) begin
			is_Matched_i_dst_i_dst[ i ]		= TabHazard[ i ].instr.dst.v  & I_Instr.dst.v  & ( TabHazard[ i ].instr.dst.idx  == I_Instr.dst.idx );
			is_Matched_i_dst_i_src1[ i ]	= TabHazard[ i ].instr.src1.v & I_Instr.src1.v & ( TabHazard[ i ].instr.src1.idx == I_Instr.dst.idx );
			is_Matched_i_dst_i_src2[ i ]	= TabHazard[ i ].instr.src2.v & I_Instr.src2.v & ( TabHazard[ i ].instr.src2.idx == I_Instr.dst.idx );
			is_Matched_i_dst_i_src3[ i ]	= TabHazard[ i ].instr.src3.v & I_Instr.src3.v & ( TabHazard[ i ].instr.src3.idx == I_Instr.dst.idx );

			is_Matched_i_src1_i_dst[ i ]	= TabHazard[ i ].instr.dst.v  & I_Instr.src1.v & ( TabHazard[ i ].instr.dst.idx  == I_Instr.src1.idx );
			is_Matched_i_src1_i_src1[ i ]	= TabHazard[ i ].instr.src1.v & I_Instr.src1.v & ( TabHazard[ i ].instr.src1.idx == I_Instr.src1.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );
			is_Matched_i_src1_i_src2[ i ]	= TabHazard[ i ].instr.src2.v & I_Instr.src1.v & ( TabHazard[ i ].instr.src2.idx == I_Instr.src1.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );
			is_Matched_i_src1_i_src3[ i ]	= TabHazard[ i ].instr.src3.v & I_Instr.src1.v & ( TabHazard[ i ].instr.src3.idx == I_Instr.src1.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );

			is_Matched_i_src2_i_dst[ i ]	= TabHazard[ i ].instr.dst.v  & I_Instr.src2.v & ( TabHazard[ i ].instr.dst.idx  == I_Instr.src2.idx );
			is_Matched_i_src2_i_src1[ i ]	= TabHazard[ i ].instr.src1.v & I_Instr.src2.v & ( TabHazard[ i ].instr.src1.idx == I_Instr.src2.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );
			is_Matched_i_src2_i_src2[ i ]	= TabHazard[ i ].instr.src2.v & I_Instr.src2.v & ( TabHazard[ i ].instr.src2.idx == I_Instr.src2.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );
			is_Matched_i_src2_i_src3[ i ]	= TabHazard[ i ].instr.src3.v & I_Instr.src2.v & ( TabHazard[ i ].instr.src3.idx == I_Instr.src2.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );

			is_Matched_i_src3_i_dst[ i ]	= TabHazard[ i ].instr.dst.v  & I_Instr.src3.v & ( TabHazard[ i ].instr.dst.idx  == I_Instr.src3.idx );
			is_Matched_i_src3_i_src1[ i ]	= TabHazard[ i ].instr.src1.v & I_Instr.src3.v & ( TabHazard[ i ].instr.src1.idx == I_Instr.src3.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );
			is_Matched_i_src3_i_src2[ i ]	= TabHazard[ i ].instr.src2.v & I_Instr.src3.v & ( TabHazard[ i ].instr.src2.idx == I_Instr.src3.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );
			is_Matched_i_src3_i_src3[ i ]	= TabHazard[ i ].instr.src3.v & I_Instr.src3.v & ( TabHazard[ i ].instr.src3.idx == I_Instr.src3.idx ) & ( TabHazard[ i ].instr.slice_len != 0 );
		end
	end

	assign RAR_Hazard			= I_Slice & ( RAR_Hazard_Src1 | RAR_Hazard_Src2 | RAR_Hazard_Src3 );


	//// Issueable Detection
	assign v_Issue				= I_Req_Issue & ~( RAW_Hazard_Src1 | RAW_Hazard_Src2 | RAW_Hazard_Src3 | WAR_Hazard_Src1 | WAR_Hazard_Src2 | WAR_Hazard_Src3 | WAW_Hazard );


	//// Buffer Control
	assign We					= I_Req_Issue & ~Full;
	assign Re					= v_Issue & ~Empty;


	//// Storing to Table
	//	 Taking Care of Stall
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Dst	<= 1'b0;
		end
		else begin
			We_Valid_Dst	<= I_Req & I_Instr.dst.v;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src1	<= 1'b0;
		end
		else begin
			We_Valid_Src1	<= I_Req & I_Instr.src1.v;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src2	<= 1'b0;
		end
		else begin
			We_Valid_Src2	<= I_Req & I_Instr.src2.v;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src3	<= 1'b0;
		end
		else begin
			We_Valid_Src3	<= I_Req & I_Instr.src3.v;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Index_Dst		<= '0;
		end
		else begin
			R_Index_Dst		<= Index_Dst;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Index_Src1	<= '0;
		end
		else begin
			R_Index_Src1	<= Index_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Index_Src2	<= '0;
		end
		else begin
			R_Index_Src2	<= Index_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
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
			if ( We_Valid_Dst ) begin
				R_Indeces.instr.dst.v	<= 1'b1;
				R_Indeces.instr.dst.idx	<= R_Index_Dst;
			end
			else begin
				R_Indeces.instr.dst.v	<= 1'b0;
			end

			if ( We_Valid_Src1 ) begin
				R_Indeces.instr.src1.v	<= 1'b1;
				R_Indeces.instr.src1.idx<= R_Index_Src1;
			end
			else begin
				R_Indeces.instr.src1.v	<= 1'b0;
			end

			if ( We_Valid_Src2 ) begin
				R_Indeces.instr.src2.v	<= 1'b1;
				R_Indeces.instr.src2.idx<= R_Index_Src2;
			end
			else begin
				R_Indeces.instr.src2.v	<= 1'b0;
			end

			if ( We_Valid_Src3 ) begin
				R_Indeces.instr.src3.v	<= 1'b1;
				R_Indeces.instr.src3.idx<= R_Index_Src3;
			end
			else begin
				R_Indeces.instr.src3.v	<= 1'b0;
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
			for ( int i=0; i<NUM_ENTRY_HAZARD; ++i ) begin
				TabHazard[ i ]			<= '0;
			end
		end
		else if ( I_Commit_Req | I_Req_Issue ) begin
			if ( I_Commit_Req ) begin
				TabHazard[ I_Commit_No ].instr.dst.v	<= 1'b0;
				TabHazard[ I_Commit_No ].instr.src1.v	<= 1'b0;
				TabHazard[ I_Commit_No ].instr.src2.v	<= 1'b0;
				TabHazard[ I_Commit_No ].instr.src3.v	<= 1'b0;
			end

			if ( I_Req_Issue ) begin
				TabHazard[ WNo ].instr	<= I_Instr;
			end
		end
	end


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY_HAZARD		)
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