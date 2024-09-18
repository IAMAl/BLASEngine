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
	paramter bool INT_UNit		= true
)(
	input						I_En,
	input						I_Stall,
	input						I_Grant,
	input   opt_t 				I_Op,
	input	issue_no_t			I_Pres_Issue_No,
	input   data_t				I_Data1,
	input   data_t				I_Data2,
	input   data_t				I_Data3,
	input	TYPE				I_Token,
	input   issue_no_t			I_Issue_No,
	output  data_t				O_Valid,
	output  data_t				O_Data,
	output	TYPE				O_Token,
	output  issue_no_t			O_Issue_No,
	output						O_Stall
);


	logic						En_Add;
	logic						En_Mlt;

	op_t						Op_Add;
	op_t						Op_Mlt;

	op_t						Op;

	data_t						Data1_Add;
	data_t						Data2_Add;
	data_t						Data1_Mlt;
	data_t						Data2_Mlt;

	index_t						Index_Add;
	index_t						Index_Mlt;

	issue_no_t					Issue_No_Add;
	issue_no_t					Issue_No_Mlt;


	data_t						Add_Data;
	data_t						Mlt_Data;

	index_t						Add_Index;
	index_t						Mlt_Index;

	issue_no_t					Add_Issue_No;
	issue_no_t					Mlt_Issue_No;


	logic						Chain_Mlt;
	logic						Chain_Add;


	issue_no_t					LifeAdd;
	issue_no_t					LifeMlt;


	assign LiFeAdd				= I_Pres_Issue_No - Add_Issue_No;
	assign LiFeMlt				= I_Pres_Issue_No - Mlt_Issue_No;

	assign En_Add				= is_Adder | is_MAC | is_MAD;
	assign En_Mlt				= is_Mlter;


	assign O_Valid				= ( LifeAdd > LifeMlt ) ?	Add_Valid :
															Mlt_Valid;

	assign O_Data				= ( LifeAdd > LifeMlt ) ?	Add_Data :
															Mlt_Data;

	assign O_Index				= ( LifeAdd > LifeMlt ) ?	Add_Index :
															Mlt_Index;

	assign O_Issue_No			= ( LifeAdd > LifeMlt ) ?	Add_Issue_No :
															Mlt_Issue_No;

	assign is_Adder				= I_En & ( I_Op.OpClass == 2'b00 );
	assign is_Mlter				= I_En & ( I_Op.OpClass == 2'b01 );

	assign is_MAC				= ( Op.OpClass == 2'b01 ) & ( Op.OpCode == 2'b10 );
	assign is_MAD				= ( Op.OpClass == 2'b01 ) & ( Op.OpCode == 2'b11 );


	assign Op_Add				= ( is_Adder ) ?	I_Op :
									( is_MAD ) ?	Op :
									( is_MAC ) ?	Op :
													'0;

	assign Op_Mlt				= ( is_Mlter ) ?	I_Op :
									( is_MAD ) ?	I_Op :
									( is_MAC ) ?	I_Op :
													'0;

	assign Index_Add			= ( is_Adder ) ?	I_Index :
									( is_MAD ) ?	Mlt_Index :
									( is_MAC ) ?	Mlt_Index :
													'0;

	assign Index_Mlt			= ( is_Mlter ) ?	I_Index :
									( is_MAD ) ?	I_Index :
									( is_MAC ) ?	I_Index :
													'0;

	assign Issue_No_Add			= ( is_Adder ) ?	I_Issue_No :
									( is_MAD ) ?	Mlt_Issue_No :
									( is_MAC ) ?	Mlt_Issue_No :
													0;

	assign Issue_No_Mlt			= ( is_Mlter ) ?	I_Issue_No :
									( is_MAD ) ?	I_Issue_No :
									( is_MAC ) ?	I_Issue_No :
													0;

	assign Data1_Add			= ( is_Adder ) ?	I_Data1 :
									( is_MAD ) ?	Mlt_Data :
									( is_MAC ) ?	Mlt_Data :
													0;

	assign Data2_Add			= ( is_Adder ) ?	I_Data2 :
									( is_MAD ) ?	I_Data3 :
									( is_MAC ) ?	C1 :
													0;

	assign Data1_Mlt			= ( is_Mlter ) ?	I_Data1 :
									( is_MAD ) ?	I_Data1 :
									( is_MAC ) ?	I_Data1 :
													0;

	assign Data2_Mlt			= ( is_Mlter ) ?	I_Data2 :
									( is_MAD ) ?	I_Data2 :
									( is_MAC ) ?	I_Data2 :
													0;


	`ifdef INT_UNit
		iAdd_Unit Add_Unit
		(
			.I_En(				En_Add					),
			.I_Op(				Op_Add					),
			.I_Data1(			Data1_Add				),
			.I_Data2(			Data2_Add				),
			.I_Index(			Index_Add				),
			.I_Issue_No(		Issue_No_Add			),
			.O_Valid(			Add_Valid				),
			.O_Data(			Add_Data				),
			.O_Index(			Add_Index				),
			.O_Issue_No(		Add_Issue_No			)
		);

		iMlt_Unit Mlt_Unit
		(
			.I_En(				En_Mlt					),
			.I_Op(				Op_Mlt					),
			.I_Data1(			Data1_Mlt				),
			.I_Data2(			Data2_Mlt				),
			.I_Index(			Index_Mlt				),
			.I_Issue_No(		Issue_No_Mlt			),
			.O_Valid(			Mlt_Valid				),
			.O_Data(			Mlt_Data				),
			.O_Index(			Mlt_Index				),
			.O_Issue_No(		Mlt_Issue_No			)
		);
	`else
		fAdd_Unit Add_Unit
		(
			.I_En(				En_Add					),
			.I_Op(				Op_Add					),
			.I_Data1(			Data1_Add				),
			.I_Data2(			Data2_Add				),
			.I_Index(			Index_Add				),
			.I_Issue_No(		Issue_No_Add			),
			.O_Valid(			Add_Valid				),
			.O_Data(			Add_Data				),
			.O_Index(			Add_Index				),
			.O_Issue_No(		Add_Issue_No			)
		);

		fMlt_Unit Mlt_Unit
		(
			.I_En(				En_Mlt					),
			.I_Op(				Op_Mlt					),
			.I_Data1(			Data1_Mlt				),
			.I_Data2(			Data2_Mlt				),
			.I_Index(			Index_Mlt				),
			.I_Issue_No(		Issue_No_Mlt			),
			.O_Valid(			Mlt_Valid				),
			.O_Data(			Mlt_Data				),
			.O_Index(			Mlt_Index				),
			.O_Issue_No(		Mlt_Issue_No			)
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
		.I_Issue_No(		I_Issue_No				),
		.I_Op(				I_Op					),
		.O_Op(				Op						),
		.I_Token(			I_Token					),
		.O_Token(			O_Token					),
		.O_Chain_Mlt(		Chain_Mlt				),
		.O_Chain_Add(		Chain_Add				),
		.O_Stall(			O_Stall					)
	);

endmodule