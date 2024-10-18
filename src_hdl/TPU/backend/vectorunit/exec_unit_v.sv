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
	input						I_En,
	input						I_Stall,				//Stall
	input						I_Req,					//Request from Network Stage
	input	issue_no_t			I_Issue_No,				//Current Issue No
	input	command_t			I_Command,				//Command
	input	data_t				I_Src_Data1,			//Source Data
	input	data_t				I_Src_Data2,			//Source Data
	input	data_t				I_Src_Data3,			//Source Data
	output	ldst_t				O_LdSt1,				//Load/Store Command
	output	ldst_t				O_LdSt2,				//Load/Store Command
	input	data_t				I_Ld_Data1,				//Loaded Data
	input	data_t				I_Ld_Data2,				//Loaded Data
	output	data_t				O_St_Data1,				//Storing Data
	output	data_t				O_St_Data2,				//Storing Data
	input	[1:0]				I_Ld_Ready,				//Ready to Load
	input	[1:0]				I_Ld_Grant,				//Grant for Loading
	input	[1:0]				I_St_Ready,				//Ready to Store
	input	[1:0]				I_St_Grant,				//Grant for Storing
	input						I_End_Access1,			//End of Access
	input						I_End_Access2,			//End of Access
	input						I_Re_p0,
	input						I_Re_p1,
	output	TYPE				O_WB_Token,				//Write-Back Info
	output	data_t				O_WB_Data,				//Write-Back Data
	output						O_Math_Done,			//Execution Done ToDO
	output						O_LdSt_Done1,			//Load/Store Done
	output						O_LdSt_Done2,			//Load/Store Done
	output						O_Lane_En
);


	logic						MAU_Req;
	TYPE						MAU_Token;
	data_t						MAU_Data;
	issue_no_t					MAU_IssueNo;
	logic						Valid_MAU;

	TYPE						Token_MAU;

	logic						LdSt_Req		[1:0];
	data_t						Ld_Data			[1:0];
	TYPE						Ld_Token		[1:0];

	issue_no_t					LifeMAU;
	issue_no_t					LifeLdSt1;
	issue_no_t					LifeLdSt2;
	issue_no_t					LifeLdSt;
	issue_no_t					LifeMv;

	logic						is_LifeMAU;
	logic						is_LifeLdSt2;


	logic						We;
	logic						Re;
	data_t						Mv_Data;

	logic						RegMoveOp;
	logic						CommonMov;
	logic						PMov;
	logic						PMov0;
	logic						PMov1;

	data_t						Src_Data2;

	data_t						PData;
	data_t						Data0;
	data_t						Data1;

	assign RegMoveOp			= I_Req & ( I_Command.instr.op.OpType == 2'b00 ) & ( I_Command.instr.op.OpClass == 2'b11 );
	assign CommonMov			= RegMoveOp & ( I_Command.instr.op.OpCode == 2'b01 );
	assign PMov					= RegMoveOp & ( I_Command.instr.op.OpCode == 2'b10 ) & I_Command.instr.src1.v;
	assign PMov0				= PMov & ( I_Command.instr.src1.idx == '0 );
	assign PMov1				= PMov & ( I_Command.instr.src1.idx == '1 );

	assign is_Adder				= I_En & ( I_Token.op.OpClass == 2'b00 );
	assign is_Mlter				= I_En & ( I_Token.op.OpClass == 2'b01 );

	assign MAU_Token.v			= I_Command.v;
	assign MAU_Token.op.OPType	= I_Command.op.OPType;
	assign MAU_Token.op.OPClass	= ( PMov0 ) ?	2'b01 :
									( PMov1 ) ?	2'b00 :
												I_Command.op.OPClass;
	assign MAU_Token.op.OPCode	= ( PMov0 ) ?	2'b00 :
									( PMov1 ) ?	2'b00 :
												I_Command.op.OPCode;
	assign MAU_Token.dst		= I_Command.dst;
	assign MAU_Token.slice_len	= I_Command.slice_len;
	assign MAU_Token.issue_no	= I_Command.issue_no;
	assign MAU_Token.path		= I_Command.path;

	assign Src_Data2			= ( PMov0 ) ?	32'h78000000 :
									( PMov1 ) ? 32'h00000000 :
												I_Src_Data2;


	assign We					= RegMove & ( ( LifeMAU != '0 ) | ( LifeLdSt != '0 ) );
	assign Re					= ( LifeMv > LifeLdSt ) & ( LifeMv > LifeMAU );
	assign RegMove				= I_Req & ( I_Command.instr.op.OpType == 2'b00 ) &
										( I_Command.instr.op.OpClass == 2'b11 ) &
										( |I_Command.instr.op.OpCode );

	assign PData				= ( CommonMov) ?	I_Src_Data1 :
									( PMov0 ? )		Data0 :
									( PMov1 ? )		Data1 :
													'0 :

	assign MAU_Req				= I_Req & ( I_Command.instr.op.OpType == 2'b00 );

	assign LdSt_Req[0]			= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) &  ~I_Command.instr.op.OpClass[0];
	assign LdSt_Req[1]			= I_Req & ( I_Command.instr.op.OpType == 2'b11 ) &   I_Command.instr.op.OpClass[0];


	assign LifeMAU				= I_Issue_No - MAU_IssueNo;
	assign LifeLdSt1			= I_Issue_No - Ld_Token[0].issue_no;
	assign LifeLdSt2			= I_Issue_No - Ld_Token[0].issue_no;
	assign LifeMv				= I_Issue_No - Mv_Token.issue_no;


	assign is_LifeLdSt2			= LifeLdSt2 > LifeLdSt1;
	assign LifeLdSt				= ( is_LifeLdSt2 ) ? LifeLdSt2 : LifeLdSt1;

	assign is_LifeMAU			= LifeMAU > LifeLdSt;


	assign O_WB_Token			= ( Re ) ?				Mv_Token :
									( is_LifeMAU ) ?	Token_MAU :
									( is_LifeLdSt2 ) ?	Ld_Token[1] :
														Ld_Token[0];

	assign O_WB_Data			= ( Re ) ?				Mv_Data :
									( is_LifeMAU ) ?	MAU_Data :
									( is_LifeLdSt2 ) ?	Ld_Data[1] :
														Ld_Data[0];


	assign O_Lane_En			= 1'b1;//ToDo


	MA_Unit #(
		.DEPTH_MLT(			7						),
		.DEPTH_ADD(			5						),
		.TYPE(				TYPE					),
		.INT_UNIT(			0						)
	) fMA_Unit
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				I_En					),
		.I_Data1(			I_Src_Data1				),
		.I_Data2(			Src_Data2				),
		.I_Data3(			I_Src_Data3				),
		.I_Re_p0(			I_Re_p0					),
		.I_Re_p1(			I_Re_p1					),
		.I_Token(			MAU_Token				),
		.O_Valid(			Valid_MAU				),
		.O_Data(			Data_MAU				),
		.O_Data0(			Data0					),
		.O_Data1(			Data1					),
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
		.I_End_Access(		I_End_Access1			),
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
		.I_End_Access(		I_End_Access2			),
		.O_Token(			Ld_Token[0]				),
		.O_WB_Data(			Ld_Data[0]				),
		.O_LdSt_Done(		O_LdSt_Done1			)
	);


	RingBuff #(
		.NUM_ENTRY(			8						),
		.TYPE(				TYPE					)
	) RegMoveBuff (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.I_Data(			I_Command				),
		.O_Data(			Mv_Token				),
		.O_Full(									),
		.O_Empty(									),
		.O_Num(										)
	);

	RingBuff #(
		.NUM_ENTRY(			8						),
		.TYPE(				data_t					)
	) RegMoveBuff (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.I_Data(			PData					),
		.O_Data(			Mv_Data					),
		.O_Full(									),
		.O_Empty(									),
		.O_Num(										)
	);

endmodule