module lane_unit (
	input						clock,
	input						reset,
	input						I_En,
	input	instr_t				I_ThreadID_Scalar,
	input	instr_t				I_ThreadID_SIMT,
	input	command_t			I_Command,
	input	data_t				I_Scalar_Data,
	output	data_t				O_Scalar_Data,
	input	data_t				I_Path_Odd,
	input	data_t				I_Path_Even,
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
	output	stat_t				O_Status
);

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


	//// Index Update Stage
	Index Index_Odd1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_RegFile_Odd1		),
		.I_Slice(			IDec_Slice_Odd1			),
		.I_Index(			IDec_Index_Odd1			),
		.I_Length(			IDec_Index_Length		),
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(										),
		.O_Slice(			Index_Slice_Odd1		),
		.O_Index(			Index_Odd1				)
	);

	Index Index_Odd2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_RegFile_Odd2		),
		.I_Slice(			IDec_Slice_Odd2			),
		.I_Index(			IDec_Index_Odd2			),
		.I_Length(			IDec_Index_Length		),
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(										),
		.O_Slice(			Index_Slice_Odd2		),
		.O_Index(			Index_Odd2				)
	);

	Index Index_Even1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even1			),
		.I_Slice(			IDec_Slice_Even1		),
		.I_Index(			IDec_Index_Even1		),
		.I_Length(			IDec_Index_Length		),
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(										),
		.O_Slice(			Index_Slice_Even1		),
		.O_Index(			Index_Even1				)
	);

	Index Index_Even2 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Even		),
		.I_Req(				Req_Index_Even2			),
		.I_Slice(			IDec_Slice_Even2		),
		.I_Index(			IDec_Index_Even2		),
		.I_Length(			IDec_Index_Length		),
		.I_ThreadID_Scalar(	I_ThreadID_Scalar		),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(										),
		.O_Slice(			Index_Slice_Even2		),
		.O_Index(			Index_Even2				)
	);


	//// Register Read/Write-Back Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_RegFile_Odd			),
		.I_We(				We_RegFile_Odd			),
		.I_Re1(				Re_RegFile_Odd1			),
		.I_Re2(				Re_RegFile_Odd2			),
		.I_Index_Dst(		Index_Dst_Odd			),
		.I_Data(			WB_Data_Odd				),
		.I_Index_Src1(		Index_Odd1				),
		.I_Index_Src2(		Index_Odd2				),
		.O_Data_Src1(		Pre_Src_Data1			),
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
		.I_Index_Src2(		Index_Even2				),
		.O_Data_Src1(		Pre_Src_Data3			),
		.O_Data_Src2(		Pre_Src_Data4			),
		.O_Req(										)
	);


	//// Bypass Path
	Bypass Bypass (
		.I_Config_Path(		Config_Path				),
		.I_I_WB_Path1(		I_WB_Path1				),
		.I_I_WB_Path2(		I_WB_Path2				),
		.I_Odd_Path(		I_Path_Odd				),
		.I_Even_Path(		I_Path_Even				),
		.I_Scalar_Data(		I_Scalar_Data			),
		.I_Bypass_Data1(	Bypass_Data1			),
		.I_Bypass_Data2(	Bypass_Data2			),
		.I_Src_Data1(		Pre_Src_Data1			),
		.I_Src_Data2(		Pre_Src_Data2			),
		.I_Src_Data3(		Pre_Src_Data3			),
		.I_Src_Data3(		Pre_Src_Data4			),
		.O_Src_Data1(		Src_Data1				),
		.O_Src_Data2(		Src_Data2				),
		.O_Src_Data3(		Src_Data3				),
		.O_Src_Data4(		Src_Data4				),
		.O_WB_Data1(		WB_Data1				),
		.O_WB_Data2(		WB_Data2				),
		.O_Address(			Address					),
		.O_Stride(			Stride					),
		.O_Length(			Length					)
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
		.O_Cond(			Condition				)
	);

	//	 Load/Store Unit
	LoadStoreUnit LdSt_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Odd			),
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
		.O_Done(			LdSt_Done1				)
	);

	LoadStoreUnit LdSt_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_LdSt_Even			),
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
		.O_Done(			LdSt_Done2				)
	);

endmodule