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
	input						I_En,					//Enable Execution
	input						I_Empty,				//Empty on Buffer
	input						I_Req_St,				//Store Request for Instructions
	output	logic				O_Ack_St,				//Acknowledge for Storing
	input	instr_t				I_Instr,				//Instruction from Buffer
	input	issue_no_t			I_IssueNo,				//Issued Thread-ID
	input	id_t				I_ThreadID,				//Thread-ID
	input						I_Commmit_Req_V,		//Commit Request from Vector Unit
	input	data_t				I_Scalar_Data,			//Scalar Data from Vector Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Vector Unit
	output	s_ldst_t			O_LdSt,					//Load Request
	input	s_data				I_LdData,
	output	s_data				O_StData,
	output						O_Re_Buff,				//Read-Enable for Buffer
	output	command_t			O_V_Command,			//Command to Vector Unit
	input	lane_t				I_V_State,
	output	lane_t				O_Lane_En,
	output	s_stat_t			O_Status				//Scalar Unit Status
);


	address_t				PC;
	instr_t					Instruction;
	instr_t					Instr;


	logic					Req_PCU;
	logic					PCU_Wait;
	data_t					PAC_Src_Data;


	logic					Stall_PCU;
	logic					Stall_IF;
	logic					Stall_IW_St;
	logic					Stall_IW_Ld;


	logic					Req_IFetch;


	logic					Req_IW;
	instr_t					Instr_IW;
	instr_t					Instr;
	issue_no_t				Rd_Ptr;


	logic					Dst_Slice;
	logic	[6:0]			Dst_Sel;
	index_t					Dst_Index;
	index_t					Dst_Index_Window;
	index_t					Dst_Index_Length;
	logic					Dst_RegFile_Req;
	logic					Dst_RegFile_Slice;
	index_t					Dst_RegFile_Index;

	logic					MaskedRead;
	logic					Sign;
	const_t					Constant;
	logic					Slice_Dst;
	logic					Stall_RegFile_Odd;
	logic					Stall_RegFile_Even;

	data_t					Pre_Src_Data2;
	data_t					Pre_Src_Data3;


	data_t					V_State;


	mask_t					Mask_Data;

	logic	[12:0]			Config_Path;


	index_t					Dst_Index1;
	index_t					Dst_Index2;
	index_t					WB_Index1;
	index_t					WB_Index2;
	data_t					WB_Data1;
	data_t					WB_Data2;
	logic					Math_Done;
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

	pipe_index_t			PipeReg_Idx;
	pipe_index_t			PipeReg_Index;
	pipe_net_t				PipeReg_RR;
	pipe_net_t				PipeReg_RR_Net;
	pipe_exe_t				PipeReg_Net;
	pipe_exe_t				PipeReg_Exe;


	//// Output Status
	assign O_State			= State;


	//// Select Scalar unit or Vector unit backend
	assign S_Command		= ( Instr.op.Sel_Unit ) ? '0 : Instr;
	assign O_V_Command		= ( Instr.op.Sel_Unit ) ? Instr : '0;


	//// Instruction Fetch Stage
	assign Req_IFetch		= ~Stall_IF;


	//// Hazard Detect Stage
	assign Req_IW			= ~Stall_IW_St;
	assign Req_Issue		= ~Stall_IW_Ld;


	//// Scalar unit's Back-end Pipeline
	//	Command
	PipeReg_Idx.v			= S_Command.instr.v;
	PipeReg_Idx.op			= S_Command.instr.op;

	//	Write-Back
	PipeReg_Idx.sdt			= S_Command.dst

	//	Indeces
	PipeReg_Idx.slice_len	= S_Command.instr.slice_len;

	PipeReg_Idx.src1		= S_Command.instr.src1;
	PipeReg_Idx.src2		= S_Command.instr.src2;
	PipeReg_Idx.src3		= S_Command.instr.src2;
	PipeReg_Idx.src4		= S_Command.instr.src4;


	//// Index Update Stage
	//	Command
	assign PipeReg_Index.v			= PipeReg_Idx.instr.v;
	assign PipeReg_Index.op			= PipeReg_Idx.instr.op;

	//	Write-Back
	assign PipeReg_Index.dst		= PipeReg_Idx.dst

	//	Indeces
	assign PipeReg_Index.slice_len	= PipeReg_Idx.instr.slice_len;

	//	Issue-No
	assign PipeReg_Index.issue_no	= PipeReg_Idx.issue_no;


	//// Register Read/Write Stage
	//	Capture Read Data
	//	Command
	assign PipeReg_RR_Net.v		= PipeReg_RR.v;
	assign PipeReg_RR_Net.op	= PipeReg_RR.op;

	//	Write-Back
	assign PipeReg_RR_Net.dst	= PipeReg_RR.dst;

	//	Read Data
	assign PipeReg_RR_Net.idx1	= PipeReg_RR.src1.idx;

	assign PipeReg_RR_Net.src2.idx	= ( PipeReg_RR.src2.v ) ?	PipeReg_RR.src2.idx :
										( PipeReg_RR.src3.v ) ?	PipeReg_RR.src3.idx :
																	'0;

	assign PipeReg_RR_Net.src2.data	= ( PipeReg_RR.src2.v ) ?	Pre_Src_Data2 :
										( PipeReg_RR.src3.v ) ?	Pre_Src_Data3 :
																	'0;

	assign PipeReg_RR_Net.idx3	= PipeReg_RR.src4.idx;

	//	Issue-No
	assign PipeReg_RR_Net.issue_no	= PipeReg_RR.issue_no;


	//// Nwtwork
	assign Config_Path		= ;//ToDo

	//	Capture Data
	assign PipeReg_Net.v	= PipeReg_Idx_RR.v;
	assign PipeReg_Net.op	= PipeReg_Idx_RR.op;

	//	Write-Back
	assign PipeReg_Net.dst	= PipeReg_Idx_RR.dst;

	//	Issue-No
	assign PipeReg_Net.issue_no	= PipeReg_Idx_RR.issue_no;


	//// Write-Back
	assign Dst_Slice		=;//ToDo
	assign Dst_Sel			=;//ToDo
	assign Dst_Index		=;//ToDo
	assign Dst_Index_Window	=;//ToDo
	assign Dst_Index_Length	=;//ToDo

	assign WB_Req_Odd		=;//ToDo
	assign WB_Req_Even		=;//ToDo
	assign WB_We_Odd		=;//ToDo
	assign WB_We_Even		=;//ToDo
	assign WB_Index_Odd		=;//ToDo
	assign WB_Index_Even	=;//ToDo
	assign WB_Data_Odd		=;//ToDo
	assign WB_Data_Even		=;//ToDo


	//// Lane-Enable
	assign O_Lane_En		= V_State[NUM_LANE*2-1:NUM_LANE];


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


	//// Instruction Fetch Stage
	IFetch IFetch (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IFetch				),
		.I_Empty(			I_Empty					),
		.I_Term(			),//ToDo
		.I_Instr(			Instruction				),
		.O_Req(				Req_IW					),
		.O_Instr(			Instr_IW				),
		.O_Re_Buff(			O_Re_Buff				)
	);


	//// Hazard Detect Stage
	HazardCheck_TPU HazardCheck_TPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_Issue(		Req_Issue				),
		.I_Req(				Req_IW					),
		.I_Instr(			Instr_IW				),
		.I_Commit_Req(		Commit_Req				),
		.I_Commit_No(		Commit_No				),
		.O_Req_Issue(		Req_Issue				),
		.O_Instr(			Instr					),
		.O_RAR_Hzard(		RAR_Hazard				),
		.O_RAW_Hzard(								),
		.O_WAR_Hzard(								),
		.O_WAW_Hzard(								),
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
		.I_Stall(			Stall_RegFile_Dst		),
		.I_Req(				Req_Index_Dst			),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			Slice_Dst				),
		.I_Sel(				Sel_Index_Dst			),
		.I_Index(			Index_Dst				),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			Index_Length			),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				Req_RegFile_Dst			),
		.O_Slice(			Index_Slice_Dst			),
		.O_Index(			Index_Dst				)
	);

	IndexUnit Index_Odd1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				PipeReg_Idx.src1.v		),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			PipeReg_Idx.src1.slice	),
		.I_Sel(				PipeReg_Idx.src1.sel	),
		.I_Index(			PipeReg_Idx.src1.idx	),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.src1.v	),
		.O_Slice(			PipeReg_Index.src1.slice),
		.O_Index(			PipeReg_Index.src1.idx	)
	);

	IndexUnit Index_Odd2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				PipeReg_Idx.src2.v		),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			PipeReg_Idx.src2.slice	),
		.I_Sel(				PipeReg_Idx.src2.sel	),
		.I_Index(			PipeReg_Idx.src2.idx	),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.src2.v	),
		.O_Slice(			PipeReg_Index.src2.slice),
		.O_Index(			PipeReg_Index.src2.idx	)
	);

	IndexUnit Index_Even1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				PipeReg_Idx.src3.v		),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			PipeReg_Idx.src3.slice	),
		.I_Sel(				PipeReg_Idx.src3.sel	),
		.I_Index(			PipeReg_Idx.src3.idx	),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.src3.v	),
		.O_Slice(			PipeReg_Index.src3.slice),
		.O_Index(			PipeReg_Index.src3.idx	)
	);

	IndexUnit Index_Even2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				PipeReg_Idx.src4.v		),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			PipeReg_Idx.src4.slice	),
		.I_Sel(				PipeReg_Idx.src4.sel	),
		.I_Index(			PipeReg_Idx.src4.idx	),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.src4.v	),
		.O_Slice(			PipeReg_Index.src4.slice),
		.O_Index(			PipeReg_Index.src4.idx	)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_Idx_RR	<= '0;
		end
		else if () begin
			PipeReg_Idx_RR	<= PipeReg_Index;
		end
	end


	//// Register Read/Write Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_Req_Odd				),
		.I_We(				WB_We_Odd				),
		.I_Re1(				PipeReg_Idx_RR.src1.v	),
		.I_Re2(				PipeReg_Idx_RR.src2.v	),
		.I_Index_Dst(		WB_Index_Odd			),
		.I_Data(			WB_Data_Odd				),
		.I_Index_Src1(		PipeReg_Idx_RR.src1.idx	),
		.I_Index_Src2(		PipeReg_Idx_RR.src2.idx	),
		.O_Data_Src1(		PipeReg_RR.data1		),
		.O_Data_Src2(		Pre_Src_Data21			),
		.O_Req(										)
	);

	RegFile RegFile_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_Req_Even				),
		.I_We(				WB_We_Even				),
		.I_Re1(				PipeReg_Idx_RR.src3.v	),
		.I_Re2(				PipeReg_Idx_RR.src4.v	),
		.I_Index_Dst(		WB_Index_Even			),
		.I_Data(			WB_Data_Even			),
		.I_Index_Src1(		PipeReg_Idx_RR.src3.idx	),
		.I_Index_Src2(		PipeReg_Idx_RR.src4.idx	),
		.O_Data_Src1(		Pre_Src_Data22			),
		.O_Data_Src2(		PipeReg_RR.data3		),
		.O_Req(				)//ToDo
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_RR_Net	<= '0;
		end
		else if () begin
			PipeReg_RR_Net	<= PipeReg_RR;
		end
	end


	//// Status Register
	StatusCtrl StatusCtrl (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_En					),
		.I_Diff_Data(		Diff_Data				),
		.O_Status(			Status					),
	);


	//// Lane Enable Register
	Lane_En Lane_En (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				),//ToDo
		.I_Data(			),//ToDo
		.I_Re(				),//ToDo
		.I_We_V_State(		),//ToDo
		.I_V_State(			I_V_State				),
		.O_Data(			V_State					)
	);


	//// Network Stage
	Network_S Network_S (
		.I_Req(				PipeReg_RR_Net.v		),
		.I_Sel_Path(		Config_Path				),
		.I_Op(				PipeReg_RR_Net.op		),
		.I_Src_Data1(		PipeReg_RR_Net.data1	),
		.I_Src_Data2(		PipeReg_RR_Net.data2	),
		.I_Src_Data3(		PipeReg_RR_Net.data3	),
		.I_Src_Idx1(		PipeReg_RR_Net.idx1		),
		.I_Src_Idx2(		PipeReg_RR_Net.idx2		),
		.I_Src_Idx3(		PipeReg_RR_Net.idx3		),
		.I_WB_DstIdx1(		WB_Index1				),
		.I_WB_DstIdx2(		WB_Index2				),
		.I_WB_Data1(		WB_Data1				),
		.I_WB_Data2(		WB_Data2				),
		.O_Src_Data1(		PipeReg_Net.data1		),
		.O_Src_Data2(		PipeReg_Net.data2		),
		.O_Src_Data3(		PipeReg_Net.data3		),
		.O_Address(			Address					),
		.O_Stride(			Stride					),
		.O_Length(			Length					),
		.O_PAC_Src_Data(	PAC_Src_Data			)
	);

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_Exe		<= '0;
		end
		else if () begin
			PipeReg_Exe		<= PipeReg_Net;
		end
	end


	//// Execution Stage
	//	 Math Unit
	SMathUnit SMathUnit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall					),
		.I_CEn1(			CEn1					),
		.I_CEn2(			CEn2					),
		.I_Req(				PipeReg_Exe.v			),
		.I_Command(			PipeReg_Exe.op			),
		.I_WB_Dst(			PipeReg_Exe.dst			),
		.I_Src_Src_Data1(	PipeReg_Exe.data1		),
		.I_Src_Src_Data2(	PipeReg_Exe.data2		),
		.I_Src_Src_Data3(	PipeReg_Exe.data3		),
		.O_LdSt1(			O_LdSt[0]				),
		.O_LdSt2(			O_LdSt[1]				),
		.I_LdData1(			I_LdData[0]				),
		.I_LdData2(			I_LdData[1]				),
		.O_St_Data1(		O_StData[0]				),
		.O_St_Data2(		O_StData[1]				),
		.O_WB_Index1(		WB_Index				),
		.O_WB_Index2(		WB_Index2				),
		.O_WB_Data1(		WB_Data1				),
		.O_WB_Data2(		WB_Data2				),
		.O_Math_Done(		Math_Done				),
		.O_LdSt_Done1(		LdSt_Done1				),
		.O_LdSt_Done2(		LdSt_Done2				),
		.O_Cond(			Condition				)
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