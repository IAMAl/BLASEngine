package pkg_tpu;

	parameter int WIDTH_DATA			= 32;

	parameter int NUM_ENTRY_REGFILE		= 64;
	parameter int WIDTH_ENTRY_REGFILE	= $clog2(NUM_ENTRY_REGFILE);
	parameter int WIDTH_INDEX 			= WIDTH_ENTRY_REGFILE;

	parameter int NUM_ENTRY_HAZARD		= 8;
	parameter int WIDTH_ENTRY_HAZARD	= $clog2(NUM_ENTRY_HAZARD);

	parameter int NUM_ACTIVE_INSTRS		= 16;
	parameter int WIDTH_ACTIVE_INSTRS	= $clog2(NUM_ACTIVE_INSTRS);

	parameter int WIDTH_COUNT			= WIDTH_ACTIVE_INSTRS;

	parameter int WIDTH_STATE			= 8;

	parameter int SIZE_LOCAL_MEMORY		= 1024;
	parameter int WIDTH_SIZE_LMEMORY	= $clog2(SIZE_LOCAL_MEMORY);

	typedef logic [WIDTH_DATA-1:0]				data_t;
	typedef logic [WIDTH_INDEX:0]				index_s_t;
	typedef logic [WIDTH_INDEX-1:0]				index_t;
	typedef logic [WIDTH_COUNT-1:0]				count_t;
	typedef logic [WIDTH_SIZE_LMEMORY-1:0]		address_t;
	typedef logic [WIDTH_STATE-1:0]				cond_t;


	typedef logic [WIDTH_ENTRY_STH-1:0]			issue_no_t;

	typedef data_t [NUM_LANES-1:0]				rot_srcs_t;

	//// Bit-Field in Operation Code
	// Unit Selector [2:0]
	// [2]
	//	0		Select Scalr Unit
	//	1		Select Vector Unit
	// [1:0]
	//	00		Arithmetic Unit
	//	01		Conditional (Scalar: Jump/Branch, Vector Masked Arithmetic Unit)
	//	10		Logic/Shift/Rotate
	//	11		Load/Store
	//Arithmetic Unit	[1:0]
	//  Scalar Unit
	//	00		Adder
	//		OpCode [1:0]
	//		00		Unsiged Addition
	//		01		Unsigned Subtruction
	//		10		Signed Addition
	//		11		Signed Addition
	//	01		Multiplier
	//		OpCode [1:0]
	//		00		Unsigned Multiplication
	//		01		Signed Multiplication
	//		1x		Reserved
	//	10		Divider
	//		OpCode [1:0]
	//		00		Unsigned Division
	//		01		Signed Division
	//		1x		Reserved
	//	11		Convert
	//		OpCode [1:0]
	//		00		Int32 to Float32
	//		01		Move
	//		10		Bit-Reverse
	//		11		Rese
	//  Vector Unit
	//	00		Adder
	//		OpCode [1:0]
	//		00		Addition
	//		01		Subtraction
	//		10		Compare
	//		11		Reserved
	//	01		Multiplier
	//		OpCode [1:0]
	//		00		Multiplication
	//		01		Reserved
	//		1x		Reserved
	//	10		Specials
	//		OpCode [1:0]
	//		00		Power of Any
	//		01		Exponential
	//		10		Logarithm of Two
	//		11		Reserved
	//	11		Convert
	//		OpCode [1:0]
	//		00		Float32 to Int32
	//		01		Move
	//		1x		Reserved
	//
	//
	//Conditional		[1:0]
	//	Scalar Unit
	//	00		Compare
	//		OpCode [1:0]
	//		00		Equal
	//		01		Greater than
	//		10		Lesser than or Equal
	//		11		Not Equal
	//	01		Jump
	//		OpCode [1:0]
	//		00		Relative Jump width Source
	//		01		Relative Jump width Constant
	//		1x		Reserved
	//	10		Branch
	//		OpCode [1:0]
	//		00		Relative Branch width Source
	//		01		Relative Branch width Constant
	//		1x		Reserved
	//	11		Reserved
	//	Vector Unit
	//	00		Compare
	//		OpCode [1:0]
	//		00		Equal
	//		01		Greater than
	//		10		Lesser than or Equal
	//		11		Not Equal
	//	01		Reserved
	//	1x		Reserved
	//
	//
	//Logic/Shift/Rotate	[1:0]
	//	Scalar Unit
	//	00		Logic
	//		OpCode [1:0]
	//		00		NOT
	//		01		AND
	//		10		OR
	//		11		XOR
	//	01		Shift
	//		OpCode [1:0]
	//		00		Logic Left-Shift
	//		01		Arithmetic Left-Shift
	//		10		Logic Right-Shift
	//		11		Arithmetic Right-Shift
	//	10		Rotate
	//		OpCode [1:0]
	//		00		Left-Rotate
	//		01		Reserved
	//		10		Right-Rotate
	//		11		Reserved
	//	11		Reserved
	//	Vector Unit
	//	xx		Reserved
	//
	//
	//Load/Store		[1:0]
	//	Scalar Unit
	//	00		Load with Sign-Extension to 4-Byte for Even Unit
	//		OpCode	[1:0]
	//		00		Byte Load
	//		01		Short Load
	//		10		Word Load
	//		11		Reserved
	//	01		Load with Sign-Extension to 4-Byte for Odd Unit
	//		OpCode	[1:0]
	//		00		Byte Load
	//		01		Short Load
	//		10		Word Load
	//		11		Reserved
	//	10		Store for Even Unit
	//		OpCode	[1:0]
	//		00		Byte Store
	//		01		Short Store
	//		10		Word Store
	//		11		Reserved
	//	11		Store for Odd Unit
	//		OpCode	[1:0]
	//		00		Byte Store
	//		01		Short Store
	//		10		Word Store
	//		11		Reserved
	//	Vector Unit
	//	00		Normal Word-Load for Even Unit
	//		OpCode	[1:0]
	//		0x		Reserved
	//		10		Word Load
	//		11		Reserved
	//	01		Normal Word-Load for Odd Unit
	//		OpCode	[1:0]
	//		0x		Reserved
	//		10		Word Load
	//		11		Reserved
	//	10		Normal Word Store for Even Unit
	//		0x		Reserved
	//		10		Word Store
	//		11		Reserved
	//	11		Normal Word Store for Odd Unit
	//		0x		Reserved
	//		10		Word Store
	//		11		Reserved


	typedef struct packed {
		logic								Sel_Unit;
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
		logic		[64-7-7*4-6-1:0]		Constant;
	} instruction_t;


	typedef struct packed {
		logic								v;
		instruction_t						instr;
	} instr_t;


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
		logic								Commmit;
	} iw_t;

	typedef struct packed {
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


	typedef struct enum logic [1:0] {
		INDEX_ORIG			= 2'h0,
		INDEX_CONST			= 2'h1,
		INDEX_SCALAR		= 2'h2,
		INDEX_SIMT			= 2'h3
	} index_sel_t;


endpackage