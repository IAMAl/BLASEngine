package pkg_pcu;

	parameter int NUM_ENTRY_STH     	= 8;
	parameter int WIDTH_ENTRY_STH   	= $clog2(NUM_ENTRY_STH);

	parameter int NUM_ENTRY_HAZARD  	= 8;

	typedef logic [WIDTH_THREADID_SCALAR-1:0]	id_t;


	typedef struct packed {
		id_t								ID;
		logic								Src;
		logic	[WIDTH_THREADID_SIMT-1:0]	Src_ID;
		logic								Commmit;
	} pcu_tab_hazard_t;


	typedef struct packed {
		logic								Valid;
		logic	[WIDTH_ENTRY_STH-1:0]		IsseNo;
		logic								Commmit;
	} pcu_tab_commit_t;

endpackage