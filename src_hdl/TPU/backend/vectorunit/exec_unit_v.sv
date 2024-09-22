///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ExecUnit_V
///////////////////////////////////////////////////////////////////////////////////////////////////

module ExecUnit_V
	import pkg_tpu::*;
#(
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_Lane_En,//ToDo
	input						I_Stall,
	input						I_Req,
	input	issue_no_t			I_Issue_No,
	input	command_t			I_Command,
	input						I_Src_Data1,
	input						I_Src_Data2,
	input						I_Src_Data3,
	output						O_LdSt1,
	output						O_LdSt2,
	input	data_t				I_Ld_Data1,
	input	data_t				I_Ld_Data2,
	output	data_t				O_St_Data1,
	output	data_t				O_St_Data2,
	input						I_Ld_Ready,
	input						I_Ld_Grant,
	input						I_St_Ready,
	input						I_St_Grant,
	output	index_t				O_WB_Dst,
	output	data_t				O_WB_Data,
	output	issue_no_t			O_WB_IssueNo,
	output						O_Math_Done,
	output						O_LdSt_Done1,
	output						O_LdSt_Done2,
	output						O_Cond,
	output						O_Lane_En
);


	logic						MAU_Req;
	TYPE						MAU_Token;
	data_t						MAU_Data;
	issue_no_t					MAU_IssueNo;
	logic						Valid_MAU;

	logic						LdSt_Req		[1:0];
	data_t						Ld_Data			[1:0];
	TYPE						Ld_Token		[1:0];

	issue_no_t					LifeMAU;
	issue_no_t					LifeLdSt1;
	issue_no_t					LifeLdSt2;
	issue_no_t					LifeLdSt;

	logic						is_LifeMAU;
	logic						is_LifeLdSt2;


	assign MAU_Req				= I_Req & ( I_Command.instr.op.OpType == 2'b00 );

	assign LdSt_Req[0]			= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) &  ~I_Command.instr.op.OpClass[0];
	assign LdSt_Req[1]			= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) &   I_Command.instr.op.OpClass[0];


	assign LifeMAU				= I_Issue_No - MAU_IssueNo;
	assign LifeLdSt1			= I_Issue_No - Ld_Token[0].issue_no;
	assign LifeLdSt2			= I_Issue_No - Ld_Token[0].issue_no;

	assign is_LifeLdSt2			= LifeLdSt2 > LifeLdSt1;
	assign LifeLdSt				= ( is_LifeLdSt2 ) ? LifeLdSt2 : LifeLdSt1;

	assign is_LifeMAU			= LifeMAU > LifeLdSt;


	assign O_Dst				= ( is_LifeMAU ) ?		Token_MAU.dst :
									( is_LifeLdSt2 ) ?	Ld_Token[1].dst :
														Ld_Token[0].dst;

	assign O_WB_Data			= ( is_LifeMAU ) ?		MAU_Data :
									( is_LifeLdSt2 ) ?	Ld_Data[1] :
														Ld_Data[0];

	assign O_WB_IssueNo			= ( is_LifeMAU ) ?		MAU_IssueNo :
									( is_LifeLdSt2 ) ?	Ld_Token[1] :
														Ld_Token[0];


	MA_Unit #(
		.DEPTH_MLT(			7						),
		.DEPTH_ADD(			5						),
		.TYPE(				TYPE					),
		.INT_UNit(			false					)
	) fMA_Unit
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				En_MAU					),
		.I_OP(				I_Command.instr.op		),
		.I_Data1(			I_Src_Data1				),
		.I_Data2(			I_Src_Data2				),
		.I_Data3(			I_Src_Data3				),
		.I_Token(			MA_Token				),
		.I_Issue_No(		I_Command.issue_no		),
		.O_Valid(			Valid_MAU				),
		.O_Data1(			Data_MAU				),
		.O_Issue_No(		Issue_No_MAU			),
		.O_Token(			Token_MAU				)
	);

	LdStUnit LdStUnit_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_Commit_Grant(	I_Issue_No				),
		.I_Req(				LdSt_Req[1]				),
		.I_Command(			I_Command				),
		.I_Src_Data1(		I_Src_Data1				),
		.I_Src_Data2(		I_Src_Data2				),
		.I_Src_Data3(		I_Src_Data3				),
		.O_LdSt(			O_LdSt2					),
		.I_Ld_Data(			I_Ld_Data2				),
		.O_St_Data(			O_St_Data2				),
		.I_Ld_Ready(		I_Ld_Ready[1]			),
		.I_Ld_Grant(		I_Ld_Grant[1]			),
		.I_St_Ready(		I_St_Ready[1]			),
		.I_St_Grant(		I_St_Grant[1]			),
		.I_End_Access(		),//ToDo
		.O_Token(			Ld_Token[1]				),
		.O_WB_Data(			Ld_Data[1]				),
		.O_LdSt_Done(		O_LdSt_Done2			)
	);

	LdStUnit LdStUnit_Evn (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_Commit_Grant(	I_Issue_No				),
		.I_Req(				LdSt_Req[0]				),
		.I_Command(			I_Command				),
		.I_Src_Data1(		I_Src_Data1				),
		.I_Src_Data2(		I_Src_Data2				),
		.I_Src_Data3(		I_Src_Data3				),
		.O_LdSt(			O_LdSt1					),
		.I_Ld_Data(			I_Ld_Data1				),
		.O_St_Data(			O_St_Data1				),
		.I_Ld_Ready(		I_Ld_Ready[0]			),
		.I_Ld_Grant(		I_Ld_Grant[0]			),
		.I_St_Ready(		I_St_Ready[0]			),
		.I_St_Grant(		I_St_Grant[0]			),
		.I_End_Access(		),//ToDo
		.O_Token(			Ld_Token[0]				),
		.O_WB_Data(			Ld_Data[0]				),
		.O_LdSt_Done(		O_LdSt_Done1			)
	);

endmodule