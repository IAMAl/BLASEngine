///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	MA_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module MA_Unit
	import pkg_tpu::*;
#(
	parameter int DEPTH_MLT		= 3,
	parameter int DEPTH_ADD		= 1,
	parameter type TYPE			= pipe_exe_tmp_t,
	parameter int INT_UNIT		= 1
)(
	input						clock,
	input						reset,
	input						I_En,					//Enable to Execute
	input						I_Stall,				//Stall Request
	input						I_Grant,				//Grant for End of Exec
	input	issue_no_t			I_Pres_Issue_No,		//Current Issue No
	input   data_t				I_Data1,				//Source Data
	input   data_t				I_Data2,				//Source Data
	input   data_t				I_Data3,				//Source Data
	input	TYPE				I_Token,				//Command
	output  data_t				O_Valid,				//Output Valid
	output  data_t				O_Data,					//Output Data
	input						I_Re_p0,				//Read-Enable for Pipeline Register
	input						I_Re_p1,				//Read-Enable for Pipeline Register
	output	data_t				O_Data0,				//Data from Pipeline Register
	output	data_t				O_Data1,				//Data from Pipeline Register
	output	TYPE				O_Token,				//Command
	output						O_Stall					//Stall Request
);


	localparam int WIDTH_BUFF	= $clog2(DEPTH_MLT);

	logic						En_Add;
	logic						En_Mlt;


	data_t						Data1_Add;
	data_t						Data2_Add;
	data_t						Data1_Mlt;
	data_t						Data2_Mlt;

	TYPE						Token_Add;
	TYPE						Token_Mlt;


	data_t						Add_Data;
	data_t						Mlt_Data;

	TYPE						Add_Token;
	TYPE						Mlt_Token;


	logic						Chain_Mlt;
	logic						Chain_Add;


	issue_no_t					LifeAdd;
	issue_no_t					LifeMlt;



	logic						LiFeAdd;
	logic						LiFeMlt;
	issue_no_t					Add_Issue_No;
	issue_no_t					Mlt_Issue_No;


	logic						We;
	logic						Re;
	logic	[WIDTH_BUFF-1:0]	Wno;
	logic	[WIDTH_BUFF-1:0]	Rno;
	logic						Full;
	logic						Empty;

	data_t						Buff_Src3	[DEPTH_MLT-1:0];


	assign Add_Isssue_No		= Add_Token.issue_no;
	assign Mlt_Isssue_No		= Mlt_Token.issue_no;
	assign LiFeAdd				= I_Pres_Issue_No - Add_Issue_No;
	assign LiFeMlt				= I_Pres_Issue_No - Mlt_Issue_No;

	assign En_Add				= is_Adder | is_MAC | is_MAD;
	assign En_Mlt				= is_Mlter;


	assign O_Valid				= ( LifeAdd > LifeMlt ) ?	Add_Valid :
															Mlt_Valid;

	assign O_Data				= ( LifeAdd > LifeMlt ) ?	Add_Data :
															Mlt_Data;

	assign O_Token				= ( LifeAdd > LifeMlt ) ?	Add_Token :
															Mlt_Token;


	assign O_Data0				= ( I_Re_p0 ) ? Mlt_Data : '0;
	assign O_Data1				= ( I_Re_p1 ) ? Add_Data : '0;


	assign is_Adder				= I_En & ( I_Token.op.OpClass == 2'b00 );
	assign is_Mlter				= I_En & ( I_Token.op.OpClass == 2'b01 );

	assign is_MAC				= ( I_Token.op.OpClass == 2'b01 ) & ( I_Token.op.OpCode == 2'b10 );
	assign is_MAD				= ( I_Token.op.OpClass == 2'b01 ) & ( I_Token.op.OpCode == 2'b11 );


	assign Token_Add			= ( is_Adder ) ?	I_Token :
									( is_MAD ) ?	Mlt_Token :
									( is_MAC ) ?	Mlt_Token :
													'0;

	assign Token_Mlt			= ( is_Mlter ) ?	I_Token :
									( is_MAD ) ?	I_Token :
									( is_MAC ) ?	I_Token :
													'0;

	assign Data1_Add			= ( is_Adder ) ?	I_Data1 :
									( is_MAD ) ?	Mlt_Data :
									( is_MAC ) ?	Mlt_Data :
													0;

	assign Data2_Add			= ( is_Adder ) ?	I_Data2 :
									( is_MAD ) ?	Data3 :
									( is_MAC ) ?	Data3 :
													0;

	assign Data1_Mlt			= ( is_Mlter ) ?	I_Data1 :
									( is_MAD ) ?	I_Data1 :
									( is_MAC ) ?	I_Data1 :
													0;

	assign Data2_Mlt			= ( is_Mlter ) ?	I_Data2 :
									( is_MAD ) ?	I_Data2 :
									( is_MAC ) ?	I_Data2 :
													0;


	assign We					= I_Token.v & ( is_MAD | is_MAC );
	assign Re					= ~Empty & ( Chain_Mlt | Chain_Add );

	assign Data3				= Buff_Src3[ RNo ];


	always_ff @( posedge clock ) begin
		if ( We ) begin
			Buff_Src3[ WNo ]	<= I_Data3;
		end
	end

	`ifdef INT_UNit
		iAdd_Unit Add_Unit
		(
			.I_En(				En_Add					),
			.I_Data1(			Data1_Add				),
			.I_Data2(			Data2_Add				),
			.I_Token(			Token_Add				),
			.O_Valid(			Add_Valid				),
			.O_Data(			Add_Data				),
			.O_Token(			Add_Token				)
		);


		iMlt_Unit Mlt_Unit
		(
			.I_En(				En_Mlt					),
			.I_Data1(			Data1_Mlt				),
			.I_Data2(			Data2_Mlt				),
			.I_Token(			Token_Mlt				),
			.O_Valid(			Mlt_Valid				),
			.O_Data(			Mlt_Data				),
			.O_Token(			Mlt_Token				),
		);
	`else
		fAdd_Unit #(
			.DEPTH_PIPE(		DEPTH_ADD				)
		) Add_Unit
		(
			.I_En(				En_Add					),
			.I_Data1(			Data1_Add				),
			.I_Data2(			Data2_Add				),
			.I_Token(			Token_Add				),
			.O_Valid(			Add_Valid				),
			.O_Data(			Add_Data				),
			.O_Token(			Add_Token				)
		);


		fMlt_Unit #(
			.DEPTH_PIPE(		DEPTH_MLT				)
		) Mlt_Unit
		(
			.I_En(				En_Mlt					),
			.I_Data1(			Data1_Mlt				),
			.I_Data2(			Data2_Mlt				),
			.I_Token(			Token_Mlt				),
			.O_Valid(			Mlt_Valid				),
			.O_Data(			Mlt_Data				),
			.O_Token(			Mlt_Token				)
		);
	`endif


	token_pipe_ma #(
		.DEPTH_MLT(			DEPTH_MLT				),
		.DEPTH_ADD(			DEPTH_ADD				),
		.TYPE(				TYPE					)
	) token_pipe_ma
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_Grant(			I_Grant					),
		.I_Issue_No(		I_Pres_Issue_No			),
		.I_Token(			I_Token					),
		.O_Token(			O_Token					),
		.O_Chain_Mlt(		Chain_Mlt				),
		.O_Chain_Add(		Chain_Add				),
		.O_Stall(			O_Stall					)
	);


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_MLT				)
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