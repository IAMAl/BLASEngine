///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	token_pipe_ldst
///////////////////////////////////////////////////////////////////////////////////////////////////

module token_pipe_ldst
	import	pkg_tpu::*;
#(
	parameter int DEPTH_BUFF	= 8,
	parameter int WIDTH_BUFF	= $clog2(DEPTH_BUFF),
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall
	input						I_Access_Grant,			//Access-Grant
	input						I_Req,					//Access-Request
	input	address_t			I_Length,				//Access-Length
	input	address_t			I_Stride,				//Stride Factor
	input	address_t			I_Base,					//Base Address
	output						O_Req,					//Access-Request
	output	address_t			O_Length,				//Access-Length
	output	address_t			O_Stride,				//Stride Factor
	output	address_t			O_Base,					//Base Address
	input	TYPE				I_Token,				//Input Token
	output	TYPE				O_Token,				//Output Token
	output						O_Stall,				//Stall Request
	output						O_Empty,				//Flag: Empty in Buffer
	output						O_Full					//Flag: Full in Buffer
);


	address_t					BuffLength		[DEPTH_BUFF-1:0];
	address_t					BuffStride		[DEPTH_BUFF-1:0];
	address_t					BuffBase		[DEPTH_BUFF-1:0];

	TYPE						BuffToken		[DEPTH_BUFF-1:0];


	logic						We;
	logic						Re;
	logic	[WIDTH_BUFF-1:0]	WPtr;
	logic	[WIDTH_BUFF-1:0]	RPtr;
	logic						Full;
	logic						Empty;
	logic	[WIDTH_BUFF:0]		Num;


	assign O_Req				= ~Empty & ~I_Stall;
	assign O_Length				= BuffLength[ RPtr ];
	assign O_Stride				= BuffStride[ RPtr ];
	assign O_Base				= BuffBase[ RPtr ];

	assign O_Token				= BuffToken[ RPtr ];
	assign O_Stall				= Full;
	assign O_Full				= Full;
	assign O_Empty				= Empty;


	assign We					= ~Full & I_Req;
	assign Re					= ~Empty & I_Access_Grant;


	always_ff @( posedge clock ) begin
		if ( We ) begin
			BuffToken[ WPtr ]	<= I_Token;
			BuffLength[ WPtr ]	<= I_Length;
			BuffStride[ WPtr ]	<= I_Stride;
			BuffBase[ WPtr ]	<= I_Base;
		end
	end


	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_BUFF					)
	) RingBuffCTRL_DMem
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.O_WAddr(			WPtr						),
		.O_RAddr(			RPtr						),
		.O_Full(			Full						),
		.O_Empty(			Empty						),
		.O_Num(				Num							)
	);

endmodule