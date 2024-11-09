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
	input	pipe_exe_t			I_Command,				//Command
	input						I_Commit_Grant,			//Grant for Commit
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
	input						I_Re_p0,				//REad-Enable for Pipeline Register
	input						I_Re_p1,				//REad-Enable for Pipeline Register
	output	TYPE				O_WB_Token_LdSt1,		//Write-Back Info
	output	TYPE				O_WB_Token_LdSt2,		//Write-Back Info
	output	TYPE				O_WB_Token_Math,		//Write-Back Info
	output	TYPE				O_WB_Token_Mv,			//Write-Back Info
	output	data_t				O_WB_Data_LdSt1,		//Write-Back Data
	output	data_t				O_WB_Data_LdSt2,		//Write-Back Data
	output	data_t				O_WB_Data_Math,			//Write-Back Data
	output	data_t				O_WB_Data_Mv,			//Write-Back Data
	output						O_LdSt_Done1,			//Load/Store Done
	output						O_LdSt_Done2,			//Load/Store Done
	output						O_Math_Done,			//Execution Done
	output						O_Mv_Done,				//Reg Move Done
	output						O_Ld_Stall,				//Stall Request for Loading
	output						O_St_Stall				//Stall Request for Storing
);



	issue_no_t					Issue_No;

	logic						MAU_Req;
	TYPE						MAU_Token;
	data_t						MAU_Data;
	logic						Valid_MAU;

	TYPE						Token_MAU;
	TYPE						Token_Mv;

	logic						LdSt_Req		[1:0];
	data_t						Ld_Data			[1:0];
	TYPE						Ld_Token		[1:0];


	logic						Ld_Stall_Odd;
	logic						Ld_Stall_Evn;

	logic						St_Stall_Odd;
	logic						St_Stall_Evn;


	logic						is_Adder;
	logic						is_Mlter;


	logic						We;
	logic						Re;
	TYPE						Mv_Token;
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


	assign Issue_No				= I_Command.command.issue_no;


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

	// Composing Inpu-Token for Floating-Point Unit
	assign is_Adder				= I_En & ( I_Command.command.instr.op.OpClass == 2'b00 );
	assign is_Mlter				= I_En & ( I_Command.command.instr.op.OpClass == 2'b01 );

	assign MAU_Token.v			= is_Adder | is_Mlter;
	assign MAU_Token.op.OpType	= I_Command.command.instr.op.OpType;
	assign MAU_Token.op.OpClass	= ( PMov0 ) ?	2'b01 :
									( PMov1 ) ?	2'b00 :
												I_Command.command.instr.op.OpClass;
	assign MAU_Token.op.OpCode	= ( PMov0 ) ?	2'b00 :
									( PMov1 ) ?	2'b00 :
												I_Command.command.instr.op.OpCode;
	assign MAU_Token.op.Sel_Unit= I_Command.command.instr.op.Sel_Unit;
	assign MAU_Token.dst		= I_Command.command.instr.dst;
	assign MAU_Token.slice_len	= I_Command.command.instr.slice_len;
	assign MAU_Token.path		= I_Command.command.instr.path;
	assign MAU_Token.mread		= I_Command.command.instr.mread;
	assign MAU_Token.issue_no	= I_Command.command.issue_no;

	assign Src_Data2_			= ( PMov0 ) ?	32'h78000000 :
									( PMov1 ) ? 32'h00000000 :
												Src_Data2;

	// Register Move Path
	assign PData				= ( CommonMov) ?	Src_Data1 :
									( PMov0 ) ?		Data0 :
									( PMov1 ) ?		Data1 :
													'0;

	// Request to ALU
	assign MAU_Req				= I_Command.v & ( I_Command.command.instr.op.OpType == 2'b00 );

	assign LdSt_Req[0]			= I_Command.v & ( I_Command.command.instr.op.OpType == 2'b11 ) & ~I_Command.command.instr.op.OpClass[0] & ( I_Command.command.instr.op.OpCode == 2'b10 );
	assign LdSt_Req[1]			= I_Command.v & ( I_Command.command.instr.op.OpType == 2'b11 ) &  I_Command.command.instr.op.OpClass[0] & ( I_Command.command.instr.op.OpCode == 2'b10 );

	// Write-Backs
	assign O_WB_Token_LdSt1		= Ld_Token[0];
	assign O_WB_Token_LdSt2		= Ld_Token[1];
	assign O_WB_Token_Math		= MAU_Token;
	assign O_WB_Token_Mv		= Mv_Token;

	assign O_WB_Data_LdSt1		= Ld_Data[0];
	assign O_WB_Data_LdSt2		= Ld_Data[1];
	assign O_WB_Data_Math		= MAU_Data;
	assign O_WB_Data_Mv			= Mv_Data;

	assign O_Mv_Done			= Mv_Token.v;

	// Stall by Load/Store Unit
	assign O_Ld_Stall			= Ld_Stall_Odd | Ld_Stall_Evn;
	assign O_St_Stall			= St_Stall_Odd | St_Stall_Evn;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Mv_Token		<= '0;
			Mv_Data			<= '0;
		end
		else begin
			Mv_Token		<= Token_Mv;
			Mv_Data			<= PData;
		end
	end


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
		.I_Data1(			Src_Data1				),
		.I_Data2(			Src_Data2_				),
		.I_Data3(			Src_Data3				),
		.I_Re_p0(			I_Re_p0					),
		.I_Re_p1(			I_Re_p1					),
		.I_Token(			MAU_Token				),
		.O_Valid(			Valid_MAU				),
		.O_Data(			MAU_Data				),
		.O_Data0(			Data0					),
		.O_Data1(			Data1					),
		.O_Token(			Token_MAU				)
	);


	LdStUnit LdStUnit_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			I_Stall					),
		.I_Commit_Grant(	I_Commit_Grant			),
		.I_Issue_No(		Issue_No				),
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
		.I_Issue_No(		Issue_No				),
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

endmodule