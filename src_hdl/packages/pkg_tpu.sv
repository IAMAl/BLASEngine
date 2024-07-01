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

	parameter int NUM_ACTIVE_INSTRS		= 16;
	parameter int WIDTH_ACTIVE_INSTRS	= $clog2(NUM_ACTIVE_INSTRS);

	parameter int WIDTH_COUNT			= WIDTH_ACTIVE_INSTRS;

	//Bit-Width for Status Register
	parameter int WIDTH_STATE			= 4;

	//Data Memory
	parameter int SIZE_DATA_MEMORY		= 1024;
	parameter int WIDTH_SIZE_DMEM		= $clog2(SIZE_DATA_MEMORY);


	//Logic Types
	typedef logic [WIDTH_DATA-1:0]				data_t;
	typedef logic [WIDTH_INDEX:0]				index_s_t;
	typedef logic [WIDTH_INDEX-1:0]				index_t;
	typedef logic [WIDTH_COUNT-1:0]				count_t;
	typedef logic [WIDTH_SIZE_LMEMORY-1:0]		address_t;
	typedef logic [WIDTH_STATE-1:0]				cond_t;
	typedef logic [WIDTH_ENTRY_HAZARD-1:0]		issue_no_t;
	typedef data_t [NUM_LANES-1:0]				rot_srcs_t;


	//Operation Bit-Field in Instruction
	typedef struct packed {
		logic								valid;
		logic								Sel_Unit;
		logic		[1:0]					OpType;
		logic		[1:0]					OpClass;
		logic		[1:0]					OpCode;
		logic								slice1;
		logic								slice2;
		logic								slice3;
	} op_t;

	//Instruction Bit Field
	typedef struct packed {
		logic								Sel_Unit;
		logic		[1:0]					OpType;
		logic		[1:0]					OpClass;
		logic		[1:0]					OpCode;
		logic								v_dst;
		logic								v_src1;
		logic								v_src2;
		logic								v_src3;
		logic								slice1;
		logic								slice2;
		logic								slice3;
		index_t								IdxLength;
		index_s_t							DstIdx;
		index_s_t							SrcIdx1;
		index_s_t							SrcIdx2;
		index_s_t							SrcIdx3;
		logic		[64-7-7*4-6-1:0]		Constant;
	} instruction_t;

	//Instruction+Valid
	typedef struct packed {
		logic								v;
		instruction_t						instr;
	} instr_t;


	// Hazard Unit Table
	typedef struct packed {
		logic								v_dst;
		logic								v_src1;
		logic								v_src2;
		logic								v_src3;
		logic								v_src4;
		logic								slice1;
		logic								slice2;
		logic								slice3;
		index_t								IdxLength;
		index_t								DstIdx;
		index_t								SrcIdx1;
		index_t								SrcIdx2;
		index_t								SrcIdx3;
		issue_no_t							IsseNo;
		logic								Commit;
	} iw_t;



	//Command for Vector Unit
	typedef struct packed {
		logic								valid;
		logic		[1:0]					OpType;
		logic		[1:0]					OpClass;
		logic		[1:0]					OpCode;
		logic								v_dst;
		logic								v_src1;
		logic								v_src2;
		logic								v_src3;
		logic								v_src4;
		logic								slice1;
		logic								slice2;
		logic								slice3;
		index_t								IdxLength;
		index_s_t							DstIdx;
		index_s_t							SrcIdx1;
		index_s_t							SrcIdx2;
		index_s_t							SrcIdx3;
		data_t								Imm_Data;
	} command_t;


	//Commit Table for Scalar Unit
	typedef struct packed {
		logic					Valid;
		issue_no_t				Issue_No;
		logic					Commit;
	} commit_tab_s;


	//Commit Table for Vector Unit
	typedef struct packed {
		logic					Valid;
		issue_no_t				Issue_No;
		logic	[NUM_LANE-1:0]	En_Lane;
		logic	[NUM_LANE-1:0]	En_Commit;
		logic					Commit;
	} commit_tab_v;


	//Status Register
	typedef struct packed {
		logic	[3:0]			cmp;
	} stat_reg;


	//Enum for Index Select
	typedef struct enum logic [1:0] {
		INDEX_ORIG			= 2'h0,
		INDEX_CONST			= 2'h1,
		INDEX_SCALAR		= 2'h2,
		INDEX_SIMT			= 2'h3
	} index_sel_t;


endpackage