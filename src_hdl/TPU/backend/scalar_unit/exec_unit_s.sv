///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ExecUnit_S
///////////////////////////////////////////////////////////////////////////////////////////////////

module ExecUnit_S
	import pkg_tpu::*;
#(
	parameter type TYPE			= pipe_exe_tmp_t
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall
	input	pipe_exe_t			I_Command,				//Command
	input						I_Commit_Grant,			//Grant for Commit
	input	issue_no_t			I_Issue_No,				//Current Issue No
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
	input						I_Re_p0,				//Read-Enable for Pipeline Register
	input						I_Re_p1,				//Read-Enable for Pipeline Register
	output	TYPE				O_WB_Token,				//Write-Back Index
	output	data_t				O_WB_Data,				//Write-Back Data
	output						O_Math_Done,			//Execution Done
	output						O_LdSt_Done1,			//Load/Store Done
	output						O_LdSt_Done2,			//Load/Store Done
	output						O_Ld_Stall,				//Stall for Loading
	output						O_St_Stall				//Stall for Storing
);


	logic						ALU_Req;
	data_t						ALU_Data;
	TYPE						ALU_Token;
	TYPE						Token_Mv;

	logic						LdSt_Req		[1:0];
	data_t						Ld_Data			[1:0];
	TYPE						Ld_Token		[1:0];

	issue_no_t					LifeALU;
	issue_no_t					LifeLdSt1;
	issue_no_t					LifeLdSt2;
	issue_no_t					LifeLdSt;
	issue_no_t					LifeMv;

	logic						is_LifeALU;
	logic						is_LifeLdSt2;


	logic						Ld_Stall_Odd;
	logic						Ld_Stall_Evn;

	logic						St_Stall_Odd;
	logic						St_Stall_Evn;

	logic						We;
	logic						Re;
	TYPE						Mv_Token_;
	TYPE						Mv_Token;
	data_t						Mv_Data_;
	data_t						Mv_Data;


	logic						RegMoveOp;
	logic						CommonMov;
	logic						PMov;
	logic						PMov0;
	logic						PMov1;

	data_t						Src_Data2_;

	data_t						PData;
	data_t						Data0;
	data_t						Data1;

	logic						RegMove;

	data_t						Src_Data1;
	data_t						Src_Data2;
	data_t						Src_Data3;


	logic						Valid_iDIV;


	assign Token_Mv.v			= I_Command.v;
	assign Token_Mv.op			= I_Command.command.instr.op;
	assign Token_Mv.dst			= I_Command.command.instr.dst;
	assign Token_Mv.slice_len	= I_Command.command.instr.slice_len;
	assign Token_Mv.path		= I_Command.command.instr.path;
	assign Token_Mv.mread		= I_Command.command.instr.mread;
	assign Token_Mv.issue_no	= I_Command.command.issue_no;


	assign Src_Data1			= I_Command.data1;
	assign Src_Data2			= I_Command.data2;
	assign Src_Data3			= I_Command.data3;

	assign RegMoveOp			= I_Command.v & ( I_Command.command.instr.op.OpType == 2'b00 ) & ( I_Command.command.instr.op.OpClass == 2'b11 );
	assign CommonMov			= RegMoveOp & ( I_Command.command.instr.op.OpCode == 2'b01 );
	assign PMov					= RegMoveOp & ( I_Command.command.instr.op.OpCode == 2'b10 ) & I_Command.command.instr.src1.v;
	assign PMov0				= PMov & ( I_Command.command.instr.src1.idx == '0 );
	assign PMov1				= PMov & ( I_Command.command.instr.src1.idx == '1 );

	assign Src_Data2_			= ( PMov0 ) ?	32'h78000000 :
									( PMov1 ) ? 32'h00000000 :
												Src_Data2;


	assign We					= RegMove & ( ( LifeALU != '0 ) | ( LifeLdSt != '0 ) );
	assign Re					= ( LifeMv > LifeLdSt ) & ( LifeMv > LifeALU );
	assign RegMove				=I_Command.v& ( I_Command.command.instr.op.OpType == 2'b00 ) &
										( I_Command.command.instr.op.OpClass == 2'b11 ) &
										( |I_Command.command.instr.op.OpCode );

	assign PData				= ( CommonMov) ?	Src_Data1 :
									( PMov0 ) ?		Data0 :
									( PMov1 ) ?		Data1 :
													'0;

	assign ALU_Req				= I_Command.v & ( I_Command.command.instr.op.OpType == 2'b00 );

	assign LdSt_Req[0]			= I_Command.v & ( I_Command.command.instr.op.OpType == 2'b11 ) &  ~I_Command.command.instr.op.OpClass[0];
	assign LdSt_Req[1]			= I_Command.v & ( I_Command.command.instr.op.OpType == 2'b11 ) &   I_Command.command.instr.op.OpClass[0];


	assign LifeALU				= I_Issue_No - ALU_Token.issue_no;
	assign LifeLdSt1			= I_Issue_No - Ld_Token[0].issue_no;
	assign LifeLdSt2			= I_Issue_No - Ld_Token[0].issue_no;
	assign LifeMv				= I_Issue_No - Mv_Token.issue_no;

	assign is_LifeLdSt2			= LifeLdSt2 > LifeLdSt1;
	assign LifeLdSt				= ( is_LifeLdSt2 ) ? LifeLdSt2 : LifeLdSt1;

	assign is_LifeALU			= LifeALU > LifeLdSt;


	assign O_WB_Token			= ( Re ) ?				Mv_Token :
									( is_LifeALU ) ?	ALU_Token :
									( is_LifeLdSt2 ) ?	Ld_Token[1] :
														Ld_Token[0];

	assign O_WB_Data			= ( Re ) ?				Mv_Data :
									( is_LifeALU ) ?	ALU_Data :
									( is_LifeLdSt2 ) ?	Ld_Data[1] :
														Ld_Data[0];


	assign O_Ld_Stall			= Ld_Stall_Odd | Ld_Stall_Evn;
	assign O_St_Stall			= St_Stall_Odd | St_Stall_Evn;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Mv_Token		<= '0;
			Mv_Data			<= '0;
		end
		else begin
			Mv_Token		<= Mv_Token_;
			Mv_Data			<= Mv_Data_;
		end
	end


	ALU #(
		.TYPE(				TYPE					)
	) IALU
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Issue_No(		I_Issue_No				),
		.I_Stall(			I_Stall					),
		.I_Req(				ALU_Req					),
		.I_Command(			I_Command.command		),
		.I_Src_Data1(		Src_Data1				),
		.I_Src_Data2(		Src_Data2_				),
		.I_Src_Data3(		Src_Data3				),
		.I_Re_p0(			I_Re_p0					),
		.I_Re_p1(			I_Re_p1					),
		.O_WB_Token(		ALU_Token				),
		.O_WB_Data(			ALU_Data				),
		.O_ALU_Done(		O_Math_Done				)
	);


	LdStUnit LdStUnit_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_Commit_Grant(	I_Commit_Grant			),
		.I_Issue_No(		I_Issue_No				),
		.I_Req(				LdSt_Req[1]				),
		.I_Command(			I_Command.command		),
		.I_Src_Data1(		Src_Data1				),
		.I_Src_Data2(		Src_Data2				),
		.I_Src_Data3(		Src_Data3				),
		.O_LdSt(			O_LdSt2					),
		.I_Ld_Data(			I_Ld_Data2				),
		.O_St_Data(			O_St_Data2				),
		.I_Ld_Ready(		I_Ld_Ready[1]			),
		.I_Ld_Grant(		I_Ld_Grant[1]			),
		.I_St_Ready(		I_St_Ready[1]			),
		.I_St_Grant(		I_St_Grant[1]			),
		.I_End_Access(		I_End_Access2			),
		.O_WB_Token(		Ld_Token[1]				),
		.O_WB_Data(			Ld_Data[1]				),
		.O_Ld_Stall(		Ld_Stall_Odd			),
		.O_St_Stall(		St_Stall_Odd			),
		.O_LdSt_Done(		O_LdSt_Done2			)
	);


	LdStUnit LdStUnit_Evn (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_Commit_Grant(	I_Commit_Grant			),
		.I_Issue_No(		I_Issue_No				),
		.I_Req(				LdSt_Req[0]				),
		.I_Command(			I_Command.command		),
		.I_Src_Data1(		Src_Data1				),
		.I_Src_Data2(		Src_Data2				),
		.I_Src_Data3(		Src_Data3				),
		.O_LdSt(			O_LdSt1					),
		.I_Ld_Data(			I_Ld_Data1				),
		.O_St_Data(			O_St_Data1				),
		.I_Ld_Ready(		I_Ld_Ready[0]			),
		.I_Ld_Grant(		I_Ld_Grant[0]			),
		.I_St_Ready(		I_St_Ready[0]			),
		.I_St_Grant(		I_St_Grant[0]			),
		.I_End_Access(		I_End_Access1			),
		.O_WB_Token(		Ld_Token[0]				),
		.O_WB_Data(			Ld_Data[0]				),
		.O_Ld_Stall(		Ld_Stall_Evn			),
		.O_St_Stall(		St_Stall_Evn			),
		.O_LdSt_Done(		O_LdSt_Done1			)
	);


	RingBuff #(
		.NUM_ENTRY(			8						),
		.TYPE(				TYPE					)
	) RegMoveTokenBuff (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.I_Data(			Token_Mv				),
		.O_Data(			Mv_Token_				),
		.O_Full(									),
		.O_Empty(									),
		.O_Num(										)
	);

	RingBuff #(
		.NUM_ENTRY(			8						),
		.TYPE(				data_t					)
	) RegMoveDataBuff
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.I_Data(			PData					),
		.O_Data(			Mv_Data_				),
		.O_Full(									),
		.O_Empty(									),
		.O_Num(										)
	);

endmodule