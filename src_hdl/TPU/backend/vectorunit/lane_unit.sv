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
	input	instr_t				I_ThreadID,				//SIMT Thread-ID
	input	command_t			I_Command,				//Execution Command
	input	data_t				I_Scalar_Data,			//Scalar Data from Scalar Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Scalar Unit
	output	ldst_t				O_LdSt,					//Load/Store Command
	input	ld_data_t			I_LdData,				//Loaded Data
	output	st_data_t			O_StData,				//Storing Data
	input	[1:0]				I_Ld_Ready,				//Flag: Ready
	input	[1:0]				I_Ld_Grant,				//Flag: Grant
	input	[1:0]				I_St_Ready,				//Flag: Ready
	input	[1:0]				I_St_Grat,				//Flag: Grant
	output	logic				O_Commit,				//Commit Request
	input	lane_t				I_Lane_Data_Src1,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src2,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src3,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src1,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src2,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src3,		//Inter-Lane Connect
	output	logic				O_Status				//Lane Status
);


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


	stat_v_t				Status;


	index_t					Src_Idx1;
	index_t					Src_Idx2;
	index_t					Src_Idx3;


	mask_t					Mask_Data;

	logic	[12:0]			Config_Path;


	logic					Dst_Sel;
	logic					is_WB_RF;
	logic					is_WB_BR;
	logic					is_WB_VU;
	index_t					WB_Index;
	data_t					WB_Data;
	logic					Math_Done;
	logic					Condition;

	logic					MaskReg_We;
	logic					MaskReg_Re;


	logic					LdSt_Done1;
	logic					LdSt_Done2;


	logic					En;
	logic					Lane_En;
	logic					Lane_CTRL_Rst;
	logic					Lane_CTRL_Set;


	logic					Req_Issue;

	pipe_index_t			PipeReg_Idx;
	pipe_index_t			PipeReg_Index;
	pipe_reg_t				PipeReg_RR;
	pipe_net_t				PipeReg_RR_Net;
	pipe_exe_t				PipeReg_Net;
	pipe_exe_t				PipeReg_Exe;


	//// Lane-Enable
	Lane_Unit Lane_Unit (
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				I_En					),
		.I_Rst(				Lane_CTRL_Rst			),
		.I_Set(				Lane_CTRL_Set			),
		.I_Index(			Dst_Index				),
		.I_Status(			Status					),
		.O_State(			O_Status				),
		.O_En(				Lane_En					)
	);


	//// Capture Command coming from Scalar unit
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_Idx		<= '0
		end
		else begin
			//	Command
			PipeReg_Idx.v			<= I_Command.instr.v;
			PipeReg_Idx.op			<= I_Command.instr.op;

			//	Write-Back
			PipeReg_Idx.dst			<= I_Command.dst;

			//	Indeces
			PipeReg_Idx.slice_len	<= I_Command.instr.slice_len;

			PipeReg_Idx.src1		<= I_Command.instr.src1;
			PipeReg_Idx.src2		<= I_Command.instr.src2;
			PipeReg_Idx.src3		<= I_Command.instr.src2;
			PipeReg_Idx.src4		<= I_Command.instr.src4;

			//	Path
			PipeReg_Idx.path		<= I_Command.instr.path;
		end
	end


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

	//	Path
	assign PipeReg_Index.path		= PipeReg_Idx.path;


	//// Register Read/Write Stage
	//	Capture Read Data
	//	Command
	assign PipeReg_RR_Net.v		= PipeReg_RR.v;
	assign PipeReg_RR_Net.op	= PipeReg_RR.op;

	//	Write-Back
	assign PipeReg_RR_Net.dst	= PipeReg_RR.dst;

	//	Read Data
	assign V_State_Data.v			= 1'b1;
	assign V_State_Data.idx			= '0;
	assign V_State_Data.data		= Mask_Data;
	assign V_State_Data.src_sel		= '0;

	assign PipeReg_RR_Net.src1		= ( PipeReg_RR.src2.src_sel.no == 2'3 ) ?	V_State_Data :
																				PipeReg_RR.src1;

	assign PipeReg_RR_Net.src2		= ( PipeReg_RR.src2.src_sel.no == 2'3 ) ?	V_State_Data :
										( PipeReg_RR.src2.v ) ?					PipeReg_RR.src2 :
										( PipeReg_RR.src3.v ) ?					PipeReg_RR.src3 :
																				'0;

	assign PipeReg_RR_Net.src3		= ( PipeReg_RR.src4.src_sel.no == 2'3 ) ?	V_State_Data :
																				PipeReg_RR.src4;

	//	Issue-No
	assign PipeReg_RR_Net.issue_no	= PipeReg_RR.issue_no;

	//	Path
	assign PipeReg_RR_Net.path		= PipeReg_RR.path;


	//// Network
	assign Config_Path		= PipeReg_RR_Net.path;

	//	Capture Data
	assign PipeReg_Net.v	= PipeReg_RR_Net.v;
	assign PipeReg_Net.op	= PipeReg_RR_Net.op;

	//	Write-Back
	assign PipeReg_Net.dst	= PipeReg_RR_Net.dst;

	//	Issue-No
	assign PipeReg_Net.issue_no	= PipeReg_RR_Net.issue_no;


	//// Write-Back
	assign Dst_Sel			= B_Index.dst_sel.unit_no;
	assign Dst_Slice		= WB_Index.slice
	assign Dst_Index		= WB_Index.idx
	assign Dst_Index_Window	= WB_Index.window
	assign Dst_Index_Length	= WB_Index.slice_len

	//	Write-Back Target Decision
	assign is_WB_RF			= WB_Index.dst_sel == 2'h1;
	assign is_WB_BR			= WB_Index.dst_sel == 2'h2;
	assign is_WB_VU			= WB_Index.dst_sel == 2'h3;

	assign WB_Req_Even		= ~Dst_Sel & WB_Index.v & is_WB_RF;
	assign WB_Req_Odd		=  Dst_Sel & WB_Index.v & is_WB_RF;
	assign WB_We_Even		= ~Dst_Sel & WB_Index.v & is_WB_RF;
	assign WB_We_Odd		=  Dst_Sel & WB_Index.v & is_WB_RF;
	assign WB_Index_Even	= ( ~Dst_Sel ) ? WB_Index.idx : '0;
	assign WB_Index_Odd		= (  Dst_Sel ) ? WB_Index.idx : '0;
	assign WB_Data_Even		= ( ~Dst_Sel ) ? WB_Data : 		'0;
	assign WB_Data_Odd		= (  Dst_Sel ) ? WB_Data : 		'0;

	//	Write-Back to Mask Register
	assign MaskReg_We		= WB_Index.v & is_WB_BR;
	assign Cond_Data		= ( is_WB_BR ) ? WB_Data : '0;
	assign MaskReg_Re		= ( PipeReg_RR.src1.src_sel.no == 2'h2 ) |
								( PipeReg_RR.src2.src_sel.no == 2'h2 ) |
								( PipeReg_RR.src3.src_sel.no == 2'h2 ) |
								( PipeReg_RR.src4.src_sel.no == 2'h2 );


	//// Commit Request
	assign O_Commit			= LdSt_Done1 | LdSt_Done2 | Math_Done;


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
	) Index_Odd1
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
		.O_Index(			PipeReg_Index.src1.idx	)
	);

	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index_Odd2
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
		.O_Index(			PipeReg_Index.src2.idx	)
	);

	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index_Even1
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
		.O_Index(			PipeReg_Index.src3.idx	)
	);

	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index_Even2
	(
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
		else if ( En) begin
			PipeReg_Idx_RR	<= PipeReg_Index;
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
		.I_Index_Src1(		PipeReg_Idx_RR.src1		),
		.I_Index_Src2(		PipeReg_Idx_RR.src2		),
		.O_Data_Src1(		PipeReg_RR.src1.data	),
		.O_Data_Src2(		PipeReg_RR.src2.data	)
	);

	RegFile RegFile_Even (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_Req_Even				),
		.I_We(				WB_We_Even				),
		.I_Index_Dst(		WB_Index_Even			),
		.I_Data(			WB_Data_Even			),
		.I_Index_Src1(		PipeReg_Idx_RR.src3		),
		.I_Index_Src2(		PipeReg_Idx_RR.src4		),
		.O_Data_Src1(		PipeReg_RR.src3.data	),
		.O_Data_Src2(		PipeReg_RR.src4.data	)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_RR_Net	<= '0;
		end
		else if ( En ) begin
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


	//// Mask Register
	//		I_Index: WB Dst-IndexUnit
	MaskReg MaskReg (
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				MaskReg_We				),
		.I_Index(			Dst_Index				),
		.I_Cond(			Cond_Data				),
		.I_Status(			Status					),
		.I_Re(				MaskReg_Re				),
		.O_Mask_Data(		Mask_Data				)
	);


	//// Network Stage
	Network_V #(
		.NUM_LANES(			NUM_LANES				),
		.LANE_ID(			LANE_ID					)
	) Network_V
	(
		.I_Req(				PipeReg_RR_Net.v		),
		.I_Sel_Path(		Config_Path				),
		.I_Sel_ALU_Src1(	PipeReg_RR_Net.src1.v	),
		.I_Sel_ALU_Src2(	PipeReg_RR_Net.src2.v	),
		.I_Sel_ALU_Src3(	PipeReg_RR_Net.src3.v	),
		.I_Lane_Data_Src1(	I_Lane_Data_Src1		),
		.I_Lane_Data_Src2(	I_Lane_Data_Src2		),
		.I_Lane_Data_Src3(	I_Lane_Data_Src3		),
		.I_Src_Data1(		PipeReg_RR_Net.data1	),
		.I_Src_Data2(		PipeReg_RR_Net.data2	),
		.I_Src_Data3(		PipeReg_RR_Net.data3	),
		.I_Src_Idx1(		PipeReg_RR_Net.idx1		),
		.I_Src_Idx2(		PipeReg_RR_Net.idx2		),
		.I_Src_Idx3(		PipeReg_RR_Net.idx3		),
		.I_WB_DstIdx(		WB_Index				),
		.I_WB_Data(			WB_Data					),
		.O_Src_Data1(		PipeReg_Net.data1		),
		.O_Src_Data2(		PipeReg_Net.data2		),
		.O_Src_Data3(		PipeReg_Net.data3		),
		.O_Lane_Data_Src1(	O_Lane_Data_Src1		),
		.O_Lane_Data_Src2(	O_Lane_Data_Src2		),
		.O_Lane_Data_Src3(	O_Lane_Data_Src3		)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_Exe		<= '0;
		end
		else if ( En ) begin
			PipeReg_Exe		<= PipeReg_Net;
		end
	end


	//// Execution Stage
	//	 Math Unit
	VMathUnit VMathUnit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Lane_En(			Lane_En					),
		.I_Stall(			Stall					),
		.I_CEn1(			CEn1					),
		.I_CEn2(			CEn2					),
		.I_Req(				PipeReg_Exe.v			),
		.I_Command(			PipeReg_Exe.op			),
		.I_WB_Dst(			PipeReg_Exe.dst			),
		.I_Src_Src_Data1(	PipeReg_Exe.data1		),
		.I_Src_Src_Data2(	PipeReg_Exe.data2		),
		.I_Src_Src_Data3(	PipeReg_Exe.data3		),
		.O_LdSt1(			O_LdSt1					),
		.O_LdSt2(			O_LdSt2					),
		.I_LdData1(			I_LdData1				),
		.I_LdData2(			I_LdData2				),
		.O_StData1(			O_StData1				),
		.O_StData2(			O_StData2				),
		.I_Ld_Ready(		I_Ld_Ready				),
		.I_Ld_Grant(		I_Ld_Grant				),
		.I_St_Ready(		I_St_Ready				),
		.I_St_Grant(		I_St_Grant				),
		.O_WB_Index(		WB_Index				),
		.O_WB_Data(			WB_Data					),
		.O_Math_Done(		Math_Done				),
		.O_LdSt_Done1(		LdSt_Done1				),
		.O_LdSt_Done2(		LdSt_Done2				),
		.O_Cond(			Condition				),
		.O_Lane_En(			En						)
	);

endmodule