module lane_unit
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_En,					//Enable Execution
	input	instr_t				I_LaneID,				//Lane-ID
	input	instr_t				I_ThreadID_SIMT,		//SIMT Thread-ID
	input	command_t			I_Command,				//Execution Command
	input	data_t				I_Scalar_Data,			//Scalar Data from Scalar Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Scalar Unit
	input	hop_data_t			I_Path_Hop,				//Neighbor Lane
	input	data_t				I_Rotate_Src_Data1,		//Roattion Path at Net Stage
	input	data_t				I_Rotate_Src_Data2,		//Roattion Path at Net Stage
	output	data_t				O_Rotate_Src_Data1,		//Roattion Path at Net Stage
	output	data_t				O_Rotate_Src_Dataw,		//Roattion Path at Net Stage
	output	address_t			O_Address1,				//Data Memory Address
	output	address_t			O_Address2,				//Data Memory Address
	output	logic				O_Ld_Req1,				//Load Request
	output	logic				O_Ld_Req2,				//Load Request
	input	data_t				I_Ld_Data1,				//Loaded Data
	input	data_t				I_Ld_Data2,				//Loaded Data
	output	logic				O_St_Req1,				//Store Request
	output	logic				O_St_Req2,				//Store Request
	output	data_t				O_St_Data1,				//Store Data
	output	data_t				O_St_Data2,				//Store Data
	output	logic				O_Commit,				//Commit Request
	output	v_stat_t			O_Status				//Lane Status
);


	logic					IDec_Slice_Odd1;
	logic					IDec_Slice_Odd2;
	logic					IDec_Slice_Even1;
	logic					IDec_Slice_Even2;
	index_t					IDec_Index_Window;
	index_t					IDec_Index_Length;


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
	logic					LdSt_Done1;
	logic					LdSt_Done2;


	//// Index Update Stage
	assign Index_Length		= I_Command.IdxLength;
	assign Constant			= I_Command.Imm_Data[WIDTH_INDEX-1:0];

	assign Req_Index_Dst	= I_Command.v_dst & Req_Issue;
	assign Slice_Dst		= I_Command.slice1 | I_Command.slice2 | I_Command.slice3;
	assign Index_Dst		= I_Command.Dst;

	assign Req_Index_Odd1	= I_Command.v_src1 & Req_Issue;
	assign Slice_Odd1		= I_Command.slice1;
	assign Index_Orig_Odd1	= I_Command.SrcIdx1;

	assign Req_Index_Odd2	= I_Command.v_src2 & Req_Issue;
	assign Slice_Odd2		= I_Command.slice2;
	assign Index_Odd2		= I_Command.SrcIdx2;

	assign Req_Index_Even1	= I_Command.v_src3 & Req_Issue;
	assign Slice_Even1		= I_Command.slice2;
	assign Index_Even1		= I_Command.SrcIdx2;

	assign Req_Index_Even2	= I_Command.v_src4 & Req_Issue;
	assign Slice_Even2		= I_Command.slice3;
	assign Index_Even2		= I_Command.SrcIdx3;


	//// Register Read/Write Stage
	assign Slice_Idx_RFFile	= Slice_Idx_Odd1 | Slice_Idx_Odd2 | Slice_Idx_Enen1 | Slice_Idx_Enen2;


	//// Network Stage
	//	 Rotate Path
	assign Pre_Src_Data1 	= I_Rotate_Src_Data1;
	assign Pre_Src_Data3 	= I_Rotate_Src_Data2;


	//// Commit Request
	assign O_Commit			= LdSt_Done1 | LdSt_Done2 | Math_Done;


	//// Index Update Stage
	Index Index_Dst (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_Index_Dst			),
		.I_Slice(			Slice_Dst				),
		.I_Index(			Index_Dst				),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			Index_Length			),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(				Req_RegFile_Dst			),
		.O_Slice(			Index_Slice_Dst			),
		.O_Index(			Index_Dst				)
	);

	Index Index_Odd1 (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Odd		),
		.I_Req(				Req_RegFile_Odd1		),
		.I_Slice(			IDec_Slice_Odd1			),
		.I_Index(			IDec_Index_Odd1			),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
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
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
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
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
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
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_LaneID(			I_LaneID				),
		.I_ThreadID_SIMT(	I_ThreadID_SIMT			),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.O_Req(										),
		.O_Slice(			Index_Slice_Even2		),
		.O_Index(			Index_Even2				)
	);

	pipereg PReg_Index (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			),
		.I_Op(				Pipe_OP_Index			),
		.O_Op(				Pipe_OP_RFile			)
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
		.I_Index_Src1(		Index_Odd1				),
		.I_Index_Src2(		Index_Odd2				),
		.O_Data_Src1(		O_Rotate_Src_Data1		),
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
		.O_Data_Src1(		O_Rotate_Src_Data2		),
		.O_Data_Src2(		Pre_Src_Data4			),
		.O_Req(										)
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
	network v_network (
		.I_Config_Path(		Config_Path				),
		.I_WB_Path1(		WB_Path1				),
		.I_WB_Path2(		WB_Path2				),
		.I_Path_Hop(		I_Path_Hop				),
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
		.O_WB_We1(			We_RegFile_Odd			),
		.O_WB_We2(			We_RegFile_Even			),
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