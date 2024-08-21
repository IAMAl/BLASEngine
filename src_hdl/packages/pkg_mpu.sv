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
parameter int WIDTH_NUM_ISSUE		= $clog2(NUM_ENTRY_HAZARD);

//Address Type for Thread Memory
typedef logic [WIDTH_SIZE_TMEM-1:0]	mpu_address_t;

//Thread-ID Type
typedef logic [WIDTH_THREADID_SCALAR-1:0]	id_t;

//Instruction Type
typedef logic [WIDTH_INSTR-1:0]		instr_t;

//Thread's Issue Number
typedef logic [WIDTH_NUM_ISSUE-1:0]	mpu_issue_no_t;

// Single-bit Flag for All TPUs
typedef logic [NUM_ROWS*NUM_CLMS-1:0]	tpu_row_clm_t;

//I/F Data Port
typedef struct packed {
	logic								v;
	logic	[WIDTH_DATA-1:0]			data;
} mpu_if_t;

//MapMan LookUp Table
typedef struct packed {
	mpu_address_t						length;
	mpu_address_t						address;
} lookup_t;

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
	logic	[WIDTH_NUM_ISSUE-1:0]		IsseNo;
	logic								Commmit;
} mpu_tab_commit_t;

//MPU Status
typedef struct packed {
	logic								imem_wait;
	logic								send_thread;
	logic								full_mapman;
	logic								full_commit;
} mpu_stat_t;

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