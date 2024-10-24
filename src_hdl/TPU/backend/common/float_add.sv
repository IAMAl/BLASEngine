///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	fAdd_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module fAdd_Unit
	import pkg_tpu::*;
#(
	parameter int DEPTH_PIPE	= 5,
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_En,					//Enable to Execute
	input						I_Stall,				//Stall Request
	input   data_t				I_Data1,				//Source Operand
	input   data_t				I_Data2,				//Source Operand
	input	TYPE				I_Token,				//Command
	output  					O_Valid,				//Output Valid
	output  data_t				O_Data,					//Output Data
	output	TYPE				O_Token					//Command
);


	localparam int	WIDTH_PIPE	= $clog2(DEPTH_PIPE);


	logic						is_Sub;

	logic						Valid;
	data_t						Data;
	index_t						Token;
	data_t						ResultData;

	logic						We;
	logic						Re;
	logic	[WIDTH_PIPE-1:0]	WPtr;
	logic	[WIDTH_PIPE-1:0]	RPtr;
	logic						Full;
	logic						Empty;

	logic						Stall;

	data_t						PipeData		[DEPTH_PIPE-1:0];
	index_t						PipeToken		[DEPTH_PIPE-1:0];


	assign is_Sub				= I_Token.op.OpCode[0];
	assign ResultData			= ( is_Sub ) ? I_Data1 - I_Data2 : I_Data1 + I_Data2;

	assign Valid				= I_En;
	assign Data					= ( I_En ) ? ResultData : 0;
	assign Token				= ( I_En ) ? I_Token	: '0;


	assign We					= I_En & ~Full & ~Stall;
	assign Re					= ~Empty & ~I_Stall;


	assign O_Valid				= Re;
	assign O_Data				= PipeData[ RPtr ];
	assign O_Token				= PipeToken[ RPtr ];


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
			PipeToken[ WPtr ]	<= Token;
			PipeData[ WPtr ]	<= Data;
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