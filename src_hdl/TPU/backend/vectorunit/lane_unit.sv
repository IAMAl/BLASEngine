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
	output	data_t				O_Bypass,
	input	data_t				I_Data,
	output	data_t				O_Data,
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
	Bypass Bypass (
		.I_Config_Path(		),
		.I_Odd_Path(		I_Path_Odd				),
		.I_Even_Path(		I_Path_Even				),
		.I_Scalar_Data(		I_Scalar_Data			),
		.I_Bypass_Data(		),
		.I_Src_Data1(		Pre_Src_Data1			),
		.I_Src_Data2(		Pre_Src_Data2			),
		.I_Src_Data3(		Pre_Src_Data3			),
		.O_Src_Data1(		Src_Data1				),
		.O_Src_Data2(		Src_Data2				),
		.O_Src_Data3(		Src_Data3				),
		.O_Src_Data4(		Src_Data4				),
	);

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