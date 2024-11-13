///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
///////////////////////////////////////////////////////////////////////////////////////////////////

package pkg_mpu;
	import pkg_tpu::instr_t;
	//import pkg_top::NUM_CLMS;
	import pkg_tpu::WIDTH_DATA;

	//Number of Rows in BLASEngine
	localparam int NUM_ROWS				= 1;
	localparam int NUM_CLMS				= 1;

	// Number of Scalar-Thread
	localparam int NUM_ENTRY_STH		= 64;

	//Instruction Width
	localparam int WIDTH_INSTR			= 64;

	//Maximum Number of Instructions for Thread
	localparam int MAX_THREAD_LEN		= 1024;
	localparam int WIDTH_THREAD_LEN 	= $clog2(NUM_ENTRY_STH);

	//Thread Memory Size
	localparam int SIZE_THREAD_MEM		= 4096;
	localparam int WIDTH_SIZE_TMEM		= $clog2(SIZE_THREAD_MEM);

	//Mimimum Number of Threads handled by MPU
	localparam int NUM_MPU_THREADS		= SIZE_THREAD_MEM / MAX_THREAD_LEN;
	localparam int WIDTH_NUM_MPU_THREAD	= $clog2(NUM_MPU_THREADS);

	//Number of Entries in Hazard Check Table
	localparam int NUM_ENTRY_HAZARD  	= NUM_MPU_THREADS*2;
	localparam int WIDTH_NUM_ISSUE		= $clog2(NUM_ENTRY_HAZARD);

	// Map Management Table
	localparam int SIZE_TAB_MAPMAN		= 64;
	localparam int WIDTH_TAB_MAPMAN		= $clog2(SIZE_TAB_MAPMAN);

	// Thread-ID
	localparam int WIDTH_THREADID		= 32;

	// Total Number of TPUs
	localparam int NUM_TPUS				= NUM_ROWS*NUM_CLMS;

	//Address Type for Thread Memory
	typedef logic [WIDTH_SIZE_TMEM-1:0]	mpu_address_t;

	//Thread-ID Type
	typedef logic [WIDTH_THREADID-1:0]	id_t;

	//Instruction Type
	//typedef logic [WIDTH_INSTR-1:0]		instr_t;

	//Thread's Issue Number
	typedef logic [WIDTH_NUM_ISSUE-1:0]	mpu_issue_no_t;
	typedef mpu_issue_no_t [NUM_ROWS*NUM_CLMS-1:0]	agg_issue_no_t;

	// Single-bit Flag for All TPUs
	typedef logic [NUM_CLMS-1:0]		tpu_clm_t;
	typedef tpu_clm_t	 [NUM_ROWS-1:0]	tpu_row_clm_t;

	//I/F Data Port
	typedef struct packed {
		logic							v;
		instr_t							instr;
		logic	[WIDTH_DATA-1:0]		data;
	} mpu_in_t;

	typedef struct packed {
		logic							v;
		logic	[WIDTH_DATA-1:0]		data;
	} mpu_out_t;

	//MapMan LookUp Table
	typedef struct packed {
		mpu_address_t					length;
		mpu_address_t					address;
	} lookup_t;

	//Hazard Check Table Entry
	typedef struct packed {
		id_t							ID;
		logic							Src;
		logic	[WIDTH_THREADID-1:0]	Src_ID;
		logic							Commit;
	} mpu_tab_hazard_t;

	//MapMan Table
	typedef struct packed {
		logic							Valid;
		id_t							ThreadID;
		mpu_address_t					Length;
		mpu_address_t					Address;
	} mpu_mapman_t;

	//Commit Table Entry
	typedef struct packed {
		logic							Valid;
		logic	[WIDTH_NUM_ISSUE-1:0]	IssueNo;
		logic							Commit;
	} mpu_tab_commit_t;

	//MPU Status
	typedef struct packed {
		logic	[3:0]					io;
		logic							imem_wait;
		logic							send_thread;
		logic							full_mapman;
		logic							full_commit;
	} mpu_stat_t;

	//FSM for Distapch Control
	typedef enum logic [2:0] {
		FSM_DPC_INIT			= 3'h0,
		FSM_DPC_GETINFO			= 3'h1,
		FSM_DPC_SEND_THREADID	= 3'h2,
		FSM_DPC_SEND_INSTRS		= 3'h3,
		FSM_DPC_SEND_ISSUENO	= 3'h4,
		FSM_DPC_SEND_ILENGTH	= 3'h5
	} fsm_dispatch_t;

	//FSM for MapMan Control (Store)
	typedef enum logic {
		FSM_MAPMAN_ST_INIT		= 1'h0,
		FSM_MAPMAN_ST_RUN		= 1'h1
	} fsm_mapman_st;

	//FSM for MapMan Control (Load)
	typedef enum logic {
		FSM_MAPMAN_LD_RUN		= 1'h0,
		FSM_MAPMAN_LD_INIT		= 1'h1
	} fsm_mapman_ld;

	//FSM for IF Service
	typedef enum logic [2:0] {
		FSM_EXTERN_MPU_RECV_INIT	= 3'h0,
		FSM_EXTERN_MPU_RECV_STRIDE	= 3'h1,
		FSM_EXTERN_MPU_RECV_LENGTH	= 3'h2,
		FSM_EXTERN_MPU_RECV_BASE	= 3'h3,
		FSM_EXTERN_MPU_RECV_RUN		= 3'h4
	} fsm_extern_serv;

	typedef enum logic [1:0] {
		FSM_EXTERN_MPU_ST_INIT	= 2'h0,
		FSM_EXTERN_MPU_ST_BUFF	= 2'h1,
		FSM_EXTERN_MPU_ST_NOTIFY= 2'h2,
		FSM_EXTERN_MPU_ST_RUN	= 2'h3
	} fsm_extern_st;

	typedef enum logic [1:0] {
		FSM_EXTERN_MPU_LD_INIT	= 2'h0,
		FSM_EXTERN_MPU_LD_WAIT	= 2'h1,
		FSM_EXTERN_MPU_LD_NOTIFY= 2'h2,
		FSM_EXTERN_MPU_LD_RUN	= 2'h3
	} fsm_extern_ld;

	typedef enum logic [4:0] {
		FSM_INIT_IF_MPU				= 5'h00,
		FSM_COMMAND_IF_MPU			= 5'h01,
		FSM_CHK_CMD_IF_MPU			= 5'h02,
		FSM_SET_EN_TPU_MPU			= 5'h03,
		FSM_STOP_IF_MPU				= 5'h04,
		FSM_RUN_CAPTURE_ID_IF_MPU	= 5'h05,
		FSM_RUN_QUERY_MAPMAN_IF_MPU	= 5'h06,
		FSM_RUN_QUERY_THMEM_IF_MPU	= 5'h07,
		FSM_RUN_DISPATCH_IF_MPU		= 5'h08,
		FSM_ST_CAPTURE_ID_IF_MPU	= 5'h09,
		FSM_ST_DATA_ID_IF_MPU		= 5'h0a,
		FSM_ST_DATA_STRIDE_IF_MPU	= 5'h0b,
		FSM_ST_DATA_BASE_IF_MPU		= 5'h0c,
		FSM_ST_DATA_IF_MPU			= 5'h0d,
		FSM_LD_DATA_ID_IF_MPU		= 5'h0e,
		FSM_LD_DATA_STRIDE_IF_MPU	= 5'h0f,
		FSM_LD_DATA_BASE_IF_MPU		= 5'h10,
		FSM_LD_DATA_IF_MPU			= 5'h11
	} fsm_if_t;


	typedef enum logic [2:0] {
		FSM_INSTR_ST_INIT		= 3'h0,
		FSM_INSTR_ST_CHECK		= 3'h1,
		FSM_INSTR_ST_SETUP		= 3'h2,
		FSM_INSTR_ST_RCVID		= 3'h3,
		FSM_INSTR_ST_LOOKUP		= 3'h4,
		FSM_INSTR_ST_STORE		= 3'h5
	} fsm_threadmem_t;

endpackage