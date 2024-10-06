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
	input						I_Empty,				//Empty on Buffer
	input						I_Req_St,				//Store Request for Instructions
	output						O_Ack_St,				//Acknowledge for Storing
	input	instr_t				I_Instr,				//Instruction from Buffer
	input	id_t				I_ThreadID,				//Thread-ID
	input						I_Commit_Req_V,		//Commit Request from Vector Unit
	input	data_t				I_Scalar_Data,			//Scalar Data from Vector Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Vector Unit
	output	ldst_t				O_LdSt1,				//Load Request
	output	ldst_t				O_LdSt2,				//Load Request
	input	data_t				I_Ld_Data1,				//Loaded Data
	input	data_t				I_Ld_Data2,				//Loaded Data
	output	data_t				O_St_Data1,				//Storing Data
	output	data_t				O_St_Data2,				//Storing Data
	input	[1:0]				I_Ld_Ready,				//Flag: Ready
	input	[1:0]				I_Ld_Grant,				//Flag: Grant
	input	[1:0]				I_St_Ready,				//Flag: Ready
	input	[1:0]				I_St_Grant,				//Flag: Grant
	input	[1:0]				I_End_Access,			//Flag: End of Access
	output						O_Re_Buff,				//Read-Enable for Buffer
	output	instr_t				O_V_Command,			//Command to Vector Unit
	input	lane_t				I_V_State,				//Status from Vector Unit
	output	lane_t				O_Lane_En,				//Flag: Enable for Lanes in Vector Unit
	output	state_t				O_Status,				//Scalar Unit Status
	output						O_Term					//Flag: Termination
);


	localparam int	LANE_ID = 0;

	address_t					PC;
	instr_t						Instruction;
	instr_t						Instr;


	logic						PAC_Req;
	logic						PAC_Wait;
	data_t						PAC_Src_Data;
	logic 						PAC_We;
	logic 						PAC_Re;
	data_t						PAC_Data;

	logic						CondValid1;
	logic						CondValid2;


	logic						Instr_Jump;
	logic						Instr_Branch;


	logic						Stall_PCU;
	logic						Stall_IF;
	logic						Stall_IW_St;
	logic						Stall_IW_Ld;
	logic						Stall_IW;
	logic						Stall_RegFile_Dst;
	logic						Stall_RegFile_Odd;
	logic						Stall_RegFile_Even;
	logic						Stall_Net;
	logic						Stall_Math;


	logic						Req_IFetch;

	index_t						IDec_Index_Window;
	index_t						IDec_Index_Length;

	logic						WB_Sel_CondValid;

	logic						Req_IW;
	logic						Req_Issue;
	logic						W_Req_Issue;
	issue_no_t					IW_IssueNo;
	instr_t						Instr_IW;
	issue_no_t					Rd_Ptr;

	logic						RAR_Hazard;

	instr_t						S_Command;


	logic						Dst_Slice;
	logic	[6:0]				Dst_Sel;
	index_t						Dst_Index;
	index_t						Dst_Index_Window;
	index_t						Dst_Index_Length;
	logic						Dst_RegFile_Req;
	logic						Dst_RegFile_Slice;
	index_t						Dst_RegFile_Index;

	index_t						Index_Src1;
	index_t						Index_Src2;
	index_t						Index_Src3;

	logic						Req_Index_Dst;

	data_t						RF_Odd_Data1;
	data_t						RF_Odd_Data2;
	data_t						RF_Even_Data1;
	data_t						RF_Even_Data2;


	logic						Bypass_Buff_Full;


	logic						MaskedRead;
	logic						Sign;
	const_t						Constant;
	logic						Slice_Dst;

	data_t						Pre_Src_Data2;
	data_t						Pre_Src_Data3;


	logic						Lane_We;
	logic						Lane_Re;
	data_t						Lane_Data;
	logic	[NUM_LANES-1:0]		We_V_State;
	reg_idx_t					V_State_Data;


	data_t						V_State;

	state_t						State;
	state_t						Status;

	logic						Store_S;
	logic						Store_V;


	mask_t						Mask_Data;

	logic	[12:0]				Config_Path;;


	logic						is_WB_RF;
	logic						is_WB_BR;
	logic						is_WB_VU;

	logic						WB_En;

	logic						Sel_Dst;
	dst_t						WB_Dst;
	data_t						WB_Data;;
	logic						WB_Req_Even;
	logic						WB_Req_Odd;
	logic						WB_We_Even;
	logic						WB_We_Odd;
	index_t						WB_Index_Even;
	index_t						WB_Index_Odd;
	data_t						WB_Data_Even;
	data_t						WB_Data_Odd;
	issue_no_t					WB_IssueNo;

	logic	[1:0]				Config_Path_WB;
	logic						Math_Done;
	logic						Condition;
	issue_no_t					Bypass_IssueNo;


	logic						Ld_NoReady;
	logic						Slice;
	logic						LdSt_Done1;
	logic						LdSt_Done2;


	logic						Commmit_Req_LdSt1;
	logic						Commmit_Req_LdSt2;
	logic						Commmit_Req_Math;
	issue_no_t					Commit_No_LdSt1;
	issue_no_t					Commit_No_LdSt2;
	issue_no_t					Commit_No_Math;
	issue_no_t					Hazard;
	logic						Commit_Req_S;
	issue_no_t					Commit_No_S;
	logic						Commited_LdSt1;
	logic						Commited_LdSt2;
	logic						Commited_Math;
	logic						Commit_Grant_S;
	logic						Full_RB_S;
	logic						Empty_RB_S;


	logic						Commit_Req_V;
	issue_no_t					Commit_No_V;
	logic						Commit_Grant_V;
	logic						Full_RB_V;
	logic						Empty_RB_V;


	logic						Commit_Req;
	issue_no_t					Commit_No;

	pipe_index_t				PipeReg_Idx;
	pipe_index_t				PipeReg_Index;
	pipe_index_reg_t			PipeReg_IdxRF;
	pipe_index_reg_t			PipeReg_IdxRR;
	pipe_reg_t					PipeReg_RR;
	pipe_net_t					PipeReg_RR_Net;
	pipe_exe_t					PipeReg_Net;
	pipe_exe_t					PipeReg_Exe;


	//// Output Status
	assign O_Status				= State;


	//// Select Scalar unit or Vector unit backend
	assign S_Command			= ( ~Instr.instr.op.Sel_Unit & Req_Issue ) ? Instr : '0;
	assign O_V_Command			= (  Instr.instr.op.Sel_Unit & Req_Issue ) ? Instr : '0;


	//// Instruction Fetch Stage
	assign Req_IFetch			= ~Stall_IF;


	//// Hazard Detect Stage
	assign Req_IW				= ~Stall_IW_St;
	assign W_Req_Issue			= ~Stall_IW_Ld & ~Stall_IW;


	//// Scalar unit's Back-end Pipeline
	//	Command
	assign PipeReg_Idx.v			= S_Command.v;
	assign PipeReg_Idx.op			= S_Command.instr.op;

	//	Write-Back
	assign PipeReg_Idx.dst			= S_Command.instr.dst;

	//	Indeces
	assign PipeReg_Idx.slice_len	= S_Command.instr.slice_len;

	assign PipeReg_Idx.src1			= S_Command.instr.src1;
	assign PipeReg_Idx.src2			= S_Command.instr.src2;
	assign PipeReg_Idx.src3			= S_Command.instr.src2;

	//	Path
	assign PipeReg_Idx.path			= S_Command.instr.path;


	//// Index Update Stage
	//	Command
	assign PipeReg_Index.v			= PipeReg_Idx.v;
	assign PipeReg_Index.op			= PipeReg_Idx.op;

	//	Write-Back
	assign PipeReg_Index.dst		= PipeReg_Idx.dst;

	//	Indeces
	assign PipeReg_Index.slice_len	= PipeReg_Idx.slice_len;

	//	Issue-No
	assign PipeReg_Index.issue_no	= PipeReg_Idx.issue_no;

	//	Path
	assign PipeReg_Index.path		= PipeReg_Idx.path;


	//// Packing for Register File Access
	assign PipeReg_IdxRF.v			= PipeReg_Idx.v;
	assign PipeReg_IdxRF.op			= PipeReg_Idx.op;

	//	Write-Back
	assign PipeReg_IdxRF.dst		= PipeReg_Idx.dst;

	//	Indeces
	assign PipeReg_IdxRF.slice_len	= PipeReg_Idx.slice_len;

	//	Issue-No
	assign PipeReg_IdxRF.issue_no	= PipeReg_Idx.issue_no;

	//	Path
	assign PipeReg_IdxRF.path		= PipeReg_Idx.path;


	//// Register Read/Write Stage

	//	Capture Read Data
	//	Command
	assign PipeReg_RR_Net.v			= PipeReg_RR.v;
	assign PipeReg_RR_Net.op		= PipeReg_RR.op;

	//	Write-Back
	assign PipeReg_RR_Net.dst		= PipeReg_RR.dst;

	//	Read Data
	assign V_State_Data.v			= 1'b1;
	assign V_State_Data.idx			= '0;
	assign V_State_Data.data		= V_State;
	assign V_State_Data.src_sel		= '0;

	assign PipeReg_RR_Net.src1		= ( PipeReg_RR.src1.src_sel.no == 2'h3 ) ?	V_State_Data :
										( PipeReg_RR.src1.v ) ?					PipeReg_RR.src1 :
																				'0;

	assign PipeReg_RR_Net.src2		= ( PipeReg_RR.src2.src_sel.no == 2'h3 ) ?	V_State_Data :
										( PipeReg_RR.src2.v ) ?					PipeReg_RR.src2 :
																				'0;

	assign PipeReg_RR_Net.src3		= ( PipeReg_RR.src3.src_sel.no == 2'h3 ) ?	V_State_Data :
										( PipeReg_RR.src3.v ) ?					PipeReg_RR.src3 :
																				'0;

	//	Slice Length
	assign PipeReg_RR_Net.slice_len	= PipeReg_RR.slice_len;

	//	Issue-No
	assign PipeReg_RR_Net.issue_no	= PipeReg_RR.issue_no;

	//	Path
	assign PipeReg_RR_Net.path		= PipeReg_RR.path;


	///// Write-Back to PAC
	assign PAC_We				= WB_Dst.v & is_WB_BR;
	assign PAC_Data				= ( is_WB_BR ) ? WB_Data : '0;
	assign PAC_Re				= ( PipeReg_RR.src1.src_sel.no == 2'h2 ) |
									( PipeReg_RR.src2.src_sel.no == 2'h2 ) |
									( PipeReg_RR.src3.src_sel.no == 2'h2 );


	//// Lane-Enable
	assign Lane_We				= is_WB_VU;
	assign Lane_Data			= ( is_WB_VU ) ? WB_Data : '0;
	assign Lane_Re				= ( PipeReg_RR.src1.src_sel.no == 2'h3 ) |
									( PipeReg_RR.src2.src_sel.no == 2'h3 ) |
									( PipeReg_RR.src3.src_sel.no == 2'h3 );


	//// Nwtwork
	assign Config_Path			= PipeReg_RR_Net.path;

	//	Capture Data
	assign PipeReg_Net.v		= PipeReg_RR_Net.v;
	assign PipeReg_Net.instr.op	= PipeReg_RR_Net.op;

	//	Write-Back
	assign PipeReg_Net.instr.dst= PipeReg_RR_Net.dst;

	//	Slice Length
	assign PipeReg_Net.slice_len= PipeReg_RR_Net.slice_len;

	//	Issue-No
	assign PipeReg_Net.issue_no	= PipeReg_RR_Net.issue_no;

	//	Path
	assign PipeReg_Net.path		= PipeReg_RR_Net.path;


	//// Write-Back
	//  Network Path
	assign Config_Path_WB		= WB_Dst.path;

	assign Dst_Sel				= WB_Dst.dst_sel.unit_no;
	assign Dst_Slice			= WB_Dst.slice;
	assign Dst_Index			= WB_Dst.idx[WIDTH_INDEX-1:0];
	assign Dst_Index_Window		= WB_Dst.window;
	assign Dst_Index_Length		= WB_Dst.slice_len;

	assign is_WB_RF				= WB_Dst.dst_sel.no == 2'h1;
	assign is_WB_BR				= WB_Dst.dst_sel.no == 2'h2;
	assign is_WB_VU				= WB_Dst.dst_sel.no == 2'h3;

	assign Sel_Dst				= WB_Dst.idx[WIDTH_INDEX+2:0];
	assign WB_Req_Even			= ~Sel_Dst & WB_Dst.v & is_WB_RF;
	assign WB_Req_Odd			=  Sel_Dst & WB_Dst.v & is_WB_RF;
	assign WB_We_Even			= ~Sel_Dst & WB_Dst.v & is_WB_RF;
	assign WB_We_Odd			=  Sel_Dst & WB_Dst.v & is_WB_RF;
	assign WB_Index_Even		= ( ~Sel_Dst ) ? WB_Dst.idx :	'0;
	assign WB_Index_Odd			= (  Sel_Dst ) ? WB_Dst.idx :	'0;
	assign WB_Data_Even			= ( ~Sel_Dst ) ? WB_Data : 		'0;
	assign WB_Data_Odd			= (  Sel_Dst ) ? WB_Data : 		'0;

	assign Bypass_IssueNo		= WB_IssueNo;


	//// Commit
	assign Commit_No_Math		= WB_IssueNo;


	//// Write Vector Unit Status Register
	assign We_V_State			= I_En;
	assign V_State_Data			= I_V_State;


	//// Lane-Enable
	assign O_Lane_En			= V_State[NUM_LANES*2-1:NUM_LANES];


	//// Stall-Control
	//	TB
	assign Ld_NoReady			= 1'b0;
	assign Slice				= 1'b0;


	//// End of Execution
	assign O_Term				= PipeReg_Idx.src1.v & PipeReg_Idx.src2.v & PipeReg_Idx.src3.v & (
									( PipeReg_Idx.src1.idx == '0 ) &
									( PipeReg_Idx.src2.idx == '0 ) &
									( PipeReg_Idx.src3.idx == '0 )
								);


	//// Program Address Control
	PACUnit PACUnit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			I_Req_St				),
		.I_Req(				PAC_Req					),
		.I_Stall(			Stall_PCU				),
		.I_Sel_CondValid(	WB_Sel_CondValid		),
		.I_CondValid1(		CondValid1				),
		.I_CondValid2(		CondValid2				),
		.I_Jump(			Instr_Jump				),
		.I_Branch(			Instr_Branch			),
		.I_Timing_MY(		Bypass_IssueNo			),
		.I_Timing_WB(		WB_IssueNo				),
		.I_State(			Status					),
		.I_Cond(			Condition				),
		.I_Src(				PAC_Src_Data			),
		.O_IFetch(			Req_IFetch				),
		.O_Address(			PC						),
		.O_StallReq(		PAC_Wait				)
	);


	//// Instruction Memory
	InstrMem IMem (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			I_Req_St				),
		.O_Ack_St(			O_Ack_St				),
		.I_St_Instr(		I_Instr					),
		.I_Req_Ld(			Req_IFetch				),
		.I_Ld_Address(		PC						),
		.I_St_Address(		PC						),
		.O_Ld_Instr(		Instruction				)
	);


	//// Instruction Fetch Stage
	IFetch IFetch (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IFetch				),
		.I_Empty(			I_Empty					),
		.I_Term(			O_Term					),
		.I_Instr(			Instruction				),
		.O_Req(				Req_IW					),
		.O_Instr(			Instr_IW				),
		.O_Re_Buff(			O_Re_Buff				)
	);


	//// Hazard Detect Stage
	HazardCheck_TPU HazardCheck_TPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IW					),
		.I_Slice(			Dst_Slice				),
		.I_Req_Issue(		W_Req_Issue				),
		.I_Instr(			Instr_IW				),
		.I_Commit_Req(		Commit_Req				),
		.I_Commit_No(		Commit_No				),
		.O_Req_Issue(		Req_Issue				),
		.O_Instr(			Instr					),
		.O_RAR_Hazard(		RAR_Hazard				),
		.O_RAW_Hazard(								),
		.O_WAR_Hazard(								),
		.O_WAW_Hazard(								),
		.O_Rd_Ptr(			Rd_Ptr					)
	);


	//// Stall Control
	Stall_Ctrl Stall_Ctrl (
		.I_PAC_Wait(		PAC_Wait				),
		.I_Hazard(			RAR_Hazard				),
		.I_Slice(			Slice					),
		.I_Bypass_Buff_Full(Bypass_Buff_Full		),
		.I_Ld_NoReady(		Ld_NoReady				),
		.O_Stall_IF(		Stall_IF				),
		.O_Stall_IW_St(		Stall_IW_St				),
		.O_Stall_IW_Ld(		Stall_IW_Ld				),
		.O_Stall_IW(		Stall_IW				),
		.O_Stall_Net(		Stall_Net				)
	);


	//// Index Update Stage
	//// Index Update Stage
	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index_Dst
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Dst		),
		.I_Req(				Req_Index_Dst			),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			Dst_Slice				),
		.I_Sel(				Dst_Sel					),
		.I_Index(			Dst_Index				),
		.I_Window(			Dst_Index_Window		),
		.I_Length(			Dst_Index_Length		),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				Dst_RegFile_Req			),
		.O_Slice(			Dst_RegFile_Slice		),
		.O_Index(			Dst_RegFile_Index		)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index1
	(
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
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.src1.v	),
		.O_Slice(			PipeReg_Index.src1.slice),
		.O_Index(			Index_Src1				)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index2
	(
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
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.src2.v	),
		.O_Slice(			PipeReg_Index.src2.slice),
		.O_Index(			Index_Src2				)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index3
	(
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
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.src3.v	),
		.O_Slice(			PipeReg_Index.src3.slice),
		.O_Index(			Index_Src3				)
	);


	RF_Index_Sel RF_Index_Sel (
		.I_Odd1(			PipeReg_Index.src1.v	),
		.I_Odd2(			PipeReg_Index.src2.v	),
		.I_Odd3(			PipeReg_Index.src3.v	),
		.I_Index_Src1(		Index_Src1				),
		.I_Index_Src2(		Index_Src2				),
		.I_Index_Src3(		Index_Src3				),
		.O_Index_Src1(		PipeReg_IdxRF.src1.idx	),
		.O_Index_Src2(		PipeReg_IdxRF.src2.idx	),
		.O_Index_Src3(		PipeReg_IdxRF.src3.idx	),
		.O_Index_Src4(		PipeReg_IdxRF.src4.idx	)
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

	logic	[2:0]			Sel;
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Sel				<= '0;
		end
		else begin
			Sel				<= { PipeReg_Index.src3.v, PipeReg_Index.src2.v, PipeReg_Index.src1.v };
		end
	end


	//// Register Read/Write Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_Req_Odd				),
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
		.I_Req(				WB_Req_Even				),
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
		.O_Data_Src1(		PipeReg_RR.src1.data	),
		.O_Data_Src2(		PipeReg_RR.src2.data	),
		.O_Data_Src3(		PipeReg_RR.src3.data	)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_RR_Net	<= '0;
		end
		else if ( I_En ) begin
			PipeReg_RR_Net	<= PipeReg_RR;
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


	//// Lane Enable Register
	Lane_En Lane_En (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				Lane_We					),
		.I_Data(			Lane_Data				),
		.I_Re(				Lane_Re					),
		.I_We_V_State(		We_V_State				),
		.I_V_State(			V_State_Data			),
		.O_Data(			V_State					)
	);


	//// Network Stage
	Network_S Network_S (
		.I_Stall(			Stall_Net				),
		.I_Req(				PipeReg_RR_Net.v		),
		.I_Sel_Path(		Config_Path				),
		.I_Sel_Path_WB(		Config_Path_WB			),
		.I_Sel_ALU_Src1(	PipeReg_RR_Net.src1.v	),
		.I_Sel_ALU_Src2(	PipeReg_RR_Net.src2.v	),
		.I_Sel_ALU_Src3(	PipeReg_RR_Net.src3.v	),
		.I_Src_Data1(	PipeReg_RR_Net.src1.data	),
		.I_Src_Data2(	PipeReg_RR_Net.src2.data	),
		.I_Src_Data3(	PipeReg_RR_Net.src3.data	),
		.I_Src_Idx1(		PipeReg_RR_Net.idx1		),
		.I_Src_Idx2(		PipeReg_RR_Net.idx2		),
		.I_Src_Idx3(		PipeReg_RR_Net.idx3		),
		.I_WB_Data(			WB_Data					),
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
		.I_Stall(			Stall_Math				),
		.I_Req(				PipeReg_Exe.v			),
		.I_Issue_No(		IW_IssueNo				),
		.I_Command(			PipeReg_Exe.instr		),
		.I_Src_Data1(		PipeReg_Exe.data1		),
		.I_Src_Data2(		PipeReg_Exe.data2		),
		.I_Src_Data3(		PipeReg_Exe.data3		),
		.O_LdSt1(			O_LdSt1					),
		.O_LdSt2(			O_LdSt2					),
		.I_Ld_Data1(		I_Ld_Data1				),
		.I_Ld_Data2(		I_Ld_Data2				),
		.O_St_Data1(		O_St_Data1				),
		.O_St_Data2(		O_St_Data2				),
		.I_Ld_Ready(		I_Ld_Ready				),
		.I_Ld_Grant(		I_Ld_Grant				),
		.I_St_Ready(		I_St_Ready				),
		.I_St_Grant(		I_St_Grant				),
		.I_End_Access1(		I_End_Access1			),
		.I_End_Access2(		I_End_Access2			),
		.O_WB_Dst(			WB_Dst					),
		.O_WB_Data(			WB_Data					),
		.O_WB_IssueNo(		WB_IssueNo				),
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
		.I_Commit_No_Math(	Commit_No_Math			),
		.I_Commit_Grant(	Commit_Grant_S			),
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
		.I_En_Lane(			O_Lane_En				),
		.I_Store(			Store_V					),
		.I_Issue_No(		IW_IssueNo				),
		.I_Commit_Req(		I_Commit_Req_V			),
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