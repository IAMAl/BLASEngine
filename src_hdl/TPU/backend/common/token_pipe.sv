///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	StatusCtrl
///////////////////////////////////////////////////////////////////////////////////////////////////

module token_pipe
	import	pkg_tpu::*;
#(
	parameter int DEPTH_MLT		= 7,
	parameter int DEPTH_ADD		= 5,
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall
	input	issue_no_t			I_Issue_No,				//Current Issue No
	input	op_t				I_Op,					//OpCode
	output	op_t				O_Op,					//OpCode
	input	TYPE				I_Token,				//Input Token
	output	TYPE				O_Token,				//Output Token
	output						O_Stall					//Stall Request
);


	localparam int WIDTH_MLT	= $clog2(DEPTH_MLT);
	localparam int WIDTH_ADD	= $clog2(DEPTH_ADD);

	logic						We_Mlt;
	logic						Re_Mlt;
	logic	[WIDTH_MLT-1:0]		WPtr_Mlt;
	logic	[WIDTH_MLT-1:0]		RPtr_Mlt;
	logic						Full_Mlt;
	logic						Empty_Mlt;
	logic	[WIDTH_MLT:0]		Num_Mlt;

	logic						We_Add;
	logic						Re_Add;
	logic	[WIDTH_ADD-1:0]		WPtr_Add;
	logic	[WIDTH_ADD-1:0]		RPtr_Add;
	logic						Full_Add;
	logic						Empty_Add;
	logic	[WIDTH_ADD:0]		Num_Add;


	issue_no_t					LifeMlt;
	issue_no_t					LifeAdd;
	logic						is_Mlt_Old;


	logic						SelOut;


	TYPE						Token;
	op_t						Op;

	op_t						OBuffMlt		[DEPTH_MLT-1:0];
	op_t						OBuffAdd		[DEPTH_ADD-1:0];

	TYPE						TBuffMlt		[DEPTH_MLT-1:0];
	TYPE						TBuffAdd		[DEPTH_ADD-1:0];


	assign Valid				= I_Token.v & ( I_Op.OpType == 2'b00 );

	assign Token				= ( TBuffMlt[ RPtr_Mlt ].v & ( OBuffMlt[ RPtr_Mlt ].OpCode == 2'b11 ) ) ?	TBuffMlt[ RPtr_Mlt ] :
									( TBuffAdd[ RPtr_Add ].v & ( OBuffAdd[ RPtr_Add ].OpCode == 2'b10 ) ) ?	TBuffAdd[ RPtr_Add ] :
																											I_Token;

	assign Op					= ( TBuffMlt[ RPtr_Mlt ].v & ( OBuffMlt[ RPtr_Mlt ].OpCode == 2'b11 ) ) ?	OBuffMlt[ RPtr_Mlt ] :
									( TBuffAdd[ RPtr_Add ].v & ( OBuffAdd[ RPtr_Add ].OpCode == 2'b10 ) ) ?	OBuffAdd[ RPtr_Add ] :
																											I_Op;


	assign LifeMlt				= I_Issue_No - TBuffMlt[ RPtr_Mlt ].issue_no;
	assign LifeAdd				= I_Issue_No - TBuffAdd[ RPtr_Add ].issue_no;
	assign is_Mlt_Old			= LifeMlt > LifeAdd;
	assign SelOut				= is_Mlt_Old & ~&OBuffMlt[ RPtr_Mlt ].OpCode;


	assign O_Token				= (    SelOut & TBuffMlt[ RPtr_Mlt ].v ) ?	TBuffMlt[ RPtr_Mlt ] :
									( ~SelOut & TBuffAdd[ RPtr_Add ].v ) ?	TBuffAdd[ RPtr_Add ] :
																			'0;

	assign O_Op					= (    SelOut & OBuffMlt[ RPtr_Mlt ].v ) ?	OBuffMlt[ RPtr_Mlt ] :
									( ~SelOut & OBuffAdd[ RPtr_Add ].v ) ?	OBuffAdd[ RPtr_Add ] :
																			'0;

	assign O_Stall				= Full_Mlt | Full_Add;


	assign We_Mlt				= ~Full_Mlt & ( ( Valid & ( I_Op.OpClass == 2'b01 ) ) | ( TBuffMlt[ RPtr_Mlt ].v & ( OBuffMlt[ RPtr_Mlt ].OpCode == 2'b11 ) ) );
	assign Re_Mlt				= ~Empty & ~I_Stall & TBuffMlt[ RPtr_Mlt ].v;

	assign We_Add				= ~Full_Add & ( ( Valid & ( I_Op.OpClass == 2'b00 ) ) | ( TBuffAdd[ RPtr_Add ].v & ( OBuffAdd[ RPtr_Add ].OpCode == 2'b10 ) ) );
	assign Re_Add				= ~Empty & ~I_Stall & TBuffAdd[ RPtr_Add ].v;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<DEPTH_MLT; ++i ) begin
				TBuffMlt[ i ]			<= '0;
				OBuffMlt[ i ]			<= '0;
			end
			else if ( We_Mlt | Re_Mlt ) begin
				if ( We_Mlt ) begin
					TBuffMlt[ WPtr_Mlt ]	<= Token;
					OBuffMlt[ WPtr_Mlt ]	<= Op;
				end

				if ( Re_Mlt ) begin
					TBuffMlt[ RPtr_Mlt ].v	<= 1'b0;
				end
			end
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<DEPTH_MLT; ++i ) begin
				TBuffAdd[ i ]			<= '0;
			end
			else if ( We_Add | Re_Add ) begin
				if ( We_Add ) begin
					TBuffAdd[ WPtr_Add ]	<= Token;
					OBuffAdd[ WPtr_Add ]	<= Op;
				end

				if ( Re_Add ) begin
					TBuffAdd[ RPtr_Add ].v	<= 1'b0;
				end
			end
		end
	end


	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_MLT					),
	) RingBuffCTRL_Mlt
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We_Mlt						),
		.I_Re(				Re_Mlt						),
		.O_WAddr(			WPtr_Mlt					),
		.O_RAddr(			RPtr_Mlt					),
		.O_Full(			Full_Mlt					),
		.O_Empty(			Empty_Mlt					),
		.O_Num(				Num_Mlt						)
	);

	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_ADD					),
	) RingBuffCTRL_Add
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We_Add						),
		.I_Re(				Re_Add						),
		.O_WAddr(			WPtr_Add					),
		.O_RAddr(			RPtr_Add					),
		.O_Full(			Full_Add					),
		.O_Empty(			Empty_Add					),
		.O_Num(				Num_Add						)
	);
\

endmodule