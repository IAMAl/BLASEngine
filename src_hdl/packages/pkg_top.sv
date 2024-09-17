///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
///////////////////////////////////////////////////////////////////////////////////////////////////

package pkg_top;
	import pkg_mpu::*;

	//Number of Rows in BLASEngine
	localparam int NUM_ROWS				= 2;
	localparam int NUM_CLMS				= 2;

	//Total Number of TPUs
	localparam int NUM_TPU				= NUM_ROWS*NUM_CLMS;

	//Buffer Size in Commit Aggregater
	localparam int	BYPASS_BUFF_SIZE	= 4;

	//Thread's Issue Number
	typedef logic [WIDTH_NUM_ISSUE-1:0]	mpu_issue_no_t;

	// Single-bit Flag for All TPUs
	typedef logic [NUM_TPUS-1:0]		tpu_row_clm_t;

	//Commit Aggregater Table
	typedef struct packed {
		logic				v;
		mpu_issue_no_t		issue_no;
		tpu_row_clm_t		en_tpu;
		tpu_row_clm_t		commit;
	} commit_agg_t;

endpackage