///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	IndexUnit
///////////////////////////////////////////////////////////////////////////////////////////////////

module IndexUnit
	import pkg_tpu::*;
	import pkg_mpu::*;
#(
	parameter int LANE_ID		= 0
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Force Stalling
	input						I_Req,					//Request from Hazard-Check Stage
	input						I_En_II,
	input						I_MaskedRead,			//Flag: Masked Access to Register File
	input	idx_t				I_Index,				//Index Value
	input	index_t				I_Window,				//Window for Slicing
	input	index_t				I_Length,				//Length for Slicing
	input	id_t				I_ThreadID,				//Thread-ID
	input	index_t				I_Constant,				//Constant
	input						I_Sign,					//Config: Sign
	input	mask_t				I_Mask_Data,			//Mask
	output	idx_t				O_Index,				//Index Value
	output						O_Done					//ENd of Slicing
);


	localparam int WIDTH_NLZ	= $clog2(NUM_ENTRY_NLZ_INDEX);


	index_t						Index;
	logic						En_Slice;
	logic						End_Count;

	logic						SkipReq;
	logic						SkipEnd;

	logic [1:0]					Sel_a;
	logic [1:0]					Sel_b;
	logic [1:0]					Sel_c;
	logic [1:0]					Sel_s;
	logic						Sel_Const;

	logic						sign;
	index_t						Index_a;
	index_t						Index_b;
	index_t						Index_c;
	index_t						Index_m;
	index_t						Index_s1;
	index_t						Index_s2;
	index_t						Index_val;

	logic						Next;
	index_t						OffsetVal;
	index_t						CountVal;

	logic	[WIDTH_NLZ-1:0]		Index_Offset;

	logic						R_Req;
	logic						R_Sel;
	index_t						R_Index;
	idx_t						R_Idx_Cfg;
	index_t						R_Base_Index;
	index_t						R_Length;
	index_t						R_Window;
	logic						R_MaskedRead;

	logic						Req_SkipOp;

	logic						En_II;
	logic						End_II;
	logic						Stop_II;


	assign Req_SkipOp			= R_MaskedRead | I_MaskedRead;

	assign Next					= R_Index == R_Window;

	assign En_II				= I_Req & I_En_II;

	//Parsing Selector Values
	assign Sel_a				= I_Index.sel[1:0];
	assign Sel_b				= I_Index.sel[3:2];
	assign Sel_c				= I_Index.sel[5:4];
	assign Sel_s				= I_Index.sel[6];

	//Enable Slicing
	assign En_Slice				= ( I_Req & I_Index.slice & ~Stop_II ) | ( R_Sel & ~I_Stall & ~Stop_II );

	//End of Slicing
	assign End_Count			= CountVal == R_Length;

	//Select Index Value
	assign Index				= ( Req_SkipOp ) ?				Index_Offset :
									( R_Sel ) ?					R_Index + OffsetVal + 1'b1 :
																I_Index.idx;

	//Sign: Subtraction
	assign sign					= I_Sign;

	//Index Calculation Operands
	assign Index_a				= ( Sel_a == INDEX_SIMT ) ?		I_ThreadID :
									( Sel_a == INDEX_CONST ) ? 	I_Constant :
									( Sel_a == INDEX_ORIG ) ?	Index :
																0;

	assign Index_b				= ( Sel_b == INDEX_LANE ) ?		LANE_ID :
									( Sel_b == INDEX_CONST ) ? 	I_Constant :
									( Sel_b == INDEX_ORIG ) ?	Index :
																0;

	assign Index_c				= ( Sel_c == INDEX_LANE ) ?		LANE_ID :
									( Sel_c == INDEX_CONST ) ? 	I_Constant :
									( Sel_c == INDEX_ORIG ) ?	Index :
																I_ThreadID;

	//Index Calculation
	assign Index_m				= Index_a * Index_b;
	assign Index_s1				= ( Sel_s ) ?					Index_m : Index_c;
	assign Index_s2				= ( Sel_s ) ?					Index_c : Index_m;
	assign Index_val			= ( sign ) ?					Index_s1 - Index_s2 :
																Index_s1 + Index_s2;

	//Output Actual Index
	assign O_Req				= R_Req | R_Sel | I_Req | SkipReq;
	assign O_Slice				= ( R_Req ) ? R_Sel :	I_Req & I_Index.slice;

	assign O_Index.v			= ( R_Req ) ? R_Idx_Cfg.v | SkipReq | R_Sel :	I_Index.v & I_Req;
	assign O_Index.slice		= ( R_Req ) ? R_Idx_Cfg.slice :					I_Index.slice;
	assign O_Index.sel			= ( R_Req ) ? R_Idx_Cfg.sel :					I_Index.sel;
	assign O_Index.no			= ( R_Req ) ? R_Idx_Cfg.no :					I_Index.no;
	assign O_Index.window		= ( R_Req ) ? R_Idx_Cfg.v :						I_Index.window;
	assign O_Index.src_sel		= ( R_Req ) ? R_Idx_Cfg.v :						I_Index.src_sel;
	assign O_Index.idx			= ( R_Req ) ? R_Index :							I_Index.idx;


	assign O_Done				= End_Count;

	assign End_II				= End_Count;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req			<= 1'b0;
		end
		else if ( SkipEnd ) begin
			R_Req			<= 1'b0;
		end
		else if ( I_Index.slice ) begin
			R_Req			<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_MaskedRead	<= 1'b0;
		end
		else if ( SkipEnd ) begin
			R_MaskedRead	<= 1'b0;
		end
		else if ( I_Req & I_Index.slice & ~I_Stall ) begin
			R_MaskedRead	<= I_MaskedRead;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Sel			<= 1'b0;
		end
		else if ( End_Count ) begin
			R_Sel			<= 1'b0;
		end
		else if ( I_Req & I_Index.slice & ~I_Stall ) begin
			R_Sel			<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Index			<= 0;
		end
		else if ( R_Sel & ~I_Stall ) begin
			R_Index			<= Index_val;
		end
		else if ( I_Req & ~I_Stall ) begin
			R_Index			<= I_Index.idx;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Idx_Cfg			<= 0;
		end
		else if ( I_Req & ~I_Stall ) begin
			R_Idx_Cfg			<= I_Index;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Base_Index	<= 0;
		end
		else if ( I_Req & ~I_Stall & I_Index.slice ) begin
			R_Base_Index	<= I_Index;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length		<= 0;
		end
		else if ( I_Req & ~I_Stall & I_Index.slice ) begin
			R_Length		<= I_Length;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Window		<= 0;
		end
		else if ( I_Req & ~I_Stall & I_Index.slice ) begin
			R_Window		<= I_Window;
		end
	end


	Counter WindowCount (
		.clock(				clock					),
		.reset(				reset					),
		.I_Clr(				En_Slice & Next			),
		.I_En(				En_Slice				),
		.O_Val(				OffsetVal				)
	);


	Counter SliceVal (
		.clock(				clock					),
		.reset(				reset					),
		.I_Clr(				End_Count				),
		.I_En(				En_Slice				),
		.O_Val(				CountVal				)
	);


	SkipCTRL #(
		.NUM_ENTRY_NLZ_INDEX(	NUM_ENTRY_NLZ_INDEX	)
	) SkipCTRL
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_SkipOp				),
		.I_Stall(			I_Stall					),
		.I_Mask_Data(		I_Mask_Data				),
		.I_Index_Start(		I_Index					),
		.I_Index_Length(	I_Length				),
		.O_Req(				SkipReq					),
		.O_Index_Offset(	Index_Offset			),
		.O_End(				SkipEnd)
	);

	IICtrl #(
		.LANE_ID(			LANE_ID					)
	) IICtrl
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_En_II(			En_II					),
		.I_Clr_II(			End_II					),
		.O_Stall(			Stop_II					)
	);

endmodule