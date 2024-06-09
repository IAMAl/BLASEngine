package pkg_mpu;

	parameter int NUM_ENTRY_STH     	= 8;
	parameter int WIDTH_ENTRY_STH   	= $clog2(NUM_ENTRY_STH);

	parameter int NUM_ENTRY_HAZARD  	= 8;

	parameter int SIZE_THREAD_MEM		= 8192;
	parameter int WIDTH_SIZE_TMEM		= $clog2(SIZE_THREAD_MEM);

	typedef logic [WIDTH_THREADID_SCALAR-1:0]	id_t;
	typedef logic [WIDTH_SIZE_TMEM-1:0]			st_address_t;


	typedef struct packed {
		id_t								ID;
		logic								Src;
		logic	[WIDTH_THREADID_SIMT-1:0]	Src_ID;
		logic								Commmit;
	} mpu_tab_hazard_t;

	typedef struct enum logic [1:0] {
		FSM_DPC_INIT			= 2'h0,
		FSM_DPC_GETINFO			= 2'h1,
		FSM_DPC_SEND_THREADID	= 2'h2,
		FSM_DPC_SEND_INSTRS		= 2'h3
	} fsm_dispatch_t;

	typedef struct packed {
		logic								Valid;
		logic	[WIDTH_ENTRY_STH-1:0]		IsseNo;
		logic								Commmit;
	} mpu_tab_commit_t;

endpackage