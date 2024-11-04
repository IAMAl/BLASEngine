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
	input						I_Req,					//Access-Request
	input						I_Commit_Grant,			//Grant to Commit
	input						I_Access_Grant,			//Access-Grant
	input						I_Valid,				//Valid for Data
	input	data_t				I_Data,					//Data
	output	data_t				O_Data,					//Data
	input						I_Term,					//End of Access
	input	address_t			I_Length,				//Access-Length
	input	stride_t			I_Stride,				//Stride Factor
	input	address_t			I_Base,					//Base Address
	output						O_Req,					//Access-Request
	output	address_t			O_Length,				//Access-Length
	output	stride_t			O_Stride,				//Stride Factor
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
	logic						Empty;
	logic						Full;

	logic						We_Data;
	logic						Re_Data;
	logic						Empty_Buff;
	logic						Full_Buff;


	logic						Run;
	logic						Ready;


	assign We					= ~I_Stall & I_Req & ~Full;
	assign Re					= ~I_Stall & I_Commit_Grant & ~Empty;

	assign We_Data				= ~I_Stall & Run & I_Valid & ~Full_Buff;
	assign Re_Data				= ~I_Stall & Run & ~Empty_Buff;

	assign Term					= ~I_Stall & Run & I_Term;

	assign O_Stall				= ( Full | Full_Buff ) & ( Run & ~Ready );


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


	//// Data Buffer
	RingBuff #(
		.NUM_ENTRY(			DEPTH_BUFF					),
		.TYPE(				data_t						)
	) RingBuff_DMem
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We_Data						),
		.I_Re(				Re_Data						),
		.I_Data(			I_Data						),
		.O_Data(			O_Data						),
		.O_Full(			Full_Buff					),
		.O_Empty(			Empty_Buff					),
		.O_Num(											)
	);


	//// Memory Access Configuration Buffers
	RingBuff #(
		.NUM_ENTRY(			DEPTH_BUFF_LDST				),
		.TYPE(				address_t					)
	) RingBuff_Length
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.I_Data(			I_Length					),
		.O_Data(			O_Length					),
		.O_Full(										),
		.O_Empty(										),
		.O_Num(											)
	);


	RingBuff #(
		.NUM_ENTRY(			DEPTH_BUFF_LDST				),
		.TYPE(				stride_t					)
	) RingBuff_Stride
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.I_Data(			I_Stride					),
		.O_Data(			O_Stride					),
		.O_Full(										),
		.O_Empty(										),
		.O_Num(											)
	);


	RingBuff #(
		.NUM_ENTRY(			DEPTH_BUFF_LDST				),
		.TYPE(				address_t					)
	) RingBuff_Base
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.I_Data(			I_Base						),
		.O_Data(			O_Base						),
		.O_Full(										),
		.O_Empty(										),
		.O_Num(											)
	);


	RingBuff #(
		.NUM_ENTRY(			DEPTH_BUFF_LDST				),
		.TYPE(				TYPE						)
	) RingBuff_Token
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Term						),
		.I_Data(			I_Token						),
		.O_Data(			O_Token						),
		.O_Full(			Full						),
		.O_Empty(			Empty						),
		.O_Num(											)
	);

endmodule