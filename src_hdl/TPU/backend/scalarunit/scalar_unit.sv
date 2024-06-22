module scalar_unit
	import pkg_mpu::*;
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Empty,				//Empty on Buffer
	input	instr_t				I_instr,				//Instruction from Buffer
	input						I_En,					//Enable Execution
	input	issue_no_t			I_IssueNo,				//Issued Thread-ID
	input	id_t				I_ThreadID_SIMT,		//SIMT Thread-ID
	input	data_t				I_Scalar_Data,			//Scalar Data from Vector Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Vector Unit
	output	address_t			O_Address1,				//Data Memory Address
	output	address_t			O_Address2,				//Data Memory Address
	output						O_Ld_Req1,				//Load Request
	output						O_Ld_Req2,				//Load Request
	input	data_t				I_Ld_Data1,				//Loaded Data
	input	data_t				I_Ld_Data2,				//Loaded Data
	output						O_St_Req1,				//Store Request
	output						O_St_Req2,				//Store Request
	output	data_t				O_St_Data1,				//Store Data
	output	data_t				O_St_Data2,				//Store Data
	output						O_Re,					//Read-Enable for Buffer
	output	commant_t			O_V_Command,			//Command to Vector Unit
	output	rotate_t			O_Rotate_Amount1,		//Rotation Amount Used in Network
	output	rotate_t			O_Rotate_Amount2,		//Rotation Amount Used in Network
	output	s_stat_t			O_Status				//Scalar Unit Status
);


	address_t				PC;
	instr_t					Instruction;


	logic					Req_PCU;
	logic					Stall_PCU;


	logic					Req_IFetch;


	logic					Req_IW;
	command_t				Pre_Command;
	command_t				HZD_Command;
	command_t				Command;
	iw_t					Index_Entry;

	logic					Valid_Dst;
	logic					Valid_Src1;
	logic					Valid_Src2;
	logic					Valid_Src3;
	logic					Valid_Src4;
	index_s_t				Index_Dst;
	index_s_t				Index_Src1;
	index_s_t				Index_Src2;
	index_s_t				Index_Src3;

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
	logic					LdSt_Odd;
	logic					LdSt_Even;
	logic					Stall_LdSt_Odd;
	logic					Stall_LdSt_Even;
	address_t				Address;
	address_t				Stride;
	address_t				Length;
	data_t					Ld_Data1;
	data_t					Ld_Data2;
	logic					LdSt_Done1;
	logic					LdSt_Done2;


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


	//// Command Issue
	Issue_Command Issue_Command(
		.I_Sel_Unit(		)
		.I_Command(			Pre_Command				),
		.O_S_Command(		Command					),
		,.O_V_Command(		O_V_Command				)
	);


	//// Stall Control
	assign Slice			= Slice_Idx_Odd1 | Slice_Idx_Odd2 | Slice_Idx_Even1 | Slice_Idx_Even2 | Slice_Dst;


	//// Index Update Stage
	assign Index_Length		 Command.IdxLength;

	assign Req_Index_Dst	= Command.v_dst & Req_Issue;
	assign Slice_Dst		= Command.slice1 | Command.slice2 | Command.slice3;
	assign Index_Dst		= Command.SrcDst;

	assign Req_Index_Odd1	= Command.v_src1 & Req_Issue;
	assign Slice_Odd1		= Command.slice1;
	assign Index_Orig_Odd1	= Command.SrcIdx1;

	assign Req_Index_Odd2	= Command.v_src2 & Req_Issue;
	assign Slice_Odd2		= Command.slice2;
	assign Index_Odd2		= Command.SrcIdx2;

	assign Req_Index_Even1	= Command.v_src3 & Req_Issue;
	assign Slice_Even1		= Command.slice2;
	assign Index_Even1		= Command.SrcIdx2;

	assign Req_Index_Even2	= Command.v_src4 & Req_Issue;
	assign Slice_Even2		= Command.slice3;
	assign Index_Even2		= Command.SrcIdx3;


	//// Register-Read Stage
	assign Slice_Idx_RFFile	= Slice_Idx_Odd1 | Slice_Idx_Odd2 | Slice_Idx_Enen1 | Slice_Idx_Enen2;


	//// Instruction Memory
	InstrMem IMem (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			),
		.O_Ack_St(			),
		.I_St_Instr(		),
		.I_Req_Ld(			IFetch					),
		.I_Ld_Address(		PC						),
		.O_Ld_Instr(		Instruction				)
	);


	//// Program Address Control
	PAC PAC (
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
		.I_Src(				),
		.O_IFetch(			IFetch					),
		.O_Address(			PC						)
		.O_StallReq(		)
	);


	//// Instruction Fetch Stage
	IFetch IFetch (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IFetch				),
		.I_Empty(			I_Empty					),
		.I_Term(			),
		.I_Instr(			Instruction				),
		.O_Req(				Req_IW					),
		.O_Instr(			Instr					),
		.O_Re(				O_Re					)
	);


	//// Hazard Detect Stage
	Hazard_Detect Hazard_Detect (
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
		.I_Req_Commit(		),
		.I_Commit_No(		),
		.O_Req_Issue(		Req_Issue				),
		.O_Commmand(		Pre_Command				),
		.O_Issue_No(		IW_IssueNo				),
		.O_RAR_Hzard(		RAR_Hazard				)
	);


	//// Stall Control
	Stall_Ctrl Stall_Ctrl (
		.I_PCU_Wait(		),
		.I_Hazard(			RAR_Hazard				)
		.I_Slice(			Slice					),
		.I_Ld_NoReady(		),
		.O_Stall_IF(		Stall_IF				),
		.O_Stall_IW_St(		Stall_IW_St				),
		.O_Stall_IW_Ld(		Stall_IW_Ld				)
	);


	//// Index Update Stage
	Index Index_Dst (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_Index_Dst			),
		.I_Slice(			Slice_Dst				),
		.I_Index(			Index_Dst				),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Dst			),
		.O_Slice(			Slice_Idx_Dst			),
		.O_Index(			Index_Dst				)
	);

	Index Index_Odd1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_Index_Odd1			),
		.I_Slice(			Slice_Odd1				),
		.I_Index(			Index_Orig_Odd1			),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Odd1		),
		.O_Slice(			Slice_Idx_Odd1			),
		.O_Index(			Index_Odd1				)
	);

	Index Index_Odd2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_Index_Odd2			),
		.I_Slice(			Slice_Odd2				),
		.I_Index(			Index_Orig_Odd2			),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Odd2		),
		.O_Slice(			Slice_Idx_Odd2			),
		.O_Index(			Index_Odd2				)
	);

	Index Index_Even1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even1			),
		.I_Slice(			Slice_Even1				),
		.I_Index(			Index_Orig_Even1		),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Even1		),
		.O_Slice(			Slice_Idx_Enen1			),
		.O_Index(			Index_Even1				)
		);

	Index Index_Even2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even2			),
		.I_Slice(			Slice_Even2				),
		.I_Index(			Index_Orig_Even2		),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Even2		),
		.O_Slice(			Slice_Idx_Enen2			),
		.O_Index(			Index_Even2				)
	);

	pipereg PReg_Index (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			),
		.I_Op(				Pipe_OP_Index			),
		.O_Op(				Pipe_OP_RFile			)
	);

	//// Register Read/Write-Back Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_RegFile_Odd			),
		.I_We(				),
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
		.I_We(				),
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

	pipereg_be PReg_RFile (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			),
		.I_Op(				Pipe_OP_RFile			),
		.O_Op(				Pipe_OP_Net				),
		.I_Slice_Idx(		Slixe_Idx_RFile			),
		.I_Slice_Idx(		Slixe_Idx_Net			)
	);


	//// Network Stage
	network network (
		.I_Config_Path(		Config_Path				),
		.I_WB_Path1(		WB_Path1				),
		.I_WB_Path2(		WB_Path2				),
		.I_Path_Hop(		'0						),
		.I_Scalar_Data(		I_Scalar_Data			),
		.I_WB_Index1(		WB_Index1				),
		.I_WB_Index2(		WB_Index2				),
		.I_WB_Data2(		WB_Data1				),
		.I_WB_Data2(		WB_Data2				),
		.I_Src_Data1(		Pre_Src_Data1			),
		.I_Src_Data2(		Pre_Src_Data2			),
		.I_Src_Data3(		Pre_Src_Data3			),
		.I_Src_Data3(		Pre_Src_Data4			),
		.O_Src_Data1(		Src_Data1				),
		.O_Src_Data2(		Src_Data2				),
		.O_Src_Data3(		Src_Data3				),
		.O_Src_Data4(		Src_Data4				),
		.O_WB_Index1(		WB_RF_Index1			),
		.O_WB_Index2(		WB_RF_Index2			),
		.O_WB_Data1(		WB_RF_Data1				),
		.O_WB_Data2(		WB_RF_Data2				),
		.O_Address(			Address					),
		.O_Stride(			Stride					),
		.O_Length(			Length					)
	);

	pipereg_be PReg_Net (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			),
		.I_Op(				Pipe_OP_RFile			),
		.O_Op(				Pipe_OP_Net				),
		.I_Slice_Idx(		Slixe_Idx_Net			),
		.I_Slice_Idx(		Slixe_Idx_Math			)
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
		.I_Store(			),
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
		.O_Done(			LdSt_Done1				)
	);

	LoadStoreUnit LdSt_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Even			),
		.I_Store(			),
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
		.O_Done(			LdSt_Done2				)
	);

endmodule