///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Scalar_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module Scalar_Unit
	import pkg_mpu::*;
	import pkg_tpu::*;
	import pkg_tpu::instr_t;
(
	input						clock,
	input						reset,
	input						I_En,					//Enable Execution
	input	id_t				I_ThreadID,				//Thread-ID
	output						O_Re_Instr,				//Read-Enable for Instruction Memory
	output	i_address_t			O_Rd_Address,			//Read Address for Instruction Memory
	input	instr_t				I_Instr,				//Instruction from Instruction Memory
	input						I_Commit_Req_V,			//Commit Request from CommitAgg
	input	issue_no_t			I_Commit_No_V,			//Commit No from CommitAgg
	output						O_Commit_Grant_V,		//Commit Grant to CommitAgg
	input	data_t				I_Scalar_Data,			//Scalar Data from Vector Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Vector Unit
	output	s_ldst_t			O_LdSt,					//Load Request
	input	s_ldst_data_t		I_Ld_Data,				//Loaded Data
	output	s_ldst_data_t		O_St_Data,				//Storing Data
	input	tb_t				I_Ld_Ready,				//Flag: Ready
	input	tb_t				I_Ld_Grant,				//Flag: Grant
	input	tb_t				I_St_Ready,				//Flag: Ready
	input	tb_t				I_St_Grant,				//Flag: Grant
	input	tb_t				I_End_Access,			//Flag: End of Access
	output	pipe_index_t		O_V_Command,			//Command to Vector Unit
	input	v_ready_t			I_V_State,				//Status from Vector Unit
	output	v_ready_t			O_Lane_En,				//Flag: Enable for Lanes in Vector Unit
	output	state_t				O_Status,				//Scalar Unit Status
	output						O_Term					//Flag: Termination
);


	localparam int	LANE_ID = 0;


	instr_t						Instr;


	logic						PAC_Req;
	data_t						PAC_Src_Data;
	logic 						PAC_We;
	logic 						PAC_Re;
	data_t						PAC_Data;


	logic						CondValid;


	logic						Instr_Jump;
	logic						Instr_Branch;


	logic						Stall_PCU;
	logic						Stall_IF;
	logic						Stall_IW_St;
	logic						Stall_IW_Ld;
	logic						Stall_IW;


	logic						Req_IFetch;


	logic						Req_IW;
	logic						Req_Issue;
	logic						IW_Req_Issue;
	issue_no_t					Issue_No;
	instruction_t				IW_Instr;

	logic						RAR_Hazard;
	logic						Branch_Instr;

	instr_t						S_Command;
	logic						is_Vec;


	index_t						Index_Length;
	logic						Index_En_II;
	logic						Index_MaskedRead;

	logic						Index_Req_Src1;
	idx_t						Index_Src1_;
	index_t						Index_Window_Src1;

	logic						Index_Req_Src2;
	idx_t						Index_Src2_;
	index_t						Index_Window_Src2;

	logic						Index_Req_Src3;
	idx_t						Index_Src3_;
	index_t						Index_Window_Src3;

	logic						RF_Index_Sel_Odd1;
	logic						RF_Index_Sel_Odd2;
	logic						RF_Index_Sel_Odd3;

	idx_t						Index_Src1;
	idx_t						Index_Src2;
	idx_t						Index_Src3;

	logic						Index_Src1_Busy;
	logic						Index_Src2_Busy;
	logic						Index_Src3_Busy;

	data_t						RF_Odd_Data1;
	data_t						RF_Odd_Data2;
	data_t						RF_Even_Data1;
	data_t						RF_Even_Data2;

	logic						RegMov_Wt;
	logic						RegMov_Rd;

	logic						Re_p0;
	logic						Re_p1;


	logic						Req_Index_Dst;
	logic						Dst_Slice;
	logic						Dst_Index_MRead;
	logic	[6:0]				Dst_Sel;
	idx_t						Dst_Index;
	index_t						Dst_Index_Window;
	index_t						Dst_Index_Length;
	idx_t						Dst_RegFile_Index;
	logic						Dst_Busy;
	logic						Dst_Done;

	logic						Aux_SWe;
	data_t						Scalar_Data;

	logic						MaskedRead;
	mask_t						Mask_Data;


	logic						Sign;
	logic						Sign1;
	logic						Sign2;
	logic						Sign3;
	const_t						Constant;


	logic						Bypass_Buff_Full;


	logic						is_WB_RF;
	logic						is_WB_BR;
	logic						is_WB_VU;
	logic						WB_En;
	pipe_exe_tmp_t				WB_Token;
	pipe_exe_tmp_t				WB_Token_LdSt1;
	pipe_exe_tmp_t				WB_Token_LdSt2;
	pipe_exe_tmp_t				WB_Token_Math;
	pipe_exe_tmp_t				WB_Token_Mv;
	data_t						WB_Data_LdSt1;
	data_t						WB_Data_LdSt2;
	data_t						WB_Data_Math;
	data_t						WB_Data_Mv;
	data_t						WB_Data_;
	logic						WB_We_Even;
	logic						WB_We_Odd;
	index_t						WB_Index_Even;
	index_t						WB_Index_Odd;
	data_t						WB_Data_Even;
	data_t						WB_Data_Odd;
	issue_no_t					WB_IssueNo;

	logic						LdSt_Done1;
	logic						LdSt_Done2;
	logic						Math_Done;
	logic						Mv_Done;

	logic						MaskReg_Ready;
	logic						MaskReg_Term;
	logic						MaskReg_We;
	logic						MaskReg_Re;


	logic	[12:0]				Config_Path;
	logic	[1:0]				Config_Path_WB;
	logic	[3:0]				Condition;
	logic	[1:0]				Cond_Data;


	logic						Ld_Stall;
	logic						St_Stall;


	logic						Stall_Index_Calc;
	logic						Stall_RegFile_Odd;
	logic						Stall_RegFile_Even;
	logic						Stall_Network;
	logic						Stall_ExecUnit;
	logic						Stall_RegFile_Dst;
	logic						Stall_WB;


	state_t						Status;


	logic						We_V_State;
	reg_idx_t					V_State_Data;
	data_t						V_State;


	logic						Store_S;
	logic						Store_V;


	logic						Slice;


	logic						Commmit_Req_LdSt1;
	logic						Commmit_Req_LdSt2;
	logic						Commmit_Req_Math;
	issue_no_t					Commit_No_LdSt1;
	issue_no_t					Commit_No_LdSt2;
	issue_no_t					Commit_No_Math;
	logic						Commit_Req;
	issue_no_t					Commit_No;
	logic						Commited_LdSt1;
	logic						Commited_LdSt2;
	logic						Commited_Math;
	logic						Commit_Grant_S;
	logic						Full_RB_S;
	logic						Empty_RB_S;


	logic						Lane_Enable;
	logic	[NUM_LANES-1:0]		Enable_Lanes;
	logic						Lane_We;
	logic						Lane_Re;
	data_t						Lane_Data;

	logic						Req_Even;
	logic						Req_Odd;

	logic						We_c;
	logic						Re_c;


	pipe_index_t				PipeReg_Idx;
	pipe_index_t				PipeReg_Index;
	pipe_index_reg_t			PipeReg_IdxRF;
	pipe_index_reg_t			PipeReg_IdxRR;
	pipe_reg_t					PipeReg_RR;
	pipe_net_t					PipeReg_Set_Net;
	pipe_net_t					PipeReg_RR_Net;
	pipe_exe_t					PipeReg_Net;
	pipe_exe_t					PipeReg_Exe;


	////
	assign PAC_Req				= 1;//I_En;


	//// Output Status
	assign O_Status				= Status;


	//// Select Scalar unit or Vector unit backend
	assign S_Command.v					=   ~Instr.instr.op.Sel_Unit & Req_Issue;
	assign S_Command.instr				= ( ~Instr.instr.op.Sel_Unit & Req_Issue ) ? Instr : '0;
	assign is_Vec						=   ~Instr.instr.op.Sel_Unit & Req_Issue;
	assign O_V_Command.v				=    Instr.instr.op.Sel_Unit & Req_Issue;
	assign O_V_Command.command.instr	= (  Instr.instr.op.Sel_Unit & Req_Issue ) ? Instr : '0;
	assign O_V_Command.command.issue_no	= (  Instr.instr.op.Sel_Unit & Req_Issue ) ? Issue_No : '0;


	//// Hazard Detect Stage
	//assign Req_IW				= ~Stall_IW_St;
	assign IW_Req_Issue			= ~Stall_IW_Ld & ~Stall_IW;


	//// Scalar unit's Back-end Pipeline
	assign PipeReg_Idx.v				= S_Command.v;

	//	Instruction
	assign PipeReg_Idx.command.instr	= S_Command.instr;

	// Issue-No
	assign PipeReg_Idx.command.issue_no	= Issue_No;

	// Mask Read
	assign MaskedRead					= S_Command.instr.mread;


	//// Index Update Stage
	//	Command
	assign PipeReg_Index.v			= PipeReg_Idx.v;
	assign PipeReg_Index.command	= PipeReg_Idx.command;

	// Masking
	assign Mask_Data				= '0;

	assign Index_Length				= PipeReg_Idx.command.instr.slice_len;
	assign Index_En_II				= PipeReg_Idx.command.instr.en_ii;
	assign Index_MaskedRead			= PipeReg_Idx.command.instr.mread;

	assign Index_Req_Src1			= PipeReg_Idx.command.instr.src1.v;
	assign Index_Src1_				= PipeReg_Idx.command.instr.src1;
	assign Index_Window_Src1		= PipeReg_Idx.command.instr.src1.window;

	assign Index_Req_Src2			= PipeReg_Idx.command.instr.src2.v;
	assign Index_Src2_				= PipeReg_Idx.command.instr.src2;
	assign Index_Window_Src2		= PipeReg_Idx.command.instr.src2.window;

	assign Index_Req_Src3			= PipeReg_Idx.command.instr.src3.v;
	assign Index_Src3_				= PipeReg_Idx.command.instr.src3;
	assign Index_Window_Src3		= PipeReg_Idx.command.instr.src3.window;


	assign RF_Index_Sel_Odd1		= PipeReg_Index.command.instr.src1.v;
	assign RF_Index_Sel_Odd2		= PipeReg_Index.command.instr.src2.v;
	assign RF_Index_Sel_Odd3		= PipeReg_Index.command.instr.src3.v;


	//// Packing for Register File Access
	//	Command
	assign PipeReg_IdxRF.v			= PipeReg_Index.v;
	assign PipeReg_IdxRF.command	= PipeReg_Index.command;

	assign Sign1					= PipeReg_Idx.command.instr.src1.s;
	assign Sign2					= PipeReg_Idx.command.instr.src2.s;
	assign Sign3					= PipeReg_Idx.command.instr.src3.s;
	assign Constant					= PipeReg_Idx.command.instr.imm;


	//// Register Read/Write Stage
	//	Command
	assign PipeReg_RR.v				= PipeReg_IdxRR.v;
	assign PipeReg_RR.command		= PipeReg_IdxRR.command;

	//	Capture Read Data
	//	Command
	assign PipeReg_Set_Net.v		= PipeReg_RR.v;
	assign PipeReg_Set_Net.command	= PipeReg_RR.command;

	assign PipeReg_Set_Net.data1	= ( RegMov_Rd ) ?							Scalar_Data :
										( PipeReg_RR.command.instr.src1.v ) ?	PipeReg_RR.data1 :
																				'0;

	assign PipeReg_Set_Net.data2	= ( PipeReg_RR.command.instr.src2.v ) ?		PipeReg_RR.data2 :
																				'0;

	assign PipeReg_Set_Net.data3	= ( PipeReg_RR.command.instr.src3.v ) ?		PipeReg_RR.data3 :
																				'0;

	//	Read-Enable
	assign Req_Even					= ( ( ~PipeReg_RR.command.instr.src1.src_sel.unit_no & PipeReg_RR.command.instr.src1.v ) |
										( ~PipeReg_RR.command.instr.src2.src_sel.unit_no & PipeReg_RR.command.instr.src2.v ) |
										( ~PipeReg_RR.command.instr.src3.src_sel.unit_no & PipeReg_RR.command.instr.src3.v ) ) & ~Re_c;
	assign Req_Odd					= ( (  PipeReg_RR.command.instr.src1.src_sel.unit_no & PipeReg_RR.command.instr.src1.v ) |
										(  PipeReg_RR.command.instr.src2.src_sel.unit_no & PipeReg_RR.command.instr.src2.v ) |
										(  PipeReg_RR.command.instr.src3.src_sel.unit_no & PipeReg_RR.command.instr.src3.v ) ) & ~Re_c;

	//	Read Data
	assign V_State_Data.v			= 1'b1;
	assign V_State_Data.idx			= '0;
	assign V_State_Data.data		= '0 | I_V_State;
	assign V_State_Data.src_sel		= '0;


	///// Write-Back to PAC
	assign PAC_We				= WB_Token.v & is_WB_BR;
	assign PAC_Data				= ( is_WB_BR ) ? WB_Data_ : '0;
	assign PAC_Re				= ( PipeReg_RR.command.instr.src1.src_sel.no == 2'h2 ) |
									( PipeReg_RR.command.instr.src2.src_sel.no == 2'h2 ) |
									( PipeReg_RR.command.instr.src3.src_sel.no == 2'h2 );


	//// Lane-Enable
	assign Lane_We				= is_WB_VU;
	assign Lane_Data			= ( is_WB_VU ) ? WB_Data_ : '0;
	assign Lane_Re				= ( PipeReg_RR.command.instr.src1.src_sel.no == 2'h3 ) |
									( PipeReg_RR.command.instr.src2.src_sel.no == 2'h3 ) |
									( PipeReg_RR.command.instr.src3.src_sel.no == 2'h3 );


	//// Nwtwork Stage
	assign Config_Path			= PipeReg_RR_Net.command.instr.path;

	//	Capture Data
	assign PipeReg_Net.v		= PipeReg_RR_Net.v;
	assign PipeReg_Net.command	= PipeReg_RR_Net.command;


	//// Write-Back
	assign WB_Token				= ( WB_Token_LdSt1.issue_no == Commit_No ) ?	WB_Token_LdSt1 :
									( WB_Token_LdSt2.issue_no == Commit_No ) ?	WB_Token_LdSt2 :
									( WB_Token_Math.issue_no == Commit_No ) ?	WB_Token_Math :
									( WB_Token_Mv.issue_no == Commit_No ) ?		WB_Token_Mv :
																				'0;

	//	Write-Back Target Decision
	assign is_WB_RF				= WB_Token.dst.dst_sel.no == 2'h1;
	assign is_WB_BR				= WB_Token.dst.dst_sel.no == 2'h2;
	assign is_WB_VU				= WB_Token.dst.dst_sel.no == 2'h3;

	//  Network Path
	assign Config_Path_WB		= WB_Token.path;

	assign Req_Index_Dst		= is_WB_RF & WB_Token.v;

	assign Dst_Sel				= WB_Token.dst.dst_sel.unit_no;
	assign Dst_Slice			= WB_Token.dst.slice;
	assign Dst_Index.v			= WB_Token.dst.v;
	assign Dst_Index.slice		= WB_Token.dst.slice;
	assign Dst_Index.idx		= WB_Token.dst.idx;
	assign Dst_Index.sel		= WB_Token.dst.sel;
	assign Dst_Index.src_sel	= WB_Token.dst.dst_sel;
	assign Dst_Index.window		= WB_Token.dst.window;
	assign Dst_Index.s			= WB_Token.dst.s;
	assign Dst_Index_Window		= WB_Token.dst.window;
	assign Dst_Index_Length		= WB_Token.dst.slice_len;
	assign Dst_Index_MRead		= WB_Token.mread;

	assign Sign					= WB_Token.dst.s;


	assign WB_We_Even			= ~Dst_Sel & WB_Token.v & is_WB_RF;
	assign WB_We_Odd			=  Dst_Sel & WB_Token.v & is_WB_RF;
	assign WB_Index_Even		= ( ~Dst_Sel ) ? Dst_RegFile_Index.idx :'0;
	assign WB_Index_Odd			= (  Dst_Sel ) ? Dst_RegFile_Index.idx :'0;
	assign WB_Data_Even			= ( ~Dst_Sel ) ? WB_Data_ : 			'0;
	assign WB_Data_Odd			= (  Dst_Sel ) ? WB_Data_ : 			'0;

	assign WB_IssueNo			= WB_Token.issue_no;

	assign Cond_Data			= WB_Token.op.OpCode;

	// Aux Data (Scalar Data)
	assign Aux_SWe				= WB_Token.v & is_WB_RF &
									( WB_Token.op.OpType == 2'b00 ) &
									( WB_Token.op.OpClass == 2'b11 ) &
									( WB_Token.op.OpCode == 2'b11 ) &
									WB_Token.dst.v &
									( WB_Token.dst.idx == 6'h00 );

	assign Instr_Branch			= WB_Token.v &
									( WB_Token.op.OpType == 2'b11 ) &
									( WB_Token.op.OpClass == 2'b10 ) &
									( WB_Token.op.OpCode == 2'b01 );

	assign Instr_Jump			= WB_Token.v &
									( WB_Token.op.OpType == 2'b11 ) &
									( WB_Token.op.OpClass == 2'b01 ) &
									( WB_Token.op.OpCode == 2'b01 );


	//// Reorder Buffer
	assign Store_S				= WB_Token.v;
	assign Store_V				= I_Commit_Req_V;

	assign We_c					= WB_Token.v &
									( WB_Token.op.OpType == 2'b00 ) &
									( WB_Token.op.OpClass == 2'b11 ) &
									( WB_Token.op.OpCode == 2'b11 );

	//	Write-Back to Cond Register
	assign WB_En				= WB_Token.v & is_WB_BR;
	assign MaskReg_Ready		= ( PipeReg_Idx.command.instr.op.OpType == 2'b01 ) &
									( PipeReg_Idx.command.instr.op.OpClass == 2'b10 ) &
									( PipeReg_Idx.command.instr.op.OpCode[1] == 1'b1 );
	assign MaskReg_Term			= Dst_Done;
	assign MaskReg_We			= WB_Token.v & is_WB_BR;
	assign MaskReg_Re			= (   PipeReg_RR.command.instr.src1.src_sel.no == 2'h2 ) |
									( PipeReg_RR.command.instr.src2.src_sel.no == 2'h2 ) |
									( PipeReg_RR.command.instr.src3.src_sel.no == 2'h2 );


	//// Reg Move
	assign RegMov_Rd			= ( PipeReg_Idx.command.instr.op.OpType == 2'b00 ) &
									( PipeReg_Idx.command.instr.op.OpClass == 2'b11 ) &
									( PipeReg_Idx.command.instr.op.OpCode == 2'b10 );

	assign RegMov_Wt			= ( PipeReg_Idx.command.instr.op.OpType == 2'b00 ) &
									( PipeReg_Idx.command.instr.op.OpClass == 2'b11 ) &
									( PipeReg_Idx.command.instr.op.OpCode == 2'b11 );


	//// Commit
	assign Commmit_Req_LdSt1	= WB_Token_LdSt1.v;
	assign Commmit_No_LdSt1		= WB_Token_LdSt1.issue_no;

	assign Commmit_Req_LdSt2	= WB_Token_LdSt2.v;
	assign Commmit_No_LdSt2		= WB_Token_LdSt2.issue_no;

	assign Commmit_Req_Math		= WB_Token_Math.v;
	assign Commmit_No_Math		= WB_Token_Math.issue_no;

	assign Commmit_Req_Mv		= WB_Token_Mv.v;
	assign Commmit_No_Mv		= WB_Token_Mv.issue_no;


	//// Write Vector Unit Status Register
	assign We_V_State			= I_En;


	//// Lane-Enable
	assign Enable_Lanes			= V_State[NUM_LANES*2-1:NUM_LANES];
	assign O_Lane_En			= Enable_Lanes;

	assign Lane_Enable			= I_En;


	//// End of Execution
	assign O_Term				= WB_Token.v &
									( WB_Token.op.OpType == 2'b01 ) &
									( WB_Token.op.OpClass == 2'b01 ) &
									( WB_Token.op.OpCode == 2'b11 );


	//// Stall Control
	assign Slice				= Index_Src1_Busy | Index_Src2_Busy | Index_Src3_Busy;
	assign Stall_PCU			= ~Lane_Enable;
	assign Stall_RegFile_Dst	= ~Lane_Enable | Stall_WB;
	assign Stall_RegFile_Odd	= ~Lane_Enable | Stall_Index_Calc;
	assign Stall_RegFile_Even	= ~Lane_Enable | Stall_Index_Calc;
	assign Stall_Network		= ~Lane_Enable;
	assign Stall_ExecUnit		= ~Lane_Enable;


	//// Instruction Fetch Stage
	IFetch IFetch (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IFetch & ~Stall_IF	),
		.I_Empty(			I_Empty					),
		.I_Term(			O_Term					),
		.I_Instr(			I_Instr					),
		.O_Req(				Req_IW					),
		.O_Instr(			IW_Instr				),
		.O_Re_Instr(		O_Re_Instr				)
	);


	//// Hazard Detect Stage
	HazardCheck_TPU HazardCheck_TPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IW & ~Stall_IW_St	),
		.I_Slice(			Dst_Slice				),
		.I_Req_Issue(		IW_Req_Issue			),
		.I_is_Vec(			is_Vec					),
		.I_Instr(			IW_Instr				),
		.I_Commit_Req(		Commit_Req				),
		.I_Commit_No(		Commit_No				),
		.O_Req_Issue(		Req_Issue				),
		.O_Instr(			Instr					),
		.O_RAR_Hazard(		RAR_Hazard				),
		.O_RAW_Hazard(								),
		.O_WAR_Hazard(								),
		.O_WAW_Hazard(								),
		.O_Rd_Ptr(			Issue_No				),
		.O_Branch(			Branch_Instr			)
	);


	//// Stall Control
	Stall_Ctrl Stall_Ctrl (
		.I_Hazard(			RAR_Hazard				),
		.I_Branch(			Branch_Instr			),
		.I_Slice(			Slice					),
		.I_Bypass_Buff_Full(Bypass_Buff_Full		),
		.I_Ld_Stall(		Ld_Stall				),
		.I_St_Stall(		St_Stall				),
		.O_Stall_IF(		Stall_IF				),
		.O_Stall_IW_St(		Stall_IW_St				),
		.O_Stall_IW_Ld(		Stall_IW_Ld				),
		.O_Stall_IW(		Stall_IW				),
		.O_Stall_Index(		Stall_Index_Calc		),
		.O_Stall_WB(		Stall_WB				)
	);


	//// Index Update Stage
	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index_Dst
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Dst		),
		.I_Req(				Req_Index_Dst			),
		.I_En_II(			'0						),
		.I_MaskedRead(		Dst_Index_MRead			),
		.I_Index(			Dst_Index				),
		.I_Window(			Dst_Index_Window		),
		.I_Length(			Dst_Index_Length		),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Dst_RegFile_Index		),
		.O_Busy(			Dst_Busy				),
		.O_Done(			Dst_Done				)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index1
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				Index_Req_Src1			),
		.I_En_II(			Index_En_II				),
		.I_MaskedRead(		Index_MaskedRead		),
		.I_Index(			Index_Src1_				),
		.I_Window(			Index_Window_Src1		),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign1					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src1				),
		.O_Busy(			Index_Src1_Busy			),
		.O_Done(									)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index2
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				Index_Req_Src2			),
		.I_En_II(			Index_En_II				),
		.I_MaskedRead(		Index_MaskedRead		),
		.I_Index(			Index_Src2_				),
		.I_Window(			Index_Window_Src2		),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign2					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src2				),
		.O_Busy(			Index_Src2_Busy			),
		.O_Done(									)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index3
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				Index_Req_Src3			),
		.I_En_II(			Index_En_II				),
		.I_MaskedRead(		Index_MaskedRead		),
		.I_Index(			Index_Src3_				),
		.I_Window(			Index_Window_Src3		),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign3					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src3				),
		.O_Busy(			Index_Src3_Busy			),
		.O_Done(									)
	);


	RF_Index_Sel RF_Index_Sel (
		.I_Odd1(			RF_Index_Sel_Odd1		),
		.I_Odd2(			RF_Index_Sel_Odd2		),
		.I_Odd3(			RF_Index_Sel_Odd3		),
		.I_Index_Src1(		Index_Src1				),
		.I_Index_Src2(		Index_Src2				),
		.I_Index_Src3(		Index_Src3				),
		.O_Index_Src1(		PipeReg_IdxRF.src1		),
		.O_Index_Src2(		PipeReg_IdxRF.src2		),
		.O_Index_Src3(		PipeReg_IdxRF.src3		),
		.O_Index_Src4(		PipeReg_IdxRF.src4		)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_IdxRR	<= '0;
		end
		else if ( I_En ) begin
			PipeReg_IdxRR	<= PipeReg_IdxRF;
		end
	end


	AuxRegs AuxRegs (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Re(				RegMov_Rd				),
		.I_We(				RegMov_Wt				),
		.I_Src_Command(		PipeReg_IdxRR			),
		.O_Re_p0(			Re_p0					),
		.O_Re_p1(			Re_p1					),
		.O_Re_c(			Re_c					),
		.I_Data(			WB_Data_				),
		.O_Data(			Scalar_Data				),
		.I_SWe(				Aux_SWe					),
		.I_Scalar_Data(		I_Scalar_Data			),
		.O_Scalar_Data(		O_Scalar_Data			)
	);


	logic	[2:0]			Sel;
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Sel				<= '0;
		end
		else begin
			Sel				<= { RF_Index_Sel_Odd3, RF_Index_Sel_Odd2, RF_Index_Sel_Odd1 };
		end
	end


	//// Register Read/Write Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_Odd					),
		.I_We(				WB_We_Odd				),
		.I_Index_Dst(		WB_Index_Odd			),
		.I_Data(			WB_Data_Odd				),
		.I_Index_Src1(		PipeReg_IdxRR.src1		),
		.I_Index_Src2(		PipeReg_IdxRR.src2		),
		.O_Data_Src1(		RF_Odd_Data1			),
		.O_Data_Src2(		RF_Odd_Data2			)
	);


	RegFile RegFile_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_Even				),
		.I_We(				WB_We_Even				),
		.I_Index_Dst(		WB_Index_Even			),
		.I_Data(			WB_Data_Even			),
		.I_Index_Src1(		PipeReg_IdxRR.src3		),
		.I_Index_Src2(		PipeReg_IdxRR.src4		),
		.O_Data_Src1(		RF_Even_Data1			),
		.O_Data_Src2(		RF_Even_Data2			)
	);


	RF_Data_Sel RF_Data_Sel (
		.I_Odd1(			Sel[0]					),
		.I_Odd2(			Sel[1]					),
		.I_Odd3(			Sel[2]					),
		.I_Data_Src1(		RF_Odd_Data1			),
		.I_Data_Src2(		RF_Odd_Data2			),
		.I_Data_Src3(		RF_Even_Data1			),
		.I_Data_Src4(		RF_Even_Data2			),
		.O_Data_Src1(		PipeReg_RR.data1		),
		.O_Data_Src2(		PipeReg_RR.data2		),
		.O_Data_Src3(		PipeReg_RR.data3		)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_RR_Net	<= '0;
		end
		else if ( I_En ) begin
			PipeReg_RR_Net	<= PipeReg_Set_Net;
		end
	end


	//// Status Register
	StatusCtrl StatusCtrl (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_En					),
		.I_Diff_Data(		WB_Data					),
		.O_Status(			Status					)
	);


	//// Condition Register
	CondReg CondReg (
		.clock(				clock					),
		.reset(				reset					),
		.I_Ready(			MaskReg_Ready			),
		.I_Term(			MaskReg_Term			),
		.I_We(				MaskReg_We				),
		.I_Status(			Status					),
		.I_Re(				MaskReg_Re				),
		.O_Cond(			Condition				)
	);


	//// Lane Enable Register
	Lane_En Lane_En (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				Lane_We					),
		.I_Data(			Lane_Data				),
		.I_Re(				Lane_Re					),
		.I_We_V_State(		We_V_State				),
		.I_V_State(			V_State_Data.data[15:0]	),
		.O_Data(			V_State					)
	);


	//// Network Stage
	Network_S Network_S (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Network			),
		.I_Command(			PipeReg_RR_Net			),
		.I_Sel_Path(		Config_Path[1:0]		),
		.I_Sel_Path_WB(		Config_Path_WB			),
		.I_WB_Index(		WB_Token.dst.idx		),
		.I_WB_Data(			WB_Data					),
		.O_WB_Data(			WB_Data_				),
		.O_Src_Data1(		PipeReg_Net.data1		),
		.O_Src_Data2(		PipeReg_Net.data2		),
		.O_Src_Data3(		PipeReg_Net.data3		),
		.O_Buff_Full(		Bypass_Buff_Full		),
		.O_PAC_Src_Data(	PAC_Src_Data			)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_Exe		<= '0;
		end
		else if ( I_En ) begin
			PipeReg_Exe		<= PipeReg_Net;
		end
	end


	//// Execution Stage
	//	 Math Unit
	ExecUnit_S ExecUnit_S (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_ExecUnit			),
		.I_Command(			PipeReg_Exe				),
		.I_Commit_Grant(	Commit_Grant_S			),
		.O_LdSt1(			O_LdSt[0]				),
		.O_LdSt2(			O_LdSt[1]				),
		.I_Ld_Data1(		I_Ld_Data[0]			),
		.I_Ld_Data2(		I_Ld_Data[1]			),
		.O_St_Data1(		O_St_Data[0]			),
		.O_St_Data2(		O_St_Data[1]			),
		.I_Ld_Ready(		I_Ld_Ready				),
		.I_Ld_Grant(		I_Ld_Grant				),
		.I_St_Ready(		I_St_Ready				),
		.I_St_Grant(		I_St_Grant				),
		.I_End_Access1(		I_End_Access[0]			),
		.I_End_Access2(		I_End_Access[1]			),
		.I_Re_p0(			Re_p0					),
		.I_Re_p1(			Re_p1					),
		.O_WB_Token_LdSt1(	WB_Token_LdSt1			),
		.O_WB_Token_LdSt2(	WB_Token_LdSt2			),
		.O_WB_Token_Math(	WB_Token_Math			),
		.O_WB_Token_Mv(		WB_Token_Mv				),
		.O_WB_Data_LdSt1(	WB_Data_LdSt1			),
		.O_WB_Data_LdSt2(	WB_Data_LdSt2			),
		.O_WB_Data_Math(	WB_Data_Math			),
		.O_WB_Data_Mv(		WB_Data_Mv				),
		.O_LdSt_Done1(		LdSt_Done1				),
		.O_LdSt_Done2(		LdSt_Done2				),
		.O_Math_Done(		Math_Done				),
		.O_Mv_Done(			Mv_Done					),
		.O_Ld_Stall(		Ld_Stall				),
		.O_St_Stall(		St_Stall				)
	);


	//// Program Address Control
	PACUnit PACUnit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			I_Req_St				),
		.I_End_St(			I_End_St				),
		.I_Req_Ld(			PAC_Req					),
		.I_End_Ld(			O_Term					),
		.I_Stall(			Stall_PCU				),
		.I_Valid(			CondValid				),
		.I_Jump(			Instr_Jump				),
		.I_Branch(			Instr_Branch			),
		.I_State(			Condition				),
		.I_Cond(			Cond_Data				),
		.I_Src(				PAC_Src_Data[9:0]		),
		.O_Re(				O_Re_Instr				),
		.O_Address(			O_Rd_Address			)
	);


	//// Commitment Stage
	ReorderBuff_S #(
		.NUM_ENTRY(			NUM_ENTRY_RB_S			)
	) ReorderBuff
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Store(			Store_S					),
		.I_is_Vec(			Instr.instr.op.Sel_Unit	),
		.I_Issue_No(		Issue_No				),
		.I_Commit_Req_LdSt1(Commmit_Req_LdSt1		),
		.I_Commit_Req_LdSt2(Commmit_Req_LdSt2		),
		.I_Commit_Req_Math(	Commmit_Req_Math		),
		.I_Commit_Req_Mv(	Commmit_Req_Mv			),
		.I_Commit_No_LdSt1(	Commit_No_LdSt1			),
		.I_Commit_No_LdSt2(	Commit_No_LdSt2			),
		.I_Commit_No_Math(	Commit_No_Math			),
		.I_Commit_No_Mv(	Commit_No_Mv			),
		.O_Commit_Grant(	Commit_Grant_S			),
		.I_Commit_Req_V(	I_Commmit_Req_V			),
		.I_Commit_No_V(		I_Commit_No_V			),
		.O_Commit_Grant_V(	O_Commit_Grant_V		),
		.O_Commit_Req(		Commit_Req				),
		.O_Commit_No(		Commit_No				),
		.O_Full(			Full_RB_S				),
		.O_Empty(			Empty_RB_S				)
	);

endmodule
