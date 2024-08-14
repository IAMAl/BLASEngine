///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
///////////////////////////////////////////////////////////////////////////////////////////////////

package pkg_commit_agg;
	import pkg_mpu::*;

	localparam int	BYPASS_BUFF_SIZE	= 4;

	typedef struct packed {
		logic				v;
		mpu_issue_no_t		issue_no;
		tpu_row_clm_t		en_tpu;
		tpu_row_clm_t		commit;
	} commit_agg_t;


endpackage