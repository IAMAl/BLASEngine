///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ldst_unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module ldst_unit
	import	pkg_tpu::*;
#(
	parameter int DEPTH_BUFF		= 16,
	parameter int WIDTH_BUFF		= $clog2(DEPTH_BUFF),
	parameter int DEPTH_BUFF_LDST	= 8,
	parameter type TYPE				= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall
	input						I_Commit_Grant,			//Grant to Commit
	input						I_Access_Grant,			//Access-Grant
	input						I_Valid,				//Valid
	input	data_t				I_Data,					//Data
	output	data_t				O_Data,					//Data
	input						I_Term,					//End of Access
	input						I_Req,					//Access-Request
	input	address_t			I_Length,				//Access-Length
	input	address_t			I_Stride,				//Stride Factor
	input	address_t			I_Base,					//Base Address
	output						O_Req,					//Access-Request
	output	address_t			O_Length,				//Access-Length
	output	address_t			O_Stride,				//Stride Factor
	output	address_t			O_Base,					//Base Address
	input						I_Ready,				//Ready to Access
	input	TYPE				I_Token,				//Input Token
	output	TYPE				O_Token,				//Commit Request
	output						O_Stall					//Stall Request
);


	TYPE						Token;
	logic						Stall;
	logic						Term;

	logic						We;
	logic						Re;
	logic	[WIDTH_BUFF-1:0]	WPtr;
	logic	[WIDTH_BUFF-1:0]	RPtr;
	logic						Empty;
	logic						Full;

	logic						Run;

	logic						Ready;

	logic						Empty_Buff;
	logic						Full_Buff;
	logic	[WIDTH_BUFF:0]		Num;


	assign We					= ~I_Stall & I_Valid;
	assign Re					= ~I_Stall & I_Commit_Grant;
	assign Term					= ~I_Stall & Run & I_Term;

	assign O_Token				= ( Term ) ? Token : '0;

	assign O_Stall				= Full | ( Full_Buff & ( Run & ~Ready ) );


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run				<= 1'b0;
		end
		else if ( I_Term ) begin
			Run				<= 1'b0;
		end
		else if ( ~Empty & I_Access_Grant ) begin
			Run				<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Ready	<= 1'b0;
		end
		begin
			Ready	<= I_Ready;
		end
	end


	RingBuff #(
		.NUM_ENTRY(			DEPTH_BUFF					),
		.TYPE(				data_t						)
	) RingBuff_DMem
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.I_Data(			I_Data						),
		.O_Data(			O_Data						),
		.O_Full(			Full_Buff					),
		.O_Empty(			Empty_Buff					),
		.O_Num(				Num							)
	);


	token_pipe_ldst #(
		.DEPTH_BUFF(		DEPTH_BUFF_LDST			 	),
		.TYPE(				TYPE						)
	) token_pipe_ldst
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Stall(			I_Stall						),
		.I_Access_Grant(	I_Access_Grant				),
		.I_Req(				I_Req						),
		.I_Length(			I_Length					),
		.I_Stride(			I_Stride					),
		.I_Base(			I_Base						),
		.O_Req(				O_Req						),
		.O_Length(			O_Length					),
		.O_Stride(			O_Stride					),
		.O_Base(			O_Base						),
		.I_Token(			I_Token						),
		.O_Token(			Token						),
		.O_Full(			Full						),
		.O_Empty(			Empty						)
	);

endmodule