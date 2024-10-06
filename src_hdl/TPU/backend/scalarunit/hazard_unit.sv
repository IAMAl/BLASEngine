module HazardCheck_TPU
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Issue,			//Request from Previous Stage
	input						I_Req,					//Request to Work
	input						I_is_Vec,				//Request is for Vector Unit
	input						I_Sel_Unit,				//Select Scalr/Vector Unit
	input						I_Valid_Dst,			//Flag: Valid for Destination
	input						I_Valid_Src1,			//Flag: Valid for Source-1
	input						I_Valid_Src2,			//Flag: Valid for Source-2
	input						I_Valid_Src3,			//Flag: Valid for Source-3
	input	index_t				I_Index_Dst,			//Index for Destination
	input	index_t				I_Index_Src1,			//Index for Source-1
	input	index_t				I_Index_Src2,			//Index for Source-2
	input	index_t				I_Index_Src3,			//Index fpr Source-3
	input						I_Slice,				//Flaag: Index-Slicing
	input						I_Req_Commit,			//Request to Commit
	input	[WIDTH_BUFF-1:0]	I_Commit_No,			//Commit (Issued) No.
	output						O_Req_Issue,			//Request to Next Stage
	output						O_Issue_Instr,			//Issue(Dispatch) Instruction
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


	assign O_Req_Issue			= R_Req;
	assign O_Issue_Instr.v_dst			= TabHazard[ RNo ].v_dst;
	assign O_Issue_Instr.v_src1			= TabHazard[ RNo ].v_src1;
	assign O_Issue_Instr.v_src2			= TabHazard[ RNo ].v_src2;
	assign O_Issue_Instr.v_src3			= TabHazard[ RNo ].v_src3;
	assign O_Issue_Instr.v_src4			= TabHazard[ RNo ].v_src4;
	assign O_Issue_Instr.slice1			= TabHazard[ RNo ].slice1;
	assign O_Issue_Instr.slice2			= TabHazard[ RNo ].slice2;
	assign O_Issue_Instr.slice3			= TabHazard[ RNo ].slice3;
	assign O_Issue_Instr.slice_length	= TabHazard[ RNo ].slice_length;
	assign O_Issue_Instr.DstIdx			= TabHazard[ RNo ].DstIdx;
	assign O_Issue_Instr.SrcIdx1		= TabHazard[ RNo ].SrcIdx1;
	assign O_Issue_Instr.SrcIdx2		= TabHazard[ RNo ].SrcIdx2;
	assign O_Issue_Instr.SrcIdx3		= TabHazard[ RNo ].SrcIdx3;
	assign O_Issue_Instr.Imm_Data		= TabHazard[ RNo ].Imm_Data;
	assign O_Issue_Instr.Issue_No		= RNo;

	assign O_RAR_Hazard			= R_RAR_Hazard;
	assign O_RAW_Hazard			= R_RAW_Hazard;
	assign O_WAR_Hazard			= R_WAR_Hazard;
	assign O_WAW_Hazard			= R_WAW_Hazard;


	//// Referenced at Commit Select Unit
	assign O_Rd_Ptr				= RNo;


	//// Forming Indeces for Mixing Scalar and Vector Units
	assign Index_Dst			= { I_is_Vec, I_Index_Dst };
	assign Index_Src1			= { I_is_Vec, I_Index_Src1 };
	assign Index_Src2			= { I_is_Vec, I_Index_Src2 };
	assign Index_Src3			= { I_is_Vec, I_Index_Src3 };


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
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			assign is_Matched_i_dst_i_dst[ i ]		= TabHazard[ i ].v_dst  & I_Index_Entry.v_dst  & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_dst );
			assign is_Matched_i_dst_i_src1[ i ]		= TabHazard[ i ].v_src1 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_dst );
			assign is_Matched_i_dst_i_src2[ i ]		= TabHazard[ i ].v_src2 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_dst );
			assign is_Matched_i_dst_i_src3[ i ]		= TabHazard[ i ].v_src3 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_dst );

			assign is_Matched_i_src1_i_dst[ i ]		= TabHazard[ i ].v_Dst  & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_src1 );
			assign is_Matched_i_src1_i_src1[ i ]	= TabHazard[ i ].v_src1 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_src1 ) & ( TabHazard[ i ].slice_length != 0 );
			assign is_Matched_i_src1_i_src2[ i ]	= TabHazard[ i ].v_src2 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_src1 ) & ( TabHazard[ i ].slice_length != 0 );
			assign is_Matched_i_src1_i_src3[ i ]	= TabHazard[ i ].v_src3 & I_Index_Entry.v_src1 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_src1 ) & ( TabHazard[ i ].slice_length != 0 );

			assign is_Matched_i_src2_i_dst[ i ]		= TabHazard[ i ].v_Dst  & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_src2 );
			assign is_Matched_i_src2_i_src1[ i ]	= TabHazard[ i ].v_src1 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_src2 ) & ( TabHazard[ i ].slice_length != 0 );
			assign is_Matched_i_src2_i_src2[ i ]	= TabHazard[ i ].v_src2 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_src2 ) & ( TabHazard[ i ].slice_length != 0 );
			assign is_Matched_i_src2_i_src3[ i ]	= TabHazard[ i ].v_src3 & I_Index_Entry.v_src2 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_src2 ) & ( TabHazard[ i ].slice_length != 0 );

			assign is_Matched_i_src3_i_dst[ i ]		= TabHazard[ i ].v_Dst  & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_dst  == I_Index_Entry.i_src3 );
			assign is_Matched_i_src3_i_src1[ i ]	= TabHazard[ i ].v_src1 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src1 == I_Index_Entry.i_src3 ) & ( TabHazard[ i ].slice_length != 0 );
			assign is_Matched_i_src3_i_src2[ i ]	= TabHazard[ i ].v_src2 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src2 == I_Index_Entry.i_src3 ) & ( TabHazard[ i ].slice_length != 0 );
			assign is_Matched_i_src3_i_src3[ i ]	= TabHazard[ i ].v_src3 & I_Index_Entry.v_src3 & ( TabHazard[ i ].i_src3 == I_Index_Entry.i_src3 ) & ( TabHazard[ i ].slice_length != 0 );
		end
	end

	assign RAR_Hazard			= I_Slice & ( RAR_Hazard_Src1 | RAR_Hazard_Src2 | RAR_Hazard_Src3 );


	//// Issueable Detection
	assign v_Issue				= I_Req_Issue & ~( RAW_Hazard_Src1 | RAW_Hazard_Src2 | RAW_Hazard_Src3 | WAR_Hazard_Src1 | WAR_Hazard_Src2 | WAR_Hazard_Src3 | WAW_Hazard );


	//// Buffer Control
	assign We					= I_Req_Issue & ~Full;
	assign Re					= Valud_Issue & ~Empty;


	//// Storing to Table
	//	 Taking Care of Stall
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Dst	<= 1'b0;
		end
		else begin
			We_Valid_Dst	<= I_Valid_Dst;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src1	<= 1'b0;
		end
		else begin
			We_Valid_Src1	<= I_Valid_Src1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src2	<= 1'b0;
		end
		else begin
			We_Valid_Src2	<= I_Valid_Src2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			We_Valid_Src3	<= 1'b0;
		end
		else begin
			We_Valid_Src3	<= I_Valid_Src3;
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
				TabHazard[ I_Commit_No ].v_Dst	<= 1'b0;
				TabHazard[ I_Commit_No ].v_src1	<= 1'b0;
				TabHazard[ I_Commit_No ].v_src2	<= 1'b0;
				TabHazard[ I_Commit_No ].v_src3	<= 1'b0;
			end

			if ( I_Req_Issue ) begin
				TabHazard[ WNo ] <= Index_Entry;
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