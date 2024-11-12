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
	parameter int DEPTH_PIPE	= 7,
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

	logic						Valid;
	data_t						Data;
	TYPE						Token;
	data_t						ResultData;

	logic						We;
	logic						Re;
	logic	[WIDTH_PIPE-1:0]	WPtr;
	logic	[WIDTH_PIPE-1:0]	RPtr;
	logic						Full;
	logic						Empty;

	logic						Stall;

	data_t						PipeData		[DEPTH_PIPE-1:0];
	TYPE						PipeToken		[DEPTH_PIPE-1:0];


	assign ResultData			= I_Data1 * I_Data2;

	assign Valid				= I_En;
	assign Data					= ( I_En ) ? ResultData : '0;
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
		if ( reset) begin
			for ( int i=0; i<DEPTH_PIPE; ++i ) begin
				PipeToken[ i ]	<= '0;
				PipeData[ i ]	<= '0;
			end
		end
		else if ( We ) begin
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