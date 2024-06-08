package pkg_tpu;

	parameter int WIDTH_DATA			= 32;

	parameter int NUM_ENTRY_REGFILE		= 64;
	parameter int WIDTH_ENTRY_REGFILE	= $clog2(NUM_ENTRY_REGFILE);

	parameter int NUM_ENTRY_HAZARD		= 8;
	parameter int WIDTH_ENTRY_HAZARD	= $clog2(NUM_ENTRY_HAZARD);

	parameter int NUM_ACTIVE_INSTRS		= 16;
	parameter int WIDTH_ACTIVE_INSTRS	= $clog2(NUM_ACTIVE_INSTRS);

	parameter int WIDTH_COUNT			= WIDTH_ACTIVE_INSTRS;

	parameter int WIDTH_STATE			= 8;

	parameter int SIZE_LOCAL_MEMORY		= 1024;
	parameter int WIDTH_SIZE_LMEMORY	= $clog2(SIZE_LOCAL_MEMORY);

	typedef logic [WIDTH_DATA-1:0]				data_t;
	typedef logic [WIDTH_ENTRY_REGFILE-1:0]		index_t;
	typedef logic [WIDTH_COUNT-1:0]				count_t;
	typedef logic [WIDTH_SIZE_LMEMORY-1:0]		address_t;
	typedef logic [WIDTH_STATE-1:0]				cond_t;

	typedef struct packed {
		logic								v_dst;
		logic								v_src1;
		logic								v_src2;
		logic								v_src3;
		index_t								DstIdx;
		index_t								SrcIdx1;
		index_t								SrcIdx2;
		index_t								SrcIdx3;
		logic	[WIDTH_ENTRY_STH-1:0]		IsseNo;
		logic								Commmit;
	} iw_t;

	typedef struct enum logic [1:0] {
		INDEX_ORIG			= 2'h0,
		INDEX_CONST			= 2'h1,
		INDEX_SCALAR		= 2'h2,
		INDEX_SIMT			= 2'h3
	} index_sel_t;

endpackage