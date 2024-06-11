module scalar_unit (
	input						clock,
	input						reset,
	input						I_Empty,
	input	instr_t				I_instr,
	input						I_En,
	input	instr_t				I_ThreadID_Scalar,
	input	instr_t				I_ThreadID_SIMT,
	input	data_t				I_Scalar_Data,
	output	data_t				O_Scalar_Data,
	output	address_t			O_Address1,
	output	address_t			O_Address2,
	output						O_Ld_Req1,
	output						O_Ld_Req2,
	input	data_t				I_Ld_Data1,
	input	data_t				I_Ld_Data2,
	output						O_St_Req1,
	output						O_St_Req2,
	output	data_t				O_St_Data1,
	output	data_t				O_St_Data2,
	output						O_Re,
	output	s_stat_t			O_Status
);

	InstrMem IMem (
		.clock,
		.reset,
		.I_Req_St,
		.O_Ack_St,
		.I_St_Instr,
		.I_Req_Ld,
		.I_Ld_Address(		Address					),
		.O_Ld_Instr(		Instruction				)
	);

	CTRL PCU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				),
		.I_Stall(			),
		.I_Sel_CondValid(	);
		.I_CondValid1(		),
		.I_CondValid2(		),
		.I_Jump(			),
		.I_Branch(			),
		.I_Timing_MY(		),
		.I_Timing_WB(		),
		.I_State(			),
		.I_Cond(			),
		.I_Src(				),
		.O_IFetch(			),
		.O_Address(			Address					)
		.O_StallReq(		)
	);

	IFetch IFetch (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_IFetch				),
		.I_Empty(			I_Empty					),
		.I_Term(			),
		.I_Instr(			Instruction				),
		.O_Req(				),
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
		.I_Req_Issue(),
		.I_Index_Entry(		Index_Entry				),
		.I_Slice(			Slice					),
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
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
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
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
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
		.I_Length(			),
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
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
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
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
		.I_Index_Dst(		),
		.I_Data(			),
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
		.I_Index_Dst(		),
		.I_Data(			),
		.I_Index_Src1(		Index_Even1				),
		.I_Index_Src2(		Index_Even2				),
		.O_Data_Src1(		Pre_Src_Data3			),
		.O_Data_Src2(		Pre_Src_Data22			),
		.O_Req(				)
	);


	//// Execution Stage
	//	 Bypass Path


	//	 Load/Store Unit
	LoadStoreUnit LdSt_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Odd			),
		.I_Store(			),
		.I_Stall(			Stall_LdSt_Odd			),
		.I_Address(			Address1				),
		.I_Stride(			Stride					),
		.I_Length(			Length					),
		.O_St(				O_St_Req1				),
		.O_Ld(				O_Ld_Req1				),
		.O_Address(			O_Address1				),
		.I_St_Data(			St_Data1				),
		.O_St_Data(			O_St_Data1				),
		.I_Ld_Data(			I_Ld_Data1				),
		.O_Ld_Data(			Ld_Data1				),
		.O_Done(			)
	);

	LoadStoreUnit LdSt_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Even			),
		.I_Store(			),
		.I_Stall(			Stall_LdSt_Even			),
		.I_Address(			Address1				),
		.I_Stride(			Stride					),
		.I_Length(			Length					),
		.O_St(				O_St_Req2				),
		.O_Ld(				O_Ld_Req2				),
		.O_Address(			O_Address2				),
		.I_St_Data(			St_Data2				),
		.O_St_Data(			O_St_Data2				),
		.I_Ld_Data(			I_Ld_Data2				),
		.O_Ld_Data(			Ld_Data2				),
		.O_Done(			)
	);

endmodule