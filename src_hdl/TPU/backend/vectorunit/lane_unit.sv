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
	input	id_t				I_ThreadID,				//SIMT Thread-ID
	input	instr_t				I_Command,				//Execution Command
	input	data_t				I_Scalar_Data,			//Scalar Data from Scalar Unit ToDo
	output	data_t				O_Scalar_Data,			//Scalar Data to Scalar Unit ToDo
	output	s_ldst_t			O_LdSt1,				//Load/Store Command
	output	s_ldst_t			O_LdSt2,				//Load/Store Command
	input	s_ldst_data_t		I_Ld_Data,				//Loaded Data
	output	s_ldst_data_t		O_St_Data,				//Storing Data
	input	[1:0]				I_Ld_Ready,				//Flag: Ready
	input	[1:0]				I_Ld_Grant,				//Flag: Grant
	input	[1:0]				I_St_Ready,				//Flag: Ready
	input	[1:0]				I_St_Grant,				//Flag: Grant
	input						I_End_Access1,			//Flag: End of Access
	input						I_End_Access2,			//Flag: End of Access
	output						O_Commit,				//Commit Request
	input	lane_t				I_Lane_Data_Src1,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src2,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src3,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_WB,			//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src1,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src2,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src3,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_WB,			//Inter-Lane Connect
	output						O_Status				//Lane Status
);


	idx_t						Index_Src1;
	idx_t						Index_Src2;
	idx_t						Index_Src3;

	data_t						RF_Odd_Data1;
	data_t						RF_Odd_Data2;
	data_t						RF_Even_Data1;
	data_t						RF_Even_Data2;


	logic						Re_p0;
	logic						Re_p1;


	logic						Dst_Slice;
	logic	[6:0]				Dst_Sel;
	index_t						Dst_Index;
	index_t						Dst_Index_Window;
	index_t						Dst_Index_Length;
	logic						Dst_RegFile_Req;
	logic						Dst_RegFile_Slice;
	index_t						Dst_RegFile_Index;
	logic						Dst_Done;

	logic						Sign;
	const_t						Constant;
	logic						Slice_Dst;
	logic						Stall_RegFile_Odd;
	logic						Stall_RegFile_Even;
	logic						Stall_Network;
	logic						Stall_ExecUnit;

	logic						Ld_Stall;
	logic						St_Stall;


	state_t						Status;


	index_t						Src_Idx1;
	index_t						Src_Idx2;
	index_t						Src_Idx3;

	mask_t						Mask_Data;

	logic	[12:0]				Config_Path;
	logic	[4:0]				Config_Path_WB;


	logic						Sel_Dst;
	logic						is_WB_RF;
	logic						is_WB_BR;
	logic						is_WB_VU;
	pipe_exe_tmp_t				WB_Token;
	data_t						WB_Data;
	logic						WB_Req_Even;
	logic						WB_Req_Odd;
	logic						WB_We_Even;
	logic						WB_We_Odd;
	index_t						WB_Index_Even;
	index_t						WB_Index_Odd;
	data_t						WB_Data_Even;
	data_t						WB_Data_Odd;
	issue_no_t					WB_IssueNo;

	logic						MaskReg_Ready;
	logic						MaskReg_Term;
	logic						MaskReg_We;
	logic						MaskReg_Re;


	logic						LdSt_Done1;
	logic						LdSt_Done2;


	logic						En;
	logic						Lane_Enable;
	logic						Lane_CTRL_Rst;
	logic						Lane_CTRL_Set;

	logic						Stall_Index_Calc;
	logic						Stall_RegFile_Dst;
	logic						Stall_RegFile_Odd;
	logic						Stall_RegFile_Even;
	logic						Stall_Network;
	logic						Stall_ExecUnit;


	logic						Req_Issue;

	pipe_index_t				PipeReg_Idx;
	pipe_index_t				PipeReg_Index;
	pipe_index_reg_t			PipeReg_IdxRF;
	pipe_index_reg_t			PipeReg_IdxRR;
	pipe_reg_t					PipeReg_RR;
	pipe_net_t					PipeReg_Set_Net;
	pipe_net_t					PipeReg_RR_Net;
	pipe_exe_t					PipeReg_Net;
	pipe_exe_t					PipeReg_Exe;


	//// Lane-Enable
	Lane_En_V Lane_En_V (
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				I_En					),
		.I_Rst(				Lane_CTRL_Rst			),
		.I_Set(				Lane_CTRL_Set			),
		.I_Index(			Dst_Index				),
		.I_Status(			Status					),
		.O_State(			O_Status				),
		.O_En(				Lane_Enable				)
	);


	//// Capture Command coming from Scalar unit
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_Idx		<= '0;
		end
		else begin
			//	Command
			PipeReg_Idx.v			<= I_Command.v;
			PipeReg_Idx.op			<= I_Command.instr.op;

			//	Write-Back
			PipeReg_Idx.dst			<= I_Command.instr.dst;

			//	Indeces
			PipeReg_Idx.slice_len	<= I_Command.instr.slice_len;

			PipeReg_Idx.src1		<= I_Command.instr.src1;
			PipeReg_Idx.src2		<= I_Command.instr.src2;
			PipeReg_Idx.src3		<= I_Command.instr.src3;

			//	Path
			PipeReg_Idx.path		<= I_Command.instr.path;
			PipeReg_Idx.mread		<= I_Command.instr.mread;

			PipeReg_Idx.en_ii		<= I_Command.instr.en_ii;
		end
	end


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
	assign PipeReg_Set_Net.v		= PipeReg_RR.v;
	assign PipeReg_Set_Net.op		= PipeReg_RR.op;

	//	Write-Back
	assign PipeReg_Set_Net.dst		= PipeReg_RR.dst;



	//	Read Data
	assign PipeReg_Set_Net.src1.v		= ( PipeReg_RR.src1.v ) ?	PipeReg_RR.src1.v :
																	'0;
	assign PipeReg_Set_Net.src1.idx		= ( PipeReg_RR.src1.v ) ?	PipeReg_RR.src1.idx :
																	'0;
	assign PipeReg_Set_Net.src1.src_sel	= ( PipeReg_RR.src1.v ) ?	PipeReg_RR.src1.src_sel :
																	'0;
	assign PipeReg_Set_Net.src1.data	= ( RegMov_Rd ) ? 			R_Scalar_Data :
											( PipeReg_RR.src1.v ) ?	PipeReg_RR.src1.data :
																	'0;

	assign PipeReg_Set_Net.src2.v		= ( PipeReg_RR.src2.v ) ?	PipeReg_RR.src2.v :
																	'0;
	assign PipeReg_Set_Net.src2.idx		= ( PipeReg_RR.src2.v ) ?	PipeReg_RR.src2.idx :
																	'0;
	assign PipeReg_Set_Net.src2.src_sel	= ( PipeReg_RR.src2.v ) ?	PipeReg_RR.src2.src_sel :
																	'0;

	assign PipeReg_Set_Net.src3.v		= ( PipeReg_RR.src3.v ) ?	PipeReg_RR.src3.v :
																	'0;
	assign PipeReg_Set_Net.src3.idx		= ( PipeReg_RR.src3.v ) ?	PipeReg_RR.src3.idx :
																	'0;
	assign PipeReg_Set_Net.src3.src_sel	= ( PipeReg_RR.src3.v ) ?	PipeReg_RR.src3.src_sel :
																	'0;

	//	Slice Length
	assign PipeReg_Set_Net.slice_len= PipeReg_RR.slice_len;

	//	Issue-No
	assign PipeReg_Set_Net.issue_no	= PipeReg_RR.issue_no;

	//	Path
	assign PipeReg_Set_Net.path		= PipeReg_RR.path;


	//// Network
	assign Config_Path			= PipeReg_RR_Net.path[12:0];

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
	assign Dst_Sel				= WB_Token.dst_sel.unit_no;
	assign Dst_Slice			= WB_Token.slice;
	assign Dst_Index			= WB_Token.idx;
	assign Dst_Index_Window		= WB_Token.window;
	assign Dst_Index_Length		= WB_Token.slice_len;

	//  Network Path
	assign Config_Path_WB		= WB_Token.path;

	//	Write-Back Target Decision
	assign is_WB_RF				= WB_Token.dst_sel == 2'h1;
	assign is_WB_BR				= WB_Token.dst_sel == 2'h2;
	assign is_WB_VU				= WB_Token.dst_sel == 2'h3;

	assign Sel_Dst				= WB_Token.idx[WIDTH_INDEX+2];
	assign WB_Req_Even			= ~Sel_Dst & WB_Token.v & is_WB_RF & ~Stall_RegFile_Even & ~R_Re_c;
	assign WB_Req_Odd			=  Sel_Dst & WB_Token.v & is_WB_RF & ~Stall_RegFile_Odd  & ~R_Re_c;
	assign WB_We_Even			= ~Sel_Dst & WB_Token.v & is_WB_RF & ~Stall_RegFile_Dst  & ~We_c;
	assign WB_We_Odd			=  Sel_Dst & WB_Token.v & is_WB_RF & ~Stall_RegFile_Dst  & ~We_c;
	assign WB_Index_Even		= ( ~Sel_Dst ) ? WB_Token.idx :	'0;
	assign WB_Index_Odd			= (  Sel_Dst ) ? WB_Token.idx :	'0;
	assign WB_Data_Even			= ( ~Sel_Dst ) ? W_WB_Data :	'0;
	assign WB_Data_Odd			= (  Sel_Dst ) ? W_WB_Data :	'0;

	assign We_c					= WB_Token.v & ( WB_Token.instr.op.OpType == 2'b00 ) &
									( WB_Token.instr.op.OpClass == 2'b11 ) &
									( WB_Token.instr.op.OpCode == 2'b11 );

	assign Config_Path_W		= WB_Token.path;

	//	Write-Back to Mask Register
	assign MaskReg_Ready		= ( PipeReg_Idx.op.OpType == 2'b01 ) &
									( PipeReg_Idx.op.OpClass == 2'b10 ) &
									( PipeReg_Idx.op.OpCode[1] == 1'b1 );
	assign MaskReg_Term			= Dst_Done;
	assign MaskReg_We			= WB_Token.v & is_WB_BR;
	assign MaskReg_Re			= (   PipeReg_RR.src1.src_sel.no == 2'h2 ) |
									( PipeReg_RR.src2.src_sel.no == 2'h2 ) |
									( PipeReg_RR.src3.src_sel.no == 2'h2 );


	//// Reg Move
	assign RegMov_Rd			= ( PipeReg_Idx.op.OPType == 2'b00 ) &
									( PipeReg_Idx.op.OPClass == 2'b11 ) &
									( PipeReg_Idx.op.OPCode == 2'b10 );

	assign RegMov_Wt			= ( PipeReg_Idx.op.OPType == 2'b00 ) &
									( PipeReg_Idx.op.OPClass == 2'b11 ) &
									( PipeReg_Idx.op.OPCode == 2'b11 );


	assign Cond_Data			= ( is_WB_BR ) ? W_WB_Data : '0;


	//// Commit Request
	assign O_Commit				= LdSt_Done1 | LdSt_Done2 | Math_Done;


	//// Stall Control
	assign Stall_Index_Calc		= ~Lane_Enable | St_Stall;
	assign Stall_RegFile_Dst	= ~Lane_Enable | Ld_Stall;
	assign Stall_RegFile_Odd	= ~Lane_Enable | St_Stall;
	assign Stall_RegFile_Even	= ~Lane_Enable | St_Stall;
	assign Stall_Network		= ~Lane_Enable;
	assign Stall_ExecUnit		= ~Lane_Enable;


	//// Index Update Stage
	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index_Dst
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_RegFile_Dst		),
		.I_Req(				Req_Index_Dst			),
		.I_En_II(			0						),
		.I_MaskedRead(		PipeReg_Idx.mread		),
		.I_Index(			Dst_Index				),
		.I_Window(			Dst_Index_Window		),
		.I_Length(			Dst_Index_Length		),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Dst_RegFile_Index		),
		.O_Done(			Dst_Done				)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index1
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				PipeReg_Idx.src1.v		),
		.I_En_II(			PipeReg_Idx.en_ii		),
		.I_MaskedRead(		PipeReg_Idx.mread		),
		.I_Index(			PipeReg_Idx.src1		),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src1				),
		.O_Done(									)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index2
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				PipeReg_Idx.src2.v		),
		.I_En_II(			PipeReg_Idx.en_ii		),
		.I_MaskedRead(		PipeReg_Idx.mread		),
		.I_Index(			PipeReg_Idx.src2		),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src2				),
		.O_Done(									)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index3
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				PipeReg_Idx.src3.v		),
		.I_En_II(			PipeReg_Idx.en_ii		),
		.I_MaskedRead(		PipeReg_Idx.mread		),
		.I_Index(			PipeReg_Idx.src3		),
		.I_Window(			IDec_Index_Window		),
		.I_Length(			IDec_Index_Length		),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant				),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src3				),
		.O_Done(									)
	);


	RF_Index_Sel RF_Index_Sel (
		.I_Odd1(			PipeReg_Index.src1.v	),
		.I_Odd2(			PipeReg_Index.src2.v	),
		.I_Odd3(			PipeReg_Index.src3.v	),
		.I_Index_Src1(		Index_Src1				),
		.I_Index_Src2(		Index_Src2				),
		.I_Index_Src3(		Index_Src3				),
		.O_Index_Src1(		PipeReg_IdxRF.src1		),
		.O_Index_Src2(		PipeReg_IdxRF.src2		),
		.O_Index_Src3(		PipeReg_IdxRF.src3		),
		.O_Index_Src4(		PipeReg_IdxRF.src4		),
		.O_Done(									)
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


	AuxRegs AuxRegs (
		.clock(				clock					),
		.reset(				reset					),
		.I_ThreadID(		I_ThreadID				),
		.I_Stall(			Stall_Index_Calc		),
		.I_Re(				RegMov_Rd				),
		.I_We(				RegMov_Wt				),
		.I_Src_Command(		PipeReg_IdxRR			),
		.I_Dst_Command(		WB_Token				),
		.O_Re_p0(			Re_p0					),
		.O_Re_p1(			Re_p1					),
		.O_Re_c(			Re_c					),
		.I_Data(			W_WB_Data				),
		.O_Data(			R_Scalar_Data			),
		.I_SWe(				),//ToDo
		.I_Scalar_Data(		I_Scalar_Data			),
		.O_Scalar_Data(		O_Scalar_Data			),
	);


	logic	[2:0]			Sel;
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Sel				<= '0;
		end
		else begin
			Sel				<= { PipeReg_Index.src3.v, PipeReg_Index.src2.v, PipeReg_Index.src1.v };
		end
	end

	logic					R_Re_c;
	logic					We_c;
	always_ff @( poedge clock ) begin
		if ( reset ) begin
			R_Re_c			<= 1'b0;
		end
		else begin
			R_Re_c			<= Re_c;
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
		.O_Data_Src1(		Src1_Data				),
		.O_Data_Src2(		PipeReg_RR.src2.data	),
		.O_Data_Src3(		PipeReg_RR.src3.data	)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_RR_Net	<= '0;
		end
		else if ( En ) begin
			PipeReg_RR_Net	<= PipeReg_Set_Net;
		end
	end


	//// Status Register
	StatusCtrl StatusCtrl (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				WB_En					),
		.I_Diff_Data(		Diff_Data				),
		.O_Status(			Status					)
	);


	//// Mask Register
	//		I_Index: WB Dst-IndexUnit
	MaskReg MaskReg (
		.clock(				clock					),
		.reset(				reset					),
		.I_Ready(			MaskReg_Ready			),
		.I_Term(			MaskReg_Term			),
		.I_We(				MaskReg_We				),
		.I_Set_One(			Set_One					),
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
		.I_Stall(			Stall_Network			),
		.I_Req(				PipeReg_RR_Net.v		),
		.I_Sel_Path(		Config_Path				),
		.I_Sel_Path_WB(		Config_Path_WB			),
		.I_Sel_ALU_Src1(	PipeReg_RR_Net.src1.v	),
		.I_Sel_ALU_Src2(	PipeReg_RR_Net.src2.v	),
		.I_Sel_ALU_Src3(	PipeReg_RR_Net.src3.v	),
		.I_Slice_Len(		PipeReg_RR_Net.slice_len),
		.I_Lane_Data_Src1(	I_Lane_Data_Src1		),
		.I_Lane_Data_Src2(	I_Lane_Data_Src2		),
		.I_Lane_Data_Src3(	I_Lane_Data_Src3		),
		.I_Lane_Data_WB(	I_Lane_Data_WB			),
		.I_Src_Data1(	PipeReg_RR_Net.src1.data	),
		.I_Src_Data2(	PipeReg_RR_Net.src2.data	),
		.I_Src_Data3(	PipeReg_RR_Net.src3.data	),
		.I_Src_Idx1(		PipeReg_RR_Net.idx1		),
		.I_Src_Idx2(		PipeReg_RR_Net.idx2		),
		.I_Src_Idx3(		PipeReg_RR_Net.idx3		),
		.I_WB_Index(		WB_Token.idx			),
		.I_WB_Data(			WB_Data					),
		.O_Src_Data1(		PipeReg_Net.data1		),
		.O_Src_Data2(		PipeReg_Net.data2		),
		.O_Src_Data3(		PipeReg_Net.data3		),
		.O_WB_Data(			W_WB_Data				),
		.O_Lane_Data_Src1(	O_Lane_Data_Src1		),
		.O_Lane_Data_Src2(	O_Lane_Data_Src2		),
		.O_Lane_Data_Src3(	O_Lane_Data_Src3		),
		.O_Lane_Data_WB(	O_Lane_Data_WB			),
		.O_Buff_Full(		Bypass_Buff_Full		)
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
	ExecUnit_V ExecUnit_V (
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				Lane_Enable				),
		.I_Stall(			Stall_ExecUnit			),
		.I_Req(				PipeReg_Exe.v			),
		.I_Command(			PipeReg_Exe.instr		),
		.I_Src_Data1(		PipeReg_Exe.data1		),
		.I_Src_Data2(		PipeReg_Exe.data2		),
		.I_Src_Data3(		PipeReg_Exe.data3		),
		.O_LdSt1(			O_LdSt1					),
		.O_LdSt2(			O_LdSt2					),
		.I_Ld_Data1(		I_Ld_Data[0]			),
		.I_Ld_Data2(		I_Ld_Data[1]			),
		.O_St_Data1(		O_St_Data[0]			),
		.O_St_Data2(		O_St_Data[1]			),
		.I_Ld_Ready(		I_Ld_Ready				),
		.I_Ld_Grant(		I_Ld_Grant				),
		.I_St_Ready(		I_St_Ready				),
		.I_St_Grant(		I_St_Grant				),
		.I_End_Access1(		I_End_Access1			),
		.I_End_Access2(		I_End_Access2			),
		.I_Re_p0(			Re_p0					),
		.I_Re_p1(			Re_p1					),
		.O_WB_Token(		WB_Token				),
		.O_WB_Data(			WB_Data					),
		.O_Math_Done(		Math_Done				),
		.O_LdSt_Done1(		LdSt_Done1				),
		.O_LdSt_Done2(		LdSt_Done2				),
		.O_Ld_Stall(		Ld_Stall				),
		.O_St_Stall(		ST_Stall				),
		.O_Lane_En(			En						)
	);

endmodule