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

	//Bit-Width for Data
	parameter int WIDTH_DATA			= 32;

	//Number of Entries in Register File
	parameter int NUM_ENTRY_REGFILE		= 64;
	parameter int WIDTH_ENTRY_REGFILE	= $clog2(NUM_ENTRY_REGFILE);

	//Register File Index
	parameter int WIDTH_INDEX 			= WIDTH_ENTRY_REGFILE;

	//Number of Entries in Hazard Check Table
	parameter int NUM_ENTRY_HAZARD		= 8;
	parameter int WIDTH_ENTRY_HAZARD	= $clog2(NUM_ENTRY_HAZARD);

	//NUmber of Active Instructions
	parameter int NUM_ACTIVE_INSTRS		= 16;
	parameter int WIDTH_ACTIVE_INSTRS	= $clog2(NUM_ACTIVE_INSTRS);

	//Bit-Width for Status Register
	parameter int WIDTH_STATE			= 4;

	//Data Memory
	parameter int SIZE_DATA_MEMORY		= 1024;
	parameter int WIDTH_SIZE_DMEM		= $clog2(SIZE_DATA_MEMORY);

	//Constant in Instruction
	parameter int WIDTH_CONSTANT		= 64-7-7*4-6-1;


	//Logic Types
	//	General Data Type
	typedef logic	[WIDTH_DATA-1:0]		data_t;

	//	General Index Type
	//		MSb differenciates Two Register Files
	typedef logic	[WIDTH_INDEX:0]			index_s_t;

	//	Index Type for Single Register File
	typedef logic	[WIDTH_INDEX-1:0]		index_t;

	//	Address Type for Data Memory
	typedef logic	[WIDTH_SIZE_LMEMORY-1:0]address_t;

	//	Status Data (cmp instr. result) Types
	typedef logic	[WIDTH_STATE-1:0]		stat_s_t;
	typedef logic	[WIDTH_STATE-1:0]		stat_v_t;

	//	Instruction Issue No
	//		Used for Commit as clearing address the Hazard Check Table
	typedef logic	[WIDTH_ENTRY_HAZARD-1:0]issue_no_t;

	//	Mask Type
	//		Used in Vector Lane
	//		One-bit flag selected from stat_v_t
	typedef logic	[NUM_ENTRY_REGFILE-1:0]	mask_t;



	////Instruction-Set
	//	Operation Bit-Field in Instruction
	typedef struct packed {
		logic							Sel_Unit;
		logic		[1:0]				OpType;
		logic		[1:0]				OpClass;
		logic		[1:0]				OpCode;
	} op_t;

	typedef struct packed {
		logic							v;
		logic							slice;
		index_s_t						idx;
		logic		[6:0]				sel;
	} idx_t;

	typedef struct packed {
		logic							v;
		index_t							idx;
	} reg_idx_t;

	//	Constant Type
	typedef logic 	[WIDTH_CONSTANT-1:0]	imm_t;

	//	Instruction Bit Field
	typedef struct packed {
		op_t							op;
		idx_t							dst;
		idx_t							src1;
		idx_t							src2;
		idx_t							src3;
		index_t							slice_len;
		imm_t							imm;
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
		idx_t							dst;
		idx_t							src1;
		idx_t							src2;
		idx_t							src3;
		index_t							slice_len;
		issue_no_t						issue_no;
		logic							commit;
	} iw_t;

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
		logic	[NUM_LANE-1:0]			en_lane;
		logic	[NUM_LANE-1:0]			en_commit;
	} commit_tab_v;


	////Command for Vector Unit
	typedef struct packed {
		instr_t							instr;
		issue_no_t						issue_no;
	} command_t;


	////Pipeline Registers
	//	Hazard Check Stage
	typedef instr_t						pipe_hazard_t;

	//	Index Stage
	typedef struct packed {
		logic							v;
		op_t							op;
		idx_t							dst:
		idx_t							src1;
		idx_t							src2;
		idx_t							src3;
		idx_t							src4;
		index_t							slice_len;
		issue_no_t						issue_no;
	} pipe_index_t;


	//	Register-Read Stages
	typedef struct packed {
		logic							v;
		op_t							op;
		idx_t							dst:
		reg_idx_t						src1;
		reg_idx_t						src2;
		reg_idx_t						src3;
		issue_no_t						issue_no;
	} pipe_rr_t;

	//	Register-Read and Network Stages
	typedef struct packed {
		logic							v;
		op_t							op;
		idx_t							dst:
		data_t							data1;
		data_t							data2;
		data_t							data3;
		issue_no_t						issue_no;
	} pipe_net_t;

	//	Execution Stage (Intermediate)
	typedef struct packed {
		logic							v;
		idx_t							dst:
		issue_no_t						issue_no;
	} pipe_exe_tmp_t;

	//	Execuution Stage (Last)
	typedef struct packed {
		logic							v;
		idx_t							dst:
		data_t							data;
		issue_no_t						issue_no;
	} pipe_exe_end_t;


	////ETC
	//	Enum for Index Select
	typedef struct enum logic [1:0] {
		INDEX_ORIG				= 2'h0,
		INDEX_CONST				= 2'h1,
		INDEX_SCALAR			= 2'h2,
		INDEX_SIMT				= 2'h3
	} index_sel_t;


endpackage