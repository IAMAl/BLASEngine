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
import pkg_tpu::instr_t;
import pkg_mpu::*;
#(
	parameter int NUM_LANES		= 16,
	parameter int WIDTH_LANES	= $clog2(NUM_LANES),
	parameter int LANE_ID		= 0
)(
	input						clock,
	input						reset,
	input						I_Commit_Grant,			//Grant for Commit
	input						I_En_Lane,				//Enable Execution
	input	id_t				I_ThreadID,				//SIMT Thread-ID
	input	pipe_index_t		I_Command,				//Execution Command
	input	data_t				I_Scalar_Data,			//Scalar Data from Scalar Unit
	output	data_t				O_Scalar_Data,			//Scalar Data to Scalar Unit
	output	s_ldst_t			O_LdSt,					//Load/Store Command
	input	s_ldst_data_t		I_Ld_Data,				//Loaded Data
	output	s_ldst_data_t		O_St_Data,				//Storing Data
	input	tb_t				I_Ld_Ready,				//Flag: Ready
	input	tb_t				I_Ld_Grant,				//Flag: Grant
	input	tb_t				I_St_Ready,				//Flag: Ready
	input	tb_t				I_St_Grant,				//Flag: Grant
	input						I_End_Access1,			//Flag: End of Access
	input						I_End_Access2,			//Flag: End of Access
	input	lane_t				I_Lane_Data_Src1,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src2,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_Src3,		//Inter-Lane Connect
	input	lane_t				I_Lane_Data_WB,			//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src1,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src2,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_Src3,		//Inter-Lane Connect
	output	data_t				O_Lane_Data_WB,			//Inter-Lane Connect
	output						O_Status,				//Lane Status
	output						O_Commit				//Commit Request
);


	idx_t						Index_Src1;
	idx_t						Index_Src2;
	idx_t						Index_Src3;

	logic						Index_Src1_Busy;
	logic						Index_Src2_Busy;
	logic						Index_Src3_Busy;

	data_t						RF_Odd_Data1;
	data_t						RF_Odd_Data2;
	data_t						RF_Even_Data1;
	data_t						RF_Even_Data2;

	logic						RegMov_Wt;
	logic						RegMov_Rd;

	logic						Re_p0;
	logic						Re_p1;


	logic						Req_Index_Dst;
	logic						Dst_Slice;
	logic						Dst_Index_MRead;
	logic	[6:0]				Dst_Sel;
	idx_t						Dst_Index;
	index_t						Dst_Index_Window;
	index_t						Dst_Index_Length;
	logic						Dst_RegFile_Req;
	logic						Dst_RegFile_Slice;
	idx_t						Dst_RegFile_Index;
	logic						Dst_Busy;
	logic						Dst_Done;


	data_t						R_Scalar_Data;

	mask_t						Mask_Data;


	logic						Sign;
	logic						Sign1;
	logic						Sign2;
	logic						Sign3;
	const_t						Constant;


	logic						Bypass_Buff_Full;


	logic						is_WB_RF;
	logic						is_WB_BR;
	logic						is_WB_VU;
	logic						WB_En;
	pipe_exe_tmp_t				WB_Token;
	data_t						WB_Data;
	data_t						WB_Data_;
	logic						WB_Req_Even;
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


	logic	[6:0]				Config_Path;
	logic	[4:0]				Config_Path_WB;
	logic						Math_Done;


	logic						LdSt_Done1;
	logic						LdSt_Done2;

	logic						Ld_Stall;
	logic						St_Stall;

	logic						Stall_Index_Calc;
	logic						Stall_RegFile_Odd;
	logic						Stall_RegFile_Even;
	logic						Stall_Network;
	logic						Stall_ExecUnit;
	logic						Stall_RegFile_Dst;

	state_t						Status;


	logic						Slice;


	logic						En;
	logic						Lane_Enable;
	logic						Lane_CTRL_Rst;
	logic						Lane_CTRL_Set;

	logic						Req_Even;
	logic						Req_Odd;
	
	logic						We_c;
	logic						Re_c;

	logic						R_Re_c;
	logic	[1:0]				Cond_Data;

	logic						Set_One;


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
	assign Lane_CTRL_Rst		= ( PipeReg_Exe.command.instr.op.OpType == 2'b01 ) &
									( PipeReg_Exe.command.instr.op.OpClass == 2'b10 ) &
									( PipeReg_Exe.command.instr.op.OpCode == 2'b01 );
	assign Lane_CTRL_Set		= ( PipeReg_Exe.command.instr.op.OpType == 2'b01 ) &
									( PipeReg_Exe.command.instr.op.OpClass == 2'b10 ) &
									( PipeReg_Exe.command.instr.op.OpCode == 2'b00 );
	Lane_En_V Lane_En_V (
		.clock(				clock					),
		.reset(				reset					),
		.I_En(				I_En_Lane				),
		.I_Rst(				Lane_CTRL_Rst			),
		.I_Set(				Lane_CTRL_Set			),
		.I_Index(			Dst_Index.idx			),
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
			PipeReg_Idx.command		<= I_Command.command;
		end
	end


	//// Index Update Stage
	//	Command
	assign PipeReg_Index.v			= PipeReg_Idx.v;
	assign PipeReg_Index.command	= PipeReg_Idx.command;


	//// Packing for Register File Access
	assign PipeReg_IdxRF.v			= PipeReg_Idx.v;
	assign PipeReg_IdxRF.command	= PipeReg_Idx.command;


	assign Sign1					= PipeReg_Idx.command.instr.src1.s;
	assign Sign2					= PipeReg_Idx.command.instr.src2.s;
	assign Sign3					= PipeReg_Idx.command.instr.src3.s;
	assign Constant					= PipeReg_Idx.command.instr.imm;


	//// Register Read/Write Stage
	//	Command
	assign PipeReg_RR.v				= PipeReg_IdxRR.v;
	assign PipeReg_RR.command		= PipeReg_IdxRR.command;

	//	Capture Read Data
	//	Command
	assign PipeReg_Set_Net.v		= PipeReg_RR.v;
	assign PipeReg_Set_Net.command	= PipeReg_RR.command;

	assign PipeReg_Set_Net.data1	= ( RegMov_Rd ) ?							R_Scalar_Data :
										( PipeReg_RR.command.instr.src1.v ) ?	PipeReg_RR.data1 :
																				'0;

	assign PipeReg_Set_Net.data2	= ( PipeReg_RR.command.instr.src2.v ) ?		PipeReg_RR.data2 :
																				'0;

	assign PipeReg_Set_Net.data3	= ( PipeReg_RR.command.instr.src3.v ) ?		PipeReg_RR.data3 :
																				'0;

	//	Read-Enable
	assign Req_Even					= ( ( ~PipeReg_RR.command.instr.src1.src_sel.unit_no & PipeReg_RR.command.instr.src1.v ) |
										( ~PipeReg_RR.command.instr.src2.src_sel.unit_no & PipeReg_RR.command.instr.src2.v ) |
										( ~PipeReg_RR.command.instr.src3.src_sel.unit_no & PipeReg_RR.command.instr.src3.v ) ) & ~Re_c;
	assign Req_Odd					= ( (  PipeReg_RR.command.instr.src1.src_sel.unit_no & PipeReg_RR.command.instr.src1.v ) |
										(  PipeReg_RR.command.instr.src2.src_sel.unit_no & PipeReg_RR.command.instr.src2.v ) |
										(  PipeReg_RR.command.instr.src3.src_sel.unit_no & PipeReg_RR.command.instr.src3.v ) ) & ~Re_c;


	//// Network
	assign Config_Path			= PipeReg_RR_Net.command.instr.path[6:0];

	//	Capture Data
	assign PipeReg_Net.v		= PipeReg_RR_Net.v;
	assign PipeReg_Net.command	= PipeReg_RR_Net.command;


	//// Write-Back
	//  Network Path
	assign Config_Path_WB		= WB_Token.path;

	assign Req_Index_Dst		= is_WB_RF & WB_Token.v;

	assign Dst_Sel				= WB_Token.dst.dst_sel.unit_no;
	assign Dst_Slice			= WB_Token.dst.slice;
	assign Dst_Index.v			= WB_Token.dst.v;
	assign Dst_Index.slice		= WB_Token.dst.slice;
	assign Dst_Index.idx		= WB_Token.dst.idx;
	assign Dst_Index.sel		= WB_Token.dst.sel;
	assign Dst_Index.src_sel	= WB_Token.dst.dst_sel;
	assign Dst_Index.window		= WB_Token.dst.window;
	assign Dst_Index.s			= WB_Token.dst.s;
	assign Dst_Index_Window		= WB_Token.dst.window;
	assign Dst_Index_Length		= WB_Token.dst.slice_len;
	assign Dst_Index_MRead		= WB_Token.mread;

	assign Sign					= WB_Token.dst.s;

	//	Write-Back Target Decision
	assign is_WB_RF				= WB_Token.dst.dst_sel.no == 2'h1;
	assign is_WB_BR				= WB_Token.dst.dst_sel.no == 2'h2;
	assign is_WB_VU				= WB_Token.dst.dst_sel.no == 2'h3;

	assign WB_We_Even			= ~Dst_Sel & WB_Token.v & is_WB_RF & ~Stall_RegFile_Dst & ~We_c;
	assign WB_We_Odd			=  Dst_Sel & WB_Token.v & is_WB_RF & ~Stall_RegFile_Dst & ~We_c;
	assign WB_Index_Even		= ( ~Dst_Sel ) ? Dst_RegFile_Index.idx :'0;
	assign WB_Index_Odd			= (  Dst_Sel ) ? Dst_RegFile_Index.idx :'0;
	assign WB_Data_Even			= ( ~Dst_Sel ) ? WB_Data_ :				'0;
	assign WB_Data_Odd			= (  Dst_Sel ) ? WB_Data_ :				'0;

	assign We_c					= WB_Token.v & ( WB_Token.op.OpType == 2'b00 ) &
									( WB_Token.op.OpClass == 2'b11 ) &
									( WB_Token.op.OpCode == 2'b11 );

	assign Cond_Data			= ( is_WB_BR ) ? WB_Token.op.OpCode : '0;


	assign Set_One				= is_WB_BR &
									( WB_Token.op.OpType == 2'b01 ) &
									( WB_Token.op.OpClass == 2'b11 ) &
									( WB_Token.op.OpCode == 2'b00 );

	//	Write-Back to Mask Register
	assign WB_En				= WB_Token.v & is_WB_BR;
	assign MaskReg_Ready		= ( PipeReg_Idx.command.instr.op.OpType == 2'b01 ) &
									( PipeReg_Idx.command.instr.op.OpClass == 2'b10 ) &
									( PipeReg_Idx.command.instr.op.OpCode[1] == 1'b1 );
	assign MaskReg_Term			= Dst_Done;
	assign MaskReg_We			= WB_Token.v & is_WB_BR;
	assign MaskReg_Re			= (   PipeReg_RR.command.instr.src1.src_sel.no == 2'h2 ) |
									( PipeReg_RR.command.instr.src2.src_sel.no == 2'h2 ) |
									( PipeReg_RR.command.instr.src3.src_sel.no == 2'h2 );


	//// Reg Move
	assign RegMov_Rd			= ( PipeReg_Idx.command.instr.op.OpType == 2'b00 ) &
									( PipeReg_Idx.command.instr.op.OpClass == 2'b11 ) &
									( PipeReg_Idx.command.instr.op.OpCode == 2'b10 );

	assign RegMov_Wt			= ( PipeReg_Idx.command.instr.op.OpType == 2'b00 ) &
									( PipeReg_Idx.command.instr.op.OpClass == 2'b11 ) &
									( PipeReg_Idx.command.instr.op.OpCode == 2'b11 );


	//// Commit Request
	assign O_Commit				= LdSt_Done1 | LdSt_Done2 | Math_Done;


	//// Stall Control
	assign Slice				= Index_Src1_Busy | Index_Src2_Busy | Index_Src3_Busy;
	assign Stall_Index_Calc		= ~Lane_Enable | St_Stall | Bypass_Buff_Full;
	assign Stall_RegFile_Dst	= ~Lane_Enable | Ld_Stall;
	assign Stall_RegFile_Odd	= ~Lane_Enable | St_Stall;
	assign Stall_RegFile_Even	= ~Lane_Enable | St_Stall;
	assign Stall_Network		= ~Lane_Enable;
	assign Stall_ExecUnit		= ~Lane_Enable;


	assign En					= ~( Stall_RegFile_Dst | Stall_RegFile_Odd | Stall_RegFile_Even | Stall_Network );


	//// Index Update Stage
	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index_Dst
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			0&Stall_RegFile_Dst		),
		.I_Req(				1|Req_Index_Dst			),
		.I_En_II(			'0						),
		.I_MaskedRead(		Dst_Index_MRead			),
		.I_Index(			Dst_Index				),
		.I_Window(			Dst_Index_Window		),
		.I_Length(			Dst_Index_Length		),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Dst_RegFile_Index		),
		.O_Busy(									),
		.O_Done(			Dst_Done				)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index1
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				PipeReg_Idx.command.instr.src1.v		),
		.I_En_II(			PipeReg_Idx.command.instr.en_ii		),
		.I_MaskedRead(		PipeReg_Idx.command.instr.mread		),
		.I_Index(			PipeReg_Idx.command.instr.src1		),
		.I_Window(			PipeReg_Idx.command.instr.src1.window	),
		.I_Length(			PipeReg_Idx.command.instr.slice_len	),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign1					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src1				),
		.O_Busy(			Index_Src1_Busy			),
		.O_Done(									)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index2
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				PipeReg_Idx.command.instr.src2.v		),
		.I_En_II(			PipeReg_Idx.command.instr.en_ii		),
		.I_MaskedRead(		PipeReg_Idx.command.instr.mread		),
		.I_Index(			PipeReg_Idx.command.instr.src2		),
		.I_Window(			PipeReg_Idx.command.instr.src2.window	),
		.I_Length(			PipeReg_Idx.command.instr.slice_len	),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign2					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src2				),
		.O_Busy(			Index_Src2_Busy			),
		.O_Done(									)
	);


	IndexUnit #(
		.LANE_ID(			LANE_ID					)
	) Index3
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Req(				PipeReg_Idx.command.instr.src3.v		),
		.I_En_II(			PipeReg_Idx.command.instr.en_ii		),
		.I_MaskedRead(		PipeReg_Idx.command.instr.mread		),
		.I_Index(			PipeReg_Idx.command.instr.src3		),
		.I_Window(			PipeReg_Idx.command.instr.src3.window	),
		.I_Length(			PipeReg_Idx.command.instr.slice_len	),
		.I_ThreadID(		I_ThreadID				),
		.I_Constant(		Constant[5:0]			),
		.I_Sign(			Sign3					),
		.I_Mask_Data(		Mask_Data				),
		.O_Index(			Index_Src3				),
		.O_Busy(			Index_Src3_Busy			),
		.O_Done(									)
	);


	RF_Index_Sel RF_Index_Sel (
		.I_Odd1(			PipeReg_Index.command.instr.src1.v	),
		.I_Odd2(			PipeReg_Index.command.instr.src2.v	),
		.I_Odd3(			PipeReg_Index.command.instr.src3.v	),
		.I_Index_Src1(		Index_Src1				),
		.I_Index_Src2(		Index_Src2				),
		.I_Index_Src3(		Index_Src3				),
		.O_Index_Src1(		PipeReg_IdxRF.src1		),
		.O_Index_Src2(		PipeReg_IdxRF.src2		),
		.O_Index_Src3(		PipeReg_IdxRF.src3		),
		.O_Index_Src4(		PipeReg_IdxRF.src4		)
	);

	//	Pipeline Register
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			PipeReg_IdxRR	<= '0;
		end
		else if ( I_En_Lane ) begin
			PipeReg_IdxRR	<= PipeReg_IdxRF;
		end
	end


	AuxRegs AuxRegs (
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Index_Calc		),
		.I_Re(				RegMov_Rd				),
		.I_We(				RegMov_Wt				),
		.I_Src_Command(		PipeReg_IdxRR			),
		.O_Re_p0(			Re_p0					),
		.O_Re_p1(			Re_p1					),
		.O_Re_c(			Re_c					),
		.I_Data(			WB_Data_				),
		.O_Data(			R_Scalar_Data			),
		.I_SWe(				'0						),//ToDo
		.I_Scalar_Data(		I_Scalar_Data			),
		.O_Scalar_Data(		O_Scalar_Data			)
	);


	logic	[2:0]			Sel;
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Sel				<= '0;
		end
		else begin
			Sel				<= { PipeReg_Index.command.instr.src3.v, PipeReg_Index.command.instr.src2.v, PipeReg_Index.command.instr.src1.v };
		end
	end


	//// Register Read/Write Stage
	RegFile RegFile_Odd (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Req_Odd					),
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
		.I_Req(				Req_Even				),
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
		.O_Data_Src1(		PipeReg_RR.data1		),
		.O_Data_Src2(		PipeReg_RR.data2		),
		.O_Data_Src3(		PipeReg_RR.data3		)
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
		.I_Diff_Data(		WB_Data_				),
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
		.clock(				clock					),
		.reset(				reset					),
		.I_Stall(			Stall_Network			),
		.I_Command(			PipeReg_RR_Net			),
		.I_Sel_Path(		Config_Path				),
		.I_Sel_Path_WB(		Config_Path_WB			),
		.I_Lane_Data_Src1(	I_Lane_Data_Src1		),
		.I_Lane_Data_Src2(	I_Lane_Data_Src2		),
		.I_Lane_Data_Src3(	I_Lane_Data_Src3		),
		.I_Lane_Data_WB(	I_Lane_Data_WB			),
		.I_WB_Index(		WB_Token.dst.idx		),
		.I_WB_Data(			WB_Data					),
		.O_WB_Data(			WB_Data_				),
		.O_Src_Data1(		PipeReg_Net.data1		),
		.O_Src_Data2(		PipeReg_Net.data2		),
		.O_Src_Data3(		PipeReg_Net.data3		),
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
		.I_Command(			PipeReg_Exe				),
		.I_Commit_Grant(	I_Commit_Grant			),
		.O_LdSt1(			O_LdSt[0]				),
		.O_LdSt2(			O_LdSt[1]				),
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
		.O_St_Stall(		St_Stall				)
	);

endmodule