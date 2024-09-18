///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	iMA_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module iMA_Unit
	import pkg_tpu::*;
#(
	parameter type TYPE			= pipe_exe_tmp_t
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


	assign is_Add				= ( I_En & ( I_Op.OpClass == 2'b00 ) ) | is_Chain_to_Add;
	assign is_Mlt				= ( I_En & ( I_Op.OpClass == 2'b01 ) );

	//assign LiFeAdd				= I_Pres_Issue_No - Add_Issue_No;
	//assign LiFeMlt				= I_Pres_Issue_No - Mlt_Issue_No;

	//assign is_Chain_to_Mlt		= ( I_Op.OpCode == 2'b10 ) & is_Mlt;
	//assign is_Chain_to_Add		= ( I_Op.OpCode == 2'b11 ) & is_Mlt;

	assign En_Add				= is_Add;
	assign En_Mlt				= is_Mlt;


	assign O_Valid				= ( LifeAdd > LifeMlt ) ?	Add_Valid :
															Mlt_Valid;

	assign O_Data				= ( LifeAdd > LifeMlt ) ?	Add_Data :
															Mlt_Data;

	assign O_Index				= ( LifeAdd > LifeMlt ) ?	Add_Index :
															Mlt_Index;

	assign O_Issue_No			= ( LifeAdd > LifeMlt ) ?	Add_Issue_No :
															Mlt_Issue_No;


	always_comb begin
		case ()
		2'h0: begin
			assign Data1_Add	= ;//
			assign Data2_Add	= ;//
			assign Data1_Mlt	= ;//
			assign Data2_Mlt	= ;//
		end
		endcase
	end


	Add_Unit Add_Unit
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

	Mlt_Unit Mlt_Unit
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

	token_pipe_ma #(
		.DEPTH_MLT(			3						),
		.DEPTH_ADD(			1						),
		.TYPE(				pipe_exe_tmp_t			)
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