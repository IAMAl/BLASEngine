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
	parameter int NUM_ROWS				= 2;
	parameter int NUM_CLMS				= 2;

	//Total Number of TPUs
	parameter int NUM_TPU				= NUM_ROWS*NUM_CLMS;

	//Buffer Size in Commit Aggregater
	localparam int	BYPASS_BUFF_SIZE	= 4;


	//Commit Aggregater Table
	typedef struct packed {
		logic				v;
		mpu_issue_no_t		issue_no;
		tpu_row_clm_t		en_tpu;
		tpu_row_clm_t		commit;
	} commit_agg_t;

endpackage