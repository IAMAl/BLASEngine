module scalar_unit (
	input						clock,
	input						reset,
	input						I_Empty,				//Empty on Buffer
	input	instr_t				I_instr,				//Instruction from Buffer
	input						I_En,					//Enable Execution
	input	issue_no_t			I_ThreadID_Scalar,		//Scalar Thread-ID
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
	output	s_stat_t			O_Status				//Scalar Unit Status
);


	address_t				PC;
	instr_t					Instruction;


	logic					Req_PCU;
	logic					Stall_PCU;


	logic					Req_IFetch;


	logic					Req_IW;
	iw_t					Index_Entry;


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


	index_t					Dst_Index1;
	index_t					Dst_Index2;
	index_t					WB_Index1;
	index_t					WB_Index2;
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
	CTRL PCU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_PCU					),
		.I_Stall(			Stall_PCU				),
		.I_Sel_CondValid(	);
		.I_CondValid1(		CondValid1				),
		.I_CondValid2(		CondValid2				),
		.I_Jump(			),
		.I_Branch(			),
		.I_Timing_MY(		),
		.I_Timing_WB(		),
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
		.O_Instr(			),
		.O_Re(				O_Re					)
	);


	//// Hazard Check Stage
	St_InstrWindow  St_IW (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IW					),
		.I_Valid_Dst(		),
		.I_Valid_Src1(		),
		.I_Valid_Src2(		),
		.I_Valid_Src3(		),
		.I_Index_Dst(		),
		.I_Index_Src1(		),
		.I_Index_Src2(		),
		.I_Index_Src3(		),
		.O_Index_Entry(		Index_Entry				)
	);

	Hazard IW (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_Issue(		),
		.I_Index_Entry(		Index_Entry				),
		.I_Slice(			Slice					),
		.I_Req_Commit(		),
		.I_Commit_No(		),
		.O_Req_Issue(		),
		.O_Issue_No(		),
		.O_RAR_Hzard(		)
	);


	//// Index Update Stage
	Index Index_Odd1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_RegFile_Odd1		),
		.I_Slice(			Slice_Odd1				),
		.I_Index(			Index_Odd1				),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				),
		.O_Slice(			),
		.O_Index(			Index_Odd1				)
	);

	Index Index_Odd2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_RegFile_Odd2		),
		.I_Slice(			Slice_Odd2				),
		.I_Index(			Index_Odd2				),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				),
		.O_Slice(			),
		.O_Index(			Index_Odd2				)
	);

	Index Index_Even1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even1			),
		.I_Slice(			Slice_Even1				),
		.I_Index(			Index_Even1				),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				),
		.O_Slice(			),
		.O_Index(			Index_Even1				)
	);

	Index Index_Even2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even2			),
		.I_Slice(			Slice_Even2				),
		.I_Index(			Index_Even2				),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				),
		.O_Slice(			),
		.O_Index(			Index_Even2				)
	);


	//// Register Read/Write-Back Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_RegFile_Odd			),
		.I_We(				),
		.I_Re1(				),
		.I_Re2(				),
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
		.I_Re1(				),
		.I_Re2(				),
		.I_Index_Dst(		WB_RF_Index2			),
		.I_Data(			WB_RF_Data2				),
		.I_Index_Src1(		Index_Even1				),
		.I_Index_Src2(		Index_Even2				),
		.O_Data_Src1(		Pre_Src_Data3			),
		.O_Data_Src2(		Pre_Src_Data22			),
		.O_Req(				)
	);


	//// Bypass Path
	Bypass Bypass (
		.I_Config_Path(		Config_Path				),
		.I_WB_Path1(		WB_Path1				),
		.I_WB_Path2(		WB_Path2				),
		.I_Odd_Path(		I_Path_Odd				),//Unnecessary
		.I_Even_Path(		I_Path_Even				),//Unnecessary
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


	//// Execution Stage
	//	 Math Unit
	SMathUnit SMathUnit (
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