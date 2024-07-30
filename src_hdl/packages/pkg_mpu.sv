package pkg_mpu;

	//Instruction Width
	parameter int WIDTH_INSTR			= 64;

	//Maximum Number of Instructions for Thread
	parameter int MAX_THREAD_LEN		= 1024;
	parameter int WIDTH_THREAD_LEN 		= $clog2(NUM_ENTRY_STH);

	//Thread Memory Size
	parameter int SIZE_THREAD_MEM		= 8192;
	parameter int WIDTH_SIZE_TMEM		= $clog2(SIZE_THREAD_MEM);

	//Mimimum Number of Threads handled by MPU
	parameter int NUM_MPU_THREADS		= SIZE_THREAD_MEM / MAX_THREAD_LEN;
	parameter int WIDTH_NUM_MPU_THREAD	= $clog2(NUM_MPU_THREADS)

	//Number of Entries in Hazard Check Table
	parameter int NUM_ENTRY_HAZARD  	= NUM_MPU_THREADS*2;

	//Address Type for Thread Memory
	typedef logic [WIDTH_SIZE_TMEM-1:0]	t_address_t;

	//Thread-ID Type
	typedef logic [WIDTH_THREADID_SCALAR-1:0]	id_t;

	//Instruction Type
	typedef logic [WIDTH_INSTR-1:0]		instr_t;

	//Hazard Check Table Entry
	typedef struct packed {
		id_t								ID;
		logic								Src;
		logic	[WIDTH_THREADID_SIMT-1:0]	Src_ID;
		logic								Commmit;
	} mpu_tab_hazard_t;

	//Commit Table Entry
	typedef struct packed {
		logic								Valid;
		logic	[WIDTH_ENTRY_STH-1:0]		IsseNo;
		logic								Commmit;
	} mpu_tab_commit_t;

	//FSM for Distapch Control
	typedef struct enum logic [1:0] {
		FSM_DPC_INIT			= 2'h0,
		FSM_DPC_GETINFO			= 2'h1,
		FSM_DPC_SEND_THREADID	= 2'h2,
		FSM_DPC_SEND_INSTRS		= 2'h3
	} fsm_dispatch_t;

	//FSM for MapMan Control (Store)
	typedef struct enum logic {
		FSM_MAPMAN_ST_INIT		= 1'h0,
		FSM_MAPMAN_ST_RUN		= 1'h1
	} fsm_mapman_st;

	//FSM for MapMan Control (Load)
	typedef struct enum logic {
		FSM_MAPMAN_LD_RUN		= 1'h0,
		FSM_MAPMAN_LD_INIT		= 1'h1
	} fsm_mapman_ld;

endpackage