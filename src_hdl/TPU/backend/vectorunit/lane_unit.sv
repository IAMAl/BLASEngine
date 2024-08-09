///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Lane_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module Lane_Unit
	import pkg_tpu::*;
#(
	parameter int NUM_LANES		= 16,
	parameter int WIDTH_LANES	= $clog2(NUM_LANES),
	parameter int LANE_ID		= 0
)(
	input						clock,
	input						reset,
	input						I_En,					//Enable Execution
	input	instr_t				I_LaneID,				//Lane-ID
	input	instr_t				I_ThreadID,				//SIMT Thread-ID
	input	command_t			I_Command,				//Execution Command
	input	data_t				I_Scalar_Data,			//Scalar Data from Scalar Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Scalar Unit
	output	address_t			O_Address1,				//Data Memory Address
	output	address_t			O_Address2,				//Data Memory Address
	output	logic				O_Ld_Req1,				//Load Request
	output	logic				O_Ld_Req2,				//Load Request
	input						I_Ack_Ld1,				//Acknowlefge from Loading
	input						I_Ack_Ld2,				//Acknowlefge from Loading
	input	data_t				I_Ld_Data1,				//Loaded Data
	input	data_t				I_Ld_Data2,				//Loaded Data
	output	logic				O_St_Req1,				//Store Request
	output	logic				O_St_Req2,				//Store Request
	output	data_t				O_St_Data1,				//Store Data
	output	data_t				O_St_Data2,				//Store Data
	output	logic				O_Commit,				//Commit Request
	input	lane_t				I_Lane_Data_Src1,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src2,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src3,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src1,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src2,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src3,		//Inter-Lane Connect
	output	logic				O_Status				//Lane Status
);


	pipe_rr_net_t			pipe_idx_rf;
	pipe_rr_net_t			pipe_rr;
	pipe_rr_net_t			pipe_net;


	dst_info_t				DstInfo;


	logic					IDec_Slice_Odd1;
	logic					IDec_Slice_Odd2;
	logic					IDec_Slice_Even1;
	logic					IDec_Slice_Even2;
	index_t					IDec_Index_Window;
	index_t					IDec_Index_Length;


	logic					MaskedRead;
	logic					Sign;
	const_t					Constant;
	logic					Slice_Dst;
	logic					Stall_RegFile_Odd;
	logic					Stall_RegFile_Even;
	logic					Req_RegFile_Odd1;
	logic					Req_RegFile_Odd2;
	logic					Req_RegFile_Even1;
	logic					Req_RegFile_Even2;
	logic					Index_Slice_Dst;
	logic					Index_Slice_Odd1;
	logic					Index_Slice_Odd2;
	logic					Index_Slice_Even1;
	logic					Index_Slice_Even2;
	index_t					Index_Dst;
	index_t					Index_Odd1;
	index_t					Index_Odd2;
	index_t					Index_Even1;
	index_t					Index_Even2;
	logic	[7:0]			Sel_Index_Dst;
	logic	[7:0]			Sel_Index_Odd1;
	logic	[7:0]			Sel_Index_Odd2;
	logic	[7:0]			Sel_Index_Evn1;
	logic	[7:0]			Sel_Index_Evn2;


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


	stat_v_t				Status;


	logic	[2:0]			Sel_ALU_Src1;
	logic	[2:0]			Sel_ALU_Src2;
	logic	[2:0]			Sel_ALU_Src3;

	index_t					Src_Idx1;
	index_t					Src_Idx2;
	index_t					Src_Idx3;


	mask_t					Mask_Data;

	logic	[12:0]			Config_Path;


	data_t					Bypass_Data1;
	data_t					Bypass_Data2;
	data_t					Src_Data1;
	data_t					Src_Data2;
	data_t					Src_Data3;
	data_t					Src_Data4;


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
	logic					LdSt_Odd;
	logic					LdSt_Even;
	logic					Stall_LdSt_Odd;
	logic					Stall_LdSt_Even;
	address_t				Address;
	address_t				Stride;
	address_t				Length;
	data_t					Ld_Data1;
	data_t					Ld_Data2;
	logic					Ld_NoReady1;
	logic					Ld_NoReady2;
	logic					LdSt_Done1;
	logic					LdSt_Done2;

	logic					Req_Issue;


	//// Index Update Stage
	// Constant Value Extraction
	// Capture Extracted Info
	pipe_index_t			PipeReg_Index;

	//	Command
	assign PipeReg_Index.v			= I_Command.instr.v;
	assign PipeReg_Index.op			= I_Command.instr.op;

	//	Write-Back
	assign PipeReg_Index.sdt		= I_Command.dst

	//	Indeces
	assign PipeReg_Index.slice_len	= I_Command.instr.slice_len;

	assign PipeReg_Index.src1		= I_Command.instr.src1;
	assign PipeReg_Index.src2		= I_Command.instr.src2;
	assign PipeReg_Index.src3		= I_Command.instr.src2;
	assign PipeReg_Index.src4		= I_Command.instr.src4;

	//	Issue-No
	assign PipeReg_Index.issue_no	= I_Command.issue_no;


	//// Register Read/Write Stage
	pipe_rr_t			Slice_Idx_RR;

	//	Command
	assign Slice_Idx_RR.v		= pipe_idx_rf.v;
	assign Slice_Idx_RR.op		= pipe_idx_rf.op;

	//	Write-Back
	assign Slice_Idx_RR.dst		= pipe_idx_rf.dst;

	//	Indeces
	assign Slice_Idx_RR.src1	= pipe_idx_rf.src1;
	assign Slice_Idx_RR.src2	= pipe_idx_rf.src2;
	assign Slice_Idx_RR.src3	= pipe_idx_rf.src3;
	assign Slice_Idx_RR.src4	= pipe_idx_rf.src4;

	//	Issue-No
	assign Slice_Idx_RR.issue_no= pipe_idx_rf.issue_no;


	assign Slice_Idx_RR	= Slice_Idx_Odd1 | Slice_Idx_Odd2 | Slice_Idx_Even1 | Slice_Idx_Even2;

	assign Re_RegFile_Odd1	= Slice_Idx_RR.src1.v;
	assign Re_RegFile_Odd2	= Slice_Idx_RR.src2.v;
	assign Re_RegFile_Even1	= Slice_Idx_RR.src3.v;
	assign Re_RegFile_Even2	= Slice_Idx_RR.src4.v;

	assign Index_Odd1		= Slice_Idx_RR.src1.idx;
	assign Index_Odd2		= Slice_Idx_RR.src2.idx;
	assign Index_Even1		= Slice_Idx_RR.src3.idx;
	assign Index_Even2		= Slice_Idx_RR.src4.idx;


	//	Capture Read Data
	pipe_net_t			PipeReg_RR_Net;
	//	Command
	assign PipeReg_RR_Net.v		= Slice_Idx_RR.v;
	assign PipeReg_RR_Net.op	= Slice_Idx_RR.op;

	//	Write-Back
	assign PipeReg_RR_Net.dst	= Slice_Idx_RR.dst;

	//	Read Data
	assign PipeReg_RR_Net.src1.idx	= Index_Odd1;
	assign PipeReg_RR_Net.src1.data	= Src_Data1;

	assign PipeReg_RR_Net.src2.idx	= ( Slice_Idx_RR.src2.v ) ?			Index_Odd2 :
										( Slice_Idx_RR.src1.src3.v ) ?	Index_Even1 :
																		'0;

	assign PipeReg_RR_Net.src2.data	= ( Slice_Idx_RR.src2.v ) ?			Pre_Src_Data2 :
										( Slice_Idx_RR.src1.src3.v ) ?	Pre_Src_Data3 :
																		'0;

	assign PipeReg_RR_Net.src3.idx	= Index_Odd4;
	assign PipeReg_RR_Net.src3.data	= Src_Data4;

	//	Issue-No
	assign PipeReg_RR_Net.issue_no	= Slice_Idx_RR.issue_no;


	//// Nwtwork
	assign Config_Path		= ;//ToDo

	assign Sel_ALU_Src1		= Pipe_OP_Net.Sel_ALU_Src1;
	assign Sel_ALU_Src2		= Pipe_OP_Net.Sel_ALU_Src2;
	assign Sel_ALU_Src3		= Pipe_OP_Net.Sel_ALU_Src3;

	assign Src_Idx1			= Pipe_OP_Net.Src_Idx1;
	assign Src_Idx2			= Pipe_OP_Net.Src_Idx2;
	assign Src_Idx3			= Pipe_OP_Net.Src_Idx3;

	assign pipe_net.valid	= pipe_rr_net.valid;
	assign pipe_net.OpType	= pipe_rr_net.OpType;
	assign pipe_net.OpClass	= pipe_rr_net.OpClass;
	assign pipe_net.OpCode	= pipe_rr_net.OpCode;
	assign pipe_net.dst_info= pipe_rr_net.dst_info;

	assign pipe_net.Issue_No= pipe_rr_net.Issue_No;


	//// Commit Request
	assign O_Commit			= LdSt_Done1 | LdSt_Done2 | Math_Done;


	//// Lane Status
	assign O_Status			= ;//ToDo


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
		.I_Req(				Req_RegFile_Odd1		),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			IDec_Slice_Odd1			),
		.I_Sel(				Sel_Index_Odd1			),
		.I_Index(			IDec_Index_Odd1			),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.v_src1		),
		.O_Slice(			PipeReg_Index.slice1		),
		.O_Index(			PipeReg_Index.SrcIdx1		)
	);

	IndexUnit Index_Odd2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_RegFile_Odd2		),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			IDec_Slice_Odd2			),
		.I_Sel(				Sel_Index_Odd2			),
		.I_Index(			IDec_Index_Odd2			),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.v_src2		),
		.O_Slice(			PipeReg_Index.slice2		),
		.O_Index(			PipeReg_Index.SrcIdx2		)
	);

	IndexUnit Index_Even1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even1			),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			IDec_Slice_Even1		),
		.I_Sel(				Sel_Index_Evn1			),
		.I_Index(			IDec_Index_Even1		),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.v_src3		),
		.O_Slice(			PipeReg_Index.slice3		),
		.O_Index(			PipeReg_Index.SrcIdx3		)
	);

	IndexUnit Index_Even2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even2			),
		.I_MaskedRead(		MaskedRead				),
		.I_Slice(			IDec_Slice_Even2		),
		.I_Sel(				Sel_Index_Evn2			),
		.I_Index(			IDec_Index_Even2		),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Req(				PipeReg_Index.v_src4		),
		.O_Slice(			PipeReg_Index.slice4		),
		.O_Index(			PipeReg_Index.SrcIdx4		)
	);


	PipeReg PReg_Index (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			),//ToDo
		.I_Op(				PipeReg_Index				),
		.O_Op(				pipe_idx_rf				)
	);


	//// Register Read/Write Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_RegFile_Odd			),
		.I_We(				We_RegFile_Odd			),
		.I_Re1(				Re_RegFile_Odd1			),
		.I_Re2(				Re_RegFile_Odd2			),
		.I_Index_Dst(		Index_Dst_Odd			),
		.I_Data(			WB_Data_Odd				),
		.I_Index_Src1(		pipe_rr.SrcIdx1			),
		.I_Index_Src2(		Index_Odd2				),
		.O_Data_Src1(		pipe_rr.Src_Data1		),
		.O_Data_Src2(		Pre_Src_Data2			),
		.O_Req(										)
	);

	RegFile RegFile_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_RegFile_Even		),
		.I_We(				We_RegFile_Even			),
		.I_Re1(				Re_RegFile_Even1		),
		.I_Re2(				Re_RegFile_Even2		),
		.I_Index_Dst(		Index_Dst_Even			),
		.I_Data(			WB_Data_Even			),
		.I_Index_Src1(		Index_Even1				),
		.I_Index_Src2(		pipe_rr.SrcIdx3			),
		.O_Data_Src1(		Pre_Src_Data3			),
		.O_Data_Src2(		pipe_rr.Src_Data3		),
		.O_Req(				)//ToDo
	);


	PipeReg_BE PReg_RFile (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			),//ToDo
		.I_Op(				pipe_rr					),
		.O_Op(				pipe_rr_net				),
		.I_Slice_Idx(		Slixe_Idx_RFile			),
		.O_Slice_Idx(		Slixe_Idx_Net			)
	);


	//// Status Register
	StatusCtrl StatusCtrl (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_En					),
		.I_Diff_Data(		Diff_Data				),
		.O_Status(			Status					),
	);


	//// Mask Register
	//		I_Index: WB Dst-IndexUnit
	MaskReg MaskReg (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				),//ToDo
		.I_Index(			),//ToDo
		.I_Cond(			).//ToDo
		.I_Status(			Status					),
		.I_Re(				),//ToDo
		.O_Mask_Data(		Mask_Data				)
	);


	//// Network Stage
	Network_V #(
		.NUM_LANES(			NUM_LANES				),
		.LANE_ID(			LANE_ID					)
	) Network_V
	(
		.I_Req(				),//ToDo
		.I_Sel_Path(		Config_Path				),
		.I_Scalar_Data(		I_Scalar_Data			),
		.I_Sel_ALU_Src1(	Sel_ALU_Src1			),
		.I_Sel_ALU_Src2(	Sel_ALU_Src2			),
		.I_Sel_ALU_Src3(	Sel_ALU_Src3			),
		.I_Lane_Data_Src1(	I_Lane_Data_Src1		),
		.I_Lane_Data_Src2(	I_Lane_Data_Src2		),
		.I_Lane_Data_Src3(	I_Lane_Data_Src3		),
		.I_Src_Data1(		Pre_Src_Data1			),
		.I_Src_Data2(		Pre_Src_Data2			),
		.I_Src_Data3(		Pre_Src_Data3			),
		.I_Src_Data4(		Pre_Src_Data4			),
		.I_Src_Idx1(		Src_Idx1				),
		.I_Src_Idx2(		Src_Idx2				),
		.I_Src_Idx3(		Src_Idx3				),
		.I_WB_DstIdx1(		WB_Index1				),
		.I_WB_DstIdx2(		WB_Index2				),
		.I_WB_Data2(		WB_Data1				),
		.I_WB_Data2(		WB_Data2				),
		.O_Src_Data1(		Src_Data1				),
		.O_Src_Data2(		Src_Data2				),
		.O_Src_Data3(		Src_Data3				),
		.O_Lane_Data_Src1(	O_Lane_Data_Src1		),
		.O_Lane_Data_Src2(	O_Lane_Data_Src2		),
		.O_Lane_Data_Src3(	O_Lane_Data_Src3		),
		.O_Address(			Address					),
		.O_Stride(			Stride					),
		.O_Length(			Length					)
	);


	PipeReg_BE PReg_Net (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			),//ToDo
		.I_Op(				pipe_net				),
		.O_Op(				Pipe_OP_Net				),
		.I_Slice_Idx(		Slice_Idx_Net			),
		.O_Slice_Idx(		Slice_Idx_Math			)
	);


	//// Execution Stage
	//	 Math Unit
	VMathUnit VMathUnit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall1(			Stall1					),
		.I_Stall2(			Stall2					),
		.I_CEn1(			CEn1					),
		.I_CEn2(			CEn2					),
		.I_Command1(		Command1				),
		.I_Command2(		Command2				),
		.I_WB_Index1(		Dst_Index1				),
		.I_WB_Index2(		Dst_Index2				),
		.I_Src_Src_Data1(	Src_Data1				),
		.I_Src_Src_Data2(	Src_Data2				),
		.I_Src_Src_Data3(	Src_Data3				),
		.I_Src_Src_Data4(	Src_Data4				),
		.O_WB_Index1(		WB_Index1				),
		.O_WB_Index2(		WB_Index2				),
		.O_WB_Data1(		WB_Data1				),
		.O_WB_Data2(		WB_Data2				),
		.O_Done(			Math_Done				),
		.O_Cond(			Condition				)
	);

	//	 Load/Store Unit
	LoadStoreUnit LdSt_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Odd			),
		.I_Ack_Ld(			I_Ack_Ld1				),
		.I_Store(			LdSt_Odd				),
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
		.I_Store(			LdSt_Even				),
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

endmodule