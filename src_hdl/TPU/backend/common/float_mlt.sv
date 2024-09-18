///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	fMlt_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module fMlt_Unit
	import pkg_tpu::*;
#(
	parameter int DEPTH_PIPE	= 7
)(
	input						I_En,
	input						I_Stall,
	input   opt_t 				I_Op,
	input   float				I_Data1,
	input   float				I_Data2,
	input	index_t				I_Index,
	input   issue_no_t			I_Issue_No,
	output  data_t				O_Valid,
	output  data_t				O_Data,
	output	index_t				O_Index,
	output  issue_no_t			O_Issue_No
);


	localparam int	WIDTH_PIPE	= $clog2(DEPTH_PIPE);

	logic						Valid;
	data_t						Data;
	index_t						Index;
	issue_no_t					Issue_No;
	float						ResultData;

	logic						We;
	logic						Re;
	logic	[WIDTH_PIPE-1:0]	WPtr;
	logic	[WIDTH_PIPE-1:0]	RPtr;
	logic						Full;
	logic						Empty;

	logic						Stall;

	data_t						PipeData		[DEPTH_PIPE-1:0];
	index_t						PipeIndex		[DEPTH_PIPE-1:0];
	issue_no_t					PipeIssueNo		[DEPTH_PIPE-1:0];


	assign ResultData			= I_Data1 * I_Data2;

	assign Valid				= I_En;
	assign Data					= ( I_En ) ? ResultData : 0;
	assign Index				= ( I_En ) ? I_Index	: '0;
	assign Issue_No				= ( I_En ) ? I_Issue_No : '0:


	assign We					= I_En & ~Full & ~Stall;
	assign Re					= ~Empty & ~I_Stall;


	assign O_Valid				= Re;
	assign O_Data				= PipeData[ RPtr ];
	assign O_Index				= PipeIndex[ RPtr ];
	assign O_Issue_No			= PipeIssueNo[ RPtr ];


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Stall			<= 1'b0;
		end
		else begin
			Stall			<= I_Stall;
		end
	end

	always_ff @( posedge clock ) begin
		if ( We ) begin
			PipeIndex[ WPtr ]	<= Index;
			PipeData[ WPtr ]	<= Data;
			PipeIssueNo[ WPtr ]	<= Issue_No;
		end
	end

	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_PIPE					)
	) RingBuffCTRL
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.O_WAddr(			WPtr						),
		.O_RAddr(			RPtr						),
		.O_Full(			Full						),
		.O_Empty(			Empty						),
		.O_Num(											)
	);

endmodule