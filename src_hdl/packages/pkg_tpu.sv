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
		logic							valid;
		logic							Sel_Unit;
		logic		[1:0]				OpType;
		logic		[1:0]				OpClass;
		logic		[1:0]				OpCode;
		logic							slice1;
		logic							slice2;
		logic							slice3;
	} op_t;

	//	Instruction Bit Field
	typedef struct packed {
		logic							Sel_Unit;
		logic		[1:0]				OpType;
		logic		[1:0]				OpClass;
		logic		[1:0]				OpCode;
		logic							v_dst;
		logic							v_src1;
		logic							v_src2;
		logic							v_src3;
		logic							slice1;
		logic							slice2;
		logic							slice3;
		index_t							slice_length;
		index_s_t						DstIdx;
		index_s_t						SrcIdx1;
		index_s_t						SrcIdx2;
		index_s_t						SrcIdx3;
		logic		[64-7-7*4-6-1:0]	Constant;
	} instruction_t;

	//	Instruction + Valid
	typedef struct packed {
		logic							v;
		instruction_t					instr;
	} instr_t;


	////Execution Steering
	//	Hazard Table used in Scalar unit
	typedef struct packed {
		logic							v_dst;
		logic							v_src1;
		logic							v_src2;
		logic							v_src3;
		logic							v_src4;
		logic							slice1;
		logic							slice2;
		logic							slice3;
		index_t							slice_length,
		index_t							DstIdx;
		index_t							SrcIdx1;
		index_t							SrcIdx2;
		index_t							SrcIdx3;
		data_t							Imm_Data;
		logic							Commit;
	} iw_t;

	//	Commit Table for Scalar Unit
	typedef struct packed {
		logic							Valid;
		issue_no_t						Issue_No;
		logic							Commit;
	} commit_tab_s;

	//	Commit Table for Vector Unit
	//		NOTE: Placed in Scalar Unit
	typedef struct packed {
		logic							Valid;
		issue_no_t						Issue_No;
		logic	[NUM_LANE-1:0]			En_Lane;
		logic	[NUM_LANE-1:0]			En_Commit;
		logic							Commit;
	} commit_tab_v;


	//	Destination Infor Type
	typedef struct packed {
		logic							We_Odd;
		logic							We_Evn;
		logic							Slice;
		index_t 						Index;
		logic	[1:0]					Sel;
	} dst_info_t;


	////Command for Vector Unit
	typedef struct packed {
		logic							valid;
		logic		[1:0]				OpType;
		logic		[1:0]				OpClass;
		logic		[1:0]				OpCode;
		dst_info_t						dst_info:
		logic							v_src1;
		logic							v_src2;
		logic							v_src3;
		logic							slice1;
		logic							slice2;
		logic							slice3;
		index_t							slice_length;
		index_s_t						SrcIdx1;
		index_s_t						SrcIdx2;
		index_s_t						SrcIdx3;
		logic		[1:0]				Src1_Sel;
		logic		[1:0]				Src2_Sel;
		logic		[1:0]				Src3_Sel;
		data_t							Imm_Data;
	} command_t;


	////Pipeline Registers
	//	Hazard Check Stage
	typedef struct packed {
		dst_info_t						dst_info:
		logic							v_src1;
		logic							v_src2;
		logic							v_src3;
		logic							v_src4;
		logic							slice1;
		logic							slice2;
		logic							slice3;
		index_t							slice_length,
		index_t							SrcIdx1;
		index_t							SrcIdx2;
		index_t							SrcIdx3;
		data_t							Imm_Data;
		issue_no_t						Issue_No;
	} pipe_hazard_t;

	//	Index Stage
	typedef struct packed {
		logic							valid;
		logic		[1:0]				OpType;
		logic		[1:0]				OpClass;
		logic		[1:0]				OpCode;
		dst_info_t						dst_info:
		logic							v_src1;
		logic							v_src2;
		logic							v_src3;
		logic							v_src4;
		logic							slice1;
		logic							slice2;
		logic							slice3;
		logic							slice4;
		index_s_t						DstIdx;
		index_s_t						SrcIdx1;
		index_s_t						SrcIdx2;
		index_s_t						SrcIdx3;
		index_s_t						SrcIdx4;
		data_t							Imm_Data;
		issue_no_t						Issue_No;
	} pipe_index_t;

	//	Register-Read and Network Stages
	typedef struct packed {
		logic							valid;
		logic		[1:0]				OpType;
		logic		[1:0]				OpClass;
		logic		[1:0]				OpCode;
		dst_info_t						dst_info:
		logic							v_src1;
		logic							v_src2;
		logic							v_src3;
		logic							v_src4;
		logic							slice1;
		logic							slice2;
		logic							slice3;
		logic							slice4;
		index_s_t						DstIdx;
		index_s_t						SrcIdx1;
		index_s_t						SrcIdx2;
		index_s_t						SrcIdx3;
		data_t							Src_Data1;
		data_t							Src_Data2;
		data_t							Src_Data3;
		issue_no_t						Issue_No;
	} pipe_rr_net_t;

	//	Execution Stage (Intermediate)
	typedef struct packed {
		logic							valid;
		dst_info_t						dst_info:
		issue_no_t						Issue_No;
	} pipe_exe_tmp_t;

	//	Execuution Stage (Last)
	typedef struct packed {
		logic							valid;
		dst_info_t						dst_info:
		data_t							WB_Data;
		issue_no_t						Issue_No;
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