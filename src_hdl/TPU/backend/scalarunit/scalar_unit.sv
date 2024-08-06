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
(
	input						clock,
	input						reset,
	input						I_Empty,				//Empty on Buffer
	input						I_Req_St,				//Store Request for Instructions
	output	logic				O_Ack_St,				//Acknowledge for Storing
	input	instr_t				I_Instr,				//Instruction from Buffer
	input						I_En,					//Enable Execution
	input	issue_no_t			I_IssueNo,				//Issued Thread-ID
	input	id_t				I_ThreadID,				//Thread-ID
	input						I_Commmit_Req_V,		//Commit Request from Vector Unit
	input	data_t				I_Scalar_Data,			//Scalar Data from Vector Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Vector Unit
	output	address_t			O_Address1,				//Data Memory Address
	output	address_t			O_Address2,				//Data Memory Address
	output						O_Ld_Req1,				//Load Request
	output						O_Ld_Req2,				//Load Request
	input						I_Ack_Ld1,				//Acknowlefge from Loading
	input						I_Ack_Ld2,				//Acknowlefge from Loading
	input	data_t				I_Ld_Data1,				//Loaded Data
	input	data_t				I_Ld_Data2,				//Loaded Data
	output						O_St_Req1,				//Store Request
	output						O_St_Req2,				//Store Request
	output	data_t				O_St_Data1,				//Store Data
	output	data_t				O_St_Data2,				//Store Data
	output						O_Re_Buff,				//Read-Enable for Buffer
	output	command_t			O_V_Command,			//Command to Vector Unit
	input	lane_t				I_V_State,
	output	lane_t				O_Lane_En,
	output	s_stat_t			O_Status				//Scalar Unit Status
);


	address_t				PC;
	instr_t					Instruction;


	logic					Req_PCU;
	logic					PCU_Wait;
	data_t					PAC_Src_Data;


	logic					Stall_PCU;
	logic					Stall_IF;
	logic					Stall_IW_St;
	logic					Stall_IW_Ld;


	logic					Req_IFetch;


	logic					Req_IW;
	command_t				Pre_Command;
	command_t				HZD_Command;
	command_t				Command;
	iw_t					Index_Entry;
	issue_no_t				Rd_Ptr;

	logic					Valid_Dst;
	logic					Valid_Src1;
	logic					Valid_Src2;
	logic					Valid_Src3;
	logic					Valid_Src4;
	index_s_t				Index_Dst;
	index_s_t				Index_Src1;
	index_s_t				Index_Src2;
	index_s_t				Index_Src3;
	logic	[7:0]			Index_Sel_Dst;
	logic	[7:0]			Index_Sel_Odd1;
	logic	[7:0]			Index_Sel_Odd2;
	logic	[7:0]			Index_Sel_Even1;
	logic	[7:0]			Index_Sel_Even2;

	index_t					Index_Length;
	index_t					Window_Length;

	logic					Slice;
	logic					Sign;
	const_t					Constant;
	logic					Stall_RegFile_Odd;
	logic					Stall_RegFile_Even;
	logic					Req_RegFile_Odd1;
	logic					Req_RegFile_Odd2;
	logic					Req_RegFile_Even1;
	logic					Req_RegFile_Even2;
	logic					Index_Slice_Odd1;
	logic					Index_Slice_Odd2;
	logic					Index_Slice_Even1;
	logic					Index_Slice_Even2;
	index_t					Index_Orig_Odd1;
	index_t					Index_Orig_Odd2;
	index_t					Index_Orig_Even1;
	index_t					Index_Orig_Even2;
	index_t					Index_Odd1;
	index_t					Index_Odd2;
	index_t					Index_Even1;
	index_t					Index_Even2;


	logic					Req_RegFile_Odd;
	logic					Req_RegFile_Even;
	logic					We_RegFile_Odd;
	logic					We_RegFile_Even;
	logic					Re_RegFile_Odd1;
	logic					Re_RegFile_Odd2;
	logic					Re_RegFile_Even1;
	logic					Re_RegFile_Even2;
	data_t					Pre_Src_Data1;
	data_t					Pre_Src_Data2;
	data_t					Pre_Src_Data3;
	data_t					Pre_Src_Data4;


	index_t					Src_Idx1;
	index_t					Src_Idx2;
	index_t					Src_Idx3;
	index_t					Src_Idx4;


	data_t					V_State;


	data_t					Bypass_Data1;
	data_t					Bypass_Data2;
	data_t					Src_Data1;
	data_t					Src_Data2;
	data_t					Src_Data3;
	data_t					Src_Data4;


	index_s_t				Dst_Index1;
	index_s_t				Dst_Index2;
	index_s_t				WB_Index1;
	index_s_t				WB_Index2;
	data_t					WB_Data1;
	data_t					WB_Data2;
	logic					Condition;


	logic					Req_LdSt_Odd;
	logic					Req_LdSt_Even;
	logic	[1:0]			OpClass_LdSt_Odd;
	logic	[1:0]			OpClass_LdSt_Even;
	logic	[1:0]			OpCode_LdSt_Odd;
	logic	[1:0]			OpCode_LdSt_Even;
	logic					LdSt_Odd;
	logic					LdSt_Even;
	logic					Stall_LdSt_Odd;
	logic					Stall_LdSt_Even;
	address_t				Address;
	address_t				Stride;
	address_t				Length;
	data_t					Ld_Data1;
	data_t					Ld_Data2;
	logic					Ld_NoReady;
	logic					Ld_NoReady1;
	logic					Ld_NoReady2;
	logic					LdSt_Done1;
	logic					LdSt_Done2;


	logic					Commmit_Req_LdSt1;
	logic					Commmit_Req_LdSt2;
	logic					Commmit_Req_Math;
	issue_no_t				Commit_No_LdSt1;
	issue_no_t				Commit_No_LdSt2;
	issue_no_t				Commit_No_Math;
	logic					Commit_Req_S;
	issue_no_t				Commit_No_S;
	logic					Commited_LdSt1;
	logic					Commited_LdSt2;
	logic					Commited_Math;
	logic					Commit_Grant_S;
	logic					Full_RB_S;
	logic					Empty_RB_S;


	logic					Commit_Req_V;
	issue_no_t				Commit_No_V;
	logic					Commit_Grant_V;
	logic					Full_RB_V;
	logic					Empty_RB_V;


	logic					Commit_Req;
	issue_no_t				Commit_No;


	assign O_State			= State;


	//// Instruction Fetch Stage
	assign Req_IFetch		= ~Stall_IF;


	//// Hazard Detect Stage
	assign Req_IW			= ~Stall_IW_St;
	assign Req_Issue		= ~Stall_IW_Ld;

	assign Valid_Dst		= Inst.Valid_Dst;
	assign Valid_Src1		= Inst.Valid_src1;
	assign Valid_Src2		= Inst.Valid_src2;
	assign Valid_Src3		= Inst.Valid_src3;
	assign Index_Dst		= Instr.IdxDst;
	assign Index_Src1		= Instr.SrcIdx1;
	assign Index_Src2		= Instr.SrcIdx2;
	assign Index_Src3		= Instr.SrcIdx3;


	//// Stall Control
	assign Slice			= Slice_Idx_Odd1 | Slice_Idx_Odd2 | Slice_Idx_Even1 | Slice_Idx_Even2 | Slice_Dst;


	//// Index Update Stage
	assign Index_Length		= S_Command.IdxLength;
	assign Window_Length	= S_Command.IdxWindow;

	assign Req_Index_Dst	= S_Command.v_dst & Req_Issue;
	assign Slice_Dst		= S_Command.slice1 | S_Command.slice2 | S_Command.slice3;
	assign Index_Dst		= S_Command.SrcDst;
	assign Index_Sel_Dst	= //ToDo;

	assign Req_Index_Odd1	= S_Command.v_src1 & Req_Issue;
	assign Slice_Odd1		= S_Command.slice1;
	assign Index_Orig_Odd1	= S_Command.SrcIdx1;
	assign Index_Sel_Odd1	= ;//ToDo;

	assign Req_Index_Odd2	= S_Command.v_src2 & Req_Issue;
	assign Slice_Odd2		= S_Command.slice2;
	assign Index_Odd2		= S_Command.SrcIdx2;
	assign Index_Sel_Odd2	= ;//ToDo;

	assign Req_Index_Even1	= S_Command.v_src3 & Req_Issue;
	assign Slice_Even1		= S_Command.slice2;
	assign Index_Even1		= S_Command.SrcIdx2;
	assign Index_Sel_Even1	= ;//ToDo;

	assign Req_Index_Even2	= S_Command.v_src4 & Req_Issue;
	assign Slice_Even2		= S_Command.slice3;
	assign Index_Even2		= S_Command.SrcIdx3;
	assign Index_Sel_Even2	= ;//ToDo;


	//// Register-Read Stage
	assign Slice_Idx_RFFile	= Slice_Idx_Odd1 | Slice_Idx_Odd2 | Slice_Idx_Enen1 | Slice_Idx_Enen2;


	//// Lane-Enable
	assign O_Lane_En		= V_State[WIDTH_DATA-1:NUM_LANE];


	//// Network
	assign Src_Idx1			= ;//ToDo
	assign Src_Idx2			= ;//ToDo
	assign Src_Idx3			= ;//ToDo
	assign Src_Idx4			= ;//ToDo


	//// Execution Stage
	//	 Load/Store Unit
	assign OpClass_LdSt_Odd	= S_Command.OpClass;
	assign OpClass_LdSt_Even= S_Command.OpClass;
	assign OpCode_LdSt		= S_Command.OpCode;

	assign Ld_NoReady		= Ld_NoReady1 | Ld_NoReady2;


	//// Instruction Memory
	InstrMem IMem (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			I_Req_St				),
		.O_Ack_St(			O_Ack_St				),
		.I_St_Instr(		I_Instr					),
		.I_Req_Ld(			IFetch					),
		.I_Ld_Address(		PC						),
		.O_Ld_Instr(		Instruction				)
	);


	//// Program Address Control
	PACUnit PACUnit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_PCU					),
		.I_Stall(			Stall_PCU				),
		.I_Sel_CondValid(	WB_Sel_CondValid		);
		.I_CondValid1(		CondValid1				),
		.I_CondValid2(		CondValid2				),
		.I_Jump(			Instr_Jump				),
		.I_Branch(			Instr_Branch			),
		.I_Timing_MY(		Bypass_IssueNo			),
		.I_Timing_WB(		WB_IssueNo				),
		.I_State(			State					),
		.I_Cond(			Condition				),
		.I_Src(				PAC_Src_Data			),
		.O_IFetch(			IFetch					),
		.O_Address(			PC						)
		.O_StallReq(		PCU_Wait				)
	);


	//// Instruction Fetch Stage
	IFetch IFetch (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IFetch				),
		.I_Empty(			I_Empty					),
		.I_Term(			),//ToDo
		.I_Instr(			Instruction				),
		.O_Req(				Req_IW					),
		.O_Instr(			Instr					),
		.O_Re_Buff(			O_Re_Buff				)
	);


	//// Hazard Detect Stage
	HazardCheck_TPU HazardCheck_TPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_Issue(		Req_Issue				),
		.I_Req(				Req_IW					),
		.I_Command(			Pre_Command				),
		.I_Valid_Dst(		Valid_Dst				),
		.I_Valid_Src1(		Valid_Src1				),
		.I_Valid_Src2(		Valid_Src2				),
		.I_Valid_Src3(		Valid_Src3				),
		.I_Index_Dst(		Index_Dst				),
		.I_Index_Src1(		Index_Src1				),
		.I_Index_Src2(		Index_Src2				),
		.I_Index_Src3(		Index_Src3				),
		.I_Command(			HZD_Command				),
		.I_Index_Entry(		Index_Entry				),
		.I_Slice(			Slice					),
		.I_Req_Commit(		Commit_Req				),
		.I_Commit_No(		Commit_No				),
		.O_Req_Issue(		Req_Issue				),
		.O_Command(			Pre_Command				),
		.O_Issue_No(		IW_IssueNo				),
		.O_RAR_Hzard(		RAR_Hazard				),
		.O_Rd_Ptr(			Rd_Ptr					)
	);


	//// Select Scalar-Unit Back-End or Vector Unit Back-End
	Dispatch_TPU Dispatch_TPU (
		.I_Command(			Pre_Command				),
		.O_S_Command(		S_Command				),
		.O_V_Command(		O_V_Command				)
	);


	//// Stall Control
	Stall_Ctrl Stall_Ctrl (
		.I_PCU_Wait(		PCU_Wait				),
		.I_Hazard(			RAR_Hazard				)
		.I_Slice(			Slice					),
		.I_Ld_NoReady(		Ld_NoReady				),
		.O_Stall_IF(		Stall_IF				),
		.O_Stall_IW_St(		Stall_IW_St				),
		.O_Stall_IW_Ld(		Stall_IW_Ld				)
	);


	//// Index Update Stage
	IndexUnit Index_Dst (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_Index_Dst			),
		.I_Slice(			Slice_Dst				),
		.I_Sel(				Index_Sel_Dst			),
		.I_Index(			Index_Dst				),
		.I_Window(			Window_Length			),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Dst			),
		.O_Slice(			Slice_Idx_Dst			),
		.O_Index(			Index_Dst				)
	);

	IndexUnit Index_Odd1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_Index_Odd1			),
		.I_Slice(			Slice_Odd1				),
		.I_Sel(				Index_Sel_Odd1			),
		.I_Index(			Index_Orig_Odd1			),
		.I_Window(			Window_Length			),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Odd1		),
		.O_Slice(			Slice_Idx_Odd1			),
		.O_Index(			Index_Odd1				)
	);

	IndexUnit Index_Odd2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_Index_Odd2			),
		.I_Slice(			Slice_Odd2				),
		.I_Sel(				Index_Sel_Odd2			),
		.I_Index(			Index_Orig_Odd2			),
		.I_Window(			Window_Length			),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Odd2		),
		.O_Slice(			Slice_Idx_Odd2			),
		.O_Index(			Index_Odd2				)
	);

	IndexUnit Index_Even1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even1			),
		.I_Slice(			Slice_Even1				),
		.I_Sel(				Index_Sel_Even1			),
		.I_Index(			Index_Orig_Even1		),
		.I_Window(			Window_Length			),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Even1		),
		.O_Slice(			Slice_Idx_Enen1			),
		.O_Index(			Index_Even1				)
		);

	IndexUnit Index_Even2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even2			),
		.I_Slice(			Slice_Even2				),
		.I_Sel(				Index_Sel_Even1			),
		.I_Index(			Index_Orig_Even2		),
		.I_Window(			Window_Length			),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Even2		),
		.O_Slice(			Slice_Idx_Enen2			),
		.O_Index(			Index_Even2				)
	);

	PipeReg PReg_Index (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall					),
		.I_Op(				Pipe_OP_Index			),
		.O_Op(				Pipe_OP_RFile			)
	);


	//// Register Read/Write-Back Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_RegFile_Odd			),
		.I_We(				WB_RF_We1				),
		.I_Re1(				Req_RegFile_Odd1		),
		.I_Re2(				Req_RegFile_Odd2		),
		.I_Index_Dst(		WB_RF_Index1			),
		.I_Data(			WB_RF_Data1				),
		.I_Index_Src1(		Index_Odd1				),
		.I_Index_Src2(		Index_Odd2				),
		.O_Data_Src1(		Pre_Src_Data1			),
		.O_Data_Src2(		Pre_Src_Data21			),
		.O_Req(				)
	);

	RegFile RegFile_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_RegFile_Even		),
		.I_We(				WB_RF_We2				),
		.I_Re1(				Req_RegFile_Even1		),
		.I_Re2(				Req_RegFile_Even2		),
		.I_Index_Dst(		WB_RF_Index2			),
		.I_Data(			WB_RF_Data2				),
		.I_Index_Src1(		Index_Even1				),
		.I_Index_Src2(		Index_Even2				),
		.O_Data_Src1(		Pre_Src_Data3			),
		.O_Data_Src2(		Pre_Src_Data22			),
		.O_Req(				)
	);

	PipeReg_BE PReg_RFile (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall					),
		.I_Op(				Pipe_OP_RFile			),
		.O_Op(				Pipe_OP_Net				),
		.I_Slice_Idx(		Slice_Idx_RFile			),
		.O_Slice_Idx(		Slice_Idx_Net			)
	);


	//// Lane Enable Register
	Lane_En Lane_En (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				),
		.I_Data(			),
		.I_Re(				),
		.I_We_V_State(		),
		.I_V_State(			I_V_State				),
		.O_Data(			V_State					)
	);


	//// Network Stage
	Network_S Network_S (
		.I_Req(				),//ToDo
		.I_Sel_Path(		Sel_Path				),
		.I_Sel_ALU_Src1(	Sel_ALU_Src1			),
		.I_Sel_ALU_Src2(	Sel_ALU_Src2			),
		.I_Sel_ALU_Src3(	Sel_ALU_Src3			),
		.I_Src_Data1(		Pre_Src_Data1			),
		.I_Src_Data2(		Pre_Src_Data2			),
		.I_Src_Data3(		Pre_Src_Data3			),
		.I_Src_Data4(		Pre_Src_Data4			),
		.I_Src_Idx1(		Src_Idx1				),
		.I_Src_Idx2(		Src_Idx2				),
		.I_Src_Idx3(		Src_Idx3				),
		.I_Src_Idx4(		Src_Idx4				),
		.I_WB_DstIdx1(		WB_Index1				),
		.I_WB_DstIdx2(		WB_Index2				),
		.I_WB_Data1(		WB_Data1				),
		.I_WB_Data2(		WB_Data2				),
		.O_Src_Data1(		Src_Data1				),
		.O_Src_Data2(		Src_Data2				),
		.O_Src_Data3(		Src_Data3				),
		.O_Address(			Address					),
		.O_Stride(			Stride					),
		.O_Length(			Length					),
		.O_PAC_Src_Data(	PAC_Src_Data			)
	);


	PipeReg_BE PReg_Net (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall					),
		.I_Op(				Pipe_OP_RFile			),
		.O_Op(				Pipe_OP_Net				),
		.I_Slice_Idx(		Slixe_Idx_Net			),
		.O_Slice_Idx(		Slixe_Idx_Math			)
	);


	//// Execution Stage
	//	 Math Unit
	SMathUnit SMathUnit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall					),
		.I_CEn(				CEn						),
		.I_Command(			Command					),
		.I_WB_Index(		Dst_Index				),
		.I_Src_Src_Data1(	Src_Data1				),
		.I_Src_Src_Data2(	Src_Data2				),
		.I_Src_Src_Data3(	Src_Data3				),
		.O_WB_Index1(		WB_Index1				),
		.O_WB_Index2(		WB_Index2				),
		.O_WB_Data1(		WB_Data1				),
		.O_WB_Data2(		WB_Data2				),
		.O_CondValid1(		CondValid1				),
		.O_CondValid2(		CondValid2				),
		.O_State(			State					)
	);


	//	 Load/Store Unit
	LoadStoreUnit LdSt_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Odd			),
		.I_Ack_Ld(			I_Ack_Ld1				),
		.I_OpClass(			OpClass_LdSt_Odd		),
		.I_OpCode(			OpCode_LdSt				),
		.I_Stall(			Stall_LdSt_Odd			),
		.I_Address(			Address					),
		.I_Stride(			Stride					),
		.I_Length(			Length					),
		.O_St(				O_St_Req1				),
		.O_Ld(				O_Ld_Req1				),
		.O_Address(			O_Address1				),
		.I_St_Data(			St_Data1				),
		.O_St_Data(			O_St_Data1				),
		.I_Ld_Data(			I_Ld_Data1				),
		.O_Ld_Data(			Ld_Data1				),
		.O_Ld_NoReady(		Ld_NoReady1				),
		.O_Done(			LdSt_Done1				)
	);

	LoadStoreUnit LdSt_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Even			),
		.I_Ack_Ld(			I_Ack_Ld2				),
		.I_OpClass(			OpClass_LdSt_Even		),
		.I_OpCode(			OpCode_LdSt				),
		.I_Stall(			Stall_LdSt_Even			),
		.I_Address(			Address					),
		.I_Stride(			Stride					),
		.I_Length(			Length					),
		.O_St(				O_St_Req2				),
		.O_Ld(				O_Ld_Req2				),
		.O_Address(			O_Address2				),
		.I_St_Data(			St_Data2				),
		.O_St_Data(			O_St_Data2				),
		.I_Ld_Data(			I_Ld_Data2				),
		.O_Ld_Data(			Ld_Data2				),
		.O_Ld_NoReady(		Ld_NoReady2				),
		.O_Done(			LdSt_Done2				)
	);


	//// Commitment Stage
	//	 Commit Unit for Scalar Unit
	ReorderBuff_S #(
		.NUM_ENTRY(			NUM_ENTRY_RB_S			)
	) ReorderBuff_S
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Store(			Store_S					),
		.I_Issue_No(		IW_IssueNo				),
		.I_Commit_Req_LdSt1(Commmit_Req_LdSt1		),
		.I_Commit_Req_LdSt2(Commmit_Req_LdSt2		),
		.I_Commit_Req_Math(	Commmit_Req_Math		),
		.I_Commit_No_LdSt1(	Commit_No_LdSt1			),
		.I_Commit_No_LdSt2(	Commit_No_LdSt2			),
		.I_Commit_No_LMath(	Commit_No_Math			),
		.I_Commit_Grant(	Commit_Grant_S			)
		.O_Commit_Req(		Commit_Req_S			),
		.O_Commit_No(		Commit_No_S				),
		.O_Commited_LdSt1(	Commited_LdSt1			),
		.O_Commited_LdSt2(	Commited_LdSt2			),
		.O_Commited_Math(	Commited_Math			),
		.O_Full(			Full_RB_S				),
		.O_Empty(			Empty_RB_S				)
	);

	//	 Commit Unit for Vector Unit
	ReorderBuff_V #(
		.NUM_ENTRY(			NUM_ENTRY_RB_V			)
	) ReorderBuff_V
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Store(			Store_V					),
		.I_Issue_No(		IW_IssueNo				),
		.I_Commmit_Req(		I_Commmit_Req_V			),
		.I_Commit_Grant(	Commit_Grant_V			),
		.O_Commit_Req(		Commit_Req_V			),
		.O_Commit_No(		Commit_No_V				),
		.O_Full(			Full_RB_V				),
		.O_Empty(			Empty_RB_V				)
	);

	// Commit Request Selecter
	Commit_TPU Commit_TPU (
		.I_Rd_Ptr(			Rd_Ptr					),
		.I_RB_Empty_S(		Empty_RB_S				),
		.I_RB_Empty_V(		Empty_RB_V				),
		.I_Commit_Req_S(	Commit_Req_S			),
		.I_Commit_Req_V(	Commit_Req_V			),
		.I_Commit_No_S(		Commit_No_S				),
		.I_Commit_No_V(		Commit_No_V				),
		.O_Commit_Grant_S(	Commit_Grant_S			),
		.O_Commit_Grant_V(	Commit_Grant_V			),
		.O_Commit_Req(		Commit_Req				),
		.O_Commit_No(		Commit_No				)
	);

endmodule