///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
///////////////////////////////////////////////////////////////////////////////////////////////////

package pkg_tpu;

	localparam int DEPTH_PIPE_FADD		= 5;
	localparam int DEPTH_PIPE_FMLT		= 6;

	//Bit-Width for Data
	localparam int WIDTH_DATA			= 32;

	//Number of Entries in Register File
	localparam int NUM_ENTRY_REGFILE	= 64;
	localparam int WIDTH_ENTRY_REGFILE	= $clog2(NUM_ENTRY_REGFILE);

	//Register File Index
	localparam int WIDTH_INDEX 			= WIDTH_ENTRY_REGFILE;

	//Number of Entries in Hazard Check Table
	localparam int NUM_ENTRY_HAZARD		= 8;
	localparam int WIDTH_ENTRY_HAZARD	= $clog2(NUM_ENTRY_HAZARD);

	//NUmber of Active Instructions
	localparam int NUM_ACTIVE_INSTRS		= 16;
	localparam int WIDTH_ACTIVE_INSTRS	= $clog2(NUM_ACTIVE_INSTRS);

	//Bit-Width for Status Register
	localparam int WIDTH_STATE			= 4;

	//Data Memory
	localparam int SIZE_DATA_MEM		= 1024;
	localparam int WIDTH_SIZE_DMEM		= $clog2(SIZE_DATA_MEM);
	localparam int POS_MSB_DMEM_ADDR	= WIDTH_SIZE_DMEM;

	//Constant in Instruction
	localparam int WIDTH_CONSTANT		= 64-7-7*4-6-1;

	// Number of Lanes in TPU
	localparam int NUM_LANES			= 16;

	//Number of Entries in Register File
	localparam int NUM_RF_ENTRY			= 64;

	//
	localparam int NUM_ENTRY_NLZ_INDEX	= 64;

	//
	localparam int BYPASS_BUFF_SIZE		= 16;

	// Reorder Buffer Size for Scalar Unit
	localparam int NUM_ENTRY_RB_S		= 16;

	// Reorder Buffer Size for Scalar Unit
	localparam int NUM_ENTRY_RB_V		= 8;

	// Instruction Memory
	localparam int IMEM_SIZE			= 1024;
	localparam int WIDTH_IMEM			= $clog2(IMEM_SIZE);


	////Logic Types
	//	General Data Type
	typedef logic	[WIDTH_DATA-1:0]		data_t;

	typedef data_t	[NUM_LANES-1:0]			v_data_t;

	//	Constant
	typedef data_t							const_t;


	//	General Index Type
	//	Index Type for Single Register File
	typedef logic	[WIDTH_INDEX-1:0]		index_t;

	//	Address Type for Data Memory
	typedef logic	[WIDTH_SIZE_DMEM-1:0]	address_t;

	//	Status Data (cmp instr. result) Types
	typedef logic	[WIDTH_STATE-1:0]		state_t;

	//	Instruction Memory
	typedef logic	[WIDTH_IMEM-1:0]		t_address_t;

	//	Instruction Issue No
	//		Used for Commit as clearing address the Hazard Check Table
	typedef logic	[WIDTH_ENTRY_HAZARD-1:0]issue_no_t;

	//	Mask Type
	//		Used in Vector Lane
	//		One-bit flag selected from stat_v_t
	typedef logic	[NUM_ENTRY_REGFILE-1:0]	mask_t;

	//
	typedef	logic							unit_no_t;
	typedef logic	[1:0]					no_t;

	//	Interconnection Network
	typedef	data_t	[NUM_LANES-1:0]			lane_t;

	//	Data Memory Flag
	typedef	logic							s_ready_t;
	typedef	logic							s_grant_t;
	typedef	logic	[NUM_LANES-1:0]			v_ready_t;
	typedef	logic	[NUM_LANES-1:0]			v_grant_t;

	//	Lane Commit Flag
	typedef	logic	[NUM_LANES-1:0]			commit_lane_t;

	//	Width Condition (4 types)
	typedef logic	[1:0]					cond_t;


	////Instruction-Set
	//	Operation Bit-Field in Instruction
	typedef struct packed {
		logic							Sel_Unit;
		logic		[1:0]				OpType;
		logic		[1:0]				OpClass;
		logic		[1:0]				OpCode;
	} op_t;

	typedef struct packed {
		unit_no_t						unit_no;
		no_t							no;
	} sel_t;

	//		MSb differenciates Two Register Files
	//		Mid-field used for no_t in hazard unit
	typedef struct packed {
		logic							v;
		index_t							idx;
		sel_t							sel;
	} index_s_t;

	typedef struct packed {
		logic							v;
		logic							slice;
		index_t							idx;
		logic		[6:0]				sel;
		logic		[1:0]				path;
		sel_t							dst_sel;
		index_t							window;
		index_t							slice_len;
		logic							s;
	} dst_t;

	typedef struct packed {
		logic							v;
		logic							slice;
		index_t							idx;
		logic		[6:0]				sel;
		index_t							window;
		sel_t							src_sel;
		logic							s;
	} idx_t;

	typedef struct packed {
		logic							v;
		index_t							idx;
		sel_t							src_sel;
		data_t							data;
	} reg_idx_t;

	//	Constant Type
	typedef logic 	[WIDTH_CONSTANT-1:0]	imm_t;

	//	Instruction Bit Field
	typedef struct packed {
		op_t							op;
		dst_t							dst;
		idx_t							src1;
		idx_t							src2;
		idx_t							src3;
		index_t							slice_len;
		imm_t							imm;
		logic	[16:0]					path;
		logic							mread;
		logic							en_ii;
	} instruction_t;

	//	Instruction + Valid
	typedef struct packed {
		logic							v;
		instruction_t					instr;
	} instr_t;


	////Execution Steering
	//	Hazard Table used in Scalar unit
	typedef struct packed {
		logic							v;
		instruction_t					instr;
		logic							commit;
		index_s_t						dst;
		index_s_t						src1;
		index_s_t						src2;
		index_s_t						src3;
		logic							br;
	} iw_t;

	typedef struct packed {
		logic							v;
		index_t							idx;
		data_t							data;
	} reg_t;

	//	Commit Table for Scalar Unit
	typedef struct packed {
		logic							v;
		issue_no_t						issue_no;
		logic							commit;
	} commit_tab_s;

	//	Commit Table for Vector Unit
	//		NOTE: Placed in Scalar Unit
	typedef struct packed {
		logic							v;
		issue_no_t						issue_no;
		logic							commit;
		logic	[NUM_LANES-1:0]			en_lane;
	} commit_tab_v;


	////Command for Vector Unit
	typedef struct packed {
		instruction_t					instr;
		issue_no_t						issue_no;
	} command_t;


	////Data Memory
	typedef struct packed {
		logic							req;
		address_t						len;
		address_t						stride;
		address_t						base;
	} dmem_t;

	typedef struct packed {
		dmem_t							ld;
		dmem_t							st;
	} ldst_t;

	typedef ldst_t [1:0]				s_ldst_t;
	typedef s_ldst_t [NUM_LANES-1:0]	v_ldst_t;

	typedef data_t	[1:0]				s_ldst_data_t;
	typedef s_ldst_data_t[NUM_LANES-1:0]v_ldst_data_t;

	typedef logic	[1:0]				tb_t;
	typedef tb_t	[NUM_LANES-1:0]		v_2b_t;


	////Pipeline Registers
	//	Hazard Check Stage
	typedef instr_t						pipe_hazard_t;

	//	Index Stage
	typedef struct packed {
		logic							v;
		command_t						command;
	} pipe_index_t;

	typedef struct packed {
		logic							v;
		command_t						command;
		idx_t							src1;
		idx_t							src2;
		idx_t							src3;
		idx_t							src4;
	} pipe_index_reg_t;

	//	Register-Read Stages
	typedef struct packed {
		logic							v;
		command_t						command;
		data_t							data1;
		data_t							data2;
		data_t							data3;
	} pipe_reg_t;

	//	Register-Read and Network Stages
	typedef struct packed {
		logic							v;
		command_t						command;
		data_t							data1;
		data_t							data2;
		data_t							data3;
	} pipe_net_t;

	//	Execuution Stage (First)
	typedef struct packed {
		logic							v;
		command_t						command;
		data_t							data1;
		data_t							data2;
		data_t							data3;
	} pipe_exe_t;

	//	Execution Stage (Intermediate)
	typedef struct packed {
		logic							v;
		op_t							op;
		dst_t							dst;
		index_t							slice_len;
		issue_no_t						issue_no;
		logic	[4:0]					path;
		logic							mread;
	} pipe_exe_tmp_t;

	//	Execuution Stage (Last)
	typedef struct packed {
		logic							v;
		dst_t							dst;
		data_t							data;
		index_t							slice_len;
		issue_no_t						issue_no;
		logic	[4:0]					path;
	} pipe_exe_end_t;


	/// FSM
	typedef enum logic [2:0] {
		FSM_EXTERN_INIT			= 3'h0,
		FSM_EXTERN_RECV_STRIDE	= 3'h1,
		FSM_EXTERN_RECV_LENGTH	= 3'h2,
		FSM_EXTERN_RECV_BASE	= 3'h3,
		FSM_EXTERN_RECV_SET		= 3'h4,
		FSM_EXTERN_RUN			= 3'h5
	} fsm_extern_t;

	typedef enum logic [1:0] {
		FSM_EXTERN_ST_INIT		= 2'h0,
		FSM_EXTERN_ST_BUFF		= 2'h1,
		FSM_EXTERN_ST_NOTIFY	= 2'h2,
		FSM_EXTERN_ST_RUN		= 2'h3
	} fsm_extern_st_t;

	typedef enum logic [1:0] {
		FSM_EXTERN_LD_INIT		= 2'h0,
		FSM_EXTERN_LD_WAIT		= 2'h1,
		FSM_EXTERN_LD_NOTIFY	= 2'h2,
		FSM_EXTERN_LD_RUN		= 2'h3
	} fsm_extern_ld_t;

	typedef enum logic [1:0] {
		FSM_TPU_FE_INIT			= 2'h0,
		FSM_TPU_SCALAR			= 2'h1,
		FSM_TPU_SIMT			= 2'h2,
		FSM_TPU_INSTR			= 2'h3
	} fsm_frontend_t;


	////ETC
	//	Enum for Index Select
	typedef enum logic [1:0] {
		INDEX_ORIG				= 2'h0,
		INDEX_CONST				= 2'h1,
		INDEX_LANE				= 2'h2,
		INDEX_SIMT				= 2'h3
	} index_sel_t;

endpackage
